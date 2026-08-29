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
#     ``<dirname(WORKLOCAL_DIR)>/main.elf``.

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

    parts = [host.rstrip("\n"), _AIE_MESH_PREAMBLE]

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
    kept = [ln for ln in main_src.splitlines()
            if not ln.lstrip().startswith("#include")]
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


def _invoke_hostcompile(build_dir: str, repo_root: str) -> str:
    """Run ``script/hostcompile.sh`` over ``build_dir`` and return the ELF path.

    Invokes with ``WORKLOCAL_DIR=build_dir AIE_VERSION=5 PLATFORM=baremetal``
    (the same env aiehlc.sh/aiehlcrebuild.sh pass). On non-zero exit raises
    ``RuntimeError`` with the tail of the combined stdout/stderr log. On success
    returns ``build_dir/build/host`` (the linked ELF), verifying it exists.
    """
    script = os.path.join(repo_root, "script", "hostcompile.sh")
    if not os.path.isfile(script):
        raise RuntimeError(f"hostcompile.sh not found: {script!r}")
    env = dict(os.environ)
    env["WORKLOCAL_DIR"] = build_dir
    env.setdefault("AIE_VERSION", "5")
    env.setdefault("PLATFORM", "baremetal")
    proc = subprocess.run(["bash", script], cwd=build_dir, env=env,
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                          text=True)
    if proc.returncode != 0:
        tail = "\n".join((proc.stdout or "").splitlines()[-40:])
        raise RuntimeError(
            f"hostcompile.sh failed (rc={proc.returncode}) for {build_dir!r}\n"
            f"--- log tail ---\n{tail}")
    elf = os.path.join(build_dir, "build", "host")
    if not os.path.isfile(elf):
        tail = "\n".join((proc.stdout or "").splitlines()[-40:])
        raise RuntimeError(
            f"hostcompile.sh reported success but {elf!r} is missing\n"
            f"--- log tail ---\n{tail}")
    return elf


def build_main_elf(build_dir: str) -> str:
    """Build the A2 ``main.elf`` from an ``orchestrate_plan`` build dir.

    Arranges ``build_dir`` to satisfy hostcompile.sh's multi-kernel contract
    (folds ``main.cc`` + CPU bodies + the aieMesh/aieArray preamble into
    ``host.cc``; the ``kernel_<name>.cc``/``.prx``/``.bcf`` are already in place),
    then reuses ``script/hostcompile.sh`` to compile every kernel and link the
    host ELF. Returns the linked ELF path (``build_dir/build/host``); a copy is
    also published by the script at ``<dirname(build_dir)>/main.elf``. Raises
    ``RuntimeError`` on any arrangement or compile/link failure (never fakes a
    build).
    """
    build_dir = os.path.abspath(build_dir)
    # repo root: this file is <root>/src/frontend/tvm/orchestrator.py.
    repo_root = os.path.abspath(
        os.path.join(os.path.dirname(__file__), "..", "..", ".."))
    _arrange_build_dir(build_dir)
    return _invoke_hostcompile(build_dir, repo_root)
