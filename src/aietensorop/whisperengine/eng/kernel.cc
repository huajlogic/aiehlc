/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * Whisper engine -- the persistent AIE core program. Loaded once, it runs
 * every op of Whisper-tiny forever: each op begins with a header on the A
 * channel (we_desc.h) naming the op and its shape; the core then programs its
 * own tile DMAs for exactly that op, computes, and waits for its output to
 * drain before reading the next header. Operands are replayed from the memory
 * tiles (engine_fabric.h); outputs leave as packets to the shim.
 ******************************************************************************/
#include <stdint.h>
#include <adf.h>
#include <aie_api/aie.hpp>
#include "aie_kernel_runtime.h"
#include "engine_fabric.h"
#include "we_desc.h"

/* One arena, carved per op (offsets below). The header always lands in A0.
 * The GELU table sits in two fixed 8 KB-aligned spots (aieml.bcf) so its two
 * copies are in different banks, as aie::lut<4> requires. */
#define AR_A0 0x0000  /* A ping 6 KB (header too) */
#define AR_A1 0x1800  /* A pong 6 KB              */
#define AR_B0 0x3000  /* B ping 4.5 KB            */
#define AR_B1 0x4200  /* B pong 4.5 KB            */
#define AR_C 0x5400   /* GEMM accumulators 12 KB  */
#define AR_OUT 0x8400 /* output block 6 KB        */
#define AR_PRM 0x9C00 /* per-op params 3 KB       */
#define AR_BYTES 0xA800
alignas(64) int8_t we_arena[AR_BYTES];
#define AR(off, T) ((T *)(we_arena + (off)))
#include "we_gelu_lut.h"
alignas(64) uint16_t we_gelu_ab[2 * WE_GELU_LUT_N] = WE_GELU_LUT_INIT;
alignas(64) uint16_t we_gelu_cd[2 * WE_GELU_LUT_N] = WE_GELU_LUT_INIT;

static const int k_pkt[EF_MESH_ROWS][EF_MESH_COLS] = EF_PKT_ID_TABLE;
static const int k_ooo[EF_MESH_ROWS][EF_MESH_COLS] = EF_OOO_BD_TABLE;

#define LK_ACQ(id, v) acquire_greater_equal(EF_LOCK_BASE + (id), (v))
#define LK_REL(id, v) release(EF_LOCK_BASE + (id), (v))

typedef aie::mmul<4, 8, 8, bfloat16, bfloat16, accauto> MM;
typedef aie::vector<float, 32> V32;

static int g_mr, g_mc, g_pkt, g_ooo;

// ---- tile DMA programming ---------------------------------------------------
static void cfg_s2mm(int ch, int bd0, int bd1, unsigned o0, unsigned o1, unsigned len, int lk_e, int lk_f,
                     unsigned rounds) {
    AieKcReg kc[8];
    if (rounds == 1) {
        core_reg_write_block(
            kc, aie_kc_encode_bd(kc, bd0, (uintptr_t)(we_arena + o0), len, -1, lk_e, -1, lk_f, 1, 0, 0, 0, -1));
        aie_kc_encode_s2mm_start(kc, ch, bd0, 1, 0);
    } else {
        core_reg_write_block(
            kc, aie_kc_encode_bd(kc, bd1, (uintptr_t)(we_arena + o1), len, -1, lk_e, -1, lk_f, 1, 0, 0, 0, -1));
        core_reg_write_block(
            kc, aie_kc_encode_bd(kc, bd0, (uintptr_t)(we_arena + o0), len, bd1, lk_e, -1, lk_f, 1, 0, 0, 0, -1));
        aie_kc_encode_s2mm_start(kc, ch, bd0, rounds / 2, 0);
    }
    core_reg_write(kc[0].off, kc[0].val);
}
static void cfg_a(unsigned len, unsigned rounds) {
    cfg_s2mm(0, EF_BD_IN_PING, EF_BD_IN_PONG, AR_A0, AR_A1, len, EF_LK_IN_EMPTY, EF_LK_IN_FULL, rounds);
}
static void cfg_b(unsigned len, unsigned rounds) {
    cfg_s2mm(1, EF_BD_W_PING, EF_BD_W_PONG, AR_B0, AR_B1, len, EF_LK_W_EMPTY, EF_LK_W_FULL, rounds);
}
static void cfg_out(unsigned len, unsigned rounds) {
    AieKcReg kc[8];
    core_reg_write_block(kc, aie_kc_encode_bd(kc, EF_BD_OUT_PING, (uintptr_t)(we_arena + AR_OUT), len, -1,
                                              EF_LK_OUT_FULL, -1, EF_LK_OUT_EMPTY, 1, 1, g_pkt, 0, g_ooo));
    aie_kc_encode_mm2s_start(kc, 0, EF_BD_OUT_PING, rounds, 0);
    core_reg_write(kc[0].off, kc[0].val);
}
static void out_drained() {
    LK_ACQ(EF_LK_OUT_EMPTY, 1);
    LK_REL(EF_LK_OUT_EMPTY, 1);
}

// ---- GEMM -------------------------------------------------------------------
// C[64x48] += A chunk (64x48) * B chunk (48x48); 2x2 register blocking.
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
                    const aie::vector<bfloat16, 32> a0 = aie::load_v<32>(pa0 + k * 32);
                    const aie::vector<bfloat16, 32> a1 = aie::load_v<32>(pa1 + k * 32);
                    const aie::vector<bfloat16, 64> b0 = aie::load_v<64>(pb + k * 6 * 64);
                    const aie::vector<bfloat16, 64> b1 = aie::load_v<64>(pb + k * 6 * 64 + 64);
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

__attribute__((noinline)) static void zero_c(float *C) {
    const V32 z = aie::zeros<float, 32>();
    for (unsigned i = 0; i < WE_TM * WE_TN / 32; i++)
        chess_prepare_for_pipelining aie::store_v(C + i * 32, z);
}

// float vector arithmetic that stays in vector<float> (aie::mul yields an accumulator)
template <typename A, typename B> __attribute__((always_inline)) static inline V32 fmul(const A &a, const B &b) {
    return aie::mul(a, b).template to_vector<float>();
}
template <typename A, typename B> __attribute__((always_inline)) static inline V32 fadd(const A &a, const B &b) {
    return V32(aie::add(a, b));
}

__attribute__((always_inline)) static inline V32 to_f32(const aie::vector<bfloat16, 32> &v) {
    aie::accum<accfloat, 32> acc;
    acc.from_vector(v, 0);
    return acc.template to_vector<float>();
}

__attribute__((always_inline)) static inline aie::vector<bfloat16, 32> to_bf16(const V32 &v) {
    aie::accum<accfloat, 32> acc;
    acc.from_vector(v, 0);
    return acc.template to_vector<bfloat16>();
}

typedef aie::vector<bfloat16, 32> VB;
typedef aie::vector<int16, 32> VI;

// Exact erf-GELU of a bf16 value (we_model.gelu_aie): table for 1/8 <= |x| < 4,
// 0.5x + bf16(x^2)/sqrt(2 pi) below, x / 0 beyond. Only native ops: integer,
// table lookup, bf16 x bf16 -> fp32 products, fp32 add.
__attribute__((always_inline)) static inline VB gelu_bf16(const VB &xb) {
    static aie::lut<4, bfloat16> lut(WE_GELU_LUT_N, we_gelu_ab, we_gelu_cd);
    aie::parallel_lookup<int16, aie::lut<4, bfloat16>> lk(lut, 0, 0);
    const VI u = xb.template cast_to<int16>();
    const VI e = aie::bit_and((int16)0xFF, aie::downshift(u, 7));
    const VI m = aie::bit_and((int16)0x7F, u);
    const aie::mask<32> neg = aie::lt(u, (int16)0);
    VI idx = aie::add(aie::upshift(aie::sub(e, (int16)124), 7), m);
    idx = aie::select(idx, aie::add(idx, (int16)640), neg);
    const VB tab = lk.fetch(idx);
    // small |x|: 0.5 x + bf16(x^2) * c
    aie::accum<accfloat, 32> acc = aie::mul(xb, aie::broadcast<bfloat16, 32>((bfloat16)0.5f));
    const VB x2 = aie::mul(xb, xb).template to_vector<bfloat16>();
    acc = aie::mac(acc, x2, aie::broadcast<bfloat16, 32>((bfloat16)0.3989422804f));
    const VB small = acc.template to_vector<bfloat16>();
    VB y = aie::select(tab, small, aie::lt(e, (int16)124));
    y = aie::select(y, aie::select(xb, aie::zeros<bfloat16, 32>(), neg), aie::ge(e, (int16)129));
    return y;
}

// out = bf16(epi(C)) in [rg16][nt6][4][8]; res (bf16, same layout) or null.
__attribute__((noinline)) static void epilogue(const float *C, const float *bias8, const bfloat16 *res, bfloat16 *out,
                                               int flags) {
    for (unsigned rg = 0; rg < 16; rg++)
        for (unsigned nt = 0; nt < 6; nt++)
            chess_prepare_for_pipelining {
                const unsigned o = (rg * 6 + nt) * 32;
                V32 v = aie::load_v<32>(C + o);
                if (flags & WE_F_BIAS) {
                    const aie::vector<float, 8> b8 = aie::load_v<8>(bias8 + nt * 8);
                    v = aie::add(v, aie::concat(b8, b8, b8, b8));
                }
                if (flags & WE_F_RES)
                    v = aie::add(v, to_f32(aie::load_v<32>(res + o))); /* x + d, rounded once */
                VB y = to_bf16(v);
                if (flags & WE_F_GELU)
                    y = gelu_bf16(y);
                aie::store_v(out + o, y);
            }
}

// Transposed variant for K: [dt 6][kp 8][8 dims][8 keys].
__attribute__((noinline)) static void epilogue_kt(const float *C, const float *bias8, bfloat16 *out, int flags) {
    for (unsigned kp = 0; kp < 8; kp++)
        for (unsigned nt = 0; nt < 6; nt++)
            chess_prepare_for_pipelining {
                V32 lo = aie::load_v<32>(C + ((2 * kp) * 6 + nt) * 32);
                V32 hi = aie::load_v<32>(C + ((2 * kp + 1) * 6 + nt) * 32);
                if (flags & WE_F_BIAS) {
                    const aie::vector<float, 8> b8 = aie::load_v<8>(bias8 + nt * 8);
                    const V32 b = aie::concat(b8, b8, b8, b8);
                    lo = aie::add(lo, b);
                    hi = aie::add(hi, b);
                }
                // [8 keys][8 dims] row-major -> [8 dims][8 keys]
                const aie::vector<bfloat16, 64> kd = aie::concat(to_bf16(lo), to_bf16(hi));
                aie::store_v(out + (nt * 8 + kp) * 64, aie::transpose(kd, 8, 8));
            }
}

// bf16 parameters (header) -> fp32 table, vectorized (n multiple of 32)
__attribute__((noinline)) static void prm_to_f32(const bfloat16 *src, float *dst, unsigned n) {
    for (unsigned i = 0; i < n; i += 32)
        chess_prepare_for_pipelining aie::store_v(dst + i, to_f32(aie::load_v<32>(src + i)));
}

static void op_gemm(const int32_t *h) {
    const int MB = h[WH_MB], NB = h[WH_NB], KCN = h[WH_KCN], flags = h[WH_FLAGS];
    const int kt_lo = h[WH_KT_LO], kt_hi = h[WH_KT_HI];
    float *bias8 = AR(AR_PRM, float); /* [N]: tile cb at cb*48 */
    if (flags & WE_F_BIAS)            /* all N (aligned start), indexed by tile below */
        prm_to_f32((const bfloat16 *)((const int8_t *)h + WE_PRM_OFF), bias8, (unsigned)(h[WH_N] + 31) & ~31u);
    chess_memory_fence();
    LK_REL(EF_LK_IN_EMPTY, 1); /* header consumed */
    const int res = flags & WE_F_RES;
    const unsigned blocks = (unsigned)(NB * MB);
    const unsigned a_per_blk = (unsigned)KCN + (res ? 4u : 0u);
    cfg_a(WE_A_CHUNK, blocks * a_per_blk);
    cfg_b(WE_B_CHUNK, blocks * KCN);
    cfg_out(WE_BLK, blocks);
    float *C = AR(AR_C, float);
    bfloat16 *out = AR(AR_OUT, bfloat16);
    unsigned ia = 0, ib = 0;
    for (int nb = 0; nb < NB; nb++) {
        const int cb = g_mc * NB + nb;
        const int kt = (flags & WE_F_KT) && cb >= kt_lo && cb < kt_hi;
        for (int mb = 0; mb < MB; mb++) {
            zero_c(C);
            for (int k = 0; k < KCN; k++) {
                LK_ACQ(EF_LK_IN_FULL, 1);
                LK_ACQ(EF_LK_W_FULL, 1);
                mac_chunk(AR(ia ? AR_A1 : AR_A0, bfloat16), AR(ib ? AR_B1 : AR_B0, bfloat16), C);
                LK_REL(EF_LK_IN_EMPTY, 1);
                LK_REL(EF_LK_W_EMPTY, 1);
                ia ^= 1;
                ib ^= 1;
            }
            LK_ACQ(EF_LK_OUT_EMPTY, 1);
            if (res) {
                // 4 chunks, one per mesh column; ours (chunk mc) -> out, the epilogue adds it in place
                for (int q = 0; q < 4; q++) {
                    LK_ACQ(EF_LK_IN_FULL, 1);
                    if (q == g_mc) {
                        const bfloat16 *src = AR(ia ? AR_A1 : AR_A0, bfloat16);
                        for (unsigned i = 0; i < WE_BLK / 2 / 32; i++)
                            aie::store_v(out + i * 32, aie::load_v<32>(src + i * 32));
                    }
                    LK_REL(EF_LK_IN_EMPTY, 1);
                    ia ^= 1;
                }
            }
            if (kt)
                epilogue_kt(C, bias8 + cb * WE_TN, out, flags);
            else
                epilogue(C, bias8 + cb * WE_TN, out, out, flags);
            chess_memory_fence();
            LK_REL(EF_LK_OUT_FULL, 1);
        }
    }
    out_drained();
}

// ---- LayerNorm ----------------------------------------------------------------
// Sum the 8 lanes of each 4-row group's row (lanes i*8 .. i*8+7), result
// replicated across those 8 lanes. Vector-only: the scalar unit has no FPU.
__attribute__((always_inline)) static inline V32 row_sum8(const V32 &v) {
    V32 t = aie::add(v, aie::shuffle_down(v, 4));
    t = aie::add(t, aie::shuffle_down(t, 2));
    t = aie::add(t, aie::shuffle_down(t, 1)); /* lane i*8 holds row i's sum */
    return aie::concat(aie::broadcast<float, 8>(t[0]), aie::broadcast<float, 8>(t[8]), aie::broadcast<float, 8>(t[16]),
                       aie::broadcast<float, 8>(t[24]));
}

// One 4-row group: x [cb 8][kt 6][4][8] bf16 -> y same layout. Statistics in
// fp32: E[x] by native adds, E[x^2] by native bf16 x bf16 MACs (exact squares);
// var = E[x^2] - E[x]^2 is safe here (Whisper's LN inputs: mean^2/var <= 11).
__attribute__((noinline)) static void ln_group(const bfloat16 *x, bfloat16 *y, const float *g8, const float *b8,
                                               const V32 &epsv) {
    V32 s = aie::zeros<float, 32>();
    aie::accum<accfloat, 32> q;
    q.from_vector(aie::zeros<float, 32>(), 0);
    for (unsigned t = 0; t < 48; t++)
        chess_prepare_for_pipelining {
            const VB xb = aie::load_v<32>(x + t * 32);
            s = aie::add(s, to_f32(xb));
            q = aie::mac(q, xb, xb);
        }
    const V32 inv_n = aie::broadcast<float, 32>(1.0f / 384.0f);
    const V32 mv = fmul(row_sum8(s), inv_n);
    const V32 ex2 = fmul(row_sum8(q.template to_vector<float>()), inv_n);
    const V32 rv = aie::invsqrt(aie::add(aie::sub(ex2, fmul(mv, mv)), epsv));
    for (unsigned t = 0; t < 48; t++)
        chess_prepare_for_pipelining {
            const aie::vector<float, 8> gg = aie::load_v<8>(g8 + t * 8), bb = aie::load_v<8>(b8 + t * 8);
            const V32 d = aie::sub(to_f32(aie::load_v<32>(x + t * 32)), mv);
            const V32 rg = fmul(rv, aie::concat(gg, gg, gg, gg));
            aie::store_v(y + t * 32, to_bf16(aie::add(fmul(d, rg), aie::concat(bb, bb, bb, bb))));
        }
}

static void op_ln(const int32_t *h) {
    const int RGC = h[WH_RGC];
    const V32 epsv = aie::broadcast<int32, 32>(h[WH_EPS]).template cast_to<float>();
    float *g8 = AR(AR_PRM, float), *b8 = g8 + 384;
    prm_to_f32((const bfloat16 *)((const int8_t *)h + WE_PRM_OFF), g8, 768);
    chess_memory_fence();
    LK_REL(EF_LK_IN_EMPTY, 1);
    const unsigned total = 4u * RGC; /* every group of the row block passes every core */
    cfg_a(WE_RG_ROW, total);
    cfg_out(WE_RG_ROW, RGC);
    unsigned ia = 0;
    for (unsigned g = 0; g < total; g++) {
        LK_ACQ(EF_LK_IN_FULL, 1);
        if ((int)(g & 3) == g_mc) { /* interleaved: the 4 cores of a row work in parallel */
            LK_ACQ(EF_LK_OUT_EMPTY, 1);
            ln_group(AR(ia ? AR_A1 : AR_A0, bfloat16), AR(AR_OUT, bfloat16), g8, b8, epsv);
            chess_memory_fence();
            LK_REL(EF_LK_OUT_FULL, 1);
        }
        LK_REL(EF_LK_IN_EMPTY, 1);
        ia ^= 1;
    }
    out_drained();
}

// kernel_decl eng
int32_t main() {
    AieKcReg kc[2];
    const int init[6][2] = {{EF_LK_IN_EMPTY, 2}, {EF_LK_IN_FULL, 0},   {EF_LK_W_EMPTY, 2},
                            {EF_LK_W_FULL, 0},   {EF_LK_OUT_EMPTY, 1}, {EF_LK_OUT_FULL, 0}};
    for (int i = 0; i < 6; i++) {
        aie_kc_encode_lock(kc, init[i][0], init[i][1]);
        core_reg_write(kc[0].off, kc[0].val);
    }
    aie::set_rounding(aie::rounding_mode::conv_even);
    const unsigned cid = get_coreid();
    g_mc = ((int)(cid >> 16) - EF_PART_START_COL - EF_FIRST_COL) % EF_PART_NUM_COLS;
    g_mr = (int)(cid & 0x1F) - EF_FIRST_ROW;
    g_pkt = k_pkt[g_mr][g_mc];
    g_ooo = k_ooo[g_mr][g_mc];
    for (;;) {
        cfg_a(WE_HDR_BYTES, 1);
        LK_ACQ(EF_LK_IN_FULL, 1);
        const int32_t *h = AR(AR_A0, int32_t);
        const int op = h[WH_OP];
        if (g_mr >= h[WH_RACT]) { /* idle row: header only; drain the column-broadcast B */
            const unsigned nbk = op == WE_OP_GEMM ? (unsigned)(h[WH_NB] * h[WH_MB] * h[WH_KCN]) : 0u;
            LK_REL(EF_LK_IN_EMPTY, 1);
            if (nbk) {
                cfg_b(WE_B_CHUNK, nbk);
                for (unsigned i = 0; i < nbk; i++) {
                    LK_ACQ(EF_LK_W_FULL, 1);
                    LK_REL(EF_LK_W_EMPTY, 1);
                }
            }
            continue;
        }
        if (op == WE_OP_GEMM)
            op_gemm(h);
        else if (op == WE_OP_LN)
            op_ln(h);
        else
            LK_REL(EF_LK_IN_EMPTY, 1);
    }
    return 0;
}
