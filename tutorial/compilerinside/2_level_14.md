<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# 2. The launch leaves the host: same flows, a different program

Sources: `step1_vector.cc` (the kernel on `aie::mmul<8,8,8>`, nothing else changes in the IR) and
`step2_launch.cc`, which adds five pragmas:

```c
#pragma aie_debug_level(AIE_DEBUG_FLAG_DISABLE_PARTITIONTEARDOWN)
#pragma control_plan_op_control_packet   // kernel ELF + core launch as control packets on the stream fabric
#pragma control_packet_mode(aot)
#pragma KERNELCONFIGOFFLOAD              // each core programs its own DMA from kernel.cc
#pragma output_tile_major                // C as whole tiles: one out-of-order shim BD covers every round
```

Step 1's change is the kernel body; in the IR it adds exactly one thing, `block_align = 64` on the three tensors
(the vector loads need 64-byte-aligned core buffers, `{.align = 64}`) -- the dfschedule program is byte-identical
to step 0's. Step 2 is the interesting one, because
**every level above dfschedule keeps its shape** -- the data movement is the same -- and all of the change is
in how the program is executed.

## routing: switches, not structure

The pragmas become module attributes (control switches; skill **routingirtilingcarriers**: tiling and data
movement never live on the module):

```mlir
module attributes {routing.control_packet_mode = 1 : i64, routing.control_plan_exclusive = 1 : i64,
  routing.control_plan_mm2s_ch = 0 : i64, routing.control_plan_op_control_packet = 1 : i64,
  routing.control_plan_s2mm_ch = 0 : i64, routing.control_plan_shim_col = 0 : i64,
  routing.kernel_config_offload = 1 : i64, routing.output_tile_major = 1 : i64, ...}
  %0 = routing.routingcreatehwmesh row = 4, col = 4 partition = 2, 6, 0, 6 -> i32
```

The partition grew by one column (`2, 6` instead of `3, 6`): the control-packet plane takes partition column 0
(`control_plan_shim_col = 0`), the data plane moves one column right. The tensors, `#routing.kernel_block` and the
partitions are step 1's.

## dmap, dmaphop, dfscheblueprint: the same flows

Diffing step 2 against step 1 with the column numbers masked, the dmap and dmaphop modules differ only in the
output ports' packet ids, and the blueprint only in `base_packet_id`:

```mlir
// dmaphop (step 0)                                         // dmaphop (step 2)
dmaphop.port @f5_corePortOut0 on %38 {..., dmapktid = 1}     dmaphop.port @f5_corePortOut0 on %38 {..., dmapktid = 4}
// dfscheblueprint
,base_packet_id = 1 : i32,                                   ,base_packet_id = 4 : i32,
```

Packet ids 1-3 are reserved by the control plane (`ResourceMgr::reserveControlPlaneResources`), so the output
packet flows start at 4. The shim -> core hops, the paths, the one-to-many transfers and their shim walks are
unchanged. This is the point of the level split: *what* moves is decided above, *how it is driven* below.

## dfschedule: where 14 % comes from

| host schedule (`7_BlueprintToSchedulePass.mlir`) | step 0 | step 2 |
|---|---|---|
| `config.dma_bd` | 120 | 24 |
| `scf.for` (per-round host loops) | 12 | 0 |
| `schedule.start_io` | 60 | 12 |
| `schedule.wait` | 24 | 12 |

Three mechanisms remove them, each a pass reading one switch:

- **The output is one BD for all rounds** (`routing.output_tile_major`). The core writes C as whole 64 x 64 tiles,
  so one out-of-order shim S2MM BD with an iteration covers the 30 rounds; the host loop over rounds is gone:

  ```mlir
  %bd = dfschedule.config.dma_bd(...) {..., iter_step_size = 4096 : i32, iter_wrap = 30 : i32}
  %io = dfschedule.config.create_io(%bd, %tile) {..., enable_out_of_order = true}
  ```

- **The cores program their own DMA** (`routing.kernel_config_offload`). `BlueprintToScheduleKernelPass` emits the
  core-tile BDs into the kernel module (96 `config.dma_bd` for 16 cores in `20_BlueprintToScheduleKernelPass.mlir`);
  `DfscheduleKernelAggregationPass` folds them into one BD group per window, because one kernel ELF runs on every
  core (36 left in `21_DfscheduleKernelAggregationPass.mlir`). `kernel.cc` then writes its own BDs and locks
  (`aie_kc_encode_bd`, 36 of them) and the host writes none.
- **Kernel load and launch over control packets** (`routing.control_plan_op_control_packet`, `control_packet_mode`):
  the same `config.load_kernel_group` / `schedule.launch_kernel_group` ops lower to the control-packet runtime --
  `host.cc` calls `__Runtime_ctrl_plan_init` once, `__Runtime_load_kernel_group_16t_ctrl` and
  `__Runtime_launch_kernel_group_ctrl` instead of the MMIO `__Runtime_load_kernel_group_16t` /
  `__Runtime_launch_kernel_group`, and an AOT relaunch resends only the reset and the data, not program memory.

In `host.cc`: 120 -> 24 `__Runtime_dma_bd_config*` calls, 60 -> 12 `__Runtime_dma_createio_4` / `__Runtime_startio`.
Every one of them was MMIO register writes at ~0.4 us each. The cores now do the work they were waiting for.

## What to remember

| level | step 0 -> step 2 |
|---|---|
| routing | + control switches on the module, the partition one column wider |
| dmap / dmaphop / dfscheblueprint | the same flows; packet ids shifted past the control plane's |
| dfschedule | no per-round host loop (tile-major output, one OOO BD), core DMA in the kernel module (aggregated), kernel load / launch as control packets |

What is left: every core still gets its A and B straight from a shim channel, once per K block, and each column's
shim feeds four cores the same bytes. The next chapter changes *what moves*.
