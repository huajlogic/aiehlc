/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
/* qwen on the baremetal A78: the weight blob is already in DDR, in segments at QW_SEGS (qwen_board.py load).
 * The prompt's token ids come from qwen_prompt.h (generated); prints
 *   QW TOP5 / QW GEN <ids> / QW PERF prefill .. decode .. tok/s */
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "qwen_engine.h"
#ifdef QW_PROMPT_EXTERN /* the prompt in its own object (qwen_web.py links one per question) */
extern "C" const int qw_prompt_ids[];
extern "C" const int qw_prompt_n, qw_prompt_ngen;
#define qw_prompt qw_prompt_ids
#define QW_NGEN qw_prompt_ngen
#else
#include "qwen_prompt.h" /* static const int qw_prompt[]; QW_NGEN */
#endif
#include "xil_cache.h"
#include "xiltimer.h"
#include "xtimer_config.h"
#ifdef QW_AIE /* the weight matmuls on the AIE: qwen_gemv (libqwen_gemv_lib.a) */
#include <math.h>
#include <stdlib.h>
#include "qwen_aie.h"
#ifdef QW_CHECK
#include "qwen_gemv_host.h" /* qg_selftest: one launch on random data against the scalar reference */
#endif
/* built as C++ against the aiehlc library: its launch is extern "C", the runtime is C++ */
extern "C" void qwen_gemv_launch(int8_t *w, int8_t *x, int8_t *y);
void *__Runtime_alloc_uncached(size_t bytes);
int __Runtime_buffer_device_only(void *ptr, size_t size); /* no per-launch cache maintenance for the weights */
#endif

/* where the blob's segments sit (qwen_board.py loaders --bases): VEK385 has five 2 GB DDR regions, the
 * three DDR_CH ones hold the model (DDR_LOW1 aliases the netboot supervisor's DMA memory there) */
#ifndef QW_SEGS
#define QW_SEGS 0x50000000000ULL, 0x60000000000ULL, 0x70000000000ULL
#endif
static const uintptr_t qw_segs[] = {QW_SEGS};
#define QW_NSEG ((int)(sizeof qw_segs / sizeof qw_segs[0]))
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
void qw_dcache_flush(intptr_t adr, intptr_t len) { Xil_DCacheFlushRange((INTPTR)adr, (INTPTR)len); }
#endif

#ifndef QW_VERIFY
#define QW_VERIFY 1
#endif
/* the loader's per-chunk checksum (qwen_load.c, qwen_board.py): is the blob still in DDR? */
static void verify_blob(size_t size, size_t seg) {
    for (int i = 0; i < QW_NSEG && (size_t)i * seg < size; i++) {
        const size_t n = (size - i * seg < seg ? size - i * seg : seg) / 8;
        const uint64_t *w = (const uint64_t *)qw_segs[i];
        uint64_t s = 0;
        for (size_t k = 0; k < n; k++)
            s += w[k] ^ k;
        printf("QW BLOBSUM 0x%llx sum=0x%016llx\r\n", (unsigned long long)qw_segs[i], (unsigned long long)s);
    }
}

static void emit_print(void *ctx, int t) {
    (void)ctx;
#ifdef QW_STREAM /* one line per token: a host reading the console line by line streams them */
    printf("QWT %d\r\n", t);
#else
    printf(" %d", t);
#endif
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
    const uint8_t *blob = (const uint8_t *)qw_segs[0]; /* segment 0: the header and the tensor table */
    const size_t seg = (size_t)((const struct qw_header *)blob)->ints[QWC_SEG_MB] << 20;
    const size_t total = (blob_size(blob) + 63) & ~(size_t)63; /* the file size: 64-aligned */
    const void *segv[QW_NSEG];
    for (int i = 0; i < QW_NSEG; i++)
        segv[i] = (const void *)qw_segs[i];
    static qw_model m;
    char err[160];
#ifdef QW_PROMPT_EXTERN
    const int n = qw_prompt_n;
#else
    const int n = (int)(sizeof qw_prompt / sizeof qw_prompt[0]);
#endif
    if (QW_VERIFY) {
        const double v0 = now_s();
        verify_blob(total, seg);
        printf("QW blob checked in %.2f s\r\n", now_s() - v0);
    }
    if (qw_open_seg(&m, segv, QW_NSEG, QW_CTX, QW_BATCH, err, sizeof err)) {
        printf("QW ERROR %s\r\n", err);
        return 1;
    }
    printf("QW model %d layers, hidden %d, vocab %d, prompt %d tokens\r\n", m.layers, m.hidden, m.vocab, n);
#ifdef QW_AIE
    static qa_ctx actx;
    actx.launch = qwen_gemv_launch;
    { /* the blob is never written again: launches skip its cache maintenance (cleaned once here) */
        const double r0 = now_s();
        int rc = 0;
        for (int i = 0; i < QW_NSEG && (size_t)i * seg < total; i++)
            rc |= __Runtime_buffer_device_only((void *)qw_segs[i], total - i * seg < seg ? total - i * seg : seg);
        printf("QW blob registered device-only (rc %d, %.2f s)\r\n", rc, now_s() - r0);
    }
    /* cached + one explicit clean per launch set: uncached stores run at ~0.5 GB/s on the A78 */
    actx.xbuf = (int8_t *)aligned_alloc(64, QA_XCOPIES * QA_XB);
    memset(actx.xbuf, 0, QA_XCOPIES * QA_XB);
    actx.xcached = 1;
    /* cached: invalidated after each launch, then the glue reads only the tokens in use (uncached reads are slow) */
    actx.ybuf = (float *)aligned_alloc(64, QA_YB);
    /* x and y: the glue does their cache maintenance (clean x after writing it, invalidate y before reading it), so
     * the launches skip theirs: registered device-only */
    actx.ycached = 1;
    __Runtime_buffer_device_only(actx.xbuf, QA_XCOPIES * QA_XB);
    __Runtime_buffer_device_only(actx.ybuf, QA_YB);
    actx.now = now_s;
    m.matmul = qw_matmul_aie, m.matmul_ctx = &actx;
    m.now = now_s;
    printf("QW matmul on the AIE (qwen_gemv, %d tokens per launch)\r\n", QA_M);
#ifdef QW_CHECK
    printf("QW check 1: the library's launch on random data (DDR_LOW0)\r\n");
    qg_selftest(qwen_gemv_launch);
    { /* check 2: layer 0's qkvz from the blob in DDR_LOW1, AIE vs the CPU reference, one random token */
        const qw_mat *w = &m.layer[0].qkvz;
        float *x = (float *)malloc(sizeof(float) * w->cols), *ya = (float *)malloc(sizeof(float) * w->rows),
              *yc = (float *)malloc(sizeof(float) * w->rows);
        uint32_t r = 7;
        for (int i = 0; i < w->cols; i++)
            r = r * 1664525u + 1013904223u, x[i] = ((int)(r >> 9) % 2001 - 1000) * 0.001f;
        const double c0 = now_s();
        qw_matmul_aie(&actx, w, x, 1, ya);
        const double c1 = now_s();
        qw_matmul_cpu(NULL, w, x, 1, yc);
        const double c2 = now_s();
        double me = 0, mr = 0;
        for (int i = 0; i < w->rows; i++) {
            const double e = fabs((double)ya[i] - yc[i]);
            me = e > me ? e : me, mr = fabs(yc[i]) > mr ? fabs(yc[i]) : mr;
        }
        printf("QW check 2: %s %d x %d, AIE %.3f ms, CPU %.3f ms, max |err| %.3g of max |y| %.3g -> %s\r\n", w->name,
               w->rows, w->cols, (c1 - c0) * 1e3, (c2 - c1) * 1e3, me, mr, me <= 1e-3 * mr + 1e-6 ? "PASS" : "FAIL");
    }
#endif
#endif
#ifndef QW_SPEC
#define QW_SPEC 1
#endif
    m.mtp_hid_pre = 0, m.mtp_pos_off = 1; /* the MTP head takes the hidden state after the final norm */
#ifndef QW_MTP_VOCAB
#define QW_MTP_VOCAB 16384 /* the draft's vocabulary: 4 of lm_head's 61 launches, acceptance 68 -> 64 % on x86 */
#endif
    m.mtp_vocab = QW_MTP_VOCAB;
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
    static const char *pn[QW_P_N] = {"matmul", "ab",      "deltanet",   "attn",    "mlp-act",
                                     "norm",   "lm_head", "dn-conv+l2", "dn-heads"};
    printf("QW PROF");
    for (int k = 0; k < QW_P_N; k++)
        printf(" %s %.3f", pn[k], m.prof[k]);
    printf(" s\r\n");
#ifdef QW_AIE
    printf("QW AIE %ld launches, %.3f s in launches, %.3f s CPU x/y glue (x prep %.3f s)\r\n", actx.launches,
           actx.aie_s, actx.cpu_s, actx.prep_s);
#endif
    return 0;
}
