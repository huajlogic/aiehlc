###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""BYOC entry point: pattern table + annotation + codegen, chained in order.

``deploy_flow --aie-offload`` calls ``partition_for_aie(mod, params, convs=...)``
with the conv weight fingerprints ``aie_offload.resolve_conv_targets`` selected. Merging,
partitioning and host-side compilation are TVM's job; this calls them in order.

The pass order matters
----------------------
``InferType`` -> ``FoldConstant`` -> ``qnn.CanonicalizeOps`` -> ``FoldConstant``
-> ``MergeComposite`` -> **annotation** -> ``InferType`` ->
``MergeCompilerRegions`` -> ``PartitionGraph``

* ``CanonicalizeOps`` before matching: see ``aie_patterns`` -- matching ``qnn.*``
  directly makes qnn's own canonicalization die on lifted constants.
* ``FoldConstant`` AFTER canonicalization too: the expansion leaves the
  zero-point correction (``C2``) as an expression over constants, and the
  fused pattern needs it as a single ``Constant``.
* Annotation after ``MergeComposite``: the unit to wrap is the whole composite.
* ``InferType`` after annotation: ``compiler_begin/end`` carry no type, and
  ``PartitionGraph`` needs types to find the boundaries.

Partition before ``AlterOpLayout``
----------------------------------
Once the layout goes NCHWc the conv becomes the 5-D ``contrib_conv2d_NCHWc``
that neither the pattern nor the kernel recognizes, so this must run before
``relay.build``. TVM then inserts its own layout transforms around the extern
call, and the AIE subgraph boundary stays plain NCHW.
"""

from __future__ import annotations

import tvm
from tvm import relay
from tvm.relay.qnn import transform as qnn_transform

from frontend.tvmrelay.byoc import aie_codegen  # noqa: F401  registers relay.ext.aie
from frontend.tvmrelay.byoc.aie_annotate import AIE_COMPILER_NAME, ConvSelectAnnotator
from frontend.tvmrelay.byoc.aie_patterns import AIE_PATTERN_NAME, pattern_table

__all__ = ["partition_for_aie", "count_composites", "partition_summary"]


def count_composites(mod, pattern_name: str = AIE_PATTERN_NAME) -> int:
    """How many target composite functions are in the graph after ``MergeComposite``.

    This is factored out because it answers the first question you ask when
    debugging: did the pattern match at all? If it is 0, the problem is in the
    pattern table, not in annotation or partitioning.
    """
    n = 0

    def visit(expr):
        nonlocal n
        if isinstance(expr, relay.Function) and expr.attrs \
                and "Composite" in expr.attrs \
                and str(expr.attrs["Composite"]) == pattern_name:
            n += 1

    relay.analysis.post_order_visit(mod["main"], visit)
    return n


def partition_summary(mod, compiler: str = AIE_COMPILER_NAME) -> dict:
    """The actual outcome after partitioning: how many subgraphs were offloaded
    and what they are called.

    This counts the ``Compiler`` attributes directly rather than trusting the
    count from the annotation stage -- a mismatch between the two means
    ``PartitionGraph`` merged or discarded some subgraphs, and that is something
    you must be able to see.
    """
    names = []
    for gv in mod.get_global_vars():
        fn = mod[gv]
        if isinstance(fn, relay.Function) and fn.attrs \
                and "Compiler" in fn.attrs \
                and str(fn.attrs["Compiler"]) == compiler:
            names.append(str(gv.name_hint))
    return {"count": len(names), "functions": sorted(names)}


def partition_for_aie(mod, params=None, convs=(), verbose: bool = True):
    """Partition the fused qconvs whose weight fingerprint is in *convs*
    (``None``: all that match). Returns ``(mod, info)``.

    ``info["convs"]`` lists every conv with its fingerprint, geometry and
    whether it was offloaded -- the caller cross-checks it against TVM's graph.
    A selected conv that does not match the pattern is simply not offloaded
    (``info["unmatched"]``); it is never forced onto the AIE.
    """
    # Work on a copy: the caller's module is still the CPU build's input.
    mod = tvm.IRModule(dict(mod.functions), dict(mod.type_definitions))
    if params:
        mod["main"] = relay.build_module.bind_params_by_name(mod["main"], params)

    mod = tvm.transform.Sequential([
        relay.transform.InferType(),
        relay.transform.FoldConstant(),
        qnn_transform.CanonicalizeOps(),
        relay.transform.InferType(),
        relay.transform.FoldConstant(),
        relay.transform.InferType(),
        relay.transform.MergeComposite(pattern_table()),
    ])(mod)

    matched = count_composites(mod)
    if verbose:
        print(f"  [aie-byoc] MergeComposite matched {matched} {AIE_PATTERN_NAME} "
              f"(AIE_BYOC_DEBUG=1 prints every rejection reason)")

    annotator = ConvSelectAnnotator(selected=convs, pattern_name=AIE_PATTERN_NAME)
    mod["main"] = annotator.visit(mod["main"])
    if verbose:
        print(f"  [aie-byoc] {annotator.report()}")

    mod = tvm.transform.Sequential([
        relay.transform.InferType(),
        relay.transform.MergeCompilerRegions(),
        relay.transform.PartitionGraph(),
        relay.transform.InferType(),
    ])(mod)

    summary = partition_summary(mod)
    if verbose:
        print(f"  [aie-byoc] partitioned out {summary['count']} AIE subgraph(s)"
              + (f": {', '.join(summary['functions'])}" if summary["functions"] else ""))

    offloaded = {c["fingerprint"] for c in annotator.convs if c["offloaded"]}
    info = {"matched": matched, "annotated": annotator.annotated,
            "convs": annotator.convs,
            "unmatched": sorted(set(convs or ()) - offloaded), **summary}
    return mod, info
