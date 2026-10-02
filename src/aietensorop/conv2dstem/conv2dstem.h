/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * conv2dstem — ResNet-18 stem convolution (conv1) on an AIE 4x4 mesh.
 *
 *   ifm [224,224,3] (*) wts [64,7,7,3]  stride 2, pad 3  ->  ofm [112,112,64]
 *
 * This is the PUBLIC header of the `libconv2dstem.a` static library. It is
 * deliberately lean: no xil_cache.h / xiltimer.h / AIE programming-model types
 * leak out, so a plain host translation unit (e.g. a TVM BYOC wrapper) can
 * include it without pulling the AIE toolchain's header set.
 *
 * Buffer contract (caller-facing, all int8, all row-major / HWC):
 *   ifm : [H=224][W=224][C=3]      raw, UNPADDED, channel-packed
 *   wts : [F=64][KH=7][KW=7][C=3]  raw, filter-major
 *   ofm : [OH=112][OW=112][F=64]   channel-fastest (HWC)
 *
 * The AIE data path needs a spatially pre-padded, channel-aligned input
 * ([230,230,4]) and a B^T[64,196] filter. The library materializes both in its
 * own DMA-capable staging buffers, so callers never see that layout.
 *
 * Caller buffers need no special alignment and are not retained after return.
 ******************************************************************************/
#ifndef AIETENSOROP_CONV2DSTEM_H
#define AIETENSOROP_CONV2DSTEM_H

#include <stdint.h>

/* ── Geometry (ResNet-18 conv1) ─────────────────────────────────────────── */
#define CONV2DSTEM_INPUT_H 224
#define CONV2DSTEM_INPUT_W 224
#define CONV2DSTEM_INPUT_C 3 /* real channels; AIE pads to 4 internally */
#define CONV2DSTEM_KERNEL_H 7
#define CONV2DSTEM_KERNEL_W 7
#define CONV2DSTEM_NUM_FILTERS 64
#define CONV2DSTEM_STRIDE 2
#define CONV2DSTEM_PAD 3

#define CONV2DSTEM_OUTPUT_H 112 /* (224 + 2*3 - 7)/2 + 1 */
#define CONV2DSTEM_OUTPUT_W 112

/* ── Caller buffer sizes, in int8 elements ──────────────────────────────── */
#define CONV2DSTEM_IFM_ELEMS (CONV2DSTEM_INPUT_H * CONV2DSTEM_INPUT_W * CONV2DSTEM_INPUT_C) /* 150528 */
#define CONV2DSTEM_WTS_ELEMS                                                                                           \
    (CONV2DSTEM_NUM_FILTERS * CONV2DSTEM_KERNEL_H * CONV2DSTEM_KERNEL_W * CONV2DSTEM_INPUT_C)     /* 9408 */
#define CONV2DSTEM_OFM_ELEMS (CONV2DSTEM_OUTPUT_H * CONV2DSTEM_OUTPUT_W * CONV2DSTEM_NUM_FILTERS) /* 802816 */

/* ── Return codes ───────────────────────────────────────────────────────── */
#define CONV2DSTEM_OK 0
#define CONV2DSTEM_ERR_NULL_ARG (-1)
#define CONV2DSTEM_ERR_ALLOC (-2)

/*
 * Run the stem convolution on the AIE mesh.
 *
 * On the first call the library allocates its DMA-capable staging buffers and
 * packs `wts` into the B^T[64,196] layout the kernel consumes; both are reused
 * on later calls. Weights are re-packed only when `wts` differs from the
 * pointer seen on the previous call — if you mutate the weight buffer IN PLACE
 * at the same address, call conv2d_stem_invalidate_weights() first or the stale
 * packed copy will be used.
 *
 * Not reentrant and not thread-safe: the staging buffers are process-global.
 *
 * Returns CONV2DSTEM_OK, or a negative CONV2DSTEM_ERR_* code.
 */
int conv2d_stem(const int8_t *ifm, const int8_t *wts, int8_t *ofm);

/*
 * Force the next conv2d_stem() call to re-pack the weight buffer. Use after
 * mutating weights in place at an address already seen by conv2d_stem().
 */
void conv2d_stem_invalidate_weights(void);

/*
 * Release the cached staging buffers. Safe to call when nothing is cached, and
 * safe to call repeatedly. A later conv2d_stem() will simply re-allocate.
 */
void conv2d_stem_release(void);

/*
 * Bring-up only: run conv2d_stem(), then recompute the same convolution with a
 * scalar CPU reference and compare element-wise. Prints a per-mismatch report
 * (capped) and a PASS/FAIL summary.
 *
 * This is ~157M MACs of scalar int8 work on the APU and takes seconds — it is
 * NOT part of the conv2d_stem() fast path. Returns the mismatch count (0 ==
 * bit-exact), or a negative CONV2DSTEM_ERR_* code if the AIE run itself failed.
 */
int conv2d_stem_verify(const int8_t *ifm, const int8_t *wts, int8_t *ofm);

#endif /* AIETENSOROP_CONV2DSTEM_H */
