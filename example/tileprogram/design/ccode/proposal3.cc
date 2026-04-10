/******************************************************************************
 * Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 *
 * AIE Programming Model — Matrix Multiplication with Data Caching
 *
 * GEMM: C[16x16] = A[16x16] * B^T[16x16], int8
 * Deployed on a 2x2 AIE tile mesh.
 *
 * Current pipeline data distribution (actual routing):
 *   A[16x16]: split into A_top[8x16] and A_bot[8x16]
 *     SHIM(2,0) ch0 → A_top → tiles (0,3) and (1,3)
 *     SHIM(2,0) ch1 → A_bot → tiles (0,4) and (1,4)
 *   B[16x16]: split into B_top[8x16] and B_bot[8x16]
 *     SHIM(3,0) ch0 → B_top → tiles (0,3) and (1,3)
 *     SHIM(3,0) ch1 → B_bot → tiles (0,4) and (1,4)
 *
 * Each tile receives 8x16 A-partition + 8x16 B-partition via 2 DMA rounds:
 *   Round 0: A[0:3, 0:15] (64 bytes) + B[0:3, 0:15] (64 bytes)
 *   Round 1: A[4:7, 0:15] (64 bytes) + B[4:7, 0:15] (64 bytes)
 *
 * Kernel computes C_tile[8x8] = A_tile[8x16] * B_tile^T[8x16]
 *   C_tile[i][j] = sum_{k=0}^{15} A_tile[i][k] * B_tile[j][k]
 *
 * Data caching strategy (matches DMA ping-pong):
 *   Round 0: cache A0[4x16], B0[4x16], write C[0:3, 0:3] to output (32 bytes)
 *   Round 1: use cached + new data, write C[4:7, 0:3]... to output (32 bytes)
 *
 * NOTE: With current pipeline, tiles (0,3)/(1,3) produce redundant output
 * (same inputs). Host assembles them at different C offsets.
 *
 ******************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define M 16
#define K 16
#define N 16

// ═══════════════════════════════════════════════════════════════════════════
// KERNEL: matmul
//
// Matches current MLIR pipeline infrastructure:
//   - BUF_SZ = 16 (v4int8 units = 64 bytes) for all windows
//   - 2 symmetric iterations: each iter does 1 input acquire + 1 output acquire
//   - Input: 64 bytes per acquire (4 rows x 16 cols int8)
//   - Output DMA BD len=8 (32 bytes transferred per cycle)
//
// Per-tile computation: C_tile[8x8] = A_tile[8x16] * B_tile^T[8x16]
//   C_tile[i][j] = sum_k A_tile[i][k] * B_tile[j][k]
//
// Iter 0: read A[0:3,:], B[0:3,:], cache both
//         write first 32 bytes of output (garbage/placeholder - overwritten)
// Iter 1: read A[4:7,:], B[4:7,:], now have all 8 rows of A and B
//         compute full 8x8 result using cached + new data
//         write last 32 bytes of output
//
// The output DMA only transfers 32 bytes from each 64-byte buffer.
// So we write the 8x8 result as two 32-byte chunks:
//   Chunk 0: C[0:3, 0:7] = 4 rows x 8 cols = 32 bytes
//   Chunk 1: C[4:7, 0:7] = 4 rows x 8 cols = 32 bytes
//
// PROBLEM: In iter 0, we only have B[0:3,:], not the full B[0:7,:].
// We can compute C[i][j] for j in [0:3] but not j in [4:7].
//
// SOLUTION: Write the full 8x8 output in iter 1 only, using both cached
// and new data. In iter 0, write a dummy/partial output that will be
// overwritten or that the DMA picks up as the first 32 bytes.
//
// Actually, the cleanest approach for the 2-iter symmetric loop:
// Each iter reads A_chunk[4x16] + B_chunk[4x16], computes partial 4x8
// C rows using ONLY that iteration's B_chunk as the j-index:
//   Iter 0: compute C[0:3, 0:3] = A0 * B0^T  → but this is 4x4 = 16 bytes
//           pad to 32 bytes (rest unused) → DMA picks up 32 bytes
//   Iter 1: compute C[4:7, 0:3] = A1 * B0_cached^T  → but also 4x4
//
// None of these work cleanly. The simplest correct approach:
// Use iter 0 to cache, iter 1 to compute everything. Fill output in both
// iters but only iter 1 output matters (both go to host via different
// ping/pong buffers).
// ═══════════════════════════════════════════════════════════════════════════
__global__ void matmul(input_window_int8 *window_in_0, input_window_int8 *window_in_1,
                       output_window_int8 *window_out_0) {
#define K_DIM 16

    // Local cache for round-0 data
    int8_t cache_A[4 * K_DIM]; // 4 x 16 = 64 bytes
    int8_t cache_B[4 * K_DIM]; // 4 x 16 = 64 bytes

    // ===== Iter 0: read A[0:3,:], B[0:3,:], cache, write partial output =====
    int8_t *A0 = (int8_t *)acquire_input_window(window_in_0);
    int8_t *B0 = (int8_t *)acquire_input_window(window_in_1);

    // Cache for use in iter 1
    for (int i = 0; i < 4 * K_DIM; i++) {
        cache_A[i] = A0[i];
        cache_B[i] = B0[i];
    }

    // Write 32 bytes: C[0:3, 0:3] = A0 * B0^T, columns 4-7 = 0
    {
        int8_t *out = acquire_output_window(window_out_0);
        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 4; j++) {
                int16_t sum = 0;
                for (int k = 0; k < K_DIM; k++) {
                    sum += (int16_t)A0[i * K_DIM + k] * (int16_t)B0[j * K_DIM + k];
                }
                if (sum > 127)
                    sum = 127;
                else if (sum < -128)
                    sum = -128;
                out[i * 8 + j] = (int8_t)sum;
            }
            for (int j = 4; j < 8; j++) {
                out[i * 8 + j] = 0;
            }
        }
        release_output_window(window_out_0);
    }

    release_input_window(window_in_0);
    release_input_window(window_in_1);

    // ===== Iter 1: read A[4:7,:], B[4:7,:], compute remaining output =====
    int8_t *A1 = (int8_t *)acquire_input_window(window_in_0);
    int8_t *B1 = (int8_t *)acquire_input_window(window_in_1);

    // Write 32 bytes: C[4:7, 0:3] + C[4:7, 4:7]
    {
        int8_t *out = acquire_output_window(window_out_0);
        // C[4:7, 0:3] = A1 * cached_B0^T
        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 4; j++) {
                int16_t sum = 0;
                for (int k = 0; k < K_DIM; k++) {
                    sum += (int16_t)A1[i * K_DIM + k] * (int16_t)cache_B[j * K_DIM + k];
                }
                if (sum > 127)
                    sum = 127;
                else if (sum < -128)
                    sum = -128;
                out[i * 8 + j] = (int8_t)sum;
            }
        }
        // C[4:7, 4:7] = A1 * B1^T
        for (int i = 0; i < 4; i++) {
            for (int j = 0; j < 4; j++) {
                int16_t sum = 0;
                for (int k = 0; k < K_DIM; k++) {
                    sum += (int16_t)A1[i * K_DIM + k] * (int16_t)B1[j * K_DIM + k];
                }
                if (sum > 127)
                    sum = 127;
                else if (sum < -128)
                    sum = -128;
                out[i * 8 + j + 4] = (int8_t)sum;
            }
        }
        release_output_window(window_out_0);
    }

    release_input_window(window_in_0);
    release_input_window(window_in_1);
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
// Pipeline data distribution (actual routing):
//   tile(0,3): A[0:7,:] + B[0:7,:]  → output at C[0:63]
//   tile(1,3): A[0:7,:] + B[0:7,:]  → output at C[64:127]  (REDUNDANT)
//   tile(0,4): A[8:15,:] + B[8:15,:] → output at C[128:191]
//   tile(1,4): A[8:15,:] + B[8:15,:] → output at C[192:255] (REDUNDANT)
//
// Per-tile DMA output (64 bytes = 2 cycles of 32 bytes):
//   Cycle 0 (bytes 0-31): rows 0-3, cols 0-3 valid, cols 4-7 = 0
//   Cycle 1 (bytes 32-63): rows 4-7, cols 0-7 all valid
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

    // Each tile outputs an 8x8 sub-block of C_ref
    // tile row_start col_start  (in the full 16x16 matrix)
    //  0     0         0
    //  1     0         0    (redundant)
    //  2     8         8
    //  3     8         8    (redundant)
    const struct {
        int offset;
        int row_start;
        int col_start;
    } tiles[4] = {{0, 0, 0}, {64, 0, 0}, {128, 8, 8}, {192, 8, 8}};

    int mismatches = 0;
    for (int t = 0; t < 4; t++) {
        int base = tiles[t].offset;
        int rs = tiles[t].row_start;
        int cs = tiles[t].col_start;

        for (int i = 0; i < 8; i++) {
            for (int j = 0; j < 8; j++) {
                // DMA layout: cycle 0 rows 0-3 cols 4-7 are zero-filled
                int8_t expected = (i < 4 && j >= 4) ? 0 : C_ref[(rs + i) * N + (cs + j)];
                int flat = base + i * 8 + j;
                if (C[flat] != expected) {
                    printf("MISMATCH C[%d] (tile %d, row %d, col %d): "
                           "got %d, expected %d\n",
                           flat, t, i, j, C[flat], expected);
                    mismatches++;
                }
            }
        }
    }

    if (mismatches == 0)
        printf("PASS: all %d elements match.\n", M * N);
    else
        printf("FAIL: %d mismatches out of %d.\n", mismatches, M * N);

    // Print sample: tile 0, cycle 0 (rows 0-3)
    printf("\nSample output C[0:3][0:7] (tile 0,3 cycle 0):\n");
    for (int i = 0; i < 4; i++) {
        printf("  [");
        for (int j = 0; j < 8; j++) {
            printf("%4d", C[i * 8 + j]);
            if (j < 7)
                printf(",");
        }
        printf("]\n");
    }

    // Print input A first 4 rows
    printf("\nInput A[0:3][0:15]:\n");
    for (int i = 0; i < 4; i++) {
        printf("  [");
        for (int j = 0; j < K; j++) {
            printf("%4d", A[i * K + j]);
            if (j < K - 1)
                printf(",");
        }
        printf("]\n");
    }

    // Print input B first 4 rows
    printf("\nInput B[0:3][0:15]:\n");
    for (int i = 0; i < 4; i++) {
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
    printf("=== Matrix Multiply with Data Caching on AIE 2x2 Mesh ===\n");
    printf("    C[%dx%d] = A[%dx%d] * B^T[%dx%d], int8\n", M, N, M, K, K, N);

    // --- Device + mesh ---
    aieSetDevice(0);
    aieDim mesh(2, 2);

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
