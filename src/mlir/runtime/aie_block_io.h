/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
// Kernel-side block-load convention for __global__(op, map) kernels:
//
//   const int8_t *x = aie::load_buffer(win_a, {ih0, iw0, 0}, {IH_T, IW_T, C});
//   int8_t *y       = aie::store_buffer(win_c, {oh0, ow0, oc0}, {OH_T, OW_T, OC_T});
//   ... compute ...
//   aie::release(win_a);   aie::commit(win_c);
//
// Offsets/shapes are ELEMENT coordinates of the port's whole tensor (as in
// Triton's block pointers). The data still arrives by DMA in a fixed order, so
// a load/store does not choose WHAT arrives: it acquires the port's next window
// and CHECKS that the requested block is the one the DMA delivers there. The
// expected block comes from the compiler-derived aiehlc_desc_<port> (emitted
// from aie::block_desc, the same arithmetic as the port's DMA descriptor), so a
// mismatch -- a wrong offset, shape, or loop order -- is reported with klog tag
// "BLKE" instead of silently computing on the wrong data.
//
// The aiehlc pipeline rewrites the aie:: calls to the functions below (the
// kernel TU's `namespace aie` belongs to the AIE API). Design:
// doc/design/op_mapping_programming_model.md.
#ifndef AIE_BLOCK_IO_H
#define AIE_BLOCK_IO_H

#include <stdint.h>

// Field order matches aie::BlockDesc (aiehlc_opmodel.h).
struct aiehlc_blk_desc {
    int rank;
    int shape[4];
    int base_p0[4];
    int base_p1[4];
    int step_i[4];
    int step_j[4];
    int rounds_i;
    int rounds_j;
};
// Field order matches aie::KernelView.
struct aiehlc_kernel_view_t {
    int oh, ow, oh_per_core, oc_per_core, oh_t, ow_t, ih_t, iw_t, c_align;
};
// Blocks handed out so far on one port (persists across kernel calls; the
// round index wraps per launch).
struct aiehlc_blk_cursor {
    int n;
};
// A block offset or shape: {d0, d1, d2[, d3]}.
struct aiehlc_blk {
    int v[4];
};

// 1 when (off, shape) is the block port `d` delivers next on core (p0, p1).
static inline int aiehlc_blk_check(const aiehlc_blk_desc &d, aiehlc_blk_cursor &cur, int p0, int p1,
                                   const aiehlc_blk &off, const aiehlc_blk &shape) {
    const int per = d.rounds_i * d.rounds_j;
    const int round = per > 0 ? cur.n % per : 0;
    const int i = d.rounds_j > 0 ? round / d.rounds_j : 0;
    const int j = d.rounds_j > 0 ? round % d.rounds_j : 0;
    cur.n++;
    int ok = 1;
    for (int k = 0; k < d.rank; ++k) {
        const int want = d.base_p0[k] * p0 + d.base_p1[k] * p1 + d.step_i[k] * i + d.step_j[k] * j;
        if (off.v[k] != want || shape.v[k] != d.shape[k]) {
            klog("BLKE", (k << 16) | round); // dim k, round
            klog("BLKW", want);              // expected offset
            klog("BLKG", off.v[k]);          // requested offset
            ok = 0;
        }
    }
    return ok;
}

template <typename W>
static inline int8_t *aiehlc_load_buffer(W *win, const aiehlc_blk_desc &d, aiehlc_blk_cursor &cur, int p0, int p1,
                                         aiehlc_blk off, aiehlc_blk shape) {
    aiehlc_blk_check(d, cur, p0, p1, off, shape);
    return (int8_t *)acquire_input_window(win);
}
template <typename W>
static inline int8_t *aiehlc_store_buffer(W *win, const aiehlc_blk_desc &d, aiehlc_blk_cursor &cur, int p0, int p1,
                                          aiehlc_blk off, aiehlc_blk shape) {
    aiehlc_blk_check(d, cur, p0, p1, off, shape);
    return (int8_t *)acquire_output_window(win);
}
template <typename W> static inline void aiehlc_release(W *win) { release_input_window(win); }
template <typename W> static inline void aiehlc_commit(W *win) { release_output_window(win); }

#endif // AIE_BLOCK_IO_H
