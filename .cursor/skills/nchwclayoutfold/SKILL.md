<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: nchwclayoutfold
description: "`--aie-offload` reports every layer as `non-4D shapes; not a conv2d` and offloads nothing, or a selected layer gets another layer's geometry (K=0, wrong Cin). Covers folding TVM's 5-D NCHWc back to 4-D for aiehlc (which has d1..d4 only), when C_outer>1 needs a channel repack, and the manifest/call_nodes positional desync. Read before touching aie_offload._layer_geometry or select_layers."
---

# TVM NCHWc (5-D) vs aiehlc spatial spaces (4-D)

## Symptom

```
idx 1 feat=[1, 1, 224, 224, 3]  out=[1, 16, 112, 112, 4]   -> geom {}
reason: "non-4D shapes; not a conv2d"
```

0 of 30 layers eligible. Asking for the first layer looks like the trigger, but
index 0 is the input-quantize op and is rejected earlier for its op kind; the
stem conv is index **1**. (`deploy_flow.py` adds to the confusion: `--aie-layers`
defaults to `"1"` in argparse but `run()`'s signature says `(0,)`.)

## Why 5-D appears

`_layer_geometry` reads the graph **after** `relay.build`, and `AlterOpLayout`
rewrites `nn.conv2d` -> `nn.contrib_conv2d_NCHWc`, splitting `C` into
`C_outer x c` so the inner block vectorizes on x86:

```
[N, C, H, W]  ->  [N, C/c, H, W, c]
```

## aiehlc cannot take a 5-D descriptor -- and does not need to

Two independent ceilings, both below 5:

| limit | value |
|---|---|
| `aiehlc.cc` spatial dims | `tdD1`..`tdD4` -- there is no `tdD5` |
| Gen5 DMA `NumAddrDim` (shim, core) | **3** |
| Gen5 DMA `NumAddrDim` (MemTile) | 4 |

`xaie_dma.c:470` hard-rejects `Tensor->NumDim > DmaMod->NumAddrDim`.

But the 5th axis is a **layout** artifact, not a spatial axis:
`[1,16,112,112,4]` is the same 802,816 bytes as `[1,64,112,112]`. Fold it:

```python
if len(shape) == 5:
    cin = shape[1] * shape[4]        # C_outer * c_inner
```

`conv2dstem` already works this way -- it treats channels as a single
`INPUT_C_ALIGN=4` stride, never as an axis.

## The fold is valid for SIZING, not for ADDRESSING

Measured, both directions:

| `C_outer` | NCHWc byte-identical to HWC? |
|---|---|
| 1 | **yes** |
| > 1 | **no** |

With `C_outer > 1` the data interleaves as `(c_outer, h, w, c_inner)` while the
kernel reads `(h, w, c)` -- same element count, wrong order. Handing that buffer
straight to aietensorop computes against transposed channels and silently
returns plausible wrong numbers.

So `_nchw()` folds unconditionally (callers use it only for `tensor_specs`
dims), and `_layer_geometry` carries
**`needs_repack`** / `in_layout` / `out_layout` so the emit path acts on the
layout fact instead of rediscovering it. On ResNet-18, 27 of 28 recovered
layers need a repack -- including the stem, whose output is
`[1,16,112,112,4]`.

## Two bugs the fold exposes

Both were invisible while everything returned `{}`.

**1. Weights are not always `input[1]`.** In a fused residual block the second
input is another feature map and the weights land at `input[2]`:

```
[1,16,56,56,4], [1,16,56,56,4], [16,16,3,3,4,4]
                                 ^ the weights
```

Indexing `[1]` blindly gives `K=0` -- a kernel that does not exist. Identify by **rank** instead: weights are 4-D
`[Cout,Cin,KH,KW]` or 6-D `[Co/c,Ci/c,KH,KW,ci,co]`; `KH` is index 2 in both.
Fixing this turned `K` from `{3:11, 0:4, 1:3, 7:1}` into `{3:15, 1:3, 7:1}`.

**2. `call_nodes[idx]` is positionally wrong.** The manifest has one entry per
emitted C function; the graph has one node per **call**. A function invoked
twice is one manifest entry and two graph nodes -- 28 vs 30 on ResNet-18, and
they desynchronize from index 6 onward, so every later layer gets another
layer's geometry. (`aiegraph_partition.py`'s docstring already called this out.)

Map by **symbol**, consuming repeats in order. Claim the node **before** the
`--aie-layers` filter, or skipping entries shifts the sequence and the result
depends on which layers were requested:

```python
node_idx = _node_for(entry)          # claim first
if indices is not None and idx not in indices:
    continue                          # then filter
```

Check: selecting any single index must give the same geometry as a full scan.

## Result, and what still does not work

```
geometry recovered : 28/30   (was 0/30)
symbol/node mismatch: 0      (was misaligned from idx 6)
stem (idx 1)        : H=224 W=224 Cin=3 Cout=64 K=7 stride=2   <- matches conv2dstem
```

The two remaining rejects are correct: `batch_flatten` and `dense` have rank-2
outputs and are genuinely not conv2d.

**Emit deps.** The emit path needs `frontend.tvmrelay.kernels` (restored from
the `frontend.tvm` package `05ee99d` deleted) plus the `_aiebackend` pybind
module. `_require_emit_deps()` raises naming whichever is missing, after the
useful output, instead of a bare `ModuleNotFoundError` three frames down. There is deliberately no tile-budget
check on the Python side -- tiling and memory fit are aiehlc's job.

`--aie-offload` itself now goes through BYOC (skill: byocaieoffload). It
partitions *before* `relay.build`, so the AIE subgraph sees plain 4-D `nn.conv2d`
and never meets NCHWc; the NCHWc fold above only serves layer selection
(`resolve_conv_targets` reads the CPU build's graph JSON).
