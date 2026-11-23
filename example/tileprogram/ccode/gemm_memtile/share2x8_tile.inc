#if defined(__chess__)
/* SHARE2X8 tile kernel (64 x 64 x NKC*128): one software pipeline across all chunks of a tile.
 * Blocks b = 0..15 per chunk (2x2 accumulators): A pair b >> 2, B pair b & 3; accumulators of block b
 * in bank (b >> 1) & 1 (ae / ao). A chunk's A pairs {0,1} sit at a_lo (+0 / +2048), {2,3} at a_hi; B
 * likewise. At a chunk boundary the last block of chunk j overlaps the first of chunk j+1: chunk j+1 is
 * acquired first, its first operands are prefetched during block 15, chunk j is released right after
 * its last reads -- no per-chunk prologue / epilogue / call. */
typedef aie::mmul<8, 8, 8, int8_t, int8_t> KaMM4;
#ifdef SH_AALT
#define SH_AALT_ON 1
#else
#define SH_AALT_ON 0
#endif
#ifdef SH_QSLOT
#define SH_QSLOT_ON 1
#else
#define SH_QSLOT_ON 0
#endif
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
#define K4_STEPX(c, l, m, A0, A1, B0, B1)                                                                               \
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
#if defined(SH_DMAONLY) /* share2x8.py --dmaonly: no MACs / accumulator traffic; locks and DMA unchanged */
#undef K4_LD
#undef K4_ST
#undef K4_OUT
#define K4_OUT(p, c, bl) {}
#undef K4_LDZ
#define K4_LDZ(c, p) {}
#undef K4_STEPX
#define K4_LD(c, p) {}
#define K4_ST(p, c) {}
#define K4_STEPX(c, l, m, A0, A1, B0, B1) { chess_memory_fence(); }
#endif
/* acquire the chunk with running index g (channel g & 1): first reader takes F and hands G on.
 * lv = 1 normally; 0 for the no-wait bench (acquire >= 0 and release 0 are no-ops). */
#define SH_ACQ(g)                                                                                                      \
    {                                                                                                                  \
        /* branch-free (each role branch cost ~5 delay-slot bundles per chunk): the first reader takes F and \
         * hands G on; the second takes G and "releases" own lock 15 (id 63) by 0 -- a no-op */                     \
        const int ch4_ = 4 * ((g) & 1);                                                                                \
        acquire_greater_equal(lA + (fa_ ? 6 : 7) + ch4_, lv);                                                         \
        release(fa_ ? lA + 7 + ch4_ : 63, fa_ ? lv : 0);                                                               \
        acquire_greater_equal(lB + (fb_ ? 6 : 7) + ch4_, lv);                                                         \
        release(fb_ ? lB + 7 + ch4_ : 63, fb_ ? lv : 0);                                                               \
        chess_memory_fence();                                                                                          \
    }
#define SH_REL(g)                                                                                                      \
    {                                                                                                                  \
        chess_memory_fence();                                                                                          \
        release(lA + 8 + 4 * ((g) & 1) + (((g) >> 1) & 1), lv);                                                         \
        release(lB + 8 + 4 * ((g) & 1) + (((g) >> 1) & 1), lv);                                                         \
    }
/* the four half pointers of chunk g, in this core's phase */
#define SH_HALVES(g, Alo, Ahi, Blo, Bhi)                                                                               \
    {                                                                                                                  \
        /* buffer index: 2 ch + slot, or with SH_QSLOT 2 slot + ch (a channel's slots in different banks) */         \
        const unsigned q_ = SH_QSLOT_ON ? 2 * (((g) >> 1) & 1) + ((g) & 1) : 2 * ((g) & 1) + (((g) >> 1) & 1);        \
        const int8_t *x0_ = (const int8_t *)(vA + 0x8000 + q_ * 4096), *x1_ = (const int8_t *)(vA + 0xc000 + q_ * 4096); \
        const int8_t *y0_ = (const int8_t *)(vB + 0x8000 + q_ * 4096), *y1_ = (const int8_t *)(vB + 0xc000 + q_ * 4096); \
        /* SH_AALT: the A half order flips every chunk, so a reader stays in one A half for 16 blocks   \
         * across the chunk boundary instead of 8 (fewer bank conflicts with the other reader's lag) */  \
        const int af_ = (fl & 4) ^ (SH_AALT_ON ? (((g) & 1) << 2) : 0);                                                \
        Alo = af_ ? x1_ : x0_;                                                                                         \
        Ahi = af_ ? x0_ : x1_;                                                                                         \
        Blo = (fl & 8) ? y1_ : y0_;                                                                                    \
        Bhi = (fl & 8) ? y0_ : y1_;                                                                                    \
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
        int32_t *t_ = cur + 512 + ((unsigned)(i - 2) < 2u ? dW : 0); /* SH_AALT odd chunk: offsets wrap */            \
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
/* boundary: blocks 14, 15 of chunk g, blocks 0, 1 of chunk g+1; then g = g + 1 */
#define SH_BOUND()                                                                                                     \
    {                                                                                                                  \
        const int8_t *nAl, *nAh, *nBl, *nBh;                                                                           \
        SH_ACQ(g + 1);                                                                                                 \
        SH_HALVES(g + 1, nAl, nAh, nBl, nBh);                                                                          \
        K4_ST(cur, X);                                                                                                 \
        K4_LD(X, ae + SH_WO(g + 1));                                                                                   \
        K4_BLK(Y, aY, bY, nAl, nBl);                                                                                   \
        SH_REL(g);                                                                                                     \
        K4_ST(cur + 256, Y);                                                                                           \
        K4_LD(Y, ae + 256 + SH_WO(g + 1));                                                                             \
        K4_BLK(X, nAl, nBl, nAl, nBl + 2048);                                                                          \
        SH_RESET(nAl, nAh, nBl, nBh, g + 1);                                                                           \
        g++;                                                                                                           \
    }
/* SH_AALT: an odd chunk's blocks are the even chunk's with A halves swapped (logical block bl ^ 8), so their
 * accumulators sit 1024 ints further in each 8 KB region (mod 2048) */
#define SH_WO(g) (SH_AALT_ON && ((g) & 1) ? 1024 : 0)
/* pointer state for chunk g whose halves are (al_, ah_, bl_, bh_) */
#define SH_RESET(al_, ah_, bl_, bh_, g)                                                                                \
    {                                                                                                                  \
        dA = (int)((ah_) - (al_)) - 4096;                                                                              \
        dW = SH_WO(g) ? -2048 : 0;                                                                                     \
        cur = ae + SH_WO(g);                                                                                           \
        nxt = ao + SH_WO(g);                                                                                           \
        aY = (al_);                                                                                                    \
        aX = (al_);                                                                                                    \
        bY = (bl_) + 2048;                                                                                             \
        bYo = (bh_) + 2048;                                                                                            \
        bX = (bh_);                                                                                                    \
        bXo = (bl_);                                                                                                   \
    }
/* One 64 x 64 tile over nkc chunks starting at running chunk index g0; accumulators start at ZERO
 * (acc is scratch: chunk 0 starts from zero registers, the last chunk writes the int8 tile to y). fl: 1 A first reader, 2 B first reader, 4 A halves swapped,
 * 8 B halves swapped. */
__attribute__((noinline)) static void ka_tile(uintptr_t vA, uintptr_t vB, int lA, int lB, int fl, unsigned g0, int nkc, int lv,
                                              int32_t *__restrict ae, int32_t *__restrict ao, int8_t *__restrict y, int swz) {
    KaMM4 X0, X1, X2, X3, Y0, Y1, Y2, Y3;
    const int8_t *Al, *Ah, *Bl, *Bh;
    int32_t *cur, *nxt;
    const int8_t *aY, *aX, *bY, *bYo, *bX, *bXo;
    int dA, dW;
    if (SH_AALT_ON) /* the output follows the last chunk's A phase */
        swz ^= ((g0 + nkc - 1) & 1) << 3;
    unsigned g = g0;
    const int fa_ = fl & 1, fb_ = fl & 2;
    SH_ACQ(g);
    SH_HALVES(g, Al, Ah, Bl, Bh);
    aie::vector<int8_t, 64> va0 = aie::load_v<64>(Al), va1 = aie::load_v<64>(Al + K4_H);
    aie::vector<int8_t, 64> vb0 = aie::load_v<64>(Bl), vb1 = aie::load_v<64>(Bl + K4_H);
    aie::vector<int8_t, 64> wa0 = aie::load_v<64>(Al + 64), wa1 = aie::load_v<64>(Al + K4_H + 64);
    aie::vector<int8_t, 64> wb0 = aie::load_v<64>(Bl + 64), wb1 = aie::load_v<64>(Bl + K4_H + 64);
    SH_RESET(Al, Ah, Bl, Bh, g);
    K4_LDZ(X, ae);
    K4_LDZ(Y, ae + 256);
    K4_BLK(X, Al, Bl, Al, Bl + 2048);
    /* chunk 0 (accumulators from zero), chunks 1 .. nkc-2, then the last chunk (output); nkc >= 2 */
    SH_INNER_W(K4_STI, K4_LDZ);
    SH_BOUND();
    for (int j = 1; j < nkc - 1; j++) {
        SH_INNER_W(K4_STI, K4_LD);
        SH_BOUND();
    }
    SH_INNER_W(K4_OUT, K4_LD); /* last chunk: blocks go straight to the output tile */
    K4_OUT(cur, X, 14);
    K4_BLK(Y, aY, bY, Al, Bl);
    SH_REL(g);
    K4_OUT(cur + 256, Y, 15);
}
/* int32 accumulators -> int8 output tile; iteration block bl holds logical block bl ^ swz (phase swap).
 * Own function: inlined into the caller it hit chess's "no mappings for bundle" (SRS + store + add). */
__attribute__((noinline)) static void sh_convert(int8_t *__restrict y, int32_t *__restrict acc, int swz) {
    for (int bl = 0; bl < 16; bl++) {
        const int L = bl ^ swz;
        int8_t *tt = y + ((2 * (L >> 2)) * 8 + 2 * (L & 3)) * 64;
        int32_t *ap = acc + ((((bl) >> 1) & 1) * 2048 + (((bl) >> 2) * 2 + ((bl) & 1)) * 256);
        KaMM4 Z0, Z1, Z2, Z3;
        K4_LD(Z, ap);
        /* leave the accumulators zeroed for the next tile (saves a separate 16 KB zeroing pass) */
        aie::store_v((int32_t *)ap, aie::zeros<int32_t, 64>());
        aie::store_v((int32_t *)ap + 64, aie::zeros<int32_t, 64>());
        aie::store_v((int32_t *)ap + 128, aie::zeros<int32_t, 64>());
        aie::store_v((int32_t *)ap + 192, aie::zeros<int32_t, 64>());
        chess_separator_scheduler();
        aie::store_v(tt, Z0.to_vector<int8_t>(0));
        aie::store_v(tt + 64, Z1.to_vector<int8_t>(0));
        aie::store_v(tt + 8 * 64, Z2.to_vector<int8_t>(0));
        aie::store_v(tt + 8 * 64 + 64, Z3.to_vector<int8_t>(0));
        chess_separator_scheduler();
    }
}
#endif
