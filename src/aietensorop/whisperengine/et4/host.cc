/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * ET4: the encoder's op sequence conv1 -> conv2 -> LN -> QKV -> attention (hang repro), checked on the CPU.
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

static int tail(WeEng *ep, WeAct *xp, const char *tag, int use_ln, int use_bias) {
    WeEng &e = *ep;
    WeAct &x = *xp;
    printf("ET4 tail %s\n", tag);
    WeAct y = {dalloc((size_t)1536 * 384), 384, 384}, qkv = {dalloc((size_t)1536 * 1152), 384, 1152},
          o = {dalloc((size_t)1536 * 384), 384, 384};
    static bf16_t gm[384], bt[384], wq[1152 * 384], bq[1152];
    for (int i = 0; i < 384; i++) {
        gm[i] = f2bf(1 + rnd() * 0.2f);
        bt[i] = f2bf(rnd() * 0.2f);
    }
    for (int i = 0; i < 1152 * 384; i++)
        wq[i] = f2bf(rnd() * 0.05f);
    for (int i = 0; i < 1152; i++)
        bq[i] = f2bf(rnd() * 0.1f);
    bf16_t *wqp = dalloc(1152 * 384);
    we_pack_w(wqp, wq, 1152, 384, 1);
    __Runtime_sync_for_dev(dev_g, wqp, 1152 * 384 * 2);
    printf("ET4 ln=%d bias=%d\n", use_ln, use_bias);
    if (use_ln) {
        if (we_ln(&e, &x, gm, bt, 1e-5f, &y, 4))
            return 1;
    } else {
        memcpy(y.p, x.p, (size_t)1536 * 384 * 2);
        __Runtime_sync_for_dev(dev_g, y.p, (size_t)1536 * 384 * 2);
    }
    printf("ET4 qkv\n");
    WeGemm gq = {&y, wqp, use_bias ? bq : 0, 0, &qkv, 1152, WE_F_KT | WE_F_VT, 8, 16, 4, 0, 16, 24};
    if (we_gemm(&e, &gq))
        return 1;
    printf("ET4 attn\n");
    WeAttn at = {&qkv, 0, &qkv, 8, 16, &o, 1500, 0, 4, 4};
    if (we_attn(&e, &at)) {
        printf("ET4 FAIL attn\n");
        return 1;
    }
    printf("ET4 attn done\n");
    return 0;
}

int main() {
    printf("=== ET4: conv stem + logits ===\n");
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
    {
        WeAct x0 = {dalloc((size_t)1536 * 384), 384, 384};
        for (int i = 0; i < 1536 * 384; i++)
            x0.p[i] = f2bf(rnd());
        __Runtime_sync_for_dev(dev, x0.p, (size_t)1536 * 384 * 2);
        for (int v = 0; v < 4; v++)
            if (tail(&e, &x0, "variant", v & 1, v >> 1))
                return 1;
    }
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
    if (we_gemm(&e, &g1))
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
    if (we_gemm(&e, &g2))
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
    if (tail(&e, &x, "after conv", 1, 1))
        return 1;

    printf("ET4 %s\n", fails ? "FAIL" : "PASS");
    return fails;
}
