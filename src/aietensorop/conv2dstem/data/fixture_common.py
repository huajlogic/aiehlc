#!/usr/bin/env python3
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Shared plumbing for the conv2dstem fixture generators.

Three scripts sit on top of this module -- ``make_image_header.py``,
``make_weights_header.py`` and ``groundtruth.py`` -- and all three need the same
two things: the quantization parameters of ResNet-18's first conv, and a C
header emitter. Keeping them here means the scale/zero-point are read from the
model in exactly one place, so the image, the weights and the golden output
cannot drift apart.

What the quantized stem actually looks like
-------------------------------------------
From the int8 QDQ model, node ``resnetv15_conv0_fwd``::

    data_scale / data_zero_point      0.01859129 / 113   (uint8 activations)
    weight                            int8 [64,3,7,7], per-channel scale, zp 0
    bias                              int32 [64], scale = in_scale * w_scale
    output scale / zero_point         0.008710225 / 0

The output zero-point being **0** is load-bearing: the core's epilogue has no
additive term after the multiply, so a non-zero output zp could not be
expressed at all. :func:`load_stem_params` asserts it rather than assuming it.

Mapping that onto the kernel's ``conv2dstem_qparam``
-----------------------------------------------------
The kernel is int8 x int8, the graph is uint8 x int8, so activations go in as
``x_s8 = x_u8 - 128`` and the matching ``+128 * sum(w)`` is folded into the
bias. The input zero-point folds into the same term::

    bias[c]           = bias_q[c] + (128 - in_zp) * sum(w[c])
    zero_point[c]     = 0
    mult[c], shift[c] = fixed_point(in_scale * w_scale[c] / out_scale)

This is the same folding ``byoc/aie_codegen.py:fold_qparams`` performs
(``bias = C2 + C3 - C4 + 128*wsum``), reached from the ONNX side instead of the
Relay side -- so the two independently cross-check each other.

**The shift's sign is the trap.** TVM's ``GetFixedPointMultiplierShift``
(``thirdparty/tvm-0.16/src/relay/qnn/utils.cc:33``) returns ``frexp``'s
exponent, but the value stored in the qparam -- the one consumed by
``(acc*mult + 2^(sh+30)) >> (sh+31)`` -- is its **negation**. TVM's own
generated C emits ``... + ((int64_t)1 << (p9[c] + 31 - 1))) >> (p9[c] + 31)``
(``worklocal/tvmrelay_deploy/resnet18.c:648``), which pins the convention down.
Getting it backwards yields plausible-looking but uniformly wrong pixels, so
:func:`fold_qparams` asserts the ``mult * 2**-(shift+31)`` round-trip per
channel.

Verified end to end: the pipeline below reproduces onnxruntime's own int8
output for this layer on dog.jpg to within **2 elements out of 802,816**
(max difference 1), the expected residue of round-half-even vs the core's
fixed-point round-half-up.
"""
from __future__ import annotations

import math
import os
import re
import sys
import textwrap
from dataclasses import dataclass
from pathlib import Path

import numpy as np

__all__ = ["StemParams", "REPO", "DATA_DIR", "OUT_DIR", "DEFAULT_IMAGE",
           "resolve_qdq_model", "load_stem_params", "fixed_point",
           "fold_qparams", "preprocess_to_pad4", "pad4_to_hwc3",
           "emit_header", "hex_array", "i16_array", "i32_array",
           # TVM layer 0 -- deploy_flow's front end, reimplemented
           "TVM_LAYER0_SYMBOL", "find_tvm_layer0_source",
           "parse_tvm_layer0_consts", "roundf", "tvm_quantize_u8",
           "tvm_layer0", "preprocess_to_tvm_layer0", "pad4_to_tvm_layer0",
           "verify_against_kernel"]

#: Repository root: .../src/aietensorop/conv2dstem/data -> up four.
REPO = Path(__file__).resolve().parents[4]
DATA_DIR = Path(__file__).resolve().parent
#: Generated headers land FLAT in the app source dir, not in data/ --
#: script/aiehlc.sh:532 copies user headers with a non-recursive `*.h` glob
#: flattened to basename, and hostcompile.sh only adds -I<worklocal>. A header
#: left in data/ is never copied and the cross-g++ step fails to find it.
OUT_DIR = DATA_DIR.parent
DEFAULT_IMAGE = DATA_DIR / "dog.jpg"

#: Geometry -- ResNet-18 conv1. Must agree with conv2dstem.h:41-51.
IN_H = IN_W = 224
IN_C = 3
C_ALIGN = 4          # channel-layout stride; the 4th channel is alignment pad
KH = KW = 7
STRIDE = 2
PAD = 3
OC = 64
OUT_H = OUT_W = 112

IFM_PAD4_ELEMS = (IN_H + 2 * PAD) * (IN_W + 2 * PAD) * C_ALIGN   # 211600
WTS_ELEMS = OC * KH * KW * IN_C                                   # 9408
OFM_ELEMS = OUT_H * OUT_W * OC                                    # 802816


@dataclass
class StemParams:
    """Everything the first conv's QDQ neighbourhood carries."""
    weight: np.ndarray      # int8  [OC, IC, KH, KW], as stored (OIHW)
    w_scale: np.ndarray     # float64 [OC]
    bias_q: np.ndarray      # int32 [OC], scale = in_scale * w_scale
    in_scale: float
    in_zp: int
    out_scale: float
    out_zp: int
    model: Path

    @property
    def real_scale(self) -> np.ndarray:
        """Per-channel requantization scale ``in_scale * w_scale / out_scale``."""
        return self.in_scale * self.w_scale / self.out_scale


def resolve_qdq_model(path=None, *, verbose: bool = True) -> Path:
    """Locate the int8 QDQ ResNet-18, quantizing it first if need be.

    Prefers the model the TVM flow already produced under ``worklocal/``. Only
    if that is absent does it fall back to downloading the fp32 model and
    running the repo's own PTQ (``onnx_ptq.quantize_onnx_int8`` -- onnxruntime
    ``quantize_static``, QDQ, per-channel symmetric int8 weights / asymmetric
    uint8 activations). No new quantization scheme is introduced here.
    """
    if path is not None:
        p = Path(path)
        if not p.is_file():
            raise FileNotFoundError(f"{p} not found")
        return p

    cached = REPO / "worklocal" / "tvmrelay_deploy" / "resnet18-v1-7.int8.qdq.onnx"
    if cached.is_file():
        if verbose:
            print(f"  [model]  {cached.relative_to(REPO)} (cached)")
        return cached

    # Importing frontend.tvmrelay runs ensure_tvm016(), which can kick off a
    # 10-25 minute TVM source build. These scripts need onnx + onnxruntime
    # only, so switch that off and import lazily -- the common path above
    # never gets here at all.
    os.environ.setdefault("AIEHLC_TVM_AUTO_INSTALL", "0")
    if str(REPO / "src") not in sys.path:
        sys.path.insert(0, str(REPO / "src"))
    from frontend.tvmrelay import onnx_ptq, deploy_flow   # noqa: E402

    out_dir = REPO / "worklocal" / "tvmrelay_deploy"
    out_dir.mkdir(parents=True, exist_ok=True)
    if verbose:
        print(f"  [model]  {cached.name} absent -- fetching fp32 + running PTQ")
    # quantize_onnx_int8() does the opset upgrade and BN fold itself (order is
    # load-bearing, see its module docstring) and caches the QDQ result.
    raw = deploy_flow.fetch_model(out_dir, verbose=verbose)
    return onnx_ptq.quantize_onnx_int8(raw, out_dir, verbose=verbose)


def _qdq_operand(graph_init, producers, name, what):
    """``(tensor, scale, zero_point)`` behind a DequantizeLinear output.

    ``tensor`` is ``None`` for an *activation* input, whose quantized value is a
    runtime tensor rather than an initializer -- only its scale and zero-point
    are constants. Weights and bias have all three.
    """
    node = producers.get(name)
    if node is None or node.op_type != "DequantizeLinear":
        raise ValueError(f"{what}: expected a DequantizeLinear producing {name!r}, "
                         f"got {node.op_type if node else 'an initializer'}")
    q = graph_init.get(node.input[0])
    return q, graph_init[node.input[1]], graph_init[node.input[2]]


def load_stem_params(model_path=None, *, verbose: bool = True) -> StemParams:
    """Pull the first conv's weights and quantization parameters out of the QDQ model.

    Walks the ``Conv``'s own QDQ neighbourhood rather than matching initializer
    names, so it survives the BN-fusion renaming ORT applies.
    """
    import onnx
    from onnx import numpy_helper as nh

    path = resolve_qdq_model(model_path, verbose=verbose)
    model = onnx.load(str(path))
    g = model.graph
    init = {i.name: nh.to_array(i) for i in g.initializer}
    producers = {o: n for n in g.node for o in n.output}

    convs = [n for n in g.node if n.op_type == "Conv"]
    if not convs:
        raise ValueError(f"{path}: no Conv node found")
    conv = convs[0]
    attrs = {a.name: onnx.helper.get_attribute_value(a) for a in conv.attribute}

    _, in_s, in_zp = _qdq_operand(init, producers, conv.input[0], "conv input")
    w_q, w_s, w_zp = _qdq_operand(init, producers, conv.input[1], "conv weight")
    b_q, _, _ = _qdq_operand(init, producers, conv.input[2], "conv bias")

    # The Conv's consumer is the QuantizeLinear that re-quantizes the fused
    # conv+relu result; its scale/zp are the output quantization.
    consumers = [n for n in g.node if conv.output[0] in n.input]
    qout = next((n for n in consumers if n.op_type == "QuantizeLinear"), None)
    if qout is None:
        raise ValueError(f"{conv.name}: output is not consumed by a QuantizeLinear")
    out_s, out_zp = init[qout.input[1]], init[qout.input[2]]

    sp = StemParams(weight=w_q.astype(np.int64), w_scale=w_s.astype(np.float64),
                    bias_q=b_q.astype(np.int64), in_scale=float(in_s),
                    in_zp=int(in_zp), out_scale=float(out_s), out_zp=int(out_zp),
                    model=path)

    # --- geometry + scheme assertions, each one a silent-wrongness guard ---
    if tuple(sp.weight.shape) != (OC, IN_C, KH, KW):
        raise ValueError(f"{conv.name}: weight {sp.weight.shape}, expected "
                         f"{(OC, IN_C, KH, KW)} -- conv2dstem.h geometry mismatch")
    if tuple(attrs.get("strides", ())) != (STRIDE, STRIDE):
        raise ValueError(f"{conv.name}: strides {attrs.get('strides')}, expected "
                         f"{(STRIDE, STRIDE)}")
    if tuple(attrs.get("pads", ())) != (PAD,) * 4:
        raise ValueError(f"{conv.name}: pads {attrs.get('pads')}, expected "
                         f"{(PAD,) * 4}")
    if np.any(np.asarray(w_zp) != 0):
        raise ValueError(f"{conv.name}: weight zero-point is non-zero; the kernel "
                         f"cannot express it (the result would depend on sum(x))")
    if sp.out_zp != 0:
        raise ValueError(f"{conv.name}: output zero-point is {sp.out_zp}, not 0. "
                         f"The core's epilogue has no additive term after the "
                         f"multiply, so this cannot be expressed.")

    if verbose:
        print(f"  [stem]   {conv.name}: in s={sp.in_scale:.8g} zp={sp.in_zp}, "
              f"out s={sp.out_scale:.8g} zp={sp.out_zp}")
    return sp


def fixed_point(d: float) -> tuple:
    """``(multiplier, shift)`` for a positive real scale, TVM's convention.

    Transcribes ``GetFixedPointMultiplierShift``
    (``thirdparty/tvm-0.16/src/relay/qnn/utils.cc:33``) -- frexp, round the
    significand into Q31, carry if it lands exactly on 2^31 -- and then
    **negates the exponent**, because the qparam stores the right-shift the
    core applies as ``>> (shift + 31)``, not frexp's exponent.
    """
    if d == 0.0:
        return 0, 0
    significand, exponent = math.frexp(d)
    q31 = int(round(significand * (1 << 31)))
    if q31 == (1 << 31):
        q31 //= 2
        exponent += 1
    return q31, -exponent


def fold_qparams(sp: StemParams) -> np.ndarray:
    """``[OC, 4]`` int32 ``{bias, zero_point, multiplier, shift}`` for the kernel.

    ``bias`` absorbs the ONNX bias and the ``(128 - in_zp) * sum(w)`` term that
    undoes the uint8 -> int8 input shift and the input zero-point together.
    """
    wsum = sp.weight.reshape(OC, -1).sum(axis=1)
    bias = sp.bias_q + (128 - sp.in_zp) * wsum

    real = sp.real_scale
    mult = np.empty(OC, np.int64)
    shift = np.empty(OC, np.int64)
    for c in range(OC):
        mult[c], shift[c] = fixed_point(float(real[c]))

    # Every one of these would otherwise fail silently on the core.
    lo, hi = -(1 << 31), (1 << 31)
    for name, arr in (("bias", bias), ("multiplier", mult), ("shift", shift)):
        if (arr < lo).any() or (arr >= hi).any():
            raise ValueError(f"folded {name} overflows int32: "
                             f"[{arr.min()}, {arr.max()}]")
    if (shift + 30 < 0).any():
        raise ValueError(f"shift+30 is negative ({shift.min()}); the epilogue's "
                         f"rounding term 1 << (shift+30) would be undefined")
    back = mult.astype(np.float64) * 2.0 ** -(shift + 31)
    rel = np.abs(back / real - 1.0)
    if rel.max() > 1e-6:
        raise ValueError(f"fixed-point round-trip is off by {rel.max():.3g} -- "
                         f"the multiplier/shift convention is wrong")

    return np.stack([bias, np.zeros_like(bias), mult, shift], axis=1).astype(np.int64)


def preprocess_to_pad4(sp: StemParams, image=None, *, verbose: bool = True):
    """``(ifm_pad4 int8 [230,230,4], image_path)`` -- the exact bytes the DMA pushes.

    The float preprocessing is **not** reimplemented here: it calls
    ``example/model/resnet18py/classify.py:preprocess``, the same function the
    reference classifier and the TVM flow use. A second copy of resize /
    crop / mean / std would be the easiest possible way to make the board and
    the reference disagree for a reason that has nothing to do with the
    compiler.

    The rest is the quantized graph's own input handling:

    1. ``clip(round(x / in_scale) + in_zp, 0, 255)``  -> uint8
    2. pad 3 on every spatial border with **in_zp**, not zero. ONNX pads the
       *dequantized* tensor with 0.0, and 0.0 dequantizes from ``x_q = zp``.
    3. ``x_s8 = x_u8 - 128`` so the int8 x int8 kernel sees the right values;
       the border becomes ``in_zp - 128`` (-15 for this model).
    4. NCHW -> HWC4. Channel 3 is the alignment pad and stays 0; the MAC loop
       stops at ``SP_REAL_C`` (``conv2dstem.cc:371``) so nothing reads it.
    """
    sys.path.insert(0, str(REPO / "example" / "model" / "resnet18py"))
    import classify  # noqa: E402

    src = str(image) if image is not None else str(DEFAULT_IMAGE)
    path = classify.resolve(src, classify.DEFAULT_IMAGE_URL, "input_image")
    x = np.asarray(classify.preprocess(path), np.float32).reshape(1, IN_C, IN_H, IN_W)

    q = np.clip(np.round(x.astype(np.float64) / sp.in_scale) + sp.in_zp,
                0, 255).astype(np.uint8)
    qp = np.pad(q, ((0, 0), (0, 0), (PAD, PAD), (PAD, PAD)), constant_values=sp.in_zp)

    hp, wp = IN_H + 2 * PAD, IN_W + 2 * PAD
    pad4 = np.zeros((hp, wp, C_ALIGN), np.int8)
    pad4[:, :, :IN_C] = (qp[0].transpose(1, 2, 0).astype(np.int16) - 128).astype(np.int8)

    if verbose:
        print(f"  [image]  {path}")
        print(f"           -> uint8 (s={sp.in_scale:.8g}, zp={sp.in_zp}), "
              f"border={sp.in_zp - 128}, HWC4 [{hp},{wp},{C_ALIGN}]")
    return pad4, path


def pad4_to_hwc3(pad4: np.ndarray) -> np.ndarray:
    """Drop the alignment channel: ``[230,230,4]`` -> ``[230,230,3]``."""
    return np.ascontiguousarray(pad4[:, :, :IN_C])


# ─────────────────────────────────────────────────────────────────────────────
# TVM's layer 0 -- the deploy_flow front end, reimplemented step for step
#
# `deploy_flow.py` does the same quantization inside a generated kernel,
# `tvmgen_default_fused_divide_round_add_clip_cast_subtract_layout_transform`.
# The functions below are that kernel, not a paraphrase of it: same order of
# operations, same float32 precision, same C `roundf` tie rule, same output
# layout and dtype. `make_image_header.py --tvm-layer0` runs them and then
# asserts the result against `pad4_to_tvm_layer0`, so the two descriptions of
# one quantization cannot drift apart silently.
# ─────────────────────────────────────────────────────────────────────────────

#: The generated symbol. Also the directory name stage 5 splits it into.
TVM_LAYER0_SYMBOL = ("tvmgen_default_fused_divide_round_add_clip_cast_"
                     "subtract_layout_transform")

#: Where deploy_flow.py writes its output tree.
DEPLOY_DIR = REPO / "worklocal" / "tvmrelay_deploy"


def find_tvm_layer0_source(deploy_dir=None):
    """The generated C for layer 0, or ``None``. Prefers the per-layer split.

    Stage 5 writes one translation unit per operator, so
    ``layers/00_*/00_*.c`` holds this kernel alone; the monolithic
    ``resnet18.c`` is the ``--no-split`` fallback and holds it among 64 others.
    Either is fine to read constants out of.
    """
    deploy_dir = Path(deploy_dir) if deploy_dir else DEPLOY_DIR
    for cand in sorted(deploy_dir.glob("layers/*/*.c")):
        if TVM_LAYER0_SYMBOL in cand.read_text():
            return cand
    mono = deploy_dir / "resnet18.c"
    if mono.is_file() and TVM_LAYER0_SYMBOL in mono.read_text():
        return mono
    return None


def parse_tvm_layer0_consts(source) -> dict:
    """Pull layer 0's baked-in float literals out of the generated C.

    Read rather than recomputed, because they are **not** quite what the model
    says. TVM emits the reciprocal of the input scale to 7 significant digits
    as a float32 literal -- ``5.378862e+01f`` -- while ``1/in_scale`` rounded
    to float32 is ``53.788624``. The gap is ~7e-8 relative, far too small to
    change any pixel here (nothing on dog.jpg lands within 0.002 of a rounding
    tie), but recomputing instead of reading would quietly make this a
    *different* front end on some other image. Parsing keeps "what deploy_flow
    computes" authoritative.

    Returns ``{"recip", "zp_add", "clip_hi", "clip_lo", "source"}``. Raises if
    the kernel's shape has changed, rather than returning stale constants.
    """
    text = Path(source).read_text() if not isinstance(source, str) else source
    body = text.split(TVM_LAYER0_SYMBOL, 1)[-1]

    m = re.search(r"\*\s*([0-9.]+e[+-][0-9]+)f\s*\)\)\s*\+\s*"
                  r"([0-9.]+e[+-][0-9]+)f", body)
    if not m:
        raise ValueError(
            f"{TVM_LAYER0_SYMBOL}: could not find the "
            "`roundf(x * RECIP) + ZP` pattern -- the generated kernel changed "
            "shape; re-read it before trusting these constants")
    recip, zp_add = float(m.group(1)), float(m.group(2))

    hi = re.search(r"<\s*\(([0-9.]+e[+-][0-9]+)f\)", body)
    lo = re.search(r">\s*\(([0-9.]+e[+-][0-9]+)f\)", body)
    if not (hi and lo):
        raise ValueError(f"{TVM_LAYER0_SYMBOL}: could not find the clip bounds")
    return {"recip": recip, "zp_add": zp_add,
            "clip_hi": float(hi.group(1)), "clip_lo": float(lo.group(1)),
            "source": str(source) if not isinstance(source, str) else "<text>"}


def roundf(a: np.ndarray) -> np.ndarray:
    """C ``roundf``: nearest, ties **away from zero** -- not ``np.round``.

    ``np.round`` is round-half-to-**even**, which is what ONNX Runtime's
    QuantizeLinear does and therefore what :func:`preprocess_to_pad4` uses. The
    generated kernel calls ``roundf``. The two disagree only on an exact ``.5``,
    which does not occur on dog.jpg -- but writing ``np.round`` here would make
    this function silently stop being the kernel.
    """
    a64 = np.asarray(a, np.float64)
    return np.copysign(np.floor(np.abs(a64) + 0.5), a64).astype(np.float32)


def tvm_quantize_u8(x_f32: np.ndarray, consts: dict) -> np.ndarray:
    """Step 1 -- the quantize: fp32 activations -> uint8, in float32 throughout.

    The generated C, line for line::

        float v_   = roundf(p0[i] * RECIP) + ZP_ADD;
        float v__1 = (v_) < (CLIP_HI) ? (v_) : (CLIP_HI);
        /* ... */   (v__1) > (CLIP_LO) ? (v__1) : (CLIP_LO)

    Note it is a **multiply by the reciprocal** in float32, not a divide --
    ``x / in_scale`` in float64 (what the ONNX side does) differs by up to
    1.3e-5 before rounding. Returns float32 holding integral values in
    ``[clip_lo, clip_hi]``, deliberately not yet cast: the cast is step 2's.
    """
    prod = np.asarray(x_f32, np.float32) * np.float32(consts["recip"])
    v = roundf(prod) + np.float32(consts["zp_add"])
    v = np.minimum(v, np.float32(consts["clip_hi"]))
    return np.maximum(v, np.float32(consts["clip_lo"]))


def tvm_layer0(x_nchw: np.ndarray, consts: dict, zp_sub: int) -> np.ndarray:
    """Step 2 -- the whole kernel: NCHW fp32 ``[1,3,224,224]`` -> int16 HWC.

    The cast and the layout transform the quantize feeds into::

        T_layout_trans[h*672 + w*3 + c] =
            (int16_t)clip_result - p1[0];

    ``p1[0]`` is a scalar int16 **parameter**, the graph input's zero-point
    (113 for this model) -- so the `+zp` of the quantize and this `-zp` cancel
    except at the clip, which is exactly what makes the output span
    ``[-zp, 255-zp]`` = [-113, 142] and therefore need int16.

    The index arithmetic is NCHW in (``c*50176 + h*224 + w``) and HWC out
    (``h*672 + w*3 + c``), i.e. a plain transpose -- no channel padding and no
    spatial padding. Returns a C-contiguous ``[224,224,3] int16``.
    """
    x = np.asarray(x_nchw, np.float32).reshape(1, IN_C, IN_H, IN_W)
    v = tvm_quantize_u8(x, consts)
    out = v.astype(np.int16) - np.int16(zp_sub)
    return np.ascontiguousarray(out[0].transpose(1, 2, 0))


def preprocess_to_tvm_layer0(sp: StemParams, image=None, *,
                             deploy_dir=None, verbose: bool = True):
    """``(int16 [224,224,3], image_path, consts)`` -- deploy_flow's layer-0 output.

    Same float preprocessing as :func:`preprocess_to_pad4` (``classify.preprocess``
    -- not a second copy), then :func:`tvm_layer0` instead of the AIE fixture's
    quantize/pad/shift. Constants come from the generated C when
    ``deploy_flow.py`` has been run, and from the model otherwise; which one was
    used is reported, because only the first is *literally* what the board runs.
    """
    sys.path.insert(0, str(REPO / "example" / "model" / "resnet18py"))
    import classify  # noqa: E402

    src = str(image) if image is not None else str(DEFAULT_IMAGE)
    path = classify.resolve(src, classify.DEFAULT_IMAGE_URL, "input_image")
    x = np.asarray(classify.preprocess(path), np.float32).reshape(1, IN_C, IN_H, IN_W)

    found = find_tvm_layer0_source(deploy_dir)
    if found is not None:
        consts = parse_tvm_layer0_consts(found)
        origin = os.path.relpath(found, REPO)
    else:
        # No deploy_flow tree here. float32(1/in_scale) is what TVM's literal
        # approximates; see parse_tvm_layer0_consts for the 7e-8 gap.
        consts = {"recip": float(np.float32(1.0 / sp.in_scale)),
                  "zp_add": float(sp.in_zp), "clip_hi": 255.0, "clip_lo": 0.0,
                  "source": "model"}
        origin = "derived from the model (no worklocal/tvmrelay_deploy tree)"

    out = tvm_layer0(x, consts, sp.in_zp)
    if verbose:
        print(f"  [image]  {path}")
        print(f"           consts from {origin}")
        print(f"           roundf(x * {consts['recip']:.8g}) + {consts['zp_add']:g}"
              f", clip [{consts['clip_lo']:g}, {consts['clip_hi']:g}], "
              f"- zp({sp.in_zp})")
        print(f"           -> int16 HWC [{out.shape[0]},{out.shape[1]},"
              f"{out.shape[2]}], range [{int(out.min())}, {int(out.max())}]")
    return out, path, consts


_VERIFY_MAIN_C = r"""
/* Generated by data/fixture_common.py -- throwaway harness.
 *
 * Calls the REAL generated layer-0 kernel through TVM's packed ABI with the
 * same fp32 image the Python side used, so the comparison is against the
 * compiled code rather than against a reading of it.
 */
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include "tvm_graph_types.h"

int32_t %(sym)s(void*, int32_t*, int32_t, void*, int32_t*, void*);

static float   in[1 * %(c)d * %(h)d * %(w)d];
static int16_t out[%(h)d * %(w)d * %(c)d];

int main(int argc, char **argv) {
    if (argc != 4) { fprintf(stderr, "usage: %%s in.f32 out.i16 zp\n", argv[0]); return 2; }
    FILE *f = fopen(argv[1], "rb");
    if (!f || fread(in, sizeof in, 1, f) != 1) { fprintf(stderr, "bad input\n"); return 1; }
    fclose(f);
    int16_t zp = (int16_t)atoi(argv[3]);

    int64_t s_in[4] = {1, %(c)d, %(h)d, %(w)d};
    int64_t s_zp[1] = {1};
    int64_t s_out[3] = {%(h)d, %(w)d, %(c)d};
    DLTensor t_in = {0}, t_zp = {0}, t_out = {0};
    t_in.data = in;    t_in.ndim = 4;  t_in.dtype.code = 2; t_in.dtype.bits = 32;
    t_in.dtype.lanes = 1;  t_in.shape = s_in;
    t_zp.data = &zp;   t_zp.ndim = 0;  t_zp.dtype.code = 0; t_zp.dtype.bits = 16;
    t_zp.dtype.lanes = 1;  t_zp.shape = s_zp;
    t_out.data = out;  t_out.ndim = 3; t_out.dtype.code = 0; t_out.dtype.bits = 16;
    t_out.dtype.lanes = 1; t_out.shape = s_out;

    TVMValue args[3];
    int32_t codes[3] = {7, 7, 7};          /* kTVMDLTensorHandle */
    args[0].v_handle = &t_in;
    args[1].v_handle = &t_zp;
    args[2].v_handle = &t_out;
    if (%(sym)s(args, codes, 3, 0, 0, 0) != 0) { fprintf(stderr, "kernel failed\n"); return 1; }

    f = fopen(argv[2], "wb");
    if (!f || fwrite(out, sizeof out, 1, f) != 1) { fprintf(stderr, "bad output\n"); return 1; }
    fclose(f);
    return 0;
}
"""


def verify_against_kernel(expect: np.ndarray, x_nchw: np.ndarray, zp_sub: int,
                          *, deploy_dir=None, verbose: bool = True) -> dict:
    """Compile and RUN the generated layer-0 kernel; diff it against *expect*.

    The only check that actually answers "is this what ``deploy_flow.py``
    produces after the first layer" -- everything else compares one reading of
    the generated C against another. The kernel is compiled from its own source
    with the host gcc, driven through TVM's packed ABI, and its output buffer is
    diffed byte for byte.

    Returns ``{"ok", "reason"|"ndiff", "kernel", ...}``. Never raises for a
    missing deploy tree or gcc: those are "cannot check here", not "wrong".
    """
    import subprocess
    import tempfile

    src = find_tvm_layer0_source(deploy_dir)
    if src is None:
        return {"ok": False, "reason": "no generated layer-0 C found -- run "
                                       "deploy_flow.py first"}
    if src.name == "resnet18.c":
        return {"ok": False, "reason": "only the monolithic resnet18.c is "
                                       "present; the harness needs the "
                                       "per-layer split (drop --no-split)"}
    build_inc = (Path(deploy_dir) if deploy_dir else DEPLOY_DIR) / "arm_build"
    if not (build_inc / "tvm_graph_types.h").is_file():
        return {"ok": False, "reason": f"{build_inc}/tvm_graph_types.h missing "
                                       f"-- run deploy_flow.py's stage 6"}
    import shutil as _sh
    if _sh.which("gcc") is None:
        return {"ok": False, "reason": "no gcc on PATH"}

    with tempfile.TemporaryDirectory() as td:
        td = Path(td)
        (td / "harness.c").write_text(
            _VERIFY_MAIN_C % {"sym": TVM_LAYER0_SYMBOL, "c": IN_C,
                              "h": IN_H, "w": IN_W})
        exe = td / "harness"
        cmd = ["gcc", "-O1", "-std=gnu11", f"-I{build_inc}",
               str(td / "harness.c"), str(src), "-o", str(exe), "-lm"]
        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            return {"ok": False, "reason": "harness did not compile",
                    "stderr": proc.stderr[-2000:]}

        f_in, f_out = td / "in.f32", td / "out.i16"
        f_in.write_bytes(np.ascontiguousarray(
            np.asarray(x_nchw, np.float32)).tobytes())
        proc = subprocess.run([str(exe), str(f_in), str(f_out), str(zp_sub)],
                              capture_output=True, text=True)
        if proc.returncode != 0:
            return {"ok": False, "reason": "harness did not run",
                    "stderr": (proc.stderr or proc.stdout)[-2000:]}
        got = np.frombuffer(f_out.read_bytes(), np.int16).reshape(expect.shape)

    diff = got.astype(np.int32) - np.asarray(expect, np.int32)
    ndiff = int((diff != 0).sum())
    res = {"ok": ndiff == 0, "ndiff": ndiff, "total": int(got.size),
           "max_abs": int(np.abs(diff).max()) if diff.size else 0,
           "kernel": os.path.relpath(src, REPO)}
    if verbose:
        if res["ok"]:
            print(f"  [verify] MATCH -- all {res['total']:,} values equal the "
                  f"compiled {Path(src).parent.name}/ kernel")
        else:
            print(f"  [verify] MISMATCH -- {ndiff:,} of {res['total']:,} "
                  f"differ (max |diff| {res['max_abs']})")
    return res


def pad4_to_tvm_layer0(pad4: np.ndarray, sp: StemParams) -> np.ndarray:
    """``[230,230,4] int8`` -> ``[224,224,3] int16``, TVM's layer-0 output.

    What ``tvmgen_default_fused_divide_round_add_clip_cast_subtract_layout_transform``
    writes, derived from the fixture rather than recomputed, because the two
    **are** the same quantization: verified bit-exact over all 150,528 values
    on dog.jpg. Only the representation differs, in three ways:

    * the fixture subtracts **128** so the result fits int8 ([-128, 127]);
      TVM subtracts the **zero-point** (113), giving [-113, 142], which does
      not fit int8 -- hence its int16 output. The gap is the constant
      ``128 - in_zp``;
    * the fixture carries the conv's 3-pixel zero-point border (230x230);
      TVM's layer 0 does not pad at all (224x224), because the padding is
      inside the conv op downstream;
    * the fixture pads the channel axis to 4 for the AIE's MAC stride; TVM
      keeps 3.

    Both are HWC, so no transpose is involved -- TVM indexes
    ``h*672 + w*3 + c``.
    """
    core = pad4[PAD:PAD + IN_H, PAD:PAD + IN_W, :IN_C].astype(np.int16)
    return np.ascontiguousarray(core + np.int16(128 - sp.in_zp))


# ─────────────────────────────────────────────────────────────────────────────
# C header emission
#
# Conventions follow src/frontend/tvmrelay/image_input.py:104-149 -- the only
# bulk-array header generator that already exists here: a "Generated by ... do
# not edit" banner (no copyright block; these are machine output), an
# upper-snake include guard derived from the path, an element-count #define
# used as the array bound, and textwrap.fill at width 78 with a 4-space indent.
#
# The one departure is hex, which the caller asked for and which has no
# precedent in the repo. Arrays are emitted as **uint8_t**, not int8_t:
# `static const int8_t x[] = {0xff}` relies on an implementation-defined
# out-of-range conversion, whereas uint8_t + a cast at the use site is
# well-defined -- and is also literally the byte image the DMA pushes.
# ─────────────────────────────────────────────────────────────────────────────

_BANNER = """\
/* Generated by {generator} -- do not edit.
 *
{prose}
 */
#ifndef {guard}
#define {guard}

#include <stdint.h>

"""


def hex_array(name: str, values, count_macro: str) -> str:
    """A ``static const uint8_t`` array, hex, wrapped at 78 columns."""
    flat = np.asarray(values).reshape(-1)
    body = ", ".join(f"0x{int(v) & 0xFF:02x}" for v in flat.tolist())
    return (f"#define {count_macro} {flat.size}\n\n"
            f"static const uint8_t {name}[{count_macro}] = {{\n"
            + textwrap.fill(body, width=78, initial_indent="    ",
                            subsequent_indent="    ")
            + "\n};\n")


def i16_array(name: str, values, count_macro: str, *, per_line: int = 12) -> str:
    """A ``static const int16_t`` array, decimal, ``per_line`` values per row.

    Decimal rather than hex on purpose: the values are signed and span
    [-113, 142], and a hex initializer for a signed type would lean on an
    implementation-defined out-of-range conversion -- the same reason
    ``hex_array`` emits ``uint8_t`` and the use site casts.
    """
    flat = np.asarray(values).reshape(-1)
    rows = [", ".join(str(int(v)) for v in flat[i:i + per_line])
            for i in range(0, flat.size, per_line)]
    return (f"#define {count_macro} {flat.size}\n\n"
            f"static const int16_t {name}[{count_macro}] = {{\n"
            + ",\n".join("    " + r for r in rows)
            + "\n};\n")


def i32_array(name: str, values, count_macro: str, *, per_line: int = 4) -> str:
    """A ``static const int32_t`` array, decimal, ``per_line`` values per row."""
    flat = np.asarray(values).reshape(-1)
    rows = [", ".join(str(int(v)) for v in flat[i:i + per_line])
            for i in range(0, flat.size, per_line)]
    return (f"#define {count_macro} {flat.size}\n\n"
            f"static const int32_t {name}[{count_macro}] = {{\n"
            + ",\n".join("    " + r for r in rows)
            + "\n};\n")


def emit_header(out_path: Path, guard: str, generator: str, prose: str,
                bodies, *, verbose: bool = True) -> Path:
    """Write a generated header: banner, guard, bodies, ``#endif``."""
    out_path = Path(out_path)
    text = (_BANNER.format(generator=generator, guard=guard,
                           prose="\n".join(" * " + ln if ln else " *"
                                           for ln in prose.splitlines()))
            + "\n".join(bodies)
            + f"\n#endif /* {guard} */\n")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(text)
    if verbose:
        kb = len(text) / 1024.0
        # Relative to where the USER is standing, not to the repo root. These
        # scripts live in data/ but write one level up, and a repo-relative
        # path printed from inside data/ reads as though it were relative to
        # data/ -- which sends people looking for a header that is not there.
        try:
            shown = os.path.relpath(out_path, Path.cwd())
        except ValueError:                      # different drive (Windows)
            shown = out_path
        print(f"  [write]  {shown}  ({kb:,.0f} KB)")
        print(f"           = {out_path}")
    return out_path
