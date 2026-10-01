###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Relay-era TVM frontend for AIEHLC.

This package targets **TVM 0.16**, the last release with a complete
``tvm.relay``. The sibling ``src/frontend/tvm`` package targets the modern
Relax-era TVM (0.25+). The two are **mutually exclusive** — one Python
environment can only have one TVM installed — so exactly one of them is live at
a time.

Why 0.16 rather than what ships today: Relay was removed in the Relax/Unity
transition, and the compile flow this package implements is specified in terms
of walking Relay IR op by op. ``import tvm.relay`` raises ``ImportError`` on
0.25+, which is also why ``../tvm/relay_import.py`` has been silently inert.

``setup_tvm016.py`` provisions the right TVM:

    python src/frontend/tvmrelay/setup_tvm016.py --verify-only   # report only
    python src/frontend/tvmrelay/setup_tvm016.py --yes           # do it

No 0.16 wheel exists on PyPI (``apache-tvm`` publishes only 0.25+) or on the
tlcpack index, so in practice that script builds from source at tag ``v0.16.0``.

TVM 0.16 also predates onnx 1.16, which deleted ``onnx.mapping``. Importing
this package installs a shim for it (see ``onnx_compat``), so importing
``tvmrelay`` before using ``relay.frontend.from_onnx`` is required, not
decorative.

Import it the way the rest of ``src/frontend`` is imported -- put ``.../src`` on
``sys.path`` and use ``frontend.tvmrelay``::

    import frontend.tvmrelay            # installs the onnx.mapping shim
    from tvm import relay

Putting ``.../src/frontend`` on the path instead shadows the real ``tvm`` and
``onnx`` packages with the sibling directories of those names, which fails in
confusing ways (``module 'tvm' has no attribute '__version__'``).
"""

from .onnx_compat import ensure_onnx_mapping, ensure_tvm016, tvm016_status
from .setup_tvm016 import Installed, detect, provision, verify

# Order matters: get the right TVM in place first, then patch the onnx module
# its Relay frontend will reach for.
#
# ensure_tvm016() installs TVM 0.16 if it is missing -- which uninstalls the
# current TVM and may run a 10-25 minute source build. Set
# AIEHLC_TVM_AUTO_INSTALL=0 to make it report and continue instead.
ensure_tvm016()

# No-op if the real onnx.mapping exists. Does not import tvm.
ensure_onnx_mapping()

__all__ = [
    "Installed",
    "detect",
    "ensure_onnx_mapping",
    "ensure_tvm016",
    "provision",
    "tvm016_status",
    "verify",
]
