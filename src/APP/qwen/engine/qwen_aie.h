/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
/* The engine's matmul on the AIE: every Q4G64 matmul becomes launches of the qwen_gemv kernel
 * (4096 rows x 4096 K, up to QA_M tokens); K slices are summed on the CPU, other matrices stay on the CPU. */
#ifndef QWEN_AIE_H
#define QWEN_AIE_H

#include "qwen_engine.h"

#ifdef __cplusplus
extern "C" {
#endif

#define QA_M 4
#define QA_ROWS 4096
#define QA_K 4096
#define QA_XB (QA_M * QA_K + QA_M * (QA_K / 64) * 4)
#define QA_XCOPIES 4 /* the plan streams x once per mesh column: QA_XCOPIES consecutive copies */
#define QA_YB (QA_ROWS * QA_M * 4)

/* one launch: y[256 row blocks][QA_M][16] fp32 = W (4096 x 4096, Q4G64) . x (QA_M tokens, tiled) */
typedef void (*qa_launch_fn)(int8_t *w, int8_t *x, int8_t *y);

typedef struct {
    qa_launch_fn launch;
    int8_t *xbuf; /* QA_XCOPIES x QA_XB, written by the CPU, read by the AIE (uncached) */
    float *ybuf;  /* QA_YB, written by the AIE */
    int ycached;  /* invalidate ybuf before reading it */
    int xcached;  /* xbuf is cached memory: clean it (qw_dcache_flush) before each launch set */
    long launches;
    double aie_s, cpu_s; /* time in launches / in the x prep + y scatter (when timers are set) */
    double prep_s;       /* of cpu_s: the x prep */
    double (*now)(void);
} qa_ctx;

/* quantize n (<= QA_M) tokens' K slice s into the kernel's x layout, `copies` times (other token slots untouched) */
void qa_prep_x(const float *x, int K, int n, int s, int8_t *xbuf, int copies);
void qw_matmul_aie(void *ctx, const qw_mat *w, const float *x, int n, float *y);

#ifdef __cplusplus
}
#endif
#endif
