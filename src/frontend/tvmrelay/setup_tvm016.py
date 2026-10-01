#!/usr/bin/env python3
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Provision TVM 0.16 -- the last release with a complete ``tvm.relay``.

What it does, in order:

  1. Detect the installed TVM (in a subprocess, so a broken install cannot kill
     this process).
  2. If its version is newer than 0.16, uninstall it -- every known TVM
     distribution name -- and sweep the leftovers pip abandons in site-packages.
  3. Try a 0.16 wheel from PyPI, then from the tlcpack index. At time of
     writing neither publishes one, so this is expected to fail harmlessly.
  4. Fall back to a source build at tag ``v0.16.0``: git clone --recursive,
     cmake + ninja, then ``pip install -e python/``.
  5. Verify by actually importing ``tvm.relay`` and calling
     ``relay.frontend.from_onnx`` -- not by reading a version string.

Usage::

    python src/frontend/tvmrelay/setup_tvm016.py --verify-only  # report only
    python src/frontend/tvmrelay/setup_tvm016.py --dry-run      # print commands
    python src/frontend/tvmrelay/setup_tvm016.py --yes          # do it

The build takes 10-25 minutes on a many-core box. Run it in the background and
tail the log.

Why LLVM is off by default: the Relay ONNX importer, the Relay graph walk, and
``target="c"`` codegen need no LLVM backend. Only ``target="llvm"`` JIT does.
This host carries LLVM 19, which postdates TVM 0.16 and is a likely build break,
so LLVM is opt-in via ``--llvm``.

Note this script deliberately does **not** touch numpy. TVM 0.16 predates numpy
2.0 but is already numpy-2 aware (``runtime_ctypes.py`` guards ``np.float_``
behind ``hasattr``) and its Python layer is ctypes-based, so there is no
compiled-ABI break. ``verify()`` is the gate that settles it empirically.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import sysconfig
import textwrap
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import List, Optional, Sequence

TARGET = (0, 16)
TVM_TAG = "v0.16.0"
TVM_REPO = "https://github.com/apache/tvm.git"
TLCPACK_INDEX = "https://tlcpack.ai/wheels"

#: Every distribution name that has ever shipped an importable ``tvm``.
#: ``apache-tvm-ffi`` exists only for TVM >= 0.25 and is dead weight under 0.16.
DIST_NAMES = [
    "apache-tvm",
    "apache-tvm-ffi",
    "tvm",
    "tlcpack",
    "tlcpack-nightly",
    "mlc-ai-nightly",
]

#: Directory name prefixes to sweep out of site-packages after pip uninstall.
#: Both ``apache-tvm`` and ``apache-tvm-ffi`` ship an empty ``top_level.txt``,
#: so pip does not always know to remove the package directories themselves.
LEFTOVER_GLOBS = ["tvm", "tvm-*", "tvm_ffi", "tvm_ffi-*", "apache_tvm*"]

#: Written into --src-dir by uninstall() so a removal is always reversible.
MANIFEST_NAME = "uninstalled.json"

#: TVM 0.16's core runtime requirements, verbatim from its own
#: ``python/gen_requirements.py`` ("core" piece). Frozen, because TVM_TAG is.
#: ``numpy`` is deliberately omitted -- see the module docstring: the installed
#: numpy 2.2.6 works, and this script must not move it.
CORE_DEPS = [
    "attrs",
    "cloudpickle",
    "decorator",
    "ml_dtypes",
    "psutil",
    "scipy",
    "tornado",
    "typing_extensions",
]

REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_SRC_DIR = REPO_ROOT / "thirdparty" / "tvm-0.16"


# --------------------------------------------------------------------------- #
# small helpers
# --------------------------------------------------------------------------- #


class ProvisionError(RuntimeError):
    """Raised for a failure the user must act on; main() turns it into exit 1."""


@dataclass
class Installed:
    """What ``detect()`` found. ``version`` is ``None`` if unparseable."""

    version: Optional[tuple]
    version_str: str
    path: str
    dists: List[str]
    has_relay: bool

    def describe(self) -> str:
        relay = "with relay" if self.has_relay else "NO relay"
        dists = ", ".join(self.dists) if self.dists else "no pip dist"
        return f"tvm {self.version_str} ({relay}) at {self.path} [{dists}]"


def _log(msg: str) -> None:
    print(f"[tvm016] {msg}", flush=True)


def _run(cmd: Sequence[str], *, dry_run: bool, cwd=None, check: bool = True) -> int:
    """Run ``cmd``, streaming output. Returns the exit code."""
    printable = " ".join(str(c) for c in cmd)
    if cwd:
        printable = f"(cd {cwd} && {printable})"
    _log(f"$ {printable}")
    if dry_run:
        return 0
    rc = subprocess.call([str(c) for c in cmd], cwd=str(cwd) if cwd else None)
    if rc != 0 and check:
        raise ProvisionError(f"command failed (exit {rc}): {printable}")
    return rc


def _pip(*args: str) -> List[str]:
    return [sys.executable, "-m", "pip", *args]


def _parse_version(text: str) -> Optional[tuple]:
    """``"0.16.0.dev0"`` -> ``(0, 16, 0)``. Returns None if nothing parses."""
    parts: List[int] = []
    for chunk in text.strip().split("."):
        digits = ""
        for ch in chunk:
            if ch.isdigit():
                digits += ch
            else:
                break
        if not digits:
            break
        parts.append(int(digits))
    return tuple(parts) if parts else None


def _in_virtualenv() -> bool:
    return sys.prefix != sys.base_prefix or bool(os.environ.get("VIRTUAL_ENV"))


# --------------------------------------------------------------------------- #
# 1. detect
# --------------------------------------------------------------------------- #

_PROBE = textwrap.dedent(
    """
    import json
    out = {"version": None, "path": None, "has_relay": False, "error": None}
    try:
        import tvm
        out["version"] = getattr(tvm, "__version__", "")
        out["path"] = getattr(tvm, "__file__", "")
        try:
            from tvm import relay  # noqa: F401
            out["has_relay"] = True
        except Exception:
            out["has_relay"] = False
    except Exception as exc:
        out["error"] = f"{type(exc).__name__}: {exc}"
    print("@@PROBE@@" + json.dumps(out))
    """
)


def _probe_tvm() -> dict:
    """Import tvm out-of-process; a segfaulting install must not take us down."""
    proc = subprocess.run(
        [sys.executable, "-c", _PROBE], capture_output=True, text=True
    )
    for line in proc.stdout.splitlines():
        if line.startswith("@@PROBE@@"):
            return json.loads(line[len("@@PROBE@@") :])
    return {
        "version": None,
        "path": None,
        "has_relay": False,
        "error": f"probe crashed (exit {proc.returncode}): {proc.stderr.strip()[-400:]}",
    }


def _installed_dists() -> List[dict]:
    """``pip list --format=json`` entries whose name is a known TVM dist."""
    proc = subprocess.run(
        _pip("list", "--format=json"), capture_output=True, text=True
    )
    if proc.returncode != 0:
        return []
    try:
        entries = json.loads(proc.stdout)
    except json.JSONDecodeError:
        return []
    wanted = {n.lower().replace("_", "-") for n in DIST_NAMES}
    return [
        e for e in entries if e.get("name", "").lower().replace("_", "-") in wanted
    ]


def detect() -> Optional[Installed]:
    """Report the live TVM, or None if nothing importable is installed."""
    probe = _probe_tvm()
    dists = [f"{d['name']}=={d['version']}" for d in _installed_dists()]
    if probe["version"] is None:
        if dists:
            _log(f"tvm not importable but pip knows: {', '.join(dists)}")
            if probe["error"]:
                _log(f"  import error: {probe['error']}")
            return Installed(None, "<unimportable>", "", dists, False)
        return None
    return Installed(
        version=_parse_version(probe["version"]),
        version_str=probe["version"],
        path=probe["path"] or "",
        dists=dists,
        has_relay=bool(probe["has_relay"]),
    )


def needs_uninstall(inst: Optional[Installed]) -> bool:
    """True iff what is installed is newer than 0.16 (or is broken)."""
    if inst is None:
        return False
    if inst.version is None:
        return True  # present but unimportable -- clear it out
    return inst.version[:2] > TARGET


def is_target(inst: Optional[Installed]) -> bool:
    return inst is not None and inst.version is not None and inst.version[:2] == TARGET


# --------------------------------------------------------------------------- #
# 2. uninstall
# --------------------------------------------------------------------------- #


def _sweep_leftovers(dry_run: bool) -> List[str]:
    """Remove package dirs pip leaves behind (empty ``top_level.txt`` dists)."""
    site = sysconfig.get_paths().get("purelib")
    if not site or not Path(site).is_dir():
        return []
    removed = []
    for pattern in LEFTOVER_GLOBS:
        for path in sorted(Path(site).glob(pattern)):
            # An editable install points elsewhere; only sweep real contents.
            removed.append(str(path))
            _log(f"sweeping leftover {path}")
            if not dry_run:
                if path.is_dir() and not path.is_symlink():
                    shutil.rmtree(path, ignore_errors=True)
                else:
                    path.unlink(missing_ok=True)
    return removed


def uninstall(inst: Installed, *, dry_run: bool, manifest_dir: Path) -> None:
    """pip-uninstall every TVM dist, then sweep site-packages leftovers."""
    found = _installed_dists()
    names = [d["name"] for d in found]
    if names:
        pinned = ", ".join("{name}=={version}".format(**d) for d in found)
        _log(f"uninstalling: {pinned}")
        _run(_pip("uninstall", "-y", *names), dry_run=dry_run, check=False)
    else:
        _log("no TVM pip distribution found to uninstall")

    swept = _sweep_leftovers(dry_run)

    record = {
        "removed_dists": found,
        "swept_paths": swept,
        "previous": asdict(inst) if inst else None,
        "restore_hint": (
            f"{sys.executable} -m pip install "
            + " ".join(f"{d['name']}=={d['version']}" for d in found)
            if found
            else "nothing was removed"
        ),
    }
    if not dry_run:
        manifest_dir.mkdir(parents=True, exist_ok=True)
        path = manifest_dir / MANIFEST_NAME
        path.write_text(json.dumps(record, indent=2) + "\n")
        _log(f"recorded removals to {path}")
    _log(f"restore with: {record['restore_hint']}")


# --------------------------------------------------------------------------- #
# 3. wheel attempt
# --------------------------------------------------------------------------- #


def try_wheel(*, dry_run: bool) -> bool:
    """Try a 0.16 wheel from PyPI then tlcpack. Never raises; returns success."""
    attempts = [
        _pip("install", "apache-tvm==0.16.*"),
        _pip("install", "--extra-index-url", TLCPACK_INDEX, "apache-tvm==0.16.*"),
        _pip("install", "--extra-index-url", TLCPACK_INDEX, "tlcpack==0.16.*"),
    ]
    for cmd in attempts:
        try:
            if _run(cmd, dry_run=dry_run, check=False) == 0 and not dry_run:
                if is_target(detect()):
                    _log("wheel install succeeded")
                    return True
        except ProvisionError:
            pass
    _log("no 0.16 wheel available (expected) -- falling back to a source build")
    return False


# --------------------------------------------------------------------------- #
# 4. source build
# --------------------------------------------------------------------------- #


def _require_tools(names: Sequence[str]) -> None:
    missing = [n for n in names if shutil.which(n) is None]
    if missing:
        raise ProvisionError(
            f"missing required build tool(s): {', '.join(missing)}. "
            "Install them (or load the right module) and re-run."
        )


def _clone(src_dir: Path, *, dry_run: bool) -> None:
    if (src_dir / "CMakeLists.txt").is_file():
        _log(f"reusing existing checkout at {src_dir}")
        return
    # uninstall() drops its manifest here before the clone happens, so a
    # directory holding nothing but our own bookkeeping still counts as empty.
    strays = [
        p for p in src_dir.iterdir() if p.name != MANIFEST_NAME
    ] if src_dir.is_dir() else []
    if strays:
        raise ProvisionError(
            f"{src_dir} exists but is not a TVM checkout "
            f"(found {strays[0].name}); remove it or pass --src-dir"
        )
    src_dir.parent.mkdir(parents=True, exist_ok=True)

    # git clone accepts an existing *empty* directory but not one holding the
    # manifest, so park it for the duration of the clone.
    manifest = src_dir / MANIFEST_NAME
    parked = src_dir.parent / f".{MANIFEST_NAME}.parked"
    if manifest.is_file() and not dry_run:
        manifest.replace(parked)
    try:
        _run(
            [
                "git", "clone", "--recursive", "--depth", "1",
                "--branch", TVM_TAG, TVM_REPO, str(src_dir),
            ],
            dry_run=dry_run,
        )
    finally:
        if parked.is_file():
            src_dir.mkdir(parents=True, exist_ok=True)
            parked.replace(manifest)


#: Source fixups TVM 0.16 needs to build/run against toolchains newer than it.
#: Each entry is ``(relative path, [(old, new), ...])``.
#:
#: Every ``old`` must be absent from the *patched* result, or the substitution
#: re-fires on the next run -- ``"import logging\n" -> "import logging\nimport
#: math\n"`` is the trap, since the pattern survives in its own replacement and
#: stacks another ``import math`` every call. Anchoring on the unpatched-only
#: text (``import logging\nimport multiprocessing``) makes the rewrite
#: self-limiting, which ``test_apply_source_fixups_is_idempotent`` enforces.
#:
#: These are *semantically identical* renames, not behaviour changes:
#:
#: * ``StringRef::startswith``/``endswith`` were renamed to ``starts_with``/
#:   ``ends_with`` in LLVM 16 and the old spellings deleted by LLVM 19. Without
#:   this, an ``--llvm`` build fails to compile three files in src/target/llvm/.
#: * ``np.math`` was only ever an alias for the stdlib ``math`` module; NumPy
#:   2.0 removed it. Without this, ``relay.quantize`` reaches calibration and
#:   dies in ``_power2_scale`` -- i.e. int8 quantization is broken on NumPy 2
#:   even when LLVM is present.
_SOURCE_FIXUPS = (
    ("src/target/llvm/llvm_instance.cc",
     ((".startswith(", ".starts_with("), (".endswith(", ".ends_with("))),
    ("src/target/llvm/codegen_hexagon.cc",
     ((".startswith(", ".starts_with("), (".endswith(", ".ends_with("))),
    ("src/target/llvm/codegen_llvm.cc",
     ((".startswith(", ".starts_with("), (".endswith(", ".ends_with("))),
    ("python/tvm/relay/quantize/_calibrate.py",
     (("import logging\nimport multiprocessing",
       "import logging\nimport math\nimport multiprocessing"),
      ("2 ** np.math.ceil(np.math.log(val, 2))", "2 ** math.ceil(math.log(val, 2))"))),
)


def apply_source_fixups(src_dir: Path, *, dry_run: bool = False) -> list:
    """Patch TVM 0.16 for LLVM 19 + NumPy 2. Returns the files changed.

    Idempotent: re-running finds nothing to do. Safe to call on every build,
    which is the point -- ``thirdparty/tvm-0.16/`` is gitignored, so a fresh
    provision would otherwise silently reintroduce both breakages.
    """
    changed = []
    for rel, subs in _SOURCE_FIXUPS:
        path = src_dir / rel
        if not path.is_file():
            continue
        text = original = path.read_text()
        for old, new in subs:
            if old in text:
                text = text.replace(old, new)
        if text == original:
            continue
        changed.append(rel)
        if not dry_run:
            backup = path.with_suffix(path.suffix + ".orig")
            if not backup.exists():
                backup.write_text(original)
            path.write_text(text)
    if changed:
        _log(f"patched for LLVM 19 / NumPy 2: {', '.join(changed)}")
    return changed


def _cmake_config(build_dir: Path, src_dir: Path, use_llvm: str, *, dry_run: bool) -> None:
    if not dry_run:
        build_dir.mkdir(parents=True, exist_ok=True)
    _run(
        [
            "cmake", "-G", "Ninja",
            "-S", str(src_dir), "-B", str(build_dir),
            "-DCMAKE_BUILD_TYPE=Release",
            # CMake 4 hard-errors on the < 3.5 minimums declared by TVM 0.16's
            # 3rdparty submodules; this restores the old permissive behaviour.
            "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
            # USE_GTEST defaults to AUTO, which picks up a system GTest and then
            # hard-errors if that GTest's config sets IMPORTED_LOCATION only on
            # GTest::gtest_main (true for GTest 1.11 under CMake 4). We do not
            # build TVM's C++ sanity tests, so take it out of the picture.
            "-DUSE_GTEST=OFF",
            f"-DUSE_LLVM={use_llvm}",
        ],
        dry_run=dry_run,
    )


def build_from_source(
    src_dir: Path, *, jobs: int, use_llvm: str, dry_run: bool
) -> None:
    """Clone tag v0.16.0, cmake+ninja it, and pip-install python/ editable."""
    _require_tools(["git", "cmake", "ninja"])
    _clone(src_dir, dry_run=dry_run)
    # Must run after the clone and before cmake: two of the four files are C++
    # that will not compile against LLVM 19 as shipped.
    apply_source_fixups(src_dir, dry_run=dry_run)

    build_dir = src_dir / "build"
    _cmake_config(build_dir, src_dir, use_llvm, dry_run=dry_run)
    _log(f"building with {jobs} jobs -- this takes 10-25 minutes")
    _run(["ninja", "-C", str(build_dir), f"-j{jobs}"], dry_run=dry_run)

    lib = build_dir / "libtvm.so"
    if not dry_run and not lib.is_file():
        raise ProvisionError(f"build finished but {lib} is missing")

    _install_python_package(src_dir, dry_run=dry_run)


def _install_python_package(src_dir: Path, *, dry_run: bool) -> None:
    """Put ``<src_dir>/python`` on sys.path, keeping the in-source layout.

    Editable is not a preference, it is a requirement: TVM 0.16's
    ``_ffi/libinfo.py`` locates ``libtvm.so`` by walking up from the package
    directory to a sibling ``build/``. Copying ``python/tvm`` into
    site-packages severs that, and the import then fails looking for the .so.

    ``pip install -e`` on a setup.py-only project goes through the legacy
    ``setup.py develop`` path, which setuptools 80+ may refuse; the .pth
    fallback achieves the same layout without setuptools' help.
    """
    pkg_dir = src_dir / "python"
    rc = _run(
        _pip("install", "--no-build-isolation", "-e", str(pkg_dir)),
        dry_run=dry_run,
        check=False,
    )
    if rc == 0 or dry_run:
        return

    # TVM 0.16 predates PEP 660, so modern pip refuses `-e` on it outright
    # ("build backend is missing the 'build_editable' hook"). A .pth entry is
    # the same thing by hand.
    _log("editable install failed; falling back to a .pth path entry")
    site = sysconfig.get_paths().get("purelib")
    if not site:
        raise ProvisionError("cannot locate site-packages for the .pth fallback")
    pth = Path(site) / "tvm-0.16.pth"
    pth.write_text(f"{pkg_dir}\n")
    _log(f"wrote {pth} -> {pkg_dir}")

    # A .pth entry bypasses pip entirely, so nothing resolved TVM's own
    # dependencies -- without this, `import tvm` dies on `decorator`.
    _log("installing TVM core dependencies (pip did not get to)")
    _run(_pip("install", *CORE_DEPS), dry_run=dry_run, check=False)


# --------------------------------------------------------------------------- #
# 5. verify
# --------------------------------------------------------------------------- #

#: Run out-of-process by verify(). This does not merely check that
#: ``from_onnx`` exists -- it builds a one-op ONNX model and imports it, because
#: the failure modes that actually bite (onnx 1.16 dropping ``onnx.mapping``,
#: a missing runtime dep) only surface once the function runs.
_VERIFY = textwrap.dedent(
    """
    import json, os, sys
    out = {"ok": False, "version": None, "relay": False, "from_onnx": False,
           "numpy": None, "onnx": None, "shimmed": None, "error": None}
    try:
        import numpy as np
        out["numpy"] = np.__version__

        # Sample this BEFORE importing the package: frontend.tvmrelay's
        # __init__ installs the shim on import, so asking afterwards always
        # reports "already there" and tells us nothing.
        import importlib.util
        out["shimmed"] = importlib.util.find_spec("onnx.mapping") is None

        # Repo convention: .../src goes on the path, packages are reached as
        # frontend.<name>. Adding .../src/frontend instead would shadow the
        # real `tvm` and `onnx` with the sibling directories of the same name.
        sys.path.insert(0, os.path.join(REPO, "src"))
        import frontend.tvmrelay  # noqa: F401  (installs the onnx.mapping shim)

        import onnx
        from onnx import TensorProto, helper
        out["onnx"] = onnx.__version__

        import tvm
        out["version"] = tvm.__version__
        from tvm import relay
        out["relay"] = True

        node = helper.make_node("Relu", ["x"], ["y"])
        graph = helper.make_graph(
            [node], "probe",
            [helper.make_tensor_value_info("x", TensorProto.FLOAT, [1, 4])],
            [helper.make_tensor_value_info("y", TensorProto.FLOAT, [1, 4])],
        )
        model = helper.make_model(graph, producer_name="tvm016-verify")
        mod, _ = relay.frontend.from_onnx(model, shape={"x": (1, 4)})
        mod = relay.transform.InferType()(mod)
        out["from_onnx"] = "main" in [gv.name_hint for gv in mod.get_global_vars()]
        out["ok"] = tvm.__version__.startswith("0.16") and out["from_onnx"]
    except Exception as exc:
        out["error"] = f"{type(exc).__name__}: {exc}"
    print("@@VERIFY@@" + json.dumps(out))
    """
)


def verify() -> bool:
    """Import tvm.relay out-of-process and confirm the ONNX frontend is live."""
    script = f"REPO = {str(REPO_ROOT)!r}\n" + _VERIFY
    # This probe imports frontend.tvmrelay, whose __init__ calls
    # ensure_tvm016(), which would call provision() -> verify() -> ... The
    # sentinel tells onnx_compat that a provision is already in flight.
    env = dict(os.environ, _TVMRELAY_PROVISIONING="1")
    proc = subprocess.run(
        [sys.executable, "-c", script], capture_output=True, text=True, env=env
    )
    payload = None
    for line in proc.stdout.splitlines():
        if line.startswith("@@VERIFY@@"):
            payload = json.loads(line[len("@@VERIFY@@") :])
    if payload is None:
        _log(f"verification probe crashed: {proc.stderr.strip()[-600:]}")
        return False

    shim = {True: "shim installed", False: "native", None: "n/a"}[payload["shimmed"]]
    _log(f"tvm version  : {payload['version']}")
    _log(f"numpy        : {payload['numpy']}")
    _log(f"onnx         : {payload['onnx']} ({shim} for onnx.mapping)")
    _log(f"tvm.relay    : {'ok' if payload['relay'] else 'MISSING'}")
    _log(f"from_onnx    : {'ok (imported a model)' if payload['from_onnx'] else 'BROKEN'}")
    if payload["error"]:
        _log(f"error        : {payload['error']}")
    return bool(payload["ok"])


# --------------------------------------------------------------------------- #
# orchestration
# --------------------------------------------------------------------------- #


def _confirm(inst: Installed, assume_yes: bool) -> bool:
    if assume_yes:
        return True
    if not sys.stdin.isatty():
        _log("refusing to uninstall non-interactively; pass --yes")
        return False
    print(f"\nAbout to UNINSTALL {inst.describe()}\nand install TVM {TVM_TAG}.")
    return input("Proceed? [y/N] ").strip().lower() in ("y", "yes")


def provision(
    *,
    assume_yes: bool = False,
    src_dir: Path = DEFAULT_SRC_DIR,
    jobs: Optional[int] = None,
    use_llvm: str = "OFF",
    force_source: bool = False,
    dry_run: bool = False,
    verify_only: bool = False,
    allow_system: bool = False,
) -> int:
    """Run the full detect -> uninstall -> install -> verify sequence."""
    jobs = jobs or min(os.cpu_count() or 4, 32)

    inst = detect()
    _log(f"detected: {inst.describe() if inst else 'no TVM installed'}")

    if verify_only:
        ok = verify()
        _log("verify-only: nothing was changed")
        return 0 if ok else 1

    if is_target(inst) and inst.has_relay and not force_source:
        _log("TVM 0.16 with relay is already installed -- nothing to do")
        return 0 if verify() else 1

    if not _in_virtualenv() and not allow_system and not dry_run:
        raise ProvisionError(
            "not running inside a virtualenv. This script uninstalls packages; "
            "refusing to touch a system Python. Activate a venv, or pass "
            "--allow-system if you really mean it."
        )

    # ---- step 1: remove anything newer than 0.16 -------------------------- #
    if needs_uninstall(inst):
        assert inst is not None
        if not _confirm(inst, assume_yes or dry_run):
            _log("aborted by user; nothing was changed")
            return 1
        uninstall(inst, dry_run=dry_run, manifest_dir=src_dir)
    elif inst is not None and not is_target(inst):
        _log(f"installed tvm {inst.version_str} is older than 0.16; replacing it")
        uninstall(inst, dry_run=dry_run, manifest_dir=src_dir)

    # ---- step 2: wheel, else source --------------------------------------- #
    if force_source or not try_wheel(dry_run=dry_run):
        build_from_source(
            src_dir, jobs=jobs, use_llvm=use_llvm, dry_run=dry_run
        )

    if dry_run:
        _log("dry-run complete; nothing was changed")
        return 0

    # ---- step 3: prove it ------------------------------------------------- #
    if not verify():
        raise ProvisionError(
            "TVM installed but verification failed -- tvm.relay is not usable. "
            f"See the build tree at {src_dir}."
        )
    _log("SUCCESS: tvm 0.16 with relay is live")
    _log("active frontend is now src/frontend/tvmrelay (the Relax-era")
    _log("src/frontend/tvm package will not work against this install)")
    if use_llvm.upper() == "OFF":
        _log("note: built with USE_LLVM=OFF -- target='c' works, target='llvm' does not")
    return 0


def main(argv: Optional[Sequence[str]] = None) -> int:
    p = argparse.ArgumentParser(
        prog="setup_tvm016",
        description="Uninstall a too-new TVM and install 0.16 (Relay-capable).",
    )
    p.add_argument("--yes", action="store_true", help="skip the uninstall prompt")
    p.add_argument(
        "--src-dir", type=Path, default=DEFAULT_SRC_DIR,
        help=f"clone/build directory (default: {DEFAULT_SRC_DIR})",
    )
    p.add_argument("--jobs", type=int, default=None, help="ninja parallelism")
    p.add_argument(
        "--llvm", nargs="?", const="__auto__", default=None,
        metavar="PATH",
        help="build with LLVM; PATH defaults to `which llvm-config` (default: OFF)",
    )
    p.add_argument("--force-source", action="store_true", help="skip the wheel attempt")
    p.add_argument("--dry-run", action="store_true", help="print commands, change nothing")
    p.add_argument("--verify-only", action="store_true", help="report only, change nothing")
    p.add_argument(
        "--allow-system", action="store_true",
        help="permit running outside a virtualenv",
    )
    args = p.parse_args(argv)

    if args.llvm is None:
        use_llvm = "OFF"
    elif args.llvm == "__auto__":
        found = shutil.which("llvm-config")
        if not found:
            _log("--llvm given but llvm-config is not on PATH; using ON")
            use_llvm = "ON"
        else:
            use_llvm = found
    else:
        use_llvm = args.llvm

    try:
        return provision(
            assume_yes=args.yes,
            src_dir=args.src_dir.resolve(),
            jobs=args.jobs,
            use_llvm=use_llvm,
            force_source=args.force_source,
            dry_run=args.dry_run,
            verify_only=args.verify_only,
            allow_system=args.allow_system,
        )
    except ProvisionError as exc:
        _log(f"ERROR: {exc}")
        return 1
    except KeyboardInterrupt:
        _log("interrupted")
        return 130


if __name__ == "__main__":
    sys.exit(main())
