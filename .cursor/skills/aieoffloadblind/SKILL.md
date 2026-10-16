---
name: aieoffloadblind
description: Frontend (TVM --aie-offload / --aiegraph) prints "OVER BUDGET" or gates offload on a per-tile memory estimate. Don't — the frontend offloads blindly; tiling and tile-memory fit are aiehlc's job.
---

# Frontend offload is blind — no tile-budget check

## Rule

The model-ingest frontends (`src/frontend/tvmrelay/aie_offload.py`,
`aiegraph_partition.py`, `byoc/`) select layers by **op kind only** and hand
them to aiehlc as-is. They must **not** estimate per-tile working sets, compare
against tile memory, or emit `feasible` / "OVER BUDGET" verdicts.

Spatial tiling, halo, mesh partitioning, DMA and the per-tile memory budget are
aiehlc's responsibility (`doc/design/byoc_aie_plan.md`: "does not fit a tile —
aiehlc's job"). A Python-side estimate duplicates the backend's policy, drifts
from it (the removed `check_layer` assumed whole-feature-map kernels and
reported the stem 10.1x over a 49,152 B tile), and misleads users into thinking
the frontend is what blocks the offload.

## History

`check_layer` / `TILE_USABLE_BYTES` / `PING_PONG_DEPTH` / `CONFIG_SZ` and the
`feasible`, `per_tile_bytes`, `infeasible` result fields were removed from
`aie_offload.py`, `aiegraph_partition.py` (incl. `partition.json`) and
`deploy_flow.py` at the user's request.

## Don't confuse with

`--aie-offload` failing with `RuntimeError: AIE emit unavailable` — that is
`_require_emit_deps()` (missing `_aiebackend` or
`frontend.tvmrelay.kernels`), not a budget gate. For `_aiebackend`, see
skill **mlirbuildsandbox** ("silently skipped / not installed"). See skill **nchwclayoutfold**.
