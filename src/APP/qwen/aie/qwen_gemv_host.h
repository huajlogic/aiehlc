/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * Host side of qwen_gemv.cc: a self test of one launch (4096 rows x 4096 K, M = 4) against the
 * scalar reference (the math of qw_matmul_cpu), with timing. The kernel uses none of it.
 ******************************************************************************/
#ifndef QWEN_GEMV_HOST_H
#define QWEN_GEMV_HOST_H
#include "xil_cache.h"
#include "xiltimer.h"
#include "xtimer_config.h"
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void __Runtime_ctrl_high_throughput_enable(int on);
void __Runtime_ctrl_pmap_enable(int on);
void *__Runtime_alloc_uncached(size_t bytes);
// w / x laid out in DDR in the order the plan's shim BDs stream them (generated into aiehlc_plan.h)
#if __has_include("aiehlc_plan.h")
#include "aiehlc_plan.h"
#else
void aiehlc_plan_arrange(int arg, const void *src, void *dst);
#endif

#define QGH_K 4096
#define QGH_M 4
#define QGH_ROWS 4096
#define QGH_CB 8704
#define QGH_WBYTES ((size_t)QGH_ROWS / 16 * (QGH_K / 1024) * QGH_CB)
#define QGH_XB (QGH_M * QGH_K + QGH_M * (QGH_K / 64) * 4)

static uint32_t qgh_rng(uint32_t *s) {
    *s ^= *s << 13, *s ^= *s >> 17, *s ^= *s << 5;
    return *s;
}

static float qgh_bf16(const uint8_t *p) {
    uint32_t u = (uint32_t)p[1] << 24 | (uint32_t)p[0] << 16;
    float f;
    memcpy(&f, &u, 4);
    return f;
}

/* x layout: two halves of 32 K groups, each [32][4][M][16] int8 then [32][M] fp32 scales */
static int8_t *qgh_xt(int8_t *xb, int g) { return xb + (g / 32) * 8704 + (g % 32) * 256; }
static float *qgh_xs(int8_t *xb, int g) { return (float *)(xb + (g / 32) * 8704 + 8192) + (g % 32) * QGH_M; }

/* reference: y[m][row] for M tokens (w as logical chunks [rb][kc][8704]), the kernel's math in the same order */
static void qgh_ref(const uint8_t *w, int8_t *xb, float *y) {
    for (int rb = 0; rb < QGH_ROWS / 16; rb++)
        for (int m = 0; m < QGH_M; m++)
            for (int n = 0; n < 16; n++) {
                float acc = 0;
                for (int g = 0; g < QGH_K / 64; g++) {
                    const uint8_t *ch = w + ((size_t)rb * 4 + g / 16) * QGH_CB, *wt = ch + (g % 16) * 512;
                    int32_t d = 0;
                    for (int k = 0; k < 64; k++) {
                        const int e = (k % 16) * 16 + n, b = wt[(k / 16) * 128 + e / 2];
                        const int v = (e & 1) ? (b >> 4) : (b & 15);
                        d += (v >= 8 ? v - 16 : v) * qgh_xt(xb, g)[(k / 16) * 64 + m * 16 + k % 16];
                    }
                    acc += (float)d * (qgh_bf16(ch + 8192 + (g % 16) * 32 + 2 * n) * qgh_xs(xb, g)[m]);
                }
                y[(size_t)m * QGH_ROWS + rb * 16 + n] = acc;
            }
}

static int qg_selftest(void (*run)(int8_t *, int8_t *, int8_t *)) {
    uint8_t *w = (uint8_t *)malloc(QGH_WBYTES), *wl = (uint8_t *)malloc(QGH_WBYTES);
    uint8_t *wd = (uint8_t *)__Runtime_alloc_uncached(QGH_WBYTES); /* the plan's stream order */
    int8_t *x = (int8_t *)malloc(QGH_XB), *xd = (int8_t *)__Runtime_alloc_uncached(4 * QGH_XB); /* x per column */
    int8_t *y = (int8_t *)__Runtime_alloc_uncached((size_t)QGH_ROWS * QGH_M * 4);
    float *ref = (float *)malloc((size_t)QGH_ROWS * QGH_M * 4);
    uint32_t s = 12345;
    for (size_t i = 0; i < QGH_WBYTES; i++) /* logical chunks wl[rb][kc][8704] */
        wl[i] = (uint8_t)qgh_rng(&s);
    for (size_t c = 0; c < QGH_WBYTES / QGH_CB; c++) /* sane bf16 scales: 2^-7 .. 2^-6 */
        for (int j = 0; j < 256; j++) {
            const uint32_t m7 = qgh_rng(&s) & 0x7F;
            wl[c * QGH_CB + 8192 + 2 * j] = (uint8_t)m7;
            wl[c * QGH_CB + 8192 + 2 * j + 1] = (uint8_t)(0x3C); /* exponent 120: 2^-7 x (1 + m/128) */
        }
    memcpy(w, wl, QGH_WBYTES); /* the kernel takes the chunks as they are: w[row block][k chunk][8704] */
    for (int g = 0; g < QGH_K / 64; g++) {
        for (int i = 0; i < 4 * QGH_M * 16; i++)
            qgh_xt(x, g)[i] = (int8_t)(qgh_rng(&s) % 255 - 127);
        for (int m = 0; m < QGH_M; m++)
            qgh_xs(x, g)[m] = 0.001f * (1 + (int)(qgh_rng(&s) % 100));
    }
    qgh_ref(wl, x, ref);
    aiehlc_plan_arrange(0, w, wd);
    aiehlc_plan_arrange(1, x, xd);
    const int launches = 8;
    double first = 0, best = 1e9, sum = 0;
    for (int it = 0; it < launches; it++) {
        memset(y, 0, (size_t)QGH_ROWS * QGH_M * 4);
        XTime t0, t1;
        XTime_GetTime(&t0);
        run((int8_t *)wd, xd, y);
        XTime_GetTime(&t1);
        const double ms = (double)(t1 - t0) * 1000.0 / COUNTS_PER_SECOND;
        printf("[qwen_gemv] launch %d: %.3f ms\n", it, ms);
        if (it == 0)
            first = ms;
        else
            sum += ms, best = ms < best ? ms : best;
    }
    /* y is [row block][M][16] (store order); reference [M][row] */
    const float *yf = (const float *)y;
    double maxe = 0, maxr = 0;
    long bad = 0;
    for (int rb = 0; rb < QGH_ROWS / 16; rb++)
        for (int m = 0; m < QGH_M; m++)
            for (int n = 0; n < 16; n++) {
                const float a = yf[((size_t)rb * QGH_M + m) * 16 + n], r = ref[(size_t)m * QGH_ROWS + rb * 16 + n];
                const double e = fabs((double)a - r), rel = e / (fabs(r) + 1e-3);
                maxe = e > maxe ? e : maxe;
                if (rel > 1e-3)
                    bad++;
                maxr = rel > maxr ? rel : maxr;
            }
    const double gbs = (double)QGH_WBYTES / (best * 1e6);
    printf("PERF SUMMARY qwen_gemv first %.3f ms, steady %.3f ms mean, best %.3f ms (%.2f GB/s of int4 weights)\n",
           first, sum / (launches - 1), best, gbs);
    printf("GOLDEN %s: qwen_gemv %d x %d x M=%d, max abs err %.4g, max rel %.3g, %ld outside 1e-3\n",
           bad ? "FAIL" : "PASS", QGH_ROWS, QGH_K, QGH_M, maxe, maxr, bad);
    return bad ? 1 : 0;
}
#endif
