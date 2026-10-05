###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""AIE backend: Python access to the ``TilingLinalgPipeline`` C++ compiler.

``_aiebackend`` is the pybind11 module (``aiebackend_pybind.cpp``) exposing

    run_aie_pipeline       tensor specs + kernel body -> host/kernel/routing.cc, .bcf
    build_aiegraph_module  op dicts -> verified aiegraph IR
    lower_aiegraph         aiegraph IR -> per-launch tensor_specs
    build_kernel_body      KernelOp list -> C kernel body (EmitC)
    orchestrate_conv_layer multi-kernel variant of run_aie_pipeline

It is frontend-neutral: the Triton frontend (``aietriton``) and the TVM offload
path (``src/frontend/tvmrelay``) both drive it. Two ways in:

``load()``
    Import the module into THIS process. Use it when nothing else in the process
    links LLVM (the Triton frontend).

``spawn()``
    Run it in a child process (``worker.py``) and return a ``BackendProcess``
    whose methods mirror the module's. Required next to TVM: ``_aiebackend``
    statically links LLVM/MLIR, TVM's ``libtvm.so`` carries another LLVM, and
    the two abort on duplicate LLVM command-line options in either import order
    (skill: aiebackendtvmllvm).

This package must stay stdlib-only -- ``spawn()`` is called from processes that
have TVM loaded, and the worker must never pull TVM in.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

__all__ = ["MODULE_NAME", "find_module_dir", "load", "spawn", "BackendProcess"]

MODULE_NAME = "_aiebackend"

_PKG_DIR = Path(__file__).resolve().parent
_REPO = _PKG_DIR.parents[4]              # <repo>/src/mlir/mlirfront/frontend/aiebackend
_REL = _PKG_DIR.relative_to(_REPO)


def find_module_dir():
    """Directory holding the built ``_aiebackend*.so``, or ``None``.

    ``pybind11_add_module`` writes the ``.so`` into the CMake BUILD tree, not
    next to these sources, so the build trees are searched first (``make``
    alone is enough; ``make install`` is optional). ``$AIEHLC_BUILD_DIR``
    overrides the default ``<repo>/build`` for out-of-tree builds.
    """
    env_build = os.environ.get("AIEHLC_BUILD_DIR")
    candidates = [
        Path(env_build) / _REL if env_build else None,
        _REPO / "build" / _REL,          # the usual cmake build tree
        _REPO / "build_claude" / _REL,   # the repo's second configured tree
        _PKG_DIR,                        # an installed copy (make install)
    ]
    for d in candidates:
        if d is not None and d.is_dir() and list(d.glob(MODULE_NAME + "*.so")):
            return d
    return None


def _require_module_dir() -> Path:
    d = find_module_dir()
    if d is None:
        raise ModuleNotFoundError(
            f"no {MODULE_NAME}*.so under build/, build_claude/, "
            f"$AIEHLC_BUILD_DIR or {_PKG_DIR}. Configure with "
            f"-Dpybind11_DIR=$(python3 -m pybind11 --cmakedir), then "
            f"`make {MODULE_NAME}` (skill: mlirbuildsandbox)")
    return d


def load():
    """Import ``_aiebackend`` in-process. NOT safe once TVM is loaded."""
    d = str(_require_module_dir())
    if d not in sys.path:
        sys.path.insert(0, d)
    import _aiebackend  # noqa: F401

    return _aiebackend


class BackendProcess:
    """``_aiebackend`` running in a child process (``worker.py``).

    Calls look the same as on the module -- ``backend.run_aie_pipeline(...)``
    -- with JSON-able arguments and results (tuples come back as lists).
    """

    def __init__(self, module_dir: Path):
        self._proc = subprocess.Popen(
            [sys.executable, str(_PKG_DIR / "worker.py"), str(module_dir)],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
        hello = self._recv()
        if not hello.get("ok"):
            self.close()
            raise ImportError(hello.get("error", "aiebackend worker failed to start"))
        self.__file__ = hello["result"]

    def _recv(self) -> dict:
        line = self._proc.stdout.readline()
        if not line:
            raise RuntimeError(f"aiebackend worker exited "
                               f"(rc={self._proc.poll()}); see stderr above")
        return json.loads(line)

    def __getattr__(self, name):
        if name.startswith("_"):
            raise AttributeError(name)

        def call(*args, **kwargs):
            self._proc.stdin.write(json.dumps(
                {"fn": name, "args": list(args), "kwargs": kwargs}) + "\n")
            self._proc.stdin.flush()
            reply = self._recv()
            if not reply.get("ok"):
                raise RuntimeError(f"{MODULE_NAME}.{name}: {reply['error']}")
            return reply["result"]
        return call

    def close(self) -> None:
        if self._proc.poll() is None:
            self._proc.stdin.close()
            self._proc.wait()


def spawn() -> BackendProcess:
    """Start ``_aiebackend`` in a child process. Safe next to TVM."""
    return BackendProcess(_require_module_dir())
