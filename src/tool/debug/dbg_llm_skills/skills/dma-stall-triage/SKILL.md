<!-- Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: dma-stall-triage
description: The ordered symptom-to-root-cause PROCEDURE. Read when the user reports a SYMPTOM rather than asking a question: "it hangs", "the run never finishes", "no output", "the output is wrong", "the output is all zeros", a DMA channel stalled / starved / backpressured, a channel that started but never finished, or a stuck core - kernel never returns, CORE_DONE never set. Sequences the whole investigation: gate on session provenance, name the suspect flow from get_design_overview / get_flow_detail, then walk producer -> hop -> consumer with aie_exec (`dma status`, `event`, `bd`; at tile scope `status`, `pc`, `log`, `callstack`). Supplies the INTERPRETATION no other skill carries: the dma-status bit map and per-tile-type register offsets from aiediag.py, how shim `event` output differs from core (no ERROR row on shim; STALLED_LOCK / STREAM_BACKPRESSURE / STREAM_STARVATION / MEMORY_BACKPRESSURE / MEMORY_STARVATION exist only there), the stream=1 vs lock_acq=1 vs BD_UNAVAIL/BD_INVALID decision tree, turning `bd`'s "Total intended" against get_flow_detail's participants into an OVER-/UNDER-SUPPLY verdict, which BD-config symbol to look for per producer flow (`__Runtime_*` for aiehlc vs `XAie_Dma*` for aiecompiler), and the aiediag offset-as-value pitfall that fabricates BD_UNAVAIL/BD_INVALID out of a register OFFSET - always confirm such a decode against the `[registers read]` value. Note `dma counter setup` WRITES HARDWARE; ask the user first. Command spelling is aiegdb-console's; what you may claim about what you read is session-provenance's.
---

# DMA Stall Triage

Run the steps in order. Do not skip step 0 — reporting board state you did not read is
the worst failure mode here.

## 0. Gate: is there a live session at all?

1. `mcp__debugui__get_backend_status` -> read `backend`, `session`, `session_summary`, `note`.
   `session.mode` (from `DebugState.session_state()`) is four-valued, and reads
   **succeeding** does not mean the registers belong to the run you are debugging:
   - `mode == "none"` (`authorized` false) => `mcp__aiegdb__aie_exec` returns
     `{"refused": true}` for any hardware command. Say so and ask the user to press
     **Connect**, **Run test**, or **Open Current Session**. Do NOT describe board state.
   - `mode == "connected"` => the link was probed, but **no run was started in this
     session**. Reads work and return whatever the board is still holding from an
     earlier run. Tell the user this before step 1, and phrase every finding as
     "the board currently holds ...", never "the run stalled at ...".
   - `mode == "attached"` => the user adopted a run started outside this UI. Live
     registers are current, but the board's earlier history is unknown to the daemon,
     so do not attribute the applog to that run unless `session.applog.state == "current"`.
   - `mode == "ran"` => the only state where live registers *and* the applog describe
     this run. Also check `session.run_in_progress`: while true the run is still going,
     so a channel that looks stuck may simply not have got there yet.
   - `backend == "simulator"` and `ipc_ready` false => nothing to read; ask for a run.
   - `backend == "simulator"`: raw passthroughs (`reg read`, `mem read`, `scan`) are
     unavailable. Use only the decoded verbs (`dma status`, `bd`, `event`, `pc`, `channels`).
2. `mcp__debugui__get_applog(lines=80)` — the reply is prefixed with a provenance banner.
   `[FRESH: ...]` is the only banner that means this session's run wrote it;
   `[STALE: ...]` / `[UNVERIFIED: ...]` mean the log describes a *previous* or external
   run and a `PASS` line in it proves nothing. Report which banner you got.

## 1. Establish which flow and which tiles

- `mcp__debugui__get_design_overview` — grid (cols/rows/startcol/shim rows/core rows),
  every `f<N>` flow, and the per-flow `balanced | OVER-SUPPLY | UNDER-SUPPLY` verdict.
  A static `UNDER-SUPPLY` verdict already names your suspect flow before you touch the board.
- `mcp__debugui__tile_list` — `(col,row) type role` for every tile.
- `mcp__debugui__get_flow_detail(flow_index=N)` — producer stage, consumer stage, hop
  tiles, `hop: from -> to`, stream-switch `circuit_connect` pairs, and
  `[supply/demand] pattern= supply=B/round demand=B/round balanced=` plus one
  `participants` line per endpoint: `(col,row) io_direction ch<N> bd_len= fires=`.
  **This is your producer -> hop -> consumer walk order.**
- `mcp__debugui__tile_info(col, row, section="hi")` — role, kernel, per-flow
  supply/demand verdict, and the channel <-> kernel-argument map. Use `section="lo"` for
  the attributed `host.cc` lines when you need the BD config that produced a channel.

Coordinates from these tools are **logical** grid coords. aiegdb converts with
`phys_col = col + startcol`; `aie_scope` prints both.

## 2. Walk the chain with aie_exec

Every line below is the `cmd` argument to `mcp__aiegdb__aie_exec` — **never a shell
command**. `aie_exec("target tile 0 3")`, not `Bash`. In a shell these are no-ops.

For each endpoint from step 1, in producer -> hop -> consumer order:

```
target tile <col> <row>        # e.g. target tile 0 3   (row 0 = shim, >=3 = core)
channels                       # lists dma channels + flow_index from the schedule JSON
target channel <dir_ch>        # e.g. target channel mm2s0  (mm2s0/mm2s1/s2mm0/s2mm1)
dma status                     # decoded DMA status register
event                          # DMA events — output SHAPE DIFFERS shim vs core, see below
bd                             # BD chain from JSON + live HW Buffer_Length compare
up                             # pop to tile scope        top = back to partition
```

`event` at channel scope has two entirely different branches (`aiegdb._channel_events`):

- **core tile (row >= 3)** — four rows plus a verdict:
  `START_TASK / FINISHED_BD / FINISHED_TASK / ERROR`, each `SET` or `not set`.
- **shim tile (row 0)** — `Shim events for <DIR> ch<N> (col C):` then one row per event
  from `aiediag.SHIM_DMA_EVENT_IDS`: `START_TASK`, `FINISHED_BD`, `FINISHED_TASK`,
  `STALLED_LOCK`, and direction-specific `STREAM_BACKPRESSURE` (mm2s) /
  `STREAM_STARVATION` (s2mm), `MEMORY_STARVATION` (mm2s) / `MEMORY_BACKPRESSURE` (s2mm).
  There is **no ERROR row on shim** — do not report its absence as a clean result, and
  do use `STALLED_LOCK` / `STREAM_*` / `MEMORY_*`, which the core branch does not have.
  Since step 1 starts at a shim producer, this is usually the first `event` you run.
  A `Warning: ~/aiejson/shimtile_events.json not found` line is cosmetic — that file only
  supplies display names; the registers were still read and the decode is valid.

Other useful verbs: `pc` (tile scope, core only — PC resolved to `file:line`),
`status` (decoded Core_Status: ENABLE/RESET/CORE_DONE/stalls), `log` (kernel klog).
Never issue `show cores`, `show dmaevent`, `show dmastatus` — live TUI grids that never
exit; aiegdb refuses them and they would drop the session. Prefer scoped reads over
array-wide `scan` (it can monopolise the JTAG link).
`dma counter setup [finished|started]` **WRITES HARDWARE** (the only `intrusive=True`
entry in `aiegdb.COMMAND_SPEC`) — ask the user first. `dma counter` without `setup`
is read-only.

### Core-side stalls (the kernel, not the DMA)

When the core itself is stuck — "the kernel never returns", CORE_DONE never set, or a
DMA `lock_acq=1` that points at the kernel rather than the fabric — stay at **tile**
scope and use:

```
status                         # Core_Status: ENABLE/RESET, LOCK_STALL_{S,W,N,E},
                               #   MEMORY_STALL_*, STREAM_STALL_{SS0,MS0},
                               #   CASCADE_STALL_*, DEBUG_HALT, ERROR_HALT, CORE_DONE
pc                             # CORE_PC (0x30F00, value = raw & 0xFFFFF) -> file:line
log                            # kernel klog buffer (alias klog; core tiles only)
callstack show                 # GDB-style call stack   (also: layers, stream)
```

`status` reads `Core_Status` at `0x32004` (aie=5) or `0x38004` (aie=2ps)
(`aiediag.CORE_STATUS_OFFSET`). `pc`, `status` and `log` all refuse on row 0 — shim
tiles have no core.

`callstack` is an `aiedbg` passthrough with two traps:
- It **requires `--work-dir`**, auto-injected from the active app's aiecompiler `Work/`
  tree. Apps with no `Work/` (your system prompt's `aiecompiler Work/:` line says
  `(none ...)`) cannot run it at all.
- At tile scope aiegdb auto-appends coordinates, but rewrites the row to
  `max(0, row - 3)`: `callstack` uses **Work/ directory coordinates**, not the schedule
  row you navigated to. Only supply col/row yourself if you already have Work/ coords.

## 3. Read `dma status`

Output shape (from `aiediag.format_dma_status`):

```
  raw=0x........  Idle|Running|Paused  running=0|1  q_size=N  cur_bd=N
  STALLED: lock_acq=0 lock_rel=0 stream=0 tct=0
  >> ERRORS: BD_UNAVAIL, BD_INVALID        (only when set)
```

Bit map (`aiediag.decode_dma_status`): `status = raw & 0x3` (0 Idle, 1 Running, 2 Paused);
bit2 `stall_lock_acq`, bit3 `stall_lock_rel`, bit4 `stall_stream`, bit5 `stall_tct`,
bit10 `err_bd_unavail`, bit11 `err_bd_invalid`, bit19 `channel_running`,
bits[22:20] `q_size`, bits[27:24] `cur_bd`.

Status register offsets (`DMA_STATUS_OFFSETS`, `+0x4` per channel):

| tile | s2mm | mm2s |
|---|---|---|
| core | `0x1DF00` | `0x1DF10` |
| shim, aie=5 | `0x1D220` | `0x1D228` |
| shim, aie=2ps | `0x9320` | `0x9328` |

## 4. PITFALL — offset decoded as value (false BD_UNAVAIL / BD_INVALID)

`aiedbg`'s human-readable line is `----0x1DF10 --- REG_0x1DF10-- 0x04080012`: the register
**value is the LAST hex token**, the first two are the *offset*. Decoding the offset as the
value fabricates errors — `0x1DF10` has bits 4, 10 and 11 set, so it decodes as
`Idle, stream stall, BD_UNAVAIL, BD_INVALID`. `0x1DF00` likewise sets bits 10 and 11.

Rule: **if `raw=` happens to equal the offset you were reading (`0x1DF00`, `0x1DF10`,
`0x1D220`, `0x1D228`, `0x9320`, `0x9328`, ...), do not report the error until you have
matched it against the `= 0x<VALUE>` line in the `[registers read]` block.** A word like
`0x0001DF10` is legal, if improbable — if the two agree, the value is real, not an artefact.

Confirm before you report any BD_UNAVAIL/BD_INVALID:
- Every decoded aiegdb command appends a `[registers read] { ... }` block whose lines read
  `reg read <phys_col> <row> 0x<OFF>  (abs 0x........) = 0x<VALUE>`. Check the `=` value
  against the `raw=` in the decode. They must match.
- Or read it raw at tile/channel scope (col/row auto-injected), hardware backend only:
  `aie_exec("reg read 0x1DF10")` and take the **last** hex token.

(`aiediag.run_aiedbg_reg_read` calls `aiedbg --json` and prefers `value_hex`, so the decoded
path is normally safe; the trap is reading a raw passthrough line by eye.)

## 5. Decision tree

Read the queried channel first, then its peer from step 1.

- **`>> ERRORS: BD_UNAVAIL`** — no BD queued for this channel. First apply step 4. If real:
  `bd` will show the chain the schedule intended; a missing/`len=0` HW BD means the BD was
  never configured (check `tile_info(section="lo")` for the BD-config call — see
  "Which BD-config symbol to look for" in step 6; the name differs per producer flow).
- **`>> ERRORS: BD_INVALID`** — BD configuration error. Same confirmation, then `bd`.
- **Idle (`status=0 running=0`)** — completed *or* never started. Disambiguate with `event`:
  - `START_TASK` not set -> never started; `start_io` was not issued for this channel.
  - `START_TASK` set + `FINISHED_TASK` set -> completed all programmed transfers. If the
    peer is still stalled, the repeat/`iter_wrap` on this side is too low (go to step 6).
  - `START_TASK` set, `FINISHED_TASK` not set -> started but stuck. On core tiles `event`
    also prints `FINISHED_BD`: set means some BDs completed and the task is mid-flight.
- **`stream=1` on an MM2S** — stream **backpressure**: downstream is not draining. Walk to
  the consumer S2MM: idle -> it finished early or never started; `stream=1` too -> routing
  congestion along the hops from `get_flow_detail`; `lock_acq=1` -> kernel not consuming.
- **`stream=1` on an S2MM** — stream **starvation**: no data from upstream. Walk to the
  producer MM2S: idle -> never started or already finished; `lock_acq=1` -> the producing
  kernel has not released its output buffer (check `status` and `pc` on that core tile).
- **`lock_acq=1` on an MM2S** — the kernel has not released the output buffer. Check the
  core: `up`, then `status` (LOCK_STALL_*/STREAM_STALL_* bits, CORE_DONE) and `pc`.
- **`lock_acq=1` on an S2MM** — DMA waiting for the kernel to consume the input buffer
  (ping-pong not cycling / lock credits exhausted).
- **`lock_rel=1`** — cannot release the lock. **`tct=1`** — stalled on task-completion count.
- **All clear, `status=1`** — that channel is running normally; move to the next hop.

## 6. Supply/demand verdict

`bd` at channel scope prints, per BD:
`BD<n>: offset= len=<N>B next->BD<m> acq=lock(id,±v) rel=lock(id,±v)` plus shim
`strides= wraps= iter_step= iter_wrap=`, then
`start_io: repeat=<R>` and `Total intended: <per_run>B/run x repeat <R> = <total>B`,
then `Intended vs real BD length (from HW)` per BD: `OK` / `MISMATCH` /
`hw not configured (len=0)`. A two-BD chain also reports `Ping-pong: BDx<->BDy cycle OK`,
`No ping-pong chain (next_bd=-1, likely shim OOO)`, or `WARNING: ping-pong chain broken`.

Build the verdict:

1. Producer total (`Total intended` on the sending channel) vs consumer total on the
   receiving channel. Cross-check against `get_flow_detail`'s
   `supply=<S>B/round demand=<D>B/round balanced=` and each participant's `bd_len=`/`fires=`.
2. `S > D` -> **OVER-SUPPLY** (consumer finishes, producer backpressures -> MM2S `stream=1`).
   `S < D` -> **UNDER-SUPPLY** (consumer starves -> S2MM `stream=1`, kernel blocks on
   acquire). Equal but still stalled -> look at locks, not volume.
3. Any HW `MISMATCH` or `len=0` means the *runtime* BD does not match the schedule — that
   is a configuration bug, not a starvation bug; stop and report it.
4. Name the responsible stage using `tile_info(section="lo")` (the emitted BD-config /
   start line) and `section="mid"` (dfschedule IR). For the mismatch-pattern -> pass
   mapping, read
   `.claude/commands/data-mismatch-debug.md`.

**Which BD-config symbol to look for.** `__Runtime_*` names exist only in
aiehlc-generated `host.cc`. Not finding them does **not** mean the BD was never
configured — check which producer flow this app came from first (your system prompt's
`aiecompiler Work/:` line: a real path = the aiecompiler flow, `(none ...)` = aiehlc):

| flow | BD config | start |
|---|---|---|
| aiehlc | `__Runtime_dma_bd_config`, `__Runtime_dma_bd_config_multidim`, `__Runtime_dma_bd_config_multidim_ooo` | `__Runtime_startio` |
| aiecompiler / naiebaremetal (`host.cc` is `Work/ps/c_rts/aie_control.cpp` verbatim) | `XAie_DmaDescInit`, `XAie_DmaSetAddrLen`, `XAie_DmaSetLock`, `XAie_DmaSetNextBd`, `XAie_DmaEnableBd`, `XAie_DmaWriteBd` | `XAie_DmaChannelSetStartQueue` |

## Report format

In this order: session/applog provenance; flow and endpoints walked; the `raw=` word per
endpoint (quote it, do not paraphrase); the `event` verdict; the supply/demand numbers;
one root-cause sentence. Mark anything you could not read as unread, never inferred.
