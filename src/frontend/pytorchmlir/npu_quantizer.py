###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""``NPUQuantizer`` -- a PT2E quantizer for a spatial int8 NPU.

The scheme matches what ``src/frontend/tvmrelay/onnx_ptq.py`` produces through
onnxruntime, so the two frontends quantize the same network the same way and
their MLIR/C output stays comparable:

==================  ==========================================================
weights             symmetric int8, **per-channel** (``ch_axis=0``), zp = 0
activations         **asymmetric** int8 (affine, non-zero zero-point)
bias                left in fp32 -- the integer conv accumulates in int32
==================  ==========================================================

Why not subclass ``XNNPACKQuantizer``
-------------------------------------
It is the obvious base, and it is a trap. In torchao 0.18 it lives at
``torchao/testing/pt2e/_xnnpack_quantizer.py`` -- a private module inside a
``testing`` package -- and it warns ``XNNPACKQuantizer is deprecated!`` on
construction. Its config also encodes XNNPACK's kernel constraints, not a
spatial NPU's. So this subclasses the public ``Quantizer`` ABC directly and
annotates the patterns this target cares about.

Annotation order is load-bearing
--------------------------------
Patterns are tried longest-first (``conv+bn+relu`` before ``conv+bn`` before
``conv``) and every node that gets annotated is recorded, so a later, shorter
pattern cannot re-annotate a node that a longer one already claimed. Without
that, ``conv`` would overwrite the fused ``conv+relu`` annotation and the ReLU
would land outside the quantized region.
"""

from __future__ import annotations

from typing import Optional

from .torch_deps import pt2e_api

__all__ = [
    "ANNOTATED_PATTERNS",
    "make_npu_quantizer",
    "npu_quantization_config",
]

#: Weight range. ``-127`` rather than ``-128`` keeps the range symmetric about
#: zero, which is what a symmetric (zp = 0) scale assumes -- the same choice
#: ``onnx_ptq`` makes via ``QuantType.QInt8``.
WEIGHT_QMIN, WEIGHT_QMAX = -127, 127

#: Activation range. Full int8; the zero-point carries the asymmetry.
ACT_QMIN, ACT_QMAX = -128, 127

#: The exact keys :func:`make_npu_quantizer`'s ``counts`` can contain, longest
#: pattern first -- the order *is* the behavior (see the module docstring).
#:
#: There is deliberately no ``"conv2d + bn + relu"`` entry: PT2E folds BatchNorm
#: into the preceding conv *before* annotation runs, so by the time these
#: patterns are matched a conv's user is the relu directly and a bn-fused
#: pattern can never occur.
ANNOTATED_PATTERNS = (
    "conv2d + relu",
    "conv2d",
    "linear",
    "add + relu",
    "add",
    "adaptive_avg_pool2d",
)


def _annotation_symbol(api, name: str):
    """Fetch *name* from the resolved PT2E tree, or fail with a useful message.

    Going through ``pt2e_api()`` rather than importing ``torchao...`` directly is
    the whole point: a hardcoded import crashes on exactly the ``torch.ao``
    fallback the resolver exists to provide, and it crashes *after* stage 1 has
    already reported the environment as healthy.
    """
    symbol = api.annotation.get(name)
    if symbol is None:
        raise RuntimeError(
            f"{name} not found in the {api.provenance} PT2E tree "
            f"(have: {sorted(api.annotation)}). This frontend needs a tree that "
            f"exposes the annotation helpers.")
    return symbol


def npu_quantization_config(per_channel: bool = True,
                            observer: str = "histogram"):
    """A ``QuantizationConfig`` for this target.

    *observer* picks the **activation** observer: ``"histogram"`` (default,
    minimizes quantization error over the calibration set) or ``"minmax"``
    (cheaper, and what ONNX PTQ's ``CalibrationMethod.MinMax`` uses -- pick it
    when comparing against the tvmrelay path). Weights always use a min/max
    observer; a histogram over weights buys nothing because they are static.
    """
    import torch

    api = pt2e_api()
    obs = api.observers
    QuantizationConfig = _annotation_symbol(api, "QuantizationConfig")

    act_ctr = obs.get("HistogramObserver") if observer == "histogram" else None
    if act_ctr is None:
        act_ctr = obs.get("MinMaxObserver")
    if act_ctr is None:
        raise RuntimeError(f"no activation observer available (have: {sorted(obs)})")

    # Asymmetric activations: affine qscheme, so the observer is free to place a
    # non-zero zero-point. This is the half of the scheme relay.quantize cannot
    # express at all (see tvmrelay/README.md).
    act_spec = api.QuantizationSpec(
        dtype=torch.int8,
        quant_min=ACT_QMIN,
        quant_max=ACT_QMAX,
        qscheme=torch.per_tensor_affine,
        is_dynamic=False,
        observer_or_fake_quant_ctr=act_ctr.with_args(eps=2 ** -12),
    )

    if per_channel:
        w_obs = obs.get("PerChannelMinMaxObserver")
        if w_obs is None:
            raise RuntimeError("PerChannelMinMaxObserver missing; use per_channel=False")
        weight_spec = api.QuantizationSpec(
            dtype=torch.int8,
            quant_min=WEIGHT_QMIN,
            quant_max=WEIGHT_QMAX,
            qscheme=torch.per_channel_symmetric,
            ch_axis=0,  # output channels -- one scale per filter
            is_dynamic=False,
            observer_or_fake_quant_ctr=w_obs.with_args(eps=2 ** -12),
        )
    else:
        weight_spec = api.QuantizationSpec(
            dtype=torch.int8,
            quant_min=WEIGHT_QMIN,
            quant_max=WEIGHT_QMAX,
            qscheme=torch.per_tensor_symmetric,
            is_dynamic=False,
            observer_or_fake_quant_ctr=obs["MinMaxObserver"].with_args(eps=2 ** -12),
        )

    # bias=None keeps bias in fp32. The integer convolution accumulates into
    # int32, and a quantized bias would have to be re-scaled to the accumulator
    # scale -- extra constraint, no benefit on this target.
    return QuantizationConfig(act_spec, act_spec, weight_spec, None, is_qat=False)


# ═══════════════════════════════════════════════════════════════════════════
#  Annotation passes
# ═══════════════════════════════════════════════════════════════════════════
#
# Module-level rather than methods, because the class they serve must be built
# inside make_npu_quantizer (see its docstring). Each takes the quantizer `q`
# for its claim/count bookkeeping and `s` -- the resolved PT2E symbols -- so no
# torch import happens at module scope.


def _single_user(node):
    """The sole consumer of *node*, or ``None`` when it has several."""
    users = list(node.users)
    return users[0] if len(users) == 1 else None


def _is_call_to(node, targets) -> bool:
    return node.op == "call_function" and node.target in targets


def _annotate_convs(q, gm, s) -> None:
    """conv (+ relu). Longest pattern first, so bare conv cannot steal a relu."""
    import torch

    convs = (torch.ops.aten.conv2d.default, torch.ops.aten.convolution.default)
    relus = (torch.ops.aten.relu.default, torch.ops.aten.relu_.default)

    for conv in [n for n in gm.graph.nodes if _is_call_to(n, convs)]:
        if not q._free([conv]):
            continue
        user = _single_user(conv)
        # export_for_training keeps BN as its own node, but PT2E folds conv+bn
        # before annotation runs -- so by now a conv's user is the relu directly
        # and there is no separate conv+bn+relu pattern to match.
        if user is not None and _is_call_to(user, relus) and q._free([user]):
            _annotate_conv(q, conv, user, "conv2d + relu", s)
        else:
            _annotate_conv(q, conv, conv, "conv2d", s)


def _annotate_conv(q, node, output_node, pattern: str, s) -> None:
    """Annotate conv *node*, placing the output qspec on *output_node*.

    When the conv is fused with a following relu the quantized region ends at
    the relu, so the conv itself gets no output annotation.
    """
    act, weight = node.args[0], node.args[1]
    node.meta[s["key"]] = s["Annotation"](
        input_qspec_map={act: s["in_q"](q.config), weight: s["w_q"](q.config)},
        output_qspec=s["out_q"](q.config) if output_node is node else None,
        _annotated=True,
    )
    if output_node is not node:
        output_node.meta[s["key"]] = s["Annotation"](
            output_qspec=s["out_q"](q.config), _annotated=True)
    q._claim([node, output_node])
    q._bump(pattern)


def _annotate_linear(q, gm, s) -> None:
    import torch

    for node in gm.graph.nodes:
        if (not _is_call_to(node, (torch.ops.aten.linear.default,))
                or not q._free([node])):
            continue
        act, weight = node.args[0], node.args[1]
        node.meta[s["key"]] = s["Annotation"](
            input_qspec_map={act: s["in_q"](q.config),
                             weight: s["w_q"](q.config)},
            output_qspec=s["out_q"](q.config),
            _annotated=True,
        )
        q._claim([node])
        q._bump("linear")


def _annotate_residual(q, gm, s) -> None:
    """``add`` (+ optional ``relu``) -- the ResNet skip join.

    Both addends share the *input* spec so the two branches arrive on a common
    scale. Annotated separately, the skip path would requantize on its own scale
    and drift from the residual path.
    """
    import torch
    from torch.fx import Node

    adds = (torch.ops.aten.add.Tensor, torch.ops.aten.add_.Tensor)
    relus = (torch.ops.aten.relu.default, torch.ops.aten.relu_.default)

    for node in gm.graph.nodes:
        if not _is_call_to(node, adds) or not q._free([node]):
            continue
        lhs, rhs = node.args[0], node.args[1]
        if not (isinstance(lhs, Node) and isinstance(rhs, Node)):
            continue  # add with a scalar is not a residual join

        user = _single_user(node)
        fused = user is not None and _is_call_to(user, relus) and q._free([user])
        out_node = user if fused else node

        act = s["in_q"](q.config)
        node.meta[s["key"]] = s["Annotation"](
            input_qspec_map={lhs: act, rhs: act},
            output_qspec=None if fused else s["out_q"](q.config),
            _annotated=True,
        )
        if fused:
            out_node.meta[s["key"]] = s["Annotation"](
                output_qspec=s["out_q"](q.config), _annotated=True)
        q._claim([node, out_node])
        q._bump("add + relu" if fused else "add")


def _annotate_pool(q, gm, s) -> None:
    """``adaptive_avg_pool2d`` -- output shares the input's scale.

    Average pooling is scale-preserving, so re-observing its output would invent
    a second scale for the same data.
    """
    import torch
    from torch.fx import Node

    pools = (torch.ops.aten.adaptive_avg_pool2d.default, torch.ops.aten.mean.dim)
    for node in gm.graph.nodes:
        if not _is_call_to(node, pools) or not q._free([node]):
            continue
        src = node.args[0]
        if not isinstance(src, Node):
            continue
        node.meta[s["key"]] = s["Annotation"](
            input_qspec_map={src: s["in_q"](q.config)},
            output_qspec=s["Shared"]((src, node)),
            _annotated=True,
        )
        q._claim([node])
        q._bump("adaptive_avg_pool2d")


# ═══════════════════════════════════════════════════════════════════════════
#  The quantizer
# ═══════════════════════════════════════════════════════════════════════════

def make_npu_quantizer(per_channel: bool = True, observer: str = "histogram"):
    """Build an ``NPUQuantizer`` bound to the resolved PT2E API.

    The class is defined **inside** this function on purpose. Subclassing the
    ``Quantizer`` ABC at module scope would require resolving it -- and so
    importing torch -- just to *import* this module, which would break the
    torch-free unit tests and make a missing-dependency failure surface as an
    import error far from its cause.
    """
    api = pt2e_api()

    # One bundle of resolved symbols, threaded into the annotation passes. They
    # come from whichever PT2E tree answered -- never a hardcoded torchao path,
    # which would crash on exactly the torch.ao fallback the resolver provides.
    syms = {
        "Annotation": api.QuantizationAnnotation,
        "Shared": _annotation_symbol(api, "SharedQuantizationSpec"),
        "in_q": _annotation_symbol(api, "get_input_act_qspec"),
        "out_q": _annotation_symbol(api, "get_output_act_qspec"),
        "w_q": _annotation_symbol(api, "get_weight_qspec"),
        "key": _annotation_symbol(api, "Q_ANNOTATION_KEY"),
    }

    Base = api.Quantizer
    config = npu_quantization_config(per_channel=per_channel, observer=observer)

    class _NPUQuantizer(Base):
        """See :class:`NPUQuantizer`."""

        def __init__(self, cfg):
            super().__init__()
            self.config = cfg
            #: Nodes already claimed by a longer pattern. Keyed by node name so
            #: it survives the graph mutations annotation performs.
            self._claimed: set = set()
            #: Per-pattern annotation counts, reported by the flow.
            self.counts: dict = {}

        # -- helpers ----------------------------------------------------- #

        def _free(self, nodes) -> bool:
            """True when no node in *nodes* has been annotated yet."""
            return all(n.name not in self._claimed for n in nodes)

        def _claim(self, nodes) -> None:
            for n in nodes:
                self._claimed.add(n.name)

        def _bump(self, pattern: str) -> None:
            self.counts[pattern] = self.counts.get(pattern, 0) + 1

        def _annotate_conv(self, node, output_node, pattern: str) -> None:
            """Annotate *node* (a conv) with its output taken from *output_node*.

            When conv is fused with a following relu, the quantized region ends
            at the relu, so the output qspec goes there and the conv itself gets
            no output annotation.
            """
            act, weight = node.args[0], node.args[1]
            qmap = {
                act: get_input_act_qspec(self.config),
                weight: get_weight_qspec(self.config),
            }
            node.meta[Q_ANNOTATION_KEY] = QuantizationAnnotation(
                input_qspec_map=qmap,
                _annotated=True,
                # output is annotated on output_node when they differ
                output_qspec=(get_output_act_qspec(self.config)
                              if output_node is node else None),
            )
            if output_node is not node:
                output_node.meta[Q_ANNOTATION_KEY] = QuantizationAnnotation(
                    output_qspec=get_output_act_qspec(self.config),
                    _annotated=True,
                )
            self._claim([node, output_node])
            self._bump(pattern)

        # -- Quantizer ABC ------------------------------------------------ #

        def annotate(self, model):
            """Annotate *model* in place, longest patterns first."""
            for pass_fn in (_annotate_convs, _annotate_linear,
                            _annotate_residual, _annotate_pool):
                pass_fn(self, model, syms)
            return model

        def validate(self, model) -> None:
            """No extra constraints beyond what ``prepare_pt2e`` enforces."""
            return None

    inst = _NPUQuantizer(config)
    inst.__class__.__name__ = "NPUQuantizer"
    return inst
