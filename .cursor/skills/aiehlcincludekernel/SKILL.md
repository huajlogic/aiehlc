<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: aiehlcincludekernel
description: "An aiehlc entry file may `#include \"kernel.cc\"` instead of carrying the `__global__` kernel inline. Read before touching inlineSourceIncludes / GetKeyReplaceAndAddInclude in src/llvm/aiehlc.cc, or when a build fails with `unknown type name '__global__'` / `no matching function for call to 'acquire_input_window'` pointing at an INCLUDED .cc. Explains why the splice must be opaque (no #line) and why kernel-visible #defines are the silent failure."
---

# `main.cc` that `#include`s a kernel `.cc`

```bash
# ELF  -- entry file has main()
source script/aiehlc.sh --aie-version 5 \
    --runtime-source-file ./src/aietensorop/conv2dstem/main.cc

# archive -- entry file has no main() (skill: hostlibrarymode)
source script/aiehlc.sh --aie-version 5 \
    --runtime-source-file ./src/aietensorop/conv2dstem/conv2dstem.cc
```

Same kernel, two entry files, two artifact kinds. `hostcompile.sh:376` picks by
grepping the generated `host.cc` for `main()`.

## Why it used to fail

```
conv2dstem.cc:273:1: error: unknown type name '__global__'
conv2dstem.cc:332:35: error: no matching function for call to 'acquire_input_window'
```

`GetKeyReplaceAndAddInclude` (`src/llvm/aiehlc.cc`) reads **only the main file's
buffer** and does every rewrite on that one string: `#define` collection,
`__global__` → `__attribute__((annotate("__global__")))`, the
`#ifdef KERNEL_COMPILE` body guard, and the `<<<mesh>>>` → `__aie_launch`
rewrite. Clang expands `#include` *after* that, so an included kernel was never
rewritten. `__global__` has no `#define` anywhere — it is purely text-replaced —
hence `unknown type name`.

The second error is diagnostic gold: it reads
`newfile.cpp:23:35: note: candidate template ignored`, proving the **stub
preamble was already in scope** (it is prepended to the TU). Only the *rewrites*
were missing.

`inlineSourceIncludes()` now splices quoted `.cc`/`.cpp` includes into the text
before the `#define` scan, so every existing rewrite applies unchanged.

## The splice must be OPAQUE — never emit `#line`

Tempting, and wrong. Two later stages key off the kernel's `FileID`:

| stage | code | breaks how |
|---|---|---|
| kernel export | `GetFuncText`: `getBufferData(getFileID(startLocation))` | resolves to the **unrewritten** `conv2dstem.cc` — no `annotate` to strip, no `KERNEL_COMPILE` guard to remove |
| `host.cc` | harvested from `getRewriteBufferFor(getMainFileID())`, but `RemoveText(kernel)` / `InsertText(_binary_kernel_*)` apply at the kernel's own location | edits land in a buffer nobody reads: kernel body stays in `host.cc`, externs missing |

So the kernel must *appear* to live in the main file. Cost: diagnostics point
into the flattened buffer. **Read `aout/newfile.cpp`** — it is that buffer
verbatim, and is the first thing to check when this misbehaves.

## Kernel-visible `#define`s are the silent failure

The kernel TU is a **flat text copy** — `userMacroDefines` + prologue + body,
with no `#include`s (hence the note at `conv2dstem.cc:61-64`). The body uses
`SP_KH`, `SP_KW`, `SP_C`, `SP_S`, `SP_K`, `SP_OHR`, `OW_T` and the
backslash-continued `RD_PARAM_I32`. If the `#define` scan ever stops covering
the included text, none of them reach `aout/worklocal/conv2d_spatial.cc` and it
dies under xchess with undeclared identifiers — **after** the host side looks
fine. Always check:

```bash
grep -cE '^#define SP_(KH|KW|C|S|K|OHR)' aout/worklocal/conv2d_spatial.cc   # want 6
grep -c RD_PARAM_I32 aout/worklocal/conv2d_spatial.cc                        # want >0
```

The scan runs over the already-flattened string as one stream, so `ifDepth` /
`inMultiLine` stay continuous — no per-file reset is needed with the splice
approach (it would be, if files were scanned separately and concatenated after).

## Other traps

- **Header-copy regex** (`aiehlc.cc`, near the end) matches *any* quoted
  include. It must skip `.cc`, or it copies the raw unrewritten kernel into
  `worklocal/` next to a `host.cc` that includes it — reproducing
  `unknown type name '__global__'` at host-compile time.
- **Two launch sites is fine.** Including `conv2dstem.cc` brings its own
  `conv2d_spatial` launch along; the rewriter loops over launches, so each
  becomes an independent `__aie_launch`. Only the executed path matters.
- **`partition()` must be in the same function as the launch** — unchanged, and
  satisfied inside `stem_run` (`conv2dstem.cc:476`, `:614`).
- **`stem_run` has two overloads.** 3-arg `(wts, qp, ofm)` is the shared launch
  site; 4-arg `(ifm, wts, ofm, qp)` stages a raw input first, for an including
  driver. Not folded into one, because `conv2d_stem_prepadded` stages
  *differently* (`stage_ifm_prepadded`).
- **Do not also include `parameter.h`** from a file that includes
  `conv2dstem.cc`: both define `OUTPUT_H`/`K` (same values, different spelling)
  and would redefine them.
- The raw-string regex needs a custom delimiter (`R"RE(...)RE"`) — the pattern
  contains `"` and `)`.

## Verification

| check | expect |
|---|---|
| `grep -c '__global__' aout/newfile.cpp` | > 0 |
| `aout/worklocal/conv2d_spatial.cc` | exists, has `int64_t v = ` (int32 acc + epilogue) |
| ELF `aout/worklocal/build/host` | AArch64 EXEC, `main` + `conv2d_stem` + `_binary_kernel_conv2d_spatial_start`, 0 undefined |
| no `*.a` in `build/` | correct for a `main()` entry |

**Regressions to run — touching the rewriter is the risk:**
`conv2dstem.cc` still archives to `libconv2dstem.a`;
`example/tileprogram/ccode/simplematmul2.cc` still builds;
`deploy_flow.py --aie-offload --aie-layers 1` still partitions 1 subgraph and
links (it calls `conv2d_stem_prepadded` from that archive).

No existing entry file in the repo includes a `.cc`, so the change is purely
additive — verified by grepping every `example/tileprogram/ccode/*.cc`.
