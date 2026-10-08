---
name: hostcodegen
description: Generate, compile, run and debug the TilingLinalg host code (host.cc + aie_runtime) for the aiehlc AIE flow. Use when you need to (1) generate host.cc/kernel.cc, either from an app with aiehlc.sh or from the standalone unitest driver, (2) compile the host ELF with script/hostcompile.sh, (3) run it on a board and check the console, or (4) decide whether a failure is in a pass, the generated host.cc, the runtime or the board.
---
<!-- Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Hostcodegen

Generate -> compile -> run on HW -> verify -> fix, for the host side. The kernel side
is skill **kernelcodegen**; both share the references below.

## Workflow

1. **Generate** (two entry points, same passes):
   - App flow: `source script/aiehlc.sh --aie-version 5 --platform baremetal
     --runtime-source-file <app>.cc` writes `aout/worklocal/{host,kernel,routing}.cc`
     and also compiles them.
   - Unitest flow: build and run the driver in `pass/unitest` (`cd build && ./test`);
     it writes `<cwd>/worklocal/`, i.e. `pass/unitest/build/worklocal/`.
   Paths: [references/project-layout.md](references/project-layout.md). Every pass's
   output IR is dumped to `ir/dfschedule/N_<Pass>.mlir`.
2. **Compile**: `WORKLOCAL_DIR=<worklocal> source script/hostcompile.sh` builds the host
   ELF `<worklocal>/build/host` and the kernel ELF.
   Env and errors: [references/compile-env.md](references/compile-env.md).
3. **Run on HW**: VEK385 boards use `script/test/appvek385.py` (skill
   **vek385-board-benchmark**); PAL boards use `script/test/apppaltest.py`
   ([references/hw-test.md](references/hw-test.md)).
4. **Verify**: pass = `device_teardown done` (or the app's `PASS:` line), fail = `AIE ERROR`
   / `Invalid Tile Type`. [scripts/verify_host.sh](scripts/verify_host.sh) runs a PAL
   board and checks both. `pass/unitest/piplinerun.sh` chains generate, compile and a
   PAL run.

## Bug-fix decision flow

- **Pass / codegen error** -> the MLIR passes (`passdfscheduletoapi`,
  `passblueprintlowering/passblueprinttoschedule`, ...). Read the per-pass dumps in
  `ir/dfschedule/N_<Pass>.mlir` to find the first pass whose output is wrong.
- **Compile error in host.cc** -> fix the lowering (DfscheduleToApi / EmitC); there is no
  post-processing of the generated file.
- **Link / runtime error** -> `src/mlir/runtime/aie_runtime.c` and the link recipe in
  `script/hostcompile.sh`.
- **Board failure** -> [references/hw-test.md](references/hw-test.md); for wrong data
  before touching HW, the `/data-mismatch-debug` command.
