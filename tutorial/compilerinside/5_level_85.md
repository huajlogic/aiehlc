<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# 5. 85 %: two fields of the stream

Sources: `step6_banks.cc` (`.parts = 2` on A and B: a chunk is addressed as two row halves, which the plan puts in
different core memory banks) and `step7_ring.cc` = `gemm_plan.cc` (`.ring = 10`: a deeper A FIFO in the MemTile).
Both act on the stream only; the routes and the generated flows do not move.

## step 6: `.parts = 2` -> the chunk in two banks

| level | the whole difference to step 5 |
|---|---|
| routing | A and B: `#routing.dataflow<..., parts = 1, ...>` -> `parts = 2` |
| dmaphop | both plan paths: `#dmaphop.stream<..., readers = 2, parts = 1, ...>` -> `parts = 2` |
| dfscheblueprint | the same field in both `dfscheblueprint.plan_stream`s |
| dfschedule (kernel plan program) | the core BDs write a chunk as two halves, a bank apart |
| `aiehlc_plan.h` | `AIEHLC_PLAN_PART_STRIDE 32768 -> 16384`, `AIEHLC_PLAN_SLOT_STRIDE 8192 -> 4096` |

The core's S2MM BD is where `parts` lands: the chunk (64 rows x 128 B = 8 KB) used to be one 2-D block in one 32 KB
region; now its two 32-row halves go 16 KB apart (`PART_STRIDE`), i.e. into different 16 KB memory banks, and the
kernel's `x.part(i)` (`aie_block_io_plan.h`) points at them:

```mlir
// step 5
dfschedule.config.tile_bd(%0) {bd_id = 0 : i32, addr = 491520 : i64, len = 8192 : i32,
    dim_strides = [4 : i32, 512 : i32, 32768 : i32], dim_wraps = [128 : i32, 16 : i32, 0 : i32], ...}
// step 6
dfschedule.config.tile_bd(%0) {bd_id = 0 : i32, addr = 491520 : i64, len = 8192 : i32,
    dim_strides = [4 : i32, 512 : i32, 16384 : i32], dim_wraps = [128 : i32, 8 : i32, 0 : i32], ...}
```

The two readers of a chunk walk its halves in opposite order (`pa` / `pb` in `SH_PARTS`, `gemm_plan_tile.h`), so
they touch different banks at the same time. Nothing about the transfer changes -- same bytes, same channels, same locks -- only where in the
core's memory they land, and that is the 9 points: the cores stall on bank conflicts far less
(`perftest/gemm90/`, skill **coreloss**: memory stall 4.6 % remains).

## step 7: `.ring = 10` -> a deeper MemTile FIFO

| level | the whole difference to step 6 |
|---|---|
| routing | A: `#routing.dataflow<..., ring = 2, ...>` -> `ring = 10` |
| dmaphop | A's plan path: `#dmaphop.stream<..., ring = 2, ...>` -> `ring = 10` |
| dfscheblueprint | the same field in A's `dfscheblueprint.plan_stream` |
| dfschedule (host plan program) | A's MemTile: 10 buffers instead of 2 -- more BDs (36 -> 100 `config.tile_bd`), the ring's empty lock starts at 10 |

```mlir
// MemTile (1, 2), A's ring, step 6 -> step 7 (14_DataflowPlanToDfschedule.mlir)
dfschedule.config.lock_set(%27) {dfplan.tag = "mem/0/0/lock/0", lock_id = 0 : i32, restored = true, value = 2 : i32}
dfschedule.config.lock_set(%27) {dfplan.tag = "mem/0/0/lock/0", lock_id = 0 : i32, restored = true, value = 10 : i32}
dfschedule.config.tile_bd(%27) {bd_id = 2 : i32, ..., dfplan.tag = "mem/0/0/out/0/0", next_bd = 3 : i32, ...}
dfschedule.config.tile_bd(%27) {bd_id = 10 : i32, ..., dfplan.tag = "mem/0/0/out/0/0", next_bd = 11 : i32, ...}
```

The empty-buffer lock counts the ring's free buffers (10), the S2MM chain has 10 BDs and the MM2S chains start
after them (BD 10); `planresource.cpp` checked the MemTile's BD count and memory (`A ring 10, 163840 B per
MemTile`). With a 2-deep ring the MemTile could run at most one buffer ahead of the cores; with 10 the shim's
bursts are absorbed. On VEK385_2's DDR this is within noise (85.67 % -> 85.68 %): the design is core-bound here.

## Measured (VEK385_2, GOLDEN PASS every run)

| step | per launch | % of peak |
|---|---|---|
| 5 (`persistent_kernel`) | 1.608 ms | 76.4 % |
| 6 (`.parts = 2`) | 1.434 ms | 85.67 % |
| 7 (`.ring = 10`, `gemm_plan.cc`) | 1.434 ms | 85.68 % |

## Across the series

From step 3 on, every source change was one field of one tensor's `#routing.dataflow` or one module switch, and
each travelled the same way: routing attribute -> `#dmaphop.stream` / `dmaphop.plan` on the plan path ->
`dfscheblueprint.plan_stream` / module attributes -> a few dfschedule ops. That is what the unified IR buys: one
place per level to look, and a diff of two builds that is as small as the source change.
