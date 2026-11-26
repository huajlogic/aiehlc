<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# 1. 0.01 % of peak: the generic path, every level once

Source: `example/tileprogram/ccode/gemm_plan/step0_baseline.cc` -- the GEMM body with scalar MACs and no
option at all (`GEN_VECTOR 0`, `GEN_LAUNCH 0`). C[7680 x 256] = A[7680 x 2560] . B[256 x 2560]^T, int8, 4 x 4
mesh. The kernel takes its blocks with `aie::load_buffer(a, {row, k}, {64, 64})` / `store_buffer`; the compiler
derives everything else. The measured level is in `README.md`.

This chapter walks the generic lowering once, level by level. The routing excerpts show A; from dmap on the
excerpts are the first flow in the IR, B's slice for mesh column 0 (`tensor<640x256xi8>`) -- every input flow has
the same shape. Later chapters only show what changes.

## routing: what moves, how it is cut

`0_initial.mlir`. Each kernel argument becomes a schedule tensor carrying the blocks the kernel analysis traced:

```mlir
%2 = routing.routingcreatescheduletensor %1 : tensor<7680x2560xi8> shape = [7680, 2560], dim = 2
       {kernel_block = #routing.kernel_block<tensor_shape = [7680, 2560], shape = [64, 64],
                                              rounds_i = 30, rounds_j = 40, step_i = [64, 0], step_j = [0, 64], ...>}
```

`shape = [64, 64]` is the block one `load_buffer` takes, `rounds_i x rounds_j = 30 x 40` the blocks a core takes
per launch (30 output tiles x 40 K steps of 64). The mesh split is a separate op per tensor:

```mlir
%8 = routing.partitiontensor %2 : tensor<7680x2560xi8> {
  partition = #routing.partition<splitnum = 4, splitdim = 0, hwAxisOwner = "row", replicateOn = "col", ...>,
  tiling = #routing.tiling<d0 = #routing.dim<outer = #routing.level<base = 7680, total = 7680, slice = 1920,
             step = 1920, rounds = 4, slice_tiling = #routing.level<base = 1920, slice = 64, rounds = 30>>>, ...>}
```

A is split by rows over the 4 mesh rows (1920 rows each) and replicated over the columns; inside a core it walks
64-row tiles 30 times. Then one `routing.RoutingCreate` per mesh row (an `scf.for` over 4) moves its slice:

```mlir
%11 = routing.RoutingCreate<Memo = "row"> ( scf_idx = %10 : i32) -> i32{
^bb0(%arg4: i32):
  %12 = routing.routingextract_tiles %7, %arg4 : i32, i32 -> i32
  %13 = routing.routingextract_data %8, %arg4 : tensor<7680x2560xi8>, i32 -> tensor<1920x2560xi8>
  %14 = routing.routingcreatehwiowithtarget targettilelist = %12 : i32 {direction = "input", iotype = "mem2"} -> i32
  %15 = routing.routingmovedatabyio tensordata = %13, hwiowithtarget = %14 : tensor<1920x2560xi8>, i32 -> i32
```

The module attributes are all switches and all off here (`routing.control_plan_op_control_packet = 0`, ...).

## dmap: logical streams

`2_RoutingToDmapPass.mlir`. A `routingmovedatabyio` becomes an IO engine, a core group and a stream between them:

```mlir
%12 = dmap.define_io_engine {io_id = 0 : i32, ioattr = "SHIM"}
%13 = dmap.define_core_group {core_count = 4 : i32, group_axis = "col", group_idx = 0 : i32}
%14 = dmap.define_port_configure @receive_port_0 : {"RECEIVE", 16, 1, 1}
%17 = dmap.create_stream src = %15, dst = %16 ... {streamType = #dmap.io<DMAP_SHIMIO>, stream_id = 1 : i32}
dmap.push %11 : tensor<640x256xi8> to %17
```

Still no tile coordinates for the shim, no channels: "the shim feeds these four cores".

## dmaphop: tiles, ports, hops

`3_DmapToDmaphopPass.mlir`. The stream gets physical endpoints. Each core of the group is a `dmaphop.tile`
with an input port on its S2MM channel 1 and an output port (for forwarding) on MM2S 0; the shim column and
channel are allocated by the router (`createDataIO`):

```mlir
%12 = dmaphop.tile{TILETYPE = "core", col = 0, row = 3} -> !dmaphop.tile
%13 = dmaphop.port @f0_corePortIn0 on %12 { direction = "In", direction_channel = 1 }
%14 = dmaphop.port @f0_corePortOut0 on %12 { direction = "Out", direction_channel = 0 }
...                                                     // cores (0, 4), (0, 5), (0, 6)
%28 = dmaphop.tile{TILETYPE = "shim", col = 0, row = 0} -> !dmaphop.tile
%29 = dmaphop.port @f0_shimPortOut on %28 { direction = "Out", direction_channel = 0 }
%31 = dmaphop.create_hop %29 -> %13                     // shim MM2S 0 -> core (0,3) S2MM 1
%32 = dmaphop.create_hop %14 -> %16                     // core (0,3) -> core (0,4) ...
%33 = dmaphop.create_hop %17 -> %19
%34 = dmaphop.create_hop %20 -> %22
%35 = dmaphop.create_path[%31, %32, %33, %34] {producers = [[@f0_shimPortIn]],
        consumers = [[@f0_consumer0, @f0_consumer1, @f0_consumer2, @f0_consumer3]], tee_points = [[]]}
dmaphop.push %11 into %35 consumer(%11, %11, %11, %11 at %13, %16, %19, %22)
dmaphop.sync %35
```

A **hop** is one port-to-port edge, a **path** the set of hops one data movement uses plus who produces and who
consumes. This is the level the routing path starts from: a clone of this module goes to
`DmaphopToRoutinghwPass`, which turns each path into stream-switch connections (`routing.cc`). The plan step
(`4_DataflowPlan.mlir`) changes nothing here: this source has no `load_buffer` options, so no plan.

## dfscheblueprint: one transfer, programmed how

`6_DmaphopTodfscheblueprintPass.mlir`. Per path one transfer between two tile groups, each with its DMA:

```mlir
dfscheblueprint.tile_group @group_src_0{tiles = [[0, 0]]}
dfscheblueprint.tile_group @group_dst_0{tiles = [[0, 3], [0, 4], [0, 5], [0, 6]]}
dfscheblueprint.flowconfig @flow_src_0 {
  target = @group_src_0, view = %extracted_slice : tensor<640x256xi8>, distribution = "root",
  dma = #dfscheblueprint.DMA<channels = [0], direction = MM2S>, type = "shim", data_id = 0 : i32,
  shim_dim_strides = [4 : i32, 2560 : i32, 64 : i32], shim_dim_wraps = [16 : i32, 64 : i32, 40 : i32] }
dfscheblueprint.flowconfig @flow_dst_0 {
  target = @group_dst_0, distribution = "linear",
  dma = #dfscheblueprint.DMA<channels = [1], direction = S2MM>, type = "core",
  slice_symbols = [@consumer_slice_0_0, @consumer_slice_0_1, @consumer_slice_0_2, @consumer_slice_0_3] }
dfscheblueprint.flow_transfer @transfer_0 { type = "one_to_many", from = @flow_src_0, to = @flow_dst_0,
  ordering = "sequential", base_packet_id = 0 : i32, flow_index = 0 : i32 }
```

The shim BD's multi-dimensional walk is decided here (`shim_dim_strides / wraps`, in 32-bit words): the order in
which the DDR bytes must leave so that every core receives its blocks in the order its kernel takes them. The tensors are `declare_data` ops that keep
the routing attributes (`routing.kernel_block = ...`).

## dfschedule: the program, and why it is slow

`7_BlueprintToSchedulePass.mlir` (host) and `19_BlueprintToScheduleKernelPass.mlir` (kernel). The transfer
becomes BDs per tile. Two things in this program cost almost all of the time:

```mlir
%38 = dfschedule.config.load_kernel_group(%5, %13, %21, %29) {...}   // the 16 cores' ELF, every launch
%39 = dfschedule.schedule.launch_kernel_group(%38)
scf.for %arg4 = %c0 to %c30 step %c1 {                              // 30 rounds, per launch
  %46 = dfschedule.config.dma_bd(%subview, %4, %c0_i32_0, %45, ...) {len = 163840 : i32,
          dim_strides = [4, 2560, 64], dim_wraps = [16, 64, 40], ...}
  %47 = dfschedule.config.create_io(%46, %4) {channel = 0, direction = "MM2S", io_operation = "SEND"}
  %49 = dfschedule.schedule.start_io(%47, %48) {flow_index = 0 : i32}
  dfschedule.schedule.wait(%49)                                      // the host waits for every round
}
```

It is a host-driven program: every round the host writes the shim BDs over MMIO and waits. In `host.cc` this is a
plain C loop (`for (size_t v375 = ...) { __Runtime_dma_bd_config_multidim(...); __Runtime_dma_createio_4(...);
__Runtime_startio(...); ... }`) -- 120 `config.dma_bd` and 84 start / wait ops in this schedule, each one MMIO
register writes at ~0.4 us apiece (`doc/performance/register_write_cost.md`), plus the kernel ELF load. And the
kernel itself is scalar.

## What to remember

| level | what it said for this source |
|---|---|
| routing | 3 tensors, 64 x 64 blocks, A by rows / B by columns over the mesh, 30 tiles x 40 K steps per core |
| dmap | per mesh column (B) / row (A): SHIM -> 4 cores |
| dmaphop | shim (c, 0) MM2S 0 -> core (c, 3) S2MM 1 -> forwarded core to core |
| dfscheblueprint | one-to-many transfer, multi-dimensional shim walk |
| dfschedule | kernel load + a 30-round host loop of BD writes and waits per launch |

The next chapter keeps every level's shape and moves the program off the host.
