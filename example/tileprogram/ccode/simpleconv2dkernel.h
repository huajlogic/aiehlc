/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * Test data + golden check for simpleconv2dkernel.cc (tensor-form conv2d).
 *
 * The tensors are the REAL ones -- input [224, 224, 3] without any border,
 * weights [64, 7, 7, 3] OHWI, output [112, 112, 64] HWC. The compiler stages
 * the input / weights into the DMA layout (zero border, channels aligned to 4)
 * at the launch; nothing here knows about it.
 ******************************************************************************/
#ifndef SIMPLECONV2DKERNEL_H
#define SIMPLECONV2DKERNEL_H

#include <stdint.h>
#include <stdio.h>
#include <string.h>

// The conv the kernel computes (its body states the same numbers).
static constexpr int kStride = 2, kPad = 3;

static inline uint32_t conv_mix32(uint32_t x) {
    x ^= x >> 16;
    x *= 0x7feb352dU;
    x ^= x >> 15;
    x *= 0x846ca68bU;
    x ^= x >> 16;
    return x;
}

// Input in [-2, 2], weights in {-1, 0, 1}: sums rarely reach the int8 saturation.
template <class T> void init_input(T &t) {
    for (long i = 0; i < T::size(); i++)
        t.data[i] = (int8_t)((int)(conv_mix32((uint32_t)i + 17u) % 5u) - 2);
}
template <class T> void init_filter(T &t) {
    for (long i = 0; i < T::size(); i++)
        t.data[i] = (int8_t)((int)(conv_mix32((uint32_t)i + 9001u) % 3u) - 1);
}

// out(oh, ow, k) = saturate_int8(sum in(oh*S - P + kh, ow*S - P + kw, c) * w(k, kh, kw, c)),
// zero outside the input. Returns the number of mismatching outputs.
template <class I, class W, class O> int verify(const I &in, const W &wt, const O &out) {
    const int H = I::dim(0), Wd = I::dim(1), C = I::dim(2);
    const int K = W::dim(0), KH = W::dim(1), KW = W::dim(2);
    const int OH = O::dim(0), OW = O::dim(1);
    long bad = 0, sat = 0;
    for (int oh = 0; oh < OH; oh++)
        for (int ow = 0; ow < OW; ow++)
            for (int k = 0; k < K; k++) {
                int32_t acc = 0;
                for (int kh = 0; kh < KH; kh++)
                    for (int kw = 0; kw < KW; kw++) {
                        const int ih = oh * kStride - kPad + kh, iw = ow * kStride - kPad + kw;
                        if (ih < 0 || ih >= H || iw < 0 || iw >= Wd)
                            continue;
                        for (int c = 0; c < C; c++)
                            acc += in(ih, iw, c) * wt(k, kh, kw, c);
                    }
                const int8_t want = (int8_t)(acc < -128 ? -128 : acc > 127 ? 127 : acc);
                sat += acc != want;
                const int8_t got = out(oh, ow, k);
                if (got != want && bad++ < 8)
                    printf("  mismatch out(%d, %d, %d): got %d, want %d\n", oh, ow, k, got, want);
            }
    printf("conv2d %dx%dx%d -> %dx%dx%d: %ld / %ld outputs match (%ld saturated)\n", H, Wd, C, OH, OW, K,
           (long)OH * OW * K - bad, (long)OH * OW * K, sat);
    printf(bad ? "GOLDEN FAIL\n" : "GOLDEN PASS\n");
    return bad ? 1 : 0;
}

#endif // SIMPLECONV2DKERNEL_H
