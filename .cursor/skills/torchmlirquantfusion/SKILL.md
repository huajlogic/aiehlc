<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: torchmlirquantfusion
description: PT2E int8 through torch-mlir produces NO !torch.qint8 and NO linalg.conv_2d_nhwc_hwcf_q / linalg.quantized_matmul -- torch-fuse-quantized-ops and torch-match-quantized-custom-ops both look like silent no-ops. Also covers "failed to legalize operation 'torch.quantized_decomposed.dequantize_per_channel' that was explicitly marked illegal" on --output-type tosa, torchvision silently upgrading an installed torch (and dragging in CUDA), and torch.ao.quantization.quantize_pt2e being deprecated in favor of torchao.
---

# PT2E → torch-mlir: why the quantized ops never fuse

Applies to `src/frontend/pytorchmlir/`. Verified on torch 2.10.0+cu128,
torchvision 0.25.0, torchao 0.18.0, torch-mlir 20261001, python 3.10.

## 1. The symptom

You quantize with PT2E, import with `torch_mlir.fx.export_and_import`, run
`torch-fuse-quantized-ops`, and get **zero** `!torch.qint8` and **zero**
`linalg.*_q` ops. No error, no warning. torch-mlir's own lit tests
(`test/Dialect/Torch/fuse-quantized-ops.mlir`) clearly show the fused form, so it
looks like you called something wrong.

You did not. **The pass cannot fire on this input.**

## 2. Root cause

Three facts that only break when combined:

1. `quantized_decomposed.{quantize,dequantize}_per_tensor` and
   `dequantize_per_channel` are **registered ODS ops** in torch-mlir.
   Confirm:
   ```bash
   strings .../torch_mlir/_mlir_libs/torch-mlir-opt \
     | grep -o 'torch\.quantized_decomposed\.[a-z_]*' | sort -u
   ```
2. Because they are registered, `fx_importer` emits them **natively** as
   `torch.quantized_decomposed.*`. It only emits `torch.operator "..."` for
   *unregistered* ops (`fx_importer.py` ~line 2663).
3. `torch-match-quantized-custom-ops` — the pass that produces `!torch.qint8` —
   matches **only the `torch.operator` spelling**.

So the matcher sees nothing, `torch-fuse-quantized-ops` finds no `aten`-form QDQ
pair, and both passes are no-ops. It is an **upstream gap**, not a mistake in
your pipeline.

### Prove it in 30 seconds, without PyTorch

```bash
OPT=.../site-packages/torch_mlir/_mlir_libs/torch-mlir-opt

# native form -> unchanged
cat > /tmp/native.mlir <<'EOF'
func.func @f(%arg0: !torch.vtensor<[1,3,8,8],f32>) -> !torch.vtensor<[1,3,8,8],si8> {
  %s = torch.constant.float 0.02
  %z = torch.constant.int 6
  %lo = torch.constant.int -128
  %hi = torch.constant.int 127
  %d = torch.constant.int 1
  %0 = torch.quantized_decomposed.quantize_per_tensor %arg0, %s, %z, %lo, %hi, %d : !torch.vtensor<[1,3,8,8],f32>, !torch.float, !torch.int, !torch.int, !torch.int, !torch.int -> !torch.vtensor<[1,3,8,8],si8>
  return %0 : !torch.vtensor<[1,3,8,8],si8>
}
EOF
$OPT --torch-match-quantized-custom-ops /tmp/native.mlir | grep -c qint8   # -> 0

# operator form -> rewritten to qint8 + int_repr + clamp
sed 's/torch.quantized_decomposed.quantize_per_tensor \(.*\) :/torch.operator "torch.quantized_decomposed.quantize_per_tensor"(\1) :/' ... # see README
```

The `torch.operator` spelling returns `torch.aten.quantize_per_tensor ... ->
!torch.qint8`. Same pass, same build, different spelling.

## 3. What you actually get, and why it is fine

The backend lowers the native ops to explicit dequant arithmetic:

```mlir
%3 = linalg.conv_2d_nchw_fchw ins(%0, %1 : ...)
  %4 = arith.extsi %in : i8 to i64   // the int8 datum
  %5 = arith.subi  %4, %c6_i64       // zero-point
  %8 = arith.mulf  %7, %6            // scale
```

int8 weights, per-channel scales and zero-points are **all present**. On
ResNet-18: 21 `si8` weight literals (20 convs + fc), **0 f32** weight literals,
21 `dequantize_per_channel`, 20 `linalg.conv_2d_nchw_fchw`.

**Do not gate success on `qint8` or `*_q` counts** — they are 0 on every current
torch-mlir and a build that is working perfectly will look broken. Gate on int8
literals + `arith.extsi … i8` instead. See `torch_import.count_evidence`.

Keep running both passes anyway: they are harmless, and the flow improves for
free the day upstream teaches the matcher the registered form.

## 4. `--output-type tosa` → "failed to legalize"

```
error: failed to legalize operation
       'torch.quantized_decomposed.dequantize_per_channel'
       that was explicitly marked illegal
```

TOSA marks that op illegal and ships no pattern for it. **Fix: `--per-tensor`.**
With per-tensor weights it lowers cleanly to 20 `tosa.conv2d` with int8
throughout.

## 5. `pip install torchvision` silently upgrades torch

**torchvision pins torch exactly** (`torchvision==0.25.0` → `torch==2.10.0`). A
bare install next to an existing torch upgrades it *and* pulls a matching CUDA
stack — measured here as torch 2.10→2.14 plus ~5 GB of CUDA 13 wheels into a
shared venv.

Always dry-run first:

```bash
python -m pip install --dry-run torchvision | tail -3   # read "Would install"
```

Then pin the torchvision that matches the torch you have.
`setup_torchmlir.install()` resolves this from PyPI automatically.

## 6. PT2E moved to torchao

`torch.ao.quantization.quantize_pt2e` is deprecated (deletion planned ~2.10);
the live copy is `torchao.quantization.pt2e.quantize_pt2e`
([pytorch/ao#2259](https://github.com/pytorch/ao/issues/2259)). Resolve through
`torch_deps.pt2e_api()`, never import either path directly.

`XNNPACKQuantizer` is **not** a safe base class: in torchao 0.18 it is
`torchao/testing/pt2e/_xnnpack_quantizer.py` — private, inside `testing`, and it
warns `XNNPACKQuantizer is deprecated!`. Subclass the public `Quantizer` ABC.

## 7. Two more traps

- **`\bi8\b` never matches MLIR int8.** Tensors are spelled `tensor<1000x512xi8>`
  — `x` is a word character, so the boundary fails. Use `xi8>`.
- **ResNet-18 v1 ≠ v2.** `example/model/resnet18py/resnet18.py:resnet18()` builds
  **v2** from ONNX weights. torchvision's `resnet18(weights=IMAGENET1K_V1)` is
  **v1**. Quantizing the wrong one still "works" and nothing downstream notices.
  Reuse `classify.preprocess` (architecture-independent); not the model.
