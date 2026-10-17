/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * M8 -- GEMM epilogue probe: the engine's GELU epilogue (64x48 block, + bias,
 * erf-GELU by table, bf16 out) against restructured variants. Every variant
 * must reproduce variant 0 bit for bit; cycles of 8 calls land in m8_res.
 ******************************************************************************/
#include <stdint.h>
#include <adf.h>
#include <aie_api/aie.hpp>
#include "we_gelu_lut.h"

typedef aie::vector<float, 32> V32;
typedef aie::vector<bfloat16, 32> VB;
typedef aie::vector<int16, 32> VI;

alignas(64) float m8_c[64 * 48];
alignas(64) bfloat16 m8_o0[64 * 48];
alignas(64) bfloat16 m8_o1[64 * 48];
alignas(64) float m8_b[48];
alignas(64) volatile int32_t m8_res[64];
alignas(64) uint16_t we_gelu_ab[2 * WE_GELU_LUT_N] = WE_GELU_LUT_INIT;
alignas(64) uint16_t we_gelu_cd[2 * WE_GELU_LUT_N] = WE_GELU_LUT_INIT;

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

// ---- variant 0: the engine (eng/kernel.cc gelu_bf16 + epilogue, GELU, no residual)
__attribute__((always_inline)) static inline VB gelu_bf16(const VB &xb) {
    const aie::lut<4, bfloat16> lut(WE_GELU_LUT_N, we_gelu_ab, we_gelu_cd);
    aie::parallel_lookup<int16, aie::lut<4, bfloat16>> lk(lut, 0, 0);
    const VI u = xb.template cast_to<int16>();
    const VI e = aie::bit_and((int16)0xFF, aie::downshift(u, 7));
    const VI m = aie::bit_and((int16)0x7F, u);
    const aie::mask<32> neg = aie::lt(u, (int16)0);
    VI idx = aie::add(aie::upshift(aie::sub(e, (int16)124), 7), m);
    idx = aie::select(idx, aie::add(idx, (int16)640), neg);
    const VB tab = lk.fetch(idx);
    aie::accum<accfloat, 32> acc = aie::mul(xb, aie::broadcast<bfloat16, 32>((bfloat16)0.5f));
    const VB x2 = aie::mul(xb, xb).template to_vector<bfloat16>();
    acc = aie::mac(acc, x2, aie::broadcast<bfloat16, 32>((bfloat16)0.3989422804f));
    const VB small = acc.template to_vector<bfloat16>();
    VB y = aie::select(tab, small, aie::lt(e, (int16)124));
    y = aie::select(y, aie::select(xb, aie::zeros<bfloat16, 32>(), neg), aie::ge(e, (int16)129));
    return y;
}
alignas(64) static const bfloat16 k_zero32[32] = {};
__attribute__((noinline)) static void epi0(const float *C, const float *bias8, bfloat16 *out) {
    for (unsigned nt = 0; nt < 6; nt++) {
        const aie::vector<float, 8> b8 = aie::load_v<8>(bias8 + nt * 8);
        const V32 b = aie::concat(b8, b8, b8, b8);
        const float *c = C + nt * 32;
        const bfloat16 *r = k_zero32;
        bfloat16 *o = out + nt * 32;
        for (unsigned rg = 0; rg < 16; rg++)
            chess_prepare_for_pipelining chess_loop_range(16, 16) {
                const VB g = gelu_bf16(to_bf16(aie::add(aie::load_v<32>(c + rg * 192), b)));
                aie::store_v(o + rg * 192, to_bf16(aie::add(to_f32(g), to_f32(aie::load_v<32>(r)))));
            }
    }
}

// ---- variant 1: two loops (bias + round, then GELU in place), magnitude compares
__attribute__((always_inline)) static inline VB gelu_v1(const VB &xb) {
    const aie::lut<4, bfloat16> lut(WE_GELU_LUT_N, we_gelu_ab, we_gelu_cd);
    aie::parallel_lookup<int16, aie::lut<4, bfloat16>> lk(lut, 0, 0);
    const VI u = xb.template cast_to<int16>();
    const VI a = aie::bit_and((int16)0x7FFF, u); /* |x| bits: exponent << 7 | mantissa */
    const aie::mask<32> neg = aie::lt(u, (int16)0);
    VI idx = aie::sub(a, (int16)(124 << 7));
    idx = aie::select(idx, aie::add(idx, (int16)640), neg);
    const VB tab = lk.fetch(idx);
    aie::accum<accfloat, 32> acc = aie::mul(xb, aie::broadcast<bfloat16, 32>((bfloat16)0.5f));
    const VB x2 = aie::mul(xb, xb).template to_vector<bfloat16>();
    acc = aie::mac(acc, x2, aie::broadcast<bfloat16, 32>((bfloat16)0.3989422804f));
    const VB small = acc.template to_vector<bfloat16>();
    VB y = aie::select(tab, small, aie::lt(a, (int16)(124 << 7)));
    y = aie::select(y, aie::select(xb, aie::zeros<bfloat16, 32>(), neg), aie::ge(a, (int16)(129 << 7)));
    return y;
}
__attribute__((noinline)) static void epi1(const float *C, const float *bias8, bfloat16 *out) {
    for (unsigned nt = 0; nt < 6; nt++) {
        const aie::vector<float, 8> b8 = aie::load_v<8>(bias8 + nt * 8);
        const V32 b = aie::concat(b8, b8, b8, b8);
        for (unsigned rg = 0; rg < 16; rg++)
            chess_prepare_for_pipelining chess_loop_range(16, 16)
                aie::store_v(out + rg * 192 + nt * 32, to_bf16(aie::add(aie::load_v<32>(C + rg * 192 + nt * 32), b)));
    }
    for (unsigned i = 0; i < 96; i++)
        chess_prepare_for_pipelining chess_loop_range(96, 96)
            aie::store_v(out + i * 32, gelu_v1(aie::load_v<32>(out + i * 32)));
}

// ---- variant 2: as 1, the GELU loop two vectors per iteration
__attribute__((noinline)) static void epi2(const float *C, const float *bias8, bfloat16 *out) {
    for (unsigned nt = 0; nt < 6; nt++) {
        const aie::vector<float, 8> b8 = aie::load_v<8>(bias8 + nt * 8);
        const V32 b = aie::concat(b8, b8, b8, b8);
        for (unsigned rg = 0; rg < 16; rg++)
            chess_prepare_for_pipelining chess_loop_range(16, 16)
                aie::store_v(out + rg * 192 + nt * 32, to_bf16(aie::add(aie::load_v<32>(C + rg * 192 + nt * 32), b)));
    }
    for (unsigned i = 0; i < 96; i += 2)
        chess_prepare_for_pipelining chess_loop_range(48, 48) {
            const VB x0 = aie::load_v<32>(out + i * 32), x1 = aie::load_v<32>(out + i * 32 + 32);
            aie::store_v(out + i * 32, gelu_v1(x0));
            aie::store_v(out + i * 32 + 32, gelu_v1(x1));
        }
}

// ---- variant 3: GELU loop without the lut object: small/large paths only (timing floor)
__attribute__((noinline)) static void epi3(const float *C, const float *bias8, bfloat16 *out) {
    for (unsigned nt = 0; nt < 6; nt++) {
        const aie::vector<float, 8> b8 = aie::load_v<8>(bias8 + nt * 8);
        const V32 b = aie::concat(b8, b8, b8, b8);
        for (unsigned rg = 0; rg < 16; rg++)
            chess_prepare_for_pipelining chess_loop_range(16, 16)
                aie::store_v(out + rg * 192 + nt * 32, to_bf16(aie::add(aie::load_v<32>(C + rg * 192 + nt * 32), b)));
    }
}

// ---- variants 4, 5: GELU out of place through restrict pointers (x staged in m8_x)
alignas(64) bfloat16 m8_x[64 * 48];
__attribute__((noinline)) static void gelu_loop(const bfloat16 *__restrict x, bfloat16 *__restrict o, unsigned n) {
    for (unsigned i = 0; i < n; i++)
        chess_prepare_for_pipelining chess_loop_range(8, )
            aie::store_v(o + i * 32, gelu_v1(aie::load_v<32>(x + i * 32)));
}
__attribute__((noinline)) static void gelu_loop2(const bfloat16 *__restrict x, bfloat16 *__restrict o, unsigned n) {
    for (unsigned i = 0; i < n; i += 2)
        chess_prepare_for_pipelining chess_loop_range(4, ) {
            const VB x0 = aie::load_v<32>(x + i * 32), x1 = aie::load_v<32>(x + i * 32 + 32);
            aie::store_v(o + i * 32, gelu_v1(x0));
            aie::store_v(o + i * 32 + 32, gelu_v1(x1));
        }
}
__attribute__((noinline)) static void bias_round(const float *__restrict C, const float *__restrict bias8,
                                                 bfloat16 *__restrict x) {
    for (unsigned nt = 0; nt < 6; nt++) {
        const aie::vector<float, 8> b8 = aie::load_v<8>(bias8 + nt * 8);
        const V32 b = aie::concat(b8, b8, b8, b8);
        for (unsigned rg = 0; rg < 16; rg++)
            chess_prepare_for_pipelining chess_loop_range(16, 16)
                aie::store_v(x + rg * 192 + nt * 32, to_bf16(aie::add(aie::load_v<32>(C + rg * 192 + nt * 32), b)));
    }
}
__attribute__((noinline)) static void epi4(const float *C, const float *bias8, bfloat16 *out) {
    bias_round(C, bias8, m8_x);
    gelu_loop(m8_x, out, 96);
}
__attribute__((noinline)) static void epi5(const float *C, const float *bias8, bfloat16 *out) {
    bias_round(C, bias8, m8_x);
    gelu_loop2(m8_x, out, 96);
}

typedef void (*epi_fn)(const float *, const float *, bfloat16 *);
static void time_it(int slot, epi_fn f, bfloat16 *o) {
    f(m8_c, m8_b, o);
    const uint64_t t0 = aie::tile::current().cycles();
    for (int r = 0; r < 8; r++)
        f(m8_c, m8_b, o);
    const uint64_t t1 = aie::tile::current().cycles();
    m8_res[2 + 2 * slot] = (int32_t)(t1 - t0);
}
static int32_t diff(const bfloat16 *a, const bfloat16 *b) {
    int32_t n = 0;
    const uint16_t *x = (const uint16_t *)a, *y = (const uint16_t *)b;
    for (int i = 0; i < 64 * 48; i++)
        n += x[i] != y[i];
    return n;
}

// kernel_decl m8
int32_t main() {
    /* x over every regime: |x| < 1/8 (to tiny), the table, >= 4, both signs */
    for (int i = 0; i < 64 * 48; i++) {
        const int k = (i * 37) % 3072;
        float v = ((float)k - 1536.0f) / 192.0f; /* [-8, 8) */
        if (i % 7 == 0)
            v *= 1.0f / 64;
        if (i % 11 == 0)
            v *= 1.0f / 4096;
        m8_c[i] = v;
    }
    for (int i = 0; i < 48; i++)
        m8_b[i] = (float)(i % 5 - 2) * 0.03125f;
    time_it(0, epi0, m8_o0);
    m8_res[3] = 0;
    static const epi_fn f[6] = {epi0, epi1, epi2, epi3, epi4, epi5};
    for (int v = 1; v < 6; v++) {
        for (int i = 0; i < 64 * 48; i++)
            m8_o1[i] = (bfloat16)0.0f;
        time_it(v, f[v], m8_o1);
        m8_res[3 + 2 * v] = v == 3 ? -1 : diff(m8_o0, m8_o1);
    }
    m8_res[1] = 6;
    m8_res[0] = 0x4D384F4B; /* "M8OK" */
    return 0;
}
