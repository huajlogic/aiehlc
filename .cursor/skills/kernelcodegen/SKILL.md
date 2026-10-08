---
name: kernelcodegen
description: Generate, compile and debug the TilingLinalg AIE kernel code (kernel.cc) for the aiehlc flow. Use when kernel.cc is wrong or fails to compile with xchesscc/xchessmk, when changing BlueprintToScheduleKernelPass, DfscheduleKernelAggregationPass or DfscheduleToKernelApiPass, or when building just the kernel ELF. Complements hostcodegen (host side).
---
<!-- Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Kernelcodegen

Generation, layout, environment and board runs are shared with skill **hostcodegen**
([project-layout](../hostcodegen/references/project-layout.md),
[compile-env](../hostcodegen/references/compile-env.md)). This page is the kernel-specific
part.

## Pass path

The kernel module is cloned from the dfscheblueprint IR (after `DmaphopTodfscheblueprintPass`):

| Pass | Dir under `src/mlir/mlirfront/tilinglinalg/pass/` |
|------|------|
| `BlueprintToScheduleKernelPass` | `passblueprintlowering/passblueprinttoschedulekernel/` (core-tile DMA/lock config shared with the host path via `passblueprintlowering/helper/`) |
| `DfscheduleKernelAggregationPass` (only with `#pragma KERNELCONFIGOFFLOAD`) | `passdfschedulekernelaggregation/` |
| `DfscheduleToKernelApiPass` -> EmitC -> `kernel.cc` | `passdfscheduletokernelapi/` |

Each pass's output IR is dumped to `ir/dfschedule/N_<Pass>.mlir` (the kernel passes run
last). Anything the host and kernel paths must agree on (BD bank, locks)
belongs in `passblueprintlowering/helper/`; see `passblueprintlowering/README.md`. Under
KCO the core configures its own DMA through `src/mlir/runtime/aie_kernel_runtime.h`, and
its register writes must go through `kernel_tm.h`'s `TM_W` (a plain pointer store never
reaches the processor bus).

## Kernel body

`kernel.cc` `#include`s the compute function and calls it with the window handles
(`computekernel(get_input_async_window_int8(...), ...)`). In the app flow that function
is the app's kernel (e.g. `matmul.cc`); in the unitest flow it is the hand-written
`<worklocal>/computekernel.cc`, which must exist before compiling.

## Build only the kernel

```bash
WORKLOCAL_DIR=<worklocal> KERNEL_ONLY=1 source script/hostcompile.sh
```

Output `<worklocal>/build/kernel`. `kc.sh` strips `.debug_loc` (keep it with
`--keep-debug-loc`) and keeps the full DWARF at `build/kernel_debug`.

## Bug fixes

- Wrong or missing kernel C++: compare the `ir/dfschedule/N_<Pass>.mlir` dumps of the
  kernel passes (the highest numbers; they shift with optional passes) and find the first
  wrong one.
- EmitC translate failure: the kernel module is not valid EmitC; fix the lowering in
  `DfscheduleToKernelApiPass`.
- Compile error in xchesscc: check `kc.sh` include paths and that `kernel.cc` matches the
  AIE API for the target (`aie2ps` on Gen5).
