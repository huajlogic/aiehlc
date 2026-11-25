// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// PROBE, expected to be refused: 4096^3 int8 as ONE gemm_plan program (N = 4096). 2 x 8 layout gives
// SH_NT2 = 8 and SH_TILES = 256 tiles / core > 64 (6-bit OOO iteration counter): gemm_plan_body.cc
// static_asserts refuse it. 4096^3 runs as 8 N-slices instead (gemm_plan_4096s512_int8.cc).
#define GP_M 4096
#define GP_N 4096
#define GP_K 4096
#define GP_DTYPE 1
#define GP_LAUNCHES 101
#include "gemm_plan.cc"
