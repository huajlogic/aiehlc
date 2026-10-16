<!-- Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: aieswitchtrace
description: Read back and flow-trace the live AIE stream-switch configuration over JTAG with aiegdb's tile-scope `show switch` / `scan switch`. Decodes each tile's master/slave config registers (core/shim master 0x3F000, slave 0x3F100, slot 0x3F200; memtile 0xB0000/0xB0100/0xB0200) into "SRC slave -> master [circuit|packet]" plus packet-slot detail, then BFS-hops tile-to-tile along enabled directional ports to assemble end-to-end connections (e.g. DMA0@(0,3) -> NORTH0@(0,3) -> NORTH0@(0,4) -> CORE0@(0,5)). Use when a routing/connectivity bug is suspected on hardware — a flow that never arrives, a wrong source, a packet-vs-circuit mismatch — to compare what the switch is ACTUALLY programmed to against the compiler's intended routing (routing.cc / dmaphopprovenacemap.json). Both commands are read-only and cycle-safe.
---

# AIE stream-switch read-back & flow-trace (`show switch` / `scan switch`)

Two read-only tile-scope aiegdb commands decode the AIE stream switch straight
from its configuration registers, so you can check what the hardware is
*actually* wired to do against what the compiler intended.

Source of truth: `src/tool/debug/aiediag.py` (`read_switch`, `format_switch`,
`decode_strm_master/slave/slot`, `master_neighbor`, the `STRM_SW_*` tables) and
`src/tool/debug/aiegdb.py` (`_show_switch`, `_scan_switch`, `_trace_upstream`,
`_trace_downstream`). Register model transcribed from
`thirdparty/aie-rt/driver/src/global/xaie2psgbl_{params,reginit}.c`.

## Commands

```bash
# One tile: decode its whole switch.
aie_exec("target tile 0 3")
aie_exec("show switch")          # aliases: switch, switches

# Flow-trace every connection through this tile across all reachable tiles.
aie_exec("scan switch")          # alias: scanswitch
```

`show switch` output per enabled master: `  <slave> -> <master>  [circuit|packet]`
plus `enabled slaves: ...` and, for packet slaves, `slot <port> #n: id=.. mask=..
msel=.. arbiter=..`.

`scan switch` prints each visited tile's `show switch`, then the assembled flows
through the origin tile.

## How the decode works (the one fact that makes it possible)

A **master**-config register's `CONFIGURATION` field (bits[6:0]) is the
*physical slave port index* feeding that master — the driver
`_XAie_StreamSwitchConfigureCct` writes `SlaveIdx` there, and
`_XAie_GetSlaveIdx` computes it as `(SlaveRegAddr - SlaveBase)/4` = the physical
slave index. So `decode_strm_master(raw)["config"]` indexes directly into
`STRM_SW_SLAVE_PORTS[tile_type]` to name the source. Master bit31 = enable,
bit30 = packet, bit7 = drop_header. Slave bit31 = enable, bit30 = packet.

## Register bases (identical for gen5/aieml and gen 2ps)

| tile    | master  | slave   | slot    |
|---------|---------|---------|---------|
| core    | 0x3F000 | 0x3F100 | 0x3F200 |
| shim    | 0x3F000 | 0x3F100 | 0x3F200 |
| memtile | 0xB0000 | 0xB0100 | 0xB0200 |

Config regs stride 0x4 (indexed by physical port). Slots: 4/slave, stride 0x4
(0x10 per slave). Slot fields: ID[28:24] MASK[20:16] ENABLE[8] MSEL[5:4]
ARBITER[2:0].

## Inter-tile wiring (how `scan switch` hops)

A directional MASTER crosses to the neighbor's SLAVE of the opposite direction,
same port number:

- NORTH master @(c,r) → SOUTH slave @(c,r+1)   (SOUTH master → NORTH @(c,r-1))
- EAST  master @(c,r) → WEST  slave @(c+1,r)   (WEST  master → EAST @(c-1,r))

Flow terminals (no hop): non-directional ports {CORE, DMA, CTRL, TRACE, FIFO}
and the **shim (row 0) SOUTH** boundary = PL/NoC/DDR. MemTiles have **no
EAST/WEST** ports (vertical only).

## Using it to find a routing bug

1. On the suspect tile: `show switch`. Is the master you expect enabled? Is its
   source slave the one you expect? circuit vs packet as intended?
2. `scan switch` to get the end-to-end chain, then compare to the compiler's
   intent in `worklocal/dmaphopprovenacemap.json` / the emitted `routing.cc`
   (the `xaieapiverify` / `routinghwdebug` skills cover the static side).
3. A flow that stops early (`... (sink)` or a bare `[SLAVEn]@(c,r)`) means the
   arriving slave feeds no enabled master downstream — the route was not
   programmed all the way through.
4. `slave#N?` in place of a source name means the master's CONFIGURATION points
   at a slave index with no port map entry — a bogus/uninitialised config.

## Guarantees / pitfalls

- **Read-only.** Neither command writes hardware (unlike `dma counter setup`).
- **Cycle-safe.** BFS keeps a `visited` set; `_trace_upstream`/`_trace_downstream`
  each carry a recursion guard, so a misconfigured loop terminates and is
  annotated `(cycle)` rather than hanging.
- `scan switch` can read **many** tiles (it fans out over the whole reachable
  set) — for a single-tile question prefer `show switch`.
- A dry-run / failed read makes every master decode as disabled (raw 0/None), so
  `scan switch` reports 1 tile and "no enabled connections" — check the
  `[registers read]` appendix shows real values, not `= ----------`.

## Verify

```bash
python3 -m pytest src/tool/debug/tests/test_aiegdb_switch.py -v
python3 src/tool/debug/aiegdb.py --dry-run -c "tile 0 3; show switch; scan switch"
```
