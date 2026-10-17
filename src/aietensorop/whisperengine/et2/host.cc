/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * ET2: attention through the engine, end to end from x: QKV GEMM (head-permuted
 * weights, K^T / V tile epilogues) then the flash-attention op, checked against
 * a CPU attention on the same bf16 q/k/v (scores in log2 units, exp2 softmax,
 * P rounded to bf16). Encoder shape (1500 of 1536 keys) and a causal decoder
 * shape (one active mesh row).
 ******************************************************************************/
#include "we_host.h"
#include <math.h>
#include <stdlib.h>

extern unsigned char _binary_kernel_eng_start[], _binary_kernel_att_start[];
static uint32_t g_seed = 7;
static float rnd() {
    g_seed = g_seed * 1664525u + 1013904223u;
    return ((g_seed >> 8) & 0xFFFF) / 32768.0f - 1.0f;
}
static XAie_DevInst *dev_g;
static WeAct act(int rb, int c) {
    WeAct t = {(bf16_t *)__Runtime_Alloc((size_t)4 * rb * c * 2), rb, c};
    memset(t.p, 0, we_act_bytes(&t));
    __Runtime_sync_for_dev(dev_g, t.p, we_act_bytes(&t)); /* else dirty zero lines evict over DMA output */
    return t;
}
static float at(const WeAct *t, int row, int col) { return bf2f(t->p[we_blk_idx(t->rb, t->c, row, col)]); }

static int test(WeEng *e, const char *name, int rb, int rows, int causal, int ract) {
    const int M = 4 * rb;
    WeAct x = act(rb, 384), qkv = act(rb, 1152), o = act(rb, 384);
    for (int i = 0; i < rows; i++)
        for (int j = 0; j < 384; j++)
            x.p[we_blk_idx(rb, 384, i, j)] = f2bf(rnd());
    __Runtime_sync_for_dev(e->dev, x.p, we_act_bytes(&x));
    // W rows: [q (scaled) | k | v], head-permuted per 384 block
    bf16_t *w = (bf16_t *)malloc((size_t)1152 * 384 * 2), *wp = (bf16_t *)malloc((size_t)1152 * 384 * 2);
    for (int i = 0; i < 1152 * 384; i++)
        w[i] = f2bf(rnd() * (i < 384 * 384 ? 0.15f : 0.08f));
    for (int part = 0; part < 3; part++)
        for (int h = 0; h < 6; h++)
            for (int d = 0; d < 64; d++)
                memcpy(wp + (size_t)(part * 384 + we_head_col(h, d)) * 384, w + (size_t)(part * 384 + h * 64 + d) * 384,
                       384 * 2);
    bf16_t *wq = (bf16_t *)__Runtime_Alloc((size_t)1152 * 384 * 2);
    we_pack_w(wq, wp, 1152, 384, 1);
    __Runtime_sync_for_dev(e->dev, wq, (size_t)1152 * 384 * 2);
    WeGemm g = {&x, wq, 0, 0, &qkv, 1152, WE_F_KT | WE_F_VT, 8, 16, ract, 0, 16, 24};
    if (we_gemm(e, &g) || we_drain(e))
        return 1;
    memset(o.p, 0xFF, we_act_bytes(&o));
    __Runtime_sync_for_dev(e->dev, o.p, we_act_bytes(&o));
    WeAttn a = {&qkv, 0, &qkv, 8, 16, &o, rows, causal, ract, ract};
    XTime t0, t1;
    XTime_GetTime(&t0);
    if (we_attn(e, &a) || we_drain(e))
        return 1;
    XTime_GetTime(&t1);
    __Runtime_sync_for_cpu(e->dev, o.p, we_act_bytes(&o));
    if (rb == 64 && !causal && rows == 64) { /* core (1,3) buffers after round 2: head 4, q-block 0 */
        __Runtime_sync_for_cpu(e->dev, qkv.p, we_act_bytes(&qkv));
        const u32 ARENA = 0x0C00, AQ = ARENA + 0xA000, AB0 = ARENA + 0x2000, AB1 = ARENA + 0x4000;
        long qb = 0, kb = 0, vb = 0;
        for (int w = 0; w < 1024; w++) {
            u32 gq, gk, gv;
            XAie_DataMemRdWord(dev_g, XAie_TileLoc(1, 3), AQ + 4 * w, &gq);
            XAie_DataMemRdWord(dev_g, XAie_TileLoc(1, 3), AB0 + 4 * w, &gk);
            XAie_DataMemRdWord(dev_g, XAie_TileLoc(1, 3), AB1 + 4 * w, &gv);
            uint16_t wq[2], wk[2], wv[2];
            for (int z2 = 0; z2 < 2; z2++) {
                const int e2 = w * 2 + z2;
                { /* Q [rg8][kd8][4][8] */
                    const int rg = e2 / 256, kd = (e2 / 32) % 8, i = (e2 / 8) % 4, j = e2 % 8;
                    wq[z2] = qkv.p[we_blk_idx(64, 1152, rg * 4 + i, we_head_col(4, kd * 8 + j))];
                }
                { /* K^T [kd8][kp8][8 dims][8 keys] (first half of 8 KB) */
                    const int kd = e2 / 512, kp = (e2 / 64) % 8, dd = (e2 / 8) % 8, kk = e2 % 8;
                    const int key = kp * 8 + kk, col = 384 + we_head_col(4, kd * 8 + dd);
                    const int cb = col / 48, dt = (col % 48) / 8, d8 = col % 8;
                    wk[z2] = qkv.p[((size_t)cb * 64) * 48 + ((dt * 8 + key / 8) * 8 + d8) * 8 + key % 8];
                }
                { /* V [kp8][dt8][8 keys][8 dims] */
                    const int kp = e2 / 512, dt = (e2 / 64) % 8, kk = (e2 / 8) % 8, dd = e2 % 8;
                    const int key = kp * 8 + kk, col = 768 + we_head_col(4, dt * 8 + dd);
                    const int cb = col / 48, nt = (col % 48) / 8, d8 = col % 8;
                    wv[z2] = qkv.p[((size_t)cb * 64) * 48 + ((key / 8 * 6 + nt) * 8 + key % 8) * 8 + d8];
                }
            }
            if (gq != (wq[0] | ((u32)wq[1] << 16)) && qb++ < 3)
                printf("  CORE Q word %d got %08x want %04x%04x\n", w, (unsigned)gq, wq[1], wq[0]);
            if (gk != (wk[0] | ((u32)wk[1] << 16)) && kb++ < 3)
                printf("  CORE K word %d got %08x want %04x%04x\n", w, (unsigned)gk, wk[1], wk[0]);
            if (gv != (wv[0] | ((u32)wv[1] << 16)) && vb++ < 3)
                printf("  CORE V word %d got %08x want %04x%04x\n", w, (unsigned)gv, wv[1], wv[0]);
        }
        printf("ET2 core(1,3) buffers: Q bad %ld, K bad %ld (first 4 KB), V bad %ld (first 4 KB)\n", qb, kb, vb);
    }
    if (rb == 384) { /* round 2 left heads 4,4,5,5 in MT_B: check the gathered chunks of column 0 (head 4) */
        __Runtime_sync_for_cpu(e->dev, qkv.p, we_act_bytes(&qkv));
#ifdef WE_ATT_R1ONLY
        const int h = 0;
#else
        const int h = 4;
#endif
        long nz = 0;
        for (size_t i = 0; i < (size_t)4 * 384 * 1152; i++)
            nz += qkv.p[i] != 0;
        printf("  qkv nonzero %ld of %ld; KT(0,9,0)[1056]=%04x q(0,0)=%04x\n", nz, (long)4 * 384 * 1152,
               qkv.p[(size_t)(9 * 384) * 48 + 1056], qkv.p[0]);
        long kbad = 0, vbad = 0;
        for (int ch = 0; ch < 24; ch++) /* 64-key chunks of 16 KB: K^T 2048 words then V 2048 */
            for (int w = 0; w < 4096; w++) {
                u32 got;
                XAie_DataMemRdWord(dev_g, we_mt(1, EF_MT_B_ROW), (u32)(ch * 16384 + w * 4), &got);
                const int isv = w >= 2048, el = (w % 2048) * 2;
                uint16_t want[2];
                for (int z2 = 0; z2 < 2; z2++) {
                    const int e2 = el + z2;
                    int key, dim;
                    if (!isv) { /* [kd 8][kp 8][8 dims][8 keys] */
                        const int kd = e2 / 512, kp = (e2 / 64) % 8, dd = (e2 / 8) % 8, kk = e2 % 8;
                        key = ch * 64 + kp * 8 + kk;
                        dim = kd * 8 + dd;
                        const int col = we_head_col(h, dim), cb = 8 + col / 48, dt = (col % 48) / 8, d8 = col % 8;
                        const int r = key / 384, mb = (key % 384) / 64, kp8 = (key % 64) / 8, k8 = key % 8;
                        want[z2] =
                            qkv.p[((size_t)(r * 24 + cb) * 384 + mb * 64) * 48 + ((dt * 8 + kp8) * 8 + d8) * 8 + k8];
                    } else { /* [kp 8][dt 8][8 keys][8 dims] */
                        const int kp = e2 / 512, dt = (e2 / 64) % 8, kk = (e2 / 8) % 8, dd = e2 % 8;
                        key = ch * 64 + kp * 8 + kk;
                        dim = dt * 8 + dd;
                        const int col = we_head_col(h, dim), cb = 16 + col / 48, nt = (col % 48) / 8, d8 = col % 8;
                        const int r = key / 384, mb = (key % 384) / 64, kp8 = (key % 64) / 8, k8 = key % 8;
                        want[z2] =
                            qkv.p[((size_t)(r * 24 + cb) * 384 + mb * 64) * 48 + ((kp8 * 6 + nt) * 8 + k8) * 8 + d8];
                    }
                }
                const u32 wv = want[0] | ((u32)want[1] << 16);
                if (got != wv) {
                    if (isv ? vbad++ < 3 : kbad++ < 3)
                        printf("  MT_B chunk %d word %d (%s): got %08x want %08x\n", ch, w, isv ? "V" : "K",
                               (unsigned)got, (unsigned)wv);
                }
            }
        printf("ET2 MT_B gather check head 4: K bad words %ld, V bad words %ld\n", kbad, vbad);
    }
    printf("ET2 %-20s attention %.1f us (fill %.1f arm %.1f run %.1f)\n", name, we_us(t0, t1), e->t_fill, e->t_arm,
           e->t_run);
    e->t_fill = e->t_arm = e->t_run = 0;
    // reference on CPU: q,k,v from x (bf16-rounded like the GEMM), per head
    static float q[1536][384], k[1536][384], v[1536][384];
    for (int i = 0; i < rows; i++)
        for (int n = 0; n < 1152; n++) {
            float acc = 0;
            for (int kk = 0; kk < 384; kk++)
                acc += at(&x, i, kk) * bf2f(w[(size_t)n * 384 + kk]);
            const float r = bf2f(f2bf(acc));
            if (n < 384)
                q[i][n] = r;
            else if (n < 768)
                k[i][n - 384] = r;
            else
                v[i][n - 768] = r;
        }
    long bad = 0, cnt = 0;
    double maxe = 0;
    static int hist[4][8][6], tot[4][8][6];
    memset(hist, 0, sizeof(hist));
    memset(tot, 0, sizeof(tot));
    static float srow[1536], prow[1536];
    for (int i = 0; i < rows; i += (rows > 64 ? 23 : 1))
        for (int h = 0; h < 6; h++) {
            float m = -1e30f;
            const int nk = causal ? i + 1 : rows;
            for (int j = 0; j < nk; j++) {
                float s = 0;
                for (int d = 0; d < 64; d++)
                    s += q[i][h * 64 + d] * k[j][h * 64 + d];
                srow[j] = s;
                m = s > m ? s : m;
            }
            double l = 0;
            for (int j = 0; j < nk; j++) {
                const float p = exp2f(srow[j] - m);
                l += p;
                prow[j] = bf2f(f2bf(p));
            }
            if (rows <= 64 && h == 0 && (i == 0 || i == 5)) {
                printf("  ROW %d want:", i);
                for (int d = 0; d < 64; d++) {
                    double a2 = 0;
                    for (int j = 0; j < nk; j++)
                        a2 += prow[j] * v[j][d];
                    printf(" %.3f", a2 / l);
                }
                printf("\n");
            }
            for (int d = 0; d < 64; d++) {
                double acc = 0;
                for (int j = 0; j < nk; j++)
                    acc += prow[j] * v[j][h * 64 + d];
                const double want = acc / l;
                const float got = at(&o, i, we_head_col(h, d));
                const double err = fabs(got - want);
                if (err > maxe || got != got)
                    maxe = got != got ? 1e30 : err;
                const int rbk = i / rb, qbk = (i % rb) / WE_QB;
                tot[rbk][qbk][h]++;
                if (!(err <= fabs(want) / 32 + 0.01)) {
                    hist[rbk][qbk][h]++;
                    if (bad++ < 3)
                        printf("  %s row %d head %d dim %d: got %f want %f\n", name, i, h, d, got, want);
                }
                cnt++;
            }
        }
    if (bad)
        for (int r = 0; r < 4; r++)
            for (int qbk = 0; qbk < 8; qbk++) {
                int any = 0;
                for (int h = 0; h < 6; h++)
                    any += hist[r][qbk][h];
                if (!any)
                    continue;
                printf("  rowblock %d qblock %d bad/total per head:", r, qbk);
                for (int h = 0; h < 6; h++)
                    printf(" %d/%d", hist[r][qbk][h], tot[r][qbk][h]);
                printf("\n");
            }
    if (rows <= 64) { /* decoder: row 0 / row 5, head 0, all dims */
        for (int i = 0; i < 6; i += 5) {
            printf("  ROW %d got :", i);
            for (int d = 0; d < 64; d++)
                printf(" %.3f", at(&o, i, we_head_col(0, d)));
            printf("\n");
        }
    }
    printf("ET2 %-20s %s (%ld / %ld bad, max err %.3g)\n", name, bad ? "FAIL" : "PASS", bad, cnt, maxe);
    return bad != 0;
}

int main() {
    printf("=== ET2: engine attention ===\n");
    /* two kernel programs (GEMM, attention) swapped over the control-packet plane, as eng/host.cc */
    __Runtime_ctrl_high_throughput_enable(1);
    __Runtime_ctrl_pmap_enable(0);
    XAie_DevInst *dev = __Runtime_init_mesh_partition(0, EF_PART_START_COL, EF_PART_NUM_COLS);
    static __Runtime_CtrlRowFabric fab;
    static const __Runtime_CtrlRowChain fab_rows[] = {{3, 1, 4}, {4, 1, 4}, {5, 1, 4}, {6, 1, 4}};
    __Runtime_ctrl_plan_init(&fab, dev, 0, 0, 1, fab_rows, 4);
    __Runtime_ctrl_plan_set_exclusive(&fab, 1);
    XAie_LocType tiles[16];
    for (int r = 0; r < 4; r++)
        for (int c = 0; c < 4; c++)
            tiles[r * 4 + c] = XAie_TileLoc((uint8_t)(EF_FIRST_COL + c), (uint8_t)(EF_FIRST_ROW + r));
    static WeEng e;
    we_init(&e, dev);
    e.ctrl = &fab;
    e.prog[1] = _binary_kernel_eng_start, e.prog[2] = _binary_kernel_att_start;
    memcpy(e.tiles, tiles, sizeof(tiles));
    if (we_prog(&e, 1))
        return 1;
    dev_g = dev;
    int fails = 0;
    fails += test(&e, "dec nomask T64", 64, 64, 0, 1);
    fails += test(&e, "dec T20 noncausal", 64, 20, 0, 1);
    fails += test(&e, "decoder causal", 64, 20, 1, 1);
    fails += test(&e, "encoder 1500", 384, 1500, 0, 4);
    printf("ET2 %s\n", fails ? "FAIL" : "PASS");
    return fails;
}
