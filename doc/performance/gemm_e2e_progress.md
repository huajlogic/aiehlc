# int8 GEMM on the 4x4 mesh: end-to-end progress (aiehlchj-90)

Source session: **aiehlchj-90** (Claude Code, aiehlc repo). Branch `gemm-e2e-opt`
(worktree `.worktrees/gemm_e2e`). Board: palmyra (`apppaltest.py --netload`).
Every number below is a board run with a host golden check. The golden check is
bit-exact on a subsample of C (e.g. 200,241 outputs), not on all of C.

## 1. Where it stands

| Metric | Result | Window |
|---|---|---|
| Per-core compute | **91.5 %** of int8 peak | core cycle counter around the compute loop only |
| End to end, best | **14.6 %** (0.897 ms per 2.15 G MAC) | host XTime around the whole launch: kernel load, BD config, DDR in/out, cache sync |
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
| Shape N=512, K=256, 32-row strips (2.15 G MAC) | 1.08 ms (2x the work) |
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

## 5. What remains (not built)
1. A persistent kernel re-armed in microseconds (today ~0.17-0.9 ms fixed cost per
   launch, versus ~0.1-0.3 ms of ideal work per launch).
2. MemTile staging in the compiler. Hand-edited, it took the run phase from
   0.15 to 0.12 ms, but the pipeline has no MemTile BD/lock support today.
3. An output path past the 64-round limit (see section 2).

## 6. Files
- Branch `gemm-e2e-opt` (`53406fee`, `6d6f7500`), worktree `.worktrees/gemm_e2e`.
- Per-core peak example: `example/tileprogram/ccode/simplegemm_peak.cc`.
- All measurements: `.cursor/skills/gemmendtoend/SKILL.md`.
- Test programs (not in repo): `/tmp/claude-35620/gs18/gemm_s2.cc` (best end to
  end), `gs13` (DMA-only probe), `hand1..3` (MemTile hand edits).
