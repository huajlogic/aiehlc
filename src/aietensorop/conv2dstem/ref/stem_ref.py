#!/usr/bin/env python3
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Ground-truth reference for the fused ResNet-18 stem conv, and a generator for
the fixture `conv2dstem` bring-up consumes.

This mirrors, exactly, what TVM emits for graph node 9 -- the fused op
``nn_contrib_conv2d_NCHWc_add_subtract_fixed_point_multiply_per_axis_clip_cast``.
The arithmetic is transcribed from the generated C
(``layers/01_*/*.c``), not reinvented::

    v = ((int64)((acc + bias[c]) - zp[c]) * mult[c]
         + ((int64)1 << (shift[c] + 30))) >> (shift[c] + 31);
    out[c] = (uint8)clip(v, 0, 255);          # the clip at 0 IS the ReLU

Two facts this file exists to pin down, both measured rather than assumed:

* **The accumulator must be int32.** With the real stem weights the worst-case
  |accumulator| is 1,182,116 against an int16 range of +-32,767 -- a 36x
  overflow. The kernel's original ``int16_t sum`` only ever looked correct
  because ``main.cc`` fed it synthetic values in [-4,4] x {-1,0,1}. Any check
  that does not use real weights will miss this.
* **Max-pool is NOT part of this op.** It is graph node 10, a separate
  ``fused_nn_max_pool2d``. The stem kernel must not pool.

Run directly to regenerate the fixture::

    <venv>/bin/python3 src/aietensorop/conv2dstem/ref/stem_ref.py --out <dir>
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

import numpy as np

# Geometry -- ResNet-18 conv1. Must agree with conv2dstem.h.
IN_H = IN_W = 224
IN_C = 3
K = 7
STRIDE = 2
PAD = 3
OC = 64
OUT_H = OUT_W = 112


def requantize(acc: np.ndarray, bias: np.ndarray, zp: np.ndarray,
               mult: np.ndarray, shift: np.ndarray) -> np.ndarray:
    """Per-channel fixed-point requantize + ReLU + uint8 cast.

    ``acc`` is [OH, OW, OC] int32/int64; the four parameter arrays are [OC].
    Returns uint8 [OH, OW, OC].

    The rounding term and the double shift are TVM's, reproduced verbatim --
    ``+ (1 << (shift+30))`` then ``>> (shift+31)``. Computed in int64 because
    ``acc * mult`` overflows int32 badly (mult is up to 2**31-ish).
    """
    acc64 = acc.astype(np.int64)
    m = mult.astype(np.int64)[None, None, :]
    s = shift.astype(np.int64)[None, None, :]
    biased = acc64 + bias.astype(np.int64)[None, None, :] - zp.astype(np.int64)[None, None, :]
    v = (biased * m + (np.int64(1) << (s + 30))) >> (s + 31)
    return np.clip(v, 0, 255).astype(np.uint8)


def conv2d_stem_ref(ifm: np.ndarray, wts: np.ndarray, bias: np.ndarray,
                    zp: np.ndarray, mult: np.ndarray,
                    shift: np.ndarray) -> tuple:
    """Fused stem conv. Returns ``(ofm_uint8[OH,OW,OC], acc_int32[OH,OW,OC])``.

    ``ifm`` is [H, W, C] (HWC, unpadded), ``wts`` is [OC, KH, KW, C].
    The raw accumulator is returned alongside the output so a caller can show
    how far past int16 it actually goes.
    """
    pad = np.zeros((IN_H + 2 * PAD, IN_W + 2 * PAD, IN_C), np.int64)
    pad[PAD:PAD + IN_H, PAD:PAD + IN_W, :] = ifm.astype(np.int64)

    # im2col: [OH*OW, K*K*C] @ [K*K*C, OC] -- one matmul beats 157M Python MACs.
    cols = np.empty((OUT_H * OUT_W, K * K * IN_C), np.int64)
    for oh in range(OUT_H):
        ih = oh * STRIDE
        for ow in range(OUT_W):
            iw = ow * STRIDE
            cols[oh * OUT_W + ow] = pad[ih:ih + K, iw:iw + K, :].reshape(-1)
    acc = (cols @ wts.astype(np.int64).reshape(OC, -1).T).reshape(OUT_H, OUT_W, OC)
    return requantize(acc, bias, zp, mult, shift), acc.astype(np.int64)


def load_params(params_bin: Path) -> dict:
    """Pull the stem's weights and quant parameters out of TVM's params blob.

    Weights arrive NCHWc-blocked as [OCo, ICo, KH, KW, IC, OCi]; this returns
    them de-blocked to the plain [OC, KH, KW, IC] the kernel wants.
    """
    sys.path.insert(0, str(Path(__file__).resolve().parents[3]))
    import frontend.tvmrelay  # noqa: F401  (installs the TVM 0.16 + onnx shims)
    import tvm

    p = tvm.runtime.load_param_dict(params_bin.read_bytes())
    blocked = p["p1"].numpy()                      # [16,1,7,7,3,4]
    wts = np.zeros((OC, K, K, IN_C), np.int8)
    for oco in range(blocked.shape[0]):
        for oci in range(blocked.shape[-1]):
            wts[oco * 4 + oci] = blocked[oco, 0, :, :, :, oci].astype(np.int8)
    return {
        "wts": wts,
        "bias": p["p2"].numpy().reshape(-1).astype(np.int32),
        "zp": p["p3"].numpy().reshape(-1).astype(np.int32),
        "mult": p["p4"].numpy().reshape(-1).astype(np.int32),
        "shift": p["p6"].numpy().reshape(-1).astype(np.int32),
    }


def write_fixture(out_dir: Path, ifm: np.ndarray, prm: dict,
                  ofm: np.ndarray) -> None:
    """Write the raw binaries `main.cc` loads, plus a packed param block.

    The param block is the on-core layout: 64 channels x 4 int32 LE fields in
    the order (bias, zero_point, multiplier, shift). One file keeps the C side
    to a single read and a single pointer.
    """
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "ifm.bin").write_bytes(ifm.astype(np.int8).tobytes())
    (out_dir / "wts.bin").write_bytes(prm["wts"].astype(np.int8).tobytes())
    (out_dir / "ofm_ref.bin").write_bytes(ofm.astype(np.uint8).tobytes())

    packed = bytearray()
    for c in range(OC):
        packed += struct.pack("<iiii", int(prm["bias"][c]), int(prm["zp"][c]),
                              int(prm["mult"][c]), int(prm["shift"][c]))
    (out_dir / "params.bin").write_bytes(bytes(packed))


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--out", type=Path,
                    default=Path("worklocal/stem_fixture"),
                    help="directory to write the fixture into")
    ap.add_argument("--params", type=Path,
                    default=Path("worklocal/tvmrelay_deploy/resnet18_params.bin"))
    args = ap.parse_args(argv)

    if not args.params.is_file():
        print(f"error: {args.params} not found -- run deploy_flow.py first",
              file=sys.stderr)
        return 2

    prm = load_params(args.params)
    # Deterministic pseudo-input in the int8 range. Real magnitudes on purpose:
    # the whole point is to drive the accumulator where int16 would wrap.
    rng = np.random.default_rng(0)
    ifm = rng.integers(-128, 128, size=(IN_H, IN_W, IN_C), dtype=np.int16).astype(np.int8)

    ofm, acc = conv2d_stem_ref(ifm, prm["wts"], prm["bias"], prm["zp"],
                               prm["mult"], prm["shift"])
    write_fixture(args.out, ifm, prm, ofm)

    peak = int(np.abs(acc).max())
    print(f"fixture -> {args.out}")
    print(f"  ifm      [{IN_H},{IN_W},{IN_C}] int8")
    print(f"  wts      [{OC},{K},{K},{IN_C}] int8")
    print(f"  params   {OC} x (bias, zp, mult, shift) int32")
    print(f"  ofm_ref  [{OUT_H},{OUT_W},{OC}] uint8  "
          f"min={ofm.min()} max={ofm.max()} nonzero={int((ofm > 0).sum())}")
    print(f"  peak |accumulator| = {peak:,}  (int16 max 32,767 -- "
          f"{'OVERFLOWS, int32 required' if peak > 32767 else 'fits int16'})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
