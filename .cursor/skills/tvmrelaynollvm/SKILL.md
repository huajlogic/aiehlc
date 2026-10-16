<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: tvmrelaynollvm
description: deploy_flow.py does not int8-quantize by default (prints "done: fp32 C" or "[3/7] int8 : SKIPPED"), or dies with "InternalError: Check failed: (bf != nullptr) is false: target.build.llvm is not enabled" inside relay.frontend.from_onnx, or "ModuleNotFoundError: No module named 'onnx'". Root cause is almost always a USE_LLVM=OFF TVM -- ONNX PTQ is the intended default and needs LLVM. Covers building TVM with LLVM without sudo (zlib/zstd/libxml2 staging), and "[5/7] split : skipped -- the emitted C does not compile".
---

# tvmrelay flow: getting the default int8 path to actually run

## 1. Run it with the venv interpreter, not system python3

```bash
/scratch/staff/huaj/aiehlc/.venv/bin/python3 src/frontend/tvmrelay/deploy_flow.py
```

System `/usr/bin/python3` has no `tvm`, `onnx` or `onnxruntime`. It used to fail
with a bare `ModuleNotFoundError: No module named 'onnx'` raised from
`ensure_onnx_mapping()` *during the package import* — which reads as "the shim
is broken" rather than "wrong interpreter". `onnx_compat.ensure_onnx_mapping`
now distinguishes the two and names the interpreter.

The auto-installer does not rescue this: it refuses to touch a system Python
("not running inside a virtualenv"), which is correct behaviour.

## 2. `target.build.llvm is not enabled` during ONNX import

```
File "deploy_flow.py", line 666, in run
    mod, params = import_relay(qdq_path, verbose=verbose)
  ...
  File "src/target/codegen.cc", line 72
InternalError: Check failed: (bf != nullptr) is false: target.build.llvm is not enabled
```

### Root cause

`relay.frontend.from_onnx` calls `fold_constant()` on **every** node
(`onnx.py:6973` → `common.py:515` → `FoldConstantExpr`). Folding JIT-executes
the subgraph against a target hardcoded as `"llvm"` in C++
(`fold_constant.cc:403`). On a `USE_LLVM=OFF` build that raises.

The critical detail: this fires **inside the frontend**, so
`disabled_pass=["FoldConstant"]` (which `build_c` already applies via
`NO_LLVM_DISABLED_PASSES`) cannot reach it.

It is **specific to the int8 QDQ graph**, not to ONNX import in general —
verified directly:

| model | `from_onnx` without LLVM |
|-------|--------------------------|
| `resnet18-v1-7.folded.onnx` (fp32) | **OK** |
| `resnet18-v1-7.int8.qdq.onnx` (QDQ) | **fails** — folding a q/dq node needs the JIT |

So the existing `llvm_status()` gates on `quantize_int8` (stage 3) and
`build_c` (stage 4) were not enough: the **default** ONNX-PTQ path crashed one
step earlier, at import.

### Fix in place

`deploy_flow.run()` now has an `elif not llvm_status()[0]:` branch before the
default ONNX-PTQ branch. It reports, prints `_LLVM_HINT`, and continues in fp32
— the same policy the `relay.quantize` branch already used — instead of
spending minutes quantizing a model it then cannot import.

Expected output on a no-LLVM build:

```
[3/7] int8   : SKIPPED -- this TVM has no LLVM (USE_LLVM=OFF)
[3/7]          continuing in fp32; stage 4 output is NOT int8
[5/7] split  : 22 layers -> worklocal/tvmrelay_deploy/layers/ (all compile)
done: fp32 C in worklocal/tvmrelay_deploy
```

**The output is fp32, not int8.** That is the honest result for this build, not
a silent downgrade — stage 4 says so explicitly.

## 3. The real fix: build TVM with LLVM (now the default)

**int8 ONNX PTQ is the flow's intended default and it works.** Falling back to
fp32 is a degraded mode, not the answer. `setup_tvm016.py` now:

- **defaults to an LLVM build** (`_default_llvm_config()` checks `$LLVM_CONFIG`,
  `$LLVM_INSTALL_DIR/bin`, `PATH`, then the sibling `llvm-project/build`).
  It used to default to `OFF`, which silently produced a TVM that downgraded
  `deploy_flow.py` to fp32 — the root cause of "why isn't it quantizing?".
  `--no-llvm` opts out.
- **auto-stages the missing link deps** via `stage_llvm_link_deps()` into
  `thirdparty/.llvmdeps/`, so no sudo and no `-dev` packages are needed.

```bash
/scratch/staff/huaj/aiehlc/.venv/bin/python3 \
    src/frontend/tvmrelay/setup_tvm016.py --yes --force-source
```

### Why staging is needed

`llvm-config --system-libs` reports `-lz -lzstd -lxml2`, so TVM's `find_llvm`
runs `find_package(ZLIB)` / `Findzstd` and fails when the `-dev` packages are
absent (`Could NOT find ZLIB (missing: ZLIB_LIBRARY ZLIB_INCLUDE_DIR)`) — the
same missing-dev gap as skill **mlirbuildsandbox**. The staging helper:

| dep | approach |
|-----|----------|
| zlib, zstd | symlink the installed runtime soname + fetch the **version-matched** upstream header (`libz.so.1.2.11` → `zlib.h` v1.2.11) |
| libxml2 | compile a stub exporting the **16** symbols `libLLVMWindowsManifest.a` needs; that code is unreachable on Linux, so it only has to link |

Matching the header to the soname matters — a mismatched `zlib.h` compiles and
then misbehaves at runtime.

### Verified working

LLVM 19 (static) at `/scratch/staff/huaj/llvm-project/build` builds TVM 0.16
cleanly (0 errors) despite TVM's newest guard being `TVM_LLVM_VERSION >= 180`.
`apply_source_fixups()` handles the two known incompatibilities (LLVM 19
removed `StringRef::startswith`; NumPy 2.0 removed `np.math`).

Result on the default path:

```
[1/7] env    : tvm 0.16.0 | onnx 1.22.0 | llvm yes (USE_LLVM=.../llvm-config)
[3/7] fq2i   : 20 qnn.conv2d, 23 requantize, 1 quantize (the input)
[5/7] split  : 28 layers -> .../layers/ (all compile)
done: int8 C in worklocal/tvmrelay_deploy
```

Check it is genuinely int8, not just labelled so:

| signal | fp32 | int8 |
|--------|------|------|
| `resnet18_params.bin` | 46.7 MB | **23.5 MB** |
| kernels | 22 | **28** |
| graph dtypes | mostly `float32` | `int16`/`int32`/`uint8`, 2 `float32` |
| final line | `done: fp32 C` | `done: int8 C` |

If you see `done: fp32 C` on a default run, LLVM is off — do not accept it.

## 4. `split : skipped -- the emitted C does not compile`

Stage 5 has **two** skip paths and they look alike in a long log:

```python
if not split:      print("[5/7] split  : skipped (--no-split)")
elif not compiles: print("[5/7] split  : skipped -- the emitted C does not compile")
```

So `--no-split` being False does **not** mean split ran. `compiles` comes from
`verify_c`, which hardcodes

```python
tvm_root = Path(__file__).resolve().parents[3] / "thirdparty" / "tvm-0.16"
```

If `thirdparty/tvm-0.16` is missing (e.g. TVM lives in another worktree such as
`.worktrees/cnn/`), gcc fails on the very first include and the message blames
the *generated C*, which is actually fine. Check with:

```bash
python3 -c "
from pathlib import Path
p = Path('src/frontend/tvmrelay/deploy_flow.py').resolve()
r = p.parents[3]/'thirdparty'/'tvm-0.16'; print(r, r.exists())"
```

The real `fatal error` goes to **stderr** from `verify_c`, so under
`python3 -m pdb` it easily scrolls away from the `[5/7]` line. Breakpoint on
`compiles`, not on `split`.

## Gotcha when editing `ensure_onnx_mapping`

`ModuleNotFoundError` subclasses `ImportError`. A `except ModuleNotFoundError`
clause placed above `except ImportError: pass` **shadows** it, so a bare `raise`
(or falling off the end after re-raising) breaks the normal
"onnx installed, onnx.mapping deleted in 1.16" path that the shim exists for.
Match `exc.name == "onnx"` **exactly** — a missing submodule reports
`name="onnx.mapping"`, which is the expected case, not an error.
