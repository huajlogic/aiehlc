# Kernel Config Offload (KERNELCONFIGOFFLOAD) — Design

**Status:** approved-approach (raw MMIO in-core writes; PC-bus enable researched)
**Date:** 2026-09-14

## Goal

Offload core-tile DMA configuration from the HOST to the AIE CORE. Today the host
programs every core tile's incoming/ongoing DMA buffer descriptors (BDs), lock
inits, and DMA channel-start over the config bus (`host.cc`, via
`DfscheduleToApiPass`). Under an opt-in `#pragma KERNELCONFIGOFFLOAD`, the AIE
core self-configures its DMA from inside `kernel.cc` using raw memory-mapped
register writes to its own memory-module registers.

Default OFF. Absent the pragma, behavior is byte-identical to today.

## Current data flow (baseline)

- `FlowTransferConversion` (`flowtransfer_kernel.cpp`) emits per-core-tile
  `dfschedule::ConfigDmaBdOp` (ping/pong or single), lock ops, and a deferred
  `StartIoOp` **into the HOST module**.
- `DfscheduleToApiPass` (`ConfigDmaBdInnerPattern`, passdfscheduletoapi.cpp:1191)
  lowers those into `host.cc`: `__Runtime_dma_bd_config(...)`,
  `XAie_LockSetValue(...)`, `XAie_DmaChannelSetStartQueue(...)`.
- `kernel.cc` (via `DfscheduleToKernelApiPass`) does NO DMA programming; it only
  emits `window_init` / `kernel_invoke` / `done()` and uses
  `acquire_greater_equal`/`release` lock intrinsics on host-initialized locks.

So the HOST configures each core's DMA. Offload relocates that into the CORE.

## Register map (AIE2PS / gen5, tile-local, from `xaie2psgbl_params.h`)

| Register | Offset | Notes |
|---|---|---|
| `MEMORY_MODULE_DMA_BD0_0` | `0x1D000` | BD block base; per-BD stride from param header |
| `MEMORY_MODULE_DMA_S2MM_0_CTRL` | `0x1DE00` | S2MM channel ctrl (ch stride from header) |
| `MEMORY_MODULE_DMA_S2MM_0_START_QUEUE` | `0x1DE04` | channel start (BD id, repeat) |
| `MEMORY_MODULE_DMA_MM2S_0_CTRL` | `0x1DE10` | MM2S channel ctrl |
| `MEMORY_MODULE_LOCK0_VALUE` | `0x1F000` | lock value, stride `0x10` (matches GroupRegWrite) |

`CORE_MODULE_CORE_PC` (`0x30F00`) is the program counter, NOT a bus. The core's
access to its own memory-mapped config registers is gated by the **core
processor bus control** register, enabled per-tile by the host API
`XAie_CoreProcessorBusEnable(dev, Loc)` (xaie_core.c:1113 — AIE-tile type only,
mask-writes the ProcBusCtrl enable bit at the tile address). This is the #3
enable. `XAie_PartitionInitialize` (xaie_io_privilege.c:611) already
ungates/clocks columns; the processor-bus enable is the additional per-core step
that lets the core write DMA BD/lock registers.

## Approach: raw MMIO writes from `kernel.cc`

The core writes its own DMA BD / channel / lock registers via volatile pointers
to the tile-local offsets above (the core's view of its own memory module). BD
field encoding mirrors what `__Runtime_dma_bd_config` / `XAie_DmaWriteBd`
produce (address, length, lock acquire/release ids+vals, next_bd, packet
enable/id, out-of-order bd id).

### #1 Incoming (S2MM) + ongoing (ping/pong) BD + lock init → kernel

Move the S2MM BD chain (ping BD → next_bd pong → next_bd ping) and the lock
initial values into `kernel.cc main()`, emitted BEFORE `kernel_invoke`. Lock
init writes `LOCK0_VALUE + id*0x10`.

### #2 Outgoing (MM2S) BD → per-(col,row) if/else

The MM2S out-of-order target BD id (`coreOooBdId`) differs per core tile, so the
kernel emits an `if/else` chain keyed on the core's own `(col,row)`, each branch
programming that tile's MM2S BD. The core learns its own `(col,row)` — resolution
mechanism TBD in the spike (aie_api tile-position intrinsic, or a compile-time
per-tile kernel binary; the pipeline already builds a shared kernel binary so a
runtime (col,row) query is preferred).

### #4 DMA channel start → kernel

Write `S2MM_0_START_QUEUE` (0x1DE04) with the first BD id + repeat, replacing the
host `XAie_DmaChannelSetStartQueue` for offloaded core tiles.

### #3 Runtime: enable core processor bus (host)

Add a helper `__Runtime_enable_core_proc_bus(dev)` that iterates the partition's
AIE core tiles (row >= core-row-min) and calls
`XAie_CoreProcessorBusEnable(dev, XAie_TileLoc(col,row))` for each. Invoke it
from the partition-init path (`__Runtime_explicit_init` /
`__Runtime_explicit_init_partition`, right after
`__Runtime_partition_initialize`). Gate on `AIE_GEN==5` and non-`__AIESIM__`.
This enables each core's access to its own memory-mapped DMA/lock registers so
the offloaded `kernel.cc` MMIO writes take effect.

## Pass structure (#5)

Reuse existing passes, gated by the module attr `routing.kernel_config_offload`:
- `FlowTransferConversion` / `DfscheduleToKernelApiPass`: when offload on, emit
  the core BD/lock/channel-start config into the kernel path.
- `DfscheduleToApiPass`: when offload on, skip the core-tile BD/lock/channel-start
  host emission (leave shim BDs and kernel-group launch intact).

Gate plumbing mirrors `CONTROL_PLAN_GROUP_REG_WRITE` (Task E):
`aiehlc.cc` static bool + `PragmaHandler("KERNELCONFIGOFFLOAD")` +
`module->setAttr("routing.kernel_config_offload", ...)` at both setAttr sites.

## Risk / validation

The #3 enable is confirmed supported by aie-rt (`XAie_CoreProcessorBusEnable`),
which de-risks core access. Residual unknown: the exact core-visible address the
kernel uses for its own memory-module registers (tile-local `0x1D000`/`0x1F000`
vs. a core aperture base) and DMA re-arm behavior. Plan Task 1 is a minimal HW
spike: host calls `XAie_CoreProcessorBusEnable` for one core tile, and a
hand-written `kernel.cc` self-programs its S2MM BD + lock + start-queue via MMIO;
confirm data lands BEFORE the full codegen refactor.

## Out of scope (v1)

- MemTile / shim self-config (shim BDs stay host-side).
- Non-AIE2PS generations (gate on gen5 initially).
- Dynamic reconfiguration mid-run (one-shot config at kernel entry only).
