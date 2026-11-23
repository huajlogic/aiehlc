/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * Host side of simplegemm_peak.cc: C[M][N] = A[M][K] . B[N][K]^T, int8 in,
 * int32 accumulation, the low byte of every sum out.
 *
 * Packing. Every core holds one 64-row block of A and of B for the whole launch
 * and feeds aie::mmul<8, 8, 8> from them with aligned 64-byte loads, so the host
 * stores each block in mmul operand order (the block's rows stay where they are
 * in the tensor; only the order of its bytes changes):
 *   A block: [mi][ki][8 m][8 k]   (8x8 M x K tiles, row-major)
 *   B block: [ni][ki][8 k][8 n]   (8x8 K x N tiles, row-major)
 * The core writes its C block tile by tile, [mi][ni][8 m][8 n]; gp_untile_c
 * puts it back in row-major order.
 ******************************************************************************/
#ifndef SIMPLEGEMM_PEAK_H
#define SIMPLEGEMM_PEAK_H

#include "unistd.h"
#include "xil_cache.h"
#include "xiltimer.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define GP_HW_ROWS 4
#define GP_HW_COLS 4

static inline uint32_t gp_mix32(uint32_t x) {
    x ^= x >> 16;
    x *= 0x7feb352dU;
    x ^= x >> 15;
    x *= 0x846ca68bU;
    x ^= x >> 16;
    return x;
}

static void gp_init(int8_t *A, int8_t *B, int m, int n, int k) {
    for (long i = 0; i < (long)m * k; i++)
        A[i] = (int8_t)(gp_mix32((uint32_t)i + 1234u) & 0xff);
    for (long i = 0; i < (long)n * k; i++)
        B[i] = (int8_t)(gp_mix32((uint32_t)i + 5678u) & 0xff);
}

// [rows][k] row-major -> blocks of `blk` rows in mmul operand order (see the file header).
// kn = 0: 8x8 tiles in (row, k) order -- the A operand; kn = 1: in (k, row) order -- the B operand.
static void gp_pack(const int8_t *src, int8_t *dst, int rows, int k, int blk, int kn) {
    const int kt = k / 8;
    for (int r0 = 0; r0 < rows; r0 += blk)
        for (int ti = 0; ti < blk / 8; ti++)
            for (int ki = 0; ki < kt; ki++)
                for (int a = 0; a < 8; a++)
                    for (int b = 0; b < 8; b++) {
                        const int r = r0 + ti * 8 + (kn ? b : a), kk = ki * 8 + (kn ? a : b);
                        dst[(long)r0 * k + (long)(ti * kt + ki) * 64 + a * 8 + b] = src[(long)r * k + kk];
                    }
}

// C as the cores wrote it -> row-major [m][n]. Core (pm, pn) fills its [cm][cn] block buffer tile by tile
// ([mi][ni][8][8]); the DMA puts block byte q at row pm * cm + q / cn, column pn * cn + q % cn.
static void gp_untile_c(const int8_t *Ct, int8_t *C, int m, int n) {
    const int cm = m / GP_HW_ROWS, cn = n / GP_HW_COLS;
    for (int pm = 0; pm < GP_HW_ROWS; pm++)
        for (int pn = 0; pn < GP_HW_COLS; pn++)
            for (int q = 0; q < cm * cn; q++) {
                const int t = q / 64, mi = t / (cn / 8), ni = t % (cn / 8), a = q % 64 / 8, b = q % 8;
                C[(long)(pm * cm + mi * 8 + a) * n + pn * cn + ni * 8 + b] =
                    Ct[(long)(pm * cm + q / cn) * n + pn * cn + q % cn];
            }
}

// Bit-exact check (low byte of each int32 sum); prints GOLDEN PASS / FAIL, returns the mismatch count.
static long gp_verify(const int8_t *A, const int8_t *B, const int8_t *C, int m, int n, int k) {
    long mismatches = 0;
    for (int i = 0; i < m; i++)
        for (int j = 0; j < n; j++) {
            int acc = 0;
            for (int q = 0; q < k; q++)
                acc += A[(long)i * k + q] * B[(long)j * k + q];
            const int8_t want = (int8_t)acc, got = C[(long)i * n + j];
            if (got != want && ++mismatches <= 16)
                printf("MISMATCH C[%d][%d]: got %d, expected %d\n", i, j, got, want);
        }
    if (mismatches == 0)
        printf("GOLDEN PASS: all %ld output elements match.\n", (long)m * n);
    else
        printf("GOLDEN FAIL: %ld mismatches out of %ld.\n", mismatches, (long)m * n);
    return mismatches;
}

static double gp_ms(XTime t0, XTime t1) { return t1 > t0 ? 1000.0 * (double)(t1 - t0) / COUNTS_PER_SECOND : 0.0; }

#endif // SIMPLEGEMM_PEAK_H
