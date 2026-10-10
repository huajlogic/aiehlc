/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * convgemm host logic -- shape-independent, target-independent.
 *
 * Plain C on purpose: it is #included by convgemm.cc (the aiehlc library,
 * where the tile function launches the AIE mesh) AND by the x86 verification
 * harness (where the tile function is a scalar loop). The same im2col, the
 * same tiling, the same accumulation and the same scatter run in both, so the
 * harness proves everything except the AIE tile itself.
 *
 * The caller defines, before including this file:
 *   CONVGEMM_TILE(a, b, c)  run ONE tile: c[TM][TN] = a[TM][TK] . b[TN][TK]^T
 *                           (int32, overwritten); returns 0 on success
 *   CONVGEMM_DMA_ALLOC(n)   allocate n bytes the tile may DMA from/to
 ******************************************************************************/
#ifndef AIETENSOROP_CONVGEMM_HOST_H
#define AIETENSOROP_CONVGEMM_HOST_H

#include "convgemm.h"
#include <stdlib.h>
#include <string.h>

static int8_t *cg_a_tile = 0;  /* [TM][TK] */
static int8_t *cg_b_tile = 0;  /* [TN][TK] */
static int32_t *cg_c_tile = 0; /* [TM][TN] */
static long cg_launches = 0;

static int cg_ensure_tiles(void) {
    if (cg_a_tile && cg_b_tile && cg_c_tile)
        return CONVGEMM_OK;
    cg_a_tile = (int8_t *)CONVGEMM_DMA_ALLOC((size_t)CONVGEMM_TM * CONVGEMM_TK);
    cg_b_tile = (int8_t *)CONVGEMM_DMA_ALLOC((size_t)CONVGEMM_TN * CONVGEMM_TK);
    cg_c_tile = (int32_t *)CONVGEMM_DMA_ALLOC((size_t)CONVGEMM_TM * CONVGEMM_TN * 4);
    return (cg_a_tile && cg_b_tile && cg_c_tile) ? CONVGEMM_OK : CONVGEMM_ERR_ALLOC;
}

/* Copy rows [r0, r0+rows) x cols [k0, k0+cols) of a row-major [*, ld] matrix
 * into a zero-filled [tr][tk] tile. Zero fill makes ragged edges exact: a zero
 * row/col contributes nothing to any dot product. */
static void cg_pack(int8_t *tile, int tr, int tk, const int8_t *src, int ld, int r0, int rows, int k0, int cols) {
    memset(tile, 0, (size_t)tr * tk);
    for (int r = 0; r < rows; r++)
        memcpy(tile + (size_t)r * tk, src + (size_t)(r0 + r) * ld + k0, (size_t)cols);
}

/* C[M,N] = A[M,K] . Bt[N,K]^T over the fixed AIE tile. K tiles accumulate in
 * int32 on the host: the AIE returns one tile's partial sum per launch. */
int convgemm_i8i32(const int8_t *A, const int8_t *Bt, int32_t *C, int M, int N, int K) {
    if (!A || !Bt || !C)
        return CONVGEMM_ERR_NULL_ARG;
    if (M <= 0 || N <= 0 || K <= 0)
        return CONVGEMM_ERR_GEOM;
    int rc = cg_ensure_tiles();
    if (rc != CONVGEMM_OK)
        return rc;
    for (int m0 = 0; m0 < M; m0 += CONVGEMM_TM) {
        const int mm = (M - m0 < CONVGEMM_TM) ? M - m0 : CONVGEMM_TM;
        for (int n0 = 0; n0 < N; n0 += CONVGEMM_TN) {
            const int nn = (N - n0 < CONVGEMM_TN) ? N - n0 : CONVGEMM_TN;
            for (int k0 = 0; k0 < K; k0 += CONVGEMM_TK) {
                const int kk = (K - k0 < CONVGEMM_TK) ? K - k0 : CONVGEMM_TK;
                cg_pack(cg_a_tile, CONVGEMM_TM, CONVGEMM_TK, A, K, m0, mm, k0, kk);
                cg_pack(cg_b_tile, CONVGEMM_TN, CONVGEMM_TK, Bt, K, n0, nn, k0, kk);
                rc = CONVGEMM_TILE(cg_a_tile, cg_b_tile, cg_c_tile);
                cg_launches++;
                if (rc != 0)
                    return rc;
                for (int i = 0; i < mm; i++) {
                    int32_t *dst = C + (size_t)(m0 + i) * N + n0;
                    const int32_t *src = cg_c_tile + (size_t)i * CONVGEMM_TN;
                    for (int j = 0; j < nn; j++)
                        dst[j] = (k0 == 0) ? src[j] : dst[j] + src[j];
                }
            }
        }
    }
    return CONVGEMM_OK;
}

long convgemm_launch_count(void) { return cg_launches; }

/* conv as GEMM.
 *   m = oy*ow + ox                                    (output pixel)
 *   n = occ*oc_block + ob                             (output channel)
 *   k = ((ky*kw + kx)*ic_chunk + icc)*ic_block + ib   (tap x input channel)
 * A[m][k] = ifm[icc][oy*sh+ky][ox*sw+kx][ib]
 * Bt[n][k] = wts[occ][icc][ky][kx][ib][ob]
 * acc[occ][oy][ox][ob] = C[m][n] */
int conv2d_nchwc_i8(const int8_t *ifm, const int8_t *wts, int32_t *acc, const convgemm_geom *g) {
    if (!ifm || !wts || !acc || !g)
        return CONVGEMM_ERR_NULL_ARG;
    if (g->oh != (g->ih - g->kh) / g->stride_h + 1 || g->ow != (g->iw - g->kw) / g->stride_w + 1)
        return CONVGEMM_ERR_GEOM;
    const int M = g->oh * g->ow;
    const int N = g->oc_chunk * g->oc_block;
    const int K = g->kh * g->kw * g->ic_chunk * g->ic_block;
    int8_t *A = (int8_t *)malloc((size_t)M * K);
    int8_t *Bt = (int8_t *)malloc((size_t)N * K);
    int32_t *C = (int32_t *)malloc((size_t)M * N * sizeof(int32_t));
    int rc = (A && Bt && C) ? CONVGEMM_OK : CONVGEMM_ERR_ALLOC;
    if (rc == CONVGEMM_OK) {
        const int icb = g->ic_block, icc_n = g->ic_chunk, ih = g->ih, iw = g->iw;
        for (int oy = 0; oy < g->oh; oy++)
            for (int ox = 0; ox < g->ow; ox++) {
                int8_t *row = A + (size_t)(oy * g->ow + ox) * K;
                for (int ky = 0; ky < g->kh; ky++)
                    for (int kx = 0; kx < g->kw; kx++)
                        for (int icc = 0; icc < icc_n; icc++) {
                            const int8_t *px =
                                ifm +
                                (((size_t)icc * ih + (oy * g->stride_h + ky)) * iw + (ox * g->stride_w + kx)) * icb;
                            memcpy(row + ((ky * g->kw + kx) * icc_n + icc) * icb, px, (size_t)icb);
                        }
            }
        const int ocb = g->oc_block;
        for (int occ = 0; occ < g->oc_chunk; occ++)
            for (int icc = 0; icc < icc_n; icc++)
                for (int ky = 0; ky < g->kh; ky++)
                    for (int kx = 0; kx < g->kw; kx++)
                        for (int ib = 0; ib < icb; ib++)
                            for (int ob = 0; ob < ocb; ob++) {
                                const size_t w =
                                    (((((size_t)occ * icc_n + icc) * g->kh + ky) * g->kw + kx) * icb + ib) * ocb + ob;
                                const int n = occ * ocb + ob;
                                const int k = ((ky * g->kw + kx) * icc_n + icc) * icb + ib;
                                Bt[(size_t)n * K + k] = wts[w];
                            }
        rc = convgemm_i8i32(A, Bt, C, M, N, K);
        if (rc == CONVGEMM_OK)
            for (int occ = 0; occ < g->oc_chunk; occ++)
                for (int m = 0; m < M; m++)
                    for (int ob = 0; ob < ocb; ob++)
                        acc[((size_t)occ * M + m) * ocb + ob] = C[(size_t)m * N + occ * ocb + ob];
    }
    free(A);
    free(Bt);
    free(C);
    return rc;
}

#endif /* AIETENSOROP_CONVGEMM_HOST_H */
