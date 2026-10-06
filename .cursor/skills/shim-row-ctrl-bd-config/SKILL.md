---
name: shim-row-ctrl-bd-config
description: Sends host shim DMA BD, out-of-order channel enable and start-queue writes to the partition's shim tiles as control packets along row 0 instead of MMIO. Use when working on #pragma control_plan_shim_bd_ctrl, __Runtime_ctrl_shim_bd_begin/_commit, acr_plan_shim_row, a shim_bd_ctrl TIMEOUT or capture fallback, or when choosing a completion barrier for control-packet register writes.
---

# Shim-row control-packet BD config

## Enabling
- `#pragma control_plan_shim_bd_ctrl` (next to `control_plan_op_control_packet`; the app
  must call `__Runtime_ctrl_high_throughput_enable(1)`). aiehlc publishes
  `routing.control_plan_shim_bd_ctrl`.
- `planControlColumn` keeps it only with the control pragma, a spare column (dedicated
  spine) and `meshCols <= RT_RES_SHIMROW_MAX_COLS`; otherwise it prints a WARNING and
  resets the attr to 0. Check the build log for
  `shim-row BD control on MM2S ch1 / S2MM ch1`.
- Codegen (DfscheduleToApi): `__Runtime_ctrl_shim_bd_begin(&fab)` after
  `__Runtime_launch_kernel_group_ctrl`, `__Runtime_ctrl_shim_bd_commit()` once before the
  first wait. No pragma = neither call emitted, MMIO unchanged.
- Reservation: `reserveShimRowControl` (spine ch1 DMA + SOUTH ports + EAST 0; WEST/EAST 0
  on every shim east of the spine) and `reserveControlShimBds(col, shimRow)` (BDs 7-11, 15).
  These are owner-tagged reservations (`kControlPlaneOwner`), so the data router allocates
  around them; if a data route already holds one, the reservation throws.

## Shape
- Needs a dedicated control spine (`f->dedicated_shim`, spine = `col_lo - 1`), HT mode
  (TLAST error disabled), and at most `RT_RES_SHIMROW_MAX_COLS` (5) mesh columns.
- Forward: spine MM2S ch1 (SOUTH 7) -> CCT -> EAST 0, then along shim-row WEST 0 slaves.
  Column k id `(1<<k)-1`; OWN slot exact-match -> CTRL, FWD slot bit k -> EAST.
- One TLAST segment per column (a packet-switched slot routes a whole TLAST frame by
  its first header), chained BDs 7..11, a single queue push.
- Return: per shim, CTRL RET_LOCAL + EAST RET_TRANSIT -> WEST 0; spine EAST 0 -> CCT ->
  S2MM ch1 BD 15. The return-route writes ride each column's first segment.

## Barrier
Completion = the write-with-return on each column's last write, drained into BD 15
(FoT off, completes on `nseg` words). `__Runtime_wait_io` polls the pending-BD count, so
without a barrier it could read 0 before the start-queue write lands.

**Do not use `NOC_MODULE_SPARE_REG` (or any spare register) as a token.** The shim
spare registers belong to the NoC and PL, not to the runtime.

## Cost model
- Column k's segment lives at `pkt[k * RT_SB_SEG_WORDS]` and is encoded while
  capturing. A rollback snapshot also saves the open access's control header,
  because extending an access rewrites a header from before the snapshot.
- `begin` -> `rt_sb_prepare`: the route and the pre-armed BDs 7..10 + 15 cost
  ~22k cycles, once per fabric. The kick is 4 `XAie_DmaUpdateBdLen` writes plus
  2 queue pushes.
- Don't try to hide the setup MMIO by moving it (before the ELF fill, after the
  ELF push) or by awaiting the ACK later: wall time does not move (skill
  **host-register-write-attribution**).

## Debug
- `[aie_runtime] shim_bd_ctrl: capture fallback` = a hooked call issued a read, a
  mask write, a poll or a non-SHIMDMABD op. Its writes are rolled back, the batch is
  flushed, and the call re-runs over MMIO, so ordering is preserved.
- `shim_bd_ctrl TIMEOUT ... s2mm_pending=1 mm2s_pending=0` means the segments went
  out but a response did not come back: check the shim-row return route.
  `mm2s_pending>0` points to the forward route or the packet build.
- `__Runtime_ctrl_shim_bd_ctrl_stats_print()` after the timed region prints the
  build/kick/poll split.
- Planner unit test: `bash src/mlir/runtime/unitest/build_ctrl_row_plan.sh`
  (`test_shim_row`).
