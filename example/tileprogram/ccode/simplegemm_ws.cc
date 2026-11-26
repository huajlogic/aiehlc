/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * Inner loop of a weight-stationary int8 GEMM, measured on its own.
 *
 *   C[GP_M, GP_N] = A[GP_M, GP_K] . B[GP_N, GP_K]^T on the 4x4 mesh; core (pm, pn) computes the
 *   (GP_M / 4) x (GP_N / 4) block (pm, pn) of C.
 *
 * The question it answers: when the accumulators stay in registers for the WHOLE K (no partial sums in
 * core memory) and two 16 x 16 blocks (2 x 2 accumulators each, all 8 dm registers) are written in one
 * straight-line body so the compiler can overlap one block's write-back with the other's MACs, how many
 * cycles does a block cost outside its K / 8 * 4 MAC instructions? A weight-stationary GEMM (B resident
 * per core, A streamed, int8 out) runs exactly this loop per A row block.
 *
 * Both operands are resident here ({.resident}), host-packed in mmul order (simplegemm_peak.h), so the
 * CYC each core klogs is the loop alone. Efficiency = (cm * cn * GP_K) / (CYC * 512).
 *
 * Measured on palmyra, 2026-11-25 (16 x 96 x 384 per core, all 16 cores, GOLDEN PASS): 1152 MAC instructions
 * in 1365 cycles = 84.4 %. Inside a block the schedule is one VMAC per bundle; each 16 x 16 block pays ~35
 * cycles at its start (load latency) and end (MAC / SRS latency before the int8 stores), and the compiler does
 * not overlap one block's end with the next block's start. Compare simplegemm_peak.cc with
 *perftest/gemm90/simplegemm_peak_2x4.patch (97.6 %: one 2 x 4 group of 1152 MAC instructions per core).
 *doc/performance/gemm_e2e_progress.md, "the 95 % question".
 ******************************************************************************/
#pragma aie_debug_level(AIE_KERNEL_CONFIG_TRACE)
#include "simplegemm_peak.h"

// Per core: A 16 x 384 (6 KB), B 96 x 384 (36 KB), C 16 x 96 ping-pong (2 x 1.5 KB): 45 KB (GP_M 128 does
// not fit next to the stack TilingLinalg reserves).
#ifndef GP_M
#define GP_M 64
#endif
#ifndef GP_N
#define GP_N 384
#endif
#ifndef GP_K
#define GP_K 384
#endif

// AIEHLC_KERNEL_PROLOGUE_BEGIN
#if defined(__chess__)
typedef aie::mmul<8, 8, 8, int8_t, int8_t> WsMM;
// One 16 x 16 block: A tiles pa0 / pa1 (8 rows each), B tiles pb0 / pb1 (8 columns each), the whole K.
#define WS_BLOCK(c, pa0, pa1, pb0, pb1)                                                                                \
    {                                                                                                                  \
        (c##00).mul(aie::load_v<64>(pa0), aie::load_v<64>(pb0));                                                       \
        (c##01).mul(aie::load_v<64>(pa0), aie::load_v<64>(pb1));                                                       \
        (c##10).mul(aie::load_v<64>(pa1), aie::load_v<64>(pb0));                                                       \
        (c##11).mul(aie::load_v<64>(pa1), aie::load_v<64>(pb1));                                                       \
        for (int ki = 1; ki < kt; ki++)                                                                                \
            chess_flatten_loop {                                                                                       \
                const aie::vector<int8_t, 64> a0 = aie::load_v<64>(pa0 + ki * 64);                                     \
                const aie::vector<int8_t, 64> a1 = aie::load_v<64>(pa1 + ki * 64);                                     \
                const aie::vector<int8_t, 64> b0 = aie::load_v<64>(pb0 + ki * 64);                                     \
                const aie::vector<int8_t, 64> b1 = aie::load_v<64>(pb1 + ki * 64);                                     \
                (c##00).mac(a0, b0);                                                                                   \
                (c##01).mac(a0, b1);                                                                                   \
                (c##10).mac(a1, b0);                                                                                   \
                (c##11).mac(a1, b1);                                                                                   \
            }                                                                                                          \
    }
#define WS_STORE(c, t)                                                                                                 \
    {                                                                                                                  \
        aie::store_v((t), (c##00).to_vector<int8_t>(0));                                                               \
        aie::store_v((t) + 64, (c##01).to_vector<int8_t>(0));                                                          \
        aie::store_v((t) + (cn / 8) * 64, (c##10).to_vector<int8_t>(0));                                               \
        aie::store_v((t) + (cn / 8) * 64 + 64, (c##11).to_vector<int8_t>(0));                                          \
    }
#endif
// AIEHLC_KERNEL_PROLOGUE_END

__global__ void gemm_ws(aie::port<input_window_int8 *, aie::IFM, aie::shape<GP_M, GP_K>> a,
                        aie::port<input_window_int8 *, aie::WEIGHTS, aie::shape<GP_N, GP_K>> b,
                        aie::port<output_window_int8 *, aie::OFM, aie::shape<GP_M, GP_N>> c) {
    const int cm = GP_M / 4, cn = GP_N / 4, kt = GP_K / 8;
    const int pm = aie::program_id(0), pn = aie::program_id(1);
    const int8_t *x = aie::load_buffer(a, {pm * cm, 0}, {cm, GP_K}, {.resident = true});
    const int8_t *w = aie::load_buffer(b, {pn * cn, 0}, {cn, GP_K}, {.resident = true});
    int8_t *y = aie::store_buffer(c, {pm * cm, pn * cn}, {cm, cn});
#if defined(__chess__)
    const unsigned long long t0 = aie::tile::current().cycles();
    // X = block (mi, ni), Y = block (mi, ni + 2): all 8 accumulators, one straight-line body per pair
    for (int mi = 0; mi < cm / 8; mi += 2)
        for (int ni = 0; ni < cn / 8; ni += 4) {
            const int8_t *__restrict pa0 = x + mi * kt * 64;
            const int8_t *__restrict pa1 = pa0 + kt * 64;
            const int8_t *__restrict pb0 = w + ni * kt * 64;
            const int8_t *__restrict pb1 = pb0 + kt * 64;
            const int8_t *__restrict pb2 = pb1 + kt * 64;
            const int8_t *__restrict pb3 = pb2 + kt * 64;
            WsMM X00, X01, X10, X11, Y00, Y01, Y10, Y11;
            WS_BLOCK(X, pa0, pa1, pb0, pb1);
            WS_BLOCK(Y, pa0, pa1, pb2, pb3);
            int8_t *t = y + (mi * (cn / 8) + ni) * 64;
            WS_STORE(X, t);
            WS_STORE(Y, t + 128);
        }
    const unsigned long long t1 = aie::tile::current().cycles();
    klog("CYC", (int)(t1 - t0));
#else
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

static void gemm_ws_run(int8_t *A, int8_t *B, int8_t *C) {
    aieSetDevice(0);
    aieArray device;
    aieMesh mesh = device.partition({3, 6, 0, 6}, GP_HW_ROWS, GP_HW_COLS);
    gemm_ws<<<mesh>>>(A, B, C);
}

int main() {
    printf("=== gemm_ws: C[%d x %d] = A[%d x %d] . B[%d x %d]^T, int8, 4x4 mesh ===\n", GP_M, GP_N, GP_M, GP_K, GP_N,
           GP_K);
    int8_t *A = (int8_t *)malloc(GP_M * GP_K), *B = (int8_t *)malloc(GP_N * GP_K), *C = (int8_t *)malloc(GP_M * GP_N);
    int8_t *Ap = (int8_t *)__Runtime_Alloc(GP_M * GP_K), *Bp = (int8_t *)__Runtime_Alloc(GP_N * GP_K);
    int8_t *Ct = (int8_t *)__Runtime_Alloc(GP_M * GP_N);
    gp_init(A, B, GP_M, GP_N, GP_K);
    gp_pack(A, Ap, GP_M, GP_K, GP_M / GP_HW_ROWS, 0);
    gp_pack(B, Bp, GP_N, GP_K, GP_N / GP_HW_COLS, 1);
    memset(Ct, 0, GP_M * GP_N);
    gemm_ws_run(Ap, Bp, Ct);
    Xil_DCacheInvalidateRange((UINTPTR)Ct, GP_M * GP_N);
    printf("[gemm_ws] per-core compute: CYC above, MACs/core %d -> efficiency = %d / (CYC * 512)\n",
           (GP_M / 4) * (GP_N / 4) * GP_K, (GP_M / 4) * (GP_N / 4) * GP_K);
    gp_untile_c(Ct, C, GP_M, GP_N);
    const long bad = gp_verify(A, B, C, GP_M, GP_N, GP_K);
    return bad ? 1 : 0;
}
