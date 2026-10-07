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
import sys
import textwrap
from dataclasses import dataclass
from pathlib import Path

import numpy as np

__all__ = ["StemParams", "REPO", "DATA_DIR", "OUT_DIR", "DEFAULT_IMAGE",
           "resolve_qdq_model", "load_stem_params", "fixed_point",
           "fold_qparams", "preprocess_to_pad4", "pad4_to_hwc3",
           "emit_header", "hex_array", "i32_array"]

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
