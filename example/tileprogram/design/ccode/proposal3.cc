/******************************************************************************
 * Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 *
 * AIE Programming Model — Matrix Multiplication with Data Caching
 *
 * GEMM: C[16x16] = A[16x16] * B^T[16x16], int8
 * Deployed on a 2x2 AIE tile mesh.
 *
 * Data partitioning (2D split):
 *
 *          col-0 (B[0:7,:])     col-1 (B[8:15,:])
 *   row-0  tile(0,0)             tile(0,1)
 *  (A[0:7]) C[0:7, 0:7]          C[0:7, 8:15]
 *
 *   row-1  tile(1,0)             tile(1,1)
 *  (A[8:15])C[8:15, 0:7]         C[8:15, 8:15]
 *
 *   A: row-split (splitnum=2 on dim-0), replicated across cols
 *   B: row-split (splitnum=2 on dim-0), replicated across rows
 *   C: 2D-split (2x2 quadrants), each tile produces 8x8
 *
 * Each tile receives 4x16 int8 per acquire_input (4 rows, full K=16).
 * 2 input rounds per tile:
 *   Round 1: cache data, compute 1 sub-block (4x4)
 *   Round 2: use cached + new data, compute 3 sub-blocks (4x4 each)
 * Total: 4 sub-blocks of 4x4 = 8x8 per tile
 *
 * CUDA concepts kept (honest mapping):
 *   __global__             - kernel runs on AIE tiles
 *   kernel<<<mesh>>>()     - launch kernel across tile mesh
 *   aieDeviceSynchronize() - wait for all tiles to finish
 *   malloc/free            - plain C host memory allocation
 *
 * What the compiler handles automatically:
 *   DDR <-> tile DMA transfers, tensor partitioning, stream switch routing,
 *   buffer descriptors, lock synchronization, core load/run/wait
 *
 ******************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// ═══════════════════════════════════════════════════════════════════════════
// Dimensions
//
// Full GEMM: C[M x N] = A[M x K] * B^T[K x N]  (B transposed)
// 2x2 mesh: M split by 2 across rows, N split by 2 across cols
// Each tile computes an 8x8 quadrant of C
//
// Per acquire: 4 rows x 16 cols = 64 bytes (CHUNK_M x K)
// 2 acquires per input window = 8 rows total per tile
// ═══════════════════════════════════════════════════════════════════════════
#define M 16
#define K 16
#define N 16
#define CHUNK_M 4     // Rows per input acquire (both A and B chunks)
#define CHUNK_N 4     // Output cols per sub-block (= B rows per acquire mapped to C cols)
#define BUF_SZ_IN 16  // Input buffer: 16 v4int8 = 64 bytes = 4 rows x 16 cols
#define BUF_SZ_OUT 4  // Output buffer: 4 v4int8 = 16 bytes = 4 rows x 4 cols
#define CACHE_SIZE 64 // Local cache per input: CHUNK_M * K = 4 x 16 = 64 bytes

// ═══════════════════════════════════════════════════════════════════════════
// KERNEL: matmul — C_tile[8x8] = A_tile[8x16] * B_tile^T[8x16]
//
// Each tile receives its row-partition of A and row-partition of B.
// B is treated as transposed: C[i][j] = dot(A_row[i,:], B_row[j,:])
//
// Inputs (per acquire, 2 rounds each):
//   window_in_0: A chunk [CHUNK_M x K] = [4 x 16] int8
//   window_in_1: B chunk [CHUNK_M x K] = [4 x 16] int8
// Output (per acquire, 4 rounds total):
//   window_out_0: C sub-block [CHUNK_M x CHUNK_N] = [4 x 4] int8
//
// Round 1: acquire A0, B0 → cache both → compute C[0:3,0:3] → 1 output
// Round 2: acquire A1, B1 → compute C[0:3,4:7], C[4:7,0:3], C[4:7,4:7] → 3 outputs
// ═══════════════════════════════════════════════════════════════════════════
__global__ void matmul(input_window_int8 *window_in_0, input_window_int8 *window_in_1,
                       output_window_int8 *window_out_0) {

#define M 16
#define K 16
#define N 16
#define CHUNK_M 4     // Rows per input acquire (both A and B chunks)
#define CHUNK_N 4     // Output cols per sub-block (= B rows per acquire mapped to C cols)
#define BUF_SZ_IN 16  // Input buffer: 16 v4int8 = 64 bytes = 4 rows x 16 cols
#define BUF_SZ_OUT 4  // Output buffer: 4 v4int8 = 16 bytes = 4 rows x 4 cols
#define CACHE_SIZE 64 // Local cache per input: CHUNK_M * K = 4 x 16 = 64 bytes

    // Local cache for round-1 data reuse in round-2
    int8_t cache_A[CHUNK_M * K]; // 4 x 16 = 64 bytes
    int8_t cache_B[CHUNK_M * K]; // 4 x 16 = 64 bytes

    // ===== Round 1: acquire + cache + compute 1 sub-block =====
    int8_t *A0 = (int8_t *)acquire_input_window(window_in_0); // A[0:3, 0:15]
    int8_t *B0 = (int8_t *)acquire_input_window(window_in_1); // B[0:3, 0:15]

    // Cache for reuse in round 2
    for (int i = 0; i < CHUNK_M * K; i++) {
        cache_A[i] = A0[i];
        cache_B[i] = B0[i];
    }

    // Compute C[0:3, 0:3] = dot(A0, B0^T)
    {
        int8_t *out = acquire_output_window(window_out_0);
        for (int i = 0; i < CHUNK_M; i++) {
            for (int j = 0; j < CHUNK_N; j++) {
                int16_t sum = 0;
                for (int k = 0; k < K; k++) {
                    sum += (int16_t)A0[i * K + k] * (int16_t)B0[j * K + k];
                }
                if (sum > 127)
                    sum = 127;
                else if (sum < -128)
                    sum = -128;
                out[i * CHUNK_N + j] = (int8_t)sum;
            }
        }
        release_output_window(window_out_0);
    }

    release_input_window(window_in_0);
    release_input_window(window_in_1);

    // ===== Round 2: acquire + compute 3 sub-blocks =====
    int8_t *A1 = (int8_t *)acquire_input_window(window_in_0); // A[4:7, 0:15]
    int8_t *B1 = (int8_t *)acquire_input_window(window_in_1); // B[4:7, 0:15]

    // Sub-block 2: C[0:3, 4:7] = dot(cached_A0, B1^T)
    {
        int8_t *out = acquire_output_window(window_out_0);
        for (int i = 0; i < CHUNK_M; i++) {
            for (int j = 0; j < CHUNK_N; j++) {
                int16_t sum = 0;
                for (int k = 0; k < K; k++) {
                    sum += (int16_t)cache_A[i * K + k] * (int16_t)B1[j * K + k];
                }
                if (sum > 127)
                    sum = 127;
                else if (sum < -128)
                    sum = -128;
                out[i * CHUNK_N + j] = (int8_t)sum;
            }
        }
        release_output_window(window_out_0);
    }

    // Sub-block 3: C[4:7, 0:3] = dot(A1, cached_B0^T)
    {
        int8_t *out = acquire_output_window(window_out_0);
        for (int i = 0; i < CHUNK_M; i++) {
            for (int j = 0; j < CHUNK_N; j++) {
                int16_t sum = 0;
                for (int k = 0; k < K; k++) {
                    sum += (int16_t)A1[i * K + k] * (int16_t)cache_B[j * K + k];
                }
                if (sum > 127)
                    sum = 127;
                else if (sum < -128)
                    sum = -128;
                out[i * CHUNK_N + j] = (int8_t)sum;
            }
        }
        release_output_window(window_out_0);
    }

    // Sub-block 4: C[4:7, 4:7] = dot(A1, B1^T)
    {
        int8_t *out = acquire_output_window(window_out_0);
        for (int i = 0; i < CHUNK_M; i++) {
            for (int j = 0; j < CHUNK_N; j++) {
                int16_t sum = 0;
                for (int k = 0; k < K; k++) {
                    sum += (int16_t)A1[i * K + k] * (int16_t)B1[j * K + k];
                }
                if (sum > 127)
                    sum = 127;
                else if (sum < -128)
                    sum = -128;
                out[i * CHUNK_N + j] = (int8_t)sum;
            }
        }
        release_output_window(window_out_0);
    }

    release_input_window(window_in_0);
    release_input_window(window_in_1);
}

// ═══════════════════════════════════════════════════════════════════════════
// HOST
//
// Data distribution for 2x2 mesh (B^T semantics):
//
//   A[16x16]: row-split by 2 → A_top[0:7,:] and A_bot[8:15,:]
//     tile_row_0 gets A_top, tile_row_1 gets A_bot (replicated across cols)
//
//   B[16x16]: row-split by 2 → B_left[0:7,:] and B_right[8:15,:]
//     tile_col_0 gets B_left, tile_col_1 gets B_right (replicated across rows)
//     B rows map to C columns via B^T
//
//   C[16x16]: 2D-split into 8x8 quadrants
//     tile(0,0): C[0:7,  0:7 ]
//     tile(0,1): C[0:7,  8:15]
//     tile(1,0): C[8:15, 0:7 ]
//     tile(1,1): C[8:15, 8:15]
//
// DMA configuration:
//   Input BD:  64 bytes (4x16 int8), repeat_count = 2
//   Output BD: 16 bytes (4x4 int8), repeat_count = 4
//   Total input per tile:  2 x 64 = 128 bytes per window (8x16)
//   Total output per tile: 4 x 16 = 64 bytes (8x8)
//
// Per-tile output order (host must know for reassembly):
//   1. C[0:3, 0:3]  (top-left)
//   2. C[0:3, 4:7]  (top-right)
//   3. C[4:7, 0:3]  (bottom-left)
//   4. C[4:7, 4:7]  (bottom-right)
//
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
    // Small values to avoid int8 overflow in dot product
    for (int i = 0; i < M * K; i++)
        A[i] = (int8_t)((i % 7) - 3); // values in [-3, 3]

    for (int i = 0; i < K * N; i++)
        B[i] = (int8_t)((i % 5) - 2); // values in [-2, 2]

    // Zero output
    for (int i = 0; i < M * N; i++)
        C[i] = 0;

    // --- Launch kernel on tile mesh ---
    matmul<<<mesh>>>(A, B, C);

    // --- Wait for completion ---
    aieDeviceSynchronize();

    // --- CPU reference: C_ref = A * B^T ---
    // C_ref[i][j] = sum_k( A[i][k] * B[j][k] )  (B transposed)
    int8_t *C_ref = (int8_t *)malloc(M * N * sizeof(int8_t));
    for (int i = 0; i < M; i++) {
        for (int j = 0; j < N; j++) {
            int16_t sum = 0;
            for (int kk = 0; kk < K; kk++) {
                sum += (int16_t)A[i * K + kk] * (int16_t)B[j * K + kk];
            }
            if (sum > 127)
                sum = 127;
            else if (sum < -128)
                sum = -128;
            C_ref[i * N + j] = (int8_t)sum;
        }
    }

    // --- Verify ---
    int mismatches = 0;
    for (int i = 0; i < M; i++) {
        for (int j = 0; j < N; j++) {
            int idx = i * N + j;
            if (C[idx] != C_ref[idx]) {
                printf("MISMATCH C[%d][%d]: got %d, expected %d\n", i, j, C[idx], C_ref[idx]);
                mismatches++;
            }
        }
    }

    if (mismatches == 0)
        printf("PASS: all %d elements match.\n", M * N);
    else
        printf("FAIL: %d mismatches out of %d.\n", mismatches, M * N);

    // --- Print sample output ---
    printf("\nSample output C[0:3][0:3]:\n");
    for (int i = 0; i < 4; i++) {
        printf("  [");
        for (int j = 0; j < 4; j++) {
            printf("%4d", C_ref[i * N + j]);
            if (j < 3)
                printf(",");
        }
        printf("]\n");
    }

    // --- Data partitioning summary ---
    printf("\n--- Data Distribution Summary (2x2 mesh, B^T) ---\n");
    printf("  Mesh: 2 rows x 2 cols = 4 tiles\n");
    printf("  A[%dx%d]: row-split (splitnum=2, splitdim=0), replicate across cols\n", M, K);
    printf("    tile row 0 -> A[0:7, 0:15]   (128 bytes)\n");
    printf("    tile row 1 -> A[8:15, 0:15]  (128 bytes)\n");
    printf("  B[%dx%d]: row-split (splitnum=2, splitdim=0), replicate across rows\n", K, N);
    printf("    tile col 0 -> B[0:7, 0:15]   (128 bytes)\n");
    printf("    tile col 1 -> B[8:15, 0:15]  (128 bytes)\n");
    printf("  C[%dx%d]: 2D-split (2x2 quadrants)\n", M, N);
    printf("    tile(0,0) -> C[0:7, 0:7]     (64 bytes)\n");
    printf("    tile(0,1) -> C[0:7, 8:15]    (64 bytes)\n");
    printf("    tile(1,0) -> C[8:15, 0:7]    (64 bytes)\n");
    printf("    tile(1,1) -> C[8:15, 8:15]   (64 bytes)\n");
    printf("\n--- Per-Tile Kernel Parameters ---\n");
    printf("  BUF_SZ_IN = %d (v4int8 units, %d bytes)\n", BUF_SZ_IN, BUF_SZ_IN * 4);
    printf("  BUF_SZ_OUT = %d (v4int8 units, %d bytes)\n", BUF_SZ_OUT, BUF_SZ_OUT * 4);
    printf("  Input rounds = 2, Output rounds = 4 (1 + 3)\n");
    printf("  Cache per input = %d bytes\n", CACHE_SIZE);

    // --- Cleanup ---
    free(A);
    free(B);
    free(C);
    free(C_ref);
    return 0;
}
