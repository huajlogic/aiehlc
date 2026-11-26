/* aie_shim_ts.c -- gemm90 m33621242222122 PA (see aie_shim_ts.h for the knobs).
 *
 * Not a separate translation unit: aie_runtime.c includes this file (after its own includes, so the static
 * helpers there are visible) ONLY under `#if defined(AIEHLC_SHIM_TS) || defined(AIEHLC_B_SHIM_DELAY_NS)`; with
 * both knobs undefined nothing of it reaches the compiler and the runtime object is byte-identical to the base.
 *
 * Hooks called from aie_runtime.c (all no-ops unless the matching knob is defined):
 *   rt_sts_push(dev, tile, ch, dir, bd)  just before a start-queue push (__Runtime_startio, startio_prequeue):
 *                                        B delay (shim MM2S AIEHLC_B_SHIM_CH) + push timestamp
 *   rt_sts_done(dev, tile, ch, dir)      when rt_wait_io_upto sees the channel's pending BD count drop (shim only)
 *   rt_sts_launch_begin()                __Runtime_shim_bd_rebase_count_reset (gemm_plan: start of each launch)
 *   rt_sts_launch_end()                  __Runtime_shim_bd_rebase_count       (gemm_plan: after each launch, outside
 *                                        the XTime window); after launch AIEHLC_LOCKSNAP_LAUNCH it prints SHIMTS +
 *                                        LOCKSNAP (read-only).
 * Timestamps are the shim tile's PL-module timer (XAie_ReadTimer, AIE clock). Per-column timers are NOT re-synced
 * here (the record carries the column), so cross-column deltas need the PCP's own alignment.
 */
#include "aie_shim_ts.h"

#ifdef AIEHLC_SHIM_TS_ANY

#ifndef AIEHLC_SHIM_TS_AIE_MHZ
#define AIEHLC_SHIM_TS_AIE_MHZ 1000ULL
#endif
#ifndef AIEHLC_SHIM_TS_MAX
#define AIEHLC_SHIM_TS_MAX 16384
#endif
#ifndef AIEHLC_LOCKSNAP_LAUNCH
#define AIEHLC_LOCKSNAP_LAUNCH 101
#endif
#ifndef AIEHLC_B_SHIM_CH
#define AIEHLC_B_SHIM_CH 0
#endif
#ifndef AIEHLC_B_SHIM_DELAY_LAUNCHES
#define AIEHLC_B_SHIM_DELAY_LAUNCHES 101
#endif
#define RT_STS_COLS 64
#define RT_STS_TBL_MAX 32

static XAie_DevInst *s_sts_dev = NULL;
static uint32_t s_sts_launch = 0U;      /* 1-based index of the launch in progress (0: before the first) */
static uint8_t s_sts_col_used[RT_STS_COLS];
static uint32_t s_sts_b_push_cur = 0U;  /* B pushes in the launch in progress */
static uint32_t s_sts_b_push_last = 0U; /* ... in the last complete launch */
static int s_sts_snap_done = 0;

/* ---------------------------------------------------------------------------------------------- B delay table */
#ifdef AIEHLC_B_SHIM_DELAY_NS
static const uint32_t s_sts_tbl_builtin[] = {AIEHLC_B_SHIM_DELAY_NS};
static uint32_t s_sts_tbl[RT_STS_TBL_MAX];
static int s_sts_tbl_n = -1; /* -1: not yet copied from the built-in list */
static int s_sts_lpp = AIEHLC_B_SHIM_DELAY_LAUNCHES;
static int s_sts_pin = -1;
static void rt_sts_tbl_init(void) {
    if (s_sts_tbl_n >= 0)
        return;
    int n = (int)(sizeof(s_sts_tbl_builtin) / sizeof(s_sts_tbl_builtin[0]));
    if (n > RT_STS_TBL_MAX)
        n = RT_STS_TBL_MAX;
    for (int i = 0; i < n; i++)
        s_sts_tbl[i] = s_sts_tbl_builtin[i];
    s_sts_tbl_n = n;
}
static int rt_sts_point(void) {
    rt_sts_tbl_init();
    if (s_sts_tbl_n <= 0)
        return -1;
    if (s_sts_pin >= 0)
        return s_sts_pin < s_sts_tbl_n ? s_sts_pin : s_sts_tbl_n - 1;
    const uint32_t l = s_sts_launch ? s_sts_launch - 1U : 0U;
    int p = (int)(l / (uint32_t)(s_sts_lpp > 0 ? s_sts_lpp : 1));
    return p < s_sts_tbl_n ? p : s_sts_tbl_n - 1;
}
void __Runtime_b_shim_delay_table(const uint32_t *ns, int n, int launches_per_point) {
    rt_sts_tbl_init();
    if (ns && n > 0) {
        if (n > RT_STS_TBL_MAX)
            n = RT_STS_TBL_MAX;
        for (int i = 0; i < n; i++)
            s_sts_tbl[i] = ns[i];
        s_sts_tbl_n = n;
    }
    if (launches_per_point > 0)
        s_sts_lpp = launches_per_point;
}
uint32_t __Runtime_b_shim_delay_select(int i) {
    rt_sts_tbl_init();
    s_sts_pin = i;
    const int p = rt_sts_point();
    return p >= 0 ? s_sts_tbl[p] : 0U;
}
uint32_t __Runtime_b_shim_delay_ns(void) {
    const int p = rt_sts_point();
    return p >= 0 ? s_sts_tbl[p] : 0U;
}
/* busy-wait d ns on the AIE timer of the shim tile that is about to be pushed */
static void rt_sts_delay(XAie_DevInst *dev, XAie_LocType shim, uint32_t d_ns) {
    if (!d_ns)
        return;
    const uint64_t cyc = ((uint64_t)d_ns * AIEHLC_SHIM_TS_AIE_MHZ + 999ULL) / 1000ULL;
    u64 t0 = 0, t = 0;
    if (XAie_ReadTimer(dev, shim, XAIE_PL_MOD, &t0) != XAIE_OK)
        return;
    do {
        if (XAie_ReadTimer(dev, shim, XAIE_PL_MOD, &t) != XAIE_OK)
            return;
    } while ((uint64_t)(t - t0) < cyc);
}
#else
uint32_t __Runtime_b_shim_delay_ns(void) { return 0U; }
#endif
uint32_t __Runtime_b_shim_pushes_last_launch(void) { return s_sts_b_push_last; }

/* ---------------------------------------------------------------------------------------------- timestamps */
#ifdef AIEHLC_SHIM_TS
typedef struct {
    uint32_t launch;
    uint8_t col, ch, dir, ev; /* ev 0 push, 1 done */
    uint8_t bd;
    uint32_t d_ns;
    uint64_t ts;
} rt_sts_rec;
static rt_sts_rec s_sts_rec[AIEHLC_SHIM_TS_MAX];
static uint32_t s_sts_n = 0U, s_sts_drop = 0U;
static void rt_sts_log(XAie_DevInst *dev, XAie_LocType t, uint8_t ch, XAie_DmaDirection dir, uint8_t ev, uint8_t bd) {
    u64 ts = 0;
    if (XAie_ReadTimer(dev, XAie_TileLoc(t.Col, 0U), XAIE_PL_MOD, &ts) != XAIE_OK)
        ts = ~0ULL;
    if (s_sts_n >= AIEHLC_SHIM_TS_MAX) {
        s_sts_drop++;
        return;
    }
    rt_sts_rec *r = &s_sts_rec[s_sts_n++];
    r->launch = s_sts_launch;
    r->col = (uint8_t)t.Col;
    r->ch = ch;
    r->dir = (uint8_t)dir;
    r->ev = ev;
    r->bd = bd;
    r->d_ns = __Runtime_b_shim_delay_ns();
    r->ts = (uint64_t)ts;
}
#endif

static int rt_sts_is_shim(XAie_DevInst *dev, XAie_LocType t) {
    const uint8_t tt = XAie_GetTileTypefromLoc(dev, t);
    return tt == XAIEGBL_TILE_TYPE_SHIMNOC || tt == XAIEGBL_TILE_TYPE_SHIMPL;
}

static void rt_sts_push(XAie_DevInst *dev, XAie_LocType t, uint8_t ch, XAie_DmaDirection dir, uint8_t bd) {
    if (!dev || !rt_sts_is_shim(dev, t))
        return;
    s_sts_dev = dev;
    if (t.Col < RT_STS_COLS)
        s_sts_col_used[t.Col] = 1U;
    if (dir == DMA_MM2S && ch == (uint8_t)AIEHLC_B_SHIM_CH) {
        s_sts_b_push_cur++;
#ifdef AIEHLC_B_SHIM_DELAY_NS
        rt_sts_delay(dev, t, __Runtime_b_shim_delay_ns());
#endif
    }
#ifdef AIEHLC_SHIM_TS
    rt_sts_log(dev, t, ch, dir, 0U, bd);
#else
    (void)bd;
#endif
}

static void rt_sts_done(XAie_DevInst *dev, XAie_LocType t, uint8_t ch, XAie_DmaDirection dir) {
#ifdef AIEHLC_SHIM_TS
    if (dev && rt_sts_is_shim(dev, t))
        rt_sts_log(dev, t, ch, dir, 1U, 0xFFU);
#else
    (void)dev;
    (void)t;
    (void)ch;
    (void)dir;
#endif
}

void __Runtime_shim_ts_dump(void) {
#ifdef AIEHLC_SHIM_TS
    printf("SHIMTS_CFG mhz=%llu src=shim_pl_timer b_ch=mm2s%u launches=%u recs=%u dropped=%u b_pushes_per_launch=%u\n",
           (unsigned long long)AIEHLC_SHIM_TS_AIE_MHZ, (unsigned)AIEHLC_B_SHIM_CH, (unsigned)s_sts_launch,
           (unsigned)s_sts_n, (unsigned)s_sts_drop, (unsigned)s_sts_b_push_last);
    for (uint32_t i = 0; i < s_sts_n; i++) {
        const rt_sts_rec *r = &s_sts_rec[i];
        printf("SHIMTS launch=%u col=%u %s%u ev=%s bd=%d d_ns=%u ts=%llu\n", (unsigned)r->launch, (unsigned)r->col,
               r->dir == (uint8_t)DMA_MM2S ? "mm2s" : "s2mm", (unsigned)r->ch, r->ev ? "done" : "push",
               r->bd == 0xFFU ? -1 : (int)r->bd, (unsigned)r->d_ns, (unsigned long long)r->ts);
    }
    printf("SHIMTS_DONE n=%u\n", (unsigned)s_sts_n);
#endif
}

/* ---------------------------------------------------------------------------------------------- lock snapshot */
/* READ-ONLY: XAie_LockGetValue + AieRt_DmaGetChannelStatusFull only (the megak STALL_DUMP reader's register set,
 * 9e366d31 rt_stall_dump, without its wait_io timeout path). Lines: one per non-zero lock and one per DMA channel
 * that is running / has a queue / is stalled, then LOCKSNAP_DONE n=<lock lines>. */
int __Runtime_lock_snapshot(XAie_DevInst *dev) {
    int n = 0;
    if (!dev)
        dev = s_sts_dev;
    if (!dev) {
        printf("LOCKSNAP_DONE n=0 err=no_dev\n");
        return 0;
    }
    printf("LOCKSNAP_CFG launch=%u readonly=1 curbd_bit=%u src=stall_dump\n", (unsigned)s_sts_launch,
           (unsigned)(AIE_GEN == 5 ? 25U : 24U));
    for (uint8_t col = 0U; col < RT_STS_COLS; col++) {
        if (!s_sts_col_used[col])
            continue;
        for (int k = 0; k < 2; k++) { /* 0 MemTile, 1 core */
            const uint8_t r0 = k == 0 ? dev->MemTileRowStart : dev->AieTileRowStart;
            const uint8_t nr = k == 0 ? dev->MemTileNumRows : dev->AieTileNumRows;
            const uint8_t nl = k == 0 ? 64U : 16U;
            const uint8_t nch = k == 0 ? 6U : 2U;
            for (uint8_t r = r0; r < (uint8_t)(r0 + nr); r++) {
                const XAie_LocType t = XAie_TileLoc(col, r);
                for (uint8_t l = 0U; l < nl; l++) {
                    u32 v = 0U;
                    if (XAie_LockGetValue(dev, t, XAie_LockInit(l, 0), &v) != XAIE_OK || v == 0U)
                        continue;
                    printf("LOCKSNAP tile=(%u,%u) lock=%u value=%u kind=%s\n", (unsigned)col, (unsigned)r, (unsigned)l,
                           (unsigned)v, k == 0 ? "mt" : "core");
                    n++;
                }
                for (int dd = 0; dd < 2; dd++)
                    for (uint8_t c = 0U; c < nch; c++) {
                        const XAie_DmaDirection dir = dd ? DMA_MM2S : DMA_S2MM;
                        uint32_t raw = 0U;
                        if (AieRt_DmaGetChannelStatusFull(dev, t, c, dir, &raw) != XAIE_OK)
                            continue;
                        const AieRt_DmaChStatusDecoded d = AieRt_DecodeDmaChStatus(raw);
                        if (!d.channel_running && !d.task_q_size && !d.stall_lock_acq && !d.stall_lock_rel &&
                            !d.stall_stream)
                            continue;
                        /* Cur_BD: bits 28:25 (gen 5, human 11-24); MemTile 6-bit field at the same LSB */
                        const unsigned cur = k == 0 ? (unsigned)((raw >> (AIE_GEN == 5 ? 25 : 24)) & 0x3FU)
                                                    : (unsigned)__Runtime_dma_cur_bd(raw);
                        printf("LOCKSNAP_DMA tile=(%u,%u) %s%u raw=0x%08x run=%u q=%u cur_bd=%u acq=%u rel=%u strm=%u\n",
                               (unsigned)col, (unsigned)r, dd ? "mm2s" : "s2mm", (unsigned)c, (unsigned)raw,
                               (unsigned)d.channel_running, (unsigned)d.task_q_size, cur, (unsigned)d.stall_lock_acq,
                               (unsigned)d.stall_lock_rel, (unsigned)d.stall_stream);
                    }
            }
        }
    }
    printf("LOCKSNAP_DONE n=%d\n", n);
    return n;
}

static void rt_sts_launch_begin(void) {
    s_sts_launch++;
    s_sts_b_push_cur = 0U;
}

static void rt_sts_launch_end(void) {
    s_sts_b_push_last = s_sts_b_push_cur;
    if (!s_sts_snap_done && s_sts_launch == (uint32_t)AIEHLC_LOCKSNAP_LAUNCH) {
        s_sts_snap_done = 1;
#ifdef AIEHLC_SHIM_TS
        __Runtime_shim_ts_dump();
        (void)__Runtime_lock_snapshot(s_sts_dev);
#endif
    }
}

#endif /* AIEHLC_SHIM_TS_ANY */
