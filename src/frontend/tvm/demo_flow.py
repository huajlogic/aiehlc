###############################################################################
# Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Demo: the whole TVM frontend flow, unrolled stage by stage.

    (real ResNet-18 reference)  ->  ONNX -> Relay walk -> LayerOp plan
                                    -> aiegraph IR -> per-launch AIE code

Stage 0 classifies a real dog image with the pretrained ImageNet ResNet-18
(``example/model/resnet18py``) so the demo prints a *meaningful* answer
("it's a dog"). The same image is then fed as int8 input into the AIE
pipeline's bit-exact oracle. Degrades gracefully: without torch/PIL/onnx or a
network the reference is skipped and the oracle falls back to
``model.make_input()``; stages 3-4 need the built ``_aietriton_core`` pybind.

Run:  python src/frontend/tvm/demo_flow.py
"""
import os
import sys

import numpy as np

# Allow "python src/frontend/tvm/demo_flow.py" from anywhere: put .../src on path.
_HERE = os.path.dirname(os.path.abspath(__file__))
_SRC = os.path.dirname(os.path.dirname(_HERE))          # .../src
_ROOT = os.path.dirname(_SRC)                           # repo root
_RESNET18PY = os.path.join(_ROOT, "example", "model", "resnet18py")
if _SRC not in sys.path:
    sys.path.insert(0, _SRC)
if _RESNET18PY not in sys.path:
    sys.path.insert(0, _RESNET18PY)                     # classify.py / resnet18.py

from frontend.tvm import model, kernels, _compiler, cpu_codegen
from frontend.tvm.walk import build_plan
from frontend.tvm.relay_import import tvm_available, onnx_available

OUT = "./worklocal/tvm_demo"
os.makedirs(OUT, exist_ok=True)


# ═══════════════════════════════════════════════════════════════════════════
#  Helpers
# ═══════════════════════════════════════════════════════════════════════════

def classify_dog_reference(topk=5):
    """Download + classify a dog image with the real pretrained ResNet-18.

    Returns the local image path on success, or ``None`` if torch/PIL/onnx or
    the network are unavailable (the caller then falls back gracefully).
    """
    try:
        import torch  # noqa: F401  (import test only; used via classify helpers)
        from classify import (resolve, preprocess, load_labels,
                              DEFAULT_IMAGE_URL, DEFAULT_WEIGHTS_URL,
                              DEFAULT_LABELS_URL)
        from resnet18 import resnet18
    except Exception as e:                              # noqa: BLE001
        print(f"[stage0] real ResNet-18 reference unavailable ({e}); "
              f"falling back to model.make_input()")
        return None

    try:
        image_path = resolve(None, DEFAULT_IMAGE_URL, "input_image")
        weights_path = resolve(None, DEFAULT_WEIGHTS_URL, "resnet18-v2-7.onnx")
        labels_path = resolve(None, DEFAULT_LABELS_URL, "imagenet_classes.txt")
    except Exception as e:                              # noqa: BLE001
        print(f"[stage0] download failed ({e}); falling back to "
              f"model.make_input()")
        return None

    labels = load_labels(labels_path)
    net = resnet18(onnx_path=weights_path)
    x = preprocess(image_path)
    with torch.no_grad():
        probs = torch.softmax(net(x), dim=1)[0]
    topv, topi = probs.topk(topk)
    print(f"[stage0] real ResNet-18 v2 (ImageNet-1000) on {image_path}")
    print(f"[stage0] top-{topk} predictions (this is the actual 'it's a dog' answer):")
    for rank, (p, i) in enumerate(zip(topv.tolist(), topi.tolist()), 1):
        print(f"           {rank}. {labels[i]:<45s} {p*100:6.2f}%  (class {i})")
    return image_path


def dog_to_scaled_input(path):
    """Open ``path``, grayscale -> INPUT_W x INPUT_H, quantize to length-64 int8.

    Produces the input the scaled AIE demo model expects (8x8x1). Returns
    ``None`` if PIL is unavailable so the caller can fall back.
    """
    try:
        from PIL import Image
    except Exception as e:                              # noqa: BLE001
        print(f"[stage2] PIL unavailable ({e}); using model.make_input()")
        return None
    img = Image.open(path).convert("L").resize((model.INPUT_W, model.INPUT_H))
    arr = np.asarray(img, dtype=np.float32)            # [0,255], HxW
    # Map [0,255] -> int8 [0,127] (Q7-ish); keep it simple and deterministic.
    q = np.clip(np.round(arr / 255.0 * 127.0), 0, 127).astype(np.int8)
    return q.reshape(-1)                               # length INPUT_H*INPUT_W*INPUT_C


# ═══════════════════════════════════════════════════════════════════════════
#  Stage 0: meaningful reference classification (real model, real image)
# ═══════════════════════════════════════════════════════════════════════════
image_path = classify_dog_reference()

# The same image, quantized for the scaled AIE model (or None -> make_input()).
demo_input = dog_to_scaled_input(image_path) if image_path else None

# ═══════════════════════════════════════════════════════════════════════════
#  Stage 1: ONNX -> Relay walk -> LayerOp plan (fallback if TVM/onnx absent)
# ═══════════════════════════════════════════════════════════════════════════
onnx_path = None
if tvm_available() and onnx_available():
    onnx_path = os.path.join(OUT, "resnet.onnx")
    model.export_onnx(onnx_path)                        # scaled ResNet -> ONNX
plan = build_plan(onnx_path)                            # -> List[LayerOp]
print("plan:", [op.op for op in plan])

# ═══════════════════════════════════════════════════════════════════════════
#  Stage 2: bit-exact numpy CPU oracle on the *real* image (no build needed)
# ═══════════════════════════════════════════════════════════════════════════
logits, _ = _compiler.cpu_reference(plan, demo_input)   # demo_input None -> make_input()
print("scaled-model predicted class:", int(np.argmax(logits)),
      "(caveat: placeholder weights -> all logits equal -> structurally class 0)")

# ═══════════════════════════════════════════════════════════════════════════
#  Stage 3: plan -> aiegraph dialect (build + verify in C++), print textual IR
# ═══════════════════════════════════════════════════════════════════════════
core = _compiler._core()                                # _aietriton_core pybind
dicts = model.plan_to_aiegraph_dicts(plan)              # LayerOp -> op dicts
ir = core.build_aiegraph_module(dicts, "resnet")        # -> verified textual IR
print(ir)

# ═══════════════════════════════════════════════════════════════════════════
#  Stage 4: aiegraph IR -> per-launch descriptors -> emit AIE host/kernel/routing
# ═══════════════════════════════════════════════════════════════════════════
for op, launch in zip(plan, core.lower_aiegraph(ir)):
    out_dir = os.path.join(OUT, f"{int(launch['index']):02d}_{op.op}")
    os.makedirs(out_dir, exist_ok=True)
    if cpu_codegen.is_aie_op(op.op):                    # conv2d family -> AIE
        specs = [(list(s), int(b), bool(i)) for (s, b, i) in launch["tensor_specs"]]
        body = kernels.kernel_body_for(op.op, launch["func_name"])
        ok = core.run_aie_pipeline(2, 2, specs, out_dir, body, launch["func_name"])
        kind = "AIE"
    else:                                               # everything else -> TVM CPU C
        ok = cpu_codegen.emit_cpu_launch(op, out_dir, launch["func_name"])
        kind = "CPU"
    print(op.op, kind, out_dir, "OK" if ok else "FAIL")
