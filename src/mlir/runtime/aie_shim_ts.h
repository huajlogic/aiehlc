/* aie_shim_ts.h -- gemm90 m33621242222122 PA: shim DMA timestamps, read-only lock snapshot, B-shim supply delay.
 *
 * Everything here is DEFAULT OFF. aie_runtime.c includes aie_shim_ts.c only when one of the two knobs is defined,
 * so with neither defined the preprocessed aie_runtime.c (and hence its object, the host archive and the
 * aiehlc-generated host.cc, which this file never touches) is byte-identical to the base.
 *
 * Knobs (app / EXTRA_DEFS -D):
 *   AIEHLC_SHIM_TS                 record an AIE-timer timestamp (shim tile PL-module timer, AIE clock) for every
 *                                  shim start-queue push and every shim channel completion seen by wait_io, per
 *                                  launch; after launch AIEHLC_LOCKSNAP_LAUNCH (default 101) print the records as
 *                                  `SHIMTS ...` lines plus a read-only core/MemTile lock + DMA snapshot
 *                                  (`LOCKSNAP ...`, `LOCKSNAP_DONE n=`).
 *   AIEHLC_B_SHIM_DELAY_NS=<d0[,d1,...]>
 *                                  before each start-queue push of the B shim channel (shim MM2S channel
 *                                  AIEHLC_B_SHIM_CH, default 0 = the pre-queued dataflow_slices input of
 *                                  gemm_plan_4096c) busy-wait d ns on the AIE timer of that shim tile. The list is
 *                                  the built-in table: point p = (launch-1) / AIEHLC_B_SHIM_DELAY_LAUNCHES (default
 *                                  101) so ONE ELF sweeps all d values; the host may replace the table at run time
 *                                  (__Runtime_b_shim_delay_table) or pin a point (__Runtime_b_shim_delay_select).
 *   AIEHLC_A_SHIM_DELAY_NS=<d0[,d1,...]>   (gemm90 m33621242222122 PAE)
 *                                  same table / point rule as AIEHLC_B_SHIM_DELAY_NS, but the busy-wait is before each
 *                                  start-queue push of the A shim channel (shim MM2S AIEHLC_A_SHIM_CH, default 1 = the
 *                                  A input of gemm_plan_4096c). Exclusive with AIEHLC_B_SHIM_DELAY_NS (#error).
 *   AIEHLC_LOCKSAMPLE              lock-stall attribution sampler: in every rt_wait_io_upto poll iteration read ONE
 *                                  core tile (round robin over cols AIEHLC_LOCKSAMPLE_COL0.., rows ..ROW0..) Core_Status,
 *                                  Core_PC, Core_Status (read-only); a sample counts as a lock stall when both status
 *                                  reads have a Lock_Stall_{S,W,N,E} bit; per-tile PC histogram of the stalled samples
 *                                  over launches AIEHLC_LOCKSAMPLE_FROM..TO (default 2..101), printed after launch TO as
 *                                  LKSAMP_CFG / LKSAMP / LKPC lines.
 *   AIEHLC_PERF_LOCKSPLIT_TABLE=<lo,hi,lo,hi, x AIEHLC_PERF_LOCKSPLIT_ROWS rows>   (gemm90 m336212422221221 PL)
 *                                  host table of core PC ranges for the lock-stall split: row k = 2 ranges
 *                                  [lo0,hi0] [lo1,hi1] (byte PCs of the linked kernel, from tools/lockpc_lst.py);
 *                                  with AIEHLC_PERF_LOCKSPLIT semantics (ctr1 = LOCK_STALL in range 0, ctr2 = in range
 *                                  1) the runtime arms row p for sweep point p (AIEHLC_SWEEP_RERUN=<rows> re-runs main,
 *                                  one ELF covers every row) and re-arms the core PC events + zeroes ctr1/ctr2 of every
 *                                  armed core tile before the point's first launch. `=== SWEEP point row=<k>` marks a
 *                                  point. The host may replace the table (__Runtime_locksplit_table). Exclusive with
 *                                  AIEHLC_PERF_LOCKSPLIT (fixed -D ranges) and with the shim delay tables (#error).
 *                                  After the last launch of every point the read-only neighbour snapshot runs
 *                                  (`LOCKSNAP tile=(c,r) lock=<l> value=<v> nbr=<S|W|N|E> of=(c,r)`, LOCKSNAP_NBR_DONE).
 *   AIEHLC_LOCKSNAP_NBR            the neighbour snapshot alone (after launch AIEHLC_LOCKSNAP_LAUNCH).
 *   AIEHLC_SHIM_TS_AIE_MHZ         AIE clock for ns -> cycles (default 1000, = GPLAN aie_mhz on palmyra213).
 *   AIEHLC_SHIM_TS_MAX             record capacity (default 16384; overflow is counted, not wrapped).
 *
 * Read-only rule of the lock snapshot: it only calls XAie_LockGetValue and AieRt_DmaGetChannelStatusFull
 * (register reads); it never acquires/releases a lock, writes a BD or touches a start queue. Cur_BD is decoded
 * with __Runtime_dma_cur_bd (aie_runtime_bdlimits.h): bits 28:25 on AIE_GEN 5 (human 11-24), 27:24 otherwise;
 * MemTile channels carry the 6-bit field at the same LSB (bit 25 on gen 5).
 */
#ifndef AIE_SHIM_TS_H
#define AIE_SHIM_TS_H

#if defined(AIEHLC_SHIM_TS) || defined(AIEHLC_B_SHIM_DELAY_NS) || defined(AIEHLC_A_SHIM_DELAY_NS) ||                \
    defined(AIEHLC_LOCKSAMPLE) || defined(AIEHLC_PERF_LOCKSPLIT_TABLE) || defined(AIEHLC_LOCKSNAP_NBR)
#define AIEHLC_SHIM_TS_ANY 1

#include <stdint.h>
#include "xaiengine.h"

#ifdef __cplusplus
extern "C" {
#endif

/* host-side delay table: n values (ns), each point held for launches_per_point launches (<=0: keep current) */
void __Runtime_b_shim_delay_table(const uint32_t *ns, int n, int launches_per_point);
/* pin point i of the table (i < 0: back to launch-indexed points); returns the selected d in ns */
uint32_t __Runtime_b_shim_delay_select(int i);
/* d (ns) the next B push will wait; B pushes counted in the previous complete launch */
uint32_t __Runtime_b_shim_delay_ns(void);
uint32_t __Runtime_b_shim_pushes_last_launch(void);
/* PAE: A = shim MM2S AIEHLC_A_SHIM_CH (default 1); pushes counted in the previous complete launch, and the d (ns) the
 * next A push waits (the same table as above when AIEHLC_A_SHIM_DELAY_NS is the swept knob, else 0) */
uint32_t __Runtime_a_shim_pushes_last_launch(void);
uint32_t __Runtime_a_shim_delay_ns(void);
/* print the SHIMTS records now (also done automatically after launch AIEHLC_LOCKSNAP_LAUNCH) */
void __Runtime_shim_ts_dump(void);
/* read-only lock / DMA snapshot of every column that had a shim push (also automatic after that launch) */
int __Runtime_lock_snapshot(XAie_DevInst *dev);
/* PL: read-only lock values of the 4 neighbour memory modules (S/W/N/E) of every core tile of the used columns */
int __Runtime_lock_snapshot_nbr(XAie_DevInst *dev);
/* PL (AIEHLC_PERF_LOCKSPLIT_TABLE): replace the PC-range table (rows x {lo0,hi0,lo1,hi1}); returns the rows kept.
 * __Runtime_locksplit_row: the row armed for the launch in progress (-1: none). */
int __Runtime_locksplit_table(const uint16_t *pcs, int rows);
int __Runtime_locksplit_row(void);

#ifdef __cplusplus
}
#endif

#endif /* AIEHLC_SHIM_TS || AIEHLC_B_SHIM_DELAY_NS */
#endif /* AIE_SHIM_TS_H */
