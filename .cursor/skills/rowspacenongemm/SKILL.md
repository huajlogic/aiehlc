---
name: rowspacenongemm
description: Write an aiehlc kernel for a NON-GEMM operator (layer norm, softmax, element-wise add, any row-wise map) with aie::RowSpace. Use when a GemmSpace port gets the wrong shape (a [2,W] operand shows up as `win_b [WxW]`), when the output width is forced to N, when "Explicit tiling exceeds AIE data memory" fires on a row op, or when `aie::get_arg_per_round_size_in_dim` is "no member named ... in namespace 'aie'" outside a fullconnect_auto=1 GEMM.
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# RowSpace: non-GEMM kernels in aiehlc

## Symptom

A row-wise kernel written with `aie::GemmSpace` ports builds wrong shapes:

```
[TilingLinalg] Tensor param: win_b [384x384] i32 (input) policy=ParamB   <- declared [2,384]
[TilingLinalg] ERROR: Total buffer requirement (89088 bytes) exceeds tile data memory limit
```

## Root cause

GemmSpace infers shapes from the launch's `(M, N, K)` **by role**: Row input
`[M,K]`, Col input `[K,N]`, output `[M,N]` (`aiehlc.cc`, "Re-assign shape from
resolved policy fields"). The memory check and per-port window math are A/B/C
GEMM formulas. A non-GEMM operand cannot be described.

## Fix: `aie::RowSpace {policy, rows, cols}`

* every port declares its own `[rows.fullsize, cols.fullsize]`;
* Row-layout port = row-split operand (input or output), `rows.tile_size` rows
  per window; Col-layout **input** = broadcast operand (every tile, whole);
* **all** ports RowSpace; `GlobalPolicy{.fullconnect_auto = 0}`;
* launch on a **1 x N mesh**: `device.partition({0, 3, 0, 6}, 1, 4)` -- rows go
  one tile per array column (`flipRowSpaceDistribution`). Not R x 1 (one shim
  column runs out of DMA channels: `No free shim DMA slot`).
* pick `l1_budget` = rows_per_window x row bytes, or the build fails with
  "window splits a row" / "do not divide into ... windows" -- deliberate:
  the pipeline streams `min(perTile, l1_budget/elemBytes)`-element windows.
* in the kernel use only `aie::get_num_rounds(win)` and
  `aie::get_buffer_size(win)`; rows per window = buffer / cols.
* query `get_num_rounds/get_buffer_size` of every port you walk in lockstep,
  so a build-time check can compare them.

Check the log for `[TilingLinalg] RowSpace port ... window=... numRounds=...`
and `kernel.cc`'s `BUF_SZ_IN_*/OUT_*` (v4int32 units, x4 = elements): they must
equal the kernel's `buf_sz_*`.

Reference: `doc/design/spatial_space_composition.md` "RowSpace";
generator `src/frontend/tvmrelay/example/whisper/aie_kernels_whisper.py`.
