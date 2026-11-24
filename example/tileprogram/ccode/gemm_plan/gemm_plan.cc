// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// int8 GEMM on the 4 x 4 mesh in the 2 x 8 SHARED-OPERAND layout -- 85.5 % of the VEK385 peak from
// this source alone (README.md; doc/design/dmaphop_dataflow_plan.md). The data movement is stated
// where the kernel loads its blocks, and the compiler derives the rest:
//
//   #pragma persistent_kernel                  load the kernel once; later launches release a go lock
//   aie::load_buffer(a, ..., {.share = aie::share::neighbor, .stage = aie::stage::memtile_ring,
//                             .ring = 10})     A: hosted in one neighbour core's memory, staged through
//                                              a MemTile FIFO ring of 10 buffers
//   aie::load_buffer(b, ..., {.share = aie::share::neighbor, .stage = aie::stage::memtile,
//                             .keep = true})   B: hosted likewise, held in a MemTile across launches
//
// Those options become `dataflow` attributes on the routing IR's tensors; the dataflow-plan synthesis
// turns them into dmaphop.plan* ops (host-tile matching, views, locks, MemTile / core / shim BDs,
// routes), and the compiler emits routing.cc / host.cc / kernel.cc and aiehlc_plan.h -- the
// constants the chess kernel below reads. The same build also works one level lower: edit the
// routing IR (AIEHLC_ROUTING_IR_IN) or write the dmaphop plan yourself (gen_plan.py,
// AIEHLC_DMAPHOP_IR_IN); an explicit plan wins over the options.
//
// C[7680 x 512] = A[7680 x 2560] . B[512 x 2560]^T per launch (10.07 G MAC). Logical grid: A in 2
// strips, B in 8 strips; core (pm, pn) computes A strip pm >> 1 x B strip pn + 4 (pm & 1), 60 tiles
// of 64 x 64 x 2560. Each core tile hosts one operand stream that two neighbours read.
#pragma aie_debug_level(AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN)
#pragma control_plan_op_control_packet
#pragma control_packet_mode(aot)
#pragma KERNELCONFIGOFFLOAD
#pragma output_tile_major
#pragma persistent_kernel
#include "simplegemm_peak.h"

#define KA_TM 64
#define KA_TN 64
#define KA_KC 128
#define K4_KC 128
#define KA_K 2560
#define KA_R 30
#define KA_NT 2
#define KA_M (4 * KA_TM * KA_R)
#define KA_N (4 * KA_TN * KA_NT)
#define SH_R2 60
#define SH_NT2 1
#define SH_NK 20
#define SH_TILES 60

// AIEHLC_KERNEL_PROLOGUE_BEGIN
#include "gemm_plan_tile.h"
// AIEHLC_KERNEL_PROLOGUE_END

// One body for the core and for the compiler's x86 trace: every operand block comes from
// aie::load_buffer, every output tile goes out through aie::store_buffer -- the compiler serves the
// shared ports from the dataflow plan's hosted slots (locks, slot rotation, bank-split parts).
__global__ void gemm_ka(aie::port<input_window_int8 *, aie::IFM, aie::shape<KA_M, KA_K>> a,
                        aie::port<input_window_int8 *, aie::WEIGHTS, aie::shape<KA_N, KA_K>> b,
                        aie::port<output_window_int8 *, aie::OFM, aie::shape<KA_M, KA_N>> c) {
    typedef aie::mmul<8, 8, 8, int8_t, int8_t> KaMM4; // one mac_8x8_8x8: 512 int8 MAC / cycle
    // 2 x 8 logical grid on the 4 x 4 mesh: core (pm, pn) computes A strip sa x B strip sb.
    const int pm = aie::program_id(0), pn = aie::program_id(1);
    const int sa = pm >> 1, sb = pn + 4 * (pm & 1), brow = sb * KA_TN;
    // The two cores reading one block walk its two parts in opposite order (different memory banks).
    const int pa = pm & 1, pb = pm >> 1, swz = (pa << 3) ^ (pb << 1);
    alignas(8192) static int32_t acc[KA_TM * KA_TN];
    int32_t *__restrict ae = acc, *__restrict ao = acc + 2048;
    int arow = 0;
    // A: shared with the neighbour core, staged through a MemTile FIFO ring of 10 buffers.
    // B: shared likewise, kept in a MemTile across launches (weight-resident).
// How A and B travel (the dataflow the compiler builds; see the file header).
#define OPTS_A                                                                                                         \
    {                                                                                                                  \
        .depth = 2, .share = aie::share::neighbor, .stage = aie::stage::memtile_ring, .ring = 10, .parts = 2,          \
        .align = 64                                                                                                    \
    }
#define OPTS_B                                                                                                         \
    {.depth = 2, .share = aie::share::neighbor, .stage = aie::stage::memtile, .keep = true, .parts = 2, .align = 64}
    KaMM4 X0, X1, X2, X3, Y0, Y1, Y2, Y3;
    int32_t *cur, *nxt;
    const int8_t *aY, *aX, *bY, *bYo, *bX, *bXo;
    int dA;
    for (int t = 0; t < SH_TILES; t++) {
        arow = sa * (KA_M / 2) + t * KA_TM;
        int8_t *__restrict y = aie::store_buffer(c, {arow, brow}, {KA_TM, KA_TN}, {.align = 64});
        const int8_t *Al, *Ah, *Bl, *Bh;
        {
            auto xa = aie::load_buffer(a, {arow, 0}, {KA_TM, KA_KC}, OPTS_A);
            auto xb = aie::load_buffer(b, {brow, 0}, {KA_TN, KA_KC}, OPTS_B);
            SH_PARTS(xa, xb, Al, Ah, Bl, Bh);
        }
        aie::vector<int8_t, 64> va0 = aie::load_v<64>(Al), va1 = aie::load_v<64>(Al + K4_H);
        aie::vector<int8_t, 64> vb0 = aie::load_v<64>(Bl), vb1 = aie::load_v<64>(Bl + K4_H);
        aie::vector<int8_t, 64> wa0 = aie::load_v<64>(Al + 64), wa1 = aie::load_v<64>(Al + K4_H + 64);
        aie::vector<int8_t, 64> wb0 = aie::load_v<64>(Bl + 64), wb1 = aie::load_v<64>(Bl + K4_H + 64);
        SH_RESET(Al, Ah, Bl, Bh);
        K4_LDZ(X, ae);
        K4_LDZ(Y, ae + 256);
        K4_BLK(X, Al, Bl, Al, Bl + 2048);
// boundary into chunk k: chunk k is taken before chunk k - 1 is given back (blocks 14 / 15 of chunk
// k - 1 run with chunk k's first operands prefetched)
#define GEMM_NEXT_CHUNK(k)                                                                                             \
    {                                                                                                                  \
        const int8_t *nAl, *nAh, *nBl, *nBh;                                                                           \
        auto xa = aie::load_buffer(a, {arow, (k) * KA_KC}, {KA_TM, KA_KC}, OPTS_A);                                    \
        auto xb = aie::load_buffer(b, {brow, (k) * KA_KC}, {KA_TN, KA_KC}, OPTS_B);                                    \
        SH_PARTS(xa, xb, nAl, nAh, nBl, nBh);                                                                          \
        SH_BOUND1(nAl, nBl);                                                                                           \
        aie::release(a);                                                                                               \
        aie::release(b);                                                                                               \
        SH_BOUND2(nAl, nAh, nBl, nBh);                                                                                 \
    }
        SH_INNER_W(K4_STI, K4_LDZ); // chunk 0: accumulators start from zero
        GEMM_NEXT_CHUNK(1);
        for (int j = 1; j < SH_NK - 1; j++) {
            SH_INNER_W(K4_STI, K4_LD);
            GEMM_NEXT_CHUNK(j + 1);
        }
        SH_INNER_W(K4_OUT, K4_LD); // last chunk: blocks go straight to the int8 output tile
        K4_OUT(cur, X, 14);
        K4_BLK(Y, aY, bY, aY, bY);
        aie::release(a);
        aie::release(b);
        K4_OUT(cur + 256, Y, 15);
        aie::commit(c);
    }
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

// A / B laid out in DDR in the order the plan's shim BDs stream them, contiguously:
// A column c: m-tiles s = 0..R2-1 x chunks jj = 0..NK/2-1 of strip c >> 1, k-chunk 2 jj + (c & 1);
// B column c: strip c then strip c+4, each NT2 n-tiles x NK chunks. Chunk = 64 rows x 128 B of the
// packed operand (already in mmul order).
static void sh_arrange(const int8_t *Ap, const int8_t *Bp, int8_t *A2, int8_t *B2, long M, long K) {
    const long nk = K / 128, hk = nk / 2;
    int8_t *a = A2;
    for (int c = 0; c < 4; c++)
        for (long s = 0; s < SH_R2; s++)
            for (long jj = 0; jj < hk; jj++)
                for (int r = 0; r < 64; r++, a += 128)
                    memcpy(a, Ap + ((c >> 1) * (M / 2) + s * 64 + r) * K + (2 * jj + (c & 1)) * 128, 128);
    int8_t *b = B2;
    for (int c = 0; c < 4; c++)
        for (int half = 0; half < 2; half++)
            for (long nt = 0; nt < SH_NT2; nt++)
                for (long kc = 0; kc < nk; kc++)
                    for (int r = 0; r < 64; r++, b += 128)
                        memcpy(b, Bp + (((c + 4 * half) * SH_NT2 + nt) * 64 + r) * K + kc * 128, 128);
}

int main() {
    const long M = 2L * 64 * SH_R2, N = 8L * 64 * SH_NT2, K = 128L * SH_NK, R = SH_R2 * SH_NT2, blk = KA_TM * KA_TN,
               nti = KA_TN / 8;
    printf("=== gemm_plan: C[%ld x %ld] = A[%ld x %ld] . B^T, int8, 2 x 8 shared operands from the dmaphop "
           "dataflow plan, %.3f GMAC ===\n",
           M, N, M, K, (double)M * N * K / 1e9);
    int8_t *A = (int8_t *)malloc(M * K), *B = (int8_t *)malloc(N * K);
    int8_t *Ap = (int8_t *)malloc(M * K), *Bp = (int8_t *)malloc(N * K);
    int8_t *A2 = (int8_t *)__Runtime_alloc_uncached(M * K), *B2 = (int8_t *)__Runtime_alloc_uncached(N * K);
    int8_t *Ct = (int8_t *)__Runtime_Alloc(M * N);
    gp_init(A, B, M, N, K);
    ka_pack(A, Ap, M, K, KA_TM, 0);
    ka_pack(B, Bp, N, K, KA_TN, 1);
    sh_arrange(Ap, Bp, A2, B2, M, K);
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
    /* peak = 16 cores x 512 MAC/cycle; the array clock is GEMM_AIE_MHZ (VEK385: 1250, palmyra: 998) */
#ifndef GEMM_AIE_MHZ
#define GEMM_AIE_MHZ 1250.0
#endif
    const double peak_ms = (double)M * N * K / (16.0 * 512.0 * GEMM_AIE_MHZ * 1e6) * 1e3;
    printf("[gemm_plan] PMU clock %.3f GHz; ideal (16 x 512 MAC/cycle @ %.0f MHz) %.4f ms\n", pmu_ghz, GEMM_AIE_MHZ,
           peak_ms);
    double sum = 0, best = 1e9;
    const int iters = 8;
    for (int it = 0; it < iters; it++) {
        XTime t0, t1;
        XTime_GetTime(&t0);
        gemm_ka_run(A2, B2, Ct);
        XTime_GetTime(&t1);
        const double ms = gp_ms(t0, t1);
        printf("[gemm_plan] call %d: end to end %.3f ms -> %.2f %% of peak\n", it, ms, 100.0 * peak_ms / ms);
        if (it > 0) {
            sum += ms;
            best = ms < best ? ms : best;
        }
    }
    printf("PERF SUMMARY gemm_plan steady %.3f ms mean (%.2f %% of peak), best %.3f ms (%.2f %%)\n", sum / (iters - 1),
           100.0 * peak_ms * (iters - 1) / sum, best, 100.0 * peak_ms / best);
    Xil_DCacheInvalidateRange((UINTPTR)Ct, M * N);
    long bad = 0, checked = 0;
    for (long i = 0; i < M; i += 7) {
        const long h = i / (M / 2), s = (i % (M / 2)) / KA_TM, rr = i % KA_TM;
        for (long jj = 0; jj < N; jj += 3) {
            const long nt2 = SH_NT2, sj = jj / (KA_TN * nt2), nt = (jj % (KA_TN * nt2)) / KA_TN, cj = jj % KA_TN;
            const long pn = sj & 3, pm = 2 * h + (sj >> 2);
            const long q = ((rr / 8) * nti + cj / 8) * 64 + (rr % 8) * 8 + cj % 8;
            const int8_t got = Ct[((pm * 4 + pn) * R + s * nt2 + nt) * blk + q];
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
