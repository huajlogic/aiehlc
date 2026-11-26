/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
// qwen small-M int4 GEMM on the 4 x 4 mesh: one launch is y[4096 rows][M] = W[4096 x 4096] . x[M x 4096]
// with W in the qwen blob's Q4G64 layout (src/aietensorop/qwen/engine/qwen_blob.h): per row block of 16 rows,
// 4 chunks of 16 K-groups (64 K each), a chunk = 16 x 512 B int4 tiles then 16 x 32 B bf16 row scales.
// Core c (mesh row-major) owns row blocks c * QG_U .. c * QG_U + QG_U - 1: its weights are one contiguous
// range, streamed once. x (M tokens, int8 per 64 with a float scale) is held by every core, in two halves of
// 32 K groups each: int8 tiles [32 groups][4][M][16] (8192 B), then the scales [32 groups][M] fp32 (512 B).
// y per row block: [M][16] fp32. The math is qw_matmul_cpu's: per group int32 sum, times w_scale x x_scale.
// The qwen_gemv kernel and its launch function, no main(): aiehlc archives it as libqwen_gemv_lib.a, which the
// qwen board app links (src/aietensorop/qwen/board/build_aie.sh).
#include "qwen_gemv_host.h"
#include "qwen_gemv_kernel.cc"
