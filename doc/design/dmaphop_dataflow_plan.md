<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Explicit dataflow plans: C source -> routing IR -> dmaphop (dataflow) -> dfschedule (DMA program) -> code

The 84.5 % int8 GEMM on VEK385 (`example/tileprogram/ccode/gemm_memtile/share2x8.py`,
`doc/performance/gemm_e2e_progress.md`) was reached by **rewriting the generated `host.cc`,
`kernel.cc` and `routing.cc`** after every build: MemTile staging, neighbour-shared operands,
a persistent kernel, BDs written once. This design moves that dataflow into the compiler at three
levels; each level generates the one below it, and the same build reaches the same speed from any
of them.

| level | what you write | example |
|---|---|---|
| **C** | `load_buffer` options + `#pragma persistent_kernel` | `example/tileprogram/ccode/gemm_plan/gemm_plan.cc` |
| **routing IR** | `dataflow = {...}` on a tensor's `routingcreatescheduletensor`, `routing.persistent_kernel` | `AIEHLC_ROUTING_IR_IN` |
| **dmaphop IR** | the dataflow decisions: `dmaphop.plan` / `plan_route` / `plan_stream` | `gen_plan.py`, `AIEHLC_DMAPHOP_IR_IN` |
| **dfschedule IR** (derived) | the DMA program: `config.tile_bd` / `lock_set` / `channel_enable` / `channel_start` (MemTiles, cores), `config.dma_bd` + `create_io` + `start_io` (shim), module switches | dumped as `*_DataflowPlanToDfschedule.mlir` |

Measured on vek385-6 (1.25 GHz array), per launch of 10.07 G MAC, GOLDEN PASS (187,758 sampled
outputs) every time:

| build | steady ms | % of peak |
|---|---|---|
| hand edits (reference) | 1.155-1.189 | 82.7-85.1 |
| dmaphop plan | 1.160 (best 1.154) | 84.8 (85.2) |
| routing IR attributes | 1.160 (best 1.154) | 84.7 (85.2) |
| C source alone | 1.158 (best 1.154) | 84.9 (85.2) |
| C source, one `load_buffer` body, DMA program as dfschedule ops (current) | 1.156-1.162 typical (best 1.156) | 84.6-85.0 (85.0) |

## 1. C level

```c++
#pragma persistent_kernel
...
aie::load_buffer(a, off, shape, {.depth = 2, .share = aie::share::neighbor,
                                 .stage = aie::stage::memtile_ring, .ring = 10});
aie::load_buffer(b, off, shape, {.depth = 2, .share = aie::share::neighbor,
                                 .stage = aie::stage::memtile, .keep = true});
```

| option | meaning |
|---|---|
| `.share = aie::share::neighbor` | the stream is held in ONE core's memory; the cores that read it reach it through their own / north / south memory view |
| `.stage = aie::stage::memtile` | staged through a MemTile |
| `.stage = aie::stage::memtile_ring, .ring = N` | a MemTile FIFO ring of N buffers (the first chunks flow after one buffer, not after the whole tile) |
| `.keep = true` | loaded on the first launch only, kept across launches (weight-resident) |
| `#pragma persistent_kernel` | ELF loaded and cores started once; later launches release a go lock |

The options are declared after `.tile` in `aie::load_opts` (designated initializers keep that
order). They are recorded by the trace harness (`kernel_trace.cpp`, event fields after `tile`),
carried as `BlockOpts` -> `KernelBlock` (`tilinglinalg_pipeline.h`) and attached by
`attachTensorRoutingInfo` as the `dataflow` dictionary. `src/aiegraph/kemu.py` mirrors
`load_opts` so such kernels still emulate on x86.

The kernel body reads what the compiler decided from the generated `aiehlc_plan.h`
(`AIEHLC_PLAN_A_VIEW(pm)`, `_A_LOCK`, `_A_FIRST`, `_A_PHASE`, `_SLOT_LO`, `_LOCK_F`, ...,
`AIEHLC_PLAN_PERSISTENT`, `AIEHLC_PLAN_GO_LOCK`); include it in the kernel prologue
(`// AIEHLC_KERNEL_PROLOGUE_BEGIN ... #include "aiehlc_plan.h"`), under `__chess__`.

### One kernel body, no `#if defined(__chess__)` (2026-11-23, later)

`gemm_plan.cc`'s kernel is ONE body for the core and for the x86 trace: every operand block comes from
`aie::load_buffer`, every output tile goes out through `aie::store_buffer`, with the TRUE 2 x 8 offsets
(`sa = pm >> 1`, `sb = pn + 4 (pm & 1)`). `gemm_plan_tile.h` is compute macros only. What made it work:

| piece | where |
|---|---|
| `.parts = n` -> `block.part(i)`: the block's row parts (the plan puts them in different DM banks) | harness / kemu `AnyPtr`, `aie_block_io.h`, plan `aiehlc_share_block` |
| `.align = N`: the port's core buffers N-aligned (64-byte `load_v` / `store_v` on a window) | harness / kemu allocation, `block_align` attr -> `flowtransfer_kernel.cpp` allocator |
| kernel analysis accepts blocks affine in the shared-operand grid (p0 / 2, p1 + C (p0 % 2)) when a port has `.share`; the true fit checks the core (`aiehlc_blk_desc.remap_cols`), an equivalent R x C tiling feeds the routing derivation | `kernel_trace.cpp remapSharedGrid`, `trace_routing.cpp` |
| a shared port's `load_buffer` / `release` -> `aiehlc_share_load` / `_release` (lock role, slot rotation, bank-split parts), its state copied to a LOCAL at kernel entry (registers), one `chess_memory_fence()` per run of loads / releases | `resolveBlockIoBuiltins`, `planemit.cpp shareRuntime` |
| `#pragma persistent_kernel` -> `main()` calls the kernel in a go-lock loop | `passdfscheduletokernelapi.cpp` |
| on-core block check off for plan builds (`AIEHLC_BLOCK_CHECK 0`, the analysis proved every block); the check no longer divides | `aie_block_io.h` |
| the trace harness `-I` the source dir (prologue headers), `-O2` (the full compute traces in 53 s) | `kernel_trace.cpp` |

Measured (vek385-6, GOLDEN PASS every run): typical launch 1.160-1.168 ms = 84.4-84.7 % (best 84.79 %),
against 1.153-1.158 ms for the `#if __chess__` version; both see the same occasional 1.20-1.26 ms launch
(board noise). The ~0.5 % left is static: the last-chunk loop 141 vs 139 bundles, the chunk boundary
148 vs ~145.5 (chess unrolled the hand-written chunk loop by 2; unrolling it here overflows the 16 KB
program memory). Steps that mattered: state in registers (77 -> 81 %), the reference's chunk-loop
shape (81 -> 81.8 %), `__restrict` output + division-free check + one fence (-> 84.7 %).

## 2. Routing level

```mlir
module attributes {routing.persistent_kernel = 1 : i64, ...} {
  %A = routing.routingcreatescheduletensor ... {dataflow = {ring = 10 : i64, share = "neighbor",
                                                 stage = "memtile_ring"}, kernel_block = ...}
  %B = routing.routingcreatescheduletensor ... {dataflow = {resident = "launches", share = "neighbor",
                                                 stage = "memtile"}, kernel_block = ...}
```

`routing.persistent_kernel` is a control switch (module attribute); the per-tensor intent is on
the tensor's op, as `routing_ir_tiling_carriers.md` requires. The attributes survive to the dmaphop
IR, where **plan synthesis** (`pass/dataflowplan/plansynth.cpp`, after `DmapToDmaphopPass`) turns
them into the dmaphop plan (header, routes, streams -- section 3; dump `ir/dfschedule/4_DataflowPlan.mlir`),
and `deriveDmaProgram` turns the streams into the dfschedule DMA program (section 4). What the two decide:

* **Logical grid.** `share = "neighbor"` on the two GEMM operands means the R x C mesh computes a
  (R/2) x (2C) grid: core (pm, pn) takes A strip pm / 2 and B strip pn + C (pm % 2). Every operand
  stream then has two consumers in one column.
* **Host-tile matching.** Per column, each stream gets one host core within one row of both
  consumers, one stream per core (backtracking matching; 4 x 4: A0 -> row 0, B_c -> 1,
  B_{c+4} -> 2, A1 -> 3).
* **Views and roles** (dfschedule / kernel side). A consumer reads its stream through `own` (0x70000, locks 48..), `north`
  (0x60000, 32..) or `south` (0x40000, 0..). The lower consumer reads first and hands the buffer on;
  the two walk its halves in opposite phase (bank conflicts).
* **Hosted buffers** (dfschedule). 2 channels x 2 slots of one chunk at the top 32 KB of the host's memory, each
  chunk split over two DM banks; locks per channel F (DMA -> first reader), G (first -> second),
  E per slot (both readers -> DMA, acquired -2).
* **MemTiles** (routes: dmaphop; BDs / locks / channels: dfschedule). A: top MemTile row, a FIFO ring (counting locks), column c carries strip c / 2,
  chunk parity c % 2, broadcast to the strip's host row. B: bottom MemTile row, strips c and c + C,
  4 MM2S channels replay them; `resident = "launches"` loads B on the first launch only.
* **Shim** (dfschedule). One BD per stream (A ch 1, B ch 0), the DDR layout one contiguous stream per column
  (the host app arranges it, `sh_arrange` in `gemm_plan.cc`).

Limits (errors name them): exactly two shared operands, mesh rows = 2 x A strips and mesh columns =
2 x A strips (4 x 4), N = 2C block rows (one n tile per core), output tiles per core = M / (R/2) /
block rows <= 64, K / chunk even, the ring must divide one strip's stream.

## 3. dmaphop level: the dataflow decisions

Attribute-only ops (`assemblyFormat = "attr-dict"`, `td/dmaphopop.td`), read and validated by
`collectDataflowPlan` (`pass/dataflowplan/dataflowplan.cpp`) with errors at the op's location.
Columns are partition-relative, rows absolute; `host_rows` / `first_rows` are mesh rows.

```mlir
dmaphop.plan {replace_args = [0, 1], share_args = [0, 1], persistent_go_lock = 14, bd_once = true}
dmaphop.plan_route {src = [1, 0, 1], src_kind = "shim", dsts = [[1, 2, 1]]}
dmaphop.plan_route {src = [1, 2, 1], src_kind = "dma", dsts = [[1, 3, 0], [2, 3, 0], [3, 3, 0], [4, 3, 0]]}
dmaphop.plan_stream {arg = 0, role = "a", share = "neighbor", stage = "memtile_ring", ring = 10, resident = "launch",
                     chunk = [64, 128], chunks = 20, rounds = 60, tensor = [7680, 2560], host_rows = [0, 3], first_rows = [0, 2]}
dmaphop.plan_stream {arg = 1, role = "b", share = "neighbor", stage = "memtile", resident = "launches",
                     chunk = [64, 128], chunks = 20, rounds = 60, tensor = [512, 2560], host_rows = [1, 2], first_rows = [0, 1]}
```

Edit a stream (e.g. `ring = 8`) and the DMA program follows; nothing BD-level is written here.

## 4. dfschedule level: the DMA program (derived)

`deriveDmaProgram` (`plandma.cpp`) turns the streams into locks, BDs, channels, shim transfers and
the kernel constants; `materializeHostPlan` / `materializeKernelPlan` write them as dfschedule ops,
dumped as `ir/dfschedule/NN_DataflowPlanToDfschedule.mlir` and `..(kernel).mlir`:

| op | where | lowered by | to |
|---|---|---|---|
| `config.tile_bd` (local address, byte strides, hw lock ids: MemTile own locks 64..) | host (MemTiles), kernel (cores, `declaretile.self`) | DfscheduleToApi / DfscheduleToKernelApi | `__Runtime_tile_bd_config` / `aie_kc_encode_bd_nd` |
| `config.lock_set {value, later_value}` | host, kernel | same | `__Runtime_tile_lock_set` / `aie_kc_encode_lock` |
| `config.channel_enable` | host | DfscheduleToApi | `__Runtime_dma_channel_enable` |
| `config.channel_start {repeat_count, first_launch_only}` | host, kernel | same | `__Runtime_dma_channel_start` / `aie_kc_encode_s2mm_start` |
| `config.dma_bd` + `config.create_io` + `schedule.start_io` (+ `dfschedule.first_launch_only`) + `schedule.wait` | host (shim) | DfscheduleToApi | `__Runtime_dma_bd_config_multidim_ooo`, `__Runtime_startio(_first)` |
| module `dfschedule.plan_bd_once` / `dfschedule.plan_go_lock` | host, kernel | LoadKernelGroup lowering / kernel main | `__Runtime_plan_setup(..)` before the load; `for (;;) { acquire(go); kernel(); }` |

Runtime: `__Runtime_plan_setup` counts launches (first-launch-only starts, `later_value` locks);
under BD write-once the tile program is written on the first launch only (constant time) and
identical shim / ooo-channel rewrites are skipped; a first-launch-only `start_io` returns an event
`__Runtime_wait_io` skips. A persistent kernel is loaded and started once; later launches set
every core's go lock.

### What else the compiler does with a plan

| where | what |
|---|---|
| `collectDataflowPlan` (after the dmaphop stage) | validates, derives the DMA program, tags every `create_path` / `push` of a replaced argument `dmaphop.plan_replaced`, erases the plan ops, publishes `dfplan::activePlan()` |
| `DmaphopToRoutinghwPass` | no generated stream route for a tagged path |
| `BlueprintToSchedulePass` (host) | for a replaced argument: core buffers / windows kept (the kernel signature is unchanged), no shim BD / create_io / start_io / wait; `resolveKernelBlock` skips its window check |
| `ScheduleCanonicalizePass` | `host_canonicalized` keeps every memref argument (the plan's shim transfers read them) |
| routing.cc | `aiehlc_plan_routing()` -- BFS over the AIE2PS port model around the ports the generated routes took (`routingresourcemap.json`) and the control-packet row fabric; MemTile SOUTH/NORTH lanes kept tied (skill memtilepassthroughlane) |
| kernel.cc | the KCO input blocks on core S2MM channels the plan's `channel_start` ops own are dropped |
| aiehlc_plan.h | the shared ports' kernel side (`aiehlc_share_load` / `_release`, per-core init) and `AIEHLC_PLAN_*` constants |
| flowcheck | replaced flows are listed; every `plan_route` is simulated through routing.cc (`plan_routes` in `dmaphopprovenacemap.json`) |

A build with no plan is byte-identical to before; the C-level and dmaphop-level builds of
`gemm_plan.cc` generate byte-identical host.cc / kernel.cc / routing.cc / bcf; the routing and
dmaphop IR round trips stay byte-identical (`script/test/routing_ir_roundtrip.sh`).

## 5. Traps

* **The kernel must agree with the plan's protocol.** The plan programs DMA, locks and buffers; the
  kernel body acquires / releases those locks and reads those buffers. `gemm_plan_tile.h` takes
  every offset and lock id from `aiehlc_plan.h`; a kernel with literals silently breaks when the plan
  changes.
* **A build without a plan cannot compile the kernel** (`aiehlc_plan.h` missing). Intended: the
  kernel needs the plan.
* **Host BD ids.** Plan shim BDs (14, 15) must not collide with the generated output BDs (2..11 here);
  check `host.cc` after changing the shape.
* **The replaced inputs' core buffers stay allocated** (`buf_in_*` at 0x78000..0x7FFFF) and the
  hosted streams reuse exactly that range -- the window buffers are never touched by the plan
  kernel. A layout with fewer / smaller input windows must move the hosted region.
* **Persistent + KCO**: the plan's core block runs once at kernel start; locks the kernel needs at
  every launch must be re-armed by the kernel itself (go lock).
