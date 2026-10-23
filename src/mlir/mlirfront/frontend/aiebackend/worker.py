###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Child-process host for the ``_aiebackend`` pybind module.

``_aiebackend`` statically links LLVM/MLIR, and TVM 0.16's ``libtvm.so``
carries its own LLVM. Both register LLVM's global command-line options, so
loading the two into one process aborts in either order::

    CommandLine Error: Option 'disable-gisel-legality-check' registered more than once!
    LLVM ERROR: inconsistency in registered CommandLine options

The TVM offload path always has TVM loaded (any import of the
``frontend.tvmrelay`` package does it), so it runs the module here instead, in
a child process that never imports TVM. This file must therefore stay a
standalone, stdlib-only script.

Protocol (``aiebackend.BackendProcess`` is the client): one JSON object per line.

    -> {"fn": "<name>", "args": [...], "kwargs": {...}}
    <- {"ok": true, "result": ...}  |  {"ok": false, "error": "..."}

The first line written is the handshake, ``{"ok": true, "result": "<so path>"}``
or the import error. Replies go to the ORIGINAL stdout; fd 1 is then pointed at
stderr so the pipeline's C++ logging cannot interleave with a reply.

Usage: ``python3 worker.py <dir containing _aiebackend*.so>``
"""

import json
import os
import sys
import traceback


def _to_py(value):
    """pybind results -> JSON-able (tuples become lists; dicts recurse)."""
    if isinstance(value, dict):
        return {str(k): _to_py(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [_to_py(v) for v in value]
    return value


def main() -> int:
    reply = os.fdopen(os.dup(1), "w", buffering=1)
    os.dup2(2, 1)
    sys.stdout = sys.stderr

    def send(obj):
        reply.write(json.dumps(obj) + "\n")
        reply.flush()

    sys.path.insert(0, sys.argv[1])
    try:
        import _aiebackend as backend
    except Exception as exc:  # report, do not crash: the client names the cause
        send({"ok": False, "error": f"{type(exc).__name__}: {exc}"})
        return 1
    send({"ok": True, "result": backend.__file__})

    for line in sys.stdin:
        if not line.strip():
            continue
        try:
            req = json.loads(line)
            fn = getattr(backend, req["fn"])
            send({"ok": True,
                  "result": _to_py(fn(*req.get("args", []),
                                      **req.get("kwargs", {})))})
        except Exception as exc:
            send({"ok": False, "error": f"{type(exc).__name__}: {exc}\n"
                                        f"{traceback.format_exc()}"})
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
