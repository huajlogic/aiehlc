/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
// The GEMM of tutorial/perfoptmize steps 0-2 on the compiler's GENERIC path (no dataflow plan): every
// core (pm, pn) of the 4 x 4 mesh computes KA_R output tiles of 64 x 64, K accumulated in core memory
// over KA_K / KA_KC chunks; A and B arrive per chunk through the DMA the compiler derives from the
// load_buffer / store_buffer calls. Included by step0_baseline.cc / step1_vector.cc / step2_launch.cc,
// which set
//   GEN_VECTOR  0: scalar MACs   1: aie::mmul<8, 8, 8> with a 2 x 2 register block
//   GEN_LAUNCH  0: plain launch  1: the launch knobs (pragmas in step2_launch.cc, uncached operands,
//                                   tile-major output, control-plane fabric enabled)
//   C[7680 x 256] = A[7680 x 2560] . B[256 x 2560]^T (5.03 G MAC) -- one 64-wide n tile per core, the
//   shape the generic path derives (its kernel analysis fits two loop levels: tiles x K chunks).
#ifndef GP_HW_ROWS
#define GP_HW_ROWS 4
#endif
#ifndef GP_HW_COLS
#define GP_HW_COLS 4
#endif
#include "simplegemm_peak.h"

#if GEN_VECTOR
#define GEN_ALIGN 64
#else
#define GEN_ALIGN 32
#endif
#define KA_TM 64
#define KA_TN 64
#define KA_KC 64
#define KA_K 2560
#define KA_R 30
#define KA_M (GP_HW_ROWS * KA_TM * KA_R)
#define KA_N (GP_HW_COLS * KA_TN)

__global__ void gemm_gen(aie::port<input_window_int8 *, aie::IFM, aie::shape<KA_M, KA_K>> a,
                         aie::port<input_window_int8 *, aie::WEIGHTS, aie::shape<KA_N, KA_K>> b,
                         aie::port<output_window_int8 *, aie::OFM, aie::shape<KA_M, KA_N>> c) {
    const int pm = aie::program_id(0), pn = aie::program_id(1);
    const int kb = KA_KC / 8, nk = KA_K / KA_KC, nti = KA_TN / 8;
    alignas(64) static int32_t acc[KA_TM * KA_TN];
    for (int s = 0; s < KA_R; s++) {
        // GEN_ALIGN: a vector kernel's 64-byte aie::load_v / store_v need 64-byte aligned buffers ({.align})
        int8_t *y = aie::store_buffer(c, {(pm * KA_R + s) * KA_TM, pn * KA_TN}, {KA_TM, KA_TN}, {.align = GEN_ALIGN});
        for (int j = 0; j < nk; j++) {
            const int8_t *x = aie::load_buffer(a, {(pm * KA_R + s) * KA_TM, j * KA_KC}, {KA_TM, KA_KC},
                                               {.depth = 2, .align = GEN_ALIGN});
            const int8_t *w =
                aie::load_buffer(b, {pn * KA_TN, j * KA_KC}, {KA_TN, KA_KC}, {.depth = 2, .align = GEN_ALIGN});
#if GEN_VECTOR
            // 2 x 2 register block of mmul<8,8,8> (one mac_8x8_8x8 = 512 MAC per cycle), the int32
            // accumulators reloaded from / stored to core memory once per K chunk
            typedef aie::mmul<8, 8, 8, int8_t, int8_t> MM;
            for (int mh = 0; mh < KA_TM / 16; mh++)
                for (int nh = 0; nh < KA_TN / 16; nh++) {
                    const int8_t *__restrict pa0 = x + (2 * mh) * kb * 64, *__restrict pa1 = pa0 + kb * 64;
                    const int8_t *__restrict pb0 = w + (2 * nh) * kb * 64, *__restrict pb1 = pb0 + kb * 64;
                    int32_t *__restrict ac = acc + (mh * (KA_TN / 16) + nh) * 256;
                    MM c00, c01, c10, c11;
                    if (j == 0) {
                        c00.mul(aie::load_v<64>(pa0), aie::load_v<64>(pb0));
                        c01.mul(aie::load_v<64>(pa0), aie::load_v<64>(pb1));
                        c10.mul(aie::load_v<64>(pa1), aie::load_v<64>(pb0));
                        c11.mul(aie::load_v<64>(pa1), aie::load_v<64>(pb1));
                    } else {
                        aie::accum<acc32, 64> q00, q01, q10, q11;
                        q00.from_vector(aie::load_v<64>(ac));
                        q01.from_vector(aie::load_v<64>(ac + 64));
                        q10.from_vector(aie::load_v<64>(ac + 128));
                        q11.from_vector(aie::load_v<64>(ac + 192));
                        c00 = MM(q00), c01 = MM(q01), c10 = MM(q10), c11 = MM(q11);
                        c00.mac(aie::load_v<64>(pa0), aie::load_v<64>(pb0));
                        c01.mac(aie::load_v<64>(pa0), aie::load_v<64>(pb1));
                        c10.mac(aie::load_v<64>(pa1), aie::load_v<64>(pb0));
                        c11.mac(aie::load_v<64>(pa1), aie::load_v<64>(pb1));
                    }
                    for (int ki = 1; ki < kb; ki++) {
                        const aie::vector<int8_t, 64> a0 = aie::load_v<64>(pa0 + ki * 64);
                        const aie::vector<int8_t, 64> a1 = aie::load_v<64>(pa1 + ki * 64);
                        const aie::vector<int8_t, 64> b0 = aie::load_v<64>(pb0 + ki * 64);
                        const aie::vector<int8_t, 64> b1 = aie::load_v<64>(pb1 + ki * 64);
                        c00.mac(a0, b0);
                        c01.mac(a0, b1);
                        c10.mac(a1, b0);
                        c11.mac(a1, b1);
                    }
                    if (j == nk - 1) {
                        int8_t *t = y + ((2 * mh) * nti + 2 * nh) * 64;
                        aie::store_v(t, c00.to_vector<int8_t>(0));
                        aie::store_v(t + 64, c01.to_vector<int8_t>(0));
                        aie::store_v(t + nti * 64, c10.to_vector<int8_t>(0));
                        aie::store_v(t + nti * 64 + 64, c11.to_vector<int8_t>(0));
                    } else {
                        aie::store_v(ac, c00.to_vector<int32_t>());
                        aie::store_v(ac + 64, c01.to_vector<int32_t>());
                        aie::store_v(ac + 128, c10.to_vector<int32_t>());
                        aie::store_v(ac + 192, c11.to_vector<int32_t>());
                    }
                }
#else
            // scalar MACs, same operand / accumulator layouts: x [mi][kb][8 m][8 k], w [ni][kb][8 k][8 n],
            // acc [mh][nh][2 x 2 blocks][8 m][8 n], y [mi][ni][8 m][8 n]
            for (int mi = 0; mi < KA_TM / 8; mi++)
                for (int ni = 0; ni < nti; ni++)
                    for (int r = 0; r < 8; r++)
                        for (int q = 0; q < 8; q++) {
                            const int bi =
                                ((mi / 2) * (KA_TN / 16) + ni / 2) * 256 + ((mi % 2) * 2 + ni % 2) * 64 + r * 8 + q;
                            int sum = j ? acc[bi] : 0;
                            for (int k = 0; k < KA_KC; k++)
                                sum += x[(mi * kb + k / 8) * 64 + r * 8 + k % 8] *
                                       w[(ni * kb + k / 8) * 64 + (k % 8) * 8 + q];
                            acc[bi] = sum;
                            if (j == nk - 1)
                                y[(mi * nti + ni) * 64 + r * 8 + q] = (int8_t)sum;
                        }
#endif
            aie::release(a);
            aie::release(b);
        }
        aie::commit(c);
    }
}

void __Runtime_ctrl_high_throughput_enable(int on);
void __Runtime_ctrl_pmap_enable(int on);
void __Runtime_buffer_device_written(void *ptr, size_t size);
void *__Runtime_alloc_uncached(size_t bytes);

static void gemm_gen_run(int8_t *A, int8_t *B, int8_t *C) {
#if GEN_LAUNCH
    __Runtime_ctrl_high_throughput_enable(1); // required by the control-packet ELF load (step2 pragmas)
    __Runtime_ctrl_pmap_enable(0);
    aieSetDevice(0);
    aieArray device;
    aieMesh mesh = device.partition({2, 6, 0, 6}, GP_HW_ROWS, GP_HW_COLS); // + the control-packet column
#else
    aieSetDevice(0);
    aieArray device;
    aieMesh mesh = device.partition({3, 6, 0, 6}, GP_HW_ROWS, GP_HW_COLS);
#endif
    gemm_gen<<<mesh>>>(A, B, C);
}

// [rows][K] row-major -> every (br x KA_KC) chunk's bytes in mmul operand order, placed where the
// chunk's DMA reads them. kn = 0: [mi][kb][8 row][8 k] (A); kn = 1: [ni][kb][8 k][8 row] (B).
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

#ifndef GEMM_AIE_MHZ
#define GEMM_AIE_MHZ 1250.0 /* VEK385 array clock */
#endif
#ifndef GEN_ITERS
#define GEN_ITERS 4
#endif

int main() {
    const long M = KA_M, N = KA_N, K = KA_K, R = KA_R, blk = KA_TM * KA_TN, nti = KA_TN / 8;
    printf("=== gemm_gen (vector %d, launch knobs %d): C[%ld x %ld] = A[%ld x %ld] . B^T, int8, %.3f GMAC ===\n",
           GEN_VECTOR, GEN_LAUNCH, M, N, M, K, (double)M * N * K / 1e9);
    int8_t *A = (int8_t *)malloc(M * K), *B = (int8_t *)malloc(N * K);
#if GEN_LAUNCH
    int8_t *Ap = (int8_t *)__Runtime_alloc_uncached(M * K), *Bp = (int8_t *)__Runtime_alloc_uncached(N * K);
#else
    int8_t *Ap = (int8_t *)__Runtime_Alloc(M * K), *Bp = (int8_t *)__Runtime_Alloc(N * K);
#endif
#if GEN_LAUNCH /* C non-cacheable: the per-launch output coherence is a barrier, not a 2 MB invalidate */
    int8_t *Ct = (int8_t *)__Runtime_alloc_uncached(M * N);
#else
    int8_t *Ct = (int8_t *)__Runtime_Alloc(M * N);
#endif
    gp_init(A, B, M, N, K);
    ka_pack(A, Ap, M, K, KA_TM, 0);
    ka_pack(B, Bp, N, K, KA_TN, 1);
    memset(Ct, 0, M * N);
#if GEN_LAUNCH
    __Runtime_buffer_device_written(Ct, M * N);
#endif
    const double peak_ms = (double)M * N * K / (GP_HW_ROWS * GP_HW_COLS * 512.0 * GEMM_AIE_MHZ * 1e6) * 1e3;
    printf("[gemm_gen] ideal (%d x 512 MAC/cycle @ %.0f MHz) %.4f ms\n", GP_HW_ROWS * GP_HW_COLS, GEMM_AIE_MHZ,
           peak_ms);
    double sum = 0, best = 1e30;
    for (int it = 0; it < GEN_ITERS; it++) {
        XTime t0, t1;
        XTime_GetTime(&t0);
        gemm_gen_run(Ap, Bp, Ct);
        XTime_GetTime(&t1);
        const double ms = gp_ms(t0, t1);
        printf("[gemm_gen] call %d: end to end %.3f ms -> %.3f %% of peak\n", it, ms, 100.0 * peak_ms / ms);
        if (it > 0) {
            sum += ms;
            best = ms < best ? ms : best;
        }
    }
    printf("PERF SUMMARY gemm_gen steady %.3f ms mean (%.3f %% of peak), best %.3f ms (%.3f %%)\n",
           sum / (GEN_ITERS - 1), 100.0 * peak_ms * (GEN_ITERS - 1) / sum, best, 100.0 * peak_ms / best);
    Xil_DCacheInvalidateRange((UINTPTR)Ct, M * N);
    long bad = 0, checked = 0;
    for (long i = 0; i < M; i += 7) {
        const long pm = i / (M / GP_HW_ROWS), s = (i % (M / GP_HW_ROWS)) / KA_TM, rr = i % KA_TM;
        for (long jj = 0; jj < N; jj += 3) {
            const long pn = jj / KA_TN, cj = jj % KA_TN;
            const long q = ((rr / 8) * nti + cj / 8) * 64 + (rr % 8) * 8 + cj % 8; // byte of the tile the core wrote
#if GEN_LAUNCH /* #pragma output_tile_major: tile after tile */
            const int8_t got = Ct[((pm * GP_HW_COLS + pn) * R + s) * blk + q];
#else /* the tile's bytes land as a 64 x 64 block of row-major C */
            const int8_t got = Ct[((pm * R + s) * KA_TM + q / KA_TN) * N + pn * KA_TN + q % KA_TN];
#endif
            int acc = 0;
            for (long k = 0; k < K; k++)
                acc += A[i * K + k] * B[jj * K + k];
            if (got != (int8_t)acc && ++bad <= 8)
                printf("MISMATCH C[%ld][%ld] core (%ld,%ld) tile %ld: got %d want %d\n", i, jj, pm, pn, s, got,
                       (int8_t)acc);
            checked++;
        }
    }
    printf("%s: %ld / %ld checked outputs match\n", bad ? "GOLDEN FAIL" : "GOLDEN PASS", checked - bad, checked);
    return bad != 0;
}
