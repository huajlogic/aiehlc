// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// gemm_plan.cc configured for C[4096 x 512] = A[4096 x 4096] . B[512 x 4096]^T, bf16, 101 persistent launches.
// The shape / dtype / launch knobs are set here, in the source, and not only as -D flags: the aiehlc front
// end (kernel analysis, x86 trace, dataflow plan) and the chess kernel compile read the source's #defines
// and do not receive EXTRA_DEFS (only the host compile does). Build with the same values as -D flags too:
//   run_board.sh --build-only example/tileprogram/ccode/gemm_plan/gemm_plan_4096x512x4096_bf16.cc <log> -DGP_M=4096 -DGP_N=512 -DGP_K=4096 -DGP_LAUNCHES=101 -DGP_DTYPE=2
#define GP_M 4096
#define GP_N 512
#define GP_K 4096
#define GP_DTYPE 2
#define GP_LAUNCHES 101
#include "gemm_plan.cc"
