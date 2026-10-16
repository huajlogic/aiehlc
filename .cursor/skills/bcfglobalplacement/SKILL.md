---
name: bcfglobalplacement
description: An aiehlc kernel that uses aie_api SRS/to_vector (requantize, shift-round-saturate) produces outputs off by +1 (or other small, data-dependent rounding errors) on hardware while the same math is exact on the host; or kernel.map shows `_ZN12me_primitive11control_rndE`, `control_satE` or `_ZZ4mainE11sync_buffer` at DMb 0x0..0xff; or a kernel global reads back garbage. Root cause: the generated aieml.bcf did not reserve the non-local data address space, so bridge placed .data/.bss at DMb 0x0 — not this tile's memory.
---

# Kernel globals must live in the tile's own data memory

## Symptom
`conv2dstem_vec.cc` (aie::mmul + vector requantize) ran 17.9x faster but failed
golden with **726,699 / 802,816 outputs off by exactly +1**. The algorithm was
proven exact in numpy (0 mismatches); no single SRS rounding mode reproduced
the count — the mode was effectively *random per tile and round*.

## Root cause
aie_api keeps the rounding/saturation mode in libme globals
`me_primitive::control_rnd` / `control_sat`, and chess **reloads `crRnd`/`crSat`
from them after every call** (e.g. each `acquire_input_window`). `aieml.bcf` only
reserved `DMb 0x40000 0x10000`, so bridge placed all `.data/.bss` at **DMb 0x0**
(see `build/kernel.map`, "Memory map for memory 'DMb'"). That is not the core's
own memory (own = 0x70000..0x7FFFF), so the restored mode was whatever byte lived
there. `rnd_floor` is 0 (`aie2ps/lib/me_defines.h`), so a dead address would have
been harmless — the fact that results changed proves it aliased live memory.
Scalar kernels never call SRS, which is why this hid until the first vector kernel.

A second latent hole: output buffers were declared `v4int8[196]` (784 B) for a
3136 B DMA window, so once globals were pushed into own memory the linker could
place them in the "free" tail the DMA writes.

## Fix (compiler)
* `tilinglinalg_pipeline.cpp` Phase 4 (BCF): reserve `0x0 0x40000`,
  `0x40000 0x10000`, `0x50000 0x20000`, and the TM window `0x80000 0x80000` — the
  same convention ADF BCFs use (`_reserved DMb 0x0 0x40000` ... `0x80000 0x80000`).
* `passdfscheduletokernelapi.cpp`: declare every buffer at least
  `CoreMemAllocator::getSize(name)` bytes (new accessor), so the C symbol covers the
  whole DMA slot.
* Do **not** `_reserved` a buffer's own range: bridge then fails with
  `cannot find free area ... for space symbol 'buf_in_ping_0'` (a pinned `_symbol`
  may not sit inside a reserved range).

## Verify
```bash
cat aout/worklocal/aieml.bcf                         # 4 _reserved lines incl. 0x0 0x40000
grep -E "control_rnd|control_sat|sync_buffer" aout/worklocal/build/kernel.map   # all >= 0x78000
grep "v4int8 buf_out" aout/worklocal/kernel.cc        # [784] for conv2dstem, not [196]
```
Board: conv2dstem_vec GOLDEN PASS 802816/802816 (1.77 ms); scalar conv2dstem
unchanged (GOLDEN PASS, 31.47 ms).

## Rule
Any time a kernel misbehaves only after adding aie_api vector/SRS code, check
`kernel.map` for symbols below 0x70000 before suspecting the arithmetic.
