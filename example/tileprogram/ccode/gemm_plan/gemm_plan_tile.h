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
/* ---- generic tile (M3.3.6.2.1.2.3.1, gemm_plan_tbody.cc knobs GP_TM / GP_TN / GP_KC / GP_C_DEPTH) ---------- */
/* the hand-scheduled 4 x 4-pair pipeline above (K4_* / SH_*) is the 64 x 64 x 128 tile; any other tile runs
 * the generic chunk (GT_CHUNK) */
#define GP_K4_TILE (KA_TM == 64 && KA_TN == 64 && KA_KC == 128)
#if defined(GP_C_DEPTH) && GP_C_DEPTH == 1
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
/* The int32 partial sums: ONE array per 8-row block (8 x KA_TN int32: [KA_TN / 8][64]), not one KA_TM x KA_TN
 * array -- the compiler places the hosted windows from 0x78000 up in the core's DMb and the stack (4096 B) and
 * statics from 0x70000, so a 96 x 96 x 4 B = 36864 B array has no contiguous hole; 3072 B pieces fill the holes
 * on both sides. GT_ACC_DECL declares block i (the kernel declares blocks 0 .. KA_TM / 8 - 1 and their table). */
#define GT_ACC_DECL(i) alignas(64) static int32_t acc##i[8 * KA_TN];
/* one chunk over 8-row blocks m0 .. m1 - 1 of the tile (pair rows m0 / 2 .. m1 / 2 - 1) x all KA_TN / 16 pair
 * columns: 2 x 2 accumulators (aie::mmul<8, 8, 8>) per (pair row, pair column). first: the accumulators start at
 * zero; last: int8 (low byte, as K4_OUT) straight to the output slice y, whose first 8-row block is ym0
 * ([mi][ni][8 m][8 n]); otherwise the int32 partial sums go back to fp[8-row block]. */
#define GT_CHUNK(fp, y, ym0, a0, a1, b0, b1, first, last, m0, m1)                                                      \
    for (int mi = (m0); mi < (m1); mi += 2)                                                                            \
        for (int ni = 0; ni < KA_TN / 8; ni += 2) {                                                                    \
            int32_t *f00 = (fp)[mi] + ni * 64, *f01 = f00 + 64;                                                        \
            int32_t *f10 = (fp)[mi + 1] + ni * 64, *f11 = f10 + 64;                                                    \
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
                int8_t *o_ = (y) + ((mi - (ym0)) * (KA_TN / 8) + ni) * 64;                                             \
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
/* ---- GT_CHUNK_P (M3.3.6.2.1.2.4.1 fix96_inner, gemm_plan_tbody.cc GP_GT 1 / 2) -------------------------------
 * GT_CHUNK with the inner loop at 64 x 64 level: first / last are compile-time constants (the kernel calls one
 * specialisation per chunk kind, so no branch is left in the loop), the k blocks are flattened, and the loop over the
 * pair columns is software-pipelined -- the accumulator reload / store of one 2 x 2 block overlaps the VMACs of the
 * next. ns = 1: one chunk (a0 .. b1); ns = 2: two chunks (both input slots, a0 .. b1 then a0q .. b1q) per accumulator
 * reload, i.e. 2 * KA_KC of K per int32 round trip. Same numerics as GT_CHUNK (kernel_trace_cases "gt_chunk_p"). */
#define GT_KB(c0, c1, c2, c3, pa0, pa1, pb0, pb1)                                                                      \
    for (int kb = 0; kb < KA_KC / 8; kb++)                                                                             \
        chess_flatten_loop {                                                                                           \
            const aie::vector<int8_t, 64> va0 = aie::load_v<64>((pa0) + kb * 64);                                      \
            const aie::vector<int8_t, 64> va1 = aie::load_v<64>((pa1) + kb * 64);                                      \
            const aie::vector<int8_t, 64> vb0 = aie::load_v<64>((pb0) + kb * 64);                                      \
            const aie::vector<int8_t, 64> vb1 = aie::load_v<64>((pb1) + kb * 64);                                      \
            c0.mac(va0, vb0);                                                                                          \
            c1.mac(va0, vb1);                                                                                          \
            c2.mac(va1, vb0);                                                                                          \
            c3.mac(va1, vb1);                                                                                          \
        }
#define GT_CHUNK_P2(fp, y, ym0, a0, a1, b0, b1, a0q, a1q, b0q, b1q, first, last, m0, m1, ns)                           \
    for (int mi = (m0); mi < (m1); mi += 2) {                                                                          \
        const int8_t *__restrict pa0_ = GT_OP(a0, a1, mi, 0, KA_TM), *__restrict pa1_ = GT_OP(a0, a1, mi + 1, 0, KA_TM); \
        const int8_t *__restrict qa0_ = GT_OP(a0q, a1q, mi, 0, KA_TM);                                                 \
        const int8_t *__restrict qa1_ = GT_OP(a0q, a1q, mi + 1, 0, KA_TM);                                             \
        int32_t *__restrict fr0_ = (fp)[mi], *__restrict fr1_ = (fp)[mi + 1];                                          \
        int8_t *__restrict yr_ = (last) ? (y) + (mi - (ym0)) * (KA_TN / 8) * 64 : nullptr;                             \
        for (int ni = 0; ni < KA_TN / 8; ni += 2)                                                                      \
            chess_prepare_for_pipelining chess_loop_range(KA_TN / 16, KA_TN / 16) {                                    \
                int32_t *__restrict f00 = fr0_ + ni * 64, *__restrict f10 = fr1_ + ni * 64;                            \
                KaMM4 c0, c1, c2, c3;                                                                                  \
                if (first) {                                                                                           \
                    const aie::accum<acc32, 64> z_ = aie::zeros<acc32, 64>();                                          \
                    c0 = KaMM4(z_);                                                                                    \
                    c1 = KaMM4(z_);                                                                                    \
                    c2 = KaMM4(z_);                                                                                    \
                    c3 = KaMM4(z_);                                                                                    \
                } else {                                                                                               \
                    aie::accum<acc32, 64> q0_, q1_, q2_, q3_;                                                          \
                    q0_.from_vector(aie::load_v<64>(f00));                                                             \
                    q1_.from_vector(aie::load_v<64>(f00 + 64));                                                        \
                    q2_.from_vector(aie::load_v<64>(f10));                                                             \
                    q3_.from_vector(aie::load_v<64>(f10 + 64));                                                        \
                    c0 = KaMM4(q0_);                                                                                   \
                    c1 = KaMM4(q1_);                                                                                   \
                    c2 = KaMM4(q2_);                                                                                   \
                    c3 = KaMM4(q3_);                                                                                   \
                }                                                                                                      \
                const int8_t *__restrict pb0_ = GT_OP(b0, b1, ni, 0, KA_TN);                                           \
                const int8_t *__restrict pb1_ = GT_OP(b0, b1, ni + 1, 0, KA_TN);                                       \
                GT_KB(c0, c1, c2, c3, pa0_, pa1_, pb0_, pb1_)                                                          \
                if ((ns) == 2) {                                                                                       \
                    const int8_t *__restrict qb0_ = GT_OP(b0q, b1q, ni, 0, KA_TN);                                     \
                    const int8_t *__restrict qb1_ = GT_OP(b0q, b1q, ni + 1, 0, KA_TN);                                 \
                    GT_KB(c0, c1, c2, c3, qa0_, qa1_, qb0_, qb1_)                                                      \
                }                                                                                                      \
                if (last) {                                                                                            \
                    int8_t *o_ = yr_ + ni * 64;                                                                        \
                    aie::store_v(o_, c0.to_vector<int8_t>(0));                                                         \
                    aie::store_v(o_ + 64, c1.to_vector<int8_t>(0));                                                    \
                    aie::store_v(o_ + (KA_TN / 8) * 64, c2.to_vector<int8_t>(0));                                      \
                    aie::store_v(o_ + (KA_TN / 8) * 64 + 64, c3.to_vector<int8_t>(0));                                 \
                } else {                                                                                               \
                    aie::store_v(f00, c0.to_vector<int32_t>());                                                        \
                    aie::store_v(f00 + 64, c1.to_vector<int32_t>());                                                   \
                    aie::store_v(f10, c2.to_vector<int32_t>());                                                        \
                    aie::store_v(f10 + 64, c3.to_vector<int32_t>());                                                   \
                }                                                                                                      \
            }                                                                                                          \
    }
#define GT_CHUNK_P(fp, y, ym0, a0, a1, b0, b1, first, last, m0, m1)                                                    \
    GT_CHUNK_P2(fp, y, ym0, a0, a1, b0, b1, a0, a1, b0, b1, first, last, m0, m1, 1)
/* ---- GT_CHUNK_K (GP_GT 3 / 4): the K4 idea on the generic tile -- two 2 x 2 accumulator sets X / Y, hand-pipelined:
 * Y's int32 partial sums are loaded before X's VMACs, X's are stored (and the next X loaded) before Y's VMACs, so the
 * accumulator round trip of one block overlaps the VMACs of the other (with GT_CHUNK_P the store of block j and the
 * load of block j + 1 may alias, which serialises the pipelined loop: 39 bundles / 16 MAC). Walk: pair rows mi
 * (outer), pair columns ni in steps of 2 pairs (X = ni, Y = ni + 2); the X after the last Y of a row is the next
 * row's first pair (after the last row: pair (m0, 0) again, loaded and discarded -- a valid address, no branch).
 * Operand / partial-sum addresses are selects and constant multiplies (no division in the loop). KA_TN % 32 == 0.
 * ns as GT_CHUNK_P2 (2: two chunks a0 .. b1 then a0q .. b1q per partial-sum round trip). */
/* 8 x 8 operand block r of a T-row chunk (parts p0 / p1), k block 0 -- GT_OP without the division */
#define GT_OPS(p0, p1, r, T) ((r) < (T) / 16 ? (p0) + (r) * (KA_KC / 8) * 64 : (p1) + ((r) - (T) / 16) * (KA_KC / 8) * 64)
#define GT_LDC(c, first, g0, g1)                                                                                       \
    if (first) {                                                                                                       \
        const aie::accum<acc32, 64> z_ = aie::zeros<acc32, 64>();                                                      \
        c##0 = KaMM4(z_);                                                                                              \
        c##1 = KaMM4(z_);                                                                                              \
        c##2 = KaMM4(z_);                                                                                              \
        c##3 = KaMM4(z_);                                                                                              \
    } else {                                                                                                           \
        aie::accum<acc32, 64> q0_, q1_, q2_, q3_;                                                                      \
        q0_.from_vector(aie::load_v<64>(g0));                                                                          \
        q1_.from_vector(aie::load_v<64>((g0) + 64));                                                                   \
        q2_.from_vector(aie::load_v<64>(g1));                                                                          \
        q3_.from_vector(aie::load_v<64>((g1) + 64));                                                                   \
        c##0 = KaMM4(q0_);                                                                                             \
        c##1 = KaMM4(q1_);                                                                                             \
        c##2 = KaMM4(q2_);                                                                                             \
        c##3 = KaMM4(q3_);                                                                                             \
    }
#define GT_MACC(c, pa0, pa1, qa0, qa1, b0, b1, b0q, b1q, ns, ni_)                                                     \
    {                                                                                                                  \
        const int8_t *__restrict pb0_ = GT_OPS(b0, b1, ni_, KA_TN), *__restrict pb1_ = GT_OPS(b0, b1, (ni_) + 1, KA_TN); \
        GT_KB(c##0, c##1, c##2, c##3, pa0, pa1, pb0_, pb1_)                                                            \
        if ((ns) == 2) {                                                                                               \
            const int8_t *__restrict qb0_ = GT_OPS(b0q, b1q, ni_, KA_TN);                                              \
            const int8_t *__restrict qb1_ = GT_OPS(b0q, b1q, (ni_) + 1, KA_TN);                                        \
            GT_KB(c##0, c##1, c##2, c##3, qa0, qa1, qb0_, qb1_)                                                        \
        }                                                                                                              \
    }
#define GT_STC(c, last, g0, g1, o)                                                                                     \
    if (last) {                                                                                                        \
        aie::store_v((o), (c##0).to_vector<int8_t>(0));                                                                \
        aie::store_v((o) + 64, (c##1).to_vector<int8_t>(0));                                                           \
        aie::store_v((o) + (KA_TN / 8) * 64, (c##2).to_vector<int8_t>(0));                                            \
        aie::store_v((o) + (KA_TN / 8) * 64 + 64, (c##3).to_vector<int8_t>(0));                                       \
    } else {                                                                                                           \
        aie::store_v((g0), (c##0).to_vector<int32_t>());                                                               \
        aie::store_v((g0) + 64, (c##1).to_vector<int32_t>());                                                          \
        aie::store_v((g1), (c##2).to_vector<int32_t>());                                                               \
        aie::store_v((g1) + 64, (c##3).to_vector<int32_t>());                                                          \
    }
/* the pair-column loop of a chunk kind (first, last): GP_GT_UNROLL 1 flattens it in the middle kind (a whole pair row
 * of X / Y steps scheduled as one block); the first / last kinds (2 of SH_NK / GT_NS steps) keep the loop */
#if defined(GP_GT_UNROLL) && GP_GT_UNROLL
#define GT_NI_LOOP_00 chess_flatten_loop
#else
#define GT_NI_LOOP_00 chess_loop_range(KA_TN / 32, KA_TN / 32)
#endif
#define GT_NI_LOOP_10 chess_loop_range(KA_TN / 32, KA_TN / 32)
#define GT_NI_LOOP_01 chess_loop_range(KA_TN / 32, KA_TN / 32)
#define GT_NI_LOOP_11 chess_loop_range(KA_TN / 32, KA_TN / 32)
#define GT_CHUNK_K(fp, y, ym0, a0, a1, b0, b1, a0q, a1q, b0q, b1q, first, last, m0, m1, ns)                            \
    {                                                                                                                  \
        KaMM4 X0, X1, X2, X3, Y0, Y1, Y2, Y3;                                                                          \
        GT_LDC(X, first, (fp)[m0], (fp)[(m0) + 1])                                                                     \
        for (int mi = (m0); mi < (m1); mi += 2) {                                                                      \
            const int8_t *__restrict pa0_ = GT_OPS(a0, a1, mi, KA_TM), *__restrict pa1_ = GT_OPS(a0, a1, mi + 1, KA_TM); \
            const int8_t *__restrict qa0_ = GT_OPS(a0q, a1q, mi, KA_TM);                                               \
            const int8_t *__restrict qa1_ = GT_OPS(a0q, a1q, mi + 1, KA_TM);                                           \
            int32_t *const r0_ = (fp)[mi], *const r1_ = (fp)[mi + 1];                                                  \
            const int mn_ = mi + 2 < (m1) ? mi + 2 : (m0);                                                             \
            int32_t *const n0_ = (fp)[mn_], *const n1_ = (fp)[mn_ + 1];                                                \
            int8_t *const yr_ = (last) ? (y) + (mi - (ym0)) * (KA_TN / 8) * 64 : nullptr;                              \
            for (int ni = 0; ni < KA_TN / 8; ni += 4)                                                                  \
                GT_NI_LOOP_##first##last {                                                                             \
                    /* the three partial-sum blocks of this step (Y, X, next X) are disjoint: restrict lets the next \
                       X load move above X's store (otherwise store -> load order serialises the two sets) */      \
                    const bool nx_ = ni + 4 < KA_TN / 8;                                                               \
                    int32_t *__restrict py0_ = r0_ + (ni + 2) * 64, *__restrict py1_ = r1_ + (ni + 2) * 64;            \
                    int32_t *__restrict px0_ = r0_ + ni * 64, *__restrict px1_ = r1_ + ni * 64;                        \
                    const int32_t *__restrict pn0_ = nx_ ? r0_ + (ni + 4) * 64 : n0_;                                  \
                    const int32_t *__restrict pn1_ = nx_ ? r1_ + (ni + 4) * 64 : n1_;                                  \
                    GT_LDC(Y, first, py0_, py1_)                                                                       \
                    GT_MACC(X, pa0_, pa1_, qa0_, qa1_, b0, b1, b0q, b1q, ns, ni)                                       \
                    GT_STC(X, last, px0_, px1_, yr_ + ni * 64)                                                         \
                    GT_LDC(X, first, pn0_, pn1_)                                                                       \
                    GT_MACC(Y, pa0_, pa1_, qa0_, qa1_, b0, b1, b0q, b1q, ns, ni + 2)                                   \
                    GT_STC(Y, last, py0_, py1_, yr_ + (ni + 2) * 64)                                                   \
                }                                                                                                      \
        }                                                                                                              \
    }
#endif
