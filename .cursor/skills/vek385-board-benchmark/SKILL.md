---
name: vek385-board-benchmark
description: Builds and benchmarks AIEHLC applications on reserved VEK385 boards, including reliable UART capture, timer discipline, and control-packet compatibility fallback. Use for any VEK385 hardware run or performance measurement.
---

# VEK385 board benchmark

## Procedure

1. Build with `--platform baremetal --profiling`.
2. Time the whole launch with exactly two `XTime_GetTime` calls. Use PMU cycle
   counters already present in the runtime for intermediate phases.
3. Run through `script/test/appvek385.py`; allow at least 60 seconds for XSDB
   startup. Rev B boards need `--board-rev b` (boot PDI, then PLD PDI); see
   skill `vek385-revb-boot`.
4. Use `VEK385_CONSOLE` when the UART is not `com3`. Set `USERNAME` and
   `VEK385IP` explicitly (`USERNAME=<you> VEK385IP=<board>`); if
   `USERNAME` is unset, the harness sources `envlocal.sh` and targets its board
   instead.
5. Reject stale UART captures. A `DEBUG_NOCOMPUTE` run must print `test end`,
   not a normal correctness `PASS`.
6. Require correctness output plus the final repeated performance line before
   accepting a run.

## Harness: UART and PDI programming

- **`telnet>` means the UART is lost; reconnect.** In some runs, right after
  `connect com3`, the com port's telnet client drops into command mode by itself
  ("Versal PS UART0", blank lines, `telnet>`). Resuming it with an empty line or `\r`
  gets it out of command mode but no more data arrives (the run "hangs" on the 300 s
  no-output timeout while the app actually reached `_exit`). `connect com3` typed at
  `telnet>` only gives `?Invalid command`. What works: `console_reader` sends `quit`
  ("Connection closed."), then `uart_reconnect_step` sends `connect com3` **only after
  the `Systest#` prompt appears**, because a line typed ahead while telnet is exiting
  gets swallowed. Both the pre-download settle loop and the console wait use it.
- `python3 -u` when redirecting the harness to a log, or the log trails the run by
  minutes and looks hung at "Continuing execution...".
- **Don't wait for the `xsdb%` prompt after `device program`.** `conn` launches
  hw_server and leaves extra prompts, so `program_pdi` used to return before the PDI
  loaded. It now wraps the command in `catch` and waits for a
  `PDIRES_OK` / `PDIRES_FAIL: <msg>` marker, then for the prompt after it.
- The UART can attach in the middle of the PLM log without printing the "Versal PS
  UART" banner. Any output counts as a live UART.
- `source .../settings64.sh` is sent to the systest prompt, which isn't a shell, and
  prints "token recognition error" lines. That's harmless; systest's `xsdb` is
  already on PATH.

## Control-packet ELF stalls

If a high-throughput build completes kernel loading but stalls in `wait_io`, don't
blame the board or PDI first: diagnose with skill **control-kernel-packet-load**
("Failure signatures") and, next to a live data plane, **control-plane-dataplane-coexistence**. A known-good ELF rerun separates board changes from code regressions.
Compatibility mode (`__Runtime_ctrl_high_throughput_enable(0)`) stays available,
but it gives only about 24x on ELF load against about 750x for high-throughput.

Do not compare high-throughput and compatibility timings as if they differed
only in compute: compatibility kernel-load time scales strongly with ELF size.
