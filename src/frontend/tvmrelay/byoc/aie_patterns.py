###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Pattern table: which Relay subgraphs an AIE kernel can take.

The first of the four BYOC files. It declares that "a subgraph shaped like this
is called ``aie.qconv_fused``", and -- through ``extract_fused`` -- what every
constant in it means. Merging and partitioning are left to TVM.

The boundary is the FUSED op, not the bare conv
-----------------------------------------------
The AIE kernel (``conv2d_spatial`` in ``libconv2dstem.a``) implements conv +
bias + zero-point + per-channel requantize + ReLU + uint8 store in one pass,
and that is the only thing it can produce. So the partition must cover exactly
that chain; cutting at the bare ``nn.conv2d`` (the earlier design) asks the AIE
for an int32 accumulator it cannot emit, and the only way to honour that was a
scalar loop on the APU -- an "offload" that never touched the AIE.

Written against the real IR, after ``qnn.transform.CanonicalizeOps`` +
``FoldConstant`` (dumped from the ResNet-18 PT2E/ONNX int8 graph)::

    %5  = nn.pad(%4, 113, pad_width=[..,[3,3],[3,3]])           # outside: zp-padded
    %11 = nn.conv2d(%5, W:int8[64,3,7,7], strides=2, out_dtype=int32)
    %10 = repeat(avg_pool2d(multiply(sum(cast(%5)), 49)), 64)   # sum(x) per window
    %13 = subtract(%11, multiply(C1:[64,1,1], %10))              # weight-zp term
    %14 = add(%13, C2:[1,64,1,1])                                # -in_zp*sum(w) etc.
    %15 = nn.bias_add(%14, C3:[64])
    %16 = cast(%15, int32)                                       # optional
    %17 = subtract(%16, C4:[64,1,1])                             # requantize in-zp
    %18 = fixed_point_multiply_per_axis(%17, C5, C6=lshift, C7=rshift, axes=[1])
    %20 = cast(clip(%18, 0, 255), uint8)

Canonicalize first, then match. Matching ``qnn.*`` directly fails: MergeComposite
lifts the scale/zero-point constants into composite parameters and qnn's own
canonicalization then dies on ``GetScalarFromConstant`` (verified).

``check_fused_qconv`` holds the constraints
-------------------------------------------
The pattern only covers the shape. The checker rejects anything the kernel
cannot reproduce bit-exactly -- a non-zero weight zero-point (C1 makes the
result data-dependent), any left shift, a clip other than [0, 255] -- and,
until the kernel learns more shapes, anything that is not the stem geometry.
Every rejection carries a reason (``AIE_BYOC_DEBUG=1``), because "did not
match" and "matched but rejected" look identical in the final IR.
"""

from __future__ import annotations

import os
from dataclasses import dataclass

import numpy as np
from tvm import relay
from tvm.relay.dataflow_pattern import is_constant, is_op, wildcard

__all__ = ["pattern_table", "fused_qconv_pattern", "check_fused_qconv",
           "extract_fused", "FusedConv", "AIE_PATTERN_NAME", "STEM_GEOMETRY"]

#: Name of the composite function. After PartitionGraph it shows up in the
#: ``Composite`` attribute, and codegen dispatches on this name.
AIE_PATTERN_NAME = "aie.qconv_fused"

#: The ONE geometry `libconv2dstem.a` implements: ResNet-18 conv1,
#: ifm[224,224,3] (*) wts[64,7,7,3], stride 2, pad 3 -> ofm[112,112,64].
#:
#: Baked into conv2dstem.cc three times over (the #defines, the GemmSpace
#: descriptors, and static_asserts pinning the mesh tiling), so the gate is
#: exact-match on every field. NOTE the input is 230x230 with padding 0: TVM
#: hoists the spatial padding into a separate ``nn.pad`` before we match.
STEM_GEOMETRY = {
    "in_hw": (230, 230),
    "in_c": 3,
    "kernel": (7, 7),
    "strides": (2, 2),
    "padding": (0, 0, 0, 0),
    "out_c": 64,
}


def _debug(msg: str) -> None:
    if os.environ.get("AIE_BYOC_DEBUG"):
        print(f"  [aie-byoc] {msg}")


def fused_qconv_pattern():
    """conv -> [- wzp term] -> + C2 -> bias_add -> [cast] -> - C4 -> fpm -> clip -> cast."""
    x = wildcard()
    conv = is_op("nn.conv2d")(x, is_constant())
    win_sum = is_op("repeat")(is_op("nn.avg_pool2d")(
        is_op("multiply")(is_op("sum")(is_op("cast")(x)), is_constant())))
    acc = is_op("subtract")(conv, is_op("multiply")(is_constant(), win_sum)) | conv
    acc = is_op("add")(acc, is_constant())
    acc = is_op("nn.bias_add")(acc, is_constant())
    acc = is_op("cast")(acc) | acc
    acc = is_op("subtract")(acc, is_constant())
    acc = is_op("fixed_point_multiply_per_axis")(
        acc, is_constant(), is_constant(), is_constant())
    return is_op("cast")(is_op("clip")(acc))


@dataclass
class FusedConv:
    """Everything the AIE kernel needs from one matched fused op, as numpy."""

    conv: object               # the nn.conv2d call
    weight: np.ndarray         # int8 [OC, IC, KH, KW]
    wzp: np.ndarray            # int32 [OC] weight zero-point (C1), zeros if absent
    add_c: np.ndarray          # int32 [OC] (C2)
    bias: np.ndarray           # int32 [OC] (C3)
    sub_c: np.ndarray          # int32 [OC] (C4)
    mult: np.ndarray           # int32 [OC] Q31 multiplier (C5)
    lshift: np.ndarray         # int32 [OC] (C6)
    rshift: np.ndarray         # int32 [OC] (C7)
    lshift_required: bool
    clip: tuple                # (a_min, a_max)
    out_dtype: str


def _op_name(e) -> str:
    return e.op.name if isinstance(e, relay.Call) and hasattr(e.op, "name") else ""


def _const(e, oc: int, what: str) -> np.ndarray:
    """A per-output-channel int32 vector from a scalar / [OC] / [OC,1,1] / [1,OC,1,1] const."""
    if not isinstance(e, relay.Constant):
        raise ValueError(f"{what} is not a Constant (run FoldConstant first)")
    a = e.data.numpy()
    if a.size == 1:
        return np.full(oc, int(a.reshape(-1)[0]), np.int64)
    if a.size != oc:
        raise ValueError(f"{what} has {a.size} elements, want 1 or {oc}")
    return a.reshape(-1).astype(np.int64)


def _const_arg(call, what: str):
    """(other_arg, constant) of a binary call, whichever side the constant is on."""
    a, b = call.args
    if isinstance(b, relay.Constant):
        return a, b
    if isinstance(a, relay.Constant):
        return b, a
    raise ValueError(f"{what}: no constant operand")


def extract_fused(root) -> FusedConv:
    """Walk the matched chain from the final cast down to the conv. Raises ValueError.

    Shared by the pattern checker and the codegen, so "what C2 means" is decided
    in exactly one place.
    """
    e = root
    if _op_name(e) != "cast":
        raise ValueError(f"root is {_op_name(e)!r}, want cast")
    out_dtype = str(e.attrs.dtype)
    e = e.args[0]
    if _op_name(e) != "clip":
        raise ValueError("no clip under the final cast")
    clip = (float(e.attrs.a_min), float(e.attrs.a_max))
    fpm = e.args[0]
    if _op_name(fpm) != "fixed_point_multiply_per_axis":
        raise ValueError("no fixed_point_multiply_per_axis under clip")
    if [int(a) for a in fpm.attrs.axes] != [1]:
        raise ValueError(f"fpm axes={list(fpm.attrs.axes)}, want [1] (NCHW channel)")
    e = fpm.args[0]
    if _op_name(e) != "subtract":
        raise ValueError("no requantize input-zp subtract")
    e, c4 = _const_arg(e, "requantize subtract")
    if _op_name(e) == "cast":
        e = e.args[0]
    if _op_name(e) != "nn.bias_add":
        raise ValueError("no nn.bias_add")
    e, c3 = e.args[0], e.args[1]
    if _op_name(e) != "add":
        raise ValueError("no zero-point add")
    e, c2 = _const_arg(e, "zero-point add")
    c1 = None
    if _op_name(e) == "subtract":
        e, term = e.args
        if _op_name(term) != "multiply":
            raise ValueError("weight-zp term is not a multiply")
        _, c1 = _const_arg(term, "weight-zp multiply")
    if _op_name(e) != "nn.conv2d":
        raise ValueError(f"chain ends at {_op_name(e)!r}, want nn.conv2d")
    conv = e
    if not isinstance(conv.args[1], relay.Constant):
        raise ValueError("conv weight is not a Constant")
    weight = conv.args[1].data.numpy()
    oc = int(weight.shape[0])
    return FusedConv(
        conv=conv, weight=weight,
        wzp=_const(c1, oc, "C1 weight-zp") if c1 is not None else np.zeros(oc, np.int64),
        add_c=_const(c2, oc, "C2"), bias=_const(c3, oc, "C3 bias"),
        sub_c=_const(c4, oc, "C4"),
        mult=_const(fpm.args[1], oc, "C5 mult"),
        lshift=_const(fpm.args[2], oc, "C6 lshift"),
        rshift=_const(fpm.args[3], oc, "C7 rshift"),
        lshift_required=bool(fpm.attrs.is_lshift_required),
        clip=clip, out_dtype=out_dtype)


def _stem_geometry_ok(conv) -> bool:
    """Exact-match the one convolution `libconv2dstem.a` implements."""
    attrs = conv.attrs
    try:
        in_shape = [int(v) for v in conv.args[0].checked_type.shape]
        w_shape = [int(v) for v in conv.args[1].checked_type.shape]
    except Exception as exc:
        _debug(f"reject: cannot read shapes off the conv ({exc})")
        return False
    if len(in_shape) != 4 or len(w_shape) != 4:
        _debug(f"reject: unexpected rank in={in_shape} w={w_shape}")
        return False
    got = {
        "in_hw": (in_shape[2], in_shape[3]),
        "in_c": in_shape[1],
        "kernel": (w_shape[2], w_shape[3]),
        "strides": tuple(int(v) for v in attrs.strides),
        "padding": tuple(int(v) for v in attrs.padding),
        "out_c": w_shape[0],
    }
    for field, expect in STEM_GEOMETRY.items():
        if got[field] != expect:
            _debug(f"reject: not the stem -- {field}={got[field]} != {expect}")
            return False
    return True


def check_fused_qconv(root) -> bool:
    """Can ``libconv2dstem.a`` reproduce this fused op bit-exactly?"""
    try:
        f = extract_fused(root)
    except (ValueError, AttributeError, IndexError) as exc:
        _debug(f"reject: {exc}")
        return False
    conv = f.conv
    if int(conv.attrs.groups) != 1 or str(conv.attrs.data_layout) != "NCHW":
        _debug(f"reject: groups={conv.attrs.groups} layout={conv.attrs.data_layout}")
        return False
    try:
        in_dtype = str(conv.args[0].checked_type.dtype)
    except Exception:
        in_dtype = "?"
    if in_dtype != "uint8" or str(f.weight.dtype) != "int8":
        _debug(f"reject: dtypes in={in_dtype} w={f.weight.dtype}, want uint8 x int8")
        return False
    if f.wzp.any():
        _debug("reject: non-zero weight zero-point -- the result depends on sum(x)")
        return False
    if f.lshift_required or f.lshift.any():
        _debug("reject: left shift in the requantize -- the kernel only right-shifts")
        return False
    if (f.rshift < 0).any():
        _debug("reject: negative right shift")
        return False
    if f.clip != (0.0, 255.0) or f.out_dtype != "uint8":
        _debug(f"reject: clip={f.clip} out={f.out_dtype}, want [0,255] -> uint8")
        return False
    if not _stem_geometry_ok(conv):
        return False
    _debug("accept: stem fused qconv")
    return True


def pattern_table():
    """The ``[(name, pattern, checker)]`` that ``MergeComposite`` expects."""
    return [(AIE_PATTERN_NAME, fused_qconv_pattern(), check_fused_qconv)]
