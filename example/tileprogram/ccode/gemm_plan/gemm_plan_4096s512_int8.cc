// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// One N-slice of the 4096^3 int8 GEMM: C[4096 x 512] = A[4096 x 4096] . B[512 x 4096]^T, 101 launches.
// 4096^3 runs as 8 such slices (N = 8 x 512): the host rebases the shim B / C BD addresses per slice.
// GP_KEEP false: B's whole 512 KiB slice is reloaded every launch (a new slice per call), as 2 chained
// MemTile BDs (a53ab35f). Knobs are #defines: EXTRA_DEFS reach only the host compile.
#define GP_M 4096
#define GP_N 512
#define GP_K 4096
#define GP_DTYPE 1
#define GP_LAUNCHES 101
#define GP_KEEP false
#include "gemm_plan.cc"
