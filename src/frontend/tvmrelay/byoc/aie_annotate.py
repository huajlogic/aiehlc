###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Annotation pass: hand the SELECTED matched composite functions to AIE.

The second of the four BYOC files. ``AnnotateTarget`` offloads everything that
matches; ``--aie-offload --aie-layers`` asks for specific layers, so this pass
inserts ``compiler_begin``/``compiler_end`` itself, around the composites whose
conv was selected. ``MergeCompilerRegions`` + ``PartitionGraph`` then work as
usual.

A conv is identified by its WEIGHTS, not its position
-----------------------------------------------------
Relay's post-order and the graph executor's order are NOT the same: in every
ResNet downsampling block TVM fuses the 1x1 shortcut conv with the residual
add, so it runs after the main branch, while Relay's post-order visits it
first (convs 5-7, 10-12, 15-17 swap -- measured). Any "n-th conv" numbering is
therefore wrong on one side. ``weight_fingerprint`` -- a hash of the SORTED
weight values -- is layout-independent (the CPU build stores the same weights
as NCHWc-blocked int16) and unique for all 20 ResNet-18 convs, so
``aie_offload.resolve_conv_targets`` selects by it.

The boundary goes on the composite function, not on individual operators
-----------------------------------------------------------------------
``compiler_begin`` wraps the composite's inputs and ``compiler_end`` its output.
Marking individual operators inside it would tear the fused kernel apart again.
"""

from __future__ import annotations

import hashlib

import numpy as np
from tvm import relay
from tvm.relay.op.annotation import compiler_begin, compiler_end

__all__ = ["ConvSelectAnnotator", "AIE_COMPILER_NAME", "weight_fingerprint"]

#: The codegen name registered with TVM. It must match the registration name of
#: ``relay.ext.<name>``, otherwise after PartitionGraph TVM cannot find the
#: backend and reports "No compiler registered".
AIE_COMPILER_NAME = "aie"


def weight_fingerprint(weights) -> str:
    """Layout- and dtype-independent identity of a conv: hash of its sorted weights."""
    a = np.sort(np.asarray(weights).astype(np.int64).reshape(-1))
    return hashlib.sha1(a.tobytes()).hexdigest()


def _conv_geometry(conv) -> dict:
    """(Cin, Cout, K, stride) of an nn.conv2d -- read off the constant weight and
    attrs, so it works on freshly rebuilt nodes that carry no checked_type."""
    w = conv.args[1]
    shape = [int(d) for d in (w.data.shape if isinstance(w, relay.Constant)
                              else w.checked_type.shape)]
    return {"Cin": shape[1], "Cout": shape[0], "K": shape[2],
            "stride": int(conv.attrs.strides[0])}


def _find_conv(expr):
    found = []
    relay.analysis.post_order_visit(
        expr, lambda e: found.append(e) if isinstance(e, relay.Call)
        and getattr(e.op, "name", "") == "nn.conv2d" else None)
    return found[0] if found else None


class ConvSelectAnnotator(relay.ExprMutator):
    """Mark the ``Composite`` functions whose conv weight fingerprint is in *selected*
    (``None``: every composite the pattern accepted).

    Composites that are not selected are inlined back (see ``visit_call``).
    ``convs`` records ``{fingerprint, geometry, composite, offloaded}`` for
    every conv -- matched or not -- for the caller to verify.
    """

    def __init__(self, selected, pattern_name: str,
                 compiler: str = AIE_COMPILER_NAME):
        super().__init__()
        self.selected = None if selected is None else set(selected)
        self.compiler = compiler
        self.pattern_name = pattern_name
        self.convs = []

    def _is_target_composite(self, op) -> bool:
        if not isinstance(op, relay.Function):
            return False
        comp = op.attrs["Composite"] if op.attrs and "Composite" in op.attrs else None
        return comp is not None and str(comp) == self.pattern_name

    def _record(self, conv, composite: bool, offloaded: bool) -> None:
        self.convs.append({"fingerprint": self._fingerprint(conv),
                           **_conv_geometry(conv),
                           "composite": composite, "offloaded": offloaded})

    @staticmethod
    def _fingerprint(conv):
        w = conv.args[1]
        return weight_fingerprint(w.data.numpy()) if isinstance(w, relay.Constant) else None

    def visit_call(self, call):
        new_args = [self.visit(a) for a in call.args]
        op = call.op

        if not self._is_target_composite(op):
            if getattr(op, "name", "") == "nn.conv2d":
                self._record(call, composite=False, offloaded=False)
            return relay.Call(self.visit(op) if isinstance(op, relay.Function) else op,
                              new_args, call.attrs, call.type_args, call.span)

        conv = _find_conv(op.body)
        take = self.selected is None or self._fingerprint(conv) in self.selected
        self._record(conv, composite=True, offloaded=take)
        if not take:
            # Inline the composite back. A Composite function left in main has
            # neither a Compiler nor a Primitive attribute, and TECompiler dies:
            #   Check failed: (prim_fns) is false: primitive functions not set
            # Inlining = bind the params to the args, then take the body.
            return relay.bind(op.body, dict(zip(op.params, new_args)))

        begins = [compiler_begin(a, self.compiler) for a in new_args]
        out = relay.Call(op, begins, call.attrs, call.type_args, call.span)
        return compiler_end(out, self.compiler)

    @property
    def annotated(self) -> int:
        return sum(1 for c in self.convs if c["offloaded"])

    def report(self) -> str:
        """One-line summary the caller can print directly."""
        matched = sum(1 for c in self.convs if c["composite"])
        return (f"annotated {self.annotated} {self.pattern_name} for AIE "
                f"({'all' if self.selected is None else len(self.selected)} conv(s) selected; "
                f"{matched}/{len(self.convs)} convs match the pattern)")
