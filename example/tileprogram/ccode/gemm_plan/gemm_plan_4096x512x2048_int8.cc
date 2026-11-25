// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// Test entry: int8 C[4096 x 512] = A[4096 x 2048] . B^T -- B (256 KiB per column) held in the MemTiles.
#define GP_M 4096
#define GP_N 512
#define GP_K 2048
#define GP_DTYPE 1
#define GP_LAUNCHES 21
#include "gemm_plan.cc"
