###############################################################################
# Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Demo: the whole TVM frontend flow, unrolled stage by stage.

    (real ResNet-18 reference)  ->  ONNX -> Relay walk -> LayerOp plan
                                    -> aiegraph IR -> per-launch AIE code
                                    -> A2 orchestration -> single main.elf

Stage 0 classifies a real dog image with the pretrained ImageNet ResNet-18
(``example/model/resnet18py``) so the demo prints a *meaningful* answer
("it's a dog"). The same image is then fed as int8 input into the AIE
pipeline's bit-exact oracle. Stage 5 orchestrates every launch into ONE
program-order ``main.elf`` (A2 multi-kernel path, ``orchestrator.py``) and links
it via ``script/hostcompile.sh``. Degrades gracefully: without torch/PIL/onnx or
a network the reference is skipped and the oracle falls back to
``model.make_input()``; stages 3-5 need the built ``_aietriton_core`` pybind, and
stage 5's ELF link additionally needs an aarch64 cross g++ + xchesscc/Vitis
(sources are still emitted when the toolchain is absent).

Run:  python src/frontend/tvm/demo_flow.py
"""
import os
import re
import shutil
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

from frontend.tvm import model, kernels, _compiler, cpu_codegen, orchestrator
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


def dog_to_pixels(path):
    """Open ``path`` -> grayscale INPUT_W x INPUT_H raw uint8 pixels.

    Returns the *unquantized* pixels: the ELF embeds these and does the
    asymmetric quantization itself (``emit_image_header``), so the quantizer is
    part of what runs on target rather than a host-side preprocessing step.
    ``None`` if PIL is unavailable, so the caller can fall back.
    """
    try:
        from PIL import Image
    except Exception as e:                              # noqa: BLE001
        print(f"[stage2] PIL unavailable ({e}); using model.make_input()")
        return None
    img = Image.open(path).convert("L").resize((model.INPUT_W, model.INPUT_H))
    return np.asarray(img, dtype=np.uint8).reshape(-1)  # [0,255], len H*W*C


def quantize_pixels_asym(px):
    """Host-side twin of the emitted ``<name>_quantize`` C function.

    Must stay bit-identical to ``orchestrator.emit_image_header``'s generated C
    — it is what lets Stage 2's numpy oracle be compared against the ELF's
    output at all. Both derive scale/zp from the image's own [min,max] and
    round half away from zero.
    """
    px = np.asarray(px, dtype=np.float32)
    lo, hi = float(px.min()), float(px.max())
    if hi - lo < 1e-9:
        scale, zp = 1.0, -128
    else:
        scale = (hi - lo) / 255.0
        zp = int(np.clip(round(-128 - lo / scale), -128, 127))
    v = px / scale + zp
    q = np.where(v < 0, np.ceil(v - 0.5), np.floor(v + 0.5))   # half away from 0
    return np.clip(q, -128, 127).astype(np.int8)


# ═══════════════════════════════════════════════════════════════════════════
#  Stage 0: meaningful reference classification (real model, real image)
# ═══════════════════════════════════════════════════════════════════════════
image_path = classify_dog_reference()

# The same image as raw pixels; the ELF quantizes them on-target. The host
# oracle applies the identical affine so the two are comparable.
demo_pixels = dog_to_pixels(image_path) if image_path else None
demo_input = (quantize_pixels_asym(demo_pixels)
              if demo_pixels is not None else None)

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
# Single switch for BOTH stage 4 (per-launch dirs) and stage 5 (the A2
# orchestrated main.elf). False => the conv2d family is force-offloaded to the
# CPU backend everywhere, so no kernel_<name>.cc is emitted and hostcompile.sh
# never invokes xchesscc.
enable_aiehlc_offload = False
for op, launch in zip(plan, core.lower_aiegraph(ir)):
    out_dir = os.path.join(OUT, f"{int(launch['index']):02d}_{op.op}")
    os.makedirs(out_dir, exist_ok=True)
    if cpu_codegen.is_aie_op(op.op) and enable_aiehlc_offload:                    # conv2d family -> AIE
        specs = [(list(s), int(b), bool(i)) for (s, b, i) in launch["tensor_specs"]]
        body = kernels.kernel_body_for(op.op, launch["func_name"])
        ok = core.run_aie_pipeline(2, 2, specs, out_dir, body, launch["func_name"])
        kind = "AIE"
    else:                                               # everything else -> CPU C
        # conv2d family reaching this branch is a *force-offload to CPU* (offload
        # disabled): emit its bit-exact plain-C. Native CPU ops ignore force.
        ok = cpu_codegen.emit_cpu_launch(op, out_dir, launch["func_name"],
                                         force=cpu_codegen.is_aie_op(op.op))
        kind = "CPU(forced)" if cpu_codegen.is_aie_op(op.op) else "CPU"
    print(op.op, kind, out_dir, "OK" if ok else "FAIL")

# ═══════════════════════════════════════════════════════════════════════════
#  Stage 5: orchestrate all launches into ONE main.elf (A2 multi-kernel path)
# ═══════════════════════════════════════════════════════════════════════════
# Unlike Stage 4 (independent per-launch dirs), the orchestrator regenerates
# everything into one build dir: ONE host.cc (N appended host_canonicalized_<name>
# funcs + __aie_launch dispatcher), per-conv kernel_<name>.cc, CPU-op plain-C
# <name>.c, and a program-order main.cc with DDR buffer chaining. build_main_elf
# then folds main.cc + CPU bodies into host.cc and links via hostcompile.sh.
launches = core.lower_aiegraph(ir)                     # program-order launches
a2_dir = os.path.join(OUT, "a2")
try:
    build_dir = orchestrator.orchestrate_plan(
        plan, launches, a2_dir, enable_aiehlc_offload=enable_aiehlc_offload,
        image_pixels=demo_pixels)
    _emitted = ("host.cc / kernel_*.cc / main.cc / cpu .c" if enable_aiehlc_offload
                else "host.cc / main.cc / cpu .c (all ops on CPU, no AIE kernel)")
    print(f"[stage5] emitted A2 driver ({_emitted}):", build_dir)
except Exception as e:                                  # noqa: BLE001
    print(f"[stage5] orchestrate_plan failed ({e}); skipping ELF build")
    build_dir = None

# Link main.elf only when the cross-toolchain is present; else stop at sources.
_have_gpp = (shutil.which("aarch64-linux-gnu-g++")
             or shutil.which("aarch64-none-elf-g++"))
# xchesscc is only needed when a conv actually compiles to an AIE kernel; the
# all-CPU build has no kernel_*.cc for hostcompile.sh to hand to kc.sh.
_have_chess = (not enable_aiehlc_offload
               or (shutil.which("xchesscc") and os.environ.get("XILINX_VITIS")))
if build_dir and _have_gpp and _have_chess:
    print("[stage5] linking main.elf via hostcompile.sh "
          f"({'multi-kernel' if enable_aiehlc_offload else 'host-only'} build; "
          "live log below)...", flush=True)
    try:
        elf = orchestrator.build_main_elf(build_dir)
        print("[stage5] built main.elf ->", elf)
    except Exception as e:                              # noqa: BLE001
        print(f"[stage5] ELF link failed ({e})")
elif build_dir:
    print("[stage5] cross toolchain absent "
          "(need aarch64 g++ + xchesscc/$XILINX_VITIS); emitted sources only")

# ═══════════════════════════════════════════════════════════════════════════
#  Stage 6: build + RUN the same CPU code natively on x86
# ═══════════════════════════════════════════════════════════════════════════
# Stage 5's main.elf is a baremetal aarch64 binary — it only runs on the board
# over JTAG, so it tells you the build works but not what it computes. This
# compiles the SAME emitted .c files for the host and runs them, so the numbers
# are visible immediately. Only possible for an all-CPU build: with AIE offload
# on, the launches go into hardware and have no x86 equivalent.
if build_dir and not enable_aiehlc_offload:
    print("\n[stage6] building the same CPU code for x86 and running it...")
    try:
        x86 = orchestrator.build_x86_main(build_dir)
        print(f"[stage6] built {x86}")
        out = orchestrator.run_x86_main(x86)
        print("[stage6] ---- x86 output ----")
        for line in out.rstrip("\n").splitlines():
            print(f"[stage6] {line}")
        print("[stage6] ---------------------")
        # The CPU oracle ran back in Stage 2 on the same plan and input, so a
        # mismatch here means the emitted C diverges from the numpy reference.
        want = [int(v) for v in logits]
        got = [int(m) for m in re.findall(r"logit\[\d+\] = (-?\d+)", out)]
        if got and got == want:
            print(f"[stage6] MATCHES the Stage-2 numpy oracle {want}")
        elif got:
            print(f"[stage6] MISMATCH vs numpy oracle: C={got} numpy={want}")
        else:
            print("[stage6] (no logit lines parsed from x86 output)")
    except Exception as e:                              # noqa: BLE001
        print(f"[stage6] x86 build/run failed ({e})")
elif build_dir:
    print("\n[stage6] skipped: AIE offload is on, so the launches need "
          "hardware (set enable_aiehlc_offload=False for a runnable x86 build)")
