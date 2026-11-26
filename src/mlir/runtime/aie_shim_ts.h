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

#if defined(AIEHLC_SHIM_TS) || defined(AIEHLC_B_SHIM_DELAY_NS)
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
/* print the SHIMTS records now (also done automatically after launch AIEHLC_LOCKSNAP_LAUNCH) */
void __Runtime_shim_ts_dump(void);
/* read-only lock / DMA snapshot of every column that had a shim push (also automatic after that launch) */
int __Runtime_lock_snapshot(XAie_DevInst *dev);

#ifdef __cplusplus
}
#endif

#endif /* AIEHLC_SHIM_TS || AIEHLC_B_SHIM_DELAY_NS */
#endif /* AIE_SHIM_TS_H */
