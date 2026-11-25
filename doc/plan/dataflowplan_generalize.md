<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Generalizing the dataflow plan beyond one GEMM point

Status file for the work that takes the dmaphop dataflow plan (`doc/design/dmaphop_dataflow_plan.md`)
from "85 % on one int8 GEMM shape on VEK385" to a general mechanism. Each stage lists its acceptance
checks; a check is ticked only with its **evidence** written next to it (commit, board, the GOLDEN /
PERF SUMMARY line, or the command output). Branch: `gemm-dmaphop-ir`; commit per stage, never push.

## Rules for every stage

- Never run two `aiehlc.sh` at once; board runs are serial (one board session at a time).
- The reference point must not regress: `example/tileprogram/ccode/gemm_plan/gemm_plan.cc` on VEK385
  stays >= 85 % of peak with GOLDEN PASS, and a build without a plan stays byte-identical. If it
  drops, fix it before the next stage.
- Close each stage with: design doc + CLAUDE.md + skill updated, `python3 script/ci/check_opensource.py
  --changed` PASS, one commit on `gemm-dmaphop-ir`.
- Stop and ask the user before: pushing, adding any non-original file, touching another session's
  worktree or the main checkout's uncommitted files.
- Report every number twice: % of the core peak and % of the DDR bound for that shape and board
  (bytes moved / measured DDR bandwidth), so shapes and boards are compared fairly.

## Known limits this plan addresses (2026-11-24 review)

| # | limit | where |
|---|---|---|
| L1 | measured on one point only: VEK385, int8, C[7680 x 512] = A[7680 x 2560] . B[512 x 2560]^T | `tutorial/perfoptmize/` |
| L2 | only `share = "neighbor"`, exactly two operands | `plansynth.cpp` (`shared.size() != 2`) |
| L3 | A fixed to `memtile_ring`, B fixed to `memtile` with the whole K resident | `plansynth.cpp` (`sa.stage` / `sb.stage`) |
| L4 | B of 4096 x 512 x 4096 bf16 needs 1 MiB per column, MemTile has 512 KiB | `planresource.cpp` (`exceed its ... B`) |
| L5 | fp32 accumulator (`facc`) does not fit core DM at K 2048 bf16 | `gemm_plan_body.cc` |
| L6 | `-D` reaches only the host compile; front end, trace, plan and `kc.sh` do not see it | `script/aiehlc.sh`, `script/kc.sh` |
| L7 | tiling and shape are hand-written macros (`KA_*`, `SH_*`, `GP_HW_*`); `gemm_plan.py` is a lookup table | `gemm_plan_body.cc`, `gemm_plan.py` |
| L8 | `kWrapMax = 1024` literal; device table knows aie2ps only | `flowtransfer_host.cpp`, `plantarget.h` |
| L9 | non-GEMM ops not regressed on this branch after the `flowtransfer_host.cpp` change | -- |
| L10 | "MAC loop unchanged" compared by bundle count, which varies run to run (1833 vs 1829) | -- |

## Stage 0: baseline and regression (L1, L9)

- [x] VEK385: `gemm_plan.cc` and `gemm_plan_4x2.cc` GOLDEN PASS + PERF SUMMARY. Evidence (2026-11-24,
      vek385-3, build at 12109fc7): 4 x 4 `GOLDEN PASS: 187758 / 187758 checked outputs match | PERF SUMMARY
      gemm_plan steady 1.150 ms mean (85.47 % of peak), best 1.147 ms (85.71 %) | 0 wait_io timeouts`;
      4 x 2 `GOLDEN PASS: 94428 / 94428 ... | PERF SUMMARY gemm_plan steady 1.134 ms mean (86.70 % of peak),
      best 1.133 ms (86.80 %) | 0 wait_io timeouts`.
- [x] palmyra213: the same two builds (or the reason they cannot run there). Evidence (2026-11-24,
      same ELFs): 4 x 4 `GOLDEN PASS: 187758 / 187758 | PERF SUMMARY gemm_plan steady 2.657 ms mean
      (37.00 % of peak)`; 4 x 2 `GOLDEN PASS: 94428 / 94428 | PERF SUMMARY gemm_plan steady 1.993 ms mean
      (49.33 % of peak)`. The printed % assumes VEK385's 1250 MHz; at palmyra's 998 MHz the peak share is
      46.3 % (4 x 4) and 61.8 % (4 x 2).
- [x] DDR bound per shape and board computed and recorded next to the % of peak. Evidence: palmyra's
      measured model (`script/perf/gemm_plan.py` BOARDS: reads / 16.1 GB/s + writes / 3.58 GB/s, one
      controller, no overlap). 4 x 4: A 19.66 MB read (B kept), C 3.93 MB written -> 2.320 ms bound;
      measured 2.657 ms = **87.3 % of the DDR bound** (46.3 % of peak). 4 x 2: C 1.97 MB -> 1.770 ms
      bound, measured 1.993 ms = **88.8 % of the DDR bound** (61.8 % of peak). palmyra is DDR-bound
      (writes at 3.58 GB/s cost as much as all of A); VEK385 is not (3 interleaved controllers; the
      DMA-only twin moves A in ~0.85 ms against 1.150 ms, `gemm_plan.py` profile), so there the bound
      is the cores: 85.5 % of peak.
- [x] Non-GEMM regression on this branch: `simplematmul2.cc`, conv2dstem (`buildtest.sh`),
      `script/test/routing_ir_roundtrip.sh` pass; board run for simplematmul2 + conv2dstem. Evidence
      (VEK385): conv2dstem (`test_conv2d.cc`, headers on disk) `[conv2dstem] GOLDEN PASS 802816/802816 |
      PERF SUMMARY iters 5 first 1.087 min 0.389 mean 0.394 (ms)`; simplematmul2 **hung on this branch**
      (`wait_io TIMEOUT tile(0,0) ch=0 dir=1`, watchdog) while the 3ff40966 build ran -- 0a4ac5d1's
      whole-K-walk repeat collapse also hit a GemmSpace kernel; gated on traced kernel-only ports (skill
      `kwalkrepeatcollapse`), now `aie matmul time: 26614.954 ms`, no timeout; simplegemm_kacc (the case
      0a4ac5d1 fixed) still `GOLDEN PASS: 112384 / 112384` on palmyra, host.cc identical to 12109fc7. `routing_ir_roundtrip.sh`
      simplematmul2.cc and simpleconv2d.cc: `[roundtrip] PASS`.
- [x] A build without a plan is byte-identical to main before the plan work (host.cc / kernel.cc /
      routing.cc). Evidence: baseline aiehlc built at 3ff40966 (worktree `dfplan_base`); simplematmul2 and
      conv2dstem `host.cc`, `kernel.cc`, `routing.cc` identical to it (re-checked after the stage-2
      output change: `s2e_* vs 3ff40966 ...: identical` x 6).

## Stage 1: per-operand staging chosen by capacity; B streamed along K (L3, L4)

- [x] `plansynth` decides per operand: whole operand fits the MemTile budget -> `keep` (resident),
      else `memtile_ring` streamed chunk by chunk along K. Roles are operand indices, not `"a"` / `"b"`.
      Evidence: B's staging by `memBytes` and by ONE BD's length (`memBdMaxLenWords`), ring depth by
      `chMaxRepeat`; `role` is a label (the layout is `row_groups` / `strips`; `"a"` / `"b"` only give
      their defaults); forced ring `gemm_plan_bring.cc` (7680 x 512 x 2560, B `memtile_ring 3`): `GOLDEN
      PASS shape=7680x512x2560 dtype=int8 launch=8 checked=562176 bad=0` (VEK385).
- [x] The decision and the budget are printed (`[DataflowPlan] stream N: keep|ring, X B of Y B`).
      Evidence (int8 4096 build log): `[DataflowPlan] stream 1: held whole it needs 524288 B per MemTile
      (524288 B left next to A's ring, one BD holds 524284 B): streamed as memtile_ring 2 (re-read from DDR
      per output tile; keep ignored)` / `stream 0: memtile_ring 8, 131072 B per MemTile; stream 1:
      memtile_ring 2, 65536 B per MemTile (of 524288)`.
- [x] int8 4096 x 512 x 4096 on VEK385: GOLDEN PASS + PERF. Evidence: VEK385 `GOLDEN PASS
      shape=4096x512x4096 dtype=int8 launch=101 checked=300032 bad=0 | PERF SUMMARY gemm_plan steady 3.136 ms
      median (26.75 % of peak @ 1250 MHz)`; palmyra `GOLDEN PASS ... | PERF SUMMARY ... 9.203 ms median
      (11.39 % of peak @ 1000 MHz)`. B is re-read from DDR for each of the 32 output tiles (64 MB per
      launch against A's 16 MB): DDR traffic, not the cores, sets this number -- the tiling (stage 4)
      is the lever. Found on the way: MemTile BD length 2^17 words truncates to 0, a shim BD iteration
      step of 0 wraps to the largest step (skill `planbdfieldlimits`).
- [x] bf16 4096 x 512 x 4096 builds (no `exceed its 524288 B`). Evidence: `[DataflowPlan] stream 1:
      held whole it needs 1048576 B per MemTile ...: streamed as memtile_ring 4`, flowcheck OK; the kernel
      link then ran out of core memory (`could not find free space ... in memory DMb`) -- stage 2.
- [x] 7680 x 512 x 2560 int8: generated files unchanged, >= 85 % on VEK385. Evidence: `kernel.cc`,
      `routing.cc`, `aiehlc_plan.h` byte-identical to the stage-0 build (`host.cc` differs only by the
      generic body from bdca2fc1: shape knobs, GOLDEN via `gplan_ref.h`); VEK385 `GOLDEN PASS
      shape=7680x512x2560 dtype=int8 launch=8 checked=562176 bad=0 | PERF SUMMARY gemm_plan steady 1.148 ms
      median (85.62 % of peak @ 1250 MHz), best 1.147 ms (85.68 %)`; palmyra 2.613 ms (47.02 %).

## Stage 2: core data-memory budget owns the accumulator (L5)

- [x] Accumulator size comes from the plan (`aiehlc_plan.h`) and is counted by `planresource` with the
      port buffers and chunk slots; over budget -> the plan shrinks the tile or ring, or fails naming
      the item and the overflow in bytes. Evidence: `planCoreMemory` (A chunk rows x B chunk rows x 4 B);
      int8 7680: `[DataflowPlan] core memory: windows 40960 B (32768 B the plan's), stack >= 4096 B,
      statics 4096 B, 16384 B left; K accumulator 16384 B: the kernel's own` (files unchanged); bf16:
      `... 8192 B left; K accumulator 16384 B: does not fit, the plan holds it in its windows with 1 slot(s)
      per channel (AIEHLC_PLAN_ACC)`; still short -> error naming the accumulator and the bytes missing.
- [x] bf16 4096 x 512 x 4096 (fp32 accumulate) builds without hand-edited macros and runs GOLDEN PASS
      on VEK385. Evidence: VEK385 `GOLDEN PASS shape=4096x512x4096 dtype=bf16 launch=101 checked=300032
      bad=0 in_crc=63c4a919 ref_crc=a10c5ff4 out_crc=a10c5ff4 | PERF SUMMARY gemm_plan steady 6.209 ms
      median (27.02 % of peak @ 1250 MHz)`; palmyra same crc, 18.253 ms (11.49 %). Needed two more fixes:
      the bf16 C (declared N x 2 bytes) had no GEMM tiling, so `output_tile_major` was not applied and the
      tiles were scattered -- now taken from the traced blocks; and fp32 -> bf16 rounding set to RNE
      (skill `kbtilemajoroutput`).

## Stage 3: one source, any configuration via -D (L6)

- [x] `aiehlc.sh` passes user `-D` (and `AIEHLC_DEFINES`) to the front end, the x86 trace, the plan,
      `kc.sh` and the KOBJ cache key. Evidence: `aiehlc.sh --define NAME=VALUE` / `AIEHLC_DEFINES`; aiehlc
      writes them as `#define` lines at the top of the source text before anything reads it
      (`injectUserDefines`, `#line 1`), so all of these derive from one text; build log `[aiehlc] define
      GP_M = 4096 (AIEHLC_DEFINES)` x 5.
- [x] Shape macros that differ between host and kernel builds are a build error. Evidence:
      `EXTRA_DEFS=-DGP_M=4096` on gemm_plan.cc -> rc 1, `Error: EXTRA_DEFS -DGP_M=4096 reaches only the host
      compile, but GP_M is used by the source (gemm_plan.cc gemm_plan_body.cc): the kernel, the trace and the
      plan would see another value. Pass it with --define GP_M=4096 (or AIEHLC_DEFINES) instead.`
- [x] `gemm_plan.cc` with `-DGP_M=4096 ...` produces the same files as a dedicated entry file.
      Evidence: `--define GP_M=4096 GP_N=512 GP_K=4096 GP_DTYPE=1 GP_LAUNCHES=101` vs
      `gemm_plan_4096x512x4096_int8.cc`: `kernel.cc`, `routing.cc`, `aiehlc_plan.h` identical, `host.cc`
      differs only in the entry file's comment and the splice markers; VEK385 `GOLDEN PASS
      shape=4096x512x4096 dtype=int8 launch=101 checked=300032 bad=0 | PERF SUMMARY gemm_plan steady 3.138 ms
      median (26.73 % of peak @ 1250 MHz)`. Without defines gemm_plan.cc's kernel.cc / routing.cc /
      aiehlc_plan.h are unchanged.

## Stage 4: tiling chosen by the compiler (L7)

- [x] The compiler derives the tiling from the tensor shapes, dtype, the mesh limits and `plantarget.h`
      before the kernel is traced, and the kernel body reads only what it is given. Evidence:
      `#pragma gemm_autotile` (`gemm_plan_auto.cc`; `src/llvm/convautotile/gemm_autotile.cpp`) reads
      GP_M / GP_N / GP_K / GP_DTYPE and writes GP_HW_ROWS / GP_HW_COLS / GP_RING as `#define`s (stage 3's
      path), so trace, plan and both compiles follow; every count in the body derives from them.
      (Changed from "the plan emits them in aiehlc_plan.h": the trace needs the mesh before the plan exists,
      so the choice has to come first. What the 2 x 8 kernel leaves open is the mesh width -- N = 2 x
      columns x 64 -- and A's ring; rows are 4 (A and B reader counts must match), the 64 x 64 tile and the
      64 x 128 B chunk are the kernel's. Infeasible shapes are refused by name, e.g. N 1024: `4 x 8 mesh:
      32 output cores, 27 packet ids free`.)
- [x] A cost model (DDR bytes, core DM, MemTile capacity, stream rate) picks the tiling; the
      measured table in `gemm_plan.py` becomes calibration data. Override knob documented. Evidence:
      time = max(cores = tiles x chunks x cycles per chunk, busiest shim channel, DDR) + launch; MemTile
      capacity / BD length decide B kept or re-read; packet ids and the A ring's divisibility decide
      feasibility. Calibration: int8 1188 cycles / chunk and palmyra's DDR rates from `gemm_plan.py`;
      VEK385 shim 5.2 GB/s per channel and 24 GB/s aggregate DDR read fitted on the runs below; bf16 2600
      cycles / chunk. Override: `--define GP_HW_ROWS/GP_HW_COLS/GP_RING` (the source's value wins and is
      logged), board `#pragma gemm_autotile(palmyra)` / `AIEHLC_GEMM_BOARD`. Ranking printed per build
      (`[GemmAutoTile]   4 x 4 mesh, ring 10, B kept, ...: core 1.140 shim 0.945 DDR 0.819 ms -> 1.160 ms`).
- [x] At least 4 shapes (N 512 / 1024 / 2048, K 2560 / 4096) x int8 / bf16 build and run GOLDEN PASS
      on VEK385 with no source edit; table of % of peak and % of DDR bound. Evidence: one source,
      `gemm_plan_auto.cc --define GP_M=.. GP_N=.. GP_K=.. GP_DTYPE=..`, 21 launches, VEK385, all GOLDEN PASS
      (bad=0). N 1024 / 2048 do not fit the packet ids (refused, see above); N 768 is the widest.

      | dtype | M x N x K | mesh | B | measured ms | % of peak | model ms (bound) | model error | DDR-model ms / measured |
      |---|---|---|---|---|---|---|---|---|
      | int8 | 7680 x 512 x 2560 | 4 x 4 | kept | 1.148 | 85.63 | 1.160 (cores) | +1 % | 71 % |
      | int8 | 4096 x 512 x 4096 | 4 x 4 | re-read | 3.140 | 26.72 | 3.515 (DDR) | +12 % | 111 % |
      | int8 | 4096 x 512 x 2048 | 4 x 4 | kept | 0.512 | 81.97 | 0.507 (cores) | -1 % | 68 % |
      | int8 | 4096 x 768 x 2560 | 4 x 6 | kept | 0.645 | 81.33 | 0.628 (cores) | -3 % | 68 % |
      | bf16 | 4096 x 512 x 1024 | 4 x 4 | kept | 1.118 | 37.52 | 1.085 (cores) | -3 % | 31 % |
      | bf16 | 4096 x 512 x 4096 | 4 x 4 | re-read | 6.207 | 27.03 | 7.011 (DDR) | +13 % | 113 % |
      | bf16 | 4096 x 768 x 2560 | 4 x 6 | re-read | 6.767 | 15.50 | 6.137 (DDR) | -9 % | 90 % |
      | bf16 | 7680 x 512 x 2560 | 4 x 4 | re-read | 7.392 | 26.60 | 8.212 (DDR) | +11 % | 111 % |

      Kept-B shapes run at 81-86 % (int8) of peak, core-bound; re-read-B shapes are DDR-bound at ~24 GB/s
      (the "DDR bound" is the fitted rate, hence ~90-113 %). Fixes found on the way: a 4 x 6 mesh needed
      a 24-core kernel load (`_32t`, skill `meshsizelimits`); bf16 7680 needed B's ring walk split over
      the channel start queue (skill `planbdfieldlimits`).

## Stage 5: more sharing modes, any operand count, other ops (L2)

- [x] `share = none` (per-core stream, plan-derived DMA) and `share = broadcast` (row / column).
      Evidence: `{.share = aie::share::broadcast}` (the kernel analysis sets the axis from the fit: row or
      column; both program ids -> error) and a `.stage` without `.share` (`share = "none"`, with the traced
      core origin) synthesize per-core copies (`synthCopyText` / `synthPerCore`): one multicast stream per
      mesh row / column, or one per core through a per-column MemTile ring; core side under
      `AIEHLC_PLAN_COPY` (`deriveCopySlots`, `aie_block_io_plan.h`). All three on the board below.
- [x] Any number of planned operands; one stream synthesized per operand. Evidence: one stream per operand,
      each with its own core S2MM channel, MemTile row and shim channel; the bound is the hardware's: 2
      per-core operands (a core has 2 S2MM channels; `N per-core copy streams: a core has 2 S2MM channels`
      otherwise), and neighbour and per-core operands do not mix in one plan (named error).
- [x] An elementwise kernel through the plan path: GOLDEN PASS, not slower than main. Evidence (VEK385):
      `simpleeltwise_add_plan.cc` (x, y row broadcast) `GOLDEN PASS: eltwise_plan z = sat(x + y), 262144
      outputs | PERF SUMMARY eltwise_plan first 0.969 ms, steady 0.365 ms mean`; the same kernel on main's
      generated path (`simpleeltwise_add.cc`): `[BENCH] aie_wall_ms=57.024`, `FAIL: 237456 mismatches out of
      262144`. `simpleeltwise_add_none.cc` (x per core, y column broadcast): `GOLDEN PASS ... 262144 outputs
      | PERF SUMMARY eltwise_none first 1.040 ms, steady 0.213 ms mean`.
- [x] A kernel-only conv (`load_buffer` blocks, e.g. `simpleconv2dkernel_port.cc`) through the plan path
      (input with halo, weights `keep`): GOLDEN PASS, not slower than main. Evidence:
      `simpleconv2dkernel_port_plan.cc` (input 19 x 61 x 4 halo blocks, row broadcast through a MemTile ring;
      weights column broadcast, held in the MemTiles across launches) `GOLDEN PASS: conv_plan 0 mismatches
      of 802816 | PERF SUMMARY conv_plan first 0.723 ms, steady 0.098 ms mean, best 0.097 ms`; main's
      generated path, same kernel: `[BENCH] aie_wall_ms=54.229` (that example checks nothing).
      (Changed 2026-11-24 with the user's approval: conv2dstem has its own halo-slab DMA and GemmSpace
      descriptors -- moving it onto the plan is a rewrite of the operator; it stays on its path.)
      GEMM unchanged by all of this: gemm_plan.cc kernel.cc / routing.cc / aiehlc_plan.h identical,
      `GOLDEN PASS ... | PERF SUMMARY gemm_plan steady 1.147 ms median (85.72 % of peak @ 1250 MHz)`.

## Stage 6: device table and measurement hygiene (L8, L10)

- [ ] `kWrapMax` and every remaining device literal in the flow-transfer helpers read `plantarget.h`.
- [ ] An aie2p entry in the device table; a plan build for an aie2p target compiles. Evidence:
- [ ] A script that extracts the MAC inner loop from `kernel.lst` and compares its instruction
      sequence between two builds; used in place of bundle counts. Evidence:

## Log

| date | stage | result | commit |
|---|---|---|---|
| 2026-11-24 | 0 | baseline re-measured (VEK385 85.5 % / 86.7 %, palmyra 87-89 % of its DDR bound); a plan-less GemmSpace GEMM (simplematmul2) hung on this branch -- fixed, files identical to 3ff40966 again (skill `kwalkrepeatcollapse`) | 46ae6afc |
| 2026-11-24 | 1 | B staged by MemTile capacity (keep or ring, re-read per output tile); int8 4096 x 512 x 4096 GOLDEN PASS on VEK385 + palmyra (26.8 % / 11.4 %, DDR-bound by B re-reads); 7680 unchanged at 85.6 %; three silently truncating DMA fields now limits + build errors (skill `planbdfieldlimits`); generic shape / dtype body from bdca2fc1 | 5f75d43e |
| 2026-11-24 | 2 | the plan owns the K accumulator when it does not fit (one slot per channel, AIEHLC_PLAN_ACC); bf16 4096 x 512 x 4096 GOLDEN PASS on VEK385 + palmyra (27.0 % / 11.5 %); tile-major output from the traced blocks + RNE bf16 rounding (skill `kbtilemajoroutput`) | 57b2d949 |
| 2026-11-24 | 3 | `--define` / `AIEHLC_DEFINES` reach every stage (macros injected into the source text); EXTRA_DEFS refused for a source macro; gemm_plan.cc + --define == the 4096 entry file (GOLDEN PASS, 3.138 ms) | 4c38e5e0 |
| 2026-11-25 | 4 | `#pragma gemm_autotile`: mesh + A ring by a calibrated cost model, 8 shapes (int8 / bf16, N 512 / 768, K 1024..4096) GOLDEN PASS from one source, model within +-13 %; 32-core kernel load, packet-id limit as an error, channel start queue split | c0d9168b |
| 2026-11-25 | 5 | per-core copies: `.share = broadcast` (row / column) and per-core streams; eltwise 0.365 ms (main: 57 ms, wrong) and kernel-only conv 0.098 ms (main 54.2 ms) GOLDEN PASS; GEMM unchanged | this commit |
