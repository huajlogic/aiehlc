<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# int8 GEMM performance optimization on AIE2PS, step by step

From a scalar kernel to **~85 % of the VEK385 int8 peak** -- every step is a change to the **C source
only** (a load / store option, a pragma, the kernel's arithmetic). The compiler derives the DMA, the
routes, the MemTile program, the locks and the launch; nothing generated is edited by hand.

The steps retrace the history of this GEMM (`doc/performance/gemm_e2e_progress.md`): the first time
each level was reached it took hand edits of the generated `host.cc` / `kernel.cc` / `routing.cc`
(`example/tileprogram/ccode/gemm_memtile/share2x8.py`). Here each one is reproduced with the
compiler's current, hard-code-free logic.

| step | source (`example/tileprogram/ccode/gemm_plan/`) | what changes | VEK385 (per launch, % of peak) | history (first reached, by hand) |
|---|---|---|---|---|
| 0 | `step0_baseline.cc` | scalar MACs, no options | 3194.4 ms, 0.015 % | 0.09 % (VEK385_2, 293 ms) |
| 1 | `step1_vector.cc` | `aie::mmul<8,8,8>` 2 x 2 register block | 99.25 ms, 0.50 % | -- |
| 2 | `step2_launch.cc` | launch off the MMIO path: control-packet ELF, KCO, tile-major output, no teardown, uncached buffers | 2.042 ms, 24.1 % | 14.6 % (compiler alone) |
| 3 | `step3_memtile.cc` | dataflow plan: 2 x 8 shared operands, MemTile staging (A ring 2, B per launch) | 1.497 ms, 65.7 % | 26-57 % (MemTile staging, hand-edited) |
| 4 | `step4_keep.cc` | + `.keep`: B resident across launches | 1.314 ms, 74.8 % | 64.7 % (weight-resident B) |
| 5 | `step5_persistent.cc` | + `#pragma persistent_kernel` | 1.287 ms, 76.4 % | 74.2 % (persistent, shared layout) |
| 6 | `step6_banks.cc` | + `.parts = 2`: chunk halves in different memory banks | 1.148 ms, 85.6 % | 77-82 % (bank split + phase) |
| 7 | `step7_ring.cc` (= `gemm_plan.cc`) | + `.ring = 10` | 1.147 ms, 85.7 % | 84.5 % by hand, 85.5 % compiler |

Problem: int8, C = A . B^T on the 4 x 4 mesh of a VEK385 (array clock 1.25 GHz, peak 16 x 512 MAC /
cycle = 10.24 TMAC/s). Steps 0-2 compute C[7680 x 256] (K 2560, 5.03 G MAC: the generic path walks one
n tile per core), steps 3-7 C[7680 x 512] (10.07 G MAC). Time = host wall clock around one launch (steps 3-7 re-measured 2026-11-25 on the generic body: median of the launches after the first),
steady state (the first launch, which loads the kernel, is reported apart). Every run checks a sample
of C bit-exact against the CPU (GOLDEN PASS).

Build and run any step:

```bash
source script/aiehlc.sh --aie-version 5 --runtime-source-file $PWD/example/tileprogram/ccode/gemm_plan/step3_memtile.cc
python3 script/test/apppaltest.py -board vek385-3 -host gomphus3 -y --netload aout/worklocal/build/host
```

Chapters:

1. [Steps 0-2: the generic path -- kernel first, then the launch](1_generic_path.md)
2. [Steps 3-7: the dataflow plan -- feed the cores](2_dataflow_plan.md)
3. [Where the time goes, and the knobs that matter](3_knobs.md)
4. [Beyond one shape: other shapes, bf16, the tiling by the compiler, other operators, AIE-ML](4_beyond_one_shape.md)
