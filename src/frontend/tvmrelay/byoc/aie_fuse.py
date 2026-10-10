###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Step 1 of the BYOC flow: FUSE every layer into a named composite function.

``deploy_flow --aie-offload`` runs four steps, and only this one is TVM's:

1. **fuse** -- ``MergeComposite`` wraps each matching layer into
   ``aie.qconv_fused`` (this file);
2. **select** -- ``aie_annotate`` assigns ``aie.layer_id`` and decides what goes
   to the AIE;
3. **partition** -- ``MergeCompilerRegions`` + ``PartitionGraph`` cut the
   selected composites out as ``Compiler="aie"`` functions (``aie_byoc``);
4. **codegen** -- ``relay.ext.aie`` dispatches on the composite name
   (``aie_codegen``).

Fusion is geometry-agnostic ON PURPOSE
--------------------------------------
This used to live inside ``partition_for_aie``, with the stem geometry gate in
the ``MergeComposite`` checker -- so the only layer that ever fused was the one
layer the AIE could already run, and fusing and offloading were one decision.
Splitting them buys three things: a layer that cannot be offloaded can still be
named and explained, the inline-back path in ``aie_annotate`` becomes real
rather than unreachable, and "what would it take to run layer 7" has somewhere
to stand. What the kernel can actually execute is ``aie_patterns.kernel_can_run``,
asked in step 2.

Beware the OTHER "fuse"
-----------------------
TVM's own ``FuseOps`` (``build_module.cc``, last pass before codegen) is TE-level
operator fusion and has nothing to do with this. It necessarily runs AFTER
partitioning, inside the second ``relay.build``, so that it only fuses what
stayed on the CPU. Reordering the two is not a thing you can do, and "byoc runs
before fuse" is not a bug.

The pass order inside this file matters
---------------------------------------
``InferType`` -> ``FoldConstant`` -> ``qnn.CanonicalizeOps`` -> ``FoldConstant``
-> ``MergeComposite`` -> ``InferType``

* ``CanonicalizeOps`` before matching: see ``aie_patterns`` -- matching ``qnn.*``
  directly makes qnn's own canonicalization die on lifted constants.
* ``FoldConstant`` AFTER canonicalization too: the expansion leaves the
  zero-point correction (``C2``) as an expression over constants, and the fused
  pattern needs it as a single ``Constant``.
* ``InferType`` AFTER ``MergeComposite``: the composite's body args become param
  Vars, and ``kernel_can_run`` reads the input dtype and shape off
  ``checked_type`` in step 2.

Must run before ``AlterOpLayout``
---------------------------------
Once the layout goes NCHWc the conv becomes the 5-D ``contrib_conv2d_NCHWc``
that neither the pattern nor the kernel recognizes. ``AlterOpLayout`` lives
inside ``relay.build`` (``relay/backend/utils.cc``), so the caller must hand us
the PRE-build module -- which ``deploy_flow._stage_aie_offload`` does.
"""

from __future__ import annotations

import tvm
from tvm import relay
from tvm.relay.qnn import transform as qnn_transform

from frontend.tvmrelay.byoc.aie_annotate import weight_fingerprint
from frontend.tvmrelay.byoc.aie_patterns import (ATTR_WEIGHT_FP, composite_name,
                                                 conv_geometry, find_conv,
                                                 pattern_table)

__all__ = ["fuse_layers", "CompositeTagger"]


class CompositeTagger(relay.ExprMutator):
    """Stamp ``aie.weight_fp`` on every composite the pattern table produced.

    Done here rather than recomputed during selection so that identity is
    established once, at the moment the composite is formed, and travels with it
    through ``PartitionGraph`` into codegen. ``BaseFunc.with_attr`` copies the
    function and adds to the EXISTING attrs, so ``Composite`` survives alongside.
    """

    def __init__(self, names):
        super().__init__()
        self.names = set(names)
        self.tagged = []

    def visit_call(self, call):
        new_args = [self.visit(a) for a in call.args]
        op = call.op
        if composite_name(op) not in self.names:
            return relay.Call(self.visit(op) if isinstance(op, relay.Function) else op,
                              new_args, call.attrs, call.type_args, call.span)

        conv = find_conv(op.body)
        w = conv.args[1] if conv is not None else None
        if not isinstance(w, relay.Constant):
            # No constant weight => no stable identity. Leave it untagged rather
            # than inventing one; selection then simply never matches it.
            return relay.Call(op, new_args, call.attrs, call.type_args, call.span)

        fp = weight_fingerprint(w.data.numpy())
        self.tagged.append({"name": composite_name(op), "fingerprint": fp,
                            "geometry": conv_geometry(conv)})
        return relay.Call(op.with_attr(ATTR_WEIGHT_FP, fp), new_args,
                          call.attrs, call.type_args, call.span)


def fuse_layers(mod, params=None, verbose: bool = True):
    """Canonicalize, fuse every matching layer into a composite, tag each. ``(mod, info)``.

    Works on a COPY: the caller's module is still the CPU build's input.
    ``info["composites"]`` is one record per tagged composite
    (``{name, fingerprint, geometry}``) -- step 2 selects from it.
    """
    mod = tvm.IRModule(dict(mod.functions), dict(mod.type_definitions))
    if params:
        mod["main"] = relay.build_module.bind_params_by_name(mod["main"], params)

    table = pattern_table()
    mod = tvm.transform.Sequential([
        relay.transform.InferType(),
        relay.transform.FoldConstant(),
        qnn_transform.CanonicalizeOps(),
        relay.transform.InferType(),
        relay.transform.FoldConstant(),
        relay.transform.InferType(),
        relay.transform.MergeComposite(table),
        relay.transform.InferType(),
    ])(mod)

    tagger = CompositeTagger(name for name, _, _ in table)
    mod["main"] = tagger.visit(mod["main"])
    if verbose:
        by_name = {}
        for c in tagger.tagged:
            by_name[c["name"]] = by_name.get(c["name"], 0) + 1
        what = ", ".join(f"{n} x{k}" for n, k in sorted(by_name.items())) or "nothing"
        print(f"  [aie-byoc] 1/4 fuse  : {what} "
              f"(AIE_BYOC_DEBUG=1 prints every non-match)")
    return mod, {"composites": tagger.tagged}
