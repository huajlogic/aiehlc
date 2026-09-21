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
  └─ relay_import.import_relay  ONNX ─► Relay (primitive, NO FuseOps)
                               (InferType, SimplifyInference[BN fold],
                                FoldConstant, InferType)
       └─ walk.build_plan       primitive graph ─► LayerOp launch plan
                               (recover_primitives → fuse_primitives,
                                validated against model.layer_plan())
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
| **tvm** (Python) | scaled ResNet-18 via ONNX → Relay | primitive walk + our-fusion → per-launch tensor specs + C body → `_aietriton_core.run_aie_pipeline` | Multi-launch CNN forward pass (~29 launches) |

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

**Placeholder weights — what the scaled model can and cannot show.** Its
parameters are deterministic Q7 patterns, not trained values. That is enough to
verify *structure and plumbing* bit-exactly (every buffer, offset, and launch
matches the oracle), but the logits are all-zero and every class ties, so the
prediction is structural rather than learned. Any "it classified the dog" claim
must come from the quantization track below, not from this model.

## Real int8 classification (`quant/`)

`src/frontend/tvm/quant/` is the complement to the scaled model: real
post-training quantization of the **pretrained ImageNet ResNet-18**
(`example/model/resnet18py`) down to int8 C that actually classifies — the
sample dog comes out *Samoyed 83.92%* against the float reference's 90.01%.

| File | Role |
|------|------|
| `resnet_np.py` | dependency-free numpy float forward pass; verified vs torch (max err 6.7e-06) |
| `ptq.py` | activation calibration + per-channel weight quantization |
| `qresnet.py` | the quantized network (integer fixed-point requantization) |
| `emit_c.py` | emits `resnet_int8.c` + the int8 weight blob |
| `build_demo.py` | ONNX → quantize → C → binary; `--run` also classifies |

Two things that are easy to get wrong and are therefore handled here rather
than left to the caller:

* **Preprocessing is not a free choice.** The image must arrive exactly as the
  network was calibrated for (resize-256 / center-crop-224 / ImageNet mean-std),
  quantized with the *calibrated input scale*. Raw `[0,255]` pixels, or a
  different scale, silently produce garbage with perfectly good weights. So
  `build_demo.py` emits `input_f32.bin` and bakes the calibrated scale/zp into
  `main.c`, which quantizes on target — keeping the quantizer inside the program
  being verified.
* **`build_aarch64` deliberately bypasses `script/hostcompile.sh`.** That script
  links a generated AIE host (XAie driver, `routing()` extern, embedded kernel
  ELF); this program uses none of it — no device, no DMA, just int8 arithmetic
  on the ARM core. It links against the same BSP and linker script directly.

`main.c` prints `device_teardown done` because `apppaltest.py` polls the console
for that marker; without it a finished run looks like a hang until the 300 s
timeout even though the answer already printed.

This track does **not** go through the aiegraph/AIE pipeline — it is the
numerical reference for what int8 ResNet-18 *should* compute, and uses plain
`int` config fields, so it is unaffected by the `CONFIG_FIELD_BYTES` layout.

## ONNX → Relay import (relay_import.py)

`import_relay(onnx_path, input_name, input_shape)` runs `relay.frontend.from_onnx`
then a `Sequential` pass pipeline:

```
InferType → SimplifyInference → FoldConstant → InferType
```

`SimplifyInference` folds BatchNorm into `multiply` + `add` (scale/shift). We
**deliberately drop `FuseOps`** so the imported graph is left in *primitive*
form (top-level `nn.conv2d`, `multiply`, `add`, `nn.relu`, …) — fusion is done by
our own pass in `walk.py` (below), so the frontend tolerates any TVM grouping.
`tvm_available()` / `onnx_available()` gate the optional path. See the design doc
`docs/plans/2026-09-09-aiegraph-primitive-fusion-offload-design.md`.

## Primitive walk + our-fusion (walk.py)

Because the import no longer fuses, `walk.py` runs two passes:

1. **`recover_primitives(onnx_path)`** — walks the flat graph with a
   `relay.ExprVisitor` and emits a *tagged* primitive stream in dataflow order.
   The key discriminator: a BN `multiply`/`add` has exactly one `relay.Constant`
   operand, while a residual `add(tensorA, tensorB)` has none. Tags:
   `conv2d(H,W,Cin,Cout,K,stride)`, `bn_mul`, `bn_add`, `res_add`, `relu`, `gap`,
   `dense(channels,nclass)`, and `bias_add` (a const `add` seen after a `dense`).

2. **`fuse_primitives(prims)`** — OUR greedy fusion pass, grouping the stream
   into the four fused `LayerOp` kinds:

| Primitive window                                    | AIE launch          |
|-----------------------------------------------------|---------------------|
| `conv2d` [`bn_mul`] [`bn_add`] `relu`               | `conv_bn_relu`      |
| `conv2d` [`bn_mul`] [`bn_add`]                      | `conv_bn`           |
| `res_add` `relu`                                    | `residual_add_relu` |
| `gap` `dense` [`bias_add`]                          | `avgpool_fc`        |

Conv geometry `(H, W, Cin, Cout, K, stride)` is recovered from the graph:
`(Cout, Cin, K, K)` from the weight's `checked_type.shape` (OIHW), `(H, W)` from
the input's `checked_type.shape` (NCHW), `stride` from `attrs.strides[0]`, and
carried onto the fused `LayerOp`.

**Why the walk validates rather than rebuilds.** Recovering the *buffer wiring*
(which scratch buffer feeds which launch) and the residual element counts from
the graph is fragile, and `model.layer_plan()` already encodes that wiring in a
hand-verified form. So `build_plan(onnx_path, strict)` runs
`recover_primitives` → `fuse_primitives` to get the *structural* op sequence, then
**validates** it against the canonical plan (`validate_fused_against_canonical`:
ordered conv geometry, residual count, `avgpool_fc` presence); on a match it
returns the canonical plan (buffer wiring intact). If TVM is unavailable or the
structure diverges it falls back to the canonical plan (or raises when
`strict=True`). This keeps the frontend a genuine TVM-driven path while staying
bit-exact with the verified reference.

Offload is unchanged: `_compiler.compile_plan_via_aiegraph` dispatches each op by
`cpu_codegen.is_aie_op` (conv family → AIE, rest → CPU C) and now prints a
per-launch `[tvm-offload] launch NN <op> -> AIE|CPU` transparency line.

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

- conv: `[config={H,W,Cin,Cout,K,stride}][weights:Cin·Cout·K·K][bn_scale:Cout][bn_bias:Cout]`
- fc:   `[config={spatial_h,spatial_w,channels,num_classes}][weights:channels·nclass][bias:nclass]`

**Config fields are 2-byte little-endian uint16, not single bytes.** One byte
caps every dimension at 255, which real ResNet-18 exceeds (512 channels, 1000
classes). So `CONFIG_SZ = 6·2 = 12` and `FC_CONFIG_SZ = 4·2 = 8`
(`model.CONFIG_FIELD_BYTES`); the buffer itself stays `int8`, so `tensor_specs`,
DMA, and windows are unaffected. `model.pack_config` range-checks each field
rather than truncating — a wrapped dimension builds and runs but computes
nonsense.

The width is duplicated across every reader, and one left behind does **not**
fail to build: it shifts every weight offset and silently produces garbage.
Keep these in lock-step:

| Reader | Where |
|--------|-------|
| writer + decoder | `model.pack_config` / `unpack_config` |
| AIE kernels | `kernels._KERNEL_PRELUDE`'s `CFG16` (sizes formatted from `model.py`) |
| numpy oracle | `_compiler._cpu_conv` |
| emitted plain-C | `cpu_codegen` (its own `CFG16`) |
| launch sizing | `AiegraphLowerDriver.cpp` `kConfigFieldBytes` |
| test oracle | `test_tvm_frontend._cfg16` — deliberately independent |

`CFG16` casts through `uint8_t` before combining: `params` is `int8_t*`, so a
byte ≥ 0x80 would sign-extend and corrupt the field.

**Channel bound.** `avgpool_fc`'s AIE kernel pools into a fixed on-stack
`pooled[MAX_POOL_CH]`. Now that >255 channels are representable, that array is
the binding limit, so `model.make_fc_params` rejects `channels >
MAX_POOL_CHANNELS` (512) up front instead of overflowing the stack on target.

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

## CPU fallback for non-conv ops (TVM `target="c"`) — `cpu_codegen.py`

The aiegraph **runtime** pipeline (`run_aie_pipeline` → real AIE) only implements
the conv2d family. The remaining plan ops are emitted instead as **bit-exact CPU
C generated by TVM** (`target="c"`), not sent to the AIE backend. Non-conv ops
still live in the aiegraph IR (build + verify + lower all keep working — the
dialect models them fine); only the *emit* path forks.

### Op split (single source of truth)

`cpu_codegen.AIE_OPS = {"conv_bn", "conv_bn_relu"}` go to AIE;
`cpu_codegen.CPU_OPS = {"residual_add_relu", "avgpool_fc"}` go to TVM CPU C.
`is_aie_op(op_name)` is the dispatch predicate used at every emit site.

### Dispatch point

Both emit paths branch on `is_aie_op`:

| Site | AIE op | non-AIE op |
|------|--------|------------|
| `_compiler.compile_launch` (legacy direct) | `run_aie_pipeline` | `cpu_codegen.emit_cpu_launch` |
| `_compiler.compile_plan_via_aiegraph` loop | `run_aie_pipeline` | `cpu_codegen.emit_cpu_launch` |
| `demo_flow.py` Stage 4 loop | `run_aie_pipeline` | `cpu_codegen.emit_cpu_launch` |

Output layout is symmetric: each launch still gets `out_root/<idx>_<op>/`. Conv
dirs contain `host.cc`/`kernel.cc`/`routing.cc`/…; CPU dirs contain a single
`<func_name>.c`.

### Disabling AIE offload entirely (all-CPU build)

`is_aie_op` answers *"could this op run on AIE"*, **not** *"does it, in this
build"*. The second question is `orchestrator._to_aie(op, enable_aiehlc_offload)`
— `is_aie_op(op) and enable_aiehlc_offload` — and every backend-selecting site
in the A2 orchestrator must use it. `orchestrate_plan(..., enable_aiehlc_offload
=False)` force-offloads the conv2d family to its bit-exact plain-C
(`plain_c_source(force=True)`), so **no `kernel_<name>.cc` is emitted and
`hostcompile.sh` never invokes xchesscc**. `demo_flow.py`'s single
`enable_aiehlc_offload` flag drives both Stage 4 and Stage 5.

Three artifacts the AIE path *produces* have to be synthesized when it is off:

| Artifact | Normally from | All-CPU replacement |
|----------|---------------|---------------------|
| `host.cc` | created by the first `orchestrate_conv_layer` | `_emit_cpu_only_host()` (stub; hostcompile.sh compiles only this TU) |
| `routing.cc` | per-conv routing emit | `_emit_cpu_only_routing()` — a no-op `routing()`, since `aie_runtime.o` references it unconditionally |
| a kernel to compile | `kernel_*.cc` | none; `script/hostcompile.sh` gained a host-only mode |

The all-CPU `main` also skips `__Runtime_explicit_init` / mesh partition /
teardown — the ELF must not require working AIE hardware to produce its logits.

### Param buffers are filled, not zeroed

`main.cc` emits `fill_conv_params` / `fill_fc_params` (C transcriptions of
`model.make_conv_params` / `fc_params_no_header`) for **both** backends. Zeroing
is not a benign placeholder: the conv config (`H,W,Cin,Cout,K,stride`) is the
leading `CONFIG_SZ` bytes of the params buffer, so an all-zero buffer means
`H=W=0` and the
conv writes nothing. Verified by replaying `_compiler.cpu_reference` per launch
and comparing every intermediate DDR buffer against the natively-compiled
emitted C — not just the logits, which are all-zero under placeholder weights
and so match vacuously.

### Bit-exact TE mapping (transcription of the numpy Q7 oracle)

Each CPU op is a TVM TE compute mirroring the `_compiler.py` oracle
(`_cpu_add_relu` / `_cpu_avgpool_fc`). int8 inputs are widened with
`.astype("int16")` so every `te.sum` reduction accumulates in int16 and the
emitted C `int16_t` wraps exactly like the numpy `int16` oracle; the pool divide
uses `te.truncdiv` (post-ReLU features are `≥ 0`, so trunc == floor, matching
`int(s)//spatial_sz`); saturation is `te.max(te.min(x, hi), lo)`.

* `residual_add_relu` → `_residual_te(n)`:
  `out[i] = int8(clamp(int16(main[i]) + int16(skip[i]), 0, 127))`.
* `avgpool_fc` → `_avgpool_fc_te(sh, sw, C, NC)`, split into separate reduction
  stages (TVM requires reductions at the top level of a compute):
  `psum[c] = Σ_r int16(feat[c·ssz+r])`; `pooled[c] = int8(truncdiv(psum[c], ssz))`;
  `logits[j] = int8(clamp(Σ_k int16(pooled[k])·int16(wts[k·NC+j]) + bias[j], -128, 127))`.
  Weights/bias are headerless (`wts = fc_params[:C·NC]`, `bias = fc_params[C·NC:]`).

Because the same TE drives both `target="c"` (emitted artifact) and
`target="llvm"` (run by the tests against the numpy oracle), the two are
numerically identical.

### ABI note (installed TVM specifics)

The installed TVM (0.26) is an FFI/relax build (no `relay`, no `te.create_schedule`).
`_make_module` uses `te.create_prim_func` + `tvm.build`, sets the PrimFunc
`global_symbol` to `func_name` so the requested name is the public symbol, and
reads source via `.inspect_source()` (falling back to `.get_source()` on classic
TVM). That codegen emits a **packed** function under the TVM FFI ABI
(entry `__tvm_ffi_<func_name>`, `DLTensor`/`TVMFFIAny` args, needs the `tvm/ffi`
headers to link) rather than a standalone `void <func_name>(int8_t*, …)`.
Wrapping the packed func into a plain host entry and linking the CPU ops into one
end-to-end AIE+CPU executable is **out of scope** (no multi-layer host
orchestrator exists yet); each launch is emitted as a standalone C artifact,
mirroring the standalone `host.cc`/`kernel.cc` the AIE path emits per launch.

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

* config reads via `model.unpack_config` (2-byte LE uint16 fields);
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
  assert the output file set appears (skipped otherwise);
* `test_cpu_codegen_bit_exact` — if TVM is present, build the residual and
  avgpool TE on `target="llvm"`, run random int8 inputs, and assert elementwise
  equality with `_compiler._cpu_add_relu` / `_cpu_avgpool_fc`; also asserts the
  `func_name` entry appears in `cpu_c_source(...)`;
* `test_cpu_codegen_rejects_aie_op` — `cpu_codegen.op_tensors(conv)` raises
  `ValueError` (conv is an AIE op, not a CPU-codegen op);
* `test_dispatch_routes_non_conv_to_cpu` — if the extension is built, run
  `compile_plan_via_aiegraph` on the canonical plan and assert conv dirs contain
  `host.cc` (no `.c`) while residual/avgpool dirs contain `<func_name>.c` (no
  `host.cc`).

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
| `walk.py` | primitive `ExprVisitor` (`recover_primitives`) + our-fusion (`fuse_primitives`) → `LayerOp` plan; validates vs canonical |
| `kernels.py` | raw-C bodies for the 4 kernels (int8/int16 Q7 math) |
| `_compiler.py` | tensor specs + `run_aie_pipeline` glue; bit-exact numpy CPU reference; im2col DMA helper; AIE-vs-CPU emit dispatch |
| `cpu_codegen.py` | TVM `target="c"` CPU fallback for non-conv ops (bit-exact TE transcription of the Q7 oracle) |
| `orchestrator.py` | A2 multi-layer driver: DDR buffer chaining, `__aie_launch` dispatcher, all-CPU stubs, `main.cc`, ELF + x86 builds |
| `demo_flow.py` | the whole flow unrolled stage by stage (reference classify → plan → aiegraph IR → emit → ELF → x86 run) |
| `quant/` | real int8 PTQ of pretrained ImageNet ResNet-18 → C that actually classifies (see above) |
| `__init__.py` | `run_resnet` entry + `RunResult` |
| `requirements.txt` | Python dependencies (numpy + optional tvm/onnx/torch) |
| `test_tvm_frontend.py` | verification (PASS/FAIL) |
| `quant/test_quant.py` | quantization verification (calibration, fixed-point, emitted-C classification) |
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
