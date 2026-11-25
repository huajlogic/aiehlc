<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Steps 3-7: the dataflow plan -- feed the cores

From step 3 on, every step builds the same body, `example/tileprogram/ccode/gemm_plan/gemm_plan_body.cc`;
the step file sets the pragmas and three knobs:

```c++
#define GP_RING  2       // A's MemTile FIFO ring depth (buffers of 2 chunks)
#define GP_KEEP  false   // B held in the MemTiles across launches
#define GP_PARTS 1       // a chunk in 1 or 2 row parts (memory banks)
#include "gemm_plan_body.cc"
```

The problem grows to C[7680 x 512] (10.07 G MAC) and the chunk to 64 x 128 (K 2560 = 20 chunks).

## Step 3: shared operands through the MemTiles (`step3_memtile.cc`) -- 1.498 ms per launch, 65.6 % of peak

The kernel states **where its blocks come from**, not how they get there:

```c++
#define OPTS_A {.depth = 2, .share = aie::share::neighbor, .stage = aie::stage::memtile_ring, \
                .ring = GP_RING, .parts = GP_PARTS, .align = 64}
#define OPTS_B {.depth = 2, .share = aie::share::neighbor, .stage = aie::stage::memtile, \
                .keep = GP_KEEP, .parts = GP_PARTS, .align = 64}

const int pm = aie::program_id(0), pn = aie::program_id(1);
const int sa = pm >> 1, sb = pn + GP_HW_COLS * (pm & 1);        // the 2 x 8 LOGICAL grid
...
auto xa = aie::load_buffer(a, {arow, (k) * KA_KC}, {KA_TM, KA_KC}, OPTS_A);
auto xb = aie::load_buffer(b, {brow, (k) * KA_KC}, {KA_TN, KA_KC}, OPTS_B);
...
aie::release(a);
aie::release(b);
```

**Why 2 x 8.** On a 4 x 4 grid every core needs its own A strip and its own B strip: 32 input streams for
16 cores, and the per-core input rate (about 2.7 B/cycle per S2MM channel measured) caps the MACs.
Folding the grid -- core (pm, pn) computes A strip pm / 2 x B strip pn + 4 (pm % 2) -- makes every strip
needed by exactly **two vertically adjacent cores**. One core then hosts the stream in its memory and
its neighbour reads it through the shared north / south memory view. Each core receives one stream
instead of two.

**What the options become.** `.share`, `.stage`, `.ring`, `.keep`, `.parts` turn into a `dataflow`
attribute on the tensor in the routing IR; the plan synthesis (`pass/dataflowplan/plansynth.cpp`)
turns them into dmaphop ops, deciding the host core of every stream, the MemTile rows and channels,
the routes:

```mlir
dmaphop.plan_stream {arg = 0, role = "a", share = "neighbor", stage = "memtile_ring", ring = 2, ...,
                     host_rows = [0, 3], first_rows = [0, 2], channels = 2, slots = 2, readers = 2, parts = 1}
```

and the DMA program follows, derived in dfschedule with every id allocated (`planresource.cpp`):
A goes shim -> a MemTile FIFO ring -> broadcast to the strip's host row; B shim -> MemTile -> replayed
per (strip, parity) to its host rows. The kernel's `load_buffer` / `release` on a shared port compile to
the plan's protocol (`src/mlir/runtime/aie_block_io_plan.h`, always inline):

```c++
const int i = aiehlc_plan_reader(o, pm);                    // reader 0 or 1 of this stream
const int acq = lockbase + LOCK_F + i * HAND_DELTA + ch;    // my turn for chunk g
acquire_greater_equal(acq, 1);
release(acq + HAND_DELTA, i < READERS - 1);                 // hand on to the next reader (or a no-op lock)
return view(o, pm) + SLOT_LO + buffer(g) * SLOT_STRIDE;     // own / north / south memory view
```

At this step B is still sent every launch and the kernel is reloaded every launch (warm, AOT).

Reproducing this step found a compiler bug: without `.keep`, B's MemTile locks were marked `restored`
(written on launch 0 only) although nothing hands lock 1 back, so launch 1 hung on the B input. Fixed in
`plandma.cpp` (`restored = keep`); skill `planmemtilebperlaunch`.

## Step 4: weights stay (`step4_keep.cc`) -- 1.317 ms per launch, 74.7 % of peak

```c++
#define GP_KEEP true
```

`{.keep = true}` on B: the plan loads B into the MemTiles on the **first launch only**
(`__Runtime_startio_first`, the S2MM channel started once) and replays it from MemTile memory on every
launch after. A GEMM with fixed weights (inference) moves only A and C through DDR. The MemTile locks
that guard B are `restored` -- every launch hands them back at their start value -- so the host does not
rewrite them either.

The generated `host.cc` differs from step 3 in three places only: B's MemTile locks get their
second-launch values (`later` = 4 ready, 0 free), and both the MemTile S2MM channel start and the shim
`__Runtime_startio` for B become first-launch-only (`__Runtime_startio_first`). `kernel.cc` is unchanged.

History: 64.7 % on palmyra was the weight-resident 4 x 4 design (hand-edited); here it comes from one
option.

## Step 5: the kernel stays (`step5_persistent.cc`) -- 1.287 ms per launch, 76.4 % of peak

```c++
#pragma persistent_kernel
```

The kernel is loaded and the cores started on the first launch; `main()` in the generated `kernel.cc`
becomes

```c++
for (;;) {                       // persistent kernel: one call per launch
    acquire_greater_equal(GO, 1);  // released by the host
    gemm_ka(...);
}
```

and every later launch is a go-lock release per core plus the shim transfers. The plan also writes BDs
and channel configuration **once** (BD write-once) -- the core's own DMA program runs once at kernel
start.

The gain is small here because step 2's AOT warm reload already removed most of the reload cost. In the
history this step was larger (74.2 % on VEK385, `share2x8.py --persist`): AOT did not exist yet.

## Step 6: two memory banks (`step6_banks.cc`) -- 1.151 ms per launch, 85.4 % of peak

```c++
#define GP_PARTS 2
```

Two cores read every hosted chunk. If both read the same 16 KB memory bank at the same time they
conflict on every access. `{.parts = 2}` makes the plan place each chunk's two row halves `PART_STRIDE`
(16 KB) apart -- in different banks -- and the kernel walks them in opposite order:

```c++
const int pa = pm & 1, pb = pm >> 1;              // reader phase
al = (const int8_t *)xa.part(pa);                 // reader 0: rows 0-31 first,
ah = (const int8_t *)xa.part(pa ^ 1);             // reader 1: rows 32-63 first
```

The core BD writes the second half one `PART_STRIDE` further on (a third BD dimension), so the data
movement needs no extra transfer. The plan's runtime also syncs a stream's two readers once per output
tile (`LOCK_SYNC`): readers that drift half a chunk apart hit the same bank half on every access.

## Step 7: a deeper ring (`step7_ring.cc` = `gemm_plan.cc`) -- 1.152 ms per launch, 85.4 % of peak

```c++
#define GP_RING 10
```

A's MemTile FIFO goes from 2 to 10 buffers of 16 KB: the shim stream from DDR no longer stalls each time
a core is slow for a chunk, and the jitter between DDR and the cores is absorbed in the MemTile. Measured
today it is within noise of step 6 (1.152 vs 1.151 ms): with the bank split and the per-tile reader
sync the cores no longer drift, so a 2-deep ring already keeps them fed. In the hand-edited history,
which had no tile sync, the deeper ring was worth about 2 points. It stays in `gemm_plan.cc` as head
room against DDR jitter. This is the final build: **85.4 %** of the VEK385 peak (1.152 ms per launch), GOLDEN PASS, from the C source alone.

History: 84.5 % was the last hand-edited build (`share2x8.py --afine`: a 10-buffer A ring); the
compiler build reproduces and slightly passes it.
