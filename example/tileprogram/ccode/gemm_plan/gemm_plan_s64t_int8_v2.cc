// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// gemm_plan_s64t_int8.cc variant for M3.3.6.2.1.2.4.1 fix96_inner (phase PV, build-only): V2 kc32 cdepth1, GT_CHUNK_P (chunk kind specialised, k blocks flattened, pair columns pipelined)
// C[12288 x 768] = A[12288 x 2048] . B[768 x 2048]^T int8, core tile 96 x 96, K chunks of 32, output {.depth = 1},
// chunk kernel GP_GT 1 (gemm_plan_tbody.cc / gemm_plan_tile.h). The default configs are untouched.
//   run_board.sh --build-only example/tileprogram/ccode/gemm_plan/gemm_plan_s64t_int8_v2.cc <log> -DGP_M=12288 -DGP_N=768 -DGP_K=2048 -DGP_LAUNCHES=8 -DGP_TM=96 -DGP_TN=96 -DGP_KC=32 -DGP_C_DEPTH=1 -DGP_GT=1 -DGP_DM_FIXED=4096
#define GP_M 12288
#define GP_N 768
#define GP_K 2048
#define GP_DTYPE 1
#define GP_LAUNCHES 8
#define GP_TM 96
#define GP_TN 96
#define GP_KC 32
#define GP_C_DEPTH 1
#define GP_GT 1
#define GP_DM_FIXED 4096
// the pragmas of gemm_plan.cc
#pragma aie_debug_level(AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN)
#pragma control_plan_op_control_packet
#pragma control_packet_mode(aot)
#pragma KERNELCONFIGOFFLOAD
#pragma output_tile_major
#pragma persistent_kernel
#include "gemm_plan_tbody.cc"
