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
#endif
