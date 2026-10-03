#!/usr/bin/env python3
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Provision torch / torchvision / torchao / torch-mlir for this frontend.

    python src/frontend/pytorchmlir/setup_torchmlir.py --verify-only  # report only
    python src/frontend/pytorchmlir/setup_torchmlir.py --dry-run      # print commands
    python src/frontend/pytorchmlir/setup_torchmlir.py --yes          # install

Unlike ``tvmrelay/setup_tvm016.py`` this is **wheels only** -- every piece has a
cp310 wheel, so provisioning takes minutes rather than a 10-25 minute source
build. ``torch-mlir`` is pinned (it publishes date-stamped releases and only the
newest has a cp310 wheel); ``torch`` is deliberately **not** pinned, because
torch-mlir declares no torch dependency and guessing a pin here would be
guesswork rather than knowledge.

The one thing that *is* load-bearing: **torchvision pins torch exactly**
(``torchvision==0.25.0`` requires ``torch==2.10.0``). Installing a bare
``torchvision`` next to an existing torch therefore silently *upgrades* torch and
drags in a matching CUDA stack. When a torch is already present, this script
resolves the torchvision release that pins it and installs that one, so an
existing environment is not rebuilt underneath its other users.

Verification is **functional**: it builds a small conv+relu model, runs it
through PT2E convert and torch-mlir, and checks real IR comes out. A version
string proves nothing about whether the pair actually works together.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import textwrap
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import List, Optional, Sequence

__all__ = [
    "Installed",
    "ProvisionError",
    "detect",
    "main",
    "provision",
    "verify",
]

#: Pinned: only the newest torch-mlir release ships a cp310 wheel.
TORCH_MLIR_PIN = "torch-mlir==20261001"

#: Minimum torch. ``export_for_training`` and the torchao PT2E migration both
#: land around here; below this the flow needs different call sites.
TORCH_FLOOR = (2, 6)

#: CPU wheel index. Keeps a GPU-less host from pulling a multi-GB CUDA stack.
CPU_INDEX = "https://download.pytorch.org/whl/cpu"

#: Modules the flow imports at runtime.
RUNTIME_MODULES = ("torch", "torchvision", "torch_mlir")

#: Written next to the repo so a disruptive change is recoverable.
MANIFEST_NAME = "uninstalled.json"

REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_STATE_DIR = REPO_ROOT / "worklocal" / "pytorchmlir_deploy"

#: Recursion sentinel -- see ``torch_deps.PROVISION_SENTINEL``.
PROVISION_SENTINEL = "_PYTORCHMLIR_PROVISIONING"


class ProvisionError(RuntimeError):
    """A failure the user must act on; :func:`main` turns it into exit 1."""


@dataclass
class Installed:
    """What is importable now."""

    torch: Optional[str]
    torchvision: Optional[str]
    torchao: Optional[str]
    torch_mlir: Optional[str]
    error: str = ""

    @property
    def complete(self) -> bool:
        """True when every runtime module imports."""
        return all((self.torch, self.torchvision, self.torch_mlir))

    def describe(self) -> str:
        parts = [f"torch {self.torch or 'MISSING'}",
                 f"torchvision {self.torchvision or 'MISSING'}",
                 f"torchao {self.torchao or 'absent'}",
                 f"torch-mlir {self.torch_mlir or 'MISSING'}"]
        return " | ".join(parts)


def _log(msg: str) -> None:
    print(f"[torchmlir] {msg}", flush=True)


def _run(cmd: Sequence[str], *, dry_run: bool, check: bool = True) -> int:
    """Run *cmd*. The **only** place ``dry_run`` is honored."""
    _log("$ " + " ".join(cmd))
    if dry_run:
        return 0
    proc = subprocess.run(list(cmd))
    if check and proc.returncode != 0:
        raise ProvisionError(f"command failed ({proc.returncode}): {' '.join(cmd)}")
    return proc.returncode


def _pip(*args: str) -> List[str]:
    return [sys.executable, "-m", "pip", *args]


def _in_virtualenv() -> bool:
    return sys.prefix != sys.base_prefix or bool(os.environ.get("VIRTUAL_ENV"))


# ═══════════════════════════════════════════════════════════════════════════
#  1. detect -- out of process
# ═══════════════════════════════════════════════════════════════════════════

#: Probes in a subprocess and reports one sentinel-prefixed JSON line. Out of
#: process because a half-installed torch can segfault the interpreter, and a
#: detector that dies with it is useless.
_PROBE = textwrap.dedent("""
    import json
    out = {"torch": None, "torchvision": None, "torchao": None,
           "torch_mlir": None, "error": ""}
    def _ver(name, dist=None):
        try:
            mod = __import__(name)
            v = getattr(mod, "__version__", None)
            if v:
                return str(v)
            import importlib.metadata as md
            return md.version(dist or name.replace("_", "-"))
        except Exception as exc:
            out["error"] = (out["error"] + f"; {name}: {exc}").strip("; ")
            return None
    for key, mod in (("torch", "torch"), ("torchvision", "torchvision"),
                     ("torchao", "torchao"), ("torch_mlir", "torch_mlir")):
        out[key] = _ver(mod)
    print("@@PROBE@@" + json.dumps(out))
""")


def _probe() -> dict:
    proc = subprocess.run([sys.executable, "-c", _PROBE],
                          capture_output=True, text=True)
    for line in proc.stdout.splitlines():
        if line.startswith("@@PROBE@@"):
            return json.loads(line[len("@@PROBE@@"):])
    tail = proc.stderr.strip()[-400:]
    return {"torch": None, "torchvision": None, "torchao": None,
            "torch_mlir": None,
            "error": f"probe crashed (exit {proc.returncode}): {tail}"}


def detect() -> Installed:
    """What is installed, determined out-of-process."""
    return Installed(**_probe())


def _torchvision_for(torch_version: str) -> Optional[str]:
    """The torchvision release pinning *torch_version*, or ``None``.

    Without this, ``pip install torchvision`` resolves to the newest release,
    which pins a newer torch and silently upgrades it -- taking a CUDA stack
    along. Queried from PyPI rather than hardcoded, because the mapping grows
    with every release.
    """
    import urllib.request

    base = torch_version.split("+")[0]
    try:
        with urllib.request.urlopen(
                "https://pypi.org/pypi/torchvision/json", timeout=60) as fh:
            data = json.load(fh)
    except Exception:
        return None

    import re

    def key(v):
        return tuple(int(x) for x in re.findall(r"\d+", v)[:3])

    for ver in sorted((v for v in data["releases"]
                       if re.fullmatch(r"\d+\.\d+\.\d+", v)), key=key,
                      reverse=True):
        try:
            with urllib.request.urlopen(
                    f"https://pypi.org/pypi/torchvision/{ver}/json",
                    timeout=60) as fh:
                meta = json.load(fh)
        except Exception:
            continue
        for req in meta["info"].get("requires_dist") or []:
            if req.strip() == f"torch=={base}":
                return f"torchvision=={ver}"
    return None


# ═══════════════════════════════════════════════════════════════════════════
#  2. install
# ═══════════════════════════════════════════════════════════════════════════

def _record_plan(state_dir: Path, plan: List[str], inst: Installed,
                 dry_run: bool) -> None:
    """Write what we are about to change, with a restore command."""
    if dry_run:
        return
    state_dir.mkdir(parents=True, exist_ok=True)
    pins = [f"{k}=={v}" for k, v in
            (("torch", inst.torch), ("torchvision", inst.torchvision),
             ("torchao", inst.torchao), ("torch-mlir", inst.torch_mlir))
            if v]
    record = {
        "installed": plan,
        "previous": asdict(inst),
        "restore_hint": (f"{sys.executable} -m pip install " + " ".join(pins))
                        if pins else "nothing was present to restore",
    }
    path = state_dir / MANIFEST_NAME
    path.write_text(json.dumps(record, indent=2) + "\n")
    _log(f"recorded changes to {path}")
    _log(f"restore with: {record['restore_hint']}")


def install(inst: Installed, *, dry_run: bool, cpu_only: bool = True,
            state_dir: Path = DEFAULT_STATE_DIR) -> None:
    """Install whatever is missing, without disturbing an existing torch."""
    plan: List[str] = []

    if not inst.torch:
        spec = f"torch>={TORCH_FLOOR[0]}.{TORCH_FLOOR[1]}"
        cmd = _pip("install", spec)
        if cpu_only:
            cmd += ["--index-url", CPU_INDEX]
        _run(cmd, dry_run=dry_run)
        plan.append(spec)
        inst = detect() if not dry_run else inst

    if not inst.torchvision:
        spec = "torchvision"
        if inst.torch:
            pinned = _torchvision_for(inst.torch)
            if pinned:
                spec = pinned
                _log(f"torch {inst.torch} is installed -> {spec} "
                     f"(keeps torch unchanged)")
            else:
                _log(f"WARNING: no torchvision found pinning torch {inst.torch}; "
                     f"a bare install may upgrade torch")
        cmd = _pip("install", spec)
        if cpu_only and not inst.torch:
            cmd += ["--index-url", CPU_INDEX]
        _run(cmd, dry_run=dry_run)
        plan.append(spec)

    if not inst.torchao:
        _run(_pip("install", "torchao"), dry_run=dry_run)
        plan.append("torchao")

    if not inst.torch_mlir:
        _run(_pip("install", TORCH_MLIR_PIN), dry_run=dry_run)
        plan.append(TORCH_MLIR_PIN)

    if plan:
        _record_plan(state_dir, plan, inst, dry_run)
    else:
        _log("nothing to install")


# ═══════════════════════════════════════════════════════════════════════════
#  3. verify -- functionally, not by version string
# ═══════════════════════════════════════════════════════════════════════════

_VERIFY = textwrap.dedent("""
    import json
    out = {"ok": False, "torch": None, "ir_lines": 0, "quant_ops": 0, "error": ""}
    try:
        import torch, torch.nn as nn
        out["torch"] = torch.__version__
        sys_path_ok = True

        class M(nn.Module):
            def __init__(self):
                super().__init__()
                self.c = nn.Conv2d(3, 4, 3, padding=1)
                self.r = nn.ReLU()
            def forward(self, x):
                return self.r(self.c(x))

        import frontend.pytorchmlir.torch_deps as td
        from frontend.pytorchmlir.npu_quantizer import make_npu_quantizer
        api = td.pt2e_api()
        ex = (torch.randn(1, 3, 8, 8),)
        gm, _ = td.torch_export_module(M().eval(), ex)
        gm = api.prepare_pt2e(gm, make_npu_quantizer())
        gm(*ex)
        gm = api.convert_pt2e(gm)
        out["quant_ops"] = sum(
            1 for n in gm.graph.nodes
            if n.op == "call_function" and "quantized_decomposed" in str(n.target))

        from torch_mlir import fx
        from torch_mlir.compiler_utils import OutputType
        mod = fx.export_and_import(gm, *ex, output_type=OutputType.TORCH)
        text = str(mod)
        out["ir_lines"] = len(text.splitlines())
        out["ok"] = out["quant_ops"] > 0 and out["ir_lines"] > 10
    except Exception as exc:
        import traceback
        out["error"] = traceback.format_exc()[-600:]
    print("@@VERIFY@@" + json.dumps(out))
""")


def verify(verbose: bool = True) -> bool:
    """Exercise the install for real: PT2E convert + torch-mlir import."""
    script = f"import sys; sys.path.insert(0, {str(REPO_ROOT / 'src')!r})\n" + _VERIFY
    # The sentinel stops this subprocess's `import frontend.pytorchmlir` from
    # calling ensure_torchmlir() -> provision() -> verify() -> ... forever.
    env = dict(os.environ, **{PROVISION_SENTINEL: "1"})
    proc = subprocess.run([sys.executable, "-c", script],
                          capture_output=True, text=True, env=env)

    payload = None
    for line in proc.stdout.splitlines():
        if line.startswith("@@VERIFY@@"):
            payload = json.loads(line[len("@@VERIFY@@"):])
            break

    if payload is None:
        if verbose:
            _log(f"verify crashed (exit {proc.returncode}): "
                 f"{proc.stderr.strip()[-600:]}")
        return False

    if verbose:
        _log(f"torch        : {payload['torch']}")
        _log(f"PT2E convert : {payload['quant_ops']} quantized ops")
        _log(f"torch-mlir   : {payload['ir_lines']} lines of torch IR")
        _log(f"result       : {'ok' if payload['ok'] else 'BROKEN'}")
        if payload["error"]:
            _log(f"error: {payload['error']}")
    return bool(payload["ok"])


# ═══════════════════════════════════════════════════════════════════════════
#  4. orchestration
# ═══════════════════════════════════════════════════════════════════════════

def provision(*, assume_yes: bool = False, dry_run: bool = False,
              verify_only: bool = False, allow_system: bool = False,
              cpu_only: bool = True,
              state_dir: Path = DEFAULT_STATE_DIR) -> int:
    """Detect, install what is missing, verify. Returns an exit code."""
    if verify_only:
        ok = verify()
        _log("verify-only: nothing was changed")
        return 0 if ok else 1

    inst = detect()
    _log(f"found: {inst.describe()}")

    if inst.complete:
        _log("all runtime modules present -- nothing to install")
        return 0 if verify() else 1

    if not (_in_virtualenv() or allow_system or dry_run):
        raise ProvisionError(
            "refusing to install into a system Python. Activate a virtualenv, "
            "or pass --allow-system if you are sure.")

    if not assume_yes and not dry_run:
        if not sys.stdin.isatty():
            raise ProvisionError("refusing to install non-interactively; pass --yes")
        missing = [m for m in RUNTIME_MODULES
                   if not getattr(inst, m.replace("-", "_"))]
        reply = input(f"[torchmlir] install {', '.join(missing)} into "
                      f"{sys.executable}? [y/N] ").strip().lower()
        if reply not in ("y", "yes"):
            _log("aborted")
            return 1

    install(inst, dry_run=dry_run, cpu_only=cpu_only, state_dir=state_dir)

    if dry_run:
        _log("dry-run complete; nothing was changed")
        return 0

    return 0 if verify() else 1


def main(argv: Optional[Sequence[str]] = None) -> int:
    ap = __import__("argparse").ArgumentParser(
        description=__doc__.splitlines()[0])
    ap.add_argument("--yes", action="store_true", help="do not prompt")
    ap.add_argument("--dry-run", action="store_true",
                    help="print commands, change nothing")
    ap.add_argument("--verify-only", action="store_true",
                    help="report only, change nothing")
    ap.add_argument("--allow-system", action="store_true",
                    help="permit installing outside a virtualenv")
    ap.add_argument("--with-cuda", action="store_true",
                    help="allow CUDA wheels (default: CPU-only index)")
    ap.add_argument("--state-dir", type=Path, default=DEFAULT_STATE_DIR,
                    help=f"where {MANIFEST_NAME} is written "
                         f"(default: {DEFAULT_STATE_DIR})")
    args = ap.parse_args(argv)

    try:
        return provision(assume_yes=args.yes, dry_run=args.dry_run,
                         verify_only=args.verify_only,
                         allow_system=args.allow_system,
                         cpu_only=not args.with_cuda,
                         state_dir=args.state_dir.resolve())
    except ProvisionError as exc:
        _log(f"ERROR: {exc}")
        return 1
    except KeyboardInterrupt:
        _log("interrupted")
        return 130


if __name__ == "__main__":
    sys.exit(main())
