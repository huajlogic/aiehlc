#!/usr/bin/env python3
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Download + quantize ResNet-18, and emit its first conv as a C header.

    resnet18-v1-7.onnx -> onnxruntime int8 PTQ (QDQ) -> first Conv
                       -> ../conv2dstem_weights.h

Run it with no arguments to regenerate the committed fixture::

    python3 src/aietensorop/conv2dstem/data/make_weights_header.py

Two arrays come out:

* ``conv2dstem_wts[9408]`` -- int8 weights, transposed OIHW -> **OHWI**
  [64,7,7,3], the layout ``stage_weights()`` (``conv2dstem.cc:568``) indexes.
* ``conv2dstem_qp[256]`` -- int32, 64 channels x {bias, zero_point, multiplier,
  shift}, layout-compatible with ``conv2dstem_qparam`` (``conv2dstem.h:115``).

The quantization itself is **not** reinvented: if the TVM flow's QDQ model is
already on disk it is reused, otherwise ``onnx_ptq.quantize_onnx_int8`` runs the
repo's own PTQ (per-channel symmetric int8 weights, asymmetric uint8
activations). The folding from ONNX's (scale, zero-point, int32 bias) into the
core's (bias, zp, multiplier, shift) is described in fixture_common's module
docstring -- including why the stored shift is the *negation* of frexp's
exponent, which is the one sign error that produces plausible-looking but
uniformly wrong pixels.

``--emit-npz`` also writes ``stem_fixture.npz`` so ``groundtruth.py`` consumes
the very same arrays rather than re-deriving them.
"""
from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import fixture_common as fc  # noqa: E402

GUARD = "AIETENSOROP_CONV2DSTEM_WEIGHTS_H"
GENERATOR = "src/aietensorop/conv2dstem/data/make_weights_header.py"


def build_prose(sp, qp) -> str:
    bias, mult, shift = qp[:, 0], qp[:, 2], qp[:, 3]
    real = sp.real_scale
    return (
        f"ResNet-18 conv1 (the stem), int8-quantized, from:\n"
        f"    {sp.model.name}\n"
        f"\n"
        f"  input      scale {sp.in_scale:.8g}, zero-point {sp.in_zp} (uint8)\n"
        f"  weights    int8 [64,3,7,7] OIHW -> [64,7,7,3] OHWI, per-channel\n"
        f"             scale in [{sp.w_scale.min():.4g}, {sp.w_scale.max():.4g}], "
        f"zero-point 0\n"
        f"  output     scale {sp.out_scale:.8g}, zero-point {sp.out_zp}\n"
        f"\n"
        f"Folded into the core's per-channel epilogue\n"
        f"    acc += bias; acc -= zero_point;\n"
        f"    v = ((int64)acc * multiplier + (1LL << (shift+30))) >> (shift+31);\n"
        f"    out = (uint8)clamp(v, 0, 255);          // the clamp at 0 IS the ReLU\n"
        f"as\n"
        f"    bias[c]  = bias_q[c] + (128 - {sp.in_zp}) * sum(w[c])\n"
        f"               -- absorbs the uint8->int8 input shift and the input\n"
        f"               zero-point together; range [{bias.min():,}, {bias.max():,}]\n"
        f"    zp[c]    = 0\n"
        f"    mult/shift = fixed_point(in_scale * w_scale[c] / out_scale)\n"
        f"               real scale in [{real.min():.4g}, {real.max():.4g}],\n"
        f"               shift in [{shift.min()}, {shift.max()}]\n"
        f"\n"
        f"NOTE the shift is the NEGATION of frexp's exponent -- the core applies\n"
        f"it as >> (shift+31). See fixture_common.fixed_point.\n"
        f"\n"
        f"The accumulator must stay int32: with these weights the peak\n"
        f"|accumulator| on a real image is ~1.02e6, against an int16 range of\n"
        f"+-32,767. Synthetic bring-up data never shows this.\n"
        f"\n"
        f"Weights are emitted as uint8_t hex and cast to const int8_t* at the\n"
        f"use site; the qparams are int32_t decimal."
    )


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--onnx", default=None,
                    help="int8 QDQ model (default: cached, else download+quantize)")
    ap.add_argument("--out", type=Path,
                    default=fc.OUT_DIR / "conv2dstem_weights.h",
                    help="header to write (default: ../conv2dstem_weights.h)")
    ap.add_argument("--emit-npz", action="store_true",
                    help="also write stem_fixture.npz for groundtruth.py")
    args = ap.parse_args(argv)

    print("=== conv2dstem weight fixture ===")
    sp = fc.load_stem_params(args.onnx)
    qp = fc.fold_qparams(sp)

    # OIHW -> OHWI, the layout stage_weights() indexes as
    # wts[((f*KH + kh)*KW + kw)*INPUT_C + c].
    wts_ohwi = sp.weight.transpose(0, 2, 3, 1).astype(np.int64)
    if wts_ohwi.size != fc.WTS_ELEMS:
        raise SystemExit(f"internal error: {wts_ohwi.size} weights, "
                         f"expected {fc.WTS_ELEMS}")

    print(f"  [qparam] bias [{qp[:, 0].min():,}, {qp[:, 0].max():,}]  "
          f"shift [{qp[:, 3].min()}, {qp[:, 3].max()}]  (all int32-safe)")

    fc.emit_header(
        args.out, GUARD, GENERATOR, build_prose(sp, qp),
        [fc.hex_array("conv2dstem_wts", wts_ohwi, "CONV2DSTEM_DATA_WTS_ELEMS"),
         "\n",
         fc.i32_array("conv2dstem_qp", qp, "CONV2DSTEM_DATA_QP_WORDS")])

    if args.emit_npz:
        npz = fc.DATA_DIR / "stem_fixture.npz"
        np.savez_compressed(
            npz, wts_ohwi=wts_ohwi.astype(np.int8), qp=qp.astype(np.int32),
            weight_oihw=sp.weight.astype(np.int8),
            w_scale=sp.w_scale, bias_q=sp.bias_q.astype(np.int32),
            in_scale=sp.in_scale, in_zp=sp.in_zp,
            out_scale=sp.out_scale, out_zp=sp.out_zp, model=str(sp.model))
        print(f"  [write]  {os.path.relpath(npz, Path.cwd())}  "
              f"({npz.stat().st_size / 1024:,.0f} KB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
