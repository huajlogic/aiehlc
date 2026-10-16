---
name: conv2dstemfixture
description: The conv2dstem real-data fixture (data/*.py -> conv2dstem_image.h / _weights.h / _golden.h). Use when a generated header is not found at the cross-g++ step, when the stem's output is wrong only at the borders or wrong everywhere uniformly, when the accumulator overflows, when adding any generated header to an aiehlc app, or when conv2dstem_image.h and TVM's layer-0 output (tvmgen_default_fused_divide_round_add_clip_cast_subtract_layout_transform, bytes like "98 ff 9e ff a9 ff") look like different data.
---

# conv2dstem real-data fixture

`src/aietensorop/conv2dstem/data/` turns a photo + the int8-quantized ResNet-18
into the headers `main.cc` runs on, and a CPU ground truth the board checks
itself against. Four traps, each of which fails quietly.

## 1. A generated header CANNOT live in a subdirectory

**Symptom:** `fatal error: data/image.h: No such file or directory` — from the
**cross-g++** step, after the aiehlc frontend parsed the same file happily.

**Why:** two different include paths.

- Frontend parse: `script/aiehlc.sh:447` passes `--extra-arg=-I${SOURCE_DIR}`,
  so `data/image.h` resolves.
- Host compile: `script/aiehlc.sh:532` copies user headers with a
  **non-recursive glob, flattened to basename**

  ```bash
  for f in "${SOURCE_DIR}"/*.h; do cp -f "$f" "${WORKLOCAL_DIR}/$(basename "$f")"; done
  ```

  and `script/hostcompile.sh:345` adds only `-I${WORKLOCAL_DIR}`. A header in
  `data/` is never copied and the app source dir is never on the include path.

**Fix:** emit generated headers **flat into the app source dir** with a prefix
(`conv2dstem_image.h`), not into the subdirectory the generator lives in. The
scripts may live anywhere; the output may not.

The general fix — adding `-I$(dirname $(cat ${WORKLOCAL_DIR}/app_source.txt))`
to `hostcompile.sh` — is the only way to make `#include "data/…"` work as
written. It was not taken here because the flat layout needs no script change.

## 2. Macro-name collisions with `conv2dstem.h`

`conv2dstem.h` already defines `CONV2DSTEM_WTS_ELEMS`, `CONV2DSTEM_OFM_ELEMS`,
`CONV2DSTEM_IFM_PAD_ELEMS` as *expressions*. A generated header defining the
same name as a literal is a redefinition with a different token sequence —
warns, and invites the two to drift. All generated counts use a disjoint
`CONV2DSTEM_DATA_*` namespace.

## 3. The border is the zero-point, not zero

The quantized graph pads the stem's 3-pixel border with `in_zp = 113`, because
ONNX pads the **dequantized** tensor with `0.0` and `0.0` dequantizes from
`x_q = zp`. After the `x − 128` shift the border is **−15** (`0xf1`), not `0`.

- Padding with zero corrupts **only the outer 3 rows/cols** — so a failure
  concentrated there points straight at this.
- This is why the fixture is pre-padded `[230,230,4]` and `main.cc` uses
  `stage_ifm_pad4()`, not `conv2d_stem()`, which re-pads with zero
  (`conv2dstem.cc:528`).

## 4. The stored shift is `−exponent`

TVM's `GetFixedPointMultiplierShift`
(`thirdparty/tvm-0.16/src/relay/qnn/utils.cc:33`) returns `frexp`'s exponent.
The core applies the shift as

```c
v = ((int64_t)acc * mult + ((int64_t)1 << (sh + 30))) >> (sh + 31);
```

so the qparam stores its **negation** — for this layer `+7 .. +27`, not
`−27 .. −7`. Confirmed against TVM's own generated C
(`worklocal/tvmrelay_deploy/resnet18.c:648`).

Wrong sign ⇒ **every** pixel wrong, uniformly, with no obvious structure.
`fixture_common.fold_qparams` asserts the `mult · 2^−(shift+31)` round-trip per
channel so this can never ship silently.

## 5. The accumulator must be int32

Real weights drive `|acc|` to **1,023,225** against an int16 range of ±32,767.
The old synthetic fixture (`ifm = i%9-4`, `wts = i%3-1`) stayed inside int16, so
it could not catch an int16 accumulator. Any check that does not use real
weights will miss this.

## Regenerating

Order matters — the ground truth derives from the other two.

```bash
cd src/aietensorop/conv2dstem/data
python3 make_image_header.py
python3 make_weights_header.py --emit-npz
python3 groundtruth.py
```

Needs numpy / onnx / onnxruntime / torch / PIL. **Not TVM** —
`fixture_common.resolve_qdq_model` imports it lazily, only on the fallback path,
with `AIEHLC_TVM_AUTO_INSTALL=0`, so a missing TVM never kicks off a 10–25
minute source build.

`conv2dstem_golden.h` is gitignored (~800 KB, fully derived); the image and
weight headers are committed so the app builds without a network.

## Verifying without hardware

The strongest pre-hardware check — the generated headers driven through the x86
model of the core's arithmetic:

```bash
cd src/aietensorop/conv2dstem
gcc -O2 -I. -o /tmp/h harness.c ref/conv2dstem_x86.c && /tmp/h
# x86 kernel model vs golden: 0 mismatches / 802816
```

where `harness.c` strips channel 3 from `conv2dstem_ifm_pad4` into a
`[230,230,3]` buffer (`conv2dstem_x86.c` takes the 3-channel form) and calls
`conv2d_stem_prepadded`. This validates the headers, the `uint8_t`→`int8_t`
casts, and the `conv2dstem_qp` → `conv2dstem_qparam` reinterpretation together.

`groundtruth.py` also cross-checks its numpy reference against **onnxruntime**
running the real quantized layer. A few differences are expected and reported,
not failed — ORT rounds half-to-even, the core rounds half-up. Measured: **2 of
802,816, max difference 1**. A *large* divergence means a scale or zero-point
was read wrong.

## Reading a board failure

`main.cc` prints at most 32 mismatch lines (`apppaltest.py` has a 300 s
no-output / 600 s total watchdog — 802,816 lines over UART would blow through
both), then one machine-readable verdict that `groundtruth.py --applog` parses.

| Pattern | Cause |
|---|---|
| outer 3 rows/cols only | zero-point border padding (trap 3) |
| everything, uniformly | qparam folding — check the shift's sign (trap 4) |
| scattered | the AIE data path (skill: `datacorrectness`) |

## Hex arrays are `uint8_t`

`static const int8_t x[] = {0xff}` relies on an implementation-defined
out-of-range conversion. The generators emit `uint8_t` and `main.cc` casts at
the use site — which is also literally the byte image the DMA pushes.

## The fixture and TVM's layer 0 look different and are not

Symptom: you dump `tvmgen_default_fused_divide_round_add_clip_cast_subtract_layout_transform`'s
output (`worklocal/tvmrelay_deploy/layers/00_*/`) and get

```
98 ff 9e ff a9 ff 98 ff 9e ff aa ff ...
```

while `conv2dstem_image.h` starts `f1 f1 f1 00 f1 f1 f1 00 ...`. **Nothing is
wrong.** The arithmetic is identical — verified bit-exact over all 150,528
values on `dog.jpg` — and only the representation differs.

First, `98 ff` is **int16 little-endian**, not two bytes: `0xff98 = -104`. The
TVM kernel's store is `((int16_t*)T_layout_trans)[h*672 + w*3 + c]`.

| | `conv2dstem_image.h` | TVM layer 0 |
|---|---|---|
| offset | `x_u8 - 128` | `x_u8 - in_zp` (113) — a constant **+15** apart |
| dtype | `int8`, [-128, 127] | `int16`; [-113, 142] does not fit int8 |
| border | 3 px of `in_zp` → `[230,230]` | none, `[224,224]` |
| channels | 4 (ch3 = alignment pad, 0) | 3 |
| layout | HWC | HWC — same family, no transpose involved |

The fixture's first bytes are the **padding border** (`0xf1 = -15 = 113-128`)
with every fourth byte the alignment pad, which is why they look nothing like
TVM's first pixel. Compare the *interiors*:

```python
tvm == pad4[3:-3, 3:-3, :3].astype(np.int16) + (128 - in_zp)
```

`fixture_common.pad4_to_tvm_layer0(pad4, sp)` is that one-liner.

To get the TVM form itself, `make_image_header.py --tvm-layer0` writes
`../conv2dstem_image_tvm.h` (int16, decimal — a hex initializer for a signed
type would hit the same out-of-range conversion as above). It does **not**
convert the fixture: it runs the kernel's own two steps,
`fixture_common.tvm_quantize_u8` then `tvm_layer0`, in the same order and the
same float32 precision, and then asserts the result against
`pad4_to_tvm_layer0` so the two front ends cannot drift apart. It never
overwrites `conv2dstem_image.h`.

Three details that make this a reimplementation rather than a formula — each
one silently produces *almost* the right pixels:

- The float literals are **parsed out of the generated C**
  (`parse_tvm_layer0_consts`), not recomputed. TVM emits the reciprocal to 7
  significant digits, `5.378862e+01f`, which is not
  `float32(1/in_scale) = 53.788624`.
- It is a **float32 multiply by the reciprocal**, not `x / in_scale` in
  float64. Those differ by up to 1.3e-5 before rounding.
- `roundf` is round-half-**away-from-zero**. `np.round` is round-half-to-even
  (which is what ONNX Runtime does, hence `preprocess_to_pad4`).
  `fixture_common.roundf` implements the C rule.

`--verify-kernel` settles it properly: it compiles `layers/00_*/00_*.c` with
the host gcc, drives it through TVM's packed ABI on the same image, and diffs
the output buffer — the only check that compares against the compiled code
rather than a reading of it.

```bash
python3 src/aietensorop/conv2dstem/data/make_image_header.py \
    --tvm-layer0 --verify-kernel
#   [verify] MATCH -- all 150,528 values equal the compiled 00_divide_..._transform/ kernel
```

It needs stage 5's per-layer split (not `--no-split`) and stage 6's
`arm_build/tvm_graph_types.h`; without them it reports what is missing rather
than failing. Confirmed live, not vacuous: perturbing one value reports
`ndiff=1`, and passing the wrong zero-point reports all 150,528.

Why each side chose what it did, so neither looks arbitrary:

- **−128 vs −zp.** The AIE kernel is `int8 × int8`, so the activation must fit
  int8; `x_u8 − 128` does, `x_u8 − 113` does not (it reaches 142). The
  `+128·Σw` this introduces is folded into the bias — see skill
  **byocaieoffload**.
- **Pre-padded vs not.** `conv2d_stem()` does not pad, so the fixture carries
  the border; TVM pads inside the conv op, downstream of layer 0.
- **int16 output.** Not a deliberate width choice: the generic
  `qnn_conv2d_legalize` upcasts to int16 to fold zero-points, and `target="c"`
  registers no fast-int8 legalization. The values are genuine int8 range.

Two differences that are latent rather than active, and would show as a 1-LSB
disagreement on a handful of pixels for some *other* image: TVM's C does
`roundf(x * 53.78862f)` — reciprocal multiply in float32, round-half-away-from-
zero — while the fixture does `np.round(x / in_scale)` in float64, round-half-
to-**even** (which is what ONNX Runtime's QuantizeLinear does). On `dog.jpg` no
value lands within 0.002 of a `.5` tie and the two reciprocal forms differ by
at most 1.3e-5, so neither fires. If you ever see a sparse ±1 mismatch between
the two front-ends, this is where to look first — not at the DMA.
