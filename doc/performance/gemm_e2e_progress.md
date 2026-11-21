# int8 GEMM on the 4x4 mesh: end-to-end progress (aiehlchj-90)

Source session: **aiehlchj-90** (Claude Code, aiehlc repo). Branch `gemm-e2e-opt`
(worktree `.worktrees/gemm_e2e`). Board: palmyra (`apppaltest.py --netload`).
Every number below is a board run with a host golden check. The golden check is
bit-exact on a subsample of C (e.g. 200,241 outputs), not on all of C.

## 1. Where it stands

| Metric | Result | Window |
|---|---|---|
| Per-core compute | **91.5 %** of int8 peak | core cycle counter around the compute loop only |
| End to end, best | **56.5 %** (2.288 ms per 10.57 G MAC: software-pipelined kernel + shim BDs written once; 55.9 % = 2.311 ms; before it 44.5 % = 2.906 ms: K 2560, A in the row-2 MemTiles (3 buffers), B in row 1, A uncached, 128-B K chunks; 41.5 % / 37.2 % / 32.3 % / 26.8 % before; MemTile-staged A and B, hand-edited host/routing; section 8) -- 14.6 % (0.897 ms per 1.07 G MAC) from the compiler alone | host XTime around the whole launch: kernel load, BD config, DDR in/out, cache sync |
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
| shim BDs + OOO channel config written on the first launch only (`shim_bd_once.py`) | **2.288 ms = 56.5 %** |
| uncached C (now really uncached) | 2.32 ms (no change: the invalidate runs inside the wait) |
| MMIO ELF loader + `AIEHLC_PM_WARM_SKIP` | 2.62 ms (the .data rewrite costs 0.38 ms) |
| K 1536, NT 5 (less A from DDR) | 42.2 % (slower per chunk) |
| B shared between row pairs, 64 x 64 (`memtile_bshare.py`) | 2.42 ms; DMA-only twin 2.08 ms = no gain |
| B shared, 48 x 96 tile (fits only with B halves) | 2.706 ms = 51.2 %, GOLDEN PASS |

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
