---
name: opmappingmodel
description: Writing or extending a `__global__(op, map)` kernel (aie::Conv2d + aie::Mapping, ports tagged aie::IFM/WEIGHTS/OFM). Use when such a kernel fails with "'Conv2d' in namespace 'aie' does not name a type" in host_fixed.cc, "non-type template argument is not a constant expression ... mapping_check", the kernel TU cannot see SP_*/OW_T/TILE_W or `conv`, OH comes out 115 instead of 112, or when adding a new operator to the derivation.
---

# Op + mapping kernels (`__global__(op, map)`)

Design: `doc/design/op_mapping_programming_model.md`. Example:
`example/tileprogram/ccode/simpleconv2d_new_load.cc` (byte-identical IR/host/kernel
to the hand-written `simpleconv2d.cc`).

## How it lowers
- `aiehlc.cc` rewrites `__global__(conv, map)`: port tags `aie::IFM` ->
  `aie::derive(aie::IFM, conv, map)` (a C++20 class NTTP read by the existing
  APValue port parser), plus a synthesized `constexpr aie::GlobalPolicy
  __aie_policy_conv_map = aie::derive_policy(conv, map)`.
- The types and `derive` live in ONE string, `opModelPrelude()` in
  `tilinglinalg/pass/aiehlc_opmodel.h`.

## Traps
- **Three `aie::` preludes.** The frontend prelude and the stub block in
  `aiehlc.cc`, AND the host stubs `tilinglinalg_pipeline.cpp` writes into
  `host.cc` (that one defines `AIEHLC_TILING_STUBS_DEFINED` first, so the
  aiehlc.cc block is skipped in `host_fixed.cc`). A new type must reach all
  three -- emit `opModelPrelude()`, never copy it.
- **The kernel TU sees only `#define`s from the .cc** -- no constexpr globals.
  `opDeclForKernel` evaluates the op and pushes a literal
  `static constexpr aiehlc_conv2d_t conv = {...}` onto `userMacroDefines`.
  It is OUTSIDE `namespace aie`: the kernel TU includes the AIE API, which owns
  `aie::` (e.g. `aie::tile`).
- Loaded-data geometry comes from the ports:
  `aie::get_arg_per_round_size_in_dim(d, port)` resolves from the derived
  `#routing.tiling`; the width slab is NOT there (it is in `#routing.halo`), so
  compute it: `((ow_t - 1) * stride + kw) * c`.
- **The op is the math, not the DDR layout.** `{.h = 224, .c = 3, .pad = 3}`;
  writing the padded `230`/`4` pads twice (OH 115). The channel alignment and
  the padded pitch are derived.
- Validation is `mapping_check(cond, "why")`: a `throw` in the constexpr
  `derive` makes the port's NTTP non-constant; Clang prints the "why" note.
- `MESH_ROW`/`MESH_COL` are user macros that must equal the launch mesh.

## Triton block-load kernels (aie::load_buffer / store_buffer / program_id)
- `aie::program_id(0|1)` is resolved by `resolveBlockIoBuiltins` from the
  `dmaphop.tile` placement -- the attribute is `tiletype` (the printer shows
  `TILETYPE`); a lookup by the printed name finds nothing and program_id stays
  unresolved ("no member named 'program_id' in namespace 'aie'").
- A load does NOT choose the data: the DMA order is fixed, the call acquires the
  next window and only CHECKS the block (klog BLKE, visible with kernel logging
  on). Wrong offsets can still give a correct output -- don't trust a PASS as
  proof the offsets are right; run `simpleconv2ddebug/emu_conv2d_spatial.sh`.
- Kernel locals must not reuse the example header's macro names (`M`, `N`, `K`):
  the host TU and the x86 emulator include it.
