/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
// K-accumulating int8 GEMM (step 1 of the MemTile design): every core keeps an int32 C tile
// (KA_TM x KA_TN) in core memory across all K chunks; A and B arrive in KA_KC-wide chunks.
#pragma aie_debug_level(AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN)
#pragma control_plan_op_control_packet
#pragma control_packet_mode(aot)
#pragma KERNELCONFIGOFFLOAD
#pragma output_tile_major
#include "simplegemm_peak.h"

#define KA_TM 64
#define KA_TN 64
#define KA_KC 128
#define KA_K 2560
#define KA_R 21
#define KA_NT 3
#define KA_M (4 * KA_TM * KA_R)
#define KA_N (4 * KA_TN * KA_NT)

__global__ void gemm_ka(aie::port<input_window_int8 *, aie::IFM, aie::shape<KA_M, KA_K>> a,
                        aie::port<input_window_int8 *, aie::WEIGHTS, aie::shape<KA_N, KA_K>> b,
                        aie::port<output_window_int8 *, aie::OFM, aie::shape<KA_M, KA_N>> c) {
    const int pm = aie::program_id(0), pn = aie::program_id(1);
    const int kb = KA_KC / 8, nk = KA_K / KA_KC, nti = KA_TN / 8;
    alignas(8192) static int32_t acc[KA_TM * KA_TN];
#if defined(__chess__)
    // Chunk kernel (64x64x128): 16 blocks of 2x2 accumulators; two register sets X / Y, so one set's
    // accumulator store + reload overlaps the other's MACs. Operands are loaded two k-steps ahead (the
    // last two steps of a block load the next block's first ones), and the accumulators of block b sit
    // in bank (b >> 1) & 1 of acc (8 KB-aligned, two 8 KB banks), so the store of block b and the reload
    // of block b + 2, issued together, never hit one bank. Addresses rotate; no div / mod in the loop.
    typedef aie::mmul<8, 8, 8, int8_t, int8_t> KaMM;
#define KA_H (KA_KC / 8 * 64)
#define KA_LD4(c, p)                                                                                                   \
    {                                                                                                                  \
        aie::accum<acc32, 64> q0_, q1_, q2_, q3_;                                                                      \
        q0_.from_vector(aie::load_v<64>(p));                                                                           \
        q1_.from_vector(aie::load_v<64>((p) + 64));                                                                    \
        q2_.from_vector(aie::load_v<64>((p) + 128));                                                                   \
        q3_.from_vector(aie::load_v<64>((p) + 192));                                                                   \
        c##0 = KaMM(q0_);                                                                                              \
        c##1 = KaMM(q1_);                                                                                              \
        c##2 = KaMM(q2_);                                                                                              \
        c##3 = KaMM(q3_);                                                                                              \
    }
#define KA_ST4(p, c)                                                                                                   \
    {                                                                                                                  \
        aie::store_v((p), (c##0).to_vector<int32_t>());                                                                \
        aie::store_v((p) + 64, (c##1).to_vector<int32_t>());                                                           \
        aie::store_v((p) + 128, (c##2).to_vector<int32_t>());                                                          \
        aie::store_v((p) + 192, (c##3).to_vector<int32_t>());                                                          \
    }
#define KA_ST8(t, c, nti)                                                                                              \
    {                                                                                                                  \
        aie::store_v((t), (c##0).to_vector<int8_t>(0));                                                                \
        aie::store_v((t) + 64, (c##1).to_vector<int8_t>(0));                                                           \
        aie::store_v((t) + (nti) * 64, (c##2).to_vector<int8_t>(0));                                                   \
        aie::store_v((t) + (nti) * 64 + 64, (c##3).to_vector<int8_t>(0));                                              \
    }
/* one k-step: MAC va/vb, rotate wa/wb (next step) in, load the step after that from l (A) / m (B) */
#define KA_STEP(c, l, m)                                                                                               \
    {                                                                                                                  \
        const aie::vector<int8_t, 64> n0 = aie::load_v<64>(l), n1 = aie::load_v<64>((l) + KA_H);                       \
        const aie::vector<int8_t, 64> m0 = aie::load_v<64>(m), m1 = aie::load_v<64>((m) + KA_H);                       \
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
/* a block's KA_KC / 8 k-steps; the last two load the next block's (npa, npb) steps 0 and 1 */
#define KA_BLK(c, pa0, pb0, npa, npb)                                                                                  \
    {                                                                                                                  \
        const int8_t *__restrict pa_ = (pa0);                                                                          \
        const int8_t *__restrict pb_ = (pb0);                                                                          \
        for (int ki = 2; ki < KA_KC / 8; ki++)                                                                         \
            chess_flatten_loop KA_STEP(c, pa_ + ki * 64, pb_ + ki * 64);                                               \
        KA_STEP(c, (npa), (npb));                                                                                      \
        KA_STEP(c, (npa) + 64, (npb) + 64);                                                                            \
    }
/* accumulator offset (int32) of block b: bank (b >> 1) & 1, slot (b >> 2) * 2 + (b & 1) */
#define KA_AO(b) ((((b) >> 1) & 1) * 2048 + (((b) >> 2) * 2 + ((b) & 1)) * 256)
#define KA_CHUNK(x_, w_)                                                                                               \
    {                                                                                                                  \
        const int8_t *__restrict xr_ = (x_);                                                                           \
        const int8_t *__restrict wr_ = (w_);                                                                           \
        KaMM X0, X1, X2, X3, Y0, Y1, Y2, Y3;                                                                           \
        aie::vector<int8_t, 64> va0 = aie::load_v<64>(xr_), va1 = aie::load_v<64>(xr_ + KA_H);                         \
        aie::vector<int8_t, 64> vb0 = aie::load_v<64>(wr_), vb1 = aie::load_v<64>(wr_ + KA_H);                         \
        aie::vector<int8_t, 64> wa0 = aie::load_v<64>(xr_ + 64), wa1 = aie::load_v<64>(xr_ + KA_H + 64);               \
        aie::vector<int8_t, 64> wb0 = aie::load_v<64>(wr_ + 64), wb1 = aie::load_v<64>(wr_ + KA_H + 64);               \
        int32_t *__restrict cur = acc, *__restrict nxt = acc + 2048;                                                   \
        const int8_t *aY = xr_, *aX = xr_;                                                                             \
        int oy = 2 * KA_H, ox = 4 * KA_H;                                                                              \
        KA_LD4(X, acc);                                                                                                \
        KA_LD4(Y, acc + 256);                                                                                          \
        KA_BLK(X, xr_, wr_, xr_, wr_ + 2 * KA_H);                                                                      \
        for (int i = 0; i < 7; i++) {                                                                                  \
            KA_ST4(cur, X);                                                                                            \
            KA_LD4(X, nxt);                                                                                            \
            KA_BLK(Y, aY, wr_ + oy, aX, wr_ + ox);                                                                     \
            KA_ST4(cur + 256, Y);                                                                                      \
            KA_LD4(Y, nxt + 256);                                                                                      \
            const int8_t *aY2 = aX;                                                                                    \
            const int oy2 = 8 * KA_H - oy;                                                                             \
            KA_BLK(X, aX, wr_ + ox, aY2, wr_ + oy2);                                                                   \
            int32_t *t_ = cur + 512;                                                                                   \
            cur = nxt;                                                                                                 \
            nxt = t_;                                                                                                  \
            aX = aY + 2 * KA_H;                                                                                        \
            aY = aY2;                                                                                                  \
            oy = oy2;                                                                                                  \
            ox = 4 * KA_H - ox;                                                                                        \
        }                                                                                                              \
        KA_ST4(cur, X);                                                                                                \
        KA_BLK(Y, aY, wr_ + oy, xr_, wr_);                                                                             \
        KA_ST4(cur + 256, Y);                                                                                          \
    }
#endif
#if defined(__chess__)
    // On the core: every (m tile, n tile) takes its full K -- A(m) NT times, B(n) R times.
    // The MemTiles replay them (hand experiment); the shim sends each block once.
    for (int s = 0; s < KA_R; s++)
        for (int nt = 0; nt < KA_NT; nt++) {
            int8_t *y = aie::store_buffer(c, {(pm * KA_R + s) * KA_TM, (pn * KA_NT + nt) * KA_TN}, {KA_TM, KA_TN});
            for (int i = 0; i < KA_TM * KA_TN; i += 64) /* K accumulation starts from zero */
                aie::store_v(acc + i, aie::zeros<int32_t, 64>());
            for (int j = 0; j < nk; j++) {
                const int8_t *x =
                    aie::load_buffer(a, {(pm * KA_R + s) * KA_TM, j * KA_KC}, {KA_TM, KA_KC}, {.depth = 2});
                const int8_t *w =
                    aie::load_buffer(b, {(pn * KA_NT + nt) * KA_TN, j * KA_KC}, {KA_TN, KA_KC}, {.depth = 2});
                KA_CHUNK(x, w)
                aie::release(a);
                aie::release(b);
            }
            for (int bl = 0; bl < (KA_TM / 16) * (KA_TN / 16); bl++) { /* int32 -> int8 (low byte), once per tile */
                int8_t *t = y + ((2 * (bl / (KA_TN / 16))) * nti + 2 * (bl % (KA_TN / 16))) * 64;
                const int32_t *ap = acc + KA_AO(bl);
                KaMM Z0, Z1, Z2, Z3;
                KA_LD4(Z, ap);
                chess_separator_scheduler();
                KA_ST8(t, Z, nti);
                chess_separator_scheduler();
            }
            aie::commit(c);
        }
#else
    // Traced (x86): what the shim sends -- A(m) once (m, k), B(n) once (n, k); C every tile.
    for (int s = 0; s < KA_R; s++)
        for (int nt = 0; nt < KA_NT; nt++) {
            int8_t *y = aie::store_buffer(c, {(pm * KA_R + s) * KA_TM, (pn * KA_NT + nt) * KA_TN}, {KA_TM, KA_TN});
            for (int j = 0; j < nk; j++) {
                if (nt == 0) {
                    const int8_t *x =
                        aie::load_buffer(a, {(pm * KA_R + s) * KA_TM, j * KA_KC}, {KA_TM, KA_KC}, {.depth = 2});
                    (void)x;
                    aie::release(a);
                }
                if (s == 0) {
                    const int8_t *w =
                        aie::load_buffer(b, {(pn * KA_NT + nt) * KA_TN, j * KA_KC}, {KA_TN, KA_KC}, {.depth = 2});
                    (void)w;
                    aie::release(b);
                }
            }
            for (int i = 0; i < KA_TM * KA_TN; i++)
                y[i] = 0;
            aie::commit(c);
        }
#endif
}

void __Runtime_ctrl_high_throughput_enable(int on);
void __Runtime_ctrl_pmap_enable(int on);
void __Runtime_buffer_device_written(void *ptr, size_t size);
void *__Runtime_alloc_uncached(size_t bytes);

static void gemm_ka_run(int8_t *A, int8_t *B, int8_t *C) {
    __Runtime_ctrl_high_throughput_enable(1);
    __Runtime_ctrl_pmap_enable(0);
    aieSetDevice(0);
    aieArray device;
    aieMesh mesh = device.partition({2, 6, 0, 6}, GP_HW_ROWS, GP_HW_COLS);
    gemm_ka<<<mesh>>>(A, B, C);
}

void __Runtime_phase_cycles(unsigned long long *cyc, unsigned int *calls);
void __Runtime_wait_io_cycles(unsigned long long *cycles, unsigned int *calls);
static inline unsigned long long pmu(void) {
    unsigned long long v;
    __asm__ volatile("mrs %0, pmccntr_el0" : "=r"(v));
    return v;
}

// [rows][K] row-major -> every (br x KA_KC) chunk's bytes in mmul operand order, placed where the
// chunk's DMA reads them (row r0 + p / KA_KC, column k0 + p % KA_KC for chunk byte p).
// kn = 0: [mi][kb][8 row][8 k] (A); kn = 1: [ni][kb][8 k][8 row] (B).
static void ka_pack(const int8_t *src, int8_t *dst, long rows, long K, int br, int kn) {
    const int kb = KA_KC / 8;
    for (long r0 = 0; r0 < rows; r0 += br)
        for (long k0 = 0; k0 < K; k0 += KA_KC)
            for (int ti = 0; ti < br / 8; ti++)
                for (int ki = 0; ki < kb; ki++)
                    for (int u = 0; u < 8; u++)
                        for (int v = 0; v < 8; v++) {
                            const long r = r0 + ti * 8 + (kn ? v : u), k = k0 + ki * 8 + (kn ? u : v);
                            const long p = (long)(ti * kb + ki) * 64 + u * 8 + v;
                            dst[(r0 + p / KA_KC) * K + k0 + p % KA_KC] = src[r * K + k];
                        }
}

int main() {
    const long M = KA_M, N = KA_N, K = KA_K, R = KA_R * KA_NT, blk = KA_TM * KA_TN, nti = KA_TN / 8;
    printf("=== gemm_ka: C[%ld x %ld] = A[%ld x %ld] . B^T, int8, K accumulated on core, %.3f GMAC ===\n", M, N, M, K,
           (double)M * N * K / 1e9);
    int8_t *A = (int8_t *)malloc(M * K), *B = (int8_t *)malloc(N * K);
    int8_t *Ap = (int8_t *)__Runtime_alloc_uncached(M * K), *Bp = (int8_t *)__Runtime_alloc_uncached(N * K);
    int8_t *Ct = (int8_t *)__Runtime_Alloc(M * N);
    if (!Ap || !Bp) {
        printf("[gemm_ka] uncached alloc failed, falling back to cached\n");
        Ap = Ap ? Ap : (int8_t *)__Runtime_Alloc(M * K);
        Bp = Bp ? Bp : (int8_t *)__Runtime_Alloc(N * K);
    }
    gp_init(A, B, M, N, K);
    ka_pack(A, Ap, M, K, KA_TM, 0);
    ka_pack(B, Bp, N, K, KA_TN, 1);
    memset(Ct, 0, M * N);
    __Runtime_buffer_device_written(Ct, M * N);
    double pmu_ghz = 0;
    {
        XTime a0, a1;
        XTime_GetTime(&a0);
        const unsigned long long p0 = pmu();
        do
            XTime_GetTime(&a1);
        while (gp_ms(a0, a1) < 20.0);
        pmu_ghz = (double)(pmu() - p0) / (gp_ms(a0, a1) * 1e6);
    }
    const double peak_ms = (double)M * N * K / (16.0 * 512.0 * 0.998e9) * 1e3;
    printf("[gemm_ka] PMU clock %.3f GHz; ideal (16 x 512 MAC/cycle @ 998 MHz) %.4f ms\n", pmu_ghz, peak_ms);
    for (int it = 0; it < 5; it++) {
        unsigned long long ph0[4] = {0, 0, 0, 0}, ph1[4] = {0, 0, 0, 0}, w0 = 0, w1 = 0;
        unsigned int n[4], nw;
        __Runtime_phase_cycles(ph0, n);
        __Runtime_wait_io_cycles(&w0, &nw);
        XTime t0, t1;
        XTime_GetTime(&t0);
        gemm_ka_run(Ap, Bp, Ct);
        XTime_GetTime(&t1);
        __Runtime_phase_cycles(ph1, n);
        __Runtime_wait_io_cycles(&w1, &nw);
        const double ms = gp_ms(t0, t1), f = pmu_ghz * 1e6;
        printf("[gemm_ka] call %d: end to end %.3f ms -> %.2f %% of peak | kload %.3f bdcfg %.3f coreen %.3f "
               "startio %.3f wait_io %.3f ms\n",
               it, ms, 100.0 * peak_ms / ms, (ph1[0] - ph0[0]) / f, (ph1[1] - ph0[1]) / f, (ph1[2] - ph0[2]) / f,
               (ph1[3] - ph0[3]) / f, (w1 - w0) / f);
    }
    Xil_DCacheInvalidateRange((UINTPTR)Ct, M * N);
    long bad = 0, checked = 0;
    for (long i = 0; i < M; i += 7) {
        const long pm = i / (M / 4), s = (i % (M / 4)) / KA_TM, rr = i % KA_TM;
        for (long jj = 0; jj < N; jj += 3) {
            const long pn = jj / (KA_TN * KA_NT), nt = (jj % (KA_TN * KA_NT)) / KA_TN, cj = jj % KA_TN;
            const long q = ((rr / 8) * nti + cj / 8) * 64 + (rr % 8) * 8 + cj % 8;
            const int8_t got = Ct[((pm * 4 + pn) * R + s * KA_NT + nt) * blk + q];
            int acc = 0;
            for (long k = 0; k < K; k++)
                acc += A[i * K + k] * B[jj * K + k];
            if (got != (int8_t)acc && ++bad <= 8)
                printf("MISMATCH C[%ld][%ld] core (%ld,%ld) round %ld: got %d want %d\n", i, jj, pm, pn, s, got,
                       (int8_t)acc);
            checked++;
        }
    }
    printf("%s: %ld / %ld checked outputs match\n", bad ? "GOLDEN FAIL" : "GOLDEN PASS", checked - bad, checked);
    return bad != 0;
}
