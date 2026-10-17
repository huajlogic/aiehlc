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
    int ct; /* 48-col tiles per row block of the underlying tensor (0: c / 48); a
             * column view of a wider tensor keeps the parent's ct */
} WeAct;
static inline size_t we_tile_elems(const WeAct *t) { return (size_t)t->rb * 48; }
static inline size_t we_act_bytes(const WeAct *t) { return (size_t)4 * t->rb * t->c * 2; }
static inline bf16_t *we_tile(const WeAct *t, int r, int cb) {
    return t->p + ((size_t)r * (t->ct ? t->ct : t->c / 48) + cb) * we_tile_elems(t);
}
static inline size_t we_blk_idx(int rb, int c, int row, int col) {
    const int r = row / rb, rr = row % rb, cb = col / 48, cc = col % 48;
    return ((size_t)(r * (c / 48) + cb) * rb * 48) + (size_t)((rr / 4) * 6 + cc / 8) * 32 + (rr % 4) * 8 + cc % 8;
}

typedef struct {
    XAie_DevInst *dev;
    __Runtime_CtrlRowFabric *fab;  /* non-null: shim BDs over control packets */
    __Runtime_CtrlRowFabric *ctrl; /* control-packet plane for the program swaps */
    unsigned char *prog[3];        /* kernel ELFs: [1] GEMM, [2] attention (kernel.cc WE_PROG) */
    int cur;                       /* program on the cores */
    XAie_LocType tiles[16];
    double t_swap;
    unsigned nswap;
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

/* ---- BD shadow ---------------------------------------------------------- */
/* Every BD the host writes is remembered (parameters minus the buffer address).
 * Re-arming a BD with the same shape costs one address update (1-2 MMIO writes,
 * ~355 ns each: doc/performance/register_write_cost.md) instead of the full BD,
 * and an identical BD costs nothing. Only the host writes these BDs (the cores
 * program their own tile DMAs), so the shadow stays exact. */
#define WE_SH_NP 20
typedef struct {
    int valid;
    uint64_t addr;
    int32_t p[WE_SH_NP];
} WeShadow;
static WeShadow we_shadow[8][3][48]; /* [partition-relative col][row 0..2][bd] */
static unsigned long we_n_full, we_n_addr, we_n_skip;
/* 1: write the BD in full; 0: done (unchanged, or only its address updated) */
static int we_shadow_check(WeEng *e, XAie_LocType t, int bd, uint64_t addr, const int32_t *p, int np) {
    WeShadow *s = &we_shadow[t.Col][t.Row][bd];
    int32_t q[WE_SH_NP] = {0};
    memcpy(q, p, (size_t)np * 4);
    if (s->valid && !memcmp(s->p, q, sizeof(q))) {
        if (s->addr != addr) {
            XAie_DmaUpdateBdAddr(e->dev, t, addr, (u16)bd);
            s->addr = addr;
            we_n_addr++;
        } else {
            we_n_skip++;
        }
        return 0;
    }
    s->valid = 1;
    s->addr = addr;
    memcpy(s->p, q, sizeof(q));
    we_n_full++;
    return 1;
}
/* shim BD through the runtime (OOO / packet / iteration fields), shadowed */
static XAie_DmaDesc we_shim_bd(WeEng *e, XAie_LocType t, const void *buf, int bd, int len, int next, int pkt_en,
                               int pkt_id, int ooo, int nd, int s0, int w0, int s1, int w1, int s2, int w2, int it_step,
                               int it_n) {
    const int32_t p[16] = {len, next, pkt_en, pkt_id, ooo, nd, s0, w0, s1, w1, s2, w2, it_step, it_n, 0x5348, 0};
    XAie_DmaDesc d = {};
    if (we_shadow_check(e, t, bd, __Runtime_dev_addr((void *)buf), p, 16))
        d = __Runtime_dma_bd_config_multidim_ooo(e->dev, t, (void *)buf, bd, len, next, pkt_en, pkt_id, -1, 0, -1, 0,
                                                 ooo, nd, s0, w0, s1, w1, s2, w2, it_step, it_n);
    return d;
}

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
    we_shim_bd(e, we_shim(col), src, bd, len, next, 0, 0, -1, nd ? nd : 3, s[0], w[0], s[1], w[1], s[2], w[2], 0, 0);
}
static void we_sh_start(WeEng *e, int col, int ch, int bd) {
    XAie_DmaDesc d = {};
    __Runtime_startio(e->dev, __Runtime_dma_createio_4(we_shim(col), d, ch, bd, DMA_MM2S), bd, 1);
}

/* Shim BD / channel writes go over the control-packet plane (~3 ns/word, not
 * ~355 ns per MMIO write) when e->fab is set: captured between begin and sync.
 * sync waits for the batch's ack, so DMA state polled afterwards is current. */
static void we_sb_begin(WeEng *e) {
    if (e->fab)
        __Runtime_ctrl_shim_bd_begin(e->fab);
}
static void we_sb_sync(WeEng *e) {
    if (e->fab)
        __Runtime_ctrl_shim_bd_sync();
}

/* Program swap: the cores run the GEMM or the attention program (one 16 KB
 * program memory cannot hold both, skill aie2psprogrammemory). Between ops the
 * cores idle in main waiting for a header; the control-packet ELF load resets
 * cores and core DMAs, writes program + data memory as broadcast packets, and the
 * launch re-enables them. */
static int we_prog(WeEng *e, int p) {
    if (e->cur == p || !e->prog[p] || !e->ctrl)
        return 0;
    XTime t0, t1;
    XTime_GetTime(&t0);
    const XAie_LocType *t = e->tiles;
    __Runtime_set_kernel_elf(e->prog[p]);
    struct_kernel_group kg =
        __Runtime_load_kernel_group_16t_ctrl(e->dev, e->ctrl, t[0], t[1], t[2], t[3], t[4], t[5], t[6], t[7], t[8],
                                             t[9], t[10], t[11], t[12], t[13], t[14], t[15], 16, 2, 0);
    if (kg.num_tiles != 16) {
        printf("WE program %d load FAILED\n", p);
        return -1;
    }
    __Runtime_launch_kernel_group_ctrl(e->dev, e->ctrl, kg, 2, 0);
    e->cur = p;
    XTime_GetTime(&t1);
    e->t_swap += we_us(t0, t1);
    e->nswap++;
    return 0;
}

/* ---- memtile ----------------------------------------------------------- */
static void we_mt_bd(WeEng *e, XAie_LocType t, int bd, uint32_t addr, uint32_t len, int nd, const uint32_t *st,
                     const uint32_t *wr, uint32_t it_step, uint32_t it_wrap, int next) {
    int32_t p[14] = {(int32_t)len, nd, (int32_t)it_step, (int32_t)it_wrap, next, 0x4D54};
    for (int i = 0; i < nd && i < 4; i++)
        p[6 + 2 * i] = (int32_t)st[i], p[7 + 2 * i] = (int32_t)wr[i];
    if (!we_shadow_check(e, t, bd, addr, p, 14))
        return;
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

/* Hang dump: every engine DMA channel's status plus the cores' progress words. */
static void we_dump(WeEng *e) {
    const char *dn[2] = {"S2MM", "MM2S"};
    for (int k = 1; k <= 4; k++)
        for (int row = 0; row <= 6; row++)
            for (int ch = 0; ch < 2; ch++)
                for (int d = 0; d < 2; d++) {
                    if ((row == 1 || row == 2) && ch > 0)
                        continue;
                    if (row >= 3 && d == 1 && ch > 0)
                        continue;
                    u32 st = 0;
                    u8 pend = 0;
                    XAie_DmaGetChannelStatus(e->dev, we_mt(k, row), (u8)ch, (XAie_DmaDirection)d, &st);
                    XAie_DmaGetPendingBdCount(e->dev, we_mt(k, row), (u8)ch, (XAie_DmaDirection)d, &pend);
                    if (st)
                        printf("WE dump tile(%d,%d) %s%d status %08x pending %u\n", k, row, dn[d], ch, (unsigned)st,
                               pend);
                }
    for (int k = 1; k <= 4; k++)
        for (int row = 3; row <= 6; row++) {
            u32 w[5];
            for (int i = 0; i < 5; i++)
                XAie_DataMemRdWord(e->dev, we_mt(k, row), 0x07C0 + 4 * i, &w[i]);
            u32 lut0 = 0;
            XAie_DataMemRdWord(e->dev, we_mt(k, row), 0xC000, &lut0);
            if (k == 1) { /* core DMA BDs 0..4 (6 words each) */
                const u64 tb = XAie_GetTileAddr(e->dev, (u8)row, (u8)k);
                for (int bd = 0; bd < 5; bd++) {
                    u32 v[6];
                    for (int i = 0; i < 6; i++)
                        XAie_Read32(e->dev, tb + 0x1D000 + bd * 0x20 + i * 4, &v[i]);
                    printf("WE dump core(%d,%d) BD%d %08x %08x %08x %08x %08x %08x\n", k, row, bd, (unsigned)v[0],
                           (unsigned)v[1], (unsigned)v[2], (unsigned)v[3], (unsigned)v[4], (unsigned)v[5]);
                }
            }
            printf("WE dump core(%d,%d) seq %d op %d step %d kc %d fin %d (lut[0..1] %08x)\n", k, row, (int)w[0],
                   (int)w[1], (int)w[2], (int)w[3], (int)w[4], (unsigned)lut0);
        }
}
/* Output wait with a 2 s timeout and a dump instead of the runtime's ~20 s spin. */
static int we_wait_out(WeEng *e, struct_ioevent ev) {
    XTime t0, t1;
    XTime_GetTime(&t0);
    for (;;) {
        u8 n = 1;
        XAie_DmaGetPendingBdCount(e->dev, ev.io.tile_loc, ev.io.channel_id, ev.io.direction, &n);
        if (!n)
            return 0;
        XTime_GetTime(&t1);
        if (we_us(t0, t1) > 2e6) {
            printf("WE HANG waiting output tile(%d,%d) ch %d op seq %u\n", ev.io.tile_loc.Col, ev.io.tile_loc.Row,
                   ev.io.channel_id, e->seq);
            we_dump(e);
            return -1;
        }
    }
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

/* S2MM out-of-order mode, once per shim channel */
static void we_ooo_enable(WeEng *e, XAie_LocType s, int ch) {
    static unsigned done;
    const unsigned bit = 1u << (s.Col * 2 + ch);
    if (done & bit)
        return;
    __Runtime_dma_channel_enable_ooo(e->dev, s, ch, DMA_S2MM);
    done |= bit;
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
            d = we_shim_bd(e, s, dst[r][c], we_ooo[r][c], len, -1, 0, we_pkt[r][c], we_ooo[r][c], 3, 4, run / 4, stride,
                           cnt, stride, 0, step, n);
        we_ooo_enable(e, s, we_out_ch[r]);
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
    int vt_lo, vt_hi;                   /* WE_F_VT tile range */
    /* A from overlapping row windows of a row-major tensor (conv1 / conv2):
     * A row t = conv_base[t * conv_stride .. + conv_len), K = conv_len rounded up
     * to 48 (the extra columns' weights are zero). */
    const bf16_t *conv_base;
    int conv_stride, conv_len;
    bf16_t *out_rm; /* WE_F_ROWMAJOR: row-major output, row 0 here, ld = n */
    float *logits;  /* WE_F_LOGIT: fp32 [tile][6][4][8] of row group lrg */
    int lrg;
    int wsplit; /* weights as hi+lo bf16 pairs: W' = [Wh | Wl] (K' = 2K), A replayed twice */
    /* WE_F_LN (we_desc.h): LayerNorm of A folded in. w is gamma (.) W, lnd = b + beta W^T
     * (fp32, replaces bias), lnc = c_hi | c_lo bf16 [n each]: c = row sums of w */
    const float *lnd;
    const bf16_t *lnc;
    int lnn; /* full N of lnd / lnc (a column chunk of a wider GEMM indexes into them) */
} WeGemm;

/* Column tiles per mesh column per sub-op: <= 4 (memtile task queue), 1 when
 * the op runs in M passes (keeps each core's output a 1-level BD iteration). */
static inline int we_gemm_nbs(int n, int passes) {
    const int nbc = n / 192;
    if (passes > 1 || passes < 0) /* passes < 0: caller forces NB = 1 (row-major output) */
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
    if (we_prog(e, 1))
        return -1;
    const int K = g->a->c, RB = g->a->rb, MB = RB / 64, KCN = K * (1 + g->wsplit) / 48;
    const int MBP = g->mbp ? g->mbp : MB, passes = MB / MBP;
    const int rm = (g->flags & WE_F_ROWMAJOR) != 0, lg = (g->flags & WE_F_LOGIT) != 0;
    const int NBS = we_gemm_nbs(g->n, rm ? -1 : passes), NSUB = g->n / 192 / NBS, NSB = 4 * NBS;
    const int res = g->res != 0;
    const size_t a_pass = (size_t)MBP * 64 * K * 2, r_pass = res ? (size_t)MBP * 64 * g->n * 2 : 0;
    const size_t hdrs = (size_t)NSUB * WE_HDR_BYTES, wcol = (size_t)(g->n / 4) * K * (1 + g->wsplit);
    if (MB % MBP || g->n % 192 || hdrs + a_pass + r_pass > EF_MT_BYTES || wcol * 2 > EF_MT_BYTES ||
        (g->ract < 4 && passes > 1) || (g->conv_base && 16 * MBP > 64) || (lg && MB != 1)) {
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
    const int ln = g->lnd != 0;
    for (int s = 0; s < NSUB; s++) {
        int32_t *h = (int32_t *)((int8_t *)hbuf + (size_t)s * WE_HDR_BYTES);
        memset(h, 0, WE_PRM_OFF);
        h[WH_MAGIC] = WE_MAGIC;
        h[WH_OP] = WE_OP_GEMM;
        h[WH_SEQ] = (int32_t)e->seq++;
        h[WH_RACT] = g->ract;
        h[WH_MB] = MBP;
        h[WH_NB] = NBS;
        h[WH_KCN] = KCN;
        h[WH_FLAGS] = g->flags | (g->bias || ln ? WE_F_BIAS : 0) | (res ? WE_F_RES : 0) | (ln ? WE_F_LN : 0);
        h[WH_N] = NSB * 48;
        h[WH_KT_LO] = g->kt_lo - s * NSB;
        h[WH_KT_HI] = g->kt_hi - s * NSB;
        h[WH_VT_LO] = g->vt_lo - s * NSB;
        h[WH_VT_HI] = g->vt_hi - s * NSB;
        h[WH_LRG] = g->lrg;
        h[WH_KST] = K / 48;
        const float eps = 1e-5f, invk = 1.0f / (float)K;
        memcpy(&h[WH_LNEPS], &eps, 4);
        memcpy(&h[WH_LNINVK], &invk, 4);
        // parameters of this sub-op's NSB*48 columns: d fp32, then (LN) c_hi, c_lo bf16
        float *d = (float *)((int8_t *)h + WE_PRM_OFF);
        const size_t c0 = (size_t)s * NSB * 48;
        for (int i = 0; i < NSB * 48; i++)
            d[i] = ln ? g->lnd[c0 + i] : g->bias ? bf2f(g->bias[c0 + i]) : 0.0f;
        if (ln) {
            memcpy(d + NSB * 48, g->lnc + c0, (size_t)NSB * 48 * 2);
            memcpy((bf16_t *)(d + NSB * 48) + NSB * 48, g->lnc + g->lnn + c0, (size_t)NSB * 48 * 2);
        }
    }
    __Runtime_sync_for_dev(e->dev, hbuf, hdrs);
    we_sb_begin(e);
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
        if (p > 0)
            we_sb_begin(e);
        // fill MT_A: [headers][A pass][res pass]; idle rows get only the headers
        for (int k = 1; k <= 4; k++) {
            const int r = k - 1, act = k <= g->ract;
            XAie_LocType ta = we_mt(k, EF_MT_A_ROW);
            if (!act && p > 0)
                continue;
            const uint32_t tot = (uint32_t)(hdrs + (act && !g->conv_base ? a_pass + r_pass : 0));
            we_mt_bd(e, ta, 0, EF_MT_BASE, tot, 0, 0, 0, 0, 0, -1);
            we_mt_queue(e, ta, DMA_S2MM, 0, 1);
            const int st[3] = {4, 1024, (int)tileb}, wa[3] = {256, 6 * MBP, K / 48};
            we_sh_bd(e, k, 12, hbuf, (int)hdrs, act ? 13 : -1, 0, 0, 0);
            if (act && g->conv_base) { /* rows t0.. of the windowed tensor, re-tiled by the memtile write */
                const int t0 = r * RB + mb0 * 64, rows = MBP * 64, rowb = g->conv_len * 2;
                we_mt_bd(e, ta, 0, EF_MT_BASE, (uint32_t)hdrs, 0, 0, 0, 0, 0, -1);
                const uint32_t cs[4] = {1, 16, (uint32_t)MBP * 1536, 4},
                               cw[4] = {4, 6, (uint32_t)(g->conv_len / 48), 4};
                we_mt_bd(e, ta, 1, EF_MT_BASE + (uint32_t)hdrs, (uint32_t)(4 * rowb), 4, cs, cw, 96, 16 * MBP, -1);
                we_mt_queue(e, ta, DMA_S2MM, 1, 16 * MBP);
                const int sd[3] = {4, g->conv_stride * 2, 0}, wd[3] = {rowb / 4, rows, 0};
                we_sh_bd(e, k, 13, g->conv_base + (size_t)t0 * g->conv_stride, rows * rowb, res ? 14 : -1, 2, sd, wd);
                if (res) {
                    we_mt_bd(e, ta, 2, EF_MT_BASE + (uint32_t)(hdrs + a_pass), (uint32_t)r_pass, 0, 0, 0, 0, 0, -1);
                    we_mt_queue(e, ta, DMA_S2MM, 2, 1);
                    const int wr[3] = {256, 6 * MBP, g->n / 48};
                    we_sh_bd(e, k, 14, we_tile(g->res, r, 0) + (size_t)mb0 * 64 * 48, (int)r_pass, -1, 3, st, wr);
                }
            } else if (act) {
                we_sh_bd(e, k, 13, we_tile(g->a, r, 0) + (size_t)mb0 * 64 * 48, (int)a_pass, res ? 14 : -1, 3, st, wa);
                if (res) {
                    const int wr[3] = {256, 6 * MBP, g->n / 48};
                    we_sh_bd(e, k, 14, we_tile(g->res, r, 0) + (size_t)mb0 * 64 * 48, (int)r_pass, -1, 3, st, wr);
                }
            }
            we_sh_start(e, k, 1, 12);
        }
        we_sb_sync(e);
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
                for (int c = 0; c < 4; c++) {
                    const int cb = s * NSB + c * NBS;
                    dst[r][c] = rm   ? g->out_rm + ((size_t)r * RB + mb0 * 64) * g->n + cb * 48
                                : lg ? (bf16_t *)(g->logits + (size_t)cb * 192)
                                     : we_tile(g->out, r, cb) + (size_t)mb0 * 64 * 48;
                }
            we_sb_begin(e);
            if (rm)
                we_arm_out(e, g->ract, dst, WE_BLK, MBP, 64 * g->n * 2, 96, 64, g->n * 2, ev);
            else if (lg)
                we_arm_out(e, g->ract, dst, 768, NBS, 768, 768, 1, 768, ev);
            else
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
                    we_mt_bd(e, ta, 2, abase, (uint32_t)(64 * K * 2), 3, sa, wa, 1536, MBP,
                             g->wsplit ? 8 : (res ? 3 : -1));
                    if (g->wsplit) /* the same A chunks again, against Wl */
                        we_mt_bd(e, ta, 8, abase, (uint32_t)(64 * K * 2), 3, sa, wa, 1536, MBP, res ? 3 : -1);
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
            we_sb_sync(e);
            XTime_GetTime(&q1);
            for (int r = 0; r < g->ract; r++)
                if (we_wait_out(e, ev[r]))
                    return -1;
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

/* ---- attention ---------------------------------------------------------- */
/* Column permutation of q/k/v/o (384 = 6 heads x 64): head h, dim d lives at
 * tile 2*(d/16) + h/3, kt (h%3)*2 + (d%16)/8, lane d%8 of the 8 48-col tiles, so
 * every head is 4 runs of 16 cols at a 2-tile stride (one DMA pattern). */
static inline int we_head_col(int h, int d) {
    return (2 * (d / 16) + h / 3) * 48 + ((h % 3) * 2 + (d % 16) / 8) * 8 + d % 8;
}

typedef struct {
    const WeAct *q; /* [M x C], q heads in tiles q_cb .. q_cb+7 (head-permuted) */
    int q_cb;
    const WeAct *kv; /* keys: K^T tiles kt_cb.., V tiles vt_cb.. (we_gemm WE_F_KT / WE_F_VT) */
    int kt_cb, vt_cb;
    const WeAct *out; /* [M x 384], head-permuted */
    int t;            /* valid keys */
    int causal, ract; /* ract: mesh rows holding queries */
    int krows;        /* row blocks of kv holding keys */
} WeAttn;

/* Output packet: d0 = 2 kt (128 B), d1 = 4 pairs at 2 tiles, d2 = WE_QB/4 row groups */
static void we_arm_out_att(WeEng *e, int ract, bf16_t *const dst[4][4], const int nqb[4], size_t tileb,
                           struct_ioevent *ev) {
    for (int r = 0; r < ract; r++) {
        XAie_LocType s = we_shim(we_out_col[r]);
        XAie_DmaDesc d = {};
        int any = 0;
        for (int c = 0; c < 4; c++) {
            if (!nqb[c])
                continue;
            d = we_shim_bd(e, s, dst[r][c], we_ooo[r][c], WE_Q_CHUNK, -1, 0, we_pkt[r][c], we_ooo[r][c], 3, 4, 32,
                           (int)(2 * tileb), 4, 384, WE_QB / 4, WE_QB / 4 * 384, nqb[c]);
            any += nqb[c];
        }
        we_ooo_enable(e, s, we_out_ch[r]);
        ev[r] = __Runtime_startio(e->dev, __Runtime_dma_createio_4(s, d, we_out_ch[r], we_ooo[r][0], DMA_S2MM),
                                  we_ooo[r][0], any);
    }
}

static int we_attn_round(WeEng *e, const WeAttn *a, const int head[4], const int nqb[4], const int qb0[4]) {
    if (we_prog(e, 2))
        return -1;
    const int RB = a->q->rb, KBPR = a->kv->rb / 64, rk = a->krows, NKC = KBPR * rk; /* 64-key chunks */
    const size_t tileb = (size_t)RB * 48 * 2, qtile = tileb, kvtile = (size_t)a->kv->rb * 48 * 2;
    const size_t kvrow = (size_t)(a->kv->c / 48) * kvtile; /* bytes between row blocks of kv */
    int steps = 0;
    for (int c = 0; c < 4; c++)
        steps = nqb[c] > steps ? nqb[c] : steps;
    XTime p0, p1, p2, p3;
    XTime_GetTime(&p0);
    we_hdr_begin(e, WE_OP_ATTN, a->ract);
    e->hdr[WH_T] = a->t;
    e->hdr[WH_NKC] = NKC;
    e->hdr[WH_AFLAGS] = a->causal ? WE_A_CAUSAL : 0;
    for (int c = 0; c < 4; c++) {
        e->hdr[WH_NQB + c] = nqb[c];
        e->hdr[WH_Q0 + c] = qb0[c] * WE_QB;
    }
    e->hdr[WH_STEPS] = steps;
    __Runtime_sync_for_dev(e->dev, e->hdr, WE_HDR_BYTES);
    struct_ioevent ev[4];
    bf16_t *dst[4][4];
    for (int r = 0; r < 4; r++)
        for (int c = 0; c < 4; c++)
            dst[r][c] = we_tile(a->out, r, head[c] / 3) + (head[c] % 3) * 64 + (size_t)qb0[c] * (WE_QB / 4) * 6 * 32;
    we_sb_begin(e);
    we_arm_out_att(e, a->ract, dst, nqb, tileb, ev);
    // A: header + this row block's q tiles; B: the head's K^T and V, gathered chunk-major
    for (int k = 1; k <= 4; k++) {
        const int r = k - 1, act = k <= a->ract;
        XAie_LocType ta = we_mt(k, EF_MT_A_ROW), tb = we_mt(k, EF_MT_B_ROW);
        we_mt_bd(e, ta, 0, EF_MT_BASE, (uint32_t)(WE_HDR_BYTES + (act ? 8 * qtile : 0)), 0, 0, 0, 0, 0, -1);
        we_mt_queue(e, ta, DMA_S2MM, 0, 1);
        we_sh_bd(e, k, 12, e->hdr, WE_HDR_BYTES, act ? 13 : -1, 0, 0, 0);
        if (act)
            we_sh_bd(e, k, 13, we_tile(a->q, r, a->q_cb), (int)(8 * qtile), -1, 0, 0, 0);
        we_sh_start(e, k, 1, 12);
        const int c = k - 1, h = head[c];
        if (!nqb[c])
            continue;
        /* chunk b (64 keys) = 16 KB: K^T [kd = 2j+dt][kp 8][64] then V [kp 8][dt = 2j+dtp][64] */
        const uint32_t kst[3] = {1, 256, 4096}, kwr[3] = {256, 2, 0};
        we_mt_bd(e, tb, 0, EF_MT_BASE, (uint32_t)(2048 * KBPR * rk), 3, kst, kwr, 512, 4, -1);
        const uint32_t vst[3] = {1, 256, 4096}, vwr[3] = {64, 8, 0};
        we_mt_bd(e, tb, 1, EF_MT_BASE + 8192, (uint32_t)(2048 * KBPR * rk), 3, vst, vwr, 64, 4, -1);
        we_mt_queue(e, tb, DMA_S2MM, 0, 4);
        we_mt_queue(e, tb, DMA_S2MM, 1, 4);
        const bf16_t *ks = we_tile(a->kv, 0, a->kt_cb + h / 3) + (h % 3) * 1024;
        const bf16_t *vs = we_tile(a->kv, 0, a->vt_cb + h / 3) + (h % 3) * 128;
        we_shim_bd(e, we_shim(k), ks, 15, 2048 * KBPR * rk, -1, 0, 0, -1, 3, 4, 512, WE_BLK, KBPR, (int)kvrow, rk,
                   (int)(2 * kvtile), 4);
        we_shim_bd(e, we_shim(k), vs, 14, 2048 * KBPR * rk, -1, 0, 0, -1, 3, 4, 64, 768, 8 * KBPR, (int)kvrow, rk,
                   (int)(2 * kvtile), 4);
        XAie_DmaDesc d0 = {};
        __Runtime_startio(e->dev, __Runtime_dma_createio_4(we_shim(k), d0, 0, 15, DMA_MM2S), 15, 4);
        __Runtime_startio(e->dev, __Runtime_dma_createio_4(we_shim(k), d0, 0, 14, DMA_MM2S), 14, 4);
    }
    we_sb_sync(e);
    int rc = 0;
    for (int k = 1; k <= 4 && !rc; k++) {
        rc |= we_wait_ch(e, we_mt(k, EF_MT_A_ROW), 0, DMA_S2MM);
        if (nqb[k - 1])
            rc |= we_wait_ch(e, we_mt(k, EF_MT_B_ROW), 0, DMA_S2MM);
    }
    XTime_GetTime(&p1);
    for (int k = 1; k <= 4; k++) {
        XAie_LocType ta = we_mt(k, EF_MT_A_ROW), tb = we_mt(k, EF_MT_B_ROW);
        we_mt_bd(e, ta, 1, EF_MT_BASE, WE_HDR_BYTES, 0, 0, 0, 0, 0, -1);
        we_mt_queue(e, ta, DMA_MM2S, 1, 1);
        if (k <= a->ract) {
            for (int c = 0; c < 4; c++) {
                const int h = head[c];
                const uint32_t base = EF_MT_BASE + WE_HDR_BYTES +
                                      (uint32_t)((h / 3) * qtile + (h % 3) * 128 + (size_t)qb0[c] * (WE_QB / 4) * 384);
                const uint32_t st[3] = {1, (uint32_t)(2 * qtile / 4), 96}, wr[3] = {32, 4, 0};
                we_mt_bd(e, ta, 3 + c, base, WE_Q_CHUNK, 3, st, wr, (WE_QB / 4) * 96, steps, c < 3 ? 4 + c : -1);
            }
            we_mt_queue(e, ta, DMA_MM2S, 3, steps);
        }
        if (nqb[k - 1]) {
            we_mt_bd(e, tb, 2, EF_MT_BASE, (uint32_t)(NKC * 2 * WE_KV_CHUNK), 0, 0, 0, 0, 0, -1);
            we_mt_queue(e, tb, DMA_MM2S, 2, nqb[k - 1]);
        }
    }
    XTime_GetTime(&p2);
    for (int r = 0; r < a->ract; r++)
        if (we_wait_out(e, ev[r]))
            return -1;
    XTime_GetTime(&p3);
    e->t_fill += we_us(p0, p1);
    e->t_arm += we_us(p1, p2);
    e->t_run += we_us(p2, p3);
    return rc;
}

/* All 6 heads: round 1 heads 0..3 (one per column), round 2 heads 4,5 split by
 * q-blocks over two columns each. */
static int we_attn(WeEng *e, const WeAttn *a) {
    const int QB = a->q->rb / WE_QB; /* q-blocks per row block */
    const int h1[4] = {0, 1, 2, 3}, n1[4] = {QB, QB, QB, QB}, z[4] = {0, 0, 0, 0};
    if (we_attn_round(e, a, h1, n1, z))
        return -1;
    if (QB >= 2) {
        const int h2[4] = {4, 4, 5, 5}, n2[4] = {QB / 2, QB - QB / 2, QB / 2, QB - QB / 2},
                  q2[4] = {0, QB / 2, 0, QB / 2};
        return we_attn_round(e, a, h2, n2, q2);
    }
    const int h2[4] = {4, 5, 4, 5}, n2[4] = {QB, QB, 0, 0};
    return we_attn_round(e, a, h2, n2, z);
}

/* Header to the idle mesh rows too (cores of rows >= ract only read it). */
#endif
