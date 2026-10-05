###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Select layers to offload to AIE, and lower them through the aiegraph dialect.

The default flow keeps every layer on the APU as generated C. With
``--aie-offload`` the chosen layers instead go:

    LayerOp geometry  ->  aiegraph.conv_bn_relu  (built + verified in C++)
                      ->  lower_aiegraph         (-> per-launch tensor_specs)
                      ->  run_aie_pipeline       (-> host.cc/kernel.cc/
                                                     routing.cc/aieml.bcf)

Artifacts land in that layer's folder under ``layers/`` -- ``00_conv2d_add_relu/``
gets an ``aie/`` subdirectory -- which is what the per-layer, execution-ordered
layout exists for. The C path and the APU ``main.elf`` are untouched: this is
additive, so a run with offload on still produces the same CPU program.

Selection
---------
``--aie-layers`` takes indices (``0``, ``0,2,4``, ``all``) and ``--aie-ops``
filters by op kind, defaulting to the conv2d family because that is all
``run_aie_pipeline`` implements. Layer 0 is the default: it is the 7x7/s2 stem,
the first thing to execute and the easiest to reason about.

**No tile-budget check here -- offload is blind by design.** Every selected
layer is handed to aiehlc as-is; spatial tiling, halo, mesh partitioning and
the per-tile memory budget are aiehlc's job, and it reports what does not fit.
Predicting that from Python would duplicate (and drift from) the backend's own
policy -- see ``doc/design/byoc_aie_plan.md``.
"""

from __future__ import annotations

import atexit
import json
import sys
from pathlib import Path

__all__ = ["select_layers", "offload_layers", "parse_selection"]

#: Only the conv2d family has a kernel body + runtime path. Everything else in
#: the graph stays on the APU regardless of what is selected.
AIE_OP_KINDS = ("conv_bn_relu", "conv_bn")

DEFAULT_MESH = (2, 2)


# ═══════════════════════════════════════════════════════════════════════════
#  Selection
# ═══════════════════════════════════════════════════════════════════════════

def parse_selection(spec) -> list:
    """``"0"`` / ``"0,2,4"`` / ``"all"`` / ``None`` -> list of indices or None.

    ``None`` means "every layer" and is what ``all`` resolves to; the caller
    still filters by op kind afterwards.
    """
    if spec is None or str(spec).strip().lower() in ("all", "*"):
        return None
    out = []
    for part in str(spec).split(","):
        part = part.strip()
        if not part:
            continue
        if not part.lstrip("-").isdigit():
            raise ValueError(f"bad layer selector {part!r} (want ints or 'all')")
        out.append(int(part))
    return out


def _nchw(shape: list) -> tuple:
    """Normalize a feature-map shape to ``(C, H, W)``, or ``None`` if we cannot.

    Two layouts arrive here, because ``_layer_geometry`` reads the graph AFTER
    ``relay.build`` has run ``AlterOpLayout``:

        [N, C, H, W]          plain NCHW
        [N, C/c, H, W, c]     NCHWc -- C split so the inner block vectorizes

    The 5-D form is a *layout* artifact of TVM's x86 schedule, not a real fifth
    spatial axis, so folding ``C = C_outer * c`` recovers the geometry aiehlc
    wants. aiehlc's spatial spaces carry d1..d4 (``aiehlc.cc`` defines no
    ``tdD5``), and the Gen5 DMA tops out at ``NumAddrDim`` 3 for the shim and
    core tiles / 4 for the MemTile, so a genuine 5-D descriptor could not be
    programmed anyway.

    The fold is valid for SIZING unconditionally -- ``Cin = C_outer * c`` is the
    true channel count either way, and that is all the callers here use it for
    (``tensor_specs`` dims, never addressing).

    It is NOT a statement about memory order. Only ``C_outer == 1`` makes the
    NCHWc buffer byte-identical to the HWC that aietensorop reads; with
    ``C_outer > 1`` the data interleaves as ``(c_outer, h, w, c_inner)`` and a
    repack is required at the data-movement boundary or the kernel computes
    against transposed channels. ``needs_repack`` in ``_layer_geometry`` carries
    that fact forward so the emit path can act on it instead of rediscovering
    it. Both cases verified empirically.
    """
    if len(shape) == 4:
        return shape[1], shape[2], shape[3]
    if len(shape) == 5:
        c_outer, h, w, c_inner = shape[1], shape[2], shape[3], shape[4]
        return c_outer * c_inner, h, w
    return None


def _layer_geometry(graph: dict, node_idx: int) -> dict:
    """Recover ``{H,W,Cin,Cout,K,stride}`` for a conv node from the graph JSON.

    The shapes are authoritative -- they come from TVM's own type inference --
    so nothing here has to re-derive convolution arithmetic. ``K`` and
    ``stride`` come from the weight shape and the input/output ratio.

    Accepts both NCHW and NCHWc; see ``_nchw`` for why the 5-D case folds and
    when it must not.
    """
    attrs = graph["attrs"]
    shapes = attrs["shape"][1]
    row_ptr = graph["node_row_ptr"]
    node = graph["nodes"][node_idx]

    in_eids = [row_ptr[src] + slot for src, slot, _ in node["inputs"]]
    raw_in = shapes[in_eids[0]]                  # input  [N, Cin, H, W](c)
    raw_out = shapes[row_ptr[node_idx]]          # output [N, Cout, OH, OW](c)
    feat = _nchw(raw_in)
    out = _nchw(raw_out)
    if feat is None or out is None:
        return {}
    cin, h, w = feat
    cout, oh, ow = out

    # Kernel size, from the weight tensor.
    #
    # Do NOT assume the weights are input[1]. In a fused residual block the
    # second input is another feature map and the weights land at input[2]
    # (e.g. [1,16,56,56,4], [1,16,56,56,4], [16,16,3,3,4,4]) -- indexing [1]
    # blindly yields K=0 -- a kernel that does not exist. Identify it by RANK instead: weights are 4-D [Cout,Cin,KH,KW]
    # or 6-D NCHWc-blocked [Co/c,Ci/c,KH,KW,ci,co]; feature maps are 4-D/5-D
    # with a leading batch of 1, so require a non-1 leading dim to disambiguate
    # the 4-D case. KH sits at index 2 in both weight forms.
    k = 0
    for eid in in_eids[1:]:
        s = shapes[eid]
        if len(s) == 6 or (len(s) == 4 and s[0] != 1):
            k = s[2]
            break
    stride = max(1, h // oh) if oh else 1

    # Does the buffer need a channel repack before/after the AIE kernel?
    # NCHWc with C_outer == 1 is already byte-identical to HWC; anything bigger
    # interleaves and must be transposed at the data-movement boundary. Carried
    # here so the emit path acts on it instead of rediscovering it.
    def _blocked(s):
        return len(s) == 5 and s[1] != 1

    return {"H": h, "W": w, "Cin": cin, "Cout": cout,
            "K": k, "stride": stride,
            "in_elems": cin * h * w,
            "out_elems": cout * oh * ow,
            "in_layout": "NCHWc" if len(raw_in) == 5 else "NCHW",
            "out_layout": "NCHWc" if len(raw_out) == 5 else "NCHW",
            "needs_repack": _blocked(raw_in) or _blocked(raw_out)}


def _require_emit_deps() -> None:
    """Fail with both missing names, before any of the emit work starts.

    The emit path needs two things:

      * ``frontend.tvmrelay.kernels`` -- the kernel-body generator
        (``kernel_body_for()``), restored from the ``src/frontend/tvm/``
        package that ``05ee99d`` deleted.
      * ``_aiebackend`` -- the AIE backend pybind module. cmake silently skips
        it unless it finds python3-dev AND pybind11 (pass ``-Dpybind11_DIR``;
        the pip install is not on cmake's search path). ``aie_backend()`` finds
        the ``.so`` in the build tree and runs it out of process, because it
        cannot share a process with TVM (skills: mlirbuildsandbox,
        aiebackendtvmllvm).

    Raised up front, naming both, instead of letting a bare
    ``ModuleNotFoundError`` surface from an import several frames down. Layer
    selection runs before this and is useful on its own, so the caller still
    sees it.
    """
    missing = []
    try:
        aie_backend()
    except Exception as exc:
        missing.append(f"AIE backend _aiebackend ({type(exc).__name__}: {exc})")
    try:
        from frontend.tvmrelay import kernels  # noqa: F401
    except Exception:
        missing.append("frontend.tvmrelay.kernels -- the kernel-body "
                       "generator; --aie-offload cannot emit without it")
    if missing:
        raise RuntimeError(
            "AIE emit unavailable: " + "; ".join(missing)
            + ". Layer selection above still ran. "
              "The working offload path today is --byoc-aie.")


def _geometry_reject_reason(graph: dict, node_idx: int) -> str:
    """Say WHY the geometry was unusable, with the actual shapes."""
    shapes = graph["attrs"]["shape"][1]
    row_ptr = graph["node_row_ptr"]
    node = graph["nodes"][node_idx]
    in_eids = [row_ptr[src] + slot for src, slot, _ in node["inputs"]]
    feat = shapes[in_eids[0]]
    out = shapes[row_ptr[node_idx]]
    return (f"unsupported shapes: input {feat}, output {out} "
            f"(want rank 4 NCHW or rank 5 NCHWc)")


def select_layers(manifest: dict, graph: dict, indices=None,
                  op_kinds=AIE_OP_KINDS) -> list:
    """Pick the layers to offload. Returns a list of selection dicts.

    *manifest* is ``layers/manifest.json`` from stage 5 (so the per-layer
    folder names line up) and *graph* the stage-4 graph JSON (so geometry comes
    from TVM's shapes). A requested index whose op kind has no AIE path is
    returned with ``eligible=False`` and a reason rather than silently dropped
    -- asking for a layer and getting nothing back with no explanation is the
    failure mode worth avoiding.
    """
    # Graph nodes that are real kernel calls, in execution order.
    call_nodes = [i for i, n in enumerate(graph["nodes"])
                  if n.get("op") == "tvm_op"
                  and n["attrs"].get("func_name") != "__nop"]

    # Map manifest entry -> graph node by SYMBOL, not by position.
    #
    # `call_nodes[idx]` looks right and is not: the manifest has one entry per
    # emitted C function while the graph has one node per CALL, and a function
    # invoked twice appears once in the manifest and twice here. On ResNet-18
    # that is 28 vs 30, and the two desynchronize from index 6 onward -- every
    # later layer then gets another layer's geometry, silently. (The same bug
    # is called out in aiegraph_partition.py's docstring.)
    #
    # Symbols repeat, so consume them in order: the n-th manifest entry naming
    # a symbol takes the n-th graph node calling it.
    by_symbol = {}
    for ni in call_nodes:
        by_symbol.setdefault(graph["nodes"][ni]["attrs"]["func_name"], []).append(ni)
    taken = {}

    def _node_for(entry):
        sym = entry["symbol"]
        nodes = by_symbol.get(sym, [])
        seq = taken.get(sym, 0)
        if seq >= len(nodes):
            return None
        taken[sym] = seq + 1
        return nodes[seq]

    picked = []
    for entry in manifest["layers"]:
        idx = entry["index"]
        # Claim this entry's graph node BEFORE the index filter. _node_for
        # consumes repeated symbols in order, so skipping entries early would
        # hand the next selected layer an earlier layer's node -- making the
        # result depend on which --aie-layers were asked for.
        node_idx = _node_for(entry)
        if indices is not None and idx not in indices:
            continue
        kind = entry.get("kind", "")
        ops = entry.get("ops", [])
        # Map the split-layer name onto an aiegraph op kind.
        if "conv2d" in ops:
            aie_op = "conv_bn_relu" if "relu" in ops else "conv_bn"
        else:
            aie_op = None

        sel = {"index": idx, "dir": entry.get("dir", ""), "kind": kind,
               "symbol": entry["symbol"], "ops": ops, "aie_op": aie_op}

        if aie_op is None or aie_op not in op_kinds:
            sel.update(eligible=False,
                       reason=f"op kind {kind!r} has no AIE kernel "
                              f"(run_aie_pipeline implements {', '.join(op_kinds)})")
            picked.append(sel)
            continue
        if node_idx is None:
            sel.update(eligible=False,
                       reason=f"no graph node calls {entry['symbol']!r}")
            picked.append(sel)
            continue

        geom = _layer_geometry(graph, node_idx)
        if not geom:
            sel.update(eligible=False, reason=_geometry_reject_reason(graph, node_idx))
            picked.append(sel)
            continue
        sel["node"] = node_idx
        sel.update(eligible=True, **geom)
        picked.append(sel)
    return picked


# ═══════════════════════════════════════════════════════════════════════════
#  Offload
# ═══════════════════════════════════════════════════════════════════════════

#: ``src/mlir/mlirfront/frontend`` -- parent of the ``aiebackend`` package.
_MLIR_FRONTEND_DIR = (Path(__file__).resolve().parents[2]
                      / "mlir" / "mlirfront" / "frontend")

_BACKEND = None


def aie_backend():
    """The AIE backend (``_aiebackend``), running in a child process.

    Returns an ``aiebackend.BackendProcess`` whose methods mirror the pybind
    module (``build_aiegraph_module`` / ``lower_aiegraph`` /
    ``run_aie_pipeline``). It is never imported in-process here: this package
    always has TVM loaded, and TVM's LLVM and the backend's static LLVM abort on
    duplicate command-line options (skill: aiebackendtvmllvm). Started once and
    reused; closed at interpreter exit.
    """
    global _BACKEND
    if _BACKEND is None:
        if str(_MLIR_FRONTEND_DIR) not in sys.path:
            sys.path.insert(0, str(_MLIR_FRONTEND_DIR))
        import aiebackend

        _BACKEND = aiebackend.spawn()
        atexit.register(_BACKEND.close)
    return _BACKEND


def build_aiegraph_ir(selections: list, func_name: str = "offload") -> str:
    """Lift the eligible selections into one verified ``aiegraph.func``.

    Built as a single module rather than one per layer so the dialect verifies
    the whole offloaded subgraph at once, and so the textual IR is a readable
    record of exactly what was handed to the backend.
    """
    backend = aie_backend()
    ops = []
    for sel in selections:
        if not sel.get("eligible"):
            continue
        ops.append({
            "op": sel["aie_op"],
            # -1 = network input. Each offloaded layer is launched standalone
            # (the APU owns the buffers between launches), so none of them
            # chains to another layer's aiegraph result.
            "main_index": -1,
            "H": sel["H"], "W": sel["W"], "Cin": sel["Cin"],
            "Cout": sel["Cout"], "K": sel["K"], "stride": sel["stride"],
            "in_scale": 1.0, "in_zp": 0, "out_scale": 1.0, "out_zp": 0,
            "bn_scale": 64, "bn_bias": 0,
            "weights": f"w{sel['index']}",
        })
    if not ops:
        return ""
    return backend.build_aiegraph_module(ops, func_name)


def offload_layers(out_dir, indices=None, op_kinds=AIE_OP_KINDS,
                   mesh=DEFAULT_MESH, verbose: bool = True) -> dict:
    """Offload the selected layers through aiegraph. Returns a result dict.

    Writes each layer's AIE artifacts into ``layers/<NN_name>/aie/`` and the
    shared textual IR to ``layers/aiegraph.mlir``. The APU C path is not
    touched.
    """
    out_dir = Path(out_dir).resolve()
    layers_dir = out_dir / "layers"
    manifest_path = layers_dir / "manifest.json"
    graph_path = next(out_dir.glob("*_graph.json"), None)
    if not manifest_path.is_file():
        return {"ok": False, "reason": "layers/manifest.json not found "
                                       "(stage 5 did not run)"}
    if graph_path is None:
        return {"ok": False, "reason": "no *_graph.json in the output dir"}

    manifest = json.loads(manifest_path.read_text())
    graph = json.loads(graph_path.read_text())
    selections = select_layers(manifest, graph, indices, op_kinds)
    eligible = [s for s in selections if s.get("eligible")]

    if verbose:
        for sel in selections:
            if not sel.get("eligible"):
                print(f"  [aie] layer {sel['index']:02d} {sel['kind']}: "
                      f"skipped -- {sel['reason']}")
    if not eligible:
        return {"ok": False, "reason": "no eligible layers selected",
                "selections": selections}

    # No budget check: tiling and memory fit are aiehlc's call (module doc).
    if verbose:
        for sel in eligible:
            print(f"  [aie] layer {sel['index']:02d} {sel['kind']}: "
                  f"{sel['H']}x{sel['W']}x{sel['Cin']} -> {sel['Cout']}ch "
                  f"K{sel['K']}s{sel['stride']}")

    _require_emit_deps()

    ir = build_aiegraph_ir(eligible)
    ir_path = layers_dir / "aiegraph.mlir"
    ir_path.write_text(ir)
    if verbose:
        print(f"  [aie] aiegraph IR verified -> {ir_path.name}")

    backend = aie_backend()
    from frontend.tvmrelay import kernels

    launches = backend.lower_aiegraph(ir)
    built = []
    for sel, launch in zip(eligible, launches):
        layer_dir = layers_dir / (sel["dir"] or f"{sel['index']:02d}")
        aie_dir = layer_dir / "aie"
        aie_dir.mkdir(parents=True, exist_ok=True)
        specs = [(list(shape), int(bits), bool(is_in))
                 for (shape, bits, is_in) in launch["tensor_specs"]]
        body = kernels.kernel_body_for(sel["aie_op"], launch["func_name"])
        ok = backend.run_aie_pipeline(mesh[0], mesh[1], specs, str(aie_dir),
                                   body, launch["func_name"])
        produced = sorted(p.name for p in aie_dir.iterdir()) if ok else []
        built.append({"index": sel["index"], "dir": str(aie_dir), "ok": bool(ok),
                      "func_name": launch["func_name"], "files": produced})
        if verbose:
            print(f"  [aie] layer {sel['index']:02d} -> {aie_dir.relative_to(out_dir)}/ "
                  f"({len(produced)} files: {', '.join(produced[:4])}"
                  f"{', ...' if len(produced) > 4 else ''})")

    return {"ok": all(b["ok"] for b in built), "ir": str(ir_path),
            "layers": built, "selections": selections}
