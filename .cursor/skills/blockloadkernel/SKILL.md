---
name: blockloadkernel
description: Writing or debugging a Triton-style block-load AIE kernel -- kernel-only (`__global__ void k(aie::port<T, aie::IFM, aie::shape<...>> ...)`, DMA inferred from the kernel) or on top of `__global__(conv, map)` -- with `aie::program_id`, `aie::load_buffer` / `aie::store_buffer` in tensor coordinates, `aie::release` / `aie::commit`. Use for `[KernelAnalysis] ERROR` (too big / too small, outside the tensor, data used without being loaded, use after release, never committed, column-outer loops, schedule depends on data, never stored), Use for "no member named 'program_id' in namespace 'aie'", klog BLKE/BLKW/BLKG, a kernel local clashing with an emitted macro (`OH_T`, `OW_T`, `TILE_*`, `SP_*`, `K`), or to emulate the generated kernel on x86 before a board run.
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

## Kernel-only kernels (no conv / map)
- Ports carry the tensor: `aie::port<T, aie::IFM, aie::shape<230, 230, 4>>`.
  `inferKernelOnly` (kernel_trace.cpp) traces the body on x86 under ASan for
  every core, fits each port to base/step/rounds, recognizes the spatial-halo
  conv, derives with convautotile, compares exactly, then rewrites the source
  into `__global__(__aie_conv_k, __aie_map_k)`. Example:
  `example/tileprogram/ccode/simpleconv2dkernel.cc`.
- Iterate with `build/aiehlc-convtile trace <file.cc>` (seconds) instead of a
  full aiehlc.sh run; `AIEHLC_TRACE_KEEP=1` keeps the harness.
- A too-small slab is reported as "data used without being loaded" (ASan), not
  as a shape mismatch: the conv compute reads past it first.
- The body must compile on x86 and the schedule must be data-independent.
- Regression: `python3 src/llvm/convautotile/unitest/kernel_trace_cases.py build/aiehlc-convtile`.
