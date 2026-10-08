# conv2dstem fixture — real image, real weights, real ground truth

The generators that turn a photograph and the quantized ResNet-18 into the C
headers `../main.cc` runs on, plus the CPU ground truth the board checks itself
against.

Before this existed, `main.cc` convolved `ifm[i] = i%9-4` with `wts[i] = i%3-1`
under an identity requantize. That exercises the data path but not the
arithmetic: those magnitudes keep the accumulator inside int16, while the real
weights drive it to **1,023,225** — a 31× int16 overflow that synthetic data can
never reveal.

## Regenerate

> **The headers are written one level UP, not into this directory.**
> `../conv2dstem_image.h`, `../conv2dstem_weights.h`, `../conv2dstem_golden.h`.
> That is required, not a preference — see
> [Why the headers are not in this directory](#why-the-headers-are-not-in-this-directory).
> Only `stem_fixture.npz` lands here. If you ran everything and `ls` shows no
> `.h`, you are looking in the wrong directory: `ls ../conv2dstem_*.h`.

Order matters: the ground truth is derived from the other two.

```bash
cd src/aietensorop/conv2dstem/data
python3 make_image_header.py            # dog.jpg -> ../conv2dstem_image.h
python3 make_weights_header.py --emit-npz   #      -> ../conv2dstem_weights.h + stem_fixture.npz
python3 groundtruth.py                  #          -> ../conv2dstem_golden.h

ls -l ../conv2dstem_*.h                 # confirm: three files, ~1.3 MB / 62 KB / 5.0 MB
```

Needs `numpy`, `onnx`, `onnxruntime`, `torch` + `PIL` (for the preprocessing).
**Not TVM** — `fixture_common.resolve_qdq_model` imports it lazily and only on
the fallback path, with `AIEHLC_TVM_AUTO_INSTALL=0`, so a missing TVM never
triggers a 10–25 minute source build.

## Files

| File | What |
|---|---|
| `dog.jpg` | The fixture image — the pytorch-hub sample, a Samoyed |
| `fixture_common.py` | Model parsing, qparam folding, image pipeline, header emitter |
| `make_image_header.py` | → `../conv2dstem_image.h`, `int8 [230,230,4]`; `--tvm-layer0` → `../conv2dstem_image_tvm.h`, `int16 [224,224,3]` |
| `make_weights_header.py` | → `../conv2dstem_weights.h`, `int8 [64,7,7,3]` + 64 qparams |
| `groundtruth.py` | → `../conv2dstem_golden.h`, `uint8 [112,112,64]`; also `--applog` |
| `stem_fixture.npz` | The arrays the weight header was built from, pinned for `groundtruth.py` |

## Comparing against TVM's layer 0

The TVM flow quantizes the same image in its own layer 0,
`tvmgen_default_fused_divide_round_add_clip_cast_subtract_layout_transform`
(`worklocal/tvmrelay_deploy/layers/00_*/`). Dumping both and finding they
disagree is expected and **not a bug** — the arithmetic is identical, the
representation is not. Verified bit-exact over all 150,528 values on `dog.jpg`:

| | `conv2dstem_image.h` | TVM layer 0 |
|---|---|---|
| offset | `x_u8 - 128` | `x_u8 - in_zp` (113) — a constant **+15** apart |
| dtype | `int8`, [-128, 127] | `int16`; [-113, 142] does not fit int8 |
| border | 3 px of `in_zp` → `[230,230]` | none, `[224,224]` — TVM pads inside the conv op downstream |
| channels | 4 (ch3 = alignment pad, always 0) | 3 |
| layout | HWC | HWC (`h*672 + w*3 + c`) |

So a hexdump of TVM's output starts `98 ff 9e ff a9 ff …` — that is **int16
little-endian**, `0xff98 = -104`, not a byte stream. The fixture starts
`f1 f1 f1 00 …` because its first row is the zero-point border
(`0xf1 = -15 = 113 - 128`) and every fourth byte is the alignment pad.

To emit TVM's form — what `deploy_flow.py` holds after its first layer:

```bash
python3 make_image_header.py --tvm-layer0                  # -> ../conv2dstem_image_tvm.h
python3 make_image_header.py --tvm-layer0 --verify-kernel  # + diff vs the compiled kernel
```

This does **not** convert the fixture. It runs the kernel's own two steps, in
the same order and the same float32 precision
(`fixture_common.tvm_quantize_u8` → `tvm_layer0`):

```c
v = roundf(x * 53.78862f) + 113.0f           /* quantize */
v = min(v, 255.0f);  v = max(v, 0.0f)        /* clip     */
out[h*672 + w*3 + c] = (int16_t)v - p1[0]    /* cast + layout, p1[0] = 113 */
```

Three details that are easy to get subtly wrong, and are why this is a
reimplementation rather than a formula:

- The float literals are **read out of the generated C**
  (`parse_tvm_layer0_consts`), not recomputed. TVM emits the scale reciprocal
  to 7 significant digits — `5.378862e+01f` — which is *not*
  `float32(1/in_scale) = 53.788624`. The gap is ~7e-8 relative; harmless here,
  but recomputing would quietly make this a different front end.
- It is a **multiply by the reciprocal in float32**, not `x / in_scale` in
  float64. Those differ by up to 1.3e-5 before rounding.
- `roundf` is round-half-**away-from-zero**; `np.round` (and ONNX Runtime's
  QuantizeLinear, hence `preprocess_to_pad4`) is round-half-to-**even**.
  `fixture_common.roundf` implements the C rule.

The last two only bite within ~1e-5 of a `.5` tie. On `dog.jpg` nothing comes
closer than 0.002, so both front ends agree exactly — but a different image
could make them differ by 1 LSB on a handful of pixels. That is the first place
to look if the two ever disagree sparsely.

### Checking it against the real kernel

`--verify-kernel` compiles `layers/00_*/00_*.c` from its own source with the
host gcc, drives it through TVM's packed ABI on the same image, and diffs the
output buffer. It is the only check that compares against the *compiled code*
rather than against a reading of it:

```
  [verify] MATCH -- all 150,528 values equal the compiled 00_divide_round_..._transform/ kernel
```

It needs stage 5's per-layer split and stage 6's `arm_build/tvm_graph_types.h`;
without them it reports what is missing instead of failing. Every run (with or
without `--verify-kernel`) additionally asserts the result equals
`pad4_to_tvm_layer0(pad4)`, so the two front ends cannot drift apart silently.

Neither mode overwrites `conv2dstem_image.h` — `conv2dstem.cc` consumes that
one and needs the int8 / pre-padded form.

## Why the headers are not in this directory

`script/aiehlc.sh:532` copies user headers into the build with a **non-recursive
glob, flattened to basename**:

```bash
for f in "${SOURCE_DIR}"/*.h; do cp -f "$f" "${WORKLOCAL_DIR}/$(basename "$f")"; done
```

and `script/hostcompile.sh:345` gives the host compile only `-I${WORKLOCAL_DIR}`.
A header left in `data/` is never copied, so `#include "data/image.h"` parses
fine in the aiehlc frontend (which does get `-I${SOURCE_DIR}`) and then dies at
the cross-g++ step. Hence the generators write **flat into the parent
directory** with a `conv2dstem_` prefix. `--out` overrides it.

`conv2dstem_golden.h` is gitignored (~800 KB, fully derived). The image and
weight headers are committed, so the app builds with no network.

## The three things that would silently produce wrong pixels

1. **Border padding is the zero-point, not zero.** The quantized graph pads the
   conv's 3-pixel border with `in_zp = 113` — ONNX pads the *dequantized* tensor
   with `0.0`, and `0.0` dequantizes from `x_q = zp`. After the `x − 128` shift
   the border is `−15`, not `0`. Padding with zero corrupts every edge pixel.
2. **The stored shift is `−exponent`.** TVM's `GetFixedPointMultiplierShift`
   returns `frexp`'s exponent, but the core applies it as `>> (shift + 31)`, so
   the qparam holds its negation (here, `+7..+27`). `fold_qparams` asserts the
   `mult · 2^−(shift+31)` round-trip per channel because the wrong sign yields
   plausible-looking but uniformly wrong output.
3. **The accumulator must be int32.** See above — 1,023,225 against 32,767.

## Verification

Off-board, the generated headers are checked against the x86 model of the
core's arithmetic (`../ref/conv2dstem_x86.c`), which is **bit-exact**:

```
x86 kernel model vs golden: 0 mismatches / 802816
```

`groundtruth.py` additionally cross-checks its own numpy reference against
**onnxruntime** running the real quantized layer. A handful of differences is
expected and is reported, not failed — ORT rounds half-to-even on floats where
the core does fixed-point round-half-up:

```
[xchk]   802,814/802,816 agree with onnxruntime; 2 differ, max 1 (rounding only)
```

A *large* divergence there means a scale or zero-point was read wrong.

On-board:

```bash
bash script/aiehlc.sh --aie-version 5 \
    --runtime-source-file ./src/aietensorop/conv2dstem/main.cc
python3 ./script/test/apppaltest.py -y -nonreboot > ./applog 2>&1
python3 src/aietensorop/conv2dstem/data/groundtruth.py --applog ./applog
```

`main.cc` compares against the golden array on the board and prints a bounded
mismatch report (capped at 32 lines — `apppaltest.py` has a 300 s no-output
watchdog) plus one machine-readable verdict line that `--applog` parses back. A
baremetal board under xsdb cannot hand a file back; the console is the only
channel.

Reading a failure:

| Pattern | Likely cause |
|---|---|
| outer 3 rows/cols only | zero-point border padding |
| scattered | the AIE data path (skill: `datacorrectness`) |
| everything, uniformly | qparam folding — check the shift's sign |
