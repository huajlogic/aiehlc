###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""AIE layer -> aiehlc app source (library mode), one per distinct signature.

Two templates cover every Whisper layer:

``gemm``  (``aie::GemmSpace``, 4x4 mesh, ``fullconnect_auto=1``)
    ``C = epi(A @ B^T)`` -- dense, batch_matmul (one launch per batch), conv1d
    (im2col staged into A). Bias rides as an extra K column: A carries ``1.0``,
    B carries the bias, so ``A@B^T`` already contains it and the core needs no
    fourth port (a fourth ``aie::port`` is unproven in this repo -- see
    conv2dstem.cc). Epilogue: identity or exact GELU (erf).

``row``   (``aie::RowSpace``, 1x4 mesh, the new spatial type)
    Row-parallel maps: ``layernorm`` (+ broadcast gamma/beta),
    ``softmax``, ``softmax_mask`` and ``add`` (two row-split operands).

A *signature* is everything the generated source depends on (padded dims,
tiling, op); layers with the same signature share one library -- e.g. the
encoder's q/v/out projections and the decoder's cross-attention v projection
are all ``gemm 1536x384x448 bias``.

Every library exports the same C ABI, which ``aie_codegen_whisper`` targets
and the x86 emulator (``aie_emu_whisper``) re-implements::

    float *aiew_<sig>_port(int i);   // DMA buffer of port i (0=A, 1=B, 2=C)
    int    aiew_<sig>_run(void);     // one launch on the mesh

Kernel-visible helpers (exp, erf, rsqrt) are MACROS: aiehlc copies only the
``#define``s of the app file into the kernel translation unit (skill:
byocaieoffload). The device has no libm in this flow, so exp/erf/rsqrt are
polynomial/Newton forms accurate to fp32 rounding.
"""

from __future__ import annotations

import hashlib
import math

GEMM_MESH = (4, 4)
ROW_MESH = (1, 4)          # RowSpace: rows over a 1 x N mesh, one tile per column
TILE_M = 16
TILE_N = 16
ROW_BUDGET = 6144          # bytes per RowSpace window (3 ports x 2 ping-pong fit 48 KB)
GEMM_BUDGET = 4096


def _ceil(a, b):
    return -(-a // b) * b


# ═══════════════════════════════════════════════════════════════════════════
#  Planning
# ═══════════════════════════════════════════════════════════════════════════

def plan_library(L) -> dict:
    """The library a layer runs on: template, padded geometry, signature."""
    if L.op in ("dense", "bmm", "conv1d"):
        bias = L.bias_arg >= 0
        k_real = L.K + (1 if bias else 0)
        kc = min((64, 32), key=lambda c: (_ceil(k_real, c), -c))
        R, C = GEMM_MESH
        lib = dict(template="gemm", M=_ceil(L.M, R * TILE_M), N=_ceil(L.N, C * TILE_N),
                   K=_ceil(k_real, kc), kc=kc, bias=bias, gelu=L.gelu,
                   mesh=GEMM_MESH, budget=GEMM_BUDGET)
        lib["key"] = ("gemm", lib["M"], lib["N"], lib["K"], kc, bias, L.gelu)
    else:
        op = "add" if L.op == "embed" else L.op
        _, R = ROW_MESH
        rpw = max(1, min(ROW_BUDGET // (L.cols * 4), -(-L.rows // R)))
        lib = dict(template="row", op=op, rows=_ceil(L.rows, R * rpw), cols=L.cols,
                   rpw=rpw, mesh=ROW_MESH, budget=rpw * L.cols * 4,
                   ports=3 if op in ("layernorm", "softmax_mask", "add") else 2,
                   param_rows=2 if op == "layernorm" else 0, eps=L.eps)
        lib["key"] = ("row", op, lib["rows"], lib["cols"], rpw)
    tag = "_".join(str(int(v)) if isinstance(v, bool) else str(v) for v in lib["key"])
    lib["sig"] = f"aiew_{tag}"
    lib["kernel"] = "k" + hashlib.sha1(lib["sig"].encode()).hexdigest()[:10]
    lib["expect"] = expected_constants(lib)
    return lib


def expected_constants(lib) -> dict:
    """What aiehlc must resolve the kernel's ``aie::get_*`` calls to.

    Computed from the plan, independently of aiehlc; ``aie_build`` compares it
    with the constants in the resolved kernel source, so a derivation drift in
    the compiler is a build error here, not a hang on the board.
    """
    if lib["template"] == "gemm":
        R, C = lib["mesh"]
        return dict(k_rounds=lib["K"] // lib["kc"], eff_k=lib["kc"],
                    num_a_rounds=1, num_b_rounds=1, num_c_rounds=1,
                    buf_sz_a=TILE_M * lib["kc"], buf_sz_b=TILE_N * lib["kc"],
                    buf_sz_c=TILE_M * TILE_N,
                    m_rounds=lib["M"] // R // TILE_M, n_rounds=lib["N"] // C // TILE_N,
                    tile_rows=TILE_M, tile_cols=TILE_N)
    _, R = lib["mesh"]
    per_tile = lib["rows"] // R * lib["cols"]
    win = lib["rpw"] * lib["cols"]
    exp = dict(num_a_rounds=per_tile // win, buf_sz_a=win,
               num_c_rounds=per_tile // win, buf_sz_c=win)
    if lib["op"] in ("softmax_mask", "add"):
        exp.update(num_b_rounds=per_tile // win, buf_sz_b=win)
    elif lib["op"] == "layernorm":
        p = 2 * lib["cols"]
        bwin = min(p, win)
        exp.update(num_b_rounds=p // bwin, buf_sz_b=bwin)
    return exp


def port_elems(lib) -> list:
    if lib["template"] == "gemm":
        return [lib["M"] * lib["K"], lib["N"] * lib["K"], lib["M"] * lib["N"]]
    rc = lib["rows"] * lib["cols"]
    if lib["op"] == "softmax":
        return [rc, 0, rc]
    if lib["op"] == "layernorm":
        return [rc, 2 * lib["cols"], rc]
    return [rc, rc, rc]


# ═══════════════════════════════════════════════════════════════════════════
#  Kernel-visible math (macros)
# ═══════════════════════════════════════════════════════════════════════════

MATH_MACROS = r"""
/* e^x in fp32: 2^(x*log2e) = 2^i * 2^f, f in [0,1), 2^f by a degree-6
 * minimax polynomial (rel. err ~2e-7). x < -87 (incl. -inf masks) -> 0. */
#define WSP_EXP(out, xin)                                                        \
    do {                                                                         \
        float wsp_x_ = (xin);                                                    \
        if (wsp_x_ < -87.0f) {                                                   \
            (out) = 0.0f;                                                        \
        } else {                                                                 \
            if (wsp_x_ > 88.0f)                                                  \
                wsp_x_ = 88.0f;                                                  \
            float wsp_t_ = wsp_x_ * 1.4426950409f;                               \
            int wsp_i_ = (int)wsp_t_;                                            \
            if ((float)wsp_i_ > wsp_t_)                                          \
                wsp_i_ -= 1;                                                     \
            float wsp_f_ = wsp_t_ - (float)wsp_i_;                               \
            float wsp_p_ = 1.0f + wsp_f_ * (0.6931471806f + wsp_f_ * (0.2402265070f + \
                wsp_f_ * (0.0555041087f + wsp_f_ * (0.0096181291f +             \
                wsp_f_ * (0.0013333558f + wsp_f_ * 0.0001540353f)))));           \
            union { float f; int i; } wsp_u_;                                    \
            wsp_u_.i = (wsp_i_ + 127) << 23;                                     \
            (out) = wsp_p_ * wsp_u_.f;                                           \
        }                                                                        \
    } while (0)

/* GELU(x) = 0.5 x (1 + erf(x / sqrt2)); erf by Abramowitz-Stegun 7.1.26
 * (|err| < 1.5e-7) -- the exact (erf) GELU Whisper uses, not the tanh one. */
#define WSP_GELU(out, xin)                                                       \
    do {                                                                         \
        float wsp_v_ = (xin);                                                    \
        float wsp_z_ = wsp_v_ * 0.7071067812f;                                   \
        float wsp_az_ = wsp_z_ < 0.0f ? -wsp_z_ : wsp_z_;                        \
        float wsp_tt_ = 1.0f / (1.0f + 0.3275911f * wsp_az_);                    \
        float wsp_e_;                                                            \
        WSP_EXP(wsp_e_, -wsp_az_ * wsp_az_);                                     \
        float wsp_y_ = 1.0f - (((((1.061405429f * wsp_tt_ - 1.453152027f) * wsp_tt_ + \
            1.421413741f) * wsp_tt_ - 0.284496736f) * wsp_tt_ + 0.254829592f) *  \
            wsp_tt_) * wsp_e_;                                                   \
        float wsp_erf_ = wsp_z_ < 0.0f ? -wsp_y_ : wsp_y_;                       \
        (out) = 0.5f * wsp_v_ * (1.0f + wsp_erf_);                               \
    } while (0)

/* 1/sqrt(v), v > 0: bit-trick seed + 3 Newton steps (fp32 accurate). */
#define WSP_RSQRT(out, vin)                                                      \
    do {                                                                         \
        float wsp_r_v_ = (vin);                                                  \
        union { float f; int i; } wsp_r_u_;                                      \
        wsp_r_u_.f = wsp_r_v_;                                                   \
        wsp_r_u_.i = 0x5f3759df - (wsp_r_u_.i >> 1);                             \
        float wsp_r_y_ = wsp_r_u_.f;                                             \
        wsp_r_y_ = wsp_r_y_ * (1.5f - 0.5f * wsp_r_v_ * wsp_r_y_ * wsp_r_y_);    \
        wsp_r_y_ = wsp_r_y_ * (1.5f - 0.5f * wsp_r_v_ * wsp_r_y_ * wsp_r_y_);    \
        wsp_r_y_ = wsp_r_y_ * (1.5f - 0.5f * wsp_r_v_ * wsp_r_y_ * wsp_r_y_);    \
        (out) = wsp_r_y_;                                                        \
    } while (0)
"""


# ═══════════════════════════════════════════════════════════════════════════
#  Kernel bodies
# ═══════════════════════════════════════════════════════════════════════════

_GEMM_BODY = r"""
    const int k_rounds = aie::get_arg_total_rounds_in_dim(1, win_a);
    const int eff_k = aie::get_arg_per_round_size_in_dim(1, win_a);
    const int num_a_rounds = aie::get_num_rounds(win_a);
    const int num_b_rounds = aie::get_num_rounds(win_b);
    const int num_c_rounds = aie::get_num_rounds(win_c);
    const int buf_sz_a = aie::get_buffer_size(win_a);
    const int buf_sz_b = aie::get_buffer_size(win_b);
    const int buf_sz_c = aie::get_buffer_size(win_c);
    const int m_rounds = aie::get_spatial_multiple_rounds(win_a);
    const int n_rounds = aie::get_spatial_multiple_rounds(win_b);
    const int tile_rows = aie::get_arg_per_round_size_in_dim(0, win_a);
    const int tile_cols = aie::get_arg_per_round_size_in_dim(0, win_b);
    const int cols_per_round = buf_sz_b / eff_k;
    float all_A[tile_rows * eff_k];
    float accum[tile_rows * tile_cols];
    /* One (m,n) output sub-tile per iteration; A repeats while B cycles. */
    for (int it = 0; it < m_rounds * n_rounds; it++) {
        for (int i = 0; i < tile_rows * tile_cols; i++)
            accum[i] = 0.0f;
        for (int kr = 0; kr < k_rounds; kr++) {
            for (int ra = 0; ra < num_a_rounds; ra++) {
                float *A_ptr = (float *)acquire_input_window(win_a);
                for (int i = 0; i < buf_sz_a; i++)
                    all_A[ra * buf_sz_a + i] = A_ptr[i];
                release_input_window(win_a);
            }
            for (int rb = 0; rb < num_b_rounds; rb++) {
                float *B_ptr = (float *)acquire_input_window(win_b);
                for (int i = 0; i < tile_rows; i++) {
                    for (int j = 0; j < cols_per_round; j++) {
                        float sum = 0.0f;
                        for (int k = 0; k < eff_k; k++)
                            sum += all_A[i * eff_k + k] * B_ptr[j * eff_k + k];
                        accum[i * tile_cols + rb * cols_per_round + j] += sum;
                    }
                }
                release_input_window(win_b);
            }
        }
        for (int rc = 0; rc < num_c_rounds; rc++) {
            float *out = (float *)acquire_output_window(win_c);
            for (int i = 0; i < buf_sz_c; i++) {
                float v = accum[rc * buf_sz_c + i];
                EPILOGUE
                out[i] = v;
            }
            release_output_window(win_c);
        }
    }
"""

_ROW_PROLOGUE = r"""
    const int num_a_rounds = aie::get_num_rounds(win_a);
    const int num_c_rounds = aie::get_num_rounds(win_c);
    const int buf_sz_a = aie::get_buffer_size(win_a);
    const int buf_sz_c = aie::get_buffer_size(win_c);
    const int rows_per_win = buf_sz_a / COLS;
"""

_ROW_BODIES = {
    "layernorm": r"""
    const int num_b_rounds = aie::get_num_rounds(win_b);
    const int buf_sz_b = aie::get_buffer_size(win_b);
    /* gamma | beta, broadcast to every tile once */
    float P[2 * COLS];
    for (int rb = 0; rb < num_b_rounds; rb++) {
        float *p = (float *)acquire_input_window(win_b);
        for (int i = 0; i < buf_sz_b; i++)
            P[rb * buf_sz_b + i] = p[i];
        release_input_window(win_b);
    }
    for (int w = 0; w < num_a_rounds; w++) {
        float *a = (float *)acquire_input_window(win_a);
        float *c = (float *)acquire_output_window(win_c);
        for (int r = 0; r < rows_per_win; r++) {
            const float *x = a + r * COLS;
            float s = 0.0f;
            for (int j = 0; j < COLS; j++)
                s += x[j];
            const float mean = s / (float)COLS;
            float q = 0.0f;
            for (int j = 0; j < COLS; j++) {
                float d = x[j] - mean;
                q += d * d;
            }
            float inv;
            WSP_RSQRT(inv, q / (float)COLS + LN_EPS);
            for (int j = 0; j < COLS; j++)
                c[r * COLS + j] = (x[j] - mean) * inv * P[j] + P[COLS + j];
        }
        release_output_window(win_c);
        release_input_window(win_a);
    }
""",
    "softmax": r"""
    for (int w = 0; w < num_a_rounds; w++) {
        float *a = (float *)acquire_input_window(win_a);
        float *c = (float *)acquire_output_window(win_c);
        for (int r = 0; r < rows_per_win; r++) {
            const float *x = a + r * COLS;
            float *y = c + r * COLS;
            float mx = x[0];
            for (int j = 1; j < COLS; j++)
                mx = x[j] > mx ? x[j] : mx;
            float s = 0.0f;
            for (int j = 0; j < COLS; j++) {
                float e;
                WSP_EXP(e, x[j] - mx);
                y[j] = e;
                s += e;
            }
            for (int j = 0; j < COLS; j++)
                y[j] = y[j] / s;
        }
        release_output_window(win_c);
        release_input_window(win_a);
    }
""",
    "softmax_mask": r"""
    /* Walked in lockstep with A: aie_build checks these resolve to A's values. */
    const int num_b_rounds = aie::get_num_rounds(win_b);
    const int buf_sz_b = aie::get_buffer_size(win_b);
    (void)num_b_rounds;
    (void)buf_sz_b;
    for (int w = 0; w < num_a_rounds; w++) {
        float *a = (float *)acquire_input_window(win_a);
        float *m = (float *)acquire_input_window(win_b);
        float *c = (float *)acquire_output_window(win_c);
        for (int r = 0; r < rows_per_win; r++) {
            float *y = c + r * COLS;
            for (int j = 0; j < COLS; j++)
                y[j] = a[r * COLS + j] + m[r * COLS + j];
            float mx = y[0];
            for (int j = 1; j < COLS; j++)
                mx = y[j] > mx ? y[j] : mx;
            float s = 0.0f;
            for (int j = 0; j < COLS; j++) {
                float e;
                WSP_EXP(e, y[j] - mx);
                y[j] = e;
                s += e;
            }
            for (int j = 0; j < COLS; j++)
                y[j] = y[j] / s;
        }
        release_output_window(win_c);
        release_input_window(win_b);
        release_input_window(win_a);
    }
""",
    "add": r"""
    /* Walked in lockstep with A: aie_build checks these resolve to A's values. */
    const int num_b_rounds = aie::get_num_rounds(win_b);
    const int buf_sz_b = aie::get_buffer_size(win_b);
    (void)num_b_rounds;
    (void)buf_sz_b;
    for (int w = 0; w < num_a_rounds; w++) {
        float *a = (float *)acquire_input_window(win_a);
        float *b = (float *)acquire_input_window(win_b);
        float *c = (float *)acquire_output_window(win_c);
        for (int i = 0; i < buf_sz_a; i++)
            c[i] = a[i] + b[i];
        release_output_window(win_c);
        release_input_window(win_b);
        release_input_window(win_a);
    }
""",
}


def _space(name, kind, layout, d1, d2, budget, merge=False, wgt=False):
    pat = "wgt" if wgt else "act"
    mp = (f".map = {{.layout = aie::Layout::{layout}, .merge_order = aie::Flow::LeftToRight}}"
          if merge else f".map = {{.{pat} = aie::Pattern::Broadcast, .layout = aie::Layout::{layout}}}")
    if kind == "GemmSpace":
        return (f"constexpr aie::GemmSpace {name} = {{\n"
                f"    .policy = {{{mp},\n"
                f"               .mat = {{.pad = aie::PadMaterialize::DDR, .im2col = aie::Im2col::None}},\n"
                f"               .sched = {{.pp_depth = 2, .l1_budget = aie::Bytes{{{budget}}}}}}},\n"
                f"    .d1 = {{.fullsize = {d1[0]}, .tile_size = {d1[1]}, .stride = {d1[1]}}},\n"
                f"    .d2 = {{.fullsize = {d2[0]}, .tile_size = {d2[1]}, .stride = {d2[1]}}}}};\n")
    rows = f"{{.fullsize = {d1[0]}" + (f", .tile_size = {d1[1]}}}" if d1[1] else "}")
    return (f"constexpr aie::RowSpace {name} = {{\n"
            f"    .policy = {{{mp},\n"
            f"               .sched = {{.pp_depth = 2, .l1_budget = aie::Bytes{{{budget}}}}}}},\n"
            f"    .rows = {rows},\n"
            f"    .cols = {{.fullsize = {d2[0]}}}}};\n")


def app_source(lib) -> str:
    """The aiehlc app (library mode: no ``main``) for one signature.

    Text traps this layout respects (skill: aiesourcetextrewrite): the kernel
    keyword appears only on the kernel itself, the launch syntax only at the
    launch, and nothing referring to the launching function precedes the
    kernel definition.
    """
    sig, kname = lib["sig"], lib["kernel"]
    R, C = lib["mesh"]
    elems = port_elems(lib)
    head = [f"/* Generated by src/frontend/tvmrelay/example/whisper/aie_kernels_whisper.py.",
            f" * Signature {sig}: {lib['key']} -- do not edit. */",
            "#include <stddef.h>", "#include <stdint.h>", "#include <string.h>", ""]
    if lib["template"] == "gemm":
        head += [f"#define M {lib['M']}", f"#define N {lib['N']}", f"#define K {lib['K']}",
                 f"#define KC {lib['kc']}", f"#define HW_ROWS {R}", f"#define HW_COLS {C}"]
        spaces = (_space(f"{kname}_A", "GemmSpace", "Row", ("M", TILE_M), ("K", "KC"), lib["budget"])
                  + _space(f"{kname}_B", "GemmSpace", "Col", ("N", TILE_N), ("K", "KC"), lib["budget"],
                           wgt=True)
                  + _space(f"{kname}_C", "GemmSpace", "Row", ("M", TILE_M), ("N", TILE_N), lib["budget"],
                           merge=True))
        body = _GEMM_BODY.replace("EPILOGUE", "WSP_GELU(v, v);" if lib["gelu"] else "/* identity */")
        fca = 1
        ports = [("input", "A"), ("input", "B"), ("output", "C")]
        launch_dims = "M, N, K"
    else:
        head += [f"#define ROWS {lib['rows']}", f"#define COLS {lib['cols']}",
                 f"#define RPW {lib['rpw']}", f"#define HW_ROWS {R}", f"#define HW_COLS {C}",
                 f"#define LN_EPS {lib['eps']!r}f" if lib["op"] == "layernorm" else ""]
        spaces = _space(f"{kname}_A", "RowSpace", "Row", ("ROWS", "RPW"), ("COLS",), lib["budget"])
        ports = [("input", "A")]
        if lib["op"] == "layernorm":
            spaces += _space(f"{kname}_B", "RowSpace", "Col", (2, 0), ("COLS",), lib["budget"], wgt=True)
            ports.append(("input", "B"))
        elif lib["ports"] == 3:
            spaces += _space(f"{kname}_B", "RowSpace", "Row", ("ROWS", "RPW"), ("COLS",), lib["budget"],
                             wgt=True)
            ports.append(("input", "B"))
        spaces += _space(f"{kname}_C", "RowSpace", "Row", ("ROWS", "RPW"), ("COLS",), lib["budget"],
                         merge=True)
        ports.append(("output", "C"))
        body = _ROW_PROLOGUE + _ROW_BODIES[lib["op"]]
        fca = 0
        launch_dims = "ROWS, COLS, COLS"
    names = {"A": "win_a", "B": "win_b", "C": "win_c"}
    params = ",\n    ".join(f"aie::port<{d}_window_int32 *, {kname}_{p}> {names[p]}" for d, p in ports)
    bufs = [p for _, p in ports]
    lines = head + [MATH_MACROS, spaces,
                    f"constexpr aie::GlobalPolicy {kname}_policy = {{.fullconnect_auto = {fca}}};",
                    f"__global__({kname}_policy) void {kname}(\n    {params}) {{{body}}}", ""]
    lines += [f"static float *g_{sig}_{p} = 0;" for p in bufs]
    lines += ["", "/* aie_runtime.h declares it with C++ linkage in the host compile. */", "void *__Runtime_Alloc(size_t bytes);", "",
              "/* DMA-capable buffers, allocated and zeroed once: the zero padding",
              " * (rows/cols past the real tensor) is never written again. */",
              f'extern "C" float *{sig}_port(int i) {{']
    for i, p in enumerate("ABC"):
        if p in bufs:
            lines += [f"    if (!g_{sig}_{p}) {{",
                      f"        g_{sig}_{p} = (float *)__Runtime_Alloc({elems[i]}u * sizeof(float));",
                      f"        if (g_{sig}_{p})",
                      f"            memset(g_{sig}_{p}, 0, {elems[i]}u * sizeof(float));",
                      "    }",
                      f"    if (i == {i})",
                      f"        return g_{sig}_{p};"]
    lines += ["    return 0;", "}", "",
              "/* The one launch site: the mesh VarDecl must be function-local and",
              " * constant-foldable, the aiehlc frontend reads it from the AST. */",
              f'extern "C" int {sig}_run(void) {{']
    lines += [f"    if (!{sig}_port({i}))\n        return -1;" for i, p in enumerate("ABC") if p in bufs]
    # Same partition for both; a RowSpace 1 x 4 mesh uses one core per column
    # (each tile gets its own shim column).
    part = "{0, 3, 0, 6}"
    lines += ["    aieSetDevice(0);", "    aieArray device;",
              f"    aieMesh mesh = device.partition({part}, HW_ROWS, HW_COLS);",
              f"    {kname}<<<mesh>>>({', '.join(f'g_{sig}_{p}' for p in bufs)}, {launch_dims});",
              "    return 0;", "}", ""]
    return "\n".join(x for x in lines if x is not None)
