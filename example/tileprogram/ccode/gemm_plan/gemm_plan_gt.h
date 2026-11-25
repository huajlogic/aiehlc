// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// gemm_plan_gt.h -- the fix96_inner chunk kernels of the generic int8 tile (M3.3.6.2.1.2.4.1, gemm_plan_tbody.cc
// GP_GT 1 .. 4). Kept out of gemm_plan_tile.h so the 64 x 64 default build (gemm_plan.cc -> gemm_plan_body.cc ->
// gemm_plan_tile.h) compiles byte-identical inputs. Needs gemm_plan_tile.h first (GT_OP, GT_PART, KA_* knobs).
#ifndef GEMM_PLAN_GT_H
#define GEMM_PLAN_GT_H
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
