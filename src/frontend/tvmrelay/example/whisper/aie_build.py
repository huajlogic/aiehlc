###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Build every planned aiehlc library and check what came out.

One ``aiehlc.sh --runtime-source-file <sig>.cc`` per signature, each in its own
directory (``aiehlc.sh`` writes ``aout/`` relative to the cwd and ``rm -rf``s
it). The aie-rt driver library is built once by the first job; the rest run
with ``AIEHLC_SKIP_AIELIB=1`` and in parallel -- without that flag every run
wipes ``thirdparty/alib/lib/*.a`` under its neighbours.

"Built" means more than ``rc == 0`` (``aiehlc.sh`` has returned 0 on empty
modules before -- skill aiesourcetextrewrite). Each library is checked for:

1. ``lib<sig>.a`` exists and is newer than the run;
2. ``<sig>_port`` / ``<sig>_run`` are defined in it, and the core ELF is
   embedded (``_binary_kernel_<kernel>_start``);
3. the routing provenance has connections (not an empty module);
4. every ``aie::get_*`` the kernel calls was resolved to the constant the
   plan expects (``aie_kernels_whisper.expected_constants``) -- the window
   protocol the core will run is the one the planner designed.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from aie_kernels_whisper import app_source

REPO = Path(__file__).resolve().parents[5]
AIEHLC_SH = REPO / "script" / "aiehlc.sh"


def _nm_defined(archive: Path) -> set:
    import shutil
    nm = shutil.which("aarch64-none-elf-nm") or shutil.which("nm")
    out = subprocess.run([nm, "-g", "--defined-only", str(archive)],
                         capture_output=True, text=True).stdout
    return {ln.split()[-1] for ln in out.splitlines() if len(ln.split()) == 3}


def resolved_constants(kernel_src: str) -> dict:
    """``const int name = <int>;`` lines aiehlc wrote into the kernel source."""
    return {m.group(1): int(m.group(2))
            for m in re.finditer(r"const int (\w+) = (-?\d+);", kernel_src)}


def check_library(lib: dict, work: Path, t0: float) -> dict:
    sig, kname = lib["sig"], lib["kernel"]
    res = {"sig": sig, "kernel": kname, "ok": False, "problems": []}
    arch = work / "aout" / f"lib{sig}.a"
    if not arch.is_file() or arch.stat().st_mtime < t0:
        res["problems"].append("no fresh archive")
        return res
    res["archive"] = str(arch)
    res["archive_bytes"] = arch.stat().st_size
    syms = _nm_defined(arch)
    for s in (f"{sig}_port", f"{sig}_run", f"_binary_kernel_{kname}_start"):
        if s not in syms:
            res["problems"].append(f"symbol {s} not defined")
    prov = work / "aout" / "worklocal" / "routingprovenancemap.json"
    try:
        groups = json.loads(prov.read_text()).get("routing_groups", [])
        n = len(groups)
        res["routing_groups"] = n
        if n == 0:
            res["problems"].append("empty routing (no groups)")
    except (OSError, ValueError):
        res["problems"].append("no routing provenance")
    # The core's window buffers (kernel.cc, v4int32 = 4 elements) must hold the
    # windows the kernel body walks: the pipeline sizes them from its own flow
    # view, the body from the frontend derivation -- two derivations, one check.
    kcc = work / "aout" / "worklocal" / "kernel.cc"
    if kcc.is_file():
        alloc = {m.group(1): 4 * int(m.group(2))
                 for m in re.finditer(r"#define BUF_SZ_(IN_\d+|OUT_\d+) (\d+)", kcc.read_text())}
        res["kernel_windows"] = alloc
        ports = ["IN_0", "IN_1", "OUT_0"] if "buf_sz_b" in lib["expect"] else ["IN_0", "OUT_0"]
        for port, key in zip(ports, ["buf_sz_a", "buf_sz_b", "buf_sz_c"] if len(ports) == 3
                             else ["buf_sz_a", "buf_sz_c"]):
            # Equal, not merely large enough: the core BD moves exactly one buffer
            # per acquire, so a bigger window is a DMA/acquire count mismatch.
            if alloc.get(port, 0) != lib["expect"][key]:
                res["problems"].append(f"core window {port} is {alloc.get(port)} elements, "
                                       f"kernel walks {lib['expect'][key]} per acquire")
    ksrc = work / "aout" / "worklocal" / f"{kname}.cc"
    if ksrc.is_file():
        got = resolved_constants(ksrc.read_text())
        res["resolved"] = got
        for k, v in lib["expect"].items():
            if got.get(k) != v:
                res["problems"].append(f"aiehlc resolved {k}={got.get(k)}, plan says {v}")
        res["kernel_source"] = str(ksrc)
    else:
        res["problems"].append("no resolved kernel source")
    res["ok"] = not res["problems"]
    return res


def build_one(lib: dict, root: Path, aie_version: int = 5, skip_aielib: bool = True) -> dict:
    work = root / lib["sig"]
    work.mkdir(parents=True, exist_ok=True)
    src = work / f"{lib['sig']}.cc"
    src.write_text(app_source(lib))
    log = work / "aiehlc.log"
    env = dict(os.environ)
    if skip_aielib:
        env["AIEHLC_SKIP_AIELIB"] = "1"
    t0 = time.time()
    cmd = f'source "{AIEHLC_SH}" --aie-version {aie_version} --runtime-source-file "{src}"'
    with log.open("w") as fh:
        rc = subprocess.run(["bash", "-c", cmd], cwd=str(work), env=env,
                            stdout=fh, stderr=subprocess.STDOUT).returncode
    res = check_library(lib, work, t0)
    res.update(rc=rc, seconds=round(time.time() - t0, 1), log=str(log), source=str(src))
    if rc != 0:
        res["ok"] = False
        res["problems"].insert(0, f"aiehlc.sh rc={rc}")
    return res


def build_all(libs: dict, root: Path, jobs: int = 8, verbose: bool = True,
              reuse: bool = True) -> dict:
    """Build every ``{sig: lib}``; returns ``{sig: result}`` and writes ``build.json``."""
    root.mkdir(parents=True, exist_ok=True)
    manifest = root / "build.json"
    done = json.loads(manifest.read_text()) if (reuse and manifest.is_file()) else {}
    todo = []
    for sig, lib in libs.items():
        prev = done.get(sig)
        same_src = (root / sig / f"{sig}.cc").is_file() and \
            (root / sig / f"{sig}.cc").read_text() == app_source(lib)
        if prev and prev.get("ok") and same_src:
            continue
        todo.append(lib)
    if verbose:
        print(f"  [aiehlc] {len(libs)} libraries, {len(libs) - len(todo)} up to date, "
              f"building {len(todo)} ({jobs} parallel)")
    if todo:
        # The first build also builds the aie-rt driver library; the rest reuse it.
        first = build_one(todo[0], root, skip_aielib=False)
        done[first["sig"]] = first
        if verbose:
            _report(first)
        with ThreadPoolExecutor(max_workers=jobs) as ex:
            for res in ex.map(lambda lb: build_one(lb, root), todo[1:]):
                done[res["sig"]] = res
                if verbose:
                    _report(res)
                manifest.write_text(json.dumps(done, indent=1))
    manifest.write_text(json.dumps(done, indent=1))
    return {s: done[s] for s in libs}


def _report(res):
    tag = "ok  " if res["ok"] else "FAIL"
    extra = "" if res["ok"] else " -- " + "; ".join(res["problems"][:3])
    print(f"  [aiehlc] {tag} {res['sig']} ({res.get('seconds', 0):.0f}s){extra}")
