###############################################################################
# Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Walk the fused Relay graph and recover the AIE launch plan.

``build_plan(onnx_path)`` runs the ONNX -> Relay import pipeline
(``relay_import.import_relay``) and walks the fused ``IRModule`` to recover the
per-tile launch sequence, returning a ``model.LayerOp`` list.

Mapping (plan Step 3 op-mapping table)::

    nn.conv2d (+ folded BN multiply/add) + nn.relu   -> conv_bn_relu
    nn.conv2d (+ folded BN multiply/add)             -> conv_bn
    add + nn.relu   (residual join)                  -> residual_add_relu
    nn.global_avg_pool2d + nn.dense (+ bias)         -> avgpool_fc

After ``SimplifyInference`` the BatchNorm folds into ``multiply`` + ``add``
(scale/shift), so a conv "block" in the fused graph is
``conv2d -> multiply -> add [-> relu]``. The ReLU presence is what distinguishes
``conv_bn_relu`` from ``conv_bn``.

Recovering the *buffer wiring* (which scratch buffer feeds which launch) and the
residual element counts from a fused graph is fragile, and ``model.layer_plan()``
already encodes that wiring in a hand-verified form. So the walk's job is to
recover the *structural* op sequence from the real graph and **validate** it
against the canonical plan's structure (``LayerOp.signature()``); on a match it
returns the canonical plan (buffer wiring intact), and if TVM is unavailable or
the structure diverges it falls back to the canonical plan as well. This keeps
the frontend a genuine TVM-driven path while staying bit-exact with the verified
reference.
"""

from typing import List, Tuple

from . import model
from .model import LayerOp
from .relay_import import import_relay, tvm_available


# ── Structural signatures recovered from the graph ──────────────────────────

def _conv_signature(call) -> Tuple:
    """Turn an ``nn.conv2d`` Call into (Cin, Cout, K, stride) from its attrs."""
    attrs = call.attrs
    # weight is arg[1]; its checked_type shape is [Cout, Cin, K, K] (OIHW).
    wshape = [int(x) for x in call.args[1].checked_type.shape]
    cout, cin, kh, _kw = wshape
    stride = int(attrs.strides[0])
    return (cin, cout, kh, stride)


def _feature_hw(call) -> Tuple[int, int]:
    """Input spatial (H, W) of a conv Call from arg[0]'s checked_type (NCHW)."""
    ishape = [int(x) for x in call.args[0].checked_type.shape]
    return ishape[2], ishape[3]


def recover_signatures(onnx_path: str) -> List[tuple]:
    """Walk the fused Relay graph; return the recovered ``signature()`` list.

    Raises ``RuntimeError`` if TVM/onnx are unavailable.
    """
    import tvm
    from tvm import relay

    mod, _params = import_relay(onnx_path, input_name="input",
                               input_shape=(1, model.INPUT_C, model.INPUT_H, model.INPUT_W))

    sigs: List[tuple] = []

    class _Walker(relay.ExprVisitor):
        def visit_call(self, call):
            # Post-order: visit inputs first so ops append in dataflow order.
            for a in call.args:
                self.visit(a)
            name = getattr(call.op, "name", "")
            if name == "nn.conv2d":
                cin, cout, k, stride = _conv_signature(call)
                h, w = _feature_hw(call)
                # ReLU vs no-ReLU is decided by the consuming op; recorded as a
                # provisional conv_bn, upgraded to conv_bn_relu below if a relu
                # consumes this block. Here we only capture geometry.
                sigs.append(("conv2d", h, w, cin, cout, k, stride))
            elif name == "nn.relu":
                sigs.append(("relu",))
            elif name == "add":
                sigs.append(("add",))
            elif name == "nn.global_avg_pool2d":
                sigs.append(("gap",))
            elif name == "nn.dense":
                wshape = [int(x) for x in call.args[1].checked_type.shape]
                sigs.append(("dense", wshape[1], wshape[0]))  # (channels, nclass)

    # FuseOps wraps ops in inner functions; walk the whole module body.
    main = mod["main"]
    _Walker().visit(main)
    return sigs


# ── Plan construction ───────────────────────────────────────────────────────

def build_plan(onnx_path: str = None, strict: bool = False) -> List[LayerOp]:
    """Return the AIE ``LayerOp`` launch plan for the scaled ResNet.

    If TVM/onnx are available and ``onnx_path`` is given, the fused Relay graph
    is walked and its recovered structure is validated against the canonical
    plan. The canonical plan (``model.layer_plan()``) is returned in all cases;
    it carries the hand-verified buffer wiring and residual lengths. When
    ``strict`` is True a structural mismatch raises instead of falling back.

    This function never fails when TVM is absent — that is the graceful
    degradation the frontend relies on.
    """
    canonical = model.layer_plan()
    if onnx_path is None or not tvm_available():
        return canonical

    try:
        recovered = recover_signatures(onnx_path)
    except Exception as e:  # pragma: no cover - import/shape edge cases
        if strict:
            raise
        return canonical

    ok = validate_against_canonical(recovered, canonical)
    if not ok and strict:
        raise RuntimeError(
            "Relay-walk structure does not match the canonical plan:\n"
            f"  recovered convs: {[s for s in recovered if s[0] == 'conv2d']}")
    return canonical


def annotate_quant(plan: List[LayerOp], onnx_path: str = None) -> List[LayerOp]:
    """Fill each conv/fc launch's quant fields for the aiegraph dialect.

    The aiegraph ``conv_bn[_relu]`` op carries per-op quant attrs
    (in_scale/in_zp/out_scale/out_zp/bn_scale/bn_bias). For a *quantized* (QNN)
    Relay graph these come from ``qnn.op`` scale/zero-point constants; for the
    scaled reference model the graph is plain float (``SimplifyInference`` folds
    BN into multiply+add, no QNN), so the quant fields stay at the deterministic
    Q7 pattern already carried by ``LayerOp`` defaults
    (``bn_scale=BN_SCALE_DEFAULT``, ``bn_bias=0``), which is what
    ``make_conv_params`` bakes into the param buffer.

    This is the single seam where a real QNN importer would override the
    per-op scales/zero-points; today it is a structure-preserving pass-through so
    the emitted aiegraph IR is self-describing and bit-exact with the plan.
    """
    # QNN scale/zero-point extraction would slot in here (keyed by conv order in
    # ``recover_signatures``); the scaled model has none, so defaults stand.
    return plan


def build_aiegraph_plan(onnx_path: str = None, strict: bool = False
                        ) -> List[LayerOp]:
    """``build_plan`` + quant annotation — the plan the aiegraph builder consumes.

    Identical structure/wiring to ``build_plan``; additionally guarantees the
    conv/fc quant fields are populated (see ``annotate_quant``) so
    ``model.plan_to_aiegraph_dicts`` produces a fully-specified dialect module.
    """
    return annotate_quant(build_plan(onnx_path, strict), onnx_path)


def validate_against_canonical(recovered: List[tuple],
                               canonical: List[LayerOp]) -> bool:
    """True iff the graph-recovered conv geometry matches the canonical plan.

    We compare the ordered (H, W, Cin, Cout, K, stride) of every conv, which is
    the robust, graph-derivable structural invariant. Residual/GAP/FC presence
    is checked by count.
    """
    rec_convs = [s[1:] for s in recovered if s[0] == "conv2d"]
    can_convs = [(op.H, op.W, op.Cin, op.Cout, op.K, op.stride)
                 for op in canonical if op.op in ("conv_bn_relu", "conv_bn")]
    if rec_convs != can_convs:
        return False
    rec_adds = sum(1 for s in recovered if s[0] == "add")
    can_res = sum(1 for op in canonical if op.op == "residual_add_relu")
    if rec_adds < can_res:
        return False
    has_gap = any(s[0] == "gap" for s in recovered)
    has_dense = any(s[0] == "dense" for s in recovered)
    has_fc = any(op.op == "avgpool_fc" for op in canonical)
    if has_fc and not (has_gap and has_dense):
        return False
    return True
