// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// The same shared-operand GEMM on a 4 x 2 mesh (logical 2 x 4 grid): only the mesh width changes; the
// dataflow plan the compiler synthesizes from the kernel's blocks adapts -- each A strip's MemTile ring
// serves both chunk parities (two MM2S channels, a lock pair per parity) because there are not two
// columns per strip, B replays per column as before, and the host lays A / B out with the generated
// aiehlc_plan_arrange.
#define GP_HW_COLS 2
#define GP_N 256 // 2 x 8 strips on 2 columns: N = 2 x 2 x 64
#include "gemm_plan.cc"
