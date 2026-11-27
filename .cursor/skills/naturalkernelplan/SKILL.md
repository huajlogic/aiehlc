---
name: naturalkernelplan
description: A kernel-only kernel written the natural way fails kernel analysis or the dataflow plan -- `dim 0 moves with both program_id(0) and program_id(1) ... a mesh axis can split one tensor dim only`, `an input block that depends on both program ids is unique per core`, `{.stage = memtile_ring} needs {.ring = N}`, `the ring does not divide column c's chunk stream`, `a ring of N does not divide a core's M chunks`, `a chunk does not fit the core / MemTile / shim BD wrap limits`, `its core buffers (68 B from 0x...) cannot hold its copy`, `core buffer buf_in_ping_N (... x 2) does not fit the core port-buffer region`; or you are about to hand-arrange a tensor (strided 2-D views, splitting an input in halves, interleaving chunks in a converter) to get past one of them.
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Natural kernels through the dataflow plan

Design: `doc/design/dmaphop_dataflow_plan.md` "Kernels written naturally". Since 2026-11-27 the compiler
derives what the Qwen GEMV (`src/APP/qwen/aie/`) used to work around by hand. **Write the kernel the way the
data is laid out**; do not reshape it for the DMA.

| symptom (older aiehlc) | what the compiler does now |
|---|---|
| dim moves with both program ids | a dim 0 split over the linear core index `c = p0 * C + p1` (p0 step = C x p1 step, block = whole later dims, loops inside the core's slice) is routed as the 2-D view `(R, C * s * rowElems)`: note `dim 0 is split over the core index ...: routed as the same memory viewed ...` |
| input unique per core | promoted to the plan (`.stage = memtile_ring`): note `its blocks differ per core: fed by the dataflow plan` |
| `.ring` required / ring does not divide | `.ring` optional (2 for an even chunk count, else 1); a single-parity ring falls back to one-chunk buffers |
| chunk row > BD wrap (shim 1023 words) | the shim splits the contiguous chunk into two dims |
| copy does not fit the replaced windows / x2 buffers | plan-fed buffers sized from the plan when the stand-in windows are too small |

Still yours to know:
- Other split forms (dim split by p1 major, splits of a dim other than 0, blocks that do not span the later
  dims) keep the old error -- `viewLinearSplit` (`kernel_trace.cpp`) returns false and says nothing.
- A per-core stream's DDR layout is the plan's (each column's shim interleaves its cores' chunks):
  call the generated `aiehlc_plan_arrange(arg, src, dst)` (`aiehlc_plan.h`) -- offline for static weights.
  Do not re-derive the order by hand in a converter.
- An output with the linear split is already row-major `[pm][pn][u]`: drop `#pragma output_tile_major`,
  which would reorder it again.
- Verify: `aiehlc-convtile trace <src>` (notes above), the build's `[DataflowPlan] resources` line and
  `flowcheck: OK`, then the board's GOLDEN line. Regression gate: `script/test/plan_regress.sh compare`.

Reference: `/content`-independent repro = the natural Qwen kernel (see the design doc section): VEK385
0.345 ms / 25.9 GB/s, GOLDEN PASS, same as the hand-arranged kernel.
