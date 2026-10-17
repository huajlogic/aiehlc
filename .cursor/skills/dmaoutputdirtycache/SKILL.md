---
name: dmaoutputdirtycache
description: An AIE op's DDR output is correct except one or two 64-byte lines (e.g. exactly the first 4x8 tile, 128 B) that hold zeros or stale values, different garbage on every run, while the kernel's own state checks out. Host output buffer allocated/written by the A78 without a cache clean before the AIE wrote it.
---

# Dirty host cache lines overwrite AIE DMA output

## Symptom
whisperengine et1 `ln-folded gemm`: 32 of 316800 outputs wrong, always rows 0..3
x cols 0..7 (the first 128 B of the output tensor), ~0 on the first run, other
plausible-looking values on the next. Stats read back from the core were exact;
removing software pipelining changed nothing.

## Cause
The test allocated the output with `__Runtime_Alloc` and never wrote/cleaned it.
Lines of that buffer were dirty in the A78 data cache (allocator / earlier use).
The AIE wrote DDR; later the cache evicted the dirty lines on top of the DMA
output; `__Runtime_sync_for_cpu` (invalidate) then read DDR with the stale lines.

## Fix
Every buffer the AIE writes: write it once on the host (e.g. `memset 0xFF`, which
also makes unwritten outputs obvious) and `__Runtime_sync_for_dev` it BEFORE the
op runs. eng/host.cc `act()` does memset + sync; et1 tests do the same.
Same family: an earlier whisperengine bug where `memset` without
`sync_for_dev` corrupted outputs the same way.
