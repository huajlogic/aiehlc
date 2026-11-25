// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// gemm_plan.cc defaults (NB: C[7680 x 512] = A[7680 x 2560] . B[512 x 2560]^T, int8) with 101 persistent
// launches (launch 1 loads the kernel; the median is taken over launches 2..101). Knobs are #defines in
// the source: EXTRA_DEFS reach only the host compile (see gemm_plan_4096x512x4096_int8.cc:5-7).
#define GP_LAUNCHES 101
#include "gemm_plan.cc"
