###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Pattern table: which Relay subgraphs an AIE kernel can take.

The first of the four BYOC files. Its only job is to **declare** that "a
subgraph shaped like this is called ``aie.qconv``"; merging, partitioning, and
host-side compilation/execution are all left to TVM.

The patterns are written against the real IR, not copied from the docs
----------------------------------------------------------------------
After the graph produced by ``onnx_ptq`` goes through
``FakeQuantizationToInteger``, every convolution is a fixed three-op sequence::

    %1 = qnn.conv2d(%0, W, in_zp, k_zp, in_scale, k_scale)   # 6 args
    %2 = nn.bias_add(%1, B)
    %3 = qnn.requantize(%2, in_scale, in_zp, out_scale, out_zp)

This was cross-checked against an actual IR dump (see ``test_aie_byoc.py``), it
is not guesswork. The argument counts were checked against the TVM 0.16
signatures too: ``qnn.conv2d`` takes 6 inputs, ``qnn.requantize`` takes 1 + 4.
Get a single ``is_constant()`` count wrong and ``MergeComposite`` silently fails
to match -- no error, just not a single operator offloaded, which looks exactly
like BYOC never took effect.

``check_qconv`` is the place that should actually be tightened
--------------------------------------------------------------
The pattern only covers the shape; the **constraints** live in the checker. Right
now it only rejects grouped convolution, because the AIE kernel's loop nest
assumes ``groups == 1``. As the range of things the kernel supports changes, this
is the only place that needs to change -- do not go edit the pattern.

Every rejection carries a reason and can optionally be printed
(``AIE_BYOC_DEBUG=1``), because "did not match" and "matched but was rejected"
look identical in the final IR, and you must be able to tell them apart while
debugging.
"""

from __future__ import annotations

import os

from tvm.relay.dataflow_pattern import is_constant, is_op, wildcard

__all__ = ["pattern_table", "qconv_pattern", "check_qconv", "AIE_PATTERN_NAME"]

#: Name of the composite function. After PartitionGraph it shows up in the
#: ``Composite`` attribute, and codegen dispatches on this name.
AIE_PATTERN_NAME = "aie.qconv"

#: The AIE kernel's current hard constraints. Kept as constants rather than
#: scattered through the conditionals, so that when the kernel's capability
#: changes, changing them here is enough.
MAX_KERNEL = 7           # the 7x7 stem is the largest kernel the existing kernel has seen
SUPPORTED_GROUPS = (1,)  # no kernel yet for grouped / depthwise-separable convolution

#: The ONE geometry `libconv2dstem.a` implements: ResNet-18 conv1,
#: ifm[224,224,3] (*) wts[64,7,7,3], stride 2, pad 3 -> ofm[112,112,64].
#:
#: This is not a tunable -- it is baked into conv2dstem.cc three times over (the
#: #defines, the GemmSpace descriptors, and a wall of static_asserts pinning the
#: mesh tiling to 4x4). Offloading any other shape to it would silently compute
#: against the wrong tiling, so the gate is exact-match on every field.
#:
#: Relaxing this means teaching conv2dstem.cc a second geometry first; widening
#: the check alone just moves the failure somewhere harder to see.
#:
#: NOTE the input is 230x230, not 224x224, and the padding is zero. By the time
#: we match, TVM has hoisted the spatial padding out of the conv into a separate
#: `nn.pad`, so the conv sees an already-padded tensor (224 + 2*3 = 230) and
#: carries padding=(0,0,0,0). Checking for 224 + padding=3 matches nothing --
#: measured, not assumed. `conv2d_stem()` wants the UNPADDED 224x224x3 buffer
#: and re-pads internally, so the wrapper passes the pre-pad tensor.
STEM_GEOMETRY = {
    "in_hw": (230, 230),
    "in_c": 3,
    "kernel": (7, 7),
    "strides": (2, 2),
    "padding": (0, 0, 0, 0),
    "out_c": 64,
}

#: When true, accept ONLY the geometry above. The placeholder codegen could
#: stand in for any conv; a real `conv2d_stem()` call cannot.
STEM_ONLY = True


def _debug(msg: str) -> None:
    if os.environ.get("AIE_BYOC_DEBUG"):
        print(f"  [aie-byoc] {msg}")


def qconv_pattern():
    """Quantized convolution **after canonicalization**: ``nn.conv2d(int8, int8) -> int32``.

    What is matched is the form after ``qnn.transform.CanonicalizeOps()`` has
    expanded it, not the ``qnn.conv2d`` form before expansion. This choice was
    forced by TVM 0.16, it is not a preference:

    **We cannot match before expansion.** ``MergeComposite`` lifts the constants
    inside any region it touches into parameters of the composite function, while
    qnn's canonicalization (``RequantizeLower`` / ``QnnAddCanonicalize``) requires
    scale/zero-point to be compile-time Constants, and dies outright when it gets
    a free variable instead:

        InternalError: Check failed: (n) is false: Expr must be a constant expr
          ... GetScalarFromConstant<float>

    This is not a mis-written pattern -- in practice even a **minimal pattern that
    only matches nn.bias_add and does not touch qnn at all** triggers the same
    error, and ``n=0`` (offload nothing at all) fails just the same; running
    ``FoldConstant`` afterwards does not rescue it either.

    **So canonicalize first, then match.** After expansion all 20 ``qnn.conv2d``
    become ``nn.conv2d`` (not one of them lost), with int8 inputs and int32
    output -- exactly the natural input/output form of the AIE kernel. The
    zero-point compensation and the requantize get expanded into ordinary
    operators that stay outside and are done by the host, which actually suits AIE
    better: element-wise fixed-point scaling is not what a tile is good at.

    Quantized convolution is distinguished by dtype rather than by operator name:
    after canonicalization an ``nn.conv2d`` may come from either the quantized or
    the floating-point path, and the int8 check in ``check_qconv`` is the real
    criterion.
    """
    return is_op("nn.conv2d")(wildcard(), is_constant())


def check_qconv(extract) -> bool:
    """Can the AIE kernel really run this convolution? *extract* is the matched
    ``nn.conv2d`` call itself.

    This is the **only** place that distinguishes "quantized convolution" from
    "floating-point convolution": after canonicalization both are called
    ``nn.conv2d``, so all we can look at is the data type. If the weights are not
    int8, this is not the one we want.
    """
    try:
        conv = extract
        attrs = conv.attrs
        assert attrs is not None
    except (AttributeError, IndexError, AssertionError):   # structure does not fit: reject outright, do not guess
        _debug("reject: malformed match, cannot get the nn.conv2d")
        return False

    # Only accept quantized convolution. The AIE kernel is int8; offloading a
    # floating-point convolution there would compute garbage.
    try:
        wdtype = str(conv.args[1].checked_type.dtype)
    except Exception:
        wdtype = str(getattr(getattr(conv.args[1], "data", None), "dtype", "?"))
    if wdtype not in ("int8", "uint8"):
        _debug(f"reject weight dtype={wdtype}: the AIE kernel only does int8")
        return False

    groups = int(getattr(attrs, "groups", 1))
    if groups not in SUPPORTED_GROUPS:
        _debug(f"reject groups={groups}: the AIE kernel assumes groups==1")
        return False

    kernel_size = [int(v) for v in getattr(attrs, "kernel_size", []) or []]
    if kernel_size and max(kernel_size) > MAX_KERNEL:
        _debug(f"reject kernel_size={kernel_size}: exceeds {MAX_KERNEL}x{MAX_KERNEL}")
        return False

    layout = str(getattr(attrs, "data_layout", "NCHW"))
    if layout != "NCHW":
        # We partition before AlterOpLayout, so this should still be NCHW here;
        # if it is not, the partition point has moved, and it is better not to
        # offload at all than to generate a kernel for the wrong layout.
        _debug(f"reject data_layout={layout}: the kernel is generated for NCHW")
        return False

    if STEM_ONLY and not _is_stem_geometry(conv, attrs, kernel_size):
        return False

    _debug(f"accept: groups={groups} kernel_size={kernel_size} layout={layout}")
    return True


def _is_stem_geometry(conv, attrs, kernel_size) -> bool:
    """Exact-match the one convolution `libconv2dstem.a` implements.

    Checked against ``STEM_GEOMETRY`` field by field rather than by "is this the
    first conv", because position in the graph is not a property the kernel
    cares about -- the tiling is. A 3x3 conv that happens to come first would
    still be wrong to send there.
    """
    want = STEM_GEOMETRY
    try:
        in_shape = [int(v) for v in conv.args[0].checked_type.shape]   # NCHW
        w_shape = [int(v) for v in conv.args[1].checked_type.shape]    # [OC,IC,KH,KW]
    except Exception as exc:
        _debug(f"reject: cannot read shapes off the conv ({exc})")
        return False

    if len(in_shape) != 4 or len(w_shape) != 4:
        _debug(f"reject: unexpected rank in={in_shape} w={w_shape}")
        return False

    got = {
        "in_hw": (in_shape[2], in_shape[3]),
        "in_c": in_shape[1],
        "kernel": tuple(kernel_size) if kernel_size else (w_shape[2], w_shape[3]),
        "strides": tuple(int(v) for v in getattr(attrs, "strides", (1, 1))),
        "padding": tuple(int(v) for v in getattr(attrs, "padding", (0, 0, 0, 0))),
        "out_c": w_shape[0],
    }
    for field, expect in want.items():
        if got[field] != expect:
            _debug(f"reject: not the stem -- {field}={got[field]} != {expect}")
            return False

    _debug(f"accept STEM: {got['in_hw']}x{got['in_c']} k{got['kernel']} "
           f"s{got['strides']} p{got['padding']} -> {got['out_c']}ch")
    return True


def pattern_table():
    """The ``[(name, pattern, checker)]`` that ``MergeComposite`` expects."""
    return [(AIE_PATTERN_NAME, qconv_pattern(), check_qconv)]
