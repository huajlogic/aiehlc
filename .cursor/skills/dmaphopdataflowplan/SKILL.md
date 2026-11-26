---
name: dmaphopdataflowplan
description: Explicit dataflow plans -- replacing hand edits of generated host.cc / kernel.cc / routing.cc with IR the compiler lowers. Use for `load_buffer {.share / .stage / .ring / .keep}`, `#pragma persistent_kernel`, a `#routing.dataflow<...>` attribute in the routing IR, `dmaphop.plan*` ops, `[DataflowPlan]` log lines / errors, `aiehlc_plan.h` not found, a plan build that hangs or mismatches, or "flowcheck ... replaced by the dataflow plan".
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Dataflow plans (C -> routing -> dmaphop -> code)

Design: `doc/design/dmaphop_dataflow_plan.md`. Example: `example/tileprogram/ccode/gemm_plan/`
(2 x 8 shared-operand GEMM, 85.5 % of the VEK385 peak from the C source, every launch 85.3-85.7 %,
GOLDEN PASS).

## Three ways in, one lowering
| level | write | compiler entry |
|---|---|---|
| C | `load_buffer(..., {.share = aie::share::neighbor, .stage = aie::stage::memtile_ring, .ring = 10})`, `{.keep = true}`, `#pragma persistent_kernel` | trace harness -> `KernelBlock` -> `dataflow` dict |
| routing IR | `#routing.dataflow<...>` on `routingcreatescheduletensor`, `routing.persistent_kernel` | `plansynth.cpp` (dump `4_DataflowPlan.mlir`) |
| dmaphop IR | `dmaphop.plan` / `plan_route` / `plan_stream` (dataflow decisions) | `collectDataflowPlan` (`dataflowplan.cpp`) |
| dfschedule IR (derived) | `config.tile_bd` / `lock_set` / `channel_enable` / `channel_start`, shim `config.dma_bd` + `start_io` | `plandma.cpp` derive + materialize; lowered by DfscheduleToApi / DfscheduleToKernelApi |

## Nothing in the plan is a literal
- Device facts: `pass/dataflowplan/plantarget.h` (AIE2PS) -- counts, MemTile BD banks, views, lock
  biases, per-tile-kind BD wrap limits, shim MM2S -> SOUTH port, switch port counts.
- BD / lock ids, MemTile buffers, the core chunk slots, the go / sync locks: `planresource.cpp`
  allocates them against the host module's flows, `ResourceMgr::coreOffloadPlan` (replaced args
  skipped via `funcArgIdx`) and the control plane's shim BDs; the slots are the memory the allocator
  gave the replaced windows (`CoreMemSlot.ownerId`). Read the choice in the log:
  `[DataflowPlan] resources (aie2ps): core BDs ..., core locks F .. E .. go .. sync .., ...`.
- Channels / MemTiles / replay targets come from the stream's `plan_route`s (`arg = N` required).
- Kernel side: `src/mlir/runtime/aie_block_io_plan.h` (always_inline, operand by descriptor, tile
  sync at commit); `aiehlc_plan.h` is constants only.

## Routes, protocol, layouts, readback (2026-11-24)
- Routes: `plan_route` lowered in DmaphopToRoutinghwPass (`passdmaphoptoroutinghw/planroutes.cpp`) to routinghw ops;
  `[DataflowPlan] routed N plan net(s) in DmaphopToRoutinghwPass`. No `aiehlc_plan_routing()` any more.
- Protocol: `plan_stream channels / slots / readers / parts / elem_bytes / row_groups / strips` (synthesized:
  channels = core S2MM count, slots = `{.depth}`, parts = `{.parts}`); header `AIEHLC_PLAN_READER(o, pm)`.
- Layouts: any mesh width >= A strips; 4 x 2 = `gemm_plan_4x2.cc` (86.5 %). Skill **nonsquaremeshplan**.
- Host DDR layout: `aiehlc_plan_arrange(arg, src, dst)` generated in `aiehlc_plan.h` (`#if __has_include`).
- Readback: edit `ir/dfschedule/NN_DataflowPlanProgram.mlir`, build with `AIEHLC_DFSCHEDULE_PLAN_IN=<file>`;
  `readback: the regenerated dfschedule plan program equals the edited one` or an ERROR naming the line;
  `NN_DataflowPlanReadback(dmaphop).mlir` (with `dmaphop.plan_resources`) re-enters via `AIEHLC_DMAPHOP_IR_IN`.
  `ir/` keeps dumps of earlier builds: pick the highest-numbered file.

## Checks that it worked (the build log)
- `[DataflowPlan] synthesized from the routing IR: ...` (C / routing level only)
- `[DataflowPlan] N generated flow(s) replaced by the plan` -- 0 means the args in `replace_args`
  do not match the pushes (traced from the push data operand to the func arg)
- `[DataflowPlan] routed N plan net(s): M switch connections`
- `flowcheck: OK -- ... replaced by the dataflow plan, 0 error(s)` -- plan routes ARE simulated
- `kernel.cc`: `// window_in_0: core S2MM ch 0 programmed by the dataflow plan` + `DATAFLOW PLAN` block

## Traps (each cost a build or a wrong number)
- **Edit the binary, not just the source.** A plan-op attribute the running `build/aiehlc`
  does not know is reported as `missing array attribute` (stale binary) -- rebuild.
- **Dead-argument removal.** Without a plan-aware `ScheduleCanonicalizePass`, replaced A/B lost
  their `host_canonicalized` parameters and the caller's A landed in C's slot. Fixed: under a plan
  every memref arg is kept.
- **A no-plan build cannot compile the plan kernel** (`aiehlc_plan.h` not found) -- expected.
- **`AIEHLC_KB_CHECK_WARN` is not needed** with a plan: `resolveKernelBlock` skips replaced args.
- **Text match by first occurrence.** Patching runtime / pass sources by string, the same snippet
  existed in a sibling function (`__Runtime_dma_bd_config_multidim` vs `_ooo`,
  `preMapExternalValues` vs `buildHostBlockByCloning`); check `grep -c` before replacing.
- **Routing IR re-entry with the control plane** used to report `1 line(s) differ` for every
  control-plane kernel: the dump carries the derived `control_plan_shim_col/_mm2s_ch/_s2mm_ch/
  _exclusive`. `readIROverride` now ignores them and prints the first differing line otherwise.
- **The farm host refuses scp** (`Permission denied (publickey)`) once the systest hold lapses:
  `python3 script/test/hws.py --board gomphus6 --type vek385 up`, then rerun apppaltest.
- The printed % of `gemm_plan.cc` uses GEMM_AIE_MHZ = 1250 (VEK385); palmyra is 998.

## One kernel body (no `__chess__` split) -- what cost performance and how it came back
- Shared-port state read from a global on every load: 77 %. Copy to a local at kernel entry (the
  rewrite does it); lambdas capturing by reference pin it in memory again -- use body macros.
- A conditional around the inner chunk loop (`if (j < NK - 1)`) changed chess's schedule: keep the
  hand-written shape (chunk 0, boundary, loop {inner; boundary}, last chunk).
- Output tile pointer without `__restrict` made the last-chunk loop 147 bundles (139).
- Unrolling the chunk loop by 2 overflows the 16 KB program memory (`could not find free space` /
  PM > 0x4000): do not.
- `aie::mmul` at file scope in the prologue breaks the aiehlc front-end parse: prologue headers
  must hold macros only; declare the typedef in the body.
- The occasional 1.20-1.26 ms launches were NOT board noise: a stream's follower drifted half a chunk
  behind its leader (3x bank conflicts). Tile sync at `commit` (AIEHLC_PLAN_LOCK_SYNC) removed them.
- **Core BD wraps are 8 bits** (MemTile / shim 10). A 512-word wrap in a core BD truncates silently:
  GOLDEN FAIL with a deterministic match count (24,728 / 187,758) and perf unchanged. Every derived
  wrap goes through `splitWords(words, <kind>BdMaxWrap)`.

## The DMA program lives in dfschedule
- dmaphop has no BD / lock / channel ops any more (`plan_bd` etc. are gone: "unknown plan op").
  Edit `plan_stream` (ring, resident, host rows) and the dfschedule program follows; read it in
  `ir/dfschedule/NN_DataflowPlanToDfschedule.mlir`.
- MemTile lock ids: `config.lock_set` takes 0..63, a BD's acquire / release take 64.. (own locks).
- Write-once must stay constant time: a per-call lookup over 100 MemTile BDs cost tens of us per
  launch -- `__Runtime_tile_bd_config` returns at once after the first launch under bd_once.
