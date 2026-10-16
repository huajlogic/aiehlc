<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: mlirbuildsandbox
description: Build aiehlc when `cmake: command not found`, `make` dies with "/snap/cmake/.../cmake: No such file or directory", "No rule to make target '/usr/lib/x86_64-linux-gnu/libz.so'", a configure fails with "Could NOT find Python3 (missing: Python3_INCLUDE_DIRS Development)", or with "The link interface of target LLVMSupport contains ZLIB::ZLIB but the target was not found". These are environment gaps (snap not mounted, -dev packages/symlinks absent), not code errors. Use when building from an agent/CI shell that differs from the shell the build tree was originally configured in, or when you need a fast compile-check loop for a single MLIR pass without a full relink.
---

# Building aiehlc from a Shell Where the Configured Toolchain Is Missing

## Symptoms

Four distinct failures, all environmental:

```
bash: cmake: command not found
make: /snap/cmake/1562/bin/cmake: No such file or directory
gmake: /home/huaj/.local/lib/python3.10/site-packages/cmake/data/bin/cmake: No such file or directory
make[3]: *** No rule to make target '/usr/lib/x86_64-linux-gnu/libz.so', needed by 'aiehlc'.
```

```
CMake Error at .../FindPackageHandleStandardArgs.cmake:290 (message):
  Could NOT find Python3 (missing: Python3_INCLUDE_DIRS Development
  Development.Module Development.Embed) (found version "3.10.12")
Call Stack (most recent call first):
  src/mlir/mlirfront/frontend/aietriton/CMakeLists.txt:6 (find_package)
```

And, if you try to sidestep them by configuring a fresh tree:

```
CMake Error at .../LLVMExports.cmake:55 (set_target_properties):
  The link interface of target "LLVMSupport" contains: ZLIB::ZLIB
  but the target was not found.
```

## Root cause

A CMake build tree hard-codes the absolute path of the `cmake` that configured it
(`CMAKE_COMMAND` in `CMakeCache.txt`, baked into `Makefile` and `CMakeFiles/Makefile2`)
and the absolute paths of every resolved library. Both can be unreachable from a
different shell:

- **cmake** — the tree was configured with a snap (`/snap/cmake/...`) or a pip
  install under `~/.local`. A sandboxed shell may have neither mounted.
- **libz.so / libzstd.so** — the build resolved the `-dev` **symlinks**
  (`libz.so`), but only the runtime sonames (`libz.so.1`) actually exist now.
  This also breaks a fresh `find_package(ZLIB)`, which is the `ZLIB::ZLIB` error.
- **Python3 Development** — `python3-dev` is not installed (no `Python.h`
  anywhere; `apt-cache policy python3-dev` shows no candidate). Only the
  optional `_aiebackend` pybind module needs it, never `aiehlc` itself.

Check before assuming a package is installable — on this host the apt lists are
empty, so `apt-get install python3-dev` is not an option even with sudo:

```bash
find / -maxdepth 6 -name Python.h 2>/dev/null   # expect: nothing
apt-cache policy python3-dev                    # expect: Candidate: (none)
```

`build/` and `build_claude/` in this repo are configured with *different* cmake
paths — check `CMAKE_COMMAND:INTERNAL` in each before assuming either works.

## Fix

**1. Find a reachable cmake.** The project venv usually has one:

```bash
ls /scratch/staff/huaj/aiehlc/.venv/bin/cmake
grep CMAKE_COMMAND:INTERNAL build/CMakeCache.txt      # what the tree wants
```

**2. Override it on the make command line** — do NOT rewrite the user's Makefiles:

```bash
cd build
make CMAKE_COMMAND=/scratch/staff/huaj/aiehlc/.venv/bin/cmake mlirtestlib -j$(nproc)
```

**2b. Python3 Development is already gated** — `src/mlir/mlirfront/CMakeLists.txt`
probes `Python3`/`pybind11` with `QUIET` and only descends into
`frontend/aietriton` when both are found, printing `Skipping _aiebackend:
...` otherwise. Seeing that line is expected on a host without `python3-dev`; it
does not affect `aiehlc`. Do **not** "fix" it by restoring the bare
`add_subdirectory` or by making `find_package` `REQUIRED` again — that is what
broke the whole configure. To build the module where the deps do exist:

```bash
cmake .. -DPython3_EXECUTABLE=/scratch/staff/huaj/aiehlc/.venv/bin/python3 \
         -Dpybind11_DIR=$(/scratch/staff/huaj/aiehlc/.venv/bin/python3 -m pybind11 --cmakedir)
```

`-DAIEHLC_BUILD_AIEBACKEND=OFF` skips it unconditionally. Note `pybind11` lives
only in the venv here, not under system python.

**"I re-ran cmake + make and `_aiebackend` is still ModuleNotFoundError."**
A fresh configure without `-Dpybind11_DIR` caches
`pybind11_DIR:PATH=pybind11_DIR-NOTFOUND` (the pip install's cmake dir is not on
cmake's search path) → the `Skipping _aiebackend` branch → `make` builds `aiehlc`
fine and **no `.so`**. Check `grep pybind11_DIR build/CMakeCache.txt` before
anything else. `make install` is NOT needed: `aiebackend.find_module_dir()`
searches `build/`, `build_claude/` and `$AIEHLC_BUILD_DIR` for the `.so`.

```bash
make _aiebackend -j$(nproc)
PYTHONPATH=src python3 -c "from frontend.tvmrelay.aie_offload import aie_backend; print(aie_backend().__file__)"
```

**3. Supply the missing `-dev` symlinks in a scratch dir** and link by hand from
the recorded link line, rather than reconfiguring:

```bash
mkdir -p /tmp/zstub
ln -sf /usr/lib/x86_64-linux-gnu/libz.so.1    /tmp/zstub/libz.so
ln -sf /usr/lib/x86_64-linux-gnu/libzstd.so.1 /tmp/zstub/libzstd.so

sed -e 's#/usr/lib/x86_64-linux-gnu/libz\.so#/tmp/zstub/libz.so#' \
    -e 's#/usr/lib/x86_64-linux-gnu/libzstd\.so#/tmp/zstub/libzstd.so#' \
    CMakeFiles/aiehlc.dir/link.txt > /tmp/link_aiehlc.sh
bash /tmp/link_aiehlc.sh
```

The same trick links the unit test from
`src/mlir/mlirfront/tilinglinalg/pass/unitest/utbuild/CMakeFiles/test.dir/link.txt`.

Do not `git checkout`/reconfigure to "fix" this — nothing is wrong with the repo,
and a fresh configure hits the `ZLIB::ZLIB` error anyway.

## Fast single-file compile check

Before a multi-minute library build, syntax-check one file using the exact flags
CMake recorded. This catches type/const errors in seconds:

```bash
python3 - <<'EOF'
import json, re
d = json.load(open('build_claude/compile_commands.json'))
for e in d:
    if 'passgroupregwrite.cpp' in e['file']:   # any file in the same target
        cmd = e['command']; break
# retarget to YOUR file + add its include dir, then syntax-only
cmd = cmd.replace('passgroupregwrite/passgroupregwrite.cpp',
                  'pass<yours>/pass<yours>.cpp')
cmd = cmd.replace('-I<...>/passgroupregwrite',
                  '-I<...>/pass<yours> -I<...>/passgroupregwrite')
cmd = re.sub(r'-o \S+', '', cmd)
cmd = re.sub(r'-c(?= )', ' -fsyntax-only ', cmd, count=1)
open('/tmp/syntaxcheck.sh','w').write(cmd + '\n')
EOF
bash /tmp/syntaxcheck.sh 2>&1 | grep error:
```

`compile_commands.json` may be stale for brand-new files — borrow a sibling's
command and retarget it, as above.

## Verify the binary actually contains your change

A failed `make` still leaves the OLD binary in place, so a subsequent pipeline run
can silently test stale code and report a false pass. Always confirm:

```bash
nm -C build/aiehlc | grep -c '<YourNewSymbol>'     # must be >= 1
strings -a build/aiehlc | grep '<your new log string>'
ls -la build/src/mlir/mlirfront/CMakeFiles/mlirtestlib.dir/<path>/<file>.cpp.o
```

If `make` printed a `fatal error` for *any* file in the target, the archive was
never rebuilt and the link never ran — re-check before trusting any result.

## Common gotchas hit while writing an MLIR pass here

- `llvm::SmallPtrSet<T*, N>` static-asserts for N > 32 ("SmallSize should be small").
- MLIR op accessors are **non-const**: iterate `for (auto &m : members)`, not
  `const auto &`, or `emitError`/`getPacketId()` fail with "discards qualifiers".
- `mlir::verify(module)` is not always visible; `module.verifyInvariants()` is.
- The generated `dfschedule::TileHandleType` TableGen name maps to the C++ class
  `dfschedule::TileType` (`dfscheduleype<"Tile">` → `TileType`).
- `ConfigDmaBdOp::build` takes `linked_bd` **after** `data_id`, not next to the
  other operands — check `inc/dfscheduleop.h.inc` rather than guessing.
