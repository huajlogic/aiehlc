###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""BYOC entry point: chain the pattern table, annotation, and codegen into a
single ``partition_for_aie(mod, n=...)``.

The merging and partitioning in between, as well as the host-side compilation
and execution, are all TVM's job; this just calls them in the correct order.

The pass order matters
----------------------
``InferType`` -> ``FoldConstant`` -> ``MergeComposite`` -> **annotation** ->
``InferType`` -> ``MergeCompilerRegions`` -> ``PartitionGraph``

* ``FoldConstant`` must come before ``MergeComposite``: the pattern contains a
  run of ``is_constant()``, and before folding, scale/zero-point are ``qnn``
  subexpressions rather than Constants, so matching silently fails.
* Annotation must come **after** ``MergeComposite``: what we want to wrap is the
  whole composite function, not the individual operators spread apart (see
  ``aie_annotate``).
* After annotation we must ``InferType`` again: the inserted
  ``compiler_begin/end`` have no type, and ``PartitionGraph`` needs the type
  information to determine the subgraph boundaries.

Partition before ``AlterOpLayout``
----------------------------------
This one is implicit in ``deploy_flow`` but critical: once the layout is changed
to NCHWc, the convolution becomes the 5-D ``contrib_conv2d_NCHWc``, which neither
the pattern nor the AIE kernel recognizes. So ``partition_for_aie`` must be
called **before** ``relay.build`` (the layout transform happens inside build),
and the ``data_layout != "NCHW"`` check in ``check_qconv`` is the watchdog for
this assumption.

No offload by default
---------------------
``n=0`` is the default. What ``aie_codegen`` currently emits is a **placeholder**
function body: it compiles and runs but does not compute correct results.
Offloading must be requested explicitly (``n=5``), and the warning below gets
printed.
"""

from __future__ import annotations

import tvm
from tvm import relay
from tvm.relay.qnn import transform as qnn_transform

from frontend.tvmrelay.byoc import aie_codegen  # noqa: F401  registers relay.ext.aie
from frontend.tvmrelay.byoc.aie_annotate import AIE_COMPILER_NAME, FirstNAnnotator
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


def partition_for_aie(mod, params=None, n: int = 0, verbose: bool = True):
    """Partition the first *n* qconv subgraphs onto AIE. Returns ``(mod, info)``.

    *n* = 0 offloads nothing (the default), ``None`` offloads all of them.
    ``info`` carries the count from every step, convenient to print or assert on
    directly.
    """
    if params:
        mod["main"] = relay.build_module.bind_params_by_name(mod["main"], params)

    # FoldConstant must run before MergeComposite, otherwise is_constant() will
    # not match.
    #
    # Legalize must come first too, and that is non-negotiable. Without it,
    # relay.build dies later on:
    #
    #   InternalError: Check failed: (n) is false: Expr must be a constant expr
    #     ... QnnAddCanonicalize / RequantizeQnnCanonicalize
    #         -> GetScalarFromConstant<float>
    #
    # The cause is not a mis-written pattern: in practice even a **minimal
    # pattern that only matches nn.bias_add and does not touch qnn at all**
    # triggers the same error, and n=0 (offload nothing at all) fails just the
    # same. MergeComposite lifts the constants inside any region it touches into
    # parameters of the composite function, while qnn's canonicalization requires
    # scale/zero-point to be compile-time Constants, and dies outright when it
    # gets a free variable instead. Running FoldConstant once more afterwards does
    # not rescue it either (also verified experimentally).
    #
    # The fix is qnn's own CanonicalizeOps: it expands every qnn.* into a
    # composition of ordinary operators, the constants get consumed at that step,
    # and however MergeComposite lifts parameters afterwards it no longer triggers
    # GetScalarFromConstant. The generic relay.transform.Legalize() is **not
    # enough** -- in practice it does not expand qnn.add, and build still dies in
    # QnnAddCanonicalize.
    mod = tvm.transform.Sequential([
        relay.transform.InferType(),
        relay.transform.FoldConstant(),
        qnn_transform.CanonicalizeOps(),
        relay.transform.InferType(),
        relay.transform.MergeComposite(pattern_table()),
    ])(mod)

    matched = count_composites(mod)
    if verbose:
        print(f"  [aie-byoc] MergeComposite matched {matched} {AIE_PATTERN_NAME}")
    if matched == 0 and verbose:
        print("  [aie-byoc] warning: nothing matched at all. First confirm the IR really is "
              "qnn.conv2d -> nn.bias_add -> qnn.requantize, and that FoldConstant has folded "
              "scale/zp into Constants (AIE_BYOC_DEBUG=1 shows the per-case rejection reason)")

    annotator = FirstNAnnotator(n=n)
    mod["main"] = annotator.visit(mod["main"])
    if verbose:
        print(f"  [aie-byoc] {annotator.report()}")

    # After annotation we must re-run InferType: compiler_begin/end have no type,
    # and PartitionGraph needs it.
    mod = tvm.transform.Sequential([
        relay.transform.InferType(),
        relay.transform.MergeCompilerRegions(),
        relay.transform.PartitionGraph(),
        relay.transform.InferType(),
    ])(mod)

    summary = partition_summary(mod)
    if verbose:
        print(f"  [aie-byoc] partitioned out {summary['count']} AIE subgraphs"
              + (f": {', '.join(summary['functions'][:4])}"
                 f"{' ...' if summary['count'] > 4 else ''}"
                 if summary["functions"] else ""))
        if summary["count"]:
            print("  [aie-byoc] note: subgraphs matching the ResNet-18 stem geometry call "
                  "conv2d_stem_raw() in libconv2dstem.a; anything else still gets the "
                  "placeholder body (see aie_codegen._stem_body)")

    info = {"matched": matched, "annotated": annotator.annotated,
            "skipped": annotator.skipped, **summary}
    return mod, info
