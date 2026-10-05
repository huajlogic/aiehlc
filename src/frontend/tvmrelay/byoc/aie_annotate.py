###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Annotation pass: hand only the **first N** matched composite functions to AIE.

The second of the four BYOC files. The default behaviour of ``AnnotateTarget``
is "offload everything that matches", whereas what we want here is "get the
first 5 layers working first" -- so we write our own mutator that counts in
**program order** up to the N-th one.

Why not ``AnnotateTarget``
--------------------------
``AnnotateTarget(["aie"])`` only knows "do I support this operator", it has no
notion of counting. To limit the count you have to insert
``compiler_begin``/``compiler_end`` yourself, which is exactly what this pass
does. Once they are inserted, ``MergeCompilerRegions`` + ``PartitionGraph`` work
as usual; TVM does not care who inserted the markers.

Program order == execution order
--------------------------------
``ExprMutator`` traverses Relay's nested let/call structure in post-order, and
for this model the visiting order is the dataflow order: the 0th composite
visited is the stem conv. So "the first N" is equivalent here to "the first N
layers of the network", with no extra sorting needed.

The boundary goes on the composite function, not on individual operators
-----------------------------------------------------------------------
``compiler_begin`` wraps the composite function's **inputs**, ``compiler_end``
wraps its **output**. Inserting the markers on individual operators inside the
composite would tear a kernel in half at partition time -- the three ops that
``MergeComposite`` just fused get split apart again, and the generated subgraph
is neither a complete convolution nor pure CPU.
"""

from __future__ import annotations

from tvm import relay
from tvm.relay.op.annotation import compiler_begin, compiler_end

__all__ = ["FirstNAnnotator", "AIE_COMPILER_NAME"]

#: The codegen name registered with TVM. It must match the registration name of
#: ``relay.ext.<name>``, otherwise after PartitionGraph TVM cannot find the
#: backend and reports "No compiler registered".
AIE_COMPILER_NAME = "aie"


class FirstNAnnotator(relay.ExprMutator):
    """Attach AIE begin/end markers to the first *n* ``Composite`` functions.

    ``n=None`` means no limit (offload everything that matched); ``n=0`` means
    offload nothing, which is a useful control group -- the rest of the flow is
    completely identical, only there is no AIE subgraph.

    The counter is only incremented on **acceptance**, so N means "the number
    actually offloaded", not "the number looked at".
    """

    def __init__(self, n=None, compiler: str = AIE_COMPILER_NAME,
                 pattern_name: str = "aie.qconv"):
        super().__init__()
        self.n = n
        self.compiler = compiler
        self.pattern_name = pattern_name
        self.annotated = 0          # number actually offloaded
        self.skipped = 0            # matched but beyond N

    def _is_target_composite(self, op) -> bool:
        """Is this callee the composite function we are after."""
        if not isinstance(op, relay.Function):
            return False
        comp = op.attrs["Composite"] if op.attrs and "Composite" in op.attrs else None
        return comp is not None and str(comp) == self.pattern_name

    def visit_call(self, call):
        # Recurse into the children first, so that the counting order is the
        # dataflow order (post-order).
        new_args = [self.visit(a) for a in call.args]
        op = call.op

        if not self._is_target_composite(op):
            return relay.Call(self.visit(op) if isinstance(op, relay.Function) else op,
                              new_args, call.attrs, call.type_args, call.span)

        if self.n is not None and self.annotated >= self.n:
            self.skipped += 1
            # Crucial: **inline back** the composite functions that were not
            # selected, instead of leaving them as they are.
            #
            # A Composite function produced by MergeComposite only has a home if
            # it gets offloaded by BYOC; left in the main graph it has neither a
            # Compiler attribute nor a Primitive attribute, and TECompiler dies
            # when it reaches it:
            #
            #   TVMError: Check failed: (prim_fns) is false:
            #     primitive functions not set on Relay function by TECompiler
            #
            # This error has nothing to do with how many are offloaded -- in
            # practice n=0 (offload nothing at all) fails just the same, because
            # MergeComposite still wrapped all 20 convolutions into composites.
            # So anything not offloaded must be restored to its original operator
            # sequence and handed back to TVM to compile normally.
            # Inlining = bind the parameters to the arguments and then take the
            # function body, not Call(op.body, args) (the body is an expression,
            # not something callable).
            return relay.bind(op.body, dict(zip(op.params, new_args)))

        # Wrap the whole composite function: compiler_begin on every input,
        # compiler_end on the output.
        begins = [compiler_begin(a, self.compiler) for a in new_args]
        out = relay.Call(op, begins, call.attrs, call.type_args, call.span)
        self.annotated += 1
        return compiler_end(out, self.compiler)

    def report(self) -> str:
        """A one-line plain-language summary the caller can print directly."""
        limit = "all" if self.n is None else str(self.n)
        tail = f", plus {self.skipped} matched but over the limit" if self.skipped else ""
        return f"annotated {self.annotated} {self.pattern_name} for AIE offload (limit {limit}){tail}"
