// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// gemm_plan.cc configured for C[4096 x 512] = A[4096 x 4096] . B[512 x 4096]^T, int8, 101 persistent launches.
// The knobs are set here so the file builds as it is; the same build from gemm_plan.cc alone:
//   source script/aiehlc.sh --aie-version 5 --runtime-source-file $PWD/example/tileprogram/ccode/gemm_plan/gemm_plan.cc
//   \
//       --define GP_M=4096 --define GP_N=512 --define GP_K=4096 --define GP_DTYPE=1 --define GP_LAUNCHES=101
// (--define reaches the front end, the x86 trace, the dataflow plan and both compiles; EXTRA_DEFS only the
// host compile, and it is refused for these macros).
#define GP_M 4096
#define GP_N 512
#define GP_K 4096
#define GP_DTYPE 1
#define GP_LAUNCHES 101
#include "gemm_plan.cc"
