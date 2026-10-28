---
name: blockloadkernel
description: Writing or debugging a Triton-style block-load AIE kernel on top of the declarative conv2d model (`__global__(conv, map)` + `aie::program_id`, `aie::load_buffer` / `aie::store_buffer` in tensor coordinates, `aie::release` / `aie::commit`). Use for "no member named 'program_id' in namespace 'aie'", klog BLKE/BLKW/BLKG, a kernel local clashing with an emitted macro (`OH_T`, `OW_T`, `TILE_*`, `SP_*`, `K`), or to emulate the generated kernel on x86 before a board run.
---

# Triton-style block-load kernels

Example: `example/tileprogram/ccode/simpleconv2d_new_load.cc`. Design:
`doc/design/op_mapping_programming_model.md` §4 (the derivation itself is
convautotile: `doc/design/conv_autotiling.md`).

## How it lowers
- convautotile desugars `conv`/`map` into GemmSpaces + kernel `#define`s and,
  via `kernelTUDecls`, the kernel-TU `conv`, `map` (block sizes) and per-port
  `aiehlc_desc_<port>` block descriptors (same `Derived` numbers as the DMA).
  `aiehlc.cc` appends those after the `#define` scan (`convKernelDecls`).
- `resolveBlockIoBuiltins` (tilinglinalg_pipeline.cpp) rewrites
  `aie::load_buffer/store_buffer/release/commit` to `aie_block_io.h` and
  `aie::program_id(0|1)` to `get_coreid()` minus the `dmaphop.tile` placement
  base (attribute `tiletype`, printed as `TILETYPE`).

## Traps
- A load does NOT choose the data: the DMA order is fixed; the call takes the
  next window and only CHECKS the block (klog BLKE, visible with kernel logging
  on). Wrong offsets can still give a correct output.
- Kernel locals must not reuse emitted macro names: convautotile emits
  `OH_T`, `OW_T`, `TILE_*`, `SP_*`; the example header defines `M`, `N`, `K`.
  Use lower-case locals (`oh_t`, `ow_t`).
- The op is the math (`224x224x3`, `.pad = 3`), not the padded DDR layout.
- Emulate before the board:
  `bash example/tileprogram/ccode/simpleconv2ddebug/emu_conv2d_spatial.sh aout/worklocal`
  (802,816 outputs vs the CPU reference, plus the BLKE count).
