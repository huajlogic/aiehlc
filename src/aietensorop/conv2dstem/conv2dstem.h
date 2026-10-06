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
 * The op is the FUSED one TVM emits, not a bare convolution: conv -> bias ->
 * zero-point -> per-channel fixed-point requantize -> ReLU -> uint8. The clip
 * at 0 is the ReLU. Max-pool is NOT part of it (in the Relay graph that is a
 * separate op downstream), so this library must not pool.
 *
 * Buffer contract (caller-facing, all row-major / HWC):
 *   ifm : [H=224][W=224][C=3]      int8,  raw, UNPADDED, channel-packed
 *   wts : [F=64][KH=7][KW=7][C=3]  int8,  raw, filter-major
 *   qp  : [F=64]                   per-output-channel quant params
 *   ofm : [OH=112][OW=112][F=64]   uint8, channel-fastest (HWC)
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

#ifdef __cplusplus
extern "C" {
#endif

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

///

// Conv2d spatial parameters
#define INPUT_H 224
#define INPUT_W 224
#define INPUT_C 3       // real (semantic) input channels
#define INPUT_C_ALIGN 4 // channel-layout stride: cin padded with a zero channel
#define KERNEL_H 7
#define KERNEL_W 7
#define NUM_FILTERS 64
#define STRIDE 2
#define PAD 3

// Derived output dimensions
#define OUTPUT_H ((INPUT_H + 2 * PAD - KERNEL_H) / STRIDE + 1) // 112
#define OUTPUT_W ((INPUT_W + 2 * PAD - KERNEL_W) / STRIDE + 1) // 112

// Spatially pre-padded host-buffer dimensions. The CPU reference functions
// (host_im2col / scalar_conv2d) index a DDR buffer that is zero-padded by PAD on
// every spatial border, so window position (oh*S+kh, ow*S+kw) indexes the padded
// buffer directly (real pixel sits at (h+PAD, w+PAD)). This implements true
// padded conv and removes the previous out-of-bounds reads (ih/iw reached
// INPUT_H/W+2*PAD-KERNEL into a buffer that was only [INPUT_H, INPUT_W, ...]).
#define INPUT_H_PAD (INPUT_H + 2 * PAD) // padded input rows
#define INPUT_W_PAD (INPUT_W + 2 * PAD) // padded input cols (row pitch in pixels)

// Im2col → GEMM dimensions (K uses the ALIGNED channel count, INPUT_C_ALIGN)
//   A (im2col matrix): [M, K] = [OH*OW, KH*KW*C_align] = [12544, 196]
//   B (filter matrix): [K, N] = [KH*KW*C_align, F]      = [196, 64]
//   C (output):        [M, N] = [OH*OW, F]              = [12544, 64]
#define M (OUTPUT_H * OUTPUT_W)                 // 12544
#define K (KERNEL_H * KERNEL_W * INPUT_C_ALIGN) // 196 (channel-aligned)
#define N NUM_FILTERS                           // 64

/*
 * Per-output-channel quantization parameters, one entry per filter.
 *
 * Applied on-core, after the int32 accumulator and before the uint8 store:
 *
 *   acc += bias; acc -= zero_point;
 *   v = ((int64)acc * multiplier + (1LL << (shift+30))) >> (shift+31);
 *   out = (uint8)clamp(v, 0, 255);          // clamp at 0 IS the ReLU
 *
 * This is TVM's `fixed_point_multiply_per_axis` lowering transcribed exactly,
 * including the rounding term and the split shift. Feeding values from any
 * other convention will produce plausible-looking but wrong pixels.
 *
 * NOTE the accumulator is int32 and must stay int32. With real ResNet-18 stem
 * weights the peak |accumulator| measures 257,339 (worst case 1,182,116)
 * against an int16 range of +-32,767.
 */
typedef struct {
    int32_t bias;       /* folded BN beta, pre-requantize                 */
    int32_t zero_point; /* input zero-point correction (0 for this model) */
    int32_t multiplier; /* Q31 fixed-point multiplier                     */
    int32_t shift;      /* right shift applied as (shift + 31)            */
} conv2dstem_qparam;

/*
 * Run the stem convolution on the AIE mesh.
 *
 * On the first call the library allocates its DMA-capable staging buffers and
 * packs `wts` + `qp` into the per-channel layout the kernel consumes (196
 * filter taps then 16 bytes of params, per output channel); both are reused on
 * later calls. Weights are re-packed only when `wts` differs from the pointer
 * seen on the previous call — if you mutate the weight buffer IN PLACE at the
 * same address, or change `qp` without changing `wts`, call
 * conv2d_stem_invalidate_weights() first or the stale packed copy will be used.
 *
 * Not reentrant and not thread-safe: the staging buffers are process-global.
 *
 * Returns CONV2DSTEM_OK, or a negative CONV2DSTEM_ERR_* code.
 */
int conv2d_stem(const int8_t *ifm, const int8_t *wts, const conv2dstem_qparam *qp, uint8_t *ofm);

/* Caller-padded input extents, for conv2d_stem_prepadded(). */
#define CONV2DSTEM_INPUT_H_PAD (CONV2DSTEM_INPUT_H + 2 * CONV2DSTEM_PAD)                                /* 230 */
#define CONV2DSTEM_INPUT_W_PAD (CONV2DSTEM_INPUT_W + 2 * CONV2DSTEM_PAD)                                /* 230 */
#define CONV2DSTEM_IFM_PAD_ELEMS (CONV2DSTEM_INPUT_H_PAD * CONV2DSTEM_INPUT_W_PAD * CONV2DSTEM_INPUT_C) /* 158700 */

/*
 * Same fused op as conv2d_stem(), on an input the caller ALREADY padded.
 *
 * This is the TVM BYOC entry point. TVM hoists the stem's spatial padding into
 * its own nn.pad and fills it with the input zero-point (113 for this model),
 * not with zero -- so re-padding with zero, as conv2d_stem() does, would be
 * wrong on every border pixel. Here the border is taken as given.
 *
 *   ifm_pad : [230][230][3] int8 HWC, border included
 *   wts, qp, ofm : as for conv2d_stem()
 *
 * A uint8 graph maps onto this int8 x int8 kernel exactly by passing
 * x_s8 = x_u8 - 128 and folding +128 * sum(w[f]) into qp[f].bias -- the
 * generated BYOC wrapper does both. Same caching/reentrancy rules as
 * conv2d_stem().
 */
int conv2d_stem_prepadded(const int8_t *ifm_pad, const int8_t *wts, const conv2dstem_qparam *qp, uint8_t *ofm);

/*
 * Force the next conv2d_stem() call to re-pack the weight buffer. Use after
 * mutating weights in place at an address already seen by conv2d_stem(), or
 * after changing `qp` while reusing the same `wts` pointer.
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
int conv2d_stem_verify(const int8_t *ifm, const int8_t *wts, const conv2dstem_qparam *qp, uint8_t *ofm);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* AIETENSOROP_CONV2DSTEM_H */
