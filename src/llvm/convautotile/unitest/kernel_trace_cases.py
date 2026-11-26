#!/usr/bin/env python3
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Kernel-analysis regression: each case mutates a conv example into one logic
bug and checks `aiehlc-convtile trace` rejects it with the expected diagnostic.
CASES use the kernel-only port form (simpleconv2dkernel_port.cc), TENSOR_CASES
the tensor form (simpleconv2dkernel.cc: aie::in / aie::out, .pad, .reuse,
block views, aie::autotune), DATAFLOW_CASES the {.depth / .resident / .tile}
options (simplegemm_dataflow.cc), SPACE_CASES hand-written GemmSpaces + block
loads (simpleconv2dkernel_space.cc: a GemmSpace and the kernel's blocks must agree),
TEMPLATE_CASES a `template <...> __global__` kernel (src/aiednn/gemm/gemm_kacc_kernel.cc + a host launch:
instantiated at its launch by kernel_template.cpp before the analysis).

    python3 src/llvm/convautotile/unitest/kernel_trace_cases.py [build/aiehlc-convtile]
"""
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parents[4]
CCODE = REPO / "example" / "tileprogram" / "ccode"
BASE = CCODE / "simpleconv2dkernel_port.cc"
TENSOR_BASE = CCODE / "simpleconv2dkernel.cc"
GEMM_BASE = pathlib.Path(__file__).resolve().parent / "gemm_kernel_port.cc"
SPACE_BASE = CCODE / "simpleconv2dkernel_space.cc"
LOAD_T = "aie::load_buffer(x_t, {oh0 * S - P, ow0 * S - P, 0}, {IH_T, IW_T, C}"
LOAD_X = "const int8_t *x = aie::load_buffer(win_a, {oh0 * S, ow0 * S, 0}, {ih_t, iw_t, C});"

# (name, [(old, new), ...], expected substring in the output; None = must pass,
#  "PASS:text" = must pass and print text)
CASES = [
    ("baseline", [], None),
    # A slab one row taller than the conv footprint is still an affine block
    # walk inside the tensor: the routing follows the kernel (20-row halo slabs).
    ("load bigger than the footprint (routed as is)",
     [(LOAD_X, LOAD_X.replace("{ih_t, iw_t, C}", "{ih_t + 1, iw_t, C}"))],
     None),
    # A slab narrower than the conv footprint makes the compute read past it:
    # caught first as data used without being loaded (at the exact line).
    ("load too small",
     [(LOAD_X, LOAD_X.replace("{ih_t, iw_t, C}", "{ih_t, iw_t - 2, C}"))],
     "data used without being loaded"),
    ("weights offset out of the tensor (pid_c * oc_t * 20)",
     [("{pid_c * oc_t, 0, 0, 0}", "{pid_c * oc_t * 20, 0, 0, 0}")],
     "outside the tensor extent 64"),
    ("data used without load (reads past the block)",
     [("const int8_t *r = x + (oh * S + kh) * ROW;", "const int8_t *r = x + (oh * S + kh + 1) * ROW;")],
     "data used without being loaded"),
    ("data used after release",
     [("            int8_t *y = aie::store_buffer(", "            aie::release(win_a);\n            int8_t *y = aie::store_buffer("),
      ("            aie::release(win_a);\n            aie::commit(win_c);", "            aie::commit(win_c);")],
     "uses a block after aie::release"),
    ("output never committed",
     [("            aie::commit(win_c);\n", "")],
     "never committed"),
    ("loop order swapped (j outer)",
     [("for (int i = 0; i < oh_core / oh_t; i++) {", "@OUTER@"),
      ("for (int j = 0; j < 112 / ow_t; j++) {", "for (int i = 0; i < oh_core / oh_t; i++) {"),
      ("@OUTER@", "for (int j = 0; j < 112 / ow_t; j++) {")],
     "swap the two loops"),
    # The harness runs the kernel body: an endless loop (the condition tests the
    # wrong variable) used to hang aiehlc forever; now a bounded run reports it.
    # run_case sets AIEHLC_TRACE_TIMEOUT=3 for cases named "endless loop...".
    ("endless loop in the kernel body (trace time limit)",
     [(LOAD_X, LOAD_X + "\n            for (int k = 0; i < 16; k++) { volatile int z = k; (void)z; }")],
     "the kernel did not finish within 3 s"),
    ("schedule depends on data",
     [("            aie::release(win_a);\n", "            if (x[0] > 0) { aie::release(win_a); x = aie::load_buffer(win_a, {oh0 * S, ow0 * S, 0}, {ih_t, iw_t, C}); }\n            aie::release(win_a);\n")],
     "depends on the data"),
    ("output not fully written",
     [("for (int j = 0; j < 112 / ow_t; j++) {", "for (int j = 0; j < 112 / ow_t - 1; j++) {")],
     "never stored"),
    ("weights never loaded",
     [("    const int8_t *w = aie::load_buffer(win_b, {pid_c * oc_t, 0, 0, 0}, {oc_t, KH, KW, C});",
       "    static int8_t w[16 * 196];"),
      ("    aie::release(win_b);\n", "")],
     "is never loaded"),
    # A port's `>` missing: the whole parameter list used to read as one
    # unrecognizable "GemmSpace" port; the error now names the port and line.
    ("aie::port missing its closing >",
     [("aie::shape<230, 230, 4>> win_a", "aie::shape<230, 230, 4> win_a")],
     "line 7: `aie::port<input_window_int8 *, aie::IFM, aie::shape<230, 230, 4> win_a,` -- the `<` of aie::port is never closed"),
    # A declaration the blocks cannot fit at any offset: the hint names the
    # port's aie::shape (and what the blocks span), not just each core.
    ("weights port declared with the input's shape (hint: check its aie::shape)",
     [("aie::shape<64, 7, 7, 4>> win_b", "aie::shape<230, 230, 4>> win_b")],
     "case.cc:8: win_b: hint: the kernel's blocks are 4-D, spanning (64,7,7,4), which no offset fits into the "
     "declared `aie::shape<230,230,4>` -- check this port's aie::shape (the blocks suggest aie::shape<64,7,7,4>)"),
    ("output port declared with too few channels (hint: check its aie::shape)",
     [("aie::shape<112, 112, 64>> win_c", "aie::shape<112, 112, 4>> win_c")],
     "(the blocks suggest aie::shape<112,112,64>) and its role (OFM); e.g. line 44 in "
     "`aie::store_buffer(win_c, {oh0, ow0, pid_c * oc_t}, {oh_t, ow_t, oc_t})` on core (0,0) takes 16 in dim 2"),
    ("load offset with an extra coordinate (hint: the call, not the port)",
     [(LOAD_X, LOAD_X.replace("{oh0 * S, ow0 * S, 0}", "{oh0 * S, ow0 * S, 0, 0}"))],
     "case.cc:43: win_a: hint: `aie::load_buffer(win_a, {oh0 * S, ow0 * S, 0, 0}, {ih_t, iw_t, C})` "
     "passes an offset of 4 and a block shape of 3 coordinates -- the offset has an extra coordinate"),
    # Harness errors name the failing call's line; a block never handed back
    # names the call that took it.
    ("never released: the error names the load that took the block",
     [("    aie::release(win_b);\n", "")],
     "case.cc:22: win_b block 1 on core (0,0): 1 block(s) still held at kernel end: never released"),
    ("store on an input port",
     [("int8_t *y = aie::store_buffer(win_c,", "int8_t *y = aie::store_buffer(win_a,")],
     "case.cc:44: win_a block 1 on core (0,0): aie::store_buffer on an input port"),
    # Vector kernel (aie::mmul, emulated by aie_api_x86emu.h in the trace).
    ("vector: last K-block not shifted back (64-byte load runs past the row)",
     [("const int off = kb < 3 ? kb * 8 : 20;", "const int off = kb * 8;")],
     "data used without being loaded"),
    ("vector: aligned 64-byte load on a 32-byte aligned window",
     [("aie::load_unaligned_v<64>(r + owA * 8 + off, 4)", "aie::load_v<64>(r + owA * 8 + off)")],
     "needs a 64-byte aligned address (DMA windows are only 32-byte aligned"),
    # Static bounds analysis (kernel_static.cpp): the block is sized by oc_t
    # but the compute walks 16 output channels whatever oc_t is -- the trace
    # names the line, the static analysis the constant and the fix, and the
    # OFM store the trace never reached (it stops at the first fault).
    ("weights block narrower than the compute (oc_t = 15): the cause",
     [("oc_t = 16;", "oc_t = 15;")],
     "cause (static analysis): `oc_t = 15` (case.cc:12) sizes the block of the access at line 33, whose index never "
     "reads oc_t -- with oc_t = 16 every analysed block access fits"),
    ("weights block narrower than the compute (oc_t = 15): the store the trace did not reach",
     [("oc_t = 16;", "oc_t = 15;")],
     "out-of-block access (static analysis) at case.cc:78: `aie::store_v(o + 96, z.second.extract<32>(1))`"),
    # Cross-check: the trace faults on a line the static analysis cannot explain.
    ("cross-check: the index reads data (static analysis cannot explain it)",
     [("live ? w[(nb * 8 + n) * TAPS + kh * KW * C + byte] : (int8_t)0;",
       "live ? w[(nb * 8 + n) * TAPS + kh * KW * C + byte + Bp[0] * 0 + 3136] : (int8_t)0;")],
     "static analysis: cannot explain line 33: `w[(nb * 8 + n) * TAPS + kh * KW * C + byte + Bp[0] * 0 + 3136]`: "
     "`Bp[...]` is not a const array with an initializer"),
    # ... and on a line it evaluated as in bounds: `w` moved through an alias
    # the model does not follow -- it must say so, not stay silent.
    ("cross-check: an alias moves the block pointer (static analysis disagrees)",
     [("    alignas(64) int8_t Bp[7 * 4 * 2 * 64];",
       "    const int8_t **pw = &w;\n    *pw += 2940;\n    alignas(64) int8_t Bp[7 * 4 * 2 * 64];")],
     "static analysis DISAGREES: it evaluated `w[(nb * 8 + n) * TAPS + kh * KW * C + byte]` at line 35"),
    ("block larger than core memory",
     [(LOAD_X, LOAD_X.replace("{oh0 * S, ow0 * S, 0}, {ih_t, iw_t, C}", "{0, 0, 0}, {230, 230, 4}"))],
     "larger than the core data memory"),
]

# The tensor form; with aie::autotune every candidate must be rejected, and the
# default's diagnostics are reported.
TENSOR_CASES = [
    ("tensor: baseline (autotuned)", [], None),
    ("tensor: conv border loaded without .pad",
     [(", {.pad = aie::pad_value::zero});", ");")],
     "outside the tensor extent 224 (a conv border? load it with {.pad = aie::pad_value::zero})"),
    ("tensor: wrong .reuse",
     [("{.reuse = OH_CORE / OH_T * Ofm::dim(1) / OW_T}", "{.reuse = OH_CORE / OH_T}")],
     "load_buffer says {.reuse = 4}, but 16 output block(s) are stored while it is held"),
    ("tensor: load bigger than the footprint (routed as is)",
     [(LOAD_T, LOAD_T.replace("{IH_T, IW_T, C}", "{IH_T + 1, IW_T, C}"))],
     None),
    ("tensor: data used without load (reads past the block)",
     [("x(oh * S + kh, ow * S + kw, c)", "x(oh * S + kh + 1, ow * S + kw, c)")],
     "data used without being loaded"),
    ("tensor: data used after release",
     [("auto y = aie::store_buffer(", "aie::release(x_t);\n            auto y = aie::store_buffer(")],
     "uses a block after aie::release"),
    # A block of 2 of the 3 channels (compute uses only those): the staged
    # layout aligns channels to 4, so blocks must take them all.
    ("tensor: part of the channels",
     [(LOAD_T, LOAD_T.replace("{IH_T, IW_T, C}", "{IH_T, IW_T, C - 1}")),
      ("for (int c = 0; c < C; c++)", "for (int c = 0; c < C - 1; c++)")],
     "blocks take part of the channel dim (C = 3)"),
    ("tensor: weights outside the tensor",
     [("{pc * OC_T, 0, 0, 0}", "{pc * OC_T + 1, 0, 0, 0}")],
     "outside the tensor extent 64"),
    ("tensor: output not fully written",
     [("for (int j = 0; j < Ofm::dim(1) / OW_T; j++)", "for (int j = 1; j < Ofm::dim(1) / OW_T; j++)"),
      ("Ofm::dim(1) / OW_T})", "(Ofm::dim(1) / OW_T - 1)})")],
     "never stored"),
    ("tensor: loop order swapped",
     [("for (int i = 0; i < OH_CORE / OH_T; i++)", "@OUTER@"),
      ("for (int j = 0; j < Ofm::dim(1) / OW_T; j++)", "for (int i = 0; i < OH_CORE / OH_T; i++)"),
      ("@OUTER@", "for (int j = 0; j < Ofm::dim(1) / OW_T; j++)"),
      # pinned: with one row round (OH_T=28) the swapped order is harmless
      ("conv2d<<<mesh>>>", "conv2d<7, 28, 16><<<mesh>>>")],
     "swap the two loops"),
]

# Kernel-only GEMM: routed with no operator recognition (trace_routing.h).
LOAD_B = "aie::load_buffer(b, {pn * 16, j * 64}, {16, 64})"
GEMM_CASES = [
    ("gemm: baseline (routed)", [], None),
    ("gemm: role tags omitted (aie::port<T, aie::shape<...>>)",
     [("aie::IFM, ", ""), ("aie::WEIGHTS, ", ""), ("aie::OFM, ", "")],
     None),
    ("gemm: .tile on a K-chunk block (not whole rows: the DMA would ignore it)",
     [("const int8_t *x = aie::load_buffer(a, {pm * 16, j * 64}, {16, 64});",
       "const int8_t *x = aie::load_buffer(a, {pm * 16, j * 64}, {16, 64}, {.tile = {8, 8}});")],
     "need blocks that are whole rows of the tensor"),
    ("gemm: input block unique per core",
     [(LOAD_B, "aie::load_buffer(b, {pn * 16, pm * 64}, {16, 64})")],
     "unique per core"),
    # example/other/aiehlcpm_gemm1.cc: the mesh macros come from an <angle>
    # include, which used to be skipped -> "no device.partition(...) found".
    ("gemm: mesh ROWS/COLS from an #include <header> macro",
     [('#include "simpleconv2d_new_load.h"', "#include <simplegemm_load.h>"),
      ("device.partition({3, 6, 0, 6}, 4, 4)", "device.partition({3, 6, 0, 6}, HW_ROWS, HW_COLS)")],
     None),
    ("gemm: mesh ROWS is an undefined macro",
     [("device.partition({3, 6, 0, 6}, 4, 4)", "device.partition({3, 6, 0, 6}, MY_ROWS, 4)")],
     "ROWS `MY_ROWS` is not an integer constant expression -- no `#define MY_ROWS`"),
    ("gemm: window passed by value",
     [("aie::port<input_window_int8 *, aie::IFM", "aie::port<input_window_int8, aie::IFM")],
     "port a: the window type must be a pointer"),
]


# Dataflow options on a kernel-only GEMM (simplegemm_dataflow.cc): each one
# must be something the DMA can do for that port's blocks.
DATAFLOW_BASE = CCODE / "simplegemm_dataflow.cc"
OPT_A = "{.depth = 2, .tile = {8, 8}}"
DATAFLOW_CASES = [
    ("dataflow: baseline (.resident / .depth / .tile)", [], None),
    ("dataflow: no options (still a legal DMA; the compute would then read row-major A)",
     [(", " + OPT_A, ""), ("{cn, GD_K}, {.resident = true}", "{cn, GD_K}")],
     None),
    ("dataflow: .depth = 1 on a 32-strip input (single buffer, re-armed)",
     [(OPT_A, "{.depth = 1, .tile = {8, 8}}")],
     None),
    ("dataflow: .resident on a port loaded every round",
     [(OPT_A, "{.resident = true, .tile = {8, 8}}")],
     "a resident block is loaded once"),
    ("dataflow: .resident with .depth = 2",
     [("{cn, GD_K}, {.resident = true}", "{cn, GD_K}, {.depth = 2, .resident = true}")],
     "contradicts it"),
    ("dataflow: .depth out of range", [(OPT_A, "{.depth = 3, .tile = {8, 8}}")], "single (1) or ping-pong (2)"),
    ("dataflow: .tile that does not divide the block", [(OPT_A, "{.depth = 2, .tile = {8, 7}}")],
     "does not divide the block (16,256)"),
    ("dataflow: .tile row below a 32-bit word", [(OPT_A, "{.depth = 2, .tile = {8, 2}}")],
     "must be multiples of 4 bytes"),
    ("dataflow: .depth = 1 on a store (gemm90 M3.3.2: one core buffer, one self-chained core MM2S BD)",
     [("{GD_TS, cn});", "{GD_TS, cn}, {.depth = 1});")],
     None),
    ("dataflow: .tile on a store",
     [("{GD_TS, cn});", "{GD_TS, cn}, {.tile = {8, 8}});")],
     "aie::store_buffer takes only {.depth}"),
]

# The same options on the spatial-halo conv (simpleconv2dkernel_port_opts.cc).
CONVOPTS_BASE = CCODE / "simpleconv2dkernel_port_opts.cc"
CONVOPTS_CASES = [
    ("convopts: baseline (.resident weights, .depth = 2 slab / output)", [], None),
    ("convopts: .depth = 1 on the halo slab",
     [("{ih_t, iw_t, C}, {.depth = 2}", "{ih_t, iw_t, C}, {.depth = 1}")],
     "is not supported on a spatial-halo (conv) kernel yet"),
    # A MemTile ring streams the operand chunk by chunk along its reduction dim (a FIFO of .ring buffers,
    # refilled every launch): nothing stays in the MemTile, so .keep cannot hold it across launches.
    ("convopts: .keep on a MemTile ring (a ring is refilled every launch)",
     [("{ih_t, iw_t, C}, {.depth = 2}",
       "{ih_t, iw_t, C}, {.depth = 2, .share = aie::share::neighbor, .stage = aie::stage::memtile_ring, "
       ".ring = 4, .keep = true}")],
     "a MemTile ring is refilled every launch: it cannot be {.keep = true}"),
]

# bfloat16 ports (simpleconv2dkernel_port_bf16.cc): 2-byte blocks through the
# trace (elemBytesOf), the x86 `bfloat16` (aie_api_x86emu.h) and the conv
# cross-check with the ports' element size.
BF16_BASE = CCODE / "simpleconv2dkernel_port_bf16.cc"
BF16_CASES = [
    ("bf16: baseline (bf16 in / out, fp32 accumulate)", [], None),
    ("bf16: data used past the bf16 block (an int8-sized index)",
     [("(float)x[((oh * S + kh) * iw_t + ow * S + kw) * C + c]",
       "(float)x[((oh * S + kh) * iw_t + ow * S + kw) * C + c + 2 * iw_t * C]")],
     "data used without being loaded"),
]

# Hand-written GemmSpaces + block loads (verifySpaceKernels): each side may be
# wrong, and the conflict names the GemmSpace field.
SLICE = ".slice_tiling = {.tile_size = 19, .stride = 14, .rounds = 4}"
OFM_D3 = "    .d3 = {.fullsize = 64, .tile_round = 4, .tile_size = 16}};"
SPACE_CASES = [
    ("space: baseline (GemmSpaces match the blocks)", [], None),
    ("space: GemmSpace slab step wrong",
     [(SLICE, SLICE.replace(".stride = 14", ".stride = 13"))],
     "win_a (GemmSpace RowBC_halo) .d1.slice_tiling.stride = 13, the kernel's blocks give 14"),
    ("space: GemmSpace splits the weights over 2 mesh cols",
     [(".d1 = {.fullsize = 64, .tile_round = 4, .tile_size = 16, .stride = 16},",
       ".d1 = {.fullsize = 64, .tile_round = 2, .tile_size = 32, .stride = 32},")],
     "win_b (GemmSpace ColBC) .d1.tile_round = 2, the kernel's blocks give 4"),
    ("space: kernel changed (14-row output blocks), GemmSpace not",
     [("const int oh_t = 7,", "const int oh_t = 14,")],
     "win_c (GemmSpace LtoR_Merge) .d1.slice_tiling.tile_size = 7, the kernel's blocks give 14"),
    ("space: input broadcast along the wrong mesh axis",
     [(".map = {.act = aie::Pattern::Broadcast, .layout = aie::Layout::Row}",
       ".map = {.act = aie::Pattern::Broadcast, .layout = aie::Layout::Col}")],
     ".policy.map.layout = Col, the kernel's blocks give Row"),
    ("space: GemmSpace missing a dim the kernel blocks have",
     [(OFM_D3, "};")],
     "offset has 3 and shape 3 dims, but the tensor has 2"),
    ("space: scheduling fields are the user's (pp_depth 1, l1_budget 8 KB)",
     [(".sched = {.pp_depth = 2, .l1_budget = aie::Bytes{4096}}}",  # the first: RowBC_halo
       ".sched = {.pp_depth = 1, .l1_budget = aie::Bytes{8192}}}")],
     None),
    ("space: GEMM-form field", [(OFM_D3, OFM_D3[:-2] + ",\n    .m = {.fullsize = 112}};")],
     "uses .m (the GEMM form)"),
    ("space: unknown field", [(SLICE, SLICE[:-1] + ", .win = 7}")], "unknown field .d1.slice_tiling.win"),
    ("space: undefined GemmSpace",
     [("aie::port<input_window_int8 *, ColBC> win_b", "aie::port<input_window_int8 *, ColBX> win_b")],
     "no `constexpr aie::GemmSpace ColBX"),
]


# C++ templates on a __global__: the aiednn library kernel src/aiednn/gemm/gemm_kacc_kernel.cc (the one
# gemm_kacc every network build instantiates), wrapped in TEMPLATE_HEAD / TEMPLATE_HOST (one launch); the launch
# `gemm_kacc<...><<<mesh>>>` picks the instance. The arguments are aiednn.gemm_kacc_targs(64, 576, 256, kacc_geom).
TEMPLATE_BASE = REPO / "src" / "aiednn" / "gemm" / "gemm_kacc_kernel.cc"
TEMPLATE_HEAD = """#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define GCH 64
#define GPX 256

"""
TARGS = "64, 576, 256, 288, 64, 256, 16, 32, 18, 1, 4, 0"
TARGS2 = "128, 576, 256, 288, 128, 256, 16, 32, 18, 2, 4, 0"   # (ch, K, px) = (128, 576, 256)
TLAUNCH = "gemm_kacc<" + TARGS + "><<<mesh>>>"
TEMPLATE_HOST = """

static void gemm_kacc_run(int32_t *w, int32_t *x, int32_t *y) {
    aieSetDevice(0);
    aieArray device;
    aieMesh mesh = device.partition({2, 6, 0, 6}, 4, 4);
    """ + TLAUNCH + """(w, x, y);
}

int main() {
    int32_t *Wd = (int32_t *)__Runtime_Alloc(128 * 576 * 2);
    int32_t *Xd = (int32_t *)__Runtime_Alloc(256 * 576 * 2);
    int32_t *Yd = (int32_t *)__Runtime_Alloc(128 * 256 * 4);
    gemm_kacc_run(Wd, Xd, Yd);
    printf("gemm_kacc done\\n");
    return 0;
}
"""
TPARAMS = "int NT, int S, bool TR>"
TEMPLATE_CASES = [
    ("template: baseline (one instance, keeps its name)", [],
     "PASS:instance gemm_kacc<" + TARGS + "> -> gemm_kacc"),
    ("template: trailing arguments from the defaults (TR = false)",
     [(TPARAMS, "int NT, int S, bool TR = false>"), (TLAUNCH, "gemm_kacc<" + TARGS[:-3] + "><<<mesh>>>")],
     "PASS:instance gemm_kacc<" + TARGS + "> -> gemm_kacc"),
    ("template: arguments are expressions over #defines",
     [(TLAUNCH, "gemm_kacc<GCH, 576, GPX, 576 / 2, GCH, GPX, 4 * 4, 32, 18, 1, GPX / GCH, false><<<mesh>>>")],
     "PASS:instance gemm_kacc<" + TARGS + "> -> gemm_kacc"),
    ("template: two instances in one file (same ports, a's shape <AROWS, KW>) -> per-instance block descriptors",
     [(TLAUNCH + "(w, x, y);", "gemm_kacc<" + TARGS2 + "><<<mesh>>>(w, x, y);\n    " + TLAUNCH + "(w, x, y);")],
     "PASS:static const aiehlc_blk_desc aiehlc_desc_gemm_kacc__128_576_256_288_128_256_16_32_18_2_4_0_a_port"),
    ("template: an instance the kernel cannot cover (NT = 2 tiles of 16 rows per core on a 64-row a port)",
     [(TLAUNCH, "gemm_kacc<64, 576, 256, 288, 64, 256, 16, 32, 18, 2, 4, 0><<<mesh>>>")],
     "ERROR"),
    ("template: never launched",
     [(TLAUNCH, "gemm_kacc_typo<" + TARGS + "><<<mesh>>>")],
     "is never launched as gemm_kacc<...><<<mesh>>>(...): nothing to instantiate"),
    ("template: launched without template arguments",
     [(TLAUNCH, "gemm_kacc<<<mesh>>>")],
     "launched without template arguments"),
    ("template: too many arguments",
     [(TLAUNCH, "gemm_kacc<" + TARGS + ", 1><<<mesh>>>")],
     "13 template arguments, the kernel has 12"),
    ("template: no argument and no default",
     [(TLAUNCH, "gemm_kacc<64, 576><<<mesh>>>")],
     "no argument and no default for template parameter PX"),
]

# The dataflow-plan GEMM (example/tileprogram/ccode/gemm_plan/): a config file that #includes gemm_plan.cc
# (which #includes gemm_plan_body.cc) -- run_case inlines the local .cc includes, `trace` reads one file.
# (HG) cases: a BD over its tile's length limit (MemTile: 0x1FFFF words, plantarget.h) -- the s1i8 shape
# (4096 x 512 x 4096 int8) stages a mesh column's B (128 x 4096 int8 = 512 KiB = 0x20000 words) in its
# MemTile with {.stage = aie::stage::memtile}: one BD would be truncated (0x20000 & 0x1FFFF = 0), the plan
# loads it as a next_bd chain (dfplan::splitBdLen).
GEMMPLAN_BASE = CCODE / "gemm_plan" / "gemm_plan_4096x512x4096_int8.cc"
GEMMPLAN_CASES = [
    ("gemm_plan s1i8: resident MemTile B stage 0x20000 words, over a MemTile BD's 0x1FFFF -> 2 chained BDs (HG)",
     [],
     "PASS:the dataflow plan loads it as 2 chained MemTile BDs"),
    # m3362124221 P2: #pragma dataflow_slices(S, arg, ...) -- the plan runs 4096^3 as 8 N-slices of this shape: each
    # call rebases the shim BDs of B (arg 1, by its 2 MiB tensor) and C (arg 2, by its 512 B column block, row-major
    # ldc 4096 B); a bad argument is refused.
    ("dataflow: slices=8 emits 2 shim rebases per slice (B by its tensor, C row-major ldc 4096)",
     [("#define GP_M 4096", "#pragma dataflow_slices(8, 1, 2)\n#define GP_KEEP false\n#define GP_M 4096")],
     "PASS:slices=8 emits 2 shim rebases per slice: b (arg 1) +2097152 B per slice, c (arg 2) +512 B per slice, "
     "row-major ldc 4096 B"),
    ("dataflow: slices over a non-port argument is refused",
     [("#define GP_M 4096", "#pragma dataflow_slices(8, 1, 5)\n#define GP_M 4096")],
     "#pragma dataflow_slices: argument 5 is not a distinct kernel port (3 ports)"),
    # m3362124221 P2b (PD: launch 1 call 2 hung, MemTile B S2MM lock-acquire stall): a sliced MemTile-staged input
    # is refilled every call, so its (ready, free) lock pair is re-armed per call (not "restored" once); kept
    # across launches (.keep) it would serve slice 0 to every slice and is refused.
    ("dataflow: slices=8 re-arms the sliced MemTile B stage's locks every call",
     [("#define GP_M 4096", "#pragma dataflow_slices(8, 1, 2)\n#define GP_KEEP false\n#define GP_M 4096")],
     "PASS:b: MemTile stage refilled every call, its (ready, free) locks re-armed per call"),
    ("dataflow: slices over a MemTile B kept across launches is refused",
     [("#define GP_M 4096", "#pragma dataflow_slices(8, 1, 2)\n#define GP_KEEP true\n#define GP_M 4096")],
     "is held in the MemTiles across launches ({.keep = true}) but rebased every call"),
]
# M3.3.6.2.1.2.3.1 XT: the tile knobs (gemm_plan_tbody.cc GP_TM / GP_TN / GP_KC / GP_C_DEPTH / GP_DM_FIXED) on the
# >= 88 neighbour-shared tile (gemm_plan_s64t_int8.cc: 12288 x 768 x 2048 int8, 96 x 96, 6 x 6 accumulator pairs).
GEMMPLAN_T_BASE = CCODE / "gemm_plan" / "gemm_plan_s64t_int8.cc"
GEMMPLAN_T_KC = "#define GP_KC 8\n#define GP_C_DEPTH 2"
GEMMPLAN_T_CASES = [
    ("gemm_plan tile 96x96 kc8 depth2: 32x2 output tiles/core, every block matches the DMA", [],
     "PASS:c (OFM, gather, 32x2 blocks/core): d1[12288]=rows/4@3072+i32x96@96 d2[768]=cols/4@192+j2x96@96"),
    # M3.3.6.2.1.2.4.1 PV (fix96_inner): {.depth = 1} on aie::store_buffer accepted (015dbd32 cherry-picked; was
    # "an output window is always ping-pong" on 71129420), and the GT_CHUNK_P kernels (GP_GT 1 / 2) route the same blocks.
    ("gemm_plan tile 96x96 kc32 depth1 (FEAS_PICK): {.depth = 1} on the output store is accepted",
     [(GEMMPLAN_T_KC, "#define GP_KC 32\n#define GP_C_DEPTH 1")],
     "PASS:OK: every load_buffer / store_buffer matches the DMA"),
    ("gemm_plan tile 96x96 kc32 depth1 GT_CHUNK_P (GP_GT 1): every block matches the DMA",
     [(GEMMPLAN_T_KC, "#define GP_KC 32\n#define GP_C_DEPTH 1\n#define GP_GT 1")],
     "PASS:OK: every load_buffer / store_buffer matches the DMA"),
    # M3.3.6.2.1.2.3.2 PX: the CORE1 stats block (GP_CORE1, default 0). Off: the same blocks as aa587c9f (the line of
    # the kc8 depth2 case above); on: the lock-wait timing touches only blocks load_buffer / store_buffer returned;
    # (the #error without -DGP_PEAK / the int8-peak static_assert are compile-time: `trace` does not stop on them,
    # they are checked with the compiler in the PX log, maxwell/tasks/gemm90/logs/m33621232_px_err.txt).
    ("gemm_plan core1 off == aa587c9f: GP_CORE1 0 routes the same blocks",
     [(GEMMPLAN_T_KC, GEMMPLAN_T_KC + "\n#define GP_CORE1 0")],
     "PASS:c (OFM, gather, 32x2 blocks/core): d1[12288]=rows/4@3072+i32x96@96 d2[768]=cols/4@192+j2x96@96"),
    ("gemm_plan core1 on (GP_PEAK int8 498.37): the stats timing adds no block access",
     [(GEMMPLAN_T_KC, GEMMPLAN_T_KC + "\n#define GP_CORE1 1\n#define GP_PEAK 498.37")],
     "PASS:c (OFM, gather, 32x2 blocks/core): d1[12288]=rows/4@3072+i32x96@96 d2[768]=cols/4@192+j2x96@96"),
]

# M3.3.6.2.1.2.4.1 PV: x86 numerics of the fix96_inner chunk kernels (gemm_plan_gt.h GT_CHUNK_P / _P2 / _K) against
# GT_CHUNK and a scalar int32 reference, on the aie_api_x86emu.h emulation (96 x 96 tile, 4 chunks of KC 32 / 8).
GT_NUM_BASE = CCODE / "gemm_plan" / "gemm_plan_tile.h"
GT_NUM_SRC = r"""
#include AIEHLC_EMU_HEADER
#include "gemm_plan_tile.h"
#include "gemm_plan_gt.h"
typedef aie::mmul<8, 8, 8, int8_t, int8_t> KaMM4;
#define NK 4
#define NB (KA_TM / 8)
alignas(64) static int8_t A[NK][KA_TM * KA_KC], B[NK][KA_TN * KA_KC];
alignas(64) static int32_t accG[NB][8 * KA_TN], accP[NB][8 * KA_TN], accD[NB][8 * KA_TN], accK[NB][8 * KA_TN], accE[NB][8 * KA_TN];
alignas(64) static int8_t yG[KA_TM * KA_TN], yP[KA_TM * KA_TN], yD[KA_TM * KA_TN], yK[KA_TM * KA_TN], yE[KA_TM * KA_TN];
static int32_t ref[KA_TM][KA_TN];
static int opA(int k, int m, int kk) { /* row m, k index kk (within chunk k) in GT_OP order */
    const int r = m / 8, kb = kk / 8, T = KA_TM;
    const int8_t *p = A[k] + (r / (T / 16) ? T / 2 * KA_KC : 0) + ((r % (T / 16)) * (KA_KC / 8) + kb) * 64;
    return p[(m % 8) * 8 + kk % 8];
}
static int opB(int k, int n, int kk) {
    const int r = n / 8, kb = kk / 8, T = KA_TN;
    const int8_t *p = B[k] + (r / (T / 16) ? T / 2 * KA_KC : 0) + ((r % (T / 16)) * (KA_KC / 8) + kb) * 64;
    return p[(kk % 8) * 8 + n % 8];
}
int main() {
    unsigned s = 12345;
    for (int k = 0; k < NK; k++) {
        for (int i = 0; i < KA_TM * KA_KC; i++) A[k][i] = (int8_t)((s = s * 1103515245u + 12345u) >> 16);
        for (int i = 0; i < KA_TN * KA_KC; i++) B[k][i] = (int8_t)((s = s * 1103515245u + 12345u) >> 16);
    }
    for (int m = 0; m < KA_TM; m++)
        for (int n = 0; n < KA_TN; n++) {
            int32_t t = 0;
            for (int k = 0; k < NK; k++)
                for (int kk = 0; kk < KA_KC; kk++) t += opA(k, m, kk) * opB(k, n, kk);
            ref[m][n] = t;
        }
    int32_t *fG[NB], *fP[NB], *fD[NB], *fK[NB], *fE[NB];
    for (int i = 0; i < NB; i++) fG[i] = accG[i], fP[i] = accP[i], fD[i] = accD[i], fK[i] = accK[i], fE[i] = accE[i];
    long bad_i32 = 0, bad_y = 0;
    for (int pass = 0; pass < 2; pass++) { /* pass 0: int32 partial sums (no last chunk); pass 1: int8 out */
        for (int k = 0; k < NK; k++) {
            const int8_t *a0 = A[k], *a1 = A[k] + KA_TM / 2 * KA_KC, *b0 = B[k], *b1 = B[k] + KA_TN / 2 * KA_KC;
            const bool last = pass == 1 && k == NK - 1;
            GT_CHUNK(fG, yG, 0, a0, a1, b0, b1, k == 0, last, 0, NB);
            if (k == 0) { GT_CHUNK_P(fP, yP, 0, a0, a1, b0, b1, 1, 0, 0, NB) }
            else if (last) { GT_CHUNK_P(fP, yP, 0, a0, a1, b0, b1, 0, 1, 0, NB) }
            else { GT_CHUNK_P(fP, yP, 0, a0, a1, b0, b1, 0, 0, 0, NB) }
            if (k == 0) GT_CHUNK_K(fK, yK, 0, a0, a1, b0, b1, a0, a1, b0, b1, 1, 0, 0, NB, 1)
            else if (last) GT_CHUNK_K(fK, yK, 0, a0, a1, b0, b1, a0, a1, b0, b1, 0, 1, 0, NB, 1)
            else GT_CHUNK_K(fK, yK, 0, a0, a1, b0, b1, a0, a1, b0, b1, 0, 0, 0, NB, 1)
            if (k % 2 == 1) {
                const int8_t *q0 = A[k - 1], *q1 = A[k - 1] + KA_TM / 2 * KA_KC, *r0 = B[k - 1], *r1 = B[k - 1] + KA_TN / 2 * KA_KC;
                if (k == 1) { GT_CHUNK_P2(fD, yD, 0, q0, q1, r0, r1, a0, a1, b0, b1, 1, 0, 0, NB, 2) }
                else if (last) { GT_CHUNK_P2(fD, yD, 0, q0, q1, r0, r1, a0, a1, b0, b1, 0, 1, 0, NB, 2) }
                else { GT_CHUNK_P2(fD, yD, 0, q0, q1, r0, r1, a0, a1, b0, b1, 0, 0, 0, NB, 2) }
                if (k == 1) GT_CHUNK_K(fE, yE, 0, q0, q1, r0, r1, a0, a1, b0, b1, 1, 0, 0, NB, 2)
                else if (last) GT_CHUNK_K(fE, yE, 0, q0, q1, r0, r1, a0, a1, b0, b1, 0, 1, 0, NB, 2)
                else GT_CHUNK_K(fE, yE, 0, q0, q1, r0, r1, a0, a1, b0, b1, 0, 0, 0, NB, 2)
            }
        }
        if (pass == 0)
            for (int m = 0; m < KA_TM; m++)
                for (int n = 0; n < KA_TN; n++) {
                    const int idx = (n / 8) * 64 + (m % 8) * 8 + n % 8;
                    const int32_t g = accG[m / 8][idx], p = accP[m / 8][idx], d = accD[m / 8][idx];
                    const int32_t kk = accK[m / 8][idx], e = accE[m / 8][idx];
                    bad_i32 += (g != ref[m][n]) + (p != ref[m][n]) + (d != ref[m][n]) + (kk != ref[m][n]) + (e != ref[m][n]);
                }
    }
    for (int i = 0; i < KA_TM * KA_TN; i++) bad_y += (yP[i] != yG[i]) + (yD[i] != yG[i]) + (yK[i] != yG[i]) + (yE[i] != yG[i]);
    std::printf("GTNUM tile=%dx%d kc=%d chunks=%d bad_i32=%ld bad_y=%ld\n", KA_TM, KA_TN, KA_KC, NK, bad_i32, bad_y);
    return bad_i32 || bad_y;
}
"""
GT_NUM_CASES = [
    ("gt_chunk_p numerics 96x96 kc32: GT_CHUNK_P / _P2 / _K (ns 1, 2) == GT_CHUNK == scalar int32 (x86 emu)",
     [("96", "96"), ("32", "32")], "PASS:GTNUM tile=96x96 kc=32 chunks=4 bad_i32=0 bad_y=0"),
    ("gt_chunk_p numerics 96x64 kc64: GT_CHUNK_P / _P2 / _K (ns 1, 2) == GT_CHUNK == scalar int32 (x86 emu)",
     [("96", "64"), ("64", "64")], "PASS:GTNUM tile=96x64 kc=64 chunks=4 bad_i32=0 bad_y=0"),
]


# gemm90 m3362124222211 PI: #pragma dataflow_slices pre-queue (SlicePrequeuePass, sliceprequeue_plan.h). A 2-call
# sliced stub of the 4096^3 host function -- A (unsliced, shim ch1 BD15) and B (sliced, ch0 BD14) on columns 1-4,
# C on columns 3-4 (S2MM ch0 BD2-5 / ch1 BD7-10, BDs 2..13 used) -- is planned with the pass's own rules and replayed
# call by call with the runtime's own / alt BD choice. Green: call 0 pushes A/B on BD 0/1 before its first wait,
# the first startios are B, C, A, <= 2 tasks per shim channel, a pre-queue never targets the in-flight BD, and
# call 1 pushes no input of its own. Red (no planner): call 0's first wait comes with no BD 0/1 startio before it.
PQ_PLAN_H = (REPO / "src" / "mlir" / "mlirfront" / "tilinglinalg" / "pass" / "passstartiointerleave" /
             "sliceprequeue_plan.h")
PQ_BASE = PQ_PLAN_H.parent / "__pq_stub__"
PQ_SRC = r"""
#include <cstdio>
#include <map>
#include <set>
#include <string>
#include <vector>
#if __has_include("sliceprequeue_plan.h")
#include "sliceprequeue_plan.h"
#define PQ_HAVE 1
#else
#define PQ_HAVE 0
#endif
struct E { int call; std::string kind; char arg; int col, ch, bd; };
int main() {
    struct S { char arg; int col, ch, bd, dir; bool sliced; int repeat; };
    std::vector<S> ss;
    for (int c = 1; c <= 4; c++) ss.push_back({'A', c, 1, 15, 0, false, 32});
    for (int c = 1; c <= 4; c++) ss.push_back({'B', c, 0, 14, 0, true, 2});
    for (int c = 3; c <= 4; c++) { ss.push_back({'C', c, 0, 2, 1, true, 128}); ss.push_back({'C', c, 1, 7, 1, true, 128}); }
    std::map<int, std::set<int>> used;
    for (auto &s : ss) used[s.col].insert(s.bd);
    for (int c = 3; c <= 4; c++) for (int b = 2; b <= 13; b++) used[c].insert(b);
    std::vector<int> order, alt(ss.size(), -1);
#if PQ_HAVE
    std::vector<sliceprequeue::Io> ios;
    for (auto &s : ss) {
        sliceprequeue::Io x; x.col = s.col; x.row = 0; x.ch = s.ch; x.bd = s.bd;
        x.dir = s.dir ? sliceprequeue::S2MM : sliceprequeue::MM2S; x.sliced = s.sliced; x.repeat = s.repeat;
        ios.push_back(x);
    }
    sliceprequeue::Plan p = sliceprequeue::plan(ios, used);
    order = p.order; alt = p.altBd;
#else
    for (size_t i = 0; i < ss.size(); i++) order.push_back((int)i);
#endif
    // replay 2 calls: issue (skipped when pre-queued), pre-queue, waits; the runtime's per-channel state
    std::map<std::pair<int, int>, int> pending, nextBd, curBd, depth;
    std::vector<E> ev;
    int conflicts = 0, qmax = 0, own_pushes_call1 = 0;
    for (int call = 0; call < 2; call++) {
        for (int i : order) {
            auto &s = ss[i]; auto k = std::make_pair(s.col, s.ch + 2 * s.dir);
            if (!s.dir && alt[i] >= 0 && pending[k]) { pending[k] = 0; curBd[k] = nextBd[k]; continue; }
            curBd[k] = s.bd; depth[k]++;
            ev.push_back({call, "start", s.arg, s.col, s.ch, s.bd});
            if (call == 1 && !s.dir) own_pushes_call1++;
        }
        for (int i : order) {
            auto &s = ss[i]; auto k = std::make_pair(s.col, s.ch + 2 * s.dir);
            if (s.dir || alt[i] < 0) continue;
#if PQ_HAVE
            int t = sliceprequeue::pickTarget(curBd[k], s.bd, alt[i]);
#else
            int t = alt[i];
#endif
            if (t == curBd[k]) conflicts++;
            pending[k] = 1; nextBd[k] = t; depth[k]++;
            ev.push_back({call, "start", s.arg, s.col, s.ch, t});
        }
        for (auto &d : depth) qmax = d.second > qmax ? d.second : qmax;
        for (int i : order) {
            auto &s = ss[i]; auto k = std::make_pair(s.col, s.ch + 2 * s.dir);
            ev.push_back({call, "wait", s.arg, s.col, s.ch, -1});
            depth[k] = pending[k] && !s.dir ? 1 : 0;
        }
    }
    std::set<int> pre; std::string first;
    for (auto &e : ev) {
        if (e.call == 0 && e.kind == "wait") break;
        if (e.call == 0 && (e.arg == 'A' || e.arg == 'B') && (e.bd == 0 || e.bd == 1)) pre.insert(e.bd);
    }
    for (auto &e : ev)
        if (e.call == 0 && e.kind == "start" && first.find(e.arg) == std::string::npos) first += e.arg;
    std::string bds;
    for (int b : pre) bds += (bds.empty() ? "" : ",") + std::to_string(b);
    std::string ord;
    for (char c : first) ord += (ord.empty() ? "" : ",") + std::string(1, c);
    const bool ok = bds == "0,1" && ord == "B,C,A" && qmax <= 4 && conflicts == 0 && own_pushes_call1 == 0;
    if (pre.empty())
        std::printf("PQSTUB FAIL: no BD0/1 startio before wait(0)\n");
    std::printf("PQSTUB calls=2 prequeue_bds=%s order=%s qmax=%d conflicts=%d call1_own_pushes=%d %s\n",
                bds.empty() ? "-" : bds.c_str(), ord.c_str(), qmax, conflicts, own_pushes_call1, ok ? "OK" : "FAIL");
    return ok ? 0 : 1;
}
"""
PQ_CASES = [
    ("dataflow_slices_prequeue_altbd", [],
     "PASS:PQSTUB calls=2 prequeue_bds=0,1 order=B,C,A qmax=2 conflicts=0 call1_own_pushes=0 OK"),
]


def run_pq_stub(expect):
    """g++ the 2-call sliced stub against sliceprequeue_plan.h (when present)."""
    with tempfile.TemporaryDirectory() as tmp:
        if PQ_PLAN_H.exists():
            shutil.copy(PQ_PLAN_H, tmp)
        src = pathlib.Path(tmp) / "pqstub.cc"
        src.write_text(PQ_SRC)
        cc = subprocess.run(["g++", "-std=c++17", "-O1", "-w", "-I", tmp, "-o", str(pathlib.Path(tmp) / "pqstub"),
                             str(src)], capture_output=True, text=True, timeout=600)
        if cc.returncode != 0:
            return False, cc.stdout + cc.stderr
        p = subprocess.run([str(pathlib.Path(tmp) / "pqstub")], capture_output=True, text=True, timeout=600)
        out = p.stdout + p.stderr
    return p.returncode == 0 and expect[5:] in out, out


def run_gt_num(edits, expect):
    """Compile GT_NUM_SRC with g++ on the x86 AIE API emulation; edits = [(TM, TN), (KC, KC)]."""
    tm, tn = edits[0]
    kc = edits[1][0]
    with tempfile.TemporaryDirectory() as tmp:
        shutil.copy(GT_NUM_BASE, tmp)
        if (GT_NUM_BASE.parent / "gemm_plan_gt.h").exists():
            shutil.copy(GT_NUM_BASE.parent / "gemm_plan_gt.h", tmp)
        src = pathlib.Path(tmp) / "gtnum.cc"
        src.write_text(f"#define KA_TM {tm}\n#define KA_TN {tn}\n#define KA_KC {kc}\n" + GT_NUM_SRC)
        emu = REPO / "src" / "mlir" / "runtime" / "aie_api_x86emu.h"
        cc = subprocess.run(["g++", "-std=c++20", "-O1", "-w", "-fsanitize=address", f"-DAIEHLC_EMU_HEADER=\"{emu}\"",
                             "-I", tmp, "-o", str(pathlib.Path(tmp) / "gtnum"), str(src)],
                            capture_output=True, text=True, timeout=600)
        if cc.returncode != 0:
            return False, cc.stdout + cc.stderr
        p = subprocess.run([str(pathlib.Path(tmp) / "gtnum")], capture_output=True, text=True, timeout=600,
                           env=dict(os.environ, ASAN_OPTIONS="detect_leaks=0:halt_on_error=1"))
        out = p.stdout + p.stderr
    return p.returncode == 0 and expect[5:] in out, out


def inline_cc(path):
    """The file with its `#include "x.cc"` lines (same directory) replaced by the file, recursively."""
    out = []
    for ln in path.read_text().splitlines(keepends=True):
        s = ln.strip()
        if s.startswith('#include "') and s.endswith('.cc"'):
            out.append(inline_cc(path.parent / s[len('#include "'):-1]))
        else:
            out.append(ln)
    return "".join(out)


def run_case(cli, name, edits, expect, base=BASE):
    if base == GT_NUM_BASE:
        return run_gt_num(edits, expect)
    if base == PQ_BASE:
        return run_pq_stub(expect)
    src = inline_cc(base) if base in (GEMMPLAN_BASE, GEMMPLAN_T_BASE) else base.read_text()
    if base == TEMPLATE_BASE:  # the library kernel alone: add the includes and a host launch
        src = TEMPLATE_HEAD + src + TEMPLATE_HOST
    for old, new in edits:
        if old not in src:
            return False, f"mutation anchor not found: {old[:60]!r}"
        src = src.replace(old, new, 1)
    with tempfile.TemporaryDirectory() as tmp:
        for h in list(CCODE.glob("*.h")) + list(base.parent.glob("*.h")):
            shutil.copy(h, tmp)
        path = pathlib.Path(tmp) / "case.cc"
        path.write_text(src)
        env = dict(os.environ)
        if name.startswith("endless loop"):
            env["AIEHLC_TRACE_TIMEOUT"] = "3"
        p = subprocess.run([cli, "trace", str(path)], capture_output=True, text=True, timeout=600, env=env)
        out = p.stdout + p.stderr
    if expect is None:
        return p.returncode == 0, out
    if expect.startswith("PASS:"):  # must pass AND print this
        return p.returncode == 0 and expect[5:] in out, out
    return p.returncode == 2 and expect in out, out


def main():
    cli = sys.argv[1] if len(sys.argv) > 1 else str(REPO / "build" / "aiehlc-convtile")
    failed = 0
    cases = [(n, e, x, BASE) for n, e, x in CASES] + [(n, e, x, TENSOR_BASE) for n, e, x in TENSOR_CASES]
    cases += [(n, e, x, GEMM_BASE) for n, e, x in GEMM_CASES]
    cases += [(n, e, x, DATAFLOW_BASE) for n, e, x in DATAFLOW_CASES]
    cases += [(n, e, x, CONVOPTS_BASE) for n, e, x in CONVOPTS_CASES]
    cases += [(n, e, x, BF16_BASE) for n, e, x in BF16_CASES]
    cases += [(n, e, x, SPACE_BASE) for n, e, x in SPACE_CASES]
    cases += [(n, e, x, TEMPLATE_BASE) for n, e, x in TEMPLATE_CASES]
    cases += [(n, e, x, GEMMPLAN_BASE) for n, e, x in GEMMPLAN_CASES]
    cases += [(n, e, x, GEMMPLAN_T_BASE) for n, e, x in GEMMPLAN_T_CASES]
    cases += [(n, e, x, GT_NUM_BASE) for n, e, x in GT_NUM_CASES]
    cases += [(n, e, x, PQ_BASE) for n, e, x in PQ_CASES]
    if len(sys.argv) > 2:  # a name filter
        cases = [c for c in cases if sys.argv[2] in c[0]]
    for name, edits, expect, base in cases:
        ok, out = run_case(cli, name, edits, expect, base)
        print(f"{'ok  ' if ok else 'FAIL'} {name}")
        if not ok:
            failed += 1
            print("     expected:", expect)
            print("     " + "\n     ".join(out.strip().splitlines()[-8:]))
        elif expect:
            line = next((l for l in out.splitlines() if expect.removeprefix("PASS:") in l), "")
            print("     " + line.strip()[:200])
    print(f"kernel_trace_cases: {len(cases) - failed} passed, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
