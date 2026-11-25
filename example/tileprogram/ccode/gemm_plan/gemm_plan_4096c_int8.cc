// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// 4096^3 int8 GEMM on the NB gemm_plan route as N-slices (m3362124221 P2): C[4096 x 4096] = A[4096 x 4096] .
// B[4096 x 4096]^T, 101 launches. The kernel is one 4096 x 512 x 4096 slice (gemm_plan.cc, GP_KEEP false); the
// dataflow plan runs it as GP_N_SLICES slices (#pragma dataflow_slices): call i of the generated host function
// serves slice i % 8 and rebases the shim BDs of B (arg 1, by its 2 MiB slice) and C (arg 2, by its 512 B column
// block) with __Runtime_shim_bd_set_addr; C's shim S2MM BD walks the rows at ldc = 4096 B, so C lands row-major.
// One launch = 8 calls (gemm_plan_slices.cc). Knobs are #defines: EXTRA_DEFS reach only the host compile.
#define GP_M 4096
#define GP_N 512
#define GP_K 4096
#define GP_DTYPE 1
#define GP_LAUNCHES 101
#define GP_KEEP false
#define GP_N_SLICES 8
#pragma dataflow_slices(8, 1, 2)
#include "gemm_plan_slices.cc"
