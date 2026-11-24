---
name: nonsquaremeshplan
description: Building a kernel for a non-square mesh (e.g. 4 x 2 vs 4 x 4) -- dmaphop places core groups on columns the mesh does not have, `No free shim DMA slot for dioN` before the dataflow plan replaces anything, a mesh-size macro (`#ifndef X / #define X default / #endif`) undeclared in the trace harness or the extracted kernel TU. Use for any GEMM / plan example parameterised by mesh width.
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Non-square meshes and the dataflow plan

Three generic-pipeline bugs hid behind the 4 x 4 mesh (row count == column count); the 4 x 2 build of
`example/tileprogram/ccode/gemm_plan/gemm_plan_4x2.cc` found them.

| symptom | cause | fix |
|---|---|---|
| dmaphop core tiles on columns 1..4 for a `routingcreatehwmesh row = 4, col = 2` | `routingtodmap.cpp`: a split along the rows gives one group per mesh ROW of `col` cores; the code used `row` | `tileNum = split_axis == "row" ? col : row` |
| `No free shim DMA slot for dio6` in DmapToDmaphopPass | the A / B flows the plan replaces still booked shim DMA channels; 2 columns have 4 MM2S channels | `dmaptodmaphop.cpp`: a flow of a tensor with `dataflow` books none (`createDataIOAtPoint`, stand-in in the target core's column) |
| `GP_HW_COLS was not declared` in the trace harness / `gemm_ka.cc` | `kernel_trace.cpp sourceDefines` copied only `#define` lines; `aiehlc.cc` skipped defines inside `#if` blocks | both keep the conditional structure (aiehlc: a top-level block that holds a `#define` is kept whole) |

Also: the partition must be exactly the mesh + the control column (`{2, 2 + cols}`): the routing mesh
takes the partition's width, not the kernel's `device.partition(..., R, C)` -- a wider partition puts
the dmaphop cores on the extra columns.

Plan-side, a narrow mesh changes the layout, not the code: plansynth spreads A's (strip, parity) rings
over the columns it has (4 x 2: one MemTile per strip serving both parities, an (empty, full) lock pair
and an MM2S channel per parity, channels picked so each BD bank holds its chain).
