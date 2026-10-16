---
name: pmccntrnotenabled
description: A host built with `script/aiehlc.sh --profiling` (-DAIEHLC_PROFILING=1) still reports every runtime phase counter (kload/bdcfg/coreen/startio/wait_io, __Runtime_phase_cycles / __Runtime_wait_io_cycles) as 0 — e.g. conv2dstem test_conv2d.cc printing "PERF runtime phase counters not built in" after `./buildtest.sh --profiling`. Cause: the Arm PMU cycle counter pmccntr_el0 was never started.
---

# `--profiling` reads all zeros: pmccntr_el0 never started

## Symptom

- Built with `--profiling`; `[hostcompile] profiling runtime layer ENABLED` is in the log.
- `__Runtime_phase_cycles()` / `__Runtime_wait_io_cycles()` return 0 for every phase,
  while the call counts may still be non-zero.
- conv2dstem `test_conv2d.cc` prints the "counters not built in" (old) or
  "built in ... but all read 0" (new) message.

## Root cause

`RT_PROF_TIC()` / `RT_PROF_PHASE()` in `src/mlir/runtime/aie_runtime.c` read
`pmccntr_el0`. The Xilinx standalone BSP `boot.S` (ARMv8/64bit, every
`standalone_v9_*`) never writes `PMCR_EL0` or `PMCNTENSET_EL0`, and `PMCR_EL0.E`
resets to 0 — so the counter is frozen and every `now - t0` delta is 0.

Apps whose profiling worked (`simplematmul2_prof.cc`, `simplematmul_ctrl_pkt*.cc`)
called `aie_timer.h`'s `__ps_pmccntr_enable()` at the top of `main()`. `test_conv2d.cc`
cannot include `aie_timer.h` (it branches on `AIE_GEN`, which the frontend parse
does not define), so it never did.

## Fix (in place)

`__rt_pmccntr_enable()` in `aie_runtime.c`, called from the `__Runtime_init`
constructor: sets `PMCR_EL0.E`, clears `.D` (count every cycle), sets
`PMCNTENSET_EL0` bit 31. It deliberately does **not** set `PMCR_EL0.C` (reset):
only deltas are used, and a reset would invalidate a snapshot the app already took.
Compiled only under `AIEHLC_PROFILING && __aarch64__ && !__AIESIM__ && !__linux__` —
under Linux an EL0 write to `PMCR_EL0` traps (SIGILL in a constructor).

Apps that still call `__ps_pmccntr_enable()` are unaffected (it resets the counter
before any runtime call has taken a snapshot).

## Verify without hardware

```bash
BIN=<Vitis>/gnu/aarch64/lin/aarch64-none/bin
$BIN/aarch64-none-elf-g++ -O2 -std=c++17 -DAIE_GEN=5 -DAIEHLC_PROFILING=1 \
  -Isrc/mlir/runtime -Iinclude -Ithirdparty/alib/include -Iaout/worklocal \
  -mcpu=cortex-a78 -c src/mlir/runtime/aie_runtime.c -o /tmp/rt1.o
$BIN/aarch64-none-elf-objdump -d /tmp/rt1.o | awk '/<_ZL14__Runtime_initv>:/{p=1} p&&/^$/{exit} p' \
  | grep -E 'pmcr_el0|pmcntenset_el0'      # expect mrs/msr pmcr_el0 + msr pmcntenset_el0
```

With `-DAIEHLC_PROFILING=0` the constructor must contain no PMU instruction and
`pmccntr_el0` must appear 0 times in the object.

## Related

- `profile-full-app-span` — profiling that misses part of the app span.
- `include/aie_timer.h` — `__ps_pmccntr_enable` / `__ps_pmccntr` for app-level PMU use.
