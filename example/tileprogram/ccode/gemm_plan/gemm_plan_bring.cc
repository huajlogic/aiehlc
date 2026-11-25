// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// Test entry: gemm_plan.cc with B forced through a MemTile FIFO ring (re-read per output tile).
#define GP_B_RING 2
#include "gemm_plan.cc"
