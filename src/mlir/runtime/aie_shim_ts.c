/* aie_shim_ts.c -- gemm90 m33621242222122 PA (see aie_shim_ts.h for the knobs).
 *
 * Not a separate translation unit: aie_runtime.c includes this file (after its own includes, so the static
 * helpers there are visible) ONLY under `#if defined(AIEHLC_SHIM_TS) || defined(AIEHLC_B_SHIM_DELAY_NS)` (PAE: or
 * AIEHLC_A_SHIM_DELAY_NS / AIEHLC_LOCKSAMPLE); with all knobs undefined nothing of it reaches the compiler and the runtime object is byte-identical to the base.
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
#ifndef AIEHLC_SHIM_TS_FROM
#define AIEHLC_SHIM_TS_FROM 1 /* PCP: first launch recorded (UART dump size); records of earlier launches are skipped */
#endif
#ifndef AIEHLC_B_SHIM_CH
#define AIEHLC_B_SHIM_CH 0
#endif
#ifndef AIEHLC_B_SHIM_DELAY_LAUNCHES
#define AIEHLC_B_SHIM_DELAY_LAUNCHES 101
#endif
#ifndef AIEHLC_A_SHIM_CH
#define AIEHLC_A_SHIM_CH 1
#endif
/* PAE: one delay table, one swept channel (B: PA/PCP, A: PAE) */
#if defined(AIEHLC_A_SHIM_DELAY_NS) && defined(AIEHLC_B_SHIM_DELAY_NS)
#error "AIEHLC_A_SHIM_DELAY_NS and AIEHLC_B_SHIM_DELAY_NS are exclusive (one swept shim channel per ELF)"
#endif
#if defined(AIEHLC_A_SHIM_DELAY_NS)
#define RT_STS_DELAY_LIST AIEHLC_A_SHIM_DELAY_NS
#define RT_STS_DELAY_CH AIEHLC_A_SHIM_CH
#elif defined(AIEHLC_B_SHIM_DELAY_NS)
#define RT_STS_DELAY_LIST AIEHLC_B_SHIM_DELAY_NS
#define RT_STS_DELAY_CH AIEHLC_B_SHIM_CH
#endif
#define RT_STS_COLS 64
#define RT_STS_TBL_MAX 32

static XAie_DevInst *s_sts_dev = NULL;
static uint32_t s_sts_launch = 0U;      /* 1-based index of the launch in progress (0: before the first) */
static uint8_t s_sts_col_used[RT_STS_COLS];
static uint32_t s_sts_b_push_cur = 0U;  /* B pushes in the launch in progress */
static uint32_t s_sts_b_push_last = 0U; /* ... in the last complete launch */
static uint32_t s_sts_a_push_cur = 0U;  /* PAE: A pushes in the launch in progress */
static uint32_t s_sts_a_push_last = 0U; /* ... in the last complete launch */
static int s_sts_snap_done = 0;

/* ---------------------------------------------------------------------------------------------- delay table */
#ifdef RT_STS_DELAY_LIST
static const uint32_t s_sts_tbl_builtin[] = {RT_STS_DELAY_LIST};
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
uint32_t __Runtime_a_shim_pushes_last_launch(void) { return s_sts_a_push_last; }
#ifdef AIEHLC_A_SHIM_DELAY_NS
uint32_t __Runtime_a_shim_delay_ns(void) { return __Runtime_b_shim_delay_ns(); }
#else
uint32_t __Runtime_a_shim_delay_ns(void) { return 0U; }
#endif

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
    if (s_sts_launch < (uint32_t)AIEHLC_SHIM_TS_FROM)
        return;
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
    if (dir == DMA_MM2S && ch == (uint8_t)AIEHLC_B_SHIM_CH)
        s_sts_b_push_cur++;
    if (dir == DMA_MM2S && ch == (uint8_t)AIEHLC_A_SHIM_CH)
        s_sts_a_push_cur++;
#ifdef RT_STS_DELAY_LIST
    if (dir == DMA_MM2S && ch == (uint8_t)RT_STS_DELAY_CH)
        rt_sts_delay(dev, t, __Runtime_b_shim_delay_ns());
#endif
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
    printf("SHIMTS_CFG mhz=%llu src=shim_pl_timer b_ch=mm2s%u launches=%u recs=%u dropped=%u b_pushes_per_launch=%u "
           "a_ch=mm2s%u a_pushes_per_launch=%u delay_knob=%s\n",
           (unsigned long long)AIEHLC_SHIM_TS_AIE_MHZ, (unsigned)AIEHLC_B_SHIM_CH, (unsigned)s_sts_launch,
           (unsigned)s_sts_n, (unsigned)s_sts_drop, (unsigned)s_sts_b_push_last, (unsigned)AIEHLC_A_SHIM_CH,
           (unsigned)s_sts_a_push_last,
#if defined(AIEHLC_A_SHIM_DELAY_NS)
           "AIEHLC_A_SHIM_DELAY_NS"
#elif defined(AIEHLC_B_SHIM_DELAY_NS)
           "AIEHLC_B_SHIM_DELAY_NS"
#else
           "none"
#endif
    );
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

/* ---------------------------------------------------------------------------------------------- one-ELF sweep */
/* AIEHLC_SWEEP_RERUN=<points> (PAE, default off): the app's own main runs one point (GP_LAUNCHES launches, its call
 * lines, STEADY and GOLDEN); an atexit handler registered at the first launch runs main again points-1 times, so ONE
 * ELF covers every table point (point p = launches p*lpp+1 .. (p+1)*lpp) with the host sources (and hence the
 * generated host.cc) untouched. The runtime prints `=== SWEEP point d_ns=<d> <a|b>_pushes_per_launch=<n>` after the
 * first launch of each point (before that point's GPLAN) and `SWEEPPT ...` after its last launch. */
#if defined(AIEHLC_SWEEP_RERUN) && AIEHLC_SWEEP_RERUN > 1
#ifndef RT_STS_DELAY_LIST
#error "AIEHLC_SWEEP_RERUN needs a delay table (AIEHLC_A_SHIM_DELAY_NS or AIEHLC_B_SHIM_DELAY_NS)"
#endif
#define RT_STS_SWEEP 1
#include <stdlib.h>
#ifdef __cplusplus
extern "C"
#endif
    int
    rt_sts_app_main(void) __asm__("main");
#if defined(AIEHLC_A_SHIM_DELAY_NS)
#define RT_STS_SWEEP_TAG "a"
#define RT_STS_SWEEP_PUSH s_sts_a_push_cur
#else
#define RT_STS_SWEEP_TAG "b"
#define RT_STS_SWEEP_PUSH s_sts_b_push_cur
#endif
static int s_sw_reg = 0;
static uint32_t s_sw_min = 0U, s_sw_max = 0U, s_sw_l1 = 0U;
static void rt_sts_rerun(void) {
    for (int p = 1; p < (int)(AIEHLC_SWEEP_RERUN); p++) {
        fflush(stdout);
        (void)rt_sts_app_main();
    }
    fflush(stdout);
}
static void rt_sts_sweep_end(void) {
    const uint32_t lpp = (uint32_t)(s_sts_lpp > 0 ? s_sts_lpp : 1);
    const uint32_t l = s_sts_launch ? s_sts_launch - 1U : 0U, idx = l % lpp, pt = l / lpp;
    const uint32_t pu = RT_STS_SWEEP_PUSH;
    if (idx == 0U) {
        printf("=== SWEEP point d_ns=%u " RT_STS_SWEEP_TAG "_pushes_per_launch=%u\n", (unsigned)__Runtime_b_shim_delay_ns(),
               (unsigned)pu);
        s_sw_l1 = pu;
        s_sw_min = ~0U;
        s_sw_max = 0U;
    } else {
        s_sw_min = pu < s_sw_min ? pu : s_sw_min;
        s_sw_max = pu > s_sw_max ? pu : s_sw_max;
    }
    if (idx == lpp - 1U)
        printf("SWEEPPT point=%u d_ns=%u " RT_STS_SWEEP_TAG "_pushes_min=%u " RT_STS_SWEEP_TAG
               "_pushes_max=%u launch1_pushes=%u src=runtime_rerun\n",
               (unsigned)pt, (unsigned)__Runtime_b_shim_delay_ns(), (unsigned)s_sw_min, (unsigned)s_sw_max,
               (unsigned)s_sw_l1);
}
#endif

/* ---------------------------------------------------------------------------------------------- lock-stall sampler */
#ifdef AIEHLC_LOCKSAMPLE
#ifndef AIEHLC_LOCKSAMPLE_FROM
#define AIEHLC_LOCKSAMPLE_FROM 2
#endif
#ifndef AIEHLC_LOCKSAMPLE_TO
#define AIEHLC_LOCKSAMPLE_TO 101
#endif
#ifndef AIEHLC_LOCKSAMPLE_COL0
#define AIEHLC_LOCKSAMPLE_COL0 1
#endif
#ifndef AIEHLC_LOCKSAMPLE_NCOL
#define AIEHLC_LOCKSAMPLE_NCOL 4
#endif
#ifndef AIEHLC_LOCKSAMPLE_ROW0
#define AIEHLC_LOCKSAMPLE_ROW0 3
#endif
#ifndef AIEHLC_LOCKSAMPLE_NROW
#define AIEHLC_LOCKSAMPLE_NROW 4
#endif
#define RT_LKS_NT (AIEHLC_LOCKSAMPLE_NCOL * AIEHLC_LOCKSAMPLE_NROW)
#define RT_LKS_BINS 8192U /* PC >> 1, PM < 16 KiB */
#define RT_LKS_STALL_MASK 0x3C0U /* Core_Status Lock_Stall_S/W/N/E (bits 6..9) */
static uint32_t s_lks_hist[RT_LKS_NT][RT_LKS_BINS];
static uint32_t s_lks_n[RT_LKS_NT], s_lks_st[RT_LKS_NT], s_lks_dir[RT_LKS_NT][4], s_lks_oob[RT_LKS_NT];
static uint32_t s_lks_rr = 0U;
static int s_lks_done = 0;
static void rt_lks_poll(XAie_DevInst *dev) {
    if (!dev)
        return;
    /* the reads are done in EVERY launch (same poll cost at every sweep point); only FROM..TO is accumulated */
    const uint32_t i = s_lks_rr++ % (uint32_t)RT_LKS_NT;
    const XAie_LocType t = XAie_TileLoc((uint8_t)(AIEHLC_LOCKSAMPLE_COL0 + i / AIEHLC_LOCKSAMPLE_NROW),
                                        (uint8_t)(AIEHLC_LOCKSAMPLE_ROW0 + i % AIEHLC_LOCKSAMPLE_NROW));
    u32 s0 = 0U, pc = 0U, s1 = 0U;
    if (XAie_CoreGetStatus(dev, t, &s0) != XAIE_OK || XAie_CoreGetPCValue(dev, t, &pc) != XAIE_OK ||
        XAie_CoreGetStatus(dev, t, &s1) != XAIE_OK)
        return;
    if (s_sts_launch < (uint32_t)AIEHLC_LOCKSAMPLE_FROM || s_sts_launch > (uint32_t)AIEHLC_LOCKSAMPLE_TO)
        return;
    s_lks_n[i]++;
    if (!(s0 & RT_LKS_STALL_MASK) || !(s1 & RT_LKS_STALL_MASK))
        return;
    s_lks_st[i]++;
    for (int d = 0; d < 4; d++)
        if (s0 & s1 & (1U << (6 + d)))
            s_lks_dir[i][d]++;
    if ((pc >> 1) < RT_LKS_BINS)
        s_lks_hist[i][pc >> 1]++;
    else
        s_lks_oob[i]++;
}
static void rt_lks_dump(void) {
    printf("LKSAMP_CFG from=%u to=%u tiles=%u reads=status,pc,status stall_mask=0x%03x bin=pc\n",
           (unsigned)AIEHLC_LOCKSAMPLE_FROM, (unsigned)AIEHLC_LOCKSAMPLE_TO, (unsigned)RT_LKS_NT,
           (unsigned)RT_LKS_STALL_MASK);
    unsigned nl = 0;
    for (uint32_t i = 0; i < (uint32_t)RT_LKS_NT; i++) {
        const unsigned c = (unsigned)(AIEHLC_LOCKSAMPLE_COL0 + i / AIEHLC_LOCKSAMPLE_NROW),
                       r = (unsigned)(AIEHLC_LOCKSAMPLE_ROW0 + i % AIEHLC_LOCKSAMPLE_NROW);
        printf("LKSAMP tile=(%u,%u) samples=%u stall=%u dirS=%u dirW=%u dirN=%u dirE=%u oob=%u\n", c, r,
               (unsigned)s_lks_n[i], (unsigned)s_lks_st[i], (unsigned)s_lks_dir[i][0], (unsigned)s_lks_dir[i][1],
               (unsigned)s_lks_dir[i][2], (unsigned)s_lks_dir[i][3], (unsigned)s_lks_oob[i]);
        for (uint32_t b = 0; b < RT_LKS_BINS; b++)
            if (s_lks_hist[i][b]) {
                printf("LKPC tile=(%u,%u) pc=0x%04x n=%u\n", c, r, (unsigned)(b << 1), (unsigned)s_lks_hist[i][b]);
                nl++;
            }
    }
    printf("LKSAMP_DONE lines=%u\n", nl);
}
#endif

static void rt_sts_launch_begin(void) {
    s_sts_launch++;
#ifdef RT_STS_SWEEP
    if (!s_sw_reg) {
        s_sw_reg = 1;
        (void)atexit(rt_sts_rerun);
    }
#endif
    s_sts_b_push_cur = 0U;
    s_sts_a_push_cur = 0U;
}

static void rt_sts_launch_end(void) {
    s_sts_b_push_last = s_sts_b_push_cur;
    s_sts_a_push_last = s_sts_a_push_cur;
#ifdef RT_STS_SWEEP
    rt_sts_sweep_end();
#endif
#ifdef AIEHLC_LOCKSAMPLE
    if (!s_lks_done && s_sts_launch == (uint32_t)AIEHLC_LOCKSAMPLE_TO) {
        s_lks_done = 1;
        rt_lks_dump();
    }
#endif
    if (!s_sts_snap_done && s_sts_launch == (uint32_t)AIEHLC_LOCKSNAP_LAUNCH) {
        s_sts_snap_done = 1;
#ifdef AIEHLC_SHIM_TS
        __Runtime_shim_ts_dump();
        (void)__Runtime_lock_snapshot(s_sts_dev);
#endif
    }
}

#endif /* AIEHLC_SHIM_TS_ANY */
