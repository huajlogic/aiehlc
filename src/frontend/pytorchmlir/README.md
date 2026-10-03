# `pytorchmlir` — PyTorch → PT2E int8 → torch-mlir

Ingests a PyTorch model directly and emits MLIR:

```
torchvision resnet18 (v1)
  → torch.export            (ExportedProgram / FX graph)
  → PT2E quantization       (NPUQuantizer + calibration)   → int8 Q/DQ graph
  → torch_mlir.fx           → torch dialect
  → backend pipeline        → linalg-on-tensors  (or TOSA)
```

**Scope ends at MLIR.** No aiegraph, no AIE backend — wiring the output into the
AIE pipeline is a separate change.

## Why a second frontend

`src/frontend/tvmrelay` reaches int8 the other way — ONNX → onnxruntime PTQ →
Relay — and needs a TVM 0.16 **source build** plus a tail of version shims
(`onnx.mapping`, opset-13-before-BN-fold). This path needs torch, torchvision and
a torch-mlir wheel. Nothing is compiled.

The two are **independent**: unlike `tvmrelay` vs `tvm` (one TVM per
environment), these can coexist.

## Running it

```bash
PYTHONPATH=src python src/frontend/pytorchmlir/deploy_torch.py
PYTHONPATH=src python src/frontend/pytorchmlir/deploy_torch.py --image cat.jpg
PYTHONPATH=src python src/frontend/pytorchmlir/deploy_torch.py --output-type tosa
PYTHONPATH=src python src/frontend/pytorchmlir/deploy_torch.py --observer minmax
```

Five stages, output in `./worklocal/pytorchmlir_deploy`:

```
[1/5] env    : torch 2.10.0+cu128 | torchvision 0.25.0+cu128 | torch-mlir 20261001 | pt2e via torchao
[2/5] model  : resnet18 IMAGENET1K_V1 v1 | ~/.cache/torch/hub/checkpoints/resnet18-f37072fd.pth (46,830,571 B)
[3/5] int8   : 1 adaptive_avg_pool2d, 8 add + relu, 11 conv2d, 9 conv2d + relu, 1 linear
[3/5]          per-channel symmetric w / affine act | histogram observer | calib 1 image(s)
[3/5]          95 quantized_decomposed ops after convert
[4/5] mlir   : resnet18_02_torch.mlir | 33 quantize_per_tensor, 21 int8 weight literals
[4/5]          fuse: no-op (upstream matcher wants the unregistered op form)
[5/5] linalg : 20 conv_2d_nchw_fchw, 54 int8 extends, 0 fused *_q (upstream gap)
```

Exit codes: `0` ok, `1` the flow ran but produced no int8 evidence, `2` bad CLI
arguments.

Flags: `--out-dir --image --calib-images --observer {histogram,minmax}
--per-tensor --output-type {linalg,tosa,torch} --no-fuse --no-accuracy --quiet`.

## Provisioning

```bash
python src/frontend/pytorchmlir/setup_torchmlir.py --verify-only   # report, change nothing
python src/frontend/pytorchmlir/setup_torchmlir.py --dry-run       # print commands
python src/frontend/pytorchmlir/setup_torchmlir.py --yes
```

Wheels only — minutes, not `setup_tvm016`'s 10–25 minute source build.
`import frontend.pytorchmlir` self-provisions; opt out with
`AIEHLC_TORCH_AUTO_INSTALL=0`.

`--verify-only` is **functional**: it builds a conv+relu model, runs PT2E
convert, imports through torch-mlir and checks real IR comes out. A version
string proves nothing about whether the pair works together.

Installing outside a virtualenv is refused without `--allow-system`.

### torchvision pins torch exactly — this is the trap

`torchvision==0.25.0` requires `torch==2.10.0`. So a bare `pip install
torchvision` next to an existing torch **silently upgrades torch** and drags in a
matching CUDA stack — on this host a dry run showed torch 2.10→2.14 plus ~5 GB of
CUDA 13 packages, into a venv other projects share.

`install()` therefore detects the installed torch and resolves the torchvision
release that pins *it* (queried from PyPI, not hardcoded — the mapping grows
every release). `torch-mlir` is pinned because only the newest release ships a
cp310 wheel; **torch is deliberately unpinned** (floor 2.6), since torch-mlir
declares no torch dependency and a pin here would be guesswork.

## Verified state

```
torch 2.10.0+cu128 | torchvision 0.25.0+cu128 | torchao 0.18.0 | torch-mlir 20261001
python 3.10 | pt2e via torchao
```

ResNet-18, calibrated on the pytorch/hub dog photo:

| | |
|---|---|
| annotated | 20 conv (9 fused with relu), 1 linear, 8 residual add+relu, 1 avgpool |
| after convert | 95 `quantized_decomposed` ops |
| weight literals | **21 si8, 0 f32** — all 20 convs *and* the `[1000,512]` fc |
| per-channel | 21 `dequantize_per_channel`, `[64]`-wide scales + zero-points |
| linalg | 20 `linalg.conv_2d_nchw_fchw`, 54 `arith.extsi … i8` |

fp32 vs int8 top-5 — **top-1 match, order identical**:

```
1. fp32  258 Samoyed          16.2734  | int8  258 Samoyed          16.2409
2. fp32  279 Arctic fox       13.3126  | int8  279 Arctic fox       13.6097
3. fp32  270 white wolf       13.2787  | int8  270 white wolf       13.0653
```

Same photo and same top-1 the tvmrelay flow reports, from a completely different
quantizer.

## The fusion gap, and why `0 fused *_q` is not a failure

torch-mlir's lit tests
(`test/Dialect/Torch/{match-quantized-customs-ops,fuse-quantized-ops}.mlir`)
describe a chain that turns PT2E output into `!torch.qint8` and then into
`linalg.conv_2d_nhwc_hwcf_q`. **That chain does not run**, and the symptom is
silence rather than an error:

- `quantized_decomposed.{quantize,dequantize}_per_tensor` and
  `dequantize_per_channel` are **registered ODS ops** in this torch-mlir, so
  `fx_importer` emits them *natively* — stage 01 contains **zero**
  `torch.operator` customs.
- `torch-match-quantized-custom-ops` matches **only** the *unregistered*
  `torch.operator "torch.quantized_decomposed.*"` spelling.
- So the matcher never fires, `torch-fuse-quantized-ops` finds no `aten`-form QDQ
  pair, and no `!torch.qint8` is created.

Confirmed both directions with `torch-mlir-opt` on hand-written IR — native form
passes through untouched, `torch.operator` form is rewritten exactly as the lit
test says. This is an **upstream gap**, not a defect here.

**The output is still genuinely int8.** The backend lowers the native ops to
explicit dequant arithmetic around a plain convolution:

```mlir
%3 = linalg.conv_2d_nchw_fchw ins(%0, %1 : ...)
  %4 = arith.extsi %in : i8 to i64      // int8 datum
  %5 = arith.subi  %4, %c6_i64          // zero-point
  %8 = arith.mulf  %7, %6               // scale
```

Both passes are still run: harmless today, and the flow improves for free the day
upstream teaches the matcher the registered form. The counts are reported either
way (`--no-fuse` skips them), so that day is visible rather than assumed.

If you need fused `linalg.*_q` today, the workaround is to rewrite the native ops
into the `torch.operator` form before running the matcher — verified to work on
hand-written IR, deliberately not done here because it is a textual workaround
for an upstream bug.

### TOSA needs `--per-tensor`

`--output-type tosa` fails with per-channel weights:

```
error: failed to legalize operation
       'torch.quantized_decomposed.dequantize_per_channel'
       that was explicitly marked illegal
```

The TOSA conversion marks that op illegal and supplies no pattern for it. The
flow catches this and says so, keeping the stage-01/02 artifacts rather than
dying in a pass-pipeline traceback. With `--per-tensor` it lowers cleanly:

```
[5/5] tosa   : 20 tosa.conv2d, 285 i8 references
```

So TOSA is usable, at per-tensor weight granularity.

## Quantization scheme

Matches `tvmrelay/onnx_ptq.py`, so the two frontends quantize the same network
the same way:

| | |
|---|---|
| weights | symmetric int8, **per-channel** (`ch_axis=0`), zp = 0, range ±127 |
| activations | **asymmetric** int8 (affine, non-zero zero-point), range −128…127 |
| bias | fp32 — the integer conv accumulates in int32 |

`NPUQuantizer` subclasses the public `Quantizer` ABC rather than building on
`XNNPACKQuantizer`, which in torchao 0.18 lives at
`torchao/testing/pt2e/_xnnpack_quantizer.py` — a private module in a `testing`
package that warns `XNNPACKQuantizer is deprecated!` on construction — and whose
config encodes XNNPACK's kernel constraints, not a spatial NPU's.

**Annotation order is load-bearing.** Patterns are tried longest-first
(`conv+relu` before bare `conv`) and every annotated node is recorded, so a
shorter pattern cannot re-claim it. Without that, `conv` overwrites the fused
`conv+relu` annotation and the ReLU lands outside the quantized region.

`adaptive_avg_pool2d` uses a `SharedQuantizationSpec` — average pooling is
scale-preserving, so re-observing its output would invent a second scale for the
same data. The residual `add` shares one spec across both addends, or the skip
path drifts from the residual path.

## Two reuse decisions

**The model comes from torchvision, not from `example/model/resnet18py`.** That
directory's `resnet18()` is right next door and returns a ready `nn.Module`, but
it builds ResNet-18 **v2** from ONNX weights. v1 is post-activation
(Conv→BN→ReLU), v2 is pre-activation — a different network. Quantizing v2 while
reporting "resnet18 from PyTorch" would be wrong in a way nothing downstream
catches.

**Preprocessing is reused from exactly that file.** `classify.preprocess` is
architecture-independent (PIL → numpy → NCHW torch tensor), and reimplementing it
is the easiest way to make two frontends disagree for reasons unrelated to the
compiler. `image_input.classify_reference` is *not* used — it is
onnxruntime-on-v2.

## The PT2E API moved

`torch.ao.quantization.quantize_pt2e` is deprecated and slated for deletion
([pytorch/ao#2259]); the live copy is `torchao.quantization.pt2e.quantize_pt2e`.
Every symbol is resolved in **one** place — `torch_deps.pt2e_api()` — newest
tree first, and stage 1 prints which one answered, so a fallback onto the
deprecated tree is visible rather than inferred. When the migration finishes,
that is the only file that changes.

## Tests

```bash
PYTHONPATH=src python -m pytest src/frontend/pytorchmlir/unitest/ -v
```

26 tests, **no torch required** — verified by running them with `torch`,
`torchvision`, `torchao` and `torch_mlir` blocked at the import hook. They cover
the resolver's precedence and fallback, the IR evidence counters (including a
fixture that mimics a silent fp32 regression), the probe's sentinel parsing and
crash handling, the manifest's restore command, and CLI exit codes.

The end-to-end test is opt-in, since it downloads weights and takes minutes:

```bash
AIEHLC_PYTORCHMLIR_E2E=1 PYTHONPATH=src python -m pytest \
    src/frontend/pytorchmlir/unitest/ -v -k e2e
```

## Files

| file | purpose |
|---|---|
| `torch_deps.py` | PT2E symbol resolution, dependency status, auto-provision hook |
| `setup_torchmlir.py` | provisioner — out-of-process probe, functional verify, manifest |
| `npu_quantizer.py` | `NPUQuantizer` — the annotation patterns and the int8 scheme |
| `quantize_pt2e_flow.py` | export → prepare → calibrate → convert |
| `torch_import.py` | fx import, fusion attempt, IR dumps, evidence counting |
| `deploy_torch.py` | 5-stage CLI orchestrator |
| `unitest/test_pytorchmlir.py` | torch-free tests + opt-in E2E |

[pytorch/ao#2259]: https://github.com/pytorch/ao/issues/2259
