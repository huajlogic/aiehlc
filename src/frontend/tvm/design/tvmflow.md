# TVM Frontend Flow — Design, Architecture & Implementation

This document is the implementation-level companion to
[`doc/design/tvm_frontend.md`](../../../../doc/design/tvm_frontend.md). It walks
the **end-to-end flow** of `src/frontend/tvm/` — from a real model down to
emitted per-launch code — and documents the concrete data structures, dispatch
points, and bit-exactness contracts each stage relies on.

---

## 1. What this frontend is

The TVM frontend is a **third entry point into `TilingLinalgPipeline`**, alongside
the C++ `aiehlc` driver and the `aietriton` Python path. It takes a scaled-down
int8 ResNet-18, lowers it through TVM Relay, walks the fused graph to recover a
per-op AIE launch plan, and emits per-launch code by reusing the compiled
`_aietriton_core` pybind extension.

Design principle: **every stage degrades gracefully**. Without TVM the plan comes
straight from the canonical `model.layer_plan()`; without the built extension the
numpy CPU reference and plan recovery still work; TVM CPU C emission only needs
TVM's TE + build path (not Relay).

---

## 2. The pipeline at a glance

```
                        ┌──────────────────────────────────────────────────┐
 Stage 0 (reference)    │ real ResNet-18 (example/model/resnet18py)         │
                        │   dog image → torch → top-k "it's a dog"          │
                        └──────────────────────────────────────────────────┘
                                          │  (same image, quantized int8)
                                          ▼
 Stage 1 (plan)     model.export_onnx() ─► ONNX
                      └ relay_import.import_relay  ONNX ─► Relay
                          (InferType, SimplifyInference[BN fold],
                           FoldConstant, FuseOps, InferType)
                            └ walk.build_plan   fused graph ─► List[LayerOp]
                                                (validated vs model.layer_plan())
                                          │
                                          ▼
 Stage 2 (oracle)   _compiler.cpu_reference(plan, input)  ─► bit-exact int8 logits
                                          │
                                          ▼
 Stage 3 (IR)       model.plan_to_aiegraph_dicts(plan) ─► op dicts
                      └ core.build_aiegraph_module      ─► verified textual aiegraph IR
                                          │
                                          ▼
 Stage 4 (emit)     core.lower_aiegraph(ir) ─► per-launch descriptors
                      └ per op: dispatch on cpu_codegen.is_aie_op
                          conv2d family ─► core.run_aie_pipeline  (host.cc/kernel.cc/routing.cc)
                          everything else ─► cpu_codegen.emit_cpu_launch  (<func_name>.c, TVM target="c")
```

`demo_flow.py` is the runnable transcription of exactly these five stages.

---

## 3. Module map

| File | Role |
|------|------|
| `model.py` | scaled ResNet (torch) + ONNX export + canonical `layer_plan()` + param buffers + `plan_to_aiegraph_dicts` |
| `relay_import.py` | ONNX → Relay import + optimisation passes; `tvm_available()` / `onnx_available()` |
| `walk.py` | fused-graph `ExprVisitor` → `LayerOp` plan; validates vs canonical |
| `kernels.py` | raw-C kernel bodies for the conv2d family (int8/int16 Q7 math) |
| `_compiler.py` | tensor specs + `run_aie_pipeline` glue; bit-exact numpy CPU oracle; **AIE-vs-CPU emit dispatch**; im2col DMA helper |
| `cpu_codegen.py` | **TVM `target="c"` CPU fallback** for non-conv ops (bit-exact TE transcription of the Q7 oracle) |
| `demo_flow.py` | runnable stage-by-stage demo of the whole flow |
| `__init__.py` | `run_resnet` entry + `RunResult` |
| `test_tvm_frontend.py` | verification (PASS/FAIL), TVM/extension-optional |

The C++ side lives at `src/mlir/mlirfront/frontend/aiegraph/` (the dialect) and
`src/mlir/mlirfront/frontend/aietriton/` (the `_aietriton_core` pybind + `.so`).

---

## 4. The central data structure: `LayerOp`

The whole frontend is organized around a flat list of `LayerOp` (`model.py`). It
carries geometry for all four op kinds; unused fields default to 0.

| op kind | key fields | consumers |
|---------|-----------|-----------|
| `conv_bn_relu`, `conv_bn` | `ins[0]`, `out`, `H,W,Cin,Cout,K,stride`, derived `out_h,out_w` | conv oracle, `_tensor_specs`, kernel body, aiegraph conv op |
| `residual_add_relu` | `ins[0]`(main), `ins[1]`(skip), `out`, `length` | residual oracle, CPU codegen `_residual_te` |
| `avgpool_fc` | `ins[0]`, `out`, `spatial_h,spatial_w,channels,num_classes` | fc oracle, CPU codegen `_avgpool_fc_te` |

`layer_plan()` is the canonical ~29-launch forward pass. Buffer wiring is
expressed by **reused scratch names** (`input/feat1/feat2/feat3/tmp1/tmp2/skip_ds/
logits`); this is resolved to SSA producer indices when lifting into the dialect.

---

## 5. Stage 1 — ONNX → Relay → plan

`relay_import.import_relay` runs `relay.frontend.from_onnx` then a `Sequential`:

```
InferType → SimplifyInference → FoldConstant → FuseOps → InferType
```

`SimplifyInference` folds BatchNorm into `multiply` + `add`, so a conv "block" in
the fused graph is `conv2d → multiply → add [→ relu]`.

`walk.build_plan` walks the fused `IRModule` with a `relay.ExprVisitor` and maps
patterns to launches:

| Relay pattern (post SimplifyInference) | AIE launch |
|----------------------------------------|------------|
| `nn.conv2d` + folded BN + `nn.relu` | `conv_bn_relu` |
| `nn.conv2d` + folded BN | `conv_bn` |
| `add` + `nn.relu` (residual join) | `residual_add_relu` |
| `nn.global_avg_pool2d` + `nn.dense` (+ bias) | `avgpool_fc` |

**Validate, don't rebuild.** Recovering exact buffer wiring from a fused graph is
fragile, and `layer_plan()` already encodes it in hand-verified form. So the walk
recovers the *structural* op sequence from the real graph and **validates** it
against the canonical structure; on a match it returns the canonical plan (wiring
intact). Without TVM, or on divergence, it falls back to the canonical plan (or
raises when `strict=True`). This keeps the path genuinely TVM-driven while staying
bit-exact.

---

## 6. Stage 2 — the bit-exact CPU oracle (`_compiler.py`)

`cpu_reference(plan, input_data)` is a pure-numpy interpreter maintaining a
named-buffer dict. It is the **oracle** every emitted path is checked against, and
it is a byte-for-byte port of `resnet18_triton.py`'s CPU references. The four
per-op kernels — and the exact int types that make them bit-exact — are:

- `_cpu_conv` (`_compiler.py:49`): `int16` accumulator; Q7 BN
  `bn_out = (s * int16(bn_scale)) >> 7`, then `+= int16(bn_bias)`; clamp `[0,127]`
  (relu) or `[-128,127]` (no relu). Config read via `int(np.uint8(...))`.
- `_cpu_add_relu` (`_compiler.py:87`):
  `out[i] = int8(clamp(int16(main[i]) + int16(skip[i]), 0, 127))`.
- `_cpu_avgpool_fc` (`_compiler.py:96`):
  `pooled[c] = int8(int(Σ_spatial int16(feat)) // spatial_sz)`;
  `logits[j] = int8(clamp(Σ_c int16(pooled)*int16(w) + int16(bias), -128, 127))`.
  FC params are **headerless** here (`w = fc_params[:C*NC]`, `bias = [C*NC:]`).

These same three non-conv formulas are what the TVM CPU codegen (§8) reproduces.

---

## 7. Stages 3 & 4 (AIE) — the aiegraph dialect + `run_aie_pipeline`

`compile_plan(..., via_aiegraph=True)` (default) lifts the whole `LayerOp` plan
into the formal **aiegraph** MLIR dialect, verifies it in C++, and lowers it back
to per-launch descriptors:

```python
ir       = core.build_aiegraph_module(op_dicts, "resnet")  # build + verify -> IR text
launches = core.lower_aiegraph(ir)                         # walk -> per-launch descriptors
```

Key property: buffer wiring becomes **SSA def-use** instead of reused string
names. `model.plan_to_aiegraph_dicts` resolves each reused scratch name to an
explicit producer index (last-writer-per-name in program order), so a residual's
`%skip` back-references the correct earlier launch. The verifier enforces that a
residual's three operands share one element count.

Each descriptor is `{op, func_name, index, weights, tensor_specs}`. The C++-derived
`tensor_specs` are **byte-identical** to `_compiler._tensor_specs`:

| Op | windows: `(shape, 8, isInput)` |
|----|-------------------------------|
| `conv_bn_relu` / `conv_bn` | `([Cin·H·W], in)`, `([param_sz], in)`, `([Cout·outH·outW], out)` |
| `residual_add_relu` | `([n], in)`, `([n], in)`, `([n], out)` |
| `avgpool_fc` | `([channels·sh·sw], in)`, `([param_sz], in)`, `([num_classes], out)` |

Kernel bodies stay in Python (`kernels.kernel_body_for`); Python pairs each conv
launch's specs with its body and calls `run_aie_pipeline`, which writes one output
file set per call (`host.cc`, `kernel.cc`, `<kernel>.cc`, `routing.cc`,
`aieml.bcf`, `aieml.prx`) into `out_root/<idx>_<op>/`.

---

## 8. The CPU fallback path (`cpu_codegen.py`)

### 8.1 Why it exists

The `run_aie_pipeline` backend implements **only the conv2d family**. The other
two aiegraph ops (`residual_add_relu`, `avgpool_fc`) are **not** sent to AIE; they
are emitted as **bit-exact CPU C generated by TVM** (`target="c"`). Non-conv ops
still build/verify/lower inside the aiegraph IR — only the *emit* path forks.

### 8.2 Op split — the single source of truth

```python
AIE_OPS = {"conv_bn", "conv_bn_relu"}          # -> run_aie_pipeline
CPU_OPS = {"residual_add_relu", "avgpool_fc"}  # -> TVM target="c"
is_aie_op(op_name) -> bool                      # the dispatch predicate
```

### 8.3 Dispatch points

Every emit site branches on `is_aie_op`:

| Site | AIE op | non-AIE op |
|------|--------|------------|
| `_compiler.compile_launch` (legacy direct, `via_aiegraph=False`) | `run_aie_pipeline` | `cpu_codegen.emit_cpu_launch` |
| `_compiler.compile_plan_via_aiegraph` (default) | `run_aie_pipeline` | `cpu_codegen.emit_cpu_launch` |
| `demo_flow.py` Stage 4 loop | `run_aie_pipeline` | `cpu_codegen.emit_cpu_launch` |

Output layout stays symmetric: each launch gets `out_root/<idx>_<op>/`. Conv dirs
hold `host.cc`/`kernel.cc`/`routing.cc`/…; CPU dirs hold a single `<func_name>.c`.

### 8.4 Bit-exact TE mapping

Each CPU op is a TVM TE compute mirroring the numpy oracle (§6). The rules that
keep the emitted C numerically identical to numpy:

- int8 inputs are widened with `.astype("int16")`, so every `te.sum` reduction
  accumulates in int16 and the emitted C `int16_t` **wraps exactly** like the
  numpy `int16` oracle;
- the pool divide uses `te.truncdiv`; post-ReLU features are `≥ 0`, so
  truncation == floor, matching the oracle's `int(s) // spatial_sz`;
- saturation is `te.max(te.min(x, hi), lo)`.

Builders:

- `_residual_te(n)` → `[main, skip, out]`:
  `out[i] = int8(clamp(int16(main[i]) + int16(skip[i]), 0, 127))`.
- `_avgpool_fc_te(sh, sw, C, NC)` → `[feat, wts, bias, logits]`, split into
  separate stages because **TVM requires reductions at the top level of a
  compute**:
  - `psum[c] = Σ_r int16(feat[c·ssz+r])`
  - `pooled[c] = int8(truncdiv(psum[c], ssz))`
  - `acc[j]   = Σ_k int16(pooled[k])·int16(wts[k·NC+j])`
  - `logits[j]= int8(clamp(acc[j] + int16(bias[j]), -128, 127))`
  - weights/bias headerless: `wts = fc_params[:C·NC]`, `bias = fc_params[C·NC:]`.

Because the **same TE** drives both `target="c"` (emitted artifact) and
`target="llvm"` (run by the tests against numpy), the two are identical by
construction — the tests exploit exactly this.

### 8.5 Build / emit implementation

```python
op_tensors(op)                 # LayerOp -> [ins..., out] TE list; raises for AIE/unknown ops
_make_module(tensors, name, target)  # portable build (new & classic TVM)
cpu_c_source(op, func_name)    # -> C source string (target="c")
build_llvm(op, func_name)      # -> (runnable llvm module, tensors)  [used by tests]
emit_cpu_launch(op, dir, name) # writes <name>.c into dir; returns success
```

`op_tensors` raises `ValueError` for an AIE op or an unknown op — the strict
extension point: adding a new CPU op means adding a TE builder + a `CPU_OPS` entry.

### 8.6 ABI note (installed TVM specifics)

The installed TVM (0.26) is an FFI/relax build: **no `relay`, no
`te.create_schedule`, no `tvm.tir`**. So `_make_module` is written portably:

- new API: `te.create_prim_func(tensors)`, set the PrimFunc `global_symbol` to
  `func_name` (via `.with_attr`) so the requested name is the public symbol, then
  `tvm.build(pf, target)`; read source via `.inspect_source()`;
- classic API fallback: `te.create_schedule` + `tvm.build(..., name=func_name)`;
  read source via `.get_source()`.

The `target="c"` codegen emits a **packed** function under the TVM FFI ABI
(entry `__tvm_ffi_<func_name>`, `DLTensor`/`TVMFFIAny` args, needs the `tvm/ffi`
headers to link) — **not** a standalone `void <func_name>(int8_t*, …)`. Setting
`global_symbol` makes `func_name` the visible symbol so downstream tooling can
find the entry.

Wrapping the packed func into a plain host entry and linking the CPU ops into one
end-to-end AIE+CPU executable is **out of scope** (no multi-layer host
orchestrator exists yet). Each launch is emitted as a standalone C artifact,
mirroring the standalone `host.cc`/`kernel.cc` the AIE path emits per launch.

---

## 9. Verification (`test_tvm_frontend.py`)

Runs with or without TVM / the built extension (parts needing them are skipped,
not failed):

- `test_cpu_reference_matches_triton` — the numpy oracle matches an independent
  inline port of `resnet18_triton.py`'s CPU reference;
- `test_plan_matches_canonical` — `build_plan` returns the canonical structure;
- `test_kernel_bodies_wellformed` — every op has a C body with the window ABI;
- `test_run_resnet_smoke` — `run_resnet(emit_aie=False)` returns a plan + class;
- `test_emit_aie` — if the extension is built, one conv launch emits its file set;
- `test_cpu_codegen_bit_exact` — if TVM present, build the residual and avgpool
  TE on `target="llvm"`, run random int8 inputs, assert elementwise equality with
  `_cpu_add_relu` / `_cpu_avgpool_fc`; also asserts `func_name` appears in
  `cpu_c_source(...)`;
- `test_cpu_codegen_rejects_aie_op` — `op_tensors(conv)` raises `ValueError`;
- `test_dispatch_routes_non_conv_to_cpu` — if the extension is built, run
  `compile_plan_via_aiegraph` on the canonical plan and assert conv dirs contain
  `host.cc` (no `.c`) while residual/avgpool dirs contain `<func_name>.c`
  (no `host.cc`).

```bash
python src/frontend/tvm/test_tvm_frontend.py     # PASS: all checks passed.
python src/frontend/tvm/demo_flow.py             # end-to-end emit, all launches OK
```

---

## 10. Design decisions & rationale

| Decision | Rationale |
|----------|-----------|
| Validate-not-rebuild the plan | fused-graph buffer wiring is fragile; canonical plan is hand-verified and bit-exact |
| Non-conv ops → TVM CPU C (not AIE) | the AIE `run_aie_pipeline` backend only implements the conv2d family |
| Share one TE across `target="c"` and `target="llvm"` | makes the emitted C bit-exact with the numpy oracle *by construction*, testable without a C compiler |
| int16-widened reductions + `truncdiv` | reproduces numpy `int16` wraparound and post-ReLU floor division exactly |
| Non-conv ops stay in the aiegraph IR | the dialect models them fine (build/verify/lower); only the runtime emit path forks |
| Emit standalone per-launch artifacts | mirrors the AIE path; a multi-layer AIE+CPU host orchestrator does not exist yet |

---

## 11. Out of scope (explicitly)

- Host-ARM execution / linking the CPU ops into one end-to-end AIE+CPU executable.
- BYOC graph partitioning.
- Generic Relay→C for arbitrary unknown ops (only the two known CPU ops).

---

## 12. See also

- [`doc/design/tvm_frontend.md`](../../../../doc/design/tvm_frontend.md) — the
  top-level frontend design doc (this file is its implementation companion).
- [`doc/design/tvm_custom_model_recipe.md`](../../../../doc/design/tvm_custom_model_recipe.md)
  — "bring your own model" how-to.
- `src/mlir/mlirfront/frontend/aiegraph/` — the dialect (`td/`, `lower/`, `unitest/`).
- `example/tileprogram/design/triton/resnet18_triton.py` — the hand-written
  template whose launch sequence, kernel bodies, and CPU references this frontend
  reproduces.
