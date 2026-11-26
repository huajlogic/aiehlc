<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# GEMM toward 90 % of peak: measurement patches (not in the main tree)

The int8 dataflow-plan GEMM (`example/tileprogram/ccode/gemm_plan/gemm_plan.cc`, 7680 x 512 x 2560, 4 x 4)
runs at **85.65 %** of peak end to end on palmyra (1.435 ms, PDI of 2026-11-25) and **86.4 %** on the
array-only basis (host time in `wait_io`, 1.422 ms; the basis RSN-XNN reports), 85.5-85.7 % on VEK385.
The work that tried to push it toward 90-95 % produced the changes below. Each one has a limitation that
keeps it out of the main tree, so it is kept here as a patch on top of `main` (`git apply <patch>` from the
repository root; all apply cleanly to the tree they were cut from). What they measured is recorded in
`doc/performance/gemm_e2e_progress.md` (sections from "palmyra on the PDI of 2026-11-25" on).

| file | what it adds | why it is not in the main tree |
|---|---|---|
| `runtime_coreloss.patch` | `__Runtime_core_loss_arm(meshId, bank_a, bank_b)` / `__Runtime_core_loss_read(out, n)` in `aie_runtime.c/.h`: per core ACTIVE, MEMORY_STALL, LOCK_STALL, INSTR_VECTOR + DM bank conflicts of two banks | uses the same core performance counters as `--profiling`'s core-perf window (the two cannot be combined); the other runtime users (eltwise / conv plans, `simplematmul2`, ...) were not re-run on a board after it |
| `gemm_plan_loss.patch` (needs `runtime_coreloss.patch`) | `gemm_plan_body.cc --define GP_LOSS=1`: arms the counters on launches 3..6, one DM bank pair each, prints `LOSS ...` lines | depends on the runtime patch |
| `losstable.py` | turns the `LOSS` lines of a board log into the per-core loss table | only useful with the two patches |
| `gemm_autotile_palmyra_pdi2.patch` | `#pragma gemm_autotile` board facts for palmyra on the new PDI (1000 MHz, DDR reads 26 / writes 25 GB/s, overlapped, shim channel 7.6 GB/s) | changes the tilings the autotiler picks for palmyra; not validated on the board (`gemm_plan_auto.cc` was not rebuilt and run). VEK385, the default board, is unaffected |
| `simplegemm_peak_2x4.patch` | `simplegemm_peak.cc`: shape knobs `GP_M/N/K/BN` (`#ifndef`), 2 x 4 register blocking (`GP_BN 4`, all 8 accumulators); default 64 x 128 x 1152 = 16 x 32 x 1152 per core | changes the example's default shape and blocking: numbers quoted elsewhere for the old default (128 x 128 x 384, 2 x 2) no longer come out of a plain build |

## Results (all GOLDEN PASS)

Core MAC loop alone (`simplegemm_peak_2x4.patch`, operands resident, klog CYC per core, palmyra):

| per core | blocking | MAC instr | cycles | of peak |
|---|---|---|---|---|
| 32 x 32 x 384 (the old default) | 2 x 2 | 768 | 891 | 86.2 % |
| 32 x 32 x 768 | 2 x 2 | 1536 | 1624 | 94.6 % |
| 32 x 32 x 768 | 2 x 4 | 1536 | 1585 | 96.9 % |
| 32 x 32 x 832 | 2 x 4 | 1664 | 1713 | 97.1 % |
| 16 x 32 x 1152 | 2 x 4 | 1152 | 1180 | 97.6 % |

Loss table of gemm_plan (`runtime_coreloss.patch` + `gemm_plan_loss.patch` + `losstable.py`), per core,
median of 16 cores, launches 3..6, one ELF:

| item | palmyra (1000 MHz, 1.435 ms) | VEK385 (1250 MHz, 1.150 ms) |
|---|---|---|
| VMAC (1,228,860 vector instr; 1,228,800 MAC instr expected) | 85.6 % | 85.5 % |
| other instructions | 6.1 % | 6.1 % |
| memory stall (DM bank conflicts, banks 4-7 ~42-45 k each) | 4.6 % | 4.7 % |
| lock stall (incl. host launch 1.1 % / 0.8 %) | 3.7 % | 3.7 % |

Chunk-boundary experiments (built on the loss patches, palmyra steady, then removed):

| attempt | middle boundary bundles per 128 MACs | steady |
|---|---|---|
| baseline | 153 | 1.435 ms, 85.63 % |
| accumulator spill before the next chunk's locks | 189 | 1.468 ms, 83.72 % |
| hand-on lock id as its own expression | 152 | 1.434 ms, 85.72 % (noise) |

Conclusion: ~86-87 % (array basis) is this design's ceiling. The ~16 lock bundles per chunk boundary are the
shared-reader protocol's floor (ACQ -> REL needs 3 cycles; counting locks instead of the hand-on are
unsafe), the operand banks are bandwidth-bound, and the inner loop is at 131 bundles per 128 MACs. 90 % needs
a layout with fewer chunk boundaries and less operand-bank traffic.

The static half (no board): `python3 src/costmodel/tools/kcyc_lst.py <build>/kernel.lst --func gemm_ka`
gives the kernel's stall-free core cycles and VMAC count (within 0.3 % of the board's VMAC + other
instructions on the three builds above; `src/costmodel/README.md` §1.5).

## Use

```bash
git apply perftest/gemm90/runtime_coreloss.patch perftest/gemm90/gemm_plan_loss.patch
source script/aiehlc.sh --aie-version 5 --runtime-source-file $PWD/example/tileprogram/ccode/gemm_plan/gemm_plan.cc --define GP_LOSS=1
python3 script/test/apppaltest.py -board palmyra -y --netload aout/worklocal/build/host > applog 2>&1
python3 perftest/gemm90/losstable.py applog --macs 1228800
git apply -R perftest/gemm90/gemm_plan_loss.patch perftest/gemm90/runtime_coreloss.patch
```

Traps (skill **coreloss**): the counters run from arm to read, so a persistent kernel's go-lock wait outside the
launch is subtracted per core (its active cycles beyond the launch); the VEK385 farm console echoes and splices
lines (the script de-duplicates and takes medians over cores).
