#if defined(__chess__)
/* SHARE2X8 chunk kernel (64 x 64 x 128): A pairs {0,1} at a_lo, {2,3} at a_hi; B pairs likewise. */
typedef aie::mmul<8, 8, 8, int8_t, int8_t> KaMM4;
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
        for (int ki = 2; ki < KA_KC / 8; ki++)                                                                         \
            chess_flatten_loop K4_STEP(c, pa_ + ki * 64, pb_ + ki * 64);                                               \
        K4_STEP(c, (npa), (npb));                                                                                      \
        K4_STEP(c, (npa) + 64, (npb) + 64);                                                                            \
    }
/* One 64x64x128 chunk, iteration blocks b = 0..15 (2x2 accumulators): A pair b >> 2, B pair b & 3.
   A pairs {0,1} live at a_lo (+0 / +2048), {2,3} at a_hi; B pairs likewise at b_lo / b_hi, so a shared
   buffer can be split over two banks and two readers can walk it in opposite phase (by swapping the
   halves they pass). Accumulators of block b in bank (b >> 1) & 1 (ae / ao). */
__attribute__((noinline)) static void ka_chunk(const int8_t *__restrict a_lo, const int8_t *__restrict a_hi,
                                               const int8_t *__restrict b_lo, const int8_t *__restrict b_hi,
                                               int32_t *__restrict ae, int32_t *__restrict ao) {
    KaMM4 X0, X1, X2, X3, Y0, Y1, Y2, Y3;
    const int8_t *xr_ = a_lo, *wr_ = b_lo;
    aie::vector<int8_t, 64> va0 = aie::load_v<64>(xr_), va1 = aie::load_v<64>(xr_ + K4_H);
    aie::vector<int8_t, 64> vb0 = aie::load_v<64>(wr_), vb1 = aie::load_v<64>(wr_ + K4_H);
    aie::vector<int8_t, 64> wa0 = aie::load_v<64>(xr_ + 64), wa1 = aie::load_v<64>(xr_ + K4_H + 64);
    aie::vector<int8_t, 64> wb0 = aie::load_v<64>(wr_ + 64), wb1 = aie::load_v<64>(wr_ + K4_H + 64);
    const int dA = (int)(a_hi - a_lo) - 4096;      /* extra step from A pair 1 to pair 2 */
    int32_t *cur = ae, *nxt = ao;
    const int8_t *aY = a_lo, *aX = a_lo;             /* A of block b+1 / b+2 */
    const int8_t *bY = b_lo + 2048, *bYo = b_hi + 2048; /* B of block b+1 (q 1/3), the other odd pair */
    const int8_t *bX = b_hi, *bXo = b_lo;             /* B of block b+2 (q 2/0), the other even pair */
    K4_LD(X, ae);
    K4_LD(Y, ae + 256);
    K4_BLK(X, a_lo, b_lo, a_lo, bY);
    for (int i = 0; i < 7; i++) {
        K4_ST(cur, X);
        K4_LD(X, nxt);
        K4_BLK(Y, aY, bY, aX, bX);
        K4_ST(cur + 256, Y);
        K4_LD(Y, nxt + 256);
        const int8_t *aY2 = aX;
        K4_BLK(X, aX, bX, aY2, bYo);
        int32_t *t = cur + 512;
        cur = nxt;
        nxt = t;
        aX = aY + 2048 + ((unsigned)(i - 2) < 2u ? dA : 0);
        aY = aY2;
        const int8_t *tb = bY; bY = bYo; bYo = tb;
        tb = bX; bX = bXo; bXo = tb;
    }
    K4_ST(cur, X);
    K4_BLK(Y, aY, bY, a_lo, b_lo);
    K4_ST(cur + 256, Y);
}
#endif
