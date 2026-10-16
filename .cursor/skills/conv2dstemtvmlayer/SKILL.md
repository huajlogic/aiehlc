<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: conv2dstemtvmlayer
description: Drive the conv2dstem AIE app from a real TVM graph layer's layeriohex dump instead of the hand-built fixture -- conv2d_stem_nchwc(), conv2d_stem_in_weight.h, NCHW4c/OIHW3i4o layout bridges. Use when wiring a `make TRACE=1` tensor dump into an aiehlc app, when a conv produces plausible-but-wrong pixels after a layout change, when the int32 quant params read back as garbage or the board faults reading them, or when mismatch coordinates name the wrong pixel. Covers the two-zero-point fold, the unaligned-int32 trap, and how to verify the whole host chain without a board.
---

# Running a real TVM layer on the conv2dstem AIE kernel

## What this is

`src/aietensorop/conv2dstem/test_conv2d.cc` drives `conv2d_stem_nchwc()` from
`conv2d_stem_in_weight.h` — the `layeriohex` dump of call [01] of the compiled
int8 ResNet-18 graph — and self-checks against that layer's own output. The app
reproduces an operator the deployed network really runs, rather than a model of
it.

## Build it with buildtest.sh

Both data headers are **generated** and not committed, so building by hand fails
on a missing include. `src/aietensorop/conv2dstem/buildtest.sh` regenerates
them and then builds:

```bash
./buildtest.sh                 # make local TRACE=1 -> run elf -> copy headers -> aiehlc
./buildtest.sh --skip-trace    # reuse the layeriohex on disk (steps 1-2 are slow)
./buildtest.sh --no-aiehlc     # stop once the headers are in place
```

Two traps it exists to handle, both of which fail *silently* by hand:

* **The Makefile's objects do not depend on `CFLAGS`.** If a previous
  *untraced* `make local` left `localobj/` behind, `make local TRACE=1` relinks
  a stale ELF that compiles none of the trace code and writes no dumps at all.
  `make clean-local` first is mandatory, not hygiene.
* **`aiehlc.sh` writes its `aout/` tree relative to the CURRENT WORKING
  DIRECTORY**, not relative to the entry file or to its own location. Run it
  from the app directory and you get `src/aietensorop/conv2dstem/aout/` while an
  older `$REPO/aout/` sits untouched — so a "did the ELF get built" check passes
  against a *stale* binary. The script `cd`s to the repo root and additionally
  requires the ELF to be newer than the run started.

`main_local.elf` must also be run **from** `arm_build/`: `graph_dump_hex` writes
`./layeriohex` relative to the process's cwd, not the ELF's location.

Note `clean-hex` is deliberately separate from `clean-local`, so stale
`param_*.h` from an earlier run persist in `layeriohex/`. Harmless — the script
deletes the two files it is about to copy, so a failed run is caught rather than
silently copying yesterday's dump.

## Start here: the arithmetic is probably already right

Before changing any kernel math, check whether the gap is only **layout**. For
this layer it was. TVM's op is

```
acc = Σ_{kh,kw,ic} ifm * w                                           (int32)
v   = (int64(acc + bias − zp_a − zp_b) * mult + (1 << (sh+30))) >> (sh+31)
out = clamp(v, 0, 255)
```

and `conv2dstem_qparam {bias, zero_point, multiplier, shift}` already implements
exactly that — `conv2dstem.h` says it is "TVM's `fixed_point_multiply_per_axis`
lowering transcribed exactly", and that holds. **All 802,816 outputs recompute
bit-exactly.** What differed was three layouts:

| | TVM layer | library | bridge |
|---|---|---|---|
| input | `int8[230,230,3]` zp-padded | same | **none** — `stage_ifm_prepadded()` already widens 3→4 |
| weights | `int8[16,7,7,3,4]` OIHW3i4o | `int8[64,7,7,3]` OHWI | `stage_weights_nchwc()` |
| output | `uint8[16,112,112,4]` NCHW4c | `uint8[112,112,64]` HWC | `collect_ofm_nchwc()` |

All three are **host-side**. The AIE core, the `GemmSpace` d1..d4 descriptors
and the DMA are untouched. If you find yourself editing the MAC loop to match a
TVM layer, stop and re-derive the index math first.

TVM's packed strides, read off the generated kernel:

```
oc = oc_chunk*4 + oc_block            # the OUTER product -- a filter's taps are strided 4 apart
w  [occ*588 + kh*84 + kw*12 + ic*4 + ocb]     588=KH*KW*IC*4, 84=KW*IC*4, 12=IC*4
out[(occ*112 + oh)*448 + ow*4 + ocb]           448 = OUTPUT_W * 4
ifm[(oh*2+kh)*690 + (ow*2+kw)*3 + ic]          690 = 230*3, stride 2
```

## Three traps

### 1. TVM subtracts TWO zero-points; the struct has one field

`acc + bias − zp_a − zp_b`, but `conv2dstem_qparam` carries a single
`zero_point`. The fold is only valid while one term vanishes. For this
quantization `zp_b` (and the `unused` param) measure **identically zero** —
symmetric per-channel weights — so `zero_point = zp_a` is exact.

That is a property of *this* model, not a guarantee.
`main.cc:fold_qparams()` therefore **checks it per channel and refuses**, naming
the channel, rather than silently computing wrong pixels. Do not "fix" a future
non-zero `zp_b` by adding the two together without re-deriving the algebra.

### 2. The generated `_data[]` is `unsigned char[]` — do not cast it to `int32_t*`

```c
int32_t v = ((const int32_t *)TVM_BIAS)[oc];   /* WRONG: unaligned + endian-dependent */
```

`static const unsigned char x[]` need only be 1-byte aligned, so this is an
unaligned load that **faults on the A78**, and it bakes in host endianness. The
dump is little-endian by definition (`graph_dump_hex` writes the buffer's own
bytes). Assemble it:

```c
static int32_t rd_i32(const unsigned char *p, int idx) {
    const unsigned char *b = p + (size_t)idx * 4u;
    return (int32_t)((uint32_t)b[0] | ((uint32_t)b[1] << 8) |
                     ((uint32_t)b[2] << 16) | ((uint32_t)b[3] << 24));
}
```

### 3. Mismatch coordinates must decode as NCHW4c

The output buffer is `[16][112][112][4]`, not HWC. Decoding it the old way names
a different pixel for every reported mismatch, which sends you hunting in the
wrong place:

```c
const int ocb = i % 4;
const int ow  = (i / 4) % OUTPUT_W;
const int oh  = (i / (4 * OUTPUT_W)) % OUTPUT_H;
const int occ = i / (4 * OUTPUT_W * OUTPUT_H);     /* oc = occ*4 + ocb */
```

Also: the generated header must land **flat** in the app source dir —
`aiehlc.sh:532` copies user headers with a non-recursive `*.h` glob flattened to
basename, so one left in a subdirectory parses in the frontend and then fails at
cross-g++ (skill **conv2dstemfixture**).

## Verifying without a board

A layout bug and a kernel bug look identical in the output, so separate them.

**Layout round-trip.** Fold TVM's packed weight to plain OHWI, run both packers,
and require a byte-identical `g_wts_bt`:

```
stage_weights(OHWI)  vs  stage_weights_nchwc(TVM)   ->  12544 bytes, 0 differing
```

**End-to-end on the host, from the real source text.** Extract
`stage_ifm_prepadded`, `stage_weights_nchwc`, `scalar_conv2d_ref`,
`collect_ofm_nchwc` (conv2dstem.cc) and `rd_i32`, `fold_qparams` (main.cc) by
name into a `.inc`, compile them against the two data headers with a plain
`gcc`, and use the kernel's own `scalar_conv2d_ref()` in place of the AIE.
This exercises the entire host chain — param decode, weight pack (including the
quant params hidden in the pad channel), and output scatter — and prints the
same `GOLDEN PASS 802816/802816` line the board does. Extracting the functions
rather than copying them matters: a copy tests the copy.

Also test the **negative** path: poison one `zp_b` byte and confirm
`fold_qparams()` rejects and names that channel.

## Do not fold this into `conv2d_stem_prepadded()`

`conv2d_stem_nchwc()` is a separate entry on purpose. `conv2d_stem_prepadded()`
is the TVM BYOC wrapper's contract (`byoc/aie_codegen.py`), and the two differ
*only* in layout — merging them would silently reinterpret every weight and
output byte for the `--aie-offload` path, which fails as wrong pixels rather
than as a link error. The change that added `conv2d_stem_nchwc()` is **94
insertions, 0 deletions**; keep it that way, and check `git diff --stat` says so.
