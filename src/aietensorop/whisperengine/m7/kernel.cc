/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M0 -- per-core bf16 GEMM throughput probe for the Whisper engine.
 * Every core computes C[M][N] += A[M][K] * B[K][N] (bf16 in, fp32 accumulate)
 * on data in its own memory, M0_REPS times, and records the cycle count of the
 * compute loop (no lock or DMA inside the timed region) at m0_res.
 * Layouts (mmul<4,8,8> native tiles): A [M/4][K/8][4][8], B [K/8][N/8][8][8],
 * C [M/4][N/8][4][8] fp32.
 ******************************************************************************/
#include <stdint.h>
#include <adf.h>
#include <aie_api/aie.hpp>

#ifndef M0_M
#define M0_M 64
#endif
#ifndef M0_N
#define M0_N 64
#endif
#ifndef M0_K
#define M0_K 64
#endif
#define M0_REPS 8

typedef aie::mmul<4, 8, 8, bfloat16, bfloat16, accauto> MM;

alignas(64) bfloat16 m0_a[M0_M * M0_K];
alignas(64) bfloat16 m0_b[M0_K * M0_N];
alignas(64) float m0_c[M0_M * M0_N];
alignas(64) volatile uint32_t m0_res[16];

// 2x2 register blocking: two A row-tiles x two B col-tiles per k step.
__attribute__((noinline)) static void gemm(const bfloat16 *__restrict A, const bfloat16 *__restrict B,
                                           float *__restrict C) {
    for (unsigned z = 0; z < M0_M / 4; z += 2)
        chess_loop_range(2, ) for (unsigned j = 0; j < M0_N / 8; j += 2) chess_loop_range(2, ) {
            float *c00 = C + (z * (M0_N / 8) + j) * 32;
            float *c01 = c00 + 32;
            float *c10 = c00 + (M0_N / 8) * 32;
            float *c11 = c10 + 32;
            MM C00(aie::load_v<32>(c00)), C01(aie::load_v<32>(c01));
            MM C10(aie::load_v<32>(c10)), C11(aie::load_v<32>(c11));
            const bfloat16 *pA0 = A + z * (M0_K / 8) * 32;
            const bfloat16 *pA1 = pA0 + (M0_K / 8) * 32;
            const bfloat16 *pB0 = B + j * 64;
            const bfloat16 *pB1 = pB0 + 64;
            for (unsigned k = 0; k < M0_K / 8; k++)
                chess_prepare_for_pipelining chess_loop_range(4, ) {
                    const aie::vector<bfloat16, 32> a0 = aie::load_v<32>(pA0);
                    pA0 += 32;
                    const aie::vector<bfloat16, 32> a1 = aie::load_v<32>(pA1);
                    pA1 += 32;
                    const aie::vector<bfloat16, 64> b0 = aie::load_v<64>(pB0);
                    pB0 += (M0_N / 8) * 64;
                    const aie::vector<bfloat16, 64> b1 = aie::load_v<64>(pB1);
                    pB1 += (M0_N / 8) * 64;
                    C00.mac(a0, b0);
                    C01.mac(a0, b1);
                    C10.mac(a1, b0);
                    C11.mac(a1, b1);
                }
            aie::store_v(c00, C00.template to_vector<float>());
            aie::store_v(c01, C01.template to_vector<float>());
            aie::store_v(c10, C10.template to_vector<float>());
            aie::store_v(c11, C11.template to_vector<float>());
        }
}

// kernel_decl m7
int32_t main() {
    for (int i = 0; i < M0_M * M0_K; i++)
        m0_a[i] = (bfloat16)(float)((i * 7 % 13) - 6);
    for (int i = 0; i < M0_K * M0_N; i++)
        m0_b[i] = (bfloat16)(float)((i * 5 % 11) - 5);
    for (int i = 0; i < M0_M * M0_N; i++)
        m0_c[i] = 0.0f;
    m0_res[0] = 0;
    gemm(m0_a, m0_b, m0_c); // warm
    for (int i = 0; i < M0_M * M0_N; i++)
        m0_c[i] = 0.0f;
    const uint64_t t0 = aie::tile::current().cycles();
    for (int r = 0; r < M0_REPS; r++)
        gemm(m0_a, m0_b, m0_c);
    const uint64_t t1 = aie::tile::current().cycles();
    m0_res[1] = (uint32_t)(t1 - t0);
    m0_res[2] = M0_M;
    m0_res[3] = M0_N;
    m0_res[4] = M0_K;
    m0_res[5] = M0_REPS;
    m0_res[0] = 0x4D304F4B; /* "M7OK" */
    return 0;
}
