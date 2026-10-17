/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M6 -- bf16 mmul<4,8,8> register-blocking probe. C[MxN] += A[MxK] B[KxN] in
 * the engine's tile layouts (A [M/4][K/8][4x8], B [K/8][N/8][8x8], C
 * [M/4][N/8][4x8] fp32), BM x BN accumulators per block, the K loop pipelined.
 * Each variant runs 8 times; cycles land in m6_res for the host.
 ******************************************************************************/
#include <stdint.h>
#include <adf.h>
#include <aie_api/aie.hpp>

typedef aie::mmul<4, 8, 8, bfloat16, bfloat16, accauto> MM;
typedef aie::vector<bfloat16, 32> VB;
typedef aie::vector<bfloat16, 64> VB64;

alignas(64) bfloat16 m6_a[64 * 96];
alignas(64) bfloat16 m6_b[96 * 64];
alignas(64) float m6_c[64 * 64];
alignas(64) volatile int32_t m6_res[64];

template <unsigned BM, unsigned BN, unsigned M, unsigned N, unsigned K>
__attribute__((noinline)) void gemm(const bfloat16 *__restrict A, const bfloat16 *__restrict B, float *__restrict C) {
    for (unsigned z = 0; z < M / 4; z += BM)
        chess_loop_range(M / 4 / BM, M / 4 / BM) for (unsigned j = 0; j < N / 8; j += BN)
            chess_loop_range(N / 8 / BN, N / 8 / BN) {
            MM acc[BM][BN];
            for (unsigned r = 0; r < BM; r++)
                chess_unroll_loop() for (unsigned c = 0; c < BN; c++) chess_unroll_loop() acc[r][c] =
                    MM(aie::load_v<32>(C + ((z + r) * (N / 8) + j + c) * 32));
            const bfloat16 *pa = A + z * (K / 8) * 32;
            const bfloat16 *pb = B + j * 64;
            for (unsigned k = 0; k < K / 8; k++)
                chess_prepare_for_pipelining chess_loop_range(K / 8, K / 8) {
                    VB a[BM];
                    VB64 b[BN];
                    for (unsigned r = 0; r < BM; r++)
                        chess_unroll_loop() a[r] = aie::load_v<32>(pa + (r * (K / 8) + k) * 32);
                    for (unsigned c = 0; c < BN; c++)
                        chess_unroll_loop() b[c] = aie::load_v<64>(pb + (k * (N / 8) + c) * 64);
                    for (unsigned r = 0; r < BM; r++)
                        chess_unroll_loop() for (unsigned c = 0; c < BN; c++) chess_unroll_loop() acc[r][c].mac(a[r],
                                                                                                                b[c]);
                }
            for (unsigned r = 0; r < BM; r++)
                chess_unroll_loop() for (unsigned c = 0; c < BN; c++) chess_unroll_loop()
                    aie::store_v(C + ((z + r) * (N / 8) + j + c) * 32, acc[r][c].template to_vector<float>());
        }
}

// the engine's current mac_chunk (64x48 += 64x48 * 48x48)
__attribute__((noinline)) static void mac_chunk(const bfloat16 *__restrict A, const bfloat16 *__restrict B,
                                                float *__restrict C) {
    for (unsigned z = 0; z < 16; z += 2)
        chess_loop_range(8, 8) for (unsigned j = 0; j < 6; j += 2) chess_loop_range(3, 3) chess_prepare_for_pipelining {
            float *c00 = C + (z * 6 + j) * 32;
            float *c10 = c00 + 6 * 32;
            MM C00(aie::load_v<32>(c00)), C01(aie::load_v<32>(c00 + 32));
            MM C10(aie::load_v<32>(c10)), C11(aie::load_v<32>(c10 + 32));
            const bfloat16 *pa0 = A + z * 6 * 32;
            const bfloat16 *pa1 = pa0 + 6 * 32;
            const bfloat16 *pb = B + j * 64;
            for (unsigned k = 0; k < 6; k++)
                chess_unroll_loop() {
                    const VB a0 = aie::load_v<32>(pa0 + k * 32);
                    const VB a1 = aie::load_v<32>(pa1 + k * 32);
                    const VB64 b0 = aie::load_v<64>(pb + k * 6 * 64);
                    const VB64 b1 = aie::load_v<64>(pb + k * 6 * 64 + 64);
                    C00.mac(a0, b0);
                    C01.mac(a0, b1);
                    C10.mac(a1, b0);
                    C11.mac(a1, b1);
                }
            aie::store_v(c00, C00.template to_vector<float>());
            aie::store_v(c00 + 32, C01.template to_vector<float>());
            aie::store_v(c10, C10.template to_vector<float>());
            aie::store_v(c10 + 32, C11.template to_vector<float>());
        }
}

typedef void (*gemm_fn)(const bfloat16 *, const bfloat16 *, float *);
static void time_it(int slot, gemm_fn f, int macs) {
    f(m6_a, m6_b, m6_c); // warm
    const uint64_t t0 = aie::tile::current().cycles();
    for (int r = 0; r < 8; r++)
        f(m6_a, m6_b, m6_c);
    const uint64_t t1 = aie::tile::current().cycles();
    m6_res[2 + 2 * slot] = (int32_t)(t1 - t0);
    m6_res[3 + 2 * slot] = macs;
}

// kernel_decl m6
int32_t main() {
    for (int i = 0; i < 64 * 96; i++)
        m6_a[i] = (bfloat16)(float)((i * 7 % 13) - 6);
    for (int i = 0; i < 96 * 64; i++)
        m6_b[i] = (bfloat16)(float)((i * 5 % 11) - 5);
    for (int i = 0; i < 64 * 64; i++)
        m6_c[i] = 0.0f;
    time_it(0, mac_chunk, 64 * 48 * 48);
    time_it(1, gemm<2, 2, 64, 48, 48>, 64 * 48 * 48);
    time_it(2, gemm<4, 2, 64, 48, 48>, 64 * 48 * 48);
    time_it(3, gemm<2, 3, 64, 48, 48>, 64 * 48 * 48);
    time_it(4, gemm<4, 3, 64, 48, 48>, 64 * 48 * 48);
    time_it(5, gemm<2, 2, 32, 64, 64>, 32 * 64 * 64);
    time_it(6, gemm<4, 2, 32, 64, 64>, 32 * 64 * 64);
    time_it(7, gemm<2, 4, 32, 64, 64>, 32 * 64 * 64);
    time_it(8, gemm<2, 2, 64, 48, 96>, 64 * 48 * 96);
    time_it(9, gemm<4, 2, 64, 48, 96>, 64 * 48 * 96);
    m6_res[1] = 10;
    m6_res[0] = 0x4D364F4B; /* "M6OK" */
    return 0;
}
