---
name: postlaunchoutputinval
description: A launch got slower after merging main although kernel.cc / routing.cc / the DMA program are byte-identical -- host.cc's __aie_launch now ends with __Runtime_sync_for_cpu(dev, _tN, _sN) on every output. Use when an end-to-end number drops by a fixed per-launch amount proportional to the output size (e.g. GEMM 85.4 % -> 77.8 %, +0.11 ms for a 3.9 MB C).
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Post-launch output invalidate

## What changed
`tilinglinalg_pipeline.cpp emitSyncCalls`: after `host_canonicalized` and `__Runtime_dsync_drain()`,
every output argument gets `__Runtime_sync_for_cpu`. It is a correctness fix: while the array runs the
A78 may speculatively prefetch output lines, so without a post-launch invalidate the CPU can read the
buffer's old bytes (VEK385_2, FA D40). Do not remove it.

## Cost
On a cached buffer it is a by-VA invalidate of the whole output: ~0.1 ms for 3.9 MB on VEK385 -- 8 %
of the 1.15 ms 2 x 8 GEMM launch (85.4 % -> 77.8 %). Earlier numbers that did not pay it only
invalidated once after the timing loop.

## Fix (application side)
Allocate the output non-cacheable: `__Runtime_alloc_uncached(bytes)` (fallback `__Runtime_Alloc`).
`__Runtime_sync_for_cpu` sees the range covered by the non-cacheable map (`rt_nc_covers`) and only
issues a `dsb sy`. The CPU reads of the result are then uncached (outside the timed launch).
Measured: GEMM 4 x 4 back to 85.47 %, 4 x 2 86.60 %, GOLDEN PASS.

## Diagnose
Diff the generated host.cc against a good build: a new `__Runtime_sync_for_cpu` line in `__aie_launch`
with identical kernel.cc / routing.cc / aiehlc_plan.h points here.
