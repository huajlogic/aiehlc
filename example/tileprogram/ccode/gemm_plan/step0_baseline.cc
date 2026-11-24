/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
// tutorial/perfoptmize step 0: the baseline -- a kernel-only GEMM with scalar MACs and no options at all.
// Everything else (windows, BDs, routes, the per-launch kernel load) is what the compiler derives.
#define GEN_VECTOR 0
#define GEN_LAUNCH 0
#define GEN_ITERS 2
#include "gemm_generic_body.cc"
