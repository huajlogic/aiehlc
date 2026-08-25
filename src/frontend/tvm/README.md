# TVM frontend — scaled-down ResNet-18 on the AIE mesh

A third frontend into `TilingLinalgPipeline` (alongside the C++ `aiehlc` and the
`aietriton` Python path). It takes the scaled-down int8 ResNet-18, lowers it
through **TVM Relay**, walks the fused graph to recover a per-tile AIE launch
plan, and emits the same kernel launches the hand-written
`example/tileprogram/design/triton/resnet18_triton.py` produces.

## Pipeline

```
model.export_onnx()            scaled ResNet (torch.nn) -> ONNX
  -> relay_import.import_relay  ONNX -> Relay
                                (InferType, SimplifyInference[BN fold],
                                 FoldConstant, FuseOps, InferType)
  -> walk.build_plan            fused graph -> LayerOp launch plan
                                (validated against model.layer_plan())
  -> _compiler.compile_plan     each launch -> run_aie_pipeline (host/kernel/routing)
  -> _compiler.cpu_reference    bit-exact numpy oracle for verification
```

## Model (scaled-down, matches `resnet18_triton.py` / `resnet18.cc`)

8×8×1 input, channels 4→8→16→32, 4 classes, int8 + Q7 BatchNorm. Post-activation
ResNet: conv+BN+ReLU stem, four stages of two BasicBlocks each (first block of
stages 2–4 downsamples with a 1×1 stride-2 skip), global average pool, FC. This
is **not** the 224×224 / 1000-class ImageNet ResNet in `example/model/resnet18py`.

## Op mapping (walk.py)

| Relay pattern (after SimplifyInference)          | AIE launch          |
|--------------------------------------------------|---------------------|
| `nn.conv2d` + folded BN `multiply`/`add` + `nn.relu` | `conv_bn_relu`  |
| `nn.conv2d` + folded BN `multiply`/`add`             | `conv_bn`       |
| `add` + `nn.relu` (residual join)                    | `residual_add_relu` |
| `nn.global_avg_pool2d` + `nn.dense` (+ bias)         | `avgpool_fc`    |

The walk recovers the ordered conv geometry `(H,W,Cin,Cout,K,stride)` from the
graph and validates it against the canonical `model.layer_plan()`, which carries
the hand-verified buffer wiring and residual lengths.

## Kernel bodies (kernels.py)

Raw-C compute bodies matching the four `@aie_triton.jit` kernels. Config
(`{H,W,Cin,Cout,K,stride}` for conv, `{spatial_h,spatial_w,channels,nclass}` for
FC) travels in the param-buffer header so one body serves every launch of that
type. Two int16 details are load-bearing for bit-exactness with the CPU
reference: the conv accumulator is `int16` and wraps at each `+=`, and Q7 BN is
`(int16)(acc*bn_scale) >> 7` (the product is truncated to int16 **before** the
shift).

## Param buffers

- conv: `[config:6][weights: Cin·Cout·K·K][bn_scale: Cout][bn_bias: Cout]`
- fc:   `[config:4][weights: channels·nclass][bias: nclass]`

Deterministic patterns (weights ±1 / 1, `bn_scale=64`≈0.5 Q7, bias 0) — identical
to `resnet18_triton.py`, so the AIE result and the numpy CPU reference stay
bit-exact.

## Conv path

Default is a **direct convolution** whose loop nest lives in the kernel body
(matches `resnet18_triton.py`, easy to verify). An **im2col** path is available
via `_compiler.im2col_dma_spec(...)`, which builds the multi-dim shim DMA
addressing the extended pybind `dma_specs` argument accepts (see
`doc/design/conv2d_im2col_design.md`).

## Install

```bash
pip install -r src/frontend/tvm/requirements.txt
# or, minimally:
pip install apache-tvm    # optional; enables the Relay walk
# onnx + torch are needed for ONNX export; numpy is always required.
```

Without TVM the plan comes straight from `model.layer_plan()`; without the built
`_aietriton_core` pybind extension the CPU reference and plan recovery still
work, only `compile_plan`/`run_resnet(emit_aie=True)` need it. Build the
extension (cmake with `LLVM_INSTALL_DIR` + MLIR) before emitting AIE code.

## Usage

```python
from frontend.tvm import run_resnet, cpu_reference

res = run_resnet(emit_aie=False)          # plan + CPU logits, no build needed
print(res.predicted_class, list(res.logits), "tvm:", res.used_tvm)

res = run_resnet(out_dir="./worklocal/tvm", emit_aie=True)   # emit AIE code
for op, out_dir, ok in res.emitted:
    print(op.op, out_dir, "OK" if ok else "FAIL")
```

## Verify

```bash
python src/frontend/tvm/test_tvm_frontend.py
```

Cross-checks the frontend's CPU reference against an independent inline port of
`resnet18_triton.py`'s reference, checks the recovered plan matches the canonical
structure, checks the kernel bodies' window ABI, and — if `_aietriton_core` is
built — emits one conv launch and asserts the output file set appears.

## Files

| File | Role |
|------|------|
| `model.py` | scaled ResNet (torch) + ONNX export + canonical `layer_plan()` + param buffers |
| `relay_import.py` | ONNX → Relay import + optimisation passes; `tvm_available()` |
| `walk.py` | fused-graph `ExprVisitor` → `LayerOp` plan; validates vs canonical |
| `kernels.py` | raw-C bodies for the 4 kernels (int8/int16 Q7 math) |
| `_compiler.py` | tensor specs + `run_aie_pipeline` glue; bit-exact numpy CPU reference; im2col DMA helper |
| `__init__.py` | `run_resnet` entry + `RunResult` |
| `test_tvm_frontend.py` | verification (PASS/FAIL) |

## See also

- `doc/design/tvm_frontend.md` — frontend deep-dive (how this package works).
- `doc/design/tvm_custom_model_recipe.md` — "bring your own model" how-to:
  step-by-step recipe for taking a customized model through this frontend.
