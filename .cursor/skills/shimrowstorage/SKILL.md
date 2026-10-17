---
name: shimrowstorage
description: Keep activations on chip in memory tiles outside the compute mesh (AIE2PS). Memory tiles have no east/west stream ports, so the route goes through the shim row. Covers rerouting core output packets into out-of-order memtile S2MM, the slave port a circuit disable switches off, and lane and port allocation.
---

# On-chip storage over the shim row (whisperengine FC1 -> FC2)

## Facts (measured / read from aie-rt)
- Memtile stream switch: DMA 6, South 4/6, North 6/4 (master/slave), **no East/West**.
  A memtile DMA addresses only its own and its adjacent memtiles' memory.
- Shim stream switch: East/West 4 each way, North 6 masters / 4 slaves.
- Probe m11: memtile -> south -> shim row west -> north -> memtile runs at 7.45 GB/s
  per stream and 13.95 GB/s for two in parallel. DDR is ~10.5 GB/s for the whole array.
- Probe m12: the cores' output packets (with out-of-order BD ids), rerouted at their
  shim (NORTH p -> EAST lane), land correctly in a memtile S2MM in out-of-order mode
  (`XAie_DmaChannelEnOutofOrder` + `XAie_DmaWriteChannel`; the start-queue repeat is
  the packet count, as at a shim).
- The engine's control plane uses shim-row link 0 only for shim-BD control packets
  (`rt_sb_route`); it is not set up otherwise.

## Traps
- **`XAie_StrmConnCctDisable` also disables the slave port.** Restoring
  NORTH p -> SOUTH q *before* disabling NORTH p -> EAST L leaves NORTH p dead and
  the next op's output hangs (`WE HANG waiting output tile(4,0)`). Do every disable
  first and every enable last.
- Route changes need the lane idle: wait for the destination channel (not the
  source MM2S) before switching a lane to another storage tile.
- Two sub-ops in flight on one OOO channel need two BD id banks. The kernel adds the
  header's `WH_OOO` to its out-of-order id; the host then waits for
  "pending <= 1", not "pending == 0".

## Where
`eng/we_host.h`: `we_st`, `we_lane_east/west`, `we_st_east/west`, `we_arm_out_st`,
`we_gemm_fill_a` (`WE_ST_IN`). Partition `EF_PART_NUM_COLS 11`.
