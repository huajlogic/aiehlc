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

**Feasibility is checked and reported, not assumed.** ``run_aie_pipeline``
returns True for ResNet-18's layer 0 and writes a complete artifact set -- but
the generated kernel is the whole-feature-map loop nest from
``frontend.tvm.kernels``, indexing ``feat_in[ic*H*W + ih*W + iw]`` over 150,528
bytes, while the pipeline hands it a 1,024-byte ping-pong window. That is a
147x overrun that no stage of the existing pipeline rejects: the C++ budget
check at ``tilinglinalg_pipeline.cpp:602`` loops over a ``tensors`` vector that
neither pybind entry populates, so it reports "estimated 0 bytes per tile" and
passes everything.

So ``check_layer`` computes the real numbers and every offload result carries a
``feasible`` flag plus the arithmetic behind it. Generating the artifacts is
useful -- it exercises the dialect, the routing, and the DMA config, and
produces the ``.bcf`` -- but a layer this size needs the spatial-halo tiling
that ``example/tileprogram/ccode/simpleconv2d.cc`` does through the Clang
frontend and that the pybind ``DmaSpec`` cannot currently express (it exposes 5
of ``DmaAddressing``'s ~18 fields and drops every halo field).
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

__all__ = ["select_layers", "check_layer", "offload_layers", "parse_selection"]

#: AIE core tile data memory actually available for ping-pong buffers
#: (``hwresource.h:116-118``: 64 KB total - 10 KB stack reserve).
TILE_USABLE_BYTES = 49152

#: Ping-pong depth the pipeline assumes (``tilinglinalg_pipeline.cpp:613``).
PING_PONG_DEPTH = 2

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


def _layer_geometry(graph: dict, node_idx: int) -> dict:
    """Recover ``{H,W,Cin,Cout,K,stride}`` for a conv node from the graph JSON.

    The shapes are authoritative -- they come from TVM's own type inference --
    so nothing here has to re-derive convolution arithmetic. ``K`` and
    ``stride`` come from the weight shape and the input/output ratio.
    """
    attrs = graph["attrs"]
    shapes = attrs["shape"][1]
    row_ptr = graph["node_row_ptr"]
    node = graph["nodes"][node_idx]

    in_eids = [row_ptr[src] + slot for src, slot, _ in node["inputs"]]
    feat = shapes[in_eids[0]]                    # [N, Cin, H, W]
    out = shapes[row_ptr[node_idx]]              # [N, Cout, OH, OW]
    if len(feat) != 4 or len(out) != 4:
        return {}
    weight = shapes[in_eids[1]] if len(in_eids) > 1 else []
    k = weight[2] if len(weight) == 4 else 0
    stride = max(1, feat[2] // out[2]) if out[2] else 1
    return {"H": feat[2], "W": feat[3], "Cin": feat[1], "Cout": out[1],
            "K": k, "stride": stride,
            "in_elems": feat[1] * feat[2] * feat[3],
            "out_elems": out[1] * out[2] * out[3]}


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
    # Graph nodes that are real kernel calls, in execution order -- the same
    # order stage 5 numbered the folders in.
    call_nodes = [i for i, n in enumerate(graph["nodes"])
                  if n.get("op") == "tvm_op"
                  and n["attrs"].get("func_name") != "__nop"]

    picked = []
    for entry in manifest["layers"]:
        idx = entry["index"]
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
        if idx >= len(call_nodes):
            sel.update(eligible=False, reason="no matching graph node")
            picked.append(sel)
            continue

        geom = _layer_geometry(graph, call_nodes[idx])
        if not geom:
            sel.update(eligible=False, reason="non-4D shapes; not a conv2d")
            picked.append(sel)
            continue
        sel.update(eligible=True, **geom)
        picked.append(sel)
    return picked


# ═══════════════════════════════════════════════════════════════════════════
#  Feasibility
# ═══════════════════════════════════════════════════════════════════════════

def check_layer(sel: dict, mesh=DEFAULT_MESH) -> dict:
    """Does this layer's working set fit one AIE tile? Returns the arithmetic.

    The params buffer is **not** split across the mesh -- every tile needs the
    whole weight set -- so it is counted at full size while the feature and
    output tensors are divided by the tile count.
    """
    tiles = max(1, mesh[0] * mesh[1])
    param_elems = (CONFIG_SZ + sel["Cin"] * sel["Cout"] * sel["K"] ** 2
                   + sel["Cout"] * 2)
    per_tile = PING_PONG_DEPTH * (sel["in_elems"] // tiles + param_elems
                                  + sel["out_elems"] // tiles)
    return {"per_tile_bytes": per_tile, "budget_bytes": TILE_USABLE_BYTES,
            "param_bytes": param_elems, "fits": per_tile <= TILE_USABLE_BYTES,
            "overrun": per_tile / TILE_USABLE_BYTES}


#: Conv param header: 6 uint16 fields (``frontend.tvm.model.CONFIG_SZ``).
CONFIG_SZ = 12


# ═══════════════════════════════════════════════════════════════════════════
#  Offload
# ═══════════════════════════════════════════════════════════════════════════

def _core():
    """Import the ``_aietriton_core`` pybind extension."""
    pkg = Path(__file__).resolve().parents[1] / "mlir" / "mlirfront" / "frontend" / "aietriton"
    if not pkg.is_dir():
        pkg = (Path(__file__).resolve().parents[3] / "src" / "mlir" / "mlirfront"
               / "frontend" / "aietriton")
    if str(pkg) not in sys.path:
        sys.path.insert(0, str(pkg))
    import _aietriton_core  # noqa: F401

    return _aietriton_core


def build_aiegraph_ir(selections: list, func_name: str = "offload") -> str:
    """Lift the eligible selections into one verified ``aiegraph.func``.

    Built as a single module rather than one per layer so the dialect verifies
    the whole offloaded subgraph at once, and so the textual IR is a readable
    record of exactly what was handed to the backend.
    """
    core = _core()
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
    return core.build_aiegraph_module(ops, func_name)


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

    # Feasibility first: report before spending time in the backend.
    for sel in eligible:
        sel["check"] = check_layer(sel, mesh)
        if verbose:
            chk = sel["check"]
            verdict = ("fits" if chk["fits"]
                       else f"OVER BUDGET by {chk['overrun']:.1f}x")
            print(f"  [aie] layer {sel['index']:02d} {sel['kind']}: "
                  f"{sel['H']}x{sel['W']}x{sel['Cin']} -> {sel['Cout']}ch "
                  f"K{sel['K']}s{sel['stride']} | "
                  f"{chk['per_tile_bytes']:,} B/tile vs "
                  f"{chk['budget_bytes']:,} -- {verdict}")

    ir = build_aiegraph_ir(eligible)
    ir_path = layers_dir / "aiegraph.mlir"
    ir_path.write_text(ir)
    if verbose:
        print(f"  [aie] aiegraph IR verified -> {ir_path.name}")

    core = _core()
    from frontend.tvm import kernels

    launches = core.lower_aiegraph(ir)
    built = []
    for sel, launch in zip(eligible, launches):
        layer_dir = layers_dir / (sel["dir"] or f"{sel['index']:02d}")
        aie_dir = layer_dir / "aie"
        aie_dir.mkdir(parents=True, exist_ok=True)
        specs = [(list(shape), int(bits), bool(is_in))
                 for (shape, bits, is_in) in launch["tensor_specs"]]
        body = kernels.kernel_body_for(sel["aie_op"], launch["func_name"])
        ok = core.run_aie_pipeline(mesh[0], mesh[1], specs, str(aie_dir),
                                   body, launch["func_name"])
        produced = sorted(p.name for p in aie_dir.iterdir()) if ok else []
        built.append({"index": sel["index"], "dir": str(aie_dir), "ok": bool(ok),
                      "func_name": launch["func_name"], "files": produced,
                      "feasible": sel["check"]["fits"],
                      "per_tile_bytes": sel["check"]["per_tile_bytes"]})
        if verbose:
            print(f"  [aie] layer {sel['index']:02d} -> {aie_dir.relative_to(out_dir)}/ "
                  f"({len(produced)} files: {', '.join(produced[:4])}"
                  f"{', ...' if len(produced) > 4 else ''})")

    infeasible = [b for b in built if not b["feasible"]]
    return {"ok": all(b["ok"] for b in built), "ir": str(ir_path),
            "layers": built, "selections": selections,
            "infeasible": len(infeasible)}
