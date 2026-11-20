---
name: gemmendtoend
description: End-to-end (launch + kernel load + DDR in/out) performance of a kernel-only streaming GEMM on the 4x4 mesh -- per-strip host DMA loop, 0.09 % -> 12 % of peak, what each lever measured, and the mixed read/write DDR wall. Use for "launch takes 300 ms", a host `for` over rounds in host.cc, GOLDEN FAIL after making an input stream freely, "Memory budget exceeded" / CoreMemAllocator out of memory for a >32 KB resident block, or a run phase that does not speed up when compute does.
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Streaming GEMM end to end (palmyra, AIE2PS, 4x4)

Peak = 16 cores x 512 int8 MAC/cycle (`mmul<8,8,8,int8,int8>` = one
`mac_8x8_8x8`) x 998 MHz = 8.18 TMAC/s. A single core's compute loop reaches
91.5 % (`example/tileprogram/ccode/simplegemm_peak.cc`); end to end is another
problem.

## Measured ladder (1.07 G MAC = 2.15 G op per launch, GOLDEN PASS every row)
| Change | per launch | % peak |
|---|---|---|
| kernel-only GEMM as generated | 293 ms | 0.09 |
| + `control_plan_op_control_packet`, `--skip-port-bss`, `DISABLE_PARTITIONTEARDOWN` | ~1 ms | ~9 |
| + C `__Runtime_buffer_device_written`, A/B `__Runtime_alloc_uncached` | 0.84 ms | 10 |
| + 32-row strips, N=512 K=256 | 1.08 ms (2x work) | 12.1 |
| + `KERNELCONFIGOFFLOAD` (resident fixed) | 0.90 ms | 14.6 |

## Traps
- **Per-strip host loop.** A kernel-only input that follows its blocks got one
  shim BD per round + a host `scf.for` that re-armed every BD over MMIO and
  waited each round (`classifyScheduleMode`). Now: blocks back to back in DDR ->
  ONE 2-/3-D shim BD walk (`kbWalk`, flowtransfer_host.cpp) -- **only with
  `#pragma output_tile_major`**. Without it the outputs are still re-armed per
  round and the free-running input lets cores emit round r+1 into BDs being
  re-armed for r: GOLDEN FAIL, most of C never written (skill outputtilemajorrace).
- **GEMM output tile-major.** `output_tile_major` now also covers the GEMM path
  (`buildOutputTileDescriptor`): one S2MM BD per core walks its rounds with the
  BD iteration -- **6 bits: <= 64 rounds per launch**; more keeps the host loop.
- **Memory budget.** The pipeline's early check assumed a 10 KB stack (49 KB);
  CoreMemAllocator grows buffers into the stack to AIEHLC_DM_MIN_STACK, and a
  block larger than either side (43 KB resident B) now straddles the area start
  (gap search, capped 3 KB below the top: klog ring at 0x7F800). Ceiling 58368 B.
- **Control-plane pragmas.** `control_plan_op_control_packet` alone: kernel load
  153 ms -> 0.03 ms, run unchanged. Adding `CONTROL_PLAN_GROUP_REG_WRITE` +
  `control_packet_mode(aot)`, or `control_plan_shim_bd_ctrl`, made the DATA run
  2.4x slower (0.29 -> 0.70 ms) -- cause not found (burst is set on both paths).
  `KERNELCONFIGOFFLOAD` + `{.resident}` -- fixed, two bugs: (1) `c.kb` was
  resolved only by the host shim path (applyKernelBlockShim), so on the kernel
  clone a resident input fell back to two buffers (2 x 43 KB, out of memory);
  flowtransfer_kernel.cpp now resolves it there too. (2) The KCO single-buffer
  cross-check (passdfscheduletokernelapi checkWindowOffloadIds) compared every
  input window against EVERY input plan entry, so streamed A (ping-pong) failed
  against resident B's pp_depth=1; it now matches on the core DMA channel.
  Result: host bdcfg 0.20 -> 0.06 ms, end to end 1.08 -> 0.90 ms (14.6 %).
- **klog in the timed region** prints over the UART: seconds. Time without it.

## Best so far: 26.8 % end to end (MemTile-staged, hand-edited) -- 2026-11-20
`example/tileprogram/ccode/gemm_memtile/`: K-accumulating kernel (int32 C tile per
core, written once) + `memtile_ab.py`, which edits the generated host.cc / routing.cc:
- B is resident in each column's MemTile and replayed once per m tile;
- A is double-buffered per mesh row and replayed once per n tile;
- the shim sends every byte once.
2.20 ms / 4.83 G MAC (26.8 %) on palmyra, GOLDEN PASS (two-block kernel).

Traps:
- **The kernel analysis takes 2-level block sequences only.** Trace (x86 `#else`) what
  the SHIM sends; the chess path consumes the replays. Build with
  `AIEHLC_KB_CHECK_WARN=1`, and match the A offsets to the trace cursor, or klog fills
  with BLKE.
- **MemTile BD rules:** BDs on odd channels are 24..47; own memory starts at 0x80000;
  own locks are 64+ in a BD.
- **Write the MemTile BDs once** (static flag) and re-arm only locks + start queue:
  0.26 ms per launch of MMIO at 372 ns/write.
- **The limit now is on-chip core input:** 2.7 B/cycle per S2MM channel (slope of
  DMA-only 8 vs 16 rounds), and the input bytes per MAC are 1/tm + 1/tn. 64 x 64 tiles
  give 33 %; no tile that fits 64 KB (int32 accumulator + ping-pong + C ping-pong)
  gives more than ~42 %. A 32-B K chunk makes the accumulator reload dominate
  (96 x 80, kc 32: 14.9 %).
- AIE clock on palmyra: 1000 MHz.

## MEASURED DDR rate (2026-11-20): 7.8 GB/s mixed
These are DMA-only probes at 16/32/64 rounds: 0.311 / 0.515 / 0.909 ms end to
end for 1.57 / 3.15 / 6.29 MB. The slope is 7.7-7.9 GB/s and the fixed cost
~0.11 ms per launch. The GEMM (0.897 ms) equals its DMA-only twin, so it is
DDR-bound. `script/perf/gemm_e2e_bound.py 7.8` gives 47 % for a design that
mixes reads and writes. But write-only measures 13.9 GB/s (bound 70 %), so
keeping reads and writes apart in time (reads staged in the MemTiles) is the
open lever -- do NOT call 60 % impossible from the mixed rate alone. A read-only
slope taken inside the ~0.5 ms fixed launch cost is meaningless (0.018 ms for
1.57 MB): use >= 3 sizes and check they are linear.
Measure bandwidth by the slope of whole-launch time vs bytes, never by
bytes / a phase timer.

## The wall: mixed DDR traffic (ruled out: compute, release order, shim placement)
**CAVEAT (2026-11-20):** the GB/s figures below are NOT dedicated DMA probes --
they are bytes / the wait_io PMU phase of a whole launch. The "input only ~37
GB/s" is not physical (4 row streams x 4 B/cycle at ~1 GHz cap near 16 GB/s) and
the "output only 20.5 GB/s" needs 5.1 GB/s per 32-bit S2MM channel: wait_io most
likely does not cover the whole transfer in those two probes. Amit's dedicated
palmyra213 probes (amit/tasks/2026-11-14_palmyra-ddr-cap: read 9.9, write 8.0,
r+w 7.4 GB/s) are the reference; the conclusions below that lean on 37/20.5
(phase separation gains, projections) are unverified.
Probes on the 32-row-strip shape (A 2.1 MB in, C 4.2 MB out per launch):
| Probe | run phase |
|---|---|
| GEMM | 0.57 ms |
| no MACs at all (DMA only) | 0.574 ms |
| DMA only, A released before C is acquired | 0.583 ms |
| GEMM, outputs spread over all 4 shim tiles (`AIEHLC_SHIM_BALANCE=1`) | 0.616 ms |
| output only (A resident) | 0.205 ms = 20.5 GB/s |
| input only (C written once) | 0.057 ms = ~37 GB/s |
`AIEHLC_SHIM_BALANCE=1` (ResourceMgr::freeShimNoc, default off): prefer the shim
tile with the fewest channels of that direction allocated, then the nearest --
by default every mesh row's gather lands next to its LAST core (cols 3, 4).
Reads alone and writes alone are fast; together ~11 GB/s. Separating them in
time (all reads, then all writes) would cost R/37 + W/20 instead -- 0.27 vs
0.57 ms here -- but needs the operands staged on chip (memtiles, 512 KB each).

DMA-only probe (no MACs) takes the same time as the GEMM: compute is hidden.
Output alone 20.5 GB/s, input alone ~37 GB/s, both together 11-15 GB/s. With B
resident (<= ~43 KB/core) bytes/MAC >= 1/N + 1/K, so a DDR-streamed GEMM is
capped near 30-38 % of peak. More needs on-chip reuse (memtile staging, not in
the kernel-only path) or a way around the read/write contention.

Also ruled out on the KCO build (run phase 0.72 ms, unchanged): C 517 MB away from
A (DDR placement), shim AXI burst 32, AxCACHE 0x3, burst 32 + AxCACHE 0x3
(`EXTRA_DEFS=-DRT_SEQ_SHIM_AXI_BURST=32U -DRT_SEQ_SHIM_AXI_CACHE=3U`).

## The remaining lever: phase separation through memtiles (not built)
Keep A on chip so DDR sees a read phase (A, B) then a write phase (C, overlapping
the MACs): per MAC ~ max(1/peak, 1/(K * 20 GB/s)) + 1/(4cn * 37 GB/s). With K~370,
cn~116 (B 43 KB) that projects ~60 % run, ~55 % end to end -- a projection.
Status: routingtodmap can build SHIM->MEM->CORES (`moplevel == 1`), hard-wired to
0; the blueprint/schedule lowering has no memtile BD / lock support. Multi-day.

## Memtile staging -- measured by hand-editing generated routing.cc / host.cc
Route each A row-broadcast hop at memtile (c,1) `SOUTH p -> DMA 0` + `DMA 0 -> NORTH p`;
memtile S2MM BD0 takes the row's whole A, releases a lock; MM2S BD1 acquires it and
streams to the cores. **Memtile DMA addressing is neighbourhood-relative**: own
memory at **0x80000** (0x0 = WEST neighbour -- the first data column hangs, the
others silently write into their neighbour); own locks at **64..** in a BD
(`XAie_DmaSetLock(&d, XAie_LockInit(64 + id, ..))`), `XAie_LockSetValue` still
takes 0..63. aie-rt writes both fields raw. Results (GOLDEN PASS every row):
| build | run phase | end to end |
|---|---|---|
| R=30, no control plane, A from DDR | 0.145-0.154 ms (40-43 %) | 8.7 ms (MMIO ELF load 8 ms) |
| R=30, no control plane, A staged | 0.108-0.129 ms (48-57 %) | -- |
| R=60, control plane, A from DDR | 0.52 ms | 1.034 ms (11.9 %) |
| R=60, control plane, A staged | 0.42 ms | 1.000 ms (12.3 %) |
**The "control-plane slows the run" anomaly is accounting**: with
`control_plan_op_control_packet` the ELF is streamed asynchronously -- kload
(0.03 ms) only queues it and the load lands inside wait_io. Compare END TO END.
What bounds end to end now: ~0.6-0.9 ms fixed per launch (ELF stream, BD config,
cache sync) vs 0.12 ms of ideal work per launch (A per launch <= memtile 512 KB
per row, <= 64 output rounds per core). 60 % needs a persistent kernel re-armed in
~us, plus the staging above in the compiler.

