// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// gemm_plan.cc configured with the M3.3.6.2.1.2.3.1 FEAS_PICK tile (costmodel/m3362123_feas.txt): C[12288 x 768] =
// A[12288 x 2048] . B[768 x 2048]^T, int8, 2 x 8 neighbour-shared operands, core tile 96 x 96 (6 x 6 accumulator
// pairs). FEAS_PICK has K chunks of 32 and one output buffer ({.depth = 1}); this base (ee041f8a) refuses
// {.depth = 1} on aie::store_buffer (kernel_trace.cpp checkBlockOpts; accepted from 015dbd32 on the m336 line,
// kernel-only outputs only), so the tile is built with the ping-pong output and K chunks of 16 instead: core
// DM budget 4096 (stack + runtime, ASSUMED) + 36864 (int32 partial sums) + 6144 (2 input streams x 2 slots x
// 96 x 16) + 18432 (2 output tiles) = 65536 B <= 64 KiB (no slack). 64 tiles / core, A ring 8, 128 chunks / tile.
// The tile knobs live in gemm_plan_tile.h. Set here, in the source, and as
// -D flags (the front end and the chess kernel compile read the source's #defines, not EXTRA_DEFS):
//   run_board.sh --build-only example/tileprogram/ccode/gemm_plan/gemm_plan_s64t_int8.cc <log> -DGP_M=12288 -DGP_N=768 -DGP_K=2048 -DGP_LAUNCHES=8 -DGP_TM=96 -DGP_TN=96 -DGP_KC=16 -DGP_C_DEPTH=2 -DGP_DM_FIXED_T=4096
#define GP_M 12288
#define GP_N 768
#define GP_K 2048
#define GP_DTYPE 1
#define GP_LAUNCHES 8
#define GP_TM 96
#define GP_TN 96
#define GP_KC 16
#define GP_C_DEPTH 2
#define GP_DM_FIXED_T 4096
#include "gemm_plan.cc"
