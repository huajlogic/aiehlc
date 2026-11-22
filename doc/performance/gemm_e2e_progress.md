# int8 GEMM on the 4x4 mesh: end-to-end progress (aiehlchj-90)

Source session: **aiehlchj-90** (Claude Code, aiehlc repo). Branch `gemm-e2e-opt`
(worktree `.worktrees/gemm_e2e`). Board: palmyra (`apppaltest.py --netload`).
Every number below is a board run with a host golden check. The golden check is
bit-exact on a subsample of C (e.g. 200,241 outputs), not on all of C.

## 1. Where it stands

| Metric | Result | Window |
|---|---|---|
| Per-core compute | **91.5 %** of int8 peak | core cycle counter around the compute loop only |
| End to end, best (weight-resident B) | **64.7 %** (1.999-2.013 ms per 10.57 G MAC; B loaded into the MemTiles on the first launch only -- fixed-weight / inference use) |
| End to end, best (A and B both from DDR every launch) | **57.0 %** (2.258-2.281 ms per 10.57 G MAC: pipelined kernel + shim BDs once + `control_packet_mode(aot)` warm ELF reload; 56.5 % = 2.288 ms; 55.9 % = 2.311 ms; before it 44.5 % = 2.906 ms: K 2560, A in the row-2 MemTiles (3 buffers), B in row 1, A uncached, 128-B K chunks; 41.5 % / 37.2 % / 32.3 % / 26.8 % before; MemTile-staged A and B, hand-edited host/routing; section 8) -- 14.6 % (0.897 ms per 1.07 G MAC) from the compiler alone | host XTime around the whole launch: kernel load, BD config, DDR in/out, cache sync |
| start_io -> wait done | 36-43 % (A from DDR), 48-57 % (A staged in MemTile, hand-edited) | DMA + compute only |

Peak = 16 cores x 512 int8 MAC/cycle x 0.998 GHz = 8.18 TMAC/s. On AIE2PS,
`aie::mmul<8,8,8,int8,int8>` is one `mac_8x8_8x8` (512 MACs) per VLIW word; bf16 is
`mac_8x8_8x4_bf16` (256). The 0.998 GHz is the clock measured on VEK385; palmyra's
was not measured.

End to end went 293 ms -> 0.897 ms (0.09 % -> 14.6 %). The goal (60-70 % end to
end) is **not met**.

## 2. DMA / compute overlap -- how

The proof first: the same launch with every MAC removed takes the same time
(0.574 ms both ways). Compute is fully hidden behind DMA. Five pieces:

1. **A double-buffered** (`load_buffer(a, ..., {.depth = 2})`). The core BDs form a
   ring, ping -> pong -> ping (`next_bd`), each gated by acquire/release locks. The
   core computes strip s in ping while the DMA fills strip s+1 in pong. The ring
   runs in hardware with no host involvement.
2. **C double-buffered**. A kernel-only output window is always ping-pong: strip s
   is written while strip s-1 drains through the core MM2S.
3. **B resident** (`{.resident = true}`). Each core's B block (cn x K, here
   128 x 256 = 32 KB) is loaded once per launch; no B traffic inside the loop.
4. **No host loop between rounds** -- the key piece. The generated host code used
   to re-program the shim BDs over MMIO and `wait` on every strip
   (compute -> DMA -> host -> compute, i.e. serial). Now:
   - **A**: ONE shim BD per mesh row walks all strips in DDR, as a 3-D BD
     (e.g. d0 1024 words x d1 2 x d2 64 strips = 512 KB). Back-pressure from the
     core's locked ring paces it. (Compiler: `flowtransfer_host.cpp`, `kbWalk`.)
   - **C**: ONE out-of-order S2MM BD per core covers all rounds through its BD
     iteration counter (`#pragma output_tile_major`; compiler:
     `flowtransfer_common.cpp`, GEMM path).
   The loop over strips stays on the **core** (the kernel's `for`); only the
   host-side loop is gone. Check for this: a `for (...)` in the generated
   `host.cc` around `__Runtime_dma_bd_config` / `__Runtime_startio` /
   `__Runtime_wait` means per-round serialization.
5. **Core loop fast enough to hide**: a 2x2 `mmul<8,8,8>` register block, aligned
   64-byte loads from host-packed operands. ~1.3k compute cycles per strip, well
   inside each DMA round.

### Limits of the no-host-loop scheme (large matrices)
- **Input**: one shim BD reaches ~1024 x 1024 x 1024 words x 64 iterations.
  Beyond that, chain BDs (`next_bd`).
- **Output**: the OOO BD iteration counter is 6 bits -> **<= 64 rounds per core
  per arming**. More rounds need a host re-arm per 64-round chunk, and the re-arm
  must wait until the chunk has drained -- re-arming while cores run ahead puts
  data at stale addresses (seen: GOLDEN FAIL). Removing this needs per-core
  output channels with plain multi-dim BDs, or C gathered through a MemTile and
  written by one long BD.

## 3. Everything else that moved end to end

| Step | End to end |
|---|---|
| As generated (per-strip host loop) | 293 ms |
| One shim BD walk for A + tile-major output (compiler) | load-bound (153 ms ELF+BSS load) |
| `control_plan_op_control_packet` (ELF over control packets) + `--skip-port-bss` + `AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN` | ~1.0 ms |
| C `__Runtime_buffer_device_written`, A/B `__Runtime_alloc_uncached` | 0.84 ms |
| Shape N=512, K=256, 32-row strips (1.07 G MAC) | 1.08 ms (2x the work) |
| `KERNELCONFIGOFFLOAD` + two compiler fixes so it honours `{.resident}` | **0.897 ms (14.6 %)** |

Compiler fixes (branch `gemm-e2e-opt`; generated code for simplegemm_dataflow /
simplegemm_kernel_port / simplematmul2 is byte-identical before/after):
- memory budget matches the allocator (~57 KB of port buffers);
- the allocator places a buffer > 32 KB, clear of the klog ring;
- KCO resolves `kernel_block` on the kernel clone;
- the KCO single-buffer cross-check matches on the DMA channel;
- opt-in `AIEHLC_SHIM_BALANCE=1`;
- `kc.sh` reads `kernel_build_flags.sh` from the build's own `aout/`.

## 4. Findings worth knowing
- **Control-packet ELF load streams asynchronously**: `kload` (~0.03 ms) only
  queues it, and the real load lands inside `wait_io`. Compare end to end, not
  phase by phase. This explains an apparent "control plane slows the data run".
- **MemTile DMA addressing is neighbourhood-relative**: own memory starts at
  **0x80000** (0x0 is the WEST neighbour's -- the first data column hangs, the
  others silently write into their neighbour), and own locks start at **64** in a
  BD. aie-rt writes both fields raw.
- `control_packet_mode(aot)` (warm reload) was slower here: 1.44 vs 1.03 ms.
- Burst 32, AxCACHE 0x3, DDR placement, uncached C and shim balancing: no change.

### Retracted
Earlier "reads alone ~37 GB/s, writes alone 20.5 GB/s" were bytes / `wait_io` of
whole launches, **not** DMA probes. 37 GB/s is not physical (4 streams x 4 B/cycle).
Use Amit's palmyra213 probes (read 9.9, write 8.0, r+w 7.4 GB/s) as the reference.
Ceiling projections built on 37/20.5 are unverified.

## 5. Bound: why this architecture cannot reach 60 %
Inputs, all measured or from the driver tables:
- mixed DDR read + write: ~11 GB/s here (the DMA-only launch moves A 2.1 MB +
  C 4.2 MB in 0.574 ms, GOLDEN PASS); Amit's probes give 7.4-9.9 GB/s;
- 60 % of peak = 4.9 TMAC/s, so DDR may carry at most ~2.2e-3 B/MAC
  (at least ~450 MAC per DDR byte);
- core data memory 64 KB, MemTile 512 KB (`xaie2psgbl_reginit.c`); a core takes
  at most ~8 B/cycle in (2 S2MM channels x 32 bit).

**Today's design** (B resident in the cores, full-K A strips, C int8 written
once) moves 1/N_array + 1/K bytes per MAC. The resident B caps cn x K at about
43 KB per core, so the best case is K ~ 330 with a 512-wide array tile:
~5e-3 B/MAC, about **25 % of peak at 11 GB/s**, before any launch cost. Bigger
matrices do not help; only higher on-chip reuse does.

**An architecture that could reach ~50-60 %** (not built):
- B stationary in the MemTiles (e.g. K = N_tile = 1024: 1 MB over 4 MemTiles);
- a double-buffered A strip (256 x K) in the MemTiles;
- every core keeps an int32 C tile (~96 x 96 = 36 KB) and accumulates over K;
  A is broadcast along the row and B along the column, MemTile -> core;
- C goes to DDR once, after the full K.

The numbers for that design:
- DDR: 1/1024 + 1/1024 = ~2e-3 B/MAC, about 63 % at 10 GB/s;
- core intake: 1/48 B/MAC, so 8 B/cycle carries ~75 % of peak;
- launch cost: amortised only if one launch is >= ~10 G MAC.

The real result would sit below the smaller of those two (~50-60 %). It needs
pipeline support the compiler does not have today: MemTile buffers with
BDs and locks, an on-core K-accumulation loop with C written once, and broadcast
in both dimensions.

### Search over every legal tiling (`script/perf/gemm_e2e_bound.py`)
The search covers every K, N_tile, core tile tm x tn and K chunk that fits:
- int32 accumulators plus ping-pong chunks in <= 60 KB of core memory;
- the B column slice plus a double-buffered A in <= 512 KB of MemTile.

Each point is limited by DDR and by core intake. Launch cost and imperfect
overlap are set to zero, so this is an upper bound:

| mixed DDR bandwidth | best possible end to end | at |
|---|---|---|
| 7.4 GB/s (Amit's r+w probe) | **45 %** | K 768, N_tile 1408, core tile 40 x 176 |
| 11 GB/s (the highest mixed rate measured here) | **61 %** | K 640, N_tile 1728, core tile 48 x 216 |
| **7.8 GB/s (measured below, 2026-11-20)** | **47 %** | K 768, N_tile 1408, core tile 40 x 176 |
| 9.9 GB/s (Amit's read-only rate, an upper limit for any mix) | 57 % | K 704, N_tile 1408, core tile 48 x 176 |

Both optima fill the MemTile to the last ~2 KB. **90 % is out of reach on this
board**: the DDR bandwidth and the 2.5 MB of on-chip memory rule it out, whatever
the compiler does. 60-70 % is reachable only at the very top of the measured
bandwidth range, and only with zero launch cost and perfect overlap. A real
implementation would sit below these numbers.

### Measured: sustained mixed DDR rate = 7.8 GB/s
These are DMA-only probes: the best build (`gs18`) with every MAC removed, at 16,
32 and 64 rounds per launch. Each round moves 96 KB (A 32 KB in, C 64 KB out).
The time is host XTime around the whole launch, so no phase accounting is
involved. Steady-state calls on palmyra:

| rounds | bytes | end to end |
|---|---|---|
| 16 | 1.57 MB | 0.311 ms |
| 32 | 3.15 MB | 0.515 ms |
| 64 | 6.29 MB | 0.909 ms |

- The slope is 7.7-7.9 GB/s between every pair; the fixed cost is ~0.11 ms per
  launch.
- The real GEMM at 64 rounds takes 0.897 ms, the same as its DMA-only twin, so
  14.6 % is exactly what DDR allows for this byte count.
- The earlier 11 GB/s (bytes / `wait_io`) and the "37 / 20.5 GB/s" both came from
  the phase timers and overstate the rate.

With 7.8 GB/s the exhaustive bound above is 47 %, **but that holds only while
reads and writes share DDR at the same time**. Write-only probes (A resident in
the cores, C streamed out; 16 vs 64 rounds, no KCO) give a slope of **13.9 GB/s**,
and the bound at 13.9 GB/s is **70 %** (K 640, N_tile 1216, core tile 64 x 152).
So mixing reads and writes looks like the cost, and a design that keeps them
apart in time (A staged in the MemTiles during a read phase, C written while
the cores compute) is not ruled out. The read-only probe is not usable: it
added 0.018 ms for 1.57 MB, which is not physical. Its reads overlap the ~0.5 ms
fixed launch cost, so the slope says nothing. Re-measuring both on the KCO
build at 16/32/64 rounds. **Conclusion withdrawn: 60-70 % is not shown to be
unreachable.**

### Re-measured on the KCO build, 16 / 32 / 64 rounds (end to end, steady state)
| probe | 16 | 32 | 64 | slope |
|---|---|---|---|---|
| write-only (C 64 KB/round) | 0.256 ms | 0.349 ms | 0.544 ms | 11.3 / 10.8 GB/s, linear |
| read-only (A 32 KB/round) | 0.198 ms | 0.221 ms | 0.36-0.40 ms | not linear: ~7 GB/s between 32 and 64 |
| mixed (A + C, above) | 0.311 ms | 0.515 ms | 0.909 ms | 7.7-7.9 GB/s, linear |

- **Writes run at ~11 GB/s.** The 13.9 GB/s from the non-KCO build was too high.
- **Reads are capped by the channels, not by DDR.** A enters through only 4 shim
  MM2S channels (one per mesh row). The resnetengine measured ~2.3 GB/s per
  MM2S channel, so 4 channels give ~9 GB/s at most.
- **Effective rate for the bound's best design is ~9.8 GB/s.** That design is
  ~65 % writes, with reads and writes kept apart in time, which gives
  1 / (0.35/8 + 0.65/11).
- **The bound at 9.8 GB/s is 56 %.** It would rise only if A came in through
  more MM2S channels; a shim tile has 2, and the `{2,6}` partition has 5 shim
  tiles. The bound reaches 61 % at an effective 11 GB/s.

**Status:** 60 % sits at the edge of what the measured rates allow. It is not
shown to be impossible, and it is not shown to be reachable. It needs, all at
once:
- the MemTile-stationary design;
- read and write phases kept apart in time;
- more input channels;
- near-zero launch cost.

## 6. What remains (not built)
1. A persistent kernel re-armed in microseconds (today ~0.17-0.9 ms fixed cost per
   launch, versus ~0.1-0.3 ms of ideal work per launch).
2. MemTile staging in the compiler. Hand-edited, it took the run phase from
   0.15 to 0.12 ms, but the pipeline has no MemTile BD/lock support today.
3. An output path past the 64-round limit (see section 2).

## 8. K-accumulating GEMM with MemTile-resident B and replayed A (2026-11-20)
Kernel: `example/tileprogram/ccode/simplegemm_kacc.cc`. Every core keeps an int32 C tile
(tm x tn) across all K chunks and writes C once. The board runs used a variant with an
n-tile loop (`/tmp/claude-35620/gs33/gemm_ka.cc`), plus a hand edit
(`/tmp/claude-35620/memtile_ab.py`, applied to the generated `host.cc` / `routing.cc`):
- each MemTile (c,1) holds its column's whole B slice and replays it once per m tile;
- it double-buffers its mesh row's A tile and replays each one once per n tile;
- the shim sends every byte once.

Compiler fix that made it run: a whole-K-walk shim BD was started k_rounds times
(hang). With `output_tile_major`, the M rounds now use one BD iteration instead of a
host loop (`flowtransfer_host.cpp`, `computeMultipleInputShimBd`).

| build (palmyra, GOLDEN PASS unless noted) | end to end | % peak |
|---|---|---|
| K-acc, A and B from DDR (B re-read per m tile) | 3.50 ms / 2.42 G MAC | 8.4 % |
| + B in MemTile, replayed | 1.85 ms / 2.42 G MAC | 16.0 % |
| + n-tile loop, A double-buffered in MemTile (tm = tn = 64, kc = 96, K 1152) | **2.51 ms / 4.83 G MAC** | **23.5 %** |
| + MemTile BDs written once, only re-armed per launch | 2.25 ms | 26.2 % |
| + B received in NT parts (replay starts on part 0) | **2.24 ms** | **26.3 %** |
| C uncached instead of the invalidate contract | 2.43 ms | 24.3 % (slower) |
| 64 x 64, kc 96, two blocks (8 accumulators) per step | **2.20 ms** | **26.8 %** (DMA-bound) |
| 80 x 80, kc 48, 2 x 2 register blocks | 4.35 ms / 7.08 G MAC | 19.9 % (compute-bound) |
| 80 x 80, kc 48, two blocks (8 accumulators) per step (`gemm_kacc_ntile_80x80.cc`) | 3.42 ms | 25.3 % (still compute-bound) |
| same as 23.5 % row, DMA only (no MACs) | 2.29 ms | (25.8 %) |
| tm 96 x tn 80, kc 32 | 6.96 ms / 8.92 G MAC | 14.9 % (compute-bound: accumulator reload per 32-B chunk) |

Measured limits:
- **AIE clock on palmyra is 1000 MHz** (core timer vs XTime).
- **The on-chip DMA sets the pace.** The DMA-only probe is 2.29 ms vs 2.51 ms with the MACs.
- **Per-core input is 5.4 GB/s = 2.7 B/cycle per S2MM channel** (67 % of the 32-bit
  stream). This is the slope of DMA-only 8 vs 16 rounds: 1.41 vs 2.29 ms.
- **Fixed cost is ~0.53 ms per launch:** ELF over control packets, MemTile setup, B
  prefill, final C drain.
- **Ceiling for this design:** core input bytes per MAC = 1/tm + 1/tn.
  - 64 x 64 tiles: 32 MAC/B x 5.4 GB/s = 171 GMAC/s per core = 33 %.
  - About 42 % at most for any tile that fits in 64 KB, with accumulator and ping-pong
    buffers.
  - Going higher needs cores to share operands through neighbour memory, or a faster
    DMA channel.

Why the larger tile stays compute-bound: every K chunk reloads and re-stores the int32
accumulators. Each 64-lane acc32 is 4 VLDA + 4 VST, at 1 VLDA and 1 VST per cycle, so
2 x 2 blocks spend ~32 cycles moving accumulators per 24 MACs (kc 48). There are only
8 accumulator registers, so the next block's loads cannot overlap the current
block's MACs (`kernel.lst`). Running two blocks per step overlaps part of it
(23 % -> 30 % compute efficiency). A tile that beats 64 x 64 needs kc >= ~96 to
amortise this, and 64 KB of core memory does not fit that.

### Which input stream is slow (DMA-only probes, 64 x 96 B chunks, slope of 4 vs 8 rounds)
| probe | per-core input on the large operand |
|---|---|
| tm 16 (A tiny), B 64 rows: B only, from the MemTile, column broadcast | **~8 GB/s** |
| tm 64, tn 16 (B tiny), A replayed 4x per MemTile tile | ~4.5 GB/s |
| same, A replayed 8x per tile | ~5.9 GB/s |
| 64 x 64, both large (the 26.8 % build) | 2.7 GB/s each |

- **A single core input channel is not capped at 2.7 B/cycle.** B alone reaches ~8 GB/s.
- **A is the slow path, and refilling it is part of the reason:** more replays per DDR
  tile raise A's rate.
- **The slow A refill is not because of strided DDR reads:** laying A out contiguously
  and reading it linearly was slower (3.00 ms vs 2.20 ms).
- With both operands large, the two streams slow each other further.
- **Not the MemTile channel:** A on MemTile ch0 and B on ch1 gives the same time
  (0.965 ms).
- **Per-tile model** (A-heavy probe, 4 and 8 replays per tile): time per A tile =
  ~30 us + replays x 8.75 us.
  - The replay itself runs at ~8.4 GB/s, the same as B.
  - The ~30 us per 73.7 KB tile (~2.4 GB/s, about one shim channel's DDR read rate)
    does NOT overlap the replay, although the MemTile double-buffers A
    (BD24 -> BD25, empty / full locks per buffer).
  - **Fixed by a third A buffer** (`memtile_a3.py`): A reaches the cores at ~8.0 GB/s
    (A-heavy probe, 3 vs 6 rounds: 0.110 ms for 885 KB per core), the same as B.
    Full GEMM (64 x 64, NT 3, R 21): 1.80 ms / 4.76 G MAC = 32.3 %, GOLDEN PASS
    (196,608 checked).
  - **`__Runtime_alloc_uncached` silently returned CACHED memory for anything over 2 MB.**
    It mapped a single 2 MB block, so the 6.2 MB A was cached and every launch cleaned it
    before the DMA could start (~0.24 ms). It now maps as many 2 MB blocks as the
    buffer needs (`aie_runtime.c`). Result: **1.562 ms = 37.2 %**, GOLDEN PASS.
    Remaining per-launch time outside the stream (`wait_io`): kload 0.07 + BD config
    0.055 + ~0.11 ms.
  - **K chunk 96 -> 128 B** (64 x 64 tile; core memory: 16 KB acc + 4 x 8 KB A/B +
    2 x 4 KB C): halves the accumulator reload per MAC relative to the MACs.
    **1.401 ms = 41.5 %**, GOLDEN PASS. `wait_io` 1.16 ms = the DMA-only time of the 96-B
    build, so the stream is the limit again (~8 GB/s per core).
  - **The MemTiles are not the limit.** A on the row-2 MemTiles, B on row 1, one stream
    per MemTile (`memtile_split.py`): 1.405 ms, the same. The limit is ~8 GB/s into each
    core in total, split over its two S2MM channels.

### K 2560 with both MemTile rows: 44.5 %
B (3 n tiles x 64 x 2560 = 491 KB) in MemTile row 1, A (3 x 164 KB) in row 2
(`memtile_split.py`): **2.906 ms / 10.57 G MAC = 44.5 %**, GOLDEN PASS.
- Streaming is 2.66 ms against 1.29 ms ideal (48.6 %, near the 50 % core-input bound).
- Fixed cost is 8.5 % of the launch.
- DDR carries 19.9 MB in 2.9 ms = 6.9 GB/s.

### Software-pipelined kernel: 55.9 %
A DMA-only twin of the 44.5 % build streamed in 2.02 ms against 2.66 ms with compute,
so that build was **compute-bound**: ~2,110 cycles per 64x64x128 chunk against 1,024
ideal (49 %). In `kernel.lst`, each 16x32 step ran 32 accumulator loads, then the
MACs, then 32 stores that overlapped nothing.

The new kernel (`gemm_kacc_ntile.cc`):
- **Two register sets X / Y of 4 accumulators.** While one set runs a 16x16 block's
  MACs, the other stores the previous block and loads the next.
- **Branch-free steady state.** The first and last blocks are peeled; runtime `if`s
  split basic blocks and chess does not schedule across them.
- **`__restrict` on the int8 operand pointers.** Char pointers alias everything, so
  int32 stores could not move past them.
- **Accumulators zeroed once per tile and converted to int8 once per tile**, so a
  single compiled chunk body is needed.

The middle-chunk loop went from 57 % to ~80 % VMAC density.
**2.311 ms = 55.9 %**, GOLDEN PASS. `wait_io` 2.06 ms is about the DMA-only 2.02 ms,
so the build is input-bound again.

Traps:
- **AIE2PS program memory is 16 KB, but the kernel.map PM model says 1 MB.** Three
  flattened chunk variants (17.9 KB) linked and hung the board silently. Check
  `Section summary for memory 'PM'` Total < 16384.
- **A multi-line `#define` above the `__global__` kernel is NOT copied** into the
  extracted kernel (only one-line defines are). Put multi-line helper macros inside
  the kernel body.
- **`c##0.to_vector` is a pp-number paste error.** Write `(c##0).to_vector`.
- **chess backend "no mappings for bundle ... ssrs_store"** on accum load followed by an
  int8 SRS store. Put `chess_separator_scheduler()` between them.

### After 55.9 %: what moved and what did not
| change | end to end |
|---|---|
| shim BDs + OOO channel config written on the first launch only (`shim_bd_once.py`) | 2.288 ms = 56.5 % |
| + `#pragma control_packet_mode(aot)`: warm relaunch resends only reset + data, not PM (kload 0.074 -> 0.037 ms) | **2.258-2.281 ms = 57.0 %**, GOLDEN PASS |
| hand-rolled "skip the ELF, only reset the cores" | 58.0 % but **GOLDEN FAIL**: the load's reset sequence does more than the core-control register (core DMA channels keep running their ping-pong chain) -- use the runtime's AOT warm path |
| uncached C (now really uncached) | 2.32 ms (no change: the invalidate runs inside the wait) |
| MMIO ELF loader + `AIEHLC_PM_WARM_SKIP` | 2.62 ms (the .data rewrite costs 0.38 ms) |
| K 1536, NT 5 (less A from DDR) | 42.2 % (slower per chunk) |
| B shared between row pairs, 64 x 64 (`memtile_bshare.py`) | 2.42 ms; DMA-only twin 2.08 ms = no gain |
| B shared, 48 x 96 tile (fits only with B halves) | 2.706 ms = 51.2 %, GOLDEN PASS |
| A laid out chunk-major in DDR, shim reads it linearly (4 KB bursts) | 2.47-2.66 ms = 49-52 %, GOLDEN PASS (slower than the strided 128-B reads) |
| first chunk of each tile as a second body (mul init, no zeroing; PM 15.5 KB) | 2.41 ms = 53.5 %, GOLDEN PASS (slower than one body) |
| 80 x 80 tile, kc 48, pipelined kernel (odd 25-block tail) | 4.37 ms / 13.9 G MAC = 39.0 % (compute: ~40 % kernel efficiency) |
| 80 x 64 tile, kc 96 | 2.57 ms / 10.9 G MAC = 51.8 % (compute: ~53 %) |
| 64 x 96 tile, kc 64 (17 % fewer input bytes per MAC) | 3.79 ms / 15.1 G MAC = 48.8 % (compute-bound: kc 64 doubles the accumulator traffic per MAC) |

B sharing is correct after two fixes:
- **The MemTile part lock is released with +2** (two half-stream readers). With +1 the
  second stream waits for the whole part and the cores deadlock.
- **MemTile BD wraps are 10-bit: 1024 encodes as 0 (dimension off).** A 1024-word d0
  wrap made the half-stream BD read linearly. Split it into 512 x 2.

It does not pay off, though: neighbour reads and the pair coupling cost more than the
input they save.

Measured per-launch split (64 x 64, K 2560): kload 0.07 + MemTile re-arm 0.01 + shim
BD / start 0.15 ms (0 with `shim_bd_once`) + stream 2.06-2.17 ms. The DMA-only stream
is 2.02 ms = 57.8 % if compute were free. Per core input is ~10 GB/s (A + B together).

**DMA-only twin of the 57.0 % build** (same pragmas and host edits, no MACs):
2.185-2.220 ms = **58.2-59.2 %**. Even with free compute this configuration stays under
60 %: the stream sets the pace, and compute adds only ~0.08 ms.

**Per-core input is not buffer- or coupling-limited.** The same DMA-only twin with a
3-deep input ring on every core (3 buffers per input, counting locks at 3, hand-edited
KCO BD chain) streams in 2.181-2.208 ms, the same as with 2 buffers. Together with
the probes above (MemTile channel swap, MemTile split, transfer size, B sharing):
~10 GB/s into a core with both S2MM channels busy (~8 GB/s with one) is a hardware
limit of this data path. **For this design the DMA-only twin -- 58-59 % -- is the
ceiling.**

**Weight-resident B: 64.7 % (GOLDEN PASS).** `b_resident.py` loads B into the MemTiles on
the first launch only. Later launches re-mark the B parts full and skip B's shim transfer
and MemTile S2MM; A and C still move every launch. Result: 1.999-2.013 ms = 64.2-64.7 %
(57.0 % with B re-read). Removing ~2 MB of the ~20 MB per-launch DDR traffic, and B's
prefill wait at the start, is worth 7.7 points, consistent with a DDR / start-latency
bound. Valid only when B is the same on every launch (fixed weights, e.g. an inference
layer). A general GEMM with a new B per call stays at 57.0 %.

**Is it DDR?** The 57 % build moves 19.9 MB per launch (~9 GB/s), which made DDR a
suspect. Test: NT 4, K 2048 (B fills MemTile row 1 exactly) cuts DDR bytes per MAC by
8.5 %, but ran at 1.95 ms / 8.05 G MAC = **50.4 %** (GOLDEN PASS), with DDR at only ~7.1
GB/s. Per-chunk time rose: NT 3 1.63 us, NT 4 1.95 us, NT 5 2.07 us. So DDR is not the
binding limit **for NT 4**.

NT 2 (K 2560, N 512): 2.89 ms / 10.07 G MAC = **42.5 %**, GOLDEN PASS, with DDR at
8.6 GB/s.

| NT | K | chunks per tile | DDR rate | per chunk | end to end |
|---|---|---|---|---|---|
| 2 | 2560 | 20 | 8.6 GB/s | 2.36 us | 42.5 % |
| 3 | 2560 | 20 | 8.8 GB/s | 1.63 us | 57.0 % |
| 4 | 2048 | 16 | 7.1 GB/s | 1.95 us | 50.4 % |
| 5 | 1536 | 12 | ~6 GB/s | 2.07 us | 42.2 % |

**Two limits meet at NT 3:**
- **DDR, ~9 GB/s read+write in this pattern.** NT <= 3 runs at that rate. NT 2 reads
  more A per MAC, so it is slower.
- **Per-tile overhead**, when MemTile capacity forces a smaller K (fewer chunks per
  tile). NT 4 / 5 do not reach the DDR rate.

NT 3 with K 2560 is where both limits are lowest. Raising N at K 2560 needs more
MemTile than the two rows hold (A x3 491 KB in row 2, B 491 KB in row 1). At this
traffic, ~9 GB/s of DDR bounds the 57 % build at ~58-59 %, which matches its DMA-only
twin.

**The tile is bounded by kc.** The pipelined kernel's efficiency falls with the K
chunk, because there is more accumulator reload per MAC: kc 128 ~80 %, kc 96 ~53 %,
kc 48 ~40 % (board timing). At kc 128 only 64 x 64 fits 64 KB of core memory, so
64 x 64 / kc 128 is the best tiling found.

**B-shared 48 x 96 probes:**
- Using only the own half (no neighbour reads; wrong data, speed only): 2.556 ms.
- With neighbour reads: 2.706 ms, so the reads cost ~0.15 ms.
- Even without them the 48 x 96 kernel reaches only ~60 % VMAC density, against ~80 %
  for 64 x 64.

**Where it stands:** this 64 x 64 / kc 128 configuration is bounded at ~58-60 % end to
end by core input (~10 GB/s). Every way of lowering input bytes per MAC that was tried
costs more elsewhere:
- a bigger tile needs a smaller kc (accumulator traffic);
- B sharing costs neighbour reads and pair coupling.

Past ~60 % needs either a higher per-core input rate (cause of the ~10 GB/s cap
unknown) or accumulators that stay in registers across K chunks (larger kc), which
64 KB of core memory does not allow.

### Where 41.5 % stood (64 x 64 tile, kc 128, K 1152)
- **Core input:** 32 MAC/B x 8 B/cycle = 256 MAC/cycle = **50 %** while streaming.
  `wait_io` is 1.16 ms against 0.58 ms ideal.
- **Fixed cost:** ~0.24 ms per launch outside the stream: control-packet ELF 0.07, BD
  config 0.055, rest ~0.11. That is 17 % of the launch.
- **DDR is close too:** 10.4 MB per launch in 1.40 ms = 7.4 GB/s, against 7.8 GB/s
  measured for mixed read+write. A bigger N or K (both MemTile rows give 1 MB per
  column) would lower the bytes per MAC.
- **Past 50 % needs fewer input bytes per MAC per core.** A larger tile does not fit
  64 KB at kc 128, and a smaller kc costs compute. The candidate is B shared between
  paired rows through neighbour memory: ~67 % stream bound. That is not expressible in
  aiehlc today.
- **Script bug fixed:** `memtile_ab.py` reused lock ids when NT > 4.

**Correction to section 9:** that bound used 2.7 B/cycle as a per-channel cap. It is not
a channel cap, so the 38-54 % figures there are not hard ceilings.

## 9. Bound with the measured core-input rate (2026-11-20)
`AIEHLC_BOUND_CH=2.7 script/perf/gemm_e2e_bound.py <GB/s>` now models what each core
receives. The A channel carries 1/tn B per MAC and the B channel 1/tm, at 2.7
B/cycle each (measured above). Core memory also counts the C int8 ping-pong buffers.
Launch cost is 0 and compute efficiency 100 %, including at kc = 32 (measured: 15-25 %).

| per-channel core input | mixed DDR | best end to end, any tiling |
|---|---|---|
| 2.7 B/cycle (measured) | 7.8 GB/s (measured) | **38 %** |
| 2.7 B/cycle (measured) | 11 GB/s (optimistic) | 46 % |
| 4 B/cycle (full stream width) | 11 GB/s (optimistic) | 54 % |

**No stream-fed design reaches 60 %**, even granting a full-width stream, 11 GB/s,
zero launch cost and perfect compute. That covers any tiling, with or without MemTile
staging. The bound does not cover cores reading operands directly from neighbour tile
memory. That design is not expressible in aiehlc today, and its rate on palmyra is
unmeasured.

## 7. Files
- Branch `gemm-e2e-opt` (`53406fee`, `6d6f7500`), worktree `.worktrees/gemm_e2e`.
- Per-core peak example: `example/tileprogram/ccode/simplegemm_peak.cc`.
- All measurements: `.cursor/skills/gemmendtoend/SKILL.md`.
- Test programs (not in repo): `/tmp/claude-35620/gs18/gemm_s2.cc` (best end to
  end), `gs13` (DMA-only probe), `hand1..3` (MemTile hand edits).

## VEK385 farm board (vek385-6 @ gomphus6, 2026-11-22)

The same ELFs ran unchanged (netload), GOLDEN PASS 196,608/196,608 each:

| build | palmyra (998 MHz array) | VEK385 time | VEK385 % of own peak |
|---|---|---|---|
| gs79, A+B from DDR | 2.33 ms, 57.0 %, 9.3 TOPS | 1.643 ms, 12.9 TOPS | **62.8 %** |
| gs90, weight-resident B | 64.7 % | 1.576 ms, 13.4 TOPS | **65.5 %** |

**The array clock on the farm VEK385 is 1.25 GHz, not 998 MHz.** Measured from a core
and a shim timer (0x340F8/0x340FC) read twice over xsdb 5 s apart: 1249.1 / 1250.1 MHz.
The test hard-codes 998 MHz, so it prints 78.7 % / 82.1 % on this board; those figures
are wrong. The true peak is 16 x 512 x 2 x 1.25 GHz = 20.5 TOPS.

The wall-time gain is 1.42x, against a 1.25x clock ratio. So most of the speed-up is the
clock, which a stream-/shim-bound design scales with (4 B/cycle per stream). The rest is
DDR relief, worth about 6 points of efficiency. More memory controllers do not lift the
design to 100 %: the per-shim-channel / per-core input rate remains the limit.

## Kernel v2: 81.6 % -> 92.0 % per chunk (`gemm_kacc_v2.cc`, 2026-11-22)

Each core stamped its own cycle counter into its last output tile (KCYC). The measurement
build `gk1` on VEK385 split a core's time as follows:

| phase | share |
|---|---|
| MAC chunks | 79.6 % |
| waiting for input | 14.0 % |
| lock and loop overhead | 5.0 % |
| int32 -> int8 conversion | 1.2 % |

The kernel was the first limit. A **bench** variant runs `KA_CHUNK` 64 more times on resident
buffers and stamps the cycles per chunk (ideal: 1,024):

| kernel | cycles per chunk | efficiency |
|---|---|---|
| gemm_kacc_ntile (X/Y sets, one accumulator pointer) | 1255 | 81.6 % |
| + operands prefetched one k-step ahead, separate acc store / load pointers | 1280 | 80.0 % (worse) |
| + accumulators split over two 8 KB banks (acc pinned at 0x72000) | 1233 | 83.0 % |
| + two-step prefetch, rotating addresses (no div/mod), bank split | **1113** | **92.0 %** |

- **Count bundles, then measure: the listing does not show stalls.** The 1-step prefetch
  loop scheduled in 141 bundles instead of 150, yet ran slower. Its separate store and
  load pointers let `VST acc(b)` and `VLDA acc(b+2)` issue in the same cycle. Both are
  2 KB apart, so they sit in the same 8 KB **bank**, which cost ~130 stall cycles per chunk.
- **Fix: put block b's accumulators in bank `(b >> 1) & 1`.** The store of b and the reload
  of b+2 then always hit different banks. `alignas(8192)` on the static `acc` places it
  at 0x72000, i.e. the two banks 0x72000 and 0x74000.
- **The remaining loss** is about 5 register moves per 2-block iteration (the operand
  rotation) and about 90 cycles of chunk prologue/epilogue.
- **Do not unroll the block loop to 4 blocks:** chess was still scheduling it after 30 min.

End to end (palmyra at 998 MHz, VEK385 at its real 1.25 GHz), GOLDEN PASS 196,608 everywhere:

| build | palmyra | VEK385 |
|---|---|---|
| A + B from DDR: gs79 -> **v2** | 57.0 -> **58.4 %** | 62.8 -> **67.9 %** (1.521 ms) |
| weight-resident B: gs90 -> **v2r** | 64.7 -> **64.5-64.9 %** | 65.5 -> **71.5 %** (1.446 ms) |

Palmyra is DDR-bound, so the faster kernel barely moves it.

### Why the current layout cannot reach 95 % (VEK385 measurements)

- **The input stream caps the core at 87.5 %.** In the DMA-only twin (`gk2`, no MACs), chunks
  complete every ~1,170 cycles: 16 KB / 1,170 cycles = 14 B/cycle per core, or ~7 B/cycle per
  S2MM channel (the stream is 64-bit). A 64 x 64 tile needs 1/32 B per MAC, so even a perfect
  kernel tops out at 14 x 32 = 448 MAC/cycle = 87.5 %.
- **95 % needs fewer input bytes per tile.** The LP `share_lp.py` places operand streams so that
  cores read their second operand from a north / south neighbour's memory.
  - The standard 4 x 4 layout (A on mesh rows, B on columns) only gets to 1.5 streams per tile.
  - A **2 x 8 logical grid** gets to **1.0**. Per column, mesh rows 0..3 receive A0, B_c,
    B_{c+4}, A1, and each memory is read by two vertically adjacent cores.
- **Neighbour memory reads (bench, 64 chunks):**

  | case | cycles per chunk | cost |
  |---|---|---|
  | a neighbour's buffer that nobody else reads | 1113 | free |
  | the same buffer read by two cores at once | 1169-1174 | +5 % |
  | two shared operands, both read from the same memory | 1206-1261 | +8-13 % |

  - The +5 % comes from one 8 KB bank serving 4 loads per 4 cycles.
  - To remove it, spread each shared buffer over two banks with a 3-D S2MM BD.
- **The lock protocol for one buffer with two consumers:**
  - F: DMA -> first consumer, +1 per filled buffer.
  - G: first -> second consumer, released right after the first consumer's acquire.
  - E: both consumers -> DMA; the DMA acquires -2.

  A single counting full lock would let a fast consumer take the slower consumer's count and
  read a buffer that is not yet filled.

## 2 x 8 shared-operand layout (`share2x8.py`, VEK385, 2026-11-22)

**Bit-exact, persistent, 74.2 % of the true 1.25 GHz peak** (0.930 ms per 7.05 G MAC; weight-resident B; one tile per output packet; GOLDEN PASS; STRESS: every launch checked, no data errors).
Build: base = `gemm_kacc_v2.cc` with `KA_R 21`, `KA_NT 2` (+ the README recipe), then
`share2x8.py <aout/worklocal> --r2 42 --nt2 1 --k 2560 --bres --single --persist [--stress N] [--kcyc]`,
`rm build/{host.o,routing.o,host}`, and `hostcompile.sh`.

- **Layout.** The logical grid is 2 A strips x 8 B strips (`share_lp.py`).
  - Column c's tiles host one operand stream each: mesh row 0 = A0, 1 = B_c, 2 = B_{c+4}, 3 = A1.
  - Every core reads its operands from the host tiles directly below / above it (neighbour
    memory: north 0x60000, south 0x40000), so each tile receives one stream instead of two.
- **Bank-split buffers + opposite phases.** Each 8 KB chunk is split: rows 0-31 in bank 2,
  rows 32-63 in bank 3 (4 x 16 KB programmer banks, AM027). The two readers of a buffer walk
  its halves in opposite order. Bench: 1120 vs 1113 cycles / chunk unshared; reading the same
  bank in lockstep costs +60 (single shared operand) or +150 (both operands).
- **Locks (per hosted channel):**
  - F (DMA -> first reader);
  - G (first -> second reader, released right after the first acquire);
  - one **E per slot** (both readers -> DMA, which acquires -2). A per-channel E let a fast
    first reader free a slot the second reader was still in: corrupt rows on ~4 of 5 launches.
- **Generator pieces:**
  - `share_route.py`: keeps the generated output and control routes, books their ports (and
    the control fabric's port 0 on data rows), BFS-routes the 32 input nets.
  - `share_host.py`: rewrites the shim A / B / C BDs for the target shape, with contiguous
    DDR streams.
  - KCO hosted-stream DMA in `kernel.cc`; kernel body from `share2x8_chunk.inc`.
- **Persistent kernel (`--persist`).** Loaded once; later launches only release a go lock
  (lock 14) on the 16 cores. `kload` / `coreen` 0.03 / 0.01 ms -> 0 (0.961 -> 0.930 ms).

Traps hit on the board (each cost a hang or corrupt data):

| symptom | cause | fix |
|---|---|---|
| GOLDEN FAIL, data noise | tile S2MM BD `d0_wrap = 256`: wraps are **8-bit**, 256 = 0 = dimension off | 512 B x 8 instead of 1 KB x 4 |
| hang (outputs pending) with > 64 tiles / core | generated host loop over output rounds, and `memtile_ab.py`'s "B once" regex hit it | output BD per core with iteration <= 64; two tiles per packet when needed |
| two tiles per packet: deadlock | a packet waiting mid-route for its 2nd tile holds the row's merged output path -> other cores' outputs back up -> shared inputs not released | ping BD acquires full -2 (packet starts only when both tiles are written); pong BD release-only. Still ~10 % slower than one tile per packet (row contention) |
| hang exactly halfway through a launch | kernel chunk count came from the BASE build's `KA_K`, not the target K | emit the target count |
| hang in the first launch, only when `kernel.o` was reused | `hostcompile.sh` reuse kept a **stale control-packet image** (`kernel_<f>_ctrlpkt.h` from the base worklocal) -> the cores ran the OLD kernel | stamp now hashes `kernel.cc`'s `#include`s too, and reuse requires the recorded ctrlpkt sha to match |

Per-core cycle split (k1s, non-persistent; MAC 85.8 %, input wait 9.0 %, convert 1.9 %, other 3.2 %):
the chunk runs at ~1168 cycles in the shared layout vs 1120 in the bench (DMA bank conflicts).
Next: fuse chunk boundaries (prologue / epilogue ~90 cycles + call), zero / convert inside the
first / last chunk, find the 9 % input wait.

## Tile pipeline, persistent kernel, and the per-board plan (2026-11-22, later)

**VEK385: 0.891 ms per 7.05 G MAC = 77.4 % of the true peak**, GOLDEN PASS, no errors in any stress
launch. Build: `share2x8.py ... --r2 42 --nt2 1 --k 2560 --bres --single --persist --tile`.

- **`--tile` (`share2x8_tile.inc`) runs one software pipeline per tile, across its chunks.**
  - At a chunk boundary, chunk j's block 15 overlaps chunk j+1's block 0: j+1 is acquired
    first, its first operands are prefetched during block 15, and j is released right after
    its last reads. Before: 0.930 ms, now 0.891.
  - The int32 -> int8 conversion is a separate noinline function. Inlined, it hit chess's
    "no mappings for bundle (SRS + store + add)".
  - Program memory: 15.7 KB of 16 KB. Every further kernel change must stay below that.
- **No-wait bench (`--bench`).** The same `ka_tile` runs with lock values 0 (acquire >= 0 and
  release 0 are no-ops) on live buffers: **~1190 cycles / chunk** (85.5 %), against
  **~1262** in the run.
  - Lock waits are therefore only ~6 %.
  - The rest is the kernel: about 120 cycles of static boundary / loop overhead and about
    45 cycles of DMA bank conflicts.
  - A branch-free boundary (acquire `role ? F : G`, release by `role`) measured *slower*
    (0.91-0.93 ms). Keep the branches and the fence.
- **A from DDR is not the limit at this size.** NT2 2 (half the A traffic) gave 0.902 ms.
  - The first try at NT2 2 was 0.43 ms slower per launch. `__aie_launch` queued cache
    maintenance with the BASE build's sizes, so the 13.8 MB A range ran past the target's
    6.9 MB non-cacheable buffer and the host cleaned 13.8 MB of cache on every launch.
  - The generator now passes the target sizes.
- **palmyra: the shared layout loses** (52-57 % vs 64.7 % for the 4 x 4 + weight-resident
  design). Palmyra is DDR-bound and the 4 x 4 design moves fewer bytes per MAC.
- **DDR zones on VEK385 (probed from the A78).** `DDR_LOW1` (0x8_0000_0000) is real, separate
  memory. `DDR_CH_1` (0x500_0000_0000) hangs on the first read: not populated with this PDI,
  although the BSP maps it. So the 3 MCs are interleaved behind LOW0 / LOW1.
  - `--zones A=base:size,...` (via `__Runtime_alloc_zone`) places buffers when a board has
    separate zones.

### Solution choice from the memory system: `script/perf/gemm_plan.py`

- **What it holds:**
  - board profiles with the measured facts: MC count; which zones exist, on which MC, and
    whether they are interleaved; DDR read and write rates; shim channel rate; AIE clock;
  - both designs' constraints (MemTile capacity, at most 64 output tiles per core, K not
    split because the output is int8);
  - a cost model, max(core, DDR, shim A) plus B prefill plus launch.
- **What it does:** ranks the feasible tilings, adds A / B / C zone placement when there are
  separate controllers, and prints the build commands.
- **Calibration:** `--check` compares it with the 8 measured runs, worst error **3.0 points**.
  - palmyra fits `reads / 16.1 GB/s + writes / 3.58 GB/s`. Reads and writes do not overlap on
    the one controller, and writes are slow. That is why the 4 x 4 design, with fewer writes
    per MAC, wins there.

| board | memory system | chosen | model (measured) |
|---|---|---|---|
| palmyra | 1 MC, DDR-bound | 4 x 4 MemTile-staged, weight-resident, R 21 NT 3 K 2560 | 62.4 % (64.7 %) |
| VEK385 | 3 MC interleaved, DDR not binding | 2 x 8 shared, persistent, tile pipeline, R2 42 NT2 1 K 2560 | 76.4 % (77.4 %) |
| a board with 3 separate MC zones | separate controllers | 2 x 8 with `--zones` (A, C, B on different controllers) | -- (not measured) |
