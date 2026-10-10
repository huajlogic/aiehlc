#!/usr/bin/env python3
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Regression test for ``deploy_flow.py --aie-offload``.

Three checks, in order, each one reported separately so a failure names what
broke rather than just "the flow changed":

1. **run** -- ``python3 src/frontend/tvmrelay/deploy_flow.py --aie-offload``
   from the repo root (``deploy_flow.DEFAULT_OUT`` is ``./worklocal/
   tvmrelay_deploy``, i.e. *relative to the cwd*, so the cwd is pinned here --
   running it from anywhere else writes a second output tree somewhere else and
   this test would then verify a stale one).  The full log is kept at
   ``test/deploy_flow.log``.

2. **tree** -- ``worklocal/tvmrelay_deploy/layers/`` must match
   ``worklocal/tvmrelay_deploy/layers-golden/``: same set of files, same
   contents.  Build by-products that are not reproducible byte-for-byte
   (``.o``, ``.a``, ELFs, logs) are skipped by default -- see ``DEFAULT_IGNORES``
   -- and absolute paths that leak into generated text (``Makefile``'s
   ``TVM_HOME``, ``manifest.json``'s ``source``/``graph``) are normalized to
   ``$REPO`` / ``$TVM_HOME`` before comparing, so the test is portable between
   checkouts.

3. **aie/** -- the offloaded conv layer's folder
   (``01_contrib_conv2d_NCHWc_subtract_add_subtract_fixed_point_multiply_per_axi``
   or whatever that layer is numbered as today) must carry an extra ``aie/``
   subdirectory holding the AIE offload artifacts.  Which folder that is is
   resolved from ``layers/manifest.json`` by glob (``--aie-layer-glob``), not by
   a hardcoded index: stage 5 renumbers ``layers/`` whenever a pass adds or
   removes graph nodes, so an index here would rot silently.

   ``split_layers._clear_stale`` keeps a non-empty layer folder on purpose --
   that is exactly how an offloaded layer's ``aie/`` survives the re-split that
   ``--aie-offload`` triggers -- so this check is about the *current* run only
   if ``--clean`` was passed.

Usage::

    # from anywhere; the script pins its own cwd
    source script/setup.sh --path-set-only          # stage 6's cross toolchain
    python3 worklocal/tvmrelay_deploy/test/test_aie_offload.py

    # verify an existing tree without re-running the ~minutes-long flow
    python3 .../test_aie_offload.py --skip-run

    # first time: capture today's known-good tree as the golden
    python3 .../test_aie_offload.py --update-golden

    # pass extra flags through to deploy_flow.py
    python3 .../test_aie_offload.py --deploy-args "--no-arm --aie-layers 1"

Exit codes: ``0`` pass, ``1`` a check failed, ``2`` ``deploy_flow.py`` itself
failed, ``3`` the test could not run (no golden, no layers/, bad arguments).
"""

from __future__ import annotations

import argparse
import difflib
import fnmatch
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

#: .../worklocal/tvmrelay_deploy/test/test_aie_offload.py -> up four.
REPO = Path(__file__).resolve().parents[4]
OUT_DIR = REPO / "worklocal" / "tvmrelay_deploy"
LAYERS_DIR = OUT_DIR / "layers"
GOLDEN_DIR = OUT_DIR / "layers-golden"
TEST_DIR = Path(__file__).resolve().parent
DEPLOY_FLOW = REPO / "src" / "frontend" / "tvmrelay" / "deploy_flow.py"

#: Not compared: build products whose bytes depend on the toolchain, the clock
#: or the link order rather than on anything this flow decides.
#:
#: The AIE-only outputs (``aie/``, ``aiegraph.mlir``, ``partition.json``) are
#: excluded too: ``layers-golden/`` is the **default** (CPU-only) flow, and
#: ``--aie-offload`` must leave every layer's ``.c`` byte-identical to it while
#: *adding* those.  Check 3 owns them -- it requires ``host.cc``/``kernel.cc``/
#: ``routing.cc`` and an ``aiegraph.conv_*`` op in the IR.
DEFAULT_IGNORES = (
    "*.o", "*.a", "*.so", "*.elf", "*.d", "*.log", "*.bin",
    "*/build/*", "*/aout/*", "__pycache__/*", "*.pyc", ".*.swp",
    "*/aie/*", "aiegraph.mlir", "partition.json",
)

#: Layer folders eligible to be "the offloaded conv".  The real name today is
#: ``01_contrib_conv2d_NCHWc_subtract_add_subtract_fixed_point_multiply_per_axi``;
#: the glob survives the int8/qnn renaming and renumbering that moved the stem
#: between indices 1 and 6 more than once.
DEFAULT_AIE_LAYER_GLOB = "*conv2d*"

#: What ``run_aie_pipeline`` leaves in a layer's ``aie/`` (``aie_layer_lib``'s
#: docstring).  A missing one fails check 3.  ``build/lib<layer>.a`` is not
#: required: it only appears on a box with the Vitis cross toolchain.
AIE_EXPECTED_FILES = ("host.cc", "kernel.cc", "routing.cc")

#: Layer 01 is ResNet-18's stem, and its aie/ must be aiehlc's build of this
#: source (the file test_conv2d.cc #includes) -- see ``_check_stem``.
STEM_LAYER_PREFIX = "01_contrib_conv2d_NCHWc"
STEM_SOURCE = "src/aietensorop/conv2dstem/conv2dstem.cc"


# ═══════════════════════════════════════════════════════════════════════════
#  1 -- run the flow
# ═══════════════════════════════════════════════════════════════════════════

def run_deploy_flow(extra_args, log_path: Path, verbose: bool = True) -> dict:
    """``deploy_flow.py --aie-offload`` with the cwd pinned to the repo root.

    Returns ``{"ok", "rc", "seconds", "log"}``.  stdout and stderr are merged
    into *log_path* and echoed, because the flow's per-stage lines
    (``[6/7] aie    : offloading layer(s) ...``) are the first thing to read
    when check 2 or 3 fails.
    """
    env = dict(os.environ)
    src = str(REPO / "src")
    env["PYTHONPATH"] = (src + os.pathsep + env["PYTHONPATH"]
                         if env.get("PYTHONPATH") else src)

    cmd = [sys.executable, str(DEPLOY_FLOW), "--aie-offload", *extra_args]
    if verbose:
        print(f"[run ] cwd={REPO}")
        print(f"[run ] {' '.join(cmd)}")

    start = time.time()
    with log_path.open("w") as log:
        proc = subprocess.Popen(cmd, cwd=str(REPO), env=env,
                                stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True)
        for line in proc.stdout:
            log.write(line)
            if verbose:
                sys.stdout.write(line)
        rc = proc.wait()
    seconds = time.time() - start

    if verbose:
        print(f"[run ] rc={rc} in {seconds:,.1f}s  (log: {log_path})")
    return {"ok": rc == 0, "rc": rc, "seconds": seconds, "log": str(log_path)}


# ═══════════════════════════════════════════════════════════════════════════
#  2 -- compare layers/ against layers-golden/
# ═══════════════════════════════════════════════════════════════════════════

def _ignored(rel: str, patterns) -> bool:
    """True if *rel* (a posix relative path) matches any ignore pattern.

    Matched against both the full relative path and the bare basename, so
    ``*.o`` catches ``05_relu/05_relu.o`` without needing ``*/*.o``.
    """
    name = rel.rsplit("/", 1)[-1]
    return any(fnmatch.fnmatch(rel, pat) or fnmatch.fnmatch(name, pat)
               for pat in patterns)


def walk_files(root: Path, patterns) -> dict:
    """``{relative posix path: Path}`` for every non-ignored file under *root*."""
    found = {}
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        rel = path.relative_to(root).as_posix()
        if not _ignored(rel, patterns):
            found[rel] = path
    return found


def normalize(text: str) -> str:
    """Blank out machine-specific absolute paths so two checkouts compare equal.

    Three leak into generated text and none of them is a property of the graph:
    ``layers/Makefile``'s ``TVM_HOME``, ``manifest.json``'s ``source``/``graph``
    (written as ``str(c_path)``), and any ``aie/`` artifact that recorded where
    it was built.  Without this the test only ever passes in the one directory
    the golden was captured in.
    """
    text = text.replace(str(REPO), "$REPO")
    try:
        import tvm  # noqa: F401  -- optional; only to locate TVM_HOME

        tvm_home = str(Path(tvm.__file__).resolve().parents[2])
        text = text.replace(tvm_home, "$TVM_HOME")
    except Exception:                                   # no TVM on this path
        pass
    return text


def _text_diff(rel: str, golden: Path, actual: Path, context: int) -> list:
    """Unified diff of two text files, truncated to *context* lines."""
    try:
        a = normalize(golden.read_text(errors="replace")).splitlines(keepends=True)
        b = normalize(actual.read_text(errors="replace")).splitlines(keepends=True)
    except OSError as exc:
        return [f"    (unreadable: {exc})"]
    diff = list(difflib.unified_diff(a, b, fromfile=f"golden/{rel}",
                                     tofile=f"layers/{rel}", n=1))
    out = [f"    {line.rstrip()}" for line in diff[:context]]
    if len(diff) > context:
        out.append(f"    ... and {len(diff) - context} more diff lines")
    return out


def compare_trees(golden_dir: Path, actual_dir: Path, patterns,
                  context: int = 20) -> dict:
    """Compare two layer trees.  Returns ``{"ok", "missing", "extra", "differing"}``.

    Contents are compared **normalized** (see :func:`normalize`) and as text
    where possible; anything that is not valid UTF-8 falls back to a byte
    compare.  ``missing`` = in the golden but not produced, ``extra`` =
    produced but not in the golden.
    """
    golden = walk_files(golden_dir, patterns)
    actual = walk_files(actual_dir, patterns)

    missing = sorted(set(golden) - set(actual))
    extra = sorted(set(actual) - set(golden))
    differing = []
    for rel in sorted(set(golden) & set(actual)):
        g, a = golden[rel], actual[rel]
        try:
            same = normalize(g.read_text()) == normalize(a.read_text())
        except (UnicodeDecodeError, OSError):
            same = g.read_bytes() == a.read_bytes()
        if not same:
            differing.append((rel, _text_diff(rel, g, a, context)))

    return {"ok": not (missing or extra or differing), "missing": missing,
            "extra": extra, "differing": differing,
            "golden_files": len(golden), "actual_files": len(actual)}


def report_tree(res: dict, show: int = 20) -> None:
    """Print the tree comparison verdict."""
    if res["ok"]:
        print(f"[tree] PASS -- {res['actual_files']} file(s) identical to "
              f"layers-golden/")
        return
    print(f"[tree] FAIL -- golden {res['golden_files']} file(s), "
          f"produced {res['actual_files']}")
    for label, items in (("missing (in golden, not produced)", res["missing"]),
                         ("extra (produced, not in golden)", res["extra"])):
        if items:
            print(f"       {len(items)} {label}:")
            for rel in items[:show]:
                print(f"         {rel}")
            if len(items) > show:
                print(f"         ... and {len(items) - show} more")
    if res["differing"]:
        print(f"       {len(res['differing'])} file(s) differ:")
        for rel, diff in res["differing"][:show]:
            print(f"         {rel}")
            for line in diff:
                print(line)
        if len(res["differing"]) > show:
            print(f"         ... and {len(res['differing']) - show} more")


# ═══════════════════════════════════════════════════════════════════════════
#  3 -- the offloaded layer carries an aie/ folder
# ═══════════════════════════════════════════════════════════════════════════

def _layer_dirs(layers_dir: Path) -> list:
    """Layer folder names, from ``manifest.json`` when it is there.

    The manifest is the authority, not ``ls``: ``_clear_stale`` keeps non-empty
    folders, so a tree can hold two ``01_*`` directories from different builds
    and only one of them belongs to this graph.
    """
    manifest = layers_dir / "manifest.json"
    if manifest.is_file():
        try:
            doc = json.loads(manifest.read_text())
            dirs = [e["dir"] for e in doc.get("layers", []) if e.get("dir")]
            if dirs:
                return dirs
        except (json.JSONDecodeError, OSError, KeyError):
            pass
    return sorted(p.name for p in layers_dir.iterdir() if p.is_dir())


def check_aie_dir(layers_dir: Path, glob_pat: str) -> dict:
    """The conv layer folder must hold an ``aie/`` subdirectory with artifacts.

    Returns ``{"ok", "candidates", "with_aie", "files", "reason"}``.  Failing
    here with ``candidates`` non-empty and ``with_aie`` empty means the flow ran
    and produced the layer but emitted no AIE artifacts next to it; failing with
    ``candidates`` empty means the glob no longer names any layer, which is a
    renaming problem in the test, not in the flow.
    """
    if not layers_dir.is_dir():
        return {"ok": False, "candidates": [], "with_aie": [], "files": {},
                "reason": f"{layers_dir} does not exist"}

    names = _layer_dirs(layers_dir)
    candidates = [n for n in names if fnmatch.fnmatch(n, glob_pat)]
    if not candidates:
        return {"ok": False, "candidates": [], "with_aie": [], "files": {},
                "reason": f"no layer folder matches {glob_pat!r} "
                          f"(have: {', '.join(names[:6])}"
                          f"{', ...' if len(names) > 6 else ''})"}

    with_aie, files = [], {}
    for name in candidates:
        aie = layers_dir / name / "aie"
        if not aie.is_dir():
            continue
        produced = sorted(p.relative_to(aie).as_posix()
                          for p in aie.rglob("*") if p.is_file())
        if produced:
            with_aie.append(name)
            files[name] = produced

    if not with_aie:
        return {"ok": False, "candidates": candidates, "with_aie": [],
                "files": {},
                "reason": f"none of the {len(candidates)} matching layer "
                          f"folder(s) has a non-empty aie/ subdirectory"}

    problems = []
    for name in with_aie:
        absent = [f for f in AIE_EXPECTED_FILES if f not in files[name]]
        if absent:
            problems.append(f"{name}/aie/ lacks {', '.join(absent)}")
    problems += _check_partition(layers_dir, with_aie)
    return {"ok": not problems, "candidates": candidates, "with_aie": with_aie,
            "files": files, "reason": "; ".join(problems)}


def _check_partition(layers_dir: Path, with_aie: list) -> list:
    """Each ``aie/`` folder must be an aiegraph conv that ``partition.json`` sent
    to AIE, and that conv must be in the verified ``aiegraph.mlir``.

    Guards against a stale ``aie/`` left by an older build (``_clear_stale``
    keeps it) passing for one this run produced.
    """
    part, ir = layers_dir / "partition.json", layers_dir / "aiegraph.mlir"
    if not part.is_file() or not ir.is_file():
        return ["no partition.json / aiegraph.mlir -- the aiegraph lift did not run"]
    verdicts = {l["dir"]: l for l in json.loads(part.read_text())["layers"]}
    text = ir.read_text()
    problems = []
    for name in with_aie:
        v = verdicts.get(name)
        if not v or v.get("target") != "aie":
            problems.append(f"{name}: partition.json does not send it to AIE")
        elif not any(k.startswith("conv_") for k in v.get("aiegraph", [])):
            problems.append(f"{name}: aiegraph ops {v.get('aiegraph')} hold no conv")
        elif not any(f"aiegraph.{k}" in text for k in v["aiegraph"]):
            problems.append(f"{name}: {v['aiegraph']} missing from aiegraph.mlir")
        elif name.startswith(STEM_LAYER_PREFIX):
            problems += _check_stem(layers_dir / name / "aie", v)
    return problems


def _check_stem(aie: Path, verdict: dict) -> list:
    """Layer 01 (the stem) must be the aiehlc build of ``conv2dstem.cc``.

    That is the logic ``test_conv2d.cc`` verifies bit-exact against this very
    layer, so its ``aie/`` must carry the same kernel: ``conv2d_spatial.cc``
    with the int32 accumulator and TVM's requant, not the generic placeholder
    ``conv_bn_0.cc`` (int16 accumulator, dummy quant params).
    """
    problems = []
    if not str(verdict.get("source") or "").endswith(STEM_SOURCE):
        problems.append(f"stem aie/ built from {verdict.get('source')!r} "
                        f"({verdict.get('backend')}), want {STEM_SOURCE}")
    spatial = aie / "conv2d_spatial.cc"
    if not spatial.is_file():
        problems.append("stem aie/ has no conv2d_spatial.cc (conv2dstem kernel)")
    else:
        body = spatial.read_text(errors="replace")
        # int32 accumulator + TVM's fixed_point_multiply rounding, as in
        # conv2dstem.cc's conv2d_spatial.
        for marker in ("int32_t sum = 0", "(sh + 31)"):
            if marker not in body:
                problems.append(f"stem conv2d_spatial.cc lacks {marker!r}")
    if (aie / "conv_bn_0.cc").exists():
        problems.append("stem aie/ still holds the generic conv_bn_0.cc")
    if not (aie / "build" / "libconv2dstem.a").is_file():
        print("[aie ] NOTE stem aie/build/libconv2dstem.a absent "
              "(needs the Vitis cross toolchain; not a failure)")
    return problems


ARM_BUILD = OUT_DIR / "arm_build"


def check_elf(since=None) -> dict:
    """``main.elf`` must exist (and be from this run) and must call layer 01 on
    the AIE: ``graph_driver.c`` swaps the stem kernel for its ``aie_*`` entry
    under ``GRAPH_AIE_OFFLOAD``, the Makefile defines that macro, and the ELF
    actually links the entry plus ``conv2d_stem_nchwc``.

    deploy_flow.py exits 0 even when ``make`` fails (it reports and moves on),
    so without this check a broken board link passes the whole test.
    """
    elf, drv, mk = ARM_BUILD / "main.elf", ARM_BUILD / "graph_driver.c", \
        ARM_BUILD / "Makefile"
    problems = []
    if not elf.is_file():
        return {"ok": False, "reason": f"{elf} was not built (see the [arm] "
                                       f"lines in deploy_flow.log)"}
    if since is not None and elf.stat().st_mtime < since:
        problems.append("main.elf is older than this run -- the link failed "
                        "and a stale ELF is on disk")
    text = drv.read_text(errors="replace") if drv.is_file() else ""
    entries = sorted({w.split("(")[0] for w in text.split()
                      if w.startswith("aie_tvmgen_") and "(" in w})
    if "#ifdef GRAPH_AIE_OFFLOAD" not in text or not entries:
        problems.append("graph_driver.c does not call any aie_* entry")
    if mk.is_file() and "-DGRAPH_AIE_OFFLOAD" not in mk.read_text():
        problems.append("Makefile does not define GRAPH_AIE_OFFLOAD")
    nm = shutil.which("aarch64-none-elf-nm") or shutil.which("nm")
    syms = subprocess.run([nm, str(elf)], capture_output=True,
                          text=True).stdout if nm else ""
    for want in entries + ["conv2d_stem_nchwc"]:
        if f" {want}" not in syms:
            problems.append(f"main.elf does not define {want}")
    return {"ok": not problems, "reason": "; ".join(problems),
            "elf": str(elf), "entries": entries,
            "bytes": elf.stat().st_size}


def report_elf(res: dict) -> None:
    if not res["ok"]:
        print(f"[elf ] FAIL -- {res['reason']}")
        return
    print(f"[elf ] PASS -- {res['elf']} ({res['bytes']:,} B) runs layer 01 "
          f"on the AIE via {', '.join(res['entries'])}")


def report_aie(res: dict, show: int = 12) -> None:
    """Print the ``aie/`` check verdict, naming the artifacts it found."""
    if not res["ok"]:
        print(f"[aie ] FAIL -- {res['reason']}")
        if res["candidates"] and not res["with_aie"]:
            print(f"       matching layer folder(s): "
                  f"{', '.join(res['candidates'][:6])}")
        return
    for name in res["with_aie"]:
        produced = res["files"][name]
        print(f"[aie ] PASS -- {name}/aie/ holds {len(produced)} file(s)")
        for rel in produced[:show]:
            print(f"         aie/{rel}")
        if len(produced) > show:
            print(f"         ... and {len(produced) - show} more")


# ═══════════════════════════════════════════════════════════════════════════
#  golden capture
# ═══════════════════════════════════════════════════════════════════════════

def update_golden(layers_dir: Path, golden_dir: Path, patterns,
                  force: bool) -> int:
    """Copy today's ``layers/`` over ``layers-golden/``.  Destructive; opt-in.

    Refuses to overwrite an existing golden without ``--force``: the golden is
    the only record of what the tree looked like when it was last known good,
    and replacing it with a tree nobody has checked turns every later run green
    for the wrong reason.
    """
    if not layers_dir.is_dir():
        print(f"error: {layers_dir} does not exist -- nothing to capture",
              file=sys.stderr)
        return 3
    if golden_dir.exists():
        existing = walk_files(golden_dir, patterns)
        print(f"[gold] {golden_dir} already exists ({len(existing)} file(s))")
        if not force:
            print("error: refusing to overwrite it; re-run with --force if "
                  "today's layers/ really is the new reference",
                  file=sys.stderr)
            return 3
        shutil.rmtree(golden_dir)
        print("[gold] removed (--force)")

    def _skip(src, names):
        base = Path(src).relative_to(layers_dir).as_posix()
        return {n for n in names
                if not (Path(src) / n).is_dir()
                and _ignored(f"{base}/{n}".lstrip("./"), patterns)}

    shutil.copytree(layers_dir, golden_dir, ignore=_skip)
    captured = walk_files(golden_dir, patterns)
    print(f"[gold] captured {len(captured)} file(s) -> {golden_dir}")
    return 0


# ═══════════════════════════════════════════════════════════════════════════
#  driver
# ═══════════════════════════════════════════════════════════════════════════

def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        description=__doc__.splitlines()[0],
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--skip-run", action="store_true",
                    help="verify the tree already on disk instead of running "
                         "deploy_flow.py again")
    ap.add_argument("--clean", action="store_true",
                    help="delete layers/ before the run, so the verdict is "
                         "about this run only (split_layers keeps non-empty "
                         "folders from earlier builds on purpose)")
    ap.add_argument("--deploy-args", default="",
                    help="extra flags passed through to deploy_flow.py, e.g. "
                         "\"--no-arm --aie-layers 1\"")
    ap.add_argument("--golden", type=Path, default=GOLDEN_DIR,
                    help=f"reference tree (default: {GOLDEN_DIR})")
    ap.add_argument("--layers", type=Path, default=LAYERS_DIR,
                    help=f"produced tree (default: {LAYERS_DIR})")
    ap.add_argument("--aie-layer-glob", default=DEFAULT_AIE_LAYER_GLOB,
                    help=f"layer folders that must carry an aie/ "
                         f"subdirectory (default: {DEFAULT_AIE_LAYER_GLOB})")
    ap.add_argument("--no-aie-check", action="store_true",
                    help="skip check 3 (useful while the offload path is "
                         "being brought up)")
    ap.add_argument("--no-elf-check", action="store_true",
                    help="skip check 4 (no cross toolchain on this box)")
    ap.add_argument("--ignore", action="append", default=[],
                    help="extra glob to exclude from the tree comparison "
                         "(repeatable); added to the built-in list")
    ap.add_argument("--only-ignore", action="store_true",
                    help="use ONLY --ignore globs, dropping the built-in list "
                         "(compares .o/.a too)")
    ap.add_argument("--context", type=int, default=20,
                    help="max diff lines printed per differing file "
                         "(default: 20)")
    ap.add_argument("--update-golden", action="store_true",
                    help="capture today's layers/ as layers-golden/ instead of "
                         "comparing against it")
    ap.add_argument("--force", action="store_true",
                    help="with --update-golden, overwrite an existing golden")
    args = ap.parse_args(argv)

    patterns = tuple(args.ignore) if args.only_ignore \
        else DEFAULT_IGNORES + tuple(args.ignore)
    # Resolved, not as given: copytree's ignore callback and walk_files both
    # call relative_to(), which raises on a mix of relative and absolute paths.
    args.layers = args.layers.resolve()
    args.golden = args.golden.resolve()

    if not DEPLOY_FLOW.is_file():
        print(f"error: {DEPLOY_FLOW} not found -- is REPO wrong? ({REPO})",
              file=sys.stderr)
        return 3

    print(f"=== deploy_flow.py --aie-offload regression test")
    print(f"    repo   : {REPO}")
    print(f"    layers : {args.layers}")
    print(f"    golden : {args.golden}")

    # ---- 1. run -----------------------------------------------------------
    if not args.skip_run:
        if args.clean and args.layers.is_dir():
            shutil.rmtree(args.layers)
            print(f"[run ] removed {args.layers} (--clean)")
        TEST_DIR.mkdir(parents=True, exist_ok=True)
        run_started = time.time()
        run = run_deploy_flow(args.deploy_args.split(),
                              TEST_DIR / "deploy_flow.log")
        if not run["ok"]:
            print(f"[run ] FAIL -- deploy_flow.py exited {run['rc']}; "
                  f"see {run['log']}")
            return 2
        print("[run ] PASS")
    else:
        print("[run ] skipped (--skip-run)")

    if not args.layers.is_dir():
        print(f"error: {args.layers} does not exist -- stage 5 did not write "
              f"it (was --no-split passed?)", file=sys.stderr)
        return 3

    # ---- golden capture (instead of comparing) ----------------------------
    if args.update_golden:
        return update_golden(args.layers, args.golden, patterns, args.force)

    # ---- 2. tree ----------------------------------------------------------
    if not args.golden.is_dir():
        print(f"error: no golden tree at {args.golden}. Capture today's "
              f"layers/ as the reference with:\n"
              f"    {sys.argv[0]} --skip-run --update-golden",
              file=sys.stderr)
        return 3
    tree = compare_trees(args.golden, args.layers, patterns, args.context)
    report_tree(tree)

    # ---- 3. aie/ ----------------------------------------------------------
    aie = {"ok": True}
    if args.no_aie_check:
        print("[aie ] skipped (--no-aie-check)")
    else:
        aie = check_aie_dir(args.layers, args.aie_layer_glob)
        report_aie(aie)

    # ---- 4. main.elf -------------------------------------------------------
    elf = {"ok": True}
    if args.no_elf_check:
        print("[elf ] skipped (--no-elf-check)")
    else:
        elf = check_elf(None if args.skip_run else run_started)
        report_elf(elf)

    ok = tree["ok"] and aie["ok"] and elf["ok"]
    print(f"\n=== {'PASS' if ok else 'FAIL'}: tree "
          f"{'ok' if tree['ok'] else 'differs'}, "
          f"aie/ {'ok' if aie['ok'] else 'missing'}, "
          f"main.elf {'ok' if elf['ok'] else 'bad'}")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
