<!-- Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: session-provenance
description: PRECEDENCE - this skill alone owns "may I read the board, and is what I read current?"; every other skill defers here instead of re-deciding it. Read before the FIRST mcp__aiegdb__aie_exec device read of a conversation, before writing "the board is ..." / "the run passed" / "channel X is stalled", before quoting mcp__debugui__get_applog / get_sim_log / get_ipc_log, and whenever aie_exec returns {"refused": true}. The debug target is resolved from $AIEDBG_TARGET at daemon startup and backend:"hardware" is only the not-simulator fallback, so neither proves a board is live nor that anything ran - and a reachable board still holds the PREVIOUS run's registers. Covers the four session.mode values (none / connected / attached / ran) and the exact phrasing each one entitles you to, the four session.applog.state values (current / predates_session / foreign / absent), why "PASS: all N elements match" under a [STALE:/[UNVERIFIED: banner is not evidence, the refusal payload plus the _NO_HW_VERBS verbs it does NOT gate (and that `tile list` IS gated), and the backend_status.json keys `session` / `session_summary` to read via mcp__debugui__get_backend_status. Entitlement to claim, nothing else: command spelling is aiegdb-console's, backend capability is simulator-vs-hardware's.
---

# Session provenance — what you may claim about board state

## The trap

`schedule_debug_server.py` resolves its debug target at startup from
`--target` → `$AIEDBG_TARGET` (exported by `script/test/envlocal.sh`) →
`~/.aiedbg_env` (`_target_from_aiedbg_env`). So `target=xsdb://host:3121` is true
from process start, before the user has touched anything.

Likewise `backend: "hardware"` in `_write_backend_status()` is just the
not-simulator fallback (`backend = "simulator" if sim_ready else "hardware"`).
Neither field means a board is reachable, and neither means a run happened.

A reachable board still holds the **previous** run's registers. Reading them and
narrating them as the current run is the exact failure this discipline exists to
prevent.

## Mandatory precondition — do this before any device read

1. Call `mcp__debugui__get_backend_status()` and read `session` (dict) and
   `session_summary` (string). This is the unconditional check: both keys are
   copied verbatim from the daemon's `session_state()` / `session_summary()`,
   and the tool is always available to you.
2. The `Session:` clause on the `[context]` line prefixed to each message you
   receive (built by `_llm_backend_context()`) carries the same
   `session_summary` string and is fresher than the system prompt, which is only
   a snapshot from spawn time. When that clause is present you may use it in
   place of step 1. It is not guaranteed: `_llm_backend_context()` returns an
   empty string — and no `[context]` line is prefixed at all — when
   `backend_status.json` cannot be read or parsed.
3. If NEITHER is available, you are not talking to a live daemon. Say so and do
   not read the device.

Never substitute `target`, `device`, or `backend` for this check.

## The four session states

Source: `DebugState.session_state()` → `session.mode` and `session.authorized`.
`mark_hw_session()` is the ONLY writer; target resolution never calls it.

### `mode: "none"` (`authorized: false`) — summary starts `NO BOARD SESSION`
The user has not connected, run, or attached in this UI. `_hw_session is None`.

- Device reads are refused. `mcp__aiegdb__aie_exec` returns `{"refused": true}`
  with text beginning `REFUSED: no board session has been established`.
  `/grid` returns `_NO_SESSION_MSG`.
- You may say: nothing about board state. Not "idle", not "probably fine".
- You may do: static work — `mcp__debugui__get_design_overview`, `tile_info`,
  `tile_list`, `get_flow_detail`, `symbol_search`, and file tools under
  the repo root. Navigation/help via `aie_exec` still
  works (see the allowed-verb list below).
- Tell the user to press **Connect**, **Run test**, or **Open Current Session**,
  and state which registers you would read once they do.

### `mode: "connected"` — summary `CONNECTED at <t> (link verified) but NO run has been started in this session`
The user pressed **Connect**; `/ping` ran `run_xsdb_connect(tgt)` (or, for
`device=simulator`, `sim_ipc_ping(dbg)`) and it succeeded. `mark_hw_session("connected", …)`.

- Reads are authorized and will work.
- What the registers hold is **left over from an earlier run** — possibly days
  old, possibly another user's. Nothing in this session put it there.
- Every finding MUST be labelled pre-existing board state. Write "the board
  currently holds …", never "the run produced …".

### `mode: "attached"` — summary `ATTACHED at <t> to a run started OUTSIDE this UI`
The user pressed **Open Current Session** (`POST /attach`). The daemon probed
the link (same `ping()`) and adopted a run it did not start. Deliberately NOT
folded into `ran`.

- A real run is in play; trust the live registers as current.
- The daemon cannot vouch for what came before — do not assume the run began
  cleanly, do not assume the board was reset, do not attribute the applog to it
  unless `session.applog.state` says otherwise.

### `mode: "ran"` — summary `RAN from this UI at <t>`
`DebugState.start_run()` launched the test; `_last_run = {run_id, device,
started_at, started_iso}` and `mark_hw_session("ran", f"run #{run_id} on {device}")`.
Also check `session.run_in_progress` — true while the child process is alive.

- **Only here** may you treat live registers and the applog as describing the
  current run.
- Note `run_blocks_debug()`: while a run still holds the JTAG link exclusively,
  `/grid` and `/aiegdb` answer `"disabled during run setup"`. That is a timing
  gate, not a provenance problem — wait and retry.

## applog provenance — a stale "PASS" is not evidence

The applog defaults to the repo-root `applog`
(`applog`, at the repo root) but the daemon's `--applog`
overrides it. The live path is the `applog` key in the daemon's
`backend_status.json`, and `mcp__debugui__get_applog` echoes it in its own
`[source: (hardware applog) path=…]` prefix — read the path off that prefix
rather than assuming (`get_backend_status()` returns `sim_log` and `sim_applog`,
but not `applog`).

Whatever the path, the manual CLI flow
(`python3 script/test/apppaltest.py … > ./applog`) writes the same file, so its
existence proves nothing. `DebugState.applog_provenance()` classifies it into
`session.applog.state`:

| state | meaning | what you may say |
|---|---|---|
| `current` | `_last_run` is set — this session started the run that wrote it | quote it as the current result |
| `predates_session` | mtime < `_session_started_at` | "this log was written `<mtime_iso>`, BEFORE this debug session — it describes a PREVIOUS run" |
| `foreign` | written while we were up, but not by us | "written by something outside this UI; treat as an external run" |
| `absent` | no file on disk | say there is no log |

`mcp__debugui__get_applog(lines)` already prefixes a banner from
`_applog_banner()`: `[FRESH: …]`, `[STALE: written … BEFORE this debug session
started …]`, `[UNVERIFIED: written … by something other than this UI …]`, or
`[UNVERIFIED: no run has been started from this UI in this session.]`. **Relay
that banner's verdict.** A `PASS: all N elements match` under a `[STALE:` banner
is a previous run's result — reporting it as success is the canonical bug here.

The same reasoning applies to `mcp__debugui__get_sim_log` and `get_ipc_log`:
files on disk outlive sessions.

## The aie_exec gate (what is refused, what is not)

`aiemcp.py` `_session_refusal(line)` runs before every command in `_run()`:

- `_needs_hw(line)` — the first token decides. These verbs never touch the
  device and are always allowed: `target tar tile channel up .. top where info
  pwd set help ? commands cmds spec exit quit q channels chans`.
  Exception coded explicitly: `tile 0 0` navigates, but **`tile list`** is an
  `aiedbg` passthrough and IS gated.
- Everything else (`dma status`, `bd`, `event`, `pc`, `dma counter`, `reg read`, …)
  is a hardware command. That includes `dma counter setup [finished|started]`,
  the one command in `COMMAND_SPEC` flagged `intrusive=True` — it **WRITES to
  hardware**, so it both needs authorization and perturbs the state you are
  about to describe.
- It reads `backend_status.json` from `$AIEMCP_JSON_DIR` and refuses when
  `session.authorized` is false. Refusal payload:
  `{"output": "REFUSED: …", "scope": …, "refused": true, "session": {…}}`.
- If the status file has **no** `session` key at all (aiemcp run standalone from
  a shell, no UI), the gate is skipped and commands proceed.

So: a `refused: true` result means **nothing was read**. Do not soften it into a
finding, do not retry with a different verb hoping to slip past, do not infer
state from the refusal itself.

## Phrasing rules

- Lead the answer with provenance when it is anything other than `ran` +
  `applog: current`.
- Say "the board currently holds" (connected) vs "this run produced" (ran).
- If you did not read a register, do not name a register value.
- If you are refused, say what you would have read and which button unblocks it:
  Connect / Run test / Open Current Session.
