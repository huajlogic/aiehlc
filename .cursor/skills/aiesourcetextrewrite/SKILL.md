<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: aiesourcetextrewrite
description: App source builds "successfully" but the pipeline emits an EMPTY module -- 0 routing connections, "No buffer allocations found; skipping BCF/PRX generation", then xchessmk dies with `Couldn't open ".../aie2ps.prx": no such file or directory`. Two distinct text-level causes in the aiehlc frontend: (1) the literal token `__global__` appearing in a COMMENT above the spatial-space descriptors, (2) a forward declaration of the launching function placed ABOVE the kernel definition. Also (3): the triple-angle launch syntax written in a COMMENT just above the launching function makes the rewriter splice `__aie_launch(...)` over the function signature -- `aout/newfile.cpp: error: expected unqualified-id` / `use of undeclared identifier '<fn>'`. Use when a new app source silently produces a do-nothing host.cc/library, or fails to compile only after aiehlc's rewrite.
---

# aiehlc source-rewrite traps (empty module, missing .prx)

## Symptom

The whole MLIR pipeline reports success and still writes `host.cc` / `kernel.cc`,
but the build dies at the very end in the kernel compile:

```
Error: Couldn't open ".../aout/worklocal/aie2ps.prx": no such file or directory
xchessmk Failed
```

The missing `.prx` is a *downstream* symptom, not the bug. Look earlier in the log:

```
No buffer allocations found; skipping BCF/PRX generation.
Routing provenance map written to ... (0 groups, 0 connections)
```

BCF/PRX emission is gated on the core-memory allocator having allocations
(`tilinglinalg_pipeline.cpp`, "No buffer allocations found" branch). Zero
allocations means the module was empty, which means **no tensor params were
parsed**.

## Diagnosis: compare against a known-good build

A healthy spatial-halo conv build prints:

```
[TilingLinalg] GemmSpace spatial-halo pass-through: halo_slice=61 halo_step=56 ...
[TilingLinalg] Tensor param: win_a [230x230x4] i8 (input) policy=RowBC_spatial
```

Two broken signatures, each with a different cause:

| Observed | Meaning | Cause |
|---|---|---|
| `Policy resolved: ... maxBufferBytes=32768 ... mode=0` and `Tensor param: win_a [12544x196]` | the descriptor **default-constructed** (32768 is the `l1_budget` default, `Bytes{32*1024}`) | cause A |
| no `Tensor param:` lines at all; `func.func @main()` has **no memref args** | the kernel was never registered before the launch was visited | cause B |

Inspect `aout/newfile.cpp` (the preprocessed/rewritten source the frontend
actually parses) — it shows both bugs directly.

## Cause A — `__global__` written in a comment

`src/llvm/aiehlc.cc` (~line 3869) rewrites the kernel body by **plain text
search**, not via the AST:

```cpp
if (KeywordToReplace == "__global__") {
    auto openBracePos = SourceCodeString.find("{", KeywordPos);   // <-- next '{' ANYWHERE
    SourceCodeString.insert(openBracePos + 1, "\n#ifdef KERNEL_COMPILE\n");
    // ... brace-match, insert "\n#endif\n" before the closing brace
}
```

So the literal token `__global__` **in a comment** above the spatial-space
descriptors makes the guard wrap the first descriptor's initializer:

```cpp
constexpr aie::GemmSpace RowBC_spatial = {
#ifdef KERNEL_COMPILE          // <-- injected here, NOT in the kernel
    .policy = {...}, .d1 = {...}, .d2 = {...}
#endif
};                             // -> default-constructed, every field 0/default
```

`KERNEL_COMPILE` is undefined in the host parse, so the whole initializer
vanishes. `d1.stride < d1.size` is then false, so `tileMode` never becomes
Overlap(1) and the spatial-halo path never engages.

**Fix:** never spell `__global__` in prose in an app source. Write "the kernel"
or "an annotated kernel". The same hazard applies to any other rewritten keyword.

## Cause B — prototype above the kernel definition

`VisitFunctionDecl` registers an annotated kernel into `globalKernelFuncs` when it
visits the kernel DEFINITION, and the launch site resolves its tensor params by
looking the kernel up in that map.

Clang's `FunctionDecl::hasBody()` / `getBody()` resolve across the **whole
redeclaration chain**: visiting a mere *prototype* of the launching function
yields the real body, so the visitor traverses the `<<<mesh>>>` launch at the
*prototype's* source position. If that position is above the kernel definition,
the launch is processed while `globalKernelFuncs` is still empty.

This is exactly what `#include "yourlib.h"` at the top of the file does when the
header declares the function containing the launch.

**Fix:** include the public header **after** the kernel definition. Keep the
geometry the descriptors need as bare `#define`s above them, and pin the two
copies together with `static_assert` at the include site so they cannot drift.

Verified by bisection: adding a single forward declaration above the kernel to an
otherwise-working source reproduces the empty-module build exactly.

## Fast bisection recipe

Both causes are invisible in a semantic diff of the descriptors — the text around
them is what matters. Bisect by transplanting between a working and broken source:

```bash
# 1. Does the descriptor itself work? Swap YOUR block into a known-good source.
# 2. Does the surrounding file break a known-good descriptor? Swap the baseline
#    block into YOUR file. If it ALSO fails, the bug is in the file, not the block.
source script/aiehlc.sh --aie-version 5 --runtime-source-file /tmp/probe.cc 2>&1 \
  | grep -E "spatial-halo pass-through|Tensor param|groups,|No buffer allocations"
```

Then confirm against `aout/newfile.cpp`, which shows the post-rewrite truth.

## Cause 3: launch syntax in a comment above the launching function

Different symptom -- a hard compile error, not an empty module:

```
newfile.cpp:908:5: error: expected unqualified-id
newfile.cpp:939:12: error: use of undeclared identifier 'stem_run'
Error: source file has compilation errors. Stopping.
```

`aout/newfile.cpp` (the rewritten source) shows the cause: a doc comment
directly above `static int stem_run(...)` contained the literal
`<<<mesh>>>` ("…in the same function as the <<<mesh>>> launch…"). The rewriter
matched it as the launch and replaced everything from there through the
function's `(` with `__aie_launch("", mesh, `, eating the signature:

```
// device.partition(...) VarDecl, which must sit in the same function as the
// __aie_launch("", mesh, const int8_t *wts, const conv2dstem_qparam *qp, uint8_t *ofm) {
```

The same literal in a comment far from any launching function (conv2dstem.cc's
include-placement banner) was harmless, which is what makes this easy to
re-introduce. **Fix:** never write the triple-angle syntax in a comment; say
"kernel launch". Always read `aout/newfile.cpp` around the reported line --
it is the rewritten text, not your source.
