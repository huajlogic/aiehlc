---
name: meshsizelimits
description: A mesh wider than 4 x 4 (gemm_plan 4 x 6 / 4 x 8 / 4 x 16) -- aiehlc aborts with `terminate called after throwing an instance of 'std::bad_optional_access'` (or segfaults) right after `Allocated DataIO: shim col=...` lines; `[DmapToDmaphop] ERROR: out of packet ids`; `ERROR: too many tiles (24) for load_kernel_group`; `#pragma gemm_autotile: no feasible tiling ... output cores, 27 packet ids free`
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# How many cores a mesh can have

Two limits a 4 x 4 mesh never reached.

## Packet ids: at most 27 packet-switched output cores (aie2ps, control plane on)

Every core of a packet-switched (out-of-order gathered) output gets a packet id from ONE global pool
(`ResourceMgr::allocatePktId`, 5-bit field, ids 1..31) minus the ids the control plane reserves
(`__Runtime_res_reserved_pktid_mask`: 4 on aie2ps) -- 27. A 4 x 8 mesh (32 output cores) ran out; the
check was an `assert`, compiled out in a release build, and `pktId.value()` threw `bad_optional_access`.
Now `dmaptodmaphop.cpp` stops with `[DmapToDmaphop] ERROR: out of packet ids ... core N of M found none`.
`#pragma gemm_autotile` counts the same pool (`plantarget.h` `pktIds`) and rejects such meshes by name.
A bigger mesh needs packet ids allocated per merged route instead of globally (not done).

## Kernel load: 32 cores

The pipeline called positional `__Runtime_load_kernel_group_{4,8,16}t[_ctrl]` and stopped above 16
(`too many tiles (24) for load_kernel_group`), though the runtime holds `MAX_KERNEL_TILES = 32`. The
`_32t` / `_32t_ctrl` variants now cover 17..32 (`passdfscheduletoapi.cpp`, `aie_runtime.{c,h}`).

## Also

The 2 x 8 shared-operand GEMM needs exactly 4 mesh rows (A's strips have 2 readers, B's groups rows / 2;
one hosted-stream program per core needs them equal), so N = 2 x columns x 64 and columns <= 6 with 27
packet ids: N <= 768 on aie2ps.
