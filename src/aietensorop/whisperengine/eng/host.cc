/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * Whisper-tiny on the AIE: every layer of the encoder and of the greedy
 * decoder runs on the persistent engine (eng/kernel.cc), kernel loaded once.
 * Weights + the JFK mel come from gen_engine.py (blob.bin, eng_net.h); the
 * run is checked against we_model.EngineModel, the engine's exact numerics
 * (checkpoints after conv2 / block 0 / ln_post, step-0 logits) and the
 * transcript tokens. The A78 only embeds tokens, takes the argmax and moves
 * tensor pointers; doc/design/whisper_aie_engine.md.
 ******************************************************************************/
#include "we_host.h"
#include "eng_net.h"
#include "xil_mmu.h"

#include <math.h>
#include <stdlib.h>

extern unsigned char _binary_kernel_eng_start[], _binary_kernel_att_start[];
#define INCBIN(sym, path)                                                                                              \
    __asm__(".section .rodata\n.balign 64\n.global " #sym "\n" #sym ":\n.incbin \"" path "\"\n.previous\n")
INCBIN(wn_blob, WN_BLOB_PATH);
INCBIN(wn_gold, WN_GOLD_PATH);
extern const uint8_t wn_blob[], wn_gold[];
#define W(off) ((const bf16_t *)(wn_blob + (off)))

static XAie_DevInst *g_dev;
static WeEng g_e;
static double g_macs_enc;

static WeAct act(int rb, int c) {
    WeAct t = {(bf16_t *)__Runtime_Alloc((size_t)4 * rb * c * 2), rb, c};
    memset(t.p, 0, we_act_bytes(&t));
    __Runtime_sync_for_dev(g_dev, t.p, we_act_bytes(&t));
    return t;
}

static double now_us(void) {
    XTime t;
    XTime_GetTime(&t);
    return 1e6 * (double)t / COUNTS_PER_SECOND;
}

static int g_trace = 1;
/* per-op-type wall time of the encoder (us); LayerNorms are folded into qkv / fc1 / xkv */
enum { P_CONV, P_QKV, P_ATTN, P_OUT, P_FC1, P_FC2, P_XKV, P_N };
static double g_pt[P_N], g_pf[P_N], g_pa[P_N], g_pr[P_N]; /* wall, fill, arm, run */
static double g_prd[P_N], g_pwr[P_N];                     /* DDR bytes read / written */
static const char *g_pn[P_N] = {"conv", "qkv", "attn", "out", "fc1", "fc2", "xkv"};
#ifdef WE_PROF_GOP          /* per op kind core(1,3) cycles (kernel WE_PROF_G): drains after every op */
static double g_pc[P_N][6]; /* op total, mac, ln apply, epilogue, chunks, ln stats */
static void prof_op(int k) {
    we_drain(&g_e);
    u32 w[16];
    for (int i = 7; i < 14; i++)
        XAie_DataMemRdWord(g_dev, XAie_TileLoc(1, 3), 0x07C0 + 4 * i, &w[i]);
#ifdef WE_PROF_MAC2
    {
        u32 m2;
        XAie_DataMemRdWord(g_dev, XAie_TileLoc(1, 3), 0x07C0 + 4 * 9, &m2);
        if (w[12])
            printf("WHISPER   %-5s mac first %u, back-to-back again %u cyc/chunk\n", g_pn[k], w[10] / w[12],
                   m2 / w[12]);
        XAie_DataMemWrWord(g_dev, XAie_TileLoc(1, 3), 0x07C0 + 4 * 9, 0);
    }
#endif
    g_pc[k][0] += w[11], g_pc[k][1] += w[10], g_pc[k][2] += w[7], g_pc[k][3] += w[13], g_pc[k][4] += w[12],
        g_pc[k][5] += w[8];
    for (int i = 7; i < 14; i++)
        XAie_DataMemWrWord(g_dev, XAie_TileLoc(1, 3), 0x07C0 + 4 * i, 0);
}
#define PROF_OP(k) prof_op(k)
#else
#define PROF_OP(k)
#endif
#define PT(k, call)                                                                                                    \
    ({                                                                                                                 \
        const double _t0 = now_us(), _f = g_e.t_fill, _a = g_e.t_arm, _r = g_e.t_run, _br = g_e.b_rd, _bw = g_e.b_wr;  \
        const int _rc = (call);                                                                                        \
        PROF_OP(k);                                                                                                    \
        g_pt[k] += now_us() - _t0;                                                                                     \
        g_pf[k] += g_e.t_fill - _f, g_pa[k] += g_e.t_arm - _a, g_pr[k] += g_e.t_run - _r;                              \
        g_prd[k] += g_e.b_rd - _br, g_pwr[k] += g_e.b_wr - _bw;                                                        \
        _rc;                                                                                                           \
    })
#define TR(name) (g_trace ? printf("WE op %s\n", name) : 0)

/* K^T / V tile ranges: self-attention q|k|v = tiles 8..16 / 16..24; cross k|v = 0..8 / 8..16 */
static int g_kt0 = 8;
static int g_ws; /* decoder + cross K/V: hi/lo split weights (gen_engine add_gemm hilo) */
/* LayerNorm folded into a GEMM (we_desc.h WE_F_LN): gen_engine's <name>_ln block,
 * d fp32 [n] then c_hi, c_lo bf16 [n] */
static void set_ln(WeGemm *g, size_t ln, int n, int c0) {
    if (!ln)
        return;
    g->lnd = (const float *)(wn_blob + ln) + c0;
    g->lnc = (const bf16_t *)(wn_blob + ln + (size_t)n * 4) + c0;
    g->lnn = n;
}
static int g_stor; /* we_gemm storage mode for the next gemm() (encoder FC1 / FC2: hidden kept on chip) */
static int gemm(const WeAct *a, size_t w, size_t b, size_t ln, const WeAct *res, const WeAct *out, int n, int flags,
                int mbp, int ract) {
    TR("gemm");
    WeGemm g = {a, W(w), b ? W(b) : 0, res, out, n, flags, g_kt0, g_kt0 + 8, ract, mbp, g_kt0 + 8, g_kt0 + 16};
    g.wsplit = g_ws;
    g.stor = g_stor;
    if (g_stor == WE_ST_IN) /* FC2 reads FC1's [chunk][block 2] tiles, the out-projection attention's tile */
        g.st_j0 = a->c == 384 ? 1 : 0, g.st_ppt = a->c == 384 ? 6 : 2,
        g.st_cs = a->c == 384 ? 384 * 48 * 2 : 2 * WE_BLK;
    set_ln(&g, ln, n, 0);
    if (!(flags & WE_F_KT))
        g.kt_lo = g.kt_hi = 0;
    if (!(flags & WE_F_VT))
        g.vt_lo = g.vt_hi = 0;
    return we_gemm(&g_e, &g);
}
static int gemm_kv(const WeAct *a, size_t w, size_t ln, const WeAct *out) {
    g_kt0 = 0;
    g_ws = 1;
    const int rc = gemm(a, w, 0, ln, 0, out, 768, WE_F_KT | WE_F_VT, 3, 4); /* 2 passes: hi/lo chain <= 11 BDs */
    g_ws = 0;
    g_kt0 = 8;
    return rc;
}
static WeAct colview(const WeAct *t, int c0, int n) {
    WeAct v = {t->p + (size_t)(c0 / 48) * we_tile_elems(t), t->rb, n, t->ct ? t->ct : t->c / 48};
    return v;
}
/* split-weight GEMM in N chunks of nch columns (packed independently, gen_engine nchunk) */
static int gemm_n(const WeAct *a, size_t w, size_t b, size_t ln, const WeAct *res, const WeAct *out, int n, int nch,
                  int flags, int ract) {
    const int kp = a->c * 2;
    for (int c0 = 0; c0 < n; c0 += nch) {
        const WeAct ov = colview(out, c0, nch), rv = res ? colview(res, c0, nch) : ov;
        WeGemm g = {a, W(w) + (size_t)c0 * kp, b ? W(b) + c0 : 0, res ? &rv : 0, &ov, nch, flags, 0, 0, ract, 0, 0, 0};
        g.wsplit = 1;
        set_ln(&g, ln, n, c0);
        if (we_gemm(&g_e, &g))
            return -1;
    }
    return 0;
}
static int g_qst; /* encoder: Q left on chip by the Q/K/V GEMM (WE_ST_OUTQ) */
static int attn(const WeAct *q, const WeAct *kv, int kt, int vt, const WeAct *o, int t, int causal, int ract,
                int krows) {
    TR("attn");
    WeAttn a = {q, 0,      kv,   kt,    vt,    o,
                t, causal, ract, krows, g_qst, 0}; /* ost: measured slower (out-proj 1 block/pass) */
    return we_attn(&g_e, &a);
}

// bf16 tensors vs golden: count elements more than 2 bf16 ulp apart (rows < valid)
static int check(const char *name, const WeAct *t, size_t goff, int valid) {
    we_drain(&g_e); /* the last GEMM may still be running */
    __Runtime_sync_for_cpu(g_dev, t->p, we_act_bytes(t));
    const bf16_t *g = (const bf16_t *)(wn_gold + goff);
    long far = 0, n = 0;
    double maxe = 0;
    for (int i = 0; i < valid; i++)
        for (int j = 0; j < t->c; j++) {
            const size_t k = we_blk_idx(t->rb, t->c, i, j);
            const float a = bf2f(t->p[k]), b = bf2f(g[k]);
            const double d = fabs(a - b), tol = fabs(b) * (2.0 / 128) + 1e-3;
            maxe = d > maxe ? d : maxe;
            far += !(d <= tol);
            n++;
        }
    printf("WHISPER check %-8s %ld / %ld beyond 2 ulp, max |diff| %.4g\n", name, far, n, maxe);
    /* Report only. bf16 rounding flips (accumulation order, hw exp2) amplify through
     * the blocks: the reference model itself, under +-1 fp32 ulp noise, differs from
     * its noiseless run by 3.5% / 14% / 44% of elements after block 0 / 1 / ln_post
     * (worklocal drift probe). The transcript is the verdict. */
    return 0;
}

typedef struct {
    WeAct x, x2, qkv, o, h, kvx[4];
    bf16_t *x1;
} Enc;

static int encoder(Enc *E, int verify) {
    const double t0 = now_us();
    {
        WeAct a1 = {0, 768, 288};
        WeGemm g = {
            &a1, W(WN_CONV1_W), W(WN_CONV1_B), 0, 0, 384, WE_F_GELU | WE_F_ROWMAJOR, 0, 0, 4, 1, 0, 0, W(WN_MEL),
            80,  240,           E->x1 + 384,   0, 0};
        if (PT(P_CONV, we_gemm(&g_e, &g)))
            return -1;
        WeAct a2 = {0, 384, 1152}, pos = {(bf16_t *)W(WN_POS_ENC), 384, 384};
        WeGemm g2 = {&a2, W(WN_CONV2_W), W(WN_CONV2_B), &pos, &E->x, 384, WE_F_GELU, 0, 0, 4, 1, 0,
                     0,   E->x1,         768,           1152, 0,     0,   0};
        if (PT(P_CONV, we_gemm(&g_e, &g2)))
            return -1;
    }
    if (verify && check("conv", &E->x, WN_G_X0, 1500))
        return -1;
    static const size_t L[4][8] = {
#define ROW(l)                                                                                                         \
    {WN_E##l##_QKV_W, WN_E##l##_QKV_LN, WN_E##l##_OUT_W, WN_E##l##_OUT_B,                                              \
     WN_E##l##_FC1_W, WN_E##l##_FC1_LN, WN_E##l##_FC2_W, WN_E##l##_FC2_B}
        ROW(0), ROW(1), ROW(2), ROW(3)};
#undef ROW
    for (int l = 0; l < 4; l++) {
        const size_t *p = L[l];
        if ((g_stor = WE_ST_OUTQ, PT(P_QKV, gemm(&E->x, p[0], 0, p[1], 0, &E->qkv, 1152, WE_F_KT | WE_F_VT, 0, 4))) ||
            (g_stor = 0, g_qst = 1, PT(P_ATTN, attn(&E->qkv, &E->qkv, 8, 16, &E->o, 1500, 0, 4, 4))) ||
            (g_qst = 0, g_stor = 0, PT(P_OUT, gemm(&E->o, p[2], p[3], 0, &E->x, &E->x2, 384, 0, 3, 4))) ||
            (g_stor = WE_ST_OUT, PT(P_FC1, gemm(&E->x2, p[4], 0, p[5], 0, &E->h, 1536, WE_F_GELU, 2, 4))) ||
            (g_stor = WE_ST_IN, PT(P_FC2, gemm(&E->h, p[6], p[7], 0, &E->x2, &E->x, 384, 0, 1, 4))))
            return -1;
        g_stor = 0;
        static const size_t gx[4] = {WN_G_X1, WN_G_X2, WN_G_X3, WN_G_X4};
        static const char *gn[4] = {"block0", "block1", "block2", "block3"};
        if (verify && check(gn[l], &E->x, gx[l], 1500))
            return -1;
    }
    /* cross K/V of every decoder layer, ln_post folded in */
    const size_t xkv[4][2] = {
        {WN_X0_KV_W, WN_X0_KV_LN}, {WN_X1_KV_W, WN_X1_KV_LN}, {WN_X2_KV_W, WN_X2_KV_LN}, {WN_X3_KV_W, WN_X3_KV_LN}};
    for (int l = 0; l < 4; l++)
        if (PT(P_XKV, gemm_kv(&E->x, xkv[l][0], xkv[l][1], &E->kvx[l])))
            return -1;
    if (PT(P_XKV, we_drain(&g_e)))
        return -1;
    return (int)(now_us() - t0);
}

// token embedding row from the packed logits weight: slices of WN_LOGIT_SLICE rows,
// W' = [hi | lo] of gamma_ln (.) E (K' = 768, the final LayerNorm folded in), we_pack_w
// order (row tile T = (sub * 4 + c) * NBS + nb); E = (hi + lo) / gamma_ln in fp32
// (we_model emb_lookup)
static void emb_row(int tok, float *out) {
    const bf16_t *gam = W(WN_LND_G);
    const int s = tok / WN_LOGIT_SLICE, n = tok % WN_LOGIT_SLICE, kcn = 16;
    const int nbs = we_gemm_nbs(WN_LOGIT_SLICE, 1), T = n / 48, sub = T / (4 * nbs);
    const int c = (T / nbs) % 4, nb = sub * nbs + T % nbs, nt = (n % 48) / 8, nn = n % 8;
    const size_t col = (size_t)WN_LOGIT_SLICE / 4 * 768;
    const bf16_t *base = W(WN_EMB0_W + (size_t)s * (WN_EMB1_W - WN_EMB0_W)) + c * col;
    for (int k = 0; k < 384; k++) {
        float v = 0;
        for (int half = 0; half < 2; half++) {
            const int kk2 = k + half * 384, kc = kk2 / 48, kt = (kk2 % 48) / 8, kk = kk2 % 8;
            v += bf2f(base[((((size_t)nb * kcn + kc) * 6 + kt) * 6 + nt) * 64 + kk * 8 + nn]);
        }
        out[k] = v / bf2f(gam[k]);
    }
}

typedef struct {
    WeAct x, x2, qkv, o, q, h;
    float *logits;
} Dec;

// one greedy step over all n tokens so far; returns the argmax token
static int g_dcheck;
static void dcheck(const char *name, const WeAct *t, size_t goff, int n) {
    if (g_dcheck)
        check(name, t, goff, n);
}
static int decode_step(Enc *E, Dec *D, const int *toks, int n, float *lg_out) {
    const float *pos = (const float *)(wn_blob + WN_DEC_POS);
    memset(D->x.p, 0, we_act_bytes(&D->x));
    for (int i = 0; i < n; i++) {
        float e[384];
        emb_row(toks[i], e);
        for (int j = 0; j < 384; j++)
            D->x.p[we_blk_idx(64, 384, i, j)] = f2bf(e[j] + pos[i * 384 + j]);
    }
    __Runtime_sync_for_dev(g_dev, D->x.p, we_act_bytes(&D->x));
    dcheck("d_x0", &D->x, WN_G_D_X0, n);
    g_ws = 1;
    static const size_t L[4][12] = {
#define ROW(l)                                                                                                         \
    {WN_D##l##_QKV_W,  WN_D##l##_QKV_LN, WN_D##l##_OUT_W, WN_D##l##_OUT_B,  WN_D##l##_Q_W,   WN_D##l##_Q_LN,           \
     WN_D##l##_XOUT_W, WN_D##l##_XOUT_B, WN_D##l##_FC1_W, WN_D##l##_FC1_LN, WN_D##l##_FC2_W, WN_D##l##_FC2_B}
        ROW(0), ROW(1), ROW(2), ROW(3)};
#undef ROW
    for (int l = 0; l < 4; l++) {
        const size_t *p = L[l];
        if (gemm(&D->x, p[0], 0, p[1], 0, &D->qkv, 1152, WE_F_KT | WE_F_VT, 0, 1) ||
            attn(&D->qkv, &D->qkv, 8, 16, &D->o, n, 1, 1, 1) || gemm(&D->o, p[2], p[3], 0, &D->x, &D->x2, 384, 0, 0, 1))
            return -1;
        if (l == 0)
            dcheck("d_sa", &D->x2, WN_G_D_SA, n);
        if (gemm(&D->x2, p[4], 0, p[5], 0, &D->q, 384, 0, 0, 1) ||
            attn(&D->q, &E->kvx[l], 0, 8, &D->o, 1500, 0, 1, 4) ||
            gemm(&D->o, p[6], p[7], 0, &D->x2, &D->x, 384, 0, 0, 1))
            return -1;
        if (l == 0)
            dcheck("d_ca", &D->x, WN_G_D_CA, n);
        if (gemm_n(&D->x, p[8], 0, p[9], 0, &D->h, 1536, 768, WE_F_GELU, 1) ||
            gemm_n(&D->h, p[10], p[11], 0, &D->x, &D->x2, 384, 192, 0, 1))
            return -1;
        if (l == 0)
            dcheck("d_l0", &D->x2, WN_G_D_L0, n);
        WeAct t = D->x;
        D->x = D->x2;
        D->x2 = t;
    }
    g_ws = 0;
    const int lrg = (n - 1) / 4, lane = (n - 1) % 4;
    for (int s = 0; s < WN_NSLICE; s++) {
        // hi/lo split weight: each slice is WN_LOGIT_SLICE x (2 * 384), its _ln block in front
        WeGemm g = {&D->x,      W(WN_EMB0_W + (size_t)s * (WN_EMB1_W - WN_EMB0_W)),
                    0,          0,
                    0,          WN_LOGIT_SLICE,
                    WE_F_LOGIT, 0,
                    0,          1,
                    0,          0,
                    0,          0,
                    0,          0,
                    0,          D->logits + (size_t)s * (WN_LOGIT_SLICE / 48) * 192,
                    lrg,        1};
        set_ln(&g, WN_EMB0_LN + (size_t)s * (WN_EMB1_LN - WN_EMB0_LN), WN_LOGIT_SLICE, 0);
        if (we_gemm(&g_e, &g))
            return -1;
    }
    const size_t nl = (size_t)WN_NSLICE * (WN_LOGIT_SLICE / 48) * 192;
    if (we_drain(&g_e))
        return -1;
    __Runtime_sync_for_cpu(g_dev, D->logits, nl * 4);
    int best = 0, second = 0;
    float bv = -1e30f, sv = -1e30f;
    for (int v = 0; v < WN_NVOCAB; v++) {
        const float x = D->logits[(size_t)(v / 48) * 192 + ((v % 48) / 8) * 32 + lane * 8 + v % 8];
        if (lg_out)
            lg_out[v] = x;
        if (x > bv) {
            sv = bv;
            second = best;
            bv = x;
            best = v;
        } else if (x > sv) {
            sv = x;
            second = v;
        }
    }
    printf("WHISPER step %2d: top %d (%.4f) next %d (%.4f) margin %.4f\n", n - WN_NSOT, best, bv, second, sv, bv - sv);
    return best;
}

static double enc_macs(void) {
    const double T = 1500, d = 384;
    double m = 3000.0 * 240 * d + T * 1152 * d;
    m += 4 * (T * d * 1152 + 2.0 * 6 * T * T * 64 + T * d * d + 2 * T * d * 1536);
    m += 4 * T * d * 768; /* cross K/V */
    return m;
}

int main() {
    printf("=== Whisper-tiny on the AIE engine (4x4 mesh, kernel loaded once) ===\n");
    // shim BDs over the control-packet plane (resnetengine's set-up): AIE2PS needs
    // high-throughput mode for it, set before device init; spine on partition col 0
    __Runtime_ctrl_high_throughput_enable(1);
    __Runtime_ctrl_pmap_enable(0);
    g_dev = __Runtime_init_mesh_partition(0, EF_PART_START_COL, EF_PART_NUM_COLS);
    static __Runtime_CtrlRowFabric fab;
    static const __Runtime_CtrlRowChain fab_rows[] = {{3, 1, 4}, {4, 1, 4}, {5, 1, 4}, {6, 1, 4}};
    __Runtime_ctrl_plan_init(&fab, g_dev, 0, 0, 1, fab_rows, 4);
    __Runtime_ctrl_plan_set_exclusive(&fab, 1);
    XAie_LocType tiles[16];
    for (int r = 0; r < 4; r++)
        for (int c = 0; c < 4; c++)
            tiles[r * 4 + c] = XAie_TileLoc((uint8_t)(EF_FIRST_COL + c), (uint8_t)(EF_FIRST_ROW + r));
    we_init(&g_e, g_dev);
    g_e.ctrl = &fab;
    g_e.prog[1] = _binary_kernel_eng_start, g_e.prog[2] = _binary_kernel_att_start;
    memcpy(g_e.tiles, tiles, sizeof(tiles));
    if (we_prog(&g_e, 1)) /* kernel load over the control-packet plane */
        return 1;
#ifdef WE_CTRL /* measured: no gain -- small batches pay the control-packet round trip */
    g_e.fab = &fab;
#endif
    __Runtime_sync_for_dev(g_dev, (void *)wn_blob, WN_BLOB_BYTES);
    { /* MMIO cost: 1000 writes to an unused memtile BD word, before / after re-typing */
        const u64 probe = XAie_GetTileAddr(g_dev, EF_MT_A_ROW, 1) + 0xA0000 + 47 * 0x20; /* memtile BD 47 word 0 */
        for (int pass = 0; pass < 2; pass++) {
#ifdef WE_AIE_POSTED
            if (pass == 1) /* Device-nGnRnE -> Device-nGnRE: early write ack, order kept */
                Xil_SetTlbAttributes((UINTPTR)0x20000000000ULL, DEVICE_MEMORY); /* XAIE_BASE_ADDR */
#else
            if (pass == 1)
                break;
#endif
            const double t0 = now_us();
            for (int i = 0; i < 1000; i++)
                XAie_Write32(g_dev, probe, (u32)i);
            u32 rb = 0;
            XAie_Read32(g_dev, probe, &rb);
            printf("WHISPER mmio %s: %.1f ns per XAie_Write32 (read-back %u, want 999)\n",
                   pass ? "Device-nGnRE" : "Device-nGnRnE", (now_us() - t0) * 1e3 / 1000, (unsigned)rb);
        }
    }
    static Enc E;
    E.x = act(384, 384), E.x2 = act(384, 384), E.qkv = act(384, 1152), E.o = act(384, 384);
    E.h = act(384, 1536);
    for (int l = 0; l < 4; l++)
        E.kvx[l] = act(384, 768);
    E.x1 = (bf16_t *)__Runtime_Alloc((size_t)3080 * 384 * 2);
    memset(E.x1, 0, (size_t)3080 * 384 * 2);
    __Runtime_sync_for_dev(g_dev, E.x1, (size_t)3080 * 384 * 2);
    static Dec D;
    D.x = act(64, 384), D.x2 = act(64, 384), D.qkv = act(64, 1152), D.o = act(64, 384);
    D.q = act(64, 384), D.h = act(64, 1536);
    D.logits = (float *)__Runtime_Alloc((size_t)WN_NSLICE * (WN_LOGIT_SLICE / 48) * 768);
    g_macs_enc = enc_macs();

    int fails = 0;
    double best_enc = 1e30;
    for (int run = 0; run < 3; run++) {
        g_e.t_fill = g_e.t_arm = g_e.t_run = 0;
        memset(g_pt, 0, sizeof(g_pt)), memset(g_pf, 0, sizeof(g_pf)), memset(g_pa, 0, sizeof(g_pa));
        memset(g_pr, 0, sizeof(g_pr)), memset(g_prd, 0, sizeof(g_prd)), memset(g_pwr, 0, sizeof(g_pwr));
        const int us = encoder(&E, run == 0);
        g_trace = 0;
        if (us < 0) {
            printf("WHISPER FAIL: encoder\n");
            return 1;
        }
        best_enc = us < best_enc ? us : best_enc;
        printf("WHISPER encoder run %d: %d us (fill %.0f arm %.0f run %.0f) -> %.1f%% of 4x4 bf16 peak\n", run, us,
               g_e.t_fill, g_e.t_arm, g_e.t_run, 100 * g_macs_enc / (us * 1e-6) / 4096e9);
        { /* attention cycle split on core (1,3), accumulated over this encoder run */
            u32 w[16];
            for (int i = 0; i < 16; i++)
                XAie_DataMemRdWord(g_dev, XAie_TileLoc(1, 3), 0x07C0 + 4 * i, &w[i]);
            if (w[9])
                printf(
                    "WHISPER attn core(1,3): %u chunks, per chunk qk %u softmax %u pv %u, q-block total/chunk %u cyc\n",
                    w[9], w[5] / w[9], w[6] / w[9], w[7] / w[9], w[8] / w[9]);
            if (w[12])
                printf("WHISPER attn core(1,3): %u plain chunks: qk %u exp+mask %u cyc; %u lazy raises; per q-block "
                       "finish %u, Q/drain/zero %u cyc\n",
                       w[12], w[10] / w[12], w[11] / w[12], w[13], w[14] / (w[9] / 24), w[15] / (w[9] / 24));
            if (w[12])
                printf("WHISPER gemm core(1,3): %u chunks, mac_chunk %u cyc/chunk, epilogue %u cyc total, op total %u "
                       "cyc (mac %.0f%%)\n",
                       w[12], w[10] / w[12], w[13], w[11], 100.0 * w[10] / (w[11] ? w[11] : 1));
            for (int r = 3; r <= 6; r++)
                for (int c = 1; c <= 4; c++)
                    for (int i = 5; i < 16; i++)
                        XAie_DataMemWrWord(g_dev, XAie_TileLoc((u8)c, (u8)r), 0x07C0 + 4 * i, 0);
        }
        printf("WHISPER BD writes: %lu new, %lu partial, %lu unchanged (%lu words); %u program swaps %.0f us\n",
               we_n_full, we_n_addr, we_n_skip, we_n_words, g_e.nswap, g_e.t_swap);
        we_n_full = we_n_addr = we_n_skip = we_n_words = 0;
        g_e.nswap = 0, g_e.t_swap = 0;
#ifdef WE_TL
        if (run == 2)
            we_tl_print();
        we_tl_n = 0;
#endif
        printf("WHISPER encoder ops (us):");
        for (int k = 0; k < P_N; k++)
            printf(" %s %.0f", g_pn[k], g_pt[k]);
        printf("\n");
        for (int k = 0; k < P_N; k++)
            printf("WHISPER   %-5s wall %6.0f  fill %6.0f  arm %6.0f  run %6.0f us  DDR rd %6.2f wr %6.2f MB\n",
                   g_pn[k], g_pt[k], g_pf[k], g_pa[k], g_pr[k], g_prd[k] / 1e6, g_pwr[k] / 1e6);
        {
            double rd = 0, wr = 0;
            for (int k = 0; k < P_N; k++)
                rd += g_prd[k], wr += g_pwr[k];
            printf("WHISPER DDR traffic: read %.1f MB, written %.1f MB -> floor %.1f ms at 10.5/10 GB/s, %.1f ms at "
                   "8.3 GB/s mixed\n",
                   rd / 1e6, wr / 1e6, (rd / 10.5e9 + wr / 10e9) * 1e3, (rd + wr) / 8.3e9 * 1e3);
        }
#ifdef WE_PROF_GOP
        for (int k = 0; k < P_N; k++) {
            const double *c = g_pc[k];
            if (c[0])
                printf("WHISPER   %-5s core(1,3) op %7.0f us: mac %5.1f%% (%4.0f cyc/chunk) ln %4.1f%% + stats %4.1f%% "
                       "epi %4.1f%% wait/other %4.1f%%\n",
                       g_pn[k], c[0] / 1e3, 100 * c[1] / c[0], c[4] ? c[1] / c[4] : 0, 100 * c[2] / c[0],
                       100 * c[5] / c[0], 100 * c[3] / c[0], 100 * (c[0] - c[1] - c[2] - c[3] - c[5]) / c[0]);
        }
        memset(g_pc, 0, sizeof(g_pc));
#endif
    }
    // decoder: greedy from the start-of-transcript prompt
    int toks[64], n = 0;
    for (int i = 0; i < WN_NSOT; i++)
        toks[n++] = wn_sot[i];
    static float lg0[WN_NVOCAB];
    const double t0 = now_us();
    int ngen = 0;
    while (n < 48) {
        g_dcheck = ngen == 0;
        const int nxt = decode_step(&E, &D, toks, n, ngen == 0 ? lg0 : 0);
        if (nxt < 0) {
            printf("WHISPER FAIL: decoder\n");
            return 1;
        }
        if (ngen == 0) {
            const float *g = (const float *)(wn_gold + WN_G_LOGITS0);
            double md = 0;
            for (int v = 0; v < WN_NVOCAB; v++)
                md = fabs(lg0[v] - g[v]) > md ? fabs(lg0[v] - g[v]) : md;
            printf("WHISPER check logits0 max |diff| %.4f\n", md);
        }
        if (nxt == WN_EOT)
            break;
        toks[n++] = nxt;
        ngen++;
        printf("WHISPER token %2d: %d\n", ngen, nxt);
    }
    const double t1 = now_us();
    printf("WHISPER decoder: %d tokens in %.1f ms (%.1f ms/token)\n", ngen, (t1 - t0) / 1e3,
           (t1 - t0) / 1e3 / (ngen + 1));
    int same = ngen == WN_NEXP;
    for (int i = 0; i < ngen && same; i++)
        same = toks[WN_NSOT + i] == wn_expect[i];
    printf("WHISPER tokens:");
    for (int i = 0; i < ngen; i++)
        printf(" %d", toks[WN_NSOT + i]);
    printf("\nWHISPER transcript %s the PyTorch reference\n", same ? "MATCHES" : "DIFFERS from");
    fails += !same;
    printf("PERF SUMMARY encoder best %.3f ms = %.1f%% of 4x4 bf16 peak (%.2f GMAC); decoder %.1f ms/token\n",
           best_enc / 1e3, 100 * g_macs_enc / (best_enc * 1e-6) / 4096e9, g_macs_enc / 1e9,
           (t1 - t0) / 1e3 / (ngen + 1));
    printf("WHISPER %s\n", fails ? "FAIL" : "PASS");
    return fails;
}
