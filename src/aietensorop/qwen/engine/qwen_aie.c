/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
/* See qwen_aie.h. The x quantization is qw_matmul_cpu's (per 64, absmax / 127, round half away from 0), so the
 * AIE path computes the same int32 group sums as the CPU reference. */
#include "qwen_aie.h"

#include <math.h>
#include <string.h>

/* the board app defines it (Xil_DCacheInvalidateRange); a weak no-op elsewhere */
__attribute__((weak)) void qw_dcache_invalidate(intptr_t adr, intptr_t len) { (void)adr, (void)len; }

/* the kernel's x: two halves of 32 K groups, each [32][4][QA_M][16] int8 then [32][QA_M] fp32 scales */
void qa_prep_x(const float *x, int K, int n, int s, int8_t *xbuf) {
    memset(xbuf, 0, QA_XB);
    for (int m = 0; m < n; m++) {
        const float *xm = x + (size_t)m * K + (size_t)s * QA_K;
        for (int g = 0; g < QA_K / 64; g++) {
            float a = 0;
            for (int k = 0; k < 64; k++) {
                const float v = fabsf(xm[g * 64 + k]);
                a = v > a ? v : a;
            }
            const float inv = a > 0 ? 127.0f / a : 0;
            int8_t *half = xbuf + (g / 32) * (QA_XB / 2), *xt = half + (g % 32) * 4 * QA_M * 16;
            ((float *)(half + 32 * 4 * QA_M * 16))[(g % 32) * QA_M + m] = a / 127.0f;
            for (int k = 0; k < 64; k++) {
                const float v = xm[g * 64 + k] * inv;
                xt[((k / 16) * QA_M + m) * 16 + k % 16] = (int8_t)(v >= 0 ? (int)(v + 0.5f) : -(int)(-v + 0.5f));
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
            qa_prep_x(x + (size_t)t0 * w->cols, w->cols, nt, s, a->xbuf);
            for (int k = 1; k < QA_XCOPIES; k++)
                memcpy(a->xbuf + (size_t)k * QA_XB, a->xbuf, QA_XB);
            if (a->now)
                a->cpu_s += a->now() - c0;
            for (int l = 0; l < L; l++) {
                const double t1 = a->now ? a->now() : 0;
                a->launch((int8_t *)(w->data + s * slice_bytes + l * launch_bytes), a->xbuf, (int8_t *)a->ybuf);
                a->launches++;
                const double t2 = a->now ? a->now() : 0;
                if (a->ycached)
                    qw_dcache_invalidate((intptr_t)a->ybuf, QA_YB);
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
