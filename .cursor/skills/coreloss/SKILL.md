---
name: coreloss
description: Where does a kernel's time go -- build a per-core loss table (VMAC / other instructions / memory stall from DM bank conflicts / lock stall / not active / host launch) from core performance counters on the board; __Runtime_core_loss_arm / __Runtime_core_loss_read, gemm_plan --define GP_LOSS=1, script/perf/losstable.py; deciding what to optimize next (bank layout, buffer slots, instruction overhead, launch) before trying it; a lock stall or active count larger than the launch
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Per-core loss table

Answer "what are the missing N % of peak" with counters, not guesses. Every cycle of a launch, per core, is one of:

| row | from |
|---|---|
| VMAC | core counter `INSTR_VECTOR` (= MAC instructions for an mmul kernel; check against M*N*K / (cores * MAC per instr)) |
| other instructions | active - VMAC - memory stall - lock stall (address math, loop and chunk boundaries, accumulator spill, convert) |
| memory stall | core counter `MEMORY_STALL` (DM bank conflicts: two readers, or a reader and a DMA, on one bank) |
| lock stall | core counter `LOCK_STALL` (waiting for an input chunk / a free output slot; includes the go-lock wait during the host launch and the launch fill) |
| not active | launch time the core was not enabled (non-persistent kernels: load / start) |

plus, outside the core: the **host launch cost** = end-to-end launch time - host time in `wait_io`
(`__Runtime_host_split_wait_ticks`, always on).

## How

The code is in `perftest/gemm90/` (not in the main tree: the counters are the ones `--profiling` uses):
`git apply perftest/gemm90/runtime_coreloss.patch` (+ `gemm_plan_loss.patch` for gemm_plan), README there.

1. In the app's host code, around ONE steady launch (not the first: it loads the ELF):

   ```c
   int  __Runtime_core_loss_arm(int meshId, int bank_a, int bank_b);   // zeroes; returns tiles armed
   int  __Runtime_core_loss_read(unsigned int *out, int max_tiles);     // 8 words per core that ran
   ...
   __Runtime_core_loss_arm(0, 4, 5);  /* launch */  n = __Runtime_core_loss_read(v, 64);
   ```
   and print one `LOSS launch=.. banks=a,b window_us=.. launch_us=.. wait_us=.. tile=c,r active=.. memstall=..
   lockstall=.. vec=.. conflA=.. conflB=..` line per core. The memory module has two counters, so repeat over
   four launches with bank pairs (0,1) (2,3) (4,5) (6,7) to see all eight banks.
   `gemm_plan_body.cc` with `gemm_plan_loss.patch` does exactly this with `--define GP_LOSS=1` (launches 3..6).
2. `python3 perftest/gemm90/losstable.py applog_pal --macs <MAC instr per core>` prints the table, the host launch
   cost, the conflicts per bank and the most stalled core.

The VMAC + other-instruction part can be predicted without a board: `python3 src/costmodel/tools/kcyc_lst.py
kernel.lst --func <kernel>` (static bundle count, within 0.3 % on gemm_plan; `src/costmodel/README.md` §1.5).
Only the stall rows need the counters.

## Measured (gemm_plan 7680 x 512 x 2560 int8, 4 x 4, one ELF, GOLDEN PASS, 2026-11-25)

Per core, median of 16 cores, launches 3-6:

| item | palmyra (1000 MHz, 1.435 ms) | VEK385 (1250 MHz, 1.150 ms) |
|---|---|---|
| VMAC (1,228,860 vector instr vs 1,228,800 MAC instr) | 85.6 % | 85.5 % |
| other instructions | 6.1 % | 6.1 % |
| memory stall | 4.6 % | 4.7 % |
| lock stall (incl. host launch) | 3.7 % | 3.7 % |
| host launch (end to end - wait_io) | 1.1 % | 0.8 % |

DM bank conflicts per core per launch: banks 4-7 41-45 k each (operand chunks: two readers + the DMA),
banks 0-3 < 2 k. Same on both boards: the design is core-bound. `doc/performance/gemm_e2e_progress.md`,
"Loss tables" (also keeps the older share2x8 VEK385 table).

## Traps

| symptom | cause / fix |
|---|---|
| active / lock stall larger than the launch (lock stall ~10 %) | the counters run from arm to read; a persistent kernel waits on its go lock outside the launch and that counts as active AND lock stall. Arming walks every tile over MMIO, so the host's window stamp is NOT when a tile's counters started: subtract each core's own active - launch cycles (losstable.py does) |
| `vec` far above the MAC count | the kernel has other vector instructions (`INSTR_VECTOR` is not only VMAC there): count MACs from the listing (`script/perf/macloop.py`) |
| all counters 0 / garbage with `--profiling` | the `--profiling` core-perf window uses the same core counters: do not combine |
| moving buffers between banks "fixes" memory stall but the launch is not faster | the loss moves to lock stall (DMA loses the bank arbitration). Judge by launch time, then re-run the table |
| VEK385: more cores than the mesh, a bank at 300 k conflicts | the farm com port echoes and splices lines; losstable.py keeps the first well-formed line per (launch, tile), drops cores with vec = 0 and takes medians over cores |
| comparing boards | VEK385 runs at 1.25 GHz, palmyra 1.0 GHz: compare shares, not cycles |
