---
name: coremacpeak
description: An int8 aie::mmul<8,8,8> kernel stuck below ~92 % of the core peak although its inner loop issues one VMAC per cycle; choosing register blocking (2x2 vs 2x4, 8 dm accumulators) and K per accumulator group; how large resident operands may get in core memory; measuring per-core MAC efficiency with klog CYC (simplegemm_peak.cc, GP_M/N/K/BN)
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Core MAC efficiency (AIE2PS int8)

Example: `example/tileprogram/ccode/simplegemm_peak.cc` with `git apply perftest/gemm90/simplegemm_peak_2x4.patch`
(adds `--define GP_M= GP_N= GP_K= GP_BN=` and the 2 x 4 path; kept out of the tree because it changes the default shape). Peak =
one `mac_8x8_8x8` (512 MAC) per cycle per core. Efficiency = MAC instructions / CYC, where CYC is the
klog'd cycle count around the compute and MAC instructions = cm * cn * K / 512.

## What sets it

The inner loop is not the problem: `script/perf/macloop.py kernel.lst` shows 4 bundles for 4 VMAC (2x2)
or 8 bundles for 8 VMAC (2x4). The cost is **per accumulator group**: ~20-30 cycles of pipeline fill /
drain and int8 write-back outside the K loop. So:

- **more K steps per group** (K / 8): K is bounded by core memory, (cm + cn) x K resident bytes;
- **fewer groups**: 2x4 blocking uses all 8 `dm` accumulators (6 loads feed 8 MACs, still MAC-bound),
  half the groups of 2x2.

VEK385_2, 2026-11-25, all 16 cores identical, GOLDEN PASS:

| per core | blocking | MAC instr | cycles | of peak |
|---|---|---|---|---|
| 32 x 32 x 384 | 2x2 | 768 | 891 | 86.2 % |
| 32 x 32 x 768 | 2x2 | 1536 | 1624 | 94.6 % |
| 32 x 32 x 768 | 2x4 | 1536 | 1585 | 96.9 % |
| 32 x 32 x 832 | 2x4 | 1664 | 1713 | 97.1 % |
| 16 x 32 x 1152 | 2x4 | 1152 | 1180 | 97.6 % |

## Traps

| symptom | cause / fix |
|---|---|
| the old "91.5 % at 32x32x384" does not reproduce (86.2 %) | measured on an older PDI / toolchain; compare variants built and run together |
| `the port buffers take N B ... more than the ... buffer region holds` | resident blocks may take up to 64 KB - `AIEHLC_DM_MIN_STACK` (4 KB) - ~3 KB klog/statics (~57 KB; `trace_routing.cpp portBufferLimit`), not 29 KB |
| a run prints no CYC / no GOLDEN line | the board was held by someone else (`[devlock] ... busy`) and the run timed out before getting it: check `applog_pal`, rerun with the built ELF |
| board-run efficiency differs from a model | count from the listing: loop bundles per VMAC (macloop), loop count `MOVA lc, #N`, number of ZLS loops = groups |
