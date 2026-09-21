###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Float numpy forward pass for the real ImageNet ResNet-18 v2.

This is the **control** for the int8 quantization work: every quantized result
is judged against this, and this in turn is validated against the PyTorch
reference (``example/model/resnet18py/resnet18.py``) so a numpy bug cannot be
mistaken for quantization error.

Why numpy and not just torch
----------------------------
The int8 pipeline has to be transcribed into plain C eventually. Keeping the
float reference in numpy (same loop structure, same layer decomposition) means
the quantized version is a local edit of *this* code rather than a
reinterpretation of torch semantics — and the C is in turn a transcription of
the quantized numpy. Each step is a small diff against something already
verified.

Network shape (resnet18-v2-7, pre-activation)::

    data -> BN0 -> Conv7x7/s2 -> BN -> ReLU -> MaxPool3x3/s2
         -> stage1..4 (2 BasicBlockV2 each)
         -> BN -> ReLU -> GlobalAvgPool -> Gemm(512->1000)

Note the v2 block is **pre-activation**: ``preact = relu(bn1(x))`` feeds both
the conv path and (when downsampling) the 1x1 skip projection. That ordering is
load-bearing — the skip is taken from the *pre-activated* tensor, not from x.
"""

from typing import Dict, List, Tuple

import numpy as np

BN_EPS = 1e-5


# ═══════════════════════════════════════════════════════════════════════════
#  Primitive layers (NCHW, float32)
# ═══════════════════════════════════════════════════════════════════════════

def conv2d(x: np.ndarray, w: np.ndarray, stride: int = 1,
           pad: int = 0) -> np.ndarray:
    """NCHW conv via im2col. ``x``: [N,Cin,H,W], ``w``: [Cout,Cin,KH,KW]."""
    N, Cin, H, W = x.shape
    Cout, _, KH, KW = w.shape
    if pad:
        x = np.pad(x, ((0, 0), (0, 0), (pad, pad), (pad, pad)))
    OH = (x.shape[2] - KH) // stride + 1
    OW = (x.shape[3] - KW) // stride + 1
    # im2col: [N, Cin*KH*KW, OH*OW] — one GEMM beats six nested python loops by
    # ~1000x here, and this reference is run on every calibration image.
    cols = np.empty((N, Cin * KH * KW, OH * OW), dtype=np.float32)
    for kh in range(KH):
        for kw in range(KW):
            patch = x[:, :, kh:kh + OH * stride:stride, kw:kw + OW * stride:stride]
            cols[:, (kh * KW + kw) * Cin:(kh * KW + kw + 1) * Cin, :] = \
                patch.reshape(N, Cin, -1)
    # Reorder w to match the (kh,kw,cin) column ordering built above.
    w2 = w.transpose(2, 3, 1, 0).reshape(-1, Cout)       # [KH*KW*Cin, Cout]
    out = np.einsum("nkp,kc->ncp", cols, w2)
    return out.reshape(N, Cout, OH, OW)


def batchnorm(x: np.ndarray, gamma: np.ndarray, beta: np.ndarray,
              mean: np.ndarray, var: np.ndarray,
              eps: float = BN_EPS) -> np.ndarray:
    """Per-channel affine: ``gamma*(x-mean)/sqrt(var+eps) + beta``."""
    scale = gamma / np.sqrt(var + eps)
    shift = beta - mean * scale
    return x * scale[None, :, None, None] + shift[None, :, None, None]


def bn_to_affine(gamma: np.ndarray, beta: np.ndarray, mean: np.ndarray,
                 var: np.ndarray, eps: float = BN_EPS
                 ) -> Tuple[np.ndarray, np.ndarray]:
    """Collapse BN params to per-channel ``(scale, shift)``.

    A BatchNorm at inference is exactly ``y = scale*x + shift``. Precomputing
    this is what lets the quantizer treat BN as a cheap per-channel affine
    instead of carrying four parameter tensors into int8.
    """
    scale = gamma / np.sqrt(var + eps)
    return scale.astype(np.float32), (beta - mean * scale).astype(np.float32)


def relu(x: np.ndarray) -> np.ndarray:
    return np.maximum(x, 0.0)


def maxpool2d(x: np.ndarray, k: int = 3, stride: int = 2,
              pad: int = 1) -> np.ndarray:
    """NCHW max pool. Pads with -inf so padding never wins the max."""
    N, C, H, W = x.shape
    if pad:
        x = np.pad(x, ((0, 0), (0, 0), (pad, pad), (pad, pad)),
                   constant_values=-np.inf)
    OH = (x.shape[2] - k) // stride + 1
    OW = (x.shape[3] - k) // stride + 1
    out = np.full((N, C, OH, OW), -np.inf, dtype=np.float32)
    for kh in range(k):
        for kw in range(k):
            out = np.maximum(
                out, x[:, :, kh:kh + OH * stride:stride,
                       kw:kw + OW * stride:stride])
    return out


def global_avgpool(x: np.ndarray) -> np.ndarray:
    """[N,C,H,W] -> [N,C] mean over spatial dims."""
    return x.mean(axis=(2, 3))


def gemm(x: np.ndarray, w: np.ndarray, b: np.ndarray) -> np.ndarray:
    """[N,Cin] @ [Cout,Cin]^T + [Cout] -> [N,Cout]."""
    return x @ w.T + b


# ═══════════════════════════════════════════════════════════════════════════
#  Weight loading (ONNX initializers, matched by the resnetv22_* naming)
# ═══════════════════════════════════════════════════════════════════════════

def load_onnx_initializers(onnx_path: str) -> Dict[str, np.ndarray]:
    """Return every initializer in ``onnx_path`` as a numpy array by name."""
    import onnx
    from onnx import numpy_helper
    model = onnx.load(onnx_path)
    return {t.name: numpy_helper.to_array(t).astype(np.float32)
            for t in model.graph.initializer}


def _bn(W: Dict[str, np.ndarray], prefix: str) -> Tuple[np.ndarray, ...]:
    """Fetch a BN's (gamma, beta, mean, var) by ONNX name prefix."""
    return (W[f"{prefix}_gamma"], W[f"{prefix}_beta"],
            W[f"{prefix}_running_mean"], W[f"{prefix}_running_var"])


class ResNet18V2NP:
    """Float numpy ResNet-18 v2 with weights loaded from the ONNX file.

    Layer naming follows the ONNX initializers (``resnetv22_*``) so the mapping
    is checkable by eye against the graph dump.
    """

    def __init__(self, onnx_path: str):
        self.W = load_onnx_initializers(onnx_path)
        self._build()

    def _build(self) -> None:
        W = self.W
        self.bn0 = _bn(W, "resnetv22_batchnorm0")
        self.conv0 = W["resnetv22_conv0_weight"]
        self.bn1 = _bn(W, "resnetv22_batchnorm1")
        # Per stage: two BasicBlockV2. Stages 2-4's first block downsamples,
        # which adds a 1x1 conv on the pre-activated input.
        self.stages: List[List[dict]] = []
        for s in range(1, 5):
            p = f"resnetv22_stage{s}"
            blocks, conv_i, bn_i = [], 0, 0
            for b in range(2):
                blk = {
                    "bn1": _bn(W, f"{p}_batchnorm{bn_i}"),
                    "conv1": W[f"{p}_conv{conv_i}_weight"],
                    "bn2": _bn(W, f"{p}_batchnorm{bn_i + 1}"),
                    "conv2": W[f"{p}_conv{conv_i + 1}_weight"],
                    "down": None,
                    "stride": 2 if (s > 1 and b == 0) else 1,
                }
                bn_i += 2
                conv_i += 2
                if s > 1 and b == 0:      # downsample projection
                    blk["down"] = W[f"{p}_conv{conv_i}_weight"]
                    conv_i += 1
                blocks.append(blk)
            self.stages.append(blocks)
        self.bn2 = _bn(W, "resnetv22_batchnorm2")
        self.fc_w = W["resnetv22_dense0_weight"]
        self.fc_b = W["resnetv22_dense0_bias"]

    def forward(self, x: np.ndarray) -> np.ndarray:
        """``x``: [N,3,224,224] float32 (ImageNet-normalized) -> [N,1000]."""
        x = batchnorm(x, *self.bn0)
        x = conv2d(x, self.conv0, stride=2, pad=3)
        x = relu(batchnorm(x, *self.bn1))
        x = maxpool2d(x, 3, 2, 1)
        for blocks in self.stages:
            for blk in blocks:
                preact = relu(batchnorm(x, *blk["bn1"]))
                out = conv2d(preact, blk["conv1"], stride=blk["stride"], pad=1)
                out = relu(batchnorm(out, *blk["bn2"]))
                out = conv2d(out, blk["conv2"], stride=1, pad=1)
                # The skip is taken from preact (not x) whenever we project.
                skip = (conv2d(preact, blk["down"], stride=blk["stride"], pad=0)
                        if blk["down"] is not None else x)
                x = out + skip
        x = relu(batchnorm(x, *self.bn2))
        x = global_avgpool(x)
        return gemm(x, self.fc_w, self.fc_b)
