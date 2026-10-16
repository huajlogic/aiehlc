###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""OpenAI Whisper -> TVM (Relay) -> aiehlc, every layer on the AI Engine.

    PYTHONPATH=src python src/frontend/tvmrelay/example/whisper/whisper_flow.py

Eight stages (``--help`` for the knobs; nothing here touches hardware):

1. env        TVM 0.16 with Relay, aiehlc binary, aarch64 toolchain
2. model      official ``tiny`` checkpoint; PyTorch transcript of the JFK clip
3. import     encoder + one decoder step (fixed T) -> ONNX -> canonical Relay
4. partition  AIE-first partition; FAILS if any Relay op is left for the CPU
5. aiehlc     one aiehlc library per distinct layer signature, built + checked
6. codegen    ``relay.build(target="c")`` with ``relay.ext.aie_whisper``
7. verify     x86: the resolved aiehlc kernels, emulated, run the whole network;
              compared with TVM's CPU build and the PyTorch transcript
8. board      baremetal aarch64 ELF linking every library (compile only)

Outputs land in ``--out-dir`` (default ``worklocal/whisper_deploy``):
``report.json`` (every number below), ``layers.md`` (one row per AIE layer),
``aie_libs/<sig>/`` (aiehlc builds), ``board/whisper_aie.elf``.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[4]
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(REPO / "src"))

import numpy as np  # noqa: E402


def stage(n, name, msg):
    print(f"[{n}/8] {name:<9}: {msg}", flush=True)


def env_check() -> dict:
    import shutil

    import frontend.tvmrelay  # noqa: F401  ensure TVM 0.16 + onnx shim
    import tvm
    from tvm import relay  # noqa: F401
    aiehlc = REPO / "build" / "aiehlc"
    info = {"tvm": tvm.__version__, "aiehlc": str(aiehlc) if aiehlc.is_file() else None,
            "aarch64_gcc": shutil.which("aarch64-none-elf-gcc"),
            "llvm": bool(tvm.support.libinfo().get("USE_LLVM", "OFF") not in ("OFF", ""))}
    if not info["aiehlc"]:
        raise SystemExit("build/aiehlc missing: cmake + make aiehlc first (README.md)")
    if not info["llvm"]:
        raise SystemExit("TVM built without LLVM: stage 7 (x86 verification) needs target llvm")
    return info


def layers_md(layers, libs_res) -> str:
    rows = ["| # | symbol | AIE op | relay ops absorbed | aiehlc library | built |",
            "|---|---|---|---|---|---|"]
    for L in layers:
        ops = Counter(L.relay_ops)
        absorbed = ", ".join(f"{k}x{v}" if v > 1 else k for k, v in ops.items())
        ok = libs_res.get(L.lib["sig"], {}).get("ok")
        rows.append(f"| {L.index} | `{L.symbol}` | {L.describe()} | {absorbed} | `{L.lib['sig']}` | "
                    f"{'yes' if ok else 'NO'} |")
    return "\n".join(rows) + "\n"


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--model", default="tiny")
    ap.add_argument("--out-dir", default=str(REPO / "worklocal" / "whisper_deploy"))
    ap.add_argument("--decoder-tokens", type=int, default=32,
                    help="static decoder length T (prompt + generated tokens; causal, so padding is inert)")
    ap.add_argument("--jobs", type=int, default=8, help="parallel aiehlc builds")
    ap.add_argument("--no-verify", action="store_true", help="skip stage 7 (x86 emulation)")
    ap.add_argument("--no-board", action="store_true", help="skip stage 8 (aarch64 link)")
    args = ap.parse_args(argv)
    out = Path(args.out_dir).resolve()
    cache = out / "cache"
    report = {"model": args.model, "decoder_tokens": args.decoder_tokens}
    t_all = time.time()

    stage(1, "env", "checking TVM / aiehlc / toolchain")
    report["env"] = env_check()
    stage(1, "env", f"tvm {report['env']['tvm']}, aiehlc {report['env']['aiehlc']}")

    import torch

    import aie_build
    import aie_codegen_whisper
    import aie_emu_whisper
    import aie_kernels_whisper
    import aie_partition
    import whisper_audio as wa
    import whisper_model as wm
    import whisper_relay as wr

    stage(2, "model", f"whisper-{args.model} + PyTorch reference on jfk.flac")
    model = wm.load_whisper(args.model, cache)
    mel = wa.jfk_mel(cache)
    with torch.no_grad():
        torch_tokens = wa.greedy_decode(lambda m: model.encoder(torch.from_numpy(m)),
                                        lambda t, f: model.decoder(torch.from_numpy(t), f).numpy(), mel)
    report["torch_text"] = wa.Detokenizer(cache).decode(torch_tokens)
    report["torch_tokens"] = torch_tokens
    stage(2, "model", f"PyTorch: {report['torch_text']!r}")
    if len(torch_tokens) + len(wa.SOT_SEQUENCE) >= args.decoder_tokens:
        raise SystemExit(f"--decoder-tokens {args.decoder_tokens} too short for {len(torch_tokens)} tokens")

    stage(3, "import", "ONNX export + Relay import (encoder, decoder step)")
    paths = wr.export_onnx(model, out / "onnx", args.decoder_tokens)
    graphs = {"encoder": (paths["encoder"], wr.ENCODER_INPUTS),
              "decoder": (paths["decoder"], wr.decoder_inputs(args.decoder_tokens, model.dims.n_audio_ctx,
                                                             model.dims.n_audio_state))}
    relay_mods = {k: wr.import_relay(p, s) for k, (p, s) in graphs.items()}

    stage(4, "partition", "AIE-first partition (every op must land in an AIE layer)")
    import tvm
    parts, all_layers = {}, []
    for name, (mod, params) in relay_mods.items():
        pmod, layers = aie_partition.partition(mod, name)
        left = aie_partition.leftover_ops(pmod)
        n_ops = sum(len(L.relay_ops) for L in layers)
        report.setdefault("partition", {})[name] = {
            "aie_layers": len(layers), "relay_ops_in_aie": n_ops, "cpu_ops": dict(left),
            "ops": dict(Counter(L.op for L in layers))}
        if left:
            raise SystemExit(f"{name}: {dict(left)} left on the CPU -- not every layer is offloaded")
        parts[name] = pmod
        all_layers += layers
    stage(4, "partition", f"{len(all_layers)} AIE layers, 0 Relay ops on the CPU")

    stage(5, "aiehlc", "planning + building aiehlc libraries")
    libs = {}
    for L in all_layers:
        L.lib = aie_kernels_whisper.plan_library(L)
        libs[L.lib["sig"]] = L.lib
    t = time.time()
    lib_res = aie_build.build_all(libs, out / "aie_libs", jobs=args.jobs)
    n_ok = sum(r["ok"] for r in lib_res.values())
    report["aiehlc"] = {"libraries": len(libs), "built_ok": n_ok, "seconds": round(time.time() - t),
                        "failed": {s: r["problems"] for s, r in lib_res.items() if not r["ok"]}}
    covered = sum(1 for L in all_layers if lib_res[L.lib["sig"]]["ok"])
    report["layers_offloaded"] = covered
    report["layers_total"] = len(all_layers)
    (out / "layers.md").write_text(layers_md(all_layers, lib_res))
    stage(5, "aiehlc", f"{n_ok}/{len(libs)} libraries ok; {covered}/{len(all_layers)} layers have an "
          f"aiehlc library (layers.md)")
    if n_ok != len(libs):
        (out / "report.json").write_text(json.dumps(report, indent=1, default=str))
        raise SystemExit("aiehlc build failures -- see report.json")

    stage(6, "codegen", "relay.build(target=c) with relay.ext.aie_whisper")
    aie_codegen_whisper.LAYERS.update({L.symbol: L for L in all_layers})
    aie_codegen_whisper.register()
    from tvm import relay
    board_dir = out / "board"
    board_dir.mkdir(parents=True, exist_ok=True)
    wrappers, gjson, pblob = [], {}, {}
    for name, pmod in parts.items():
        with tvm.transform.PassContext(opt_level=3, config={"tir.disable_vectorize": True}):
            blib = relay.build(pmod, target=tvm.target.Target("c", host="c"), params=relay_mods[name][1])
        g = json.loads(blib.get_graph_json())
        fns = Counter(n["attrs"]["func_name"] for n in g["nodes"] if n["op"] == "tvm_op")
        not_aie = {f: c for f, c in fns.items() if not f.startswith("wsp_") and f != "__nop"}
        report.setdefault("codegen", {})[name] = {"graph_calls": sum(fns.values()),
                                                  "aie_calls": sum(c for f, c in fns.items() if f.startswith("wsp_")),
                                                  "nop": fns.get("__nop", 0), "cpu_kernels": not_aie}
        if not_aie:
            raise SystemExit(f"{name}: TVM compiled CPU kernels {not_aie}")
        gjson[name] = board_dir / f"{name}_graph.json"
        gjson[name].write_text(blib.get_graph_json())
        pblob[name] = board_dir / f"{name}_params.bin"
        pblob[name].write_bytes(relay.save_param_dict(blib.get_params()))
        src = "\n".join(m.get_source() for m in blib.get_lib().imported_modules if m.type_key == "c")
        wsrc = board_dir / f"{name}_aie_wrappers.c"
        wsrc.write_text(src)
        wrappers.append(wsrc)
        stage(6, "codegen", f"{name}: {report['codegen'][name]['aie_calls']} AIE calls + "
              f"{report['codegen'][name]['nop']} __nop, 0 CPU kernels -> {wsrc.name}")

    if not args.no_verify:
        import whisper_verify
        stage(7, "verify", "x86: resolved aiehlc kernels, emulated, run the whole network")
        objs = aie_emu_whisper.build_emulators(libs, lib_res, out / "emu")
        report["verify"] = whisper_verify.verify(
            {k: (parts[k], relay_mods[k][0], relay_mods[k][1]) for k in parts}, objs, out / "x86",
            mel, torch_tokens, args.decoder_tokens, cache)

    if not args.no_board:
        import whisper_board
        stage(8, "board", "baremetal aarch64 link (compile only)")
        drivers = []
        for name in parts:
            d = board_dir / f"whisper_{name}_driver.c"
            report.setdefault("board", {})[name] = whisper_board.generate_driver(gjson[name], pblob[name], name, d)
            drivers.append(d)
        melbin = board_dir / "jfk_mel.bin"
        melbin.write_bytes(mel.astype(np.float32).tobytes())
        dims = dict(mel_bytes=mel.nbytes, feat_bytes=model.dims.n_audio_ctx * model.dims.n_audio_state * 4,
                    T=args.decoder_tokens, V=model.dims.n_vocab, eot=wa.EOT,
                    prompt=", ".join(str(t) for t in wa.SOT_SEQUENCE),
                    enc=report["partition"]["encoder"]["aie_layers"],
                    dec=report["partition"]["decoder"]["aie_layers"])
        archives = {s: (r["archive"], libs[s]["kernel"]) for s, r in lib_res.items()}
        report["board"]["link"] = whisper_board.link(
            board_dir, wrappers, drivers,
            {"encoder_params": pblob["encoder"], "decoder_params": pblob["decoder"], "jfk_mel": melbin},
            archives, dims)

    report["seconds"] = round(time.time() - t_all)
    (out / "report.json").write_text(json.dumps(report, indent=1, default=str))
    print(f"done in {report['seconds']}s -> {out / 'report.json'}")
    return 0


if __name__ == "__main__":
    os.environ.setdefault("AIEHLC_TVM_AUTO_INSTALL", "0")
    sys.exit(main())
