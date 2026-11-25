---
name: aie2planbuild
description: A dataflow-plan build for AIE-ML (`--aie-version 2`, the `aie2` plan target) fails -- `the plan streams from the shims of columns N, which have no DMA on aie2`, `control spine column has no shim DMA`, `route from (c, 1) ch k: no free path to (c, r)` / `DmaphopToRoutinghwPass failed`, `XPAR_CPU_TIMESTAMP_CLK_FREQ` undeclared in simplegemm_peak.h; debugging a plan route (`AIEHLC_PLAN_ROUTE_DEBUG`)
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Dataflow plans on AIE-ML (aie2)

`plantarget.h` has a table per target, `aie2ps` (`--aie-version 5`) and `aie2` (AIE-ML, `--aie-version 2`),
selected by the pipeline (`selectPlanTarget`). The example: `example/tileprogram/ccode/gemm_plan/gemm_plan_aie2.cc`
(builds; no AIE-ML board in the farm to run it).

| symptom | cause / fix |
|---|---|
| `the plan streams from the shims of columns 4, 5, which have no DMA on aie2` | AIE-ML has shim DMAs on its NoC columns only (2, 3, 6, 7, 14, 15, ...; `shimDmaCols`). A layout with a shim stream per column must sit on such columns: the 4 x 2 mesh on columns 2, 3 |
| `control spine column has no shim DMA` | the control-packet plane needs its own column with a shim DMA, and the NoC columns come in pairs: no third column next to a NoC pair -- build without the control-plane pragmas (`gemm_plan_aie2.cc`) |
| `route from (1, 1) ch 2: no free path to (1, 5)` | the router's AIE-ML core template had 4 NORTH masters / 4 SOUTH slaves; the hardware has 6 / 6 (`xaiemlgbl_reginit.c` `AieMlTileStrmMstr` / `Slv`), pairing with the MemTile's 6 NORTH masters. Fixed in `hwresource.cpp` |
| `XPAR_CPU_TIMESTAMP_CLK_FREQ` undeclared | gate `xiltimer.h` on `AIE_GEN > 2` (skill bspheadergen2) |

## Debugging a plan route

`AIEHLC_PLAN_ROUTE_DEBUG=1`: on `no free path` the plan router (`passdmaphoptoroutinghw/planroutes.cpp`) prints
the destination column's vertical ports per tile, `+` free / `x` taken (`Nm` north masters, `Ss` south slaves,
...), and every routinghw op occupying rows 2..4. A taken lane with no routinghw op on it is one of the
plan's own earlier routes.
