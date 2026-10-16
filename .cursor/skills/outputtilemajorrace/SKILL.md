---
name: outputtilemajorrace
description: Spatial-halo conv gives GOLDEN FAIL only after the kernel got faster (whole 3136-byte output tiles wrong, pattern per mesh column, passes when the core is slowed with a spin); host.cc has an scf.for re-programming shim S2MM OOO BDs per height slab. Also: KCYC cycle stamps, mismatch map, deferred cache sync, warm ELF reload, non-cacheable staging.
---

# Output BD re-programming race (conv2dstem)

## Symptom
`GOLDEN FAIL` with whole rounds wrong (test_conv2d `MISMAP` shows ~2.5k mismatches
per round for some (col,row,round)), plausible values, identical between runs of
the same build, gone when each kernel round is slowed (20k-cycle spin).

## Cause
Dense HWC output = 2-D per-core round walk (width x height); a BD has one
iteration dim, so `buildOutputTileDescriptor` folds width into the BD and makes
height a host `scf.for` that rewrites the S2MM OOO BDs between slabs. Fast cores
send the next slab while BDs are rewritten -> data lands at stale addresses.

## Fix
`#pragma output_tile_major` (aiehlc.cc -> `routing.output_tile_major` ->
`flowtransfer_common.cpp`): each core's rounds contiguous, one BD per core,
`totalRounds=1`, straight-line schedule. Host converts layout (`collect_ofm_*`).
`ScheduleSequentialOpPass` starts S2MM (sinks) before MM2S (sources).

## Measuring
- `#define CONV2DSTEM_KCYC 1` (unconditional literal; the kernel extractor drops
  `#define`s inside `#if`). Cores stamp cycles into their last tile; test prints
  `KCYC core N`. GOLDEN then fails on exactly those bytes.
- Never chain a board run after a failed build: `apppaltest -y` silently picks a
  stale `debugcache/kco_scratch` ELF that can hang the board.

## Runtime pieces added alongside (aie_runtime.c)
- `__Runtime_sync_for_dev_deferred` / `__Runtime_dsync_drain` (emitted by both
  `__aie_launch` emitters). Do NOT drain inside `__Runtime_sync_for_cpu`: the
  runtime calls it for every ctrl ack token (kload 28 -> 84 us).
- `__Runtime_buffer_device_written` (invalidate-only, overlapped with wait_io).
- `__Runtime_alloc_uncached` (2 MB NC block below 4 GB) for CPU-written inputs.
- Warm ELF reload (skips program-memory accesses; keyed on blob/fabric/dev/
  partition gen/`g_elf_load_seq`); `ctrl_plan_init` snapshot cache.
