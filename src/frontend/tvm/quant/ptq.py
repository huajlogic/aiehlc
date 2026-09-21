###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Hand-rolled post-training int8 quantization for ResNet-18 v2.

TVM's PTQ (``relay.quantize``) does not exist in this install — Relay was
removed in 0.26 and no replacement quantizer ships with ``tvm.relax``. So the
scheme below is written out explicitly. That is not purely a workaround: the
emitted C has to implement exactly this arithmetic, and a scheme we wrote is one
we can transcribe line-by-line and verify, rather than reverse-engineer from a
compiler pass.

The scheme
----------
**Weights** — per-output-channel symmetric int8. Each output channel gets its
own scale ``sw[c] = max|W[c]| / 127``; zero-point is 0. Per-channel (rather than
per-tensor) matters a lot here: ResNet's channel magnitudes vary by 10-100x
within one layer, and a single tensor scale would flush the small channels to
zero.

**Activations** — per-tensor asymmetric uint8-style int8: ``q = round(x/sa) +
za`` clamped to [-128,127]. Asymmetric because post-ReLU activations are
one-sided ([0, max]); forcing them symmetric would waste half the range.

**Ranges** — collected by running the float model over calibration images and
taking a high percentile (not the absolute max, which a single outlier
activation would blow out).

**Requantization** — the integer pipeline accumulates in int32:
``acc = Σ (q_x - za_x) * q_w``. The result is brought back to int8 by a
single float multiplier ``M = (sa_in * sw) / sa_out``, folded with the BN affine
and the bias. In C this becomes a fixed-point multiply-and-shift; here it is
kept as float32 until the C-emit step, so quantization error and fixed-point
rounding error stay separable when debugging.

**BN folding** — a v2 block is pre-activation (BN -> ReLU -> Conv), so BN can
*not* fold into the conv that follows it the way it does in post-activation
nets: the ReLU sits between them. BN is therefore quantized as its own
per-channel affine op rather than being absorbed. This is the main structural
difference from a v1 quantization recipe and the reason the op list keeps a
standalone BN.
"""

from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple

import numpy as np

QMIN, QMAX = -128, 127


# ═══════════════════════════════════════════════════════════════════════════
#  Quantization primitives
# ═══════════════════════════════════════════════════════════════════════════

@dataclass
class QParam:
    """Affine quantization params for one tensor: ``x ≈ scale*(q - zp)``."""
    scale: float
    zp: int = 0

    def quantize(self, x: np.ndarray) -> np.ndarray:
        q = np.round(x / self.scale) + self.zp
        return np.clip(q, QMIN, QMAX).astype(np.int8)

    def dequantize(self, q: np.ndarray) -> np.ndarray:
        return (q.astype(np.float32) - self.zp) * self.scale


def choose_act_qparam(lo: float, hi: float) -> QParam:
    """Asymmetric int8 params covering ``[lo, hi]``.

    The zero-point is snapped to an integer so that float 0.0 maps exactly onto
    an integer — required for correct zero-padding in conv, where padded
    elements must contribute nothing.
    """
    lo = min(float(lo), 0.0)                 # always include 0
    hi = max(float(hi), 0.0)
    if hi - lo < 1e-12:                      # degenerate (all-constant) tensor
        return QParam(scale=1.0, zp=0)
    scale = (hi - lo) / (QMAX - QMIN)
    zp = int(np.clip(round(QMIN - lo / scale), QMIN, QMAX))
    return QParam(scale=scale, zp=zp)


def quantize_weights_per_channel(w: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
    """Symmetric per-output-channel int8 weights.

    ``w``: [Cout, ...]. Returns ``(q_w int8, scales float32[Cout])``. A channel
    that is entirely zero gets scale 1.0 to avoid a divide-by-zero; its
    quantized values are zero either way.
    """
    flat = w.reshape(w.shape[0], -1)
    amax = np.abs(flat).max(axis=1)
    scales = np.where(amax < 1e-12, 1.0, amax / QMAX).astype(np.float32)
    q = np.round(flat / scales[:, None])
    q = np.clip(q, QMIN, QMAX).astype(np.int8).reshape(w.shape)
    return q, scales


# ═══════════════════════════════════════════════════════════════════════════
#  Calibration — observe activation ranges on real data
# ═══════════════════════════════════════════════════════════════════════════

@dataclass
class RangeObserver:
    """Accumulates a tensor's value range across calibration batches.

    Keeps a histogram rather than a running min/max so a percentile can be
    taken: one saturating activation in one image should not set the scale for
    the whole layer.
    """
    lo: float = float("inf")
    hi: float = float("-inf")
    samples: List[np.ndarray] = field(default_factory=list)

    def observe(self, x: np.ndarray) -> None:
        self.lo = min(self.lo, float(x.min()))
        self.hi = max(self.hi, float(x.max()))
        # Subsample to bound memory; enough to estimate a percentile.
        flat = x.ravel()
        if flat.size > 4096:
            idx = np.linspace(0, flat.size - 1, 4096).astype(np.int64)
            flat = flat[idx]
        self.samples.append(flat.astype(np.float32))

    def qparam(self, percentile: float = 99.99) -> QParam:
        """Range at ``percentile`` of observed magnitudes (100 => true min/max)."""
        if percentile >= 100.0 or not self.samples:
            return choose_act_qparam(self.lo, self.hi)
        allv = np.concatenate(self.samples)
        lo = float(np.percentile(allv, 100.0 - percentile))
        hi = float(np.percentile(allv, percentile))
        return choose_act_qparam(lo, hi)
