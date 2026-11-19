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
from aiednn import path as _tplpath, runtime_source as _rt, template as _tpl  # noqa: E402

_HERE = Path(__file__).resolve().parent  # UNet-only C text lives next to this file


def _local(fn):
    with open(_HERE / fn, encoding="utf-8", newline="") as f:
        return f.read()


P2K = _HERE / "bf16_gemm_convin.cc"  # 64x64 ports (8e7254d, board PASS p0_board.log)
P2K_KT = _HERE / "bf16_gemm_convin_ktimer.cc"  # --ktimer: core timer tail, b 80x64 / c 64x80
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


# ─────────────────────── GATT: attention bmm sites (--aie conv,linear,attn) ───────────────────────
def bmm_geom(H: int, M: int, K: int, N: int) -> dict:
    """GATT: geometry of one attention bmm Y[h] = X[h] (M x K) . W[h]^T (W [N][K]) on ONE gemm_kacc instance --
    the board-proven PBK rules of kacc_gemm.main_bmm (fd4cb96): M/K/N zero-padded to 64 (aiegraph.gemmpad.pad_mkn),
    swap (ch = M) for big square outputs, kacc_gemm.plan split, one more zero ch block when the a/b ports would
    have the same shape (aiehlc GemmSpace port sizing), K padded until kp/2 is not 32/64 (aiehlc 2-dim+iter b BD)."""
    import sys
    src = str(Path(__file__).resolve().parents[3] / "src")
    if src not in sys.path:
        sys.path.insert(0, src)
    from aiegraph.gemmpad import pad_mkn
    import kacc_gemm
    Mp, Kp, Np = pad_mkn(M, K, N)
    swap = int(Mp == Np and H * M * N >= (4 << 20))
    CHR, PXR = (M, N) if swap else (N, M)
    CHP, PXP = (Mp, Np) if swap else (Np, Mp)
    mode, S, chs, pxs = kacc_gemm.plan(CHP, Kp, PXP)
    geo = kacc_geom(chs, Kp, pxs)
    while geo["arows"] == geo["brows"] and mode == "none":
        CHP += 64
        mode, S, chs, pxs = kacc_gemm.plan(CHP, Kp, PXP)
        geo = kacc_geom(chs, Kp, pxs)
    while geo["kp"] // 2 in (32, 64):
        Kp += 64
        geo = kacc_geom(chs, Kp, pxs)
    return dict(H=H, M=M, K=K, N=N, swap=swap, CHR=CHR, PXR=PXR, CHP=CHP, PXP=PXP, Kp=Kp, kp=geo["kp"],
                kch=geo["kch"], tr=geo["tr"], splitpx=int(mode == "px"), S=S, chs=chs, pxs=pxs)


def map_attn(partition: dict, work: Path, onnx=None) -> list:
    """GATT (GAP-aiegraph-attn-site), sprint unet-m3 S3: the matching moved into aiegraph --
    ``aiegraph.attention.partition_attention`` finds the attention groups on graph.json (+ ONNX for the
    Q/K/V sources and the scale) and joins the partition 'attn' rows to their TVM nn_batch_matmul calls by
    ONNX node name. Here only the kernel geometry is added (bmm_geom). ``ag_group`` = the AttentionGroup."""
    import sys
    src = str(Path(__file__).resolve().parents[3] / "src")
    if src not in sys.path:
        sys.path.insert(0, src)
    from aiegraph.attention import partition_attention
    from aiegraph.group import CallGraph
    cg = CallGraph.load(work)
    att = partition_attention(cg, partition, onnx=onnx, workdir=work)
    log(f"TVM graph: {len(att)} attention bmm calls in {len({c['ag_group'].name for c in att})} aiegraph attention "
        f"groups ({sum(len(g.calls) for g in {c['ag_group'].name: c['ag_group'] for c in att}.values())} calls)")
    out = []
    for c in att:
        H, M, K, N = c["H"], c["M"], c["K"], c["N"]
        geo = bmm_geom(H, M, K, N)
        out.append(dict(c, geo=geo, launches=H * geo["S"], macs=H * M * N * K))
    log(f"mapped {len(out)} partition attn bmm layers ({len({c['group'] for c in out})} groups) to TVM "
        f"nn_batch_matmul calls, {sum(c['launches'] for c in out)} gemm_kacc launches")
    return out


def attn_shapes(att: list) -> list:
    """gemm_kacc instances (ch, K, px) of the attention sites"""
    return sorted({(c["geo"]["chs"], c["geo"]["Kp"], c["geo"]["pxs"]) for c in att})


def check_data_arg0(layers_dir: Path, sel: list) -> None:
    """The TVM kernel's conv reads its activation from p0 (not a residual/temb arg)."""
    for sym in sorted({c["symbol"] for c in sel}):
        hits = [p for p in layers_dir.glob("*/*.c") if f" {sym}(void* args" in p.read_text()]
        assert len(hits) == 1, (sym, hits)
        t = hits[0].read_text()
        src = set()
        for line in t.splitlines():
            if "p1_1)[" in line and "*" in line:
                src |= {x for x in re.findall(r"\(\(float\*\)(\w+)\)\[", line) if x != "p1_1"}
        if "data_pad" in src:
            src.discard("data_pad")
            for line in t.splitlines():
                if re.search(r"condval = |data_pad\)\[.*\] = ", line):
                    src |= set(re.findall(r"\(\(float\*\)(p\d+_1)\)\[", line))
        assert src == {"p0_1"}, f"{sym} ({hits[0].name}): conv activation from {src}, expected p0_1"
    log(f"checked {len({c['symbol'] for c in sel})} TVM conv kernels: activation = arg 0, weight = arg 1")


# ─────────────────────────────── kernel source ───────────────────────────────
HOST_CC = (_tpl("conv2d/tile64_conv_host.cc") + _tpl("elementwise/epilogue_bias_residual.cc") + _tpl("conv2d/tile64_conv_entry.cc"))

REF_C = _tpl("conv2d/conv_bf16_carrier_ref.c")


def kernel_text(ktimer: bool = False) -> str:
    src = (P2K_KT if ktimer else P2K).read_text()
    m = re.search(r"(__global__ void gemm_bf16\(.*?\n\})\s*\n\s*int main\(", src, re.S)
    assert m, "gemm_bf16 not found"
    return m.group(1)


SOFTFLOAT_RM = _local("softfloat_rm_reset.cc")


CTRLPKT_PRAGMAS = (  # --ctrlpkt aot (P2a): spelled as aiehlc prints them (src/llvm/aiehlc.cc); no KERNELCONFIGOFFLOAD (P3)
    _tpl("gemm/ctrlpkt_aot_pragmas.h"))
# --ctrlpkt aot-kco (build_unet.py) / UNET_CTRLPKT_KCO=1 in the env (kacc_bench.sh -> kacc_gemm.py): the same 5
# pragmas + KERNELCONFIGOFFLOAD (the core programs its own DMA, .TM in kernel.lst); one switch for probe and full net
CTRLPKT_KCO = os.environ.get("UNET_CTRLPKT_KCO", "0") == "1"
if CTRLPKT_KCO:
    CTRLPKT_PRAGMAS += _tpl("gemm/ctrlpkt_kco_pragma.h")
CTRLPKT_NPRAGMAS = CTRLPKT_PRAGMAS.count("#pragma")


def kt_select(text: str, ktimer: bool) -> str:
    """keep /*KT+*/../*KT-*/ spans with --ktimer, /*NK+*/../*NK-*/ spans without; drop the other"""
    keep, drop = (("KT", "NK") if ktimer else ("NK", "KT"))
    text = re.sub(r"/\*%s\+\*/.*?/\*%s-\*/" % (drop, drop), "", text, flags=re.S)
    text = text.replace("/*%s+*/" % keep, "").replace("/*%s-*/" % keep, "")
    assert "/*KT" not in text and "/*NK" not in text
    return text


def write_kernel(kdst: Path, spec: str, maxacc: int, warm: bool = False, ctrlpkt: str = "off",
                 ktimer: bool = False) -> Path:
    spec = spec.replace('"out ', '"export    aiednn_aie_conv\\n"\n        "export    aiednn_aie_stats\\n"\n'
                        '        "export    aiednn_aie_launch_stats\\n"\n'
                        '        "export    aiednn_aie_host_split_site\\n"\n'
                        '        "export    aiednn_aie_host_split_line\\n"\n' +
                        ('        "export    aiednn_aie_ktimer_stats\\n"\n' if ktimer else '') +
                        '        "export    aiednn_aie_split_stats\\n"\n        "out ', 1)
    assert "export    aiednn_aie_conv" in spec, spec
    kdst.mkdir(parents=True, exist_ok=True)
    kcc = kdst / f"{ENTRY}.cc"
    head = _local("tile64_conv_head.cc").replace("@E@", ENTRY).replace("@SRC@", str(P2K_KT if ktimer else P2K))
    if ctrlpkt == "aot":
        head = CTRLPKT_PRAGMAS + head
    ktext = kernel_text(ktimer)
    if warm:
        i = ktext.index(") {\n") + len(") {\n")
        ktext = ktext[:i] + SOFTFLOAT_RM + ktext[i:]
    kcc.write_text(head + ktext + "\n" + kt_select(HOST_CC, ktimer).replace("@MAXACC@", str(maxacc)).replace("@WARM@", "1" if warm else "0")
                   .replace("@CTRLPKT@", "1" if ctrlpkt == "aot" else "0")
                   .replace("@PART_C0@", "2" if ctrlpkt == "aot" else "3")
                   .replace("@E@", ENTRY).replace("@SPEC@", spec))
    (kdst / f"{ENTRY}_ref.c").write_text(REF_C.replace("@E@", ENTRY))
    return kcc


# ─────────────────────────────── driver patch ───────────────────────────────
DECL = ("int aiednn_aie_conv(int cid, void *args, int nargs, const uint16_t *wbf, "
        "int sh, int sw, int ph, int pw);   /* build_unet.py --aie conv */\n"
        "int aiednn_aie_linear(int cid, void *args, int nargs, const uint16_t *wbf, int S);   /* --aie conv,linear */\n")
DECL_ATTN = ("int aiednn_aie_attn(int cid, void *args, int nargs, int qk, int swap, int chp, int pxp, int kk, int kp, "
             "int kch, "
             "int splitpx, int S, int chs, int pxs, int tr);   /* --aie conv,linear,attn (GATT) */\n")
CALL_RE = re.compile(r"    GRAPH_PROF_BEGIN\((\d+)\);\n(#ifdef GRAPH_AIE_OFFLOAD\n.*?#endif\n|"
                     r"    \w+\(args, codes, \d+, 0, 0, 0\);\n    GRAPH_PROF_END\(\1, \"[^\"]*\"\);\n)", re.S)


def patch_driver(text: str, sel: list) -> tuple:
    """The text patches aiegraph does not do yet. S1 (unet-m3): when aiegraph already placed the
    conv / linear group steps (its declarations sit before kernel_ws), only the attention sites,
    the attention declaration and the PROF glue are added here; *sel* must then hold attn layers
    only. Without aiegraph steps (test_attn_sites.py) the conv / linear sites are patched as before."""
    head = text.split("static uint8_t kernel_ws[")[0]
    if "UP_AIE_BEGIN(" in head or "up_pending_exp" in head:
        raise RuntimeError("driver already patched")
    ag_steps = "int aiednn_aie_conv(int cid, void" in head
    att = [c for c in sel if c.get("kind") == "attn"]
    sel = [c for c in sel if c.get("kind") != "attn"]
    if ag_steps and sel:
        raise RuntimeError("aiegraph placed the conv/linear steps: patch_driver takes attn layers only")
    i = text.index("static uint8_t kernel_ws[")
    # GATT: the attn declaration / PROF branch only when there are attn sites (--aie conv,linear stays byte-identical)
    fam = bool(att) and all(c.get("fa") is not None for c in att)   # GFA: fused flash-attention sites
    if fam:
        import fa_attn
        # S3: the FA groups are aiegraph group offloads (build_unet.fa_offload_groups): arm_build already placed
        # their steps and removed the other calls (softmax included); only the declarations are added here
        assert all(c.get("fa_steps") for c in att), "GFA sites must be aiegraph group steps"
    text = text[:i] + ("" if ag_steps else DECL) + ((fa_attn.DECL_FA + fa_attn.DECL_KL if fam else DECL_ATTN) if att else "") + \
        (prof_c_attn() if att else PROF_C) + "\n" + text[i:]
    exp_body = "    for (uint64_t i = 0; i < n; ++i) d[i] = (uint32_t)src[i] << 16;\n}\n"
    assert text.count(exp_body) == 1, text.count(exp_body)
    text = text.replace(exp_body, "    XTime e0_, e1_;\n    XTime_GetTime(&e0_);\n" + exp_body[:-2] +
                        "    XTime_GetTime(&e1_);\n    up_pending_exp += e1_ - e0_;\n    up_exp_calls++;\n}\n", 1)
    run = "float *graph_run(void) {\n"
    assert text.count(run) == 1
    text = text.replace(run, run + "    up_pending_exp = 0; /* P1 PROF: expands before graph_run are not graph_run time */\n", 1)
    n = 0
    for c in sel:
        m = re.search(r"    tensors\[(\d+)\]\.data = 0;   /\* %s: bf16 @(\d+)\+(\d+) B" % re.escape(c["wname"]), text)
        assert m, f"no bf16 init line for {c['wname']}"
        eid, off, nb = int(m.group(1)), int(m.group(2)), int(m.group(3))
        c["woff"] = off   # P4w: aiegraph.wlayout.prelayout_weights rewrites this bf16 region of weights.bin
        wel = 1
        for d in c["wshape"]:
            wel *= d
        assert nb == 2 * wel, (c["wname"], nb, wel)
        exp = re.compile(r"    graph_bf16_expand\(\(float \*\)\(g_wscratch \+ (\d+)\), \(const uint16_t \*\)"
                         r"\(g_params \+ %d\), %dULL\);\n    tensors\[%d\]\.data = g_wscratch \+ \1;\n" % (off, wel, eid))
        hits = exp.findall(text)
        assert len(hits) == 1, (c["wname"], len(hits))
        text = exp.sub("    tensors[%d].data = 0;   /* AIE conv %d: bf16 weight read in place by aiednn_aie_conv */\n"
                       % (eid, c["cid"]), text)
        a1 = "    args[1].v_handle = &tensors[%d];\n" % eid
        assert text.count(a1) == 1, (c["wname"], text.count(a1))
        pos = text.index(a1)
        cm = CALL_RE.search(text, pos)
        nxt = text.find("    args[0].v_handle", pos)
        assert cm and (nxt < 0 or cm.start() < nxt), c["wname"]
        calls = re.findall(r"(?:aie_)?(tvmgen_\w+)\(args, codes, (\d+), 0, 0, 0\);", cm.group(2))
        assert calls and all(s == c["symbol"] and int(k) == c["nargs"] for s, k in calls), (calls, c["symbol"])
        if c.get("kind") == "linear":   # PDN: tag "aie aiednn_aie_lin <cid>" -> PROF op=aie_host_linear<cid>
            rep = ("    GRAPH_PROF_BEGIN(%s);\n    UP_AIE_BEGIN(%s);\n"
                   "    aiednn_aie_linear(%d, args, %d, (const uint16_t *)(g_params + %d), %d);\n"
                   "    UP_AIE_END(%s);\n    GRAPH_PROF_END(%s, \"aie aiednn_aie_lin %d\");\n"
                   % (cm.group(1), cm.group(1), c["cid"], c["nargs"], off, c["S"], cm.group(1), cm.group(1), c["cid"]))
        else:
            rep = ("    GRAPH_PROF_BEGIN(%s);\n    UP_AIE_BEGIN(%s);\n"
                   "    aiednn_aie_conv(%d, args, %d, (const uint16_t *)(g_params + %d), %d, %d, %d, %d);\n"
                   "    UP_AIE_END(%s);\n    GRAPH_PROF_END(%s, \"aie aiednn_aie_conv %d\");\n"
                   % (cm.group(1), cm.group(1), c["cid"], c["nargs"], off, c["sh"], c["sw"], c["ph"], c["pw"],
                      cm.group(1), cm.group(1), c["cid"]))
        text = text[:cm.start()] + rep + text[cm.end():]
        n += 1
    nl = sum(1 for c in sel if c.get("kind") == "linear")
    if not ag_steps:
        assert text.count("    aiednn_aie_conv(") == len(sel) - nl and text.count("    aiednn_aie_linear(") == nl
    if fam:   # S3: count the group steps arm_build emitted (2 per bmm site: pack_q+pack_k / pack_v+run_o)
        nkl = len(re.findall(r"^    aiednn_aie_attn_kl\(", text, re.M))
        assert nkl == 2 * len(att), (nkl, len(att))
        assert not re.search(r"\btvmgen_default_fused_nn_(softmax|batch_matmul)\w*\(args, ",
                             text.split("float *graph_run(void)")[1]), "attention call left in graph_run"
        return text, n + len(att)
    for c in att:   # GATT: tag "aie aiednn_aie_attn <cid>" -> PROF op=aie_host_attn<cid>
        text = _patch_attn_site(text, c)
        n += 1
    assert text.count("    aiednn_aie_attn(") == len(att)
    return text, n


def _patch_attn_site(text: str, c: dict) -> str:
    """GATT: one TVM nn_batch_matmul call site (located by its unique args[0..2] tensor block) -> aiednn_aie_attn.
    No weight: both operands are activations, packed at run time by the host (aie_kacc_pack.h)."""
    e0, e1 = c["eids"]
    blk = ("    args[0].v_handle = &tensors[%d];\n    args[1].v_handle = &tensors[%d];\n"
           "    args[2].v_handle = &tensors[%d];\n" % (e0, e1, c["yeid"]))
    assert text.count(blk) == 1, (c["onnx"], c["node"], text.count(blk))
    pos = text.index(blk)
    cm = CALL_RE.search(text, pos)
    nxt = text.find("    args[0].v_handle", pos + len(blk))
    assert cm and (nxt < 0 or cm.start() < nxt), (c["onnx"], c["node"])
    calls = re.findall(r"(?:aie_)?(tvmgen_\w+)\(args, codes, (\d+), 0, 0, 0\);", cm.group(2))
    assert calls and all(s == c["symbol"] and int(k) == c["nargs"] for s, k in calls), (calls, c["symbol"])
    if c.get("fa") is not None:  # GFA: role 0 = QK (pack Q, K), role 1 = PV (pack V, launch, write O)
        rep = ("    GRAPH_PROF_BEGIN(%s);\n    UP_AIE_BEGIN(%s);\n"
               "    aiednn_aie_attn(%d, args, %d, %d, %d);   /* fa %s g%d %s */\n"
               "    UP_AIE_END(%s);\n    GRAPH_PROF_END(%s, \"aie aiednn_aie_attn %d\");\n"
               % (cm.group(1), cm.group(1), c["cid"], c["nargs"], int(c["role"] == "pv"), c["fa"], c["role"],
                  c["group"], c["onnx"].replace("*/", "*_/"), cm.group(1), cm.group(1), c["cid"]))
        return text[:cm.start()] + rep + text[cm.end():]
    g = c["geo"]
    rep = ("    GRAPH_PROF_BEGIN(%s);\n    UP_AIE_BEGIN(%s);\n"
           "    aiednn_aie_attn(%d, args, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d);   /* %s g%d %s */\n"
           "    UP_AIE_END(%s);\n    GRAPH_PROF_END(%s, \"aie aiednn_aie_attn %d\");\n"
           % (cm.group(1), cm.group(1), c["cid"], c["nargs"], int(c["role"] == "qk"), g["swap"], g["CHP"], g["PXP"],
              g["Kp"], g["kp"], g["kch"], g["splitpx"], g["S"], g["chs"], g["pxs"], g["tr"], c["role"], c["group"],
              c["onnx"].replace("*/", "*_/"), cm.group(1), cm.group(1), c["cid"]))
    return text[:cm.start()] + rep + text[cm.end():]


# P1 (b) per-call-site A78 time (graph_driver.c PROF glue) and the board main are generated by
# aiegraph.boardmain (unet-m4 P4); kept here under their old names for patch_driver / test_host_split.
from aiegraph import boardmain as _bm  # noqa: E402

PROF_C = _bm.prof_c()


def prof_c_attn() -> str:
    """PROF_C with the GATT branch: attention sites print op=aie_host_attn<cid> (counted as aie_host by hsplit)"""
    return _bm.prof_c(attn=True)


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


KACC_KERNEL = _tpl("gemm/gemm_kacc_kernel.cc")   # C++ template __global__: aiehlc instantiates it per launch


def write_kernel_kacc(kdst: Path, spec: str, shapes: list, warm: bool = False, ctrlpkt: str = "off",
                      lin: list = (), att: list = (), fa: list = ()) -> Path:
    """--kincore: aiek_unetconv.cc from aiegraph.kincore.write_source (one gemm_kacc instance per distinct
    (ch, K, px), conv / linear host); att / fa: the attention parts (fa_attn) passed as its extra parts"""
    from aiegraph import kincore
    if ctrlpkt == "aot" and CTRLPKT_KCO:
        ctrlpkt = "aot-kco"
    kw = {}
    if att:
        kw["exports"] = ("aiednn_aie_attn",) + (("aiednn_aie_attn_kl",) if fa else ())
    if fa:  # GFA (--attn-fa): flash-attention prologue, the fa_kernel template, the FA host entries
        import fa_attn
        kw.update(prologue=fa_attn.fa_prologue(fa) + "\n", kernels="\n\n" + fa_attn.FA_KERNEL,
                  host_entries=fa_attn.fa_host(fa).lstrip("\n"))
    elif att:
        kw.update(host_entries=ATTN_HOST.lstrip("\n"),
                  bufs=[(g["CHP"] * g["kp"], g["PXP"] * g["kp"], g["CHP"] * g["PXP"]) for g in (c["geo"] for c in att)])
    return kincore.write_source(kdst, spec, shapes, entry=ENTRY, warm=warm, ctrlpkt=ctrlpkt, lin=lin, **kw)


ATTN_HOST = _tpl("attention/kacc_bmm_host.cc")


# S6 (unet-m3) / P4 (unet-m4): the driver template is aiegraph.boardmain.driver_glue.
def driver_template(att: list) -> dict:
    """``emod.driver_template(**driver_template(att))`` (old name): *att* must be the GFA (``fa``)
    attention layers placed as aiegraph FA group steps, or empty."""
    if att and not all(c.get("fa") is not None and c.get("fa_steps") for c in att):
        raise ValueError("driver_template: attention layers must be aiegraph FA group steps (--attn-fa)")
    import fa_attn
    return _bm.driver_glue(fa_attn.DECL_FA + fa_attn.DECL_KL if att else "", attn=bool(att))
