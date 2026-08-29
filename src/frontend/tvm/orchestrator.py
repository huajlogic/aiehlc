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

import os
from dataclasses import dataclass
from typing import Dict, List, Set

from . import cpu_codegen, kernels
from .model import LayerOp

# C source header prepended to every emitted artifact.
_COPYRIGHT = (
    "/******************************************************************************\n"
    " * Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.\n"
    " * SPDX-License-Identifier: Apache-2.0\n"
    " ******************************************************************************/\n")

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


# ═══════════════════════════════════════════════════════════════════════════
#  A2 driver emit — one host.cc (N appended funcs + __aie_launch dispatcher),
#  per-conv kernel_<name>.cc, per-CPU-op <name>.c, and a program-order main.cc.
# ═══════════════════════════════════════════════════════════════════════════
#
# Authoritative func name
# -----------------------
# ``launch["func_name"]`` (from ``lower_aiegraph``) is the single source of
# truth for a conv layer's name: it is what actually names the emitted
# ``host_canonicalized_<name>`` host func and the ``kernel_<name>.cc`` file when
# ``orchestrate_conv_layer(..., host_func_suffix=name)`` runs. So the dispatcher
# ``strcmp`` key, the ``_binary_kernel_<name>_start`` symbol, the
# ``host_canonicalized_<name>`` call, and the ``__aie_launch("<name>", ...)``
# call in main all use ``launch["func_name"]`` — NOT ``LayerBuf.func_name``
# (which is ``"{op}_{idx}"`` and used only for buffer identity/sizes). Launches
# and ``graph.layers`` are both in program order, one per plan op, so we zip
# them by index.


def _param_elems(op: LayerOp) -> int:
    """Element count of a CPU op's headerless param buffer (0 if it has none)."""
    if op.op == "avgpool_fc":            # weights|bias, no config header
        return op.channels * op.num_classes + op.num_classes
    return 0                              # residual_add_relu takes no params


def _emit_dispatcher(convs: List[dict], ddr_args: Dict[str, int]) -> str:
    """Return the ``__aie_launch`` dispatcher C text to append to ``host.cc``.

    Mirrors ``aiehlc.cc`` (multi-kernel aieMesh overload, :4711-4734): a
    ``strcmp`` chain keyed on ``launch["func_name"]`` selecting
    ``__Runtime_set_kernel_elf(_binary_kernel_<name>_start)`` +
    ``__Runtime_sync_for_dev`` per DDR arg + ``host_canonicalized_<name>(dev,
    ...)``. ``convs`` is the list of conv launch dicts (program order);
    ``ddr_args`` maps each func_name to its ``numHostDdrArgs``.
    """
    max_args = max((ddr_args[c["func_name"]] for c in convs), default=0)
    out = ["\n// ===== A2 multi-kernel __aie_launch dispatcher ====="]
    for c in convs:                       # extern binary symbols (declared first)
        name = c["func_name"]
        out.append(f"extern unsigned char _binary_kernel_{name}_start[];")
    for c in convs:
        out.append(f"void host_canonicalized_{c['func_name']}(XAie_DevInst* dev"
                   + ", void*" * ddr_args[c["func_name"]] + ");")
    sig = "inline void __aie_launch(const char* kernel, aieMesh mesh"
    for i in range(max_args):
        sig += f", void* _t{i}, size_t _s{i}"
    out.append(sig + ", ...) {")
    out.append("    XAie_DevInst* dev = __Runtime_get_partition_dev(mesh.meshId);")
    for ki, c in enumerate(convs):
        name = c["func_name"]
        n = ddr_args[name]
        cond = "if" if ki == 0 else "} else if"
        out.append(f"    {cond} (strcmp(kernel, \"{name}\") == 0) {{")
        out.append(f"        __Runtime_set_kernel_elf(_binary_kernel_{name}_start);")
        for i in range(n):
            out.append(f"        __Runtime_sync_for_dev(dev, _t{i}, _s{i});")
        call = f"        host_canonicalized_{name}(dev"
        for i in range(n):
            call += f", _t{i}"
        out.append(call + ");")
    out.append("    }")
    out.append("}")
    return "\n".join(out) + "\n"


def _emit_allocs(graph: BufferGraph, param_bufs: Dict[str, int]) -> List[str]:
    """Return the ``__Runtime_Alloc`` lines for every distinct DDR buffer once.

    Inter-launch buffers come from ``graph.sizes`` (entry, buf_<i>, logits);
    ``param_bufs`` adds a CPU op's ``params_<idx>`` buffer (int8, one per op).
    """
    lines: List[str] = []
    for name, sz in graph.sizes.items():
        lines.append(f"    int8_t* {name} = (int8_t*)__Runtime_Alloc(dev, {sz});")
    for name, sz in param_bufs.items():
        lines.append(f"    int8_t* {name} = (int8_t*)__Runtime_Alloc(dev, {sz});")
    return lines


def _emit_body(graph: BufferGraph, launches: List[dict],
               plan: List[LayerOp]) -> List[str]:
    """Return the program-order launch/call lines for ``main``.

    Conv layers dispatch through ``__aie_launch("<func_name>", mesh, in, sin,
    out, sout)``; CPU ops call their plain-C entry directly with the wired
    buffers (residual: ``a, b, out, n``; avgpool_fc: ``feat, wts, bias, out``).

    The ``avgpool_fc`` ``.c`` (``_plain_c_avgpool_fc``) has a 4-pointer ABI:
    ``(const int8_t* feat, const int8_t* wts, const int8_t* bias, int8_t* out)``.
    The single ``params_<idx>`` buffer holds ``weights|bias`` concatenated
    (``params[:C*NC]=weights``, ``params[C*NC:]=bias``), so we pass the buffer
    base as ``wts`` and ``params_<idx> + C*NC`` as ``bias`` (``C*NC`` =
    ``channels*num_classes``, emitted as a compile-time literal).
    """
    lines: List[str] = []
    for layer, launch, op in zip(graph.layers, launches, plan):
        name = launch["func_name"]
        out_buf, out_sz = layer.out_buf, graph.sizes[layer.out_buf]
        if cpu_codegen.is_aie_op(op.op):
            args = f'__aie_launch("{name}", mesh'
            for b in layer.in_bufs:
                args += f", {b}, {graph.sizes[b]}"
            args += f", {out_buf}, {out_sz}"
            lines.append(f"    {args});")
        elif op.op == "residual_add_relu":
            a, b = layer.in_bufs[0], layer.in_bufs[1]
            lines.append(f"    {name}({a}, {b}, {out_buf}, {op.length});")
        elif op.op == "avgpool_fc":
            feat = layer.in_bufs[0]
            params = f"params_{layer.index}"  # weights|bias buffer (see _emit_allocs)
            wts_len = op.channels * op.num_classes  # params[:C*NC]=wts, params[C*NC:]=bias
            lines.append(
                f"    {name}({feat}, {params}, {params} + {wts_len}, {out_buf});")
        else:
            raise ValueError(f"unknown op {op.op!r} in main body")
    return lines


def _emit_main(graph: BufferGraph, launches: List[dict],
               plan: List[LayerOp], param_bufs: Dict[str, int]) -> str:
    """Return the ``main.cc`` text: allocs, entry fill, program order, readback.

    Mirrors the emitted-host ``main`` shape (device init → mesh partition →
    ``__Runtime_Alloc`` → launches → read back logits → teardown).
    """
    convs = [L for op, L in zip(plan, launches) if cpu_codegen.is_aie_op(op.op)]
    cpu_protos = []
    for op, L in zip(plan, launches):
        if op.op == "residual_add_relu":
            cpu_protos.append(f"void {L['func_name']}(const int8_t*, const int8_t*,"
                              " int8_t*, int);")
        elif op.op == "avgpool_fc":
            cpu_protos.append(f"void {L['func_name']}(const int8_t*, const int8_t*,"
                              " const int8_t*, int8_t*);")
    entry_sz = graph.sizes[graph.entry_buffer]
    logits_sz = graph.sizes[graph.logits_buffer]
    txt = [_COPYRIGHT,
           '#include "aie_runtime.h"',
           "#include <cstdint>",
           "#include <cstdio>",
           "#include <cstring>",
           "",
           "// CPU-op plain-C entries (linked from <func>.c).",
           'extern "C" {'] + cpu_protos + ["}", ""]
    txt.append("int main(int argc, char** argv) {")
    txt.append("    XAie_DevInst* dev = __Runtime_device_init();")
    txt.append("    aieArray arr; arr._dev = dev;")
    txt.append("    aieMesh mesh = arr.partition(2, 2);")
    txt += _emit_allocs(graph, param_bufs)
    txt.append(f"    // Fill layer-0 entry ({entry_sz} int8) from the input image.")
    txt.append(f"    for (int i = 0; i < {entry_sz}; ++i) {graph.entry_buffer}[i] = 0;")
    txt += _emit_body(graph, launches, plan)
    txt.append(f"    __Runtime_sync_for_cpu(dev, {graph.logits_buffer}, {logits_sz});")
    txt.append(f"    for (int j = 0; j < {logits_sz}; ++j)")
    txt.append(f'        printf("logit[%d] = %d\\n", j, (int){graph.logits_buffer}[j]);')
    txt.append("    __Runtime_device_teardown(dev);")
    txt.append("    return 0;")
    txt.append("}")
    return "\n".join(txt) + "\n"


def orchestrate_plan(plan: List[LayerOp], launches: List[dict],
                     out_dir: str) -> str:
    """A2 driver: emit ONE host.cc (+dispatcher), per-op glue, and main.cc.

    For each conv launch (first ``append_mode=False``, rest ``True``) calls
    ``core.orchestrate_conv_layer`` — producing one ``host.cc`` with N appended
    ``host_canonicalized_<name>`` funcs and per-conv ``kernel_<name>.cc``.
    CPU ops are emitted as plain-C ``<name>.c``. Then appends the ``__aie_launch``
    dispatcher to ``host.cc`` and writes ``main.cc`` in program order. Returns
    the build directory path. ``launches`` must align 1:1 with ``plan``.
    """
    from . import _compiler  # lazy: keeps module import cheap when pybind absent
    core = _compiler._core()

    build_dir = os.path.join(out_dir, "build")
    os.makedirs(build_dir, exist_ok=True)
    graph = _buffer_graph(plan)

    # 1) Conv launches → ONE host.cc (append after the first) + kernel_<name>.cc.
    ddr_args: Dict[str, int] = {}
    convs: List[dict] = []
    conv_i = 0
    for op, launch in zip(plan, launches):
        if not cpu_codegen.is_aie_op(op.op):
            continue
        specs = [(list(s), int(b), bool(x)) for (s, b, x) in launch["tensor_specs"]]
        body = kernels.kernel_body_for(op.op, launch["func_name"])
        n = core.orchestrate_conv_layer(2, 2, specs, build_dir, body,
                                        launch["func_name"],
                                        host_func_suffix=launch["func_name"],
                                        append_mode=(conv_i > 0))
        ddr_args[launch["func_name"]] = int(n)
        convs.append(launch)
        conv_i += 1

    # 2) CPU ops → plain-C <name>.c, and collect their param buffers.
    param_bufs: Dict[str, int] = {}
    for op, launch in zip(plan, launches):
        if cpu_codegen.is_aie_op(op.op):
            continue
        cpu_codegen.emit_cpu_launch_plain(op, build_dir, launch["func_name"])
        pelems = _param_elems(op)
        if pelems:
            idx = launches.index(launch)
            param_bufs[f"params_{idx}"] = pelems

    # 3) Append the __aie_launch dispatcher to host.cc.
    host_path = os.path.join(build_dir, "host.cc")
    with open(host_path, "a") as f:
        f.write(_emit_dispatcher(convs, ddr_args))

    # 4) Emit main.cc (program order: allocs → entry fill → launches → readback).
    with open(os.path.join(build_dir, "main.cc"), "w") as f:
        f.write(_emit_main(graph, launches, plan, param_bufs))

    return build_dir
