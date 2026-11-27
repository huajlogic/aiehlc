/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/
/* x86 driver: qwen_x86 <blob> <tok,tok,...> [n_gen] [batch]
 * Runs the prompt (batch tokens per forward), then greedy-decodes n_gen tokens; prints
 *   TOP1 <top-5 ids:logit> of the prompt's last position, GEN <ids>, and the timing. */
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#include "qwen_aie.h"
#include "qwen_engine.h"

/* x86 stand-in for one qwen_gemv launch: walks the plan's stream order exactly as the 16 cores do
 * (core c = 4 pm + pn, its jj-th chunk at [pn][jj][pm]) -- checks the converter layout and the AIE glue */
static float bf16f(const uint8_t *p) {
    uint32_t u = (uint32_t)p[1] << 24 | (uint32_t)p[0] << 16;
    float f;
    memcpy(&f, &u, 4);
    return f;
}
static void fake_gemv(int8_t *w8, int8_t *xd, int8_t *y8) {
    const uint8_t *w = (const uint8_t *)w8;
    float *y = (float *)y8;
#pragma omp parallel for
    for (int c = 0; c < 16; c++) {
        const int pm = c / 4, pn = c % 4;
        float acc[16][64] = {{0}};
        for (int jj = 0; jj < 64; jj++) {
            const int h = jj / 32, u = (jj % 32) / 2, kh = jj % 2;
            const uint8_t *ch = w + ((size_t)(pn * 64 + jj) * 4 + pm) * QW_CHUNK_BYTES;
            const int8_t *xh = xd + (size_t)pn * QA_XB + h * (QA_XB / 2); /* column pn's copy, half h */
            for (int gg = 0; gg < 16; gg++) {
                const int gh = kh * 16 + gg;
                const int8_t *xt = xh + gh * 256;
                const float *xs = (const float *)(xh + 8192) + gh * QA_M;
                for (int m = 0; m < QA_M; m++)
                    for (int n = 0; n < 16; n++) {
                        int32_t d = 0;
                        for (int k = 0; k < 64; k++) {
                            const int e = (k % 16) * 16 + n, b = ch[gg * 512 + (k / 16) * 128 + e / 2];
                            const int v = (e & 1) ? (b >> 4) : (b & 15);
                            d += (v >= 8 ? v - 16 : v) * xt[(k / 16) * 64 + m * 16 + k % 16];
                        }
                        acc[u][m * 16 + n] += (float)d * (bf16f(ch + 8192 + gg * 32 + 2 * n) * xs[m]);
                    }
            }
        }
        for (int u = 0; u < 16; u++)
            memcpy(y + (size_t)(c * 16 + u) * 64, acc[u], sizeof(float) * 64);
    }
}

static void emit_print(void *ctx, int t) {
    (void)ctx;
    printf(" %d", t);
    fflush(stdout);
}

static void null_matmul(void *ctx, const qw_mat *w, const float *x, int n, float *y) {
    (void)ctx, (void)x;
    memset(y, 0, sizeof(float) * (size_t)n * w->rows);
}

static double now(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec * 1e-9;
}

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "usage: %s blob tok,tok,... [n_gen] [batch]\n", argv[0]);
        return 2;
    }
    int fd = open(argv[1], O_RDONLY);
    struct stat st;
    if (fd < 0 || fstat(fd, &st)) {
        perror(argv[1]);
        return 1;
    }
    void *blob = mmap(NULL, (size_t)st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
    if (blob == MAP_FAILED) {
        perror("mmap");
        return 1;
    }
    int toks[8192], n = 0;
    for (char *p = strtok(argv[2], ","); p && n < 8192; p = strtok(NULL, ","))
        toks[n++] = atoi(p);
    const int ngen = argc > 3 ? atoi(argv[3]) : 8, batch = argc > 4 ? atoi(argv[4]) : 64;
    qw_model m;
    char err[256];
    if (qw_open(&m, blob, (size_t)st.st_size, 4096, batch, err, sizeof err)) {
        fprintf(stderr, "qw_open: %s\n", err);
        return 1;
    }
    static int8_t xbuf[QA_XCOPIES * QA_XB];
    static float ybuf[QA_YB / 4];
    qa_ctx actx;
    memset(&actx, 0, sizeof actx);
    actx.launch = fake_gemv, actx.xbuf = xbuf, actx.ybuf = ybuf;
    if (argc > 5 && !strcmp(argv[5], "null")) { /* time everything but the weight matmuls */
        m.matmul = null_matmul;
        printf("matmul: none (CPU-side cost only)\n");
    }
    if (argc > 5 && !strcmp(argv[5], "aie")) {
        m.matmul = qw_matmul_aie, m.matmul_ctx = &actx;
        printf("matmul: the AIE path with an x86 stand-in for the kernel\n");
    }
    printf("model: %d layers (%d full, %d linear), hidden %d, vocab %d, mtp %d\n", m.layers, m.n_full, m.n_la, m.hidden,
           m.vocab, m.mtp);
    const int spec = argc > 6 ? atoi(argv[6]) : 0;
    m.mtp_hid_pre = getenv("QW_MTP_PRE") ? atoi(getenv("QW_MTP_PRE")) : 0;
    m.mtp_pos_off = getenv("QW_MTP_POS") ? atoi(getenv("QW_MTP_POS")) : 1;
    m.mtp_vocab = getenv("QW_MTP_VOCAB") ? atoi(getenv("QW_MTP_VOCAB")) : 0;
    m.mtp_fill = getenv("QW_MTP_FILL") ? atoi(getenv("QW_MTP_FILL")) : 0;
    const int stop[] = {248046, 248044};
    qw_gen_stats gs;
    printf("GEN");
    if (qw_generate(&m, toks, n, ngen, spec, stop, 2, emit_print, NULL, now, &gs))
        return 1;
    printf("\nprefill %d tok %.2f s, decode %d tok in %d steps %.2f s (%.2f tok/s)", n, gs.prefill_s, gs.emitted - 1,
           gs.steps, gs.decode_s, gs.emitted > 1 ? (gs.emitted - 1) / gs.decode_s : 0.0);
    if (gs.drafted)
        printf(", MTP accepted %d / %d (%.0f %%)", gs.accepted, gs.drafted, 100.0 * gs.accepted / gs.drafted);
    printf("\n");
    if (actx.launches)
        printf("AIE launches %ld\n", actx.launches);
    qw_close(&m);
    return 0;
}
