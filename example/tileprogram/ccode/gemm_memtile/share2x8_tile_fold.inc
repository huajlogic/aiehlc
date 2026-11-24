/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
#if defined(__chess__)
/* SHARE2X8 tile kernel (64 x 64 x NKC*128): one software pipeline across all chunks of a tile.
 * Blocks b = 0..15 per chunk (2x2 accumulators): A pair b >> 2, B pair b & 3; accumulators of block b
 * in bank (b >> 1) & 1 (ae / ao). A chunk's A pairs {0,1} sit at a_lo (+0 / +2048), {2,3} at a_hi; B
 * likewise. At a chunk boundary the last block of chunk j overlaps the first of chunk j+1: chunk j+1 is
 * acquired first, its first operands are prefetched during block 15, chunk j is released right after
 * its last reads -- no per-chunk prologue / epilogue / call. */
typedef aie::mmul<8, 8, 8, int8_t, int8_t> KaMM4;
#ifndef K4_KC
#define K4_KC 128
#endif
#define K4_H (K4_KC / 8 * 64) /* second row-octet of a pair */
#define K4_P (2 * K4_H)       /* next pair within a half */
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
#define K4_ST(p, c)                                                                                                    \
    {                                                                                                                  \
        aie::store_v((p), (c##0).to_vector<int32_t>());                                                                \
        aie::store_v((p) + 64, (c##1).to_vector<int32_t>());                                                           \
        aie::store_v((p) + 128, (c##2).to_vector<int32_t>());                                                          \
        aie::store_v((p) + 192, (c##3).to_vector<int32_t>());                                                          \
    }
#define K4_STEP(c, l, m)                                                                                               \
    {                                                                                                                  \
        const aie::vector<int8_t, 64> n0 = aie::load_v<64>(l), n1 = aie::load_v<64>((l) + K4_H);                       \
        const aie::vector<int8_t, 64> m0 = aie::load_v<64>(m), m1 = aie::load_v<64>((m) + K4_H);                       \
        (c##0).mac(va0, vb0);                                                                                          \
        (c##1).mac(va0, vb1);                                                                                          \
        (c##2).mac(va1, vb0);                                                                                          \
        (c##3).mac(va1, vb1);                                                                                          \
        va0 = wa0;                                                                                                     \
        va1 = wa1;                                                                                                     \
        vb0 = wb0;                                                                                                     \
        vb1 = wb1;                                                                                                     \
        wa0 = n0;                                                                                                      \
        wa1 = n1;                                                                                                      \
        wb0 = m0;                                                                                                      \
        wb1 = m1;                                                                                                      \
    }
#define K4_BLK(c, pa0, pb0, npa, npb)                                                                                  \
    {                                                                                                                  \
        const int8_t *__restrict pa_ = (pa0);                                                                          \
        const int8_t *__restrict pb_ = (pb0);                                                                          \
        for (int ki = 2; ki < K4_KC / 8; ki++)                                                                         \
            chess_flatten_loop K4_STEP(c, pa_ + ki * 64, pb_ + ki * 64);                                               \
        K4_STEP(c, (npa), (npb));                                                                                      \
        K4_STEP(c, (npa) + 64, (npb) + 64);                                                                            \
    }
#if K4_KC == 128
/* chunk g arrives on channel g & 1, slot (g >> 1) & 1; both halves in one 8 KB piece */
#define SH_CH(g) ((g) & 1)
#define SH_SLOT(g) (((g) >> 1) & 1)
/* dm: dummy chunk after the last one -- acquire / release own lock 15 (always 1) instead: an
 * acquire with value 0 waits for the lock to EQUAL 0 and hung when the next chunk was already filled */
#define SH_ACQ1(base, first, ch, dm)                                                                                   \
    {                                                                                                                  \
        if (first) {                                                                                                   \
            acquire_greater_equal((dm) ? 63 : (base) + 6 + 4 * (ch), 1);                                               \
            release((dm) ? 63 : (base) + 7 + 4 * (ch), 1);                                                             \
        } else {                                                                                                       \
            acquire_greater_equal((dm) ? 63 : (base) + 7 + 4 * (ch), 1);                                               \
            if (dm)                                                                                                    \
                release(63, 1);                                                                                        \
        }                                                                                                              \
    }
#define SH_ACQ(g, dm)                                                                                                 \
    {                                                                                                                  \
        SH_ACQ1(lA, fl & 1, SH_CH(g), dm);                                                                            \
        SH_ACQ1(lB, fl & 2, SH_CH(g), dm);                                                                            \
        chess_memory_fence();                                                                                          \
    }
#define SH_REL(g)                                                                                                      \
    {                                                                                                                  \
        chess_memory_fence();                                                                                          \
        release(lA + 8 + 4 * SH_CH(g) + SH_SLOT(g), lv);                                                               \
        release(lB + 8 + 4 * SH_CH(g) + SH_SLOT(g), lv);                                                               \
    }
#define SH_QOFF(g) ((2 * SH_CH(g) + SH_SLOT(g)) * 4096)
#else
/* KC 256: chunk g = rows 0-31 on channel 0 (bank 2), rows 32-63 on channel 1 (bank 3), slot g & 1 */
#define SH_ACQ1(base, first, ch, dm)                                                                                   \
    {                                                                                                                  \
        if (first) {                                                                                                   \
            acquire_greater_equal((dm) ? 63 : (base) + 6 + 4 * (ch), 1);                                               \
            release((dm) ? 63 : (base) + 7 + 4 * (ch), 1);                                                             \
        } else {                                                                                                       \
            acquire_greater_equal((dm) ? 63 : (base) + 7 + 4 * (ch), 1);                                               \
            if (dm)                                                                                                    \
                release(63, 1);                                                                                        \
        }                                                                                                              \
    }
#define SH_ACQ(g, dm)                                                                                                 \
    {                                                                                                                  \
        SH_ACQ1(lA, fl & 1, 0, dm);                                                                                   \
        SH_ACQ1(lA, fl & 1, 1, dm);                                                                                   \
        SH_ACQ1(lB, fl & 2, 0, dm);                                                                                   \
        SH_ACQ1(lB, fl & 2, 1, dm);                                                                                   \
        chess_memory_fence();                                                                                          \
    }
#define SH_REL(g)                                                                                                      \
    {                                                                                                                  \
        chess_memory_fence();                                                                                          \
        release(lA + 8 + ((g) & 1), lv);                                                                               \
        release(lA + 12 + ((g) & 1), lv);                                                                              \
        release(lB + 8 + ((g) & 1), lv);                                                                               \
        release(lB + 12 + ((g) & 1), lv);                                                                              \
    }
#define SH_QOFF(g) (((g) & 1) * 8192)
#endif
/* the four half pointers of chunk g, in this core's phase */
#define SH_HALVES(g, Alo, Ahi, Blo, Bhi)                                                                               \
    {                                                                                                                  \
        const unsigned q_ = SH_QOFF(g);                                                                                \
        const int8_t *x0_ = (const int8_t *)(vA + 0x8000 + q_), *x1_ = (const int8_t *)(vA + 0xc000 + q_);             \
        const int8_t *y0_ = (const int8_t *)(vB + 0x8000 + q_), *y1_ = (const int8_t *)(vB + 0xc000 + q_);             \
        Alo = (fl & 4) ? x1_ : x0_;                                                                                    \
        Ahi = (fl & 4) ? x0_ : x1_;                                                                                    \
        Blo = (fl & 8) ? y1_ : y0_;                                                                                    \
        Bhi = (fl & 8) ? y0_ : y1_;                                                                                    \
    }
/* 7 iterations: blocks 1 .. 14 of the current chunk (state: X = block 0 done, Y = block 1 loaded) */
#define SH_INNER()                                                                                                     \
    for (int i = 0; i < 7; i++) {                                                                                      \
        K4_ST(cur, X);                                                                                                 \
        K4_LD(X, nxt);                                                                                                 \
        K4_BLK(Y, aY, bY, aX, bX);                                                                                     \
        K4_ST(cur + 256, Y);                                                                                           \
        K4_LD(Y, nxt + 256);                                                                                           \
        const int8_t *aY2 = aX;                                                                                        \
        K4_BLK(X, aX, bX, aY2, bYo);                                                                                   \
        int32_t *t_ = cur + 512;                                                                                       \
        cur = nxt;                                                                                                     \
        nxt = t_;                                                                                                      \
        aX = aY + K4_P + ((unsigned)(i - 2) < 2u ? dA : 0);                                                            \
        aY = aY2;                                                                                                      \
        const int8_t *tb = bY;                                                                                         \
        bY = bYo;                                                                                                      \
        bYo = tb;                                                                                                      \
        tb = bX;                                                                                                       \
        bX = bXo;                                                                                                      \
        bXo = tb;                                                                                                      \
    }
/* pointer state for a chunk whose halves are (al_, ah_, bl_, bh_) */
#define SH_RESET(al_, ah_, bl_, bh_)                                                                                   \
    {                                                                                                                  \
        dA = (int)((ah_) - (al_)) - 2 * K4_P;                                                                              \
        cur = ae;                                                                                                      \
        nxt = ao;                                                                                                      \
        aY = (al_);                                                                                                    \
        aX = (al_);                                                                                                    \
        bY = (bl_) + K4_P;                                                                                             \
        bYo = (bh_) + K4_P;                                                                                            \
        bX = (bh_);                                                                                                    \
        bXo = (bl_);                                                                                                   \
    }
/* One 64 x 64 tile over nkc chunks starting at running chunk index g0; accumulators start at ZERO
 * (acc must be zeroed by the caller). fl: 1 A first reader, 2 B first reader, 4 A halves swapped,
 * 8 B halves swapped. ONE loop body for every block pair, the chunk boundary included: iteration i of a
 * chunk runs block 2i+1 (Y) and block 2i+2 (X; at i = 7 that is block 0 of the NEXT chunk). Lock work
 * sits at the top of the body (acquire the next chunk at i = 7, release the previous one at i = 0), the
 * chunk switch is selects -- so the body stays one basic block and the code holds three block copies.
 * After the last chunk the "next" chunk is a dummy (own lock 15): its block-0 MACs are never stored. */
__attribute__((noinline)) static void ka_tile(uintptr_t vA, uintptr_t vB, int lA, int lB, int fl, unsigned g0, int nkc, int lv,
                                              int32_t *__restrict ae, int32_t *__restrict ao) {
    KaMM4 X0, X1, X2, X3, Y0, Y1, Y2, Y3;
    const int8_t *Al, *Ah, *Bl, *Bh;
    int32_t *cur, *nxt;
    const int8_t *aY, *aX, *bY, *bYo, *bX, *bXo;
    int dA;
    unsigned g = g0;
    (void)lv;
    SH_ACQ(g, 0);
    SH_HALVES(g, Al, Ah, Bl, Bh);
    aie::vector<int8_t, 64> va0 = aie::load_v<64>(Al), va1 = aie::load_v<64>(Al + K4_H);
    aie::vector<int8_t, 64> vb0 = aie::load_v<64>(Bl), vb1 = aie::load_v<64>(Bl + K4_H);
    aie::vector<int8_t, 64> wa0 = aie::load_v<64>(Al + 64), wa1 = aie::load_v<64>(Al + K4_H + 64);
    aie::vector<int8_t, 64> wb0 = aie::load_v<64>(Bl + 64), wb1 = aie::load_v<64>(Bl + K4_H + 64);
    SH_RESET(Al, Ah, Bl, Bh);
    K4_LD(X, ae);
    K4_LD(Y, ae + 256);
    K4_BLK(X, Al, Bl, Al, Bl + K4_P);
    const int8_t *nAl = Al, *nAh = Ah, *nBl = Bl, *nBh = Bh;
    for (int j = 0; j < nkc; j++, g++) {
        for (int i = 0; i < 8; i++) {
            if (i == 0 && j > 0)
                SH_REL(g - 1);
            if (i == 7) {
                SH_ACQ(g + 1, j == nkc - 1);
                SH_HALVES(g + 1, nAl, nAh, nBl, nBh);
            }
            const int sw = (i == 7);
            /* prefetch targets of this iteration: block 2i+2 (X) and 2i+3 */
            aX = sw ? nAl : aX;
            bX = sw ? nBl : bX;
            bYo = sw ? nBl + K4_P : bYo;
            K4_ST(cur, X);
            K4_LD(X, nxt);
            K4_BLK(Y, aY, bY, aX, bX);
            K4_ST(cur + 256, Y);
            K4_LD(Y, nxt + 256);
            const int8_t *aY2 = aX;
            K4_BLK(X, aX, bX, aY2, bYo);
            /* rotate to blocks 2i+3, 2i+4 -- or, after i = 7, to blocks 1, 2 of the next chunk */
            int32_t *t_ = (i == 6) ? ae : (i == 7) ? ao : cur + 512;
            cur = nxt;
            nxt = t_;
            const int8_t *naX = aY + K4_P + ((unsigned)(i - 2) < 2u ? dA : 0);
            aX = sw ? nAl : naX;
            aY = aY2;
            const int8_t *tb = bY;
            bY = sw ? nBl + K4_P : bYo;
            bYo = sw ? nBh + K4_P : tb;
            tb = bX;
            bX = sw ? nBh : bXo;
            bXo = sw ? nBl : tb;
            dA = sw ? (int)(nAh - nAl) - 2 * K4_P : dA;
        }
    }
    SH_REL(g - 1);
}

/* int32 accumulators -> int8 output tile; iteration block bl holds logical block bl ^ swz (phase swap).
 * Own function: inlined into the caller it hit chess's "no mappings for bundle" (SRS + store + add). */
__attribute__((noinline)) static void sh_convert(int8_t *__restrict y, const int32_t *__restrict acc, int swz) {
    for (int bl = 0; bl < 16; bl++) {
        const int L = bl ^ swz;
        int8_t *tt = y + ((2 * (L >> 2)) * 8 + 2 * (L & 3)) * 64;
        const int32_t *ap = acc + ((((bl) >> 1) & 1) * 2048 + (((bl) >> 2) * 2 + ((bl) & 1)) * 256);
        KaMM4 Z0, Z1, Z2, Z3;
        K4_LD(Z, ap);
        chess_separator_scheduler();
        aie::store_v(tt, Z0.to_vector<int8_t>(0));
        aie::store_v(tt + 64, Z1.to_vector<int8_t>(0));
        aie::store_v(tt + 8 * 64, Z2.to_vector<int8_t>(0));
        aie::store_v(tt + 8 * 64 + 64, Z3.to_vector<int8_t>(0));
        chess_separator_scheduler();
    }
}
#endif
