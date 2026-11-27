// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// gemm_plan.cc with the tiling chosen by the compiler: the shape and dtype come from the build
//   source script/aiehlc.sh --aie-version 5 --runtime-source-file
//   $PWD/example/tileprogram/ccode/gemm_plan/gemm_plan_auto.cc \
//       --define GP_M=4096 --define GP_N=1024 --define GP_K=2560 --define GP_DTYPE=1
// and #pragma gemm_autotile picks the mesh (rows x columns) and A's MemTile ring with its cost model
// (src/llvm/convautotile/gemm_autotile.cpp: cores, shim channels, DDR; build log "[GemmAutoTile]"), the
// dataflow plan stages B by MemTile capacity. Board: #pragma gemm_autotile(VEK385_2) or AIEHLC_GEMM_BOARD.
#pragma gemm_autotile
#include "gemm_plan.cc"
