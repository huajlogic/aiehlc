// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// gemm_plan_tile.h -- compute macros of the 2 x 8 shared-operand GEMM tile (64 x 64 x K in 128-wide
// chunks, aie::mmul<8, 8, 8> int8). Pure compute: no locks, addresses or memory layout -- the blocks
// come from aie::load_buffer in gemm_plan.cc, which the compiler serves from the dataflow plan's hosted
// slots on the core and from the trace harness on x86. Same macros on both.
//
// A chunk = 16 blocks of 2 x 2 accumulators: A pair b >> 2, B pair b & 3; accumulators of block b in
// bank (b >> 1) & 1 (ae / ao). Pairs {0,1} sit in part 0 of the chunk, {2,3} in part 1 (the parts may
// be in different memory banks, so the next part is reached through dA, not a fixed offset). At a chunk
// boundary the last block of chunk j overlaps the first block of chunk j+1 (no prologue / epilogue).
#ifndef GEMM_PLAN_TILE_H
#define GEMM_PLAN_TILE_H
// (macros only: the kernel body declares KaMM4 = aie::mmul<8, 8, 8, int8_t, int8_t>)
#define K4_H (KA_KC / 8 * 64)
#define K4_LD(c, p)                                                                                                    \
    {                                                                                                                  \
        aie::accum<acc32, 64> q0_, q1_, q2_, q3_;                                                                      \
        q0_.from_vector(aie::load_v<64>(p));                                                                           \
        q1_.from_vector(aie::load_v<64>((p) + 64));                                                                    \
        q2_.from_vector(aie::load_v<64>((p) + 128));                                                                   \
        q3_.from_vector(aie::load_v<64>((p) + 192));                                                                   \
        c##0 = KaMM4(q0_);                                                                                             \
        c##1 = KaMM4(q1_);                                                                                             \
        c##2 = KaMM4(q2_);                                                                                             \
        c##3 = KaMM4(q3_);                                                                                             \
    }
/* chunk 0 of a tile: the accumulators start at zero -- no load, and nobody has to zero acc */
#define K4_LDZ(c, p)                                                                                                   \
    {                                                                                                                  \
        const aie::accum<acc32, 64> z_ = aie::zeros<acc32, 64>();                                                      \
        c##0 = KaMM4(z_);                                                                                              \
        c##1 = KaMM4(z_);                                                                                              \
        c##2 = KaMM4(z_);                                                                                              \
        c##3 = KaMM4(z_);                                                                                              \
    }
#define K4_ST(p, c)                                                                                                    \
    {                                                                                                                  \
        aie::store_v((p), (c##0).to_vector<int32_t>());                                                                \
        aie::store_v((p) + 64, (c##1).to_vector<int32_t>());                                                           \
        aie::store_v((p) + 128, (c##2).to_vector<int32_t>());                                                          \
        aie::store_v((p) + 192, (c##3).to_vector<int32_t>());                                                          \
    }
/* last chunk of a tile: the accumulators are final -- int8 straight to the output tile (block bl at logical
 * L = bl ^ swz, as sh_convert did); no separate convert pass, and acc is never re-zeroed (chunk 0: K4_LDZ) */
#define K4_OUT(p, c, bl)                                                                                               \
    {                                                                                                                  \
        const int L_ = (bl) ^ swz;                                                                                     \
        int8_t *tt_ = y + ((2 * (L_ >> 2)) * 8 + 2 * (L_ & 3)) * 64;                                                   \
        aie::store_v(tt_, (c##0).to_vector<int8_t>(0));                                                                \
        aie::store_v(tt_ + 64, (c##1).to_vector<int8_t>(0));                                                           \
        aie::store_v(tt_ + 8 * 64, (c##2).to_vector<int8_t>(0));                                                       \
        aie::store_v(tt_ + 8 * 64 + 64, (c##3).to_vector<int8_t>(0));                                                  \
    }
/* k-step with ping-pong operand registers: step s uses set (va, vb) if s is even, (wa, wb) if odd, and
 * reloads that set with step s + 2 -- no operand rotation, so no VMOVs (with rotation, 4 VMOVs per 4
 * VMACs saturated the move slot: 135 bundles per 128 MACs). A block has 16 steps, so (va, vb) =
 * step 0 and (wa, wb) = step 1 at every block start. */
#define K4_STEPX(c, l, m, A0, A1, B0, B1)                                                                              \
    {                                                                                                                  \
        const aie::vector<int8_t, 64> n0 = aie::load_v<64>(l), n1 = aie::load_v<64>((l) + K4_H);                       \
        const aie::vector<int8_t, 64> m0 = aie::load_v<64>(m), m1 = aie::load_v<64>((m) + K4_H);                       \
        (c##0).mac(A0, B0);                                                                                            \
        (c##1).mac(A0, B1);                                                                                            \
        (c##2).mac(A1, B0);                                                                                            \
        (c##3).mac(A1, B1);                                                                                            \
        A0 = n0;                                                                                                       \
        A1 = n1;                                                                                                       \
        B0 = m0;                                                                                                       \
        B1 = m1;                                                                                                       \
    }
#define K4_STEP(c, l, m) K4_STEPX(c, l, m, va0, va1, vb0, vb1)
#define K4_STEPW(c, l, m) K4_STEPX(c, l, m, wa0, wa1, wb0, wb1)
#define K4_BLK(c, pa0, pb0, npa, npb)                                                                                  \
    {                                                                                                                  \
        const int8_t *__restrict pa_ = (pa0);                                                                          \
        const int8_t *__restrict pb_ = (pb0);                                                                          \
        for (int ki = 2; ki < KA_KC / 8; ki += 2)                                                                      \
            chess_flatten_loop {                                                                                       \
                K4_STEP(c, pa_ + ki * 64, pb_ + ki * 64);                                                              \
                K4_STEPW(c, pa_ + ki * 64 + 64, pb_ + ki * 64 + 64);                                                   \
            }                                                                                                          \
        K4_STEP(c, (npa), (npb));                                                                                      \
        K4_STEPW(c, (npa) + 64, (npb) + 64);                                                                           \
    }
/* 7 iterations: blocks 1 .. 14 of the current chunk (state: X = block 0 done, Y = block 1 loaded) */
#define K4_STI(p, c, bl) K4_ST(p, c)
#define SH_INNER_W(ST, LD)                                                                                             \
    for (int i = 0; i < 7; i++) {                                                                                      \
        ST(cur, X, 2 * i);                                                                                             \
        LD(X, nxt);                                                                                                    \
        K4_BLK(Y, aY, bY, aX, bX);                                                                                     \
        ST(cur + 256, Y, 2 * i + 1);                                                                                   \
        LD(Y, nxt + 256);                                                                                              \
        const int8_t *aY2 = aX;                                                                                        \
        K4_BLK(X, aX, bX, aY2, bYo);                                                                                   \
        int32_t *t_ = cur + 512 + 0;                                                                                   \
        cur = nxt;                                                                                                     \
        nxt = t_;                                                                                                      \
        aX = aY + 2048 + ((unsigned)(i - 2) < 2u ? dA : 0);                                                            \
        aY = aY2;                                                                                                      \
        const int8_t *tb = bY;                                                                                         \
        bY = bYo;                                                                                                      \
        bYo = tb;                                                                                                      \
        tb = bX;                                                                                                       \
        bX = bXo;                                                                                                      \
        bXo = tb;                                                                                                      \
    }
/* pointer state for chunk g whose halves are (al_, ah_, bl_, bh_) */
#define SH_RESET(al_, ah_, bl_, bh_)                                                                                   \
    {                                                                                                                  \
        dA = (int)((ah_) - (al_)) - 4096;                                                                              \
        cur = ae + 0;                                                                                                  \
        nxt = ao + 0;                                                                                                  \
        aY = (al_);                                                                                                    \
        aX = (al_);                                                                                                    \
        bY = (bl_) + 2048;                                                                                             \
        bYo = (bh_) + 2048;                                                                                            \
        bX = (bh_);                                                                                                    \
        bXo = (bl_);                                                                                                   \
    }
/* the two halves (row parts) of chunks xa (A) / xb (B), in this core's walk order (pa / pb: 1 = half 1
   first): with {.parts = 2} the plan puts them in different memory banks (x.part(i)); with one part they
   are back to back, half a chunk apart */
#if !defined(GP_PARTS) || GP_PARTS == 2
#define SH_PARTS(xa, xb, al_, ah_, bl_, bh_)                                                                           \
    al_ = (const int8_t *)(xa).part(pa);                                                                               \
    ah_ = (const int8_t *)(xa).part(pa ^ 1);                                                                           \
    bl_ = (const int8_t *)(xb).part(pb);                                                                               \
    bh_ = (const int8_t *)(xb).part(pb ^ 1);
#else
#define SH_PARTS(xa, xb, al_, ah_, bl_, bh_)                                                                           \
    al_ = (const int8_t *)(xa) + pa * (KA_TM / 2 * KA_KC);                                                             \
    ah_ = (const int8_t *)(xa) + (pa ^ 1) * (KA_TM / 2 * KA_KC);                                                       \
    bl_ = (const int8_t *)(xb) + pb * (KA_TN / 2 * KA_KC);                                                             \
    bh_ = (const int8_t *)(xb) + (pb ^ 1) * (KA_TN / 2 * KA_KC);
#endif
/* chunk boundary, first half: blocks 14 / 15 of the current chunk with chunk (nAl, nBl) prefetched */
#define SH_BOUND1(nAl, nBl)                                                                                            \
    K4_ST(cur, X);                                                                                                     \
    K4_LD(X, ae);                                                                                                      \
    K4_BLK(Y, aY, bY, nAl, nBl);
/* second half (after the current chunk is released): blocks 0 / 1 of the next chunk */
#define SH_BOUND2(nAl, nAh, nBl, nBh)                                                                                  \
    K4_ST(cur + 256, Y);                                                                                               \
    K4_LD(Y, ae + 256);                                                                                                \
    K4_BLK(X, nAl, nBl, nAl, nBl + 2048);                                                                              \
    SH_RESET(nAl, nAh, nBl, nBh);
/* ---- tile knobs (M3.3.6.2.1.2.3.1) ---------------------------------------------------------------------
 * A config file sets them before #include "gemm_plan.cc" (and passes the same values as -D flags):
 *   GP_TM / GP_TN    core tile rows / columns, multiples of 16: TM/16 x TN/16 accumulator pairs   default 64
 *   GP_KC            chunk K in bytes (multiple of 16)                                             default 128
 *   GP_C_DEPTH       output tile slots in core DM: 2 ping-pong, 1 one buffer ({.depth = 1})       default 2
 *   GP_DM_FIXED_T    stack + runtime state in the core-DM budget (GP_DM_FIXED)                    default 8192
 * gemm_plan_body.cc's geometry defines (KA_TM 64, KA_TN 64, KA_KC 128, GP_DM_FIXED 8 KiB) stay the defaults
 * and stay untouched: the generated host.cc carries the body's text up to the kernel verbatim, so the 64 x 64
 * default build is byte-identical only if the knobs live in this header (#included, not inlined). With a knob
 * set, the geometry is redefined here and everything after (kernel, host side) expands the new values; the
 * budget below is the costmodel's DM formula (FEAS): fixed + int32 partial sums + 2 input streams x 2 slots x
 * one chunk + GP_C_DEPTH output tiles. */
#if defined(GP_TM) || defined(GP_TN) || defined(GP_KC) || defined(GP_C_DEPTH) || defined(GP_DM_FIXED_T)
#ifndef GP_TM
#define GP_TM 64
#endif
#ifndef GP_TN
#define GP_TN 64
#endif
#ifndef GP_KC
#define GP_KC 128
#endif
#ifndef GP_C_DEPTH
#define GP_C_DEPTH 2
#endif
#ifndef GP_DM_FIXED_T
#define GP_DM_FIXED_T 8192
#endif
#undef KA_TM
#define KA_TM GP_TM
#undef KA_TN
#define KA_TN GP_TN
#undef KA_KC
#define KA_KC GP_KC
#undef K4_KC
#define K4_KC GP_KC
#undef GP_DM_FIXED
#define GP_DM_FIXED GP_DM_FIXED_T
#undef GP_IN_BYTES
#define GP_IN_BYTES (GP_CORE_S2MM * 2 * (KA_TM > KA_TN ? KA_TM : KA_TN) * KA_KC)
#undef GP_DM_USED
#define GP_DM_USED (GP_DM_FIXED + GP_ACC_BYTES + GP_IN_BYTES + GP_C_DEPTH * GP_OUT_TILE_BYTES / GP_C_SPLIT)
static_assert(GP_TM % 16 == 0 && GP_TN % 16 == 0, "GP_TM / GP_TN: whole 16-row accumulator pairs");
static_assert(GP_KC % 16 == 0 && GP_KC / GP_ES % 8 == 0, "GP_KC: whole 8-deep k blocks");
static_assert(GP_C_DEPTH == 1 || GP_C_DEPTH == 2, "GP_C_DEPTH: 1 (one output buffer) or 2 (ping-pong)");
static_assert(GP_M % (GP_HW_ROWS * KA_TM) == 0 && KA_M == GP_M, "GP_M: whole GP_TM-row tiles on every mesh row");
static_assert(KA_N == GP_N && SH_NT2 == 1, "2 x 8 layout: N = 2 x mesh columns x GP_TN (one B tile per core)");
static_assert(GP_K % GP_KCE == 0 && KA_K % KA_KC == 0 && SH_NK >= 2, "K: whole chunks, at least 2");
static_assert(SH_TILES >= 1 && SH_TILES <= 64, "tiles / core <= 64 (6-bit OOO iteration counter)");
static_assert(GP_RING_CHUNKS % (2 * GP_RING) == 0, "A ring must divide the chunk stream (set GP_RING)");
static_assert(GP_RING * 2 * KA_TM * KA_KC <= GP_MT_BYTES, "A's ring must fit its MemTile");
static_assert(GP_B_MT_BYTES <= GP_MT_BYTES, "B's MemTile buffers must fit its 512 KiB MemTile");
static_assert(GP_C_SPLIT == 1 || GP_DTYPE == 2, "int8: the whole output tile in one slice");
static_assert(GP_DM_USED <= GP_DM_BYTES, "core DM (64 KiB): fixed + partial sums + input slots + output slots must fit");
#else
#define GP_C_DEPTH 2
#endif
/* the hand-scheduled 4 x 4-pair pipeline above (K4_* / SH_*) is the 64 x 64 x 128 tile; any other tile runs
 * the generic chunk (GT_CHUNK) */
#define GP_K4_TILE (KA_TM == 64 && KA_TN == 64 && KA_KC == 128)
#if GP_C_DEPTH == 1
#define GT_C_OPTS {.depth = 1, .align = 64}
#else
#define GT_C_OPTS {.align = 64}
#endif
/* the two row parts of a chunk (rows 0 .. T/2 - 1, T/2 .. T - 1) */
#if !defined(GP_PARTS) || GP_PARTS == 2
#define GT_PART(x, i, T) ((const int8_t *)(x).part(i))
#else
#define GT_PART(x, i, T) ((const int8_t *)(x) + (i) * ((T) / 2 * KA_KC))
#endif
/* 8 x 8 operand block (row block r of a T-row chunk, k block kb; [r][kb][64], row blocks < T/16 in part 0) */
#define GT_OP(p0, p1, r, kb, T) (((r) / ((T) / 16) ? (p1) : (p0)) + (((r) % ((T) / 16)) * (KA_KC / 8) + (kb)) * 64)
/* one chunk over the tile: (KA_TM / 16) x (KA_TN / 16) pairs of 2 x 2 accumulators (aie::mmul<8, 8, 8>).
 * first: the accumulators start at zero; last: int8 (low byte, as K4_OUT) straight to the output tile y
 * ([mi][ni][8 m][8 n]); otherwise the int32 partial sums go back to f ([mi][ni][64]). */
#define GT_CHUNK(f, y, a0, a1, b0, b1, first, last)                                                                    \
    for (int mi = 0; mi < KA_TM / 8; mi += 2)                                                                          \
        for (int ni = 0; ni < KA_TN / 8; ni += 2) {                                                                    \
            int32_t *f00 = (f) + (mi * (KA_TN / 8) + ni) * 64, *f01 = f00 + 64;                                        \
            int32_t *f10 = f00 + (KA_TN / 8) * 64, *f11 = f10 + 64;                                                    \
            KaMM4 c0, c1, c2, c3;                                                                                      \
            if (first) {                                                                                               \
                const aie::accum<acc32, 64> z_ = aie::zeros<acc32, 64>();                                              \
                c0 = KaMM4(z_);                                                                                        \
                c1 = KaMM4(z_);                                                                                        \
                c2 = KaMM4(z_);                                                                                        \
                c3 = KaMM4(z_);                                                                                        \
            } else {                                                                                                   \
                aie::accum<acc32, 64> q0_, q1_, q2_, q3_;                                                              \
                q0_.from_vector(aie::load_v<64>(f00));                                                                 \
                q1_.from_vector(aie::load_v<64>(f01));                                                                 \
                q2_.from_vector(aie::load_v<64>(f10));                                                                 \
                q3_.from_vector(aie::load_v<64>(f11));                                                                 \
                c0 = KaMM4(q0_);                                                                                       \
                c1 = KaMM4(q1_);                                                                                       \
                c2 = KaMM4(q2_);                                                                                       \
                c3 = KaMM4(q3_);                                                                                       \
            }                                                                                                          \
            for (int kb = 0; kb < KA_KC / 8; kb++)                                                                     \
                chess_prepare_for_pipelining {                                                                         \
                    const aie::vector<int8_t, 64> va0 = aie::load_v<64>(GT_OP(a0, a1, mi, kb, KA_TM));                 \
                    const aie::vector<int8_t, 64> va1 = aie::load_v<64>(GT_OP(a0, a1, mi + 1, kb, KA_TM));             \
                    const aie::vector<int8_t, 64> vb0 = aie::load_v<64>(GT_OP(b0, b1, ni, kb, KA_TN));                 \
                    const aie::vector<int8_t, 64> vb1 = aie::load_v<64>(GT_OP(b0, b1, ni + 1, kb, KA_TN));             \
                    c0.mac(va0, vb0);                                                                                  \
                    c1.mac(va0, vb1);                                                                                  \
                    c2.mac(va1, vb0);                                                                                  \
                    c3.mac(va1, vb1);                                                                                  \
                }                                                                                                      \
            if (last) {                                                                                                \
                int8_t *o_ = (y) + (mi * (KA_TN / 8) + ni) * 64;                                                       \
                aie::store_v(o_, c0.to_vector<int8_t>(0));                                                             \
                aie::store_v(o_ + 64, c1.to_vector<int8_t>(0));                                                        \
                aie::store_v(o_ + (KA_TN / 8) * 64, c2.to_vector<int8_t>(0));                                          \
                aie::store_v(o_ + (KA_TN / 8) * 64 + 64, c3.to_vector<int8_t>(0));                                     \
            } else {                                                                                                   \
                aie::store_v(f00, c0.to_vector<int32_t>());                                                            \
                aie::store_v(f01, c1.to_vector<int32_t>());                                                            \
                aie::store_v(f10, c2.to_vector<int32_t>());                                                            \
                aie::store_v(f11, c3.to_vector<int32_t>());                                                            \
            }                                                                                                          \
        }
#endif
