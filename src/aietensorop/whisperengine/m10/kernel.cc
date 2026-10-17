/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M10 -- attention matmul probe: the engine's att_qk (S - m = Q K^T - m) and
 * att_pv (l += rowsum P, O += P V) for one 32-query x 64-key chunk against
 * re-blocked variants. Each variant must reproduce the engine bit for bit;
 * cycles of 8 calls land in m10_res.
 ******************************************************************************/
#include <stdint.h>
#include <adf.h>
#include <aie_api/aie.hpp>

typedef aie::mmul<4, 8, 8, bfloat16, bfloat16, accauto> MM;
typedef aie::vector<float, 32> V32;
typedef aie::vector<bfloat16, 32> VB;
typedef aie::vector<bfloat16, 64> VB64;

alignas(64) bfloat16 m10_q[32 * 64];        /* Q [rg8][kd8][4][8] */
alignas(64) bfloat16 m10_k[64 * 64];        /* K^T [kd8][kp8][8][8] -- also P / V for pv */
alignas(64) bfloat16 m10_v[64 * 64];        /* V [kp8][dt8][8][8] */
alignas(64) float m10_s0[32 * 64];          /* S / O, engine */
alignas(64) float m10_s1[32 * 64];          /* S / O, variant */
alignas(64) float m10_o0[32 * 64 + 8 * 32]; /* O + l (engine) */
alignas(64) float m10_o1[32 * 64 + 8 * 32]; /* O + l (variant) */
alignas(64) float m10_ml[2 * 8 * 32];       /* m (row references), l */
alignas(64) volatile int32_t m10_res[64];

#define MLR(i, rg) (m10_ml + ((i) * 8 + (rg)) * 32)

// ---- qk, engine: 4x2 blocking, k loop pipelined
__attribute__((noinline)) static void qk0(const bfloat16 *__restrict Q, const bfloat16 *__restrict K,
                                          float *__restrict S) {
    for (unsigned z = 0; z < 8; z += 4)
        chess_loop_range(2, 2) for (unsigned j = 0; j < 8; j += 2) chess_loop_range(4, 4) {
            MM acc[4][2];
            for (unsigned r = 0; r < 4; r++)
                chess_unroll_loop() {
                    const V32 nm = aie::neg(aie::load_v<32>(MLR(0, z + r)));
                    acc[r][0] = MM(nm);
                    acc[r][1] = MM(nm);
                }
            const bfloat16 *pa = Q + z * 8 * 32, *pb = K + j * 64;
            for (unsigned k = 0; k < 8; k++)
                chess_prepare_for_pipelining chess_loop_range(8, 8) {
                    VB a[4];
                    VB64 b[2];
                    for (unsigned r = 0; r < 4; r++)
                        chess_unroll_loop() a[r] = aie::load_v<32>(pa + (r * 8 + k) * 32);
                    b[0] = aie::load_v<64>(pb + k * 8 * 64);
                    b[1] = aie::load_v<64>(pb + k * 8 * 64 + 64);
                    for (unsigned r = 0; r < 4; r++)
                        chess_unroll_loop() {
                            acc[r][0].mac(a[r], b[0]);
                            acc[r][1].mac(a[r], b[1]);
                        }
                }
            for (unsigned r = 0; r < 4; r++)
                chess_unroll_loop() {
                    aie::store_v(S + ((z + r) * 8 + j) * 32, acc[r][0].template to_vector<float>());
                    aie::store_v(S + ((z + r) * 8 + j + 1) * 32, acc[r][1].template to_vector<float>());
                }
        }
}

// ---- qk, variant 1: 4x2 blocks, one flat pipelined loop over the 8 blocks, k unrolled
__attribute__((noinline)) static void qk1(const bfloat16 *__restrict Q, const bfloat16 *__restrict K,
                                          float *__restrict S) {
    for (unsigned b = 0; b < 8; b++)
        chess_prepare_for_pipelining chess_loop_range(8, 8) {
            const unsigned z = (b >> 2) * 4, j = (b & 3) * 2;
            MM acc[4][2];
            for (unsigned r = 0; r < 4; r++)
                chess_unroll_loop() {
                    const V32 nm = aie::neg(aie::load_v<32>(MLR(0, z + r)));
                    acc[r][0] = MM(nm);
                    acc[r][1] = MM(nm);
                }
            const bfloat16 *pa = Q + z * 8 * 32, *pb = K + j * 64;
            for (unsigned k = 0; k < 8; k++)
                chess_unroll_loop() {
                    const VB64 b0 = aie::load_v<64>(pb + k * 8 * 64), b1 = aie::load_v<64>(pb + k * 8 * 64 + 64);
                    for (unsigned r = 0; r < 4; r++)
                        chess_unroll_loop() {
                            const VB a = aie::load_v<32>(pa + (r * 8 + k) * 32);
                            acc[r][0].mac(a, b0);
                            acc[r][1].mac(a, b1);
                        }
                }
            for (unsigned r = 0; r < 4; r++)
                chess_unroll_loop() {
                    aie::store_v(S + ((z + r) * 8 + j) * 32, acc[r][0].template to_vector<float>());
                    aie::store_v(S + ((z + r) * 8 + j + 1) * 32, acc[r][1].template to_vector<float>());
                }
        }
}

// ---- qk, variant 2: 2x4 blocks (2 row groups x 4 key tiles), k loop pipelined
__attribute__((noinline)) static void qk2(const bfloat16 *__restrict Q, const bfloat16 *__restrict K,
                                          float *__restrict S) {
    for (unsigned z = 0; z < 8; z += 2)
        chess_loop_range(4, 4) for (unsigned j = 0; j < 8; j += 4) chess_loop_range(2, 2) {
            MM acc[2][4];
            for (unsigned r = 0; r < 2; r++)
                chess_unroll_loop() {
                    const V32 nm = aie::neg(aie::load_v<32>(MLR(0, z + r)));
                    for (unsigned c = 0; c < 4; c++)
                        chess_unroll_loop() acc[r][c] = MM(nm);
                }
            const bfloat16 *pa = Q + z * 8 * 32, *pb = K + j * 64;
            for (unsigned k = 0; k < 8; k++)
                chess_prepare_for_pipelining chess_loop_range(8, 8) {
                    const VB a0 = aie::load_v<32>(pa + k * 32), a1 = aie::load_v<32>(pa + (8 + k) * 32);
                    for (unsigned c = 0; c < 4; c++)
                        chess_unroll_loop() {
                            const VB64 b = aie::load_v<64>(pb + k * 8 * 64 + c * 64);
                            acc[0][c].mac(a0, b);
                            acc[1][c].mac(a1, b);
                        }
                }
            for (unsigned r = 0; r < 2; r++)
                for (unsigned c = 0; c < 4; c++)
                    chess_unroll_loop()
                        aie::store_v(S + ((z + r) * 8 + j + c) * 32, acc[r][c].template to_vector<float>());
        }
}

// ---- pv, engine: row sums on the multiplier, then O += P V with 2x2 blocks
__attribute__((noinline)) static void pv0(const bfloat16 *__restrict P, const bfloat16 *__restrict V,
                                          float *__restrict O) {
    float *L = O + 32 * 64;
    const VB64 ones = aie::broadcast<bfloat16, 64>((bfloat16)1.0f);
    for (unsigned z = 0; z < 8; z += 2)
        chess_prepare_for_pipelining chess_loop_range(4, 4) {
            MM L0(aie::load_v<32>(L + z * 32)), L1(aie::load_v<32>(L + (z + 1) * 32));
            for (unsigned k = 0; k < 8; k++)
                chess_unroll_loop() {
                    L0.mac(aie::load_v<32>(P + (z * 8 + k) * 32), ones);
                    L1.mac(aie::load_v<32>(P + ((z + 1) * 8 + k) * 32), ones);
                }
            aie::store_v(L + z * 32, L0.template to_vector<float>());
            aie::store_v(L + (z + 1) * 32, L1.template to_vector<float>());
        }
    for (unsigned z = 0; z < 8; z += 2)
        chess_loop_range(4, 4) for (unsigned j = 0; j < 8; j += 2) chess_prepare_for_pipelining {
            float *c00 = O + (z * 8 + j) * 32, *c10 = c00 + 8 * 32;
            MM C00(aie::load_v<32>(c00)), C01(aie::load_v<32>(c00 + 32));
            MM C10(aie::load_v<32>(c10)), C11(aie::load_v<32>(c10 + 32));
            const bfloat16 *pa0 = P + z * 8 * 32, *pa1 = pa0 + 8 * 32, *pb = V + j * 64;
            for (unsigned k = 0; k < 8; k++)
                chess_unroll_loop() {
                    const VB a0 = aie::load_v<32>(pa0 + k * 32), a1 = aie::load_v<32>(pa1 + k * 32);
                    const VB64 b0 = aie::load_v<64>(pb + k * 8 * 64), b1 = aie::load_v<64>(pb + k * 8 * 64 + 64);
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

// ---- pv, variant 4: row sums as engine, O += P V with 4x2 blocks, one pipelined loop
__attribute__((noinline)) static void pv_sums(const bfloat16 *__restrict P, float *__restrict L) {
    const VB64 ones = aie::broadcast<bfloat16, 64>((bfloat16)1.0f);
    for (unsigned z = 0; z < 8; z += 2)
        chess_prepare_for_pipelining chess_loop_range(4, 4) {
            MM L0(aie::load_v<32>(L + z * 32)), L1(aie::load_v<32>(L + (z + 1) * 32));
            for (unsigned k = 0; k < 8; k++)
                chess_unroll_loop() {
                    L0.mac(aie::load_v<32>(P + (z * 8 + k) * 32), ones);
                    L1.mac(aie::load_v<32>(P + ((z + 1) * 8 + k) * 32), ones);
                }
            aie::store_v(L + z * 32, L0.template to_vector<float>());
            aie::store_v(L + (z + 1) * 32, L1.template to_vector<float>());
        }
}
__attribute__((noinline)) static void pv1(const bfloat16 *__restrict P, const bfloat16 *__restrict V,
                                          float *__restrict O) {
    pv_sums(P, O + 32 * 64);
    for (unsigned b = 0; b < 8; b++)
        chess_prepare_for_pipelining chess_loop_range(8, 8) {
            const unsigned z = (b >> 2) * 4, j = (b & 3) * 2;
            MM acc[4][2];
            for (unsigned r = 0; r < 4; r++)
                chess_unroll_loop() {
                    acc[r][0] = MM(aie::load_v<32>(O + ((z + r) * 8 + j) * 32));
                    acc[r][1] = MM(aie::load_v<32>(O + ((z + r) * 8 + j + 1) * 32));
                }
            const bfloat16 *pa = P + z * 8 * 32, *pb = V + j * 64;
            for (unsigned k = 0; k < 8; k++)
                chess_unroll_loop() {
                    const VB64 b0 = aie::load_v<64>(pb + k * 8 * 64), b1 = aie::load_v<64>(pb + k * 8 * 64 + 64);
                    for (unsigned r = 0; r < 4; r++)
                        chess_unroll_loop() {
                            const VB a = aie::load_v<32>(pa + (r * 8 + k) * 32);
                            acc[r][0].mac(a, b0);
                            acc[r][1].mac(a, b1);
                        }
                }
            for (unsigned r = 0; r < 4; r++)
                chess_unroll_loop() {
                    aie::store_v(O + ((z + r) * 8 + j) * 32, acc[r][0].template to_vector<float>());
                    aie::store_v(O + ((z + r) * 8 + j + 1) * 32, acc[r][1].template to_vector<float>());
                }
        }
}

// ---- pv, variant 5: 4x2 blocks with k pipelined (the qk0 shape)
__attribute__((noinline)) static void pv2(const bfloat16 *__restrict P, const bfloat16 *__restrict V,
                                          float *__restrict O) {
    pv_sums(P, O + 32 * 64);
    for (unsigned z = 0; z < 8; z += 4)
        chess_loop_range(2, 2) for (unsigned j = 0; j < 8; j += 2) chess_loop_range(4, 4) {
            MM acc[4][2];
            for (unsigned r = 0; r < 4; r++)
                chess_unroll_loop() {
                    acc[r][0] = MM(aie::load_v<32>(O + ((z + r) * 8 + j) * 32));
                    acc[r][1] = MM(aie::load_v<32>(O + ((z + r) * 8 + j + 1) * 32));
                }
            const bfloat16 *pa = P + z * 8 * 32, *pb = V + j * 64;
            for (unsigned k = 0; k < 8; k++)
                chess_prepare_for_pipelining chess_loop_range(8, 8) {
                    VB a[4];
                    for (unsigned r = 0; r < 4; r++)
                        chess_unroll_loop() a[r] = aie::load_v<32>(pa + (r * 8 + k) * 32);
                    const VB64 b0 = aie::load_v<64>(pb + k * 8 * 64), b1 = aie::load_v<64>(pb + k * 8 * 64 + 64);
                    for (unsigned r = 0; r < 4; r++)
                        chess_unroll_loop() {
                            acc[r][0].mac(a[r], b0);
                            acc[r][1].mac(a[r], b1);
                        }
                }
            for (unsigned r = 0; r < 4; r++)
                chess_unroll_loop() {
                    aie::store_v(O + ((z + r) * 8 + j) * 32, acc[r][0].template to_vector<float>());
                    aie::store_v(O + ((z + r) * 8 + j + 1) * 32, acc[r][1].template to_vector<float>());
                }
        }
}

typedef void (*mm_fn)(const bfloat16 *, const bfloat16 *, float *);
static void reset_o(float *o) {
    for (int i = 0; i < 32 * 64 + 8 * 32; i++)
        o[i] = (float)((i * 13) % 29 - 14) * 0.125f;
}
static int32_t time_qk(mm_fn f, float *S) {
    f(m10_q, m10_k, S);
    const uint64_t t0 = aie::tile::current().cycles();
    for (int r = 0; r < 8; r++)
        f(m10_q, m10_k, S);
    return (int32_t)(aie::tile::current().cycles() - t0);
}
static int32_t time_pv(mm_fn f, float *O) {
    reset_o(O);
    const uint64_t t0 = aie::tile::current().cycles();
    for (int r = 0; r < 8; r++)
        f(m10_k, m10_v, O); /* P: the K buffer viewed as [rg8][kp8][32] (first 4 KB) */
    return (int32_t)(aie::tile::current().cycles() - t0);
}
static int32_t diff(const float *a, const float *b, int n) {
    int32_t d = 0;
    const uint32_t *x = (const uint32_t *)a, *y = (const uint32_t *)b;
    for (int i = 0; i < n; i++)
        d += x[i] != y[i];
    return d;
}

// kernel_decl m10
int32_t main() {
    for (int i = 0; i < 32 * 64; i++)
        m10_q[i] = (bfloat16)((float)((i * 7) % 23 - 11) * 0.0625f);
    for (int i = 0; i < 64 * 64; i++) {
        m10_k[i] = (bfloat16)((float)((i * 5) % 19 - 9) * 0.03125f);
        m10_v[i] = (bfloat16)((float)((i * 3) % 13 - 6) * 0.25f);
    }
    for (int i = 0; i < 2 * 8 * 32; i++)
        m10_ml[i] = (float)(i % 9) * 0.5f;
    static const mm_fn qf[3] = {qk0, qk1, qk2}, pf[3] = {pv0, pv1, pv2};
    m10_res[2] = time_qk(qf[0], m10_s0);
    m10_res[3] = 0;
    for (int v = 1; v < 3; v++) {
        m10_res[2 + 2 * v] = time_qk(qf[v], m10_s1);
        m10_res[3 + 2 * v] = diff(m10_s0, m10_s1, 32 * 64);
    }
    m10_res[8] = time_pv(pf[0], m10_o0);
    m10_res[9] = 0;
    for (int v = 1; v < 3; v++) {
        m10_res[8 + 2 * v] = time_pv(pf[v], m10_o1);
        m10_res[9 + 2 * v] = diff(m10_o0, m10_o1, 32 * 64 + 8 * 32);
    }
    m10_res[1] = 6;
    m10_res[0] = 0x4D314F4B; /* "M1OK" */
    return 0;
}
