/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * convgemm -- one int8 GEMM tile on the AIE mesh, as a static library.
 *
 *   C[TM, TN] int32 = A[TM, TK] int8 . Bt[TN, TK]^T int8      (TM,TN,TK = 256,64,256)
 *
 * Built ONCE with aiehlc (library mode, no main()) and shared by every
 * offloaded conv layer: convgemm_host.h tiles any conv/GEMM onto this one
 * tile shape on the host. See convgemm.h for the API and the reasoning, and
 * src/frontend/tvmrelay/tutorial/index.html section "Many conv shapes".
 *
 * Kernel structure is example/tileprogram/ccode/simplematmul2.cc's matmul
 * (A row-broadcast, B col-broadcast, output gathered left-to-right, K in
 * on-core accumulation rounds) with two changes:
 *   * int32 accumulator -- an int16 one wraps on real ResNet weights;
 *   * int32 OUTPUT, carried as 4 little-endian bytes per element through the
 *     same int8 window, so C is a [TM, 4*TN] byte matrix on the DMA side.
 ******************************************************************************/
// Do not spell the kernel-annotation keyword or the triple-angle launch syntax
// in any comment in this file: aiehlc's source rewriter matches both as text
// (skills aiesourcetextrewrite, aiehlcincludekernel).
#include "unistd.h"
#include "xil_cache.h"
#include "xiltimer.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#pragma aie_debug_level(0 | AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN)

// Kernel-visible geometry: bare literals (the kernel TU sees only #defines
// written in this file, never convgemm.h).
//
// The DESCRIPTORS are byte-for-byte example/tileprogram/ccode/simplematmul2.cc
// (M = N = K = 256, 16-row tiles, K in 64-byte rounds, int8 C tiles of 16x16
// per core). That configuration is proven; the first convgemm (N = 64 with a
// 4x-wide int32 C port) made aiehlc derive buffer sizes that disagreed with the
// generated windows (buf_sz_b 4096 vs a 256-byte window) and the shim DMA hung
// on the board (wait_io TIMEOUT). So int32 is carried INSIDE the proven int8
// layout instead of widening it:
//
//   * the host replicates each real output channel r into 4 virtual B rows
//     4r..4r+3 (TN_V = 4 * TN = 256 virtual rows);
//   * for virtual column 4r+b the kernel stores BYTE b of acc(m, r);
//   * so C row m, read as bytes 4r..4r+3, IS acc(m, r) little-endian, and the
//     host reads C as int32[TM][TN] directly.
// The dot product is computed once per group of 4 (j % 4 == 0).
#define TM 256   // A rows per launch
#define TN 64    // real output channels per launch
#define TN_V 256 // virtual B rows = 4 bytes x TN
#define TK 256   // reduction depth per launch
#define HW_ROWS 4
#define HW_COLS 4

constexpr aie::GemmSpace RowBA = {.policy = {.map = {.act = aie::Pattern::Broadcast, .layout = aie::Layout::Row},
                                             .mat = {.pad = aie::PadMaterialize::DDR, .im2col = aie::Im2col::None},
                                             .sched = {.pp_depth = 2, .l1_budget = aie::Bytes{4096}}},
                                  .d1 = {.fullsize = TM, .tile_size = 16, .stride = 16},
                                  .d2 = {.fullsize = TK, .tile_size = 64, .stride = 64}};
constexpr aie::GemmSpace ColBB = {.policy = {.map = {.wgt = aie::Pattern::Broadcast, .layout = aie::Layout::Col},
                                             .mat = {.pad = aie::PadMaterialize::DDR, .im2col = aie::Im2col::None},
                                             .sched = {.pp_depth = 2, .l1_budget = aie::Bytes{4096}}},
                                  .d1 = {.fullsize = TN_V, .tile_size = 16, .stride = 16},
                                  .d2 = {.fullsize = TK, .tile_size = 64, .stride = 64}};
constexpr aie::GemmSpace LtoR_Merge = {
    .policy = {.map = {.layout = aie::Layout::Row, .merge_order = aie::Flow::LeftToRight},
               .mat = {.pad = aie::PadMaterialize::DDR, .im2col = aie::Im2col::None},
               .sched = {.pp_depth = 2, .l1_budget = aie::Bytes{4096}}},
    .d1 = {.fullsize = TM, .tile_size = 16, .stride = 16},
    .d2 = {.fullsize = TN_V, .tile_size = 16, .stride = 16}};

constexpr aie::GlobalPolicy gemm_i8i32_policy = {.fullconnect_auto = 1};
__global__(gemm_i8i32_policy) void gemm_i8i32(aie::port<input_window_int8 *, RowBA> win_a,
                                              aie::port<input_window_int8 *, ColBB> win_b,
                                              aie::port<output_window_int8 *, LtoR_Merge> win_c) {
    const int k_rounds = aie::get_arg_total_rounds_in_dim(1, win_a);
    const int eff_k = aie::get_arg_per_round_size_in_dim(1, win_a);
    const int num_a_rounds = aie::get_num_rounds(win_a);
    const int num_b_rounds = aie::get_num_rounds(win_b);
    const int num_c_rounds = aie::get_num_rounds(win_c);
    const int buf_sz_a = aie::get_buffer_size(win_a);
    const int buf_sz_b = aie::get_buffer_size(win_b);
    const int buf_sz_c = aie::get_buffer_size(win_c);
    const int m_rounds = aie::get_spatial_multiple_rounds(win_a);
    const int n_rounds = aie::get_spatial_multiple_rounds(win_b);
    const int tile_rows = aie::get_arg_per_round_size_in_dim(0, win_a);
    const int tile_cols = aie::get_arg_per_round_size_in_dim(0, win_b);
    const int cols_per_round = buf_sz_b / eff_k;

    int8_t all_A[tile_rows * eff_k];
    int32_t accum[tile_rows * tile_cols];

    for (int mr = 0; mr < m_rounds * n_rounds; mr++) {
        for (int i = 0; i < tile_rows * tile_cols; i++)
            accum[i] = 0;

        // K rounds: accumulate partial products in int32. Virtual columns
        // 4r+1..4r+3 repeat 4r, so only every 4th is computed.
        for (int kr = 0; kr < k_rounds; kr++) {
            for (int ra = 0; ra < num_a_rounds; ra++) {
                int8_t *A_ptr = (int8_t *)acquire_input_window(win_a);
                for (int i = 0; i < buf_sz_a; i++)
                    all_A[ra * buf_sz_a + i] = A_ptr[i];
                release_input_window(win_a);
            }
            for (int rb = 0; rb < num_b_rounds; rb++) {
                int8_t *B_ptr = (int8_t *)acquire_input_window(win_b);
                for (int i = 0; i < tile_rows; i++) {
                    for (int j = 0; j < cols_per_round; j++) {
                        const int col = rb * cols_per_round + j;
                        if (col & 3)
                            continue;
                        int32_t sum = 0;
                        for (int k = 0; k < eff_k; k++)
                            sum += (int32_t)all_A[i * eff_k + k] * (int32_t)B_ptr[j * eff_k + k];
                        accum[i * tile_cols + col] += sum;
                    }
                }
                release_input_window(win_b);
            }
        }

        // Virtual column j carries byte (j & 3) of the int32 at column j & ~3.
        const int rows_per_c_round = buf_sz_c / tile_cols;
        for (int rc = 0; rc < num_c_rounds; rc++) {
            int8_t *out = (int8_t *)acquire_output_window(win_c);
            for (int i = 0; i < rows_per_c_round; i++) {
                const int row = rc * rows_per_c_round + i;
                for (int j = 0; j < tile_cols; j++) {
                    const uint32_t v = (uint32_t)accum[row * tile_cols + (j & ~3)];
                    out[i * tile_cols + j] = (int8_t)((v >> (8 * (j & 3))) & 0xFF);
                }
            }
            release_output_window(win_c);
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// HOST. Header and host logic come AFTER the kernel definition, so the kernel
// is registered before the frontend sees any declaration on the launch path
// (skill aiesourcetextrewrite: a prototype above the kernel -> empty module).
// ═══════════════════════════════════════════════════════════════════════════
#include "convgemm.h"

static_assert(TM == CONVGEMM_TM && TN == CONVGEMM_TN && TK == CONVGEMM_TK,
              "convgemm.cc tile out of sync with convgemm.h");

void *__Runtime_Alloc(size_t bytes);

// The ONE launch site. aiehlc recovers the mesh from the function-local
// device.partition VarDecl, so it must live in the same function as the launch.
static int cg_tile_run(const int8_t *a, const int8_t *b, int32_t *c) {
    aieSetDevice(0);
    aieArray device;
    aieMesh mesh = device.partition({3, 6, 0, 6}, HW_ROWS, HW_COLS);
    gemm_i8i32<<<mesh>>>((int8_t *)a, (int8_t *)b, (int8_t *)c, TM, TN_V, TK);
    // The generated launch flushes a/b/c BEFORE the DMA but does nothing after.
    // c is reused by every launch, and lines the CPU speculatively refetched
    // while the DMA ran would be read stale: measured on the board as ~4% wrong
    // outputs once a GEMM needs more than one launch (one launch was exact).
    // Invalidate c so the host reads what the S2MM DMA wrote.
    device.synchronizecpu(c, (size_t)TM * TN_V);
    return 0;
}

#define CONVGEMM_TILE(a, b, c) cg_tile_run((a), (b), (c))
#define CONVGEMM_BREP 4 /* B rows replicated per real channel (see the kernel) */
#define CONVGEMM_DMA_ALLOC(n) __Runtime_Alloc(n)
#include "convgemm_host.h"
