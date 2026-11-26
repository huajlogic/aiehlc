<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# 3. The dataflow plan: what moves changes, and every level shows it

Source: `step3_memtile.cc` -- the GEMM body with load options on A and B (and N doubled to 512: the 2 x 8 layout).
The kernel still says only which block it takes; the options say how the two operands may travel:

```c
#define OPTS_A {.depth = 2, .share = aie::share::neighbor, .stage = aie::stage::memtile_ring, .ring = 2, .align = 64}
#define OPTS_B {.depth = 2, .share = aie::share::neighbor, .stage = aie::stage::memtile, .keep = false, .align = 64}
auto xa = aie::load_buffer(a, {arow, k * KA_KC}, {KA_TM, KA_KC}, OPTS_A);
```

`.share = neighbor`: a 64 x 128 chunk is received by ONE core ("host") and read by its neighbour from the host's
memory (one stream feeds two cores). `.stage = memtile_ring` / `memtile`: the stream goes through a MemTile -- A
as a FIFO ring of 2 buffers, B whole. This chapter follows that intent from the routing IR down to the DMA program.

## routing: the intent, typed

`0_initial.mlir`. Each of A and B carries a `#routing.dataflow` next to its `#routing.kernel_block`:

```mlir
%A = routing.routingcreatescheduletensor ... {dataflow = #routing.dataflow<share = "neighbor",
       stage = "memtile_ring", ring = 2, keep = false, parts = 1, axis = "", base_p0 = [], base_p1 = []>, ...}
%B = routing.routingcreatescheduletensor ... {dataflow = #routing.dataflow<share = "neighbor",
       stage = "memtile", ring = 0, keep = false, parts = 1, axis = "", base_p0 = [], base_p1 = []>, ...}
```

Nothing else in the routing IR changes: the partitions and the `RoutingCreate` regions are the generic ones.
The intent is a typed attribute of the tensor (every field printed, so `AIEHLC_ROUTING_IR_IN` reads it back).

## dmap, then dmaphop: the generated flows, then the plan step

`2_RoutingToDmapPass.mlir` and `3_DmapToDmaphopPass.mlir` are produced as in chapter 1: per mesh row / column a
shim -> 4 cores flow. Then the plan step (`4_DataflowPlan.mlir`) runs on the dmaphop module:

1. **Synthesis** (`plansynth.cpp`) reads the `#routing.dataflow`s and the kernel blocks and decides the 2 x 8 grid:
   which mesh rows host A's strips and B's, which MemTile each column's stream goes through, which DMA channels.
   The build log says it: `synthesized from the routing IR: 4 x 4 mesh, A strips 2 x B strips 8, 60 tiles / core,
   K chunks 20, A ring 2 over 4 column(s), 2 readers per stream, B per launch, host rows A[0, 3] B[1, 2]`.
2. **The plan joins the hop graph** (`planpaths.cpp`): every route is a `dmaphop.create_hop` and each stream one
   `dmaphop.create_path` carrying the stream as `#dmaphop.stream`. A's first two routes in column 1:

```mlir
%12 = dmaphop.tile{TILETYPE = "shim", col = 1, row = 0}
%13 = dmaphop.port @plan0_r0_src on %12 { direction = "Out", direction_channel = 1 }     // shim MM2S 1
%14 = dmaphop.tile{TILETYPE = "mem", col = 1, row = 2}
%15 = dmaphop.port @plan0_r0_d0 on %14 { direction = "In", direction_channel = 0 }      // MemTile S2MM 0
%16 = dmaphop.create_hop %13 -> %15 {route = 0 : i64}
%17 = dmaphop.port @plan0_r1_src on %14 { direction = "Out", direction_channel = 0 }    // MemTile MM2S 0
%19 = dmaphop.port @plan0_r1_d0 on %18 { direction = "In", direction_channel = 0 }      // core (1, 3) S2MM 0
%20 = dmaphop.create_hop %17 -> %19 {route = 1 : i64}
%23 = dmaphop.create_hop %17 -> %22 {route = 1 : i64}                                     // core (2, 3)
%26 = dmaphop.create_hop %17 -> %25 {route = 1 : i64}                                     // core (3, 3)
%29 = dmaphop.create_hop %17 -> %28 {route = 1 : i64}                                     // core (4, 3)
...
%76 = dmaphop.create_path[%16, %20, %23, %26, %29, ...] {producers = [[@plan0_r0_src, @plan0_r1_src, ...]], ...}
        {stream = #dmaphop.stream<arg = 0, role = "a", share = "neighbor", channel = 0, stage = "memtile_ring",
                  ring = 2, resident = false, chunk = [64, 128], tensor = [7680, 2560], chunks = 20, rounds = 60,
                  host_rows = [0, 3], first_rows = [0, 2], channels = 2, slots = 2, readers = 2, parts = 1, ...>}
```

Read it as chapter 1's hops: shim (1, 0) channel 1 -> MemTile (1, 2) channel 0 (route 0), and that MemTile's MM2S
0 multicast to the four cores of mesh row 0 (route 1). Same vocabulary as the generated flows -- tiles, ports with
DMA channels, hops, a path -- plus the stream: the chunk geometry, the protocol (`channels / slots / readers /
parts`: the host core receives chunk g on S2MM channel g mod 2 into one of 2 x 2 slots, 2 cores read it) and the
layout (`host_rows`, `row_groups`, `strips`). The `route = i` on each hop keeps the router's order.

The plan header stays next to the paths (`dmaphop.plan {bd_once = true, persistent = false, replace_args = [0, 1],
share_args = [0, 1]}`), and the generated flows of A and B are still there, tagged `dmaphop.plan_replaced`: their
core end is the kernel's window (the kernel signature) and its memory, which the plan's chunk slots reuse; their
shim end is not programmed. (Removing that remainder is the open stage 2 of `doc/plan/dataflowplan_unify_ir.md`.)

**Routing.** The routing path takes the plan paths out of its dmaphop clone before the generated-flow conversion
(`takeDataflowPlanRoutes`) and routes their hops after it with the plan router (`planroutes.cpp`) -- in
`routing.cc` they are ordinary stream-switch connections, like every other flow.

## dfscheblueprint: the whole plan, typed

The blueprint lowers the generated flows as in chapter 1 and then carries the plan: each shared tensor's
`declare_data` gets its stream, the module the routes and the plan-wide facts
(`6_DmaphopTodfscheblueprintPass.mlir`; `26_DataflowPlanReadback(dfscheblueprint).mlir` adds the assigned
resources):

```mlir
module attributes {dfscheblueprint.plan_args = array<i64: 0, 1>, dfscheblueprint.plan_bd_once = true,
  dfscheblueprint.plan_mesh = array<i64: 1, ...>, dfscheblueprint.plan_persistent = false,
  dfscheblueprint.plan_routes = [#dmaphop.route<arg = 0, src = [1, 0, 1], src_shim = true, dsts = [1, 2, 0]>,
                                 #dmaphop.route<arg = 0, src = [1, 2, 0], src_shim = false,
                                                dsts = [1, 3, 0, 2, 3, 0, 3, 3, 0, 4, 3, 0]>, ...], ...}
  %1 = dfscheblueprint.declare_data %0 : tensor<7680x2560xi8> {dfscheblueprint.plan_stream =
         #dmaphop.stream<arg = 0, role = "a", share = "neighbor", channel = 0, stage = "memtile_ring", ring = 2, ...>}
```

The pipeline reads the plan back from here (`planFromBlueprint`), checks it is the dmaphop plan and derives the DMA
program from it: below dmaphop, the blueprint is the single description of every transfer of the build.

## dfschedule: a tile-local DMA program

The plan's program is not "shim BD per round": every tile programs a chain of BDs on locks, once. The host module
gets the MemTile part (`14_DataflowPlanToDfschedule.mlir`: 36 `config.tile_bd`, 16 `config.lock_set`, 28
`config.channel_enable`, 28 `config.channel_start`), the kernel module the core part on `declaretile.self`
(`23_DataflowPlanToDfschedule(kernel).mlir`: the core's own BDs, locks and S2MM starts, in its
KERNELCONFIGOFFLOAD block):

```mlir
// MemTile (1, 2), A's ring: S2MM writes a 16 KB buffer, MM2S sends it on, locks 64 / 65 hand it over
dfschedule.config.tile_bd(%27) {addr = 524288 : i64, bd_id = 0 : i32, len = 16384 : i32, next_bd = 1 : i32,
    acquire_lock_id = 64 : i32, acquire_lock_val = -1 : i32, release_lock_id = 65 : i32, release_lock_val = 1 : i32,
    dfplan.tag = "mem/0/0/in/0"}
dfschedule.config.lock_set(%27) {lock_id = 0 : i32, value = 2 : i32, restored = true, dfplan.tag = "mem/0/0/lock/0"}
dfschedule.config.channel_start(%27) {channel = 0 : i32, direction = "S2MM", repeat_count = 150 : i32, start_bd = 0 : i32}
// a core: chunk slots in its own memory, released to its 2 readers (acquire -2)
%0 = dfschedule.declaretile.self
dfschedule.config.tile_bd(%0) {addr = 491520 : i64, bd_id = 0 : i32, len = 8192 : i32, next_bd = 1 : i32,
    acquire_lock_id = 0 : i32, acquire_lock_val = -2 : i32, dim_strides = [4, 512, 32768], dim_wraps = [128, 16, 0], ...}
dfschedule.config.channel_start(%0) {channel = 0 : i32, direction = "S2MM", start_bd = 0 : i32}
```

Every id and address (BD 0, lock 64, `addr = 524288`) is allocated by `planresource.cpp` against the generated
flows; the `dfplan.tag` names each op so an edited program can be read back (`AIEHLC_DFSCHEDULE_PLAN_IN`). The
shim side stays `config.dma_bd` (one BD per stream and column). The kernel takes its blocks through
`aie_block_io_plan.h`, bound by the generated `aiehlc_plan.h` constants: `load_buffer` on a shared operand is
"acquire my turn lock, point at slot g mod 4", no copy.

## What to remember

| level | chapter 2 -> chapter 3 |
|---|---|
| routing | + `#routing.dataflow` on A and B |
| dmap | unchanged |
| dmaphop | + one plan path per stream: MemTile and multicast hops, `#dmaphop.stream`; the generated A / B flows tagged replaced |
| dfscheblueprint | + the plan, typed (streams on `declare_data`, routes on the module) |
| dfschedule | + a tile-local DMA program (MemTile and core BD chains on locks, started once per launch) |

A and B now arrive at a core from its own column's MemTile, each chunk once for two cores; the host programs a
launch with a handful of shim BDs. The next chapter changes two fields and one switch.
