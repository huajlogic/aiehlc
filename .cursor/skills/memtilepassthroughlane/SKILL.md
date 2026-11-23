---
name: memtilepassthroughlane
description: A hand-routed circuit through a MemTile (row 1 / 2) never delivers -- the upstream DMA sits in Stalled_Stream_Backpressure, the downstream S2MM runs with no data, and an aiedump shows the MemTile's slave / master config for that hop as 0. Cause: on AIE2PS a MemTile passes SOUTH / NORTH slave k ONLY to SOUTH / NORTH master k; XAie_StrmConnCctEnable returns XAIE_ERR_STREAM_PORT for any other lane, and generated routing code ignores the return code.
---

# MemTile pass-through keeps its lane

## Symptom
- A new or re-routed stream through a MemTile hangs (`wait_io TIMEOUT` on the upstream shim MM2S).
- `script/aiedump.py`: the shim MM2S shows `Stalled_Stream_Backpressure=1`. The target S2MM is
  `Channel_Running` on its first BD with nothing arriving.
- The MemTile hop's `stream_switch_slave_config_south_<k>` / `master_config_north<j>` read 0.
  The `XAie_StrmConnCctEnable` call failed, and nobody checked its return code.

## Cause
`_XAie2PS_MemTile_StrmSwCheckPortValidity` (`aie-rt .../stream_switch/xaie_ss_aie2ps.c`) rejects
SOUTH/NORTH slave -> SOUTH/NORTH master with different indices. Core and shim tiles only tie the
index for same-direction loopback (SOUTH->SOUTH), and a shim SOUTH slave may go to any master.
Example: `TileLoc(c,1), SOUTH, 1, NORTH, 5` is rejected; `SOUTH, 5, NORTH, 5` is accepted.

## Fix
- **Router:** `example/tileprogram/ccode/gemm_memtile/share_route.py` `route_net` searches
  states (tile, incoming slave) and ties the lane through rows 1-2. Keying the search on the
  tile alone commits to the first free lane into the MemTile and then finds no way out
  (`no route`).
- **Re-routes:** switch at a point with no lane rule, such as the shim's SOUTH slave.
  `share2x8.py --a2ch` disables shim SOUTH 3 -> NORTH k and MemTile SOUTH k -> DMA 0, then
  routes SOUTH 3 -> NORTH 5 -> MemTile row 1 NORTH 5 -> row 2 DMA 0.
- **Hand-written stream-switch calls:** check `!= XAIE_OK` (the `sh_reroute` pattern).
