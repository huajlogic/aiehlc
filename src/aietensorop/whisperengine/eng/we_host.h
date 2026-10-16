/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 *
 * we_host.h -- host-side op arming for the Whisper engine (header-only).
 * Every op: fill the memory tiles from DDR (shim -> MT_A / MT_B), replay them
 * to the cores (memtile MM2S tasks), collect the output packets (shim S2MM,
 * out-of-order BDs, one per core). Layouts: we_desc.h.
 *
 * Shim BD use (per shim column): 2..11 output OOO (engine_fabric.h tables),
 * 12..14 the A-side fill chain (MM2S ch1), 15 the B-side fill (MM2S ch0).
 * Memtile BDs: MT_A 0 fill, 1 header, 2..3 A/res replay; MT_B 0 fill,
 * 1..4 per-nb replay.
 ******************************************************************************/
#ifndef WE_HOST_H
#define WE_HOST_H
#include "aie_runtime.h"
#include "aie_timer.h"
#include "engine_fabric.h"
#include "we_desc.h"
#include <stdio.h>
#include <string.h>

typedef uint16_t bf16_t;
static inline float bf2f(bf16_t h) {
    uint32_t u = (uint32_t)h << 16;
    float f;
    memcpy(&f, &u, 4);
    return f;
}
static inline bf16_t f2bf(float f) {
    uint32_t u;
    memcpy(&u, &f, 4);
    u += 0x7FFF + ((u >> 16) & 1);
    return (bf16_t)(u >> 16);
}

/* A BLK activation: M = 4*RB rows, C cols (multiple of 48). */
typedef struct {
    bf16_t *p;
    int rb, c;
} WeAct;
static inline size_t we_tile_elems(const WeAct *t) { return (size_t)t->rb * 48; }
static inline size_t we_act_bytes(const WeAct *t) { return (size_t)4 * t->rb * t->c * 2; }
static inline bf16_t *we_tile(const WeAct *t, int r, int cb) {
    return t->p + ((size_t)r * (t->c / 48) + cb) * we_tile_elems(t);
}
static inline size_t we_blk_idx(int rb, int c, int row, int col) {
    const int r = row / rb, rr = row % rb, cb = col / 48, cc = col % 48;
    return ((size_t)(r * (c / 48) + cb) * rb * 48) + (size_t)((rr / 4) * 6 + cc / 8) * 32 + (rr % 4) * 8 + cc % 8;
}

typedef struct {
    XAie_DevInst *dev;
    __Runtime_CtrlRowFabric *fab; /* non-null: shim BDs over control packets */
    int32_t *hdr;                 /* WE_HDR_BYTES DMA buffer per op slot */
    double t_fill, t_arm, t_run;  /* accumulated, us */
    unsigned seq;
} WeEng;

static const int we_ooo[EF_MESH_ROWS][EF_MESH_COLS] = EF_OOO_BD_TABLE;
static const int we_pkt[EF_MESH_ROWS][EF_MESH_COLS] = EF_PKT_ID_TABLE;
static const int we_out_col[EF_MESH_ROWS] = EF_OUT_SHIM_COL_TABLE;
static const int we_out_ch[EF_MESH_ROWS] = EF_OUT_SHIM_CH_TABLE;

static inline XAie_LocType we_shim(int c) { return XAie_TileLoc((uint8_t)c, 0); }
static inline XAie_LocType we_mt(int k, int row) { return XAie_TileLoc((uint8_t)k, (uint8_t)row); }
static inline double we_us(XTime a, XTime b) { return 1e6 * (double)(b - a) / COUNTS_PER_SECOND; }

/* ---- shim -------------------------------------------------------------- */
/* MM2S BD: up to 3 dims in BYTES (stride, wrap); nd = 0 -> contiguous. */
static void we_sh_bd(WeEng *e, int col, int bd, const void *src, int len, int next, int nd, const int *st,
                     const int *wr) {
    int s[3] = {4, 256, 256 * 512}, w[3] = {64, 512, 0};
    if (nd) {
        for (int i = 0; i < 3; i++) {
            s[i] = i < nd ? st[i] : 0;
            w[i] = i < nd ? wr[i] : 0;
        }
    }
    __Runtime_dma_bd_config_multidim_ooo(e->dev, we_shim(col), (void *)src, bd, len, next, 0, 0, 0, 0, 0, 0, -1,
                                         nd ? nd : 3, s[0], w[0], s[1], w[1], s[2], w[2], 0, 0);
}
static void we_sh_start(WeEng *e, int col, int ch, int bd) {
    XAie_DmaDesc d = {};
    __Runtime_startio(e->dev, __Runtime_dma_createio_4(we_shim(col), d, ch, bd, DMA_MM2S), bd, 1);
}

/* ---- memtile ----------------------------------------------------------- */
static void we_mt_bd(WeEng *e, XAie_LocType t, int bd, uint32_t addr, uint32_t len, int nd, const uint32_t *st,
                     const uint32_t *wr, uint32_t it_step, uint32_t it_wrap, int next) {
    XAie_DmaDesc d;
    XAie_DmaDescInit(e->dev, &d, t);
    if (nd) {
        XAie_DmaDimDesc dims[4];
        for (int i = 0; i < nd; i++) {
            dims[i].AieMlDimDesc.StepSize = st[i];
            dims[i].AieMlDimDesc.Wrap = (uint16_t)wr[i];
        }
        XAie_DmaTensor tn;
        tn.NumDim = (uint8_t)nd;
        tn.Dim = dims;
        XAie_DmaSetMultiDimAddr(&d, &tn, addr, len);
    } else {
        XAie_DmaSetAddrLen(&d, addr, len);
    }
    if (it_wrap > 1)
        XAie_DmaSetBdIteration(&d, it_step, (uint8_t)it_wrap, 0);
    if (next >= 0)
        XAie_DmaSetNextBd(&d, (uint8_t)next, XAIE_ENABLE);
    XAie_DmaEnableBd(&d);
    XAie_DmaWriteBd(e->dev, &d, t, (uint8_t)bd);
}
static void we_mt_queue(WeEng *e, XAie_LocType t, XAie_DmaDirection dir, int bd, int repeat) {
    XAie_DmaChannelSetStartQueue(e->dev, t, 0, dir, (uint8_t)bd, (uint32_t)repeat, XAIE_DISABLE);
}
static int we_wait_ch(WeEng *e, XAie_LocType t, int ch, XAie_DmaDirection dir) {
    u8 n = 1;
    for (long it = 0; n; it++) {
        XAie_DmaGetPendingBdCount(e->dev, t, (uint8_t)ch, dir, &n);
        if (it > 30000000) {
            printf("WE TIMEOUT tile(%d,%d) ch %d dir %d pending %u\n", t.Col, t.Row, ch, (int)dir, n);
            return -1;
        }
    }
    return 0;
}

static void we_init(WeEng *e, XAie_DevInst *dev) {
    memset(e, 0, sizeof(*e));
    e->dev = dev;
    e->hdr = (int32_t *)__Runtime_Alloc(WE_HDR_BYTES);
    for (int k = 1; k <= 4; k++)
        for (int row = EF_MT_A_ROW; row <= EF_MT_B_ROW; row++) {
            XAie_DmaChannelEnable(dev, we_mt(k, row), 0, DMA_S2MM);
            XAie_DmaChannelEnable(dev, we_mt(k, row), 0, DMA_MM2S);
        }
}

static void we_hdr_begin(WeEng *e, int op, int ract) {
    memset(e->hdr, 0, WE_HDR_BYTES);
    e->hdr[WH_MAGIC] = WE_MAGIC;
    e->hdr[WH_OP] = op;
    e->hdr[WH_SEQ] = (int32_t)e->seq++;
    e->hdr[WH_RACT] = ract;
}

/* Output: core (r,c) writes `n` packets of `len` bytes; the first lands at
 * dst[r][c], each next one `step` bytes further; inside a packet the bytes go
 * to d0 x d1 (bytes: d0 contiguous run, d1 count at d1_stride). */
static void we_arm_out(WeEng *e, int ract, bf16_t *const dst[4][4], int len, int n, int step, int run, int cnt,
                       int stride, struct_ioevent *ev) {
    for (int r = 0; r < ract; r++) {
        XAie_LocType s = we_shim(we_out_col[r]);
        XAie_DmaDesc d = {};
        for (int c = 0; c < 4; c++)
            d = __Runtime_dma_bd_config_multidim_ooo(e->dev, s, dst[r][c], we_ooo[r][c], len, -1, 0, we_pkt[r][c], -1,
                                                     0, -1, 0, we_ooo[r][c], 3, 4, run / 4, stride, cnt, stride, 0,
                                                     step, n);
        __Runtime_dma_channel_enable_ooo(e->dev, s, we_out_ch[r], DMA_S2MM);
        ev[r] = __Runtime_startio(e->dev, __Runtime_dma_createio_4(s, d, we_out_ch[r], we_ooo[r][0], DMA_S2MM),
                                  we_ooo[r][0], 4 * n);
    }
}

/* ---- GEMM -------------------------------------------------------------- */
typedef struct {
    const WeAct *a;     /* [M x K] */
    const bf16_t *w;    /* we_pack_w layout: per mesh column c, contiguous: [sub][nb][kchunk][kt6][nt6][8][8] */
    const bf16_t *bias; /* N or null */
    const WeAct *res;   /* [M x N] or null */
    const WeAct *out;   /* [M x N] */
    int n;              /* N (multiple of 192) */
    int flags, kt_lo, kt_hi, ract, mbp; /* mbp: m-blocks per pass (0 = all) */
} WeGemm;

/* Column tiles per mesh column per sub-op: <= 4 (memtile task queue), 1 when
 * the op runs in M passes (keeps each core's output a 1-level BD iteration). */
static inline int we_gemm_nbs(int n, int passes) {
    const int nbc = n / 192;
    if (passes > 1)
        return 1;
    for (int d = 4; d > 1; d--)
        if (nbc % d == 0)
            return d;
    return 1;
}
/* W [N][K] row-major (bf16) -> engine order. Returns elements per mesh column. */
static size_t we_pack_w(bf16_t *dst, const bf16_t *w, int n, int k, int passes) {
    const int nbc = n / 192, nbs = we_gemm_nbs(n, passes), nsub = nbc / nbs, kcn = k / 48;
    const size_t col = (size_t)nbc * kcn * 48 * 48;
    for (int c = 0; c < 4; c++)
        for (int s = 0; s < nsub; s++)
            for (int nb = 0; nb < nbs; nb++)
                for (int kc = 0; kc < kcn; kc++)
                    for (int kt = 0; kt < 6; kt++)
                        for (int nt = 0; nt < 6; nt++)
                            for (int kk = 0; kk < 8; kk++)
                                for (int nn = 0; nn < 8; nn++) {
                                    const int row = (s * 4 * nbs + c * nbs + nb) * 48 + nt * 8 + nn;
                                    const int cl = kc * 48 + kt * 8 + kk;
                                    dst[c * col +
                                        (((((size_t)(s * nbs + nb) * kcn + kc) * 6 + kt) * 6 + nt) * 8 + kk) * 8 + nn] =
                                        w[(size_t)row * k + cl];
                                }
    return col;
}

static int we_gemm(WeEng *e, const WeGemm *g) {
    const int K = g->a->c, RB = g->a->rb, MB = RB / 64, KCN = K / 48;
    const int MBP = g->mbp ? g->mbp : MB, passes = MB / MBP;
    const int NBS = we_gemm_nbs(g->n, passes), NSUB = g->n / 192 / NBS, NSB = 4 * NBS; /* tiles per sub-op */
    const int res = g->res != 0;
    const size_t a_pass = (size_t)MBP * 64 * K * 2, r_pass = res ? (size_t)MBP * 64 * g->n * 2 : 0;
    const size_t hdrs = (size_t)NSUB * WE_HDR_BYTES, wcol = (size_t)(g->n / 4) * K;
    if (MB % MBP || g->n % 192 || hdrs + a_pass + r_pass > EF_MT_BYTES || wcol * 2 > EF_MT_BYTES ||
        (g->ract < 4 && passes > 1)) {
        printf("WE gemm: bad shape (N %d, passes %d, A %zu + res %zu, W %zu)\n", g->n, passes, a_pass, r_pass,
               wcol * 2);
        return -1;
    }
    const size_t tileb = (size_t)RB * 48 * 2;
    // one header per sub-op, back to back in one DMA buffer
    static int32_t *hbuf;
    static size_t hcap;
    if (hcap < hdrs) {
        hbuf = (int32_t *)__Runtime_Alloc(hdrs);
        hcap = hdrs;
    }
    for (int s = 0; s < NSUB; s++) {
        int32_t *h = (int32_t *)((int8_t *)hbuf + (size_t)s * WE_HDR_BYTES);
        memset(h, 0, WE_HDR_BYTES);
        h[WH_MAGIC] = WE_MAGIC;
        h[WH_OP] = WE_OP_GEMM;
        h[WH_SEQ] = (int32_t)e->seq++;
        h[WH_RACT] = g->ract;
        h[WH_MB] = MBP;
        h[WH_NB] = NBS;
        h[WH_KCN] = KCN;
        h[WH_FLAGS] = g->flags | (g->bias ? WE_F_BIAS : 0) | (res ? WE_F_RES : 0);
        h[WH_N] = NSB * 48;
        h[WH_KT_LO] = g->kt_lo - s * NSB;
        h[WH_KT_HI] = g->kt_hi - s * NSB;
        if (g->bias)
            memcpy((int8_t *)h + WE_PRM_OFF, g->bias + (size_t)s * NSB * 48, (size_t)NSB * 48 * 2);
    }
    __Runtime_sync_for_dev(e->dev, hbuf, hdrs);
    // B: the column's whole weight slice, once per op
    for (int k = 1; k <= 4; k++) {
        we_mt_bd(e, we_mt(k, EF_MT_B_ROW), 0, EF_MT_BASE, (uint32_t)(wcol * 2), 0, 0, 0, 0, 0, -1);
        we_mt_queue(e, we_mt(k, EF_MT_B_ROW), DMA_S2MM, 0, 1);
        we_sh_bd(e, k, 15, g->w + (size_t)(k - 1) * wcol, (int)(wcol * 2), -1, 0, 0, 0);
        we_sh_start(e, k, 0, 15);
    }
    int rc = 0;
    for (int p = 0; p < passes && !rc; p++) {
        const int mb0 = p * MBP;
        XTime p0, p1, p2, p3;
        XTime_GetTime(&p0);
        // fill MT_A: [headers][A pass][res pass]; idle rows get only the headers
        for (int k = 1; k <= 4; k++) {
            const int r = k - 1, act = k <= g->ract;
            XAie_LocType ta = we_mt(k, EF_MT_A_ROW);
            if (!act && p > 0)
                continue;
            const uint32_t tot = (uint32_t)(hdrs + (act ? a_pass + r_pass : 0));
            we_mt_bd(e, ta, 0, EF_MT_BASE, tot, 0, 0, 0, 0, 0, -1);
            we_mt_queue(e, ta, DMA_S2MM, 0, 1);
            const int st[3] = {4, 1024, (int)tileb}, wa[3] = {256, 6 * MBP, K / 48};
            we_sh_bd(e, k, 12, hbuf, (int)hdrs, act ? 13 : -1, 0, 0, 0);
            if (act) {
                we_sh_bd(e, k, 13, we_tile(g->a, r, 0) + (size_t)mb0 * 64 * 48, (int)a_pass, res ? 14 : -1, 3, st, wa);
                if (res) {
                    const int wr[3] = {256, 6 * MBP, g->n / 48};
                    we_sh_bd(e, k, 14, we_tile(g->res, r, 0) + (size_t)mb0 * 64 * 48, (int)r_pass, -1, 3, st, wr);
                }
            }
            we_sh_start(e, k, 1, 12);
        }
        for (int k = 1; k <= 4 && !rc; k++) {
            if (k <= g->ract || p == 0)
                rc |= we_wait_ch(e, we_mt(k, EF_MT_A_ROW), 0, DMA_S2MM);
            if (p == 0)
                rc |= we_wait_ch(e, we_mt(k, EF_MT_B_ROW), 0, DMA_S2MM);
        }
        XTime_GetTime(&p1);
        double ta_us = 0, tr_us = 0;
        for (int s = 0; s < NSUB && !rc; s++) {
            XTime q0, q1, q2;
            XTime_GetTime(&q0);
            struct_ioevent ev[4];
            bf16_t *dst[4][4];
            for (int r = 0; r < 4; r++)
                for (int c = 0; c < 4; c++)
                    dst[r][c] = we_tile(g->out, r, s * NSB + c * NBS) + (size_t)mb0 * 64 * 48;
            we_arm_out(e, g->ract, dst, WE_BLK, NBS * MBP, WE_BLK, 1024, 6, 1024, ev);
            for (int k = 1; k <= 4; k++) {
                XAie_LocType ta = we_mt(k, EF_MT_A_ROW), tb = we_mt(k, EF_MT_B_ROW);
                const uint32_t hoff = EF_MT_BASE + (uint32_t)s * WE_HDR_BYTES;
                if (k > g->ract) {
                    if (p == 0) {
                        we_mt_bd(e, ta, 1, hoff, WE_HDR_BYTES, 0, 0, 0, 0, 0, -1);
                        we_mt_queue(e, ta, DMA_MM2S, 1, 1);
                    }
                } else {
                    const uint32_t abase = EF_MT_BASE + (uint32_t)hdrs;
                    we_mt_bd(e, ta, 1, hoff, WE_HDR_BYTES, 0, 0, 0, 0, 0, -1);
                    const uint32_t sa[3] = {1, 768, (uint32_t)MBP * 1536}, wa[3] = {768, 2, 0};
                    we_mt_bd(e, ta, 2, abase, (uint32_t)(64 * K * 2), 3, sa, wa, 1536, MBP, res ? 3 : -1);
                    if (res) {
                        const uint32_t sr[3] = {1, 768, (uint32_t)(NBS * MBP * 1536)}, wr[3] = {768, 2, 0};
                        we_mt_bd(e, ta, 3, abase + (uint32_t)a_pass + (uint32_t)s * NSB * MBP * WE_BLK, 4 * WE_BLK, 3,
                                 sr, wr, 1536, NBS * MBP, -1);
                    }
                    we_mt_queue(e, ta, DMA_MM2S, 1, 1);
                    we_mt_queue(e, ta, DMA_MM2S, 2, NBS * MBP);
                }
                const uint32_t pan = (uint32_t)KCN * WE_B_CHUNK;
                for (int nb = 0; nb < NBS; nb++) {
                    we_mt_bd(e, tb, 1 + nb, EF_MT_BASE + (uint32_t)(s * NBS + nb) * pan, pan, 0, 0, 0, 0, 0, -1);
                    we_mt_queue(e, tb, DMA_MM2S, 1 + nb, MBP);
                }
            }
            XTime_GetTime(&q1);
            for (int r = 0; r < g->ract; r++)
                __Runtime_wait_io(e->dev, ev[r]);
            XTime_GetTime(&q2);
            ta_us += we_us(q0, q1);
            tr_us += we_us(q1, q2);
        }
        XTime_GetTime(&p3);
        (void)p2;
        e->t_fill += we_us(p0, p1);
        e->t_arm += ta_us;
        e->t_run += tr_us;
    }
    return rc;
}

/* ---- LayerNorm ----------------------------------------------------------- */
static int we_ln(WeEng *e, const WeAct *x, const bf16_t *gamma, const bf16_t *beta, float eps, const WeAct *y,
                 int ract) {
    const int RB = x->rb, RG = RB / 4, RGC = RG / 4;
    const size_t tileb = (size_t)RB * 48 * 2;
    XTime p0, p1, p2, p3;
    XTime_GetTime(&p0);
    we_hdr_begin(e, WE_OP_LN, ract);
    e->hdr[WH_RGC] = RGC;
    memcpy(&e->hdr[WH_EPS], &eps, 4);
    memcpy((int8_t *)e->hdr + WE_PRM_OFF, gamma, 384 * 2);
    memcpy((int8_t *)e->hdr + WE_PRM_OFF + 768, beta, 384 * 2);
    __Runtime_sync_for_dev(e->dev, e->hdr, WE_HDR_BYTES);
    struct_ioevent ev[4];
    bf16_t *dst[4][4];
    for (int r = 0; r < 4; r++)
        for (int c = 0; c < 4; c++)
            dst[r][c] = we_tile(y, r, 0) + (size_t)c * 4 * 48; /* group g -> core g % 4 */
    we_arm_out(e, ract, dst, WE_RG_ROW, RGC, 4 * 384, 384, 8, (int)tileb, ev);
    for (int k = 1; k <= ract; k++) {
        XAie_LocType t = we_mt(k, EF_MT_A_ROW);
        we_mt_bd(e, t, 0, EF_MT_BASE, (uint32_t)(WE_HDR_BYTES + 8 * tileb), 0, 0, 0, 0, 0, -1);
        we_mt_queue(e, t, DMA_S2MM, 0, 1);
        we_sh_bd(e, k, 12, e->hdr, WE_HDR_BYTES, 13, 0, 0, 0);
        we_sh_bd(e, k, 13, we_tile(x, k - 1, 0), (int)(8 * tileb), -1, 0, 0, 0);
        we_sh_start(e, k, 1, 12);
    }
    int rc = 0;
    for (int k = 1; k <= ract && !rc; k++)
        rc |= we_wait_ch(e, we_mt(k, EF_MT_A_ROW), 0, DMA_S2MM);
    XTime_GetTime(&p1);
    for (int k = 1; k <= ract; k++) {
        XAie_LocType t = we_mt(k, EF_MT_A_ROW);
        we_mt_bd(e, t, 1, EF_MT_BASE, WE_HDR_BYTES, 0, 0, 0, 0, 0, -1);
        const uint32_t s[3] = {1, (uint32_t)(tileb / 4), 96}, w[3] = {96, 8, 0};
        we_mt_bd(e, t, 2, EF_MT_BASE + WE_HDR_BYTES, (uint32_t)(8 * tileb), 3, s, w, 0, 0, -1);
        we_mt_queue(e, t, DMA_MM2S, 1, 1);
        we_mt_queue(e, t, DMA_MM2S, 2, 1);
    }
    XTime_GetTime(&p2);
    for (int r = 0; r < ract; r++)
        __Runtime_wait_io(e->dev, ev[r]);
    XTime_GetTime(&p3);
    e->t_fill += we_us(p0, p1);
    e->t_arm += we_us(p1, p2);
    e->t_run += we_us(p2, p3);
    return rc;
}

/* Header to the idle mesh rows too (cores of rows >= ract only read it). */
#endif
