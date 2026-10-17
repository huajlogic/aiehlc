/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M5 -- attention inner-loop probe. One 32-row q-block against NKC 64-key
 * chunks, run twice: v0 = the engine's current att_qk / att_softmax / att_pv,
 * v1 = the candidates. Every stage is timed separately (no lock in between:
 * skill aiecoretimerlock) and both O results are left in memory for the host to
 * check against a CPU reference. Layouts: we_desc.h (ATTN).
 ******************************************************************************/
#include <stdint.h>
#include <adf.h>
#include <aie_api/aie.hpp>
#include "we_desc.h"

#define NKC 8
typedef aie::mmul<4, 8, 8, bfloat16, bfloat16, accauto> MM;
typedef aie::vector<float, 32> V32;
typedef aie::vector<bfloat16, 32> VB;
typedef aie::vector<bfloat16, 64> VB64;

alignas(64) bfloat16 m5_q[WE_QB * 64];
alignas(64) bfloat16 m5_k[WE_KCH * 64];
alignas(64) bfloat16 m5_v[WE_KCH * 64];
alignas(64) float m5_s[WE_QB * WE_KCH];
alignas(64) float m5_o0[WE_QB * 64];
alignas(64) float m5_o1[WE_QB * 64];
alignas(64) float m5_o2[WE_QB * 64];
alignas(64) float we_att_ml[3][8][32];                         /* m, l, chunk sums */
alignas(64) float m5_ml[4][8 * 32]; /* l after each variant */ /* we_att_ml after each variant */
alignas(64) volatile int32_t m5_res[64];

__attribute__((noinline)) static V32 fmul_vv(V32 a, V32 b) { return aie::mul(a, b).template to_vector<float>(); }
__attribute__((always_inline)) static inline V32 to_f32(const VB &v) {
    aie::accum<accfloat, 32> acc;
    acc.from_vector(v, 0);
    return acc.template to_vector<float>();
}
__attribute__((always_inline)) static inline VB to_bf16(const V32 &v) {
    aie::accum<accfloat, 32> acc;
    acc.from_vector(v, 0);
    return acc.template to_vector<bfloat16>();
}
__attribute__((always_inline)) static inline V32 row_max8(const V32 &v) {
    V32 t = aie::max(v, aie::shuffle_down(v, 4));
    t = aie::max(t, aie::shuffle_down(t, 2));
    t = aie::max(t, aie::shuffle_down(t, 1));
    return aie::concat(aie::broadcast<float, 8>(t[0]), aie::broadcast<float, 8>(t[8]), aie::broadcast<float, 8>(t[16]),
                       aie::broadcast<float, 8>(t[24]));
}

// ---- v0: the engine's current code ------------------------------------------
__attribute__((noinline)) static void att_qk(const bfloat16 *__restrict Q, const bfloat16 *__restrict K,
                                             float *__restrict S) {
    for (unsigned z = 0; z < 8; z += 2)
        chess_loop_range(4, 4) for (unsigned j = 0; j < 8; j += 2) chess_prepare_for_pipelining {
            MM C00, C01, C10, C11;
            const bfloat16 *pa0 = Q + z * 8 * 32, *pa1 = pa0 + 8 * 32, *pb = K + j * 64;
            for (unsigned k = 0; k < 8; k++)
                chess_unroll_loop() {
                    const VB a0 = aie::load_v<32>(pa0 + k * 32), a1 = aie::load_v<32>(pa1 + k * 32);
                    const aie::vector<bfloat16, 64> b0 = aie::load_v<64>(pb + k * 8 * 64),
                                                    b1 = aie::load_v<64>(pb + k * 8 * 64 + 64);
                    if (k == 0) {
                        C00.mul(a0, b0);
                        C01.mul(a0, b1);
                        C10.mul(a1, b0);
                        C11.mul(a1, b1);
                    } else {
                        C00.mac(a0, b0);
                        C01.mac(a0, b1);
                        C10.mac(a1, b0);
                        C11.mac(a1, b1);
                    }
                }
            float *c00 = S + (z * 8 + j) * 32, *c10 = c00 + 8 * 32;
            aie::store_v(c00, C00.template to_vector<float>());
            aie::store_v(c00 + 32, C01.template to_vector<float>());
            aie::store_v(c10, C10.template to_vector<float>());
            aie::store_v(c10 + 32, C11.template to_vector<float>());
        }
}

__attribute__((noinline)) static void att_pv(const bfloat16 *__restrict P, const bfloat16 *__restrict V,
                                             float *__restrict O) {
    for (unsigned z = 0; z < 8; z += 2)
        chess_loop_range(4, 4) for (unsigned j = 0; j < 8; j += 2) chess_prepare_for_pipelining {
            float *c00 = O + (z * 8 + j) * 32, *c10 = c00 + 8 * 32;
            MM C00(aie::load_v<32>(c00)), C01(aie::load_v<32>(c00 + 32));
            MM C10(aie::load_v<32>(c10)), C11(aie::load_v<32>(c10 + 32));
            const bfloat16 *pa0 = P + z * 8 * 32, *pa1 = pa0 + 8 * 32, *pb = V + j * 64;
            for (unsigned k = 0; k < 8; k++)
                chess_unroll_loop() {
                    const VB a0 = aie::load_v<32>(pa0 + k * 32), a1 = aie::load_v<32>(pa1 + k * 32);
                    const aie::vector<bfloat16, 64> b0 = aie::load_v<64>(pb + k * 8 * 64),
                                                    b1 = aie::load_v<64>(pb + k * 8 * 64 + 64);
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

__attribute__((noinline)) static void att_raise(const V32 &lmax, int rg, float *O) {
    const V32 m_old = aie::load_v<32>(&we_att_ml[0][rg][0]);
    const V32 m_new = aie::max(m_old, row_max8(lmax));
    const V32 sc = aie::exp2<float>(aie::sub(m_old, m_new));
    aie::store_v(&we_att_ml[1][rg][0], fmul_vv(aie::load_v<32>(&we_att_ml[1][rg][0]), sc));
    for (int dt = 0; dt < 8; dt++) {
        float *o = O + (rg * 8 + dt) * 32;
        aie::store_v(o, fmul_vv(aie::load_v<32>(o), sc));
    }
    aie::store_v(&we_att_ml[0][rg][0], m_new);
}

__attribute__((noinline)) static void att_softmax(float *S, float *O) {
    bfloat16 *P = (bfloat16 *)S;
    for (unsigned rg = 0; rg < 8; rg++) {
        const float *srg = S + rg * 8 * 32;
        V32 lmax = aie::load_v<32>(srg);
        for (int kp = 1; kp < 8; kp++)
            lmax = aie::max(lmax, aie::load_v<32>(srg + kp * 32));
        const V32 lim = aie::add(aie::load_v<32>(&we_att_ml[0][rg][0]), WE_SM_LAZY);
        if (!aie::gt(lmax, lim).empty())
            att_raise(lmax, rg, O);
        const V32 m = aie::load_v<32>(&we_att_ml[0][rg][0]);
        V32 l = aie::load_v<32>(&we_att_ml[1][rg][0]);
        for (int kp = 0; kp < 8; kp++) {
            const V32 p = aie::exp2<float>(aie::sub(aie::load_v<32>(srg + kp * 32), m));
            l = aie::add(l, p);
            aie::store_v(P + (rg * 8 + kp) * 32, to_bf16(p));
        }
        aie::store_v(&we_att_ml[1][rg][0], l);
    }
}

// ---- v1: candidates -----------------------------------------------------------
// exp2 straight from an fp32 accumulator to bf16 (native, 16 lanes per op)
__attribute__((always_inline)) static inline VB exp2_acc(const aie::accum<accfloat, 32> &a) {
    const aie::vector<bfloat16, 16> lo = ::exp2(a.template extract<16>(0));
    const aie::vector<bfloat16, 16> hi = ::exp2(a.template extract<16>(1));
    return aie::concat(lo, hi);
}

// Fused S - m and softmax numerator: the QK^T accumulators start at -m (the row
// reference), so exp2 reads them directly -- S never goes to memory. Writes P
// (bf16); returns the row groups with a P past 2^WE_SM_LAZY (a score above its
// reference: redo after a raise). Denominators come from att_pv2.
template <int EXP>
__attribute__((noinline)) static unsigned att_qks(const bfloat16 *__restrict Q, const bfloat16 *__restrict K,
                                                  bfloat16 *__restrict P) {
    const VB lim = aie::broadcast<bfloat16, 32>((bfloat16)4294967296.0f);
    unsigned flag = 0;
    for (unsigned z = 0; z < 8; z += 2)
        chess_loop_range(4, 4) {
            const V32 nm0 = aie::neg(aie::load_v<32>(&we_att_ml[0][z][0]));
            const V32 nm1 = aie::neg(aie::load_v<32>(&we_att_ml[0][z + 1][0]));
            VB pm0 = aie::zeros<bfloat16, 32>(), pm1 = pm0;
            for (unsigned j = 0; j < 8; j += 2)
                chess_prepare_for_pipelining chess_loop_range(4, 4) {
                    MM C00(nm0), C01(nm0), C10(nm1), C11(nm1);
                    const bfloat16 *pa0 = Q + z * 8 * 32, *pa1 = pa0 + 8 * 32, *pb = K + j * 64;
                    for (unsigned k = 0; k < 8; k++)
                        chess_unroll_loop() {
                            const VB a0 = aie::load_v<32>(pa0 + k * 32), a1 = aie::load_v<32>(pa1 + k * 32);
                            const aie::vector<bfloat16, 64> b0 = aie::load_v<64>(pb + k * 8 * 64),
                                                            b1 = aie::load_v<64>(pb + k * 8 * 64 + 64);
                            C00.mac(a0, b0);
                            C01.mac(a0, b1);
                            C10.mac(a1, b0);
                            C11.mac(a1, b1);
                        }
                    VB p00, p01, p10, p11;
                    if (EXP) {
                        p00 = exp2_acc(C00.to_accum()), p01 = exp2_acc(C01.to_accum());
                        p10 = exp2_acc(C10.to_accum()), p11 = exp2_acc(C11.to_accum());
                    } else {
                        p00 = C00.template to_vector<bfloat16>(), p01 = C01.template to_vector<bfloat16>();
                        p10 = C10.template to_vector<bfloat16>(), p11 = C11.template to_vector<bfloat16>();
                    }
                    bfloat16 *q0 = P + (z * 8 + j) * 32, *q1 = q0 + 8 * 32;
                    aie::store_v(q0, p00);
                    aie::store_v(q0 + 32, p01);
                    aie::store_v(q1, p10);
                    aie::store_v(q1 + 32, p11);
                    pm0 = aie::max(pm0, aie::max(p00, p01));
                    pm1 = aie::max(pm1, aie::max(p10, p11));
                }
            flag |= ((unsigned)!aie::gt(pm0, lim).empty() << z) | ((unsigned)!aie::gt(pm1, lim).empty() << (z + 1));
        }
    return flag;
}

// 4x2 blocking: 4 row groups x 2 key tiles (8 accumulators), the dim loop pipelined
__attribute__((noinline)) static unsigned att_qks42(const bfloat16 *__restrict Q, const bfloat16 *__restrict K,
                                                    bfloat16 *__restrict P) {
    const VB lim = aie::broadcast<bfloat16, 32>((bfloat16)4294967296.0f);
    unsigned flag = 0;
    for (unsigned z = 0; z < 8; z += 4)
        chess_loop_range(2, 2) for (unsigned j = 0; j < 8; j += 2) chess_loop_range(4, 4) {
            MM acc[4][2];
            for (unsigned r = 0; r < 4; r++)
                chess_unroll_loop() {
                    const V32 nm = aie::neg(aie::load_v<32>(&we_att_ml[0][z + r][0]));
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
                    const VB p0 = exp2_acc(acc[r][0].to_accum()), p1 = exp2_acc(acc[r][1].to_accum());
                    aie::store_v(P + ((z + r) * 8 + j) * 32, p0);
                    aie::store_v(P + ((z + r) * 8 + j + 1) * 32, p1);
                    flag |= (unsigned)!aie::gt(aie::max(p0, p1), lim).empty() << (z + r);
                }
        }
    return flag;
}

// S - m (fp32) with 4x2 blocking: accumulators start at -m, nothing loaded but Q/K
__attribute__((noinline)) static void att_qk42(const bfloat16 *__restrict Q, const bfloat16 *__restrict K,
                                               float *__restrict S) {
    for (unsigned z = 0; z < 8; z += 4)
        chess_loop_range(2, 2) for (unsigned j = 0; j < 8; j += 2) chess_loop_range(4, 4) {
            MM acc[4][2];
            for (unsigned r = 0; r < 4; r++)
                chess_unroll_loop() {
                    const V32 nm = aie::neg(aie::load_v<32>(&we_att_ml[0][z + r][0]));
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

// P = exp2(S - m) in place (bf16 over the fp32 S, never ahead of the reads);
// returns nonzero if some P passed 2^WE_SM_LAZY
__attribute__((noinline)) static unsigned att_exp(float *S) {
    bfloat16 *P = (bfloat16 *)S;
    VB pm = aie::zeros<bfloat16, 32>();
    for (unsigned i = 0; i < 64; i++)
        chess_prepare_for_pipelining chess_loop_range(64, 64) {
            const VB p = aie::exp2<bfloat16>(aie::load_v<32>(S + i * 32));
            aie::store_v(P + i * 32, p);
            pm = aie::max(pm, p);
        }
    return !aie::gt(pm, aie::broadcast<bfloat16, 32>((bfloat16)4294967296.0f)).empty();
}

// O += P V with 4x2 blocking (C from / to O), the k (key) loop pipelined
__attribute__((noinline)) static void att_pv42(const bfloat16 *__restrict P, const bfloat16 *__restrict V,
                                               float *__restrict O) {
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
                    aie::store_v(O + ((z + r) * 8 + j) * 32, acc[r][0].template to_vector<float>());
                    aie::store_v(O + ((z + r) * 8 + j + 1) * 32, acc[r][1].template to_vector<float>());
                }
        }
}

// row sums of P on the multiplier (P x 1): l[rg] += sum, in every lane of the row
__attribute__((noinline)) static void att_lsum(const bfloat16 *__restrict P) {
    const VB64 ones = aie::broadcast<bfloat16, 64>((bfloat16)1.0f);
    for (unsigned z = 0; z < 8; z += 2)
        chess_prepare_for_pipelining chess_loop_range(4, 4) {
            MM L0(aie::load_v<32>(&we_att_ml[1][z][0])), L1(aie::load_v<32>(&we_att_ml[1][z + 1][0]));
            for (unsigned k = 0; k < 8; k++)
                chess_unroll_loop() {
                    L0.mac(aie::load_v<32>(P + (z * 8 + k) * 32), ones);
                    L1.mac(aie::load_v<32>(P + ((z + 1) * 8 + k) * 32), ones);
                }
            aie::store_v(&we_att_ml[1][z][0], L0.template to_vector<float>());
            aie::store_v(&we_att_ml[1][z + 1][0], L1.template to_vector<float>());
        }
}

// Rare path for one row group (every row group of a q-block's first chunk):
// S rows into tmp, reference set (first) or raised, P recomputed.
__attribute__((noinline)) static void att_rg_slow(const bfloat16 *__restrict Q, const bfloat16 *__restrict K,
                                                  bfloat16 *__restrict P, float *__restrict tmp, float *O, unsigned rg,
                                                  int first) {
    const bfloat16 *pa = Q + rg * 8 * 32;
    for (unsigned kp = 0; kp < 8; kp++) {
        MM C;
        C.mul(aie::load_v<32>(pa), aie::load_v<64>(K + kp * 64));
        for (unsigned k = 1; k < 8; k++)
            C.mac(aie::load_v<32>(pa + k * 32), aie::load_v<64>(K + (k * 8 + kp) * 64));
        aie::store_v(tmp + kp * 32, C.template to_vector<float>());
    }
    V32 lmax = aie::load_v<32>(tmp);
    for (unsigned kp = 1; kp < 8; kp++)
        lmax = aie::max(lmax, aie::load_v<32>(tmp + kp * 32));
    if (first)
        aie::store_v(&we_att_ml[0][rg][0], row_max8(lmax));
    else
        att_raise(lmax, (int)rg, O);
    const V32 m = aie::load_v<32>(&we_att_ml[0][rg][0]);
    for (unsigned kp = 0; kp < 8; kp++)
        aie::store_v(P + (rg * 8 + kp) * 32, aie::exp2<bfloat16>(aie::sub(aie::load_v<32>(tmp + kp * 32), m)));
}

// O += P V; the denominators ride along on the multiplier: l[rg] += P[rg] x 1
// (the row sum, in every lane of the row) -- from the same rounded P as O.
__attribute__((noinline)) static void att_pv2(const bfloat16 *__restrict P, const bfloat16 *__restrict V,
                                              float *__restrict O) {
    const aie::vector<bfloat16, 64> ones = aie::broadcast<bfloat16, 64>((bfloat16)1.0f);
    for (unsigned z = 0; z < 8; z += 2)
        chess_prepare_for_pipelining chess_loop_range(4, 4) {
            MM L0(aie::load_v<32>(&we_att_ml[1][z][0])), L1(aie::load_v<32>(&we_att_ml[1][z + 1][0]));
            for (unsigned k = 0; k < 8; k++)
                chess_unroll_loop() {
                    L0.mac(aie::load_v<32>(P + (z * 8 + k) * 32), ones);
                    L1.mac(aie::load_v<32>(P + ((z + 1) * 8 + k) * 32), ones);
                }
            aie::store_v(&we_att_ml[1][z][0], L0.template to_vector<float>());
            aie::store_v(&we_att_ml[1][z + 1][0], L1.template to_vector<float>());
        }
    att_pv(P, V, O);
}

// P = exp2(S - m) in place: bf16 P over the fp32 S. The write of vector i lands
// on S vector i/2, already read, and software pipelining only moves loads earlier
// and stores later -- so the two views are declared restrict (the aliasing
// otherwise serialises the loop: 991 -> 273 cycles). Returns nonzero if some P
// passed 2^WE_SM_LAZY.
__attribute__((noinline)) static unsigned att_exp_r(const float *__restrict S, bfloat16 *__restrict P) {
    VB pm = aie::zeros<bfloat16, 32>();
    for (unsigned i = 0; i < 64; i += 2)
        chess_prepare_for_pipelining chess_loop_range(32, 32) {
            const VB p0 = aie::exp2<bfloat16>(aie::load_v<32>(S + i * 32));
            const VB p1 = aie::exp2<bfloat16>(aie::load_v<32>(S + i * 32 + 32));
            aie::store_v(P + i * 32, p0);
            aie::store_v(P + i * 32 + 32, p1);
            pm = aie::max(pm, aie::max(p0, p1));
        }
    return !aie::gt(pm, aie::broadcast<bfloat16, 32>((bfloat16)4294967296.0f)).empty();
}

// the same, plus the per-lane denominators l[rg] += P (P x 1 on the multiplier)
__attribute__((noinline)) static unsigned att_exp_l(const float *__restrict S, bfloat16 *__restrict P) {
    const VB one = aie::broadcast<bfloat16, 32>((bfloat16)1.0f);
    VB pm = aie::zeros<bfloat16, 32>();
    for (unsigned rg = 0; rg < 8; rg++)
        chess_prepare_for_pipelining chess_loop_range(8, 8) {
            aie::accum<accfloat, 32> l0, l1;
            l0.from_vector(aie::load_v<32>(&we_att_ml[1][rg][0]), 0);
            l1.from_vector(aie::zeros<float, 32>(), 0);
            for (unsigned kp = 0; kp < 8; kp += 2)
                chess_unroll_loop() {
                    const VB p0 = aie::exp2<bfloat16>(aie::load_v<32>(S + (rg * 8 + kp) * 32));
                    const VB p1 = aie::exp2<bfloat16>(aie::load_v<32>(S + (rg * 8 + kp + 1) * 32));
                    aie::store_v(P + (rg * 8 + kp) * 32, p0);
                    aie::store_v(P + (rg * 8 + kp + 1) * 32, p1);
                    l0 = aie::mac(l0, p0, one);
                    l1 = aie::mac(l1, p1, one);
                    pm = aie::max(pm, aie::max(p0, p1));
                }
            aie::store_v(&we_att_ml[1][rg][0],
                         aie::add(l0.template to_vector<float>(), l1.template to_vector<float>()));
        }
    return !aie::gt(pm, aie::broadcast<bfloat16, 32>((bfloat16)4294967296.0f)).empty();
}

// first chunk of a q-block: S with m = 0, the row maxima become the references,
// S - m again (cheaper than a subtract pass), then the numerator
__attribute__((noinline)) static void att_first(const bfloat16 *Q, const bfloat16 *K, float *S) {
    const V32 z = aie::zeros<float, 32>();
    for (unsigned rg = 0; rg < 8; rg++)
        aie::store_v(&we_att_ml[0][rg][0], z);
    att_qk42(Q, K, S);
    for (unsigned rg = 0; rg < 8; rg++) {
        V32 lmax = aie::load_v<32>(S + rg * 8 * 32);
        for (unsigned kp = 1; kp < 8; kp++)
            lmax = aie::max(lmax, aie::load_v<32>(S + (rg * 8 + kp) * 32));
        aie::store_v(&we_att_ml[0][rg][0], row_max8(lmax));
    }
    att_qk42(Q, K, S);
}

// one chunk's numerator: v1 per-lane sums in the exp pass, v2 row sums by mmul in lsum
__attribute__((noinline)) static void att_chunk1(const bfloat16 *Q, const bfloat16 *K, float *S, float *O, int first,
                                                 int v) {
    bfloat16 *P = (bfloat16 *)S;
    float *tmp = S + WE_QB * WE_KCH / 2;
    if (first)
        att_first(Q, K, S);
    else
        att_qk42(Q, K, S);
    const unsigned big = v == 1 ? att_exp_l(S, P) : att_exp_r(S, P);
    if (big && !first)
        for (unsigned rg = 0; rg < 8; rg++) {
            att_rg_slow(Q, K, P, tmp, O, rg, 0);
            m5_res[18]++;
        }
}

// ---- driver -------------------------------------------------------------------
static void fill(int c) {
    // deterministic synthetic operands; the host rebuilds the same values
    for (int r = 0; r < WE_QB; r++)
        for (int d = 0; d < 64; d++)
            m5_q[((r / 4) * 8 + d / 8) * 32 + (r % 4) * 8 + d % 8] = (bfloat16)(float)((r * 7 + d * 3) % 17 - 8);
    for (int k = 0; k < WE_KCH; k++) {
        const int kk = c * WE_KCH + k;
        for (int d = 0; d < 64; d++) {
            m5_k[((d / 8) * 8 + k / 8) * 64 + (d % 8) * 8 + k % 8] =
                (bfloat16)((float)((kk * 5 + d * 11) % 19 - 9) * 0.015625f);
            m5_v[((k / 8) * 8 + d / 8) * 64 + (k % 8) * 8 + d % 8] = (bfloat16)(float)((kk * 3 + d * 7) % 13 - 6);
        }
    }
}

static void run(int v, float *O, volatile int32_t *t) {
    const V32 ninf = aie::broadcast<float, 32>(-1.0e30f), z = aie::zeros<float, 32>();
    for (int rg = 0; rg < 8; rg++) {
        aie::store_v(&we_att_ml[0][rg][0], ninf);
        aie::store_v(&we_att_ml[1][rg][0], z);
    }
    for (unsigned i = 0; i < WE_QB * 64 / 32; i++)
        aie::store_v(O + i * 32, z);
    for (int c = 0; c < NKC; c++) {
        fill(c);
        const uint64_t c0 = aie::tile::current().cycles();
        if (v)
            att_chunk1(m5_q, m5_k, m5_s, O, c == 0, v);
        else
            att_qk(m5_q, m5_k, m5_s);
        const uint64_t c1 = aie::tile::current().cycles();
        if (!v)
            att_softmax(m5_s, O);
        const uint64_t c2 = aie::tile::current().cycles();
        if (v == 2)
            att_lsum((const bfloat16 *)m5_s);
        att_pv((const bfloat16 *)m5_s, m5_v, O);
        const uint64_t c3 = aie::tile::current().cycles();
        t[0] += (int32_t)(c1 - c0);
        if (c == 0)
            t[3] = (int32_t)(c1 - c0);
        t[1] += (int32_t)(c2 - c1);
        t[2] += (int32_t)(c3 - c2);
    }
    for (unsigned i = 0; i < 8; i++)
        aie::store_v(&m5_ml[v][i * 32], aie::load_v<32>(&we_att_ml[1][0][0] + i * 32));
}

// kernel_decl m5
int32_t main() {
    aie::set_rounding(aie::rounding_mode::conv_even);
    for (int i = 0; i < 64; i++)
        m5_res[i] = 0;
    run(0, m5_o0, &m5_res[4]);
    run(1, m5_o1, &m5_res[8]);
    run(2, m5_o2, &m5_res[20]);
    m5_res[1] = NKC;
    m5_res[0] = 0x4D354F4B; /* "M5OK" */
    return 0;
}
