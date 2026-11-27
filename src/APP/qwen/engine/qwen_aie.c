/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
/* See qwen_aie.h. The x quantization is qw_matmul_cpu's (per 64, absmax / 127, round half away from 0), so the
 * AIE path computes the same int32 group sums as the CPU reference. */
#include "qwen_aie.h"

#include <math.h>
#ifdef __aarch64__
#include <arm_neon.h>
#endif
#include <string.h>

/* the board app defines it (Xil_DCacheInvalidateRange); a weak no-op elsewhere */
__attribute__((weak)) void qw_dcache_invalidate(intptr_t adr, intptr_t len) { (void)adr, (void)len; }
/* the board app defines it (Xil_DCacheFlushRange); a weak no-op elsewhere */
__attribute__((weak)) void qw_dcache_flush(intptr_t adr, intptr_t len) { (void)adr, (void)len; }

/* the kernel's x: two halves of 32 K groups, each [32][4][QA_M][16] int8 then [32][QA_M] fp32 scales, repeated
 * `copies` times (one per mesh column). Only tokens m < n are written: the kernel computes all QA_M token
 * slots, but the glue reads back only the first n, so the other slots may hold anything. */
void qa_prep_x(const float *x, int K, int n, int s, int8_t *xbuf, int copies) {
    for (int m = 0; m < n; m++) {
        const float *xm = x + (size_t)m * K + (size_t)s * QA_K;
        for (int g = 0; g < QA_K / 64; g++) {
            float a = 0;
#ifdef __aarch64__
            float32x4_t mx = vdupq_n_f32(0.0f);
            for (int k = 0; k < 64; k += 4)
                mx = vmaxq_f32(mx, vabsq_f32(vld1q_f32(xm + g * 64 + k)));
            a = vmaxvq_f32(mx);
#else
            for (int k = 0; k < 64; k++) {
                const float v = fabsf(xm[g * 64 + k]);
                a = v > a ? v : a;
            }
#endif
            const float inv = a > 0 ? 127.0f / a : 0.0f, sc = a / 127.0f;
            int8_t q[64] __attribute__((aligned(16)));
#ifdef __aarch64__ /* vcvtaq: round to nearest, ties away from zero -- the scalar rule below */
            for (int t = 0; t < 4; t++) {
                const float *p = xm + g * 64 + 16 * t;
                const int32x4_t i0 = vcvtaq_s32_f32(vmulq_n_f32(vld1q_f32(p), inv));
                const int32x4_t i1 = vcvtaq_s32_f32(vmulq_n_f32(vld1q_f32(p + 4), inv));
                const int32x4_t i2 = vcvtaq_s32_f32(vmulq_n_f32(vld1q_f32(p + 8), inv));
                const int32x4_t i3 = vcvtaq_s32_f32(vmulq_n_f32(vld1q_f32(p + 12), inv));
                const int16x8_t h0 = vcombine_s16(vqmovn_s32(i0), vqmovn_s32(i1));
                const int16x8_t h1 = vcombine_s16(vqmovn_s32(i2), vqmovn_s32(i3));
                vst1q_s8(q + 16 * t, vcombine_s8(vqmovn_s16(h0), vqmovn_s16(h1)));
            }
#else
            for (int k = 0; k < 64; k++) {
                const float v = xm[g * 64 + k] * inv;
                q[k] = (int8_t)(v >= 0 ? (int)(v + 0.5f) : -(int)(-v + 0.5f));
            }
#endif
            for (int c = 0; c < copies; c++) {
                int8_t *half = xbuf + (size_t)c * QA_XB + (g / 32) * (QA_XB / 2), *xt = half + (g % 32) * 4 * QA_M * 16;
                ((float *)(half + 32 * 4 * QA_M * 16))[(g % 32) * QA_M + m] = sc;
                for (int t = 0; t < 4; t++) /* tile t holds K 16 t .. 16 t + 15 of the group */
#ifdef __aarch64__
                    vst1q_s8(xt + (t * QA_M + m) * 16, vld1q_s8(q + 16 * t));
#else
                    memcpy(xt + (t * QA_M + m) * 16, q + 16 * t, 16);
#endif
            }
        }
    }
}

void qw_matmul_aie(void *ctx, const qw_mat *w, const float *x, int n, float *y) {
    qa_ctx *a = (qa_ctx *)ctx;
    if (w->type != QW_Q4G64 || w->cols % QA_K || w->prow % QA_ROWS) {
        qw_matmul_cpu(NULL, w, x, n, y);
        return;
    }
    const int R = w->rows, S = w->cols / QA_K, L = w->prow / QA_ROWS, nrb = w->prow / 16;
    const size_t slice_bytes = (size_t)nrb * (QA_K / 1024) * QW_CHUNK_BYTES, launch_bytes = slice_bytes / L;
    for (int t0 = 0; t0 < n; t0 += QA_M) {
        const int nt = n - t0 < QA_M ? n - t0 : QA_M;
        for (int s = 0; s < S; s++) {
            double c0 = a->now ? a->now() : 0;
            qa_prep_x(x + (size_t)t0 * w->cols, w->cols, nt, s, a->xbuf, QA_XCOPIES);
            if (a->xcached) /* cached stores are fast; one clean of the copies (uncached stores ran ~0.5 GB/s) */
                qw_dcache_flush((intptr_t)a->xbuf, QA_XCOPIES * QA_XB);
            if (a->now)
                a->cpu_s += a->now() - c0, a->prep_s += a->now() - c0;
            for (int l = 0; l < L; l++) {
                const double t1 = a->now ? a->now() : 0;
                a->launch((int8_t *)(w->data + s * slice_bytes + l * launch_bytes), a->xbuf, (int8_t *)a->ybuf);
                a->launches++;
                const double t2 = a->now ? a->now() : 0;
                if (a->ycached)
                    qw_dcache_invalidate((intptr_t)a->ybuf, QA_YB); /* (an uncached ybuf skips this) */
                for (int rb = 0; rb < QA_ROWS / 16; rb++) {
                    const int row0 = l * QA_ROWS + rb * 16;
                    if (row0 >= R)
                        break;
                    for (int m = 0; m < nt; m++) {
                        const float *src = a->ybuf + ((size_t)rb * QA_M + m) * 16;
                        float *dst = y + (size_t)(t0 + m) * R + row0;
                        if (s == 0)
                            memcpy(dst, src, sizeof(float) * 16);
                        else
                            for (int i = 0; i < 16; i++)
                                dst[i] += src[i];
                    }
                }
                if (a->now)
                    a->aie_s += t2 - t1, a->cpu_s += a->now() - t2;
            }
        }
    }
}
