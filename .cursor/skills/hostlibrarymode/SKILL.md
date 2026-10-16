<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: hostlibrarymode
description: Build an app source that has no main() -- e.g. example/tileprogram/ccode/simplematmul2_aiegraph.cc, whose host entry is `int test_matmul(int)`. hostcompile.sh archives it into a static library (lib<app>.a) instead of linking an ELF. Use when a build dies with "return-statement with a value, in function returning 'void'" in host_canonicalized, when you need to embed an aiehlc-generated host into a larger program, or when you must link a user main() against the produced .a.
---

# Host Library Mode (app source with no `main()`)

## Symptom

Building an app whose host entry is not `main()`:

```
source script/aiehlc.sh --aie-version 5 \
    --runtime-source-file ./example/tileprogram/ccode/simplematmul2_aiegraph.cc
```

used to fail in the host compile, *after* the whole AIE pipeline succeeded:

```
host_fixed.cc: In function 'void host_canonicalized(XAie_DevInst*, void*, void*, void*)':
host_fixed.cc:955:10: error: return-statement with a value, in function returning 'void'
  955 |   return 0;
```

## Root cause

`hostcompile.sh` rewrote `main`'s trailing `return;` into `return 0;` with

```sh
-e '0,/^  return;$/s/^  return;$/  return 0;/'
```

`0,/re/` matches the **first** `return;` in the whole file. That is only `main`'s
if `main` is the first function emitted. With no `main()`, the first `return;`
belongs to `void host_canonicalized(...)`, so the fixup injected a value-return
into a void function. The error is a symptom of a *missing main*, not of
anything wrong in the app source.

## Behaviour now

`hostcompile.sh` classifies the GENERATED `host.cc` into `HOST_ENTRY_KIND`:

| Kind | Detected by | Fixups | Output |
|------|-------------|--------|--------|
| `user-main` | `int main()` present | `#define __global__` only | `host` ELF |
| `mlir-main` | `void main()` present | `void main`→`int main`, first `return;`→`return 0;`, fwd decl | `host` ELF |
| `library` | neither | fwd decl + `__global__`, **no** return rewrite | `lib<app>.a` |

In `library` mode the same object set that would have been linked is archived
with `ar rcs` and published to **both** `aout/worklocal/build/` and `aout/`.
The library name comes from `worklocal/app_source.txt`:
`simplematmul2_aiegraph.cc` → `libsimplematmul2_aiegraph.a`.

The kernel objects are deliberately archived too, so the embedded-kernel symbols
(`_binary_kernel_<name>_start/_end/_size`) travel inside the `.a`. Verified:

```
$ aarch64-none-elf-nm app | grep _binary_kernel
000000000009d4b0 D _binary_kernel_matmul_end
0000000000014248 A _binary_kernel_matmul_size
0000000000089268 D _binary_kernel_matmul_start
```

## Linking your own main against the archive

`hostcompile.sh` prints a ready recipe at the end of a library build. All
**four** `-L` paths matter — `-lxaienginea78` lives in `ALIB_LIB_DIR`, the BSP
libs in `ARCH_APU_ALIB`; dropping either gives `cannot find -lxaienginea78`.

```c
// main.cc
int test_matmul(int argc);
int main() { return test_matmul(0); }
```

```bash
aarch64-none-elf-g++ -Os -o app main.o \
    aout/worklocal/build/libsimplematmul2_aiegraph.a \
    --specs=nosys.specs -Wl,--defsym,end=__bss_end__ \
    -Wl,-T -Wl,thirdparty/arch/cortexa78_0/lscript.ld \
    -L"thirdparty/alib/lib" \
    -L"<bsp>/lib/../libsrc/build_configs/gen_bsp/libsrc/aienginev2/src" \
    -L"<bsp>/lib" -L"thirdparty/alib/lib" \
    -Wl,--start-group,-lm,-lxaienginea78,-lxil,-lgcc,-lc,-lstdc++,-lxiltimer,-lxilstandalone,-lxilpm_ng,--end-group
```

Note C++ mangling: the archive exports `_Z11test_matmuli`, so declare
`int test_matmul(int);` in C++ (not `extern "C"`) to match.

## Gotcha: `thirdparty/alib/lib/*.a` is wiped every run

`build_hw_lib` in `aiehlc.sh` starts with `rm -rf "$AIE_DRIVER_PARENT_DIR/lib/"*.a`
and rebuilds `libxaienginea78.a` from `aie-rt`. **Merely sourcing `script/aiehlc.sh`
clears that directory**, so a link attempted in a later shell fails with
`cannot find -lxaienginea78` even though the file was there a moment ago.

When linking by hand, copy the libs out in the *same* shell as the build:

```bash
bash -lc '
  source script/aiehlc.sh --aie-version 5 --runtime-source-file <app>.cc >/dev/null 2>&1
  mkdir -p /tmp/libs && cp thirdparty/alib/lib/*.a /tmp/libs/
'
```

and link with `-L/tmp/libs`. The cross toolchain is at
`${XILINX_VITIS}/gnu/aarch64/lin/aarch64-none/bin` — add it to `PATH` directly
to avoid re-sourcing `aiehlc.sh` (which would wipe the libs again).

## Do not "fix" it by adding a main

Adding a `main()` to the app source defeats the point: these sources exist to be
embedded into a larger program (the aiegraph/TVM frontend path) that supplies
its own entry point. Library mode is the intended output, not a fallback.

## Library archive missing `rt_seq_*` (fixed)

Linking a program against a `lib<app>.a` died with
`undefined reference to rt_seq_start_queue` / `rt_seq_shim_bd_addr_fields`
from `libconv2dstem.a(aie_runtime.o)`. `hostcompile.sh` compiled
`aie_runtime_xaie_seq.o` and `aie_ctrlpkt_encode.o`, but its `HOST_OBJS`
(the `ar rcs` list) left them out, while the ELF link branch listed them. So
the archive only failed once something reached `__Runtime_startio`. Both are
now in `HOST_OBJS`. Check with `ar t lib<app>.a`: it must list
`aie_runtime_xaie_seq.o`. Any archive built before the fix must be rebuilt.
