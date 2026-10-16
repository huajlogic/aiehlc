<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: coretmregisterwrite
description: Core-side register write from kernel.cc appears to succeed (same-core readback returns the value) but the host XAie_Read32 still sees 0, or a DMA channel never starts despite the config code running. Use when writing tile registers from an AIE core — BD/lock/channel-start under KERNELCONFIGOFFLOAD, or any TM register poke.
---

# A Core Register Write That Never Leaves the Core

## Symptom

Code running on an AIE core writes a tile register and the write seems to work:

```c
*(volatile uint32_t *)(0x80000 + 0x1DE04) = v;   /* S2MM start queue */
uint32_t rb = *(volatile uint32_t *)(0x80000 + 0x1DE04);   /* rb == v  ✓ */
```

but:

- `XAie_Read32` from the **host** reads `0`
- the **DMA never starts** — no start event, channel idle, S2MM stalls
- no compiler warning, no error, no fault

The same-core readback *confirms* a write that never happened: the store and the
load are coherent **with each other** inside the core, so they agree on a value
the hardware never saw.

## Root cause

**The address does not select the interface.** A core sees three
non-overlapping spaces, each behind its own interface (arch doc Table 5-5):

```
PM  0x0_0000 - 0x0_4000   program memory
DM  0x4_0000 - 0x7_FFFF   data memory
TM  0x8_0000 - 0xF_FFFF   tile memory-mapped registers
```

The compiler picks the interface from the **pointer's memory space**, which a
numeric cast cannot express. So a cast pointer assembles to a plain `ST` that
stays inside the core, regardless of the address value.

Two distinct bugs hide here — fixing only the first is the trap:

| Bug | Result |
|-----|--------|
| Wrote the bare tile-local offset (`0x1DE04`) | Lands in **DM** (0x4_0000-0x7_FFFF) — scribbles on data memory |
| Added the `0x80000` bias but still used a cast | Correct *address*, wrong *interface* — plain `ST`, never reaches the bus |

## Fix

Go through `TM_W` / `TM_R` from `src/mlir/runtime/kernel_tm.h`, which carry a
file-scope `chess_storage(TM:...)` anchor — that is what makes accesses lower to
`ST.TM` / `LDA.TM`:

```c
#include "kernel_tm.h"        /* FILE scope — the anchor must be an object */

TM_W(TM_DMA_S2MM_0_START_QUEUE, v);
chess_memory_fence();
uint32_t rb = TM_R(TM_DMA_S2MM_0_START_QUEUE);
```

Offsets passed to `TM_W`/`TM_R` are **AXI-MM / tile-local** (`0x1DE04`), not the
biased core address — the anchor's base supplies the `+0x80000`.

For DMA config under KERNELCONFIGOFFLOAD, use
`src/mlir/runtime/aie_kernel_runtime.h`, whose `core_reg_write` /
`core_reg_read` / `core_reg_write_block` already delegate to `TM_W`/`TM_R`.
Encode with `aie_kc_encode_bd` / `_lock` / `_s2mm_start` / `_mm2s_start`, then
apply with `core_reg_write_block`.

`chess_storage` cannot be applied to a pointer:

```
error: chess_storage specifies storage linking for pointer/reference types,
       not allowed
```

so the anchor must be a file-scope object and accesses index off its address.

## Verify the lowering, not the value

A readback proves nothing here. Check the generated assembly:

```bash
grep -cE '\.TM' <build>/obj/kernel.lst
```

**Zero means every access degraded to plain `ST`/`LDA`** and never reached the
bus. A correct build shows one `.TM` per access.

Cross-check from the host with `XAie_Read32` (or `XAie_DataMemBlockRead` for a
value parked in DM) — the host reading the expected value is the real proof.

## In aiehlc codegen

`DfscheduleToKernelApiPass::emitWindowBdAndLocks` emits `core_reg_write_block` /
`core_reg_write`, never a raw cast. If you change what that pass emits, keep it
going through `core_reg_*` — emitting a cast reintroduces a bug that passes
every on-core check and only shows up as a dead DMA on hardware.

## Related

- `src/mlir/runtime/kernel_tm.h` — full rule, ADF alternative (`adf::write`/`adf::read`)
- `src/mlir/runtime/aie_kernel_runtime.h` — encoders + apply helpers
- `doc/design/kernel_config_offload.md` — KERNELCONFIGOFFLOAD design
- `example/perf/aieml_perf.cc` — on-HW A/B/C comparison (header vs adf:: vs raw cast)
