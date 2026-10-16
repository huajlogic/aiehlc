---
name: nonsquaremeshgemmwindow
description: aiehlc output that compiles (rc=0) but whose core DMA window disagrees with the kernel -- on a NON-SQUARE mesh (R x C with R != C) or a NON-SQUARE GEMM (tileRows != tileCols). Symptoms - tile_group lists 4 tiles per mesh row on a 4x1 mesh; kernel.cc `BUF_SZ_OUT_0` is the kernel's window / R; a GEMM B window `BUF_SZ_IN_1` = 4*k_chunk (or clamped to l1_budget) while the kernel's buf_sz_b is tile_n*k_chunk. Fixed in RoutingToDmapPass / routinglower.cpp / BlueprintToScheduleKernelPass / flowtransfer_kernel.cpp.
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Non-square mesh / non-square GEMM window mismatches

Every example app uses a 4x4 mesh and square GEMMs, so two count bugs never
showed. Both compile cleanly; both are DMA/acquire mismatches on hardware.

## 1. Tiles per mesh row taken from the mesh row count

`RoutingToDmapPass` (and its twin in `routinglower.cpp`):

```cpp
int tileNum = (split_axis == "row") ? row : col;   // WRONG: a mesh row holds `col` tiles
int tileNum = (split_axis == "row") ? col : row;   // fixed
```

A 4x1 mesh got 4 tiles per mesh row (16 tiles), and the output gather divided
each row block by 4. Seen as `tile_group @group_src_N{tiles = [[0,3],[1,3],[2,3],[3,3]]}`
in `ir/dfschedule/5_DmaphopTodfscheblueprintPass.mlir` for a 1-column mesh.

## 2. GEMM B window divided by A's sub-tile count

With `k_rounds > 1` the per-k-round core window of every input was divided by
`tileRows/tileM`. Port 1 (B) walks `tileCols/tileN`. Now port 1 uses N rounds in
both `BlueprintToScheduleKernelPass` (kernel.cc `BUF_SZ_IN_1`) and
`flowtransfer_kernel.cpp` (core BD length) -- they must stay in step.

## How to check any build

```bash
grep '#define BUF_SZ_' aout/worklocal/kernel.cc        # v4int32 units: x4 = elements
grep 'const int buf_sz_' aout/worklocal/<kernel>.cc     # what the kernel walks
```

Per port they must be **equal** (not >=): one BD transfer per acquire.
`src/frontend/tvmrelay/example/whisper/aie_build.py:check_library` automates it.

A/B against a pristine HEAD build on simplematmul2 + conv2dstem: generated
kernel.cc/routing.cc/aieml.bcf byte-identical (square cases unaffected).
