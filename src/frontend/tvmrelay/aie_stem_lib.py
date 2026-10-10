###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Build a stem-conv layer's ``aie/`` from ``conv2dstem.cc`` with aiehlc.

The generic aiegraph backend (``run_aie_pipeline`` + ``kernels.conv_bn_body``)
emits a placeholder Q7 conv: int16 accumulator, dummy quant params, NCHW
indexing. For ResNet-18's stem -- layer 01,
``contrib_conv2d_NCHWc_subtract_add_subtract_fixed_point_multiply_per_axi`` --
the repo already has the real thing: ``src/aietensorop/conv2dstem/conv2dstem.cc``
(int32 accumulator, TVM's per-channel ``fixed_point_multiply`` requant, the
OIHW3i4o / NCHW4c bridges in ``conv2d_stem_nchwc``), verified bit-exact against
this very layer by ``test_conv2d.cc``.

So a layer whose geometry is exactly that one is built the way
``test_conv2d.cc`` is: ``source script/aiehlc.sh --runtime-source-file
conv2dstem.cc``. ``test_conv2d.cc`` only adds a ``main()`` around
``#include "conv2dstem.cc"``, and the two builds' ``kernel.cc`` /
``routing.cc`` are byte-identical (``host.cc`` differs by exactly that
``main()``). Without ``main()`` aiehlc archives ``libconv2dstem.a`` (skill:
hostlibrarymode), which lands in ``aie/build/`` where ``arm_build``'s
``AIE_LAYER_LIBS`` wildcard picks it up.

``aiehlc.sh`` writes ``aout/`` relative to the **cwd** and ``rm -rf``s it first,
so it runs in a scratch directory and ``aout/worklocal/`` is copied into the
layer's ``aie/`` afterwards. The layer's data headers that aiehlc copies along
(``conv2d_stem_in_weight.h`` / ``_out_golden.h``, ~6 MB of ``layeriohex`` dump)
are left out: the library never includes them.
"""

from __future__ import annotations

import shutil
import subprocess
import tempfile
import time
from pathlib import Path

__all__ = ["STEM_SOURCE", "matches_stem", "build_stem_layer"]

#: Repo root: .../src/frontend/tvmrelay/aie_stem_lib.py -> up three.
_REPO = Path(__file__).resolve().parents[3]

#: The source aiehlc compiles for a stem layer -- the same file
#: ``test_conv2d.cc`` ``#include``s.
STEM_SOURCE = _REPO / "src" / "aietensorop" / "conv2dstem" / "conv2dstem.cc"

#: Not artifacts of the build: data headers aiehlc's ``*.h`` glob copies from
#: the source directory. Nothing in the library includes them.
_SKIP = ("conv2d_stem_in_weight.h", "conv2d_stem_out_golden.h")


def matches_stem(rec: dict) -> bool:
    """True when an aiegraph conv record is exactly the conv2dstem geometry.

    Exact match on every field, against ``byoc.aie_patterns.STEM_GEOMETRY``
    (the one definition the BYOC gate also uses): ``conv2dstem.cc`` bakes the
    geometry into its ``#define``s, its GemmSpace descriptors and its
    ``static_assert``s, so "close" is not runnable.
    """
    from frontend.tvmrelay.byoc.aie_patterns import STEM_GEOMETRY as g

    return ((rec.get("H"), rec.get("W")) == tuple(g["in_hw"])
            and rec.get("Cin") == g["in_c"] and rec.get("Cout") == g["out_c"]
            and rec.get("K") == g["kernel"][0]
            and rec.get("stride") == g["strides"][0])


def build_stem_layer(aie_dir: Path, *, aie_version: int = 5,
                     verbose: bool = True) -> dict:
    """aiehlc-build ``conv2dstem.cc`` and install its output as *aie_dir*.

    Returns ``{"ok", "files", "archive"|None, "reason"?, "log"}``. Never raises
    for a build failure -- the caller records it in ``partition.json``.
    *aie_dir* is replaced wholesale, so no file from an earlier (generic)
    build survives next to the real one.
    """
    aie_dir = Path(aie_dir)
    log = aie_dir.parent / "aiehlc_stem.log"
    scratch = Path(tempfile.mkdtemp(prefix="aiehlc_stem_"))
    cmd = (f'source "{_REPO}/script/aiehlc.sh" --aie-version {aie_version} '
           f'--runtime-source-file "{STEM_SOURCE}"')
    start = time.time()
    try:
        with log.open("w") as fh:
            rc = subprocess.run(["bash", "-c", cmd], cwd=str(scratch),
                                stdout=fh, stderr=subprocess.STDOUT).returncode
        work = scratch / "aout" / "worklocal"
        if rc != 0 or not (work / "host.cc").is_file():
            return {"ok": False, "files": [], "archive": None, "log": str(log),
                    "reason": f"aiehlc.sh rc={rc}; see {log.name}"}
        if aie_dir.exists():
            shutil.rmtree(aie_dir)
        shutil.copytree(work, aie_dir, symlinks=True,
                        ignore=lambda _d, names: [n for n in names if n in _SKIP])
    finally:
        shutil.rmtree(scratch, ignore_errors=True)

    archive = aie_dir / "build" / f"lib{STEM_SOURCE.stem}.a"
    files = sorted(p.name for p in aie_dir.iterdir())
    if verbose:
        size = (f"{archive.stat().st_size / 1024:,.0f} KB" if archive.is_file()
                else "no archive")
        print(f"  [aiegraph]   aiehlc {STEM_SOURCE.name} -> {archive.name} "
              f"({size}, {time.time() - start:.0f}s)")
    return {"ok": True, "files": files, "log": str(log),
            "archive": str(archive) if archive.is_file() else None}
