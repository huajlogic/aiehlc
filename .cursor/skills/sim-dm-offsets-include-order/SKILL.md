---
name: sim-dm-offsets-include-order
description: Diagnoses single-kernel AIE simulator runs where the kernel loads and finishes but every output word reads 0 (e.g. tutorial/example.cpp "Mismatch ... CPU=100, AIE=0") while the same ELF passes on hardware. Use when CORE_OP_MEM / CORE_IP_MEM in the sim disagree with the kernel's dm_offsets.h.
---

# Sim output all zeros: DM offset fallback wins over dm_offsets.h

## Symptom

- `--platform sim` single-kernel run: `ELF rc=0`, core reaches done, input DMA
  completes, but every output value is `0` (not the host's `9999` fill).
- The same app built `--platform baremetal` passes on a VEK385.
- Tilinglinalg sims keep passing (they do not use `CORE_OP_MEM`).

## Root cause

`aiehlc.sh` injects `#include "kernelcfg/<k>/dm_offsets.h"` at the top of
`aout/host.cc`; its `CORE_IP_MEM` / `CORE_OP_MEM` come from the kernel BCF and
are `#ifndef`-guarded. `src/sim/aiehlc_ps_wrapper.cpp` includes `host.cc` via
`AIEHLC_HOST_SRC`. If the wrapper includes `include/aie_device_map.h` **before**
the host, that header's fallbacks (`CORE_OP_MEM 0x6000`) define the macros
first and the guards in `dm_offsets.h` skip the real value (`0x2000`). The host
then DMAs the output back from an untouched DM address, which reads zero.

## Confirm

Read DM back after `XAie_CoreWaitForDone` in the generated `aout/host.cc`:

```c
XAie_DataMemRdWord(DevInst, XAie_TileLoc(4, 4), CORE_OP_MEM, &w);
```

- Printed address differs from `aout/kernelcfg/<k>/dm_offsets.h` -> this bug.
- Reading the `dm_offsets.h` address shows `100, 101, ...` -> core ran fine.

## Fix

In `aiehlc_ps_wrapper.cpp`, include `aie_device_map.h` only **after**
`#include AIEHLC_HOST_SRC`. The wrapper only needs `XAIE_BASE_ADDR` /
`XAIE_COL_SHIFT` / `XAIE_ROW_SHIFT` for the debug server, well after the host.

Verify: `bash script/ci/pr_sim_test.sh tutorial` and `... passthrough` both PASS.

## Not the cause

`--sim-tiles` (`4:2` vs `4:4`) and the shim columns (input col 2, output col 3)
were ruled out: input data reaches DM with either stub, and both stubs pass
once the include order is fixed.
