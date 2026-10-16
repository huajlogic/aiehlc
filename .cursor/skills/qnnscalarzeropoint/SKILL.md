<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: qnnscalarzeropoint
description: TVM emits dead per-conv zero-point correction chains (cast_sum -> multiply -> avg_pool2d -> repeat_multiply_layout_transform) that compute and subtract ZEROS, because qnn's four-term elision tests whether the kernel zero point is a SCALAR, not whether it is zero -- and per-channel quantization makes it a [64] tensor. Use when a quantized graph has far more kernel calls than operators (int8 ResNet-18: 120 instead of 41), when network.md / layeriohex shows an int32 activation input with the same shape as a conv's own output, or when asked why a chain cannot be int8. Covers src/frontend/tvmrelay/qnn_fold_zp.py, deploy_flow --no-fold-qnn-zp, Conv2DCombineTerms and IsConstScalar.
---

# Dead qnn zero-point chains: the elision tests scalar-ness, not zero-ness

## The symptom

A quantized graph has roughly **3x the kernel calls you expect**, and most of
them are not operators from the model:

```
call [02] cast_sum                          -> int32 [1,1,230,230]
call [03] multiply                          -> int32 [1,1,230,230]
call [04] nn_avg_pool2d                     -> int32 [1,1,112,112]
call [05] repeat_multiply_layout_transform  -> int32 [1,16,112,112,4]
call [06] nn_contrib_conv2d_NCHWc_subtract_add_...   <- consumes [05]
```

One such chain **per conv**. A second tell: the conv takes two activations, and
the second has the *same geometry as the conv's own output* with a different
dtype (`int32` in, `uint8` out), so it reads like a feedback edge.

## What it is

`QnnConv2DCanonicalize` expands a quantized conv into four terms
(`thirdparty/tvm-0.16/src/relay/qnn/op/convolution.cc`):

```
out   = term1 - term2 - term3 + term4
term1 = conv2d(data, kernel)
term2 = kernel_zero_point * sum(data over the kernel window)   <- THE CHAIN
term3 = input_zero_point  * sum(kernel)
term4 = input_zp * kernel_zp * k_h * k_w * in_channels
```

term2 is the chain. It depends on the **live input**, so `FoldConstant` cannot
remove it no matter how trivial it is.

## The actual bug

`Conv2DCombineTerms` (`convolution.cc:633`) already drops term2 and term4 when
the kernel zero point is zero:

```cpp
if (input_zero_point_int == 0 && kernel_zero_point_int == 0) return term1;
```

But those integers are only extracted when **both zero points are scalars**
(`convolution.cc:747`):

```cpp
if (IsConstScalar(input_zero_point) && (IsConstScalar(kernel_zero_point))) {
  input_zero_point_int  = GetScalarFromConstant<int>(input_zero_point);
  kernel_zero_point_int = GetScalarFromConstant<int>(kernel_zero_point);
} else {
  kernel_zero_point = Reshape(kernel_zero_point, {-1});
  dynamic_zp = true;                 // both ints stay -1
}
```

and `IsConstScalar` is **strictly rank 0**:

```cpp
bool is_scalar() const { return data->ndim == 0; }   // include/tvm/relay/expr.h:80
```

**Per-channel** quantization makes the kernel zero point a `[64]` tensor. Every
element is 0 — symmetric weights — but the test is on the *shape*, so it fails,
`dynamic_zp` is set, and the final `else` emits term2 unconditionally.

> Per-**tensor** symmetric quantization takes the fast path.
> Per-**channel** symmetric quantization misses it, for free.

A `[1]`-shaped constant does **not** help: `is_scalar()` is `ndim == 0`, not
`size == 1`.

## The fix

`src/frontend/tvmrelay/qnn_fold_zp.py` — `fold_scalar_zero_points(mod)` rewrites
a constant zero point whose elements are **all equal** to a rank-0 scalar of the
same value and dtype. TVM's own elision then fires and the chains are never
built. On by default in `deploy_flow.py`; `--no-fold-qnn-zp` opts out for A/B.

Three things that matter:

* **All-equal, not all-zero.** A uniform non-zero zero point folds too, and TVM
  then emits the terms it genuinely needs. Folding only zeros would leave the
  per-tensor-asymmetric case on the slow path for no reason.
* **It must run before `qnn.CanonicalizeOps`** — so before `build_c`
  *and* before `aie_byoc.partition_for_aie`, which canonicalizes internally.
  After expansion there is nothing left to fold.
* **`kernel_scale` stays per-channel.** Only the zero point folds; the
  requantization really is per-channel.

## Measured (int8 ResNet-18)

| | before | after |
|---|---|---|
| kernel calls | 120 | **41** |
| `cast_sum` / `repeat_multiply` nodes | 42 | **0** |
| buffers | 18.58 MB | 14.29 MB |
| logits | — | **bit-identical** (3 random inputs) |

21 dead chains, ~70 of 120 calls. Layer 06 alone was subtracting 802,816 int32
zeros.

## Why the chain cannot just be made int8

Asked often, and the answer is not "tooling". Measured through it:

| call | op | min | max | fits int8? |
|---|---|---|---|---|
| 02 | `cast_sum` | −359 | 349 | no (10 bits) |
| 03 | `multiply` | −17,591 | 17,101 | no (16 bits) |
| 04 | `avg_pool2d` | −17,273 | 17,039 | no |

Its **input already is int8** (`int8[1,3,230,230]`). The outputs are *partial
sums of the convolution* — accumulators, with no scale or zero point of their
own — and the result is subtracted from an exact int32 conv accumulator, so
rounding it to 8 bits would inject error into every output pixel.
Requantization happens once, at the end of the conv
(`fixed_point_multiply -> clip -> cast`). int32 is also right in general: a
non-zero kernel zero point would push call 05 to ~2.2M.

So the answer is never "narrow the chain", it is "the chain should not exist".

## Checking it on a build

```bash
# the chains, if any, are these node names
python3 -c "
import json; g=json.load(open('worklocal/tvmrelay_deploy/resnet18_graph.json'))
print(sum(1 for n in g['nodes'] if n.get('op')=='tvm_op'
          and any(k in n['attrs']['func_name'] for k in ('cast_sum','repeat_multiply'))))"
```

Zero means the fold fired. With `make TRACE=1` the `layeriohex/param_*_copied.h`
files are the per-channel kernel zero points — all-zero contents confirm the
weights are symmetric and the chains were pure waste.
