/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
/* qwen on the baremetal A78: the weight blob is already in DDR_LOW1 at QW_BLOB (qwen_board.py load).
 * The prompt's token ids come from qwen_prompt.h (generated); prints
 *   QW TOP5 / QW GEN <ids> / QW PERF prefill .. decode .. tok/s */
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "qwen_engine.h"
#include "qwen_prompt.h" /* static const int qw_prompt[]; QW_NGEN */
#include "xil_cache.h"
#include "xiltimer.h"
#include "xtimer_config.h"
#ifdef QW_AIE /* the weight matmuls on the AIE: qwen_gemv (libqwen_gemv_lib.a) */
#include <stdlib.h>
#include "qwen_aie.h"
/* built as C++ against the aiehlc library: its launch is extern "C", the runtime is C++ */
extern "C" void qwen_gemv_launch(int8_t *w, int8_t *x, int8_t *y);
void *__Runtime_alloc_uncached(size_t bytes);
#endif

#ifndef QW_BLOB
#define QW_BLOB 0x800000000ULL
#endif
#ifndef QW_CTX
#define QW_CTX 2048
#endif
#ifndef QW_BATCH
#define QW_BATCH 32
#endif

static double secs(XTime a, XTime b) { return (double)(b - a) / (double)COUNTS_PER_SECOND; }
static double now_s(void) {
    XTime t;
    XTime_GetTime(&t);
    return (double)t / (double)COUNTS_PER_SECOND;
}
#ifdef QW_AIE
void qw_dcache_invalidate(intptr_t adr, intptr_t len) { Xil_DCacheInvalidateRange((INTPTR)adr, (INTPTR)len); }
#endif

#ifndef QW_VERIFY
#define QW_VERIFY 1
#endif
/* the loader's per-chunk checksum (qwen_load.c, qwen_board.py): is the blob still in DDR_LOW1? */
static void verify_blob(const uint8_t *b, size_t size) {
    const size_t chunk = 0x70000000ULL;
    for (size_t off = 0; off < size; off += chunk) {
        const size_t n = (size - off < chunk ? size - off : chunk) / 8;
        const uint64_t *w = (const uint64_t *)(b + off);
        uint64_t s = 0;
        for (size_t i = 0; i < n; i++)
            s += w[i] ^ i;
        printf("QW BLOBSUM 0x%llx sum=0x%016llx\r\n", (unsigned long long)((uintptr_t)b + off), (unsigned long long)s);
    }
}

static void emit_print(void *ctx, int t) {
    (void)ctx;
    printf(" %d", t);
}

static size_t blob_size(const uint8_t *b) {
    const struct qw_header *h = (const struct qw_header *)b;
    const struct qw_tensor_ent *e = (const struct qw_tensor_ent *)(b + h->table_off);
    size_t end = 0;
    for (uint32_t i = 0; i < h->n_tensors; i++)
        if (e[i].offset + e[i].bytes > end)
            end = e[i].offset + e[i].bytes;
    return end;
}

int main(void) {
    const uint8_t *blob = (const uint8_t *)(uintptr_t)QW_BLOB;
    static qw_model m;
    char err[160];
    const int n = (int)(sizeof qw_prompt / sizeof qw_prompt[0]);
    if (QW_VERIFY) {
        const double v0 = now_s();
        verify_blob(blob, (blob_size(blob) + 63) & ~(size_t)63); /* the file is 64-aligned */
        printf("QW blob checked in %.2f s\r\n", now_s() - v0);
    }
    if (qw_open(&m, blob, blob_size(blob), QW_CTX, QW_BATCH, err, sizeof err)) {
        printf("QW ERROR %s\r\n", err);
        return 1;
    }
    printf("QW model %d layers, hidden %d, vocab %d, prompt %d tokens\r\n", m.layers, m.hidden, m.vocab, n);
#ifdef QW_AIE
    static qa_ctx actx;
    actx.launch = qwen_gemv_launch;
    actx.xbuf = (int8_t *)__Runtime_alloc_uncached(QA_XCOPIES * QA_XB);
    actx.ybuf = (float *)aligned_alloc(64, QA_YB);
    actx.ycached = 1;
    actx.now = now_s;
    m.matmul = qw_matmul_aie, m.matmul_ctx = &actx;
    printf("QW matmul on the AIE (qwen_gemv, %d tokens per launch)\r\n", QA_M);
#endif
#ifndef QW_SPEC
#define QW_SPEC 1
#endif
    m.mtp_hid_pre = 0, m.mtp_pos_off = 1; /* the MTP head takes the hidden state after the final norm */
    const int stop[] = {248046, 248044};  /* <|im_end|>, <|endoftext|> */
    qw_gen_stats st;
    printf("QW GEN");
    if (qw_generate(&m, qw_prompt, n, QW_NGEN, QW_SPEC, stop, 2, emit_print, NULL, now_s, &st)) {
        printf("\r\nQW ERROR generate\r\n");
        return 1;
    }
    printf("\r\nQW PERF prefill %d tok %.3f s, decode %d tok in %d steps %.3f s, %.3f tok/s", n, st.prefill_s,
           st.emitted - 1, st.steps, st.decode_s, st.emitted > 1 ? (st.emitted - 1) / st.decode_s : 0.0);
    if (st.drafted)
        printf(", MTP accepted %d / %d", st.accepted, st.drafted);
    printf("\r\n");
#ifdef QW_AIE
    printf("QW AIE %ld launches, %.3f s in launches, %.3f s CPU x/y glue\r\n", actx.launches, actx.aie_s, actx.cpu_s);
#endif
    return 0;
}
