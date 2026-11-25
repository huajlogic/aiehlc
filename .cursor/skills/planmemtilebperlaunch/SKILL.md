---
name: planmemtilebperlaunch
description: A dataflow-plan GEMM with B staged in the MemTiles but NOT kept (`.stage = memtile` without `.keep = true`) passes launch 0 and hangs from launch 1 with `wait_io TIMEOUT tile(c,0) ch=0 dir=1` on the B input shims -- the B MemTile locks were marked `restored` although a per-launch B does not hand them back
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Per-launch MemTile B hangs from launch 1

## Symptom

`example/tileprogram/ccode/gemm_plan/step3_memtile.cc` (`OPTS_B` with `.stage = aie::stage::memtile`,
`.keep = false`, no `persistent_kernel`): `call 0` prints a correct time (45 %), then

```
[aie_runtime] wait_io TIMEOUT tile(1,0) ch=0 dir=1 pending=1
[aie_runtime] wait_io TIMEOUT tile(2,0) ch=0 dir=1 pending=1
```

and the netboot watchdog ends the run. The same source with `.keep = true` (step 4) runs every launch.

## Cause

`deriveResident` (`pass/dataflowplan/plandma.cpp`) programs B's MemTile buffer per column with two locks:
S2MM acquires lock 1 (free, init 1) and releases lock 0 (ready) by `replays`; each MM2S replay BD acquires
**and releases lock 0** (it re-reads the held strips). Nothing gives lock 1 back, so a launch ends at
`(lock0, lock1) = (replays, 0)`. With `.keep` that is exactly the state the next launch wants (`later`
= `replays`, 0; the S2MM is started only on the first launch). Without `.keep` the S2MM runs again on every
launch and waits for lock 1 forever -- yet both locks were created with `restored = true`, which makes
`__Runtime_tile_lock_set_restored` write them on launch 0 only.

## Fix

`restored` = `keep` for both B MemTile locks. A per-launch B is now written at every launch start
(`__Runtime_tile_lock_set`, 2 locks x 4 MemTiles, ~3 us), before the channel starts; a kept B is
byte-identical (`gemm_plan.cc`). Rule: mark a plan lock `restored` only when the launch's acquires and
releases on it balance -- check the BDs, not the intent.
