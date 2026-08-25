# TVM Frontend — scaled-down ResNet-18 onto the AIE mesh

## Overview

The TVM frontend is a **third entry point into `TilingLinalgPipeline`**, alongside
the C++ `aiehlc` driver and the `aietriton` Python path. It takes the scaled-down
int8 ResNet-18, lowers it through **TVM Relay**, walks the fused graph to recover
a per-tile AIE launch plan, and emits the same kernel launches the hand-written
`example/tileprogram/design/triton/resnet18_triton.py` produces.

Package root: `src/frontend/tvm/`.

```
model.export_onnx()            scaled ResNet (torch.nn) ─► ONNX
  └─ relay_import.import_relay  ONNX ─► Relay
                               (InferType, SimplifyInference[BN fold],
                                FoldConstant, FuseOps, InferType)
       └─ walk.build_plan       fused graph ─► LayerOp launch plan
                               (validated against model.layer_plan())
            └─ _compiler.compile_plan   each launch ─► run_aie_pipeline
                                        (host.cc / kernel.cc / routing.cc / …)
            └─ _compiler.cpu_reference  bit-exact numpy oracle for verification
```

Every stage degrades gracefully. Without TVM the plan comes straight from the
canonical `model.layer_plan()`; without the built `_aietriton_core` pybind
extension the CPU reference and plan recovery still work, only `compile_plan` /
`run_resnet(emit_aie=True)` need it.

## Relation to the other two frontends

| Frontend | Input | How it reaches `TilingLinalgPipeline` | Scope |
|----------|-------|---------------------------------------|-------|
| **aiehlc** (C++) | C++ using `aie::SpatialPolicy` NTTP + Clang AST | `AieFrontEnd.cc` builds routing IR directly in-process | General GEMM / conv2d; `DmaTransform` / `Conv2dSpace`-derived im2col |
| **aietriton** (Python) | `@aie_triton.jit` GEMM kernel | AST parse → tensor specs + C body → `_aietriton_core.run_aie_pipeline` | Single-kernel GEMM |
| **tvm** (Python) | scaled ResNet-18 via ONNX → Relay | fused-graph walk → per-launch tensor specs + C body → `_aietriton_core.run_aie_pipeline` | Multi-launch CNN forward pass (~29 launches) |

The TVM frontend is **pipeline-internal** exactly like `aietriton`: it reuses the
same compiled `_aietriton_core` pybind extension (imported as
`from ..aietriton import _aietriton_core`), so a full CNN is expressed as a
sequence of `run_aie_pipeline` calls — one per `LayerOp` — rather than a single
GEMM. It shares the four hand-verified kernel bodies with `resnet18_triton.py`.

## Model (scaled-down)

`model.py` is the single source of truth. 8×8×1 input, channels 4→8→16→32,
4 classes, int8 + Q7 BatchNorm. Post-activation ResNet: conv+BN+ReLU stem, four
stages of two BasicBlocks each (first block of stages 2–4 downsamples with a 1×1
stride-2 skip), global average pool, FC. This is **not** the 224×224 / 1000-class
ImageNet ResNet in `example/model/resnet18py`.

`build_torch_model()` builds the network; `export_onnx()` writes an ONNX graph
(opset 13, input name `"input"`) so the Relay importer has a real graph to walk.
`layer_plan()` is the canonical ~29-launch forward pass; buffer names
(`input / feat1 / feat2 / feat3 / tmp1 / tmp2 / skip_ds / logits`) match
`resnet18_triton.py`'s scratch layout.

## ONNX → Relay import (relay_import.py)

`import_relay(onnx_path, input_name, input_shape)` runs `relay.frontend.from_onnx`
then a `Sequential` pass pipeline:

```
InferType → SimplifyInference → FoldConstant → FuseOps → InferType
```

`SimplifyInference` folds BatchNorm into `multiply` + `add` (scale/shift), so a
conv "block" in the fused graph is `conv2d → multiply → add [→ relu]`. `FuseOps`
wraps ops in inner functions. `tvm_available()` / `onnx_available()` gate the
optional path.

## Fused-graph walk (walk.py)

`build_plan(onnx_path, strict)` walks the fused `IRModule` with a
`relay.ExprVisitor` (`recover_signatures`) and maps op patterns to AIE launches:

| Relay pattern (after SimplifyInference)             | AIE launch          |
|-----------------------------------------------------|---------------------|
| `nn.conv2d` + folded BN `multiply`/`add` + `nn.relu` | `conv_bn_relu`      |
| `nn.conv2d` + folded BN `multiply`/`add`            | `conv_bn`           |
| `add` + `nn.relu` (residual join)                   | `residual_add_relu` |
| `nn.global_avg_pool2d` + `nn.dense` (+ bias)        | `avgpool_fc`        |

Conv geometry `(H, W, Cin, Cout, K, stride)` is recovered from the graph:
`(Cout, Cin, K, K)` from the weight's `checked_type.shape` (OIHW), `(H, W)` from
the input's `checked_type.shape` (NCHW), `stride` from `attrs.strides[0]`.

**Why the walk validates rather than rebuilds.** Recovering the *buffer wiring*
(which scratch buffer feeds which launch) and the residual element counts from a
fused graph is fragile, and `model.layer_plan()` already encodes that wiring in a
hand-verified form. So the walk recovers the *structural* op sequence from the
real graph and **validates** it against the canonical plan's structure
(`validate_against_canonical`: ordered conv geometry, residual count, GAP+dense
presence); on a match it returns the canonical plan (buffer wiring intact). If
TVM is unavailable or the structure diverges it falls back to the canonical plan
(or raises when `strict=True`). This keeps the frontend a genuine TVM-driven path
while staying bit-exact with the verified reference.

## Kernel bodies (kernels.py)

Raw-C compute bodies matching the four `@aie_triton.jit` kernels. All four use
the two-input / one-output window ABI (`window_in_0`, `window_in_1`,
`window_out_0`). Config travels in the param-buffer header so one body serves
every launch of that type.

Two int16 details are **load-bearing for bit-exactness** with the CPU reference:

* the conv accumulator is `int16` and wraps at each `+=`;
* Q7 BN is `(int16)(acc * bn_scale) >> 7` — the product is truncated to int16
  **before** the shift.

## Param buffers

- conv: `[config:6={H,W,Cin,Cout,K,stride}][weights:Cin·Cout·K·K][bn_scale:Cout][bn_bias:Cout]`
- fc:   `[config:4={spatial_h,spatial_w,channels,num_classes}][weights:channels·nclass][bias:nclass]`

Deterministic patterns (conv weights ±1 alternating, `bn_scale=64`≈0.5 Q7, bias 0;
fc weights 1, bias 0) — identical to `resnet18_triton.py`, so the AIE result and
the numpy CPU reference stay bit-exact.

**FC header divergence (intentional).** `resnet18_triton.py`'s
`make_fc_params(Cin, Cout)` is *headerless*; `model.make_fc_params` adds the
4-byte config header so one `avgpool_fc` body serves any shape. The AIE launch
uses the headered version (the kernel reads the header); the CPU reference uses
`fc_params_no_header` (matches the headerless `cpu_avgpool_fc`). Both produce
identical logits because the fc weights are 1 and bias 0.

## Launch glue + tensor specs (_compiler.py)

`compile_plan(plan, out_root, mesh)` iterates the plan and, for each `LayerOp`,
calls `compile_launch`, which assembles the per-window `tensor_specs` and the C
kernel body and calls `run_aie_pipeline`:

```python
run_aie_pipeline(mesh_rows, mesh_cols, tensor_specs, out_dir, body, func_name)
```

`tensor_specs` is a list of flat int8 `(shape, bits, isInput)` tuples per window:

| Op | windows: (shape, 8, isInput) |
|----|------------------------------|
| `conv_bn_relu` / `conv_bn` | `([Cin·H·W], in)`, `([param_sz], in)`, `([Cout·outH·outW], out)` |
| `residual_add_relu` | `([n], in)`, `([n], in)`, `([n], out)` |
| `avgpool_fc` | `([channels·sh·sw], in)`, `([param_sz], in)`, `([num_classes], out)` |

Each launch gets its own `out_root/<idx>_<op>` directory because
`run_aie_pipeline` writes one output file set per call (`host.cc`, `kernel.cc`,
`<kernel>.cc`, `routing.cc`, `aieml.bcf`, `aieml.prx`).

## The `aiegraph` dialect path (formal IR between the plan and the backend)

By default `compile_plan(..., via_aiegraph=True)` no longer calls
`compile_launch` directly; it first lifts the whole `LayerOp` plan into a formal
**`aiegraph`** MLIR dialect, verifies it in C++, then lowers it back to per-op
launches. The dialect promotes the informal Python `LayerOp` list to real IR:
verification, textual round-trip/dump, and — crucially — **buffer wiring becomes
SSA def-use** instead of reused string buffer names.

### Ops

One op per fused/quantized tensor op (mirrors the four `LayerOp` kinds), plus a
`func`/`yield` container:

| Op | operands → result | attrs |
|----|-------------------|-------|
| `aiegraph.conv_bn_relu`, `aiegraph.conv_bn` | `%in` → `%out` (`tensor<Nxi8>`) | `H,W,Cin,Cout,K,stride` + quant `{in_scale,in_zp,out_scale,out_zp,bn_scale,bn_bias}` + optional weights `SymbolRefAttr` |
| `aiegraph.residual_add_relu` | `%main,%skip` → `%out` | `length` |
| `aiegraph.avgpool_fc` | `%in` → `%logits` | `spatial_h,spatial_w,channels,num_classes` + optional weights ref |

Dataflow is SSA: the result of one op feeds the next. The plan's *reused* scratch
names (`tmp1`, `feat1`, …) are resolved to explicit producer **indices** by
`model.plan_to_aiegraph_dicts` (last-writer-per-name in program order), so a
residual's `%skip` back-references the correct earlier launch (the downsample
`skip_ds` conv, or an earlier residual). The verifier enforces that a residual's
three operands share one element count.

### pybind entries (`aietriton_pybind.cpp`)

```python
ir = build_aiegraph_module(op_dicts, func_name)   # build + verify -> textual IR
launches = lower_aiegraph(ir)                      # walk -> per-launch descriptors
```

`build_aiegraph_module` takes a list of plain dicts (ints/floats/strings only;
dataflow via `main_index`/`skip_index`), constructs one `aiegraph.func`,
runs `mlir::verify`, and returns the printed module. `lower_aiegraph` parses +
verifies the text, walks the func in program order, and returns one descriptor
per op: `{op, func_name, index, weights, tensor_specs}`. The `tensor_specs` are
computed in C++ (`AiegraphLowerDriver`) and are **byte-identical** to
`_compiler._tensor_specs` — the geometry-derived conv/fc param sizes match
`model.make_conv_params`/`make_fc_params`. Kernel bodies stay in Python
(`kernels.kernel_body_for`); Python pairs each launch's specs with its body and
calls `run_aie_pipeline`, so the emitted code is identical to the direct path.

Set `via_aiegraph=False` to bypass the dialect (legacy direct `compile_launch`).
The dialect and its per-op lowering live in
`src/mlir/mlirfront/frontend/aiegraph/` (see the `unitest/` for round-trip +
lower + negative-verify coverage).

## Conv path: direct vs im2col (the pybind `dma_specs` extension)

The **default conv path is a direct convolution** whose loop nest lives in the
kernel body (matches `resnet18_triton.py`, easy to verify), so `dma_specs` is
left empty.

An **im2col path** is available via `_compiler.im2col_dma_spec(H, W, Cin, K, stride)`,
which builds the multi-dim shim DMA addressing the extended pybind `dma_specs`
argument accepts. This is the one C++ change the plan required.

### The pybind change (Step 2, `aietriton_pybind.cpp`)

`run_aie_pipeline` gained an optional per-tensor `dma_specs` argument, defaulted
to `{}` so the existing Triton path is unaffected:

```cpp
using DmaSpec = std::tuple<std::vector<std::pair<int,int>>,  // dims (stride,size)
                           int,                              // iter_step
                           int,                              // iter_wrap
                           std::vector<int64_t>,             // ddrShape
                           int>;                             // mode
```

For each tensor with a non-empty entry, the loop populates
`TensorParam::shimDma` (a `DmaAddressing`) from the matching `dma_specs` entry
and leaves it empty otherwise. This is the Python-visible surface of the generic
`DmaAddressing` on `TensorParam` described in
`doc/design/conv2d_im2col_design.md §11` — the same mechanism the C++ conv2d path
uses, now reachable from a Python frontend.

### im2col addressing (`im2col_dma_spec`)

Mirrors `im2colAddressing` (`conv2d_im2col_design.md §11/§13`):

```
OH = (H + 2P - K) / stride + 1            (P = K // 2)
dims (C==1)  = {(1,K), (W,K), (stride,OW)}
dims (C>1)   = {(1,K), (W,K), (W·K,C), (stride,OW)}
iter_step = W · stride
iter_wrap = OH
ddrShape  = [H, W, C]
mode      = 0
```

Returned as the `(dims, iter_step, iter_wrap, ddr_shape, mode)` tuple the
extended `run_aie_pipeline` `dma_specs` argument accepts.

## CPU reference (bit-exact oracle)

`cpu_reference(plan, input_data)` is a pure-numpy interpreter of the `LayerOp`
plan, maintaining a named-buffer dict. Its per-op math is a byte-for-byte port of
`resnet18_triton.py`'s CPU references:

* config reads via `int(np.uint8(...))`;
* conv accumulator `np.int16`, `bn_out = (s * np.int16(bn_scale)) >> 7` then
  `+= bn_bias`, clamp `[0,127]` (relu) / `[-128,127]` (no relu);
* residual `np.int16` add, clamp `[0,127]`;
* avgpool `int(s) // spatial_sz`, FC `np.int16` accumulate, clamp `[-128,127]`.

This is the oracle the AIE result is checked against; it needs only numpy.

## Public API (__init__.py)

```python
run_resnet(out_dir=..., input_data=None, emit_aie=False, onnx_path=None, mesh=(2,2)) -> RunResult
build_plan(onnx_path=None, strict=False) -> List[LayerOp]
cpu_reference(plan=None, input_data=None) -> (logits, buffers)
compile_plan(plan=None, out_root=..., mesh=(2,2)) -> List[(LayerOp, out_dir, ok)]
```

`RunResult` carries `plan`, `logits`, `predicted_class`, `used_tvm`, and the
`emitted` per-launch results.

## Verification (test_tvm_frontend.py)

Runs with or without TVM / the built extension (the parts that need them are
skipped, not failed):

* `test_cpu_reference_matches_triton` — the frontend's CPU reference produces the
  exact logits an **independent inline port** of `resnet18_triton.py`'s CPU
  reference does (cross-checks two implementations, not the frontend against
  itself);
* `test_plan_matches_canonical` — `build_plan` returns the canonical structure;
* `test_kernel_bodies_wellformed` — every op has a C body with the expected
  window ABI;
* `test_run_resnet_smoke` — `run_resnet(emit_aie=False)` returns a full plan and
  a valid predicted class;
* `test_emit_aie` — if `_aietriton_core` is built, emit one conv launch and
  assert the output file set appears (skipped otherwise).

```bash
python src/frontend/tvm/test_tvm_frontend.py
```

## Install

```bash
pip install -r src/frontend/tvm/requirements.txt
# numpy is always required; apache-tvm/onnx/torch enable the optional Relay path.
```

Build `_aietriton_core` (cmake with `LLVM_INSTALL_DIR` + MLIR) before emitting
AIE code.

## Files

| File | Role |
|------|------|
| `model.py` | scaled ResNet (torch) + ONNX export + canonical `layer_plan()` + param buffers |
| `relay_import.py` | ONNX → Relay import + optimisation passes; `tvm_available()` |
| `walk.py` | fused-graph `ExprVisitor` → `LayerOp` plan; validates vs canonical |
| `kernels.py` | raw-C bodies for the 4 kernels (int8/int16 Q7 math) |
| `_compiler.py` | tensor specs + `run_aie_pipeline` glue; bit-exact numpy CPU reference; im2col DMA helper |
| `__init__.py` | `run_resnet` entry + `RunResult` |
| `requirements.txt` | Python dependencies (numpy + optional tvm/onnx/torch) |
| `test_tvm_frontend.py` | verification (PASS/FAIL) |
| `README.md` | module overview |

## See also

- [`tvm_custom_model_recipe.md`](tvm_custom_model_recipe.md) — the "bring your own
  model" how-to: step-by-step recipe for taking a customized model through this
  frontend, plus the int8-config / fixed-op-set / placeholder-weight constraints.
- `src/frontend/tvm/README.md` — module usage.
- `src/mlir/mlirfront/frontend/aietriton/README.md` + `architecture.md` — the
  sibling Triton frontend and the `_aietriton_core` pybind bridge this frontend
  reuses.
- `doc/design/conv2d_im2col_design.md §11` — the generic `DmaAddressing` on
  `TensorParam` that `dma_specs` exposes to Python.
- `example/tileprogram/design/triton/resnet18_triton.py` — the hand-written
  template whose launch sequence, kernel bodies, and CPU references this frontend
  reproduces.
