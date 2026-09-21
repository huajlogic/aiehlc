###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Verification for the int8 ResNet-18 v2 quantization oracle.

Run:  python src/frontend/tvm/quant/test_quant.py

Skips cleanly (never fails) when torch/PIL/onnx or the cached weights are
absent, matching the rest of this frontend's test conventions.
"""

import os
import sys

import numpy as np

_HERE = os.path.dirname(os.path.abspath(__file__))
_SRC = os.path.dirname(os.path.dirname(os.path.dirname(_HERE)))
_ROOT = os.path.dirname(_SRC)
for p in (_SRC, os.path.join(_ROOT, "example", "model", "resnet18py")):
    if p not in sys.path:
        sys.path.insert(0, p)

from frontend.tvm.quant.ptq import (QMAX, QMIN, choose_act_qparam,
                                    quantize_weights_per_channel)


def _assets():
    """Return (image_path, weights_path, labels) or None if unavailable."""
    try:
        from classify import (resolve, load_labels, DEFAULT_IMAGE_URL,
                              DEFAULT_WEIGHTS_URL, DEFAULT_LABELS_URL)
        img = resolve(None, DEFAULT_IMAGE_URL, "input_image")
        wts = resolve(None, DEFAULT_WEIGHTS_URL, "resnet18-v2-7.onnx")
        labels = load_labels(resolve(None, DEFAULT_LABELS_URL,
                                     "imagenet_classes.txt"))
        return img, wts, labels
    except Exception as e:                                    # noqa: BLE001
        print(f"  [skip] assets unavailable ({e})")
        return None


# ═══════════════════════════════════════════════════════════════════════════
#  Unit-level: the quantization primitives
# ═══════════════════════════════════════════════════════════════════════════

def test_act_qparam_maps_zero_exactly():
    """Float 0.0 must land on an exact integer — conv zero-padding depends on it.

    If zero does not map exactly, every padded border element contributes a
    small bias to the accumulator instead of nothing.
    """
    for lo, hi in [(-3.0, 5.0), (0.0, 6.0), (-2.5, 0.0), (-1.0, 1.0)]:
        qp = choose_act_qparam(lo, hi)
        q0 = qp.quantize(np.array([0.0], dtype=np.float32))
        assert q0[0] == qp.zp, f"zero not exact for ({lo},{hi}): {q0[0]} != {qp.zp}"
        assert abs(float(qp.dequantize(q0)[0])) < 1e-6
    print("PASS test_act_qparam_maps_zero_exactly")


def test_act_qparam_covers_range():
    """Endpoints must survive the round-trip within one quantization step."""
    lo, hi = -2.0, 7.0
    qp = choose_act_qparam(lo, hi)
    for v in (lo, 0.0, hi):
        r = float(qp.dequantize(qp.quantize(np.array([v], dtype=np.float32)))[0])
        assert abs(r - v) <= qp.scale, f"{v} -> {r} exceeds step {qp.scale}"
    print("PASS test_act_qparam_covers_range")


def test_weight_quant_is_per_channel():
    """A channel 100x smaller than its neighbour must keep its resolution.

    This is the whole reason for per-channel weights: under a single tensor
    scale the small channel would collapse to near-zero.
    """
    w = np.zeros((2, 4), dtype=np.float32)
    w[0] = [1.0, -1.0, 0.5, -0.5]
    w[1] = [0.01, -0.01, 0.005, -0.005]
    q, s = quantize_weights_per_channel(w)
    assert q.shape == w.shape and s.shape == (2,)
    assert abs(q[0]).max() == QMAX and abs(q[1]).max() == QMAX, \
        f"both channels should use full range: {q}"
    # Round-trip error is bounded by half a quantization step *per channel*
    # (int8 rounding), not by an absolute constant — channel 1 is 100x smaller
    # and so has a 100x tighter bound. Checking against a single absolute
    # epsilon would either fail on channel 0 or be vacuous on channel 1.
    deq = q.astype(np.float32) * s[:, None]
    err = np.abs(deq - w).max(axis=1)
    assert np.all(err <= s / 2 + 1e-9), f"per-channel error {err} vs step/2 {s/2}"
    print("PASS test_weight_quant_is_per_channel")


def test_weight_quant_handles_zero_channel():
    """An all-zero channel must not divide by zero."""
    w = np.zeros((2, 3), dtype=np.float32)
    w[0] = [1.0, 2.0, 3.0]
    q, s = quantize_weights_per_channel(w)
    assert np.all(np.isfinite(s)) and np.all(q[1] == 0)
    print("PASS test_weight_quant_handles_zero_channel")


def test_quantized_values_in_int8_range():
    """Nothing may escape [-128,127] — the C stores these as int8_t."""
    rng = np.random.RandomState(0)
    x = rng.randn(1000).astype(np.float32) * 50.0
    qp = choose_act_qparam(-10, 10)             # deliberately too narrow
    q = qp.quantize(x)
    assert q.min() >= QMIN and q.max() <= QMAX, f"[{q.min()},{q.max()}]"
    assert q.dtype == np.int8
    print("PASS test_quantized_values_in_int8_range")


# ═══════════════════════════════════════════════════════════════════════════
#  Model-level: float reference, then the int8 oracle
# ═══════════════════════════════════════════════════════════════════════════

def test_float_numpy_matches_torch():
    """The numpy float reference is the control — it must match PyTorch."""
    a = _assets()
    if a is None:
        return
    img, wts, labels = a
    try:
        import torch
        from classify import preprocess
        from resnet18 import resnet18
    except Exception as e:                                    # noqa: BLE001
        print(f"  [skip] torch unavailable ({e})")
        return
    from frontend.tvm.quant.resnet_np import ResNet18V2NP
    x = preprocess(img)
    with torch.no_grad():
        ref = resnet18(onnx_path=wts)(x).numpy()
    got = ResNet18V2NP(wts).forward(x.numpy())
    err = float(np.abs(ref - got).max())
    assert err < 1e-3, f"numpy diverges from torch by {err}"
    assert ref.argmax() == got.argmax() == 258, "expected Samoyed (class 258)"
    print(f"PASS test_float_numpy_matches_torch (max err {err:.2e})")


def test_int8_classifies_correctly():
    """The fully-quantized model must still answer Samoyed with high confidence.

    This is the load-bearing claim of the whole quantization effort: int8 end to
    end, real ImageNet weights, correct top-1. The confidence floor guards
    against a degenerate 'right for the wrong reason' pass where the logits are
    nearly uniform but class 258 edges ahead.
    """
    a = _assets()
    if a is None:
        return
    img, wts, labels = a
    try:
        from classify import preprocess
    except Exception as e:                                    # noqa: BLE001
        print(f"  [skip] PIL unavailable ({e})")
        return
    from frontend.tvm.quant.qresnet import QuantResNet18
    from frontend.tvm.quant.resnet_np import ResNet18V2NP
    x = preprocess(img).numpy()
    net = ResNet18V2NP(wts)
    qp = QuantResNet18.calibrate(net, [x])
    out = QuantResNet18.from_float(net, qp).forward(x)
    p = np.exp(out - out.max())
    p /= p.sum()
    conf = float(p[0][out.argmax()]) * 100.0
    assert out.argmax() == 258, \
        f"int8 misclassified: {labels[out.argmax()]} ({out.argmax()})"
    assert conf > 80.0, f"int8 confidence collapsed to {conf:.1f}%"
    print(f"PASS test_int8_classifies_correctly "
          f"({labels[258]} {conf:.2f}%)")


def test_int8_agrees_with_float_on_heldout():
    """Calibrate on one image, then check agreement on inputs never observed.

    Guards against scales overfitted to the calibration image — the failure
    mode where accuracy looks fine on the one picture used to pick the ranges
    and collapses on anything else.
    """
    a = _assets()
    if a is None:
        return
    img, wts, labels = a
    try:
        from classify import preprocess
    except Exception as e:                                    # noqa: BLE001
        print(f"  [skip] PIL unavailable ({e})")
        return
    from frontend.tvm.quant.qresnet import QuantResNet18
    from frontend.tvm.quant.resnet_np import ResNet18V2NP
    x = preprocess(img).numpy()
    net = ResNet18V2NP(wts)
    q = QuantResNet18.from_float(net, QuantResNet18.calibrate(net, [x]))
    heldout = {
        "flip": x[:, :, :, ::-1].copy(),
        "shift": np.roll(x, 16, axis=3),
        "noise": np.random.RandomState(0).randn(*x.shape).astype(np.float32),
    }
    for name, t in heldout.items():
        f, o = net.forward(t), q.forward(t)
        assert f.argmax() == o.argmax(), (
            f"{name}: float={labels[f.argmax()]} int8={labels[o.argmax()]}")
    print(f"PASS test_int8_agrees_with_float_on_heldout "
          f"({len(heldout)} inputs)")



# ═══════════════════════════════════════════════════════════════════════════
#  Emit-level: fixed point, then the generated C
# ═══════════════════════════════════════════════════════════════════════════

def test_fixed_point_roundtrip():
    """Multipliers reconstruct to <1e-9 relative error, signs preserved."""
    from frontend.tvm.quant.emit_c import to_fixed_point, verify_fixed_point
    m = np.array([1e-9, 1e-6, 3.7e-4, 0.5, 1.0, 2.5, -7.7e-7, -2.5, 0.0])
    mult, shift = to_fixed_point(m)
    assert verify_fixed_point(m, mult, shift) < 1e-9
    assert np.all(np.sign(mult) == np.sign(m)), "sign lost in conversion"
    assert mult[m == 0][0] == 0
    print("PASS test_fixed_point_roundtrip")


def test_fixed_point_preserves_negative_multipliers():
    """A negative multiplier must survive — real BN gammas go negative.

    Regression: an early version treated ``m <= 0`` as degenerate and mapped it
    to zero, silently deleting 4 of ResNet-18's channels.
    """
    from frontend.tvm.quant.emit_c import to_fixed_point
    m = np.array([-1e-6, -0.5, -2.0])
    mult, shift = to_fixed_point(m)
    assert np.all(mult < 0), f"negatives zeroed: {mult}"
    approx = mult / (2.0 ** shift)
    assert np.allclose(approx, m, rtol=1e-9)
    # And the C's arithmetic shift must reproduce it.
    acc = np.array([1000, -1000, 7], dtype=np.int64)
    half = np.where(shift > 0, np.int64(1) << np.maximum(shift - 1, 0), 0)
    v = acc * mult
    got = np.where(shift > 0, (v + np.where(v >= 0, half, -half)) >> shift, v)
    assert np.abs(got - np.round(acc * m)).max() <= 1
    print("PASS test_fixed_point_preserves_negative_multipliers")


def test_emitted_c_classifies_correctly():
    """The generated C, compiled and run, must classify the dog as Samoyed.

    This is the end-to-end claim: real ImageNet weights -> int8 -> plain C ->
    native binary -> correct answer. Skips if no host cc / ld is available.
    """
    import shutil
    import subprocess
    import tempfile
    if not (shutil.which("gcc") and shutil.which("ld")):
        print("  [skip] no gcc/ld")
        return
    a = _assets()
    if a is None:
        return
    img, wts, labels = a
    try:
        from classify import preprocess
    except Exception as e:                                    # noqa: BLE001
        print(f"  [skip] PIL unavailable ({e})")
        return
    from frontend.tvm.quant.emit_c import ResNetCEmitter
    from frontend.tvm.quant.qresnet import QuantResNet18
    from frontend.tvm.quant.resnet_np import ResNet18V2NP

    x = preprocess(img).numpy()
    net = ResNet18V2NP(wts)
    qp = QuantResNet18.calibrate(net, [x])
    q = QuantResNet18.from_float(net, qp)
    with tempfile.TemporaryDirectory() as d:
        man = ResNetCEmitter(q).emit(d)
        harness = os.path.join(d, "h.c")
        with open(harness, "w") as f:
            f.write("#include <stdint.h>\n#include <stdio.h>\n"
                    "void run_resnet(const int8_t*, float*);\n"
                    "int main(int c, char**v){static int8_t in[3*224*224];"
                    "FILE*f=fopen(v[1],\"rb\");fread(in,1,sizeof in,f);fclose(f);"
                    "static float lg[1000];run_resnet(in,lg);"
                    "FILE*o=fopen(v[2],\"wb\");fwrite(lg,4,1000,o);fclose(o);return 0;}\n")
        subprocess.run(["ld", "-r", "-b", "binary", "-o",
                        os.path.join(d, "w.o"), "weights.bin"],
                       cwd=d, check=True, capture_output=True)
        r = subprocess.run(["gcc", "-O2", "-o", os.path.join(d, "run"),
                            man["source"], harness, os.path.join(d, "w.o")],
                           capture_output=True, text=True)
        assert r.returncode == 0, f"generated C failed to compile:\n{r.stderr[-2000:]}"
        qp["input"].quantize(x).astype(np.int8).tofile(os.path.join(d, "in.bin"))
        subprocess.run([os.path.join(d, "run"), os.path.join(d, "in.bin"),
                        os.path.join(d, "out.bin")], check=True,
                       capture_output=True)
        logits = np.fromfile(os.path.join(d, "out.bin"), dtype=np.float32)
    p = np.exp(logits - logits.max())
    p /= p.sum()
    conf = float(p[logits.argmax()]) * 100.0
    assert logits.argmax() == 258, \
        f"generated C misclassified: {labels[logits.argmax()]}"
    assert conf > 75.0, f"confidence collapsed to {conf:.1f}%"
    print(f"PASS test_emitted_c_classifies_correctly (Samoyed {conf:.2f}%)")


if __name__ == "__main__":
    tests = [
        ("act qparam maps zero exactly", test_act_qparam_maps_zero_exactly),
        ("act qparam covers range", test_act_qparam_covers_range),
        ("weight quant is per-channel", test_weight_quant_is_per_channel),
        ("weight quant handles zero channel", test_weight_quant_handles_zero_channel),
        ("quantized values in int8 range", test_quantized_values_in_int8_range),
        ("float numpy == torch", test_float_numpy_matches_torch),
        ("int8 classifies correctly", test_int8_classifies_correctly),
        ("int8 agrees on held-out", test_int8_agrees_with_float_on_heldout),
        ("fixed-point roundtrip", test_fixed_point_roundtrip),
        ("fixed-point keeps negatives", test_fixed_point_preserves_negative_multipliers),
        ("emitted C classifies correctly", test_emitted_c_classifies_correctly),
    ]
    fails = 0
    for name, fn in tests:
        try:
            fn()
        except Exception as e:                                # noqa: BLE001
            fails += 1
            print(f"FAIL  {name}: {e}")
    print("PASS: all checks passed." if not fails
          else f"FAIL: {fails} check(s) failed.")
    sys.exit(1 if fails else 0)
