###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""PT2E post-training static quantization: export -> prepare -> calibrate -> convert.

The model is **torchvision ResNet-18 v1** (``IMAGENET1K_V1``), per the task.

Do not substitute ``example/model/resnet18py/resnet18.py:resnet18()`` here, even
though it is right next door and returns a ready ``nn.Module``: that one builds
ResNet-18 **v2** and loads its weights out of an ONNX file. v1 is
post-activation (Conv->BN->ReLU), v2 is pre-activation (BN->ReLU->Conv) -- a
different network. Quantizing v2 while reporting "resnet18 from PyTorch" would
be wrong in a way nothing downstream would catch.

Preprocessing *is* reused from that directory (``classify.preprocess``), because
it is architecture-independent and reimplementing it is the easiest way to make
two frontends disagree for reasons unrelated to the compiler.
"""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Optional, Sequence

from .npu_quantizer import make_npu_quantizer
from .torch_deps import pt2e_api, torch_export_module

__all__ = [
    "DEFAULT_WEIGHTS",
    "INPUT_SHAPE",
    "QuantizeResult",
    "calibration_tensors",
    "load_resnet18",
    "quantize_resnet18",
]

#: ``example/model/resnet18py`` holds ``classify.py`` (preprocessing + labels)
#: and is not a package, so it goes on ``sys.path`` directly. ``parents[3]`` is
#: the repo root -- the same index ``tvmrelay/image_input.py`` uses, and it is
#: unchanged for a file in this sibling package.
_RESNET18PY = (Path(__file__).resolve().parents[3]
               / "example" / "model" / "resnet18py")

#: torchvision weights enum name. V1 is the classic ResNet-18 checkpoint and the
#: one the tvmrelay flow's ONNX model corresponds to.
DEFAULT_WEIGHTS = "IMAGENET1K_V1"

#: ImageNet inference shape, NCHW.
INPUT_SHAPE = (1, 3, 224, 224)


class QuantizeResult:
    """What stage 3 produced. Attribute bag rather than a dataclass so the
    GraphModule and the counts travel together without a torch import here."""

    def __init__(self, module, fp32_module, counts: dict, capture: str,
                 calib_count: int, quant_ops: dict):
        self.module = module              #: converted (int8) GraphModule
        self.fp32_module = fp32_module    #: the original, for top-5 comparison
        self.counts = counts              #: per-pattern annotation counts
        self.capture = capture            #: "export_for_training" | "export"
        self.calib_count = calib_count    #: tensors actually fed
        self.quant_ops = quant_ops        #: quantized_decomposed op -> count

    def describe(self) -> str:
        """``20 conv2d, 1 linear, 8 add + relu`` -- annotation summary."""
        if not self.counts:
            return "nothing annotated"
        return ", ".join(f"{v} {k}" for k, v in sorted(self.counts.items()))


def _classify_mod():
    """Import ``classify`` from ``example/model/resnet18py``. Raises if absent."""
    path = str(_RESNET18PY)
    if path not in sys.path:
        sys.path.insert(0, path)
    import classify  # noqa: F401

    return classify


# ═══════════════════════════════════════════════════════════════════════════
#  Model + calibration data
# ═══════════════════════════════════════════════════════════════════════════

def load_resnet18(weights: str = DEFAULT_WEIGHTS, verbose: bool = True):
    """``(model, detail)`` -- torchvision ResNet-18 **v1** in eval mode.

    Downloads to the torch hub cache on first use; subsequent runs are local.
    """
    import torchvision

    enum = torchvision.models.ResNet18_Weights[weights]
    model = torchvision.models.resnet18(weights=enum).eval()

    from torch.hub import get_dir

    cache = Path(get_dir()) / "checkpoints"
    files = sorted(cache.glob("resnet18-*.pth")) if cache.is_dir() else []
    where = f"{files[0]} ({files[0].stat().st_size:,} B)" if files else "torch hub cache"
    detail = f"resnet18 {weights} v1 | {where}"
    if verbose:
        print(f"  [model] {detail}")
    return model, detail


def calibration_tensors(images: Optional[Sequence] = None,
                        verbose: bool = True) -> list:
    """Preprocessed NCHW tensors to calibrate on.

    Reuses ``classify.preprocess`` -- the same function the reference classifier
    and the tvmrelay flow call -- so calibration sees exactly the tensors
    inference will. ``images=None`` calibrates on the single cached pytorch/hub
    dog photo, matching ``onnx_ptq._calibration_reader``.

    One image is a thin calibration set. The count is returned and printed so a
    one-image run is never mistaken for a real sweep.
    """
    classify = _classify_mod()
    sources = list(images) if images else [None]

    tensors = []
    for src in sources:
        path = classify.resolve(src, classify.DEFAULT_IMAGE_URL, "input_image")
        tensors.append(classify.preprocess(path))
        if verbose:
            print(f"  [calib] {path}")
    return tensors


# ═══════════════════════════════════════════════════════════════════════════
#  The PT2E flow
# ═══════════════════════════════════════════════════════════════════════════

def quantize_resnet18(model=None, images: Optional[Sequence] = None, *,
                      per_channel: bool = True, observer: str = "histogram",
                      verbose: bool = True) -> QuantizeResult:
    """Quantize ResNet-18 to int8 with PT2E. Returns a :class:`QuantizeResult`.

    Order is fixed by PT2E: capture with ``export_for_training`` (which keeps
    BatchNorm visible so conv+bn fusion can happen), ``prepare_pt2e`` to insert
    observers, run the calibration tensors to populate them, then
    ``convert_pt2e`` to replace observers with real quantize/dequantize ops.
    """
    import torch

    api = pt2e_api()
    if model is None:
        model, _ = load_resnet18(verbose=verbose)

    tensors = calibration_tensors(images, verbose=verbose)
    example = (tensors[0],)

    captured, how = torch_export_module(model, example)

    quantizer = make_npu_quantizer(per_channel=per_channel, observer=observer)
    prepared = api.prepare_pt2e(captured, quantizer)

    # Calibrate. No grad: observers only need the forward activations.
    with torch.no_grad():
        for t in tensors:
            prepared(t)

    converted = api.convert_pt2e(prepared)

    # move_exported_model_to_eval is the supported way to switch an exported
    # graph to eval; plain .eval() does not change BN/dropout behavior on a
    # GraphModule. The model here was exported from .eval() already, so failing
    # is survivable -- but it is NOT nothing: if it fails because the signature
    # moved (the torch.ao -> torchao migration is live), BN could keep
    # training-mode numerics and the only symptom would be unexplained accuracy
    # drift. So report it instead of swallowing it.
    if api.move_to_eval is not None:
        try:
            api.move_to_eval(converted)
        except Exception as exc:
            print(f"  [warn] move_exported_model_to_eval failed "
                  f"({type(exc).__name__}: {exc}); the graph was exported from "
                  f".eval() so this is usually benign, but check accuracy",
                  file=sys.stderr)

    quant_ops: dict = {}
    for node in converted.graph.nodes:
        if node.op == "call_function":
            target = str(node.target)
            if "quantized_decomposed" in target:
                quant_ops[target] = quant_ops.get(target, 0) + 1

    return QuantizeResult(
        module=converted,
        fp32_module=model,
        counts=dict(quantizer.counts),
        capture=how,
        calib_count=len(tensors),
        quant_ops=quant_ops,
    )
