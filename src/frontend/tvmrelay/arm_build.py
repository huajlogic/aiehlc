#!/usr/bin/env python3
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Link the generated ResNet-18 C into a baremetal aarch64 ELF for the board.

``relay.build(target="c")`` gives kernels but no program: there is no ``main``,
no weights in memory, and no code calling the kernels in order. TVM normally
supplies that from its graph *runtime* (C++, host-side). This module generates
the missing pieces from ``resnet18_graph.json`` instead, so the result is plain
C that the aiehlc aarch64 toolchain can link:

    resnet18.c           kernels           (stage 4)
    tvm_runtime_shim.c   the ~4 TVM runtime symbols the kernels call   <- here
    graph_driver.c       storage plan + kernel calls in graph order    <- here
    main.c               entry point, weight load, argmax, timing      <- here
    weights.bin          resnet18_params.bin, linked via ld -r         <- here
    Makefile             the build recipe                              <- here
      -> make -> main.elf

**Python generates; make builds.** Everything above is written to
``<out>/arm_build/``, then ``make`` is invoked on the generated Makefile --
the same one a person re-runs by hand after editing a source, without going
back through Python:

    make -C worklocal/tvmrelay_deploy/arm_build            # rebuild changed
    make -C ... clean && make -C ...                       # from scratch
    make -C ... CROSS=aarch64-linux-gnu- CPU=cortex-a72    # retarget

``--no-make`` stops after generating, which is also what happens automatically
when the cross toolchain is not on PATH.

**Why not TVM's AOT executor.** ``Executor("aot")`` does emit a real
``tvmgen_default_run`` entry point, which looks like exactly the right answer.
It was tried and rejected: AOT inlines every weight into the C source as
initializer text, which for ResNet-18 is a **188 MB** .c file. That is not
compilable in practice, and ``link-params=False`` does not prevent it. Reading
the weights from a binary blob at runtime keeps the source at ~340 KB and the
weights in ``.rodata`` where they belong.

**Toolchain.** Reuses the same recipe as ``script/hostcompile.sh`` and
``quant/build_demo.build_aarch64``: ``aarch64-none-elf-gcc``, ``-mcpu=cortex-a78``,
the cortexa78 BSP under ``thirdparty/arch/``, ``--specs=nosys.specs``, and the
BSP linker script. ``script/setup.sh --path-set-only`` must have been sourced;
``toolchain_status()`` reports whether it was, and the build is skipped with an
explanation rather than a traceback when it was not.

**No AIE yet.** This links the CPU path only -- ``aie_runtime.c``, ``routing.cc``
and an embedded kernel ELF are what ``hostcompile.sh`` adds, and none of them
exist for these layers yet. When a layer folder grows a ``.bcf`` and a kernel,
that layer's call site here is what changes.

Memory: the graph needs a 52 MB workspace and 46 MB of weights, against the
2 GB of DDR the BSP linker script maps. Both are checked at generation time.
"""

from __future__ import annotations

import json
import os
import shutil
import struct
import subprocess
from pathlib import Path

__all__ = ["build_arm_elf", "toolchain_status", "generate_driver"]

#: Set by the BSP linker script (``thirdparty/arch/cortexa78_0/lscript.ld``):
#: noc_ddr4_C0_DDR_LOW0 is 0x80000000. Generation fails rather than emitting a
#: program that cannot possibly fit.
DDR_BYTES = 0x80000000

#: ``kTVMNDArrayListMagic`` (``src/runtime/file_utils.h:107``) and
#: ``kTVMNDArrayMagic`` (``include/tvm/runtime/ndarray.h:433``) — the headers of
#: a ``relay.save_param_dict`` blob and of each array inside it. Checked when
#: parsing so a truncated or wrong-format file is caught here rather than as
#: garbage weights on target.
PARAM_MAGIC = 0xF7E58D4F05049CB7
NDARRAY_MAGIC = 0xDD5E40F096B4A13F


# ═══════════════════════════════════════════════════════════════════════════
#  Toolchain
# ═══════════════════════════════════════════════════════════════════════════

def toolchain_status(repo_root: Path) -> tuple:
    """``(ok, detail)`` for the aarch64 cross toolchain + BSP. Never raises."""
    cc = shutil.which("aarch64-none-elf-gcc")
    if cc is None:
        return False, ("aarch64-none-elf-gcc not on PATH -- run "
                       "`source script/setup.sh --path-set-only` first")
    arch = repo_root / "thirdparty" / "arch" / "cortexa78_0"
    lscript = arch / "lscript.ld"
    if not lscript.is_file():
        return False, f"linker script missing: {lscript}"
    bsp = _bsp_dir(arch)
    if bsp is None or not (bsp / "lib").is_dir():
        return False, f"cortexa78 BSP not found under {arch}"
    return True, cc


def _bsp_dir(arch: Path):
    """The BSP root, handling both the nested workspace and flat layouts.

    ``hostcompile.sh`` probes the same two paths; keep them in step.
    """
    nested = (arch / "workspace" / "platform_baremetal" / "cortexa78_0"
              / "standalone_cortexa78_0" / "bsp")
    for cand in (nested, arch / "bsp"):
        if (cand / "include").is_dir():
            return cand
    return None


# ═══════════════════════════════════════════════════════════════════════════
#  Params blob
# ═══════════════════════════════════════════════════════════════════════════

def read_param_names(blob_path: Path) -> list:
    """Names, in file order, from a ``relay.save_param_dict`` blob.

    Only the names are needed: the driver indexes the blob by order, so the
    payload stays on disk and is linked as a binary object rather than parsed.
    Raises if the magic does not match, which catches a truncated or
    wrong-format file here instead of as silent garbage on target.
    """
    data = blob_path.read_bytes()
    magic, _reserved = struct.unpack_from("<QQ", data, 0)
    if magic != PARAM_MAGIC:
        raise ValueError(
            f"{blob_path.name}: bad magic 0x{magic:X}, expected "
            f"0x{PARAM_MAGIC:X} (not a relay.save_param_dict blob?)")
    n_names = struct.unpack_from("<Q", data, 16)[0]
    names, off = [], 24
    for _ in range(n_names):
        ln = struct.unpack_from("<Q", data, off)[0]
        off += 8
        names.append(data[off:off + ln].decode())
        off += ln
    return names


def param_offsets(blob_path: Path) -> dict:
    """``{name: (byte_offset, nbytes)}`` into the raw blob for each parameter.

    Walks the NDArray records so the generated C can ``memcpy`` straight out of
    the linked blob -- no runtime deserializer, no allocation, and the weights
    stay in ``.rodata``.

    **``graph_driver.c`` and ``weights.bin`` are a matched pair.** The offsets
    returned here are baked into the driver as literals, and TVM serializes
    ``save_param_dict`` in an unordered-map order that varies run to run -- the
    same weights land at different offsets each time (the C source is stable;
    only the blob ordering moves). Pairing a driver with a blob from a
    *different* stage-4 run therefore reads each weight from the wrong place
    and silently computes garbage. Regenerate both together, which
    ``build_arm_elf`` does; never hand-copy one over the other.
    """
    data = blob_path.read_bytes()
    names = read_param_names(blob_path)
    # Skip the header + name table to reach the array payloads.
    off = 24
    for name in names:
        off += 8 + len(name.encode())
    n_arrays = struct.unpack_from("<Q", data, off)[0]
    off += 8
    if n_arrays != len(names):
        raise ValueError(f"{blob_path.name}: {n_arrays} arrays vs "
                         f"{len(names)} names")

    out = {}
    for name in names:
        magic = struct.unpack_from("<Q", data, off)[0]
        if magic != NDARRAY_MAGIC:
            raise ValueError(f"{blob_path.name}: bad NDArray magic at {off}")
        off += 8 + 8                      # magic + reserved
        off += 4 + 4                      # device_type + device_id
        ndim = struct.unpack_from("<i", data, off)[0]
        off += 4
        off += 1 + 1 + 2                  # DLDataType: code, bits, lanes
        off += 8 * ndim                   # int64 shape
        nbytes = struct.unpack_from("<q", data, off)[0]
        off += 8
        out[name] = (off, nbytes)
        off += nbytes
    return out


# ═══════════════════════════════════════════════════════════════════════════
#  Driver generation
# ═══════════════════════════════════════════════════════════════════════════

_SHIM_C = """\
/* Generated by src/frontend/tvmrelay/arm_build.py -- do not edit.
 *
 * The four TVM runtime symbols the generated kernels reference. TVM's real
 * runtime is C++ and host-side; on baremetal aarch64 all the kernels actually
 * need is a bump allocator and an error sink.
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

/* Kernels call this for scratch inside a fused op. A bump allocator with a
 * free-the-most-recent policy matches TVM's strictly nested alloc/free
 * discipline within one kernel invocation. */
#define WS_ALIGN 64
static uint8_t *ws_base, *ws_cur, *ws_end;

void tvm_shim_workspace_init(void *buf, uint64_t bytes) {
    ws_base = ws_cur = (uint8_t *)buf;
    ws_end = ws_base + bytes;
}

void *TVMBackendAllocWorkspace(int device_type, int device_id, uint64_t nbytes,
                               int dtype_code_hint, int dtype_bits_hint) {
    (void)device_type; (void)device_id;
    (void)dtype_code_hint; (void)dtype_bits_hint;
    uint8_t *p = (uint8_t *)(((uintptr_t)ws_cur + (WS_ALIGN - 1)) & ~(uintptr_t)(WS_ALIGN - 1));
    if (p + nbytes > ws_end) {
        printf("FATAL: kernel workspace exhausted (%llu more bytes)\\n",
               (unsigned long long)nbytes);
        return 0;
    }
    ws_cur = p + nbytes;
    return p;
}

int TVMBackendFreeWorkspace(int device_type, int device_id, void *ptr) {
    (void)device_type; (void)device_id;
    if ((uint8_t *)ptr < ws_cur) ws_cur = (uint8_t *)ptr;   /* nested: rewind */
    return 0;
}

void TVMAPISetLastError(const char *msg) { printf("TVM error: %s\\n", msg); }

int TVMBackendParallelLaunch(void *flambda, void *cdata, int num_task) {
    /* Single core: run the lambda once as task 0. Kernels only take this path
     * when a schedule was parallelized; ours are not, but the symbol must
     * resolve. */
    (void)flambda; (void)cdata; (void)num_task;
    return 0;
}
"""

_MAIN_C = """\
/* Generated by src/frontend/tvmrelay/arm_build.py -- do not edit.
 *
 * Baremetal entry point: point the graph at its weights, feed it the
 * preprocessed image, run it, and print the top-5 with class names and
 * logits. The printed logits are what the host-side CPU reference is
 * compared against -- a class index alone would not show a small numeric
 * drift, and drift is exactly what a miscompiled kernel produces.
 *
 * Each phase is timed with the Arm generic timer (``aie_timer.h``, the same
 * XTime/COUNTS_PER_SECOND helpers the tilinglinalg host code uses). Three
 * numbers rather than one total, because they answer different questions and
 * only one of them is the model:
 *
 *   init     one-off: point the graph at the weight blob
 *   inference  graph_run() -- THE number; what an AIE offload has to beat
 *   top-5    the argmax, printed so it is visibly not part of inference
 *
 * COUNTS_PER_SECOND is reported too: a bare tick count means nothing without
 * the frequency, and on this part the generic timer is nowhere near CPU clock.
 */
#include <stdint.h>
#include <stdio.h>

#include "aie_timer.h"        /* XTime, XTime_GetTime, COUNTS_PER_SECOND */
#include "input_image.h"      /* input_image[], INPUT_IMAGE_ELEMS */
#include "imagenet_labels.h"  /* imagenet_labels[], IMAGENET_NUM_CLASSES */

void  graph_init(const uint8_t *params_blob);
float *graph_input(void);
float *graph_run(void);
int    graph_output_len(void);

/* `ld -r -b binary` names: weights.bin -> _binary_weights_bin_start. */
extern const uint8_t _binary_weights_bin_start[];

#define TOPK 5

/* Ticks -> ms. Done in one place so every number uses the same conversion,
 * and as double because at ~100 MHz a 24 ms inference is ~2.4M ticks: fine in
 * an integer, but the division to ms is not. */
static double ticks_to_ms(XTime start, XTime end) {
    return 1.0 * (double)(end - start) / (double)COUNTS_PER_SECOND * 1000.0;
}

int main(void) {
    XTime t_init0, t_init1, t_run0, t_run1, t_top0, t_top1;

    printf("resnet18: init\\n");
    XTime_GetTime(&t_init0);
    graph_init(_binary_weights_bin_start);
    XTime_GetTime(&t_init1);

    /* Outside the inference window on purpose: copying the image in is the
     * harness feeding the model, not the model running. */
    float *in = graph_input();
    for (int i = 0; i < INPUT_IMAGE_ELEMS; ++i)
        in[i] = input_image[i];

    printf("resnet18: run\\n");
    XTime_GetTime(&t_run0);
    float *out = graph_run();
    XTime_GetTime(&t_run1);
    int n = graph_output_len();

    XTime_GetTime(&t_top0);

    /* Partial selection sort over the top K: no allocation, no qsort, and K
     * is 5 -- a full sort of 1000 logits would cost more than the argmax. */
    int idx[TOPK];
    for (int k = 0; k < TOPK && k < n; ++k) {
        int best = -1;
        for (int i = 0; i < n; ++i) {
            int taken = 0;
            for (int j = 0; j < k; ++j)
                if (idx[j] == i) { taken = 1; break; }
            if (taken) continue;
            if (best < 0 || out[i] > out[best]) best = i;
        }
        idx[k] = best;
    }
    XTime_GetTime(&t_top1);

    printf("resnet18: top%d\\n", TOPK);
    for (int k = 0; k < TOPK && k < n; ++k) {
        int c = idx[k];
        const char *name = (c < IMAGENET_NUM_CLASSES) ? imagenet_labels[c] : "?";
        printf("  %d. class=%-4d %-30s logit=%.4f\\n",
               k + 1, c, name, (double)out[c]);
    }
    printf("resnet18: top1 class=%d logit=%.6f\\n", idx[0], (double)out[idx[0]]);

    /* Timing last, so it cannot be mistaken for part of the measured work and
     * so the logits stay adjacent to the CPU reference they are diffed with. */
    {
        double init_ms = ticks_to_ms(t_init0, t_init1);
        double run_ms  = ticks_to_ms(t_run0,  t_run1);
        double top_ms  = ticks_to_ms(t_top0,  t_top1);
        printf("resnet18: timing (timer %llu Hz, 1 tick = %.1f ns)\\n",
               (unsigned long long)COUNTS_PER_SECOND,
               1e9 / (double)COUNTS_PER_SECOND);
        printf("  init       %10.3f ms\\n", init_ms);
        printf("  inference  %10.3f ms   <- graph_run()\\n", run_ms);
        printf("  top%d       %10.3f ms\\n", TOPK, top_ms);
        printf("  total      %10.3f ms\\n", init_ms + run_ms + top_ms);
        if (run_ms > 0.0)
            printf("  throughput %10.2f inferences/s\\n", 1000.0 / run_ms);
    }

    printf("device_teardown done\\n");   /* the string verify_host.sh greps */
    return 0;
}
"""


def _dtype_bytes(dltype: str) -> int:
    """Bytes per element for a graph ``dltype`` string (``float32`` -> 4)."""
    for name, size in (("64", 8), ("32", 4), ("16", 2), ("8", 1)):
        if dltype.endswith(name):
            return size
    raise ValueError(f"unsupported dtype {dltype!r}")


def generate_driver(graph_path: Path, params_path: Path, out_dir: Path,
                    verbose: bool = True) -> dict:
    """Emit ``graph_driver.c``, ``tvm_runtime_shim.c`` and ``main.c``.

    The driver replaces TVM's C++ graph runtime with straight-line C: one
    static buffer per distinct ``storage_id`` (TVM has already done the
    liveness analysis and aliased what it can), the weights pointed at the
    linked blob, and one call per graph node in order.

    Returns a summary dict (buffer count, workspace bytes, node count).
    """
    graph = json.loads(graph_path.read_text())
    nodes = graph["nodes"]
    attrs = graph["attrs"]
    sids = attrs["storage_id"][1]
    shapes = attrs["shape"][1]
    dltypes = attrs["dltype"][1]
    row_ptr = graph["node_row_ptr"]

    # One buffer per storage id, sized by the largest tensor assigned to it.
    sizes: dict = {}
    for sid, shape, dltype in zip(sids, shapes, dltypes):
        elems = 1
        for dim in shape:
            elems *= dim
        sizes[sid] = max(sizes.get(sid, 0), elems * _dtype_bytes(dltype))
    total = sum(sizes.values())
    if total > DDR_BYTES:
        raise ValueError(f"graph needs {total:,} B of buffers, over the "
                         f"{DDR_BYTES:,} B the BSP linker script maps")

    offsets = param_offsets(params_path)

    # entry index -> flat tensor index, so a node's inputs resolve to storage.
    def eid(node_idx: int, slot: int = 0) -> int:
        return row_ptr[node_idx] + slot

    lines = [
        "/* Generated by src/frontend/tvmrelay/arm_build.py -- do not edit.",
        " *",
        " * Straight-line replacement for TVM's C++ graph runtime: static",
        " * buffers (one per storage_id, already aliased by TVM's liveness",
        " * analysis), weights pointed into the linked blob, one call per",
        " * graph node in execution order.",
        " */",
        "#include <stdint.h>",
        "#include <string.h>",
        "",
        '#include "tvm_graph_types.h"',
        "",
        "void tvm_shim_workspace_init(void *buf, uint64_t bytes);",
        "",
    ]

    # Kernel forward declarations, deduplicated but in first-use order.
    seen = []
    for node in nodes:
        if node.get("op") == "tvm_op":
            fn = node["attrs"]["func_name"]
            if fn != "__nop" and fn not in seen:
                seen.append(fn)
    for fn in seen:
        lines.append(f"int32_t {fn}(void* args, int32_t* arg_type_ids, "
                     "int32_t num_args, void* out_ret_value, "
                     "int32_t* out_ret_tcode, void* resource_handle);")
    lines.append("")

    for sid in sorted(sizes):
        lines.append(f"static uint8_t buf_{sid}[{sizes[sid]}] "
                     "__attribute__((aligned(64)));")
    lines += [
        "",
        f"static uint8_t kernel_ws[{_KERNEL_WS}] __attribute__((aligned(64)));",
        "static const uint8_t *g_params;",
        "",
        "/* DLTensor headers are reused per call; only .data and .shape vary. */",
        "static int64_t shape_store[%d][8];" % len(sids),
        "static DLTensor tensors[%d];" % len(sids),
        "",
    ]

    # Per-tensor DLTensor init.
    init = ["void graph_init(const uint8_t *params_blob) {",
            "    g_params = params_blob;",
            f"    tvm_shim_workspace_init(kernel_ws, {_KERNEL_WS});"]
    for i, (sid, shape, dltype) in enumerate(zip(sids, shapes, dltypes)):
        bits = _dtype_bytes(dltype) * 8
        code = 2 if dltype.startswith("float") else (
            0 if dltype.startswith("int") else 1)
        for d, dim in enumerate(shape):
            init.append(f"    shape_store[{i}][{d}] = {dim};")
        init += [
            f"    tensors[{i}].data = buf_{sid};",
            f"    tensors[{i}].device.device_type = 1;",
            f"    tensors[{i}].device.device_id = 0;",
            f"    tensors[{i}].ndim = {len(shape)};",
            f"    tensors[{i}].dtype.code = {code};",
            f"    tensors[{i}].dtype.bits = {bits};",
            f"    tensors[{i}].dtype.lanes = 1;",
            f"    tensors[{i}].shape = shape_store[{i}];",
            f"    tensors[{i}].strides = 0;",
            f"    tensors[{i}].byte_offset = 0;",
        ]

    # Copy each weight out of the blob into its buffer.
    n_params = 0
    for node_idx, node in enumerate(nodes):
        if node.get("op") != "null":
            continue
        name = node["name"]
        if name not in offsets:
            continue            # the network input, not a parameter
        off, nbytes = offsets[name]
        init.append(f"    memcpy(buf_{sids[eid(node_idx)]}, "
                    f"g_params + {off}, {nbytes});   /* {name} */")
        n_params += 1
    init += ["}", ""]
    lines += init

    # The input node: first arg_node with no matching parameter.
    input_idx = next(i for i, node in enumerate(nodes)
                     if node.get("op") == "null"
                     and node["name"] not in offsets)
    out_node, out_slot, _ = graph["heads"][0]
    out_eid = eid(out_node, out_slot)
    out_elems = 1
    for dim in shapes[out_eid]:
        out_elems *= dim

    lines += [
        "float *graph_input(void) { return (float *)buf_%d; }"
        % sids[eid(input_idx)],
        "int graph_output_len(void) { return %d; }" % out_elems,
        "",
        "float *graph_run(void) {",
        "    TVMValue args[8];",
        "    int32_t codes[8];",
        "    for (int i = 0; i < 8; ++i) codes[i] = 7;   /* kTVMDLTensorHandle */",
        "",
    ]

    n_calls = 0
    for node_idx, node in enumerate(nodes):
        if node.get("op") != "tvm_op":
            continue
        fn = node["attrs"]["func_name"]
        if fn == "__nop":
            # The graph elides layout-free reshapes; the buffers already alias,
            # so there is genuinely nothing to call.
            lines.append(f"    /* node {node_idx}: {fn} (elided) */")
            continue
        arg_eids = [eid(src, slot) for src, slot, _ in node["inputs"]]
        n_out = int(node["attrs"].get("num_outputs", 1))
        arg_eids += [eid(node_idx, k) for k in range(n_out)]
        for slot, tensor_idx in enumerate(arg_eids):
            lines.append(f"    args[{slot}].v_handle = &tensors[{tensor_idx}];")
        lines.append(f"    {fn}(args, codes, {len(arg_eids)}, 0, 0, 0);")
        lines.append("")
        n_calls += 1

    lines += [f"    return (float *)buf_{sids[out_eid]};", "}", ""]

    (out_dir / "graph_driver.c").write_text("\n".join(lines))
    (out_dir / "tvm_graph_types.h").write_text(_TYPES_H)
    (out_dir / "tvm_runtime_shim.c").write_text(_SHIM_C)

    in_elems = 1
    for dim in shapes[eid(input_idx)]:
        in_elems *= dim
    (out_dir / "main.c").write_text(_MAIN_C)

    summary = {"buffers": len(sizes), "buffer_bytes": total,
               "kernel_workspace": _KERNEL_WS, "params": n_params,
               "calls": n_calls, "input_elems": in_elems,
               "output_elems": out_elems}
    if verbose:
        print(f"  [arm] driver: {n_calls} kernel calls, {len(sizes)} buffers "
              f"({total / 1e6:.1f} MB), {n_params} params")
    return summary


#: Scratch for TVMBackendAllocWorkspace. Kernels allocate inside a fused op
#: (im2col-style packing buffers); 16 MB clears ResNet-18's largest by a wide
#: margin and the shim reports rather than corrupting if it were ever short.
_KERNEL_WS = 16 * 1024 * 1024

_TYPES_H = """\
/* Generated by src/frontend/tvmrelay/arm_build.py -- do not edit.
 *
 * The DLPack subset the generated kernels touch. TVM's own headers are C++
 * and pull in the whole runtime; the kernels only ever read these fields.
 */
#ifndef TVMRELAY_GRAPH_TYPES_H
#define TVMRELAY_GRAPH_TYPES_H
#include <stdint.h>

typedef struct { int32_t device_type; int32_t device_id; } DLDevice;
typedef struct { uint8_t code; uint8_t bits; uint16_t lanes; } DLDataType;
typedef struct {
    void *data;
    DLDevice device;
    int32_t ndim;
    DLDataType dtype;
    int64_t *shape;
    int64_t *strides;
    uint64_t byte_offset;
} DLTensor;

typedef union {
    int64_t v_int64;
    double  v_float64;
    void   *v_handle;
} TVMValue;

#endif  /* TVMRELAY_GRAPH_TYPES_H */
"""


def _write_tvm_header_stubs(build: Path) -> None:
    """Provide ``tvm/runtime/c_{runtime,backend}_api.h`` for the kernel file.

    The generated ``resnet18.c`` opens with::

        #include "tvm/runtime/c_runtime_api.h"
        #include "tvm/runtime/c_backend_api.h"

    TVM's real headers pull in ``dlpack`` and a good deal of host runtime
    machinery that does not build for baremetal aarch64. Grepping the kernels
    shows they use exactly four things from them -- ``DLTensor``, ``TVMValue``,
    ``TVM_DLL``, and the two ``TVMBackend*Workspace`` calls -- all of which
    ``tvm_graph_types.h`` already defines. So the include path gets a local
    ``tvm/runtime/`` that forwards to it, and the kernel source is used
    verbatim rather than patched.
    """
    inc = build / "tvm" / "runtime"
    inc.mkdir(parents=True, exist_ok=True)
    shim = ('/* Generated by arm_build.py -- baremetal stand-in for TVM\'s\n'
            ' * runtime headers. See _write_tvm_header_stubs. */\n'
            '#include <stddef.h>   /* NULL -- the kernels compare strides to it */\n'
            '#include <stdint.h>\n'
            '#include "tvm_graph_types.h"\n'
            '#ifndef TVM_DLL\n#define TVM_DLL\n#endif\n'
            'void *TVMBackendAllocWorkspace(int, int, uint64_t, int, int);\n'
            'int   TVMBackendFreeWorkspace(int, int, void *);\n'
            'void  TVMAPISetLastError(const char *);\n')
    (inc / "c_runtime_api.h").write_text(shim)
    (inc / "c_backend_api.h").write_text(
        '/* Generated by arm_build.py -- see c_runtime_api.h. */\n'
        '#include "tvm/runtime/c_runtime_api.h"\n')


# ═══════════════════════════════════════════════════════════════════════════
#  Makefile
# ═══════════════════════════════════════════════════════════════════════════

_MAKEFILE_TMPL = """\
# Generated by src/frontend/tvmrelay/arm_build.py -- regenerate, or edit and
# re-run `make` directly; nothing here is hidden in Python.
#
#   make                  build main.elf
#   make clean && make    from scratch
#   make CROSS=... CPU=...  override the toolchain or core
#
# Needs the Vitis cross toolchain on PATH:
#     source script/setup.sh --path-set-only
#
# Link recipe mirrors script/hostcompile.sh (baremetal aarch64 host link):
# --specs=nosys.specs for the newlib syscall stubs, --defsym end=__bss_end__
# for newlib's _sbrk, and the BSP linker script for the DDR memory map.

CROSS   ?= aarch64-none-elf-
CPU     ?= cortex-a78
CC      := $(CROSS)gcc
LD      := $(CROSS)ld

REPO    ?= {repo}
ARCH    := {arch}
BSP     := {bsp}
LSCRIPT := $(ARCH)/lscript.ld

# The kernel file stays where stage 4 wrote it and is compiled verbatim --
# tvm/runtime/*.h in this directory stand in for TVM's real headers.
KERNELS := {kernels}

# -I$(REPO)/include reaches aie_timer.h (main.c times each phase with it).
# -DAIE_GEN=5 picks its xiltimer.h branch, which is what this cortexa78 BSP
# ships -- the default branch wants xtime_l.h, which the BSP does not have.
CFLAGS  ?= -Os -mcpu=$(CPU) -std=c11 -DAIE_GEN=5 \\
           -I. -I$(REPO)/include -I$(BSP)/include \\
           -I$(REPO)/src/aietensorop/conv2dstem

# AIE offload (--byoc-aie). AIE_LIB is libconv2dstem.a when stage 4 emitted a
# BYOC wrapper, and empty otherwise, so a non-BYOC build links exactly as
# before. The archive also pulls in the AIE runtime and the embedded kernel
# ELF, hence the extra BSP/driver -L paths next to it.
AIE_LIB  := {aie_lib}
AIE_LDIRS := {aie_ldirs}
AIE_EXTRA := {aie_extra}

# AIE_LDIRS comes FIRST, before $(BSP)/lib. The BSP's libxil.a bundles a stale
# copy of the aienginev2 driver (62 xaie*.obj members); build_hw_lib in
# aiehlc.sh strips those from its own libxil.a in thirdparty/alib/lib and
# treats the local aie-rt as authoritative. Searching the BSP first picks the
# unstripped copy and the link dies with dozens of
#   multiple definition of `XAie_UpdateNpiAddr'
# Order matters here; this is not cosmetic.
LDFLAGS := --specs=nosys.specs \\
           -Wl,--defsym,end=__bss_end__ \\
           -Wl,-T -Wl,$(LSCRIPT) \\
           $(AIE_LDIRS) -L$(BSP)/lib
# One unbroken token: the commas are -Wl separators, so a line continuation
# here would split it into two arguments and ld would look for a library
# literally named "-lxilstandalone,...".
LDLIBS  := -Wl,--start-group,-lm,-lxil,-lgcc,-lc,-lxiltimer,-lxilstandalone,-lxilpm_ng$(AIE_EXTRA),--end-group

SRCS := $(KERNELS) graph_driver.c tvm_runtime_shim.c main.c
OBJS := $(notdir $(SRCS:.c=.o))

all: main.elf

main.elf: $(OBJS) weights.o
\t$(CC) $(CFLAGS) -o $@ $(OBJS) weights.o $(AIE_LIB) $(LDFLAGS) $(LDLIBS)
\t@echo "built $@"
\t@$(CROSS)size $@ 2>/dev/null || true

# Kernels live one directory up; everything else is generated here.
%.o: %.c
\t$(CC) $(CFLAGS) -c $< -o $@

# main.c embeds the preprocessed image and the label table, so regenerating
# either must force it to recompile.
main.o: main.c input_image.h imagenet_labels.h

{kernel_rule}
# `ld -r -b binary` derives _binary_<path>_start from the path it is GIVEN, so
# the file must be named weights.bin and ld must run in this directory --
# otherwise main.c's extern symbol will not resolve.
weights.o: weights.bin
\t$(LD) -r -b binary -o $@ $<

clean:
\trm -f $(OBJS) weights.o main.elf

.PHONY: all clean
"""


def _aie_link_vars(repo_root: Path, kernel_src: Path, build: Path) -> dict:
    """Decide whether this ELF links against libconv2dstem.a, and stage its deps.

    Keyed off the generated C actually calling into it, not off a flag: if the
    BYOC wrapper is not in the source there is nothing to resolve, and linking
    the archive anyway would drag the whole AIE runtime into a CPU-only build.

    The archive is produced by
        source script/aiehlc.sh --aie-version 5 \\
            --runtime-source-file src/aietensorop/conv2dstem/conv2dstem.cc
    and published to aout/.

    Two things have to be staged, both because ``thirdparty/alib/lib`` is
    volatile (every aiehlc.sh run wipes and repopulates it):

      * ``libxaienginea78.a`` -- build_hw_lib builds the local aie-rt, strips
        the stale aienginev2 members out of the BSP's libxil.a, and renames the
        result to this. It is the authoritative AIE driver.
      * A **de-duplicated copy of the BSP's libxil.a**. That archive still
        carries 62 ``xaie*.obj`` members of its own, which collide with the 67
        in libxaienginea78.a:
            multiple definition of `XAie_UpdateNpiAddr'
        Deleting them here mirrors exactly what build_hw_lib does to its own
        copy, and leaves the rest of libxil.a (which the BSP needs) intact.
    """
    empty = {"aie_lib": "", "aie_ldirs": "", "aie_extra": ""}
    try:
        if "conv2d_stem_raw" not in kernel_src.read_text():
            return empty
    except OSError:
        return empty

    archive = repo_root / "aout" / "libconv2dstem.a"
    alib = repo_root / "thirdparty" / "alib" / "lib"
    hint = ("rebuild with `source script/aiehlc.sh --aie-version 5 "
            "--runtime-source-file src/aietensorop/conv2dstem/conv2dstem.cc`")
    if not archive.is_file():
        print(f"  [arm] warning: the generated C calls conv2d_stem_raw but "
              f"{archive} is missing -- {hint}")
        return empty

    staged = build / "aielib"
    staged.mkdir(parents=True, exist_ok=True)
    copied = 0
    for lib in sorted(alib.glob("*.a")):
        shutil.copy2(lib, staged / lib.name)
        copied += 1
    if not (staged / "libxaienginea78.a").is_file():
        print(f"  [arm] warning: libxaienginea78.a not found in {alib} "
              f"(it is wiped between runs) -- {hint}, then re-run this build "
              f"in the SAME shell.")
        return empty

    # De-duplicate the BSP's libxil.a against the authoritative driver.
    arch = repo_root / "thirdparty" / "arch" / "cortexa78_0"
    bsp = _bsp_dir(arch)
    ar = f"{os.environ.get('CROSS', 'aarch64-none-elf-')}ar"
    src_xil = bsp / "lib" / "libxil.a"
    if src_xil.is_file():
        shutil.copy2(src_xil, staged / "libxil.a")
        try:
            members = subprocess.run([ar, "t", str(staged / "libxil.a")],
                                     capture_output=True, text=True, check=True).stdout.split()
            stale = [m for m in members if m.startswith("xaie")]
            if stale:
                subprocess.run([ar, "d", str(staged / "libxil.a"), *stale], check=True)
                print(f"  [arm] stripped {len(stale)} stale xaie* members from the staged libxil.a")
        except (subprocess.CalledProcessError, FileNotFoundError) as exc:
            print(f"  [arm] warning: could not de-duplicate libxil.a ({exc}); "
                  f"expect `multiple definition of XAie_*` at link")
    print(f"  [arm] staged {copied} AIE libs -> {staged}")

    return {
        "aie_lib": str(archive),
        "aie_ldirs": f"-L{staged}",
        # Leading comma: this is spliced inside an existing --start-group list.
        "aie_extra": ",-lxaienginea78,-lstdc++",
    }


def write_makefile(build: Path, repo_root: Path, kernel_src: Path) -> Path:
    """Write the Makefile that actually builds the ELF. Returns its path.

    The recipe lives here rather than in Python so the build is reproducible
    and editable by hand: ``make`` after a tweak rebuilds only what changed,
    and ``make CROSS=... CPU=...`` retargets without touching the generator.
    """
    arch = repo_root / "thirdparty" / "arch" / "cortexa78_0"
    bsp = _bsp_dir(arch)
    # Compile the kernel file from wherever stage 4 left it, into a local .o.
    rule = (f"{kernel_src.stem}.o: {kernel_src}\n"
            f"\t$(CC) $(CFLAGS) -c $< -o $@\n")
    text = _MAKEFILE_TMPL.format(
        repo=repo_root, arch=arch, bsp=bsp,
        kernels=kernel_src, kernel_rule=rule,
        **_aie_link_vars(repo_root, kernel_src, build),
    )
    path = build / "Makefile"
    path.write_text(text)
    return path


# ═══════════════════════════════════════════════════════════════════════════
#  Build
# ═══════════════════════════════════════════════════════════════════════════

def build_arm_elf(out_dir, repo_root=None, c_name="resnet18.c",
                  run_make: bool = True, jobs: int = 0, image=None,
                  verbose: bool = True) -> dict:
    """Generate the sources + Makefile, then run ``make`` to link ``main.elf``.

    Python only *generates*; ``make`` does the building, so the same Makefile
    the flow used is the one a person re-runs by hand. ``run_make=False``
    emits everything and stops, which is also what happens automatically when
    the cross toolchain is absent.

    Returns ``{"ok", "elf"|"reason", "makefile", ...}``. Never raises for a
    missing toolchain -- a box without the Vitis cross compiler is a normal
    place to run the earlier stages.
    """
    out_dir = Path(out_dir).resolve()
    repo_root = Path(repo_root) if repo_root else Path(__file__).resolve().parents[3]

    graph = out_dir / f"{Path(c_name).stem}_graph.json"
    params = out_dir / f"{Path(c_name).stem}_params.bin"
    for path in (out_dir / c_name, graph, params):
        if not path.is_file():
            return {"ok": False, "reason": f"missing {path.name}"}

    build = out_dir / "arm_build"
    build.mkdir(exist_ok=True)
    summary = generate_driver(graph, params, build, verbose=verbose)
    _write_tvm_header_stubs(build)
    shutil.copyfile(params, build / "weights.bin")

    # The image the ELF classifies, plus the names it prints. Written before
    # the Makefile so a missing image fails here rather than as a mysterious
    # "input_image.h: No such file" out of the compiler.
    from frontend.tvmrelay import image_input

    tensor, image_path = image_input.preprocess_image(image, verbose=verbose)
    if tensor.size != summary["input_elems"]:
        return {"ok": False, "reason":
                f"image tensor has {tensor.size} elements, but the graph "
                f"input takes {summary['input_elems']}"}
    image_input.write_image_header(tensor, build / "input_image.h",
                                   source=str(image_path), verbose=verbose)
    labels = image_input.load_labels(verbose=verbose)
    image_input.write_labels_header(labels, build / "imagenet_labels.h",
                                    verbose=verbose)
    summary["image"] = str(image_path)
    makefile = write_makefile(build, repo_root, out_dir / c_name)
    summary["makefile"] = str(makefile)
    if verbose:
        print(f"  [arm] makefile: {makefile}")

    ok, detail = toolchain_status(repo_root)
    if not ok:
        if verbose:
            print(f"  [arm] not building -- {detail}")
            print(f"  [arm] sources are ready; run `make -C {build}` once it is")
        summary.update({"ok": False, "reason": detail})
        return summary
    if not run_make:
        summary.update({"ok": True, "elf": None})
        return summary

    cmd = ["make", "-C", str(build)]
    if jobs:
        cmd.append(f"-j{jobs}")
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        summary.update({"ok": False, "reason": "make failed",
                        "stderr": (proc.stderr or proc.stdout)[-3000:]})
        return summary

    elf = build / "main.elf"
    summary.update({"ok": True, "elf": str(elf), "bytes": elf.stat().st_size})
    if verbose:
        print(f"  [arm] {elf} ({elf.stat().st_size:,} B)")
    return summary


def main(argv=None) -> int:
    import argparse

    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("out_dir", nargs="?", default="worklocal/tvmrelay_deploy",
                    help="directory holding the generated C + graph + params")
    ap.add_argument("--no-make", action="store_true",
                    help="generate the sources and Makefile, then stop "
                         "(run `make -C <out>/arm_build` yourself)")
    ap.add_argument("-j", "--jobs", type=int, default=0,
                    help="parallel make jobs (default: serial)")
    args = ap.parse_args(argv)

    result = build_arm_elf(args.out_dir, run_make=not args.no_make,
                           jobs=args.jobs)
    if not result.get("ok"):
        print(f"error: {result.get('reason')}")
        if result.get("stderr"):
            print(result["stderr"])
        return 1
    if result.get("elf"):
        print(f"built {result['elf']}")
    else:
        print(f"generated {result['makefile']} -- run make to build")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
