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
// What a load means here. Each shared operand stream is hosted in ONE core's memory; that core and a
// neighbour read it through their own / north / south memory view (AIEHLC_PLAN_VIEW(o, pm)), on the host
// tile's locks (bias AIEHLC_PLAN_LOCK(o, pm)). Chunk g is in buffer g & 3 (channel g & 1, slot (g >> 1) & 1):
// part 0 at SLOT_LO + buffer SLOT_STRIDE, part 1 PART_STRIDE further on (a different memory bank) -- what
// x.part(i) of a {.parts = 2} block returns. Locks, relative to the bias, channel ch = g & 1:
//   LOCK_F + ch                         DMA -> first reader
//   LOCK_G + ch = F + ch + HAND_DELTA   first -> second reader
//   G + ch + HAND_DELTA                 no-op (held at 0): the second reader "hands on" here, by 0
//   LOCK_E + (g & 3)                    both readers -> DMA (it acquires 2)
// Both readers acquire one lock and release the one HAND_DELTA above it -- branch-free. The order of
// loads and releases is the kernel's: taking the next chunk before giving the current one back is what
// overlaps a chunk boundary with compute.
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
AIEHLC_PLAN_INLINE int aiehlc_plan_first(int o, int pm) { return (int)AIEHLC_PLAN_FIRST(o, pm); }

// Chunk g's lock / buffer terms; the plan lays both out so they are one AND (CH_STRIDE 1, slots 2 apart);
// the generic forms remain for other layouts.
AIEHLC_PLAN_INLINE int aiehlc_plan_ch_lock(unsigned g) {
#if AIEHLC_PLAN_LOCK_CH_STRIDE == 1
    return (int)(g & 1);
#else
    return AIEHLC_PLAN_LOCK_CH_STRIDE * (int)(g & 1);
#endif
}
AIEHLC_PLAN_INLINE unsigned aiehlc_plan_buffer(unsigned g) {
#if AIEHLC_PLAN_SLOT_CH_STRIDE == 1 && AIEHLC_PLAN_SLOT_SLOT_STRIDE == 2
    return g & 3;
#else
    return AIEHLC_PLAN_SLOT_CH_STRIDE * (g & 1) + AIEHLC_PLAN_SLOT_SLOT_STRIDE * ((g >> 1) & 1);
#endif
}
AIEHLC_PLAN_INLINE int aiehlc_plan_e_index(unsigned r) {
#if AIEHLC_PLAN_LOCK_CH_STRIDE == 1 && AIEHLC_PLAN_LOCK_E_SLOT_STRIDE == 2
    return (int)(r & 3);
#else
    return AIEHLC_PLAN_LOCK_CH_STRIDE * (int)(r & 1) + AIEHLC_PLAN_LOCK_E_SLOT_STRIDE * (int)((r >> 1) & 1);
#endif
}

// A load: acquire F (first reader) or G (second), hand on HAND_DELTA above -- G, or the no-op lock by 0.
template <typename W>
AIEHLC_PLAN_INLINE aiehlc_block_ptr aiehlc_load_buffer(W *win, const aiehlc_blk_desc &d, aiehlc_blk_cursor &cur, int pm,
                                                       int p1, aiehlc_blk off, aiehlc_blk shape, int parts = 1) {
    const int o = aiehlc_plan_operand(d);
    if (o < 0) /* not a shared operand: its generated window */
        return aiehlc_window_load(win, d, cur, pm, p1, off, shape, parts);
    const unsigned g = (unsigned)cur.n++;
    const int first = aiehlc_plan_first(o, pm);
    const int acq =
        aiehlc_plan_lockbase(o, pm) + (first ? AIEHLC_PLAN_LOCK_F : AIEHLC_PLAN_LOCK_G) + aiehlc_plan_ch_lock(g);
    acquire_greater_equal(acq, 1);
    release(acq + AIEHLC_PLAN_LOCK_HAND_DELTA, first);
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
    release(aiehlc_plan_lockbase(o, pm) + AIEHLC_PLAN_LOCK_E + aiehlc_plan_e_index(r), 1);
}
// The output is the generated window (ping-pong, its own locks); only the block check is dropped.
template <typename W>
AIEHLC_PLAN_INLINE aiehlc_block_ptr aiehlc_store_buffer(W *win, const aiehlc_blk_desc &, aiehlc_blk_cursor &, int, int,
                                                        aiehlc_blk, aiehlc_blk) {
    return {(int8_t *)acquire_output_window(win), 0};
}
// Tile sync (AIEHLC_PLAN_LOCK_SYNC, on the streams of operand AIEHLC_PLAN_SYNC_OPERAND). A stream's two
// readers run at the same speed, so nothing pulls them back together once apart; a follower lagging by
// about half a chunk reads the same bank half as the leader on every access (measured: 3x the bank
// conflicts, 1.265 vs 1.17 ms per launch). So at the end of every output tile the leader waits for its
// follower to finish the same tile: the follower releases the host tile's sync lock (init 0), the leader
// takes it. Two lock operations per tile; the other operand's pairs are not synced (measured: no gain).
template <typename W>
AIEHLC_PLAN_INLINE void aiehlc_commit(W *win, const aiehlc_blk_desc &, aiehlc_blk_cursor &cur, int pm, int) {
    cur.r++;
    release_output_window(win);
#if defined(AIEHLC_PLAN_LOCK_SYNC) && AIEHLC_PLAN_SYNC_OPERAND >= 0
    const int lead = aiehlc_plan_first(AIEHLC_PLAN_SYNC_OPERAND, pm);
    const int s = aiehlc_plan_lockbase(AIEHLC_PLAN_SYNC_OPERAND, pm) + AIEHLC_PLAN_LOCK_SYNC;
    const int nop = AIEHLC_PLAN_OWN_LOCK_BIAS + AIEHLC_PLAN_LOCK_G + AIEHLC_PLAN_LOCK_HAND_DELTA; /* held at 0 */
    release(lead ? nop : s, lead ? 0 : 1);
    acquire_greater_equal(lead ? s : nop, lead ? 1 : 0);
#else
    (void)pm;
#endif
}

#endif // AIE_BLOCK_IO_PLAN_H
