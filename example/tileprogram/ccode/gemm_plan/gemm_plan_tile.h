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
#if defined(GP_N_SLICES) && GP_N_SLICES > 1
/* N-slices (#pragma dataflow_slices, m3362124221 P2): the output tile goes out ROW-MAJOR (KA_TN bytes per row) --
 * the shim BD writes its rows at the row stride of the whole C (ldc = slices x N). Row r of blocks (mi, ni) and
 * (mi, ni + 1) = 16 contiguous bytes (interleave_zip by 8, as simplegemm_dataflow.cc). */
/* PK (m3362124222211): the 4 rows r0..r3 of a zipped 64-byte vector v at t, t + KA_TN, .. -- ONE VSHIFT (16 B down)
 * per vector instead of three: rows 0 / 2 are quarters 0 / 2 of v, rows 1 / 3 quarters 0 / 2 of the shifted copy;
 * quarter 2 is the low quarter of the high 256-bit half (a register move, not a vector-slot op). VSHIFT and
 * VSHUFFLE take the VMAC's vector slot, so the last chunk's loop is 128 VMAC + its shifts / shuffles. */
#define K4_ROW4(t, v)                                                                                                  \
    {                                                                                                                  \
        const aie::vector<int8_t, 64> v_ = (v);                                                                        \
        const aie::vector<int8_t, 64> s_ = aie::shuffle_down_fill(v_, v_, 16);                                         \
        aie::store_v((t), v_.extract<32>(0).extract<16>(0));                                                           \
        aie::store_v((t) + 2 * KA_TN, v_.extract<32>(1).extract<16>(0));                                               \
        aie::store_v((t) + KA_TN, s_.extract<32>(0).extract<16>(0));                                                   \
        aie::store_v((t) + 3 * KA_TN, s_.extract<32>(1).extract<16>(0));                                               \
    }
#define K4_OUT(p, c, bl)                                                                                               \
    {                                                                                                                  \
        const int L_ = (bl) ^ swz;                                                                                     \
        int8_t *__restrict tt_ = y + (2 * (L_ >> 2)) * 8 * KA_TN + 2 * (L_ & 3) * 8;                                            \
        const auto z0_ = aie::interleave_zip((c##0).to_vector<int8_t>(0), (c##1).to_vector<int8_t>(0), 8);            \
        const auto z1_ = aie::interleave_zip((c##2).to_vector<int8_t>(0), (c##3).to_vector<int8_t>(0), 8);            \
        K4_ROW4(tt_, z0_.first);                                                                                       \
        K4_ROW4(tt_ + 4 * KA_TN, z0_.second);                                                                          \
        K4_ROW4(tt_ + 8 * KA_TN, z1_.first);                                                                           \
        K4_ROW4(tt_ + 12 * KA_TN, z1_.second);                                                                         \
    }
#else
#define K4_OUT(p, c, bl)                                                                                               \
    {                                                                                                                  \
        const int L_ = (bl) ^ swz;                                                                                     \
        int8_t *tt_ = y + ((2 * (L_ >> 2)) * 8 + 2 * (L_ & 3)) * 64;                                                   \
        aie::store_v(tt_, (c##0).to_vector<int8_t>(0));                                                                \
        aie::store_v(tt_ + 64, (c##1).to_vector<int8_t>(0));                                                           \
        aie::store_v(tt_ + 8 * 64, (c##2).to_vector<int8_t>(0));                                                       \
        aie::store_v(tt_ + 8 * 64 + 64, (c##3).to_vector<int8_t>(0));                                                  \
    }
#endif
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
/* PK chunk 0: the block's first k-step is a mul (acc = A x B), so the accumulators are never zeroed (no VMOV.D
 * on the vector slot, no K4_LDZ) */
#define K4_STEPXM(c, l, m, A0, A1, B0, B1)                                                                             \
    {                                                                                                                  \
        const aie::vector<int8_t, 64> n0 = aie::load_v<64>(l), n1 = aie::load_v<64>((l) + K4_H);                       \
        const aie::vector<int8_t, 64> m0 = aie::load_v<64>(m), m1 = aie::load_v<64>((m) + K4_H);                       \
        (c##0).mul(A0, B0);                                                                                            \
        (c##1).mul(A0, B1);                                                                                            \
        (c##2).mul(A1, B0);                                                                                            \
        (c##3).mul(A1, B1);                                                                                            \
        A0 = n0;                                                                                                       \
        A1 = n1;                                                                                                       \
        B0 = m0;                                                                                                       \
        B1 = m1;                                                                                                       \
    }
#define K4_BLKZ(c, pa0, pb0, npa, npb)                                                                                 \
    {                                                                                                                  \
        const int8_t *__restrict pa_ = (pa0);                                                                          \
        const int8_t *__restrict pb_ = (pb0);                                                                          \
        K4_STEPXM(c, pa_ + 2 * 64, pb_ + 2 * 64, va0, va1, vb0, vb1);                                                  \
        K4_STEPW(c, pa_ + 2 * 64 + 64, pb_ + 2 * 64 + 64);                                                             \
        for (int ki = 4; ki < KA_KC / 8; ki += 2)                                                                      \
            chess_flatten_loop {                                                                                       \
                K4_STEP(c, pa_ + ki * 64, pb_ + ki * 64);                                                              \
                K4_STEPW(c, pa_ + ki * 64 + 64, pb_ + ki * 64 + 64);                                                   \
            }                                                                                                          \
        K4_STEP(c, (npa), (npb));                                                                                      \
        K4_STEPW(c, (npa) + 64, (npb) + 64);                                                                           \
    }
#define K4_LDN(c, p)
/* PK: K4_BLK split at its last two k-steps (the only ones that load from (npa, npb)), so the next chunk can be taken
 * between them -- its lock code then shares bundles with the 8 VMACs whose operands are already in registers. */
#define K4_BLK_HEAD(c, pa0, pb0)                                                                                       \
    {                                                                                                                  \
        const int8_t *__restrict pa_ = (pa0);                                                                          \
        const int8_t *__restrict pb_ = (pb0);                                                                          \
        for (int ki = 2; ki < KA_KC / 8; ki += 2)                                                                      \
            chess_flatten_loop {                                                                                       \
                K4_STEP(c, pa_ + ki * 64, pb_ + ki * 64);                                                              \
                K4_STEPW(c, pa_ + ki * 64 + 64, pb_ + ki * 64 + 64);                                                   \
            }                                                                                                          \
    }
#define K4_BLK_TAIL(c, npa, npb)                                                                                       \
    {                                                                                                                  \
        K4_STEP(c, (npa), (npb));                                                                                      \
        K4_STEPW(c, (npa) + 64, (npb) + 64);                                                                           \
    }
/* 7 iterations: blocks 1 .. 14 of the current chunk (state: X = block 0 done, Y = block 1 loaded) */
#define K4_STI(p, c, bl) K4_ST(p, c)
#define SH_INNER_W(ST, LD) SH_INNER_G(ST, LD, K4_BLK)
#define SH_INNER_G(ST, LD, BLK)                                                                                        \
    {                                                                                                                  \
        const int8_t *bP_ = bXo, *bQ_ = bX; /* PK: bY = bP_ + 2048, bX = bQ_, bYo = bQ_ + 2048; swapped every i */   \
        for (int i = 0; i < 7; i++) {                                                                                  \
            ST(cur, X, 2 * i);                                                                                         \
            LD(X, nxt);                                                                                                \
            BLK(Y, aY, bP_ + 2048, aX, bQ_);                                                                           \
            ST(cur + 256, Y, 2 * i + 1);                                                                               \
            LD(Y, nxt + 256);                                                                                          \
            const int8_t *aY2 = aX;                                                                                    \
            BLK(X, aX, bQ_, aY2, bQ_ + 2048);                                                                          \
            int32_t *t_ = cur + 512 + 0;                                                                               \
            cur = nxt;                                                                                                 \
            nxt = t_;                                                                                                  \
            aX = aY + 2048 + ((unsigned)(i - 2) < 2u ? dA : 0);                                                        \
            aY = aY2;                                                                                                  \
            const int8_t *tb = bP_;                                                                                    \
            bP_ = bQ_;                                                                                                 \
            bQ_ = tb;                                                                                                  \
        }                                                                                                              \
        bY = bP_ + 2048;                                                                                               \
    }
/* PK: the last chunk (ST = K4_OUT writes the output tile, not cur): only the partial-sum load pointer nxt is
 * live -- nxt walks ao, ae + 512, ao + 512, ae + 1024, .. (step dn_ = -1536, +2048, ..), one pointer fewer */
#define SH_INNER_O(ST, LD)                                                                                             \
    {                                                                                                                  \
        int dn_ = -1536;                                                                                               \
        const int8_t *bP_ = bXo, *bQ_ = bX; /* bY = bP_ + 2048, bX = bQ_, bYo = bQ_ + 2048; swapped every i */        \
        for (int i = 0; i < 7; i++) {                                                                                  \
            ST(nxt, X, 2 * i);                                                                                         \
            LD(X, nxt);                                                                                                \
            K4_BLK(Y, aY, bP_ + 2048, aX, bQ_);                                                                        \
            ST(nxt, Y, 2 * i + 1);                                                                                     \
            LD(Y, nxt + 256);                                                                                          \
            const int8_t *aY2 = aX;                                                                                    \
            K4_BLK(X, aX, bQ_, aY2, bQ_ + 2048);                                                                       \
            nxt += dn_;                                                                                                \
            dn_ = 512 - dn_;                                                                                           \
            aX = aY + 2048 + ((unsigned)(i - 2) < 2u ? dA : 0);                                                        \
            aY = aY2;                                                                                                  \
            const int8_t *tb = bP_;                                                                                    \
            bP_ = bQ_;                                                                                                 \
            bQ_ = tb;                                                                                                  \
        }                                                                                                              \
        bY = bP_ + 2048;                                                                                               \
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
/* one operand's two halves (PB: SH_BOUND_S takes A and B apart) */
#define SH_PART2(x, w, l_, h_, rows)                                                                                   \
    l_ = (const int8_t *)(x).part(w);                                                                                  \
    h_ = (const int8_t *)(x).part((w) ^ 1);
#define SH_PARTS(xa, xb, al_, ah_, bl_, bh_)                                                                           \
    al_ = (const int8_t *)(xa).part(pa);                                                                               \
    ah_ = (const int8_t *)(xa).part(pa ^ 1);                                                                           \
    bl_ = (const int8_t *)(xb).part(pb);                                                                               \
    bh_ = (const int8_t *)(xb).part(pb ^ 1);
#else
#define SH_PART2(x, w, l_, h_, rows)                                                                                   \
    l_ = (const int8_t *)(x) + (w) * ((rows) / 2 * KA_KC);                                                             \
    h_ = (const int8_t *)(x) + ((w) ^ 1) * ((rows) / 2 * KA_KC);
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
/* PK chunk boundary (late take, late give-back): TAKE declares and fills (nAl, nAh, nBl, nBh) -- the next chunk's
 * load_buffer -- and runs after the 14 k-steps of block 15 that read only the current chunk; GIVE (the current
 * chunk's release) runs after the 14 k-steps of the next chunk's block 0. Same blocks, same order of accesses
 * per chunk as SH_BOUND1 / SH_BOUND2; the lock code is no longer a serial island between two VMAC streams. */
#define SH_BOUND_L(TAKE, GIVE)                                                                                         \
    {                                                                                                                  \
        K4_ST(cur, X);                                                                                                 \
        K4_LD(X, ae);                                                                                                  \
        K4_BLK_HEAD(Y, aY, bY);                                                                                        \
        TAKE;                                                                                                          \
        K4_BLK_TAIL(Y, nAl, nBl);                                                                                      \
        K4_ST(cur + 256, Y);                                                                                           \
        K4_LD(Y, ae + 256);                                                                                            \
        K4_BLK_HEAD(X, nAl, nBl);                                                                                      \
        GIVE;                                                                                                          \
        K4_BLK_TAIL(X, nAl, nBl + 2048);                                                                               \
        SH_RESET(nAl, nAh, nBl, nBh);                                                                                  \
    }
/* PB (m33621242222122, chunk-boundary static cut): K4_BLK_HEAD as two runs of k-steps [2, s) and [s, 16), so the
 * two operands' lock code sits in different VMAC runs. A chunk boundary's take / give is per operand (A then B); in
 * SH_BOUND_L the second operand's lock-id / slot arithmetic was a serial island between the first operand's lock
 * operations and its own (lock operations do not share bundles with the VMAC stream). SH_BOUND_S takes A after
 * k-step SH_SPLIT of block 15 and B after k-step 14 (gives likewise in the next chunk's block 0), so that arithmetic
 * co-issues with the k-steps in between. Same blocks, same order of accesses per chunk as SH_BOUND_L. */
#ifndef SH_SPLIT
#define SH_SPLIT 12
#endif
#define K4_BLK_RUN(c, pa0, pb0, k0, k1)                                                                                \
    {                                                                                                                  \
        const int8_t *__restrict pa_ = (pa0);                                                                          \
        const int8_t *__restrict pb_ = (pb0);                                                                          \
        for (int ki = (k0); ki < (k1); ki += 2)                                                                        \
            chess_flatten_loop {                                                                                       \
                K4_STEP(c, pa_ + ki * 64, pb_ + ki * 64);                                                              \
                K4_STEPW(c, pa_ + ki * 64 + 64, pb_ + ki * 64 + 64);                                                   \
            }                                                                                                          \
    }
#define SH_BOUND_S(TAKE_A, TAKE_B, GIVE_A, GIVE_B)                                                                     \
    {                                                                                                                  \
        K4_ST(cur, X);                                                                                                 \
        K4_LD(X, ae);                                                                                                  \
        K4_BLK_RUN(Y, aY, bY, 2, SH_SPLIT);                                                                            \
        TAKE_A;                                                                                                        \
        K4_BLK_RUN(Y, aY, bY, SH_SPLIT, KA_KC / 8);                                                                    \
        TAKE_B;                                                                                                        \
        K4_BLK_TAIL(Y, nAl, nBl);                                                                                      \
        K4_ST(cur + 256, Y);                                                                                           \
        K4_LD(Y, ae + 256);                                                                                            \
        K4_BLK_RUN(X, nAl, nBl, 2, SH_SPLIT);                                                                          \
        GIVE_A;                                                                                                        \
        K4_BLK_RUN(X, nAl, nBl, SH_SPLIT, KA_KC / 8);                                                                  \
        GIVE_B;                                                                                                        \
        K4_BLK_TAIL(X, nAl, nBl + 2048);                                                                               \
        SH_RESET(nAl, nAh, nBl, nBh);                                                                                  \
    }
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
#endif
