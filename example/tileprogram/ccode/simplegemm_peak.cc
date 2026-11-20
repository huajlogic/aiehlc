/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * Kernel-only int8 GEMM written for the core's compute peak.
 *
 *   C[GP_M, GP_N] = A[GP_M, GP_K] . B[GP_N, GP_K]^T on the 4x4 mesh; core (pm, pn)
 *   computes the (GP_M / 4) x (GP_N / 4) block (pm, pn) of C.
 *
 * Measured on palmyra (AIE2PS), all 16 cores identical, GOLDEN PASS:
 *   32 x 32 x 384 per core: 768 MAC instructions in 839 cycles = 91.5 % of peak
 *   64 x 64 x 128 per core: 1024 in 1359 cycles = 75.4 % (K too short, see below)
 * That is the core's compute. The launch around it is ~226 ms, nearly all of it
 * kernel load (a cold launch, see tutorial 6.1): this example measures the
 * kernel, not the launch.
 *
 * Peak. On AIE2PS (__AIE_ARCH__ 22, the aie2p mmul backend) aie::mmul<8, 8, 8,
 * int8, int8> is one mac_8x8_8x8 instruction: 512 MACs. One per cycle is the
 * core's int8 peak. What the kernel does to get close to it:
 *   - both operands resident: A's and B's 64-row blocks are loaded once
 *     ({.resident = true}) and stay in core memory, so the compute loop never
 *     waits for the DMA;
 *   - 2 x 2 register blocking: four accumulators (a 16 x 16 C tile) per K step,
 *     so every 64-byte operand load feeds two MACs (4 loads, 4 MACs per step);
 *   - operands host-packed in mmul order (simplegemm_peak.h), so each operand is
 *     ONE aligned 64-byte load;
 *   - the C block is written tile by tile (one 64-byte store per 8 x 8 tile) and
 *     de-tiled by the host.
 * Each core klogs the cycles of its compute loop (CYC) -- loads, MACs, the
 * int8 write-back, everything between the operands arriving and the commit.
 * Efficiency = (64 * 64 * GP_K MACs) / (CYC * 512).
 ******************************************************************************/
#pragma aie_debug_level(AIE_KERNEL_CONFIG_TRACE)
#include "simplegemm_peak.h"

// Per core: a 32 x 32 block of C, K = 384 -- A's and B's 32 x 384 blocks (12 KB each) and C's ping-pong
// (2 x 1 KB) fit the 29 KB port region. K is what sets the efficiency: a 16 x 16 C tile costs ~19 cycles
// outside its K loop, so it needs many K steps (48 here) to amortise them.
#define GP_M 128
#define GP_N 128
#define GP_K 384

__global__ void gemm_peak(aie::port<input_window_int8 *, aie::IFM, aie::shape<GP_M, GP_K>> a,
                          aie::port<input_window_int8 *, aie::WEIGHTS, aie::shape<GP_N, GP_K>> b,
                          aie::port<output_window_int8 *, aie::OFM, aie::shape<GP_M, GP_N>> c) {
    const int cm = GP_M / 4, cn = GP_N / 4, kt = GP_K / 8;
    const int pm = aie::program_id(0), pn = aie::program_id(1);
    const int8_t *x = aie::load_buffer(a, {pm * cm, 0}, {cm, GP_K}, {.resident = true});
    const int8_t *w = aie::load_buffer(b, {pn * cn, 0}, {cn, GP_K}, {.resident = true});
    int8_t *y = aie::store_buffer(c, {pm * cm, pn * cn}, {cm, cn});
#if defined(__chess__)
    // aie2ps has 8 2048-bit accumulators (dm0..dm7): the compiler keeps this 2 x 2 block's four
    // and overlaps the write-back of one 16 x 16 tile with the first MACs of the next.
    using MM = aie::mmul<8, 8, 8, int8_t, int8_t>;
    const unsigned long long t0 = aie::tile::current().cycles();
    for (int mi = 0; mi < cm / 8; mi += 2)
        for (int ni = 0; ni < cn / 8; ni += 2) {
            const int8_t *__restrict pa0 = x + mi * kt * 64;
            const int8_t *__restrict pa1 = pa0 + kt * 64;
            const int8_t *__restrict pb0 = w + ni * kt * 64;
            const int8_t *__restrict pb1 = pb0 + kt * 64;
            MM c00, c01, c10, c11;
            {
                const aie::vector<int8_t, 64> a0 = aie::load_v<64>(pa0), a1 = aie::load_v<64>(pa1);
                const aie::vector<int8_t, 64> b0 = aie::load_v<64>(pb0), b1 = aie::load_v<64>(pb1);
                c00.mul(a0, b0);
                c01.mul(a0, b1);
                c10.mul(a1, b0);
                c11.mul(a1, b1);
            }
            for (int ki = 1; ki < kt; ki++)
                chess_prepare_for_pipelining chess_loop_range(3, ) {
                    const aie::vector<int8_t, 64> a0 = aie::load_v<64>(pa0 + ki * 64);
                    const aie::vector<int8_t, 64> a1 = aie::load_v<64>(pa1 + ki * 64);
                    const aie::vector<int8_t, 64> b0 = aie::load_v<64>(pb0 + ki * 64);
                    const aie::vector<int8_t, 64> b1 = aie::load_v<64>(pb1 + ki * 64);
                    c00.mac(a0, b0);
                    c01.mac(a0, b1);
                    c10.mac(a1, b0);
                    c11.mac(a1, b1);
                }
            int8_t *t = y + (mi * (cn / 8) + ni) * 64; // tile (mi, ni); (mi, ni + 1) follows it
            aie::store_v(t, c00.to_vector<int8_t>(0));
            aie::store_v(t + 64, c01.to_vector<int8_t>(0));
            aie::store_v(t + (cn / 8) * 64, c10.to_vector<int8_t>(0));
            aie::store_v(t + (cn / 8) * 64 + 64, c11.to_vector<int8_t>(0));
        }
    const unsigned long long t1 = aie::tile::current().cycles();
    klog("CYC", (int)(t1 - t0));
#else
    // x86 trace / emulation: the same result from the same packed blocks, scalar.
    for (int mi = 0; mi < cm / 8; mi++)
        for (int ni = 0; ni < cn / 8; ni++)
            for (int r = 0; r < 8; r++)
                for (int q = 0; q < 8; q++) {
                    int acc = 0;
                    for (int k = 0; k < GP_K; k++)
                        acc += x[(mi * kt + k / 8) * 64 + r * 8 + k % 8] * w[(ni * kt + k / 8) * 64 + (k % 8) * 8 + q];
                    y[(mi * (cn / 8) + ni) * 64 + r * 8 + q] = (int8_t)acc;
                }
#endif
    aie::commit(c);
    aie::release(a);
    aie::release(b);
}

static void gemm_peak_run(int8_t *A, int8_t *B, int8_t *C) {
    aieSetDevice(0);
    aieArray device;
    aieMesh mesh = device.partition({3, 6, 0, 6}, GP_HW_ROWS, GP_HW_COLS);
    gemm_peak<<<mesh>>>(A, B, C);
}

int main() {
    printf("=== gemm_peak: C[%d x %d] = A[%d x %d] . B[%d x %d]^T, int8, 4x4 mesh ===\n", GP_M, GP_N, GP_M, GP_K, GP_N,
           GP_K);
    int8_t *A = (int8_t *)malloc(GP_M * GP_K), *B = (int8_t *)malloc(GP_N * GP_K), *C = (int8_t *)malloc(GP_M * GP_N);
    int8_t *Ap = (int8_t *)__Runtime_Alloc(GP_M * GP_K), *Bp = (int8_t *)__Runtime_Alloc(GP_N * GP_K);
    int8_t *Ct = (int8_t *)__Runtime_Alloc(GP_M * GP_N);
    gp_init(A, B, GP_M, GP_N, GP_K);
    gp_pack(A, Ap, GP_M, GP_K, GP_M / GP_HW_ROWS, 0);
    gp_pack(B, Bp, GP_N, GP_K, GP_N / GP_HW_COLS, 1);
    memset(Ct, 0, GP_M * GP_N);
    XTime t0, t1;
    XTime_GetTime(&t0);
    gemm_peak_run(Ap, Bp, Ct);
    XTime_GetTime(&t1);
    Xil_DCacheInvalidateRange((UINTPTR)Ct, GP_M * GP_N);
    printf("[gemm_peak] launch %.3f ms; per-core compute: CYC above, MACs/core %d, peak 512 MAC/cycle -> "
           "efficiency = %d / (CYC * 512)\n",
           gp_ms(t0, t1), (GP_M / 4) * (GP_N / 4) * GP_K, (GP_M / 4) * (GP_N / 4) * GP_K);
    gp_untile_c(Ct, C, GP_M, GP_N);
    const long bad = gp_verify(A, B, C, GP_M, GP_N, GP_K);
    return bad ? 1 : 0;
}
