// Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
//
// gemm_plan_tbody.cc -- the TILE-GENERIC body of the 2 x 8 shared-operand GEMM (M3.3.6.2.1.2.3.1): gemm_plan_body.cc
// plus the core-tile knobs GP_TM / GP_TN / GP_KC / GP_C_DEPTH / GP_DM_FIXED. gemm_plan_body.cc stays as it is
// (64 x 64 x 128): the generated host.cc carries a body's text up to the kernel verbatim, so knobs added there
// would change the default build's host.cc (gemm_plan.cc, the s1i8 config) byte for byte. A config file that sets
// a tile knob includes this body instead (gemm_plan_s64t_int8.cc). With the defaults it is the same 64 x 64 x 128
// kernel (gemm_plan_tile.h K4_* / SH_*); any other int8 tile runs GT_CHUNK over (TM/16) x (TN/16) accumulator pairs.
// Kernel, launch and host driver. The entry file sets the pragmas and, optionally, the knobs (all have defaults):
//   GP_M / GP_N / GP_K  C[M x N] = A[M x K] . B[N x K]^T                                  default 7680 x 512 x 2560
//   GP_DTYPE  1 = int8 (int32 accumulate, low byte out), 2 = bf16 (fp32 accumulate, bf16 out)    default 1
//   GP_LAUNCHES  persistent launches; the steady figure is the median of launches 2 .. N           default 8
//   GP_RING   A's MemTile FIFO ring depth (buffers of 2 chunks)   default: deepest <= 10 dividing the stream
//   GP_KEEP   B held in the MemTiles across launches (weight-resident)   default: when B's slice fits a MemTile
//   GP_B_RING B chunked along K through a MemTile ring of this many buffers per (strip, parity) instead of
//             staged whole (0)                                        default: 0 when B's slice fits, else 4
//   GP_C_SPLIT each 64-row output tile written as this many row slices (1 or 2)  default: 1 when core DM
//             fits, else 2
//   GP_PARTS  each chunk in 2 row parts in different core memory banks (or 1 part)    default 2
//   GP_TM / GP_TN  core tile rows / columns (multiples of 16: TM/16 x TN/16 accumulator pairs)   default 64
//   GP_KC     chunk K in bytes (whole 8-deep k blocks)                                           default 128
//   GP_C_DEPTH output tile slots in core DM: 2 ping-pong, 1 one buffer ({.depth = 1}; needs a compiler
//             that accepts {.depth = 1} on aie::store_buffer, 015dbd32)                       default 2
//   GP_DM_FIXED stack + runtime state in the core-DM budget                                     default 8192
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
// The mesh (an including file may set the width first: gemm_plan_4x2.cc).
#ifndef GP_HW_ROWS
#define GP_HW_ROWS 4
#endif
#ifndef GP_HW_COLS
#define GP_HW_COLS 4
#endif
#include "simplegemm_peak.h"

// Element bytes (int8 1, bf16 2). Ports and chunks are in BYTES: a chunk is KA_TM rows x KA_KC bytes for
// both dtypes (int8: 128 elements of K, bf16: 64), so the dataflow plan moves the same blocks.
#define GP_ES (GP_DTYPE)
#ifndef GP_TM
#define GP_TM 64
#endif
#ifndef GP_TN
#define GP_TN 64
#endif
#ifndef GP_KC
#define GP_KC 128
#endif
#ifndef GP_C_DEPTH
#define GP_C_DEPTH 2
#endif
// GP_GT: the generic int8 tile's chunk kernel: 0 GT_CHUNK (one loop nest, first / last tested in it), 1 GT_CHUNK_P
// (one specialisation per chunk kind, k blocks flattened, pair columns software-pipelined), 2 GT_CHUNK_P2 over two
// chunks per accumulator reload (both input slots held; SH_NK even), 3 GT_CHUNK_K (two accumulator sets, the
// partial-sum round trip of one block overlaps the VMACs of the other), 4 GT_CHUNK_K over two chunks per reload
#ifndef GP_GT
#define GP_GT 0
#endif
#if GP_CORE1
// GP_CORE1 (default 0, M3.3.6.2.1.2.3.2): single-core utilization of the generic int8 tile kernel. Every core keeps
// a stats block in its own data memory (gp_c1st: magic, core id, chunks, total cycles, DMA-lock wait cycles);
// the host reads it after each launch over the array's AXI window and prints, twice,
//   CORE1 impl=aiehlc board=<GP_BOARD> dtype=<dt> basis=<dt>:<GP_PEAK>:<peak json> util_core=X.XX% worst=(pm,pn) ...
// window = total - wait (kernel cycles minus load_buffer / store_buffer lock waits); util_core = work /
// (window x GP_PEAK), work = M N K / 16 MAC per core per launch; per core the median over launches 2 .. L, worst
// of the 16 cores. The peak is the dtype's OWN measured MAC/cyc/core and comes only from -DGP_PEAK (C2): no default.
#ifndef GP_PEAK
#error "GP_CORE1=1 needs -DGP_PEAK=<this dtype's measured peak, MAC/cyc/core> (int8: tasks/gemm90/peak_int8.json, bf16: tasks/gemm90/peak.json)"
#endif
#if GP_DTYPE != 1
#error "GP_CORE1: the stats block is in the generic int8 tile kernel only (GP_DTYPE 1)"
#endif
// int8 peak above the bf16 kernel's 256 MAC/cyc ceiling: a bf16 peak given with an int8 build is refused
static_assert((double)(GP_PEAK) > 256.0 && (double)(GP_PEAK) <= 512.0,
              "GP_PEAK: int8 needs the int8 measured peak (tasks/gemm90/peak_int8.json), 256 < peak <= 512");
static_assert(!(GP_TM == 64 && GP_TN == 64 && GP_KC == 128),
              "GP_CORE1: the generic int8 tile kernel only (not the hand-scheduled 64 x 64 x 128 K4 kernel)");
#ifndef GP_BOARD
#define GP_BOARD unset
#endif
#define GP_C1_STR2(x) #x
#define GP_C1_STR(x) GP_C1_STR2(x)
#define GP_C1_WORDS 8
#define GP_C1_MAGIC 0x6790c0deu
#endif
#define KA_TM GP_TM
#define KA_TN GP_TN
#define KA_KC GP_KC
#define K4_KC GP_KC
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
// launches when its slice fits. When it does not, B is chunked along K through a MemTile ring instead
// ({.stage = memtile_ring, .ring = GP_B_RING}: GP_B_RING one-chunk buffers per (strip, parity) it serves,
// refilled every launch).
#define GP_MT_BYTES (512 * 1024)
#define GP_A_RING_BYTES (GP_RING * 2 * KA_TM * KA_KC)
#define GP_B_SLICE_BYTES (KA_N / GP_HW_COLS * KA_K)
#ifndef GP_B_RING
#if GP_B_SLICE_BYTES <= GP_MT_BYTES
#define GP_B_RING 0
#else
#define GP_B_RING 4
#endif
#endif
#define GP_B_STRIPS (KA_N / GP_HW_COLS / KA_TN)
#define GP_B_RING_BYTES (GP_B_RING * GP_B_STRIPS * 2 * KA_TN * KA_KC)
#define GP_B_MT_BYTES (GP_B_RING ? GP_B_RING_BYTES : GP_B_SLICE_BYTES)
#ifndef GP_KEEP
#if GP_B_SLICE_BYTES <= GP_MT_BYTES && GP_B_RING == 0
#define GP_KEEP true
#else
#define GP_KEEP false
#endif
#endif

// Core data memory (AIE-ML v2: 64 KB per core). Statics: the KA_TM x KA_TN x 4 B partial-sum tile (int8 acc,
// bf16 facc), the output window's GP_C_DEPTH slots, the hosted input stream's slots (GP_CORE_S2MM channels x
// 2 slots x one chunk of the larger operand) and the stack + runtime state (GP_DM_FIXED) -- the costmodel's
// FEAS DM formula. The output tile goes out as
// GP_C_SPLIT row slices of GP_C_ROWS rows: 1 when that fits, else 2 -- bf16's output tile is twice int8's,
// so its whole-tile slots do not fit next to the fp32 partials. The C bytes in DDR are the same either way
// (a tile is [8-row block][8-col block][8 x 8], so row slice h is the h-th contiguous part of it).
#define GP_DM_BYTES (64 * 1024)
#ifndef GP_DM_FIXED
#define GP_DM_FIXED 8192
#endif
#define GP_CORE_S2MM 2
#define GP_ACC_BYTES (KA_TM * KA_TN * 4)
#define GP_IN_BYTES (GP_CORE_S2MM * 2 * (KA_TM > KA_TN ? KA_TM : KA_TN) * KA_KC)
#define GP_OUT_TILE_BYTES (KA_TM * KA_TN * GP_ES)
#ifndef GP_C_SPLIT
#if GP_DM_FIXED + GP_ACC_BYTES + GP_IN_BYTES + GP_C_DEPTH * GP_OUT_TILE_BYTES <= GP_DM_BYTES
#define GP_C_SPLIT 1
#else
#define GP_C_SPLIT 2
#endif
#endif
#define GP_C_ROWS (KA_TM / GP_C_SPLIT)
#define GP_DM_USED (GP_DM_FIXED + GP_ACC_BYTES + GP_IN_BYTES + GP_C_DEPTH * GP_OUT_TILE_BYTES / GP_C_SPLIT)

#if GP_DTYPE != 1 && GP_DTYPE != 2
#error "GP_DTYPE: 1 = int8, 2 = bf16"
#endif
static_assert(GP_TM % 16 == 0 && GP_TN % 16 == 0, "GP_TM / GP_TN: whole 16-row accumulator pairs");
static_assert(GP_KC % 8 == 0 && GP_KCE % 8 == 0, "GP_KC: whole 8-deep k blocks");
static_assert(GP_GT >= 0 && GP_GT <= 4 && ((GP_GT != 2 && GP_GT != 4) || (GP_K / GP_KCE) % 2 == 0),
              "GP_GT: 0 .. 4 (2 / 4: an even number of K chunks)");
static_assert(GP_GT < 3 || GP_TN % 32 == 0, "GP_GT 3 / 4: KA_TN % 32 == 0 (pair columns walked in X / Y steps)");
static_assert(GP_C_DEPTH == 1 || GP_C_DEPTH == 2, "GP_C_DEPTH: 1 (one output buffer) or 2 (ping-pong)");
static_assert(GP_C_DEPTH == 2 || (GP_DTYPE == 1 && !(KA_TM == 64 && KA_TN == 64 && KA_KC == 128)),
              "GP_C_DEPTH 1: the generic int8 tile kernel only (GT_CHUNK)");
static_assert(GP_M % (GP_HW_ROWS * KA_TM) == 0, "GP_M: whole GP_TM-row tiles on every mesh row");
static_assert(KA_M == GP_M && KA_N == GP_N, "shape must split into the 2 x 8 strips exactly");
static_assert(SH_NT2 == 1, "2 x 8 layout: N = 2 x mesh columns x GP_TN (one B tile per core)");
static_assert(GP_K % GP_KCE == 0 && KA_K % KA_KC == 0, "K % KC == 0 (whole chunks)");
static_assert(GP_RING_CHUNKS % (2 * GP_RING) == 0, "A ring must divide the chunk stream (tiles x K chunks)");
static_assert(SH_NK >= 2, "the chunk pipeline needs at least 2 K chunks");
static_assert(SH_TILES >= 1 && SH_TILES <= 64, "tiles / core <= 64 (6-bit OOO iteration counter)");
static_assert(GP_B_MT_BYTES <= GP_MT_BYTES, "B's MemTile buffers (whole slice, or GP_B_RING ring) must fit its 512 KiB MemTile");
static_assert(!(GP_B_RING && GP_KEEP), "a MemTile ring (GP_B_RING) is refilled every launch: no GP_KEEP");
static_assert(GP_A_RING_BYTES <= GP_MT_BYTES, "A's ring must fit its MemTile");
static_assert(GP_LAUNCHES >= 2, "GP_LAUNCHES >= 2 (launch 1 loads the kernel)");
static_assert(GP_C_SPLIT == 1 || (GP_C_SPLIT == 2 && (GP_DTYPE == 2 || !(KA_TM == 64 && KA_TN == 64 && KA_KC == 128))),
              "GP_C_SPLIT: 1, or 2 (bf16 kernel, or the generic int8 tile kernel)");
static_assert(KA_TM >= 32 && KA_TM <= 128, "the generic int8 tile kernel declares at most 16 partial-sum 8-row blocks (GT_ACC_DECL)");
static_assert(GP_C_ROWS % 16 == 0, "an output row slice is whole 2 x 8-row block pairs");
static_assert(GP_DM_USED <= GP_DM_BYTES, "core DM (64 KiB): fixed + partial sums + input slots + output slots must fit");

// AIEHLC_KERNEL_PROLOGUE_BEGIN
#include "gemm_plan_tile.h"
#include "gemm_plan_gt.h"
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
        .depth = 2, .share = aie::share::neighbor, .stage = aie::stage::memtile_ring, .ring = GP_RING,                 \
        .parts = GP_PARTS, .align = 64                                                                                 \
    }
#if GP_B_RING /* B chunked along K through a MemTile ring (its slice does not fit a MemTile) */
#define OPTS_B                                                                                                         \
    {.depth = 2,                                                                                                       \
     .share = aie::share::neighbor,                                                                                    \
     .stage = aie::stage::memtile_ring,                                                                                \
     .ring = GP_B_RING,                                                                                                \
     .parts = GP_PARTS,                                                                                                \
     .align = 64}
#else
#define OPTS_B                                                                                                         \
    {.depth = 2,                                                                                                       \
     .share = aie::share::neighbor,                                                                                    \
     .stage = aie::stage::memtile,                                                                                     \
     .keep = GP_KEEP,                                                                                                  \
     .parts = GP_PARTS,                                                                                                \
     .align = 64}
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
#if GP_DTYPE == 1 && GP_K4_TILE /* the hand-scheduled 64 x 64 x 128 tile (gemm_plan_tile.h K4_* / SH_*) */
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
#if GP_DTYPE == 1
    // int8, any other tile (GP_TM x GP_TN x GP_KC): per chunk, GT_CHUNK (gemm_plan_tile.h) walks the
    // (KA_TM / 16) x (KA_TN / 16) pairs of 2 x 2 accumulators; int32 partial sums in core memory between chunks
    // (one array per 8-row block), int8 out at the last chunk in GP_C_SPLIT row slices of GP_C_ROWS rows. Same
    // ports, options (A / B neighbour-shared) and 2 x 8 grid as the 64 x 64 kernel.
    typedef aie::mmul<8, 8, 8, int8_t, int8_t> KaMM4;
    const int pm = aie::program_id(0), pn = aie::program_id(1);
    const int sa = pm >> 1, sb = pn + GP_HW_COLS * (pm & 1), brow = sb * KA_TN;
    GT_ACC_DECL(0)
    GT_ACC_DECL(1)
    GT_ACC_DECL(2)
    GT_ACC_DECL(3)
#if KA_TM > 32
    GT_ACC_DECL(4)
    GT_ACC_DECL(5)
#endif
#if KA_TM > 48
    GT_ACC_DECL(6)
    GT_ACC_DECL(7)
#endif
#if KA_TM > 64
    GT_ACC_DECL(8)
    GT_ACC_DECL(9)
#endif
#if KA_TM > 80
    GT_ACC_DECL(10)
    GT_ACC_DECL(11)
#endif
#if KA_TM > 96
    GT_ACC_DECL(12)
    GT_ACC_DECL(13)
#endif
#if KA_TM > 112
    GT_ACC_DECL(14)
    GT_ACC_DECL(15)
#endif
#if GP_CORE1 && defined(__chess__)
    // CORE1 stats (the host reads them from this core's data memory after the launch). Timing rule: the cycle
    // counter is read after a volatile load from the block the lock ACQ just handed over, so the read cannot be
    // scheduled before the acquire completes. Wait sum in 32 bits (one launch waits far below 2^32 cycles).
    static volatile uint32_t gp_c1st[GP_C1_WORDS];
    unsigned int gp_c1_wait = 0, gp_c1_w0 = 0;
    const unsigned long long gp_c1_t0 = get_cycles();
#define GP_C1_T0() (gp_c1_w0 = (unsigned int)get_cycles())
#define GP_C1_ACQ(p) ((void)*(volatile const int8_t *)(p), gp_c1_wait += (unsigned int)get_cycles() - gp_c1_w0)
#else
#define GP_C1_T0() ((void)0)
#define GP_C1_ACQ(p) ((void)0)
#endif
    int32_t *const accp[KA_TM / 8] = {acc0, acc1, acc2, acc3
#if KA_TM > 32
                                      , acc4, acc5
#endif
#if KA_TM > 48
                                      , acc6, acc7
#endif
#if KA_TM > 64
                                      , acc8, acc9
#endif
#if KA_TM > 80
                                      , acc10, acc11
#endif
#if KA_TM > 96
                                      , acc12, acc13
#endif
#if KA_TM > 112
                                      , acc14, acc15
#endif
    };
#if GP_GT == 0
    for (int t = 0; t < SH_TILES; t++) {
        const int arow = sa * (KA_M / 2) + t * KA_TM;
        for (int k = 0; k < SH_NK; k++) {
            GP_C1_T0();
            auto xa = aie::load_buffer(a, {arow, k * KA_KC}, {KA_TM, KA_KC}, OPTS_A);
            auto xb = aie::load_buffer(b, {brow, k * KA_KC}, {KA_TN, KA_KC}, OPTS_B);
            const int8_t *a0p = GT_PART(xa, 0, KA_TM), *a1p = GT_PART(xa, 1, KA_TM);
            const int8_t *b0p = GT_PART(xb, 0, KA_TN), *b1p = GT_PART(xb, 1, KA_TN);
            GP_C1_ACQ(b1p);
            for (int h = 0; h < GP_C_SPLIT; h++) {
                const int m0 = h * (GP_C_ROWS / 8), m1 = (h + 1) * (GP_C_ROWS / 8);
                int8_t *__restrict y = nullptr;
                if (k == SH_NK - 1) {
                    GP_C1_T0();
                    y = aie::store_buffer(c, {arow + h * GP_C_ROWS, brow}, {GP_C_ROWS, KA_TN}, GT_C_OPTS);
                    GP_C1_ACQ(y);
                }
                GT_CHUNK(accp, y, m0, a0p, a1p, b0p, b1p, k == 0, k == SH_NK - 1, m0, m1);
                if (k == SH_NK - 1)
                    aie::commit(c);
            }
            aie::release(a);
            aie::release(b);
        }
    }
#else
    // GP_GT 1 .. 4: the K walk peeled into first chunk step / middle loop / last chunk step, each with its own
    // compile-time chunk kind (no chunk-kind branch left in the kernel). A step takes GT_NS chunks: with 2 (GP_GT 2 / 4)
    // chunk k + 1 is acquired before chunk k is released (both input slots), one partial-sum round trip per 2 chunks.
#if GP_GT == 2 || GP_GT == 4
#define GT_NS 2
#else
#define GT_NS 1
#endif
#if GP_GT == 4 || GP_GT == 3
#define GT_CALL(fi, la) GT_CHUNK_K(accp, y, m0, a0p, a1p, b0p, b1p, a0q, a1q, b0q, b1q, fi, la, m0, m1, GT_NS)
#elif GP_GT == 2
#define GT_CALL(fi, la) GT_CHUNK_P2(accp, y, m0, a0p, a1p, b0p, b1p, a0q, a1q, b0q, b1q, fi, la, m0, m1, 2)
#else
#define GT_CALL(fi, la) GT_CHUNK_P(accp, y, m0, a0p, a1p, b0p, b1p, fi, la, m0, m1)
#endif
#if GT_NS == 2
#define GT_ACQ2(k_)                                                                                                    \
    auto xa2 = aie::load_buffer(a, {arow, ((k_) + 1) * KA_KC}, {KA_TM, KA_KC}, OPTS_A);                                \
    auto xb2 = aie::load_buffer(b, {brow, ((k_) + 1) * KA_KC}, {KA_TN, KA_KC}, OPTS_B);                                \
    const int8_t *a0q = GT_PART(xa2, 0, KA_TM), *a1q = GT_PART(xa2, 1, KA_TM);                                         \
    const int8_t *b0q = GT_PART(xb2, 0, KA_TN), *b1q = GT_PART(xb2, 1, KA_TN);
#define GT_REL2()                                                                                                      \
    aie::release(a);                                                                                                   \
    aie::release(b);
#else
#define GT_ACQ2(k_)                                                                                                    \
    const int8_t *a0q = a0p, *a1q = a1p, *b0q = b0p, *b1q = b1p;
#define GT_REL2()
#endif
#define GT_STEP(kk, fi, la)                                                                                            \
    {                                                                                                                  \
        const int k_ = (kk);                                                                                           \
        GP_C1_T0();                                                                                                    \
        auto xa = aie::load_buffer(a, {arow, k_ * KA_KC}, {KA_TM, KA_KC}, OPTS_A);                                     \
        auto xb = aie::load_buffer(b, {brow, k_ * KA_KC}, {KA_TN, KA_KC}, OPTS_B);                                     \
        const int8_t *a0p = GT_PART(xa, 0, KA_TM), *a1p = GT_PART(xa, 1, KA_TM);                                       \
        const int8_t *b0p = GT_PART(xb, 0, KA_TN), *b1p = GT_PART(xb, 1, KA_TN);                                       \
        GP_C1_ACQ(b1p);                                                                                                \
        GT_ACQ2(k_)                                                                                                    \
        (void)a0q, (void)a1q, (void)b0q, (void)b1q;                                                                    \
        for (int h = 0; h < GP_C_SPLIT; h++) {                                                                         \
            const int m0 = h * (GP_C_ROWS / 8), m1 = (h + 1) * (GP_C_ROWS / 8);                                        \
            int8_t *__restrict y = nullptr;                                                                            \
            if (la) {                                                                                                  \
                GP_C1_T0();                                                                                            \
                y = aie::store_buffer(c, {arow + h * GP_C_ROWS, brow}, {GP_C_ROWS, KA_TN}, GT_C_OPTS);                 \
                GP_C1_ACQ(y);                                                                                          \
            }                                                                                                          \
            GT_CALL(fi, la)                                                                                            \
            if (la)                                                                                                    \
                aie::commit(c);                                                                                        \
        }                                                                                                              \
        aie::release(a);                                                                                               \
        aie::release(b);                                                                                               \
        GT_REL2()                                                                                                      \
    }
    static_assert(SH_NK >= 2 * GT_NS && SH_NK % GT_NS == 0, "GP_GT 1 .. 4: at least two K steps of GT_NS chunks");
    for (int t = 0; t < SH_TILES; t++) {
        const int arow = sa * (KA_M / 2) + t * KA_TM;
        GT_STEP(0, 1, 0)
        for (int k = GT_NS; k < SH_NK - GT_NS; k += GT_NS)
            chess_loop_range(1, ) GT_STEP(k, 0, 0)
        GT_STEP(SH_NK - GT_NS, 0, 1)
    }
#undef GT_STEP
#undef GT_ACQ2
#undef GT_REL2
#undef GT_CALL
#undef GT_NS
#endif
#if GP_CORE1 && defined(__chess__)
    {
        const unsigned long long tot = get_cycles() - gp_c1_t0;
        gp_c1st[1] = (uint32_t)(pm * GP_HW_COLS + pn);
        gp_c1st[2] = (uint32_t)(SH_TILES * SH_NK);
        gp_c1st[3] = (uint32_t)(tot & 0xffffffffULL);
        gp_c1st[4] = (uint32_t)(tot >> 32);
        gp_c1st[5] = gp_c1_wait;
        gp_c1st[6] = gp_c1st[6] + 1u;
        gp_c1st[7] = ~GP_C1_MAGIC;
        gp_c1st[0] = GP_C1_MAGIC;
    }
#endif
#else
    // bf16 (correctness first, as peak_bf16.cc): plain aie::mmul<8, 8, 8, bfloat16, bfloat16, accfloat>
    // 2 x 2 blocks over the 64 x 64 tile, fp32 partial sums in core memory between chunks, bf16 out at
    // the last chunk. Same ports, chunks and dataflow as int8 (KA_KC bytes = GP_KCE elements of K).
    typedef aie::mmul<8, 8, 8, bfloat16, bfloat16, accfloat> BfMM;
    const int pm = aie::program_id(0), pn = aie::program_id(1);
    const int sa = pm >> 1, sb = pn + GP_HW_COLS * (pm & 1), brow = sb * KA_TN;
    alignas(8192) static float facc[KA_TM * KA_TN];
#if GP_PARTS == 2
#define BF_PART(x, i) ((const bfloat16 *)(x).part(i))
#else
#define BF_PART(x, i) ((const bfloat16 *)(x) + (i) * (KA_TM / 2 * GP_KCE))
#endif
// 8 x 8 operand block (row block r of the chunk, k block kb): row blocks 0 .. 3 in part 0, 4 .. 7 in part 1
#define BF_OP(p0, p1, r, kb) (((r) / (KA_TM / 16) ? (p1) : (p0)) + (((r) % (KA_TM / 16)) * (GP_KCE / 8) + (kb)) * 64)
    for (int t = 0; t < SH_TILES; t++) {
        const int arow = sa * (KA_M / 2) + t * KA_TM;
        for (int k = 0; k < SH_NK; k++) {
            auto xa = aie::load_buffer(a, {arow, k * KA_KC}, {KA_TM, KA_KC}, OPTS_A);
            auto xb = aie::load_buffer(b, {brow, k * KA_KC}, {KA_TN, KA_KC}, OPTS_B);
            const bfloat16 *a0p = BF_PART(xa, 0), *a1p = BF_PART(xa, 1);
            const bfloat16 *b0p = BF_PART(xb, 0), *b1p = BF_PART(xb, 1);
            for (int h = 0; h < GP_C_SPLIT; h++) {
                // the last chunk writes row slice h of the output tile (GP_C_ROWS rows) straight out
                bfloat16 *__restrict y = nullptr;
                if (k == SH_NK - 1)
                    y = (bfloat16 *)aie::store_buffer(c, {arow + h * GP_C_ROWS, brow * GP_ES},
                                                      {GP_C_ROWS, KA_TN * GP_ES}, {.align = 64});
                for (int mi = h * (GP_C_ROWS / 8); mi < (h + 1) * (GP_C_ROWS / 8); mi += 2)
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
                        bfloat16 *o = y + ((mi - h * (GP_C_ROWS / 8)) * (KA_TN / 8) + ni) * 64;
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
                if (k == SH_NK - 1)
                    aie::commit(c);
            }
            aie::release(a);
            aie::release(b);
        }
    }
#endif
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
    aieMesh mesh = device.partition({2, 2 + GP_HW_COLS, 0, 6}, GP_HW_ROWS, GP_HW_COLS);
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

#if GP_CORE1
// CORE1 host side: the 16 cores are the kernel group's tiles, partition columns GP_C1_COL0 .. +GP_HW_COLS - 1, rows
// GP_C1_ROW0 .. +GP_HW_ROWS - 1 (host.cc's host_canonicalized: cols 1..4, rows 3..6); which core is which comes
// from the id word, not from the position. The stats block's data-memory offset is found once (after launch 1) by
// scanning the tile's 64 KiB for magic .. ~magic; before every later launch the host clears the magic word and
// after it waits for the core to write it again (so a launch's numbers are never a previous launch's).
#ifndef GP_C1_COL0
#define GP_C1_COL0 1
#endif
#ifndef GP_C1_ROW0
#define GP_C1_ROW0 3
#endif
#define GP_C1_CORES (GP_HW_ROWS * GP_HW_COLS)
#define GP_C1_DM_BYTES 0x10000u
static unsigned long long gp_c1_tot[GP_LAUNCHES][GP_C1_CORES], gp_c1_win[GP_LAUNCHES][GP_C1_CORES];
static long gp_c1_off[GP_C1_CORES];
static int gp_c1_tile[GP_C1_CORES]; // core id -> tile index (partition col GP_C1_COL0 + ti % cols, row GP_C1_ROW0 + ti / cols)
static int gp_c1_bad;
#if defined(__aarch64__) && !defined(__AIESIM__) && !defined(__linux__)
#define GP_C1_HW 1
static uint32_t gp_c1_rd(int ti, uint32_t off) {
    u32 w = 0;
    XAie_DataMemRdWord(__Runtime_get_partition_dev(0),
                       XAie_TileLoc(GP_C1_COL0 + ti % GP_HW_COLS, GP_C1_ROW0 + ti / GP_HW_COLS), off, &w);
    return (uint32_t)w;
}
static void gp_c1_wr(int ti, uint32_t off, uint32_t v) {
    XAie_DataMemWrWord(__Runtime_get_partition_dev(0),
                       XAie_TileLoc(GP_C1_COL0 + ti % GP_HW_COLS, GP_C1_ROW0 + ti / GP_HW_COLS), off, v);
}
#endif
// PROFILING=1 (aiehlc.sh --profiling -> -DAIEHLC_PROFILING=1): the runtime arms the 4 core perf counters
// (ACTIVE, INSTR_VECTOR, STREAM_STALL, LOCK_STALL) on the 16 cores at launch 1 when g_runtime_debug_level has
// AIE_DEBUG_FLAG_CORE_PERF_COUNTER (0x100); the persistent kernel is not re-armed later, so the host zeroes them
// before the last launch and prints one [PERF] tag=<last launch index> line per core after it (one launch,
// for perfsplit.py --xchk: active - lock_stall of the worst core vs its CORE1 window).
#if defined(AIEHLC_PROFILING) && AIEHLC_PROFILING
#define GP_C1_PERF 1
extern int g_runtime_debug_level;
void __Runtime_core_perf_report(int tag);
static void gp_c1_perf_zero(void) {
#ifdef GP_C1_HW
    for (int ti = 0; ti < GP_C1_CORES; ti++)
        for (uint8_t c = 0; c < 4; c++)
            XAie_PerfCounterSet(__Runtime_get_partition_dev(0),
                                XAie_TileLoc(GP_C1_COL0 + ti % GP_HW_COLS, GP_C1_ROW0 + ti / GP_HW_COLS), XAIE_CORE_MOD,
                                c, 0);
#endif
}
#endif
// before launch `it` (> 0): clear every found block's magic word
static void gp_c1_arm(int it) {
#ifdef GP_C1_HW
    for (int ti = 0; it > 0 && ti < GP_C1_CORES; ti++)
        if (gp_c1_off[ti] >= 0)
            gp_c1_wr(ti, (uint32_t)gp_c1_off[ti], 0u);
#else
    (void)it;
#endif
}
// after launch `it`: read the 16 blocks (launch 0: find them first)
static void gp_c1_collect(int it) {
    for (int ti = 0; ti < GP_C1_CORES; ti++) {
        uint32_t st[GP_C1_WORDS] = {0};
#ifdef GP_C1_HW
        if (it == 0) {
            gp_c1_off[ti] = -1;
            for (uint32_t o = 0; o + 4 * GP_C1_WORDS <= GP_C1_DM_BYTES && gp_c1_off[ti] < 0; o += 4)
                if (gp_c1_rd(ti, o) == GP_C1_MAGIC && gp_c1_rd(ti, o + 4 * (GP_C1_WORDS - 1)) == ~GP_C1_MAGIC)
                    gp_c1_off[ti] = (long)o;
        }
        if (gp_c1_off[ti] >= 0) {
            for (int p = 0; p < 100000 && gp_c1_rd(ti, (uint32_t)gp_c1_off[ti]) != GP_C1_MAGIC; p++)
                ;
            for (int w = 0; w < GP_C1_WORDS; w++)
                st[w] = gp_c1_rd(ti, (uint32_t)gp_c1_off[ti] + 4u * w);
        }
#else
        gp_c1_off[ti] = -1;
#endif
        const unsigned long long t = (unsigned long long)st[3] | ((unsigned long long)st[4] << 32), w = st[5];
        const int q = (int)st[1];
        if (gp_c1_off[ti] < 0 || st[0] != GP_C1_MAGIC || st[7] != ~GP_C1_MAGIC || q < 0 || q >= GP_C1_CORES ||
            st[2] != (uint32_t)(SH_TILES * SH_NK) || t == 0 || w >= t) {
            if (gp_c1_bad < 8)
                printf("[core1] BAD stats launch %d tile %d: off=%ld magic=%08x id=%d chunks=%u tot=%llu wait=%llu\n",
                       it + 1, ti, gp_c1_off[ti], (unsigned)st[0], q, (unsigned)st[2], t, w);
            gp_c1_bad++;
            continue;
        }
        gp_c1_tile[q] = ti;
        gp_c1_tot[it][q] = t;
        gp_c1_win[it][q] = t - w;
    }
}
static int gp_c1_cmp(const void *x, const void *y) {
    const unsigned long long a = *(const unsigned long long *)x, b = *(const unsigned long long *)y;
    return a < b ? -1 : (a > b ? 1 : 0);
}
// per core: median over launches 2 .. L of window and total; CORE1 = the worst core's util_core
static void gp_c1_report(void) {
    const int n = GP_LAUNCHES - 1;
    const double work = (double)GP_M * GP_N * GP_K / GP_C1_CORES, peak = (double)(GP_PEAK);
    double worst = 1e30;
    int wq = 0;
    unsigned long long wwin = 0, wtot = 0;
    for (int q = 0; q < GP_C1_CORES; q++) {
        unsigned long long sw[GP_LAUNCHES], stt[GP_LAUNCHES];
        for (int l = 0; l < n; l++) {
            sw[l] = gp_c1_win[l + 1][q];
            stt[l] = gp_c1_tot[l + 1][q];
        }
        qsort(sw, n, sizeof(sw[0]), gp_c1_cmp);
        qsort(stt, n, sizeof(stt[0]), gp_c1_cmp);
        const double u = sw[n / 2] ? work / ((double)sw[n / 2] * peak) : 0.0;
        printf("[core1] core(%d,%d) median of launches 2..%d: window %llu cyc total %llu cyc -> util_core %.2f%%\n",
               q / GP_HW_COLS, q % GP_HW_COLS, GP_LAUNCHES, sw[n / 2], stt[n / 2], 100.0 * u);
        if (u < worst) {
            worst = u;
            wq = q;
            wwin = sw[n / 2];
            wtot = stt[n / 2];
        }
    }
    for (int rep = 0; rep < 2; rep++) { // twice: the PLM console can swallow a line
        printf("CORE1 impl=aiehlc board=%s dtype=%s basis=%s:%.2f:%s util_core=%.2f%% worst=(%d,%d) "
               "(worst of 16 cores = (%d,%d)) worst_tile=(%d,%d) window_cyc=%llu total_cyc=%llu work=%.0f launches=%d tile=tm%d_tn%d kc=%d "
               "stats_bad=%d\n",
               GP_C1_STR(GP_BOARD), gpref_dtype(GP_REF_DTYPE), gpref_dtype(GP_REF_DTYPE), peak,
               GP_DTYPE == 1 ? "maxwell/tasks/gemm90/peak_int8.json" : "maxwell/tasks/gemm90/peak.json",
               100.0 * worst, wq / GP_HW_COLS, wq % GP_HW_COLS, wq / GP_HW_COLS, wq % GP_HW_COLS,
               GP_C1_COL0 + gp_c1_tile[wq] % GP_HW_COLS, GP_C1_ROW0 + gp_c1_tile[wq] / GP_HW_COLS, wwin, wtot, work,
               GP_LAUNCHES, KA_TM, KA_TN, KA_KC, gp_c1_bad);
        fflush(stdout);
    }
}
#endif
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
#if GP_CORE1
        gp_c1_arm(it);
#ifdef GP_C1_PERF
        if (it == 0)
            g_runtime_debug_level |= 0x100; // AIE_DEBUG_FLAG_CORE_PERF_COUNTER: armed by the launch-1 kernel start
        if (it == launches - 1)
            gp_c1_perf_zero();
#endif
#endif
        XTime t0, t1;
        XTime_GetTime(&t0);
        gemm_ka_run(A2, B2, Ct);
        XTime_GetTime(&t1);
        lms[it] = gp_ms(t0, t1);
#if GP_CORE1
        gp_c1_collect(it);
#ifdef GP_C1_PERF
        if (it == launches - 1)
            __Runtime_core_perf_report(it);
#endif
#endif
        if (it == 0) { // the array is up and clocked: measure its clock
            aie_clk = gp_aie_clock();
            printf("GPLAN where=%s dtype=%s shape=%ldx%ldx%ld aie_mhz=%.1f clk_src=%s\n", "board", dts, M, N, K, aie_clk,
                   aie_clk > 0 ? "shim_timer/cntpct" : "none");
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
    Xil_DCacheInvalidateRange((UINTPTR)Ct, cbytes);
    gp_got_ctx gx = {(const gp_elem_t *)Ct, 0xFFFFFFFFu};
    const gpref_res_t r = gpref_check(GP_REF_DTYPE, A, B, M, N, K, gp_got, &gx);
    const uint32_t out_crc = gx.crc ^ 0xFFFFFFFFu;
    if (r.bad)
        printf("MISMATCH first C[%ld][%ld]: got %d want %d (rule %s)\n", r.first_bad_i, r.first_bad_j, (int)r.first_got,
               (int)r.first_want, gpref_rule(GP_REF_DTYPE));
#if GP_CORE1
    gp_c1_report();
#endif
    printf("GOLDEN %s shape=%ldx%ldx%ld dtype=%s launch=%d checked=%ld bad=%ld in_crc=%08x ref_crc=%08x out_crc=%08x\n", r.pass ? "PASS" : "FAIL", M, N, K, dts, launches, r.checked, r.bad, (unsigned)in_crc, (unsigned)r.ref_crc, (unsigned)out_crc);
    return r.pass ? 0 : 1;
}
