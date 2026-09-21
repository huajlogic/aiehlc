###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Fully-quantized int8 ResNet-18 v2 — the oracle the emitted C must match.

Every tensor crossing a layer boundary is int8; every accumulation is int32.
This is the numerical contract the generated C implements, so the loop structure
here is deliberately C-shaped (explicit accumulate, explicit requantize) even
where numpy could vectorize it away.

Pipeline per conv::

    acc[int32] = Σ (q_in[int8] - zp_in) * q_w[int8]        # exact integer
    real       = acc * (s_in * s_w[c])                     # back to float scale
    y          = real * bn_scale[c] + bn_shift[c]          # folded BN (if any)
    q_out      = clip(round(y / s_out) + zp_out, -128, 127)

The multiplier ``(s_in*s_w[c])/s_out`` is kept in float32 here. Converting it to
a fixed-point multiply+shift is a separate, later step: keeping them apart means
a quantization-accuracy bug and a fixed-point-rounding bug cannot be confused.

``calibrate()`` runs the float model to observe real activation ranges — the
scales are data-dependent, so this needs representative images, not noise.
"""

from typing import Dict, List, Optional

import numpy as np

from .ptq import (QMAX, QMIN, QParam, RangeObserver, choose_act_qparam,
                  quantize_weights_per_channel)
from .resnet_np import (ResNet18V2NP, batchnorm, bn_to_affine, conv2d,
                        global_avgpool, maxpool2d, relu)


def _conv_int(q_x: np.ndarray, zp_x: int, q_w: np.ndarray, stride: int,
              pad: int) -> np.ndarray:
    """Integer conv: returns int32 ``Σ (q_x - zp_x) * q_w``.

    Padding is applied to the *quantized* tensor with value ``zp_x`` so that,
    after the ``- zp_x`` shift, padded elements contribute exactly zero — the
    same thing float zero-padding does. Padding with integer 0 instead would
    inject a spurious ``-zp_x`` into every border accumulation.
    """
    x = q_x.astype(np.int32) - zp_x
    w = q_w.astype(np.int32)
    return conv2d(x.astype(np.float32), w.astype(np.float32),
                  stride=stride, pad=pad).round().astype(np.int32)


class QuantResNet18:
    """int8 ResNet-18 v2. Build with ``from_float`` after calibration."""

    def __init__(self) -> None:
        self.qp: Dict[str, QParam] = {}       # activation qparams by tag
        self.qw: Dict[str, np.ndarray] = {}   # int8 weights by tag
        self.sw: Dict[str, np.ndarray] = {}   # per-channel weight scales
        self.bn: Dict[str, tuple] = {}        # folded BN (scale, shift)
        self.fc_b: Optional[np.ndarray] = None
        self.struct: List[dict] = []          # per-block stride/downsample

    # ── calibration ────────────────────────────────────────────────────────
    @staticmethod
    def calibrate(net: ResNet18V2NP, images: List[np.ndarray],
                  percentile: float = 99.99) -> Dict[str, QParam]:
        """Observe activation ranges by running the float model.

        Returns a tag -> QParam map. Tags mirror the forward pass exactly, so a
        missing tag surfaces as a KeyError at quantize time rather than a
        silently wrong scale.
        """
        obs: Dict[str, RangeObserver] = {}

        def note(tag: str, v: np.ndarray) -> np.ndarray:
            obs.setdefault(tag, RangeObserver()).observe(v)
            return v

        for x in images:
            h = note("input", x)
            h = note("bn0", batchnorm(h, *net.bn0))
            h = note("conv0", conv2d(h, net.conv0, stride=2, pad=3))
            h = note("stem_act", relu(batchnorm(h, *net.bn1)))
            h = note("pool0", maxpool2d(h, 3, 2, 1))
            for si, blocks in enumerate(net.stages):
                for bi, blk in enumerate(blocks):
                    t = f"s{si}b{bi}"
                    pre = note(f"{t}_preact", relu(batchnorm(h, *blk["bn1"])))
                    o = note(f"{t}_c1", conv2d(pre, blk["conv1"],
                                               stride=blk["stride"], pad=1))
                    o = note(f"{t}_act2", relu(batchnorm(o, *blk["bn2"])))
                    o = note(f"{t}_c2", conv2d(o, blk["conv2"], stride=1, pad=1))
                    if blk["down"] is not None:
                        sk = note(f"{t}_down", conv2d(pre, blk["down"],
                                                      stride=blk["stride"], pad=0))
                    else:
                        sk = h
                    h = note(f"{t}_out", o + sk)
            h = note("tail_act", relu(batchnorm(h, *net.bn2)))
            g = note("gap", global_avgpool(h))
            note("logits", g @ net.fc_w.T + net.fc_b)
        return {k: v.qparam(percentile) for k, v in obs.items()}

    # ── build ──────────────────────────────────────────────────────────────
    @classmethod
    def from_float(cls, net: ResNet18V2NP,
                   qp: Dict[str, QParam]) -> "QuantResNet18":
        """Quantize ``net``'s weights; adopt calibrated activation ``qp``."""
        q = cls()
        q.qp = qp
        q.qw["conv0"], q.sw["conv0"] = quantize_weights_per_channel(net.conv0)
        q.bn["bn0"] = bn_to_affine(*net.bn0)
        q.bn["bn1"] = bn_to_affine(*net.bn1)
        for si, blocks in enumerate(net.stages):
            for bi, blk in enumerate(blocks):
                t = f"s{si}b{bi}"
                q.bn[f"{t}_bn1"] = bn_to_affine(*blk["bn1"])
                q.bn[f"{t}_bn2"] = bn_to_affine(*blk["bn2"])
                q.qw[f"{t}_c1"], q.sw[f"{t}_c1"] = \
                    quantize_weights_per_channel(blk["conv1"])
                q.qw[f"{t}_c2"], q.sw[f"{t}_c2"] = \
                    quantize_weights_per_channel(blk["conv2"])
                if blk["down"] is not None:
                    q.qw[f"{t}_down"], q.sw[f"{t}_down"] = \
                        quantize_weights_per_channel(blk["down"])
                q.struct.append({"tag": t, "stride": blk["stride"],
                                 "down": blk["down"] is not None})
        q.bn["bn2"] = bn_to_affine(*net.bn2)
        q.qw["fc"], q.sw["fc"] = quantize_weights_per_channel(net.fc_w)
        q.fc_b = net.fc_b
        return q

    # ── helpers ────────────────────────────────────────────────────────────
    def _requant(self, acc: np.ndarray, s_in: float, s_w: np.ndarray,
                 out_tag: str, bn_tag: Optional[str] = None,
                 do_relu: bool = False) -> np.ndarray:
        """int32 accumulator -> int8, applying optional BN affine and ReLU.

        BN is applied in the *real* domain (after undoing the integer scales)
        because its per-channel scale/shift are float; the whole chain then
        collapses into one round-and-clip to the output scale.
        """
        real = acc.astype(np.float32) * (s_in * s_w)[None, :, None, None]
        if bn_tag is not None:
            sc, sh = self.bn[bn_tag]
            real = real * sc[None, :, None, None] + sh[None, :, None, None]
        if do_relu:
            real = np.maximum(real, 0.0)
        return self.qp[out_tag].quantize(real)

    def _dq(self, q: np.ndarray, tag: str) -> np.ndarray:
        return self.qp[tag].dequantize(q)

    # ── forward ────────────────────────────────────────────────────────────
    def forward(self, x: np.ndarray) -> np.ndarray:
        """``x``: float32 [N,3,224,224] -> float32 logits [N,1000].

        The input is quantized on entry and the logits dequantized on exit;
        everything between is int8 tensors and int32 accumulators.
        """
        qx = self.qp["input"].quantize(x)

        # Stem: BN0 is a standalone affine (no conv to fold into), then conv0.
        real = self._dq(qx, "input")
        sc, sh = self.bn["bn0"]
        real = real * sc[None, :, None, None] + sh[None, :, None, None]
        q = self.qp["bn0"].quantize(real)

        acc = _conv_int(q, self.qp["bn0"].zp, self.qw["conv0"], stride=2, pad=3)
        q = self._requant(acc, self.qp["bn0"].scale, self.sw["conv0"],
                          "stem_act", bn_tag="bn1", do_relu=True)
        # MaxPool commutes with a monotonic affine, so it runs directly on int8.
        q = maxpool2d(q.astype(np.float32), 3, 2, 1).astype(np.int8)
        cur_tag = "stem_act"

        for blk in self.struct:
            t = blk["tag"]
            # pre-activation: BN -> ReLU on the block input
            real = self._dq(q, cur_tag)
            sc, sh = self.bn[f"{t}_bn1"]
            pre_f = np.maximum(real * sc[None, :, None, None]
                               + sh[None, :, None, None], 0.0)
            q_pre = self.qp[f"{t}_preact"].quantize(pre_f)

            acc = _conv_int(q_pre, self.qp[f"{t}_preact"].zp,
                            self.qw[f"{t}_c1"], stride=blk["stride"], pad=1)
            q_o = self._requant(acc, self.qp[f"{t}_preact"].scale,
                                self.sw[f"{t}_c1"], f"{t}_act2",
                                bn_tag=f"{t}_bn2", do_relu=True)

            acc = _conv_int(q_o, self.qp[f"{t}_act2"].zp, self.qw[f"{t}_c2"],
                            stride=1, pad=1)
            out_f = (acc.astype(np.float32)
                     * (self.qp[f"{t}_act2"].scale * self.sw[f"{t}_c2"])
                     [None, :, None, None])

            if blk["down"]:
                acc_d = _conv_int(q_pre, self.qp[f"{t}_preact"].zp,
                                  self.qw[f"{t}_down"], stride=blk["stride"],
                                  pad=0)
                skip_f = (acc_d.astype(np.float32)
                          * (self.qp[f"{t}_preact"].scale * self.sw[f"{t}_down"])
                          [None, :, None, None])
            else:
                skip_f = self._dq(q, cur_tag)

            q = self.qp[f"{t}_out"].quantize(out_f + skip_f)
            cur_tag = f"{t}_out"

        real = self._dq(q, cur_tag)
        sc, sh = self.bn["bn2"]
        real = np.maximum(real * sc[None, :, None, None]
                          + sh[None, :, None, None], 0.0)
        q = self.qp["tail_act"].quantize(real)

        g = global_avgpool(self._dq(q, "tail_act"))
        qg = self.qp["gap"].quantize(g)
        acc = (qg.astype(np.int32) - self.qp["gap"].zp) @ self.qw["fc"].astype(np.int32).T
        return acc.astype(np.float32) * (self.qp["gap"].scale * self.sw["fc"])[None, :] \
            + self.fc_b[None, :]
