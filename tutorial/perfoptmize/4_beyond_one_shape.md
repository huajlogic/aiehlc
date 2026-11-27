<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Beyond one shape: other shapes, bf16, other operators

Steps 0-7 reach 85 % on one point: int8, C[7680 x 512] = A[7680 x 2560] . B[512 x 2560]^T, a 4 x 4
mesh. This part takes the same compiler further -- other shapes from the same source, bf16, the tiling
chosen by the compiler, and operators that are not a GEMM -- and shows what each step costs and where it
stops. All numbers are VEK385, GOLDEN PASS. The work plan with every measurement is
`doc/plan/dataflowplan_generalize.md`.

## 1. The shape is a build option: `--define`

`gemm_plan_body.cc` takes its problem as macros and derives every count from them:

```c++
#ifndef GP_M
#define GP_M 7680
#endif
...                                         // GP_N 512, GP_K 2560, GP_DTYPE 1 (int8) / 2 (bf16)
#define KA_R (GP_M / (GP_HW_ROWS * KA_TM))   // output tiles per core / 2
#define SH_NK (KA_K / KA_KC)                 // K chunks
static_assert(SH_TILES >= 1 && SH_TILES <= 64, "tiles / core <= 64 (6-bit OOO iteration counter)");
```

A macro has to reach **every** stage that reads the source: the front end's macro scan, the x86 trace,
the dataflow plan, the kernel compile and the host compile. `--define` does that -- aiehlc writes the
macros as `#define` lines at the top of the source text before anything reads it:

```sh
source script/aiehlc.sh --aie-version 5 --runtime-source-file $PWD/example/tileprogram/ccode/gemm_plan/gemm_plan.cc \
    --define GP_M=4096 --define GP_N=512 --define GP_K=4096 --define GP_DTYPE=1
```

```
[aiehlc] define GP_M = 4096 (AIEHLC_DEFINES)
```

`EXTRA_DEFS` reaches only the host compile, and it is refused for a macro the source uses -- it used to
build the kernel for one shape and the host for another:

```
Error: EXTRA_DEFS -DGP_M=4096 reaches only the host compile, but GP_M is used by the source
(gemm_plan.cc gemm_plan_body.cc): the kernel, the trace and the plan would see another value.
Pass it with --define GP_M=4096 (or AIEHLC_DEFINES) instead.
```

## 2. When B no longer fits: the plan decides

At 4096 x 512 x 4096, B's two strips per column are 512 KiB int8 / 1 MiB bf16 -- a MemTile is 512 KiB,
and one MemTile BD holds at most 2^17 - 1 words. The plan checks both and streams B through a MemTile
FIFO ring instead of holding it, re-read from DDR for every output tile:

```
[DataflowPlan] stream 1: held whole it needs 1048576 B per MemTile (524288 B left next to A's ring,
one BD holds 524284 B): streamed as memtile_ring 4 (re-read from DDR per output tile)
```

Nothing in the source changes. The cost is DDR traffic: B is read 32 times per launch, so these shapes
are DDR-bound at ~24 GB/s:

| dtype | M x N x K | B | per launch | % of peak |
|---|---|---|---|---|
| int8 | 4096 x 512 x 2048 | kept | 0.512 ms | 82.0 % |
| int8 | 4096 x 512 x 4096 | re-read | 3.137 ms | 26.7 % |
| bf16 | 4096 x 512 x 4096 | re-read | 6.209 ms | 27.0 % |

Three DMA fields truncate silently and are build errors now (skill `planbdfieldlimits`): a MemTile BD
length of exactly 2^17 words is written as 0; a BD iteration step of 0 ("the same data again") is
stored as step - 1 and becomes the largest step -- a re-read uses the channel's repeat count instead;
a channel start repeats at most 256 times -- a longer walk is queued as up to 4 starts.

## 3. bf16: the accumulator and the output

bf16 makes the output tile twice as big (8 KB): the K accumulator (64 x 64 fp32 = 16 KB) no longer fits
next to the core's windows. The plan counts the core's 64 KiB and, when the accumulator does not fit,
takes one chunk slot per channel instead of two in the memory it owns and places the accumulator there:

```
[DataflowPlan] core memory: windows 49152 B (32768 B the plan's), stack >= 4096 B, statics 4096 B,
8192 B left; K accumulator 16384 B: does not fit, the plan holds it in its windows with 1 slot(s) per
channel (AIEHLC_PLAN_ACC)
```

```c++
#define AIEHLC_PLAN_ACC 507904            // aiehlc_plan.h
#define AIEHLC_PLAN_SLOTS 1
```

```c++
#if defined(AIEHLC_PLAN_ACC)              // gemm_plan_body.cc, bf16 path
    float *const facc = (float *)AIEHLC_PLAN_ACC;
#else                                     // int8, and the x86 trace
    alignas(8192) static float facc[KA_TM * KA_TN];
#endif
    aie::set_rounding(aie::rounding_mode::conv_even); // the core starts in floor: one bf16 ulp off
```

The bf16 C is declared `N x 2` bytes on int8 ports, which the GEMM model does not match against B, so
`#pragma output_tile_major` now takes the layout from the traced blocks (skill `kbtilemajoroutput`) --
before, every value was right and almost every one at the wrong place.

## 4. The tiling chosen by the compiler: `#pragma gemm_autotile`

```c++
// gemm_plan_auto.cc
#pragma gemm_autotile           // or gemm_autotile(palmyra); AIEHLC_GEMM_BOARD
#include "gemm_plan.cc"
```

The 2 x 8 kernel leaves the mesh width (N = 2 x columns x 64) and A's ring open; rows must be 4 (A's and
B's reader counts must match), the 64 x 64 tile and the 64 x 128 B chunk are the kernel's. The model
(`src/llvm/convautotile/gemm_autotile.cpp`) ranks max(cores, busiest shim channel, DDR) + launch and
writes its choice as `#define`s before the kernel is traced:

```
[GemmAutoTile] vek385, int8 C[4096 x 768] K 2560: 1 tiling(s)
[GemmAutoTile]   4 x 6 mesh, ring 10, B kept, 32 tiles x 20 chunks: core 0.608 shim 0.504 DDR 0.105 ms
                 -> 0.628 ms (cores), 83.5 % of peak
[GemmAutoTile] GP_HW_COLS = 6
```

(`GP_RING ... set by the source`: the body derives its own ring by the same rule, so the model's value
is logged, not written.) One source, 8 shapes, model within +-13 %:

| dtype | M x N x K | mesh | measured | model |
|---|---|---|---|---|
| int8 | 7680 x 512 x 2560 | 4 x 4 | 1.148 ms (85.6 %) | 1.160 ms |
| int8 | 4096 x 768 x 2560 | 4 x 6 | 0.645 ms (81.3 %) | 0.628 ms |
| bf16 | 4096 x 512 x 1024 | 4 x 4 | 1.118 ms (37.5 %) | 1.085 ms |
| bf16 | 7680 x 512 x 2560 | 4 x 4 | 7.392 ms (26.6 %) | 8.212 ms |

Wider meshes stop at the packet ids: every core of the packet-switched output takes one of 27 free ids,
so 4 x 6 (N 768) is the widest; N 1024 is refused by name (skill `meshsizelimits`).

## 5. Other operators: per-core copies

The 2 x 8 GEMM hosts each operand in one core that its neighbour reads. Most operators instead want
every core to hold its own copy:

| C option | the stream | example |
|---|---|---|
| `.share = aie::share::broadcast`, blocks follow `program_id(0)` only | one per mesh row, multicast to its cores | eltwise x / y, conv input |
| the same, blocks follow `program_id(1)` only | one per mesh column | conv weights |
| `.stage = ...` without `.share` | one per core, through a per-column MemTile ring | eltwise x per core |

```c++
// simpleeltwise_add_plan.cc -- the whole change to the kernel
#define OPTS_BC {.depth = 2, .share = aie::share::broadcast, .stage = aie::stage::memtile_ring, .ring = 2}
const int8_t *a = aie::load_buffer(x, {pm * rows + i * tr, j * tc}, {tr, tc}, OPTS_BC);
```

```c++
// simpleconv2dkernel_port_plan.cc: halo input by row, weights by column, kept across launches
#define OPTS_IN {.depth = 2, .share = aie::share::broadcast, .stage = aie::stage::memtile_ring, .ring = 2}
#define OPTS_W {.depth = 2, .share = aie::share::broadcast, .stage = aie::stage::memtile, .keep = true}
```

The kernel analysis decides the axis from the traced blocks; the conv's overlapping halo blocks are laid
out in DDR by `aiehlc_plan_arrange` (the host calls it, as for the GEMM). Each core keeps its copies on
its two S2MM channels -- so at most two such operands:

| kernel | per launch | the same kernel without the plan |
|---|---|---|
| eltwise z = sat(x + y), x / y row broadcast | 0.365 ms | 57 ms, 237456 of 262144 wrong |
| eltwise, x per core + y per column | 0.213 ms | -- |
| conv 7 x 7 s2, 224 x 224 x 4 -> 112 x 112 x 64 | 0.098 ms | 54.2 ms |

Two per-core operands on a 4-row mesh would be 8 streams up one column, more than the MemTile-to-core
links carry: the router says `no free path` (skill `plancopystreams`).

## 6. Another device: AIE-ML

`plantarget.h` holds a table per target: `aie2ps` (VEK385, VEK385_2) and `aie2` (AIE-ML, `--aie-version 2`).
AIE-ML has shim DMAs on its NoC columns only (2, 3, 6, 7, 14, 15, ...), in pairs: a layout with a shim
stream per column must sit there, and there is no third such column for the control-packet plane.
`gemm_plan_aie2.cc` puts the 4 x 2 mesh on columns 2, 3 without it and builds; the 4 x 4 layout is
refused by name (skill `aie2planbuild`).

## 7. Checking that a change kept the MAC loop

chess does not emit the same program twice (a NOP, a moved scalar ADD), so a bundle count cannot tell a
rebuild from a change. Compare the vector side of the MAC blocks:

```sh
python3 script/perf/macloop.py old/kernel.lst new/kernel.lst
macloop: SAME -- every MAC block has the same vector instruction sequence (1 block(s) schedule their
scalar instructions differently)
```
