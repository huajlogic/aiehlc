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
| **routing IR** | `#routing.dataflow<...>` (typed: share, stage, ring, keep, parts, axis, per-core bases) on a tensor's `routingcreatescheduletensor`, `routing.persistent_kernel` | `AIEHLC_ROUTING_IR_IN` |
| **dmaphop IR** | the dataflow decisions: per stream a `create_path` with `#dmaphop.stream`, its routes as `create_hop`s; `dmaphop.plan` header (input also as `plan_route` / `plan_stream` ops) | `gen_plan.py`, `AIEHLC_DMAPHOP_IR_IN` |
| **dfschedule IR** (derived) | the DMA program: `config.tile_bd` / `lock_set` / `channel_enable` / `channel_start` (MemTiles, cores), `config.dma_bd` + `create_io` + `start_io` (shim), module switches | dumped as `*_DataflowPlanToDfschedule.mlir` |

Measured on vek385-6 (1.25 GHz array), per launch of 10.07 G MAC, GOLDEN PASS (187,758 sampled
outputs) every time:

| build | steady ms | % of peak |
|---|---|---|
| hand edits (reference) | 1.155-1.189 | 82.7-85.1 |
| dmaphop plan | 1.160 (best 1.154) | 84.8 (85.2) |
| routing IR attributes | 1.160 (best 1.154) | 84.7 (85.2) |
| C source alone | 1.158 (best 1.154) | 84.9 (85.2) |
| C source, one `load_buffer` body, DMA program as dfschedule ops | 1.156-1.162 typical (best 1.156) | 84.6-85.0 (85.0) |
| + resources allocated, device table, inlined plan runtime with tile sync | 1.147-1.153, every launch (mean 1.150) | 85.3-85.7 (mean 85.5) |
| + routes through routinghw, protocol from the IR, readback (current) | 1.150-1.151 mean | 85.4-85.5 |
| same plan code on a **4 x 2** mesh (`gemm_plan_4x2.cc`, 8 cores, 5.03 G MAC) | 1.136 mean | 86.5 |

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

The kernel body is a plain block-load kernel; it never names a lock, a view or an address. The
compiler binds its block calls on the shared ports to the plan (section 4, "Kernel side").

### Shape, dtype and tiling at build time: `--define`, `#pragma gemm_autotile`

`gemm_plan_body.cc` takes its problem as macros (`GP_M` / `GP_N` / `GP_K` / `GP_DTYPE`, defaults
7680 / 512 / 2560 / int8) and derives every count from them. A macro must reach every stage that
reads the source -- the front end's macro scan, the x86 kernel trace, the dataflow plan, the kernel and
host compiles -- or the kernel is built for one shape and the host for another. `aiehlc.sh --define
NAME=VALUE` (or `AIEHLC_DEFINES="-DNAME=VALUE ..."`) does that: aiehlc writes the macros as `#define`
lines at the top of the source text (`injectUserDefines`, then `#line 1`), before the includes are
spliced, so a body's `#ifndef NAME` default yields and `kernel.cc`, `host.cc` and the KOBJ cache key
all follow. `EXTRA_DEFS` stays host-only and is refused for a macro the source uses.

`#pragma gemm_autotile[(board)]` (`gemm_plan_auto.cc`) lets the compiler pick the tiling the 2 x 8
kernel leaves open: the mesh (rows x columns: N = 2 x columns x 64 fixes the columns; rows must be 4 so
A's and B's reader counts match) and A's MemTile ring (deepest <= 10 dividing the chunk stream). A mesh
must also fit the packet ids (every packet-switched output core takes one of 27 on aie2ps: columns <= 6)
and the 32-core kernel load. `src/llvm/convautotile/gemm_autotile.cpp`
ranks every feasible choice by max(cores, shim channels, DDR) + launch: cores = tiles x K chunks x
cycles per chunk (int8 1188 measured, bf16 calibrated on the board), shim = the busiest channel's bytes
at the board's per-channel rate (B re-read per output tile when it cannot be held), DDR = reads /
writes at the board's rates (VEK385_2: one controller, no overlap; VEK385: 24 GB/s aggregate read, fitted
on the B-re-read runs). Measured on 8 shapes (doc/plan/dataflowplan_generalize.md stage 4): within
+-13 %. Board facts: `vek385`, `palmyra`
(`#pragma gemm_autotile(palmyra)` or `AIEHLC_GEMM_BOARD`); device facts: `plantarget.h`. It writes
`GP_HW_ROWS` / `GP_HW_COLS` / `GP_RING` the same way as `--define`, except those the source sets itself,
and prints the ranking (`[GemmAutoTile] ...`, predicted ms and % of peak per candidate). The K chunk
(64 x 128 B) and the 64 x 64 output tile are the kernel's and not searched.

### One kernel body, no `#if defined(__chess__)` (2026-11-23, later)

`gemm_plan.cc`'s kernel is ONE body for the core and for the x86 trace: every operand block comes from
`aie::load_buffer`, every output tile goes out through `aie::store_buffer`, with the TRUE 2 x 8 offsets
(`sa = pm >> 1`, `sb = pn + 4 (pm & 1)`). `gemm_plan_tile.h` is compute macros only. What made it work:

| piece | where |
|---|---|
| `.parts = n` -> `block.part(i)`: the block's row parts (the plan puts them in different DM banks) | harness / kemu `AnyPtr`, `aie_block_io.h`, plan `aiehlc_share_block` |
| `.align = N`: the port's core buffers N-aligned (64-byte `load_v` / `store_v` on a window) | harness / kemu allocation, `block_align` attr -> `flowtransfer_kernel.cpp` allocator |
| kernel analysis accepts blocks affine in the shared-operand grid (p0 / 2, p1 + C (p0 % 2)) when a port has `.share`; the true fit checks the core (`aiehlc_blk_desc.remap_cols`), an equivalent R x C tiling feeds the routing derivation | `kernel_trace.cpp remapSharedGrid`, `trace_routing.cpp` |
| a shared port's block calls served by the plan: `aie_block_io_plan.h` (always_inline), operand chosen by descriptor (`aiehlc_plan_operand`), cursors as locals (registers) | `aie_block_io_plan.h`, `resolveBlockIoBuiltins`, `bindPlanSharedOperands` |
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
  %A = routing.routingcreatescheduletensor ... {dataflow = #routing.dataflow<share = "neighbor",
         stage = "memtile_ring", ring = 10, keep = false, parts = 2, axis = "", base_p0 = [], base_p1 = []>,
         kernel_block = ...}
  %B = routing.routingcreatescheduletensor ... {dataflow = #routing.dataflow<share = "neighbor",
         stage = "memtile", ring = 0, keep = true, parts = 2, axis = "", base_p0 = [], base_p1 = []>, ...}
```

`routing.persistent_kernel` is a control switch (module attribute); the per-tensor intent is on
the tensor's op, as `routing_ir_tiling_carriers.md` requires. The attributes survive to the dmaphop
IR, where **plan synthesis** (`pass/dataflowplan/plansynth.cpp`, after `DmapToDmaphopPass`) turns
them into the dmaphop plan (header, routes, streams -- section 3; dump `ir/dfschedule/4_DataflowPlan.mlir`),
and `deriveDmaProgram` turns the streams into the dfschedule DMA program (section 4). What the two decide:

* **Logical grid.** `share = "neighbor"` on the two GEMM operands means the R x C mesh computes a
  (R/2) x (2C) grid: core (pm, pn) takes A strip pm / 2 and B strip pn + C (pm % 2) (the grid the
  kernel analysis recognizes, `kernel_trace.cpp remapSharedGrid`). A strip's readers are its row pair, a
  B strip's the rows of one parity; the synthesis writes the grid into the plan (`row_groups`,
  `strips`) and the reader count (`readers`) -- every stream must have the same, since every core runs
  one hosted-stream program (so R = 4 on a 4-row array: 2 readers each).
* **Host-tile matching.** Per column, each stream gets one host core within one row of both
  consumers, one stream per core (backtracking matching; 4 x 4: A0 -> row 0, B_c -> 1,
  B_{c+4} -> 2, A1 -> 3).
* **Views and roles** (dfschedule / kernel side). A consumer reads its stream through its own, north
  or south memory view (addresses and lock-id biases from `plantarget.h`). The lower consumer reads
  first and hands the buffer on; the two walk its halves in opposite phase (bank conflicts).
* **Hosted buffers** (dfschedule). 2 channels x 2 slots of one chunk in the memory the allocator gave
  the replaced ports' windows, each chunk split in two parts (different DM banks); locks per channel
  F (DMA -> first reader), G (first -> second), a no-op pair, E per buffer (both readers -> DMA,
  acquired -2), plus a go and a tile-sync lock -- ids allocated (section 4).
* **MemTiles** (routes: dmaphop; BDs / locks / channels: dfschedule). A: top MemTile row, a FIFO
  ring per (strip, parity set): with C >= 2 x strips each column serves one parity of one strip (4 x 4:
  column c = strip c / 2, parity c % 2); with fewer columns a column serves a strip's every parity
  (4 x 2) -- one MM2S channel per parity and an (empty, full) lock pair each; broadcast to the strip's
  host row in every column. B: the next MemTile row, a column's strips held whole, one MM2S replay per
  (strip group, parity); `resident = "launches"` loads B on the first launch only. **B's staging follows
  the MemTile capacity** (`plantarget.h` `memBytes`): when a column's strips do not fit next to what
  else that MemTile holds (bf16 4096 x 512 x 4096: 1 MiB), B becomes a `memtile_ring` too -- one S2MM
  chain over every (strip group, parity) buffer, chunk n to MM2S route n % k, re-read from DDR for every
  output tile (the shim BD's iteration step is 0, `aiehlc_plan_arrange` lays one round out); the build
  prints `[DataflowPlan] stream N: ... streamed as memtile_ring R`. Its ring is the shallowest (from
  `.ring`, default 2) that divides the column's chunk stream and keeps every channel start at or below
  `chMaxRepeat` (256, the task queue's repeat count; any channel above it is a build error). `.stage =
  aie::stage::memtile_ring` on B forces the ring. MemTile channels
  are chosen so each channel's BD bank holds its chain; shim MM2S channels and MemTile rows go to the
  streams top-down. `role` is a label; the layout is `row_groups` / `strips` (`"a"` / `"b"` only give
  their defaults to plans written without them).
* **Shim** (dfschedule). One BD per stream and column on the channel its `plan_route` names; the DDR
  layout is one contiguous chunk stream per column, the columns one after the other -- generated into
  `aiehlc_plan.h` as `aiehlc_plan_arrange(arg, src, dst)` from the same streams and routes, which the
  host calls (`gemm_plan.cc`; byte-identical to the former hand-written `sh_arrange` on 4 x 4).

**Core data memory** (`planresource.cpp` `planCoreMemory`). The plan counts one core's 64 KiB: the
windows the allocator placed (incl. the replaced ports' windows, which the plan owns), a minimum stack
(`coreMinStack`, kc.sh's 4 KiB relink) and the kernel's other statics (`coreStaticReserve`), and the
GEMM's K accumulator (A chunk rows x B chunk rows x 4 B -- int32 / fp32 partial sums kept across the K
chunks). Fits: the kernel keeps its own (`[DataflowPlan] core memory: ... the kernel's own`, generated
files unchanged). Does not fit (bf16: the output windows are twice the int8 ones): the plan makes room in
the memory it owns -- one chunk slot per channel instead of `slots` -- and places the accumulator after
the slots, `AIEHLC_PLAN_ACC` (core address) / `AIEHLC_PLAN_ACC_BYTES` / `AIEHLC_PLAN_DM_FREE` in
`aiehlc_plan.h`; the kernel uses it when defined (`gemm_plan_body.cc` bf16: `facc`). Still short: a build
error naming the accumulator and the bytes missing.

Limits (errors name them): two shared operands (A ring, B resident or ring), every stream the same reader
count (4 mesh rows), columns >= A strips, N = 2C block rows (one n tile per core), output tiles per
core <= the shim BD's iteration limit (64), K / chunk a multiple of `channels`, the ring must divide
each column's chunk stream, every MemTile chain must fit its channel's BD bank.

## 3. dmaphop level: the dataflow decisions

**In the hop graph (2026-11-26, `doc/plan/dataflowplan_unify_ir.md` stages 3-4).** After the plan step the
plan's data movement is ordinary dmaphop: per stream ONE `dmaphop.create_path` carrying the stream as a typed
`#dmaphop.stream<...>` (every field below), whose `dmaphop.create_hop` ops are the plan's routes -- the source
`dmaphop.port` is the route's MM2S channel (`direction_channel`) on a `shim` / `mem` / `core` `dmaphop.tile`, the
destination ports its S2MM channels, `route = i` on each hop keeps the router's order
(`pass/dataflowplan/planpaths.cpp`). The `dmaphop.plan` header (replaced / shared args, persistent, BD
write-once) and `dmaphop.plan_resources` stay: they are plan-wide facts, not data movement.

```mlir
%t = dmaphop.tile {TILETYPE = "shim", col = 1, row = 0} -> !dmaphop.tile
%s = "dmaphop.port"(%t) {direction = "Out", direction_channel = 1 : i64, sym_name = "plan0_r0_src"} : ...
%d = "dmaphop.port"(%m) {direction = "In", direction_channel = 0 : i64, sym_name = "plan0_r0_d0"} : ...
%h = dmaphop.create_hop %s -> %d {route = 0 : i64} -> !dmaphop.hop
...
%p = dmaphop.create_path [%h, ...] {producers = [@plan0_r0_src, ...], consumers = [@plan0_r0_d0, ...],
       tee_points = []} {stream = #dmaphop.stream<arg = 0, role = "a", share = "neighbor", channel = 0,
       stage = "memtile_ring", ring = 10, resident = false, chunk = [64, 128], tensor = [7680, 2560], chunks = 20,
       rounds = 60, host_rows = [0, 3], first_rows = [0, 2], channels = 2, slots = 2, readers = 2, parts = 2, ...>}
```

`collectDataflowPlan` reads either form -- these paths (this compiler's dumps, re-enterable with
`AIEHLC_DMAPHOP_IR_IN`) or the attribute-only `plan_route` / `plan_stream` ops below (`plansynth.cpp`'s
output, `gen_plan.py`, older dumps) -- validates it and writes the paths; DmaphopToRoutinghwPass takes the routes
from the paths' hops (`takeDataflowPlanRoutes`) before the generated-flow conversion and routes them after it.
The generated flow of a replaced argument is still emitted and tagged `dmaphop.plan_replaced` (its core end is the
kernel's window; stage 2 of the unify plan).

The attribute-only input form (`assemblyFormat = "attr-dict"`, `td/dmaphopop.td`), read and validated by
`collectDataflowPlan` (`pass/dataflowplan/dataflowplan.cpp`) with errors at the op's location.
Columns are partition-relative, rows absolute; `host_rows` / `first_rows` are mesh rows.

```mlir
dmaphop.plan {replace_args = [0, 1], share_args = [0, 1], persistent = true, bd_once = true}
dmaphop.plan_route {arg = 0, src = [1, 0, 1], src_kind = "shim", dsts = [[1, 2, 1]]}
dmaphop.plan_route {arg = 0, src = [1, 2, 1], src_kind = "dma", dsts = [[1, 3, 0], [2, 3, 0], [3, 3, 0], [4, 3, 0]]}
dmaphop.plan_stream {arg = 0, role = "a", share = "neighbor", stage = "memtile_ring", ring = 10, resident = "launch",
                     chunk = [64, 128], chunks = 20, rounds = 60, tensor = [7680, 2560], host_rows = [0, 3], first_rows = [0, 2],
                     row_groups = [0, 0, 1, 1], strips = [0, 1, 0, 1, 0, 1, 0, 1],
                     channels = 2, slots = 2, readers = 2, parts = 2, elem_bytes = 1}
dmaphop.plan_stream {arg = 1, role = "b", ..., row_groups = [0, 1, 0, 1], strips = [0, 4, 1, 5, 2, 6, 3, 7], ...}
dmaphop.plan_resources {...}   // optional: pinned resources (the readback writes it, section 4)
```

The hosted-stream **protocol** is IR, not constants: `channels` (core S2MM channels, chunk g on
g mod channels -- the target's core S2MM count), `slots` (buffers per channel -- the kernel's
`{.depth}`), `readers` (cores reading each chunk), `parts` (the kernel's `{.parts}`), `elem_bytes`.
The derivation sizes the core lock block ((readers + 1) x channels reader / no-op locks, channels x
slots E locks), the BDs and the slot region from them, and `aie_block_io_plan.h` reads them back as
`AIEHLC_PLAN_CHANNELS / SLOTS / BUFFERS / READERS` (masks fold for powers of two).

Edit a stream (e.g. `ring = 8`) and the DMA program follows; nothing BD-level is written here. Every
route names the stream it carries (`arg`); the derivation takes each stream's channels, MemTiles and
replay targets from its routes. (`persistent_go_lock = N` from older plans still reads as
`persistent = true`; the go lock is allocated.)

## 3b. dfscheblueprint level: the plan the DMA program is derived from

`DmaphopTodfscheblueprintPass` lowers the generated flows (the replaced ones too: their core end is the
kernel's window); `annotateBlueprint` then writes the whole plan onto the blueprint, typed: each shared
tensor's `declare_data` gets `dfscheblueprint.plan_stream = #dmaphop.stream<...>`, the module
`dfscheblueprint.plan_routes = [#dmaphop.route<arg = 0, src = [1, 0, 1], src_shim = true, dsts = [1, 2, 1]>, ...]`
(router order), `plan_args`, `plan_share_args`, `plan_persistent`, `plan_bd_once`, `plan_mesh = [col_lo,
mesh_cols, mesh_rows, core_row_base, memtile_rows]` and, when resources were pinned, `plan_pinned`. The
pipeline reads the plan back from there (`planFromBlueprint`, `planreadback.cpp`), checks it equals the
dmaphop plan (`samePlanDataflow`) and derives the DMA program from it -- the blueprint IR alone describes
every transfer of a plan build.

## 4. dfschedule level: the DMA program (derived)

### Resources: allocated, never written down

`assignPlanResources` (`planresource.cpp`, at the start of `materializeHostPlan`, before the plan's own
ops exist) collects what the generated flows use -- `config.dma_bd` / `create_io` in the host module
(BD ids, lock ids, channels per tile), `ResourceMgr::coreOffloadPlan` (the cores' self-programmed
DMA; entries of a replaced argument are skipped) and the control plane's runtime shim BDs -- and
allocates against the device limits of
`plantarget.h`:

| resource | rule |
|---|---|
| core BDs | two chained pairs, the same ids on every core (one ELF) |
| core locks | F / G / no-op: three pairs `handDelta` (2) apart; E: four in a row; go; sync |
| chunk slots | the core memory the allocator gave the replaced ports' windows (`CoreMemSlot.ownerId` = kernel arg): must be contiguous and hold 4 chunks, else an error |
| MemTile | per stream: 2 locks, BDs in the bank of each channel (`memBdBank`), memory bump-allocated with a capacity check; a MemTile with a generated flow is refused |
| shim | one free BD per stream and column, from the top |

The log line `[DataflowPlan] resources (aie2ps): ...` prints the choice. `plantarget.h` is the one
place for device facts: lock / BD / channel counts, MemTile BD banks, memory views and lock-id biases,
BD word size and **per-tile-kind wrap limits** (8-bit core, 10-bit MemTile / shim -- a wider wrap is
silently truncated by the hardware), iteration limit, shim MM2S -> SOUTH port, switch port counts.

### The program

`deriveDmaProgram` (`plandma.cpp`) turns the streams + routes + resources into locks, BDs, channels,
shim transfers and the kernel constants (BD dimensions from the chunk shape, split to the tile kind's
wrap limit); `materializeHostPlan` / `materializeKernelPlan` write them as dfschedule ops, dumped as
`ir/dfschedule/NN_DataflowPlanToDfschedule.mlir` and `..(kernel).mlir`:

| op | where | lowered by | to |
|---|---|---|---|
| `config.tile_bd` (local address, byte strides, hw lock ids: MemTile own locks 64..) | host (MemTiles), kernel (cores, `declaretile.self`) | DfscheduleToApi / DfscheduleToKernelApi | `__Runtime_tile_bd_config` / `aie_kc_encode_bd_nd` |
| `config.lock_set {value, later_value, restored}` | host, kernel | same | `__Runtime_tile_lock_set(_restored)` / `aie_kc_encode_lock` |
| `config.channel_enable` | host | DfscheduleToApi | `__Runtime_dma_channel_enable` |
| `config.channel_start {repeat_count, first_launch_only}` | host, kernel | same | `__Runtime_dma_channel_start` / `aie_kc_encode_s2mm_start` |
| `config.dma_bd` + `config.create_io` + `schedule.start_io` (+ `dfschedule.first_launch_only`) + `schedule.wait` | host (shim) | DfscheduleToApi | `__Runtime_dma_bd_config_multidim_ooo`, `__Runtime_startio(_first)` |
| module `dfschedule.plan_bd_once` / `dfschedule.plan_go_lock` | host, kernel | LoadKernelGroup lowering / kernel main | `__Runtime_plan_setup(..)` before the load; `for (;;) { acquire(go); kernel(); }` |

`restored` (the MemTile locks): every launch moves the same data through the lock's buffers, so the
lock ends each launch at its start value; it is written on the first launch (and on the second if
`later_value` differs) instead of every launch (~372 ns per MMIO write).
Only the locks of a `.keep` B are `restored`: a non-keep B is sent again every launch and its
lock 1 is never handed back, so it ends at (4, 0) and must be rewritten every launch (`plandma.cpp`
`deriveResident`, `restored = keep`; skill `planmemtilebperlaunch`).

### Kernel side

The generated `aiehlc_plan.h` (constants only: `AIEHLC_PLAN_VIEW(o, pm)` / `_LOCK(o, pm)` /
`_FIRST(o, pm)` as select chains -- a table would be a data-memory load per use -- `_SLOT_*`,
`_PART_STRIDE`, `_LOCK_F/G/E/SYNC`, `_SYNC_OPERAND`, `AIEHLC_PLAN_SHARED`) is included ahead of
`aie_block_io.h`, which then takes `aiehlc_load_buffer` / `_release` / `_store_buffer` / `_commit` from
`src/mlir/runtime/aie_block_io_plan.h`: forced inline (plain `static inline` was emitted as a call,
1.21 vs 1.17 ms), the operand chosen by descriptor (`aiehlc_plan_operand`, generated after the
descriptors), chunk g in buffer `g & 3`, both readers acquire one lock and release the one
`HAND_DELTA` above it (G, or the no-op lock by 0) -- branch-free -- and `x.part(i)` is `PART_STRIDE`
apart. **Tile sync**: at every `commit` the leader of an A stream waits for its follower (one release
and one acquire of the host's sync lock per tile); without it a follower drifting half a chunk behind
read the leader's bank half on every access, 3x the bank conflicts and the occasional 1.20-1.26 ms
launch that had looked like board noise. The pipeline's only text change is generic: block calls get
the port's descriptor, a local cursor copy and the program id.

Runtime: `__Runtime_plan_setup` counts launches (first-launch-only starts, `later_value` locks);
under BD write-once the tile program is written on the first launch only (constant time) and
identical shim / ooo-channel rewrites are skipped; a first-launch-only `start_io` returns an event
`__Runtime_wait_io` skips. A persistent kernel is loaded and started once; later launches set
every core's go lock.

### Readback: dfschedule -> dfscheblueprint / dmaphop

Every op the plan materializes carries its role (`dfplan.tag`: `core/E/<buffer>`, `core/R/<reader>/<ch>`,
`core/go`, `core/sync`, `core/bd/<ch>/<slot>`, `mem/<stream>/<col>/{lock,in,out,ch_in,ch_out}/...`,
`shim/<stream>/<col>`). Every build dumps

| dump | level | what |
|---|---|---|
| `NN_DataflowPlanProgram.mlir` | dfschedule | the plan's DMA program alone (tagged ops on their tiles; a shim transfer as a `config.tile_bd` record) -- the readback input format |
| `NN_DataflowPlanReadback(dfscheblueprint).mlir` | dfscheblueprint | the whole plan, typed: `dfscheblueprint.plan_stream = #dmaphop.stream<...>` on every shared tensor's `declare_data`, `dfscheblueprint.plan_routes = [#dmaphop.route<...>, ...]` + `plan_args` / `plan_share_args` / `plan_persistent` / `plan_bd_once` / `plan_mesh` (/ `plan_pinned`) on the module, and the assigned resources (`plan_resources`). The normal blueprint dump carries the same minus the assigned resources, and the DMA program is derived from what `planFromBlueprint` reads back from it (checked equal to the dmaphop plan) |
| `NN_DataflowPlanReadback(dmaphop).mlir` | dmaphop | the plan ops with `dmaphop.plan_resources` -- re-enterable with `AIEHLC_DMAPHOP_IR_IN` |

`AIEHLC_DFSCHEDULE_PLAN_IN=<edited plan program>` reads an edited program back
(`planreadback.cpp`): resources (core / MemTile / shim BD and lock ids, buffer addresses -- checked
against the generated flows and the device like allocated ones) and ring sizes are lifted, the program
is regenerated from the lifted plan and must equal the edited one; anything the levels above cannot say
(a BD length, a dimension) stops the build with the first such line. Verified: go / sync locks moved
(12 / 13 -> 14 / 15), every A MemTile MM2S chain moved (10.. -> 12..), the A ring buffers moved
(0x80000 -> 0x90000) -> regenerated identically, `aiehlc_plan.h` follows (GO_LOCK 62, LOCK_SYNC 15), the
read-back dmaphop rebuilds byte-identically, board GOLDEN PASS 85.45 %; a changed BD length is
rejected with the line.

### Per-core copies: `.share = broadcast` and per-core streams (`share = "none"`)

Beyond the neighbour-hosted 2 x 8 GEMM, a plan can give every core its own copy of an operand:

| C option | dataflow | stream | example |
|---|---|---|---|
| `{.share = aie::share::broadcast, .stage = ...}`, blocks follow `program_id(0)` only | `share = "broadcast", axis = "row"` | one per mesh row, multicast to the row's cores | `simpleeltwise_add_plan.cc` x / y, `simpleconv2dkernel_port_plan.cc` input (halo blocks) |
| same, blocks follow `program_id(1)` only | `axis = "column"` | one per mesh column, multicast up the column | conv weights (`.stage = memtile, .keep = true`), `simpleeltwise_add_none.cc` y |
| `{.stage = ...}` without `.share` | `share = "none"` + the traced core origin `base_p0` / `base_p1` | one per core: per column one MemTile ring serving its cores (chunk n -> route n % rows) | `simpleeltwise_add_none.cc` x |

The kernel analysis decides the axis from the fit (`BlockOpts.axis`) and refuses a broadcast whose blocks
move with both program ids. Plan synthesis (`plansynth.cpp` `synthCopyText` / `synthPerCore`): operand o on
core S2MM channel o, MemTile row `memRows - o`, shim MM2S channel `last - o` -- so at most 2 such operands
(a core's S2MM channels); a row-broadcast stream is staged in column r (rows <= columns). A stream's blocks
are a 2-D walk (rank 3 / 4 blocks flattened to rows x columns, the trailing dims spanned): `row_step` /
`col_step_i` per round, `row_step_j` / `col_step` per chunk, origin `strip_row_base` / `strip_col_base` per
strip -- overlapping blocks (a conv's halo) are repeated in DDR by `aiehlc_plan_arrange`. Core side
(`deriveCopySlots`, `aie_block_io_plan.h` under `AIEHLC_PLAN_COPY`): per operand its own chain of `slots`
BDs, a counting F lock (DMA -> kernel), an E lock per slot (kernel -> DMA), its slots in that operand's own
replaced windows at the 32-byte-aligned chunk stride (`AIEHLC_PLAN_OP_*(o, pm)` constants); one reader, no
hand-on, no tile sync. Limits: a column carries a bounded number of vertical streams -- two per-core
operands on a 4-row mesh need 8 and the router refuses (`no free path`); a spatial-halo conv's weights need
`{.depth = 2}` (the kernel analysis). Board (VEK385, GOLDEN PASS): eltwise broadcast 0.365 ms per launch
(the same kernel on the generated path: 57 ms and wrong), x per core + y per column 0.213 ms, conv 7x7 s2
224 x 224 0.098 ms (54.2 ms on the generated path).

### Kernels written naturally: what the compiler now derives (2026-11-27)

Writing the Qwen int4 GEMV (`src/APP/qwen/aie/`) needed four workarounds in the kernel and the weight
converter. Each is now the compiler's job; the natural kernel (`w` = `[1024 chunks][8704 B]` read by the
linear core index `c = 4 pm + pn`, `x` loaded whole once, `y` = `[256 row blocks][256 B]`, no `.ring`, no
`output_tile_major`) builds as written and runs bit-exact at the hand-arranged kernel's speed (VEK385:
0.345 ms per launch, 25.9 GB/s of weights, GOLDEN PASS; the hand-arranged kernel 0.348 ms).

| limit | where | now |
|---|---|---|
| a tensor dim may move with only one program id | kernel analysis (`trace_routing.cpp planPort`) | `viewLinearSplit` (`kernel_trace.cpp`): dim 0 split over `c = p0 C + p1` (p0's step = C x p1's, blocks spanning the later dims, loops inside the core's slice) is routed as the same memory viewed `(R, C s rowElems)` -- p0 on dim 0, p1 on dim 1. The routing, `#routing.kernel_block` and the plan see the view; the on-core descriptor keeps the kernel's own blocks (`PortFit::linear_view`, `q_*`). An output gathered this way lands row-major `[pm][pn][u]` without `output_tile_major`. |
| an input unique per core needs `.stage` | kernel analysis (`planRouting`) | such an input with no `.stage` / `.share` / `.resident` gets `.stage = memtile_ring` (note in the report) -- one stream per core |
| `.stage = memtile_ring` needs `.ring`; a single-parity ring needs a multiple of `2 x ring` chunks | analysis; `plandma.cpp` `memtileUse` / `deriveRing` | `.ring` optional: `autoRing` (`plansynth.cpp`) = 2 when a core's chunk count is even, else 1; a single-parity ring whose stream is not a multiple of `2 x ring` uses one-chunk buffers (`MemtileUse::unit`) -- a broadcast x of one chunk per launch works |
| a chunk row wider than a BD wrap | `plandma.cpp` `shimChunkDims` (core / MemTile already split) | the shim walks the arranged (contiguous) chunk as `{1, in} {in, out}` words (`splitWords`) when the row form does not fit |
| the plan's copy must fit the replaced windows | `planresource.cpp assignCopyCores` | the stand-in flow may slice a plan-fed input far finer than its block (x cut into 68 B windows); `flowtransfer_kernel.cpp` then sizes its core buffers from the plan (traced block per buffer, one buffer for one slot) -- only when the windows cannot hold the copy, so existing builds keep their layout |

Each rule fires only where a build used to fail: `script/test/plan_regress.sh` (5 non-plan + 6 plan
examples + the current Qwen library) is byte-identical before / after, `flowcheck: OK` everywhere. Not done:
the shim reading a natural layout in place -- a per-core stream is still laid out by `aiehlc_plan_arrange`
(each column's shim interleaves its cores' chunks), so static weights are arranged once, offline.

### Device facts: one table per target

`plantarget.h` holds every device fact the plan and the flow-transfer helpers use, per target: `aie2ps`
(`--aie-version 5`: VEK385, VEK385_2) and `aie2` (AIE-ML, `--aie-version 2`), selected by the pipeline from the build's
generation (`selectPlanTarget`). Their DMA, lock and memory facts agree; the array differs (36 x 4 vs 38 x 8
core rows) and so do the shim tiles with a DMA: every column on aie2ps, only the NoC shim columns on AIE-ML
(2, 3, 6, 7, 14, 15, ...). A plan whose shim streams leave from a column without one is refused by name
(`the plan streams from the shims of columns 4, 5, which have no DMA on aie2 ...`). On AIE-ML the NoC columns
come in pairs, so the control-packet plane (a column of its own with a shim DMA) does not fit next to them:
`gemm_plan_aie2.cc` puts the 4 x 2 mesh on columns 2, 3 without the control plane, and builds (skill
**aie2planbuild**; the router's AIE-ML core template needed the hardware's 6 NORTH masters / SOUTH slaves). The flow-transfer
helpers' shim wrap (was 1024: one past the 10-bit field) and iteration limits read the same table.

### What else the compiler does with a plan

| where | what |
|---|---|
| `collectDataflowPlan` (after the dmaphop stage) | validates, derives the DMA program, tags every `create_path` / `push` of a replaced argument `dmaphop.plan_replaced`, erases the plan ops, publishes `dfplan::activePlan()` |
| `DmaphopToRoutinghwPass` | no generated stream route for a tagged path |
| `BlueprintToSchedulePass` (host) | for a replaced argument: core buffers / windows kept (the kernel signature is unchanged), no shim BD / create_io / start_io / wait; `resolveKernelBlock` skips its window check |
| `ScheduleCanonicalizePass` | `host_canonicalized` keeps every memref argument (the plan's shim transfers read them) |
| `DmaphopToRoutinghwPass` | the plan paths' hops (kept in the routing clone only, taken out before the generated-flow conversion) lowered to ordinary `routinghw.connectsinglestreamswitchport` / `enableexttoaieshimport` ops (`passdmaphoptoroutinghw/planroutes.cpp`): BFS over the router's own port model (`hwresource.cpp`, the shim's DMA mux ports) around the routinghw ops already created and the control plane's ResourceMgr reservations; MemTile SOUTH/NORTH lanes kept tied (skill memtilepassthroughlane). RoutingHWVerify, the provenance / resource maps, RoutingHWLower and EmitC see them like any route -- no text branch in routing.cc |
| kernel.cc | the KCO input blocks on core S2MM channels the plan's `channel_start` ops own are dropped |
| aiehlc_plan.h | `AIEHLC_PLAN_*` constants for `aie_block_io_plan.h` and the persistent loop |
| flowcheck | replaced flows are listed; every `plan_route` is simulated through routing.cc (`plan_routes` in `dmaphopprovenacemap.json`) |
| `DmapToDmaphopPass` | a flow of a tensor with `dataflow` intent books no shim DMA channel (a stand-in in the target core's column): the plan programs its own shim transfers, and a narrow mesh would otherwise run out of shim channels first |
| runtime | the persistent kernel (load once, go lock later) is one helper for every load / launch variant (4 / 8 / 16 tiles, MMIO or control packets) |

A build with no plan is byte-identical to before; the C-level and dmaphop-level builds of
`gemm_plan.cc` generate byte-identical host.cc / kernel.cc / routing.cc / bcf; the routing and
dmaphop IR round trips stay byte-identical (`script/test/routing_ir_roundtrip.sh`).

## 5. Traps

* **The kernel never names the plan's resources.** Ids and addresses are allocated per build; only
  `aie_block_io_plan.h` reads them (from `aiehlc_plan.h`).
* **A build without a plan cannot compile the kernel** (`aiehlc_plan.h` missing). Intended: the
  kernel needs the plan.
* **BD wrap fields differ per tile kind.** A core BD's dimension wrap is 8 bits; splitting a 4 KB half
  chunk as 512 x 2 words (fine for a MemTile) truncated silently and every output was wrong
  (GOLDEN FAIL 24,728 / 187,758, deterministic). `plantarget.h` has the limit per kind and
  `checkPlanLayout` refuses a chunk that does not fit.
* **Runtime-programmed shim BDs are not in the host IR.** The control plane's BDs
  (`aie_runtime_resource.h`) are added to the used set from the `routing.control_plan_*` switches, the
  same reservation the blueprint lowering makes.
* **Persistent + KCO**: the plan's core block runs once at kernel start; locks the kernel needs at
  every launch must be re-armed by the kernel itself (go lock).
