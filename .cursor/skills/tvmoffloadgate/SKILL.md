---
name: tvmoffloadgate
description: TVM frontend emits AIE kernels / runs xchesscc despite offload being disabled — the AIE-vs-CPU backend split is decided at several call sites and a flag that gates only one of them silently leaves the rest on the AIE path.
---

# TVM frontend: AIE-vs-CPU offload gate

## Symptom

`demo_flow.py` sets `enable_aiehlc_offload = False`, the per-launch stage
correctly reports `CPU(forced)` for every conv — and the build still spends
minutes in xchesscc, leaving `aieml_conv_bn_*.prx` / `.bcf` / `kernel_*.cc` in
the build dir.

## Root cause

`cpu_codegen.is_aie_op(op)` answers **"could this op run on AIE"** (is it in the
conv2d family), not **"does it, in this build"**. The orchestrator had its own
copies of the backend decision that consulted only `is_aie_op`, so
`orchestrate_plan` kept calling `core.orchestrate_conv_layer` per conv →
`kernel_<name>.cc` → `hostcompile.sh` globs `kernel_*.cc` (`script/hostcompile.sh:99`)
→ `compile_one_kernel` → `kc.sh` → xchesscc.

A flag that gates one call site is not a gate. Grep every backend-selecting site
before believing a switch works.

## The predicate

`orchestrator._to_aie(op, enable_aiehlc_offload)` is the single source of truth:

```python
return cpu_codegen.is_aie_op(op.op) and enable_aiehlc_offload
```

Every site that picks a backend must call it. `is_aie_op` alone is correct only
when asking about op *kind* (e.g. "does this op need a `wts_<idx>` params
buffer" — true for both backends, since the forced-CPU conv reads the same
header+weights+BN layout).

## What an all-CPU build must also provide

Turning offload off is not just "skip the conv branch" — three things are
*produced by* the AIE path and vanish with it:

1. **`host.cc` itself.** It is created by the first `orchestrate_conv_layer`
   call; `orchestrate_plan` only appends to it. With no conv, nothing creates
   it, yet `hostcompile.sh` requires it (it is the only translation unit it
   compiles). → `_emit_cpu_only_host()`.
2. **`routing.cc`.** `aie_runtime.c` declares `extern void routing(XAie_DevInst*)`
   and calls it from `__Runtime_routing_init`; the reference lives in
   `aie_runtime.o`, which is *always* linked. Without a definition the link
   fails with `undefined reference to routing(XAie_DevInst*)`. →
   `_emit_cpu_only_routing()` emits a no-op stub.
3. **A kernel for `hostcompile.sh` to compile.** Its single-kernel fallback
   hard-errors on missing `kernel.cc`. Host-only is now a first-class mode
   (`script/hostcompile.sh`, the `elif [ ! -f .../kernel.cc ]` branch).

The all-CPU `main` also skips `__Runtime_explicit_init` / mesh partition /
teardown entirely — a pure-CPU pipeline must not require working AIE hardware.

## Params must be filled, not memset

`main.cc` used to `memset(wts_<idx>, 0, n)` with a TODO. That is **not** a
harmless placeholder on the CPU path: the conv config (`H,W,Cin,Cout,K,stride`)
is read from the *first 6 bytes of the params buffer*, so an all-zero buffer
means `H=W=0` and the conv writes nothing. `_emit_param_fillers()` emits
`fill_conv_params` / `fill_fc_params` mirroring `model.make_conv_params` /
`fc_params_no_header`.

## Verifying bit-exactness

Do not trust the logits alone — with placeholder weights they are all-zero, so
a match is vacuous. Compile the emitted C natively (stub `__Runtime_Alloc` →
`calloc`, drop the device calls), dump **every** intermediate buffer, and
compare against a replay of `_compiler.cpu_reference` that keeps per-launch
outputs (`cpu_reference` returns only last-writer values, and the plan reuses
scratch names). 29 buffers, 9 non-trivial, is the current bar.

## Environment gotcha (unrelated to this fix)

`script/setup.sh` regenerates `thirdparty/alib/{include,lib}`, which in a
worktree is a symlink to the main repo. A build racing that regeneration fails
with `xaiengine/xaie_helper.h: No such file` or `cannot find -lxaienginea78`.
Re-run once it settles; it is not a code defect.

## Files

- `src/frontend/tvm/orchestrator.py` — `_to_aie`, `_emit_cpu_only_host`,
  `_emit_cpu_only_routing`, `_emit_param_fillers`, `_emit_param_init`
- `src/frontend/tvm/demo_flow.py` — the flag, threaded into stage 5
- `script/hostcompile.sh` — host-only (no kernel sources) mode
- `src/frontend/tvm/test_tvm_frontend.py` —
  `test_orchestrate_plan_offload_disabled`
