---
name: bspheadergen2
description: Fixes Gen2 (--aie-version 2, cortexa72 BSP) builds that fail with "xpseudo_asm_armclang.h file not found" right after "Starting Merged File Compilation", or with XPAR_CPU_TIMESTAMP_CLK_FREQ undeclared in the runtime's XTime code. Use when a baremetal Gen2 build breaks on a standalone-BSP header that the same source passes under --platform sim or on Gen5.
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Gen2 BSP headers

## 1. `xpseudo_asm_armclang.h` not found in the front-end

`source script/aiehlc.sh --aie-version 2 --runtime-source-file <app>.cc` fails right
after `Starting Merged File Compilation`:

```
In file included from thirdparty/alib/include/sleep.h:43:
In file included from thirdparty/alib/include/xil_io.h:56:
thirdparty/alib/include/xpseudo_asm.h:44:10: fatal error: 'xpseudo_asm_armclang.h' file not found
```

Two compilers read the app source:

| Stage | Compiler | `__clang__` |
|-------|----------|-------------|
| aiehlc AST extraction | Clang (libTooling) | defined |
| Host ELF build | `aarch64-none-elf-g++` | not defined |

The BSP's `xpseudo_asm.h` includes `xpseudo_asm_armclang.h` under `__clang__`.
`thirdparty/alib/include/` is a flattened copy of one BSP, picked by `--aie-version`
and wiped every run. The Gen2 (cortexa72) BSP ships only `xpseudo_asm_gcc.h`; the Gen5
(cortexa78) BSP has both. `--platform sim` hides the problem because examples guard
these includes with `#ifndef __AIESIM__`.

**Fix (in place):** `include/bspcompat/xpseudo_asm_armclang.h` is a shim, and
`aiehlc.sh` appends `-I${AIEHLC_DIR}/include/bspcompat` **last** in `AIEHLC_ARGS`, so the
real Gen5 header still wins. Rules:
- Add `bspcompat` to the **front-end only**, never to the host or kernel compiles (GCC
  takes the `_gcc` branch and must keep using the real BSP).
- Put any new missing-on-one-BSP header next to it, rather than into
  `thirdparty/alib/include/` (regenerated) or by deleting the include from the example.

## 2. `XPAR_CPU_TIMESTAMP_CLK_FREQ` undeclared

`aie_runtime.c` picks the host timer API with:

```c
#if AIE_GEN > 2 && defined(__has_include) && __has_include("xiltimer.h")
#include "xiltimer.h"
#include "xtimer_config.h"
#else
#include "xtime_l.h"
#endif
```

`__has_include` alone is not enough: the Gen2 BSP ships `xiltimer.h` /
`xtimer_config.h` even though XilTimer is not configured for that processor, and its
`XSLEEPTIMER_FREQ` expands to `XPAR_CPU_TIMESTAMP_CLK_FREQ`, which that BSP's
`xparameters.h` never defines (it has `XPAR_CPU_CORTEXA72_0_TIMESTAMP_CLK_FREQ`). Gate on
`AIE_GEN`, the same switch `aiehlc.sh` uses to pick the BSP and to link `-lxiltimer`
(Gen5 only). Keep `__has_include` as a second guard.

## Rule

Verify a change that touches BSP includes with a **baremetal** build on both
`--aie-version 2` and `5`; `--platform sim` skips the `#ifndef __AIESIM__` blocks.
