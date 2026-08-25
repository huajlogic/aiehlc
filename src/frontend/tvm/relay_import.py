###############################################################################
# Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""ONNX -> TVM Relay import + optimisation pipeline.

``import_relay(onnx_path)`` runs::

    relay.frontend.from_onnx(onnx_model)
      -> InferType
      -> SimplifyInference   (folds BatchNorm into scale/shift == multiply+add)
      -> FoldConstant
      -> FuseOps
      -> InferType

and returns the optimised ``(IRModule, params)``. ``walk.py`` then walks the
fused graph to recover the AIE launch plan.

TVM is an optional dependency (``pip install apache-tvm``). ``tvm_available()``
lets callers degrade gracefully: the frontend falls back to ``model.layer_plan()``
(the canonical, hand-verified plan) when TVM is not installed, so the compile /
CPU-reference path still works without it.
"""

from typing import Optional, Tuple


def tvm_available() -> bool:
    """True iff ``tvm.relay`` can be imported."""
    try:
        import tvm  # noqa: F401
        from tvm import relay  # noqa: F401
        return True
    except Exception:
        return False


def onnx_available() -> bool:
    try:
        import onnx  # noqa: F401
        return True
    except Exception:
        return False


def import_relay(onnx_path: str, input_name: str = "input",
                 input_shape: Optional[Tuple[int, ...]] = None):
    """Import ``onnx_path`` and run the Relay optimisation pipeline.

    Returns ``(mod, params)`` where ``mod`` is the fused, type-inferred
    ``IRModule``. Raises ``RuntimeError`` if TVM or onnx are unavailable.
    """
    if not onnx_available():
        raise RuntimeError("onnx is required to import the model graph")
    if not tvm_available():
        raise RuntimeError("apache-tvm is required (pip install apache-tvm)")

    import onnx
    import tvm
    from tvm import relay

    onnx_model = onnx.load(onnx_path)
    shape_dict = {input_name: input_shape} if input_shape is not None else None
    mod, params = relay.frontend.from_onnx(onnx_model, shape=shape_dict)

    seq = tvm.transform.Sequential([
        relay.transform.InferType(),
        relay.transform.SimplifyInference(),  # BN -> multiply + add
        relay.transform.FoldConstant(),
        relay.transform.FuseOps(),
        relay.transform.InferType(),
    ])
    with tvm.transform.PassContext(opt_level=3):
        mod = seq(mod)
    return mod, params
