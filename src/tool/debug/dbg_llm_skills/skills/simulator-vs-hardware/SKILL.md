<!-- Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: simulator-vs-hardware
description: Read when a SIMULATOR is or might be in play: the user says sim / aiesim / IPC, mcp__debugui__get_backend_status reports backend="simulator" or ipc_ready, you need sim_log / ipc_app.log / ipc_client.log / ipc_server.log, or a decoded aie_exec command behaved strangely and you must establish which READ PATH you are on. Two different simulators exist and only one flips the flag: the IPC simulator (sim_kind="ipc", a `*.sock.dbg` socket) yields backend="simulator" and live IPC register reads, while aiesim (sim_kind="aiesim", script/runsim.sh driving aie2pssimmsm) exposes NO debug socket, reports backend="hardware", leaves sim_applog empty, and cannot be register-read at all - debug it from <bundle_dir>/aiesim.log alone. Also read when the UI offers a Simulator that will not start: the option is shown for EVERY app, so sim_available=false means this bundle was never built for sim and sim_reason names the build command - not a broken simulator. Covers the discriminator keys (sim_kind first, then backend / ipc_ready / dbg_socket / sim_applog / sim_available / sim_reason), the two-file IPC log split (ipc_runsim.log the launcher script, ipc_sim.log the simulator engine), one batched `aiedbg --json scan` per hardware grid poll versus one AF_UNIX READ32 per register on IPC, the two different per-channel grid payload shapes (hardware has no raw/q_size/cur_bd; simulator has no core_status/active_events), which aie_exec commands IPC blocks cleanly (every raw aiedbg passthrough - `reg read`, `mem read`, `scan`, `tile list`) versus the one that does NOT refuse cleanly (`log`/`klog` spawns aiedbg directly: a 30 s stall per chunk or SystemExit: 1 - do not run it when backend=="simulator"), why get_sim_log can work where get_ipc_log answers "simulator not configured", and the grep that separates a PS.so-load crash from a runtime crash. Backend capability and read-path only - authorization to read at all is session-provenance's, command spelling is aiegdb-console's.
---

# Simulator and hardware are different debug targets

## 1. First move — find out which one you are on

```
mcp__debugui__get_backend_status()
```

Keys that decide everything (`_write_backend_status`, schedule_debug_server.py):

| key | meaning |
|---|---|
| `backend` | `"simulator"` **iff** the daemon's `_sim_ipc_ready` flag is set, else `"hardware"` |
| `ipc_ready` | same flag: the `*.sock.dbg` debug socket answered a ping |
| `dbg_socket` | path of that socket, in `<sim_example_dir>/ipc/` |
| `target` | `xsdb://host:port` — from `$AIEDBG_TARGET` at startup, proves nothing |
| `sim_log` | run log the UI console tails: `ipc_runsim.log` (IPC) / `aiesim.log` |
| `sim_applog` | PS-app log (`ipc_app.log`) — **empty string for aiesim apps** |
| `sim_engine_log` | IPC only: `ipc_sim.log`, the aiesimulator process's own stdout |
| `sim_kind` | `"ipc"` / `"aiesim"` / `""` — **the discriminator; do not infer it** |
| `sim_available` | whether this app can run a simulator at all |
| `sim_reason` | when it cannot: which artifact is missing, and what builds it |
| `session`, `session_summary` | provenance; see the `session-provenance` skill |

`sim_kind` answers §1 in one key. The older route — inferring aiesim from
`backend == "hardware"` **and** an empty `sim_applog` — still works, but it
cannot distinguish an aiesim app from a genuine board, and this key can.

**`backend == "hardware"` does not mean a board.** It is the not-simulator
fallback. Two different simulators exist and only one of them ever flips
`backend` to `"simulator"`:

- **IPC simulator** (`sim_kind == "ipc"`, naiebaremetal-style; detected from
  `<example>/ipc/build_sim.env` + `Work/ps/c_rts/systemC`, or declared in the
  app's `debug_ui_config.json`). Starting it spawns a watcher
  (`_sim_watch_dbg_socket`) that polls `<sim_example_dir>/ipc/` for a
  `*.sock.dbg` file and sets `ipc_ready`. This is the only path that yields
  `backend="simulator"` and live IPC register reads.
- **aiesim** (`sim_kind == "aiesim"`, this repo's `script/runsim.sh` driving
  `aie2pssimmsm`, auto-detected from a `sim_config.sh` next to the build). It
  exposes **no debug socket**: no watcher is started, `ipc_ready` stays false,
  `backend` stays `"hardware"`, `sim_applog` is `""`, and `sim_log` is
  `<bundle_dir>/aiesim.log`. There is **no live register read** for aiesim —
  debug it from logs only (§6). This is not a readiness race: nothing will
  ever open a socket, so do not tell the user to wait and retry.

**A missing simulator is not the same as a simulator that cannot be reached.**
The Simulator option appears in the UI for every app, so `sim_available ==
false` means this bundle was never built for sim; `sim_reason` names the
artifact and the command that produces it (`build_sim.sh <example>` for IPC,
`aiehlc.sh --platform sim` for aiesim). Quote the reason rather than reporting
the simulator as broken.

Do not trust the `Backend:` line in your own system prompt for this: it is a
first-turn snapshot computed as "hardware if a target is configured". The
`[context] Backend: …` line on each message and `get_backend_status()` are
current; prefer them.

The session gate applies to the simulator too: `aie_exec` refuses device
commands until the UI has a session (`_session_refusal`, aiemcp.py). The
daemon grants one **itself** the moment the IPC socket answers a ping —
`_sim_watch_dbg_socket` calls `mark_hw_session("simulator", …)`, so
`session.mode == "simulator"` and no board Connect is needed. It is also
revoked when the sim exits (`clear_sim_session`): unlike a board, the process
that vouched for those reads is gone. The user can still press
"Activate" to probe; if `ipc_ready` is false that answers `"simulator running
but IPC not ready yet"` or `"simulator not running — press Run to start it"`.

A `simulator` session says something stronger than a board one, and the
summary line says it: these reads come from a process this daemon started, so
they are current by construction. The **applog is not** — it is a hardware log
and unrelated to the simulator run.

## 2. Read path: batched subprocess vs per-register socket

**Hardware** — the grid endpoints run ONE subprocess for the whole array:
`aiedbg --json scan dma` (also reused for the events overlay, via each tile's
`event_status_hex`) and `aiedbg --json scan cores`. Per-command reads go through
`aiediag.run_aiedbg_reg_read`.

**Simulator (IPC)** — no xsdb, no aiedbg. `sim_ipc_reg_read(phys_col, row,
offset)` computes
`addr = base_address + (phys_col << column_shift) + (row << row_shift) + offset`
(params from `<sim_example_dir>/Work/ps/c_rts/aie_control_config.json`,
`aie_metadata.driver_config`) and sends one `READ32` (opcode `0x11`) over a fresh
AF_UNIX connection to `dbg_socket`, 5 s timeout, **one connect per register** —
so a grid poll is N_tiles × N_channels round trips: slow, and individual reads
come back `None` (state `unreachable`) instead of failing the whole poll.

`phys_col = col + startcol` on both paths; `tile_info`/`tile_list` coords are
logical.

## 3. Different per-channel payload shapes

If you are reading the grid JSON (e.g. quoting it back to the user), the two
paths do not produce the same fields:

| overlay | simulator (IPC) | hardware (`aiedbg scan`) |
|---|---|---|
| dma, per channel | `state, offset, raw, status, running, q_size, cur_bd, stalls[], errors[]` — decoded from the raw status word by `aiediag.decode_dma_status` | `state, active_events[], stalls[], errors[]` — `stalls`/`errors` are *derived from event names* (`STALLED_LOCK`, `STREAM_STARVATION`, `BD_UNAVAILABLE`, `BD_INVALID`); there is no `raw`, `q_size` or `cur_bd` |
| cores | `state, pc, source` (PC read + linemap lookup) | `state, core_status, reg` (no PC) |
| events | `state, words[]` (per-register IPC reads) | `state, words[]` (from `event_status_hex` in the batched dma scan) |

So **hardware has no `cur_bd`/`q_size`** in the overlay and **the simulator has
no `core_status` or `active_events`**. Tile state is the worst of its channels,
ordered `unreachable > error > stalled > running > idle`.

## 4. What is BLOCKED under the simulator

`aiemcp._patch_gdb_for_simulator` replaces `_reg_read` with the IPC read and
replaces `_passthrough` with a stub. So:

- **Works** (decoded paths, all via IPC READ32): `dma status`, `bd`, `pc`,
  `status` (aka `core` / `core status`, decoded core enable/reset/stall — it
  reads through `_reg_read` like the rest), `event`, `channels`, plus navigation
  (`target tile C R`, `target channel mm2s0`, `where`, `up`, `top`, `?`,
  `help`).
- **Blocked, cleanly**: any raw aiedbg passthrough — `reg read`, `mem read`,
  `scan`, `tile list`. You get
  `[simulator] passthrough '<cmd>' not supported via IPC; use decoded commands
  (dma, pc, event, channels, bd) instead.` Do not retry it; switch to a decoded
  command.
- **Broken, NOT cleanly refused**: `log` / `klog`. It looks like a decoded
  command but reads data memory via `aiediag.read_klog` →
  `run_aiedbg_mem_read`, which spawns `aiedbg` *directly* and so is not
  replaced by the patched `_passthrough`. Under the simulator it has no valid
  target: expect a 30 s stall per chunk (`subprocess.run(..., timeout=30)`) or
  `error: command exited (SystemExit: 1)` surfacing through `aiemcp._run` when
  `aiedbg` is not on PATH — never the friendly `[simulator] passthrough …`
  message. **Do not run `log` when `backend == "simulator"`.**
- The UI's per-channel event op (`chanevent`) returns
  `"chanevent not supported for simulator (IPC)"` — the shim/core event-status
  decode is a hardware-only path.

## 5. Simulator-only logs and which tool reads which

| file | what | how you read it |
|---|---|---|
| `sim_log` (from `get_backend_status`) | the run log the UI console tails: `<sim_example_dir>/ipc_runsim.log` (IPC launcher script) or `<bundle_dir>/aiesim.log` (aiesim, the whole run) | `mcp__debugui__get_sim_log()` on aiesim; `Read` / `Bash grep` otherwise |
| `sim_engine_log` — `<sim_example_dir>/ipc_sim.log` | IPC only: the aiesimulator process's own stdout | `Read` / `Bash grep` on the path |
| `<sim_example_dir>/ipc_app.log` | PS application (`ipc_app`) stdout/stderr | `mcp__debugui__get_sim_log(lines=N)` |
| `<sim_example_dir>/ipc_client.log`, `ipc_server.log` | CSV IPC transaction logs | `mcp__debugui__get_ipc_log(lines=N, side="client"\|"server"\|"both")` |
| repo-root `applog` | **hardware** board run | `mcp__debugui__get_applog(lines=N)` |

**`ipc_runsim.log` and `ipc_sim.log` are two files on purpose.** `runsim_ipc.sh`
redirects the simulator process to `ipc_sim.log` itself, so the daemon captures
the *script's* stdout to `ipc_runsim.log` and hands the script its own path via
`$AEG_SIM_LOG`. Both writing one path gave it two file offsets and they
overwrote each other — measured at 63 of 80 lines surviving, some spliced
mid-line. If you are reading a shredded IPC sim log, it predates this split.

`get_sim_log` returns the path it read as its first line, and falls back from
`sim_applog` to `sim_log` — which is what makes it work on **aiesim**, where
there is no separate PS process and `sim_applog` is `""` by construction.
`get_ipc_log` has no such fallback: it reads **only** `$DEBUGUI_SIM_APPLOG` and
takes its `dirname` as the log directory, never consulting
`backend_status.json`, so on an IPC app whose daemon started without that env
var `get_sim_log` works while `get_ipc_log` returns "simulator not configured".
On aiesim `get_ipc_log` is meaningless — there are no IPC transactions.

`get_applog` branches on `backend`, and on an **aiesim** app (`backend ==
"hardware"`) it returns the repo-root `applog`, which the aiesim run never
wrote — that content is from some other run. Say so; use `get_sim_log()`.

## 6. IPC transaction log and PS process inspection

The IPC CSV schema, the `wchan` value table, `addr2line` on `ipc_app`, the
`graph.cpp` / `do_transaction()` pointers and the ipc_app-vs-aiesimulator
process model are **injected into your system prompt only when the loaded app
has an IPC simulator** (`sim_example_dir` is set). If the hardware flow is
selected and the app has no IPC simulator, this section is absent from your
prompt — do NOT suggest IPC logs or `READ_GM` to a user on the hardware flow.

For hardware-flow hangs: use `aie_exec` (`dma status`, `bd`, `event`) to trace
the stall through the producer → hop → consumer chain, and read the applog for
timeout or error messages.

When the section IS present, use those paths rather than re-deriving them. One
caveat: run the shell commands with your `Bash` tool (`aie_exec` takes aiegdb
commands, not shell), and paste the absolute paths from the prompt.

## 7. Discriminator: an aiesim that died at PS.so load

If the aiesim run produced only a segfault and no application output, decide
*before* debugging anything else whether the PS thread ever ran. Grep the sim
log (`sim_log` from `get_backend_status`, i.e. `<bundle_dir>/aiesim.log`):

```bash
grep -aE 'AIEHLC PS IP started|AIEHLC PS IP loaded|__Runtime_init' <sim_log>
```

- **No match** → the crash is at `aiehlc_ps.so` load / SystemC elaboration,
  before any host or runtime code. Nothing about DMA, BDs, locks or the schedule
  is relevant. Most common cause is a stale
  `script/sim/build/kernel_elf_init.cc`
  naming the wrong embedded-kernel symbol; confirm with

  ```bash
  nm -D -u script/sim/build/aiehlc_ps.so | grep _binary_kernel_
  ```

  where an **undefined** `_binary_kernel_<name>_start` is the bug. If this
  prints nothing, confirm the `.so` actually exists (`ls -l` the path) before
  concluding the symbol resolves — a missing file and a clean symbol table look
  identical through `grep`. Full root-cause list:
  `.cursor/skills/aiesimloaddebug/SKILL.md`.
- **Match, crash later** → a runtime crash; that skill's root cause #3 covers the
  `XAie_LoadElfMem` path, otherwise proceed with normal DMA/data debug.

Do not try to attach gdb to the simulator: it crashes a known-good baseline
identically, so any backtrace is an artifact.
