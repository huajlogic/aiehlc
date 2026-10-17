/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M9 -- LayerNorm-apply probe: the engine's ln_apply (C <- rstd C - (rstd mu) c on
 * the multiplier, hi/lo bf16 operands) against restructured variants. Every
 * variant must reproduce variant 0 bit for bit; cycles of 8 calls land in m9_res
 * (each call restores C from m9_in first; that copy is timed alone and subtracted).
 ******************************************************************************/
#include <stdint.h>
#include <adf.h>
#include <aie_api/aie.hpp>

typedef aie::mmul<4, 8, 8, bfloat16, bfloat16, accauto> MM;
typedef aie::vector<float, 32> V32;
typedef aie::vector<bfloat16, 32> VB;

alignas(64) float m9_c0[64 * 48];
alignas(64) float m9_c1[64 * 48];
alignas(64) float m9_in[64 * 48];
alignas(64) float m9_st[128];
alignas(64) bfloat16 m9_prm[96];
alignas(64) bfloat16 m9_aw[16 * 3 * 32];
alignas(64) volatile int32_t m9_res[64];

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

// ---- variant 0: the engine
__attribute__((noinline)) static void ln_apply0(float *C, const float *st, const bfloat16 *ch, const bfloat16 *cl) {
    const aie::vector<bfloat16, 8> z8 = aie::zeros<bfloat16, 8>();
    const VB z = aie::zeros<bfloat16, 32>();
    const aie::mask<32> m01 = aie::mask<32>::from_uint32(0x03030303u), m2 = aie::mask<32>::from_uint32(0x04040404u);
    const aie::mask<32> dg = aie::mask<32>::from_uint32(0x08040201u), dg4 = aie::mask<32>::from_uint32(0x80402010u);
    for (unsigned rg = 0; rg < 16; rg++) {
        const float *q = st + rg * 4, *r = st + 64 + rg * 4;
        const V32 qm = aie::concat(aie::broadcast<float, 8>(q[0]), aie::broadcast<float, 8>(q[1]),
                                   aie::broadcast<float, 8>(q[2]), aie::broadcast<float, 8>(q[3]));
        const V32 rs = aie::concat(aie::broadcast<float, 8>(r[0]), aie::broadcast<float, 8>(r[1]),
                                   aie::broadcast<float, 8>(r[2]), aie::broadcast<float, 8>(r[3]));
        const VB rh = to_bf16(rs), rl = to_bf16(aie::sub(rs, to_f32(rh)));
        const VB qh = aie::neg(to_bf16(qm)), ql = aie::neg(to_bf16(aie::sub(qm, to_f32(to_bf16(qm)))));
        const VB a2 = aie::select(z, rh, dg), a1 = aie::select(a2, rl, dg4);
        const VB a3 = aie::select(aie::select(z, qh, m01), ql, m2);
        for (unsigned nt = 0; nt < 6; nt++)
            chess_prepare_for_pipelining {
                float *c = C + (rg * 6 + nt) * 32;
                const V32 cv = aie::load_v<32>(c);
                const VB c_h = to_bf16(cv), c_l = to_bf16(aie::sub(cv, to_f32(c_h)));
                const aie::vector<bfloat16, 8> h8 = aie::load_v<8>(ch + nt * 8);
                MM acc;
                acc.mul(a1, aie::concat(c_h, c_h));
                acc.mac(a2, aie::concat(c_l, z));
                acc.mac(a3, aie::concat(h8, aie::load_v<8>(cl + nt * 8), h8, z8, z8, z8, z8, z8));
                aie::store_v(c, acc.template to_vector<float>());
            }
    }
}

// per row group: the A operands (a1 = [diag rh | diag rl], a2 = [diag rh | 0], a3 = rows -qh, -qh, -ql)
__attribute__((noinline)) static void ln_stage(const float *st, bfloat16 *aw) {
    const VB z = aie::zeros<bfloat16, 32>();
    const aie::mask<32> m01 = aie::mask<32>::from_uint32(0x03030303u), m2 = aie::mask<32>::from_uint32(0x04040404u);
    const aie::mask<32> dg = aie::mask<32>::from_uint32(0x08040201u), dg4 = aie::mask<32>::from_uint32(0x80402010u);
    for (unsigned rg = 0; rg < 16; rg++) {
        const float *q = st + rg * 4, *r = st + 64 + rg * 4;
        const V32 qm = aie::concat(aie::broadcast<float, 8>(q[0]), aie::broadcast<float, 8>(q[1]),
                                   aie::broadcast<float, 8>(q[2]), aie::broadcast<float, 8>(q[3]));
        const V32 rs = aie::concat(aie::broadcast<float, 8>(r[0]), aie::broadcast<float, 8>(r[1]),
                                   aie::broadcast<float, 8>(r[2]), aie::broadcast<float, 8>(r[3]));
        const VB rh = to_bf16(rs), rl = to_bf16(aie::sub(rs, to_f32(rh)));
        const VB qh = aie::neg(to_bf16(qm)), ql = aie::neg(to_bf16(aie::sub(qm, to_f32(to_bf16(qm)))));
        const VB a2 = aie::select(z, rh, dg), a1 = aie::select(a2, rl, dg4);
        aie::store_v(aw + rg * 96, a1);
        aie::store_v(aw + rg * 96 + 32, a2);
        aie::store_v(aw + rg * 96 + 64, aie::select(aie::select(z, qh, m01), ql, m2));
    }
}
// one tile
__attribute__((always_inline)) static inline void ln_tile(float *c, const VB &a1, const VB &a2, const VB &a3,
                                                          const aie::vector<bfloat16, 64> &b3) {
    const VB z = aie::zeros<bfloat16, 32>();
    const V32 cv = aie::load_v<32>(c);
    const VB c_h = to_bf16(cv), c_l = to_bf16(aie::sub(cv, to_f32(c_h)));
    MM acc;
    acc.mul(a1, aie::concat(c_h, c_h));
    acc.mac(a2, aie::concat(c_l, z));
    acc.mac(a3, b3);
    aie::store_v(c, acc.template to_vector<float>());
}
// B3 rows [c_hi; c_lo; c_hi; 0..] for column tile nt
__attribute__((always_inline)) static inline aie::vector<bfloat16, 64> ln_b3(const bfloat16 *ch, const bfloat16 *cl,
                                                                             unsigned nt) {
    const aie::vector<bfloat16, 8> z8 = aie::zeros<bfloat16, 8>(), h8 = aie::load_v<8>(ch + nt * 8);
    return aie::concat(h8, aie::load_v<8>(cl + nt * 8), h8, z8, z8, z8, z8, z8);
}

// ---- variant 1: staged A operands, nt unrolled (6 independent tiles per row group)
__attribute__((noinline)) static void ln_apply1(float *__restrict C, const float *st, const bfloat16 *ch,
                                                const bfloat16 *cl) {
    ln_stage(st, m9_aw);
    for (unsigned rg = 0; rg < 16; rg++)
        chess_prepare_for_pipelining chess_loop_range(16, 16) {
            const VB a1 = aie::load_v<32>(m9_aw + rg * 96), a2 = aie::load_v<32>(m9_aw + rg * 96 + 32),
                     a3 = aie::load_v<32>(m9_aw + rg * 96 + 64);
            for (unsigned nt = 0; nt < 6; nt++)
                chess_unroll_loop() ln_tile(C + (rg * 6 + nt) * 32, a1, a2, a3, ln_b3(ch, cl, nt));
        }
}

// ---- variant 2: staged A operands, column tile outer, row groups pipelined
__attribute__((noinline)) static void ln_apply2(float *__restrict C, const float *st, const bfloat16 *ch,
                                                const bfloat16 *cl) {
    ln_stage(st, m9_aw);
    for (unsigned nt = 0; nt < 6; nt++) {
        const aie::vector<bfloat16, 64> b3 = ln_b3(ch, cl, nt);
        for (unsigned rg = 0; rg < 16; rg++)
            chess_prepare_for_pipelining chess_loop_range(16, 16)
                ln_tile(C + (rg * 6 + nt) * 32, aie::load_v<32>(m9_aw + rg * 96), aie::load_v<32>(m9_aw + rg * 96 + 32),
                        aie::load_v<32>(m9_aw + rg * 96 + 64), b3);
    }
}

// ---- variant 3: as 2, two row groups per iteration
__attribute__((noinline)) static void ln_apply3(float *__restrict C, const float *st, const bfloat16 *ch,
                                                const bfloat16 *cl) {
    ln_stage(st, m9_aw);
    for (unsigned nt = 0; nt < 6; nt++) {
        const aie::vector<bfloat16, 64> b3 = ln_b3(ch, cl, nt);
        for (unsigned rg = 0; rg < 16; rg += 2)
            chess_prepare_for_pipelining chess_loop_range(8, 8) {
                ln_tile(C + (rg * 6 + nt) * 32, aie::load_v<32>(m9_aw + rg * 96), aie::load_v<32>(m9_aw + rg * 96 + 32),
                        aie::load_v<32>(m9_aw + rg * 96 + 64), b3);
                ln_tile(C + ((rg + 1) * 6 + nt) * 32, aie::load_v<32>(m9_aw + rg * 96 + 96),
                        aie::load_v<32>(m9_aw + rg * 96 + 128), aie::load_v<32>(m9_aw + rg * 96 + 160), b3);
            }
    }
}

__attribute__((noinline)) static void restore(float *C) {
    for (unsigned i = 0; i < 96; i++)
        chess_prepare_for_pipelining aie::store_v(C + i * 32, aie::load_v<32>(m9_in + i * 32));
}
typedef void (*ln_fn)(float *, const float *, const bfloat16 *, const bfloat16 *);
static void nop_fn(float *, const float *, const bfloat16 *, const bfloat16 *) {}
static int32_t time_it(ln_fn f, float *C) {
    restore(C);
    f(C, m9_st, m9_prm, m9_prm + 48);
    const uint64_t t0 = aie::tile::current().cycles();
    for (int r = 0; r < 8; r++) {
        restore(C);
        f(C, m9_st, m9_prm, m9_prm + 48);
    }
    const uint64_t t1 = aie::tile::current().cycles();
    restore(C);
    f(C, m9_st, m9_prm, m9_prm + 48);
    return (int32_t)(t1 - t0);
}
static int32_t diff(const float *a, const float *b) {
    int32_t n = 0;
    const uint32_t *x = (const uint32_t *)a, *y = (const uint32_t *)b;
    for (int i = 0; i < 64 * 48; i++)
        n += x[i] != y[i];
    return n;
}

// kernel_decl m9
int32_t main() {
    for (int i = 0; i < 64 * 48; i++)
        m9_in[i] = (float)((i * 7919) % 20011 - 10005) * 0.0137f;
    for (int i = 0; i < 64; i++) {
        m9_st[i] = 0.37f + 0.011f * (float)(i % 13) - 0.2f * (float)(i % 3); /* rstd mu */
        m9_st[64 + i] = 1.9f + 0.173f * (float)(i % 7);                      /* rstd */
    }
    for (int i = 0; i < 96; i++)
        m9_prm[i] = (bfloat16)((float)(i % 17 - 8) * 0.29f);
    const int32_t base = time_it(nop_fn, m9_c1);
    static const ln_fn f[4] = {ln_apply0, ln_apply1, ln_apply2, ln_apply3};
    m9_res[2] = time_it(f[0], m9_c0) - base;
    m9_res[3] = 0;
    for (int v = 1; v < 4; v++) {
        m9_res[2 + 2 * v] = time_it(f[v], m9_c1) - base;
        m9_res[3 + 2 * v] = diff(m9_c0, m9_c1);
    }
    m9_res[1] = 4;
    m9_res[0] = 0x4D394F4B; /* "M9OK" */
    return 0;
}
