/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * ET3: Whisper's conv stem and logits through the engine, checked on the CPU.
 * conv1: A = overlapping windows of the time-major mel (K 240 -> 288), GELU,
 *        row-major output one row down (row 0 = conv2's zero padding).
 * conv2: A = windows of conv1's output (stride 2 rows, 1152 wide), GELU, then
 *        + positional embedding as the residual, BLK output.
 * logits: one active row, fp32 first-row-group output.
 ******************************************************************************/
#include "we_host.h"
#include <math.h>
#include <stdlib.h>

extern unsigned char _binary_kernel_eng_start[];
static XAie_DevInst *dev_g;
static uint32_t g_seed = 11;
static float rnd() {
    g_seed = g_seed * 1664525u + 1013904223u;
    return ((g_seed >> 8) & 0xFFFF) / 32768.0f - 1.0f;
}
static bf16_t *dalloc(size_t n) {
    bf16_t *p = (bf16_t *)__Runtime_Alloc(n * 2);
    memset(p, 0, n * 2);
    __Runtime_sync_for_dev(dev_g, p, n * 2);
    return p;
}
static float gelu_ref(float xb) {
    if (xb >= 4)
        return xb;
    if (xb <= -4)
        return 0;
    if (fabsf(xb) < 0.125f)
        return bf2f(f2bf(0.5f * xb + bf2f(f2bf(xb * xb)) * bf2f(f2bf(0.3989422804f))));
    return bf2f(f2bf((float)(0.5 * xb * (1.0 + erf(xb / sqrt(2.0))))));
}
static int report(const char *n, long bad, long cnt, double maxe) {
    printf("ET3 %-12s %s (%ld / %ld bad, max err %.3g)\n", n, bad ? "FAIL" : "PASS", bad, cnt, maxe);
    return bad != 0;
}

int main() {
    printf("=== ET3: conv stem + logits ===\n");
    XAie_DevInst *dev = __Runtime_init_mesh_partition(0, EF_PART_START_COL, EF_PART_NUM_COLS);
    dev_g = dev;
    XAie_LocType tiles[16];
    for (int r = 0; r < 4; r++)
        for (int c = 0; c < 4; c++)
            tiles[r * 4 + c] = XAie_TileLoc((uint8_t)(EF_FIRST_COL + c), (uint8_t)(EF_FIRST_ROW + r));
    __Runtime_set_kernel_elf(_binary_kernel_eng_start);
    __Runtime_launch_kernel_group(dev, __Runtime_load_kernel_group_nt(dev, tiles, 16));
    static WeEng e;
    we_init(&e, dev);
    int fails = 0;
    // ---- conv1: mel_rm [3074][80] (row 0 and 3001.. zero), A row t = mel_rm[t*80 .. +240]
    bf16_t *mel = dalloc((size_t)3080 * 80);
    for (int t = 1; t <= 3000; t++)
        for (int c = 0; c < 80; c++)
            mel[t * 80 + c] = f2bf(rnd());
    __Runtime_sync_for_dev(dev, mel, (size_t)3080 * 80 * 2);
    static bf16_t w1[384 * 288], w2[384 * 1152], b1[384], b2[384];
    for (int i = 0; i < 384 * 288; i++)
        w1[i] = (i % 288) < 240 ? f2bf(rnd() * 0.1f) : 0;
    for (int i = 0; i < 384 * 1152; i++)
        w2[i] = f2bf(rnd() * 0.05f);
    for (int i = 0; i < 384; i++) {
        b1[i] = f2bf(rnd() * 0.3f);
        b2[i] = f2bf(rnd() * 0.3f);
    }
    bf16_t *w1p = dalloc(384 * 288), *w2p = dalloc(384 * 1152);
    we_pack_w(w1p, w1, 384, 288, 3);
    we_pack_w(w2p, w2, 384, 1152, 2);
    __Runtime_sync_for_dev(dev, w1p, 384 * 288 * 2);
    __Runtime_sync_for_dev(dev, w2p, 384 * 1152 * 2);
    bf16_t *x1 = dalloc((size_t)3080 * 384); /* conv1 out, row r+1 = time r */
    WeAct a1 = {0, 768, 288};
    WeGemm g1 = {&a1, w1p, b1, 0, 0, 384, WE_F_GELU | WE_F_ROWMAJOR, 0, 0, 4, 4, 0, 0, mel, 80, 240, x1 + 384, 0};
    XTime t0, t1, t2;
    XTime_GetTime(&t0);
    if (we_gemm(&e, &g1) || we_drain(&e))
        return 1;
    XTime_GetTime(&t1);
    // conv2: A row t' = x1[(2t') * 384 .. + 1152], + pos residual (BLK)
    WeAct pos = {dalloc((size_t)1536 * 384), 384, 384}, x = {dalloc((size_t)1536 * 384), 384, 384};
    for (int i = 0; i < 1536; i++)
        for (int j = 0; j < 384; j++)
            pos.p[we_blk_idx(384, 384, i, j)] = f2bf(rnd());
    __Runtime_sync_for_dev(dev, pos.p, (size_t)1536 * 384 * 2);
    WeAct a2 = {0, 384, 1152};
    WeGemm g2 = {&a2, w2p, b2, &pos, &x, 384, WE_F_GELU, 0, 0, 4, 2, 0, 0, x1, 768, 1152, 0, 0};
    if (we_gemm(&e, &g2) || we_drain(&e))
        return 1;
    XTime_GetTime(&t2);
    printf("ET3 conv1 %.1f us, conv2 %.1f us (fill %.1f arm %.1f run %.1f)\n", we_us(t0, t1), we_us(t1, t2), e.t_fill,
           e.t_arm, e.t_run);
    __Runtime_sync_for_cpu(dev, x1, (size_t)3080 * 384 * 2);
    __Runtime_sync_for_cpu(dev, x.p, (size_t)1536 * 384 * 2);
    long bad = 0, cnt = 0;
    double maxe = 0;
    for (int t = 0; t < 3000; t += 7)
        for (int n = 0; n < 384; n++) {
            float acc = 0;
            for (int k = 0; k < 240; k++)
                acc += bf2f(mel[t * 80 + k]) * bf2f(w1[n * 288 + k]);
            const float want = gelu_ref(bf2f(f2bf(acc + bf2f(b1[n])))), got = bf2f(x1[(t + 1) * 384 + n]);
            const double err = fabs(got - want);
            maxe = err > maxe ? err : maxe;
            if (!(err <= fabs(want) / 64 + 0.01) && bad++ < 3)
                printf("  conv1 t %d n %d: got %f want %f\n", t, n, got, want);
            cnt++;
        }
    fails += report("conv1", bad, cnt, maxe);
    bad = cnt = 0;
    maxe = 0;
    for (int t = 0; t < 1500; t += 5)
        for (int n = 0; n < 384; n++) {
            float acc = 0;
            for (int k = 0; k < 1152; k++)
                acc += bf2f(x1[(size_t)2 * t * 384 + k]) * bf2f(w2[n * 1152 + k]);
            const float g = gelu_ref(bf2f(f2bf(acc + bf2f(b2[n]))));
            const float want = bf2f(f2bf(g + bf2f(pos.p[we_blk_idx(384, 384, t, n)])));
            const float got = bf2f(x.p[we_blk_idx(384, 384, t, n)]);
            const double err = fabs(got - want);
            maxe = err > maxe ? err : maxe;
            if (!(err <= fabs(want) / 64 + 0.02) && bad++ < 3)
                printf("  conv2 t %d n %d: got %f want %f\n", t, n, got, want);
            cnt++;
        }
    fails += report("conv2", bad, cnt, maxe);
    // ---- logits: x_last [64 x 384] (row 0), E [1536 x 384]
    WeAct xl = {dalloc((size_t)256 * 384), 64, 384};
    for (int j = 0; j < 384; j++)
        xl.p[we_blk_idx(64, 384, 0, j)] = f2bf(rnd());
    __Runtime_sync_for_dev(dev, xl.p, (size_t)256 * 384 * 2);
    static bf16_t E[1536 * 384];
    for (int i = 0; i < 1536 * 384; i++)
        E[i] = f2bf(rnd() * 0.2f);
    bf16_t *Ep = dalloc(1536 * 384);
    we_pack_w(Ep, E, 1536, 384, 1);
    __Runtime_sync_for_dev(dev, Ep, 1536 * 384 * 2);
    float *lg = (float *)__Runtime_Alloc(1536 / 48 * 768);
    memset(lg, 0xFF, 1536 / 48 * 768);
    __Runtime_sync_for_dev(dev, lg, 1536 / 48 * 768);
    WeGemm g3 = {&xl, Ep, 0, 0, 0, 1536, WE_F_LOGIT, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, lg};
    XTime_GetTime(&t0);
    if (we_gemm(&e, &g3) || we_drain(&e))
        return 1;
    XTime_GetTime(&t1);
    __Runtime_sync_for_cpu(dev, lg, 1536 / 48 * 768);
    bad = cnt = 0;
    maxe = 0;
    for (int n = 0; n < 1536; n++) {
        float acc = 0;
        for (int k = 0; k < 384; k++)
            acc += bf2f(xl.p[we_blk_idx(64, 384, 0, k)]) * bf2f(E[n * 384 + k]);
        const float got = lg[(n / 48) * 192 + ((n % 48) / 8) * 32 + n % 8]; /* [tile][nt][row 0][8] */
        const double err = fabs(got - acc);
        maxe = err > maxe || got != got ? (got != got ? 1e30 : err) : maxe;
        if (!(err <= 1e-3 + fabs(acc) * 1e-4) && bad++ < 3)
            printf("  logit %d: got %f want %f\n", n, got, acc);
        cnt++;
    }
    printf("ET3 logits 1536: %.1f us\n", we_us(t0, t1));
    fails += report("logits", bad, cnt, maxe);
    printf("ET3 %s\n", fails ? "FAIL" : "PASS");
    return fails;
}
