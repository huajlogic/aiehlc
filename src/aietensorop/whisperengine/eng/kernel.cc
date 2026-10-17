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

/* One arena, carved per op (offsets below). Data memory is 8 banks of 8 KB
 * (bank b = 0x70000 + b * 0x2000); buffers the core and the DMAs touch at the same
 * time sit in different banks -- with A, B and C sharing banks mac_chunk ran 40%
 * slower in the engine than in the standalone probe (m6).
 *   bank 0: stack, we_dbg, A0          bank 1: A1, PRM | ATT: Q copy, m/l
 *   bank 2: B0, TMP                    bank 3: B1, ST
 *   banks 4-5: C | ATT: S, O           banks 6-7: GELU tables, OUT (we_out)
 * The header always lands in A0 (8 KB: over A0 and the start of A1). The GELU
 * table copies (aieml.bcf) are in different banks, as aie::lut<4> requires. */
#define AR_A0 0x0000  /* A ping 6 KB (header too), bank 0 */
#define AR_A1 0x1800  /* A pong 6 KB, bank 1 */
#define AR_PRM 0x3000 /* own tiles' params 1.5 KB: d fp32 [NB*48], c_hi, c_lo bf16 [NB*48] */
#define AR_B0 0x3800  /* B ping 4.5 KB, bank 2 */
#define AR_TMP 0x4A00 /* LN: per-row-group partial sums of x, x^2 (2 KB) */
#define AR_B1 0x5800  /* B pong 4.5 KB, bank 3 */
#define AR_ST 0x6A00  /* LN: rstd*mu, rstd per row of the op's blocks (3 KB) */
#define AR_C 0x7800   /* GEMM accumulators 12 KB, banks 4-5 */
#define AR_OUT 0xCC00 /* output block 6 KB = we_out (0x7d400, banks 6-7), outside the arena */
#define AR_BYTES 0xB800
/* ATT carve-up */
#define AT_A0 0x0000 /* Q chunk ping 4 KB (header too) */
#define AT_A1 0x1000 /* Q chunk pong 4 KB */
#define AT_Q 0x2000  /* own Q chunk copy 4 KB, bank 1 */
#define AT_ML 0x3000 /* m, l [2][8][32] fp32 (2 KB) */
#define AT_B0 0x3800 /* K or V chunk 8 KB, bank 2 */
#define AT_B1 0x5800 /* bank 3 */
#define AT_S 0x7800  /* S fp32 32x64, P bf16 in place; O bf16 goes out from here (bank 4) */
#define AT_O 0x9800  /* O fp32 32x64 (bank 5) */
alignas(64) int8_t we_arena[AR_BYTES];
alignas(64) int8_t we_out[WE_BLK]; /* aieml.bcf: we_arena + AR_OUT */
#define AR(off, T) ((T *)(we_arena + (off)))
/* attention row state: [0] reference m per row (x8 lanes), [1] denominator l (the row
 * sum, every lane), [2] scratch (raise k, 1/l; in we_out: no GEMM output during attention) */
#define ML(i, rg) ((i) < 2 ? AR(AT_ML, float) + ((i) * 8 + (rg)) * 32 : (float *)we_out + (rg) * 32)
#include "we_gelu_lut.h"
#if WE_PROG != 2
alignas(64) uint16_t we_gelu_ab[2 * WE_GELU_LUT_N] = WE_GELU_LUT_INIT;
alignas(64) uint16_t we_gelu_cd[2 * WE_GELU_LUT_N] = WE_GELU_LUT_INIT;
#else /* the attention program only keeps the symbols aieml.bcf places (no 10 KB .data to load) */
alignas(64) uint16_t we_gelu_ab[2 * WE_GELU_LUT_N];
alignas(64) uint16_t we_gelu_cd[2 * WE_GELU_LUT_N];
#endif
alignas(64) volatile int32_t we_dbg[16]; /* progress for host-side hang dumps (aieml.bcf: 0x707c0) */

static const int k_pkt[EF_MESH_ROWS][EF_MESH_COLS] = EF_PKT_ID_TABLE;
static const int k_ooo[EF_MESH_ROWS][EF_MESH_COLS] = EF_OOO_BD_TABLE;

/* cycle split (never across a lock acquire: skill aiecoretimerlock): WE_PROF_G for
 * the GEMM, WE_PROF_A for attention -- one at a time, both overflow the 16 KB PM */
#if defined(WE_PROF_G) || defined(WE_PROF_A)
#define WE_T(v) const uint64_t v = aie::tile::current().cycles()
#else
#define WE_T(v)
#endif
#ifdef WE_PROF_G
#define WE_ACC(i, d) we_dbg[i] += (int32_t)(d)
#else
#define WE_ACC(i, d)
#endif
#ifdef WE_PROF_A
#define WE_ACCA(i, d) we_dbg[i] += (int32_t)(d)
#else
#define WE_ACCA(i, d)
#endif
#define LK_ACQ(id, v) acquire_greater_equal(EF_LOCK_BASE + (id), (v))
#define LK_REL(id, v) release(EF_LOCK_BASE + (id), (v))

typedef aie::mmul<4, 8, 8, bfloat16, bfloat16, accauto> MM;
typedef aie::vector<float, 32> V32;
typedef aie::vector<bfloat16, 32> VB;

static int g_mr, g_mc, g_pkt, g_ooo;

// ---- tile DMA programming ---------------------------------------------------
// one BD (lock acquire / release, optional packet header) and one channel start,
// each encoded in exactly one place (program memory)
__attribute__((noinline)) static void bd_write(int bd, unsigned off, unsigned len, int next, int lk_acq, int lk_rel,
                                               int pkt) {
    AieKcReg kc[8];
    core_reg_write_block(kc, aie_kc_encode_bd(kc, (uint8_t)bd, (uintptr_t)(we_arena + off), len, next, lk_acq, -1,
                                              lk_rel, 1, pkt, pkt ? g_pkt : 0, 0, pkt ? g_ooo : -1));
}
__attribute__((noinline)) static void ch_start(int ch, int mm2s, int bd, unsigned rounds) {
    AieKcReg kc[2];
    if (mm2s)
        aie_kc_encode_mm2s_start(kc, ch, bd, rounds, 0);
    else
        aie_kc_encode_s2mm_start(kc, ch, bd, rounds, 0);
    core_reg_write(kc[0].off, kc[0].val);
}
__attribute__((noinline)) static void cfg_s2mm(int ch, int bd0, int bd1, unsigned o0, unsigned o1, unsigned len,
                                               int lk_e, int lk_f, unsigned rounds) {
    const int pp = rounds != 1; /* ping-pong pair, else a single BD */
    if (pp)
        bd_write(bd1, o1, len, -1, lk_e, lk_f, 0);
    bd_write(bd0, o0, len, pp ? bd1 : -1, lk_e, lk_f, 0);
    ch_start(ch, 0, bd0, pp ? rounds / 2 : 1);
}
__attribute__((noinline)) static void cfg_a(unsigned len, unsigned rounds) {
    cfg_s2mm(0, EF_BD_IN_PING, EF_BD_IN_PONG, AR_A0, AR_A1, len, EF_LK_IN_EMPTY, EF_LK_IN_FULL, rounds);
}
__attribute__((noinline)) static void cfg_out_at(unsigned off, unsigned len, unsigned rounds) {
    bd_write(EF_BD_OUT_PING, off, len, -1, EF_LK_OUT_FULL, EF_LK_OUT_EMPTY, 1);
    ch_start(0, 1, EF_BD_OUT_PING, rounds);
}
static void out_drained() {
    LK_ACQ(EF_LK_OUT_EMPTY, 1);
    LK_REL(EF_LK_OUT_EMPTY, 1);
}

// n 128-byte vectors (any element type; buffers 64-byte aligned): one copy of each
// loop in program memory
__attribute__((noinline)) static void vcopy(void *dst, const void *src, unsigned n) {
    for (unsigned i = 0; i < n; i++)
        chess_prepare_for_pipelining aie::store_v((float *)dst + i * 32, aie::load_v<32>((const float *)src + i * 32));
}
__attribute__((noinline)) static void vzero(void *dst, unsigned n) {
    for (unsigned i = 0; i < n; i++)
        chess_prepare_for_pipelining aie::store_v((float *)dst + i * 32, aie::zeros<float, 32>());
}

// float vector arithmetic that stays in vector<float> (aie::mul yields an accumulator)
// fp32 multiply is emulated on this core (3 bf16 products): one out-of-line copy
// keeps the 16 KB program memory from filling up with inlined expansions.
__attribute__((noinline)) static V32 fmul_vv(V32 a, V32 b) { return aie::mul(a, b).template to_vector<float>(); }
__attribute__((always_inline)) static inline V32 fmul(const V32 &a, const V32 &b) { return fmul_vv(a, b); }
__attribute__((always_inline)) static inline V32 fmul(const V32 &a, float b) {
    return fmul_vv(a, aie::broadcast<float, 32>(b));
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

/* WE_PROG selects the program this file builds (build.sh compiles it twice):
 * 1 = GEMM (+ LayerNorm fold, epilogues), 2 = attention. One 16 KB program memory
 * cannot hold both; the host swaps programs over the control-packet plane
 * (we_host.h we_prog). 0 = both (does not fit; probes only). */
#ifndef WE_PROG
#define WE_PROG 0
#endif
#if WE_PROG != 2
// ---- GEMM -------------------------------------------------------------------
// C[64x48] += A chunk (64x48) * B chunk (48x48): 4x2 register blocking (4 row
// groups x 2 column tiles, 8 accumulators), the k loop pipelined -- 1042 vs 1336
// cycles for 2x2 in the m6 probe (wider B blocking spills: 2x3 2405)
__attribute__((noinline)) static void mac_chunk(const bfloat16 *__restrict A, const bfloat16 *__restrict B,
                                                float *__restrict C) {
    for (unsigned z = 0; z < 16; z += 4)
        chess_loop_range(4, 4) for (unsigned j = 0; j < 6; j += 2) chess_loop_range(3, 3) {
            MM acc[4][2];
            for (unsigned r = 0; r < 4; r++)
                chess_unroll_loop() {
                    acc[r][0] = MM(aie::load_v<32>(C + ((z + r) * 6 + j) * 32));
                    acc[r][1] = MM(aie::load_v<32>(C + ((z + r) * 6 + j + 1) * 32));
                }
            const bfloat16 *pa = A + z * 6 * 32, *pb = B + j * 64;
            for (unsigned k = 0; k < 6; k++)
                chess_prepare_for_pipelining chess_loop_range(6, 6) {
                    VB a[4];
                    for (unsigned r = 0; r < 4; r++)
                        chess_unroll_loop() a[r] = aie::load_v<32>(pa + (r * 6 + k) * 32);
                    const aie::vector<bfloat16, 64> b0 = aie::load_v<64>(pb + k * 6 * 64),
                                                    b1 = aie::load_v<64>(pb + k * 6 * 64 + 64);
                    for (unsigned r = 0; r < 4; r++)
                        chess_unroll_loop() {
                            acc[r][0].mac(a[r], b0);
                            acc[r][1].mac(a[r], b1);
                        }
                }
            for (unsigned r = 0; r < 4; r++)
                chess_unroll_loop() {
                    aie::store_v(C + ((z + r) * 6 + j) * 32, acc[r][0].template to_vector<float>());
                    aie::store_v(C + ((z + r) * 6 + j + 1) * 32, acc[r][1].template to_vector<float>());
                }
        }
}

typedef aie::vector<int16, 32> VI;

// Exact erf-GELU of a bf16 value (we_model.gelu_aie): table for 1/8 <= |x| < 4,
// 0.5x + bf16(x^2)/sqrt(2 pi) below, x / 0 beyond. Only native ops: integer,
// table lookup, bf16 x bf16 -> fp32 products, fp32 add. The regimes are compares
// on the magnitude bits |x| = exponent << 7 | mantissa.
__attribute__((always_inline)) static inline VB gelu_bf16(const VB &xb) {
    const aie::lut<4, bfloat16> lut(WE_GELU_LUT_N, we_gelu_ab, we_gelu_cd); /* not static: no guard / atexit code */
    aie::parallel_lookup<int16, aie::lut<4, bfloat16>> lk(lut, 0, 0);
    const VI u = xb.template cast_to<int16>();
    const VI a = aie::bit_and((int16)0x7FFF, u);
    const aie::mask<32> neg = aie::lt(u, (int16)0);
    VI idx = aie::sub(a, (int16)(124 << 7));
    idx = aie::select(idx, aie::add(idx, (int16)640), neg);
    const VB tab = lk.fetch(idx);
    // small |x|: 0.5 x + bf16(x^2) * c
    aie::accum<accfloat, 32> acc = aie::mul(xb, aie::broadcast<bfloat16, 32>((bfloat16)0.5f));
    const VB x2 = aie::mul(xb, xb).template to_vector<bfloat16>();
    acc = aie::mac(acc, x2, aie::broadcast<bfloat16, 32>((bfloat16)0.3989422804f));
    const VB small = acc.template to_vector<bfloat16>();
    VB y = aie::select(tab, small, aie::lt(a, (int16)(124 << 7)));
    y = aie::select(y, aie::select(xb, aie::zeros<bfloat16, 32>(), neg), aie::ge(a, (int16)(129 << 7)));
    return y;
}

// GELU over n vectors, out of place through restrict pointers: the loop then
// software-pipelines (m8 probe: 9462 -> 4408 cycles per 64x48 block with the
// bias pass). r: residual added after GELU (in place on o), or null.
__attribute__((noinline)) static void gelu_vec(const bfloat16 *__restrict x, bfloat16 *__restrict o, unsigned n) {
    for (unsigned i = 0; i < n; i++)
        chess_prepare_for_pipelining chess_loop_range(8, )
            aie::store_v(o + i * 32, gelu_bf16(aie::load_v<32>(x + i * 32)));
}
__attribute__((noinline)) static void gelu_vec_res(const bfloat16 *__restrict x, bfloat16 *__restrict o, unsigned n) {
    for (unsigned i = 0; i < n; i++)
        chess_prepare_for_pipelining chess_loop_range(8, ) {
            const VB g = gelu_bf16(aie::load_v<32>(x + i * 32));
            aie::store_v(o + i * 32, to_bf16(aie::add(to_f32(g), to_f32(aie::load_v<32>(o + i * 32)))));
        }
}

// out = epi(C) in [rg16][nt6][4][8] (or row-major [64][48] with WE_F_ROWMAJOR):
// + d (the bias; zeros if none), GELU (bf16 in/out), + residual (bf16, same layout
// as out), rounded once. Column tile outer so d is one vector per inner loop; one
// branch-free loop per GELU / no GELU (a missing residual reads a zero vector).
// GELU: x = bf16(C + d) is compacted into the consumed C (vector i over the bytes of
// C vector i/2, already read) and the GELU pass reads it from there.
alignas(64) static const bfloat16 k_zero32[32] = {};
__attribute__((noinline)) static void epilogue(float *C, const float *bias8, const bfloat16 *res, bfloat16 *out,
                                               int flags) {
    const unsigned rs = (flags & WE_F_RES) ? 6 * 32 : 0;
    if (flags & WE_F_GELU) {
        bfloat16 *x = (bfloat16 *)C;
        for (unsigned rg = 0; rg < 16; rg++)
            for (unsigned nt = 0; nt < 6; nt++)
                chess_unroll_loop() {
                    const aie::vector<float, 8> b8 = aie::load_v<8>(bias8 + nt * 8);
                    aie::store_v(x + (rg * 6 + nt) * 32, to_bf16(aie::add(aie::load_v<32>(C + (rg * 6 + nt) * 32),
                                                                          aie::concat(b8, b8, b8, b8))));
                }
        if (rs)
            gelu_vec_res(x, out, 96);
        else
            gelu_vec(x, out, 96);
    } else {
        for (unsigned nt = 0; nt < 6; nt++) {
            const aie::vector<float, 8> b8 = aie::load_v<8>(bias8 + nt * 8);
            const V32 b = aie::concat(b8, b8, b8, b8);
            const float *c = C + nt * 32;
            const bfloat16 *r = rs ? res + nt * 32 : k_zero32;
            bfloat16 *o = out + nt * 32;
            for (unsigned rg = 0; rg < 16; rg++)
                chess_prepare_for_pipelining chess_loop_range(16, 16)
                    aie::store_v(o + rg * 192, to_bf16(aie::add(aie::add(aie::load_v<32>(c + rg * 192), b),
                                                                to_f32(aie::load_v<32>(r + rg * rs)))));
        }
    }
    if (flags & WE_F_ROWMAJOR) { /* conv1: tiles -> rows through the consumed C, then back */
        bfloat16 *t = (bfloat16 *)C;
        for (unsigned rg = 0; rg < 16; rg++)
            for (unsigned nt = 0; nt < 6; nt++) {
                const VB y = aie::load_v<32>(out + (rg * 6 + nt) * 32);
                for (unsigned q = 0; q < 4; q++)
                    aie::store_v(t + (rg * 4 + q) * 48 + nt * 8, y.template extract<8>(q));
            }
        vcopy(out, t, WE_BLK / 128);
    }
}

// Logits: fp32, one row group -> [nt 6][4][8] fp32 (+ d: the folded LayerNorm's beta W^T)
__attribute__((noinline)) static void epilogue_logit(const float *C, const float *bias8, float *out, int rg) {
    for (unsigned nt = 0; nt < 6; nt++) {
        const aie::vector<float, 8> b8 = aie::load_v<8>(bias8 + nt * 8);
        aie::store_v(out + nt * 32, aie::add(aie::load_v<32>(C + (rg * 6 + nt) * 32), aie::concat(b8, b8, b8, b8)));
    }
}

// ---- LayerNorm folded into the GEMM (WE_F_LN, we_desc.h) ---------------------------
// One A chunk [rg16][kt6][4][8] of x: partial sums into tmp[rg] -- lanes 0..3 of
// each row's 8 lanes hold sums of x, lanes 4..7 sums of x^2 (fp32; x^2 exact).
__attribute__((noinline)) static void ln_acc(const bfloat16 *A, float *tmp, int first) {
    if (first)
        vzero(tmp, 16);
    const VB one = aie::broadcast<bfloat16, 32>((bfloat16)1.0f);
    const aie::mask<32> hi4 = aie::mask<32>::from_uint32(0xF0F0F0F0u);
    for (unsigned rg = 0; rg < 16; rg++)
        chess_prepare_for_pipelining chess_loop_range(16, 16) {
            const VB x0 = aie::load_v<32>(A + rg * 6 * 32);
            aie::accum<accfloat, 32> sa = aie::mul(x0, one), qa = aie::mul(x0, x0);
            for (unsigned kt = 1; kt < 6; kt++)
                chess_unroll_loop() {
                    const VB x = aie::load_v<32>(A + (rg * 6 + kt) * 32);
                    sa = aie::mac(sa, x, one);
                    qa = aie::mac(qa, x, x);
                }
            V32 sv = sa.template to_vector<float>(), qv = qa.template to_vector<float>();
            sv = aie::add(sv, aie::shuffle_down(sv, 4));
            qv = aie::add(qv, aie::shuffle_down(qv, 4));
            aie::store_v(tmp + rg * 32,
                         aie::add(aie::load_v<32>(tmp + rg * 32), aie::select(sv, aie::shuffle_up(qv, 4), hi4)));
        }
}

// Per row of the block: rstd*mu and rstd -> st[0..64) and st[64..128). The row
// sums are first compacted in place in tmp ([row][sum x, sum x^2]), so the fp32
// math (vector invsqrt included) runs on 2 vectors, not 16.
__attribute__((noinline)) static void ln_fin(float *tmp, float *st, float invk, float eps) {
    for (unsigned rg = 0; rg < 16; rg++) {
        V32 t = aie::load_v<32>(tmp + rg * 32);
        t = aie::add(t, aie::shuffle_down(t, 2));
        t = aie::add(t, aie::shuffle_down(t, 1)); /* lane 8i: sum x, lane 8i+4: sum x^2 of row i */
        aie::store_v(tmp + rg * 8, aie::filter_even(aie::filter_even(t)));
    }
    const V32 ik = aie::broadcast<float, 32>(invk), ev = aie::broadcast<float, 32>(eps);
    for (unsigned h = 0; h < 2; h++) {
        const V32 va = aie::load_v<32>(tmp + h * 64), vb = aie::load_v<32>(tmp + h * 64 + 32);
        const V32 m = fmul(aie::concat(aie::filter_even(va), aie::filter_even(vb)), ik);
        const V32 e2 = fmul(aie::concat(aie::filter_odd(va), aie::filter_odd(vb)), ik);
        const V32 r = aie::invsqrt(aie::add(aie::sub(e2, fmul(m, m)), ev));
        aie::store_v(st + h * 32, fmul(r, m));
        aie::store_v(st + 64 + h * 32, r);
    }
}

// C (one 64x48 block) <- rstd (C - mu c) = rstd C - (rstd mu) c, all on the multiplier
// with hi/lo bf16 operands (fp32 accumulation, only the lo x lo terms dropped):
//   rstd C : A1 = [diag(r_hi) | diag(r_lo)] x B1 = [C_hi; C_hi]  +  A2 = [diag(r_hi) | 0] x B2 = [C_lo; 0]
//   (rstd mu) c : A3 rows [-q_hi, -q_hi, -q_lo, 0..] x B3 rows [c_hi; c_lo; c_hi; 0..]
__attribute__((noinline)) static void ln_apply(float *C, const float *st, const bfloat16 *ch, const bfloat16 *cl) {
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

// K^T / V tile variants (attention operands), rows paired into 8-key tiles:
// tr = 1: K^T [dt 6][kp 8][8 dims][8 keys];  tr = 0: V [kp 8][nt 6][8 keys][8 dims]
__attribute__((noinline)) static void epilogue_kv(const float *C, const float *bias8, bfloat16 *out, int flags,
                                                  int tr) {
    for (unsigned kp = 0; kp < 8; kp++)
        for (unsigned nt = 0; nt < 6; nt++)
            chess_prepare_for_pipelining {
                V32 lo = aie::load_v<32>(C + ((2 * kp) * 6 + nt) * 32);
                V32 hi = aie::load_v<32>(C + ((2 * kp + 1) * 6 + nt) * 32);
                const aie::vector<float, 8> b8 = aie::load_v<8>(bias8 + nt * 8);
                const V32 b = aie::concat(b8, b8, b8, b8);
                lo = aie::add(lo, b);
                hi = aie::add(hi, b);
                const aie::vector<bfloat16, 64> kd = aie::concat(to_bf16(lo), to_bf16(hi));
                if (tr)
                    aie::store_v(out + (nt * 8 + kp) * 64, aie::transpose(kd, 8, 8));
                else
                    aie::store_v(out + (kp * 6 + nt) * 64, kd);
            }
}

__attribute__((noinline)) static void op_gemm(const int32_t *h) {
    const int MB = h[WH_MB], NB = h[WH_NB], KCN = h[WH_KCN], flags = h[WH_FLAGS];
    const int kt_lo = h[WH_KT_LO], kt_hi = h[WH_KT_HI], vt_lo = h[WH_VT_LO], vt_hi = h[WH_VT_HI];
    const int lrg = h[WH_LRG], ln = flags & WE_F_LN, KST = h[WH_KST]; /* the header buffer is reused */
    const int lnst = ln && !(flags & WE_F_LNKEEP); /* row stats here, else AR_ST from the previous sub-op */
    const float lneps = ((const float *)h)[WH_LNEPS], invk = ((const float *)h)[WH_LNINVK]; /* by A chunks */
    // own column tiles' parameters out of the header (contiguous: tiles g_mc*NB ..)
    const int nsb48 = h[WH_N], o48 = g_mc * NB * 48;
    const float *hd = (const float *)((const int8_t *)h + WE_PRM_OFF);
    const bfloat16 *hc = (const bfloat16 *)(hd + nsb48);
    float *d8 = AR(AR_PRM, float);
    bfloat16 *ch8 = AR(AR_PRM + 768, bfloat16), *cl8 = AR(AR_PRM + 1152, bfloat16);
    for (int i = 0; i < NB * 3; i++) {
        aie::store_v(d8 + i * 16, aie::load_v<16>(hd + o48 + i * 16));
        aie::store_v(ch8 + i * 16, aie::load_v<16>(hc + o48 + i * 16));
        aie::store_v(cl8 + i * 16, aie::load_v<16>(hc + nsb48 + o48 + i * 16));
    }
    chess_memory_fence();
    LK_REL(EF_LK_IN_EMPTY, 1); /* header consumed */
    WE_T(g0);
    const int res = flags & WE_F_RES;
    const unsigned blocks = (unsigned)(NB * MB);
    const unsigned a_per_blk = (unsigned)KCN + (res ? 4u : 0u);
    cfg_a(WE_A_CHUNK, blocks * a_per_blk);
    cfg_s2mm(1, EF_BD_W_PING, EF_BD_W_PONG, AR_B0, AR_B1, WE_B_CHUNK, EF_LK_W_EMPTY, EF_LK_W_FULL, blocks * KCN);
    cfg_out_at(AR_OUT, (flags & WE_F_LOGIT) ? 6 * 32 * 4 : WE_BLK, blocks);
    float *C = AR(AR_C, float), *st = AR(AR_ST, float), *tmp = AR(AR_TMP, float);
    bfloat16 *out = AR(AR_OUT, bfloat16);
    unsigned ia = 0, ib = 0;
    for (int nb = 0; nb < NB; nb++) {
        const int cb = g_mc * NB + nb;
        const int kt = (flags & WE_F_KT) && cb >= kt_lo && cb < kt_hi;
        const int vt = (flags & WE_F_VT) && cb >= vt_lo && cb < vt_hi;
        for (int mb = 0; mb < MB; mb++) {
            vzero(C, WE_TM * WE_TN / 32);
            for (int k = 0; k < KCN; k++) {
                LK_ACQ(EF_LK_IN_FULL, 1);
                LK_ACQ(EF_LK_W_FULL, 1);
                const bfloat16 *A = AR(ia ? AR_A1 : AR_A0, bfloat16);
                WE_T(m0);
#ifndef WE_NOMAC /* probe: data delivery alone */
                mac_chunk(A, AR(ib ? AR_B1 : AR_B0, bfloat16), C);
#endif
                WE_T(m1);
                WE_ACC(10, m1 - m0);
                WE_ACC(12, 1);
                if (lnst && nb == 0 && k < KST) { /* stats from the first column tile's pass */
                    ln_acc(A, tmp, k == 0);
                    WE_T(m2);
                    WE_ACC(8, m2 - m1);
                }
                LK_REL(EF_LK_IN_EMPTY, 1);
                LK_REL(EF_LK_W_EMPTY, 1);
                ia ^= 1;
                ib ^= 1;
            }
            if (ln) {
                WE_T(l0);
                if (lnst && nb == 0)
                    ln_fin(tmp, st + mb * 128, invk, lneps);
                ln_apply(C, st + mb * 128, ch8 + nb * 48, cl8 + nb * 48);
                WE_T(l1);
                WE_ACC(7, l1 - l0);
            }
            LK_ACQ(EF_LK_OUT_EMPTY, 1);
            if (res) {
                // 4 chunks, one per mesh column; ours (chunk mc) -> out, the epilogue adds it in place
                for (int q = 0; q < 4; q++) {
                    LK_ACQ(EF_LK_IN_FULL, 1);
                    if (q == g_mc)
                        vcopy(out, AR(ia ? AR_A1 : AR_A0, bfloat16), WE_BLK / 128);
                    LK_REL(EF_LK_IN_EMPTY, 1);
                    ia ^= 1;
                }
            }
            WE_T(e0);
            if (flags & WE_F_LOGIT)
                epilogue_logit(C, d8 + nb * WE_TN, (float *)out, lrg);
            else if (kt || vt)
                epilogue_kv(C, d8 + nb * WE_TN, out, flags, kt);
            else
                epilogue(C, d8 + nb * WE_TN, out, out, flags);
            WE_T(e1);
            WE_ACC(13, e1 - e0);
            chess_memory_fence();
            LK_REL(EF_LK_OUT_FULL, 1);
        }
    }
    out_drained();
    WE_ACC(11, aie::tile::current().cycles() - g0);
}

#endif /* WE_PROG != 2 */

#if WE_PROG != 1
// ---- row helpers ------------------------------------------------------------
// Sum the 8 lanes of each 4-row group's row (lanes i*8 .. i*8+7), result
// replicated across those 8 lanes. Vector-only: the scalar unit has no FPU.
__attribute__((always_inline)) static inline V32 row_sum8(const V32 &v) {
    V32 t = aie::add(v, aie::shuffle_down(v, 4));
    t = aie::add(t, aie::shuffle_down(t, 2));
    t = aie::add(t, aie::shuffle_down(t, 1)); /* lane i*8 holds row i's sum */
    return aie::concat(aie::broadcast<float, 8>(t[0]), aie::broadcast<float, 8>(t[8]), aie::broadcast<float, 8>(t[16]),
                       aie::broadcast<float, 8>(t[24]));
}

// ---- attention ------------------------------------------------------------------

// S - m [32x64] = Q[32x64] K^T chunk[64x64] - m: Q [rg8][kd8][32], K [kd8][kp8][64],
// S [rg8][kp8][32]. 4x2 register blocking (4 row groups x 2 key tiles), the
// accumulators start at -m (the row references), the dim loop pipelined.
__attribute__((noinline)) static void att_qk(const bfloat16 *__restrict Q, const bfloat16 *__restrict K,
                                             float *__restrict S) {
    for (unsigned z = 0; z < 8; z += 4)
        chess_loop_range(2, 2) for (unsigned j = 0; j < 8; j += 2) chess_loop_range(4, 4) {
            MM acc[4][2];
            for (unsigned r = 0; r < 4; r++)
                chess_unroll_loop() {
                    const V32 nm = aie::neg(aie::load_v<32>(ML(0, z + r)));
                    acc[r][0] = MM(nm);
                    acc[r][1] = MM(nm);
                }
            const bfloat16 *pa = Q + z * 8 * 32, *pb = K + j * 64;
            for (unsigned k = 0; k < 8; k++)
                chess_prepare_for_pipelining chess_loop_range(8, 8) {
                    VB a[4];
                    aie::vector<bfloat16, 64> b[2];
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

// O[32x64] += P[32x64] V chunk[64x64]: P [rg8][kp8][32], V [kp8][dt8][64], O [rg8][dt8][32]
// O += P V; first the denominators on the multiplier: l[rg] += P[rg] x 1 -- the
// row sum, in every lane of the row, from the same rounded P as O
__attribute__((noinline)) static void att_pv(const bfloat16 *__restrict P, const bfloat16 *__restrict V,
                                             float *__restrict O) {
    const aie::vector<bfloat16, 64> ones = aie::broadcast<bfloat16, 64>((bfloat16)1.0f);
    for (unsigned z = 0; z < 8; z += 2)
        chess_prepare_for_pipelining chess_loop_range(4, 4) {
            MM L0(aie::load_v<32>(ML(1, z))), L1(aie::load_v<32>(ML(1, z + 1)));
            for (unsigned k = 0; k < 8; k++)
                chess_unroll_loop() {
                    L0.mac(aie::load_v<32>(P + (z * 8 + k) * 32), ones);
                    L1.mac(aie::load_v<32>(P + ((z + 1) * 8 + k) * 32), ones);
                }
            aie::store_v(ML(1, z), L0.template to_vector<float>());
            aie::store_v(ML(1, z + 1), L1.template to_vector<float>());
        }
    // 4x2 blocks (4 row groups x 2 dim tiles), one pipelined loop over the 8 blocks,
    // k unrolled: 934 vs 1087 cycles for 2x2 (probe m10), bit-identical
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
                    const aie::vector<bfloat16, 64> b0 = aie::load_v<64>(pb + k * 8 * 64),
                                                    b1 = aie::load_v<64>(pb + k * 8 * 64 + 64);
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

alignas(64) static const int32_t k_lane_k[32] = {0, 1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3, 4, 5, 6, 7,
                                                 0, 1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3, 4, 5, 6, 7};
alignas(64) static const int32_t k_lane_r[32] = {0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1,
                                                 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3};
typedef struct {
    int key0, nvalid, causal, q0, on;
} AttMask;
// row groups [rg0, rg0+nrg) of S (S points at rg0): keys >= nvalid (and, causal,
// keys after the query) -> -1e30
__attribute__((noinline)) static void att_mask(float *S, int rg0, int nrg, const AttMask *mk) {
    const aie::vector<int32, 32> lk = aie::load_v<32>(k_lane_k), lr = aie::load_v<32>(k_lane_r);
    const V32 neg = aie::broadcast<float, 32>(-1.0e30f);
    for (int rg = 0; rg < nrg; rg++) {
        const aie::vector<int32, 32> row = aie::add(lr, mk->q0 + (rg0 + rg) * 4);
        for (int kp = 0; kp < 8; kp++) {
            const aie::vector<int32, 32> key = aie::add(lk, mk->key0 + kp * 8);
            aie::mask<32> bad = aie::ge(key, mk->nvalid);
            if (mk->causal)
                bad = bad | aie::gt(key, row);
            float *p = S + (rg * 8 + kp) * 32;
            aie::store_v(p, aie::select(aie::load_v<32>(p), neg, bad));
        }
    }
}

// P = exp2(S - m) in place (bf16 over the fp32 S). The write of vector i lands on
// S vector i/2, already read, and software pipelining only moves loads earlier and
// stores later -- so the two views are declared restrict (aliased, the loop
// serialises: 991 -> 273 cycles, probe m5). Returns nonzero if some P passed
// 2^WE_SM_LAZY (a score above its reference). The denominators: att_pv.
__attribute__((noinline)) static unsigned att_exp(const float *__restrict S, bfloat16 *__restrict P) {
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

// v * 2^-k, exact: exponent arithmetic on the fp32 bits (k per lane, any sign; a
// result below the normal range, or v == 0, gives 0). In place over n vectors,
// vector i scaled by k[(i / per) * 32 ..].
__attribute__((noinline)) static void pow2one(float *v, const int32 *k) {
    const aie::vector<int32, 32> kk = aie::load_v<32>(k), b = aie::load_v<32>(v).template cast_to<int32>();
    const aie::vector<int32, 32> e = aie::bit_and((int32)0xFF, aie::downshift(b, 23));
    aie::store_v(v, aie::select(aie::zeros<int32, 32>(), aie::sub(b, aie::upshift(kk, 23)), aie::gt(e, kk))
                        .template cast_to<float>());
}
static void pow2scale(float *v, const int32 *k, unsigned n, unsigned per) {
    for (unsigned i = 0; i < n; i++)
        pow2one(v + i * 32, k + (i / per) * 32);
}

// A raise over the 8 row groups: per row k = round(max) + 1 where the row max passes
// thr (else 0), m += k, k -> kout. The row max stays in vector registers (reduce
// down by 4/2/1 lanes, then spread lane 8i back over its 8 lanes with shifts and
// selects); the fp32 magic-number trick (x + 1.5*2^23 holds round(x) in the low
// mantissa bits) needs no float<->int conversion.
__attribute__((noinline)) static void raise_all(const float *__restrict S, int32 *__restrict kout, float thr) {
    const V32 mg = aie::broadcast<float, 32>(12582912.0f), th = aie::broadcast<float, 32>(thr);
    const aie::mask<32> s1 = aie::mask<32>::from_uint32(0x02020202u), s2 = aie::mask<32>::from_uint32(0x0C0C0C0Cu),
                        s4 = aie::mask<32>::from_uint32(0xF0F0F0F0u);
    for (unsigned rg = 0; rg < 8; rg++)
        chess_prepare_for_pipelining chess_loop_range(8, 8) {
            const float *Srg = S + rg * 8 * 32;
            V32 t = aie::load_v<32>(Srg);
            for (unsigned kp = 1; kp < 8; kp++)
                chess_unroll_loop() t = aie::max(t, aie::load_v<32>(Srg + kp * 32));
            t = aie::max(t, aie::shuffle_down(t, 4));
            t = aie::max(t, aie::shuffle_down(t, 2));
            t = aie::max(t, aie::shuffle_down(t, 1)); /* lane 8i: row i's max */
            t = aie::select(t, aie::shuffle_up(t, 1), s1);
            t = aie::select(t, aie::shuffle_up(t, 2), s2);
            const V32 x = aie::select(t, aie::shuffle_up(t, 4), s4);
            const aie::vector<int32, 32> ki = aie::add(
                aie::sub(aie::add(x, mg).template cast_to<int32>(), aie::broadcast<int32, 32>((int32)0x4B400000)),
                (int32)1);
            const aie::vector<int32, 32> k = aie::select(aie::zeros<int32, 32>(), ki, aie::gt(x, th));
            aie::store_v(kout + rg * 32, k);
            float *m = ML(0, rg);
            aie::store_v(
                m,
                aie::add(
                    aie::load_v<32>(m),
                    aie::sub(aie::add(k, aie::broadcast<int32, 32>((int32)0x4B400000)).template cast_to<float>(), mg)));
        }
}

// Reference raise -- every row on a q-block's first chunk (m = l = O = 0 then), else
// only the rows with a score past m + WE_SM_LAZY: S - m_old again, per row
// k = round(max) + 1, m += k, l and O scaled by 2^-k exactly (references stay
// integers, so the rescale is exponent arithmetic), then S - m once more.
__attribute__((noinline)) static void att_raise(const bfloat16 *Q, const bfloat16 *K, float *S, float *O,
                                                const AttMask *mk, int first) {
    att_qk(Q, K, S);
    if (mk->on)
        att_mask(S, 0, 8, mk);
    int32 *k = (int32 *)ML(2, 0);
    raise_all(S, k, first ? -3.0e38f : WE_SM_LAZY);
    if (!first) { /* first chunk: l = O = 0, and 0 * 2^-k is 0 -- nothing to rescale */
        pow2scale(ML(1, 0), k, 8, 1);
        pow2scale(O, k, 64, 8);
    }
    att_qk(Q, K, S);
    if (mk->on)
        att_mask(S, 0, 8, mk);
}

// One key chunk's numerator: P (bf16, over S) and l. The first chunk of a q-block
// sets the references (att_raise from m = 0); later chunks redo through att_raise
// only if a score passed its reference by 2^WE_SM_LAZY.
__attribute__((noinline)) static void att_scores(const bfloat16 *Q, const bfloat16 *K, float *S, float *O,
                                                 const AttMask *mk, int first) {
    bfloat16 *P = (bfloat16 *)S;
    if (first) {
        vzero(ML(0, 0), 8);
    } else {
        WE_T(s0);
        att_qk(Q, K, S);
        WE_T(s1);
        if (mk->on)
            att_mask(S, 0, 8, mk);
        const unsigned big = att_exp(S, P);
        WE_T(s2);
        WE_ACCA(10, s1 - s0);
        WE_ACCA(11, s2 - s1);
        WE_ACCA(12, 1);
        if (!big)
            return;
        WE_ACCA(13, 1);
    }
    att_raise(Q, K, S, O, mk, first);
    att_exp(S, P);
}

// 1/l per row (l holds the row sum in every lane): bit-trick seed (rel. err < 12.5%)
// + 3 Newton steps, then out = bf16(O / l). Inline multiplies in pipelined loops:
// through the out-of-line fmul this took ~10k cycles per q-block.
__attribute__((noinline)) static void att_finish(const float *__restrict O, bfloat16 *__restrict out) {
    float *il = ML(2, 0);
    const V32 two = aie::broadcast<float, 32>(2.0f);
    for (unsigned rg = 0; rg < 8; rg++)
        chess_prepare_for_pipelining chess_loop_range(8, 8) {
            const V32 ls = aie::load_v<32>(ML(1, rg));
            V32 x =
                aie::sub(aie::broadcast<int32, 32>(0x7EF311C7), ls.template cast_to<int32>()).template cast_to<float>();
            for (unsigned n = 0; n < 3; n++)
                chess_unroll_loop() x =
                    aie::mul(x, aie::sub(two, aie::mul(ls, x).template to_vector<float>())).template to_vector<float>();
            const VB xh = to_bf16(x);
            aie::store_v((bfloat16 *)il + rg * 64, xh);
            aie::store_v((bfloat16 *)il + rg * 64 + 32, to_bf16(aie::sub(x, to_f32(xh))));
        }
    /* O / l = O_hi x il_hi + O_hi x il_lo + O_lo x il_hi: native bf16 products, fp32 sum */
    const bfloat16 *ib = (const bfloat16 *)il;
    for (unsigned i = 0; i < 64; i++)
        chess_prepare_for_pipelining chess_loop_range(64, 64) {
            const V32 ov = aie::load_v<32>(O + i * 32);
            const VB oh = to_bf16(ov), ol = to_bf16(aie::sub(ov, to_f32(oh)));
            const VB ih = aie::load_v<32>(ib + (i >> 3) * 64), lo = aie::load_v<32>(ib + (i >> 3) * 64 + 32);
            aie::accum<accfloat, 32> acc = aie::mul(oh, ih);
            acc = aie::mac(acc, oh, lo);
            acc = aie::mac(acc, ol, ih);
            aie::store_v(out + i * 32, acc.template to_vector<bfloat16>());
        }
}

__attribute__((noinline)) static void op_attn(const int32_t *h) {
    const int T = h[WH_T], NKC = h[WH_NKC], causal = h[WH_AFLAGS] & WE_A_CAUSAL;
    const int nqb = h[WH_NQB + g_mc], q0 = h[WH_Q0 + g_mc], steps = h[WH_STEPS];
    LK_REL(EF_LK_IN_EMPTY, 1); /* header consumed */
    cfg_s2mm(0, EF_BD_IN_PING, EF_BD_IN_PONG, AT_A0, AT_A1, WE_Q_CHUNK, EF_LK_IN_EMPTY, EF_LK_IN_FULL,
             (unsigned)(4 * steps));
    if (nqb) {
        cfg_out_at(AT_S, WE_Q_CHUNK, (unsigned)nqb);
        /* K/V for every q-block, armed once: the start-queue repeat field is 8 bits, so
         * the ping-pong pairs go in as several queue entries (task queue depth 4) --
         * re-arming per q-block stalled each q-block's first chunk on the restart */
        cfg_s2mm(1, EF_BD_W_PING, EF_BD_W_PONG, AT_B0, AT_B1, WE_KV_CHUNK, EF_LK_W_EMPTY, EF_LK_W_FULL, 2);
        for (unsigned left = (unsigned)(NKC * nqb) - 1; left;) {
            const unsigned r = left > 240 ? 240 : left;
            ch_start(1, 0, EF_BD_W_PING, r);
            left -= r;
        }
    }
    float *S = AR(AT_S, float), *O = AR(AT_O, float);
    unsigned ia = 0, ib = 0;
    for (int st = 0; st < steps; st++) {
        WE_T(sb0);
        bfloat16 *Q = AR(AT_Q, bfloat16);
        for (int c = 0; c < 4; c++) {
            LK_ACQ(EF_LK_IN_FULL, 1);
            if (c == g_mc && st < nqb) /* copy ours; the ring must keep moving for the other columns */
                vcopy(Q, AR(ia ? AT_A1 : AT_A0, bfloat16), WE_Q_CHUNK / 128);
            LK_REL(EF_LK_IN_EMPTY, 1);
            ia ^= 1;
        }
        if (st >= nqb)
            continue;
        out_drained();      /* the previous q-block's O left from AT_S */
        vzero(ML(1, 0), 8); /* l; m is set by the first chunk */
        vzero(O, WE_QB * 64 / 32);
        const int qrow0 = q0 + st * WE_QB;
        WE_T(tq0);
        WE_ACCA(15, tq0 - sb0);
        AttMask mk = {0, T, causal, qrow0, 0};
        for (int kc = 0; kc < NKC; kc++) {
            LK_ACQ(EF_LK_W_FULL, 1);
            WE_T(c0);
            mk.key0 = kc * WE_KCH;
            mk.on = mk.key0 + WE_KCH > T || causal;
            att_scores(Q, AR(ib ? AT_B1 : AT_B0, bfloat16), S, O, &mk, kc == 0);
            WE_T(c1);
            LK_REL(EF_LK_W_EMPTY, 1);
            ib ^= 1;
            WE_T(c2);
            LK_ACQ(EF_LK_W_FULL, 1);
            WE_T(c3);
            att_pv((const bfloat16 *)S, AR(ib ? AT_B1 : AT_B0, bfloat16), O);
            WE_T(c4);
            LK_REL(EF_LK_W_EMPTY, 1);
            ib ^= 1;
            WE_ACCA(5, c1 - c0);
            WE_ACCA(6, c2 - c1);
            WE_ACCA(7, c4 - c3);
            WE_ACCA(9, 1);
        }
        WE_ACCA(8, aie::tile::current().cycles() - tq0);
        LK_ACQ(EF_LK_OUT_EMPTY, 1);
        WE_T(f0);
        att_finish(O, AR(AT_S, bfloat16));
        WE_T(f1);
        WE_ACCA(14, f1 - f0);
        chess_memory_fence();
        LK_REL(EF_LK_OUT_FULL, 1);
    }
    if (nqb)
        out_drained();
}

#endif /* WE_PROG != 1 */

// main never returns: an empty __cxa_finalize keeps the runtime's atexit.o (174 B
// of the 16 KB program memory) out of the link
extern "C" void __cxa_finalize(void *) {}

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
    g_mc =
        (int)((cid >> 16) & 0x7F) - EF_PART_START_COL - EF_FIRST_COL; /* absolute column (skill kcocoreidpartition) */
    g_mr = (int)(cid & 0x1F) - EF_FIRST_ROW;
    g_pkt = k_pkt[g_mr][g_mc];
    g_ooo = k_ooo[g_mr][g_mc];
    for (;;) {
        cfg_a(WE_HDR_BYTES, 1);
        LK_ACQ(EF_LK_IN_FULL, 1);
        const int32_t *h = AR(AR_A0, int32_t);
        const int op = h[WH_OP];
        we_dbg[0] = h[WH_SEQ];
        if (g_mr >= h[WH_RACT]) { /* idle row: header only; drain the column-broadcast B */
            const int att = op == WE_OP_ATTN;
            const unsigned per = att ? (unsigned)(2 * h[WH_NKC]) : (unsigned)(h[WH_NB] * h[WH_MB] * h[WH_KCN]);
            const unsigned reps = att ? (unsigned)h[WH_NQB + g_mc] : (op == WE_OP_GEMM ? 1u : 0u);
            LK_REL(EF_LK_IN_EMPTY, 1);
            for (unsigned r = 0; r < reps; r++) {
                cfg_s2mm(1, EF_BD_W_PING, EF_BD_W_PONG, AT_B0, AT_B1, att ? WE_KV_CHUNK : WE_B_CHUNK, EF_LK_W_EMPTY,
                         EF_LK_W_FULL, per);
                for (unsigned i = 0; i < per; i++) {
                    LK_ACQ(EF_LK_W_FULL, 1);
                    LK_REL(EF_LK_W_EMPTY, 1);
                }
            }
            continue;
        }
#if WE_PROG != 2
        if (op == WE_OP_GEMM) {
            op_gemm(h);
            continue;
        }
#endif
#if WE_PROG != 1
        if (op == WE_OP_ATTN) {
            op_attn(h);
            continue;
        }
#endif
        we_dbg[1] = -op; /* an op of the other program: the host did not swap */
        LK_REL(EF_LK_IN_EMPTY, 1);
    }
    return 0;
}
