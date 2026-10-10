/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * convgemm -- the BASIC OP behind every non-stem ResNet-18 conv offload.
 *
 * One fixed-shape int8 x int8 -> int32 GEMM tile runs on the AIE mesh
 * (CONVGEMM_TM x CONVGEMM_TN x CONVGEMM_TK per launch). Everything shape-
 * dependent lives on the host: NCHWc im2col, splitting an arbitrary
 * [M,N,K] problem into tiles, int32 accumulation across K tiles, and the
 * scatter back to TVM's NCHWc accumulator layout. So ONE aiehlc build serves
 * every conv geometry in the network -- 3x3 or 1x1, stride 1 or 2, 64..512
 * channels -- instead of one hand-tiled kernel per fused op (contrast
 * conv2dstem, which is exactly that, for one hot layer).
 *
 * What it returns is the RAW convolution accumulator. The fused epilogue TVM
 * attached to the conv (bias, zero-points, requantize, residual add, clip ...)
 * is NOT here: the frontend runs TVM's own generated C for it on that
 * accumulator (frontend/tvmrelay/aie_conv_lib.py), so every constant stays
 * TVM's and nothing has to be hand-transcribed per layer.
 ******************************************************************************/
#ifndef AIETENSOROP_CONVGEMM_H
#define AIETENSOROP_CONVGEMM_H

#include <stdint.h>

/* The AIE tile: one launch computes C[TM,TN] (+)= A[TM,TK] . Bt[TN,TK]^T.
 * Must match TM/TN/TK in convgemm.cc (static_assert'ed there). */
#define CONVGEMM_TM 256
#define CONVGEMM_TN 64
#define CONVGEMM_TK 256

#define CONVGEMM_OK 0
#define CONVGEMM_ERR_NULL_ARG (-1)
#define CONVGEMM_ERR_ALLOC (-2)
#define CONVGEMM_ERR_GEOM (-3)

/* Geometry of one NCHWc convolution, in TVM's packed layouts:
 *   ifm  int8  [1, ic_chunk, ih, iw, ic_block]          already spatially padded
 *   wts  int8  [oc_chunk, ic_chunk, kh, kw, ic_block, oc_block]   (OIHW{i}i{o}o)
 *   acc  int32 [1, oc_chunk, oh, ow, oc_block]          raw accumulator, no epilogue
 * Padding is NOT a parameter: TVM materializes it (with the zero-point) in the
 * producer, so oh = (ih - kh) / stride_h + 1. */
typedef struct {
    int ic_chunk, ic_block, ih, iw;
    int oc_chunk, oc_block, kh, kw;
    int stride_h, stride_w, oh, ow;
} convgemm_geom;

#ifdef __cplusplus
extern "C" {
#endif

/* acc = conv(ifm, wts). Returns CONVGEMM_OK or a negative CONVGEMM_ERR_*. */
int conv2d_nchwc_i8(const int8_t *ifm, const int8_t *wts, int32_t *acc, const convgemm_geom *g);

/* C[M,N] = A[M,K] . Bt[N,K]^T, int32, any M/N/K (tiled over the AIE tile). */
int convgemm_i8i32(const int8_t *A, const int8_t *Bt, int32_t *C, int M, int N, int K);

/* Launches issued since start-up -- for logs and the tutorial's cost model. */
long convgemm_launch_count(void);

#ifdef __cplusplus
}
#endif

#endif /* AIETENSOROP_CONVGEMM_H */
