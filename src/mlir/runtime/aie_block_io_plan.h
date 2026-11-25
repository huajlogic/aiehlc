/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
// The block-load API (aie::load_buffer / release / store_buffer / commit) on a dataflow plan's
// NEIGHBOUR-SHARED operands (load_buffer {.share = aie::share::neighbor}; doc/design/dmaphop_dataflow_plan.md).
// Included by aie_block_io.h when the generated aiehlc_plan.h defines AIEHLC_PLAN_SHARED, so the kernel
// source stays the plain block-load kernel (no locks, no addresses, no #ifdef __chess__). Every view, lock
// id and buffer offset below is a constant of the plan (AIEHLC_PLAN_*), allocated by the compiler
// (planresource.cpp) -- none is written here.
//
// What a load means here. Each shared operand stream is hosted in ONE core's memory; that core and its
// neighbours read it through their own / north / south memory view (AIEHLC_PLAN_VIEW(o, pm)), on the host
// tile's locks (bias AIEHLC_PLAN_LOCK(o, pm)). The protocol is the plan's (dmaphop.plan_stream channels /
// slots / readers / parts, all AIEHLC_PLAN_* constants): chunk g arrives on channel ch = g mod CHANNELS
// into buffer b = g mod BUFFERS (BUFFERS = CHANNELS x SLOTS); part i of it is at
// SLOT_LO + b SLOT_STRIDE + i PART_STRIDE (x.part(i) of a {.parts = n} block). Locks, relative to the bias:
//   LOCK_F + i HAND_DELTA + ch     reader i's turn (i = AIEHLC_PLAN_READER(o, pm); the DMA releases i = 0)
//   LOCK_F + READERS HAND_DELTA + ch   the no-op row (held at 0)
//   LOCK_E + b                     every reader -> DMA (it acquires READERS)
// Reader i acquires its lock and releases the one HAND_DELTA above -- reader i + 1's, or (the last) the
// no-op lock by 0 -- branch-free. The order of loads and releases is the kernel's: taking the next chunk
// before giving the current one back is what overlaps a chunk boundary with compute.
//
// Which operand a call is about: aiehlc_plan_operand(desc), emitted by the pipeline after the port
// descriptors (index into the plan's shared operands, -1 = not shared). The block offsets are not checked
// on the core (the plan, not the block coordinates, decides what arrives); the x86 trace checks them.
#ifndef AIE_BLOCK_IO_PLAN_H
#define AIE_BLOCK_IO_PLAN_H

// Every entry point is forced inline: with static inline alone chess emitted the load as a function -- a
// call per load, and the descriptors as memory, so the operand choice was no longer folded at compile time
// (1.21 vs 1.17 ms per launch on the 2 x 8 GEMM).
#define AIEHLC_PLAN_INLINE static inline __attribute__((always_inline))

AIEHLC_PLAN_INLINE int aiehlc_plan_operand(const aiehlc_blk_desc &d);

AIEHLC_PLAN_INLINE uintptr_t aiehlc_plan_view(int o, int pm) { return (uintptr_t)AIEHLC_PLAN_VIEW(o, pm); }
AIEHLC_PLAN_INLINE int aiehlc_plan_lockbase(int o, int pm) { return (int)AIEHLC_PLAN_LOCK(o, pm); }
AIEHLC_PLAN_INLINE int aiehlc_plan_reader(int o, int pm) { return (int)AIEHLC_PLAN_READER(o, pm); }

// Per-core copies (AIEHLC_PLAN_COPY; load_buffer {.share = aie::share::broadcast}): every core holds its own
// copy of each such operand's stream, on the operand's own S2MM channel, `OP_SLOTS(o)` buffers of one chunk
// OP_SLOT_STRIDE apart from OP_SLOT_LO (part i of a {.parts = n} chunk at + i OP_PART_STRIDE). The DMA
// releases the operand's counting lock OP_F once per chunk; the kernel gives each buffer back on its E lock
// (OP_E + slot). One reader, so no hand-on and no tile sync.
#if defined(AIEHLC_PLAN_COPY)
template <typename W>
AIEHLC_PLAN_INLINE aiehlc_block_ptr aiehlc_load_buffer(W *win, const aiehlc_blk_desc &d, aiehlc_blk_cursor &cur, int pm,
                                                       int p1, aiehlc_blk off, aiehlc_blk shape, int parts = 1) {
    const int o = aiehlc_plan_operand(d);
    if (o < 0) /* not a planned operand: its generated window */
        return aiehlc_window_load(win, d, cur, pm, p1, off, shape, parts);
    const unsigned g = (unsigned)cur.n++;
    acquire_greater_equal(aiehlc_plan_lockbase(o, pm) + (int)AIEHLC_PLAN_OP_F(o, pm), 1);
    chess_memory_fence();
    return {(int8_t *)(aiehlc_plan_view(o, pm) + AIEHLC_PLAN_OP_SLOT_LO(o, pm) +
                       (g % (unsigned)AIEHLC_PLAN_OP_SLOTS(o, pm)) * AIEHLC_PLAN_OP_SLOT_STRIDE(o, pm)),
            (long)AIEHLC_PLAN_OP_PART_STRIDE(o, pm)};
}
template <typename W>
AIEHLC_PLAN_INLINE void aiehlc_release(W *win, const aiehlc_blk_desc &d, aiehlc_blk_cursor &cur, int pm, int) {
    const int o = aiehlc_plan_operand(d);
    if (o < 0) {
        cur.r++;
        release_input_window(win);
        return;
    }
    const unsigned r = (unsigned)cur.r++;
    chess_memory_fence();
    release(aiehlc_plan_lockbase(o, pm) + (int)AIEHLC_PLAN_OP_E(o, pm) +
                (int)(r % (unsigned)AIEHLC_PLAN_OP_SLOTS(o, pm)),
            1);
}
template <typename W>
AIEHLC_PLAN_INLINE aiehlc_block_ptr aiehlc_store_buffer(W *win, const aiehlc_blk_desc &, aiehlc_blk_cursor &, int, int,
                                                        aiehlc_blk, aiehlc_blk) {
    return {(int8_t *)acquire_output_window(win), 0};
}
template <typename W>
AIEHLC_PLAN_INLINE void aiehlc_commit(W *win, const aiehlc_blk_desc &, aiehlc_blk_cursor &cur, int, int) {
    cur.r++;
    release_output_window(win);
}
#else // neighbour-hosted streams
// Chunk g's channel and buffer: one AND when the counts are powers of two (the constants fold).
AIEHLC_PLAN_INLINE int aiehlc_plan_ch(unsigned g) {
    return (AIEHLC_PLAN_CHANNELS & (AIEHLC_PLAN_CHANNELS - 1)) == 0 ? (int)(g & (AIEHLC_PLAN_CHANNELS - 1))
                                                                    : (int)(g % AIEHLC_PLAN_CHANNELS);
}
AIEHLC_PLAN_INLINE unsigned aiehlc_plan_buffer(unsigned g) {
    return (AIEHLC_PLAN_BUFFERS & (AIEHLC_PLAN_BUFFERS - 1)) == 0 ? g & (AIEHLC_PLAN_BUFFERS - 1)
                                                                  : g % AIEHLC_PLAN_BUFFERS;
}

// A load: reader i takes its turn lock and hands on HAND_DELTA above (reader i + 1, or the no-op by 0).
template <typename W>
AIEHLC_PLAN_INLINE aiehlc_block_ptr aiehlc_load_buffer(W *win, const aiehlc_blk_desc &d, aiehlc_blk_cursor &cur, int pm,
                                                       int p1, aiehlc_blk off, aiehlc_blk shape, int parts = 1) {
    const int o = aiehlc_plan_operand(d);
    if (o < 0) /* not a shared operand: its generated window */
        return aiehlc_window_load(win, d, cur, pm, p1, off, shape, parts);
    const unsigned g = (unsigned)cur.n++;
    const int i = aiehlc_plan_reader(o, pm);
    const int acq =
        aiehlc_plan_lockbase(o, pm) + AIEHLC_PLAN_LOCK_F + i * AIEHLC_PLAN_LOCK_HAND_DELTA + aiehlc_plan_ch(g);
    acquire_greater_equal(acq, 1);
    release(acq + AIEHLC_PLAN_LOCK_HAND_DELTA, i < AIEHLC_PLAN_READERS - 1);
    chess_memory_fence();
    return {(int8_t *)(aiehlc_plan_view(o, pm) + AIEHLC_PLAN_SLOT_LO + aiehlc_plan_buffer(g) * AIEHLC_PLAN_SLOT_STRIDE),
            AIEHLC_PLAN_PART_STRIDE};
}
// Releases come in load order: the count says which buffer's E lock to give back.
template <typename W>
AIEHLC_PLAN_INLINE void aiehlc_release(W *win, const aiehlc_blk_desc &d, aiehlc_blk_cursor &cur, int pm, int) {
    const int o = aiehlc_plan_operand(d);
    if (o < 0) {
        cur.r++;
        release_input_window(win);
        return;
    }
    const unsigned r = (unsigned)cur.r++;
    chess_memory_fence();
    release(aiehlc_plan_lockbase(o, pm) + AIEHLC_PLAN_LOCK_E + (int)aiehlc_plan_buffer(r), 1);
}
// The output is the generated window (ping-pong, its own locks); only the block check is dropped.
template <typename W>
AIEHLC_PLAN_INLINE aiehlc_block_ptr aiehlc_store_buffer(W *win, const aiehlc_blk_desc &, aiehlc_blk_cursor &, int, int,
                                                        aiehlc_blk, aiehlc_blk) {
    return {(int8_t *)acquire_output_window(win), 0};
}
// Tile sync (AIEHLC_PLAN_LOCK_SYNC, on the streams of operand AIEHLC_PLAN_SYNC_OPERAND). A stream's readers
// run at the same speed, so nothing pulls them back together once apart; a follower lagging by about half
// a chunk reads the same bank half as the leader on every access (measured: 3x the bank conflicts, 1.265
// vs 1.17 ms per launch). So at the end of every output tile the leader (reader 0) waits for its followers
// to finish the same tile: each follower releases the host tile's sync lock (init 0) once, the leader takes
// READERS - 1. Two lock operations per tile; the other operand's readers are not synced (measured: no gain).
template <typename W>
AIEHLC_PLAN_INLINE void aiehlc_commit(W *win, const aiehlc_blk_desc &, aiehlc_blk_cursor &cur, int pm, int) {
    cur.r++;
    release_output_window(win);
#if defined(AIEHLC_PLAN_LOCK_SYNC) && AIEHLC_PLAN_SYNC_OPERAND >= 0 && AIEHLC_PLAN_READERS > 1
    const int lead = aiehlc_plan_reader(AIEHLC_PLAN_SYNC_OPERAND, pm) == 0;
    const int s = aiehlc_plan_lockbase(AIEHLC_PLAN_SYNC_OPERAND, pm) + AIEHLC_PLAN_LOCK_SYNC;
    const int nop = AIEHLC_PLAN_OWN_LOCK_BIAS + AIEHLC_PLAN_LOCK_F + AIEHLC_PLAN_READERS * AIEHLC_PLAN_LOCK_HAND_DELTA;
    release(lead ? nop : s, lead ? 0 : 1);
    acquire_greater_equal(lead ? s : nop, lead ? AIEHLC_PLAN_READERS - 1 : 0);
#else
    (void)pm;
#endif
}
#endif // AIEHLC_PLAN_COPY

#endif // AIE_BLOCK_IO_PLAN_H
