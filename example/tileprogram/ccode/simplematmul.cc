/******************************************************************************
 * Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 *
 * AIE Programming Model — Matrix Multiplication with Receive-First Ping
 *
 * GEMM: C[16x16] = A[16x16] * B^T[16x16], int8
 * Deployed on a HW_ROWS x HW_COLS AIE tile mesh.
 *
 * Data distribution (row-based split, 4 groups):
 *   A[16x16]: split into 4 partitions of A[4x16], broadcast per row
 *   B[16x16]: split into 4 partitions of B[4x16], broadcast per col
 *
 * Each tile receives 4x16 A + 4x16 B via 2 DMA input rounds (ping-pong):
 *   Ping: A[0:1, 0:15] (32 bytes) + B[0:1, 0:15] (32 bytes)
 *   Pong: A[2:3, 0:15] (32 bytes) + B[2:3, 0:15] (32 bytes)
 *
 * Kernel flow (receive-first ping):
 *   Step 1: Receive ping — acquire+cache A0,B0, release inputs (no output)
 *   Step 2: Compute top-left quadrant C[0:1,0:1] from cached data
 *   Step 3: Receive pong — acquire A1,B1
 *   Step 4: Compute remaining 3 quadrants using cached + new data
 *   Step 5: Release pong inputs
 *   Step 6: Output round 0 — rows 0-1 (all 4 cols), 8 bytes sequential
 *   Step 7: Output round 1 — rows 2-3 (all 4 cols), 8 bytes sequential
 *
 * Output is sequential row-major 4x4 into local_out[16]:
 *   local_out[ 0.. 3] = C[row0, col0..col3]  → DMA round 0 (8 bytes)
 *   local_out[ 4.. 7] = C[row1, col0..col3]  ↗
 *   local_out[ 8..11] = C[row2, col0..col3]  → DMA round 1 (8 bytes)
 *   local_out[12..15] = C[row3, col0..col3]  ↗
 *
 * NOTE: With row-based split, tiles in same column produce redundant output
 * (same inputs). Host assembles them at different C offsets.
 *
 ******************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// Spatial policy definitions for kernel parameter transfer
#define M 32
#define K 32
#define N 32

// HW mesh dimensions (number of AIE tile rows and columns)
#define HW_ROWS 4
#define HW_COLS 4

// --- Tile dimensions derived from M, K, N, HW_ROWS, HW_COLS ---
#define TILE_ROWS (M / HW_ROWS)                 // 4: total output rows per tile
#define TILE_COLS (N / HW_COLS)                 // 4: total output cols per tile
#define ROWS_PER_ROUND (TILE_ROWS / 2)          // 2: A/B rows per DMA input round
#define COLS_PER_ROUND (TILE_COLS / 2)          // 2: B cols per DMA input round
#define K_DIM K                                 // 16: inner product dimension
#define BUF_SZ_OUT (ROWS_PER_ROUND * TILE_COLS) // 8: output bytes per DMA round (2 rows * 4 cols)
#define DEBUG_OUTPUT_ORDER 0
static int verify_matmul(const int8_t *A, const int8_t *B, const int8_t *C);
static int verify_mat_transpose(const int8_t *A, const int8_t *B, const int8_t *C);
// ═══════════════════════════════════════════════════════════════════════════
// KERNEL: matmul
//
// Receive-first ping design for 4x4 mesh:
//   - 2 DMA input rounds (ping-pong), 2 DMA output rounds
//   - Input: 32 bytes per acquire (2 rows x 16 cols int8)
//   - Output: 8 bytes per round (2 rows x 4 cols, sequential row-major)
//
// Per-tile computation: C_tile[4x4] = A_tile[4x16] * B_tile^T[4x16]
//   C_tile[i][j] = sum_k A_tile[i][k] * B_tile[j][k]
//
// Step 1: Receive ping — acquire+cache A0,B0, release (no output)
// Step 2: Compute top-left quadrant from cached data
// Step 3: Receive pong — acquire A1,B1
// Step 4: Compute remaining 3 quadrants (top-right, bottom-left, bottom-right)
// Step 5: Release pong inputs
// Step 6: Output round 0 — local_out[0..7] (rows 0-1, all 4 cols)
// Step 7: Output round 1 — local_out[8..15] (rows 2-3, all 4 cols)
// ═══════════════════════════════════════════════════════════════════════════
// Debug flag: when enabled, skip matmul and fill output with encoded tile ID.
// Each output byte = row[0:2] | col[3:5] | round[6:7]
// This lets you identify which tile and round produced each output byte.
#pragma aie_debug_level(2 | AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN | AIE_DEBUG_FLAG_MM2SBDFINISH)
constexpr aie::SpatialPolicy RowBC = {.pattern = aie::Pattern::Broadcast, .distribution = aie::Layout::Row};
constexpr aie::SpatialPolicy ColBC = {.pattern = aie::Pattern::Broadcast, .distribution = aie::Layout::Col};
constexpr aie::SpatialPolicy LtoR_Merge = {
    .pattern = aie::Pattern::Gather, .distribution = aie::Layout::Row, .merge_order = aie::Flow::LeftToRight};
__global__ void matmul(aie::port<input_window_int8 *, RowBC> window_in_0,
                       aie::port<input_window_int8 *, ColBC> window_in_1,
                       aie::port<output_window_int8 *, LtoR_Merge> window_out_0) {

#if DEBUG_OUTPUT_ORDER
    unsigned coreid = get_coreid();
    int col = coreid >> 16;
    int row = coreid & 0x1F;
    int8_t tag = (int8_t)((row & 0x7) | ((col & 0x7) << 3));
    klog("DEBUG", 2);
#endif

    // Local buffers
    int8_t cache_A[ROWS_PER_ROUND * K_DIM];
    int8_t cache_B[ROWS_PER_ROUND * K_DIM];
    int8_t local_out[TILE_ROWS * TILE_COLS];

    // ===== Step 1: Receive-only ping — acquire+cache+release inputs =====
    int8_t *A0 = (int8_t *)acquire_input_window(window_in_0);
    int8_t *B0 = (int8_t *)acquire_input_window(window_in_1);
    for (int i = 0; i < ROWS_PER_ROUND * K_DIM; i++) {
        cache_A[i] = A0[i];
        cache_B[i] = B0[i];
    }
    release_input_window(window_in_0);
    release_input_window(window_in_1);
#if DEBUG_OUTPUT_ORDER
    // Log first COLS_PER_ROUND elements of A and B
    for (int i = 0; i < K_DIM; i++) {
        klog("A0  ", (int32_t)cache_A[i]);
    }
    for (int i = 0; i < K_DIM; i++) {
        klog("B0  ", (int32_t)cache_B[i]);
    }
#endif

    // ===== Step 2: Compute top-left quadrant from cached data =====
    // C[0:RPR-1, 0:CPR-1] = A0 * B0^T (top-left)
    for (int i = 0; i < ROWS_PER_ROUND; i++) {
        for (int j = 0; j < COLS_PER_ROUND; j++) {
            int16_t sum = 0;
            for (int k = 0; k < K_DIM; k++)
                sum += (int16_t)cache_A[i * K_DIM + k] * (int16_t)cache_B[j * K_DIM + k];
            if (sum > 127)
                sum = 127;
            else if (sum < -128)
                sum = -128;
#if DEBUG_OUTPUT_ORDER
            if (j == 0)
                sum = tag | ((0 & 0x3) << 6);
#endif
            local_out[i * TILE_COLS + j] = (int8_t)sum;
        }
    }

    // ===== Step 3: Receive pong =====
    int8_t *A1 = (int8_t *)acquire_input_window(window_in_0);
    int8_t *B1 = (int8_t *)acquire_input_window(window_in_1);

    // ===== Step 4: Compute remaining 3 quadrants =====
    // C[0:RPR-1, CPR:TILE_COLS-1] = cached_A0 * B1^T (top-right)
    for (int i = 0; i < ROWS_PER_ROUND; i++) {
        for (int j = 0; j < COLS_PER_ROUND; j++) {
            int16_t sum = 0;
            for (int k = 0; k < K_DIM; k++)
                sum += (int16_t)cache_A[i * K_DIM + k] * (int16_t)B1[j * K_DIM + k];
            if (sum > 127)
                sum = 127;
            else if (sum < -128)
                sum = -128;
#if DEBUG_OUTPUT_ORDER
            if (j == 0)
                sum = tag | ((1 & 0x3) << 6);
#endif
            local_out[i * TILE_COLS + j + COLS_PER_ROUND] = (int8_t)sum;
        }
    }

    // C[RPR:TILE_ROWS-1, 0:CPR-1] = A1 * cached_B0^T (bottom-left)
    for (int i = 0; i < ROWS_PER_ROUND; i++) {
        for (int j = 0; j < COLS_PER_ROUND; j++) {
            int16_t sum = 0;
            for (int k = 0; k < K_DIM; k++)
                sum += (int16_t)A1[i * K_DIM + k] * (int16_t)cache_B[j * K_DIM + k];
            if (sum > 127)
                sum = 127;
            else if (sum < -128)
                sum = -128;
#if DEBUG_OUTPUT_ORDER
            if (j == 0)
                sum = tag | ((2 & 0x3) << 6);
#endif
            local_out[(i + ROWS_PER_ROUND) * TILE_COLS + j] = (int8_t)sum;
        }
    }

    // C[RPR:TILE_ROWS-1, CPR:TILE_COLS-1] = A1 * B1^T (bottom-right)
    for (int i = 0; i < ROWS_PER_ROUND; i++) {
        for (int j = 0; j < COLS_PER_ROUND; j++) {
            int16_t sum = 0;
            for (int k = 0; k < K_DIM; k++)
                sum += (int16_t)A1[i * K_DIM + k] * (int16_t)B1[j * K_DIM + k];
            if (sum > 127)
                sum = 127;
            else if (sum < -128)
                sum = -128;
#if DEBUG_OUTPUT_ORDER
            if (j == 0)
                sum = tag | ((3 & 0x3) << 6);
#endif
            local_out[(i + ROWS_PER_ROUND) * TILE_COLS + j + COLS_PER_ROUND] = (int8_t)sum;
        }
    }

    // ===== Step 5: Release pong inputs =====
    release_input_window(window_in_0);
    release_input_window(window_in_1);

    // ===== Step 6-7: Output 2 rounds (8 bytes each, sequential row-major) =====
    for (int round = 0; round < 2; round++) {
        int8_t *out = (int8_t *)acquire_output_window(window_out_0);
        for (int i = 0; i < BUF_SZ_OUT; i++) {
            out[i] = local_out[round * BUF_SZ_OUT + i];
        }
        release_output_window(window_out_0);
    }
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
    matmul<<<mesh>>>(A, B, C, M, N, K);

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

// ═══════════════════════════════════════════════════════════════════════════
// Verification
//
// scalar_matmul: pure C[M][N] = A[M][K] * B^T[N][K], completely independent
//   of pipeline topology, tile partitioning, or DMA layout.
//
// verify_matmul: computes full matmul, then compares flat C[] against
//   reference. Host assembles tile outputs into the full C matrix.
//
// Per-tile DMA output (16 bytes = 2 rounds of 8 bytes, sequential row-major):
//   Round 0 (bytes 0-7): rows 0-1, all 4 cols
//   Round 1 (bytes 8-15): rows 2-3, all 4 cols
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
    int mismatches = 0;
    int8_t C_ref[M * N];
    scalar_matmul(C_ref, A, B);
    for (int i = 0; i < M * N; i++) {
        if (C[i] != C_ref[i]) {
            printf("MISMATCH C[%d]: got %d, expected %d\n", i, C[i], C_ref[i]);
            mismatches++;
            if (mismatches > 128)
                break;
            // return 1;
        }
    }
    // Print A [16x16]
    printf("\nA [%dx%d]:\n", M, K);
    for (int i = 0; i < M; i++) {
        printf("  [");
        for (int j = 0; j < K; j++) {
            printf("%4d", A[i * K + j]);
            if (j < K - 1)
                printf(",");
        }
        printf("]\n");
    }

    // Print B [16x16]
    printf("\nB [%dx%d]:\n", K, N);
    for (int i = 0; i < K; i++) {
        printf("  [");
        for (int j = 0; j < N; j++) {
            printf("%4d", B[i * N + j]);
            if (j < N - 1)
                printf(",");
        }
        printf("]\n");
    }

    // Print C [16x16]
    printf("\nC [%dx%d]:\n", M, N);
    for (int i = 0; i < M; i++) {
        printf("  [");
        for (int j = 0; j < N; j++) {
            printf("%4d", C[i * N + j]);
            if (j < N - 1)
                printf(",");
        }
        printf("]\n");
    }

    // Print C_ref [16x16]
    printf("\nC_ref [%dx%d]:\n", M, N);
    for (int i = 0; i < M; i++) {
        printf("  [");
        for (int j = 0; j < N; j++) {
            printf("%4d", C_ref[i * N + j]);
            if (j < N - 1)
                printf(",");
        }
        printf("]\n");
    }

    int total_elements = M * N;
    if (mismatches == 0)
        printf("PASS: all %d elements match.\n", total_elements);
    else
        printf("FAIL: %d mismatches out of %d.\n", mismatches, total_elements);

    /*
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
    */
    return mismatches;
}

// Verify raw tile-order output against CPU reference
// Assumes tiles output in row-major tile order: (0,0),(0,1),...,(0,3),(1,0),...,(3,3)
// Within each tile: sequential row-major 4x4
static int verify_mat_transpose(const int8_t *A, const int8_t *B, const int8_t *C) {
    int8_t C_ref[M * N];
    scalar_matmul(C_ref, A, B);

    const int TILE_OUT_SZ = TILE_ROWS * TILE_COLS; // 16
    int total = HW_ROWS * HW_COLS * TILE_OUT_SZ;   // 256
    int mismatches = 0;

    for (int flat = 0; flat < total; flat++) {
        int tile_idx = flat / TILE_OUT_SZ;
        int local = flat % TILE_OUT_SZ;
        int hw_row = tile_idx / HW_COLS;
        int hw_col = tile_idx % HW_COLS;
        int local_r = local / TILE_COLS;
        int local_c = local % TILE_COLS;
        int global_r = hw_row * TILE_ROWS + local_r;
        int global_c = hw_col * TILE_COLS + local_c;
        int8_t expected = C_ref[global_r * N + global_c];

        if (C[flat] != expected) {
            printf("MISMATCH C[%d] (tile(%d,%d) local[%d,%d] -> global[%d,%d]): "
                   "got %d, expected %d\n",
                   flat, hw_row, hw_col, local_r, local_c, global_r, global_c, C[flat], expected);
            mismatches++;
        }
    }

    if (mismatches == 0)
        printf("verify_mat_transpose PASS: all %d elements match.\n", total);
    else
        printf("verify_mat_transpose FAIL: %d mismatches out of %d.\n", mismatches, total);

    // Print A [16x16]
    printf("\nA [%dx%d]:\n", M, K);
    for (int i = 0; i < M; i++) {
        printf("  [");
        for (int j = 0; j < K; j++) {
            printf("%4d", A[i * K + j]);
            if (j < K - 1)
                printf(",");
        }
        printf("]\n");
    }

    // Print B [16x16]
    printf("\nB [%dx%d]:\n", K, N);
    for (int i = 0; i < K; i++) {
        printf("  [");
        for (int j = 0; j < N; j++) {
            printf("%4d", B[i * N + j]);
            if (j < N - 1)
                printf(",");
        }
        printf("]\n");
    }

    // Print C [16x16]
    printf("\nC [%dx%d]:\n", M, N);
    for (int i = 0; i < M; i++) {
        printf("  [");
        for (int j = 0; j < N; j++) {
            printf("%4d", C[i * N + j]);
            if (j < N - 1)
                printf(",");
        }
        printf("]\n");
    }

    // Print C [16x16]
    printf("\nC_ref [%dx%d]:\n", M, N);
    for (int i = 0; i < M; i++) {
        printf("  [");
        for (int j = 0; j < N; j++) {
            printf("%4d", C_ref[i * N + j]);
            if (j < N - 1)
                printf(",");
        }
        printf("]\n");
    }
    return mismatches;
}
