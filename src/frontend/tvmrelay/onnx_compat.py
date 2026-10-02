###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Make the Relay-era environment usable: TVM 0.16 present, ``onnx.mapping`` back.

Two independent fixups, both applied when ``frontend.tvmrelay`` is imported:

``ensure_tvm016()``
    Checks that the importable TVM is 0.16 with a working ``tvm.relay`` and, if
    it is not, runs ``setup_tvm016.provision()`` to install it. **This can
    uninstall the current TVM and run a 10-25 minute source build**, so it
    announces itself loudly and can be switched off with
    ``AIEHLC_TVM_AUTO_INSTALL=0``.

``ensure_onnx_mapping()``
    Restores the ``onnx.mapping`` module described below.

onnx 1.16 deleted the ``onnx.mapping`` module. TVM 0.16 predates that and does
``from onnx.mapping import TENSOR_TYPE_TO_NP_TYPE`` in three places
(``relay/frontend/onnx.py``, ``relax/frontend/onnx/onnx_frontend.py``,
``contrib/target/onnx.py``), so ``relay.frontend.from_onnx`` raises::

    ImportError: Unable to import onnx which is required No module named 'onnx.mapping'

on any modern onnx. This installs a synthetic ``onnx.mapping`` into
``sys.modules``, rebuilding the tables from ``onnx.helper``, which still
exposes the same information under new names.

Why a shim and not a downgrade: the only thing TVM actually wants is one
enum-to-dtype lookup table. Pinning onnx below 1.16 to supply it would drag
``torch`` (2.10) and ``onnxruntime`` (1.23) -- which share this environment and
expect current onnx -- into a version fight over a dict.

Idempotent, and a no-op on an onnx old enough to still ship the real module.
"""

from __future__ import annotations

import importlib
import os
import sys
import types

__all__ = ["ensure_onnx_mapping", "ensure_tvm016", "tvm016_status"]

#: Set by setup_tvm016.verify() in the environment of its own probe subprocess.
#: That probe imports this package, whose import calls ensure_tvm016(), which
#: would call provision(), which calls verify() again -- forever. The sentinel
#: breaks that cycle: while provisioning is in flight, never provision.
PROVISION_SENTINEL = "_TVMRELAY_PROVISIONING"

#: Set to "0"/"false"/"no" to make ensure_tvm016() report and return instead of
#: installing. Useful in CI, or anywhere a 25-minute build on import is rude.
AUTO_INSTALL_ENV = "AIEHLC_TVM_AUTO_INSTALL"


def tvm016_status() -> tuple:
    """Return ``(ok, detail)`` for the importable TVM. Never raises.

    ``ok`` is True only when TVM is 0.16.x *and* ``tvm.relay`` imports -- a
    version string alone does not prove the Relay frontend is usable.
    """
    try:
        import tvm
    except BaseException as exc:  # a broken native lib can raise anything
        return False, f"not importable ({type(exc).__name__}: {exc})"

    version = getattr(tvm, "__version__", None)
    if version is None:
        # Almost always .../src/frontend on sys.path, whose empty `tvm/`
        # directory becomes a namespace package shadowing the real one.
        return False, (
            f"shadowed by a namespace package at {getattr(tvm, '__path__', '?')} "
            "-- put .../src on sys.path, not .../src/frontend"
        )
    if not str(version).startswith("0.16"):
        return False, f"version {version}, need 0.16.x"
    try:
        from tvm import relay  # noqa: F401
    except BaseException as exc:
        return False, f"{version} but tvm.relay is unusable ({exc})"
    return True, str(version)


def _auto_install_enabled() -> bool:
    if os.environ.get(PROVISION_SENTINEL):
        return False  # recursion guard: a provision is already running
    return os.environ.get(AUTO_INSTALL_ENV, "1").strip().lower() not in (
        "0", "false", "no", "off",
    )


def _reactivate(src_dir) -> None:
    """Make a just-installed TVM importable in *this* process.

    Two reasons the fresh install is otherwise invisible: the ``.pth`` file
    setup_tvm016 writes is only read at interpreter startup, and a stale
    ``tvm`` module may already sit in ``sys.modules`` from the failed probe.
    """
    pkg_dir = str(src_dir / "python")
    if os.path.isdir(pkg_dir) and pkg_dir not in sys.path:
        sys.path.insert(0, pkg_dir)
    for name in [m for m in sys.modules if m == "tvm" or m.startswith("tvm.")]:
        del sys.modules[name]
    importlib.invalidate_caches()


def ensure_tvm016(auto_install: bool = None, verbose: bool = True) -> bool:
    """Guarantee TVM 0.16 with Relay, installing it if necessary.

    Returns True if TVM 0.16 is usable when this returns.

    Installing is not a small side effect -- ``provision()`` uninstalls the
    current TVM and may run a 10-25 minute source build -- so it is announced
    on stderr rather than done quietly, and ``AIEHLC_TVM_AUTO_INSTALL=0``
    turns it off.
    """
    ok, detail = tvm016_status()
    if ok:
        return True

    if auto_install is None:
        auto_install = _auto_install_enabled()
    if not auto_install:
        if verbose:
            print(
                f"[tvmrelay] TVM 0.16 not available ({detail}); auto-install is "
                f"off. Run: python {os.path.join(os.path.dirname(__file__), 'setup_tvm016.py')} --yes",
                file=sys.stderr,
            )
        return False

    from . import setup_tvm016

    if verbose:
        print(
            f"[tvmrelay] TVM 0.16 not available ({detail}).\n"
            f"[tvmrelay] Installing it now -- this uninstalls the current TVM "
            f"and may take 10-25 minutes.\n"
            f"[tvmrelay] Set {AUTO_INSTALL_ENV}=0 to skip this.",
            file=sys.stderr,
        )

    # Sentinel so the verify() subprocess, which imports this package, does not
    # start a second provision from inside the first.
    previous = os.environ.get(PROVISION_SENTINEL)
    os.environ[PROVISION_SENTINEL] = "1"
    try:
        rc = setup_tvm016.provision(assume_yes=True)
    except Exception as exc:
        print(f"[tvmrelay] install failed: {exc}", file=sys.stderr)
        return False
    finally:
        if previous is None:
            os.environ.pop(PROVISION_SENTINEL, None)
        else:
            os.environ[PROVISION_SENTINEL] = previous

    if rc != 0:
        print("[tvmrelay] install did not complete; see the log above",
              file=sys.stderr)
        return False

    _reactivate(setup_tvm016.DEFAULT_SRC_DIR)
    ok, detail = tvm016_status()
    if not ok and verbose:
        print(
            f"[tvmrelay] TVM 0.16 installed but not usable in this already-running "
            f"process ({detail}); re-run the command.",
            file=sys.stderr,
        )
    return ok


def _build_tables():
    """Reconstruct the ``onnx.mapping`` tables from the modern onnx API."""
    import numpy as np
    from onnx import TensorProto, helper

    tensor_to_np = {}
    for _, value in TensorProto.DataType.items():
        if value == TensorProto.UNDEFINED:
            continue
        try:
            tensor_to_np[value] = np.dtype(helper.tensor_dtype_to_np_dtype(value))
        except Exception:
            # BFLOAT16 / FLOAT8* have no numpy equivalent on older numpy; TVM
            # only looks up types it actually encountered in the graph, so a
            # gap here is harmless.
            continue

    # Reverse map. Built second so the lowest-numbered enum wins on collisions,
    # matching what the original module produced.
    np_to_tensor = {}
    for enum_value, np_dtype in sorted(tensor_to_np.items()):
        np_to_tensor.setdefault(np_dtype, enum_value)

    return tensor_to_np, np_to_tensor


def ensure_onnx_mapping() -> bool:
    """Make ``import onnx.mapping`` work. Returns True if a shim was installed."""
    try:
        import onnx.mapping  # noqa: F401

        return False  # real module present; nothing to do
    except ModuleNotFoundError as exc:
        # Distinguish "onnx is absent entirely" from "onnx is installed but
        # 1.16 deleted onnx.mapping" -- the latter is the whole point of this
        # shim and must fall through. Match the top-level name EXACTLY: a
        # missing submodule reports name="onnx.mapping", which is the normal
        # case, not an error. Letting a genuinely-absent onnx escape as a bare
        # ModuleNotFoundError from a package import buries the real cause
        # (usually: wrong interpreter, deps installed in a venv).
        if exc.name == "onnx":
            raise ModuleNotFoundError(
                f"onnx is not installed for this interpreter "
                f"({sys.executable}). The tvmrelay flow needs onnx, "
                f"onnxruntime and TVM 0.16 -- they are usually in the project "
                f"venv. Re-run with that interpreter, e.g.\n"
                f"    <venv>/bin/python3 src/frontend/tvmrelay/deploy_flow.py",
                name=exc.name,
            ) from exc
        # onnx.mapping (or a submodule of it) is what is missing -- the exact
        # case this shim exists for. Fall through and install it. Note this
        # clause must not `raise`: ModuleNotFoundError subclasses ImportError,
        # so it shadows the handler below and nothing else will catch it.
    except ImportError:
        pass

    import onnx

    tensor_to_np, np_to_tensor = _build_tables()

    module = types.ModuleType("onnx.mapping")
    module.__doc__ = "Compatibility shim installed by src/frontend/tvmrelay."
    module.TENSOR_TYPE_TO_NP_TYPE = tensor_to_np
    module.NP_TYPE_TO_TENSOR_TYPE = np_to_tensor

    sys.modules["onnx.mapping"] = module
    onnx.mapping = module  # so `import onnx; onnx.mapping.X` also resolves
    return True
