<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Explicit dataflow plans: from the C source to the dmaphop IR to the generated code

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
| **dmaphop IR** | `dmaphop.plan*` ops (routes, BDs, locks, channels, shim walks, kernel constants) | `gen_plan.py`, `AIEHLC_DMAPHOP_IR_IN` |

Measured on vek385-6 (1.25 GHz array), per launch of 10.07 G MAC, GOLDEN PASS (187,758 sampled
outputs) every time:

| build | steady ms | % of peak |
|---|---|---|
| hand edits (reference) | 1.155-1.189 | 82.7-85.1 |
| dmaphop plan | 1.160 (best 1.154) | 84.8 (85.2) |
| routing IR attributes | 1.160 (best 1.154) | 84.7 (85.2) |
| C source alone | 1.158 (best 1.154) | 84.9 (85.2) |

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
them into plan ops and dumps the result as `ir/dfschedule/4_DataflowPlan.mlir`:

* **Logical grid.** `share = "neighbor"` on the two GEMM operands means the R x C mesh computes a
  (R/2) x (2C) grid: core (pm, pn) takes A strip pm / 2 and B strip pn + C (pm % 2). Every operand
  stream then has two consumers in one column.
* **Host-tile matching.** Per column, each stream gets one host core within one row of both
  consumers, one stream per core (backtracking matching; 4 x 4: A0 -> row 0, B_c -> 1,
  B_{c+4} -> 2, A1 -> 3).
* **Views and roles.** A consumer reads its stream through `own` (0x70000, locks 48..), `north`
  (0x60000, 32..) or `south` (0x40000, 0..). The lower consumer reads first and hands the buffer on;
  the two walk its halves in opposite phase (bank conflicts).
* **Hosted buffers.** 2 channels x 2 slots of one chunk at the top 32 KB of the host's memory, each
  chunk split over two DM banks; locks per channel F (DMA -> first reader), G (first -> second),
  E per slot (both readers -> DMA, acquired -2).
* **MemTiles.** A: top MemTile row, a FIFO ring (counting locks), column c carries strip c / 2,
  chunk parity c % 2, broadcast to the strip's host row. B: bottom MemTile row, strips c and c + C,
  4 MM2S channels replay them; `resident = "launches"` loads B on the first launch only.
* **Shim.** One BD per stream (A ch 1, B ch 0), the DDR layout one contiguous stream per column
  (the host app arranges it, `sh_arrange` in `gemm_plan.cc`).

Limits (errors name them): exactly two shared operands, mesh rows = 2 x A strips and mesh columns =
2 x A strips (4 x 4), N = 2C block rows (one n tile per core), output tiles per core = M / (R/2) /
block rows <= 64, K / chunk even, the ring must divide one strip's stream.

## 3. dmaphop level: the plan ops

Attribute-only ops (`assemblyFormat = "attr-dict"`, `td/dmaphopop.td`), read and validated by
`collectDataflowPlan` (`pass/dataflowplan/dataflowplan.cpp`) with errors at the op's location.
Columns are partition-relative; MemTile / core addresses and dims are in the tile's own units
(32-bit-word steps / wraps, byte addresses in its own view); shim dims are bytes.

```mlir
dmaphop.plan {replace_args = [0, 1], persistent_go_lock = 14, bd_once = true}
dmaphop.plan_route {src = [1, 0, 1], src_kind = "shim", dsts = [[1, 2, 1]]}
dmaphop.plan_route {src = [1, 2, 1], src_kind = "dma", dsts = [[1, 3, 0], [2, 3, 0], [3, 3, 0], [4, 3, 0]]}
dmaphop.plan_lock {tiles = [[1, 1], ...], id = 6, init = 0, later = 4}
dmaphop.plan_bd {tiles = [[1, 2], ...], bd = 24, addr = 524288, len = 16384, acq = [20, -1], rel = [24, 1], next = 25}
dmaphop.plan_channel {tiles = [...], dir = "mm2s", ch = 1, start_bd = 34, repeat = 30}
dmaphop.plan_shim_bd {col = 1, ch = 1, dir = "mm2s", arg = 0, bd = 14, offset = 0, len = 81920,
                      dims = [[4, 32], [128, 64], [8192, 10]], iter = [81920, 60], repeat = 60}
dmaphop.plan_kernel_param {name = "A_VIEW", per_mesh_row = [458752, 262144, 393216, 458752]}
dmaphop.plan_kernel_param {name = "SLOT_STRIDE", value = 4096}
```

Checked at read time: BD id ranges (MemTile 0..47, core 0..15, shim 0..15), lock ids (MemTile
0..63, core 0..15), the 10-bit MemTile / 8-bit core BD wrap fields (a too-large wrap silently turns
a dimension off), start-queue repeat 1..256, shim iteration wrap <= 64, shim BDs only over replaced
arguments.

### What the compiler does with a plan

| where | what |
|---|---|
| `collectDataflowPlan` (pipeline, after the dmaphop stage) | validates, tags every `create_path` / `push` of a replaced argument `dmaphop.plan_replaced`, erases the plan ops, publishes `dfplan::activePlan()` |
| `DmaphopToRoutinghwPass` | no generated stream route for a tagged path |
| `BlueprintToSchedulePass` (host) | for a replaced argument: core buffers / windows kept (the kernel signature is unchanged), no shim BD / create_io / start_io / wait; `resolveKernelBlock` skips its window check |
| `ScheduleCanonicalizePass` | `host_canonicalized` keeps every memref argument (the plan's launch reads them) |
| routing.cc | `aiehlc_plan_routing()` -- BFS over the AIE2PS port model around the ports the generated routes took (`routingresourcemap.json`) and the control-packet row fabric; MemTile SOUTH/NORTH lanes kept tied (skill memtilepassthroughlane); called at the end of `routing()` |
| host.cc | `aiehlc_plan_host_setup()` before the kernel load (runtime switches), `aiehlc_plan_host_launch(dev, args...)` after the kernel launch (MemTile locks every launch, BDs + channel enables once, start queues, shim BDs + start queues), `aiehlc_plan_host_wait()` before return |
| kernel.cc | the KCO input blocks on core S2MM channels the plan owns are dropped; one `DATAFLOW PLAN` block programs the cores' BDs, locks and channels (per-tile `get_coreid()` dispatch when the tiles differ) |
| aiehlc_plan.h | `AIEHLC_PLAN_<name>(pm)` tables / constants, `AIEHLC_PLAN_PERSISTENT`, `AIEHLC_PLAN_GO_LOCK` |
| flowcheck | replaced flows are listed, not checked; every `plan_route` is simulated through routing.cc (`plan_routes` in `dmaphopprovenacemap.json`) |

Runtime (`aie_runtime.c`, `__Runtime_plan_setup(bd_once, go_lock)`):
* `bd_once`: a BD or out-of-order channel write identical to one already made in this partition
  generation is skipped (the registers keep their values; only start queues are pushed again).
* persistent: `__Runtime_load_kernel_group_16t_ctrl` returns the loaded group after the first
  call; `__Runtime_launch_kernel_group_ctrl` then only sets every core's go lock to 1.

A build with no plan is byte-identical to before (host.cc, kernel.cc, routing.cc, bcf verified on
`gemm_kacc_v2.cc`). The dmaphop and routing IR round trips stay byte-identical with a plan
(`script/test/routing_ir_roundtrip.sh`); `readIROverride` compares without the plan ops and
without the derived control-plane placement attributes.

## 4. Traps

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
