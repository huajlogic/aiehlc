---
name: kbtilemajoroutput
description: A kernel-only GEMM with `#pragma output_tile_major` whose output port is not N wide (bf16 C declared `aie::shape<M, N * 2>` on int8 ports) runs but GOLDEN FAILs almost everywhere; the values are right but sit at the wrong places (only the first 256 B of each tile right); no `routing.tiling` in the build log, no `[OutputTileDescriptor] GEMM output_tile_major` line; output shim BD `d1_stride=<C row bytes>`; or after a fix the output BD has `len=0` and the launch hangs on the output shims
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Tile-major output for a kernel-only port the GEMM model does not match

## Symptom

`example/tileprogram/ccode/gemm_plan/gemm_plan_4096x512x4096_bf16.cc`: every launch finishes, GOLDEN FAIL
on ~99.8 % of the outputs. A per-block map (`GP_DEBUG_MAP` in `gemm_plan_body.cc`) shows only the first
two 8 x 8 blocks of tile 0 right, and a search of the reference shows the "wrong" values are right values
from elsewhere in the tile: kernel byte k lands at host byte `(k / 256) * 1024 + k % 256` -- the tile was
written row-major into C (rows of 256 B at the C row stride), not back to back.

## Cause

`#pragma output_tile_major` is applied in `buildOutputTileDescriptor` (`helper/flowtransfer_common.cpp`)
only on the GEMM path, which needs the GEMM tiling (`passState.tileM`, from `#routing.tiling`). The front
end derives that tiling by matching C against A and B; a bf16 C declared as `N x 2` bytes on int8 ports
does not match B's N rows, so no tiling is made, `gemm3D` is false in `flowtransfer_host.cpp`, and the
gather falls back to the routing's row-major shim dims.

## Fix

`flowtransfer_host.cpp` (output gather): with `output_tile_major`, a traced `#routing.kernel_block` on the
output, no halo and no GEMM tiling, the blocks alone give the layout -- R = rounds_i x rounds_j blocks of
`shape` bytes per core, back to back: dims `{4, 16} {64, bytes / 64}`, iteration step = block bytes,
wrap = R (<= 64), per-core stride R x bytes. Fill `c.outDesc` too (`bdLenBytes`, `roundDims {1, 0}`,
`totalRounds 1`): the BD length is read from it once `usedMRounds3D` is set -- leaving it empty gives
`len=0` and a hang in `wait_io TIMEOUT ... ch=1 dir=1` on the output shims. Build log:
`[OOO ShimBD desc] output_tile_major from the traced blocks: 32 x 8192 B per core, back to back`.
Ports that have a GEMM tiling (int8 gemm_plan) still take the GEMM branch: their files are unchanged.

## Also in the bf16 kernel

fp32 -> bf16 rounds by the core's rounding mode, which starts as `floor`: set
`aie::set_rounding(aie::rounding_mode::conv_even)` to match an RNE reference (one bf16 ulp otherwise).
