###############################################################################
# Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Scaled-down int8 ResNet-18 model + canonical AIE launch plan.

This module is the single source of truth for the scaled network the TVM
frontend compiles onto the AIE mesh. It provides three things:

1. ``build_torch_model()`` — a small *post-activation* ResNet (torch.nn) whose
   op structure mirrors ``example/tileprogram/design/triton/resnet18_triton.py``
   (conv+BN+ReLU stem, four stages of BasicBlocks with 1x1 downsample, GAP, FC).
   ``export_onnx()`` writes it to an ONNX file so the Relay importer
   (``relay_import.py``) has a real graph to walk.

2. ``layer_plan()`` — the canonical sequence of AIE kernel launches
   (``LayerOp`` list) that the network lowers to. ``walk.py`` reconstructs this
   same plan from the fused Relay graph; the frontend cross-checks the two.

3. ``make_conv_params()`` / ``make_fc_params()`` — deterministic Q7 int8 param
   buffers (matches ``resnet18_triton.py`` / ``resnet18.cc`` exactly). The
   scaled model has no pretrained weights, so numeric compute uses these fixed
   patterns, which keeps the AIE result and the CPU reference bit-exact.

Dimensions (scaled-down ResNet18, matches resnet18.cc defines):
    input 8x8x1, channels 4->8->16->32, 4 classes, int8 + Q7 BN.
"""

from dataclasses import dataclass, field
from typing import List, Optional

import numpy as np

# ── Dimensions (identical to resnet18_triton.py) ────────────────────────────
INPUT_H, INPUT_W, INPUT_C = 8, 8, 1
NUM_CLASSES = 4
CH0, CH1, CH2, CH3 = 4, 8, 16, 32
S0, S1, S2, S3 = 8, 4, 2, 1

BN_SCALE_DEFAULT = 64  # 0.5 in Q7 (64/128)
BN_BIAS_DEFAULT = 0

CONFIG_SZ = 6    # conv params header: {H, W, Cin, Cout, K, stride}
FC_CONFIG_SZ = 4  # fc params header:   {spatial_h, spatial_w, channels, num_classes}


# ═══════════════════════════════════════════════════════════════════════════
#  Launch plan
# ═══════════════════════════════════════════════════════════════════════════

@dataclass
class LayerOp:
    """One AIE kernel launch.

    op:      "conv_bn_relu" | "conv_bn" | "residual_add_relu" | "avgpool_fc"
    out:     output buffer name
    ins:     input buffer name(s)
    Conv fields:  H, W, Cin, Cout, K, stride
    Residual:     length
    Avgpool/FC:   spatial_h, spatial_w, channels, num_classes
    """
    op: str
    out: str
    ins: List[str]
    H: int = 0
    W: int = 0
    Cin: int = 0
    Cout: int = 0
    K: int = 0
    stride: int = 0
    length: int = 0
    spatial_h: int = 0
    spatial_w: int = 0
    channels: int = 0
    num_classes: int = 0
    # Quantization params (QNN scales/zero-points when available; for the
    # scaled model these default to the deterministic Q7 pattern below). These
    # ride on the aiegraph.conv_bn[_relu] op attrs so the high-level dialect is
    # self-describing. bn_scale/bn_bias mirror make_conv_params' Q7 BN fold.
    in_scale: float = 1.0
    in_zp: int = 0
    out_scale: float = 1.0
    out_zp: int = 0
    bn_scale: int = BN_SCALE_DEFAULT
    bn_bias: int = BN_BIAS_DEFAULT
    # Symbol name of the weights entry in the module-level weights table
    # (SymbolRefAttr on the op). Empty means "generated deterministically".
    weights: str = ""

    @property
    def out_h(self) -> int:
        return self.H // self.stride if self.stride else 0

    @property
    def out_w(self) -> int:
        return self.W // self.stride if self.stride else 0

    def to_aiegraph_dict(self, main_index: int = -1,
                         skip_index: int = -1) -> dict:
        """Serialize to the plain-dict form ``build_aiegraph_module`` expects.

        Only ints/floats/strings cross the pybind boundary. Dataflow is passed
        explicitly by launch index because the plan reuses scratch-buffer names
        and is not strictly linear: ``main_index`` is the launch whose result is
        this op's primary (feature) input, and ``skip_index`` (residual only) is
        the launch whose result is the skip path. ``-1`` means "network input"
        (a fresh block argument).
        """
        d = {"op": self.op, "main_index": main_index}
        if self.op in ("conv_bn_relu", "conv_bn"):
            d.update(H=self.H, W=self.W, Cin=self.Cin, Cout=self.Cout,
                     K=self.K, stride=self.stride,
                     in_scale=self.in_scale, in_zp=self.in_zp,
                     out_scale=self.out_scale, out_zp=self.out_zp,
                     bn_scale=self.bn_scale, bn_bias=self.bn_bias,
                     weights=self.weights)
        elif self.op == "residual_add_relu":
            d.update(length=self.length, skip_index=skip_index)
        elif self.op == "avgpool_fc":
            d.update(spatial_h=self.spatial_h, spatial_w=self.spatial_w,
                     channels=self.channels, num_classes=self.num_classes,
                     weights=self.weights)
        return d

    def signature(self) -> tuple:
        """Structural fingerprint used to compare plans (walk vs canonical)."""
        if self.op in ("conv_bn_relu", "conv_bn"):
            return (self.op, self.H, self.W, self.Cin, self.Cout, self.K, self.stride)
        if self.op == "residual_add_relu":
            return (self.op, self.length)
        if self.op == "avgpool_fc":
            return (self.op, self.spatial_h, self.spatial_w, self.channels, self.num_classes)
        return (self.op,)


def _conv(op, out, feat, H, W, Cin, Cout, K, stride) -> LayerOp:
    return LayerOp(op=op, out=out, ins=[feat, "params"], H=H, W=W,
                   Cin=Cin, Cout=Cout, K=K, stride=stride)


def _res(out, main, skip, length) -> LayerOp:
    return LayerOp(op="residual_add_relu", out=out, ins=[main, skip], length=length)


def plan_to_aiegraph_dicts(plan: List["LayerOp"]) -> List[dict]:
    """Serialize a ``LayerOp`` plan to the dict list ``build_aiegraph_module`` wants.

    The dialect wires dataflow as SSA def-use, but the plan uses *reused* scratch
    buffer names ("tmp1", "feat1", ...). We resolve each op's inputs to the launch
    index that most recently produced that buffer name (program order). The main
    input of every op is the immediately-preceding result (list order handles it);
    only a residual's *skip* input needs an explicit ``skip_index`` back-reference.
    """
    last_writer: dict = {}  # buffer name -> producing launch index
    dicts: List[dict] = []
    for idx, op in enumerate(plan):
        # ins[0] is the feature/main input for every op kind; "params" and the
        # network "input" are not launch results, so they resolve to -1.
        main_index = last_writer.get(op.ins[0], -1)
        skip_index = -1
        if op.op == "residual_add_relu":
            skip_index = last_writer.get(op.ins[1], -1)
        dicts.append(op.to_aiegraph_dict(main_index=main_index,
                                         skip_index=skip_index))
        last_writer[op.out] = idx
    return dicts


def layer_plan() -> List[LayerOp]:
    """Return the canonical ~29-launch forward pass (mirrors resnet18_triton.main).

    Buffer names match resnet18_triton.py's scratch layout: input, feat1, feat2,
    feat3, tmp1, tmp2, skip_ds, logits. The "params" input is filled per-op by
    the compiler from make_conv_params()/make_fc_params().
    """
    sz0, sz1, sz2, sz3 = S0 * S0 * CH0, S1 * S1 * CH1, S2 * S2 * CH2, S3 * S3 * CH3
    p: List[LayerOp] = []

    # conv1: 8x8x1 -> 8x8x4
    p.append(_conv("conv_bn_relu", "feat1", "input", S0, S0, INPUT_C, CH0, 3, 1))

    # layer1 block0
    p.append(_conv("conv_bn_relu", "tmp1", "feat1", S0, S0, CH0, CH0, 3, 1))
    p.append(_conv("conv_bn", "tmp2", "tmp1", S0, S0, CH0, CH0, 3, 1))
    p.append(_res("feat2", "tmp2", "feat1", sz0))
    # layer1 block1
    p.append(_conv("conv_bn_relu", "tmp1", "feat2", S0, S0, CH0, CH0, 3, 1))
    p.append(_conv("conv_bn", "tmp2", "tmp1", S0, S0, CH0, CH0, 3, 1))
    p.append(_res("feat3", "tmp2", "feat2", sz0))

    # layer2 block0 (downsample 4->8, stride 2)
    p.append(_conv("conv_bn_relu", "tmp1", "feat3", S0, S0, CH0, CH1, 3, 2))
    p.append(_conv("conv_bn", "tmp2", "tmp1", S1, S1, CH1, CH1, 3, 1))
    p.append(_conv("conv_bn", "skip_ds", "feat3", S0, S0, CH0, CH1, 1, 2))
    p.append(_res("feat1", "tmp2", "skip_ds", sz1))
    # layer2 block1
    p.append(_conv("conv_bn_relu", "tmp1", "feat1", S1, S1, CH1, CH1, 3, 1))
    p.append(_conv("conv_bn", "tmp2", "tmp1", S1, S1, CH1, CH1, 3, 1))
    p.append(_res("feat2", "tmp2", "feat1", sz1))

    # layer3 block0 (downsample 8->16, stride 2)
    p.append(_conv("conv_bn_relu", "tmp1", "feat2", S1, S1, CH1, CH2, 3, 2))
    p.append(_conv("conv_bn", "tmp2", "tmp1", S2, S2, CH2, CH2, 3, 1))
    p.append(_conv("conv_bn", "skip_ds", "feat2", S1, S1, CH1, CH2, 1, 2))
    p.append(_res("feat3", "tmp2", "skip_ds", sz2))
    # layer3 block1
    p.append(_conv("conv_bn_relu", "tmp1", "feat3", S2, S2, CH2, CH2, 3, 1))
    p.append(_conv("conv_bn", "tmp2", "tmp1", S2, S2, CH2, CH2, 3, 1))
    p.append(_res("feat1", "tmp2", "feat3", sz2))

    # layer4 block0 (downsample 16->32, stride 2)
    p.append(_conv("conv_bn_relu", "tmp1", "feat1", S2, S2, CH2, CH3, 3, 2))
    p.append(_conv("conv_bn", "tmp2", "tmp1", S3, S3, CH3, CH3, 3, 1))
    p.append(_conv("conv_bn", "skip_ds", "feat1", S2, S2, CH2, CH3, 1, 2))
    p.append(_res("feat2", "tmp2", "skip_ds", sz3))
    # layer4 block1
    p.append(_conv("conv_bn_relu", "tmp1", "feat2", S3, S3, CH3, CH3, 3, 1))
    p.append(_conv("conv_bn", "tmp2", "tmp1", S3, S3, CH3, CH3, 3, 1))
    p.append(_res("feat3", "tmp2", "feat2", sz3))

    # classifier: GAP + FC (32 -> 4)
    p.append(LayerOp(op="avgpool_fc", out="logits", ins=["feat3", "params"],
                     spatial_h=S3, spatial_w=S3, channels=CH3, num_classes=NUM_CLASSES))
    return p


# ═══════════════════════════════════════════════════════════════════════════
#  Deterministic Q7 int8 parameter buffers (match resnet18_triton.py)
# ═══════════════════════════════════════════════════════════════════════════

def pack_config(H, W, Cin, Cout, K, stride) -> np.ndarray:
    return np.array([H, W, Cin, Cout, K, stride], dtype=np.int8)


def make_conv_params(H, W, Cin, Cout, K, stride) -> np.ndarray:
    """Conv param buffer: [config:6][weights:Cin*Cout*K*K][bn_scale:Cout][bn_bias:Cout].

    Weights alternate 1/-1, bn_scale = 64 (Q7 0.5), bn_bias = 0.
    """
    wt_count = Cin * Cout * K * K
    param_sz = CONFIG_SZ + wt_count + Cout * 2
    buf = np.zeros(param_sz, dtype=np.int8)
    buf[:CONFIG_SZ] = pack_config(H, W, Cin, Cout, K, stride)
    buf[CONFIG_SZ:CONFIG_SZ + wt_count] = np.array(
        [1 if i % 2 == 0 else -1 for i in range(wt_count)], dtype=np.int8)
    buf[CONFIG_SZ + wt_count:CONFIG_SZ + wt_count + Cout] = BN_SCALE_DEFAULT
    buf[CONFIG_SZ + wt_count + Cout:CONFIG_SZ + wt_count + Cout * 2] = BN_BIAS_DEFAULT
    return buf


def make_fc_params(spatial_h, spatial_w, channels, num_classes) -> np.ndarray:
    """FC param buffer (AIE layout): [config:4][weights:channels*nclass][bias:nclass].

    config = {spatial_h, spatial_w, channels, num_classes}. Weights = 1, bias = 0.
    The 4-int8 config header lets one avgpool_fc kernel body serve any shape.
    """
    wt = channels * num_classes
    buf = np.zeros(FC_CONFIG_SZ + wt + num_classes, dtype=np.int8)
    buf[:FC_CONFIG_SZ] = np.array([spatial_h, spatial_w, channels, num_classes], dtype=np.int8)
    buf[FC_CONFIG_SZ:FC_CONFIG_SZ + wt] = 1  # uniform weights, bias stays 0
    return buf


def fc_params_no_header(channels, num_classes) -> np.ndarray:
    """FC weights+bias without the AIE config header (for the CPU reference)."""
    buf = np.zeros(channels * num_classes + num_classes, dtype=np.int8)
    buf[:channels * num_classes] = 1
    return buf


def make_input() -> np.ndarray:
    """Test input 8x8x1, pattern (i%7)+1 (matches resnet18_triton.py)."""
    n = INPUT_H * INPUT_W * INPUT_C
    return np.array([(i % 7) + 1 for i in range(n)], dtype=np.int8)


# ═══════════════════════════════════════════════════════════════════════════
#  Torch model + ONNX export (structure only; drives the Relay walk)
# ═══════════════════════════════════════════════════════════════════════════

def build_torch_model():
    """Build a scaled *post-activation* ResNet mirroring the launch plan.

    Structure (not weights) is what matters: the Relay walk recovers the op
    sequence and per-conv dims from this graph. Requires torch.
    """
    import torch
    import torch.nn as nn

    def conv(cin, cout, k, s):
        return nn.Conv2d(cin, cout, kernel_size=k, stride=s, padding=k // 2, bias=False)

    class BasicBlock(nn.Module):
        def __init__(self, cin, cout, stride):
            super().__init__()
            self.c1 = conv(cin, cout, 3, stride)
            self.b1 = nn.BatchNorm2d(cout)
            self.c2 = conv(cout, cout, 3, 1)
            self.b2 = nn.BatchNorm2d(cout)
            self.down = None
            if stride != 1 or cin != cout:
                self.down = nn.Sequential(conv(cin, cout, 1, stride), nn.BatchNorm2d(cout))

        def forward(self, x):
            idt = x if self.down is None else self.down(x)
            out = torch.relu(self.b1(self.c1(x)))
            out = self.b2(self.c2(out))
            return torch.relu(out + idt)

    class Net(nn.Module):
        def __init__(self):
            super().__init__()
            self.stem_c = conv(INPUT_C, CH0, 3, 1)
            self.stem_b = nn.BatchNorm2d(CH0)
            self.l1 = nn.Sequential(BasicBlock(CH0, CH0, 1), BasicBlock(CH0, CH0, 1))
            self.l2 = nn.Sequential(BasicBlock(CH0, CH1, 2), BasicBlock(CH1, CH1, 1))
            self.l3 = nn.Sequential(BasicBlock(CH1, CH2, 2), BasicBlock(CH2, CH2, 1))
            self.l4 = nn.Sequential(BasicBlock(CH2, CH3, 2), BasicBlock(CH3, CH3, 1))
            self.fc = nn.Linear(CH3, NUM_CLASSES)

        def forward(self, x):
            x = torch.relu(self.stem_b(self.stem_c(x)))
            x = self.l4(self.l3(self.l2(self.l1(x))))
            x = torch.nn.functional.adaptive_avg_pool2d(x, 1).flatten(1)
            return self.fc(x)

    return Net().eval()


def export_onnx(path: str) -> str:
    """Export the scaled model to ONNX at ``path``; returns the path. Needs torch."""
    import torch
    model = build_torch_model()
    dummy = torch.zeros(1, INPUT_C, INPUT_H, INPUT_W)
    torch.onnx.export(model, dummy, path, input_names=["input"],
                      output_names=["logits"], opset_version=13)
    return path
