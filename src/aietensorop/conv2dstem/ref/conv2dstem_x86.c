/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * x86 model of conv2d_stem_prepadded() -- for checking the generated TVM BYOC
 * wrapper off-board (src/frontend/tvmrelay/byoc/verify_aie_stem.py).
 *
 * The arithmetic is the core's, transcribed from conv2d_spatial in
 * ../conv2dstem.cc: int8 x int8 MACs into int32 over the caller-padded input,
 * then  acc + bias - zp,  (int64)acc*mult + 2^(shift+30) >> (shift+31),
 * clamp [0,255]. It does NOT model the DMA / window packing -- verify_pack.c
 * covers that. If the kernel's epilogue changes, change it here too.
 ******************************************************************************/
#include <stdint.h>

typedef struct {
    int32_t bias;
    int32_t zero_point;
    int32_t multiplier;
    int32_t shift;
} conv2dstem_qparam;

#define HP 230
#define WP 230
#define C 3
#define KH 7
#define KW 7
#define S 2
#define F 64
#define OH 112
#define OW 112

/* C linkage even when built as C++ (TVM's export_library uses g++), matching
 * conv2dstem.h's extern "C" block. */
#ifdef __cplusplus
extern "C"
#endif
    int
    conv2d_stem_prepadded(const int8_t *ifm_pad, const int8_t *wts, const conv2dstem_qparam *qp, uint8_t *ofm) {
    for (int oh = 0; oh < OH; oh++)
        for (int ow = 0; ow < OW; ow++)
            for (int f = 0; f < F; f++) {
                int32_t sum = 0;
                for (int kh = 0; kh < KH; kh++)
                    for (int kw = 0; kw < KW; kw++)
                        for (int c = 0; c < C; c++)
                            sum += (int32_t)ifm_pad[((oh * S + kh) * WP + (ow * S + kw)) * C + c] *
                                   (int32_t)wts[((f * KH + kh) * KW + kw) * C + c];
                sum += qp[f].bias;
                sum -= qp[f].zero_point;
                const int sh = qp[f].shift;
                int64_t v = ((int64_t)sum * (int64_t)qp[f].multiplier + ((int64_t)1 << (sh + 30))) >> (sh + 31);
                if (v > 255)
                    v = 255;
                else if (v < 0)
                    v = 0;
                ofm[(oh * OW + ow) * F + f] = (uint8_t)v;
            }
    return 0;
}
