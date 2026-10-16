<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: tvmint8legalize
description: int8 conv operands are the DEFAULT everywhere, including --aie-offload/--aiegraph (--no-pe-int8 opts out; the old auto-off there is gone). Use when the TVM flow quantized to int8 but conv weights/activations are STORED int16 (weights.bin 23.5 MB instead of 11.9 MB, graph_driver.c tensors show int16, network.md parameter dtypes read int16) -- or you need to tell TVM the target PE only accepts int8 operands. Covers deploy_flow.py --pe-int8, src/frontend/tvmrelay/pe_target.py, the Target("c -keys=pe_int8,cpu") custom-key dispatch, helper_change_dtypes_to_int8 vs helper_no_fast_int8_hw_legalization, and why bias / requant multiplier / shift are int32 BY DESIGN and must not be narrowed.
---

# int8 values stored as int16 — legalization, not quantization

## The symptom

`network.md` or a `make TRACE=1` dump shows conv operands as `int16`:

```
in  tensors[2] int16 [1,1,224,224,3]
in  tensors[3] int16 [16,1,7,7,3,4]     <- the WEIGHTS
out tensors[9] uint8 [1,16,112,112,4]
```

and `weights.bin` is 23.5 MB for an 11.7M-parameter int8 model.

## The quantization is fine — check before changing anything

The values really are int8. Measured on ResNet-18:

```
weights: 11,678,912 values, range [-127, 127], 100.0000% inside int8
         distinct values: 255
```

255 levels spanning `[-127, 127]` (−128 unused, the symmetric convention). So
this is a **container width**, not a quantization failure. Verify before
touching anything, with the role-aware dump in `network_md.py` plus
`arm_build.param_offsets` — never assume from the dtype.

## Why int16: it is a statement about the HARDWARE

`Target("c")` carries `keys=['cpu']`, so TVM applies its **Intel x86** QNN rule
(`qnn/op/legalizations.py:520`):

```python
@qnn_conv2d_legalize.register("cpu")
def _qnn_conv2d_legalize_intel_cpu(attrs, inputs, types):
    if is_fast_int8_on_intel():          # target_has_features("sse4.2") -> False
        return helper_change_dtypes_to_uint8_int8(...)
    return helper_no_fast_int8_hw_legalization(attrs, inputs, types, relay.nn.conv2d)
```

`helper_no_fast_int8_hw_legalization` casts **data and kernel to int16** and
subtracts the zero-points eagerly. That is correct for an LLVM backend with no
VNNI — int16 vectorizes better than int8 there — and wrong for a PE whose MACs
are int8. Legalization runs *after* quantization and describes the device.

Two things people get wrong here:

- It is **not** the generic `qnn_conv2d_legalize` — that one returns `None`.
  Saying "target=c registers no legalization" is backwards: it inherits x86's.
- The root constraint is real. Input is uint8 with zp=113, so `x − 113` spans
  **[−113, 142]**, which does not fit int8. Something has to give; int16 is one
  answer, shifting by 128 is the other.

## The fix is now the DEFAULT

int8 operands are on unless you ask otherwise:

| invocation | operands |
|---|---|
| *(nothing)* | **int8** |
| `--no-pe-int8` | int16 (the old behaviour, for A/B) |
| `--pe-int8` | int8, forced |
| `--aie-offload` / `--aiegraph` | **int8** (no longer auto-off) |

So if you are looking at an int16 build, either it predates this change or
`--no-pe-int8` was passed.

**The AIE paths used to force int16, and no longer do.** The guard was that int8
renumbers `layers/` (the stem moves from index **1 to 6**) while `--aie-layers`
selected positionally. Selection now resolves a layer to its conv by **weight
fingerprint** — `byoc.aie_annotate.weight_fingerprint`, values sorted and cast
to int64 before hashing, so it is layout- and dtype-independent. Verified: the
same weights hash identically as int8/NCHW, int16/NCHW and int16/NCHWc.

Keeping int8 off there was backwards anyway: the AIE kernel consumes int8, so
int16 legalization made the *offloaded* conv the one op not in the hardware's
operand width.

Two consequences worth knowing:

* `--aie-layers` now defaults to **6**. A stale index is not silent — it reports
  `not a conv -- only convs offload through the AIE BYOC path` and offloads
  nothing. Measured end to end: layer 6 matches `1/20 convs`, partitions, and
  links a 14.7 MB ELF carrying `conv2d_stem_prepadded` + `tvmgen_default_aie_main_0`
  (vs 24.4 MB under int16).
* `--aiegraph` maps **0 layers** — but it already did before this change
  (`doc/design/byoc_aie_plan.md:160`, "0/28 eligible, confirmed"). It keys on
  fused *names* (`conv2d_add_relu` → `conv_bn_relu`) and legalization renames the
  groups to `contrib_conv2d_NCHWc_subtract_add_add_subtract_...`. It runs clean
  and links; it just offloads nothing until that mapping is updated.

`src/frontend/tvmrelay/pe_target.py` gives the target its own key:

```python
Target("c -keys=pe_int8,cpu", host="c")
```

`qnn_conv2d_legalize` is a `tvm.target.generic_func`, so it tries keys in
order: `pe_int8` wins, and `cpu` stays available for everything else —
operator strategies, schedules, `conv2d_alter_op` are all registered there and
must still resolve, which they do because `generic_func` falls through when the
first key has no registration.

**Do not monkeypatch `register("cpu", override=True)` instead.** It works, and
it silently retargets every x86 TVM build in the same process, including
anything else that imported TVM. The custom key is the supported way to
describe a new device.

The rule registered on that key is TVM's own `helper_change_dtypes_to_int8`
(written for Nvidia `dp4a`), which is exactly the AIE convention:

```
x_i8  = x_u8 - 128
zp_i8 = zp   - 128        # 113 -> -15
```

The shifted zero-point is folded into the bias by `QnnConv2DCanonicalize`'s
four-term expansion — the same algebra as `conv2dstem`'s `+128·Σw` bias fold
(skill **byocaieoffload**), reached from the Relay side instead of by hand.
It returns `None` once the operands are already int8, and that early return is
what stops the legalize pass rewriting forever. Keep it.

Register **both** `qnn.conv2d` and `qnn.dense`. Leaving `dense` out quietly
keeps the final FC layer's 1 MB of weights at int16.

## Measured

| | default (int16) | `--pe-int8` |
|---|---|---|
| conv weight dtype | `int16` | **`int8`** |
| `weights.bin` | 23,484,752 B | **11,851,606 B** |
| activation buffers | 25.7 MB | **18.6 MB** |
| `main.elf` (board) | 24,409,664 B | **12,795,600 B** |
| `main_local.elf` | 24,253,696 B | **12,654,648 B** |
| graph nodes / kernels | 30 / 28 | 120 / 64 |
| top-1 | 258, logit 12.017338 | **identical** |

Bit-identical output, because it is algebra on the same int8 values. The cost
is the four-term expansion made explicit: 4× the nodes, an `nn_pad` and a
`cast_sum` per conv, and int32 scratch for the zero-point reductions. Verify
with `--local`, which runs the ELF and prints `local vs cpu: MATCH`.

## Bias / multiplier / shift are int32 BY DESIGN — do not "fix" them

Only the operands narrow. Measured by role:

| role | dtype | min | max |
|---|---|---|---|
| weight | `int8` | -127 | 127 |
| bias | `int32` | -3,834,368 | 2,873,728 |
| requant multiplier | `int32` | 1,073,764,180 | 2,147,291,785 |
| requant shift | `int32` | 6 | 27 |

```
acc   = Σ (q_x − z_x) · q_w         int32, at scale s_x·s_w
acc  += bias_q                      bias_q = round(bias_real / (s_x·s_w))
out   = clip((acc · M) >> (s+31)) + z_out
```

- **Bias lives at the accumulator scale**, so dividing by `s_x·s_w` (a product
  of two small scales) inflates it ~10⁶× — 23 bits here. An int8 bias is
  arithmetically wrong. TFLite, ONNX QDQ and PyTorch all store int32 bias.
- **The multiplier is a fixed-point scale, not data**: the measured range is
  precisely `[2³⁰, 2³¹)`, the normalized mantissa of `s_x·s_w/s_out`.
- Shift (6–27) and zero-point (0–149) would fit a byte but total ~200 bytes.

All of it is **0.5%** of the blob. The 99.5% is the weights. Chasing the int32
constants is effort spent on nothing; the operand width is the whole prize.

## Related

- `--aie-offload` already does the 128-shift by hand on the AIE side: skill
  **byocaieoffload**, `src/aietensorop/conv2dstem/`.
- Reading the dtypes out of a run: skill **tvmlocalhostelf** (`make TRACE=1`,
  the `DLDataType` packing) and `network.md`'s role-aware parameter tables.
- Getting the int8 path to run at all on a no-LLVM TVM: skill
  **tvmrelaynollvm**.
