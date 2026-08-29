###############################################################################
# Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""A2 multi-layer host orchestrator for the TVM frontend (buffer graph stage).

This module is the A2 primary path described in
``src/frontend/tvm/design/orchestrator.md``: it turns the recovered ``LayerOp``
launch plan into the wiring a single ``main.elf`` needs (DDR buffer allocation,
program-order launches, CPU-op calls). This file implements only the first
piece — the **DDR buffer graph** (``_buffer_graph``); the driver/dispatcher/
``main.cc`` emit (design §5.2) is a later task.

Buffer-naming scheme
--------------------
The ``LayerOp`` plan (``model.layer_plan``) wires dataflow with **reused scratch
names** (``input``, ``feat1/2/3``, ``tmp1/2``, ``skip_ds``, ``logits``, plus the
non-buffer ``params``). Because names are reused, a name alone does not identify
a distinct DDR region, so this graph assigns each producer a **deterministic,
unique** buffer name and resolves consumers to the *most recent* producer of the
referenced scratch name (exactly the ``last_writer`` rule
``model.plan_to_aiegraph_dicts`` / ``_compiler.cpu_reference`` use):

* ``entry``       — the network input (layer-0's ``ins[0]``, the reused name
  ``"input"``); it is not produced by any launch.
* ``buf_<index>`` — the output of the launch at program-order ``index`` (every
  launch produces exactly one output).
* ``logits``      — alias for the final launch's output (the ``avgpool_fc``
  producer); ``logits_buffer`` points at this so the driver can read it back.

``params`` inputs are compile-time constant param buffers (filled by the
compiler from ``make_conv_params``/``make_fc_params``), *not* inter-launch DDR
chaining buffers, so they are excluded from ``in_bufs`` here.

Buffer sizes (element counts, int8) come from the real ``LayerOp`` dim fields:
conv output ``Cout*out_h*out_w`` (``out_h``/``out_w`` fold in the stride),
``residual_add_relu`` ``length``, ``avgpool_fc`` ``num_classes``; the ``entry``
buffer is sized from layer-0's conv input ``Cin*H*W``.
"""

from dataclasses import dataclass
from typing import Dict, List, Set

from .model import LayerOp

# Reused scratch names in ``ins`` that are NOT inter-launch DDR buffers.
_PARAM_NAME = "params"
_INPUT_NAME = "input"

ENTRY_BUFFER = "entry"
LOGITS_BUFFER = "logits"


@dataclass
class LayerBuf:
    """One launch's resolved DDR buffer wiring (unique producer/consumer names)."""
    index: int
    op: str
    func_name: str
    in_bufs: List[str]
    out_buf: str


@dataclass
class BufferGraph:
    """The plan's DDR buffer graph: producers, consumers, and sizes."""
    entry_buffer: str
    logits_buffer: str
    layers: List[LayerBuf]
    sizes: Dict[str, int]

    def produced_before(self, idx: int) -> Set[str]:
        """Names of buffers produced by launches with program-order index < ``idx``."""
        return {layer.out_buf for layer in self.layers if layer.index < idx}


def _out_elems(op: LayerOp) -> int:
    """Output element count (int8) for ``op`` from its real dim fields (> 0)."""
    if op.op in ("conv_bn_relu", "conv_bn"):
        return op.Cout * op.out_h * op.out_w
    if op.op == "residual_add_relu":
        return op.length
    if op.op == "avgpool_fc":
        return op.num_classes
    raise ValueError(f"unknown op {op.op!r}")


def _entry_elems(op0: LayerOp) -> int:
    """Element count of the network input, from layer-0's conv input dims."""
    if op0.op in ("conv_bn_relu", "conv_bn"):
        return op0.Cin * op0.H * op0.W
    raise ValueError(f"expected a conv as layer 0, got {op0.op!r}")


def _buf_name(idx: int) -> str:
    """Deterministic unique output-buffer name for the launch at ``idx``."""
    return f"buf_{idx}"


def _buffer_graph(plan: List[LayerOp]) -> BufferGraph:
    """Build the DDR buffer graph for ``plan`` (see module docstring).

    Walks the plan in program order, assigning each launch a unique ``out_buf``
    and resolving its ``in_bufs`` to the most-recent producer of each referenced
    scratch name (``entry`` for the network input; ``params`` inputs dropped).
    The final launch's output is also exposed as ``logits``.
    """
    if not plan:
        raise ValueError("empty plan: no buffers to wire")

    last_index = len(plan) - 1
    sizes: Dict[str, int] = {ENTRY_BUFFER: _entry_elems(plan[0])}
    last_writer: Dict[str, int] = {}  # scratch name -> producing launch index
    layers: List[LayerBuf] = []

    for idx, op in enumerate(plan):
        in_bufs: List[str] = []
        for name in op.ins:
            if name == _PARAM_NAME:
                continue                      # compile-time const, not a DDR edge
            if name == _INPUT_NAME:
                in_bufs.append(ENTRY_BUFFER)  # network input
                continue
            producer = last_writer.get(name)
            if producer is None:
                raise ValueError(
                    f"launch {idx} ({op.op}) reads buffer {name!r} before any "
                    "launch produced it")
            in_bufs.append(_buf_name(producer))

        out_buf = LOGITS_BUFFER if idx == last_index else _buf_name(idx)
        sizes[out_buf] = _out_elems(op)
        layers.append(LayerBuf(index=idx, op=op.op,
                               func_name=f"{op.op}_{idx}",
                               in_bufs=in_bufs, out_buf=out_buf))
        last_writer[op.out] = idx

    return BufferGraph(entry_buffer=ENTRY_BUFFER, logits_buffer=LOGITS_BUFFER,
                       layers=layers, sizes=sizes)
