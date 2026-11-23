// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// int8 GEMM on the 4 x 4 mesh in the 2 x 8 SHARED-OPERAND layout, with the data movement taken from
// an explicit dataflow plan in the dmaphop IR instead of hand edits of the generated host.cc /
// kernel.cc / routing.cc (README.md; doc/design/dmaphop_dataflow_plan.md):
//
//   1. aiehlc builds this file as usual (its kernel-only ports describe the C output the compiler
//      generates; A and B are re-routed by the plan);
//   2. gen_plan.py appends the dmaphop.plan* ops to the dumped dmaphop IR;
//   3. AIEHLC_DMAPHOP_IR_IN=<plan .mlir> aiehlc ... rebuilds with the plan: the compiler routes the
//      plan's streams, programs the MemTiles / shim (host.cc), the cores' hosted-stream DMA
//      (kernel.cc), and writes aiehlc_plan.h, whose constants the kernel below reads.
//
// C[7680 x 512] = A[7680 x 2560] . B[512 x 2560]^T per launch (10.07 G MAC). Logical grid: A in 2
// strips, B in 8 strips; core (pm, pn) computes A strip pm >> 1 x B strip pn + 4 (pm & 1), 60 tiles
// of 64 x 64 x 2560. Each core tile hosts one operand stream that two neighbours read.
#pragma aie_debug_level(AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN)
#pragma control_plan_op_control_packet
#pragma control_packet_mode(aot)
#pragma KERNELCONFIGOFFLOAD
#pragma output_tile_major
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
#if defined(__chess__)
#include "aiehlc_plan.h"
#include "gemm_plan_tile.h"
#endif
// AIEHLC_KERNEL_PROLOGUE_END

__global__ void gemm_ka(aie::port<input_window_int8 *, aie::IFM, aie::shape<KA_M, KA_K>> a,
                        aie::port<input_window_int8 *, aie::WEIGHTS, aie::shape<KA_N, KA_K>> b,
                        aie::port<output_window_int8 *, aie::OFM, aie::shape<KA_M, KA_N>> c) {
    const int pm = aie::program_id(0), pn = aie::program_id(1);
    const int nk = KA_K / KA_KC;
    alignas(8192) static int32_t acc[KA_TM * KA_TN];
#if defined(__chess__)
    // Operands come from the tiles that host them (the plan's A_VIEW / B_VIEW: own / north / south
    // memory view), synchronised on the host tile's locks (A_LOCK / B_LOCK base); the first reader of
    // a buffer hands it to the second right after acquiring (A_FIRST / B_FIRST); the two readers walk
    // the buffer halves in opposite phase (A_PHASE / B_PHASE).
    (void)pn;
    (void)nk;
    const uintptr_t vA = (uintptr_t)AIEHLC_PLAN_A_VIEW(pm), vB = (uintptr_t)AIEHLC_PLAN_B_VIEW(pm);
    const int lA = (int)AIEHLC_PLAN_A_LOCK(pm), lB = (int)AIEHLC_PLAN_B_LOCK(pm);
    const int fl = (AIEHLC_PLAN_A_FIRST(pm) ? 1 : 0) | (AIEHLC_PLAN_B_FIRST(pm) ? 2 : 0) |
                   (AIEHLC_PLAN_A_PHASE(pm) ? 4 : 0) | (AIEHLC_PLAN_B_PHASE(pm) ? 8 : 0);
    const int swz = ((AIEHLC_PLAN_A_PHASE(pm) ? 1 : 0) << 3) ^ ((AIEHLC_PLAN_B_PHASE(pm) ? 1 : 0) << 1);
    unsigned gc = 0; /* chunks consumed so far (the hosted streams' slot / channel rotation) */
    for (int launch = 0; AIEHLC_PLAN_PERSISTENT || launch < 1; launch++) {
        if (AIEHLC_PLAN_PERSISTENT)
            acquire_greater_equal(AIEHLC_PLAN_GO_LOCK, 1); /* go: one launch */
        for (int i = 0; i < KA_TM * KA_TN; i += 64)
            aie::store_v(acc + i, aie::zeros<int32_t, 64>());
        for (int t = 0; t < SH_TILES; t++) {
            int8_t *y = acquire_output_window(c);
            ka_tile(vA, vB, lA, lB, fl, gc, SH_NK, 1, acc, acc + 2048, y, swz);
            gc += SH_NK;
            release_output_window(c);
        }
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
