/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * ET1: Whisper-engine op tests on synthetic data, each checked against the CPU:
 * GEMM (bias, transposed-K blocks, GELU, residual with M passes, one active
 * mesh row) and a GEMM with a LayerNorm folded in (WE_F_LN).
 ******************************************************************************/
#include "we_host.h"
#include <math.h>
#include <stdlib.h>

extern unsigned char _binary_kernel_eng_start[];

static uint32_t g_seed = 1;
static float rnd() {
    g_seed = g_seed * 1664525u + 1013904223u;
    return ((g_seed >> 8) & 0xFFFF) / 32768.0f - 1.0f;
}
static WeAct act(int rb, int c) {
    WeAct t = {(bf16_t *)__Runtime_Alloc((size_t)4 * rb * c * 2), rb, c};
    return t;
}
static void fill_act(WeEng *e, WeAct *t, float s) {
    for (size_t i = 0; i < (size_t)4 * t->rb * t->c; i++)
        t->p[i] = f2bf(rnd() * s);
    __Runtime_sync_for_dev(e->dev, t->p, we_act_bytes(t));
}
static float at(const WeAct *t, int row, int col) { return bf2f(t->p[we_blk_idx(t->rb, t->c, row, col)]); }
// we_model.gelu_aie on an already bf16-rounded x
static float gelu_ref(float xb) {
    const float ax = fabsf(xb);
    if (xb >= 4)
        return xb;
    if (xb <= -4)
        return 0;
    if (ax < 0.125f)
        return 0.5f * xb + bf2f(f2bf(xb * xb)) * bf2f(f2bf(0.3989422804f));
    return bf2f(f2bf((float)(0.5 * xb * (1.0 + erf(xb / sqrt(2.0))))));
}

static WeEng *g_e;
static int check(const char *name, long bad, long n, double maxe) {
    if (g_e) {
        printf("ET1 %-28s phases: fill %.1f  arm %.1f  run %.1f us\n", name, g_e->t_fill, g_e->t_arm, g_e->t_run);
        g_e->t_fill = g_e->t_arm = g_e->t_run = 0;
    }
    printf("ET1 %-28s %s  (%ld / %ld bad, max err %.3g)\n", name, bad ? "FAIL" : "PASS", bad, n, maxe);
    return bad != 0;
}

// C = A W^T (+bias, gelu, +res); compares rows in [0, rows) with stride rstep
static int test_gemm(WeEng *e, const char *name, int rb, int K, int N, int flags, int bias, int res, int mbp, int ract,
                     int kt_lo, int kt_hi) {
    WeAct a = act(rb, K), o = act(rb, N), rs = act(rb, N);
    fill_act(e, &a, 1.0f);
    if (res)
        fill_act(e, &rs, 1.0f);
    bf16_t *w = (bf16_t *)malloc((size_t)N * K * 2), *b = (bf16_t *)malloc((size_t)N * 2);
    for (long i = 0; i < (long)N * K; i++)
        w[i] = f2bf(rnd() * 0.1f);
    for (int i = 0; i < N; i++)
        b[i] = f2bf(rnd());
    bf16_t *wp = (bf16_t *)__Runtime_Alloc((size_t)N * K * 2);
    we_pack_w(wp, w, N, K, mbp ? (rb / 64) / mbp : 1);
    __Runtime_sync_for_dev(e->dev, wp, (size_t)N * K * 2);
    memset(o.p, 0xFF, we_act_bytes(&o));
    __Runtime_sync_for_dev(e->dev, o.p, we_act_bytes(&o));
    WeGemm g = {&a, wp, bias ? b : 0, res ? &rs : 0, &o, N, flags, kt_lo, kt_hi, ract, mbp};
    XTime t0, t1;
    XTime_GetTime(&t0);
    if (we_gemm(e, &g))
        return check(name, 1, 1, 0);
    XTime_GetTime(&t1);
    __Runtime_sync_for_cpu(e->dev, o.p, we_act_bytes(&o));
    long bad = 0, n = 0;
    double maxe = 0;
    const int rows = ract * rb;
    for (int i = 0; i < rows; i += (i % rb < 64 ? 1 : 5))
        for (int j = 0; j < N; j++) {
            float acc = 0;
            for (int k = 0; k < K; k++)
                acc += at(&a, i, k) * bf2f(w[(size_t)j * K + k]);
            if (bias)
                acc += bf2f(b[j]);
            if (flags & WE_F_GELU)
                acc = gelu_ref(bf2f(f2bf(acc)));
            if (res)
                acc += at(&rs, i, j);
            float got;
            const int cb = j / 48;
            if ((flags & WE_F_KT) && cb >= kt_lo && cb < kt_hi) {
                // block (r, cb, mb) stored [dt 6][kp 8][8 dims][8 keys]
                const int r = i / rb, rr = i % rb, mb = rr / 64, key = rr % 64, dim = j % 48;
                const size_t blk = ((size_t)(r * (N / 48) + cb) * rb + mb * 64) * 48;
                got = bf2f(o.p[blk + ((size_t)(dim / 8) * 8 + key / 8) * 64 + (dim % 8) * 8 + key % 8]);
            } else
                got = at(&o, i, j);
            const double err = fabs((double)got - acc);
            if (err > maxe || got != got)
                maxe = got != got ? 1e30 : err;
            const double tol = (flags & WE_F_GELU) ? fabs(acc) / 32 + 0.03 : fabs(acc) / 64 + 0.02;
            if (!(err <= tol)) {
                if (bad++ < 4)
                    printf("  %s (%d,%d): got %f want %f\n", name, i, j, got, acc);
            }
            n++;
        }
    const double macs = (double)rows * N * K;
    printf("ET1 %-28s %.1f us  (%.1f%% of 4x4 peak)\n", name, we_us(t0, t1),
           100 * macs / (we_us(t0, t1) * 1e-6) / 4096e9);
    return check(name, bad, n, maxe);
}

// y = LayerNorm(x) W^T + b with the LayerNorm folded in (we_desc.h WE_F_LN): the
// host passes W' = gamma (.) W, c = row sums of W' (hi/lo bf16), d = b + beta W^T
static int test_ln_gemm(WeEng *e, int rb, int N) {
    const int K = 384;
    WeAct x = act(rb, K), o = act(rb, N);
    for (size_t i = 0; i < (size_t)4 * rb * K; i++) /* a residual-stream-like row: offset + spread */
        x.p[i] = f2bf(rnd() * 3.0f + 1.5f);
    __Runtime_sync_for_dev(e->dev, x.p, we_act_bytes(&x));
    memset(o.p, 0xFF, we_act_bytes(&o)); /* and clean: a dirty line evicted later lands on the DMA output */
    __Runtime_sync_for_dev(e->dev, o.p, we_act_bytes(&o));
    static float g[384], be[384];
    for (int k = 0; k < K; k++)
        g[k] = bf2f(f2bf(1.0f + rnd() * 0.5f)), be[k] = bf2f(f2bf(rnd() * 0.5f));
    bf16_t *w = (bf16_t *)malloc((size_t)N * K * 2), *wf = (bf16_t *)malloc((size_t)N * K * 2);
    float *d = (float *)malloc((size_t)N * 4), *bias = (float *)malloc((size_t)N * 4);
    bf16_t *c = (bf16_t *)malloc((size_t)N * 4);
    for (int n = 0; n < N; n++) {
        double cs = 0, db = 0;
        bias[n] = bf2f(f2bf(rnd()));
        for (int k = 0; k < K; k++) {
            w[(size_t)n * K + k] = f2bf(rnd() * 0.1f);
            wf[(size_t)n * K + k] = f2bf(bf2f(w[(size_t)n * K + k]) * g[k]);
            cs += bf2f(wf[(size_t)n * K + k]);
            db += (double)be[k] * bf2f(w[(size_t)n * K + k]);
        }
        c[n] = f2bf((float)cs);
        c[N + n] = f2bf((float)cs - bf2f(c[n]));
        d[n] = (float)(db + bias[n]);
    }
    bf16_t *wp = (bf16_t *)__Runtime_Alloc((size_t)N * K * 2);
    we_pack_w(wp, wf, N, K, 1);
    __Runtime_sync_for_dev(e->dev, wp, (size_t)N * K * 2);
    WeGemm gm = {&x, wp, 0, 0, &o, N, 0, 0, 0, 4, 0};
    gm.lnd = d, gm.lnc = c, gm.lnn = N;
    XTime t0, t1;
    XTime_GetTime(&t0);
    if (we_gemm(e, &gm))
        return check("ln-folded gemm", 1, 1, 0);
    XTime_GetTime(&t1);
    printf("ET1 ln-folded gemm %dx%d: %.1f us\n", 4 * rb, N, we_us(t0, t1));
    __Runtime_sync_for_cpu(e->dev, o.p, we_act_bytes(&o));
    long bad = 0, n = 0;
    double maxe = 0;
    static float ln[384];
    for (int i = 0; i < 4 * rb; i += (i < 64 ? 1 : 7)) {
        double m = 0, v = 0;
        for (int k = 0; k < K; k++)
            m += at(&x, i, k);
        m /= K;
        for (int k = 0; k < K; k++)
            v += (at(&x, i, k) - m) * (at(&x, i, k) - m);
        const double rs = 1.0 / sqrt(v / K + 1e-5);
        for (int k = 0; k < K; k++)
            ln[k] = (float)((at(&x, i, k) - m) * rs * g[k] + be[k]);
        for (int j = 0; j < N; j++) {
            double want = bias[j];
            for (int k = 0; k < K; k++)
                want += (double)ln[k] * bf2f(w[(size_t)j * K + k]);
            const float got = at(&o, i, j);
            const double err = fabs(got - want);
            if (err > maxe || got != got)
                maxe = got != got ? 1e30 : err;
            if (!(err <= fabs(want) / 64 + 0.02) && bad++ < 3)
                printf("  ln-gemm (%d,%d): got %f want %f\n", i, j, got, want);
            n++;
        }
    }
    return check("ln-folded gemm", bad, n, maxe);
}

int main() {
    printf("=== ET1: Whisper engine op tests ===\n");
    XAie_DevInst *dev = __Runtime_init_mesh_partition(0, EF_PART_START_COL, EF_PART_NUM_COLS);
    XAie_LocType tiles[16];
    for (int r = 0; r < 4; r++)
        for (int c = 0; c < 4; c++)
            tiles[r * 4 + c] = XAie_TileLoc((uint8_t)(EF_FIRST_COL + c), (uint8_t)(EF_FIRST_ROW + r));
    __Runtime_set_kernel_elf(_binary_kernel_eng_start);
    __Runtime_launch_kernel_group(dev, __Runtime_load_kernel_group_nt(dev, tiles, 16));
    static WeEng e;
    we_init(&e, dev);
    g_e = &e;
    int fails = 0;
    fails += test_gemm(&e, "gemm qkv bias+KT", 384, 384, 1152, WE_F_KT, 1, 0, 0, 4, 8, 16);
    fails += test_gemm(&e, "gemm fc1 bias+gelu", 384, 384, 1536, WE_F_GELU, 1, 0, 0, 4, 0, 0);
    fails += test_gemm(&e, "gemm fc2 bias+res 3 passes", 384, 1536, 384, 0, 1, 1, 2, 4, 0, 0);
    fails += test_gemm(&e, "gemm decoder 1 row-block", 64, 384, 384, 0, 1, 0, 0, 1, 0, 0);
    fails += test_ln_gemm(&e, 384, 1152);
    fails += test_ln_gemm(&e, 384, 768);
    fails += test_gemm(&e, "gemm qkv again", 384, 384, 1152, 0, 1, 0, 0, 4, 0, 0);
    printf("ET1 %s\n", fails ? "FAIL" : "PASS");
    return fails;
}
