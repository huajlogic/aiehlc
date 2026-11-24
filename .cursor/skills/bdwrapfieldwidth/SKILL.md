---
name: bdwrapfieldwidth
description: A generated / hand-built multi-dimensional DMA BD scrambles data with no error -- GOLDEN FAIL with the SAME match count every run, perf unchanged, BD looks right in the source. Use when choosing BD dimension wraps for a core tile vs MemTile vs shim, or when a dims change (e.g. {1,128},{128,8} -> {1,512},{512,2}) breaks correctness.
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# BD wrap fields are narrower on a core tile

## Symptom
- `GOLDEN FAIL: 24728 / 187758` on the 2 x 8 plan GEMM -- identical count on every run, mismatches from
  the very first output tile, launch time unchanged (the DMA moves the same number of words).
- Nothing is wrong in host.cc / kernel.cc at a glance: the BD's wraps multiply to the right length.

## Cause
AIE2PS BD dimension wrap fields (`xaie2psgbl_params.h`, `*_D0_WRAP_MASK`):

| tile | D0 / D1 wrap | max |
|---|---|---|
| core (`MEMORY_MODULE_DMA_BD*`) | 8 bits (`0x001FE000`) | 255 |
| MemTile (`MEM_TILE_MODULE_DMA_BD*`) | 10 bits (`0x07FE0000`) | 1023 |
| shim (`NOC_MODULE_DMA_BD*`) | 10 bits (`0x3FF00000`) | 1023 |

A wrap of 512 in a core BD is truncated by the encoder (`aie_kc_field` masks it; XAie likewise), so the
DMA walks a different pattern -- silently.

## Fix / rule
- Dataflow plans: every derived BD dims goes through `splitWords(words, T.<kind>BdMaxWrap)`
  (`pass/dataflowplan/plandma.cpp`), limits in `plantarget.h`; `checkPlanLayout` refuses a chunk that
  cannot be split within them.
- Anything else that writes dims: check the wrap against the TILE KIND's field, not one global 1023.
- Debug tip: a deterministic, run-independent match count with unchanged timing points at a data
  layout (BD dims / addresses), not at synchronization.
