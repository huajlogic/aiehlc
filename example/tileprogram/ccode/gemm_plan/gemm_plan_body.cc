// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// The body of the 2 x 8 shared-operand GEMM (gemm_plan.cc, tutorial/perfoptmize steps 3-7): kernel,
// launch and host driver. The entry file sets the pragmas and, optionally, the knobs (all have defaults):
//   GP_M / GP_N / GP_K  C[M x N] = A[M x K] . B[N x K]^T                                  default 7680 x 512 x 2560
//   GP_DTYPE  1 = int8 (int32 accumulate, low byte out), 2 = bf16 (fp32 accumulate, bf16 out)    default 1
//   GP_LAUNCHES  persistent launches; the steady figure is the median of launches 2 .. N           default 8
//   GP_RING   A's MemTile FIFO ring depth (buffers of 2 chunks)   default: deepest <= 10 dividing the stream
//   GP_KEEP   B held in the MemTiles across launches (weight-resident)   default: when B's slice fits a MemTile
//   GP_PARTS  each chunk in 2 row parts in different core memory banks (or 1 part)    default 2
// Every count below (tiles per core, K chunks, strips) is derived from the shape; the limits are
// static_asserts. The AIE clock is measured in the run (shim timer vs the A78 generic timer).
#ifndef GP_M
#define GP_M 7680
#endif
#ifndef GP_N
#define GP_N 512
#endif
#ifndef GP_K
#define GP_K 2560
#endif
#ifndef GP_DTYPE
#define GP_DTYPE 1
#endif
#ifndef GP_LAUNCHES
#define GP_LAUNCHES 8
#endif
#ifndef GP_PARTS
#define GP_PARTS 2
#endif
#ifndef GP_DEPTH
#define GP_DEPTH 2 /* A / B {.depth}: chunk slots per core S2MM channel */
#endif
#ifndef GP_B_RING
#define GP_B_RING 0 /* 0: B held in the MemTiles (the plan streams it when it does not fit); N: force a ring */
#endif
// The mesh (an including file may set the width first: gemm_plan_4x2.cc).
#ifndef GP_HW_ROWS
#define GP_HW_ROWS 4
#endif
#ifndef GP_HW_COLS
#define GP_HW_COLS 4
#endif
#ifndef GP_PART_START
#define GP_PART_START 2 /* the partition's first column: the control-packet column, the mesh right of it */
#endif
#include "simplegemm_peak.h"

// Element bytes (int8 1, bf16 2). Ports and chunks are in BYTES: a chunk is KA_TM rows x KA_KC bytes for
// both dtypes (int8: 128 elements of K, bf16: 64), so the dataflow plan moves the same blocks.
#define GP_ES (GP_DTYPE)
#define KA_TM 64
#define KA_TN 64
#define KA_KC 128
#define K4_KC 128
#define GP_KCE (KA_KC / GP_ES)
#define KA_K (GP_K * GP_ES)
#define KA_R (GP_M / (GP_HW_ROWS * KA_TM))
#define KA_NT (GP_N / (GP_HW_COLS * KA_TN))
#define KA_M (GP_HW_ROWS * KA_TM * KA_R)
#define KA_N (GP_HW_COLS * KA_TN * KA_NT)
#define SH_R2 (KA_M / 2 / KA_TM)
#define SH_NT2 (KA_N / (2 * GP_HW_COLS * KA_TN))
#define SH_NK (KA_K / KA_KC)
#define SH_TILES (SH_R2 * SH_NT2)
// A's ring: the deepest ring of up to 10 buffers (2 chunks each) that divides the chunk stream of a
// column, tiles x K chunks (the dataflow plan's rule, plandma.cpp: (rounds x chunks) % (2 x ring) == 0).
#define GP_RING_CHUNKS (SH_TILES * SH_NK)
#ifndef GP_RING
#if GP_RING_CHUNKS % 20 == 0
#define GP_RING 10
#elif GP_RING_CHUNKS % 18 == 0
#define GP_RING 9
#elif GP_RING_CHUNKS % 16 == 0
#define GP_RING 8
#elif GP_RING_CHUNKS % 14 == 0
#define GP_RING 7
#elif GP_RING_CHUNKS % 12 == 0
#define GP_RING 6
#elif GP_RING_CHUNKS % 10 == 0
#define GP_RING 5
#elif GP_RING_CHUNKS % 8 == 0
#define GP_RING 4
#elif GP_RING_CHUNKS % 6 == 0
#define GP_RING 3
#else
#define GP_RING 2
#endif
#endif
// MemTile capacity (AIE-ML v2: 512 KB). The dataflow plan stages B whole in one MemTile per mesh column
// (its strips, KA_N / columns rows x KA_K bytes) and A's ring in the MemTile row above; B is kept across
// launches when its slice fits. When it does not, the plan streams B through a MemTile FIFO ring as well,
// re-read from DDR for every output tile ("[DataflowPlan] stream 1: ... streamed as memtile_ring").
#define GP_MT_BYTES (512 * 1024)
#define GP_A_RING_BYTES (GP_RING * 2 * KA_TM * KA_KC)
#define GP_B_SLICE_BYTES (KA_N / GP_HW_COLS * KA_K)
#ifndef GP_KEEP
#if GP_B_SLICE_BYTES <= GP_MT_BYTES
#define GP_KEEP true
#else
#define GP_KEEP false
#endif
#endif

#if GP_DTYPE != 1 && GP_DTYPE != 2
#error "GP_DTYPE: 1 = int8, 2 = bf16"
#endif
static_assert(GP_M % (GP_HW_ROWS * KA_TM) == 0, "GP_M: whole 64-row tiles on every mesh row");
static_assert(KA_M == GP_M && KA_N == GP_N, "shape must split into the 2 x 8 strips exactly");
static_assert(SH_NT2 == 1, "2 x 8 layout: N = 2 x mesh columns x 64 (one B tile per core)");
static_assert(GP_K % GP_KCE == 0 && KA_K % KA_KC == 0, "K % KC == 0 (whole chunks)");
static_assert(GP_RING_CHUNKS % (2 * GP_RING) == 0, "A ring must divide the chunk stream (tiles x K chunks)");
static_assert(SH_NK >= 2, "the chunk pipeline needs at least 2 K chunks");
static_assert(SH_TILES >= 1 && SH_TILES <= 64, "tiles / core <= 64 (6-bit OOO iteration counter)");
static_assert(GP_A_RING_BYTES <= GP_MT_BYTES, "A's ring must fit its MemTile");
static_assert(GP_LAUNCHES >= 2, "GP_LAUNCHES >= 2 (launch 1 loads the kernel)");

// AIEHLC_KERNEL_PROLOGUE_BEGIN
#include "gemm_plan_tile.h"
// AIEHLC_KERNEL_PROLOGUE_END

// One body for the core and for the compiler's x86 trace: every operand block comes from
// aie::load_buffer, every output tile goes out through aie::store_buffer -- the compiler serves the
// shared ports from the dataflow plan's hosted slots (locks, slot rotation, bank-split parts).
__global__ void gemm_ka(aie::port<input_window_int8 *, aie::IFM, aie::shape<KA_M, KA_K>> a,
                        aie::port<input_window_int8 *, aie::WEIGHTS, aie::shape<KA_N, KA_K>> b,
                        aie::port<output_window_int8 *, aie::OFM, aie::shape<KA_M, KA_N * GP_ES>> c) {
// How A and B travel (the dataflow the compiler builds; see the file header).
#define OPTS_A                                                                                                         \
    {                                                                                                                  \
        .depth = GP_DEPTH, .share = aie::share::neighbor, .stage = aie::stage::memtile_ring, .ring = GP_RING,          \
        .parts = GP_PARTS, .align = 64                                                                                 \
    }
#if GP_B_RING > 0 /* B streamed through a MemTile FIFO ring of GP_B_RING buffers per (strip, parity) */
#define OPTS_B                                                                                                         \
    {                                                                                                                  \
        .depth = GP_DEPTH, .share = aie::share::neighbor, .stage = aie::stage::memtile_ring, .ring = GP_B_RING,        \
        .parts = GP_PARTS, .align = 64                                                                                 \
    }
#else
#define OPTS_B                                                                                                         \
    {                                                                                                                  \
        .depth = GP_DEPTH, .share = aie::share::neighbor, .stage = aie::stage::memtile, .keep = GP_KEEP,               \
        .parts = GP_PARTS, .align = 64                                                                                 \
    }
#endif
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
#if GP_DTYPE == 1
    typedef aie::mmul<8, 8, 8, int8_t, int8_t> KaMM4; // one mac_8x8_8x8: 512 int8 MAC / cycle
    // 2 x 8 logical grid on the 4 x 4 mesh: core (pm, pn) computes A strip sa x B strip sb.
    const int pm = aie::program_id(0), pn = aie::program_id(1);
    const int sa = pm >> 1, sb = pn + GP_HW_COLS * (pm & 1), brow = sb * KA_TN;
    // The two cores reading one block walk its two parts in opposite order (different memory banks).
    const int pa = pm & 1, pb = pm >> 1, swz = (pa << 3) ^ (pb << 1);
    alignas(8192) static int32_t acc[KA_TM * KA_TN];
    int32_t *__restrict ae = acc, *__restrict ao = acc + 2048;
    int arow = 0;
    // A: shared with the neighbour core, staged through a MemTile FIFO ring of 10 buffers.
    // B: shared likewise, kept in a MemTile across launches (weight-resident).
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
#else
    // bf16 (correctness first, as peak_bf16.cc): plain aie::mmul<8, 8, 8, bfloat16, bfloat16, accfloat>
    // 2 x 2 blocks over the 64 x 64 tile, fp32 partial sums in core memory between chunks, bf16 out at
    // the last chunk. Same ports, chunks and dataflow as int8 (KA_KC bytes = GP_KCE elements of K).
    typedef aie::mmul<8, 8, 8, bfloat16, bfloat16, accfloat> BfMM;
    // fp32 -> bf16 rounds by the core's rounding mode, which starts as floor: round to nearest even, as the
    // reference does (gplan_ref.h "bf16cmp"; floor is one bf16 ulp off on half the outputs)
    aie::set_rounding(aie::rounding_mode::conv_even);
    const int pm = aie::program_id(0), pn = aie::program_id(1);
    const int sa = pm >> 1, sb = pn + GP_HW_COLS * (pm & 1), brow = sb * KA_TN;
    // The fp32 partial sums across the K chunks. When they do not fit next to the core's windows the
    // dataflow plan holds them in the memory it owns (AIEHLC_PLAN_ACC, one chunk slot per channel instead
    // of two; build log "[DataflowPlan] core memory: ..."); otherwise -- and in the x86 trace -- a static.
#if defined(AIEHLC_PLAN_ACC)
    float *const facc = (float *)AIEHLC_PLAN_ACC;
#else
    alignas(8192) static float facc[KA_TM * KA_TN];
#endif
#if GP_PARTS == 2
#define BF_PART(x, i) ((const bfloat16 *)(x).part(i))
#else
#define BF_PART(x, i) ((const bfloat16 *)(x) + (i) * (KA_TM / 2 * GP_KCE))
#endif
// 8 x 8 operand block (row block r of the chunk, k block kb): row blocks 0 .. 3 in part 0, 4 .. 7 in part 1
#define BF_OP(p0, p1, r, kb) (((r) / (KA_TM / 16) ? (p1) : (p0)) + (((r) % (KA_TM / 16)) * (GP_KCE / 8) + (kb)) * 64)
    for (int t = 0; t < SH_TILES; t++) {
        const int arow = sa * (KA_M / 2) + t * KA_TM;
        bfloat16 *__restrict y =
            (bfloat16 *)aie::store_buffer(c, {arow, brow * GP_ES}, {KA_TM, KA_TN * GP_ES}, {.align = 64});
        for (int k = 0; k < SH_NK; k++) {
            auto xa = aie::load_buffer(a, {arow, k * KA_KC}, {KA_TM, KA_KC}, OPTS_A);
            auto xb = aie::load_buffer(b, {brow, k * KA_KC}, {KA_TN, KA_KC}, OPTS_B);
            const bfloat16 *a0p = BF_PART(xa, 0), *a1p = BF_PART(xa, 1);
            const bfloat16 *b0p = BF_PART(xb, 0), *b1p = BF_PART(xb, 1);
            for (int mi = 0; mi < KA_TM / 8; mi += 2)
                for (int ni = 0; ni < KA_TN / 8; ni += 2) {
                    float *f00 = facc + (mi * (KA_TN / 8) + ni) * 64, *f01 = f00 + 64;
                    float *f10 = f00 + (KA_TN / 8) * 64, *f11 = f10 + 64;
                    BfMM c00, c01, c10, c11;
                    if (k == 0) {
                        const aie::accum<accfloat, 64> z = aie::zeros<accfloat, 64>();
                        c00 = BfMM(z);
                        c01 = BfMM(z);
                        c10 = BfMM(z);
                        c11 = BfMM(z);
                    } else {
                        aie::accum<accfloat, 64> q0, q1, q2, q3;
                        q0.from_vector(aie::load_v<64>(f00));
                        q1.from_vector(aie::load_v<64>(f01));
                        q2.from_vector(aie::load_v<64>(f10));
                        q3.from_vector(aie::load_v<64>(f11));
                        c00 = BfMM(q0);
                        c01 = BfMM(q1);
                        c10 = BfMM(q2);
                        c11 = BfMM(q3);
                    }
                    for (int kb = 0; kb < GP_KCE / 8; kb++) {
                        const aie::vector<bfloat16, 64> va0 = aie::load_v<64>(BF_OP(a0p, a1p, mi, kb));
                        const aie::vector<bfloat16, 64> va1 = aie::load_v<64>(BF_OP(a0p, a1p, mi + 1, kb));
                        const aie::vector<bfloat16, 64> vb0 = aie::load_v<64>(BF_OP(b0p, b1p, ni, kb));
                        const aie::vector<bfloat16, 64> vb1 = aie::load_v<64>(BF_OP(b0p, b1p, ni + 1, kb));
                        c00.mac(va0, vb0);
                        c01.mac(va0, vb1);
                        c10.mac(va1, vb0);
                        c11.mac(va1, vb1);
                    }
                    if (k == SH_NK - 1) { // C tile [mi][ni][8 m][8 n], bf16 (RNE)
                        bfloat16 *o = y + (mi * (KA_TN / 8) + ni) * 64;
                        aie::store_v(o, c00.to_vector<bfloat16>());
                        aie::store_v(o + 64, c01.to_vector<bfloat16>());
                        aie::store_v(o + (KA_TN / 8) * 64, c10.to_vector<bfloat16>());
                        aie::store_v(o + (KA_TN / 8) * 64 + 64, c11.to_vector<bfloat16>());
                    } else {
                        aie::store_v(f00, c00.to_vector<float>());
                        aie::store_v(f01, c01.to_vector<float>());
                        aie::store_v(f10, c10.to_vector<float>());
                        aie::store_v(f11, c11.to_vector<float>());
                    }
                }
            aie::release(a);
            aie::release(b);
        }
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
    // the control-packet column + the mesh's columns
    aieMesh mesh = device.partition({GP_PART_START, GP_PART_START + GP_HW_COLS, 0, 6}, GP_HW_ROWS, GP_HW_COLS);
    gemm_ka<<<mesh>>>(A, B, C);
}

// Host element type: int8, or the bf16 bit pattern (gplan_ref.h: data, sampling, reference, crc32).
#include "gplan_ref.h"
#if GP_DTYPE == 2
typedef uint16_t gp_elem_t;
#define GP_REF_DTYPE GPREF_BF16
#define GP_MAC_PER_CYC 256
#else
typedef int8_t gp_elem_t;
#define GP_REF_DTYPE GPREF_INT8
#define GP_MAC_PER_CYC 512
#endif

// [rows][K] row-major -> every (br x GP_KCE) chunk's elements in mmul operand order, placed where the
// chunk's DMA reads them (row r0 + p / GP_KCE, column k0 + p % GP_KCE for chunk element p).
// kn = 0: [mi][kb][8 row][8 k] (A); kn = 1: [ni][kb][8 k][8 row] (B).
static void ka_pack(const gp_elem_t *src, gp_elem_t *dst, long rows, long K, int br, int kn) {
    const int kb = GP_KCE / 8;
    for (long r0 = 0; r0 < rows; r0 += br)
        for (long k0 = 0; k0 < K; k0 += GP_KCE)
            for (int ti = 0; ti < br / 8; ti++)
                for (int ki = 0; ki < kb; ki++)
                    for (int u = 0; u < 8; u++)
                        for (int v = 0; v < 8; v++) {
                            const long r = r0 + ti * 8 + (kn ? v : u), k = k0 + ki * 8 + (kn ? u : v);
                            const long p = (long)(ti * kb + ki) * 64 + u * 8 + v;
                            dst[(r0 + p / GP_KCE) * K + k0 + p % GP_KCE] = src[r * K + k];
                        }
}

// A / B laid out in DDR in the order the plan's shim BDs stream them: aiehlc_plan_arrange, generated from
// the plan into aiehlc_plan.h (the front end parses this file before the plan exists: a declaration).
#if __has_include("aiehlc_plan.h")
#include "aiehlc_plan.h"
#else
void aiehlc_plan_arrange(int arg, const void *src, void *dst);
#endif

// AIE array clock, measured in the run: the shim PL-module Timer_Low (AIE cycles, the partition's first
// column) against the A78 generic timer (CNTPCT, COUNTS_PER_SECOND), median of 3 windows of 20 ms
// (arthur/tasks/2026-11-09_core-clock-pin). 0 when the timer does not move (not readable).
#define GP_AIE_ARRAY_BASE 0x20000000000ULL
#define GP_AIE_COL_SHIFT 25
#define GP_PL_TIMER_LOW 0x340F8ULL
#define GP_SHIM_COL 2ULL
static double gp_aie_clock(void) {
    double w[3];
#if defined(__aarch64__) && !defined(__AIESIM__) && !defined(__linux__)
    volatile uint32_t *tl =
        (volatile uint32_t *)(uintptr_t)(GP_AIE_ARRAY_BASE + (GP_SHIM_COL << GP_AIE_COL_SHIFT) + GP_PL_TIMER_LOW);
    for (int r = 0; r < 3; r++) {
        XTime x0, x1, x2;
        XTime_GetTime(&x0);
        const uint32_t c0 = *tl;
        do
            XTime_GetTime(&x1);
        while (gp_ms(x0, x1) < 20.0);
        const uint32_t c1 = *tl;
        XTime_GetTime(&x2);
        w[r] = (double)(uint32_t)(c1 - c0) / (gp_ms(x0, x2) * 1e3);
    }
#else
    for (int r = 0; r < 3; r++)
        w[r] = 0;
#endif
    const double lo = w[0] < w[1] ? w[0] : w[1], hi = w[0] < w[1] ? w[1] : w[0];
    return w[2] < lo ? lo : (w[2] > hi ? hi : w[2]);
}

// aiehlchj-90 lesson #2: __Runtime_alloc_uncached over 2 MB used to fall back to cached memory silently.
// Check every 2 MB block of the buffer in the BSP's level-2 table (low 4 GB): it must be Normal NC.
#if defined(__aarch64__) && !defined(__AIESIM__) && !defined(__linux__) && __has_include("xil_mmu.h")
#include "xil_mmu.h"
extern "C" INTPTR MMUTableL2;
#define GP_HAVE_MMU 1
#endif
static int gp_uncached(const void *p, size_t bytes) {
#ifdef GP_HAVE_MMU
    const uint64_t blk = 0x200000ULL, lo = (uint64_t)(uintptr_t)p, hi = lo + bytes;
    if (!p || hi > 0x100000000ULL)
        return 0;
    for (uint64_t b = lo / blk; b < (hi + blk - 1) / blk; b++)
        if (((uint64_t)(&MMUTableL2)[b] & ~0x0000FFFFFFE00000ULL) != (uint64_t)NORM_NONCACHE)
            return 0;
    return 1;
#else
    (void)p;
    (void)bytes;
    return 0;
#endif
}

// golden: C as the cores wrote it (tile-major, output_tile_major) -> element (i, j); out_crc over the
// board's values in the sample order (int8: 1 byte, bf16: 2 bytes little-endian)
typedef struct {
    const gp_elem_t *Ct;
    uint32_t crc;
} gp_got_ctx;
static int32_t gp_got(void *vctx, long i, long jj) {
    gp_got_ctx *x = (gp_got_ctx *)vctx;
    const long R = SH_R2 * SH_NT2, blk = KA_TM * KA_TN, nti = KA_TN / 8;
    const long h = i / (KA_M / 2), s = (i % (KA_M / 2)) / KA_TM, rr = i % KA_TM;
    const long nt2 = SH_NT2, sj = jj / (KA_TN * nt2), nt = (jj % (KA_TN * nt2)) / KA_TN, cj = jj % KA_TN;
    const long pn = sj % GP_HW_COLS, pm = 2 * h + sj / GP_HW_COLS;
    const long q = ((rr / 8) * nti + cj / 8) * 64 + (rr % 8) * 8 + cj % 8;
    const gp_elem_t g = x->Ct[((pm * GP_HW_COLS + pn) * R + s * nt2 + nt) * blk + q];
#if GP_DTYPE == 2
    x->crc = gpref_crc32_u16le(x->crc, g);
    return (int32_t)g;
#else
    const uint8_t gb = (uint8_t)g;
    x->crc = gpref_crc32_upd(x->crc, &gb, 1);
    return (int32_t)g;
#endif
}

int main() {
    const long M = GP_M, N = GP_N, K = GP_K;
    const int launches = GP_LAUNCHES;
    const char *dts = gpref_dtype(GP_REF_DTYPE);
    printf("=== gemm_plan: C[%ld x %ld] = A[%ld x %ld] . B^T, %s, 2 x 8 shared operands from the dmaphop "
           "dataflow plan, %.3f GMAC, %d tiles / core, %d K chunks, B keep %d ===\n",
           M, N, M, K, dts, (double)M * N * K / 1e9, (int)SH_TILES, (int)SH_NK, (int)(GP_KEEP));
    const size_t abytes = (size_t)M * K * GP_ES, bbytes = (size_t)N * K * GP_ES, cbytes = (size_t)M * N * GP_ES;
    gp_elem_t *A = (gp_elem_t *)malloc(abytes), *B = (gp_elem_t *)malloc(bbytes);
    gp_elem_t *Ap = (gp_elem_t *)malloc(abytes), *Bp = (gp_elem_t *)malloc(bbytes);
    int8_t *A2 = (int8_t *)__Runtime_alloc_uncached(abytes), *B2 = (int8_t *)__Runtime_alloc_uncached(bbytes);
    // C non-cacheable: every launch ends with the output made coherent for the CPU, which on a cached
    // buffer is an invalidate of all of C; on a non-cacheable one it is a barrier
    int8_t *Ct = (int8_t *)__Runtime_alloc_uncached(cbytes);
    if (!Ct)
        Ct = (int8_t *)__Runtime_Alloc(cbytes);
    if (!A || !B || !Ap || !Bp || !A2 || !B2 || !Ct) {
        printf("GPLAN ERROR alloc failed (A %zu B %zu C %zu bytes)\n", abytes, bbytes, cbytes);
        return 2;
    }
    const int unc = gp_uncached(A2, abytes) && gp_uncached(B2, bbytes) && gp_uncached(Ct, cbytes);
    printf("UNCACHED ok=%d A=%d B=%d C=%d (A %zu B %zu C %zu bytes)\n", unc, gp_uncached(A2, abytes),
           gp_uncached(B2, bbytes), gp_uncached(Ct, cbytes), abytes, bbytes, cbytes);
#if GP_DTYPE == 2
    gpref_init_bf16(A, B, M, N, K);
#else
    gpref_init_i8(A, B, M, N, K);
#endif
    const uint32_t in_crc = gpref_in_crc(GP_REF_DTYPE, A, B, M, N, K);
    // A / B pre-pack on the host, outside the timed launches (a GAP: .1.3 moves it to BDs or counts it)
    ka_pack(A, Ap, M, K, KA_TM, 0);
    ka_pack(B, Bp, N, K, KA_TN, 1);
    aiehlc_plan_arrange(0, Ap, A2);
    aiehlc_plan_arrange(1, Bp, B2);
    free(Ap);
    free(Bp);
    memset(Ct, 0, cbytes);
    __Runtime_buffer_device_written(Ct, cbytes);
    double *lms = (double *)malloc(sizeof(double) * launches);
    double aie_clk = 0;
    for (int it = 0; it < launches; it++) {
        if (it == launches - 1) { // sentinel: the checked C is written by the last launch
            memset(Ct, 0xA5, cbytes);
            __Runtime_buffer_device_written(Ct, cbytes);
        }
        XTime t0, t1;
        XTime_GetTime(&t0);
        gemm_ka_run(A2, B2, Ct);
        XTime_GetTime(&t1);
        lms[it] = gp_ms(t0, t1);
        if (it == 0) { // the array is up and clocked: measure its clock
            aie_clk = gp_aie_clock();
            printf("GPLAN where=%s dtype=%s shape=%ldx%ldx%ld aie_mhz=%.1f clk_src=%s\n", "board", dts, M, N, K,
                   aie_clk, aie_clk > 0 ? "shim_timer/cntpct" : "none");
        }
    }
    const double theory_ms =
        aie_clk > 0 ? (double)M * N * K / (GP_HW_ROWS * GP_HW_COLS * (double)GP_MAC_PER_CYC * aie_clk * 1e6) * 1e3 : 0;
    for (int it = 0; it < launches; it++)
        printf("[gemm_plan] call %d: end to end %.3f ms -> %.2f %% of theory\n", it + 1, lms[it],
               theory_ms > 0 ? 100.0 * theory_ms / lms[it] : 0.0);
    // steady: median of launches 2 .. N (launch 1 also loads the kernel)
    const int ns = launches - 1;
    double *st = lms + 1;
    for (int a = 1; a < ns; a++)
        for (int b = a; b > 0 && st[b] < st[b - 1]; b--) {
            const double tt = st[b];
            st[b] = st[b - 1];
            st[b - 1] = tt;
        }
    const double med = ns % 2 ? st[ns / 2] : 0.5 * (st[ns / 2 - 1] + st[ns / 2]);
    printf("STEADY mode=persistent launches=%d median_us=%.1f\n", launches, med * 1e3);
    printf("[gemm_plan] theory %d x %d MAC/cycle @ %.1f MHz = %.1f us -> steady %.2f %% of theory\n",
           GP_HW_ROWS * GP_HW_COLS, GP_MAC_PER_CYC, aie_clk, theory_ms * 1e3,
           theory_ms > 0 ? 100.0 * theory_ms / med : 0.0);
    printf("PERF SUMMARY gemm_plan steady %.3f ms median (%.2f %% of peak @ %.0f MHz), best %.3f ms (%.2f %%)\n", med,
           theory_ms > 0 ? 100.0 * theory_ms / med : 0.0, aie_clk, st[0],
           theory_ms > 0 ? 100.0 * theory_ms / st[0] : 0.0);
    Xil_DCacheInvalidateRange((UINTPTR)Ct, cbytes);
    gp_got_ctx gx = {(const gp_elem_t *)Ct, 0xFFFFFFFFu};
    const gpref_res_t r = gpref_check(GP_REF_DTYPE, A, B, M, N, K, gp_got, &gx);
    const uint32_t out_crc = gx.crc ^ 0xFFFFFFFFu;
#if GP_DTYPE == 2 && defined(GP_DEBUG_MAP) /* debug: which outputs are right, per row 0 / 7 / 64 / 2048 */
    {
        const long rows[] = {0, 7, 64, 2048};
        for (int ri = 0; ri < 4; ri++) {
            char map[129];
            for (long j = 0; j < 128; j++) {
                const uint16_t w = gpref_ref_bf16((const uint16_t *)A, (const uint16_t *)B, K, rows[ri], j);
                map[j] = gpref_bf16_ok((uint16_t)gp_got(&gx, rows[ri], j), w) ? '.' : 'x';
            }
            map[128] = 0;
            printf("GPDBG row %ld cols 0..127: %s\n", rows[ri], map);
        }
        for (long i = 0; i < 128; i += 8) { /* 8 x 8 blocks of tiles 0 and 1 (rows 0..127), columns 0..63 */
            char m[9];
            for (long jb = 0; jb < 8; jb++) {
                int ok = 1;
                for (long u = 0; u < 8; u++)
                    for (long v = 0; v < 8; v++)
                        ok &= gpref_bf16_ok(
                            (uint16_t)gp_got(&gx, i + u, jb * 8 + v),
                            gpref_ref_bf16((const uint16_t *)A, (const uint16_t *)B, K, i + u, jb * 8 + v));
                m[jb] = ok ? '.' : 'x';
            }
            m[8] = 0;
            printf("GPDBG blocks rows %3ld..%3ld: %s\n", i, i + 7, m);
        }
        for (long q = 0; q < 12; q++) { /* where in tile 0 does the value at row 0 / 8, column 16 + 4q belong? */
            const long gi = q < 6 ? 0 : 8, gj = 16 + 4 * (q % 6) + (q < 6 ? 0 : -16);
            const uint16_t g = (uint16_t)gp_got(&gx, gi, gj);
            long fi = -1, fj = -1, n = 0;
            for (long i = 0; i < 64; i++)
                for (long j = 0; j < 64; j++)
                    if (gpref_ref_bf16((const uint16_t *)A, (const uint16_t *)B, K, i, j) == g && n++ == 0)
                        fi = i, fj = j;
            printf("GPDBG got C[%ld][%ld] = %f equals ref C[%ld][%ld] (%ld matches in tile 0)\n", gi, gj, gpref_bf2f(g),
                   fi, fj, n);
        }
        for (long j = 0; j < 64; j += 8)
            printf("GPDBG C[0][%ld] got %f want %f\n", j, gpref_bf2f((uint16_t)gp_got(&gx, 0, j)),
                   gpref_bf2f(gpref_ref_bf16((const uint16_t *)A, (const uint16_t *)B, K, 0, j)));
    }
#endif
    if (r.bad)
        printf("MISMATCH first C[%ld][%ld]: got %d want %d (rule %s)\n", r.first_bad_i, r.first_bad_j, (int)r.first_got,
               (int)r.first_want, gpref_rule(GP_REF_DTYPE));
    printf("GOLDEN %s shape=%ldx%ldx%ld dtype=%s launch=%d checked=%ld bad=%ld in_crc=%08x ref_crc=%08x out_crc=%08x\n",
           r.pass ? "PASS" : "FAIL", M, N, K, dts, launches, r.checked, r.bad, (unsigned)in_crc, (unsigned)r.ref_crc,
           (unsigned)out_crc);
    return r.pass ? 0 : 1;
}
