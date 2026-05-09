/******************************************************************************
 * Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 *
 * AIE Programming Model — Matrix Multiplication (Generalized Ping-Pong)
 *
 * GEMM: C[MxN] = A[MxK] * B^T[NxK], int8
 * Deployed on a HW_ROWS x HW_COLS AIE tile mesh.
 *
 * Data distribution (row-based split):
 *   A[MxK]: split into HW_ROWS partitions of A[TILE_ROWS x K], broadcast per row
 *   B[NxK]: split into HW_COLS partitions of B[TILE_COLS x K], broadcast per col
 *
 * Each tile receives TILE_ROWS x K (A) + TILE_COLS x K (B) via DMA ping-pong.
 * The number of input DMA rounds is derived from PP_MAX_BYTES:
 *   NUM_A_ROUNDS = TILE_ROWS / ROWS_PER_ROUND
 *   NUM_B_ROUNDS = TILE_COLS / COLS_PER_ROUND
 *
 * Kernel strategy: "cache all A, stream B"
 *   Phase 1: Receive all A chunks into local memory (NUM_A_ROUNDS acquires)
 *   Phase 2: Stream B chunks one at a time, computing against all cached A
 *            (NUM_B_ROUNDS acquires, each iterates over all A rows)
 *   Phase 3: Output results (NUM_OUTPUT_ROUNDS acquires)
 *
 * This matches the DMA iteration counts from BlueprintToSchedulePass.
 *
 ******************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// Spatial policy definitions for kernel parameter transfer
#define M 256
#define K 256
#define N 256

// HW mesh dimensions (number of AIE tile rows and columns)
#define HW_ROWS 4
#define HW_COLS 4

// --- Tile dimensions derived from M, K, N, HW_ROWS, HW_COLS ---
#define K_DIM K           // inner product dimension
#define PP_MAX_BYTES 4096 // max ping-pong buffer size

#define TILE_ROWS (M / HW_ROWS) // output rows per tile
#define TILE_COLS (N / HW_COLS) // output cols per tile

// Input A: each ping-pong buffer holds ROWS_PER_ROUND rows x K_DIM elements
#define ROWS_PER_ROUND_RAW (TILE_ROWS / 2)
#define ROWS_PER_ROUND ((ROWS_PER_ROUND_RAW * K_DIM > PP_MAX_BYTES) ? (PP_MAX_BYTES / K_DIM) : ROWS_PER_ROUND_RAW)
#define NUM_A_ROUNDS (TILE_ROWS / ROWS_PER_ROUND)

// Input B (transposed): each ping-pong buffer holds COLS_PER_ROUND rows x K_DIM elements
#define COLS_PER_ROUND_RAW (TILE_COLS / 2)
#define COLS_PER_ROUND ((COLS_PER_ROUND_RAW * K_DIM > PP_MAX_BYTES) ? (PP_MAX_BYTES / K_DIM) : COLS_PER_ROUND_RAW)
#define NUM_B_ROUNDS (TILE_COLS / COLS_PER_ROUND)

// Output: no K dimension, just rows x cols elements
#define OUTPUT_PER_CORE (TILE_ROWS * TILE_COLS)
#define OUTPUT_PP_RAW (OUTPUT_PER_CORE / 2)
#define BUF_SZ_OUT ((OUTPUT_PP_RAW > PP_MAX_BYTES) ? PP_MAX_BYTES : OUTPUT_PP_RAW)
#define NUM_OUTPUT_ROUNDS (OUTPUT_PER_CORE / BUF_SZ_OUT)

#define DEBUG_OUTPUT_ORDER 0
static int verify_matmul(const int8_t *A, const int8_t *B, const int8_t *C);
static int verify_mat_transpose(const int8_t *A, const int8_t *B, const int8_t *C);
// ═══════════════════════════════════════════════════════════════════════════
// KERNEL: matmul
//
// "Cache all A, stream B" design for generalized round counts:
//   - NUM_A_ROUNDS DMA input rounds for A (ping-pong)
//   - NUM_B_ROUNDS DMA input rounds for B (ping-pong)
//   - NUM_OUTPUT_ROUNDS DMA output rounds
//
// Per-tile computation:
//   C_tile[TILE_ROWS x TILE_COLS] = A_tile[TILE_ROWS x K] * B_tile^T[TILE_COLS x K]
//
// Phase 1: Cache all A — acquire NUM_A_ROUNDS chunks, copy to all_A[], release
// Phase 2: Stream B — for each of NUM_B_ROUNDS B chunks:
//            compute all A rows against current B chunk
// Phase 3: Output — write NUM_OUTPUT_ROUNDS chunks of BUF_SZ_OUT bytes
// ═══════════════════════════════════════════════════════════════════════════
// Debug flag: when enabled, skip matmul and fill output with encoded tile ID.
// Each output byte = row[0:2] | col[3:5] | round_tag[6:7]
#pragma aie_debug_level(2 | AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN | AIE_DEBUG_FLAG_MM2SBDFINISH_COUNTER)
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
    int8_t all_A[TILE_ROWS * K_DIM]; // cache all A data
    int8_t local_out[TILE_ROWS * TILE_COLS];

    // ===== Phase 1: Receive and cache all A chunks =====
    for (int ra = 0; ra < NUM_A_ROUNDS; ra++) {
        int8_t *A_ptr = (int8_t *)acquire_input_window(window_in_0);
        for (int i = 0; i < ROWS_PER_ROUND * K_DIM; i++)
            all_A[ra * ROWS_PER_ROUND * K_DIM + i] = A_ptr[i];
        release_input_window(window_in_0);
    }

#if DEBUG_OUTPUT_ORDER
    // Log first K_DIM elements of cached A
    for (int i = 0; i < K_DIM; i++) {
        klog("A0  ", (int32_t)all_A[i]);
    }
#endif

    // ===== Phase 2: Stream B, compute all sub-blocks =====
    for (int rb = 0; rb < NUM_B_ROUNDS; rb++) {
        int8_t *B_ptr = (int8_t *)acquire_input_window(window_in_1);

#if DEBUG_OUTPUT_ORDER
        if (rb == 0) {
            for (int i = 0; i < K_DIM; i++) {
                klog("B0  ", (int32_t)B_ptr[i]);
            }
        }
#endif

        for (int ra = 0; ra < NUM_A_ROUNDS; ra++) {
            for (int i = 0; i < ROWS_PER_ROUND; i++) {
                for (int j = 0; j < COLS_PER_ROUND; j++) {
                    int16_t sum = 0;
                    for (int k = 0; k < K_DIM; k++)
                        sum += (int16_t)all_A[(ra * ROWS_PER_ROUND + i) * K_DIM + k] * (int16_t)B_ptr[j * K_DIM + k];
                    if (sum > 127)
                        sum = 127;
                    else if (sum < -128)
                        sum = -128;
#if DEBUG_OUTPUT_ORDER
                    if (j == 0)
                        sum = tag | (((ra * NUM_B_ROUNDS + rb) & 0x3) << 6);
#endif
                    local_out[(ra * ROWS_PER_ROUND + i) * TILE_COLS + rb * COLS_PER_ROUND + j] = (int8_t)sum;
                }
            }
        }

        release_input_window(window_in_1);
    }

    // ===== Phase 3: Output =====
    for (int round = 0; round < NUM_OUTPUT_ROUNDS; round++) {
        int8_t *out = (int8_t *)acquire_output_window(window_out_0);
        for (int i = 0; i < BUF_SZ_OUT; i++)
            out[i] = local_out[round * BUF_SZ_OUT + i];
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
    int mismatches = 0;
    int8_t C_ref[M * N];
    scalar_matmul(C_ref, A, B);
    for (int i = 0; i < M * N; i++) {
        if (C[i] != C_ref[i]) {
            printf("MISMATCH C[%d]: got %d, expected %d\n", i, C[i], C_ref[i]);
            mismatches++;
            if (mismatches > 128)
                break;
        }
    }
    // Print A
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

    // Print B
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

    // Print C
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

    // Print C_ref
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
    const int TILE_ROWS_L = M / HW_ROWS;
    const int TILE_COLS_L = N / HW_COLS;
    const int TILE_OUT_SIZE = TILE_ROWS_L * TILE_COLS_L;

    int mismatches = 0;
    for (int g = 0; g < NUM_GROUPS; g++) {
        int rs = g * TILE_ROWS_L; // row start in full matrix
        int cs = g * TILE_COLS_L; // col start in full matrix

        for (int t = 0; t < TILES_PER_GROUP; t++) {
            int tile_idx = g * TILES_PER_GROUP + t;
            int base = tile_idx * TILE_OUT_SIZE;

            for (int i = 0; i < TILE_ROWS_L; i++) {
                for (int j = 0; j < TILE_COLS_L; j++) {
                    int8_t expected = C_ref[(rs + i) * N + (cs + j)];
                    int flat = base + i * TILE_COLS_L + j;
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
    printf("\nSample output C[0:%d][0:%d] (group 0, tile 0):\n", TILE_ROWS_L - 1, TILE_COLS_L - 1);
    for (int i = 0; i < TILE_ROWS_L; i++) {
        printf("  [");
        for (int j = 0; j < TILE_COLS_L; j++) {
            printf("%4d", C[i * TILE_COLS_L + j]);
            if (j < TILE_COLS_L - 1)
                printf(",");
        }
        printf("]\n");
    }

    // Print input A first TILE_ROWS_L rows
    printf("\nInput A[0:%d][0:%d]:\n", TILE_ROWS_L - 1, K - 1);
    for (int i = 0; i < TILE_ROWS_L; i++) {
        printf("  [");
        for (int j = 0; j < K; j++) {
            printf("%4d", A[i * K + j]);
            if (j < K - 1)
                printf(",");
        }
        printf("]\n");
    }

    // Print input B first TILE_ROWS_L rows
    printf("\nInput B[0:%d][0:%d]:\n", TILE_ROWS_L - 1, K - 1);
    for (int i = 0; i < TILE_ROWS_L; i++) {
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
// Assumes tiles output in row-major tile order: (0,0),(0,1),...
// Within each tile: sequential row-major TILE_ROWS x TILE_COLS
static int verify_mat_transpose(const int8_t *A, const int8_t *B, const int8_t *C) {
    int8_t C_ref[M * N];
    scalar_matmul(C_ref, A, B);

    const int TILE_OUT_SZ = TILE_ROWS * TILE_COLS;
    int total = HW_ROWS * HW_COLS * TILE_OUT_SZ;
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

    // Print A
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

    // Print B
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

    // Print C
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

    // Print C_ref
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
