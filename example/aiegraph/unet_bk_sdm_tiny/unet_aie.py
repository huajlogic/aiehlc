"""--aie conv for build_unet.py (sprint unet-bf16-streamload, P35w).

The 37 conv layers of p35/partition.json go to the AIE; everything else stays
TVM C on the A78 (bf16 weights expanded into g_wscratch, Steve's .bss scratch).

  * map     each partition layer (ONNX Conv, by weight name) -> the TVM call that
            carries the same weight: fp32 weight statistics (count, sum, sum of
            squares) of the ONNX initializer == those of the TVM param (the TVM
            OIHW{i}i{o}o weight is a permutation). Unique match or the build fails.
  * kernel  gemm_bf16 (p2k/bf16_gemm_convin.cc, verbatim): one launch = one 64x64x64
            tile (bf16 x bf16 -> fp32). Host function aiednn_aie_conv() (C linkage)
            runs any NCHWc conv as ceil(M/64)*ceil(N/64)*ceil(K/64) launches:
            activation fp32 -> bf16 RNE im2col tile, weight tile gathered straight
            from the COMPACT bf16 blob (weights.bin, never expanded), each 64-K slice
            rounded to bf16, fp32 K-sum + bias/temb/residual adds on the APU.
            g_aie_launches++ per real launch; MACs counted per launch.
  * archive built by aiegraph's own offload flow on ONE carrier layer (a TVM function
            all of whose call sites are partition layers); calibrate/emulate (whole
            UNet on x86) are skipped -- force=True ignores their verdicts anyway.
  * driver  graph_driver.c is post-processed: each partition call site calls
            aiednn_aie_conv(cid, args, nargs, g_params+off, sh, sw, ph, pw) instead of
            the TVM kernel, and its weight is NOT expanded into g_wscratch.
"""
import json
import os
import re
from pathlib import Path

import numpy as np
import os as _os  # noqa: E402
import sys as _sys  # noqa: E402
_SRC = _os.path.normpath(_os.path.join(_os.path.dirname(_os.path.abspath(__file__)), "../../../src"))
if _SRC not in _sys.path:  # C text lives in src/aiednn/<cat>/ (kernels) and src/aiegraph/runtime/
    _sys.path.insert(0, _SRC)
from aiednn import path as _tplpath  # noqa: E402

_HERE = Path(__file__).resolve().parent  # UNet-only C text lives next to this file


ENTRY = "aiek_unetconv"


def log(msg):
    print(f"[build_unet/aie] {msg}", flush=True)


def ceil64(v):
    return (v + 63) // 64


# ─────────────────────────────── mapping ───────────────────────────────
def _stats(a):
    a = np.asarray(a, dtype=np.float64).ravel()
    return a.size, float(a.sum()), float((a * a).sum()), float(np.abs(a).sum())


def map_layers(onnx_path: Path, partition: dict, work: Path, offsets_fn) -> tuple:
    """partition layers -> TVM conv calls: (one dict per layer in partition order, all conv calls)."""
    import onnx
    from onnx import numpy_helper
    graphs = sorted(work.glob("*_graph.json"))
    assert len(graphs) == 1, graphs
    g = json.loads(graphs[0].read_text())
    params = graphs[0].with_name(graphs[0].name.replace("_graph.json", "_params.bin"))
    offs = offsets_fn(params)
    nodes, row_ptr = g["nodes"], g["node_row_ptr"]
    shapes = g["attrs"]["shape"][1]
    blob = np.memmap(params, dtype=np.uint8, mode="r")
    convs = []
    for i, n in enumerate(nodes):
        if n.get("op") != "tvm_op" or "conv2d_NCHWc" not in n["attrs"]["func_name"]:
            continue
        ins = [s for s, _, _ in n["inputs"]]
        pins = [s for s in ins if nodes[s]["op"] == "null" and nodes[s]["name"] in offs]
        w = max(pins, key=lambda s: offs[nodes[s]["name"]][1])
        wname = nodes[w]["name"]
        off, nb = offs[wname]
        st = _stats(np.frombuffer(blob[off:off + nb].tobytes(), dtype="<f4"))
        convs.append(dict(node=i, symbol="tvmgen_default_" + n["attrs"]["func_name"]
                          if not n["attrs"]["func_name"].startswith("tvmgen_") else n["attrs"]["func_name"],
                          func=n["attrs"]["func_name"], wname=wname, warg=ins.index(w),
                          nargs=len(ins) + int(n["attrs"].get("num_outputs", 1)),
                          wshape=shapes[row_ptr[w]], xshape=shapes[row_ptr[ins[0]]],
                          yshape=shapes[row_ptr[i]], stats=st))
    log(f"TVM graph {graphs[0].name}: {len(convs)} conv2d_NCHWc calls")

    m = onnx.load(str(onnx_path))
    inits = {t.name: t for t in m.graph.initializer}
    oconv = [n for n in m.graph.node if n.op_type == "Conv"]
    # ONNX Conv order == TVM conv call order (checked: same count, same O/I/KH/KW per
    # position, and the fp32 weight statistics agree wherever TVM did not fold a scale
    # into the weight -- FoldScaleAxis folds the GroupNorm affine into proj_in).
    assert len(oconv) == len(convs), (len(oconv), len(convs))
    by_name, folded = {}, []
    for n, c in zip(oconv, convs):
        w = numpy_helper.to_array(inits[n.input[1]])
        ws = c["wshape"]
        assert list(w.shape) == [ws[0] * ws[5], ws[1] * ws[4], ws[2], ws[3]], (n.name, w.shape, ws)
        st = _stats(w)
        same = (c["stats"][0] == st[0] and abs(c["stats"][1] - st[1]) <= 1e-6 * st[3] + 1e-9
                and abs(c["stats"][2] - st[2]) <= 1e-6 * st[2] + 1e-12)
        if not same:
            folded.append(n.name)
        by_name[n.name] = c
    assert all("proj_in" in x for x in folded), f"weight mismatch outside proj_in: {folded}"
    log(f"ONNX Conv -> TVM call by graph order: {len(convs)} pairs, shapes equal, weight stats equal "
        f"for {len(convs) - len(folded)} (the other {len(folded)} are proj_in, GN affine folded in by TVM)")
    onodes = {n.name: n for n in m.graph.node}
    out, used = [], set()
    for L in partition["layers"]:
        if L.get("cls") in ("linear", "attn"):
            continue   # PDN: map_linears; GATT: map_attn (autopart --mode attn partitions)
        n = onodes[L["node"]]
        assert n.op_type == "Conv" and n.input[1] == L["weight"], (L["node"], n.op_type)
        at = {a.name: onnx.helper.get_attribute_value(a) for a in n.attribute}
        assert at.get("group", 1) == 1 and list(at.get("dilations", [1, 1])) == [1, 1], at
        pads = list(at.get("pads", [0, 0, 0, 0]))
        assert pads[0] == pads[2] and pads[1] == pads[3], pads
        cand = [by_name[L["node"]]]
        c = cand[0]
        assert c["node"] not in used, c
        used.add(c["node"])
        ob, ib = c["wshape"][5], c["wshape"][4]
        O, C, KH, KW = c["wshape"][0] * ob, c["wshape"][1] * ib, c["wshape"][2], c["wshape"][3]
        M = c["yshape"][2] * c["yshape"][3]
        assert c["xshape"][1] * c["xshape"][4] == C and c["yshape"][1] * c["yshape"][4] == O, c
        assert [KH, KW] == list(at["kernel_shape"]), (KH, KW, at)
        launches = ceil64(M) * ceil64(O) * ceil64(C * KH * KW)
        mkn = L["mkn"][0]
        assert [M, C * KH * KW, O] == list(mkn), (L["node"], M, C * KH * KW, O, mkn)
        assert launches == L["launches"], (L["node"], launches, L["launches"])
        assert c["warg"] == 1, c
        out.append(dict(c, kind="conv", cid=L["idx"], onnx=L["node"], weight=L["weight"], launches=launches,
                        macs=M * O * C * KH * KW, sh=at["strides"][0], sw=at["strides"][1],
                        ph=pads[0], pw=pads[1], M=M, N=O, K=C * KH * KW))
    log(f"mapped {len(out)} partition layers to TVM calls")
    return out, convs


def kacc_split(N: int, K: int, Mp: int) -> tuple:
    """PDN: (S, px per launch) of a dense GEMM on ONE gemm_kacc instance (aiegraph.kincore.kacc_split)."""
    from aiegraph import kincore
    from aiegraph.errors import AiegraphError
    try:
        return kincore.kacc_split(N, K, Mp)
    except AiegraphError as e:
        raise SystemExit(str(e))


def map_linears(onnx_path: Path, partition: dict, work: Path, offsets_fn) -> list:
    """PDN: partition 'linear' layers (ONNX MatMul/Gemm with a constant weight) -> TVM nn_contrib_dense_pack
    calls (weight packed [N/nb][K][nb], arg 1). Matched by weight VALUE: the TVM fp32 param unpacked to [N][K]
    must equal the ONNX weight (MatMul B^T / Gemm B or B^T) exactly; a unique match per layer or the build fails."""
    import onnx
    from onnx import numpy_helper
    graphs = sorted(work.glob("*_graph.json"))
    assert len(graphs) == 1, graphs
    g = json.loads(graphs[0].read_text())
    params = graphs[0].with_name(graphs[0].name.replace("_graph.json", "_params.bin"))
    offs = offsets_fn(params)
    nodes, row_ptr = g["nodes"], g["node_row_ptr"]
    shapes = g["attrs"]["shape"][1]
    blob = np.memmap(params, dtype=np.uint8, mode="r")
    dense = {}   # (N, K) -> list of TVM calls
    ndense = 0
    for i, n in enumerate(nodes):
        if n.get("op") != "tvm_op" or "dense" not in n["attrs"]["func_name"]:
            continue
        ndense += 1
        ins = [s for s, _, _ in n["inputs"]]
        w = ins[1]
        if nodes[w]["op"] != "null" or nodes[w]["name"] not in offs:
            continue   # weight computed at run time (time embedding, M=1): stays on the CPU
        ws, xs, ys = shapes[row_ptr[w]], shapes[row_ptr[ins[0]]], shapes[row_ptr[i]]
        if len(ws) != 3 or len(xs) != 2 or len(ys) != 2:
            continue
        N, K = ws[0] * ws[2], ws[1]
        f = n["attrs"]["func_name"]
        dense.setdefault((N, K), []).append(dict(
            node=i, symbol=f if f.startswith("tvmgen_") else "tvmgen_default_" + f, func=f,
            wname=nodes[w]["name"], warg=1, nargs=len(ins) + int(n["attrs"].get("num_outputs", 1)),
            wshape=ws, xshape=xs, yshape=ys))
    log(f"TVM graph {graphs[0].name}: {ndense} dense calls, {sum(len(v) for v in dense.values())} with a param weight")
    m = onnx.load(str(onnx_path))
    inits = {t.name: t for t in m.graph.initializer}
    onodes = {n.name: n for n in m.graph.node}
    out, used = [], set()
    for L in partition["layers"]:
        if L.get("cls") != "linear":
            continue
        n = onodes[L["node"]]
        assert n.op_type in ("MatMul", "Gemm") and L["weight"] in n.input, (L["node"], n.op_type)
        b = numpy_helper.to_array(inits[L["weight"]]).astype(np.float32)
        at = {a.name: onnx.helper.get_attribute_value(a) for a in n.attribute}
        wnk = b if (n.op_type == "Gemm" and at.get("transB", 0)) else b.T   # natural W [N][K]
        M, K, N = L["pad"]["orig"] if "pad" in L else L["mkn"][0]
        assert wnk.shape == (N, K), (L["node"], wnk.shape, N, K)
        hit = []
        for c in dense.get((N, K), []):
            if c["node"] in used or c["xshape"][0] != M:
                continue
            off, nb = offs[c["wname"]]
            on, kk, ob = c["wshape"]
            pk = np.frombuffer(blob[off:off + nb].tobytes(), dtype="<f4").reshape(on, kk, ob)
            if np.array_equal(pk.transpose(0, 2, 1).reshape(N, K), wnk):
                hit.append(c)
        assert len(hit) == 1, f"linear {L['node']} ({L['weight']} M={M} K={K} N={N}): {len(hit)} TVM matches"
        c = hit[0]
        used.add(c["node"])
        assert c["yshape"] == [M, N], (L["node"], c["yshape"])
        S, pxs = kacc_split(N, K, -(-M // 64) * 64)
        out.append(dict(c, kind="linear", cid=L["idx"], onnx=L["node"], weight=L["weight"], launches=S, S=S,
                        pxs=pxs, macs=M * N * K, M=M, N=N, K=K, sh=1, sw=1, ph=0, pw=0))
    log(f"mapped {len(out)} partition linear layers to TVM dense calls (weights equal by value), "
        f"{sum(c['S'] for c in out)} gemm_kacc launches")
    return out


# GATT / GFA attention sites + driver glue: aiegraph.attnsite / aiegraph.flashattn (unet-decl P3); old names kept
# for the bench and the runtime tests
from aiegraph.attnsite import ATTN_HOST, attn_shapes, bmm_geom, prof_c_attn  # noqa: E402,F401
from aiegraph import boardmain as _bm  # noqa: E402

PROF_C = _bm.prof_c()


def check_data_arg0(layers_dir: Path, sel: list) -> None:
    """The TVM kernel's conv reads its activation from p0: aiegraph.callsite.check_conv_arg0."""
    from aiegraph.callsite import check_conv_arg0
    n = check_conv_arg0(layers_dir, [c["symbol"] for c in sel])
    log(f"checked {n} TVM conv kernels: activation = arg 0, weight = arg 1")


# ─────────────────────────────── kernel source ───────────────────────────────
# unet-decl P4: the 64x64x64 tile path (HOST_CC, REF_C, kernel_text, kt_select, write_kernel) is off the build
# (build_unet.py needs --kincore); it can be recovered at d5e9f15. The --ctrlpkt pragmas come from aiegraph.kincore.
from aiegraph import kincore as _kincore  # noqa: E402

# --ctrlpkt aot-kco (build_unet.py) / UNET_CTRLPKT_KCO=1 in the env (kacc_bench.sh -> kacc_gemm.py): the same 5
# pragmas + KERNELCONFIGOFFLOAD (the core programs its own DMA, .TM in kernel.lst); one switch for probe and full net
CTRLPKT_KCO = os.environ.get("UNET_CTRLPKT_KCO", "0") == "1"
CTRLPKT_PRAGMAS = _kincore.ctrlpkt_head("aot-kco" if CTRLPKT_KCO else "aot")
CTRLPKT_NPRAGMAS = _kincore.ctrlpkt_npragmas("aot-kco" if CTRLPKT_KCO else "aot")


# ─────────────────────────────── --kincore (P4bg) ───────────────────────────────
# One launch per conv layer, K accumulated in the core: Maxwell's gemm_kacc (bf16_gemm_kacc.cc,
# P4bk) instantiated per distinct layer GEMM shape. The kernel runs the transposed GEMM
# Y[ch][px] = W[ch,:] . X[px,:]; Maxwell's c013 kernel walks 16-row channel tiles on each core
# (px = 64 = 4 mesh cols x 16); here each core also walks px/64 16-wide pixel tiles (kplan's
# per-layer walk of 64x64 output macro tiles). Host: im2col + pre-tiling (bf16) only; NO K-sum.
KACC_CC = _tplpath("gemm/gemm_kacc_kernel.cc")


def kacc_name(ch: int, k: int, px: int) -> str:
    """the launch callee of instance (ch, k, px): aiegraph.kincore.kacc_name"""
    from aiegraph import kincore
    return kincore.kacc_name(ch, k, px)


def kacc_geom(ch: int, k: int, px: int) -> dict:
    """walk of one gemm_kacc launch on the 4x4 mesh: aiegraph.cnn.kacc_geom (the C window rule of
    GAP-aiehlc-tilinglinalg-a45e5b is aiegraph.kincore.c_window); a shape without a walk raises AssertionError
    here (kacc_gemm.fits / plan catch it)."""
    from aiegraph import cnn
    from aiegraph.errors import AiegraphError
    try:
        return cnn.kacc_geom(ch, k, px)
    except AiegraphError as e:
        raise AssertionError(str(e))


KACC_KERNEL = _kincore.KACC_KERNEL   # C++ template __global__: aiehlc instantiates it per launch


def write_kernel_kacc(kdst: Path, spec: str, shapes: list, warm: bool = False, ctrlpkt: str = "off",
                      lin: list = (), att: list = (), fa: list = ()) -> Path:
    """--kincore: aiek_unetconv.cc from aiegraph.kincore.write_source (one gemm_kacc instance per distinct
    (ch, K, px), conv / linear host); att / fa: the attention parts (aiegraph.attnsite / aiegraph.flashattn)"""
    from aiegraph import kincore
    if ctrlpkt == "aot" and CTRLPKT_KCO:
        ctrlpkt = "aot-kco"
    from aiegraph import attnsite, flashattn
    kw = flashattn.fa_kernel_parts(fa) if fa else attnsite.attn_kernel_parts(att) if att else {}
    return kincore.write_source(kdst, spec, shapes, entry=ENTRY, warm=warm, ctrlpkt=ctrlpkt, lin=lin, **kw)

