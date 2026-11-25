---
name: plancopystreams
description: A non-GEMM kernel (eltwise, kernel-only conv) through the dataflow plan with `{.share = aie::share::broadcast}` or a `.stage` without `.share` (per-core stream); `[DataflowPlan] synthesis ERROR` for broadcast / per-core args, `share_args has N but no plan_stream`, `route ... no free path`, `its core buffers ... cannot hold its copy`, GOLDEN FAIL from the second round on, `create_io ... has no users` on the output, a conv weights `{.depth = 1}` refused, a verify that never prints its verdict
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Per-core copies in a dataflow plan

Design: `doc/design/dmaphop_dataflow_plan.md` "Per-core copies". Examples (all GOLDEN PASS on VEK385):
`simpleeltwise_add_plan.cc` (row broadcast), `simpleeltwise_add_none.cc` (per core + column broadcast),
`simpleconv2dkernel_port_plan.cc` (halo input by row, weights by column, kept).

## Setup the plan expects

- The GEMM's pragmas: `KERNELCONFIGOFFLOAD`, `output_tile_major`, `control_plan_op_control_packet`,
  `control_packet_mode(aot)`, and the partition `{2, 2 + cols}` with `__Runtime_ctrl_high_throughput_enable(1)`
  first. Without KCO the output's core MM2S starts are deferred to an input round loop the plan removed:
  `'dfschedule.config.create_io' op io_handle result has no users`.
- The host lays every planned input out with `aiehlc_plan_arrange(arg, src, dst)` and de-tiles the
  tile-major output ([mesh row][mesh col][round][block]).

## Traps

| symptom | cause / fix |
|---|---|
| GOLDEN FAIL from round 1 on, round 0 right | a 0 step read as "back to back" (`rowStepOr` / `colStepOr`): only neighbour streams default; a copy states its steps |
| `share_args has 1 but no plan_stream` | `synthCopyText` returned after the first per-core operand (loop `continue`, not `return`) |
| `route from (c, 1) ch k: no free path to (c, r)` | per-core streams of 2 operands on 4 rows = 8 streams up one column: more than the MemTile -> core links carry. Make one of them a broadcast |
| `its core buffers (9272 B ...) cannot hold its copy` | the allocator aligns each window to 32 B: slots step by the aligned chunk (`copySlotStride`) |
| `{.depth = 1} is not supported on a spatial-halo (conv) kernel` | weights `{.depth = 2}` (one block is loaded, the second buffer stays unused) |
| `an input block that depends on both program ids is unique per core` | the generic router's rule; a planned port (`.stage` / `.share`) is exempt (`trace_routing.cpp`) |
| the board run ends at the watchdog, no verdict | `verify_conv2d` dumps whole tensors over the console; compare against `scalar_conv2d` silently |

## Limits

At most 2 per-core operands (one core S2MM channel each); a row-broadcast stream is staged in column r,
so rows <= columns; per-core and neighbour streams do not mix in one plan.
