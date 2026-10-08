#!/usr/bin/env python3
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Turn a photo into the input-feature-map header conv2dstem's main.cc consumes.

    dog.jpg -> ImageNet preprocess -> int8 quantize -> zero-point pad -> HWC4
            -> ../conv2dstem_image.h

Run it with no arguments to regenerate the committed fixture::

    python3 src/aietensorop/conv2dstem/data/make_image_header.py

The emitted array is **byte-for-byte the contents of ``g_ifm_pad``**
(``conv2dstem.cc:487``) -- spatially pre-padded to [230,230] and channel-aligned
to 4 -- so the board does no scatter at all: ``main.cc`` memcpy's it straight
into the DMA staging buffer.

Why pre-padded rather than the raw [224,224,3] the ``conv2d_stem()`` entry
takes: the quantized graph pads the convolution's 3-pixel border with the input
**zero-point** (113), because ONNX pads the dequantized tensor with 0.0 and 0.0
dequantizes from ``x_q = zp``. ``conv2d_stem()`` would re-pad with zero, which
is wrong on every border pixel. See conv2dstem.h:144-159.

The scale and zero-point are read out of the quantized model, never hardcoded --
see fixture_common.load_stem_params. The float preprocessing is shared with the
reference classifier rather than reimplemented (fixture_common.preprocess_to_pad4).

``--tvm-layer0`` emits what ``deploy_flow.py`` holds after its first layer,
to ``../conv2dstem_image_tvm.h``::

    python3 .../make_image_header.py --tvm-layer0
    python3 .../make_image_header.py --tvm-layer0 --verify-kernel

It does not convert the fixture; it **runs the kernel's own two steps**,
``fixture_common.tvm_quantize_u8`` then ``fixture_common.tvm_layer0``, in the
same order and the same float32 precision as
``tvmgen_default_fused_divide_round_add_clip_cast_subtract_layout_transform``::

    v = roundf(x * 53.78862f) + 113.0f          # quantize   (C roundf:
    v = min(v, 255.0f); v = max(v, 0.0f)        #             ties AWAY from 0)
    out[h*672 + w*3 + c] = (int16_t)v - p1[0]   # cast + layout, p1[0] = 113

The float literals are **read out of the generated C**
(``parse_tvm_layer0_consts``), not recomputed: TVM emits the scale reciprocal
to 7 significant digits, which is not bit-identical to
``float32(1/in_scale) = 53.788624``.

``--verify-kernel`` compiles that kernel from its own source and runs it on the
same image through TVM's packed ABI, then diffs the two buffers — the only
check that compares against the compiled code rather than against a reading of
it. Current result on dog.jpg: **all 150,528 values match**.

Every run also asserts the result equals ``pad4_to_tvm_layer0(pad4)``, so the
two front ends cannot drift apart unnoticed. The three differences from
``conv2dstem_image.h`` are therefore representational, not numerical:

===========  ====================  ==========================================
             conv2dstem_image.h    TVM layer 0
===========  ====================  ==========================================
offset       ``x_u8 - 128``        ``x_u8 - in_zp`` (113) -- the two differ by
                                   the constant ``128 - in_zp`` = 15
dtype        int8 ([-128, 127])    int16; [-113, 142] does not fit int8
border       3 px of ``in_zp``,    none, [224,224] -- TVM pads inside the
             giving [230,230]      conv op downstream, not here
channels     4 (ch3 = alignment)   3
===========  ====================  ==========================================

Layout is HWC on both sides; TVM indexes ``h*672 + w*3 + c``. The header is a
diffing aid only -- ``conv2dstem.cc`` consumes ``conv2dstem_image.h``, and
``--tvm-layer0`` never overwrites it.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import fixture_common as fc  # noqa: E402

GUARD = "AIETENSOROP_CONV2DSTEM_IMAGE_H"
TVM_GUARD = "AIETENSOROP_CONV2DSTEM_IMAGE_TVM_H"
GENERATOR = "src/aietensorop/conv2dstem/data/make_image_header.py"


def build_tvm_prose(sp, image_path, tvm, consts) -> str:
    """Banner for ``--tvm-layer0``: what makes this NOT the AIE fixture."""
    try:
        shown = Path(image_path).resolve().relative_to(fc.REPO)
    except ValueError:
        shown = Path(image_path).name
    h, w, c = tvm.shape
    return (
        f"Layer-0 output of the TVM-generated ResNet-18, from:\n"
        f"    {shown}\n"
        f"\n"
        f"Byte-identical to what\n"
        f"  tvmgen_default_fused_divide_round_add_clip_cast_subtract_layout_transform\n"
        f"writes into its output tensor (worklocal/tvmrelay_deploy/layers/00_*/).\n"
        f"Verified against the compiled kernel itself, not just by inspection:\n"
        f"  python3 data/make_image_header.py --tvm-layer0 --verify-kernel\n"
        f"\n"
        f"The kernel's own two steps, run step for step in float32:\n"
        f"  quantize   v  = roundf(x * {consts['recip']:.9g}) + {consts['zp_add']:g}\n"
        f"             v  = clip(v, {consts['clip_lo']:g}, {consts['clip_hi']:g})\n"
        f"  cast+shift out[h*{w * c} + w*{c} + c] = (int16)v - {sp.in_zp}\n"
        f"The literals are read out of the generated C, not recomputed: TVM\n"
        f"emits the scale reciprocal to 7 significant digits, which is not\n"
        f"bit-identical to float32(1/in_scale) = {float(1.0 / sp.in_scale):.9g}.\n"
        f"roundf is round-half-AWAY-FROM-ZERO; the ONNX/fixture side uses\n"
        f"round-half-to-even. They agree on this image.\n"
        f"\n"
        f"This is the SAME quantization as conv2dstem_image.h -- verified\n"
        f"bit-exact over all {h * w * c:,} values -- in a different\n"
        f"representation. Three differences, and all three are deliberate:\n"
        f"\n"
        f"  offset   TVM subtracts the zero-point ({sp.in_zp}), giving\n"
        f"           [{int(tvm.min())}, {int(tvm.max())}]. The AIE fixture subtracts 128 so the\n"
        f"           result fits int8. The gap is the constant {128 - sp.in_zp}.\n"
        f"  dtype    int16, because [-{sp.in_zp}, {255 - sp.in_zp}] does not fit int8.\n"
        f"  border   none. TVM's layer 0 is [{h},{w},{c}] unpadded; the conv's\n"
        f"           3-px zero-point border is applied downstream, inside the\n"
        f"           conv op. The AIE fixture pre-pads to [230,230] because the\n"
        f"           kernel does not pad.\n"
        f"  channels {c}, not channel-aligned to {fc.C_ALIGN}.\n"
        f"\n"
        f"Layout is HWC in both; TVM indexes h*{w * c} + w*{c} + c.\n"
        f"\n"
        f"NOT consumed by conv2dstem.cc -- this header exists to diff the two\n"
        f"front-ends against each other. See conv2dstem_image.h for the real\n"
        f"g_ifm_pad fixture."
    )


def build_prose(sp, image_path, pad4) -> str:
    hp, wp = pad4.shape[0], pad4.shape[1]
    nz = int((pad4[:, :, :fc.IN_C] != 0).sum())
    # Repo-relative when it is in-tree, so the banner does not carry a
    # machine-specific absolute path into git.
    try:
        shown = Path(image_path).resolve().relative_to(fc.REPO)
    except ValueError:
        shown = Path(image_path).name
    return (
        f"Input feature map for the ResNet-18 stem conv, from:\n"
        f"    {shown}\n"
        f"\n"
        f"ImageNet preprocessing (example/model/resnet18py/classify.py:preprocess):\n"
        f"resize shorter side to 256, center-crop 224, scale to [0,1], subtract\n"
        f"mean [0.485, 0.456, 0.406], divide by std [0.229, 0.224, 0.225].\n"
        f"\n"
        f"Then the quantized graph's own input handling, read from\n"
        f"    {sp.model.name}\n"
        f"  quantize   x_u8 = clip(round(x / {sp.in_scale:.8g}) + {sp.in_zp}, 0, 255)\n"
        f"  pad        3 px on every spatial border with the ZERO-POINT ({sp.in_zp}),\n"
        f"             not zero -- ONNX pads the dequantized tensor with 0.0\n"
        f"  shift      x_s8 = x_u8 - 128  (border becomes {sp.in_zp - 128})\n"
        f"  layout     NCHW -> HWC4 [{hp},{wp},{fc.C_ALIGN}]\n"
        f"\n"
        f"Channel 3 is the alignment pad and is zero everywhere; the core's MAC\n"
        f"loop stops at SP_REAL_C (conv2dstem.cc:371) so nothing reads it.\n"
        f"\n"
        f"This is exactly the byte image of g_ifm_pad (conv2dstem.cc:487), so\n"
        f"main.cc memcpy's it in with no reordering.\n"
        f"{nz:,} of {hp * wp * fc.IN_C:,} real-channel bytes are non-zero.\n"
        f"\n"
        f"Emitted as uint8_t, cast to const int8_t* at the use site: a hex\n"
        f"initializer for int8_t would rely on an implementation-defined\n"
        f"out-of-range conversion."
    )


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("image", nargs="?", default=None,
                    help="image path or URL (default: data/dog.jpg)")
    ap.add_argument("--onnx", default=None,
                    help="int8 QDQ model (default: the cached/quantized ResNet-18)")
    ap.add_argument("--out", type=Path, default=None,
                    help="header to write (default: ../conv2dstem_image.h, "
                         "or ../conv2dstem_image_tvm.h with --tvm-layer0)")
    ap.add_argument("--tvm-layer0", action="store_true",
                    help="emit TVM's layer-0 form instead of the AIE fixture: "
                         "int16 [224,224,3] HWC, zero-point-subtracted and "
                         "UNpadded -- byte-identical to what "
                         "tvmgen_default_fused_divide_round_add_clip_cast_"
                         "subtract_layout_transform writes. Does NOT overwrite "
                         "conv2dstem_image.h, which conv2dstem.cc consumes")
    ap.add_argument("--verify-kernel", action="store_true",
                    help="with --tvm-layer0: compile and RUN the generated "
                         "layer-0 kernel from worklocal/tvmrelay_deploy and "
                         "diff its output against this one. The only check "
                         "that compares against the compiled code rather than "
                         "against a reading of it")
    args = ap.parse_args(argv)

    print("=== conv2dstem image fixture ===")
    sp = fc.load_stem_params(args.onnx)
    pad4, image_path = fc.preprocess_to_pad4(sp, args.image)

    if pad4.size != fc.IFM_PAD4_ELEMS:
        raise SystemExit(f"internal error: {pad4.size} elements, "
                         f"expected {fc.IFM_PAD4_ELEMS}")

    if args.tvm_layer0:
        # The kernel's own two steps -- quantize, then cast + layout transform
        # -- run step for step (fixture_common.tvm_quantize_u8 / tvm_layer0),
        # with the float literals read out of the generated C rather than
        # recomputed. Not derived from pad4 by arithmetic.
        tvm, _, consts = fc.preprocess_to_tvm_layer0(sp, args.image)

        # The two descriptions of one quantization, checked against each other
        # every run. They are provably equal (offset by 128 - in_zp over the
        # unpadded interior); if that ever stops holding, one of the two front
        # ends has changed and the header would be quietly wrong.
        derived = fc.pad4_to_tvm_layer0(pad4, sp)
        if not np.array_equal(tvm, derived):
            bad = int((tvm != derived).sum())
            raise SystemExit(
                f"TVM layer 0 and the AIE fixture disagree on {bad} of "
                f"{tvm.size} values (max |diff| "
                f"{int(np.abs(tvm.astype(np.int32) - derived.astype(np.int32)).max())}). "
                f"They are the same quantization, so this means one side "
                f"changed: check round-half-away-from-zero vs round-half-even "
                f"and the {consts['recip']:.9g} reciprocal.")
        print(f"  [check]  == pad4[3:-3,3:-3,:3] + {128 - sp.in_zp} over all "
              f"{tvm.size:,} values")

        if args.verify_kernel:
            import classify  # already on sys.path via preprocess_to_tvm_layer0
            x = np.asarray(classify.preprocess(image_path), np.float32)
            v = fc.verify_against_kernel(tvm, x, sp.in_zp)
            if not v["ok"]:
                for line in (v.get("stderr") or "").strip().splitlines()[-5:]:
                    print(f"  [verify]   {line}")
                raise SystemExit(f"--verify-kernel failed: "
                                 f"{v.get('reason', 'outputs differ')}")

        out = args.out or (fc.OUT_DIR / "conv2dstem_image_tvm.h")
        fc.emit_header(
            out, TVM_GUARD, GENERATOR,
            build_tvm_prose(sp, image_path, tvm, consts),
            [fc.i16_array("conv2dstem_ifm_tvm_layer0", tvm,
                          "CONV2DSTEM_DATA_IFM_TVM_ELEMS")])
        return 0

    fc.emit_header(
        args.out or (fc.OUT_DIR / "conv2dstem_image.h"),
        GUARD, GENERATOR, build_prose(sp, image_path, pad4),
        [fc.hex_array("conv2dstem_ifm_pad4", pad4, "CONV2DSTEM_DATA_IFM_ELEMS")])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
