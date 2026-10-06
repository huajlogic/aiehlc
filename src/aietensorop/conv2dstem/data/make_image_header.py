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
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import fixture_common as fc  # noqa: E402

GUARD = "AIETENSOROP_CONV2DSTEM_IMAGE_H"
GENERATOR = "src/aietensorop/conv2dstem/data/make_image_header.py"


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
    ap.add_argument("--out", type=Path,
                    default=fc.OUT_DIR / "conv2dstem_image.h",
                    help="header to write (default: ../conv2dstem_image.h)")
    args = ap.parse_args(argv)

    print("=== conv2dstem image fixture ===")
    sp = fc.load_stem_params(args.onnx)
    pad4, image_path = fc.preprocess_to_pad4(sp, args.image)

    if pad4.size != fc.IFM_PAD4_ELEMS:
        raise SystemExit(f"internal error: {pad4.size} elements, "
                         f"expected {fc.IFM_PAD4_ELEMS}")

    fc.emit_header(
        args.out, GUARD, GENERATOR, build_prose(sp, image_path, pad4),
        [fc.hex_array("conv2dstem_ifm_pad4", pad4, "CONV2DSTEM_DATA_IFM_ELEMS")])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
