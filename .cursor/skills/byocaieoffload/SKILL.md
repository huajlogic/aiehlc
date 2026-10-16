<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: byocaieoffload
description: Offload a TVM Relay layer to the aiehlc AIE library via BYOC (`deploy_flow.py --aie-offload --aie-layers N`; `--byoc-aie` is gone, merged into it). Read before touching src/frontend/tvmrelay/byoc/, aie_offload.py, conv2dstem.cc, or the arm_build link. Covers why the subgraph is the FUSED op, the uint8 input x-128 shift, zero-point padding (conv2d_stem_prepadded), matching layers by weight fingerprint not position, the int16 accumulator overflow, params in the filter pad channel, kernel-visible macros, the libxil.a duplicate-XAie_* link failure, and aiehlc.sh wiping aout/.
---

# TVM BYOC -> AIE offload (ResNet-18 stem)

```bash
# 1. build the AIE library (also populates thirdparty/alib/lib). Re-run after
#    ANY other aiehlc.sh run -- every run resets aout/ and deletes the .a.
source script/aiehlc.sh --aie-version 5 \
    --runtime-source-file ./src/aietensorop/conv2dstem/conv2dstem.cc
# 2. in the SAME shell -- alib/lib is wiped by every aiehlc.sh run
export PATH="$XILINX_VITIS/gnu/aarch64/lin/aarch64-none/bin:$PATH"
<venv>/bin/python3 src/frontend/tvmrelay/deploy_flow.py --aie-offload --aie-layers 1
# bit-exact check, no hardware needed
PYTHONPATH=src <venv>/bin/python3 src/frontend/tvmrelay/byoc/verify_aie_stem.py
```

Without `--aie-offload` the generated C contains no `conv2d_stem_prepadded`
call and nothing extra is linked. Design: `doc/design/aie_offload_byoc.md`.

## 1. The accumulator MUST be int32 -- and synthetic data hides it

`conv2d_stem` originally accumulated into `int16_t`. With the **real** stem
weights that overflows:

| | value |
|---|---|
| peak \|accumulator\| (measured, random int8 input) | **257,339** |
| worst case over the weight set | 1,182,116 |
| int16 range | +-32,767 |

It looked correct only because `main.cc` fed values in `[-4,4] x {-1,0,1}`,
chosen with a comment saying they keep the accumulator in range. Reverting to
`int16_t` and re-running the checker gives **333,638 / 802,816 elements wrong
(41.6%)** -- it wraps silently, before any clamp.

**Never validate this kernel with synthetic small values.** Use:

```bash
<venv>/bin/python3 src/aietensorop/conv2dstem/ref/stem_ref.py   # fixture from real weights
gcc -O2 -o /tmp/vp src/aietensorop/conv2dstem/ref/verify_pack.c
/tmp/vp worklocal/stem_fixture
```

`stem_ref.py` is cross-checked bit-exact against TVM's own compiled conv, so it
is ground truth, not a second opinion.

## 2. The BYOC subgraph is the FUSED op -- the raw conv was a fake offload

The old design cut at the bare `nn.conv2d` and asked for an int32 accumulator.
The AIE kernel cannot emit that -- it only produces the fused uint8 result -- so
`conv2d_stem_raw()` was a **scalar loop on the APU**: `--byoc-aie` offloaded
nothing. It also never got its weights (`conv2dstem_byoc_set_weights` had no
caller). Both are gone.

The composite (`aie_patterns.fused_qconv_pattern`) now covers the whole
canonicalized chain, and `extract_fused` names every constant once:

```
conv → [− C1·Σx] → +C2 → bias_add C3 → [cast] → −C4 → fpm(C5, C6=lshift, C7=rshift) → clip(0,255) → cast u8
```

It folds into the kernel's per-channel params as
`bias = C2 + C3 − C4 + 128·Σw`, `zp = 0`, `mult = C5`, `shift = C7` -- TVM's
`QMultiplyShift` is `(x·y + 2^(rs+30)) >> (rs+31)`, the core's formula. The
checker REJECTS C1 ≠ 0 (data-dependent), any left shift, other clips.

`FoldConstant` must run AFTER `qnn.CanonicalizeOps` too, or C2 stays an
expression and `is_constant()` never matches.

## 3. uint8 input, zero-point padding: shift by 128, take TVM's pad

The stem input is asymmetric **uint8, zero-point 113**, and `nn.pad` fills with
**113**, not 0. Two traps:

* A plain uint8 -> int8 cast corrupts every pixel ≥ 128: **613,203 / 802,816**
  outputs wrong on full-range input. The wrapper passes `x − 128`; the
  `+128·Σw` in the bias restores the sum exactly.
* `conv2d_stem()` re-pads with **zero** -- wrong on every border pixel. The
  wrapper calls `conv2d_stem_prepadded()` with TVM's 230x230 tensor, border and
  all (also shifted by 128, so it stays exact).

The old synthetic fixture (`stem_ref.py`, int8 in [-128,127]) cannot see either.
Verify with `verify_aie_stem.py`, which uses full-range uint8 and the real image.

## 3b. Match layers by WEIGHT FINGERPRINT, never by position

`--aie-layers` uses stage-5 numbering (graph executor order). Relay's post-order
is different: TVM fuses each ResNet shortcut conv with the residual add, so the
executor runs it AFTER the main branch while Relay visits it first -- convs
5-7, 10-12, 15-17 swap. "n-th conv" offloads the wrong conv.
`aie_annotate.weight_fingerprint` (sha1 of the SORTED weight values) is
independent of the CPU build's NCHWc-blocked int16 storage and unique for all
20 convs; `aie_offload.check_targets` fails closed on any mismatch.

## 3c. Wrapper C must survive split_layers

`split_layers` carries the file prologue, prototypes and function bodies --
NOT file-scope statics or typedefs that land mid-file. So the weights/qparams
are function-scope `static const` inside the wrapper, and `qp` is a flat
`int32[OC*4]` passed as `const void*` (same layout as `conv2dstem_qparam`).

## 4. Per-channel quant params ride in the filter window's pad channel

The fused `conv2d_stem` needs 4 int32 per output channel. Two approaches that
look reasonable and are not:

* **A fourth `aie::port`** -- every kernel in this repo uses exactly three.
  Unproven in the routing/DMA path.
* **Appending 16B per channel** (a 212-byte row) -- breaks `ColBC`, which
  factorizes the window as exactly `d1(N) x d2(KW) x d3(KH) x d4(C_ALIGN)`.
  There is no slack dimension, so the DMA moves the wrong bytes while still
  appearing to work.

What works: `INPUT_C=3` padded to `INPUT_C_ALIGN=4` leaves byte 3 of all 49
taps unused -- 49 free bytes per channel, 16 needed. Params go in taps 0..15 at
offset `SP_PARAM_TAP_OFF`. Zero extra bytes, zero DMA change.

**The MAC loop must then stop at `SP_REAL_C`, not `c_dim`**, or it multiplies
the params into the accumulator. Numerically free, since the matching ifm pad
channel was always zero.

## 5. Kernel-visible helpers must be MACROS

The kernel extractor copies only `#define`s written directly in the `.cc` into
the kernel translation unit. A `static inline` helper compiles fine in the
host TU and then fails the kernel build with:

```
./conv2d_spatial.cc:172:44: error: use of undeclared identifier 'rd_param_i32'
```

Hence `RD_PARAM_I32(brow, idx)` is a macro. Same rule as the geometry
`#define`s already documented in that file.

## 6. Link: duplicate `XAie_*` from the BSP's libxil.a

```
multiple definition of `XAie_UpdateNpiAddr'
  .../alib/lib/libxaienginea78.a(xaiegbl.o)
  .../bsp/lib/libxil.a(xaiegbl.c.obj)   first defined here
```

The BSP's `libxil.a` carries **62** stale `xaie*` members; the authoritative
driver `libxaienginea78.a` has **67**. `build_hw_lib` (aiehlc.sh) solves this
for its own build by `ar d`-ing the stale members and renaming the result --
note it RENAMES libxil.a to libxaienginea78.a, so looking for a stripped
`libxil.a` in `alib/lib` finds nothing.

`arm_build._aie_link_vars` therefore stages `alib/lib/*.a` into
`<out>/arm_build/aielib/` and `ar d`s the BSP libxil.a copy itself. Staging is
required anyway: **`thirdparty/alib/lib` is wiped by every aiehlc.sh run**, so
a plain `-L` into it usually finds an empty directory by the time `make` runs.

## 7. Library build traps

* **A comment containing the triple-angle launch syntax** near the launch
  function makes aiehlc's text rewriter splice `__aie_launch(...)` over the
  function signature (`newfile.cpp: expected unqualified-id`). Skill
  **aiesourcetextrewrite**.
* `aiehlc.sh` writes `mktemp /tmp/aiehlc_err.XXXXXX` -- a sandbox where only
  `$TMPDIR` is writable fails with `Read-only file system` (and still wipes
  `aout/`). Run it unsandboxed.
* The launch lives in ONE static helper (`stem_run`) shared by `conv2d_stem`
  and `conv2d_stem_prepadded`: the mesh `partition(...)` VarDecl must be in the
  same function as the launch.

## Verification ladder

Each rung is cheap and catches a different class of error:

1. `verify_pack.c` -- packing round-trip + epilogue vs TVM ref (802,816 elems, 0 mismatch)
2. `verify_aie_stem.py` -- wrapper + `ref/conv2dstem_x86.c` vs TVM's own fused op
   on LLVM: 0 / 802,816 on full-range uint8 AND the dog image; re-injecting the
   plain cast must FAIL (it does: 613,203 wrong)
3. same script, whole network: partitioned vs unpartitioned, 0 / 1000 logits differ
4. `--aie-offload` -- 1/20 matched, `resnet18.c` compiles, 65 layers split, all compile
5. link -- `main.elf` against `aout/libconv2dstem.a`, 0 undefined
6. without `--aie-offload` -- zero `conv2d_stem_prepadded` in the C (no regression)

**Not yet verified: execution on hardware.** Everything above is host-side.
