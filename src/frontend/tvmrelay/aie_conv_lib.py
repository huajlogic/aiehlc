###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Offload ANY fused conv layer: AIE basic op + TVM's own epilogue.

Every ResNet-18 conv layer TVM emits is one fused C function of the form

    acc = conv(x, w)                         int8 x int8 -> int32   <- the work
    out = tail(acc, params, other inputs)    element-wise           <- the variety

and the tails differ a lot between layers (bias / two zero-points / per-channel
requantize, then optionally +zp, ReLU, a second fixed-point multiply, a
residual input requantized and added, clip, cast -- with layer-specific
literal constants). Writing a hand AIE kernel per fused op means writing (and
keeping bit-exact) 18 of those.

So the split is made at the one boundary every layer shares:

* the **conv** goes to the AIE through ONE basic op,
  ``src/aietensorop/convgemm`` (``conv2d_nchwc_i8``: host im2col + a fixed
  256x64x256 int8 GEMM tile on the mesh, tiled on the host for any shape);
* the **tail** stays TVM's own generated C, *transplanted*: the layer's
  function is copied, its multiply-accumulate statements are deleted, and
  every read of the accumulator becomes ``aie_acc[<index of the element this
  statement stores>]``. The tail is element-wise and the accumulator has the
  output's layout, so that index is exact -- and every constant, every
  rounding rule and every cast stays TVM's.

Per layer this writes ``layers/NN_op/aie/`` with ``tail.c``, ``entry.c`` and a
README, and proves the pair bit-exact against the untouched TVM function on
x86 (``verify_layer``: real parameters, random activations, the AIE tile
replaced by a scalar loop inside the SAME host tiling code).
"""

from __future__ import annotations

import json
import re
import subprocess
import tempfile
from pathlib import Path

import numpy as np

from frontend.tvmrelay.aiehlc_build import REPO, aiehlc_build, isolate_archive

__all__ = ["CONVGEMM_SOURCE", "CONVGEMM_API", "build_shared", "transplant_tail",
           "conv_geometry", "build_conv_layer", "verify_layer", "entry_symbol"]

CONVGEMM_DIR = REPO / "src" / "aietensorop" / "convgemm"
CONVGEMM_SOURCE = CONVGEMM_DIR / "convgemm.cc"
#: The only globals libconvgemm.a keeps after isolation.
CONVGEMM_API = ("conv2d_nchwc_i8", "convgemm_i8i32", "convgemm_launch_count")

_SIG = ("(void* args, int32_t* arg_type_ids, int32_t num_args, "
        "void* out_ret_value, int32_t* out_ret_tcode, void* resource_handle")


def entry_symbol(func_name: str) -> str:
    """The AIE entry that replaces TVM kernel *func_name* in graph_driver.c."""
    return f"aie_{func_name}"


# ═══════════════════════════════════════════════════════════════════════════
#  Shared basic op: one aiehlc build per run
# ═══════════════════════════════════════════════════════════════════════════

def build_shared(out_dir, verbose: bool = True) -> dict:
    """aiehlc-build convgemm.cc into ``<out_dir>/aie_ops/convgemm/`` and isolate it.

    Returns ``{"ok", "archive"|"reason", "dir"}``. The archive keeps only
    :data:`CONVGEMM_API` global (``aiehlc_build.isolate_archive``).
    """
    dest = Path(out_dir) / "aie_ops" / "convgemm"
    res = aiehlc_build(CONVGEMM_SOURCE, dest, dest.parent / "convgemm_aiehlc.log")
    if not res["ok"]:
        return {**res, "dir": str(dest)}
    lib = dest / "build" / "libconvgemm.a"
    if not lib.is_file():
        return {"ok": False, "dir": str(dest),
                "reason": f"aiehlc built no {lib.name} (see {res['log']})"}
    iso = isolate_archive(lib, CONVGEMM_API)
    if verbose and iso["ok"]:
        print(f"  [aiegraph] shared basic op: aiehlc {CONVGEMM_SOURCE.name} -> "
              f"aie_ops/convgemm/build/{lib.name} ({lib.stat().st_size / 1024:,.0f} KB, "
              f"isolated: {', '.join(CONVGEMM_API)})")
    return {**iso, "dir": str(dest)}


# ═══════════════════════════════════════════════════════════════════════════
#  Tail transplant
# ═══════════════════════════════════════════════════════════════════════════

_ARG_RE = re.compile(r"void\* (\w+) = \(\(\(TVMValue\*\)args\)\[(\d+)\]\.v_handle\);")
_MAC_RE = re.compile(r"^\s*(?P<lhs>\(\(int32_t\*\)(?P<n1>conv2d_NCHWc\w*)\)|(?P<n2>conv2d_NCHWc\w*))"
                     r"\[[^=]*\] = \(.*\(\(int8_t\*\)(?P<a>p\d+)_1\)\[.*\* \(\(int32_t\)"
                     r"\(\(int8_t\*\)(?P<w>p\d+)_1\)\[")


def _bracket_end(text: str, open_idx: int) -> int:
    """Index of the ``]`` matching ``text[open_idx] == '['``."""
    depth = 0
    for i in range(open_idx, len(text)):
        if text[i] == "[":
            depth += 1
        elif text[i] == "]":
            depth -= 1
            if depth == 0:
                return i
    raise ValueError("unbalanced [")


def _replace_acc_reads(line: str, names, idx: str) -> tuple:
    """Rewrite every ``NAME[...]`` / ``((int32_t*)NAME)[...]`` read to ``aie_acc[(idx)]``."""
    count = 0
    for name in names:
        for pat in (f"((int32_t*){name})[", f"{name}["):
            pos = line.find(pat)
            while pos >= 0:
                # do not match a longer identifier (conv2d_NCHWc vs conv2d_NCHWc_global)
                prev = line[pos - 1] if pos > 0 else " "
                if pat[0] != "(" and (prev.isalnum() or prev == "_"):
                    pos = line.find(pat, pos + 1)
                    continue
                end = _bracket_end(line, pos + len(pat) - 1)
                line = f"{line[:pos]}aie_acc[({idx})]{line[end + 1:]}"
                count += 1
                pos = line.find(pat, pos + 1)
    return line, count


def _block_start(lines: list, at: int) -> int:
    """First line of the innermost ``{ ... }`` block containing line *at*."""
    depth = 0
    for i in range(at - 1, -1, -1):
        depth += lines[i].count("}") - lines[i].count("{")
        if depth < 0:
            return i + 1
    return 0


def transplant_tail(c_src: str, symbol: str) -> tuple:
    """TVM layer C -> (tail C, info). Raises ValueError when it cannot be exact.

    *info*: ``{"act_slot", "wgt_slot", "out_slot", "num_args", "macs",
    "acc_reads", "stores"}``. The tail function is ``aie_tail_<symbol>`` with
    TVM's packed signature plus a trailing ``const int32_t *aie_acc``.
    """
    lines = c_src.splitlines()
    args = {m.group(1): int(m.group(2)) for m in map(_ARG_RE.search, lines) if m}
    if not args:
        raise ValueError("no TVMValue argument unpacking found")
    out_slot = max(args.values())
    out_name = next(n for n, s in args.items() if s == out_slot)

    acc_names, act, wgt, macs = set(), set(), set(), 0
    for i, line in enumerate(lines):
        m = _MAC_RE.match(line)
        if m:
            acc_names.add(m.group("n1") or m.group("n2"))
            act.add(m.group("a"))
            wgt.add(m.group("w"))
            lines[i] = "    ; /* conv MAC removed: the accumulator comes from the AIE (aie_acc) */"
            macs += 1
    if not macs or len(act) != 1 or len(wgt) != 1:
        raise ValueError(f"MAC statements not recognized (macs={macs}, act={act}, wgt={wgt})")
    # The epilogue may read a COPY of the MAC target rather than the target
    # itself: TVM stages conv2d_NCHWc_global (per-tile registers) into a local
    # or workspace conv2d_NCHWc before the epilogue loop (layers 01/04/06/08).
    # Every stage of the conv result carries the conv2d_NCHWc* name, so all of
    # them are "the accumulator" for the rewrite below.
    acc_names |= set(re.findall(r"\bconv2d_NCHWc\w*", c_src))

    store_pat = re.compile(r"\(\(\w+\*\)" + re.escape(out_name) + r"_1\)\[")
    reads = stores = 0
    for i, line in enumerate(lines):
        m = store_pat.search(line)
        if not m or " = " not in line[m.end():]:
            continue
        end = _bracket_end(line, m.end() - 1)
        if not line[end + 1:].lstrip().startswith("="):
            continue
        idx = line[m.end():end]
        stores += 1
        for j in range(_block_start(lines, i), i + 1):
            lines[j], n = _replace_acc_reads(lines[j], acc_names, idx)
            reads += n
    if not stores or not reads:
        raise ValueError(f"epilogue not found (stores={stores}, acc reads={reads})")
    # Anything still reading an accumulator inside int64 math would be a read
    # this rewrite did not cover -- refuse rather than emit a wrong tail.
    left = [l for l in lines if "int64_t" in l and any(f"{n}[" in l for n in acc_names)]
    if left:
        raise ValueError(f"{len(left)} epilogue read(s) of the accumulator not rewritten")

    text = "\n".join(lines) + "\n"
    head = f"int32_t {symbol}{_SIG}"
    if head not in text:
        raise ValueError("function signature not found")
    text = text.replace(head, f"int32_t aie_tail_{symbol}{_SIG}, const int32_t* aie_acc")
    text = text.replace('#include "../layers_common.h"', '#include "../../layers_common.h"')
    info = {"act_slot": int(next(iter(act))[1:]), "wgt_slot": int(next(iter(wgt))[1:]),
            "out_slot": out_slot, "num_args": out_slot + 1, "macs": macs,
            "acc_reads": reads, "stores": stores, "acc_arrays": sorted(acc_names)}
    return text, info


# ═══════════════════════════════════════════════════════════════════════════
#  Geometry + entry
# ═══════════════════════════════════════════════════════════════════════════

def conv_geometry(graph: dict, node_idx: int, info: dict) -> dict:
    """``convgemm_geom`` fields from the graph's shapes (NCHWc, already padded)."""
    shapes = graph["attrs"]["shape"][1]
    row_ptr = graph["node_row_ptr"]
    ins = graph["nodes"][node_idx]["inputs"]

    def shape(slot):
        if slot == info["out_slot"]:
            return shapes[row_ptr[node_idx]]
        src, k, _ = ins[slot]
        return shapes[row_ptr[src] + k]

    x, w, o = shape(info["act_slot"]), shape(info["wgt_slot"]), shape(info["out_slot"])
    if len(x) != 5 or len(w) != 6 or len(o) != 5:
        raise ValueError(f"not NCHWc: in {x}, weight {w}, out {o}")
    g = {"ic_chunk": x[1], "ih": x[2], "iw": x[3], "ic_block": x[4],
         "oc_chunk": w[0], "kh": w[2], "kw": w[3], "oc_block": w[5],
         "oh": o[2], "ow": o[3]}
    if (w[1], w[4]) != (x[1], x[4]) or (o[1], o[4]) != (w[0], w[5]):
        raise ValueError(f"inconsistent conv shapes: in {x}, weight {w}, out {o}")
    g["stride_h"] = (g["ih"] - g["kh"]) // (g["oh"] - 1) if g["oh"] > 1 else 1
    g["stride_w"] = (g["iw"] - g["kw"]) // (g["ow"] - 1) if g["ow"] > 1 else 1
    if (g["ih"] - g["kh"]) // g["stride_h"] + 1 != g["oh"]:
        raise ValueError(f"cannot recover the stride: {g}")
    return g


_ENTRY_TMPL = """\
/* Generated by src/frontend/tvmrelay/aie_conv_lib.py -- do not edit.
 *
 * Layer {index:02d}: {func_name}
 * TVM packed-call entry. graph_driver.c calls this instead of the CPU kernel
 * when built with -DGRAPH_AIE_OFFLOAD (board build only).
 *
 *   1. conv on the AIE:  conv2d_nchwc_i8()  (src/aietensorop/convgemm, libconvgemm.a)
 *      in  int8 [1,{ic_chunk},{ih},{iw},{ic_block}]   (arg {act_slot}, already padded)
 *      w   int8 [{oc_chunk},{ic_chunk},{kh},{kw},{ic_block},{oc_block}]   (arg {wgt_slot})
 *      acc int32[1,{oc_chunk},{oh},{ow},{oc_block}]   stride {stride_h}x{stride_w}
 *      GEMM M={gm} N={gn} K={gk}  ->  {launches} launch(es) of the 256x64x256 tile
 *   2. TVM's own fused epilogue on the accumulator: aie_tail_*() in tail.c
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct {{
    int ic_chunk, ic_block, ih, iw;
    int oc_chunk, oc_block, kh, kw;
    int stride_h, stride_w, oh, ow;
}} convgemm_geom;   /* = src/aietensorop/convgemm/convgemm.h */
int conv2d_nchwc_i8(const int8_t *ifm, const int8_t *wts, int32_t *acc, const convgemm_geom *g);
long convgemm_launch_count(void);

int32_t aie_tail_{func_name}(void* args, int32_t* arg_type_ids, int32_t num_args,
    void* out_ret_value, int32_t* out_ret_tcode, void* resource_handle, const int32_t* aie_acc);

/* TVMValue.v_handle is a DLTensor*, whose first field is the data pointer
 * (graph_driver.c sets byte_offset = 0). */
#define AIE_ARG_DATA(args, i) (*(void **)(((void **)(args))[(i)]))

int32_t {entry}(void* args, int32_t* arg_type_ids, int32_t num_args,
    void* out_ret_value, int32_t* out_ret_tcode, void* resource_handle) {{
    static const convgemm_geom g = {{{ic_chunk}, {ic_block}, {ih}, {iw}, {oc_chunk}, {oc_block},
                                    {kh}, {kw}, {stride_h}, {stride_w}, {oh}, {ow}}};
    const long before = convgemm_launch_count();
    printf("[aie-offload] layer {index:02d} {short}: ENTER convgemm conv2d_nchwc_i8 "
           "(M={gm} N={gn} K={gk}) on the AIE mesh\\n");
    int32_t *acc = (int32_t *)malloc((size_t){acc_elems} * sizeof(int32_t));
    if (!acc) {{
        printf("[aie-offload] layer {index:02d}: accumulator allocation failed\\n");
        return -1;
    }}
    int rc = conv2d_nchwc_i8((const int8_t *)AIE_ARG_DATA(args, {act_slot}),
                             (const int8_t *)AIE_ARG_DATA(args, {wgt_slot}), acc, &g);
    if (rc == 0)
        rc = aie_tail_{func_name}(args, arg_type_ids, num_args, out_ret_value, out_ret_tcode,
                                  resource_handle, acc);
    free(acc);
    printf("[aie-offload] layer {index:02d}: EXIT rc=%d, %ld AIE launch(es)\\n", rc,
           convgemm_launch_count() - before);
    return rc;
}}
"""


def _launches(g: dict) -> tuple:
    gm = g["oh"] * g["ow"]
    gn = g["oc_chunk"] * g["oc_block"]
    gk = g["kh"] * g["kw"] * g["ic_chunk"] * g["ic_block"]
    n = -(-gm // 256) * -(-gn // 64) * -(-gk // 256)
    return gm, gn, gk, n


def build_conv_layer(layer_dir: Path, index: int, func_name: str, graph: dict,
                     node_idx: int, verify: bool = True) -> dict:
    """Write ``<layer_dir>/aie/{tail.c, entry.c, README.md}``; optionally verify.

    Returns ``{"ok", "entry", "entry_source", "geometry", "launches",
    "verify"?, "reason"?}``. Never raises.
    """
    layer_dir = Path(layer_dir)
    src = layer_dir / f"{layer_dir.name}.c"
    try:
        tail, info = transplant_tail(src.read_text(), func_name)
        g = conv_geometry(graph, node_idx, info)
    except (OSError, ValueError, StopIteration) as exc:
        return {"ok": False, "reason": f"{type(exc).__name__}: {exc}"}
    gm, gn, gk, launches = _launches(g)
    entry = entry_symbol(func_name)
    aie = layer_dir / "aie"
    aie.mkdir(exist_ok=True)
    (aie / "tail.c").write_text(
        f"/* Generated by src/frontend/tvmrelay/aie_conv_lib.py -- do not edit.\n"
        f" * TVM's own fused epilogue for layer {index:02d}, transplanted from\n"
        f" * ../{src.name}: {info['macs']} MAC statement(s) removed, {info['acc_reads']}\n"
        f" * accumulator read(s) redirected to aie_acc[<stored element>]. */\n" + tail)
    acc_elems = g["oc_chunk"] * g["oh"] * g["ow"] * g["oc_block"]
    short = func_name.replace("tvmgen_default_fused_nn_", "")[:40]
    (aie / "entry.c").write_text(_ENTRY_TMPL.format(
        index=index, func_name=func_name, entry=entry, short=short, acc_elems=acc_elems,
        gm=gm, gn=gn, gk=gk, launches=launches, **info, **g))
    res = {"ok": True, "entry": entry, "entry_source": str(aie / "entry.c"),
           "geometry": g, "launches": launches, "transplant": info}
    if verify:
        res["verify"] = verify_layer(layer_dir, func_name, graph, node_idx, info)
        if not res["verify"]["ok"]:
            res.update(ok=False, reason=f"x86 verify: {res['verify']['reason']}")
    (aie / "README.md").write_text(_layer_readme(index, func_name, g, gm, gn, gk,
                                                 launches, info, res.get("verify")))
    return res


def _layer_readme(index, func_name, g, gm, gn, gk, launches, info, ver) -> str:
    v = ("not run" if ver is None else
         f"{'PASS' if ver['ok'] else 'FAIL'} -- {ver.get('detail') or ver.get('reason')}")
    return (f"# Layer {index:02d} on the AIE (generated -- do not edit)\n\n"
            f"`{func_name}`\n\n"
            f"| file | what |\n|---|---|\n"
            f"| `entry.c` | `{entry_symbol(func_name)}()` -- TVM packed ABI; conv via "
            f"`conv2d_nchwc_i8()` (convgemm basic op), then the tail |\n"
            f"| `tail.c` | TVM's own epilogue from `../{func_name and ''}*.c`, "
            f"{info['macs']} MACs removed, {info['acc_reads']} accumulator reads -> `aie_acc` |\n\n"
            f"Conv: in `[1,{g['ic_chunk']},{g['ih']},{g['iw']},{g['ic_block']}]` x "
            f"w `[{g['oc_chunk']},{g['ic_chunk']},{g['kh']},{g['kw']},{g['ic_block']},"
            f"{g['oc_block']}]`, stride {g['stride_h']} -> acc `[1,{g['oc_chunk']},"
            f"{g['oh']},{g['ow']},{g['oc_block']}]`.\n"
            f"GEMM M={gm} N={gn} K={gk} = {launches} launch(es) of the 256x64x256 AIE tile.\n\n"
            f"x86 bit-exactness vs the untouched TVM function: {v}\n")


# ═══════════════════════════════════════════════════════════════════════════
#  x86 verification
# ═══════════════════════════════════════════════════════════════════════════

_CPU_TILE_C = """\
#include <stdint.h>
#include <stdlib.h>
/* The AIE tile, as a scalar loop: c[TM][TN] = a[TM][TK] . b[TN][TK]^T. Everything
 * around it -- im2col, tiling, K accumulation, scatter -- is the real
 * convgemm_host.h, the same code the board runs. */
static int cpu_tile(const int8_t *a, const int8_t *b, int32_t *c) {
    for (int i = 0; i < 256; i++)
        for (int j = 0; j < 64; j++) {
            int32_t s = 0;
            for (int k = 0; k < 256; k++)
                s += (int32_t)a[i * 256 + k] * (int32_t)b[j * 256 + k];
            c[i * 64 + j] = s;
        }
    return 0;
}
#define CONVGEMM_TILE(a, b, c) cpu_tile((a), (b), (c))
#define CONVGEMM_DMA_ALLOC(n) malloc(n)
#include "convgemm_host.h"
"""

_HARNESS_C = """\
#include "layers_common.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
void* TVMBackendAllocWorkspace(int t, int d, uint64_t n, int c, int b) {{ return malloc(n); }}
int TVMBackendFreeWorkspace(int t, int d, void* p) {{ free(p); return 0; }}
void TVMAPISetLastError(const char* m) {{ fprintf(stderr, "%s\\n", m); }}
int32_t {func}(void*, int32_t*, int32_t, void*, int32_t*, void*);
int32_t {entry}(void*, int32_t*, int32_t, void*, int32_t*, void*);
static const long nbytes[{n}] = {{{nbytes}}};
static const int ndim[{n}] = {{{ndims}}};
static int64_t shapes[{n}][6] = {{{shapes}}};
static const uint8_t dcode[{n}] = {{{dcodes}}};
static const uint8_t dbits[{n}] = {{{dbits}}};
int main(int argc, char **argv) {{
    FILE *f = fopen(argv[1], "rb");
    DLTensor t[{n}]; TVMValue v[{n}]; int32_t codes[{n}];
    for (int i = 0; i < {n}; i++) {{
        memset(&t[i], 0, sizeof t[i]);
        t[i].data = calloc(1, nbytes[i] + 64);
        if (fread(t[i].data, 1, nbytes[i], f) != (size_t)nbytes[i]) {{ puts("short blob"); return 2; }}
        t[i].ndim = ndim[i]; t[i].shape = shapes[i];
        t[i].dtype.code = dcode[i]; t[i].dtype.bits = dbits[i]; t[i].dtype.lanes = 1;
        v[i].v_handle = &t[i]; codes[i] = 7;
    }}
    fclose(f);
    long ob = nbytes[{out}];
    unsigned char *ref = malloc(ob);
    if ({func}(v, codes, {n}, 0, 0, 0)) {{ puts("TVM kernel failed"); return 2; }}
    memcpy(ref, t[{out}].data, ob);
    memset(t[{out}].data, 0xA5, ob);
    if ({entry}(v, codes, {n}, 0, 0, 0)) {{ puts("AIE entry failed"); return 2; }}
    long bad = 0, first = -1;
    for (long i = 0; i < ob; i++) if (ref[i] != ((unsigned char *)t[{out}].data)[i]) {{ if (first < 0) first = i; bad++; }}
    printf("RESULT %ld %ld %ld\\n", ob, bad, first);
    return bad != 0;
}}
"""


def _arg_specs(graph, node_idx, info):
    """``[(name|None, shape, dtype)]`` for every arg slot of the node, output last."""
    shapes, dtypes = graph["attrs"]["shape"][1], graph["attrs"]["dltype"][1]
    row_ptr, nodes = graph["node_row_ptr"], graph["nodes"]
    specs = []
    for src, k, _ in nodes[node_idx]["inputs"]:
        e = row_ptr[src] + k
        name = nodes[src]["name"] if nodes[src]["op"] == "null" else None
        specs.append((name, shapes[e], dtypes[e]))
    e = row_ptr[node_idx]
    specs.append((None, shapes[e], dtypes[e]))
    return specs


def _blob(specs, params, rng):
    parts = []
    for name, shape, dtype in specs:
        if name and name in params:
            arr = params[name].numpy().astype(dtype)
        elif dtype == "int32":
            arr = rng.integers(-4000, 4000, size=shape, dtype=np.int32)
        else:
            info = np.iinfo(dtype)
            arr = rng.integers(info.min, info.max + 1, size=shape).astype(dtype)
        parts.append(np.ascontiguousarray(arr).tobytes())
    return b"".join(parts)


def verify_layer(layer_dir, func_name, graph, node_idx, info, seed: int = 7) -> dict:
    """TVM's function vs entry+tail (CPU tile), bit-exact on one input. ``{"ok", ...}``."""
    from tvm import relay

    from frontend.tvmrelay.split_layers import _tvm_include_dirs

    layer_dir = Path(layer_dir)
    out_dir = layer_dir.parent.parent
    params_path = next(out_dir.glob("*_params.bin"), None)
    params = relay.load_param_dict(params_path.read_bytes()) if params_path else {}
    specs = _arg_specs(graph, node_idx, info)
    _, incs = _tvm_include_dirs()
    code = {"int": 0, "uin": 1}
    n = len(specs)
    fmt = {
        "func": func_name, "entry": entry_symbol(func_name), "n": n, "out": n - 1,
        "nbytes": ", ".join(str(int(np.prod(s)) * np.dtype(d).itemsize) for _, s, d in specs),
        "ndims": ", ".join(str(len(s)) for _, s, _ in specs),
        "shapes": ", ".join("{" + ", ".join(map(str, s)) + "}" for _, s, _ in specs),
        "dcodes": ", ".join(str(code[d[:3]]) for _, _, d in specs),
        "dbits": ", ".join(str(np.dtype(d).itemsize * 8) for _, _, d in specs)}
    with tempfile.TemporaryDirectory(prefix="aieconv_") as tmp:
        tmp = Path(tmp)
        (tmp / "blob.bin").write_bytes(_blob(specs, params, np.random.default_rng(seed)))
        (tmp / "harness.c").write_text(_HARNESS_C.format(**fmt))
        (tmp / "cpu_tile.c").write_text(_CPU_TILE_C)
        cmd = ["gcc", "-O1", "-std=gnu11", "-w", f"-I{layer_dir.parent}", f"-I{CONVGEMM_DIR}",
               *[f"-I{d}" for d in incs], str(layer_dir / f"{layer_dir.name}.c"),
               str(layer_dir / "aie" / "tail.c"), str(layer_dir / "aie" / "entry.c"),
               str(tmp / "cpu_tile.c"), str(tmp / "harness.c"), "-lm", "-o", str(tmp / "h")]
        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            return {"ok": False, "reason": f"compile: {proc.stderr.strip()[-600:]}"}
        run = subprocess.run([str(tmp / "h"), str(tmp / "blob.bin")], capture_output=True,
                             text=True, timeout=600)
    m = re.search(r"RESULT (\d+) (\d+) (-?\d+)", run.stdout)
    if not m:
        return {"ok": False, "reason": f"harness: {(run.stdout + run.stderr).strip()[-400:]}"}
    total, bad, first = map(int, m.groups())
    detail = (f"{total - bad}/{total} output bytes identical"
              + ("" if not bad else f", first mismatch at byte {first}"))
    return {"ok": bad == 0, "bytes": total, "mismatches": bad, "detail": detail,
            "reason": None if not bad else detail}
