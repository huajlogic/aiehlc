// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// bf16 variant of gemm_plan_4096s512_int8.cc: C[4096 x 512] = A[4096 x 4096] . B[512 x 4096]^T, 101
// launches, one N-slice of 4096^3. B's slice is 1 MiB (> one MemTile), so B goes through the MemTile
// ring (GP_B_RING default 4) and is reloaded every launch.
#define GP_M 4096
#define GP_N 512
#define GP_K 4096
#define GP_DTYPE 2
#define GP_LAUNCHES 101
#define GP_KEEP false
#include "gemm_plan.cc"
