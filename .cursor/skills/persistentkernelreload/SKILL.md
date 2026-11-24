---
name: persistentkernelreload
description: A persistent kernel (#pragma persistent_kernel, dataflow plan go lock) runs launch 0 and hangs from launch 1 -- wait_io TIMEOUT on the input shim channels, aiedump shows the mesh cores core_status=0 pc=0, MemTile MM2S backpressured, ring S2MM stalled on its lock. Use when a persistent build works on one mesh size and hangs on another.
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Persistent kernel reloaded on launch 1

## Symptom
- `call 0` completes (e.g. 1.9 ms), `call 1` prints `wait_io TIMEOUT tile(c,0) ch=1 dir=1` on every input
  shim, then the netboot watchdog fires.
- `script/aiedump.py vek385-N`: the mesh's cores `core_status=0x0 pc=0` (not running), MemTile MM2S
  `Stalled_Stream_Backpressure`, the ring's S2MM `Stalled_Lock_Acq`, the shim MM2S backpressured.

## Cause
The runtime keeps a persistent kernel by (a) loading the ELF only on the first launch of a partition
generation and (b) on later launches only releasing the go lock instead of enabling the cores. (b) lived
in the launch functions, (a) only in `__Runtime_load_kernel_group_16t_ctrl`. A mesh of 8 cores goes
through `_8t_ctrl` (or the MMIO `_nt` variants): launch 1 reloaded the ELF -- which resets the cores --
and then only released the go lock, so nothing ran.

## Fix
`aie_runtime.c`: `rt_plan_kg_cached` / `rt_plan_kg_store` wrap `rt_ctrl_load_kernel_group_nt` and
`__Runtime_load_kernel_group_nt` (every load variant), `rt_plan_go` is called by both launch functions.
Add any new load / launch entry point through these helpers.

## Check
`aiedump` the cores after a hang: `pc=0` + disabled means the kernel was reset, not deadlocked on a lock.
