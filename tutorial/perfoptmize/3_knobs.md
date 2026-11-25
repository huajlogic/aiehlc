<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Where the time goes, and the knobs that matter

| step | the binding limit before the step | the knob | measured |
|---|---|---|---|
| 0 -> 1 | scalar MACs: a few per cycle against 512 | `aie::mmul<8,8,8>` + 2 x 2 register block, `{.align = 64}`, host-packed operands | 0.015 % -> 0.50 % |
| 1 -> 2 | the launch: ELF + BSS + BDs over MMIO, partition init / teardown | `DISABLE_PARTITIONTEARDOWN`, `control_plan_op_control_packet`, `control_packet_mode(aot)`, `KERNELCONFIGOFFLOAD`, `output_tile_major`, uncached buffers | 0.50 % -> 24.1 % |
| 2 -> 3 | per-core input streams and DDR: 2 streams per core | `{.share = neighbor}` (2 x 8 logical grid), `{.stage = memtile / memtile_ring}` | 24.1 % -> 65.7 % |
| 3 -> 4 | B re-sent every launch | `{.keep = true}` | 65.7 % -> 74.8 % |
| 4 -> 5 | kernel reload + BD programming per launch | `#pragma persistent_kernel` | 74.8 % -> 76.4 % |
| 5 -> 6 | two readers on the same memory bank | `{.parts = 2}` (+ tile sync) | 76.4 % -> 85.6 % |
| 6 -> 7 | DDR / core jitter on a shallow A FIFO | `{.ring = 10}` | 85.6 % -> 85.7 % |

What did **not** help (measured during the history; see `doc/performance/gemm_e2e_progress.md`):

- A read contiguously from DDR (4 KB bursts) instead of 128-byte rows: slower (49-52 % vs 57 %).
- Two kernel bodies (a separate first chunk): slower, and close to the 16 KB program memory.
- Unrolling the chunk loop by 2: overflows program memory.
- A on both shim channels: works, not faster -- the cores bind, not the shim.
- Per-buffer F locks without the hand-on (no reader order): 15 % slower.

Traps a step can fall into, each fixed in the compiler today:

| symptom | cause | skill |
|---|---|---|
| `needs a 64-byte aligned address` | 64-byte `load_v` on a 32-byte aligned window | use `{.align = 64}` |
| GOLDEN FAIL, deterministic match count | a core BD wrap > 255 (8-bit field) | `bdwrapfieldwidth` |
| launch 1 hangs, cores `pc=0` | persistent kernel reloaded on an 8-core mesh | `persistentkernelreload` |
| every launch 0.1 ms slower after a merge | post-launch invalidate of a cached output | `postlaunchoutputinval` |
| occasional 1.20-1.26 ms launches | readers drifting onto the same bank | tile sync (`LOCK_SYNC`) |

The remaining gap to 100 %: chunk-boundary and loop overhead in the kernel (~10 %, static) and DMA bank
conflicts (~4 %), measured with core cycle stamps (`doc/performance/gemm_e2e_progress.md`, "Static bound
of the current kernel").
