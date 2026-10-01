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
import subprocess
from dataclasses import dataclass
from typing import Dict, List, Set

from . import cpu_codegen, kernels, model
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


def _to_aie(op: LayerOp, enable_aiehlc_offload: bool) -> bool:
    """True iff ``op`` is actually compiled to the AIE backend for this build.

    The AIE/CPU split is the conjunction of two facts: the op *kind* must be an
    AIE op (``cpu_codegen.is_aie_op`` — the conv2d family) **and** the build must
    have AIE offload enabled. With ``enable_aiehlc_offload=False`` every conv is
    force-offloaded to the CPU backend (bit-exact plain-C, see
    ``cpu_codegen.plain_c_source(force=True)``), so no ``kernel_<name>.cc`` is
    emitted and ``hostcompile.sh`` never invokes xchesscc. This is the single
    predicate every backend-selecting call site must use — ``is_aie_op`` alone
    only answers "could this run on AIE", not "does it, here".
    """
    return cpu_codegen.is_aie_op(op.op) and enable_aiehlc_offload


def _param_elems(op: LayerOp) -> int:
    """Element count of a CPU op's headerless param buffer (0 if it has none)."""
    if op.op == "avgpool_fc":            # weights|bias, no config header
        return op.channels * op.num_classes + op.num_classes
    return 0                              # residual_add_relu takes no params


def _wts_name(idx: int) -> str:
    """Deterministic unique weights-buffer name for the conv launch at ``idx``."""
    return f"wts_{idx}"


def _wts_elems(launch: dict) -> int:
    """Conv weights DDR element count, from the launch's 2nd tensor spec.

    A conv launch's ``tensor_specs`` are ``[input, weights, output]``
    (``is_input == [True, True, False]``); index 1 is the weights tensor. Its
    ``host_canonicalized_<name>`` therefore takes 3 DDR pointers (input, weights,
    output), so ``main`` must allocate + pass a weights buffer — the plan's
    ``params`` input maps to this DDR region (dropped from the activation
    ``_buffer_graph`` because it is not an inter-launch edge).
    """
    shape, _bw, _is_in = launch["tensor_specs"][1]
    n = 1
    for dim in shape:
        n *= int(dim)
    return n


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


def _emit_cpu_only_host() -> str:
    """Return a standalone ``host.cc`` for an all-CPU (offload-disabled) build.

    On the AIE path ``host.cc`` is *created* by the first
    ``core.orchestrate_conv_layer`` call and this module only appends to it.
    With offload off there is no such call, yet hostcompile.sh still requires a
    ``host.cc`` (it is the only translation unit it compiles, and
    ``_fold_main_into_host`` splices main + the CPU bodies into it). So emit the
    minimal stub: the runtime include the fold path anchors its mesh preamble
    to, and nothing else — no ``__aie_launch`` dispatcher, because no launch
    site references one.
    """
    return (_COPYRIGHT
            + '#include "aie_runtime.h"\n'
            + "#include <cstdint>\n"
            + "#include <cstdio>\n"
            + "#include <cstring>\n"
            + "\n// All ops force-offloaded to the CPU backend: no AIE kernel and\n"
            + "// no launch dispatcher. main + the plain-C op bodies are folded\n"
            + "// in below by _fold_main_into_host.\n")


def _emit_cpu_only_routing() -> str:
    """Return a no-op ``routing.cc`` for an all-CPU (offload-disabled) build.

    ``aie_runtime.c`` declares ``extern void routing(XAie_DevInst*)`` and calls
    it from ``__Runtime_routing_init``, so the symbol must resolve at link time
    even though nothing in an all-CPU build calls that path — the reference
    lives in ``aie_runtime.o``, which hostcompile.sh always links. On the AIE
    path the definition comes from the per-conv ``routing.cc`` the pipeline
    emits; with no conv there is none, hence this stub. It is never executed
    (the all-CPU ``main`` does no device init), so an empty body is correct
    rather than merely convenient.
    """
    return (_COPYRIGHT
            + '#include "aie_runtime.h"\n\n'
            + "// All ops run on the CPU: no stream-switch routing to program.\n"
            + "// Defined only to resolve aie_runtime.o's unconditional extern.\n"
            + "void routing(XAie_DevInst* dev) { (void)dev; }\n")


def _emit_allocs(graph: BufferGraph, param_bufs: Dict[str, int],
                 wts_bufs: Dict[str, int]) -> List[str]:
    """Return the ``__Runtime_Alloc`` lines for every distinct DDR buffer once.

    Inter-launch buffers come from ``graph.sizes`` (entry, buf_<i>, logits);
    ``param_bufs`` adds a CPU op's ``params_<idx>`` buffer and ``wts_bufs`` adds a
    conv layer's ``wts_<idx>`` weights buffer (int8, one per op). ``__Runtime_Alloc``
    is the 1-arg ``void *__Runtime_Alloc(size_t)`` from ``aie_runtime.h`` (it does
    NOT take a device handle).
    """
    lines: List[str] = []
    for src in (graph.sizes, wts_bufs, param_bufs):
        for name, sz in src.items():
            lines.append(f"    int8_t* {name} = (int8_t*)__Runtime_Alloc({sz});")
    return lines


def _emit_param_fillers() -> List[str]:
    """Return the C helpers that fill conv/fc param buffers at runtime.

    The scaled model has no pretrained weights: ``model.make_conv_params`` /
    ``make_fc_params`` build deterministic Q7 patterns, and both the numpy
    oracle and the AIE/CPU kernels read that exact layout. Emitting those
    patterns as C loops (rather than a ~44 KB static table, or the zeros a
    ``memset`` would leave) is what makes the linked ELF compute the same
    logits as ``_compiler.cpu_reference``.

    Zeros are not a harmless placeholder on the CPU path: the conv config
    (``H,W,Cin,Cout,K,stride``) is read from the *first 6 bytes of the params
    buffer*, so an all-zero buffer means ``H=W=0`` and the conv writes nothing.
    """
    return [
        "// Deterministic Q7 params (mirrors model.make_conv_params /"
        " make_fc_params).",
        "static void fill_conv_params(int8_t* p, int H, int W, int Cin,",
        "                             int Cout, int K, int stride) {",
        f"    const int cfg = {model.CONFIG_SZ};",
        "    int wt_count = Cin * Cout * K * K;",
        "    // uint16 LE config fields (model.pack_config / kernel CFG16).",
        "    const int _f[6] = {H, W, Cin, Cout, K, stride};",
        "    for (int i = 0; i < 6; ++i) {",
        "        p[i * 2]     = (int8_t)(_f[i] & 0xFF);",
        "        p[i * 2 + 1] = (int8_t)((_f[i] >> 8) & 0xFF);",
        "    }",
        "    for (int i = 0; i < wt_count; ++i)",
        "        p[cfg + i] = (int8_t)((i % 2 == 0) ? 1 : -1);",
        "    for (int c = 0; c < Cout; ++c) {",
        f"        p[cfg + wt_count + c] = (int8_t){model.BN_SCALE_DEFAULT};",
        "        p[cfg + wt_count + Cout + c] = "
        f"(int8_t){model.BN_BIAS_DEFAULT};",
        "    }",
        "}",
        "",
        "// Headerless weights|bias for the CPU avgpool_fc ABI"
        " (model.fc_params_no_header).",
        "static void fill_fc_params(int8_t* p, int channels, int num_classes) {",
        "    for (int i = 0; i < channels * num_classes; ++i) p[i] = 1;",
        "    for (int j = 0; j < num_classes; ++j)",
        "        p[channels * num_classes + j] = 0;",
        "}",
        "",
    ]


def _emit_param_init(graph: BufferGraph, launches: List[dict],
                     plan: List[LayerOp],
                     param_bufs: Dict[str, int]) -> List[str]:
    """Return the per-buffer ``fill_*_params`` calls for ``main``.

    Deliberately takes no ``enable_aiehlc_offload``: param filling is
    backend-agnostic. Conv buffers (``wts_<idx>``) are filled identically for
    BOTH backends — the AIE kernel and the forced-CPU plain-C read the same
    header+weights+BN layout — which is what keeps the two paths bit-exact with
    each other and with the numpy oracle.
    """
    lines: List[str] = []
    for idx, (op, _L) in enumerate(zip(plan, launches)):
        if not cpu_codegen.is_aie_op(op.op):
            continue
        lines.append(
            f"    fill_conv_params({_wts_name(idx)}, {op.H}, {op.W}, "
            f"{op.Cin}, {op.Cout}, {op.K}, {op.stride});")
    for idx, op in enumerate(plan):
        name = f"params_{idx}"
        if name not in param_bufs:
            continue
        if op.op == "avgpool_fc":
            lines.append(f"    fill_fc_params({name}, {op.channels}, "
                         f"{op.num_classes});")
        else:
            lines.append(f"    memset({name}, 0, {param_bufs[name]});")
    return lines


def _emit_body(graph: BufferGraph, launches: List[dict],
               plan: List[LayerOp], enable_aiehlc_offload: bool = True) -> List[str]:
    """Return the program-order launch/call lines for ``main``.

    Conv layers dispatch through ``__aie_launch("<func_name>", mesh, in, sin,
    wts, swts, out, sout)`` — three DDR tensors (input, weights, output) matching
    ``host_canonicalized_<name>``'s param order (``tensor_specs`` is ``[input,
    weights, output]``). The ``wts_<idx>`` buffer is allocated in ``_emit_main``;
    CPU ops call their plain-C entry directly with the wired buffers (residual:
    ``a, b, out, n``; avgpool_fc: ``feat, wts, bias, out``).

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
        if not _to_aie(op, enable_aiehlc_offload) and cpu_codegen.is_aie_op(op.op):
            # Force-offloaded conv: plain-C ABI (feat, params, out) — no mesh,
            # no DDR sync, the config header travels inside the params buffer.
            feat = layer.in_bufs[0]
            lines.append(f"    {name}({feat}, {_wts_name(layer.index)}, "
                         f"{out_buf});")
        elif _to_aie(op, enable_aiehlc_offload):
            wts, wts_sz = _wts_name(layer.index), _wts_elems(launch)
            args = f'__aie_launch("{name}", mesh'
            for b in layer.in_bufs:       # conv activation input(s)
                args += f", {b}, {graph.sizes[b]}"
            args += f", {wts}, {wts_sz}"  # weights DDR buffer (see _wts_elems)
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
               plan: List[LayerOp], param_bufs: Dict[str, int],
               enable_aiehlc_offload: bool = True,
               image_header: str = None) -> str:
    """Return the ``main.cc`` text: allocs, entry fill, program order, readback.

    Mirrors the emitted-host ``main`` shape (device init → mesh partition →
    ``__Runtime_Alloc`` → launches → read back logits → teardown).

    When no op actually reaches AIE (``enable_aiehlc_offload=False``, so every
    conv is force-offloaded to plain-C) the device init AND the mesh partition
    are skipped entirely, and each conv calls its plain-C entry directly rather
    than going through ``__aie_launch``. That is deliberate: an all-CPU build
    must compute its logits without requiring working AIE hardware, so it must
    not call ``__Runtime_explicit_init``.
    """
    cpu_protos = []
    for op, L in zip(plan, launches):
        if op.op == "residual_add_relu":
            cpu_protos.append(f"void {L['func_name']}(const int8_t*, const int8_t*,"
                              " int8_t*, int);")
        elif op.op == "avgpool_fc":
            cpu_protos.append(f"void {L['func_name']}(const int8_t*, const int8_t*,"
                              " const int8_t*, int8_t*);")
        elif not _to_aie(op, enable_aiehlc_offload):   # force-offloaded conv
            cpu_protos.append(f"void {L['func_name']}(const int8_t*, const int8_t*,"
                              " int8_t*);")
    # Per-conv weights DDR buffers (wts_<idx>), sized from tensor_specs[1]. These
    # are allocated for BOTH backends — the forced-CPU conv reads the same
    # header+weights+BN params buffer the AIE kernel would.
    wts_bufs: Dict[str, int] = {}
    for idx, (op, L) in enumerate(zip(plan, launches)):
        if cpu_codegen.is_aie_op(op.op):
            wts_bufs[_wts_name(idx)] = _wts_elems(L)
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
    if image_header:
        txt.insert(5, f'#include "{image_header}.h"')
    txt += _emit_param_fillers()
    txt.append("int main(int argc, char** argv) {")
    if any(_to_aie(op, enable_aiehlc_offload) for op in plan):
        txt.append("    XAie_DevInst* dev = __Runtime_explicit_init();")
        txt.append("    aieArray arr; arr._dev = dev;")
        txt.append("    aieMesh mesh = arr.partition(2, 2);")
        txt.append("    (void)mesh;")
    else:
        # All-CPU build: no launch touches the array, so skip device init and
        # the mesh partition entirely — the ELF must not require working AIE
        # hardware to compute its logits.
        txt.append("    // All ops run on the CPU: no device init, no mesh.")
    txt += _emit_allocs(graph, param_bufs, wts_bufs)
    if image_header:
        # The ELF carries raw pixels and quantizes them itself (see
        # emit_image_header): the on-target quantizer is part of what runs.
        txt.append(f"    // Quantize the embedded image into the entry buffer.")
        txt.append(f"    {image_header}_quantize({graph.entry_buffer});")
    else:
        txt.append(f"    // Fill layer-0 entry ({entry_sz} int8) with model.make_input()'s")
        txt.append("    // pattern (i%7)+1 so the ELF matches the numpy oracle.")
        txt.append(f"    for (int i = 0; i < {entry_sz}; ++i)")
        txt.append(f"        {graph.entry_buffer}[i] = (int8_t)((i % 7) + 1);")
    txt += _emit_param_init(graph, launches, plan, param_bufs)
    txt += _emit_body(graph, launches, plan, enable_aiehlc_offload)
    if any(_to_aie(op, enable_aiehlc_offload) for op in plan):
        txt.append(f"    __Runtime_sync_for_cpu(dev, {graph.logits_buffer}, "
                   f"{logits_sz});")
    txt.append(f"    for (int j = 0; j < {logits_sz}; ++j)")
    txt.append(f'        printf("logit[%d] = %d\\n", j, (int){graph.logits_buffer}[j]);')
    if image_header:
        # Argmax over the logits = the predicted class. Printed alongside the
        # raw logits so a degenerate all-equal result stays visible rather than
        # being hidden behind a confident-looking "class 0".
        txt.append(f"    int best = 0, ties = 0;")
        txt.append(f"    for (int j = 1; j < {logits_sz}; ++j)")
        txt.append(f"        if ({graph.logits_buffer}[j] > {graph.logits_buffer}[best]) best = j;")
        txt.append(f"    for (int j = 0; j < {logits_sz}; ++j)")
        txt.append(f"        if ({graph.logits_buffer}[j] == {graph.logits_buffer}[best]) ++ties;")
        txt.append('    printf("predicted class = %d\\n", best);')
        txt.append('    if (ties > 1)')
        txt.append('        printf("WARNING: %d/%d classes tie at logit %d -- "')
        txt.append('               "the scaled demo model uses placeholder weights, "')
        txt.append('               "so this prediction is structural, not learned\\n",')
        txt.append(f'               ties, {logits_sz}, (int){graph.logits_buffer}[best]);')
    if any(_to_aie(op, enable_aiehlc_offload) for op in plan):
        txt.append("    __Runtime_device_teardown(dev);")
    txt.append("    return 0;")
    txt.append("}")
    return "\n".join(txt) + "\n"


def orchestrate_plan(plan: List[LayerOp], launches: List[dict],
                     out_dir: str,
                     enable_aiehlc_offload: bool = True,
                     image_pixels=None,
                     image_name: str = "demo_image") -> str:
    """A2 driver: emit ONE host.cc (+dispatcher), per-op glue, and main.cc.

    For each conv launch (first ``append_mode=False``, rest ``True``) calls
    ``core.orchestrate_conv_layer`` — producing one ``host.cc`` with N appended
    ``host_canonicalized_<name>`` funcs and per-conv ``kernel_<name>.cc``.
    CPU ops are emitted as plain-C ``<name>.c``. Then appends the ``__aie_launch``
    dispatcher to ``host.cc`` and writes ``main.cc`` in program order. Returns
    the build directory path. ``launches`` must align 1:1 with ``plan``.

    ``enable_aiehlc_offload=False`` force-offloads the conv2d family to the CPU
    backend: no ``orchestrate_conv_layer`` call, so no ``kernel_<name>.cc`` and
    no xchesscc compile — every op becomes a plain-C ``<name>.c``. Because
    ``host.cc`` is normally *produced* by the first ``orchestrate_conv_layer``,
    the all-CPU build writes a minimal standalone ``host.cc`` itself
    (``_emit_cpu_only_host``) to keep hostcompile.sh's "host.cc is the only
    translation unit" contract satisfied.
    """
    from . import _compiler  # lazy: keeps module import cheap when pybind absent

    build_dir = os.path.join(out_dir, "build")
    os.makedirs(build_dir, exist_ok=True)
    graph = _buffer_graph(plan)

    # 1) Conv launches → ONE host.cc (append after the first) + kernel_<name>.cc.
    #    Skipped entirely when offload is off (no pybind core needed either).
    ddr_args: Dict[str, int] = {}
    convs: List[dict] = []
    if enable_aiehlc_offload:
        core = _compiler._core()
        conv_i = 0
        for op, launch in zip(plan, launches):
            if not _to_aie(op, enable_aiehlc_offload):
                continue
            specs = [(list(s), int(b), bool(x))
                     for (s, b, x) in launch["tensor_specs"]]
            body = kernels.kernel_body_for(op.op, launch["func_name"])
            n = core.orchestrate_conv_layer(2, 2, specs, build_dir, body,
                                            launch["func_name"],
                                            host_func_suffix=launch["func_name"],
                                            append_mode=(conv_i > 0))
            ddr_args[launch["func_name"]] = int(n)
            convs.append(launch)
            conv_i += 1

    # 2) Every non-offloaded op → plain-C <name>.c (force=True for a conv), and
    #    collect the CPU-only param buffers (conv params live in wts_<idx>).
    param_bufs: Dict[str, int] = {}
    for idx, (op, launch) in enumerate(zip(plan, launches)):
        if _to_aie(op, enable_aiehlc_offload):
            continue
        cpu_codegen.emit_cpu_launch_plain(op, build_dir, launch["func_name"],
                                          force=cpu_codegen.is_aie_op(op.op))
        pelems = _param_elems(op)
        if pelems:
            param_bufs[f"params_{idx}"] = pelems

    # 3) host.cc: append the __aie_launch dispatcher (AIE path), or synthesize a
    #    standalone one (all-CPU path, where no conv ever created host.cc).
    host_path = os.path.join(build_dir, "host.cc")
    if convs:
        with open(host_path, "a") as f:
            f.write(_emit_dispatcher(convs, ddr_args))
    else:
        with open(host_path, "w") as f:
            f.write(_emit_cpu_only_host())
        # hostcompile.sh picks routing.cc up automatically when present; it
        # resolves aie_runtime.o's unconditional extern (see the emitter).
        with open(os.path.join(build_dir, "routing.cc"), "w") as f:
            f.write(_emit_cpu_only_routing())

    # 3b) Embed the input image as raw pixels + an on-target quantizer.
    if image_pixels is not None:
        emit_image_header(image_pixels,
                          os.path.join(build_dir, f"{image_name}.h"),
                          name=image_name,
                          src_note="input image for the scaled demo model")

    # 4) Emit main.cc (program order: allocs → entry fill → launches → readback).
    with open(os.path.join(build_dir, "main.cc"), "w") as f:
        f.write(_emit_main(graph, launches, plan, param_bufs,
                           enable_aiehlc_offload,
                           image_name if image_pixels is not None else None))

    return build_dir


# ═══════════════════════════════════════════════════════════════════════════
#  A2 build — arrange the build dir to satisfy hostcompile.sh's multi-kernel
#  contract, then reuse script/hostcompile.sh to produce main.elf.
# ═══════════════════════════════════════════════════════════════════════════
#
# hostcompile.sh (multi-kernel) contract — the pieces build_main_elf honours:
#   * WORKLOCAL_DIR holds the sources; artifacts land in ``WORKLOCAL_DIR/build``.
#   * It globs ``kernel_*.cc`` in WORKLOCAL_DIR and compiles each via kc.sh,
#     renaming ``kernel.o`` -> ``kernel_<name>.o`` (per-kernel ``aieml_<name>.prx``
#     is picked up automatically when present).
#   * The host link (hostcompile.sh:469) compiles ONLY ``host.cc`` (+ the four
#     runtime .c files + optional routing.o + the kernel objs). It does NOT pick
#     up ``main.cc`` or the CPU ``<op>.c`` files, so build_main_elf folds the
#     ``int main()`` body, the CPU-op plain-C entries, and the aieMesh/aieArray
#     preamble (aiehlc.cc:4633-4663, needed by ``main``) INTO ``host.cc``.
#   * host fixup (hostcompile.sh:369): if ``host.cc`` contains the literal
#     ``int main()`` only ``#define __global__`` is added, so the folded main is
#     emitted with the no-arg ``int main()`` signature to take that clean path.
#   * The ELF lands at ``WORKLOCAL_DIR/build/host`` and is copied to
#     ``<dirname(WORKLOCAL_DIR)>/main.elf`` -- **stripped** (--strip-debug),
#     with the unstripped original kept beside it as ``main.debug.elf``. Around
#     70% of the link is DWARF from the prebuilt BSP/libgloss/aie-rt libs
#     (nothing we compile carries -g; OPT_FLAGS is -Os), so a 2.8 MB A2 build
#     publishes at ~880 KB with a byte-identical LOAD segment. Stripping is the
#     default and is **not** driven by the ambient ``DEBUG_SYMS`` env var (which
#     script/aiehlc.sh exports for its own debug builds, and which would
#     otherwise silently triple this ELF) -- ask via
#     ``build_main_elf(debug_syms=True)``. ``build_main_elf`` returns the
#     published path, not the unstripped ``build/host`` intermediate.

# aieMesh/aieArray/aiePartition preamble — verbatim transcription of the subset
# aiehlc.cc (4633-4663) injects that ``_emit_main`` relies on (aieArray::
# partition(rows, cols), aieMesh.meshId). These types are NOT in aie_runtime.h,
# so they must be defined in host.cc for the folded ``main`` to compile.
_AIE_MESH_PREAMBLE = """
// ===== aieMesh/aieArray host-partition preamble (mirrors aiehlc.cc) =====
struct aiePartition {
    int startCol, endCol, startRow, endRow;
};
struct aieMesh {
    int rows, cols;
    aiePartition partition;
    int meshId;
};
struct aieArray {
    int nextMeshId = 0;
    XAie_DevInst* _dev = nullptr;
    aieMesh partition(aiePartition p, int rows, int cols) {
        int meshId = nextMeshId++;
        _dev = __Runtime_init_mesh_partition(meshId, p.startCol,
                                             p.endCol - p.startCol + 1);
        return aieMesh{rows, cols, p, meshId};
    }
    aieMesh partition(int rows, int cols) {
        int meshId = nextMeshId++;
        _dev = __Runtime_init_mesh_partition(meshId, 0, cols);
        return aieMesh{rows, cols, {0, cols - 1, 0, rows - 1}, meshId};
    }
    void* alloc(size_t size) { return __Runtime_alloc_buffer(_dev, size); }
    void free(void* ptr) { __Runtime_free_buffer(_dev, ptr); }
    void synchronizecpu(void* ptr, size_t size) {
        __Runtime_sync_for_cpu(_dev, ptr, size);
    }
};
"""


def _strip_leading_copyright(text: str) -> str:
    """Drop a leading ``_COPYRIGHT`` C block-comment from ``text`` (if present).

    The folded artifacts (main.cc, CPU ``.c``) each carry their own copyright
    banner; only host.cc's should survive in the merged file, so this removes a
    duplicate leading ``/*...*/`` banner before splicing bodies in.
    """
    s = text.lstrip()
    if s.startswith("/*"):
        end = s.find("*/")
        if end != -1:
            return s[end + 2:].lstrip("\n")
    return text


def _fold_main_into_host(build_dir: str) -> None:
    """Splice ``main.cc`` + CPU ``<op>.c`` bodies + mesh preamble into host.cc.

    hostcompile.sh links only ``host.cc``; ``main.cc`` and the CPU ``.c`` files
    are never picked up. So we append, in order: the aieMesh/aieArray preamble
    (right after host.cc's existing ``#include "aie_runtime.h"``), then every CPU
    op's plain-C body wrapped ``extern "C"`` (their entries are declared
    ``extern "C"`` in ``main.cc``), then ``main.cc``'s body (its own
    ``#include``s / copyright banner stripped, leaving the ``extern "C"`` protos
    + ``int main()``). The CPU ``.c`` and ``main.cc`` files are left on disk (the
    script ignores them); only ``host.cc`` is mutated.
    """
    host_path = os.path.join(build_dir, "host.cc")
    with open(host_path) as f:
        host = f.read()

    # The aieMesh/aieArray struct definitions must precede every use — in
    # particular the __aie_launch dispatcher already appended to the END of
    # host.cc dereferences ``mesh.meshId``. So splice the preamble in right after
    # host.cc's leading ``#include "aie_runtime.h"`` (not at the end of the file,
    # where it would land after the dispatcher and leave ``aieMesh`` undeclared).
    _inc = '#include "aie_runtime.h"'
    _at = host.find(_inc)
    if _at != -1:
        _cut = _at + len(_inc)
        host = host[:_cut] + "\n" + _AIE_MESH_PREAMBLE + host[_cut:]
    else:
        host = host.rstrip("\n") + "\n" + _AIE_MESH_PREAMBLE

    parts = [host.rstrip("\n")]

    # CPU-op plain-C bodies (extern "C" so the C++ main can call the C entries).
    for fname in sorted(os.listdir(build_dir)):
        if not fname.endswith(".c"):
            continue
        with open(os.path.join(build_dir, fname)) as f:
            body = _strip_leading_copyright(f.read())
        parts.append('\nextern "C" {\n' + body.rstrip("\n") + '\n}\n')

    # main.cc body: strip its copyright banner + #includes (host.cc already has
    # aie_runtime.h / cstdint / cstdio / cstring); keep the extern "C" protos +
    # int main(). Rewrite the argc/argv signature to the no-arg ``int main()``
    # form so hostcompile.sh's clean fixup path (only #define __global__) fires.
    main_path = os.path.join(build_dir, "main.cc")
    with open(main_path) as f:
        main_src = _strip_leading_copyright(f.read())
    # Strip main.cc's #includes -- host.cc already has aie_runtime.h/cstdint/
    # cstdio/cstring -- but KEEP any local "..." include: that is the embedded
    # image header, which defines the pixel table and the on-target quantizer
    # main() calls. Dropping it compiles to 'demo_image_quantize was not
    # declared in this scope'.
    kept = []
    for ln in main_src.splitlines():
        stripped = ln.lstrip()
        if stripped.startswith("#include"):
            if '"' in stripped:               # local header: keep it
                kept.append(ln)
            continue
        kept.append(ln)
    main_body = "\n".join(kept).replace("int main(int argc, char** argv)",
                                         "int main()")
    parts.append("\n// ===== folded from main.cc (program-order driver) =====\n"
                 + main_body.strip("\n") + "\n")

    with open(host_path, "w") as f:
        f.write("\n".join(parts) + "\n")


def _arrange_build_dir(build_dir: str) -> None:
    """Prepare ``build_dir`` (the WORKLOCAL_DIR) for hostcompile.sh.

    ``orchestrate_plan`` already writes ``host.cc``, ``kernel_<name>.cc``, the
    per-kernel ``aieml_<name>.prx``/``.bcf``, the CPU ``<op>.c`` files and
    ``main.cc`` here — the exact multi-kernel layout hostcompile.sh expects. The
    only missing piece is that the host link compiles ``host.cc`` alone, so we
    fold ``main.cc`` + CPU bodies + the mesh preamble into it (idempotent-guarded
    by a sentinel so a re-run doesn't double-splice).
    """
    host_path = os.path.join(build_dir, "host.cc")
    if not os.path.isfile(host_path):
        raise RuntimeError(f"host.cc not found in build dir: {build_dir!r}")
    with open(host_path) as f:
        if "folded from main.cc" in f.read():
            return  # already arranged (idempotent)
    if not os.path.isfile(os.path.join(build_dir, "main.cc")):
        raise RuntimeError(f"main.cc not found in build dir: {build_dir!r}")
    _fold_main_into_host(build_dir)


def _invoke_hostcompile(build_dir: str, repo_root: str,
                        debug_syms: bool = False) -> str:
    """Run ``script/hostcompile.sh`` over ``build_dir`` and return the ELF path.

    Invokes with ``WORKLOCAL_DIR=build_dir AIE_VERSION=5 PLATFORM=baremetal``
    (the same env aiehlc.sh/aiehlcrebuild.sh pass). The multi-kernel build
    compiles ~N AIE kernels through xchesscc and then links the host with no
    per-step console feedback, so the script's combined stdout/stderr is
    **streamed live** (each line echoed with a ``[hostcompile]`` prefix) instead
    of buffered — otherwise the caller looks frozen for the whole build. Lines
    are also accumulated so the failure path can still report the tail. On
    non-zero exit raises ``RuntimeError`` with the tail; on success returns
    ``build_dir/build/host`` (the linked ELF), verifying it exists.
    """
    script = os.path.join(repo_root, "script", "hostcompile.sh")
    if not os.path.isfile(script):
        raise RuntimeError(f"hostcompile.sh not found: {script!r}")
    env = dict(os.environ)
    env["WORKLOCAL_DIR"] = build_dir
    env.setdefault("AIE_VERSION", "5")
    env.setdefault("PLATFORM", "baremetal")
    # A small, stripped main.elf is the default here -- assigned, not
    # setdefault'd. The env is inherited from the caller's shell and
    # script/aiehlc.sh exports DEBUG_SYMS=1 for its own debug builds, so a
    # leftover export would otherwise silently publish the ~3x larger
    # unstripped ELF. Symbols are requested explicitly via
    # build_main_elf(debug_syms=True), never by ambient environment.
    env["DEBUG_SYMS"] = "1" if debug_syms else "0"
    nkernels = len([f for f in os.listdir(build_dir)
                    if f.startswith("kernel_") and f.endswith(".cc")])
    what = (f"compiling {nkernels} AIE kernel(s) via xchesscc, then host link"
            if nkernels else "host link only (no AIE kernels to compile)")
    print(f"[hostcompile] building main.elf in {build_dir}\n"
          f"[hostcompile] {what} (live log follows)...", flush=True)
    lines: List[str] = []
    proc = subprocess.Popen(["bash", script], cwd=build_dir, env=env,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            text=True, bufsize=1)
    assert proc.stdout is not None
    for raw in proc.stdout:
        line = raw.rstrip("\n")
        lines.append(line)
        print(f"[hostcompile] {line}", flush=True)
    rc = proc.wait()
    if rc != 0:
        tail = "\n".join(lines[-40:])
        raise RuntimeError(
            f"hostcompile.sh failed (rc={rc}) for {build_dir!r}\n"
            f"--- log tail ---\n{tail}")
    elf = os.path.join(build_dir, "build", "host")
    if not os.path.isfile(elf):
        tail = "\n".join(lines[-40:])
        raise RuntimeError(
            f"hostcompile.sh reported success but {elf!r} is missing\n"
            f"--- log tail ---\n{tail}")

    # Prefer the published main.elf over build/host: they are the same program,
    # but hostcompile.sh strips the published copy (~70% of the link is DWARF
    # from the prebuilt BSP/libgloss/aie-rt libs, which none of our own -Os
    # objects contribute). build/host is the unstripped intermediate, so
    # returning it would hand the caller -- and every `dow` over JTAG -- the
    # big one. Full symbols stay beside it as main.debug.elf.
    published = os.path.join(os.path.dirname(build_dir), "main.elf")
    if os.path.isfile(published):
        elf = published
    print(f"[hostcompile] done -> {elf} ({os.path.getsize(elf):,} B)", flush=True)
    return elf


def build_main_elf(build_dir: str, debug_syms: bool = False) -> str:
    """Build the A2 ``main.elf`` from an ``orchestrate_plan`` build dir.

    Arranges ``build_dir`` to satisfy hostcompile.sh's multi-kernel contract
    (folds ``main.cc`` + CPU bodies + the aieMesh/aieArray preamble into
    ``host.cc``; the ``kernel_<name>.cc``/``.prx``/``.bcf`` are already in place),
    then reuses ``script/hostcompile.sh`` to compile every kernel and link the
    host ELF. Raises ``RuntimeError`` on any arrangement or compile/link failure
    (never fakes a build).

    Returns the **published, stripped** ELF at ``<dirname(build_dir)>/main.elf``,
    falling back to the unstripped ``build_dir/build/host`` intermediate only if
    the publish step did not run. Stripping is the **default**: ~70% of the link
    is DWARF from the prebuilt BSP/libgloss/aie-rt archives (nothing this
    project compiles carries ``-g``), so a 2.8 MB A2 build publishes at ~880 KB
    with a byte-identical LOAD segment -- same program, ~3x less to push over
    JTAG. ``--strip-debug`` keeps ``.symtab``, so xsdb/aiedbg still resolve
    function names.

    ``debug_syms=True`` builds with ``-g`` and skips the strip. It is a
    parameter rather than an inherited ``DEBUG_SYMS`` env var on purpose:
    ``script/aiehlc.sh`` exports that variable for its own debug builds, and a
    leftover export silently tripling this ELF is exactly the surprise worth
    designing out. Full symbols are kept beside the stripped ELF as
    ``main.debug.elf`` regardless.
    """
    build_dir = os.path.abspath(build_dir)
    # repo root: this file is <root>/src/frontend/tvm/orchestrator.py.
    repo_root = os.path.abspath(
        os.path.join(os.path.dirname(__file__), "..", "..", ".."))
    _arrange_build_dir(build_dir)
    return _invoke_hostcompile(build_dir, repo_root, debug_syms=debug_syms)


# ═══════════════════════════════════════════════════════════════════════════
#  x86 host build — run the same emitted CPU code natively, no board needed
# ═══════════════════════════════════════════════════════════════════════════
#
# The aarch64 path (build_main_elf) produces a baremetal ELF that only runs on
# the board over JTAG. That is a slow feedback loop for a change that is purely
# numerical, so this builds the SAME generated .c files for the host instead.
# It is a verification path, not a deployment one: identical op bodies,
# identical program order, but ordinary malloc and a printf you can actually
# see. If the numbers are wrong here they are wrong on the board too.
#
# Only meaningful when every op is on the CPU (offload disabled). With AIE
# kernels in the mix the launches go through __aie_launch into hardware, which
# has no x86 equivalent.

_X86_RUNTIME_SHIM = """
/* ===== x86 stand-ins for the AIE runtime =====
 * The emitted main() calls a handful of __Runtime_* helpers for DDR buffers
 * and device lifecycle. On the host there is no device: allocation is calloc
 * (zeroed, matching __Runtime_Alloc's fresh-DMA-buffer semantics) and the
 * lifecycle calls are no-ops. Nothing here models AIE behaviour -- if a build
 * reaches one of these on a path that matters, the all-CPU assumption is
 * already broken. */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void *__Runtime_Alloc(size_t n) { return calloc(n ? n : 1, 1); }
"""


def build_x86_main(build_dir: str, out_path: str = None,
                   cc: str = "gcc") -> str:
    """Compile the emitted all-CPU sources into a native x86 binary.

    ``build_dir`` is an ``orchestrate_plan`` output directory built with
    ``enable_aiehlc_offload=False``. Returns the path to the linked binary.

    Rather than compiling ``host.cc`` (which pulls in ``aie_runtime.h`` and the
    whole XAie header set), this takes ``main.cc`` + the per-op ``.c`` files and
    supplies a tiny shim for the few ``__Runtime_*`` calls ``main`` makes. The
    op bodies -- the part whose numerics we are checking -- are compiled
    verbatim, unmodified.

    Raises ``RuntimeError`` if the build dir still contains AIE kernels (their
    launches have no host equivalent) or if the compile fails.
    """
    build_dir = os.path.abspath(build_dir)
    if [f for f in os.listdir(build_dir) if f.startswith("kernel_")]:
        raise RuntimeError(
            f"{build_dir!r} contains AIE kernels; the x86 path only supports "
            "an all-CPU build (orchestrate_plan(..., "
            "enable_aiehlc_offload=False))")
    main_cc = os.path.join(build_dir, "main.cc")
    if not os.path.isfile(main_cc):
        raise RuntimeError(f"main.cc not found in {build_dir!r}")
    if out_path is None:
        out_path = os.path.join(build_dir, "main_x86")

    # Strip the AIE include and the device lifecycle calls from main.cc; the
    # all-CPU main has none of the latter, but an offload build would.
    with open(main_cc) as f:
        src = f.read()
    src = src.replace('#include "aie_runtime.h"', _X86_RUNTIME_SHIM, 1)
    drop = ("__Runtime_explicit_init", "__Runtime_device_teardown",
            "__Runtime_sync_for_cpu", "__Runtime_sync_for_dev",
            "aieArray ", "aieMesh ")
    kept = [ln for ln in src.splitlines()
            if not any(d in ln for d in drop)]
    shim_path = os.path.join(build_dir, "main_x86.cc")
    with open(shim_path, "w") as f:
        f.write("\n".join(kept) + "\n")

    csrcs = sorted(os.path.join(build_dir, f) for f in os.listdir(build_dir)
                   if f.endswith(".c"))
    if not csrcs:
        raise RuntimeError(f"no CPU op .c files in {build_dir!r}")
    objs = []
    for c in csrcs:                      # C sources: compile with the C driver
        o = c[:-2] + ".x86.o"
        r = subprocess.run([cc, "-O1", "-c", c, "-o", o],
                           capture_output=True, text=True)
        if r.returncode != 0:
            raise RuntimeError(f"failed to compile {os.path.basename(c)}:\n"
                               f"{r.stderr[-2000:]}")
        objs.append(o)
    # -I build_dir so the generated main can find <image>.h.
    r = subprocess.run([cc.replace("gcc", "g++"), "-O1", "-I", build_dir,
                        "-o", out_path, shim_path] + objs,
                       capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"x86 link failed:\n{r.stderr[-2000:]}")
    return out_path


def run_x86_main(binary: str) -> str:
    """Run an x86 binary from ``build_x86_main`` and return its stdout."""
    r = subprocess.run([binary], capture_output=True, text=True, timeout=600)
    if r.returncode != 0:
        raise RuntimeError(f"{binary!r} exited {r.returncode}\n{r.stderr[-2000:]}")
    return r.stdout


# ═══════════════════════════════════════════════════════════════════════════
#  Embedded image input — raw pixels in a header, quantized on-target
# ═══════════════════════════════════════════════════════════════════════════
#
# The alternative would be to quantize host-side and embed int8 values, but
# then the quantizer is not part of what the ELF exercises. Embedding RAW
# uint8 pixels and doing the affine quantization in C means the on-target code
# path is the one being verified -- the same arithmetic a camera-fed pipeline
# would run.

def emit_image_header(pixels, path: str, name: str = "demo_image",
                      src_note: str = "") -> dict:
    """Write ``<path>`` declaring ``name[]`` as hex uint8 pixels + its qparams.

    ``pixels`` is a flat uint8 array (grayscale, already resized to the model's
    input). Returns the asymmetric quantization params the C will apply, so the
    caller can reproduce them exactly for an oracle comparison.

    Quantization is **asymmetric**: ``q = round(p/scale) + zp`` with the scale
    and zero-point derived from the image's own [min,max]. For one-sided data
    like 8-bit pixels this keeps the full int8 range in use, where a symmetric
    scheme would waste the negative half. The params are computed here (float,
    once) and baked in as constants; the C does only the per-pixel affine, which
    is what an embedded target can afford.
    """
    import numpy as _np
    px = _np.asarray(pixels, dtype=_np.float32).ravel()
    lo, hi = float(px.min()), float(px.max())
    if hi - lo < 1e-9:                      # flat image: avoid a zero scale
        scale, zp = 1.0, -128
    else:
        scale = (hi - lo) / 255.0
        zp = int(_np.clip(round(-128 - lo / scale), -128, 127))
    u8 = _np.clip(_np.round(px), 0, 255).astype(_np.uint8)

    rows = []
    for i in range(0, u8.size, 12):
        rows.append("    " + " ".join(f"0x{v:02X}," for v in u8[i:i + 12]))
    body = "\n".join(rows)
    with open(path, "w") as f:
        f.write(f"""{_COPYRIGHT}/* GENERATED: {src_note or 'embedded demo image'}
 * Raw 8-bit pixels; the program quantizes them at runtime with the affine
 * params below (asymmetric: q = round(p/scale) + zp, clamped to int8).
 */
#ifndef {name.upper()}_H
#define {name.upper()}_H
#include <stdint.h>

#define {name.upper()}_LEN {u8.size}
#define {name.upper()}_SCALE {scale:.9f}f
#define {name.upper()}_ZP {zp}

static const uint8_t {name}[{u8.size}] = {{
{body}
}};

/* Asymmetric quantize the embedded image into int8. Kept as a function (not a
 * table of pre-quantized values) so the ELF actually performs the quantization
 * rather than just replaying a host-side result. */
static void {name}_quantize(int8_t *out) {{
    for (int i = 0; i < {name.upper()}_LEN; ++i) {{
        float v = (float){name}[i] / {name.upper()}_SCALE + ({name.upper()}_ZP);
        int r = (int)(v < 0.0f ? v - 0.5f : v + 0.5f);   /* round-half-away */
        if (r < -128) r = -128;
        if (r >  127) r =  127;
        out[i] = (int8_t)r;
    }}
}}

#endif /* {name.upper()}_H */
""")
    return {"scale": scale, "zp": zp, "len": int(u8.size), "path": path,
            "pixels": u8}
