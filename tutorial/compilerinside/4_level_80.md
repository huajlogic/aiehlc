<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# 4. Toward 80 %: one field, one switch

Sources: `step4_keep.cc` (`.keep = true` on B: the weights stay in the MemTiles across launches) and
`step5_persistent.cc` (+ `#pragma persistent_kernel`: the kernel is loaded and started once). From here on every
step is a one-word change in the C source, and the interesting part is following that one word down: it shows
which level owns which decision.

## step 4: `.keep = true` -> `resident = true`

| level | file | the whole difference to step 3 |
|---|---|---|
| routing | `0_initial.mlir` | B: `#routing.dataflow<..., stage = "memtile", ring = 0, keep = false, ...>` -> `keep = true` |
| dmap | `2_RoutingToDmapPass.mlir` | none |
| dmaphop | `4_DataflowPlan.mlir` | B's path: `#dmaphop.stream<arg = 1, role = "b", ..., stage = "memtile", resident = false, ...>` -> `resident = true` |
| dfscheblueprint | `6_DmaphopTodfscheblueprintPass.mlir` | the same field in B's `dfscheblueprint.plan_stream` |
| dfschedule | `14_DataflowPlanToDfschedule.mlir` | B's MemTile locks and S2MM starts, below |

The routes, the hops, the protocol: all unchanged. The DMA program derivation (`plandma.cpp`, `deriveResident`)
reads `resident` and changes only what runs per launch on B's MemTiles:

```mlir
// step 3: B is sent again every launch
dfschedule.config.lock_set(%31) {dfplan.tag = "mem/1/0/lock/0", lock_id = 0 : i32, value = 0 : i32}
dfschedule.config.channel_start(%31) {channel = 0 : i32, direction = "S2MM", start_bd = 0 : i32, dfplan.tag = "mem/1/0/ch_in/0"}
// step 4: B arrives once; its locks end each launch where they started
dfschedule.config.lock_set(%31) {dfplan.tag = "mem/1/0/lock/0", lock_id = 0 : i32, value = 0 : i32,
                                  restored = true, later_value = 4 : i32}
dfschedule.config.channel_start(%31) {channel = 0 : i32, direction = "S2MM", start_bd = 0 : i32,
                                       first_launch_only = true, dfplan.tag = "mem/1/0/ch_in/0"}
```

`first_launch_only`: the MemTile's input channel (and the shim BD feeding it) runs on the first launch only;
`restored` + `later_value`: the lock value is written on the first launch (and the second, where it differs) and
then left alone, because every launch hands it back the way it found it. The runtime implements both
(`__Runtime_plan_setup`). No B bytes leave DDR after the first launch.

## step 5: `#pragma persistent_kernel` -> a go lock

| level | file | the whole difference to step 4 |
|---|---|---|
| routing | `0_initial.mlir` | module: `+ routing.persistent_kernel = 1 : i64` (a switch) |
| dmaphop | `4_DataflowPlan.mlir` | the plan header: `dmaphop.plan {..., persistent = false, ...}` -> `persistent = true` |
| dfscheblueprint | module attributes | `dfscheblueprint.plan_persistent = false` -> `true` |
| dfschedule | kernel plan program | a go lock, below; host: `__Runtime_plan_setup(1, -1)` -> `(1, 12)` |

```mlir
// kernel plan program, step 4 -> step 5 (23_DataflowPlanToDfschedule(kernel).mlir)
dfschedule.config.lock_set(%0) {dfplan.tag = "core/sync", lock_id = 12 : i32, value = 0 : i32}
// becomes
dfschedule.config.lock_set(%0) {dfplan.tag = "core/go", lock_id = 12 : i32, value = 1 : i32}
dfschedule.config.lock_set(%0) {dfplan.tag = "core/sync", lock_id = 13 : i32, value = 0 : i32}
```

`planresource.cpp` allocates one more core lock (12 becomes the go lock, the tile sync moves to 13); the kernel's
`main` becomes `for (;;) { acquire(go); kernel(); }` and the host's later launches only release the go lock
(`__Runtime_plan_setup(1, 12)`): no ELF reload, no core reset, the BDs written once (`bd_once`).

## Measured (palmyra)

| step | per launch | % of peak |
|---|---|---|
| 3 (`memtile`) | 1.860 ms | 66.1 % |
| 4 (`.keep`) | 1.799 ms median, 1.645 ms best | 68.3 % (74.7 % best) |
| 5 (`persistent_kernel`) | 1.608 ms | 76.4 % |

The DDR traffic per launch and the per-launch host work went down; what is left is the cores themselves --
the next chapter's two fields act inside a core.
