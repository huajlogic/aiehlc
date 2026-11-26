<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Compiler inside: how the IR lowers at each performance level

One int8 GEMM (`C = A . B^T`, 4 x 4 mesh) taken from 0.01 % to 85 % of the AIE peak by changing only its C
source (`example/tileprogram/ccode/gemm_plan/step0_baseline.cc` ... `step7_ring.cc`). `tutorial/perfoptmize/` tells
what each step changes in the source and why it is faster; this series opens the compiler and shows, at each
performance level, **how the program is lowered and what changed in the IR** -- above all at the routing, dmaphop
and dfscheblueprint levels, where the data movement is decided.

Every excerpt is copied from the dumps of one build of the step with this compiler (the dataflow plan unified
into the hop graph and the blueprint, `doc/plan/dataflowplan_unify_ir.md`); `0_pipeline.md` says where the dumps
are and how to read them.

| chapter | level (palmyra, % of peak) | step | what the compiler does differently |
|---|---|---|---|
| [0](0_pipeline.md) | -- | -- | the levels, the passes, the dump files |
| [1](1_level_0.01.md) | ~0.01 % (step 0: 0.012 %) | `step0_baseline.cc` | the generic path once through every level: a host loop of BD writes and waits per launch |
| [2](2_level_14.md) | ~14 % (step 1: 0.39 %, step 2: 19.6 %) | `step1_vector.cc`, `step2_launch.cc` | same flows; the launch moves off the host's MMIO: control packets, the cores program their own DMA, one out-of-order shim BD for the output |
| [3](3_level_50.md) | ~50 % (step 3: 66.1 %) | `step3_memtile.cc` | the dataflow plan: `#routing.dataflow` -> plan paths in dmaphop -> the plan on the blueprint -> a tile-local DMA program |
| [4](4_level_80.md) | ~80 % (step 4: 68.3 %, step 5: 76.4 %) | `step4_keep.cc`, `step5_persistent.cc` | B resident in the MemTiles, a persistent kernel: the same IR with different stream fields and module switches |
| [5](5_level_85.md) | 85 % (step 6: 85.67 %, step 7: 85.68 %) | `step6_banks.cc`, `step7_ring.cc` | the chunk split over two memory banks and a deeper A ring: two fields of the stream |

The levels are the ones this GEMM passed through on its way up (`doc/performance/gemm_e2e_progress.md`); the
numbers are today's, measured on palmyra (AIE2PS, 1.0 GHz, 16 x 512 MAC / cycle peak) with this compiler, every
run GOLDEN PASS (2026-11-26):

| step | per launch | % of peak |
|---|---|---|
| 0 `step0_baseline.cc` | 3995.4 ms | 0.012 % |
| 1 `step1_vector.cc` | 126.4 ms | 0.389 % |
| 2 `step2_launch.cc` | 2.506 ms | 19.6 % |
| 3 `step3_memtile.cc` | 1.860 ms | 66.1 % |
| 4 `step4_keep.cc` | 1.799 ms (best 1.645 ms) | 68.3 % (74.7 %) |
| 5 `step5_persistent.cc` | 1.608 ms | 76.4 % |
| 6 `step6_banks.cc` | 1.434 ms | 85.67 % |
| 7 `step7_ring.cc` = `gemm_plan.cc` | 1.434 ms | 85.68 % |

Steps 0-2 compute C[7680 x 256] (5.03 G MAC), steps 3-7 C[7680 x 512] (10.07 G MAC); time is the host's wall clock
around one launch, after the first launch (which loads the kernel): the mean for steps 0-2 (`gemm_gen`), the median
for steps 3-7 (`gemm_plan`), as each body's `PERF SUMMARY` reports it.

## Reproduce

```bash
source script/aiehlc.sh --aie-version 5 --runtime-source-file $PWD/example/tileprogram/ccode/gemm_plan/step3_memtile.cc
grep -a "IR ->" <build log> | sed 's#.*/##'           # the dumps this build wrote
python3 script/test/apppaltest.py -board palmyra -y --netload aout/worklocal/build/host
```

`PERF SUMMARY ... steady X ms median (Y % of peak @ 1000 MHz)` is the median of the launches after the first
(the first loads the kernel); every run checks C bit-exact against the CPU (`GOLDEN PASS`).
