<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# 0. The lowering pipeline and where to look

Every chapter of this series builds one GEMM source, opens the IR the compiler dumped at each level and
shows what changed. This chapter is the map: the levels, the pass that produces each, the file it is
dumped to, and what a level is responsible for.

## Build once, read the dumps

```bash
source script/aiehlc.sh --aie-version 5 --runtime-source-file $PWD/example/tileprogram/ccode/gemm_plan/step0_baseline.cc
ls ir/dfschedule/        # the main pipeline, one file per pass: N_<Pass>.mlir
ls aout/worklocal/       # host.cc, kernel.cc, routing.cc (+ aiehlc_plan.h for a dataflow plan)
```

The build log names every dump it writes (`IR -> .../ir/dfschedule/N_Pass.mlir`); `ir/` is tracked in git and
the stage numbers shift when a pass is added, so read the files the log names, not older numbers left over.

## The levels

```
C source (kernel body: aie::load_buffer / store_buffer, pragmas, load options)
   |  aiehlc front end: traces the kernel on x86, fits each port's blocks (kernel analysis)
   v
routing      0_initial.mlir                 what each tensor is and how it is split over the mesh
   |  RoutingUnrollingLowerPass, RoutingToDmapPass
   v
dmap         2_RoutingToDmapPass.mlir       logical streams: an IO engine -> a core group, push / pull
   |  DmapToDmaphopPass
   v
dmaphop      3_DmapToDmaphopPass.mlir       physical hops: tiles, ports with DMA channels, hops, paths
   |  (dataflow plan step: synthesize / read / validate, the plan joins the hop graph)
   |            4_DataflowPlan.mlir
   |  DmaphopTodfscheblueprintPass (+ the plan annotated on the blueprint)
   v
dfscheblueprint  6_DmaphopTodfscheblueprintPass.mlir   per transfer: source / destination tile groups,
   |                                                      DMA channels, views, shim BD shape
   |  BlueprintToSchedulePass (host)         BlueprintToScheduleKernelPass (kernel)
   v                                         v
dfschedule   7_BlueprintToSchedulePass.mlir  19_BlueprintToScheduleKernelPass.mlir
   |         executable schedule: BDs, locks, create_io / start_io / wait, kernel load
   |  (dataflow plan: its DMA program as dfschedule ops, DataflowPlanToDfschedule dumps)
   |  ScheduleCanonicalize, SequentialOp, WaitMerge, DfscheduleToApi, ...   DfscheduleToKernelApi
   v                                         v
host.cc (EmitC)                              kernel.cc (EmitC)

dmaphop (a clone) --DmaphopToRoutinghwPass--> routinghw --RoutingHWLowerPass ...--> routing.cc
```

| level | dialect | one sentence | the question it answers |
|---|---|---|---|
| routing | `routing` | tensors (`routingcreatescheduletensor`), their split over the mesh (`partitiontensor` + `#routing.partition` / `#routing.tiling`), the blocks a kernel takes (`#routing.kernel_block`), the plan intent (`#routing.dataflow`), module switches (`routing.control_*`, `routing.persistent_kernel`, ...) | WHAT moves and how it is cut |
| dmap | `dmap` | per moved slice a stream from an IO engine (`define_io_engine`, a shim) to a core group (`define_core_group`), `push` (in) / `pull` (out) | WHO talks to whom, logically |
| dmaphop | `dmaphop` | real tiles (`tile {shim / mem / core, col, row}`), ports with DMA channels, `create_hop` (port -> port), `create_path` (a set of hops + producers / consumers), `push` / `pull` | WHICH tile, channel and switch path |
| dfscheblueprint | `dfscheblueprint` | per transfer a `flowconfig` for the source and for the destination (tile group, DMA channels, view, shim BD dims) and a `flow_transfer` joining them; tensors as `declare_data` (with the plan, when there is one) | HOW each transfer is to be programmed |
| dfschedule | `dfschedule` | the program: `config.dma_bd`, `config.create_io`, `schedule.start_io` / `wait`, `config.load_kernel_group`, the plan's `config.tile_bd` / `lock_set` / `channel_*` | WHAT the host and the cores execute |

Three things to keep in mind while reading:

- **The routing IR is the contract.** It is all the compiler knows about the program's data movement; it can be
  edited and fed back (`AIEHLC_ROUTING_IR_IN`, skill **routingirreentry**). Everything below is derived.
- **dmaphop is the last level that still sees "flows".** Below it, a flow becomes BD programs on separate tiles.
  A dataflow plan (chapters 3-5) is decided here and joins the hop graph as ordinary hops and paths.
- **dfscheblueprint is per transfer, not per tile.** One `flow_transfer` turns into many BDs (one per core, per
  ping / pong, per shim column) in dfschedule; that is where the IR grows from hundreds to thousands of lines.

## The performance levels of this series

The GEMM is int8, `C = A . B^T` on the 4 x 4 mesh of VEK385_2 (AIE2PS, 1.0 GHz, 16 x 512 MAC / cycle). The
sources are `example/tileprogram/ccode/gemm_plan/step*.cc`; what each step changes in the C source and why is
told in `tutorial/perfoptmize/` -- this series tells what the compiler does with it. See `README.md` for the
measured levels and which step reaches each.
