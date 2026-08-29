###############################################################################
# Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Glue between the recovered launch plan and the AIE pipeline / CPU reference.

Two independent capabilities, so the frontend is useful with or without the
compiled pybind extension:

* ``cpu_reference(plan, input_data)`` — a pure-numpy interpreter of the
  ``LayerOp`` plan. Its per-op math is a byte-for-byte port of the CPU
  references in ``resnet18_triton.py`` (int16 wrap in the conv accumulator, Q7
  ``(int16)(acc*scale)>>7`` BN, uint8 config reads), so it is the bit-exact
  oracle the AIE result is checked against. Needs only numpy.

* ``compile_plan(plan, out_root, mesh)`` — for each launch, dispatches on the op
  kind (``cpu_codegen.is_aie_op``). Conv2d-family ops (``conv_bn``,
  ``conv_bn_relu``) assemble the ``tensor_specs`` (feature + params + output int8
  buffers) and the C kernel body (``kernels.kernel_body_for``) and call
  ``_aietriton_core.run_aie_pipeline`` (reusing the aietriton package's compiled
  extension). Non-conv ops (``residual_add_relu``, ``avgpool_fc``) are emitted as
  bit-exact TVM CPU C via ``cpu_codegen.emit_cpu_launch`` (no AIE backend). Each
  launch gets its own ``out_root/<idx>_<op>`` directory (AIE ops write
  ``host.cc``/``kernel.cc``/``routing.cc``; CPU ops write ``<func_name>.c``).
  Only the AIE ops need the built ``_aietriton_core`` extension.

The optional ``im2col_dma_spec`` helper builds the multi-dim shim DMA addressing
(mode 0) for the im2col conv path exposed by the extended pybind ``dma_specs``
argument; the default conv path is a direct convolution whose loop nest lives in
the kernel body, so ``dma_specs`` is left empty unless a caller opts in.
"""

import os
import sys
from typing import Dict, List, Optional, Tuple

import numpy as np

from . import model
from .model import CONFIG_SZ, LayerOp
from . import kernels
from . import cpu_codegen


# ═══════════════════════════════════════════════════════════════════════════
#  CPU reference — bit-exact numpy port of resnet18_triton.py's CPU refs
# ═══════════════════════════════════════════════════════════════════════════

def _cpu_conv(feat_in: np.ndarray, params: np.ndarray, relu: bool) -> np.ndarray:
    """Conv2D + Q7 BN (+ ReLU). Mirrors cpu_conv_bn_relu / cpu_conv_bn."""
    H = int(np.uint8(params[0]))
    W = int(np.uint8(params[1]))
    Cin = int(np.uint8(params[2]))
    Cout = int(np.uint8(params[3]))
    K = int(np.uint8(params[4]))
    stride = int(np.uint8(params[5]))
    pad = K // 2

    wt_count = Cin * Cout * K * K
    weights = params[CONFIG_SZ:CONFIG_SZ + wt_count]
    bn_scale = params[CONFIG_SZ + wt_count:CONFIG_SZ + wt_count + Cout]
    bn_bias = params[CONFIG_SZ + wt_count + Cout:CONFIG_SZ + wt_count + Cout * 2]

    outH, outW = H // stride, W // stride
    out = np.zeros(Cout * outH * outW, dtype=np.int8)
    lo = 0 if relu else -128

    for oc in range(Cout):
        for oh in range(outH):
            for ow in range(outW):
                s = np.int16(0)
                for ic in range(Cin):
                    for kh in range(K):
                        for kw in range(K):
                            ih = oh * stride + kh - pad
                            iw = ow * stride + kw - pad
                            if 0 <= ih < H and 0 <= iw < W:
                                in_idx = ic * H * W + ih * W + iw
                                wt_idx = oc * Cin * K * K + ic * K * K + kh * K + kw
                                s += np.int16(feat_in[in_idx]) * np.int16(weights[wt_idx])
                bn_out = (s * np.int16(bn_scale[oc])) >> 7
                bn_out += np.int16(bn_bias[oc])
                out[oc * outH * outW + oh * outW + ow] = np.int8(max(lo, min(127, int(bn_out))))
    return out


def _cpu_add_relu(main_path: np.ndarray, skip_path: np.ndarray) -> np.ndarray:
    """Element-wise add + ReLU + saturate. Mirrors cpu_add_relu."""
    out = np.zeros(len(main_path), dtype=np.int8)
    for i in range(len(main_path)):
        s = np.int16(main_path[i]) + np.int16(skip_path[i])
        out[i] = np.int8(max(0, min(127, int(s))))
    return out


def _cpu_avgpool_fc(feat: np.ndarray, fc_params: np.ndarray,
                    spatial_h: int, spatial_w: int,
                    channels: int, num_classes: int) -> np.ndarray:
    """Global average pool + FC. Mirrors cpu_avgpool_fc (headerless fc_params)."""
    spatial_sz = spatial_h * spatial_w
    fc_weights = fc_params[:channels * num_classes]
    fc_bias = fc_params[channels * num_classes:]

    pooled = np.zeros(channels, dtype=np.int8)
    for c in range(channels):
        s = np.int16(0)
        for idx in range(spatial_sz):
            s += np.int16(feat[c * spatial_sz + idx])
        pooled[c] = np.int8(int(s) // spatial_sz)

    logits = np.zeros(num_classes, dtype=np.int8)
    for j in range(num_classes):
        acc = np.int16(0)
        for i in range(channels):
            acc += np.int16(pooled[i]) * np.int16(fc_weights[i * num_classes + j])
        acc += np.int16(fc_bias[j])
        logits[j] = np.int8(max(-128, min(127, int(acc))))
    return logits


def cpu_reference(plan: Optional[List[LayerOp]] = None,
                  input_data: Optional[np.ndarray] = None
                  ) -> Tuple[np.ndarray, Dict[str, np.ndarray]]:
    """Interpret ``plan`` on the CPU with the bit-exact int8/Q7 math.

    Returns ``(logits, buffers)`` where ``buffers`` is the final value of every
    named scratch buffer. This is the oracle the AIE run is compared against.
    """
    if plan is None:
        plan = model.layer_plan()
    if input_data is None:
        input_data = model.make_input()

    bufs: Dict[str, np.ndarray] = {"input": input_data}
    for op in plan:
        if op.op in ("conv_bn_relu", "conv_bn"):
            params = model.make_conv_params(op.H, op.W, op.Cin, op.Cout, op.K, op.stride)
            bufs[op.out] = _cpu_conv(bufs[op.ins[0]], params, relu=(op.op == "conv_bn_relu"))
        elif op.op == "residual_add_relu":
            bufs[op.out] = _cpu_add_relu(bufs[op.ins[0]], bufs[op.ins[1]])
        elif op.op == "avgpool_fc":
            fc = model.fc_params_no_header(op.channels, op.num_classes)
            bufs[op.out] = _cpu_avgpool_fc(bufs[op.ins[0]], fc, op.spatial_h,
                                           op.spatial_w, op.channels, op.num_classes)
        else:
            raise ValueError(f"unknown op {op.op!r}")
    return bufs["logits"], bufs


# ═══════════════════════════════════════════════════════════════════════════
#  Param buffers + tensor specs per launch
# ═══════════════════════════════════════════════════════════════════════════

def params_for(op: LayerOp) -> Optional[np.ndarray]:
    """The param buffer an op's kernel reads from ``window_in_1`` (None if it has none)."""
    if op.op in ("conv_bn_relu", "conv_bn"):
        return model.make_conv_params(op.H, op.W, op.Cin, op.Cout, op.K, op.stride)
    if op.op == "avgpool_fc":
        return model.make_fc_params(op.spatial_h, op.spatial_w, op.channels, op.num_classes)
    return None  # residual_add_relu has no param buffer


def _tensor_specs(op: LayerOp) -> List[tuple]:
    """(shape, bits, isInput) per window for ``op`` — flat int8 buffers."""
    if op.op in ("conv_bn_relu", "conv_bn"):
        in_sz = op.Cin * op.H * op.W
        out_sz = op.Cout * op.out_h * op.out_w
        param_sz = len(params_for(op))
        return [([in_sz], 8, True), ([param_sz], 8, True), ([out_sz], 8, False)]
    if op.op == "residual_add_relu":
        n = op.length
        return [([n], 8, True), ([n], 8, True), ([n], 8, False)]
    if op.op == "avgpool_fc":
        in_sz = op.channels * op.spatial_h * op.spatial_w
        param_sz = len(params_for(op))
        return [([in_sz], 8, True), ([param_sz], 8, True), ([op.num_classes], 8, False)]
    raise ValueError(f"unknown op {op.op!r}")


def im2col_dma_spec(H: int, W: int, Cin: int, K: int, stride: int) -> tuple:
    """Multi-dim shim DMA addressing for the im2col conv feature input (mode 0).

    Mirrors ``im2colAddressing`` (doc/design/conv2d_im2col_design.md §11/§13):
    ``OH=(H+2P-K)/stride+1``; for ``C==1`` dims are ``{(1,KW),(W,KH),(stride,OW)}``
    else ``{(1,KW),(W,KH),(W*KH,C),(stride,OW)}``; ``iter_step=W*stride``,
    ``iter_wrap=OH``, ``ddrShape=[H,W,C]``. Returns the
    ``(dims, iter_step, iter_wrap, ddr_shape, mode)`` tuple the extended
    ``run_aie_pipeline`` ``dma_specs`` argument accepts. Optional: the default
    conv path is a direct convolution in the kernel body.
    """
    pad = K // 2
    OH = (H + 2 * pad - K) // stride + 1
    OW = (W + 2 * pad - K) // stride + 1
    if Cin == 1:
        dims = [(1, K), (W, K), (stride, OW)]
    else:
        dims = [(1, K), (W, K), (W * K, Cin), (stride, OW)]
    return (dims, W * stride, OH, [H, W, Cin], 0)


# ═══════════════════════════════════════════════════════════════════════════
#  AIE compilation — one run_aie_pipeline call per launch
# ═══════════════════════════════════════════════════════════════════════════

def _core():
    """Import the compiled pybind extension (reused from the aietriton package).

    The aietriton package (with its built ``_aietriton_core`` .so) lives at
    ``src/mlir/mlirfront/frontend/aietriton``; this frontend now lives at
    ``src/frontend/tvm``, so the extension is reached by absolute path rather
    than a sibling-relative import.
    """
    here = os.path.dirname(os.path.abspath(__file__))          # src/frontend/tvm
    src_root = os.path.dirname(os.path.dirname(here))          # src
    frontend_dir = os.path.join(src_root, "mlir", "mlirfront", "frontend")
    if frontend_dir not in sys.path:
        sys.path.insert(0, frontend_dir)
    try:
        from aietriton import _aietriton_core
        return _aietriton_core
    except Exception as e:  # pragma: no cover - depends on a built .so
        raise RuntimeError(
            "the _aietriton_core pybind extension is not built; build it first "
            "(cmake with LLVM_INSTALL_DIR + MLIR) so the TVM frontend can emit "
            f"AIE code. Underlying import error: {e}")


def compile_launch(op: LayerOp, idx: int, out_root: str,
                   mesh: Tuple[int, int] = (2, 2)) -> Tuple[str, bool]:
    """Emit code for a single launch into ``out_root/<idx>_<op>``.

    Conv2d-family ops go to the AIE backend (``run_aie_pipeline``, needs the
    built ``_aietriton_core``); non-conv ops emit bit-exact TVM CPU C via
    ``cpu_codegen.emit_cpu_launch``. Returns ``(out_dir, success)``.
    """
    func_name = f"{op.op}_{idx}"
    out_dir = os.path.join(out_root, f"{idx:02d}_{op.op}")
    os.makedirs(out_dir, exist_ok=True)

    if not cpu_codegen.is_aie_op(op.op):
        ok = cpu_codegen.emit_cpu_launch(op, out_dir, func_name)
        return out_dir, bool(ok)

    core = _core()
    tensor_specs = _tensor_specs(op)
    body = kernels.kernel_body_for(op.op, func_name)
    ok = core.run_aie_pipeline(mesh[0], mesh[1], tensor_specs, out_dir, body, func_name)
    return out_dir, bool(ok)


def compile_plan(plan: Optional[List[LayerOp]] = None,
                 out_root: str = "./worklocal/tvm",
                 mesh: Tuple[int, int] = (2, 2),
                 via_aiegraph: bool = True
                 ) -> List[Tuple[LayerOp, str, bool]]:
    """Emit AIE code for every launch in ``plan``; returns per-launch results.

    When ``via_aiegraph`` is True (default) the plan is first lifted into the
    ``aiegraph`` MLIR dialect (``build_aiegraph_module``), verified, and lowered
    back to per-launch descriptors (``lower_aiegraph``); the C++-derived
    ``tensor_specs`` are then paired with the Python kernel bodies and driven
    through ``run_aie_pipeline``. This routes the frontend through the formal
    dialect (verification + textual dump) while staying byte-identical to the
    direct ``compile_launch`` path. Set ``via_aiegraph=False`` to bypass the
    dialect and call ``compile_launch`` directly (the legacy path).
    """
    if plan is None:
        plan = model.layer_plan()
    if via_aiegraph:
        return compile_plan_via_aiegraph(plan, out_root, mesh)
    results: List[Tuple[LayerOp, str, bool]] = []
    for idx, op in enumerate(plan):
        out_dir, ok = compile_launch(op, idx, out_root, mesh)
        results.append((op, out_dir, ok))
    return results


def build_aiegraph_ir(plan: Optional[List[LayerOp]] = None,
                      func_name: str = "resnet") -> str:
    """Lift ``plan`` into the aiegraph dialect and return the verified textual IR.

    Constructs one ``aiegraph.func`` from the plan (dataflow inferred from the
    reused buffer names via ``model.plan_to_aiegraph_dicts``), verifies it in
    C++, and returns the printed module. Raises if the module fails verification
    or the extension is unbuilt.
    """
    if plan is None:
        plan = model.layer_plan()
    core = _core()
    op_dicts = model.plan_to_aiegraph_dicts(plan)
    return core.build_aiegraph_module(op_dicts, func_name)


def compile_plan_via_aiegraph(plan: Optional[List[LayerOp]] = None,
                              out_root: str = "./worklocal/tvm",
                              mesh: Tuple[int, int] = (2, 2)
                              ) -> List[Tuple[LayerOp, str, bool]]:
    """Route the plan through the aiegraph dialect, then emit per-launch code.

    Pipeline: ``build_aiegraph_module`` (build + verify) -> ``lower_aiegraph``
    (walk + geometry-derived ``tensor_specs``) -> pair each launch with its
    Python kernel body -> ``run_aie_pipeline`` into ``out_root/<idx>_<op>``.

    The launch order out of the dialect matches program order, so the returned
    list aligns 1:1 with ``plan``.
    """
    if plan is None:
        plan = model.layer_plan()
    core = _core()

    ir = build_aiegraph_ir(plan)
    launches = core.lower_aiegraph(ir)

    results: List[Tuple[LayerOp, str, bool]] = []
    for op, launch in zip(plan, launches):
        idx = int(launch["index"])
        func_name = launch["func_name"]
        out_dir = os.path.join(out_root, f"{idx:02d}_{op.op}")
        os.makedirs(out_dir, exist_ok=True)
        # Conv2d-family -> AIE backend; non-conv ops stay in the aiegraph IR
        # (already built + verified + lowered above) but their *runtime* code is
        # bit-exact TVM CPU C, not an AIE launch.
        if cpu_codegen.is_aie_op(op.op):
            specs = [(list(shape), int(bits), bool(is_in))
                     for (shape, bits, is_in) in launch["tensor_specs"]]
            body = kernels.kernel_body_for(op.op, func_name)
            ok = core.run_aie_pipeline(mesh[0], mesh[1], specs, out_dir, body,
                                       func_name)
        else:
            ok = cpu_codegen.emit_cpu_launch(op, out_dir, func_name)
        results.append((op, out_dir, bool(ok)))
    return results
