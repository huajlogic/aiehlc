#!/usr/bin/env python3
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""CPU ground truth for the conv2dstem AIE run, and the comparison against it.

    python3 src/aietensorop/conv2dstem/data/groundtruth.py
    python3 src/aietensorop/conv2dstem/data/groundtruth.py --applog ./applog

Three things happen, in this order:

``[ref]``  The reference output, computed in numpy with the **core's own**
           arithmetic: int8 x int8 MACs into an int32 accumulator over the
           pre-padded HWC4 input, then the fused epilogue
           ``((acc + bias - zp) * mult + (1 << (shift+30))) >> (shift+31)``
           clamped to [0,255]. The epilogue is ``ref/stem_ref.py:requantize``
           rather than a third copy of it -- that function is the subtle part
           and already exists. The im2col is written here because
           ``stem_ref.conv2d_stem_ref`` zero-pads a raw [224,224,3] input
           internally (``stem_ref.py:79-80``) and so cannot take the
           zero-point-padded array this fixture uses.

``[xchk]`` The same layer run for real in onnxruntime, by exposing the first
           conv's QuantizeLinear output as a graph output. This is what keeps
           ``[ref]`` honest: if a scale or zero-point were read wrong, thousands
           of elements would differ. A handful differing by 1 is **expected and
           not a failure** -- ORT rounds half-to-even on floats where the core
           does fixed-point round-half-up. Measured on dog.jpg: 2 of 802,816.

``[cmp]``  The board comparison. The reference is written out as
           ``../conv2dstem_golden.h``; ``main.cc`` compares the AIE output
           against it element-wise on the board and prints a bounded mismatch
           report plus one GOLDEN PASS/FAIL line. ``--applog`` parses that line
           back off the console log, since a baremetal board under xsdb has no
           way to hand a file back -- UART is the only channel.

Regeneration order is ``make_image_header.py`` -> ``make_weights_header.py
--emit-npz`` -> this script; see README.md.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "ref"))
import fixture_common as fc  # noqa: E402

GUARD = "AIETENSOROP_CONV2DSTEM_GOLDEN_H"
GENERATOR = "src/aietensorop/conv2dstem/data/groundtruth.py"

#: The QuantizeLinear that re-quantizes the fused conv+relu result. Tapping it
#: gives the uint8 tensor conv2dstem is supposed to reproduce.
_ORT_TAP = "resnetv15_relu0_fwd_QuantizeLinear_Output"


def conv2d_stem_prepadded_ref(pad4: np.ndarray, wts_ohwi: np.ndarray,
                              qp: np.ndarray) -> tuple:
    """``(ofm uint8 [112,112,64], acc int64 [112,112,64])`` from a pre-padded input.

    ``pad4`` is int8 [230,230,4] (channel 3 is alignment pad), ``wts_ohwi`` is
    int8 [64,7,7,3], ``qp`` is int32 [64,4] {bias, zp, mult, shift}.

    The padding channel is carried through the im2col and zeroed in the filter
    instead of being sliced out, which mirrors what the core does: its MAC loop
    walks all four channels and skips the fourth with ``c < SP_REAL_C``
    (``conv2dstem.cc:371``). Same result, same shape of reasoning.
    """
    import stem_ref  # ref/stem_ref.py

    P = pad4.astype(np.int64)
    oh_n, ow_n, k = fc.OUT_H, fc.OUT_W, fc.KH
    cols = np.stack([P[oh * fc.STRIDE:oh * fc.STRIDE + k,
                       ow * fc.STRIDE:ow * fc.STRIDE + k, :].reshape(-1)
                     for oh in range(oh_n) for ow in range(ow_n)])

    filt = np.zeros((fc.OC, k, k, fc.C_ALIGN), np.int64)
    filt[:, :, :, :fc.IN_C] = wts_ohwi.astype(np.int64)
    acc = (cols @ filt.reshape(fc.OC, -1).T).reshape(oh_n, ow_n, fc.OC)

    ofm = stem_ref.requantize(acc, qp[:, 0].astype(np.int64),
                              qp[:, 1].astype(np.int64),
                              qp[:, 2].astype(np.int64),
                              qp[:, 3].astype(np.int64))
    return ofm, acc


def ort_reference(sp, image=None, *, verbose: bool = True):
    """The first layer's real uint8 output from onnxruntime, as HWC [112,112,64].

    Appends the conv's QuantizeLinear output to the graph's outputs so it can be
    fetched directly; the model on disk is untouched.
    """
    import onnx
    import onnxruntime as ort

    model = onnx.load(str(sp.model))
    names = {o.name for o in model.graph.output}
    if _ORT_TAP not in names:
        model.graph.output.append(onnx.helper.make_tensor_value_info(
            _ORT_TAP, onnx.TensorProto.UINT8, [1, fc.OC, fc.OUT_H, fc.OUT_W]))

    sess = ort.InferenceSession(model.SerializeToString(),
                                providers=["CPUExecutionProvider"])
    iname = sess.get_inputs()[0].name

    sys.path.insert(0, str(fc.REPO / "example" / "model" / "resnet18py"))
    import classify  # noqa: E402
    src = str(image) if image is not None else str(fc.DEFAULT_IMAGE)
    path = classify.resolve(src, classify.DEFAULT_IMAGE_URL, "input_image")
    x = np.asarray(classify.preprocess(path), np.float32).reshape(
        1, fc.IN_C, fc.IN_H, fc.IN_W)

    out = sess.run([_ORT_TAP], {iname: x})[0]
    if verbose:
        print(f"  [xchk]   onnxruntime tap {_ORT_TAP} -> {out.shape} {out.dtype}")
    return out[0].transpose(1, 2, 0)      # NCHW -> HWC


def build_prose(sp, ofm, acc, xchk) -> str:
    peak = int(np.abs(acc).max())
    nz = int((ofm > 0).sum())
    line = (f"{xchk} of {ofm.size:,} differ from onnxruntime (rounding)"
            if xchk is not None else "onnxruntime cross-check not run")
    return (
        f"Golden output of the ResNet-18 stem conv on the fixture image,\n"
        f"computed on the CPU with the core's own arithmetic.\n"
        f"\n"
        f"  shape      [{fc.OUT_H},{fc.OUT_W},{fc.OC}] uint8, HWC (channel-fastest)\n"
        f"  range      min {int(ofm.min())}, max {int(ofm.max())}, "
        f"{nz:,} non-zero\n"
        f"  peak |acc| {peak:,}  (int16 max 32,767 -- "
        f"{'OVERFLOWS, int32 required' if peak > 32767 else 'fits int16'})\n"
        f"  xcheck     {line}\n"
        f"\n"
        f"main.cc compares the AIE result against this element-wise on the\n"
        f"board and prints a bounded mismatch report plus one GOLDEN PASS/FAIL\n"
        f"line -- a baremetal board under xsdb cannot hand a file back, so the\n"
        f"console is the only channel. groundtruth.py --applog parses it back.\n"
        f"\n"
        f"Derived from conv2dstem_image.h + conv2dstem_weights.h; regenerate all\n"
        f"three together if any of them changes."
    )


def parse_applog(path: Path) -> int:
    """Report the board's GOLDEN verdict from a console log. Returns an exit code."""
    if not path.is_file():
        print(f"  [cmp]    {path} not found")
        return 2
    text = path.read_text(errors="replace")

    m = re.search(r"GOLDEN (PASS|FAIL)\s+(\d+)\s*/\s*(\d+)", text)
    if not m:
        hint = ("the run never reached the comparison"
                if "device_teardown done" not in text else
                "the ELF was built without conv2dstem_golden.h")
        print(f"  [cmp]    no GOLDEN verdict in {path} -- {hint}")
        return 2

    verdict, n, total = m.group(1), int(m.group(2)), int(m.group(3))
    for line in re.findall(r"^.*MISMATCH ofm\[.*$", text, re.M)[:8]:
        print(f"           {line.strip()}")
    print(f"  [cmp]    board vs CPU ground truth: GOLDEN {verdict} {n:,}/{total:,}")
    if verdict == "PASS":
        return 0
    print("           outer 3 rows/cols only -> zero-point border padding;\n"
          "           scattered -> the AIE data path (skill: datacorrectness).")
    return 1


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--applog", type=Path, default=None,
                    help="parse a board console log for the GOLDEN verdict and exit")
    ap.add_argument("image", nargs="?", default=None,
                    help="image path or URL (default: data/dog.jpg)")
    ap.add_argument("--onnx", default=None, help="int8 QDQ model")
    ap.add_argument("--out", type=Path,
                    default=fc.OUT_DIR / "conv2dstem_golden.h",
                    help="header to write (default: ../conv2dstem_golden.h)")
    ap.add_argument("--no-xcheck", action="store_true",
                    help="skip the onnxruntime cross-check")
    args = ap.parse_args(argv)

    if args.applog is not None:
        print("=== conv2dstem board comparison ===")
        return parse_applog(args.applog)

    print("=== conv2dstem ground truth ===")
    sp = fc.load_stem_params(args.onnx)

    npz = fc.DATA_DIR / "stem_fixture.npz"
    if npz.is_file():
        # Consume exactly the arrays the weight header was built from, so the
        # reference cannot drift from what the board is running.
        z = np.load(npz, allow_pickle=False)
        wts_ohwi, qp = z["wts_ohwi"], z["qp"]
        print(f"  [fixture] {npz.name} (same arrays as conv2dstem_weights.h)")
    else:
        wts_ohwi = sp.weight.transpose(0, 2, 3, 1).astype(np.int8)
        qp = fc.fold_qparams(sp).astype(np.int32)
        print("  [fixture] stem_fixture.npz absent -- re-deriving from the model "
              "(run make_weights_header.py --emit-npz to pin it)")

    pad4, _ = fc.preprocess_to_pad4(sp, args.image)
    ofm, acc = conv2d_stem_prepadded_ref(pad4, wts_ohwi, qp)
    peak = int(np.abs(acc).max())
    print(f"  [ref]    [{fc.OUT_H},{fc.OUT_W},{fc.OC}] uint8  min={int(ofm.min())} "
          f"max={int(ofm.max())} nonzero={int((ofm > 0).sum()):,}")
    print(f"           peak |accumulator| = {peak:,}  (int16 max 32,767 -- "
          f"{'int32 required' if peak > 32767 else 'fits int16'})")

    xchk = None
    if not args.no_xcheck:
        want = ort_reference(sp, args.image)
        xchk = int((ofm != want).sum())
        maxdiff = int(np.abs(ofm.astype(int) - want.astype(int)).max()) if xchk else 0
        verdict = ("rounding only" if maxdiff <= 1 else
                   "LARGER THAN ROUNDING -- check the scales/zero-points")
        print(f"  [xchk]   {ofm.size - xchk:,}/{ofm.size:,} agree with onnxruntime; "
              f"{xchk} differ, max {maxdiff} ({verdict})")

    fc.emit_header(args.out, GUARD, GENERATOR, build_prose(sp, ofm, acc, xchk),
                   [fc.hex_array("conv2dstem_golden_ofm", ofm,
                                 "CONV2DSTEM_DATA_GOLDEN_ELEMS")])
    print("\nNext: build and run, then\n"
          "  python3 src/aietensorop/conv2dstem/data/groundtruth.py --applog ./applog")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
