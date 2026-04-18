/******************************************************************************
 * Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 *
 * AIE Programming Model — Matrix Multiplication with Data Caching
 *
 * GEMM: C[16x16] = A[16x16] * B^T[16x16], int8
 * Deployed on a HW_ROWS x HW_COLS AIE tile mesh.
 *
 * Current pipeline data distribution (row-based split, 4 groups):
 *   A[16x16]: split into 4 partitions of A[4x16]
 *     Group 0: A[0:3, :]   → broadcast to 4 tiles in row
 *     Group 1: A[4:7, :]   → broadcast to 4 tiles in row
 *     Group 2: A[8:11, :]  → broadcast to 4 tiles in row
 *     Group 3: A[12:15, :] → broadcast to 4 tiles in row
 *   B[16x16]: split into 4 partitions of B[4x16]
 *     Group 0: B[0:3, :]   → broadcast to 4 tiles in row
 *     Group 1: B[4:7, :]   → broadcast to 4 tiles in row
 *     Group 2: B[8:11, :]  → broadcast to 4 tiles in row
 *     Group 3: B[12:15, :] → broadcast to 4 tiles in row
 *
 * Each tile receives 4x16 A-partition + 4x16 B-partition via 2 DMA rounds:
 *   Round 0: A[0:1, 0:15] (32 bytes) + B[0:1, 0:15] (32 bytes)
 *   Round 1: A[2:3, 0:15] (32 bytes) + B[2:3, 0:15] (32 bytes)
 *
 * Kernel computes C_tile[4x4] = A_tile[4x16] * B_tile^T[4x16]
 *   C_tile[i][j] = sum_{k=0}^{15} A_tile[i][k] * B_tile[j][k]
 *
 * Data caching strategy (matches DMA ping-pong):
 *   Round 0: cache A0[2x16], B0[2x16], write partial C[0:1, 0:1] (8 bytes)
 *   Round 1: use cached + new data, compute full C[4x4], write C[2:3, :] (8 bytes)
 *
 * NOTE: With row-based split, tiles in same column produce redundant output
 * (same inputs). Host assembles them at different C offsets.
 *
 ******************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define M 16
#define K 16
#define N 16

// HW mesh dimensions (number of AIE tile rows and columns)
#define HW_ROWS 4
#define HW_COLS 4

// --- Tile dimensions derived from M, K, N, HW_ROWS, HW_COLS ---
#define ROWS_PER_ROUND ((M / HW_ROWS) / 2)       // 4: A/B rows per DMA round
#define COLS_PER_ROUND ((N / HW_COLS) / 2)       // 4: B rows per DMA round (= output cols of partial block)
#define OUT_STRIDE (N / HW_COLS)                 // 8: output row width (full tile cols)
#define K_DIM K                                  // 16: inner product dimension
#define BUF_SZ_OUT (ROWS_PER_ROUND * OUT_STRIDE) // 32: output bytes per round
// #define DEBUG_OUTPUT_ORDER 1

// ═══════════════════════════════════════════════════════════════════════════
// KERNEL: matmul
//
// Matches current MLIR pipeline infrastructure for 4x4 mesh:
//   - BUF_SZ = 8 (v4int8 units = 32 bytes) for ping-pong buffers
//   - 2 symmetric iterations: each iter does 1 input acquire + 1 output acquire
//   - Input: 32 bytes per acquire (2 rows x 16 cols int8)
//   - Output DMA BD len=2 (8 bytes transferred per cycle)
//
// Per-tile computation: C_tile[4x4] = A_tile[4x16] * B_tile^T[4x16]
//   C_tile[i][j] = sum_k A_tile[i][k] * B_tile[j][k]
//
// Iter 0: read A[0:1,:], B[0:1,:], cache both
//         write 8 bytes of output: C[0:1, 0:1] = A0 * B0^T (partial)
// Iter 1: read A[2:3,:], B[2:3,:], now have all 4 rows of A and B
//         compute C[2:3, 0:1] and C[2:3, 2:3] using cached + new data
//         write 8 bytes of output
// ═══════════════════════════════════════════════════════════════════════════
// Debug flag: when enabled, skip matmul and fill output with encoded tile ID.
// Each output byte = row[0:2] | col[3:5] | round[6:7]
// This lets you identify which tile and round produced each output byte.
#pragma aie_debug_level 2
//__global__ void matmul(aie::row_broadcast_in<input_window_int8 *>window_in_0,
//                       aie::col_broadcast_in<input_window_int8 *>window_in_1,
//                       aie::row_major_out<output_window_int8 *>window_out_0) {
__global__ void matmul(input_window_int8 *window_in_0, input_window_int8 *window_in_1,
                       output_window_int8 *window_out_0) {
#if DEBUG_OUTPUT_ORDER
    unsigned coreid = get_coreid();
    int col = coreid >> 16;
    int row = coreid & 0x1F;
    klog("DEBUG", 1);
    for (int round = 0; round < 2; round++) {
        int8_t *in0 = (int8_t *)acquire_input_window(window_in_0);
        int8_t *in1 = (int8_t *)acquire_input_window(window_in_1);
        int8_t *out = (int8_t *)acquire_output_window(window_out_0);

        // Encode: bits[0:2]=row, bits[3:5]=col, bits[6:7]=round
        int8_t tag = (int8_t)((row & 0x7) | ((col & 0x7) << 3) | ((round & 0x3) << 6));
        for (int i = 0; i < BUF_SZ_OUT; i++) {
            out[i] = tag;
        }

        release_output_window(window_out_0);
        release_input_window(window_in_0);
        release_input_window(window_in_1);
    }
#else
    // Local cache for round-0 data
    int8_t cache_A[ROWS_PER_ROUND * K_DIM];
    int8_t cache_B[ROWS_PER_ROUND * K_DIM];

    // ===== Iter 0: read A[0:1,:], B[0:1,:], cache, write partial output =====
    int8_t *A0 = (int8_t *)acquire_input_window(window_in_0);
    int8_t *B0 = (int8_t *)acquire_input_window(window_in_1);

    // Cache for use in iter 1
    for (int i = 0; i < ROWS_PER_ROUND * K_DIM; i++) {
        cache_A[i] = A0[i];
        cache_B[i] = B0[i];
    }

    // Write partial output: C[0:RPR-1, 0:CPR-1] = A0 * B0^T, cols CPR..OUT_STRIDE-1 = 0
    {
        int8_t *out = acquire_output_window(window_out_0);
        for (int i = 0; i < ROWS_PER_ROUND; i++) {
            for (int j = 0; j < COLS_PER_ROUND; j++) {
                int16_t sum = 0;
                for (int k = 0; k < K_DIM; k++) {
                    sum += (int16_t)A0[i * K_DIM + k] * (int16_t)B0[j * K_DIM + k];
                }
                if (sum > 127)
                    sum = 127;
                else if (sum < -128)
                    sum = -128;
                out[i * OUT_STRIDE + j] = (int8_t)sum;
            }
            for (int j = COLS_PER_ROUND; j < OUT_STRIDE; j++) {
                out[i * OUT_STRIDE + j] = 0;
            }
        }
        release_output_window(window_out_0);
    }

    release_input_window(window_in_0);
    release_input_window(window_in_1);

    // ===== Iter 1: read A[2:3,:], B[2:3,:], compute remaining output =====
    int8_t *A1 = (int8_t *)acquire_input_window(window_in_0);
    int8_t *B1 = (int8_t *)acquire_input_window(window_in_1);

    {
        int8_t *out = acquire_output_window(window_out_0);
        // C[RPR:2*RPR-1, 0:CPR-1] = A1 * cached_B0^T
        for (int i = 0; i < ROWS_PER_ROUND; i++) {
            for (int j = 0; j < COLS_PER_ROUND; j++) {
                int16_t sum = 0;
                for (int k = 0; k < K_DIM; k++) {
                    sum += (int16_t)A1[i * K_DIM + k] * (int16_t)cache_B[j * K_DIM + k];
                }
                if (sum > 127)
                    sum = 127;
                else if (sum < -128)
                    sum = -128;
                out[i * OUT_STRIDE + j] = (int8_t)sum;
            }
        }
        // C[RPR:2*RPR-1, CPR:2*CPR-1] = A1 * B1^T
        for (int i = 0; i < ROWS_PER_ROUND; i++) {
            for (int j = 0; j < COLS_PER_ROUND; j++) {
                int16_t sum = 0;
                for (int k = 0; k < K_DIM; k++) {
                    sum += (int16_t)A1[i * K_DIM + k] * (int16_t)B1[j * K_DIM + k];
                }
                if (sum > 127)
                    sum = 127;
                else if (sum < -128)
                    sum = -128;
                out[i * OUT_STRIDE + j + COLS_PER_ROUND] = (int8_t)sum;
            }
        }
        release_output_window(window_out_0);
    }

    release_input_window(window_in_0);
    release_input_window(window_in_1);
#endif
}

// ═══════════════════════════════════════════════════════════════════════════
// Verification
//
// scalar_matmul: pure C[M][N] = A[M][K] * B^T[N][K], completely independent
//   of pipeline topology, tile partitioning, or DMA layout.
//
// verify_matmul: computes full matmul, then maps tile outputs back to the
//   full result matrix for comparison, accounting for DMA layout.
//
// Pipeline data distribution (4x4 mesh, row-based split, 4 groups):
//   Group 0 (4 tiles): A[0:3,:] + B[0:3,:]   → 4 tiles produce redundant 4x4
//   Group 1 (4 tiles): A[4:7,:] + B[4:7,:]   → 4 tiles produce redundant 4x4
//   Group 2 (4 tiles): A[8:11,:] + B[8:11,:] → 4 tiles produce redundant 4x4
//   Group 3 (4 tiles): A[12:15,:] + B[12:15,:] → 4 tiles produce redundant 4x4
//
// Per-tile DMA output (16 bytes = 2 cycles of 8 bytes):
//   Cycle 0 (bytes 0-7): rows 0-1, cols 0-1 valid, cols 2-3 = 0
//   Cycle 1 (bytes 8-15): rows 2-3, cols 0-3 all valid
// ═══════════════════════════════════════════════════════════════════════════

// Pure scalar matmul: C_ref[M][N] = A[M][K] * B^T[N][K]
static void scalar_matmul(int8_t *C_ref, const int8_t *A, const int8_t *B) {
    for (int i = 0; i < M; i++) {
        for (int j = 0; j < N; j++) {
            int16_t sum = 0;
            for (int k = 0; k < K; k++)
                sum += (int16_t)A[i * K + k] * (int16_t)B[j * K + k];
            if (sum > 127)
                sum = 127;
            else if (sum < -128)
                sum = -128;
            C_ref[i * N + j] = (int8_t)sum;
        }
    }
}

// Verify AIE output C against CPU reference
static int verify_matmul(const int8_t *A, const int8_t *B, const int8_t *C) {
    // Compute full C_ref[16][16] = A * B^T — no pipeline knowledge
    int8_t C_ref[M * N];
    scalar_matmul(C_ref, A, B);

    // HW_ROWS x HW_COLS mesh, NUM_GROUPS row-groups of TILES_PER_GROUP tiles
    // Each group: tiles produce redundant sub-blocks
    // Group g: row_start = g*(M/HW_ROWS), col_start = g*(N/HW_COLS)
    // Tiles within a group are at consecutive offsets
    const int TILES_PER_GROUP = HW_COLS;
    const int NUM_GROUPS = HW_ROWS;
    const int TILE_ROWS = M / HW_ROWS;
    const int TILE_COLS = N / HW_COLS;
    const int TILE_OUT_SIZE = TILE_ROWS * TILE_COLS;

    int mismatches = 0;
    for (int g = 0; g < NUM_GROUPS; g++) {
        int rs = g * TILE_ROWS; // row start in full matrix
        int cs = g * TILE_COLS; // col start in full matrix

        for (int t = 0; t < TILES_PER_GROUP; t++) {
            int tile_idx = g * TILES_PER_GROUP + t;
            int base = tile_idx * TILE_OUT_SIZE;

            for (int i = 0; i < TILE_ROWS; i++) {
                for (int j = 0; j < TILE_COLS; j++) {
                    // DMA layout: cycle 0 rows 0-1 cols 2-3 are zero-filled
                    int8_t expected = (i < ROWS_PER_ROUND && j >= COLS_PER_ROUND) ? 0 : C_ref[(rs + i) * N + (cs + j)];
                    int flat = base + i * TILE_COLS + j;
                    if (C[flat] != expected) {
                        printf("MISMATCH C[%d] (group %d, tile %d, row %d, col %d): "
                               "got %d, expected %d\n",
                               flat, g, t, i, j, C[flat], expected);
                        mismatches++;
                    }
                }
            }
        }
    }

    int total_elements = NUM_GROUPS * TILES_PER_GROUP * TILE_OUT_SIZE;
    if (mismatches == 0)
        printf("PASS: all %d elements match.\n", total_elements);
    else
        printf("FAIL: %d mismatches out of %d.\n", mismatches, total_elements);

    // Print sample: group 0, tile 0
    printf("\nSample output C[0:%d][0:%d] (group 0, tile 0):\n", TILE_ROWS - 1, TILE_COLS - 1);
    for (int i = 0; i < TILE_ROWS; i++) {
        printf("  [");
        for (int j = 0; j < TILE_COLS; j++) {
            printf("%4d", C[i * TILE_COLS + j]);
            if (j < TILE_COLS - 1)
                printf(",");
        }
        printf("]\n");
    }

    // Print input A first TILE_ROWS rows
    printf("\nInput A[0:%d][0:%d]:\n", TILE_ROWS - 1, K - 1);
    for (int i = 0; i < TILE_ROWS; i++) {
        printf("  [");
        for (int j = 0; j < K; j++) {
            printf("%4d", A[i * K + j]);
            if (j < K - 1)
                printf(",");
        }
        printf("]\n");
    }

    // Print input B first TILE_ROWS rows
    printf("\nInput B[0:%d][0:%d]:\n", TILE_ROWS - 1, K - 1);
    for (int i = 0; i < TILE_ROWS; i++) {
        printf("  [");
        for (int j = 0; j < K; j++) {
            printf("%4d", B[i * K + j]);
            if (j < K - 1)
                printf(",");
        }
        printf("]\n");
    }

    return mismatches;
}

// ═══════════════════════════════════════════════════════════════════════════
// HOST
// ═══════════════════════════════════════════════════════════════════════════
int main() {
    printf("=== Matrix Multiply with Data Caching on AIE %dx%d Mesh ===\n", HW_ROWS, HW_COLS);
    printf("    C[%dx%d] = A[%dx%d] * B^T[%dx%d], int8\n", M, N, M, K, K, N);

    // --- Device + mesh ---
    aieSetDevice(0);
    aieDim mesh(HW_ROWS, HW_COLS);

    // --- Allocate host memory ---
    int8_t *A = (int8_t *)malloc(M * K * sizeof(int8_t));
    int8_t *B = (int8_t *)malloc(K * N * sizeof(int8_t));
    int8_t *C = (int8_t *)malloc(M * N * sizeof(int8_t));

    // --- Initialize input matrices ---
    for (int i = 0; i < M * K; i++)
        A[i] = (int8_t)((i % 7) - 3);

    for (int i = 0; i < K * N; i++)
        B[i] = (int8_t)((i % 5) - 2);

    for (int i = 0; i < M * N; i++)
        C[i] = 0;

    // --- Launch kernel on tile mesh ---
    matmul<<<mesh>>>(A, B, C);

    // --- Wait for completion ---
    aieDeviceSynchronize();

    // --- Verify output ---
    int result = verify_matmul(A, B, C);

    // --- Cleanup ---
    free(A);
    free(B);
    free(C);
    return result;
}
