###############################################################################
# Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""TVM-based AIEHLC frontend for the scaled-down int8 ResNet-18.

Pipeline::

    model.export_onnx()            scaled ResNet -> ONNX
      -> relay_import.import_relay  ONNX -> Relay (InferType, SimplifyInference,
                                    FoldConstant, FuseOps)
      -> walk.build_plan            fused graph -> LayerOp launch plan
                                    (validated against model.layer_plan())
      -> _compiler.compile_plan     each launch -> run_aie_pipeline (AIE code)
      -> _compiler.cpu_reference    bit-exact numpy oracle for verification

Every stage degrades gracefully: without TVM the plan comes straight from
``model.layer_plan()``; without the built ``_aietriton_core`` extension the CPU
reference and plan recovery still work, only ``compile_plan`` requires it.

Public API::

    run_resnet(out_dir=..., emit_aie=True)  -> RunResult
    build_plan(...)                          -> List[LayerOp]
    cpu_reference(...)                        -> (logits, buffers)
"""

import os
from dataclasses import dataclass, field
from typing import List, Optional, Tuple

import numpy as np

from . import model
from . import kernels
from . import _compiler
from .model import LayerOp
from ._compiler import cpu_reference, compile_plan
from .walk import build_plan
from .relay_import import tvm_available, onnx_available


@dataclass
class RunResult:
    plan: List[LayerOp]
    logits: np.ndarray
    predicted_class: int
    used_tvm: bool
    emitted: List[Tuple[LayerOp, str, bool]] = field(default_factory=list)


def run_resnet(out_dir: str = "./worklocal/tvm",
               input_data: Optional[np.ndarray] = None,
               emit_aie: bool = False,
               onnx_path: Optional[str] = None,
               mesh: Tuple[int, int] = (2, 2)) -> RunResult:
    """Run the scaled ResNet-18 TVM frontend end to end.

    * Recovers the launch plan from the Relay graph (TVM) or the canonical plan.
    * Computes the bit-exact CPU-reference logits + predicted class.
    * When ``emit_aie`` is True, emits AIE code for every launch under
      ``out_dir`` (requires the built ``_aietriton_core`` extension).

    ``onnx_path`` (optional) is where the ONNX graph is written/read when TVM is
    available; if omitted a temp path under ``out_dir`` is used.
    """
    used_tvm = tvm_available() and onnx_available()

    resolved_onnx = onnx_path
    if used_tvm and resolved_onnx is None:
        os.makedirs(out_dir, exist_ok=True)
        resolved_onnx = os.path.join(out_dir, "resnet18_scaled.onnx")
        try:
            model.export_onnx(resolved_onnx)
        except Exception:
            resolved_onnx = None  # torch missing / export failed -> canonical plan

    plan = build_plan(resolved_onnx if used_tvm else None)

    logits, _bufs = cpu_reference(plan, input_data)
    predicted = int(np.argmax(logits))

    emitted: List[Tuple[LayerOp, str, bool]] = []
    if emit_aie:
        emitted = compile_plan(plan, out_root=out_dir, mesh=mesh)

    return RunResult(plan=plan, logits=logits, predicted_class=predicted,
                     used_tvm=bool(used_tvm and resolved_onnx is not None),
                     emitted=emitted)


__all__ = [
    "run_resnet", "RunResult",
    "build_plan", "cpu_reference", "compile_plan",
    "tvm_available", "onnx_available",
    "model", "kernels",
]
