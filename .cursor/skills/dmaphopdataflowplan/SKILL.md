---
name: dmaphopdataflowplan
description: Explicit dataflow plans -- replacing hand edits of generated host.cc / kernel.cc / routing.cc with IR the compiler lowers. Use for `load_buffer {.share / .stage / .ring / .keep}`, `#pragma persistent_kernel`, a `dataflow = {...}` attribute in the routing IR, `dmaphop.plan*` ops, `[DataflowPlan]` log lines / errors, `aiehlc_plan.h` not found, a plan build that hangs or mismatches, or "flowcheck ... replaced by the dataflow plan".
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Dataflow plans (C -> routing -> dmaphop -> code)

Design: `doc/design/dmaphop_dataflow_plan.md`. Example: `example/tileprogram/ccode/gemm_plan/`
(2 x 8 shared-operand GEMM, 84.9 % of the VEK385 peak from the C source, GOLDEN PASS).

## Three ways in, one lowering
| level | write | compiler entry |
|---|---|---|
| C | `load_buffer(..., {.share = aie::share::neighbor, .stage = aie::stage::memtile_ring, .ring = 10})`, `{.keep = true}`, `#pragma persistent_kernel` | trace harness -> `KernelBlock` -> `dataflow` dict |
| routing IR | `dataflow = {...}` on `routingcreatescheduletensor`, `routing.persistent_kernel` | `plansynth.cpp` (dump `4_DataflowPlan.mlir`) |
| dmaphop IR | `dmaphop.plan*` ops | `collectDataflowPlan` (`dataflowplan.cpp`) + `planemit.cpp` |

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
