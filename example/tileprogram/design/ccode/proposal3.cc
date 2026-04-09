/******************************************************************************
* Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
*
* AIE Programming Model — Middle Ground
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
// #pragma aie_debug_level 2
//  ═══════════════════════════════════════════════════════════════════════════
//  KERNEL: __global__ marks this as an AIE tile kernel
//
//  C = A * B where A is [M x K], B is [K x N], C is [M x N]
//  Each tile receives its partition of the data automatically.
//  ═══════════════════════════════════════════════════════════════════════════
/*
__global__ void matmul(const int32_t *A, const int32_t *B, int32_t *C,
                       int M, int N, int K) {
    for (int i = 0; i < M; i++) {
        for (int j = 0; j < N; j++) {
            int32_t sum = 0;
            for (int k = 0; k < K; k++) {
                sum += A[i * K + k] * B[k * N + j];
            }
            C[i * N + j] = sum;
        }
    }
}
*/
__global__ void matmul(input_window_int8 *window_in_0, input_window_int8 *window_in_1, output_window_int8 *window_out_0) {
    unsigned coreid = get_coreid();
    int col = coreid >> 16;
    int row = coreid & 0x1F;

    for (int k = 0; k < 2; k++) {
        klog("CENk", k);
        int8_t *in0 = (int8_t *)acquire_input_window(window_in_0);
        int8_t *in1 = (int8_t *)acquire_input_window(window_in_1);
        int8_t *out = acquire_output_window(window_out_0);

        klog("IN0", (int8_t)(uintptr_t)in0);
        klog("IN1", (int8_t)(uintptr_t)in1);
        klog("OUT", (int8_t)(uintptr_t)out);

        // Kernel logic: read from both inputs, write to output
        for (int i = 0; i < BUF_SZ; i++) {
            if (k == 0 && i == 0) {
                in0[0] = row * 10 + col;
            }
            v4int8 data0 = *((v4int8 *)&in0[i * 4]);
            v4int8 data1 = *((v4int8 *)&in1[i * 4]);
            // Simple pass-through of input A for now (placeholder for GEMM)
            *((v4int8 *)&out[i * 4]) = data0;
        }
        klog("CLOP", BUF_SZ);

        release_input_window(window_in_0);
        release_input_window(window_in_1);
        release_output_window(window_out_0);
        klog("CEXT", 1);
    }
}


// ═══════════════════════════════════════════════════════════════════════════
// HOST
// ═══════════════════════════════════════════════════════════════════════════
int main() {
    const int M = 16, N = 16, K = 16;

    // --- Device + mesh ---
    aieSetDevice(0);
    aieDim mesh(2, 2);

    // --- Allocate host memory (plain malloc) ---
    int32_t *A = (int32_t *)malloc(M * K * sizeof(int32_t));
    int32_t *B = (int32_t *)malloc(K * N * sizeof(int32_t));
    int32_t *C = (int32_t *)malloc(M * N * sizeof(int32_t));

    for (int i = 0; i < M * K; i++) A[i] = i + 1;
    for (int i = 0; i < K * N; i++) B[i] = i + 1;
    printf("------------main--------\n");
    // --- Launch kernel on tile mesh ---
    matmul<<<mesh>>>(A, B, C, M, N, K);

    printf("------------after matmul--------\n");

    // --- Wait for completion ---
    aieDeviceSynchronize();

    // --- Results are ready in C ---
    int mismatches = 0;
    for (int i = 0; i < M; i++) {
        for (int j = 0; j < N; j++) {
            int32_t expected = 0;
            for (int k = 0; k < K; k++)
                expected += A[i * K + k] * B[k * N + j];
            if (C[i * N + j] != expected) {
                printf("MISMATCH C[%d][%d]: got %d, expected %d\n",
                       i, j, C[i * N + j], expected);
                mismatches++;
            }
        }
    }
    if (mismatches == 0)
        printf("PASS: all %d elements match.\n", M * N);
    else
        printf("FAIL: %d mismatches.\n", mismatches);

    free(A);
    free(B);
    free(C);
    return 0;
}
