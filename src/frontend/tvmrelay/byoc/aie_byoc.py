###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""BYOC entry point: the four steps, chained in order.

``deploy_flow --aie-offload`` calls ``partition_for_aie(mod, params, convs=...)``
with what ``aie_offload.resolve_conv_targets`` selected. This file is the
orchestration; each step lives in its own module:

==== ================= ====================================================
step module            what it does
==== ================= ====================================================
1    ``aie_fuse``      canonicalize, ``MergeComposite``, tag ``aie.weight_fp``
2    ``aie_annotate``  select by fingerprint + ``kernel_can_run``, tag
                       ``aie.layer_id``, ``compiler_begin``/``end``
3    *here*            ``MergeCompilerRegions`` + ``PartitionGraph``
4    ``aie_codegen``   ``relay.ext.aie``, dispatched on the composite name
==== ================= ====================================================

Why step 1 is separate from steps 2-3
-------------------------------------
It used to be inlined here, with the stem geometry gate inside the
``MergeComposite`` checker -- so the only layer that ever fused was the one the
AIE could already run. Fusing is now geometry-agnostic and selection owns
capability, which is what lets a layer be turned down by name. See ``aie_fuse``.

Do not confuse it with TVM's ``FuseOps``, which is TE-level operator fusion,
runs inside the second ``relay.build``, and necessarily comes AFTER partitioning
so that it only fuses what stayed on the CPU.

``InferType`` after annotation
------------------------------
``compiler_begin``/``compiler_end`` carry no type, and ``PartitionGraph`` needs
types to find the boundaries.

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

from frontend.tvmrelay.byoc import aie_codegen  # noqa: F401  registers relay.ext.aie
from frontend.tvmrelay.byoc.aie_annotate import AIE_COMPILER_NAME, ConvSelectAnnotator
from frontend.tvmrelay.byoc.aie_fuse import fuse_layers
from frontend.tvmrelay.byoc.aie_patterns import AIE_PATTERN_NAME

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
    """Fuse, select, partition. Returns ``(mod, info)``.

    *convs* is a ``{weight_fingerprint: layer_index}`` mapping (a bare iterable of
    fingerprints also works; ``None`` means every composite the kernel can run).

    ``info["convs"]`` lists every conv with its fingerprint, geometry and whether
    it was offloaded -- the caller cross-checks it against TVM's graph. A
    selected conv is never forced onto the AIE: if it did not fuse it lands in
    ``info["unmatched"]``, and if it fused but the kernel cannot run it, in
    ``info["rejected"]`` with the reason.
    """
    mod, fuse_info = fuse_layers(mod, params, verbose=verbose)
    matched = count_composites(mod)

    annotator = ConvSelectAnnotator(selected=convs, pattern_name=AIE_PATTERN_NAME)
    mod["main"] = annotator.visit(mod["main"])
    if verbose:
        print(f"  [aie-byoc] 2/4 select: {annotator.report()}")

    mod = tvm.transform.Sequential([
        relay.transform.InferType(),
        relay.transform.MergeCompilerRegions(),
        relay.transform.PartitionGraph(),
        relay.transform.InferType(),
    ])(mod)

    summary = partition_summary(mod)
    if verbose:
        print(f"  [aie-byoc] 3/4 part  : {summary['count']} AIE subgraph(s)"
              + (f": {', '.join(summary['functions'])}" if summary["functions"] else ""))

    offloaded = {c["fingerprint"] for c in annotator.convs if c["offloaded"]}
    asked = set(convs or ())
    info = {"matched": matched, "annotated": annotator.annotated,
            "convs": annotator.convs, "composites": fuse_info["composites"],
            "rejected": dict(annotator.rejected),
            "unmatched": sorted(asked - offloaded - set(annotator.rejected)),
            **summary}
    return mod, info
