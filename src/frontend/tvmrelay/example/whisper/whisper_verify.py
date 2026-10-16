###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Stage 7: run the offloaded network on x86 -- every layer through its AIE kernel.

The partitioned module is built for ``llvm`` exactly as for the board, except
that the AIE libraries behind ``aiew_<sig>_port/_run`` are the x86 emulators
of the *resolved* aiehlc kernels (``aie_emu_whisper``). Since the partition
leaves nothing on the CPU, every number the graph produces came out of an AIE
kernel body. It is compared with:

* the **CPU reference** -- the same canonical Relay graph, unpartitioned, built
  by TVM for ``llvm`` (same weights, same lifted constants);
* **PyTorch** through the transcript: greedy decoding with the AIE encoder and
  the AIE decoder step must reproduce the PyTorch transcript token for token.

Tolerances are fp32-reordering tolerances: the AIE GEMM accumulates in K
chunks and the transcendental functions are polynomials, so bit equality with
TVM's C is neither expected nor claimed.
"""

from __future__ import annotations

import time
from pathlib import Path

import numpy as np


def build_x86(mod, params, emu_objs, so_path: Path):
    import tvm
    from tvm import relay
    with tvm.transform.PassContext(opt_level=3):
        lib = relay.build(mod, target="llvm", params=params)
    lib.export_library(str(so_path), options=["-O2", "-w"] + list(emu_objs))
    return so_path


def load(so_path: Path):
    import tvm
    from tvm.contrib import graph_executor
    m = tvm.runtime.load_module(str(so_path))
    return graph_executor.GraphModule(m["default"](tvm.cpu()))


def run(gm, inputs: dict):
    for k, v in inputs.items():
        gm.set_input(k, v)
    gm.run()
    return gm.get_output(0).numpy()


def compare(name, got, ref) -> dict:
    d = np.abs(got.astype(np.float64) - ref.astype(np.float64))
    scale = float(np.abs(ref).max()) or 1.0
    res = {"graph": name, "shape": list(got.shape), "max_abs": float(d.max()),
           "max_rel_to_range": float(d.max() / scale), "mean_abs": float(d.mean()),
           "finite": bool(np.isfinite(got).all())}
    return res


def greedy(encode, decode, mel, n_ctx: int, max_tokens: int = 48):
    """Greedy decoding with a fixed-T decoder step (causal: padding is inert)."""
    import whisper_audio as wa
    feats = encode(mel)
    tokens = list(wa.SOT_SEQUENCE)
    while len(tokens) < n_ctx and len(tokens) - len(wa.SOT_SEQUENCE) < max_tokens:
        buf = np.full((1, n_ctx), wa.EOT, np.int64)
        buf[0, :len(tokens)] = tokens
        logits = decode(buf, feats)
        nxt = int(np.argmax(logits[0, len(tokens) - 1]))
        if nxt == wa.EOT:
            break
        tokens.append(nxt)
    return tokens[len(wa.SOT_SEQUENCE):]


def verify(graphs: dict, emu_objs, out_dir: Path, mel, torch_tokens, n_ctx: int,
           cache_dir: Path, verbose: bool = True) -> dict:
    """``graphs[name] = (partitioned_mod, reference_mod, params)``."""
    import whisper_audio as wa
    out_dir.mkdir(parents=True, exist_ok=True)
    mods = {}
    t0 = time.time()
    for name, (pmod, rmod, params) in graphs.items():
        mods[name] = {"aie": load(build_x86(pmod, params, emu_objs, out_dir / f"{name}_aie_x86.so")),
                      "cpu": load(build_x86(rmod, params, [], out_dir / f"{name}_cpu_x86.so"))}
    if verbose:
        print(f"  [verify] built 4 x86 modules ({time.time() - t0:.0f}s)")

    report = {}
    feats = {}
    for who in ("aie", "cpu"):
        t = time.time()
        feats[who] = run(mods["encoder"][who], {"mel": mel})
        report[f"encoder_{who}_seconds"] = round(time.time() - t, 1)
    report["encoder"] = compare("encoder", feats["aie"], feats["cpu"])
    tok = np.full((1, n_ctx), wa.EOT, np.int64)
    tok[0, :len(wa.SOT_SEQUENCE) + len(torch_tokens)] = list(wa.SOT_SEQUENCE) + list(torch_tokens)
    logits = {w: run(mods["decoder"][w], {"tokens": tok, "audio_features": feats["cpu"]})
              for w in ("aie", "cpu")}
    n_real = len(wa.SOT_SEQUENCE) + len(torch_tokens)
    report["decoder"] = compare("decoder", logits["aie"][:, :n_real], logits["cpu"][:, :n_real])
    report["decoder"]["argmax_agree"] = int((logits["aie"][0, :n_real].argmax(-1)
                                             == logits["cpu"][0, :n_real].argmax(-1)).sum())
    report["decoder"]["positions"] = n_real
    if verbose:
        for k in ("encoder", "decoder"):
            r = report[k]
            print(f"  [verify] {k}: AIE(emu) vs CPU max|d|={r['max_abs']:.3e} "
                  f"({r['max_rel_to_range']:.2e} of range), mean|d|={r['mean_abs']:.2e}")
        print(f"  [verify] decoder argmax agree {report['decoder']['argmax_agree']}/{n_real} positions")

    t = time.time()
    aie_tokens = greedy(lambda m: run(mods["encoder"]["aie"], {"mel": m}),
                        lambda tk, f: run(mods["decoder"]["aie"], {"tokens": tk, "audio_features": f}),
                        mel, n_ctx)
    report["greedy_seconds"] = round(time.time() - t, 1)
    detok = wa.Detokenizer(cache_dir)
    report["aie_tokens"] = aie_tokens
    report["aie_text"] = detok.decode(aie_tokens)
    report["torch_text"] = detok.decode(torch_tokens)
    report["transcript_match"] = list(aie_tokens) == list(torch_tokens)
    if verbose:
        print(f"  [verify] AIE(emu) transcript: {report['aie_text']!r}")
        print(f"  [verify] transcript {'MATCHES' if report['transcript_match'] else 'DIFFERS FROM'} "
              f"PyTorch ({len(aie_tokens)} tokens, {report['greedy_seconds']}s)")
    return report
