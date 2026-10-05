/******************************************************************************
 * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 ******************************************************************************/

#include "aie_ctrlpkt_sites.h"

#include "aie_ctrlpkt_aot.h"
#include "aie_ctrlpkt_encode.h"
#include "aie_device_map.h"
#include "aie_runtime_control_plan.h"
#include "aie_runtime_xaie_seq.h"
#include "ctrlpkt_dbg.h"

#include <dirent.h>
#include <stdarg.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define S_MAX_CALLS 128
#define S_MAX_WRITES 64
#define S_MAX_REC 4096
#define S_MAX_MARKS 256
#define S_SEG_WORDS ((4096U / RT_RES_SHIMROW_MAX_COLS) & ~3U)

typedef struct {
    int kind;
    int col, row, argidx;
    long off;
    int v[19];
    int ch, dir, bd, repeat;
    int line;
} s_call;

typedef struct {
    int kind, row, n, line;
    unsigned addr, data[16];
} s_write;

typedef struct {
    int gen, start_col, ncols;
    int has_plan, shim_col, ctrl_id, resp, nrows, rows[ACR_MAX_ROWS][3], plan_line;
    int nwrites;
    s_write writes[S_MAX_WRITES];
    int core_enable, core_line;
    int has_window, ncalls, batch, nbufs;
    s_call calls[S_MAX_CALLS];
} s_sites;

typedef struct {
    uint64_t regoff;
    uint32_t val;
} s_rec;
static s_rec g_rec[S_MAX_REC];
static uint32_t g_nrec;
static int g_bad, g_ret_mode;
static XAie_DevInst g_dev;
static XAie_Backend g_be;

static AieRC rec_w32(void *io, u64 regoff, u32 val) {
    (void)io;
    if (g_nrec >= S_MAX_REC) {
        g_bad = 1;
        return XAIE_ERR;
    }
    g_rec[g_nrec].regoff = regoff;
    g_rec[g_nrec++].val = val;
    return XAIE_OK;
}
static AieRC rec_bw32(void *io, u64 regoff, const u32 *d, u32 n) {
    if (g_ret_mode) {
        g_bad = 1;
        return XAIE_ERR;
    }
    for (u32 i = 0U; i < n; i++)
        if (rec_w32(io, regoff + 4U * i, d[i]) != XAIE_OK)
            return XAIE_ERR;
    return XAIE_OK;
}
static AieRC rec_runop(void *io, XAie_DevInst *dev, XAie_BackendOpCode op, void *arg) {
    (void)dev;
    if (op != XAIE_BACKEND_OP_CONFIG_SHIMDMABD || g_ret_mode) {
        g_bad = 1;
        return XAIE_ERR;
    }
    const XAie_ShimDmaBdArgs *a = (const XAie_ShimDmaBdArgs *)arg;
    return rec_bw32(io, a->Addr, a->BdWords, a->NumBdWords);
}
static AieRC rec_bad_mw32(void *io, u64 r, u32 m, u32 v) {
    (void)io, (void)r, (void)m, (void)v;
    g_bad = 1;
    return XAIE_ERR;
}
static AieRC rec_bad_r32(void *io, u64 r, u32 *d) {
    (void)io, (void)r;
    *d = 0U;
    g_bad = 1;
    return XAIE_ERR;
}
static AieRC rec_bad_poll(void *io, u64 r, u32 m, u32 v, u32 t) {
    (void)io, (void)r, (void)m, (void)v, (void)t;
    g_bad = 1;
    return XAIE_ERR;
}
static AieRC rec_bad_bset(void *io, u64 r, u32 d, u32 n) {
    (void)io, (void)r, (void)d, (void)n;
    g_bad = 1;
    return XAIE_ERR;
}

static int dev_init(int start, int ncols) {
    XAie_SetupConfig(cfg, HW_GEN, XAIE_BASE_ADDR, XAIE_COL_SHIFT, XAIE_ROW_SHIFT, XAIE_NUM_COLS, XAIE_NUM_ROWS,
                     XAIE_SHIM_ROW, XAIE_RES_TILE_ROW_START, XAIE_RES_TILE_NUM_ROWS, XAIE_AIE_TILE_ROW_START,
                     XAIE_AIE_TILE_NUM_ROWS);
    memset(&g_dev, 0, sizeof(g_dev));
    if (ncols <= 0)
        ncols = XAIE_NUM_COLS - start;
    if (XAie_SetupPartitionConfig(&g_dev, XAIE_BASE_ADDR + ((uint64_t)start << XAIE_COL_SHIFT), (u8)start,
                                  (u8)ncols) != XAIE_OK)
        return -1;
#if AIE_GEN == 5
    XAie_SetXprodEnable(&g_dev, XAIE_DISABLE);
#endif
    if (XAie_CfgInitialize(&g_dev, &cfg) != XAIE_OK)
        return -1;
    g_be = *g_dev.Backend;
    g_be.Ops.Write32 = rec_w32;
    g_be.Ops.BlockWrite32 = rec_bw32;
    g_be.Ops.RunOp = rec_runop;
    g_be.Ops.MaskWrite32 = rec_bad_mw32;
    g_be.Ops.Read32 = rec_bad_r32;
    g_be.Ops.MaskPoll = rec_bad_poll;
    g_be.Ops.BlockSet32 = rec_bad_bset;
    g_dev.Backend = &g_be;
    return 0;
}

static void decode(uint64_t regoff, int *col, int *row, uint32_t *off) {
    uint8_t rs = g_dev.DevProp.RowShift, cs = g_dev.DevProp.ColShift;
    *off = (uint32_t)(regoff & ((1ULL << rs) - 1U));
    *row = (int)((regoff >> rs) & ((1ULL << (cs - rs)) - 1U));
    *col = (int)(uint8_t)(regoff >> cs);
}

static int parse_sites(const char *path, s_sites *s) {
    FILE *f = fopen(path, "r");
    if (!f)
        return -1;
    memset(s, 0, sizeof(*s));
    s->gen = 5;
    char line[1024];
    while (fgets(line, sizeof(line), f)) {
        char *tok[64];
        int nt = 0;
        for (char *t = strtok(line, " \t\r\n"); t && nt < 64; t = strtok(NULL, " \t\r\n"))
            tok[nt++] = t;
        if (nt == 0 || tok[0][0] == '#')
            continue;
#define I(k) ((int)strtol(tok[k], NULL, 0))
        if (!strcmp(tok[0], "gen") && nt >= 2) {
            s->gen = I(1);
        } else if (!strcmp(tok[0], "partition") && nt >= 3) {
            s->start_col = I(1);
            s->ncols = I(2);
        } else if (!strcmp(tok[0], "plan") && nt >= 5) {
            s->has_plan = 1;
            s->shim_col = I(1), s->ctrl_id = I(2), s->resp = I(3), s->nrows = I(4);
            for (int r = 0; r < s->nrows && r < ACR_MAX_ROWS && 5 + 3 * r + 2 < nt; r++)
                for (int c = 0; c < 3; c++)
                    s->rows[r][c] = I(5 + 3 * r + c);
        } else if (!strcmp(tok[0], "write") && nt >= 5 && s->nwrites < S_MAX_WRITES) {
            s_write *w = &s->writes[s->nwrites++];
            w->kind = !strcmp(tok[1], "bcast") ? RT_AOT_WR_BCAST : RT_AOT_WR_ROW_ACK;
            w->row = I(2), w->addr = (unsigned)I(3), w->n = I(4);
            for (int i = 0; i < w->n && i < 16 && 5 + i < nt; i++)
                w->data[i] = (unsigned)strtoul(tok[5 + i], NULL, 0);
        } else if (!strcmp(tok[0], "core_enable")) {
            s->core_enable = 1;
        } else if (!strcmp(tok[0], "shim_bd") && nt >= 2 && !strcmp(tok[1], "begin")) {
            s->has_window = 1;
        } else if (!strcmp(tok[0], "shim_bd") && nt >= 3 && !strcmp(tok[1], "batch")) {
            s->batch = 1;
            s->nbufs = I(2);
        } else if (!strcmp(tok[0], "call") && nt >= 4 && s->ncalls < S_MAX_CALLS) {
            s_call *c = &s->calls[s->ncalls];
            memset(c, 0, sizeof(*c));
            c->col = I(2), c->row = I(3);
            if ((!strcmp(tok[1], "bd") || !strcmp(tok[1], "bd_ooo")) && nt >= 25) {
                c->kind = !strcmp(tok[1], "bd") ? RT_AOT_CALL_BD : RT_AOT_CALL_BD_OOO;
                c->argidx = I(4), c->off = strtol(tok[5], NULL, 0);
                for (int i = 0; i < 19; i++)
                    c->v[i] = I(6 + i);
                c->bd = c->v[0];
            } else if (!strcmp(tok[1], "ch_ooo") && nt >= 6) {
                c->kind = RT_AOT_CALL_CH_OOO, c->ch = I(4), c->dir = I(5);
            } else if (!strcmp(tok[1], "start") && nt >= 8) {
                c->kind = RT_AOT_CALL_START, c->ch = I(4), c->dir = I(5), c->bd = I(6), c->repeat = I(7);
            } else {
                continue;
            }
            s->ncalls++;
        }
#undef I
    }
    fclose(f);
    return 0;
}

static int host_line(const char *host_cc, const char *api, int nth, int lo_line, int hi_line) {
    FILE *f = host_cc ? fopen(host_cc, "r") : NULL;
    if (!f)
        return 0;
    char needle[128], buf[4096];
    snprintf(needle, sizeof(needle), "%s(", api);
    int ln = 0, seen = 0, found = 0;
    while (fgets(buf, sizeof(buf), f)) {
        ln++;
        if (ln < lo_line || (hi_line > 0 && ln > hi_line) || !strstr(buf, needle))
            continue;
        if (seen++ == nth) {
            found = ln;
            break;
        }
    }
    fclose(f);
    return found;
}

static void assign_lines(s_sites *s, const char *host_cc) {
    s->plan_line = host_line(host_cc, "__Runtime_ctrl_plan_init", 0, 0, 0);
    s->core_line = host_line(host_cc, "__Runtime_launch_kernel_group_ctrl", 0, 0, 0);
    int nb = 0, nr = 0;
    for (int i = 0; i < s->nwrites; i++) {
        s_write *w = &s->writes[i];
        w->line = w->kind == RT_AOT_WR_BCAST ? host_line(host_cc, "__Runtime_ctrl_row_broadcast_write", nb++, 0, 0)
                                             : host_line(host_cc, "__Runtime_ctrl_row_write_ack", nr++, 0, 0);
    }
    int lo = host_line(host_cc, "__Runtime_ctrl_shim_bd_begin", 0, 0, 0);
    int hi = host_line(host_cc, "__Runtime_ctrl_shim_bd_commit", 0, lo, 0);
    int seen[5] = {0};
    static const char *names[5] = {"", "__Runtime_dma_bd_config_multidim", "__Runtime_dma_bd_config_multidim_ooo",
                                   "__Runtime_dma_channel_enable_ooo", "__Runtime_startio"};
    int batch_line = s->batch ? host_line(host_cc, "__Runtime_ctrl_aot_window", 0, 0, 0) : 0;
    for (int i = 0; i < s->ncalls; i++) {
        s_call *c = &s->calls[i];
        c->line = s->batch ? batch_line : host_line(host_cc, names[c->kind], seen[c->kind]++, lo, hi);
    }
}

static acr_state g_spine;
static acr_portbook g_book;
static int g_fab[ACR_MAX_ROWS][3];
static int g_nfab;

typedef struct {
    rt_cpe_wr wr[S_MAX_REC];
    char why[S_MAX_REC][128];
    uint32_t n;
} s_retw;
static s_retw g_retw;
static int g_plan_bad;

static const char *port_name(acr_port p) {
    switch (p) {
    case ACR_WEST:
        return "WEST";
    case ACR_EAST:
        return "EAST";
    case ACR_NORTH:
        return "NORTH";
    case ACR_SOUTH:
        return "SOUTH";
    default:
        return "CTRL";
    }
}

static void op_desc(const acr_op *op, char *buf, size_t n) {
    uint8_t sidx = rt_seq_acr_chan(op->sport, 0, op->sidx), midx = rt_seq_acr_chan(op->mport, 1, op->midx);
    switch (op->kind) {
    case ACR_OP_SLOT:
        snprintf(buf, n, "XAie_StrmPktSwSlaveSlotEnable tile(%u,%u) %s%u slot %u id 0x%02x mask 0x%02x msel %u arb %u",
                 op->col, op->row, port_name(op->sport), sidx, op->slot, op->pkt_id, op->mask, op->msel, op->arbiter);
        break;
    case ACR_OP_SLAVE_EN:
        snprintf(buf, n, "XAie_StrmPktSwSlavePortEnable tile(%u,%u) %s%u", op->col, op->row, port_name(op->sport),
                 sidx);
        break;
    case ACR_OP_MASTER_EN:
        snprintf(buf, n, "XAie_StrmPktSwMstrPortEnable tile(%u,%u) %s%u arb %u msel_en 0x%x%s", op->col, op->row,
                 port_name(op->mport), midx, op->arbiter, op->mselen, op->keep_header ? " keep-header" : "");
        break;
    default:
        snprintf(buf, n, "XAie_StrmConnCctEnable tile(%u,%u) %s%u -> %s%u", op->col, op->row, port_name(op->sport),
                 sidx, port_name(op->mport), midx);
        break;
    }
}

static int record_op(const acr_op *op, int ret_mode) {
    uint32_t r0 = g_nrec;
    g_bad = 0;
    g_ret_mode = ret_mode;
    AieRC rc = rt_seq_row_op(&g_dev, op);
    g_ret_mode = 0;
    if (rc != XAIE_OK || g_bad) {
        g_nrec = r0;
        return -1;
    }
    return (int)r0;
}

static int plan_rows(const s_sites *s) {
    memset(&g_spine, 0, sizeof(g_spine));
    memset(&g_book, 0, sizeof(g_book));
    g_nfab = 0;
    g_retw.n = 0;
    g_plan_bad = 0;
    int top = s->rows[0][0];
    for (int i = 1; i < s->nrows; i++)
        if (s->rows[i][0] > top)
            top = s->rows[i][0];
    for (int i = 0; i < s->nrows; i++) {
        int row = s->rows[i][0], lo = s->rows[i][1], hi = s->rows[i][2];
        uint8_t before = g_spine.nrows;
        static acr_oplist ops;
        ops.n = 0;
        if (acr_plan_row_add(&g_spine, &ops, &g_book, (uint8_t)s->shim_col, (uint8_t)row, (uint8_t)lo, (uint8_t)hi,
                             (uint8_t)s->ctrl_id, row == top) != ACR_OK)
            return -1;
        uint32_t row_w0 = g_retw.n;
        int row_bad = 0;
        for (int j = 0; s->resp >= 0 && j < ops.n && !row_bad; j++) {
            const acr_op *op = &ops.ops[j];
            if (!op->is_ret || op->row != row || op->col < lo || op->col > hi)
                continue;
            g_nrec = 0U;
            if (record_op(op, 1) < 0) {
                row_bad = 1;
                break;
            }
            char why[128];
            op_desc(op, why, sizeof(why));
            for (uint32_t r = 0U; r < g_nrec && g_retw.n < S_MAX_REC; r++) {
                rt_cpe_wr *w = &g_retw.wr[g_retw.n];
                int c = 0, rr = 0;
                decode(g_rec[r].regoff, &c, &rr, &w->off);
                w->col = (uint8_t)c, w->row = (uint8_t)rr, w->val = g_rec[r].val, w->state = RT_CPE_WR_UNDECIDED;
                snprintf(g_retw.why[g_retw.n++], 128, "%s", why);
            }
        }
        if (row_bad) {
            g_retw.n = row_w0;
            g_plan_bad = 1;
        }
        if (g_spine.nrows > before && g_nfab < ACR_MAX_ROWS) {
            g_fab[g_nfab][0] = row, g_fab[g_nfab][1] = lo, g_fab[g_nfab][2] = hi;
            g_nfab++;
        }
    }
    return 0;
}

typedef struct {
    uint32_t at;
    char text[512];
} s_mark;

static void reg_name(uint32_t off, int shim, char *buf, size_t n) {
    buf[0] = '\0';
    const XAie_DmaMod *dm = g_dev.DevProp.DevMod[XAIEGBL_TILE_TYPE_SHIMNOC].DmaMod;
    const XAie_CoreMod *cm = g_dev.DevProp.DevMod[XAIEGBL_TILE_TYPE_AIETILE].CoreMod;
    if (shim && dm && off >= dm->BaseAddr && off < dm->BaseAddr + (uint32_t)dm->NumBds * dm->IdxOffset)
        snprintf(buf, n, " (shim BD%u word %u)", (unsigned)((off - dm->BaseAddr) / dm->IdxOffset),
                 (unsigned)(((off - dm->BaseAddr) % dm->IdxOffset) / 4U));
    else if (!shim && cm && off == cm->CoreCtrl->RegOff)
        snprintf(buf, n, " (Core_Control)");
}

static void emit_words(FILE *f, const uint32_t *w, uint32_t n, const s_mark *marks, int nmarks, const uint16_t *patch,
                       int npatch, int shim) {
    int m = 0;
    for (uint32_t i = 0U; i + 2U <= n;) {
        uint32_t ctrl = w[i + 1U], addr = ctrl & 0xFFFFFU, beats = ((ctrl >> 20U) & 0x3U) + 1U;
        uint32_t op = (ctrl >> 22U) & 0x3U, len = 2U + beats;
        if (i + len > n)
            len = n - i;
        for (; m < nmarks && marks[m].at < i + len; m++)
            fprintf(f, "\n    /* %s */\n", marks[m].text);
        fprintf(f, "    ");
        for (uint32_t k = 0U; k < len; k++)
            fprintf(f, "0x%08xu, ", (unsigned)w[i + k]);
        char rn[64];
        reg_name(addr, shim, rn, sizeof(rn));
        int patched = 0;
        for (int p = 0; p < npatch; p++)
            if (patch[p] != RT_AOT_NO_PATCH && patch[p] >= i && patch[p] < i + len)
                patched = 1;
        fprintf(f, "/* @%u: %s %u word%s at 0x%05x%s%s */\n", (unsigned)i,
                op == 0x2U ? "write-with-return," : "write", (unsigned)beats, beats > 1U ? "s" : "", (unsigned)addr, rn,
                patched ? "; buffer address patched at run time" : "");
        i += len;
    }
    for (; m < nmarks; m++)
        fprintf(f, "\n    /* %s */\n", marks[m].text);
}

static uint32_t g_plan_pkt[512], g_plan_words, g_plan_off[16], g_plan_val[16], g_plan_n;
static s_mark g_plan_marks[16];
static int g_plan_emit;

static void build_plan_ret(void) {
    g_plan_words = g_plan_n = 0U;
    uint32_t ntiles = 0U;
    for (int i = 0; i < g_nfab; i++)
        ntiles += (uint32_t)(g_fab[i][2] - g_fab[i][1] + 1);
    g_plan_n = rt_cpe_ret_split(g_retw.wr, g_retw.n, ntiles, g_plan_off, g_plan_val, 16U);
    for (uint32_t k = 0U; k < g_plan_n; k++) {
        const char *why = "";
        uint32_t tiles = 0U;
        for (uint32_t r = 0U; r < g_retw.n; r++)
            if (g_retw.wr[r].off == g_plan_off[k]) {
                if (!tiles)
                    why = g_retw.why[r];
                tiles++;
            }
        g_plan_marks[k].at = g_plan_words;
        snprintf(g_plan_marks[k].text, sizeof(g_plan_marks[k].text),
                 "%s; reg 0x%05x <- 0x%08x on all %u consumer tiles", why, (unsigned)g_plan_off[k],
                 (unsigned)g_plan_val[k], (unsigned)tiles);
        g_plan_words += rt_cpe_pktize(g_plan_pkt + g_plan_words, 512U - g_plan_words, ACR_ID_BCAST, g_plan_off[k],
                                      &g_plan_val[k], 1U, 0, 0U);
    }
}

typedef struct {
    int kind, row, n, line, sid;
    uint32_t addr, data[16], pkt[64], words;
    char what[256];
} s_wout;
static s_wout g_wout[S_MAX_WRITES + 1];
static int g_nwout;

static void build_writes(const s_sites *s) {
    g_nwout = 0;
    for (int i = 0; i < s->nwrites; i++) {
        const s_write *w = &s->writes[i];
        int rowidx = -1;
        for (int r = 0; r < g_nfab; r++)
            if (g_fab[r][0] == w->row)
                rowidx = r;
        if (w->kind == RT_AOT_WR_ROW_ACK && (rowidx < 0 || rowidx > ACR_MAX_ROW_IDX))
            continue;
        s_wout *o = &g_wout[g_nwout++];
        o->kind = w->kind, o->row = w->kind == RT_AOT_WR_ROW_ACK ? w->row : 0, o->n = w->n, o->line = w->line;
        o->addr = w->addr;
        memcpy(o->data, w->data, sizeof(o->data));
        o->sid = w->kind == RT_AOT_WR_BCAST ? ACR_ID_BCAST : ((ACR_CLASS_WHOLE_ROW << 2) | (rowidx & 0x3));
        o->words = rt_cpe_pktize(o->pkt, 64U, (uint32_t)o->sid, w->addr, w->data, (uint32_t)w->n,
                                 w->kind == RT_AOT_WR_ROW_ACK, 0U);
        int lock = w->addr >= 0x1F000U && w->addr < 0x1F400U && ((w->addr - 0x1F000U) % 0x10U) == 0U;
        char lk[96] = "";
        if (lock && w->n == 1)
            snprintf(lk, sizeof(lk), "; = XAie_LockSetValue(lock %u, value %u)", (w->addr - 0x1F000U) / 0x10U,
                     w->data[0]);
        snprintf(o->what, sizeof(o->what), "host.cc:%d %s(addr 0x%05x, %d word%s)%s -> %s", w->line,
                 w->kind == RT_AOT_WR_BCAST ? "__Runtime_ctrl_row_broadcast_write" : "__Runtime_ctrl_row_write_ack",
                 w->addr, w->n, w->n > 1 ? "s" : "", lk,
                 w->kind == RT_AOT_WR_BCAST ? "broadcast to every core tile"
                                            : "every column of the row, each acknowledges");
    }
    if (s->core_enable && g_nwout <= S_MAX_WRITES) {
        const XAie_RegCoreCtrl *cc = g_dev.DevProp.DevMod[XAIEGBL_TILE_TYPE_AIETILE].CoreMod->CoreCtrl;
        s_wout *o = &g_wout[g_nwout++];
        memset(o, 0, sizeof(*o));
        o->kind = RT_AOT_WR_BCAST, o->n = 1, o->line = s->core_line, o->addr = cc->RegOff, o->sid = ACR_ID_BCAST;
        o->data[0] = cc->CtrlEn.Mask;
        o->words = rt_cpe_pktize(o->pkt, 64U, ACR_ID_BCAST, o->addr, o->data, 1U, 0, 0U);
        snprintf(o->what, sizeof(o->what),
                 "host.cc:%d __Runtime_launch_kernel_group_ctrl -> Core_Control <- 0x%x on every core tile "
                 "(MMIO path: XAie_CoreEnable)",
                 s->core_line, o->data[0]);
    }
}

static uint32_t g_seg[RT_AOT_SB_MAX_SEGS][S_SEG_WORDS];
static rt_cpe_seg g_st[RT_AOT_SB_MAX_SEGS];
static uint32_t g_prefix[RT_AOT_SB_MAX_SEGS], g_len[RT_AOT_SB_MAX_SEGS], g_last[RT_AOT_SB_MAX_SEGS];
static uint32_t g_prefix_last[RT_AOT_SB_MAX_SEGS];
static s_mark g_marks[RT_AOT_SB_MAX_SEGS][S_MAX_MARKS];
static int g_nmarks[RT_AOT_SB_MAX_SEGS];
static rt_aot_sb_call g_calls[S_MAX_CALLS];
static int g_call_src[S_MAX_CALLS];
static char g_call_what[S_MAX_CALLS][256];
static int g_ncalls, g_lo, g_hi, g_window_ok;

static void add_mark(int k, const char *text) {
    if (g_nmarks[k] >= S_MAX_MARKS)
        return;
    g_marks[k][g_nmarks[k]].at = g_st[k].pw;
    snprintf(g_marks[k][g_nmarks[k]++].text, sizeof(g_marks[k][0].text), "%s", text);
}

static int append_records(uint32_t r0, const char *banner, int *seg_out, uint16_t *bdpos) {
    int first = -1;
    for (uint32_t r = r0; r < g_nrec; r++) {
        int col = 0, row = 0;
        uint32_t off = 0U;
        decode(g_rec[r].regoff, &col, &row, &off);
        if (row != 0 || col < g_lo || col > g_hi)
            return -1;
        int k = col - g_lo;
        if (first < 0) {
            first = k;
            if (banner)
                add_mark(k, banner);
        }
        if (rt_cpe_seg_write(&g_st[k], g_seg[k], S_SEG_WORDS, acr_shim_row_id((uint8_t)k), off, &g_rec[r].val, 1U) !=
            0)
            return -1;
        if (bdpos && r - r0 < 9U)
            bdpos[r - r0] = (uint16_t)(g_st[k].pw - 1U);
    }
    if (seg_out)
        *seg_out = first;
    return 0;
}

static void bd_args_of(const s_call *c, rt_seq_bd_args *a) {
    memset(a, 0, sizeof(*a));
    a->bd_id = c->v[0], a->len = c->v[1], a->next_bd = c->v[2], a->enable_packet = c->v[3], a->packet_id = c->v[4];
    a->acquire_lock_id = c->v[5], a->acquire_lock_val = c->v[6], a->release_lock_id = c->v[7];
    a->release_lock_val = c->v[8], a->out_of_order_bd_id = c->v[9], a->num_dims = c->v[10];
    a->ooo = c->kind == RT_AOT_CALL_BD_OOO;
    for (int i = 0; i < 3; i++)
        a->stride[i] = c->v[11 + 2 * i], a->wrap[i] = c->v[12 + 2 * i];
    if (a->ooo) {
        if (a->num_dims > 3)
            a->num_dims = 3;
        a->iter_step_size = c->v[17], a->iter_wrap = c->v[18];
    } else {
        if (a->num_dims > 4)
            a->num_dims = 4;
        a->stride[3] = c->v[17], a->wrap[3] = c->v[18];
    }
}

static int record_bd(const s_call *c, uint64_t addr) {
    rt_seq_bd_args a;
    bd_args_of(c, &a);
    XAie_LocType t = XAie_TileLoc((u8)c->col, (u8)c->row);
    XAie_DmaDesc d;
    g_bad = 0;
    if (rt_seq_bd_desc(&g_dev, t, addr, &a, &d) != XAIE_OK)
        return -1;
    return (XAie_DmaWriteBd(&g_dev, &d, t, (u8)a.bd_id) != XAIE_OK || g_bad) ? -1 : 0;
}

static int check_addr_fields(const s_call *c, const uint32_t *base) {
    const uint64_t test = 0x0000ABCD12345670ULL;
    uint32_t r0 = g_nrec, f[3];
    int rb = record_bd(c, test);
    AieRC rf = rt_seq_shim_bd_addr_fields(&g_dev, XAie_TileLoc((u8)c->col, (u8)c->row), test, f);
    if (rb != 0 || g_nrec - r0 != 9U || rf != XAIE_OK) {
        fprintf(stderr, "aiehlc_ctrlpkt: BD address probe failed (encode %d, %u words, fields rc %d)\n", rb,
                (unsigned)(g_nrec - r0), (int)rf);
        g_nrec = r0;
        return -1;
    }
    int ok = 1;
    for (uint32_t w = 0U; w < 9U; w++) {
        uint32_t diff = g_rec[r0 + w].val ^ base[w];
        uint32_t want = w == RT_SEQ_SHIM_BD_ADDR_W0 ? f[0] : w == RT_SEQ_SHIM_BD_ADDR_W1 ? f[1]
                                                     : w == RT_SEQ_SHIM_BD_ADDR_W2      ? f[2]
                                                                                        : 0U;
        if (diff != want) {
            fprintf(stderr, "aiehlc_ctrlpkt: BD word %u: base 0x%08x test 0x%08x diff 0x%08x want 0x%08x\n",
                    (unsigned)w, (unsigned)base[w], (unsigned)g_rec[r0 + w].val, (unsigned)diff, (unsigned)want);
            ok = 0;
        }
    }
    g_nrec = r0;
    return ok ? 0 : -1;
}

static void call_what(const s_call *c, char *buf, size_t n) {
    if (c->kind == RT_AOT_CALL_BD || c->kind == RT_AOT_CALL_BD_OOO) {
        const int *v = c->v;
        char buf2[64] = "";
        if (c->argidx >= 0)
            snprintf(buf2, sizeof(buf2), "host arg %d + %ld", c->argidx, c->off);
        snprintf(buf, n,
                 "host.cc:%d %s(tile(%d,%d), buf=%s, bd=%d, len=%d, next=%d, pkt=%d/%d, lock acq %d/%d rel %d/%d, "
                 "ooo_bd=%d, dims=%d [%dx%d %dx%d %dx%d], %s %dx%d) -> XAie_DmaWriteBd shim BD%d",
                 c->line, c->kind == RT_AOT_CALL_BD ? "__Runtime_dma_bd_config_multidim"
                                                    : "__Runtime_dma_bd_config_multidim_ooo",
                 c->col, c->row, buf2[0] ? buf2 : "?", v[0], v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8], v[9],
                 v[10], v[11], v[12], v[13], v[14], v[15], v[16], c->kind == RT_AOT_CALL_BD ? "dim3" : "iter", v[17],
                 v[18], v[0]);
    } else if (c->kind == RT_AOT_CALL_CH_OOO) {
        snprintf(buf, n,
                 "host.cc:%d __Runtime_dma_channel_enable_ooo(tile(%d,%d), ch %d, %s) -> XAie_DmaWriteChannel "
                 "(out-of-order BD mode)",
                 c->line, c->col, c->row, c->ch, c->dir ? "MM2S" : "S2MM");
    } else {
        snprintf(buf, n,
                 "host.cc:%d __Runtime_startio(tile(%d,%d) ch %d %s, bd %d, repeat %d) -> "
                 "XAie_DmaChannelSetStartQueue",
                 c->line, c->col, c->row, c->ch, c->dir ? "MM2S" : "S2MM", c->bd, c->repeat);
    }
}

static int build_window(const s_sites *s) {
    g_ncalls = 0;
    g_window_ok = 0;
    if (!s->has_window || g_nfab == 0)
        return 0;
    g_lo = 0xFF, g_hi = 0;
    for (int i = 0; i < g_nfab; i++) {
        g_lo = g_fab[i][1] < g_lo ? g_fab[i][1] : g_lo;
        g_hi = g_fab[i][2] > g_hi ? g_fab[i][2] : g_hi;
    }
    if (s->shim_col + 1 != g_lo || g_hi - g_lo + 1 > RT_AOT_SB_MAX_SEGS)
        return 0;
    for (int k = 0; k < RT_AOT_SB_MAX_SEGS; k++) {
        rt_cpe_seg_reset(&g_st[k]);
        g_nmarks[k] = 0;
    }
    static acr_oplist fwd, ret;
    fwd.n = ret.n = 0;
    if (acr_plan_shim_row(&fwd, &ret, &g_book, (uint8_t)g_lo, (uint8_t)g_hi) != ACR_OK)
        return -1;
    int prefix_ok = 1;
    for (int j = 0; j < ret.n && prefix_ok; j++) {
        g_nrec = 0U;
        char why[160], banner[256];
        op_desc(&ret.ops[j], why, sizeof(why));
        snprintf(banner, sizeof(banner), "shim-row return route, set up by __Runtime_ctrl_shim_bd_begin: %s", why);
        if (record_op(&ret.ops[j], 0) < 0 || append_records(0U, banner, NULL, NULL) != 0)
            prefix_ok = 0;
    }
    if (!prefix_ok)
        for (int k = 0; k < RT_AOT_SB_MAX_SEGS; k++) {
            rt_cpe_seg_reset(&g_st[k]);
            g_nmarks[k] = 0;
        }
    for (int k = 0; k < RT_AOT_SB_MAX_SEGS; k++) {
        g_prefix[k] = g_st[k].pw;
        g_prefix_last[k] = g_st[k].pw ? g_st[k].last : RT_CPE_NONE;
    }

    for (int i = 0; i < s->ncalls; i++) {
        const s_call *c = &s->calls[i];
        if (c->row != 0 || c->col < g_lo || c->col > g_hi)
            continue;
        rt_aot_sb_call *o = &g_calls[g_ncalls];
        memset(o, 0, sizeof(*o));
        g_call_src[g_ncalls] = i;
        o->kind = (uint8_t)c->kind, o->col = (uint8_t)c->col, o->row = (uint8_t)c->row, o->ch = (uint8_t)c->ch;
        o->bd = (uint8_t)c->bd, o->dir = (uint8_t)c->dir, o->repeat = (uint8_t)c->repeat;
        o->patch[0] = o->patch[1] = o->patch[2] = RT_AOT_NO_PATCH;
        XAie_LocType t = XAie_TileLoc((u8)c->col, (u8)c->row);
        g_nrec = 0U;
        g_bad = 0;
        AieRC rc = XAIE_OK;
        if (c->kind == RT_AOT_CALL_BD || c->kind == RT_AOT_CALL_BD_OOO) {
            for (int k = 0; k < 19; k++)
                if (c->v[k] == -999999)
                    return -1;
            o->arg_hash = rt_aot_bd_hash(c->v, 19U);
            rc = record_bd(c, 0U) == 0 ? XAIE_OK : XAIE_ERR;
            if (rc == XAIE_OK) {
                uint32_t base[9] = {0};
                for (uint32_t w = 0U; w < 9U && w < g_nrec; w++)
                    base[w] = g_rec[w].val;
                if (g_nrec != 9U || check_addr_fields(c, base) != 0) {
                    fprintf(stderr,
                            "aiehlc_ctrlpkt: shim BD address fields not where expected (%u BD words); window "
                            "stays JIT\n",
                            (unsigned)g_nrec);
                    return -1;
                }
            }
        } else if (c->kind == RT_AOT_CALL_CH_OOO) {
            XAie_DmaChannelDesc cd;
            rc = rt_seq_channel_ooo_desc(&g_dev, t, &cd);
            if (rc == XAIE_OK)
                rc = XAie_DmaWriteChannel(&g_dev, &cd, t, (u8)c->ch, (XAie_DmaDirection)c->dir);
        } else {
            rc = rt_seq_start_queue(&g_dev, t, (uint8_t)c->ch, (XAie_DmaDirection)c->dir, (uint8_t)c->bd, c->repeat);
        }
        if (rc != XAIE_OK || g_bad) {
            fprintf(stderr, "aiehlc_ctrlpkt: call %d could not be recorded (rc=%d bad=%d); window stays JIT\n", i,
                    (int)rc, g_bad);
            return -1;
        }
        call_what(c, g_call_what[g_ncalls], sizeof(g_call_what[0]));
        char banner[300];
        snprintf(banner, sizeof(banner), "[call %d] %s", g_ncalls, g_call_what[g_ncalls]);
        int seg = -1;
        uint16_t pos[9];
        if (append_records(0U, banner, &seg, pos) != 0 || seg < 0)
            return -1;
        o->seg = (uint8_t)seg;
        if (c->kind == RT_AOT_CALL_BD || c->kind == RT_AOT_CALL_BD_OOO) {
            o->patch[0] = pos[RT_SEQ_SHIM_BD_ADDR_W0];
            o->patch[1] = pos[RT_SEQ_SHIM_BD_ADDR_W1];
            o->patch[2] = pos[RT_SEQ_SHIM_BD_ADDR_W2];
        }
        g_ncalls++;
    }
    for (int k = 0; k <= g_hi - g_lo; k++) {
        g_len[k] = rt_cpe_seg_finish(&g_st[k], g_seg[k]);
        g_last[k] = g_st[k].last;
    }
    g_window_ok = g_ncalls > 0;
    return 0;
}

static void write_batch_window(FILE *f, const s_sites *s) {
    static const char *kinds[5] = {"", "BD", "BD_OOO", "CH_OOO", "START"};
    fprintf(f, "/* ==== Batched window: host.cc:%d __Runtime_ctrl_aot_window(%d buffers) ====\n"
               " * Replaces __Runtime_ctrl_shim_bd_begin, these %d calls and __Runtime_ctrl_shim_bd_commit.\n"
               " * {kind, col, row, ch, bd, dir, repeat, bufidx, {wrapper int args}} */\n",
            s->ncalls ? s->calls[0].line : 0, s->nbufs, s->ncalls);
    fprintf(f, "static const rt_aot_win_call host_ctrlpkt_win_calls[] = {\n");
    int buf = 0;
    for (int i = 0; i < s->ncalls; i++) {
        const s_call *c = &s->calls[i];
        int is_bd = c->kind == RT_AOT_CALL_BD || c->kind == RT_AOT_CALL_BD_OOO;
        fprintf(f, "    {RT_AOT_CALL_%s, %d, %d, %d, %d, %d, %d, %d, {", kinds[c->kind], c->col, c->row, c->ch, c->bd,
                c->dir, c->repeat, is_bd ? buf : 0);
        for (int k = 0; k < 19; k++)
            fprintf(f, "%d%s", is_bd ? c->v[k] : 0, k < 18 ? ", " : "");
        char what[256];
        call_what(c, what, sizeof(what));
        fprintf(f, "}}, /* [%d] %s */\n", i, what);
        buf += is_bd;
    }
    fprintf(f, "};\nstatic const rt_aot_window host_ctrlpkt_window = {%du, %du, host_ctrlpkt_win_calls};\n\n",
            s->ncalls, buf);
}

static void write_table(FILE *f, const s_sites *s) {
    fprintf(f, "static const rt_aot_table host_ctrlpkt_table = {\n    RT_AOT_MAGIC, RT_AOT_VERSION, 0u,\n");
    fprintf(f, "    %du, %s,\n", g_nwout, g_nwout ? "host_ctrlpkt_writes" : "0");
    fprintf(f, "    %s,\n    %s,\n    %s,\n};\n", g_window_ok ? "&host_ctrlpkt_shim_bd" : "0",
            g_plan_emit ? "&host_ctrlpkt_plan" : "0", s->batch ? "&host_ctrlpkt_window" : "0");
}

static void write_window(FILE *f) {
    int ncols = g_hi - g_lo + 1;
    fprintf(f,
            "/* ==== Site: shim-BD window __Runtime_ctrl_shim_bd_begin .. __Runtime_ctrl_shim_bd_commit ====\n"
            " * One unicast segment per shim column %d..%d (stream id (1<<k)-1), sent by the commit as\n"
            " * chained BDs; each segment's last write is a write-with-return. The leading\n"
            " * return-route words are what the runtime captures at begin; it checks they match. */\n",
            g_lo, g_hi);
    for (int k = 0; k < ncols; k++) {
        fprintf(f, "\n/* shim (%d,0) segment, stream id 0x%02x, %u words */\n", g_lo + k, acr_shim_row_id((uint8_t)k),
                (unsigned)g_len[k]);
        fprintf(f, "static const uint32_t host_ctrlpkt_sb_seg%d[] = {\n", k);
        uint16_t patch[S_MAX_CALLS * 3];
        int np = 0;
        for (int i = 0; i < g_ncalls; i++)
            if (g_calls[i].seg == k)
                for (int j = 0; j < 3; j++)
                    patch[np++] = g_calls[i].patch[j];
        if (g_len[k] == 0U)
            fprintf(f, "    0u /* unused */\n");
        emit_words(f, g_seg[k], g_len[k], g_marks[k], g_nmarks[k], patch, np, 1);
        fprintf(f, "};\n");
    }
    fprintf(f, "\n/* Calls in host.cc order: matched one by one at run time. */\n");
    fprintf(f, "static const rt_aot_sb_call host_ctrlpkt_sb_calls[] = {\n");
    for (int i = 0; i < g_ncalls; i++) {
        const rt_aot_sb_call *c = &g_calls[i];
        fprintf(f, "    {%u, %u, %u, %u, %u, %u, %u, %u, 0x%08xu, {%u, %u, %u}}, /* [call %d] %s */\n", c->kind, c->col,
                c->row, c->ch, c->bd, c->dir, c->seg, c->repeat, (unsigned)c->arg_hash, c->patch[0], c->patch[1],
                c->patch[2], i, g_call_what[i]);
    }
    fprintf(f, "};\n\nstatic const rt_aot_shim_bd host_ctrlpkt_shim_bd = {\n    %du, %du, %du, host_ctrlpkt_sb_calls,\n    {",
            g_lo, g_hi, g_ncalls);
    for (int k = 0; k < RT_AOT_SB_MAX_SEGS; k++)
        k < ncols ? fprintf(f, "host_ctrlpkt_sb_seg%d, ", k) : fprintf(f, "0, ");
    const uint32_t *arrs[4] = {g_len, g_last, g_prefix, g_prefix_last};
    for (int a = 0; a < 4; a++) {
        fprintf(f, "},\n    {");
        for (int k = 0; k < RT_AOT_SB_MAX_SEGS; k++)
            fprintf(f, "0x%xu, ", k < ncols ? (unsigned)(a == 1 && g_len[k] == 0U ? 0U : arrs[a][k])
                                         : (a == 3 ? RT_CPE_NONE : 0U));
    }
    fprintf(f, "},\n};\n\n");
}

static void write_plan(FILE *f, const s_sites *s) {
    fprintf(f,
            "/* ==== Site: host.cc:%d __Runtime_ctrl_plan_init(shim col %d, ctrl id %d, response ch %d, %d rows) ====\n"
            " * Return routes of the core tiles. Writes identical on every consumer tile ride the\n"
            " * kernel-ELF payload (host_ctrlpkt_plan_pkt); the others are written over MMIO at plan\n"
            " * time (host_ctrlpkt_plan_mmio_*). Used only when the call's inputs match below. */\n",
            s->plan_line, s->shim_col, s->ctrl_id, s->resp, s->nrows);
    if (g_plan_n) {
        fprintf(f, "static const uint32_t host_ctrlpkt_plan_off[] = {");
        for (uint32_t k = 0U; k < g_plan_n; k++)
            fprintf(f, "0x%05xu, ", (unsigned)g_plan_off[k]);
        fprintf(f, "};\nstatic const uint32_t host_ctrlpkt_plan_val[] = {");
        for (uint32_t k = 0U; k < g_plan_n; k++)
            fprintf(f, "0x%08xu, ", (unsigned)g_plan_val[k]);
        fprintf(f, "};\nstatic const uint32_t host_ctrlpkt_plan_pkt[] = {\n");
        emit_words(f, g_plan_pkt, g_plan_words, g_plan_marks, (int)g_plan_n, NULL, 0, 0);
        fprintf(f, "};\n");
    }
    uint32_t nm = 0U;
    for (uint32_t r = 0U; r < g_retw.n; r++)
        nm += g_retw.wr[r].state == RT_CPE_WR_MMIO;
    if (nm) {
        fprintf(f, "/* XAie_Write32 at plan time, in this order: tile, offset, value */\n");
        const char *names[3] = {"tile", "off", "val"};
        for (int a = 0; a < 3; a++) {
            fprintf(f, a == 0 ? "static const uint8_t host_ctrlpkt_plan_mmio_tile[][2] = {\n"
                              : "static const uint32_t host_ctrlpkt_plan_mmio_%s[] = {\n",
                    names[a]);
            for (uint32_t r = 0U; r < g_retw.n; r++) {
                const rt_cpe_wr *w = &g_retw.wr[r];
                if (w->state != RT_CPE_WR_MMIO)
                    continue;
                if (a == 0)
                    fprintf(f, "    {%u, %u}, /* %s */\n", w->col, w->row, g_retw.why[r]);
                else
                    fprintf(f, "    0x%08xu,\n", (unsigned)(a == 1 ? w->off : w->val));
            }
            fprintf(f, "};\n");
        }
    }
    fprintf(f, "static const rt_aot_plan_ret host_ctrlpkt_plan = {\n    %uu, %s, %s, %s, %uu,\n    %d, %d, %d, %du, {",
            (unsigned)g_plan_n, g_plan_n ? "host_ctrlpkt_plan_off" : "0", g_plan_n ? "host_ctrlpkt_plan_val" : "0",
            g_plan_n ? "host_ctrlpkt_plan_pkt" : "0", (unsigned)g_plan_words, s->shim_col, s->ctrl_id, s->resp,
            s->nrows);
    for (int r = 0; r < s->nrows; r++)
        fprintf(f, "{%d, %d, %d}, ", s->rows[r][0], s->rows[r][1], s->rows[r][2]);
    fprintf(f, "},\n    %uu, %s, %s, %s};\n\n", (unsigned)nm, nm ? "host_ctrlpkt_plan_mmio_tile" : "0",
            nm ? "host_ctrlpkt_plan_mmio_off" : "0", nm ? "host_ctrlpkt_plan_mmio_val" : "0");
}

static void write_plan_and_writes(FILE *f, const s_sites *s) {
    g_plan_emit = s->has_plan && !g_plan_bad;
    if (g_plan_emit)
        write_plan(f, s);
    for (int i = 0; i < g_nwout; i++) {
        const s_wout *o = &g_wout[i];
        fprintf(f, "/* ==== Site: %s ==== */\nstatic const uint32_t host_ctrlpkt_wr%d_data[] = {", o->what, i);
        for (int k = 0; k < o->n; k++)
            fprintf(f, "0x%08xu, ", (unsigned)o->data[k]);
        fprintf(f, "};\nstatic const uint32_t host_ctrlpkt_wr%d_pkt[] = {\n", i);
        emit_words(f, o->pkt, o->words, NULL, 0, NULL, 0, 0);
        fprintf(f, "};\n\n");
    }
    if (g_nwout) {
        fprintf(f, "static const rt_aot_write host_ctrlpkt_writes[] = {\n");
        for (int i = 0; i < g_nwout; i++)
            fprintf(f, "    {%du, %du, 0x%05xu, %du, host_ctrlpkt_wr%d_data, host_ctrlpkt_wr%d_pkt, %uu},\n",
                    g_wout[i].kind, g_wout[i].row, (unsigned)g_wout[i].addr, g_wout[i].n, i, i,
                    (unsigned)g_wout[i].words);
        fprintf(f, "};\n\n");
    }
}

typedef struct {
    const s_sites *s;
    int shim, k;
} s_note;

static void app(char *buf, size_t n, int *u, const char *fmt, ...) __attribute__((format(printf, 4, 5)));
static void app(char *buf, size_t n, int *u, const char *fmt, ...) {
    if (*u < 0 || (size_t)*u >= n)
        return;
    if (*u)
        *u += snprintf(buf + *u, n - (size_t)*u, "; ");
    if ((size_t)*u >= n)
        return;
    va_list ap;
    va_start(ap, fmt);
    *u += vsnprintf(buf + *u, n - (size_t)*u, fmt, ap);
    va_end(ap);
}

static void site_note(void *ctx, uint32_t acc, uint32_t at, const uint32_t *w, uint32_t len, char *buf, size_t n) {
    (void)acc;
    const s_note *c = (const s_note *)ctx;
    char rn[64];
    int u = 0;
    buf[0] = '\0';
    uint32_t addr = w[1] & 0xFFFFFU;
    reg_name(addr, c->shim, rn, sizeof(rn));
    int core_val = !c->shim && len > 2U;
    if (rn[0] && core_val)
        app(buf, n, &u, "%.*s <- 0x%x", (int)strlen(rn) - 3, rn + 2, (unsigned)w[2]);
    else if (rn[0])
        app(buf, n, &u, "%.*s", (int)strlen(rn) - 3, rn + 2);
    else if (core_val && addr >= 0x1F000U && addr < 0x1F400U && (addr - 0x1F000U) % 0x10U == 0U)
        app(buf, n, &u, "lock %u value <- %u (XAie_LockSetValue)", (unsigned)((addr - 0x1F000U) / 0x10U),
            (unsigned)w[2]);
    if (c->k < 0)
        return;
    if (at < g_prefix[c->k])
        app(buf, n, &u, "shim-row return route: sent by the first window only");
    for (int i = 0; i < g_ncalls; i++) {
        if (g_calls[i].seg != c->k)
            continue;
        const s_call *sc = &c->s->calls[g_call_src[i]];
        char wl[32] = "";
        int nw = 0;
        for (int j = 0; j < 3; j++) {
            uint16_t p = g_calls[i].patch[j];
            if (p != RT_AOT_NO_PATCH && p >= at && p < at + len)
                nw += snprintf(wl + nw, sizeof(wl) - (size_t)nw, "%s%u", nw ? "," : "", (unsigned)p);
        }
        if (nw)
            app(buf, n, &u, "DDR address OR-ed into word %s at run time (host arg %d + %ld)", wl, sc->argidx, sc->off);
    }
}

static int to_marks(const s_mark *m, int nm, cpd_mark *out) {
    for (int i = 0; i < nm; i++) {
        out[i].at = m[i].at;
        out[i].text = m[i].text;
    }
    return nm;
}

static void dump_plan(const char *dir, const s_sites *s) {
    char title[768];
    snprintf(title, sizeof(title),
             "plan_ret: __Runtime_ctrl_plan_init at host.cc:%d (shim col %d, ctrl id %d, response ch %d, %d rows)\n"
             "Return-route writes identical on all consumer tiles, broadcast (stream id 0x%x) in front of the\n"
             "kernel-ELF body (kernel_<fn>_wire.h). Used only when ctrl_plan_init's inputs match the table.\n"
             "Writes that differ per tile stay MMIO: ctrlpkt_plan_ret_mmio[] below.",
             s->plan_line, s->shim_col, s->ctrl_id, s->resp, s->nrows, (unsigned)ACR_ID_BCAST);
    FILE *f = cpd_open_h(dir, "plan_ret", title);
    if (!f)
        return;
    cpd_mark m[16];
    s_note c = {s, 0, -1};
    FILE *ann = cpd_open_raw(dir, "plan_ret.ann", "w");
    cpd_array(f, ann, "plan_ret", g_plan_pkt, g_plan_words, m, to_marks(g_plan_marks, (int)g_plan_n, m), site_note,
              &c);
    if (ann)
        fclose(ann);
    fprintf(f, "\n/* XAie_Write32 at plan time, in this order: {col, row, offset, value} */\n"
               "static const uint32_t ctrlpkt_plan_ret_mmio[][4] = {\n");
    uint32_t nm = 0U;
    for (uint32_t r = 0U; r < g_retw.n; r++) {
        const rt_cpe_wr *w = &g_retw.wr[r];
        if (w->state != RT_CPE_WR_MMIO)
            continue;
        fprintf(f, "    {%uu, %uu, 0x%05xu, 0x%08xu}, /* %s */\n", w->col, w->row, (unsigned)w->off, (unsigned)w->val,
                g_retw.why[r]);
        nm++;
    }
    if (!nm)
        fprintf(f, "    {0u, 0u, 0u, 0u} /* none */\n");
    fprintf(f, "};\n#define CTRLPKT_PLAN_RET_MMIO_COUNT %uu\n", (unsigned)nm);
    cpd_close_h(f);
    cpd_bin(dir, "plan_ret", g_plan_pkt, g_plan_words);
    cpd_index(dir, "plan_ret", g_plan_words, "ctrl_plan_init return-route prefix (+ ctrlpkt_plan_ret_mmio[])");
}

static void dump_writes(const char *dir, const s_sites *s) {
    const XAie_RegCoreCtrl *cc = g_dev.DevProp.DevMod[XAIEGBL_TILE_TYPE_AIETILE].CoreMod->CoreCtrl;
    for (int i = 0; i < g_nwout; i++) {
        const s_wout *o = &g_wout[i];
        int lock = o->addr >= 0x1F000U && o->addr < 0x1F400U;
        char name[64], title[512];
        snprintf(name, sizeof(name), "write%d_%s", i,
                 o->addr == cc->RegOff ? "core_enable" : lock ? "lock_init" : "reg");
        snprintf(title, sizeof(title), "%s\n%s, stream id 0x%02x.", o->what,
                 o->kind == RT_AOT_WR_BCAST ? "Broadcast write" : "Row-multicast write-with-return", (unsigned)o->sid);
        s_note c = {s, 0, -1};
        cpd_dump(dir, name, title, o->pkt, o->words, NULL, 0, site_note, &c);
    }
}

static void dump_calls(const char *dir, const s_sites *s) {
    static const char *kinds[5] = {"", "BD", "BD_OOO", "CH_OOO", "START"};
    FILE *f = cpd_open_h(dir, "shim_bd_calls",
                         "shim_bd_calls: the shim-BD window's calls in host.cc order, as the runtime matches them\n"
                         "one by one (host_ctrlpkt_sb_calls): kind, tile, channel, BD, direction, repeat and, for BD\n"
                         "calls, the FNV hash of the 19 integer arguments. seg = shim_bd_seg<seg>_col*.h; patch =\n"
                         "word offsets of BD words 1/2/8 in that segment (65535 = none).");
    if (!f)
        return;
    fprintf(f, "typedef struct {\n    const char *kind;\n    uint8_t col, row, ch, bd, dir, seg, repeat;\n"
               "    uint32_t arg_hash;\n    uint16_t patch[3];\n} ctrlpkt_dbg_call;\n\n"
               "static const ctrlpkt_dbg_call ctrlpkt_shim_bd_calls[] = {\n");
    for (int i = 0; i < g_ncalls; i++) {
        const rt_aot_sb_call *c = &g_calls[i];
        fprintf(f, "    {\"%s\", %u, %u, %u, %u, %u, %u, %u, 0x%08xu, {%u, %u, %u}}, /* [call %d] %s */\n",
                kinds[c->kind], c->col, c->row, c->ch, c->bd, c->dir, c->seg, c->repeat, (unsigned)c->arg_hash,
                c->patch[0], c->patch[1], c->patch[2], i, g_call_what[i]);
    }
    fprintf(f, "};\n");
    if (s->batch) {
        fprintf(f, "\n/* Batched window (__Runtime_ctrl_aot_window, %d buffers): every call's arguments, replayed\n"
                   " * through the runtime wrappers when the segments cannot be used (host_ctrlpkt_win_calls).\n"
                   " * {kind, col, row, ch, bd, dir, repeat, buf index, host arg, byte offset, 19 BD int args} */\n"
                   "static const int32_t ctrlpkt_shim_bd_replay[][29] = {\n",
                s->nbufs);
        int buf = 0;
        for (int i = 0; i < s->ncalls; i++) {
            const s_call *c = &s->calls[i];
            int is_bd = c->kind == RT_AOT_CALL_BD || c->kind == RT_AOT_CALL_BD_OOO;
            fprintf(f, "    {%d, %d, %d, %d, %d, %d, %d, %d, %d, %ld, ", c->kind, c->col, c->row, c->ch, c->bd, c->dir,
                    c->repeat, is_bd ? buf : -1, is_bd ? c->argidx : -1, is_bd ? c->off : 0L);
            for (int k = 0; k < 19; k++)
                fprintf(f, "%d%s", is_bd ? c->v[k] : 0, k < 18 ? ", " : "");
            char what[256];
            call_what(c, what, sizeof(what));
            fprintf(f, "}, /* [%d] %s */\n", i, what);
            buf += is_bd;
        }
        fprintf(f, "};\n");
    }
    cpd_close_h(f);
    cpd_index(dir, "shim_bd_calls", 0U, "shim-BD window call match table (+ batched replay arguments)");
}

static void dump_window(const char *dir, const s_sites *s) {
    for (int k = 0; k <= g_hi - g_lo; k++) {
        char name[64], title[640];
        snprintf(name, sizeof(name), "shim_bd_seg%d_col%d", k, g_lo + k);
        snprintf(title, sizeof(title),
                 "%s: shim-BD window segment for shim tile (%d,0), stream id 0x%02x, %u words.\n"
                 "Sent by __Runtime_ctrl_shim_bd_commit (or __Runtime_ctrl_aot_window) as one chained BD with\n"
                 "one TLAST; the last access (word %u) is the write-with-return barrier.\n"
                 "Words 0..%u are the shim-row return route: only the first window after the route is set\n"
                 "up sends them; a later window (relaunch) starts at word %u.",
                 name, g_lo + k, acr_shim_row_id((uint8_t)k), (unsigned)g_len[k], (unsigned)g_last[k] - 1U,
                 g_prefix[k] ? (unsigned)g_prefix[k] - 1U : 0U, (unsigned)g_prefix[k]);
        static cpd_mark m[S_MAX_MARKS];
        s_note c = {s, 1, k};
        cpd_dump(dir, name, title, g_seg[k], g_len[k], m, to_marks(g_marks[k], g_nmarks[k], m), site_note, &c);
    }
    dump_calls(dir, s);
}

static uint32_t *read_words(const char *path, uint32_t *n) {
    FILE *f = fopen(path, "rb");
    if (!f)
        return NULL;
    fseek(f, 0, SEEK_END);
    long len = ftell(f);
    fseek(f, 0, SEEK_SET);
    uint32_t *w = len > 0 ? (uint32_t *)malloc((size_t)len) : NULL;
    *n = w && fread(w, 1, (size_t)len, f) == (size_t)len ? (uint32_t)(len / 4) : 0U;
    fclose(f);
    return w;
}

typedef struct {
    s_note plan;
    uint32_t plan_acc;
    const cpd_ann *body;
} s_wire_note;

static void wire_note(void *ctx, uint32_t acc, uint32_t at, const uint32_t *w, uint32_t len, char *buf, size_t n) {
    const s_wire_note *c = (const s_wire_note *)ctx;
    if (acc < c->plan_acc)
        site_note((void *)&c->plan, acc, at, w, len, buf, n);
    else
        snprintf(buf, n, "%s", acc - c->plan_acc < c->body->nnotes ? c->body->notes[acc - c->plan_acc] : "");
}

static uint32_t count_accesses(const uint32_t *w, uint32_t n) {
    uint32_t acc = 0U;
    for (uint32_t i = 0U; i + 2U <= n; acc++) {
        uint32_t op = (w[i + 1U] >> 22U) & 0x3U;
        i += 2U + (op == 1U ? 0U : ((w[i + 1U] >> 20U) & 0x3U) + 1U);
    }
    return acc;
}

static void dump_one_wire(const char *dir, const s_sites *s, const char *base) {
    char path[1024], name[300], title[1024], body_mark[320];
    snprintf(path, sizeof(path), "%.600s/raw/%.200s.bin", dir, base);
    uint32_t nb = 0U, *body = read_words(path, &nb);
    uint32_t *w = body ? (uint32_t *)malloc((size_t)(g_plan_words + nb) * sizeof(uint32_t)) : NULL;
    cpd_ann ann;
    if (!w || cpd_ann_load(dir, base, g_plan_words, &ann) != 0) {
        free(w);
        free(body);
        return;
    }
    memcpy(w, g_plan_pkt, g_plan_words * sizeof(uint32_t));
    memcpy(w + g_plan_words, body, nb * sizeof(uint32_t));
    snprintf(name, sizeof(name), "%.200s_wire", base);
    snprintf(title, sizeof(title),
             "%.250s: the kernel-ELF load exactly as sent, in one shim MM2S BD with one TLAST.\n"
             "Words 0..%u: plan_ret (return-route prefix); words %u..: %.200s.h word = this word - %u.\n"
             "Applies when ctrl_plan_init matched its table entry (plan_aot=1 in [CTRLPKT_AOT]).",
             name, g_plan_words ? (unsigned)g_plan_words - 1U : 0U, (unsigned)g_plan_words, base,
             (unsigned)g_plan_words);
    snprintf(body_mark, sizeof(body_mark), "Kernel body (%.200s.h) starts here", base);
    cpd_mark *m = (cpd_mark *)malloc((size_t)(g_plan_n + 1U + (uint32_t)ann.nmarks) * sizeof(cpd_mark));
    if (m) {
        int nm = to_marks(g_plan_marks, (int)g_plan_n, m);
        m[nm].at = g_plan_words;
        m[nm++].text = body_mark;
        for (int i = 0; i < ann.nmarks; i++)
            m[nm++] = ann.marks[i];
        s_wire_note c = {{s, 0, -1}, count_accesses(g_plan_pkt, g_plan_words), &ann};
        cpd_dump(dir, name, title, w, g_plan_words + nb, m, nm, wire_note, &c);
    }
    free(m);
    cpd_ann_free(&ann);
    free(w);
    free(body);
}

static void dump_kernel_wire(const char *dir, const s_sites *s) {
    char raw[1024];
    snprintf(raw, sizeof(raw), "%s/raw", dir);
    DIR *d = opendir(raw);
    if (!d)
        return;
    char bases[16][256];
    int nb = 0;
    struct dirent *e;
    while ((e = readdir(d)) != NULL && nb < 16) {
        size_t l = strlen(e->d_name);
        if (strncmp(e->d_name, "kernel_", 7) == 0 && l > 4 && strcmp(e->d_name + l - 4, ".bin") == 0 &&
            !strstr(e->d_name, "_wire.bin"))
            snprintf(bases[nb++], sizeof(bases[0]), "%.*s", (int)(l - 4), e->d_name);
    }
    closedir(d);
    for (int i = 0; i < nb; i++)
        dump_one_wire(dir, s, bases[i]);
}

static void dump_sites(const char *dir, const s_sites *s) {
    if (g_plan_emit) {
        dump_plan(dir, s);
        dump_kernel_wire(dir, s);
    } else if (s->has_plan) {
        cpd_index(dir, "-", 0U, "ctrl_plan_init: not precomputed (a row cannot be captured), runs JIT");
    }
    dump_writes(dir, s);
    if (g_window_ok)
        dump_window(dir, s);
    else if (s->has_window)
        cpd_index(dir, "-", 0U, "shim-BD window: not precomputed, runs JIT (see the aiehlc_ctrlpkt build log)");
}

int ctrlpkt_emit_sites(const char *sites_path, const char *host_cc, const char *out_hdr, const char *debug_dir) {
    static s_sites s;
    if (parse_sites(sites_path, &s) != 0) {
        fprintf(stderr, "aiehlc_ctrlpkt: cannot read %s\n", sites_path);
        return 1;
    }
    assign_lines(&s, host_cc);
    if (dev_init(s.start_col, s.ncols) != 0) {
        fprintf(stderr, "aiehlc_ctrlpkt: XAie device init failed (gen %d, cols %d+%d)\n", s.gen, s.start_col, s.ncols);
        return 1;
    }
    if (s.has_plan && plan_rows(&s) != 0) {
        fprintf(stderr, "aiehlc_ctrlpkt: planner failed; plan and shim-BD sites stay JIT\n");
        s.has_plan = 0;
        s.has_window = 0;
    }
    if (s.has_plan)
        build_plan_ret();
    build_writes(&s);
    if (s.has_plan && build_window(&s) != 0)
        g_window_ok = 0;
    FILE *f = fopen(out_hdr, "w");
    if (!f)
        return 1;
    fprintf(f, "/* Auto-generated by aiehlc_ctrlpkt from ctrlpkt_sites.txt -- do not edit.\n"
               " *\n"
               " * AOT control packets for every control-packet site of host.cc except the kernel ELF\n"
               " * (#pragma control_packet_mode(aot)). Each site names the runtime API call it replaces\n"
               " * and its host.cc line; each array line is one control access: stream header, control\n"
               " * header ([19:0] tile address, [21:20] words-1, [23:22] op), data words. host.cc passes\n"
               " * host_ctrlpkt_table to __Runtime_ctrl_aot_register(); every call checks it matches its\n"
               " * entry and falls back to the runtime (JIT) encode otherwise.\n"
               " */\n#ifndef HOST_CTRLPKT_H\n#define HOST_CTRLPKT_H\n\n#include <stdint.h>\n#include \"aie_ctrlpkt_aot.h\"\n\n");
    write_plan_and_writes(f, &s);
    if (g_window_ok)
        write_window(f);
    if (s.batch)
        write_batch_window(f, &s);
    write_table(f, &s);
    fprintf(f, "\n#endif\n");
    fclose(f);
    if (debug_dir)
        dump_sites(debug_dir, &s);
    fprintf(stderr, "aiehlc_ctrlpkt: %s plan_ret=%u writes=%d shim_bd_calls=%d\n", out_hdr, (unsigned)g_plan_n,
            g_nwout, g_window_ok ? g_ncalls : 0);
    return 0;
}
