<!-- Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Project layout (paths from repo root)

Shared by **hostcodegen** and **kernelcodegen**. `pass/` below means
`src/mlir/mlirfront/tilinglinalg/pass/`.

## Generated sources (worklocal)

| Flow | Worklocal | Written by |
|------|-----------|------------|
| App (`script/aiehlc.sh`) | `aout/worklocal/` | `tilinglinalg_pipeline.cpp` |
| Unitest driver | `pass/unitest/build/worklocal/` (`<cwd>/worklocal`, `./test` runs in `build/`) | `pass/unitest/test.cpp` |

Inside a worklocal:

| File | Notes |
|------|-------|
| `host.cc`, `kernel.cc`, `routing.cc` | generated |
| `build/host` | host ELF (`hostcompile.sh`) |
| `build/kernel` | kernel ELF (`compile_one_kernel` -> `kc.sh`; full-DWARF copy `build/kernel_debug`) |
| `computekernel.cc` | unitest flow only: hand-written kernel body, `#include`d by `kernel.cc`. In the app flow the body is the app's kernel function (e.g. `matmul.cc`). |
| `aieml.bcf`, `aieml.prx` | core memory placement for the chess compiler |
| `dfscheduleprovenancemap.json` | input for `src/tool/debug/schedule_view.py` |

## Per-pass IR dumps

`ir/dfschedule/N_<Pass>.mlir` (host + kernel paths) and `ir/simplerouting/N_<Pass>.mlir`
(routing path), relative to the directory the pipeline ran in.

## Scripts and sources

| Item | Path |
|------|------|
| Host + kernel compile | `script/hostcompile.sh` (`WORKLOCAL_DIR=...`; `KERNEL_ONLY=1` for the kernel only) |
| Kernel ELF build | `script/kc.sh` (called by `compile_one_kernel`) |
| Unitest driver / full chain | `pass/unitest/test.cpp`, `pass/unitest/piplinerun.sh` |
| Host API lowering | `pass/passdfscheduletoapi/` |
| Host / kernel blueprint lowering | `pass/passblueprintlowering/` (`passblueprinttoschedule`, `passblueprinttoschedulekernel`, shared `helper/`) |
| Kernel API lowering | `pass/passdfscheduletokernelapi/` |
| Runtime | `src/mlir/runtime/aie_runtime.{c,h}`, `include/aie_device_map.h` |
| Board harnesses | `script/test/appvek385.py` (VEK385), `script/test/apppaltest.py` (PAL) |
