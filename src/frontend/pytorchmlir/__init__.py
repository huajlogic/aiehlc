###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""PyTorch -> PT2E int8 -> torch-mlir frontend for AIEHLC.

Ingests a PyTorch model directly and emits MLIR::

    torchvision resnet18 (v1)
      -> torch.export            (ExportedProgram / FX graph)
      -> PT2E quantization       (NPUQuantizer + calibration)  -> int8 Q/DQ graph
      -> torch_mlir.fx           -> torch dialect
      -> backend pipeline        -> linalg-on-tensors (or TOSA)

The sibling ``frontend.tvmrelay`` gets to int8 through ONNX + Relay and needs a
TVM 0.16 source build. These two are **independent** -- no shared dependency, so
unlike ``tvmrelay`` vs ``tvm`` they can both be installed at once.

Import it the way the rest of ``src/frontend`` is imported -- put ``.../src`` on
``sys.path`` and use ``frontend.pytorchmlir``::

    import frontend.pytorchmlir
    from frontend.pytorchmlir import quantize_resnet18

Putting ``.../src/frontend`` on the path instead shadows the real ``torch`` and
``torchvision`` packages with sibling directories and fails confusingly.

Importing self-provisions
-------------------------
This module calls :func:`ensure_torchmlir`, which installs torch / torchvision /
torch-mlir when they are missing. That is a large side effect for an ``import``,
so it announces itself on stderr, and::

    AIEHLC_TORCH_AUTO_INSTALL=0 python your_script.py   # report, do not install

On a healthy environment it costs three imports.
"""

from .torch_deps import (
    AUTO_INSTALL_ENV,
    DepStatus,
    Pt2eApi,
    deps_status,
    ensure_torchmlir,
    pt2e_api,
)

# Get the dependencies in place before anything tries to use them. No-op when
# torch, torchvision and torch_mlir already import.
ensure_torchmlir()

__all__ = [
    "AUTO_INSTALL_ENV",
    "DepStatus",
    "Pt2eApi",
    "deps_status",
    "ensure_torchmlir",
    "pt2e_api",
]
