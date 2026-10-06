<!-- Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Compile environment (host + kernel)

## Setup

```bash
source script/setup.sh --path-set-only   # from repo root; sets XILINX_VITIS and paths
```

`aiehlc.sh` does this itself and then delegates to `hostcompile.sh`
(`WORKLOCAL_DIR=aout/worklocal AIE_VERSION=... PLATFORM=...`).

## script/hostcompile.sh

```bash
WORKLOCAL_DIR=<worklocal> source script/hostcompile.sh             # host + kernel
WORKLOCAL_DIR=<worklocal> KERNEL_ONLY=1 source script/hostcompile.sh  # kernel only
```

Without `WORKLOCAL_DIR` it uses the current dir if it holds `host.cc`/`kernel.cc`, else
`./aout/worklocal`. Output: `<worklocal>/build/host`.

| Option / env | Effect |
|--------------|--------|
| `--aie-version 2` / `5` (`AIE_VERSION`) | 2 = AIEML (cortex-a72), 5 = AIE2PS (cortex-a78); sets `-DAIE_GEN`, which must match the XAie lib. |
| `--platform baremetal` / `linux` (`PLATFORM`) | `aarch64-none-elf-` or `aarch64-linux-gnu-` |
| `CROSS_COMPILE` | toolchain prefix override |
| `DEBUG_SYMS=1` | add `-g` to the host build |

Kernel build (`compile_one_kernel` -> `script/kc.sh`): xchesscc `kernel.cc` -> LLVM IR,
xlopt twice, xchessmk link with the generated `.prx`. `kc.sh` then strips `.debug_loc` from
the kernel ELF (the full-DWARF copy stays as `kernel_debug`), and in AOT builds writes the
control-packet headers (skill **ctrlpkt-aot-elf**).

## Common errors

| Symptom | Fix |
|---------|-----|
| `host.cc` / `kernel.cc not found` | Generate first; check `WORKLOCAL_DIR`. |
| `XILINX_VITIS` unset, `XAie_*` undefined | Source `setup.sh`; under `set -u` see skill **setup-nounset**. |
| Unknown `XAie_RoutingInstance` | Vitis aie-codegen headers shadowed the driver: skill **aie-rt-clone-headers**. |
| AIE_GEN mismatch | Same `--aie-version` for the lib, the runtime and the host. |
| Gen2 BSP header / XTime errors | Skill **bspheadergen2**. |
| xchesscc / xchessmk not found | Vitis aietools not on PATH. |
