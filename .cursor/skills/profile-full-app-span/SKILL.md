---
name: profile-full-app-span
description: Diagnoses AIEHLC profiling that misses part of the app — a debug-UI Profile tab / timeline.py host lane that starts at the launch instead of the app top, [PERF] stage counters that sum to far less than wall_ms, or CONTROLPAN-PMAP printing that inflates control-packet ELF load and core enable by ~1000x. Use when profiling a tiling GEMM (especially simplematmul_ctrl_pkt.cc) with --profiling or #pragma aie_trace.
---

# Profiling the whole app span

## Two profile paths

| Path | Enabled by | Output |
|------|-----------|--------|
| PMU stage counters | `--profiling` (`-DAIEHLC_PROFILING=1`) | `[PERF]` / `[FINAL_PERF]` lines (CPU cycles, `pmccntr_el0`, ~1.3 GHz) |
| Host/AIE timeline | `#pragma aie_trace((c, r), ...)` | `[TIMESYNC]` block, then `src/tool/debug/timeline.py` renders it |

## What must be true

1. **Session opens at the app top.** `CoreTraceInsertPass` emits
   `__Runtime_core_trace_app_begin(dev)` first in `host_canonicalized`, so host
   events before anchor0 still record.
2. **Markers cover the app.** Generated `aout/worklocal/host.cc` contains, in order:
   `ctrl_plan`, `kload`, `launch` (before the launch call), `iter_start`,
   `dma_start`, `wait_start`, `wait_done`, `app_end`. `__Runtime_ctrl_plan_init`
   is `emitc.verbatim` (not `call_opaque`), so it is found by
   `findFirstCallOrVerbatim`. A missing `ctrl_plan` means that lookup broke.
3. **Instrumentation is excluded.** Trace setup prints, the trace-buffer clear
   and PMAP lines go into `s_trace_host_skew` (printed as
   `[TIMESYNC] excluded host=`). PMAP cycles also go into `g_prof_excl_cyc`,
   which every `RT_PROF_*` interval subtracts. Both anchors must stay after every
   excluded span, or the per-tile fit slope is wrong.
4. **Setup is counted.** `plan` (`ctrl_plan_init`) and `sync` (`sync_for_dev`)
   come from `__Runtime_setup_split_cycles`; `pmap_print` from
   `__Runtime_pmap_print_cycles`.

## PMAP trap

`__Runtime_ctrl_pmap_enable(1)` is not just ~1.8 s of plan-time UART. The shim
entry/return circuits are re-armed on every control send. Before the
`pmap_shim_seen` dedup, each re-arm printed two identical lines (~19 ms at
115200 baud). The signature is exact and repeatable:

| counter | PMAP on (bug) | PMAP on (fixed) | PMAP off |
|---------|--------------:|----------------:|---------:|
| `elf` | 75.7M | 84k | 72k |
| `coreen` | 25.3M | 9.4k | 9.4k |
| `plan` | 2.35G | 1.1M | 90k |

If `elf`/`coreen` read tens of millions again, look for a new `rt_pmap_port`
call on a per-send path. Spin-count diagnostics showed the ctrl poll loops
spinning fewer than 10 times, so the time sat in the prints, not in hardware
waits. `plan` keeps a ~1M-cycle residual with PMAP on (register writes queued
behind the UART), so benchmark with PMAP off.

## Console output in a measured phase

Any UART print inside a timed phase dominates it. `__Runtime_ctrl_push(..., log=1)`
dumps a `ctrl_push` line plus seven `ctrl_path` lines, about 100M cycles: a 4x4 ELF load
measured 122M cycles with one `log=1` push, 1.4M without it, against 15.4M for MMIO. The
logging alone turned "8x slower than MMIO" into "11x faster". Per-send success chatter is
behind `AIEHLC_LOG`. Before comparing variants, check both print nothing in the window:

```sh
awk '/=== Matrix Multiply/,/PERF/' applog.txt | grep -c "aie_runtime"   # want 0
```

## Run and render

```bash
# traced variant: add the aie_trace pragma in a temp copy
sed '/^#pragma control_plan_op_control_packet/a #pragma aie_trace((1, 3), (STREAM, "mm2s", 0))' \
  example/tileprogram/ccode/simplematmul_ctrl_pkt.cc > example/tileprogram/ccode/zz_trace_tmp.cc
bash -c "source script/aiehlc.sh --aie-version 5 --platform baremetal --profiling \
  --runtime-source-file ./example/tileprogram/ccode/zz_trace_tmp.cc"
cp aout/main.elf /tmp/t.elf; cp aout/worklocal/host.cc /tmp/t_host.cc
USERNAME=<you> VEK385IP=<board> python3 script/test/appvek385.py -y /tmp/t.elf > /tmp/t.log 2>&1
python3 src/tool/debug/timeline.py /tmp/t.log --out-dir /tmp/tl --png /tmp/tl/<unique>.png --host-cc /tmp/t_host.cc
```

- In the ctrl-pkt layout, column 0 is the control spine, so the first compute
  tile is (1, 3), and it drives only MM2S channel 0. `(STREAM, "mm2s", 1)` fails
  validation.
- After changing a pass, rebuild the front end with `make -C build -j32 aiehlc`;
  `aiehlc.sh` does not rebuild it.
- `wall_ms` includes the trace dump and PMAP prints; compare stage counters and
  the host lane instead.
