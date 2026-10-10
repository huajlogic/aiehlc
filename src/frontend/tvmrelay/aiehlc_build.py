###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Two build helpers every hand-written AIE op library needs.

``aiehlc_build``  -- run ``script/aiehlc.sh`` on one source in a scratch cwd and
                     install ``aout/worklocal/`` somewhere stable.
``isolate_archive`` -- make an aiehlc static library safe to link NEXT TO
                     another one.

Why isolation is not optional
-----------------------------
Every aiehlc library carries its own copy of the AIE runtime plus generated
``routing()``, ``host_canonicalized()``, ``dskernel_receiver()`` and the
``g_runtime_debug_level``/``g_xtimer_*`` globals. Two such libraries in one
ELF (the stem's ``libconv2dstem.a`` and the shared ``libconvgemm.a``) collide
at link -- and renaming a few symbols is not enough: ``aie_runtime.o`` calls
``routing(dev)`` by its fixed global name (``__Runtime_routing_init``), so a
shared runtime would program one app's stream switches with the other app's
routing. Each library therefore keeps a PRIVATE runtime: the archive is
partially linked into one relocatable object (``ld -r --whole-archive``) so
every internal reference binds inside it, then ``objcopy
--keep-global-symbols`` turns everything except the public API local. The XAie
driver (``libxaienginea78.a``) and libc stay external and shared.
"""

from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
from pathlib import Path

__all__ = ["REPO", "aiehlc_build", "isolate_archive", "cross_tool"]

#: Repo root: .../src/frontend/tvmrelay/aiehlc_build.py -> up three.
REPO = Path(__file__).resolve().parents[3]


def cross_tool(name: str) -> str:
    """``aarch64-none-elf-<name>`` (or ``$CROSS<name>``)."""
    return f"{os.environ.get('CROSS', 'aarch64-none-elf-')}{name}"


def aiehlc_build(source: Path, dest: Path, log: Path, *, skip=(),
                 aie_version: int = 5) -> dict:
    """``source script/aiehlc.sh`` on *source*; install ``aout/worklocal`` as *dest*.

    Runs in a scratch directory because aiehlc writes -- and first
    ``rm -rf``s -- ``aout/`` relative to the CWD. *dest* is replaced wholesale
    so nothing from an earlier build survives. *skip* names files aiehlc
    copies along (its ``*.h`` glob) that are not build products.
    Returns ``{"ok", "reason"?, "log"}``; never raises for a build failure.
    """
    scratch = Path(tempfile.mkdtemp(prefix="aiehlc_"))
    cmd = (f'source "{REPO}/script/aiehlc.sh" --aie-version {aie_version} '
           f'--runtime-source-file "{source}"')
    try:
        log.parent.mkdir(parents=True, exist_ok=True)
        with log.open("w") as fh:
            rc = subprocess.run(["bash", "-c", cmd], cwd=str(scratch),
                                stdout=fh, stderr=subprocess.STDOUT).returncode
        work = scratch / "aout" / "worklocal"
        if rc != 0 or not (work / "host.cc").is_file():
            return {"ok": False, "log": str(log),
                    "reason": f"aiehlc.sh rc={rc}; see {log}"}
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(work, dest, symlinks=True,
                        ignore=lambda _d, names: [n for n in names if n in skip])
    finally:
        shutil.rmtree(scratch, ignore_errors=True)
    return {"ok": True, "log": str(log)}


def isolate_archive(archive: Path, keep, out: Path = None) -> dict:
    """Partially link *archive* and localize every global except *keep*.

    Writes *out* (default: *archive* in place) as a one-member archive.
    Returns ``{"ok", "archive"|"reason", "kept"}``.
    """
    archive = Path(archive)
    out = Path(out) if out else archive
    work = Path(tempfile.mkdtemp(prefix="aieiso_"))
    try:
        obj = work / f"{archive.stem}_isolated.o"
        keep_file = work / "keep.txt"
        keep_file.write_text("\n".join(keep) + "\n")
        steps = [
            [cross_tool("ld"), "-r", "--whole-archive", str(archive), "-o", str(obj)],
            [cross_tool("objcopy"), f"--keep-global-symbols={keep_file}", str(obj)],
        ]
        for cmd in steps:
            proc = subprocess.run(cmd, capture_output=True, text=True)
            if proc.returncode != 0:
                return {"ok": False, "reason": f"{Path(cmd[0]).name}: "
                        f"{(proc.stderr or proc.stdout).strip()[-400:]}"}
        defined = subprocess.run([cross_tool("nm"), "-g", "--defined-only", str(obj)],
                                 capture_output=True, text=True).stdout.split()
        missing = [s for s in keep if s not in defined]
        if missing:
            return {"ok": False, "reason": f"public symbols not defined: {missing}"}
        tmp = work / out.name
        subprocess.run([cross_tool("ar"), "rcs", str(tmp), str(obj)], check=True)
        out.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(tmp), str(out))
        return {"ok": True, "archive": str(out), "kept": list(keep)}
    finally:
        shutil.rmtree(work, ignore_errors=True)
