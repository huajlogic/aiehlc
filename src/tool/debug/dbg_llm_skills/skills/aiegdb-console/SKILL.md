<!-- Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: aiegdb-console
description: PRECEDENCE - this skill alone owns "what is the exact aie_exec command string?"; other skills name commands, this one is authoritative on spelling, arguments and scope. Read while COMPOSING an mcp__aiegdb__aie_exec call, or after one errored, hung, came back empty, or was rejected as a live TUI. Your always-loaded system prompt shows two WRONG forms: `bd <id>` (`bd` takes NO argument; the id is silently ignored) and `target channel DIR N` (rejected - it is one token, `target channel mm2s0`). Gives the partition -> tile -> channel scope model and what each level auto-injects (phys_col = col + startcol and row at tile scope, direction and channel number at channel scope), the per-scope verb/alias/argument tables straight from aiegdb.COMMAND_SPEC, which raw aiedbg passthroughs are refused (`show cores`, `show dmaevent`, `show dmastatus`) or monopolise the JTAG link (`scan`), the places `event` prints no decode at all (shim tile scope; shim channels beyond ch0/ch1), and the INTRUSIVE writers to ask the user about before firing: `dma counter setup [finished|started]`, the only COMMAND_SPEC entry flagged intrusive=True (it reg-writes CONTROL0, 0x11000 core / 0x31000 shim), and any passthrough whose name starts with `write`, e.g. `reg write`. Syntax only: whether you may believe the answer is session-provenance's, what the decoded numbers mean is dma-stall-triage's, what the IPC simulator additionally blocks is simulator-vs-hardware's.
---

# Driving aiegdb through `aie_exec`

Source of truth: `src/tool/debug/aiegdb.py`
(`COMMAND_SPEC`, `_dispatch`, `_tile_cmd`, `_channel_cmd`) and
`src/tool/debug/aiemcp.py` (`_run`, `_needs_hw`, `_session_refusal`).

## Scope model

One long-lived `AieGdb` instance lives inside the MCP server, so **scope persists across
tool calls**. Three nested levels; the returned `"scope"` field is the prompt:

```
partition(startcol=N)>                     nothing decoded here — raw aiedbg only
partition(startcol=N)/tile(0,3)>           target tile 0 3
partition(startcol=N)/tile(0,3)/mm2s0>     target channel mm2s0
```

- **partition** — holds `startcol`, `device`, `aie_version`, `target`. `COMMAND_SPEC["partition"]`
  is empty: every non-navigation verb here is forwarded verbatim to the `aiedbg` binary with
  explicit col/row.
- **tile** — `target tile <col> <row>` (col/row are *logical*). Decoded commands auto-inject
  `phys_col = col + startcol` and `row` (`AieGdb.phys_col`). `row == 0` is typed `shim`, else `core`.
- **channel** — `target channel <dir_ch>`, `<dir_ch>` matching `^(mm2s|s2mm)\d+$`. Direction and
  channel number are auto-injected on top of col/row, so `dma status` / `bd` / `event` need no args.

Navigation, valid at every scope (`COMMAND_SPEC["universal"]`):

| command | aliases | args |
|---|---|---|
| `target tile` | `tar tile`, `tile` | `<col> <row>` |
| `target channel` | `tar channel`, `channel` | `<dir_ch>` |
| `target partition` | `tar partition` | `[startcol=N] [target=..] [device=..] [aie=5\|2ps]` |
| `up` | `..` | pop one level |
| `top` | — | jump to partition |
| `where` | `info`, `pwd` | breadcrumb + phys_col/row + target/device |
| `set` | — | `startcol N \| target .. \| device .. \| aie ..` |
| `?` | `commands`, `cmds` | current-scope command list |
| `help` | — | full reference |
| `spec` | — | the grammar as JSON |
| `exit` | `quit`, `q` | (do not use from MCP) |

`tile(0,3)` parenthesised forms work — `_expand_parens` rewrites them to `tile 0 3`.
A bare `mm2s0` at tile scope also selects the channel.

## Tile-scope commands (`COMMAND_SPEC["tile"]`)

| command | aliases | args | notes |
|---|---|---|---|
| `dma` | — | `<dir_ch>` | decoded DMA status for one channel |
| `pc` | — | — | core PC resolved to source via line map; errors on row 0 |
| `status` | `core`, `core status` | — | decoded core status (enable/reset/stall); errors on row 0 |
| `event` | — | — | **core tiles only**: decoded MEM-module event status (`MEM_EVT_STATUS_REGS`). On a **shim tile (row 0) there is NO decode, ever** — `_tile_events` just reads `0x34200`/`0x34204` and the only output is the `[registers read]` appendix. For a shim verdict go to channel scope. |
| `channels` | `chans` | — | lists channels from `schedule_view.json` — **no board read** |
| `log` | `klog` | — | kernel klog buffer, core tiles only |

`reg read OFF`, `mem read ADDR LEN` and `callstack show|layers|stream` are
passthrough here with col/row auto-filled. `reg write OFF VAL` is also
passthrough with col/row auto-filled and **WRITES HARDWARE — ask the user
before issuing it** (see Intrusive below).
`callstack` also gets `--work-dir` injected and, *only when you do not supply
col/row yourself*, `work_row = max(0, row - 3)` appended — Work/ directory
coordinates, not schedule rows (`aiegdb.py` `_tile_cmd`, the `has_coords` check).

## Channel-scope commands (`COMMAND_SPEC["channel"]`)

| command | aliases | args | notes |
|---|---|---|---|
| `dma status` | `status`, `dma` | — | decoded DMA status register |
| `bd` | — | — | BD chain from provenance JSON + live HW lengths |
| `event` | — | — | per-channel DMA start/finish/error, with a verdict line. **Shim decode covers ch0/ch1 only** (`aiediag.SHIM_DMA_EVENT_IDS`); `decode_shim_event_status` returns `None` — and the command prints **nothing at all** — for a shim channel outside that range (e.g. `mm2s2`) or when both event-status reads came back `None`. An EMPTY reply does NOT mean "no events fired". Check the `[registers read]` block: if it is missing, or shows `= ----------`, the read failed. |
| `dma counter` | `counter` | — | AIE perf counters, read-only |
| `dma counter setup` | — | `[finished\|started]` | **INTRUSIVE — writes CONTROL0** |
| `log` | `klog` | — | kernel klog buffer, core tiles only |

## Intrusive — do not run casually

Only one entry in `COMMAND_SPEC` carries `intrusive: True`: **`dma counter setup`**. It
`reg write`s **CONTROL0** — `0x11000` on core tiles (`PERF_OFFSETS["core_mem"]["ctrl0"]`) or
`0x31000` on shim (`PERF_OFFSETS["shim_pl"]["ctrl0"]`) — packing the event id into bits[6:0]
and bits[14:8] so CNT0 start == stop == that event, and it perturbs the running design.
The counter **value** registers are `0x11020`/`0x11024` (core mem) and `0x31020`/`0x31024`
(shim PL); plain `dma counter` only reads those plus CONTROL0, and is read-only.

Passthrough commands are auto-marked intrusive when any word of the name starts with
`write` (`_parse_aiedbg_help`: `intrusive=any(t.startswith("write") ...)`), e.g. `reg write`,
`reg write-mmio`. Ask the user before firing any of these.

## Passthrough (raw `aiedbg`) — and what will break

Anything aiegdb does not decode is forwarded to the `aiedbg` binary. The passthrough list is
*discovered* at runtime from `aiedbg --help` (`discover_aiedbg_spec`), so run
`aie_exec("?")` to see what this install actually has rather than assuming.

- **Blocking live TUIs are refused.** `aiemcp` sets `gdb.no_tui = True`, so `_blocked_tui`
  rejects `show cores`, `show dmaevent`, `show dmastatus` (and anything `aiedbg --help`
  describes as "Real-time …"/"Live …"). Do not retry them; use the UI grid overlay.
- `scan ...` is array-wide and can monopolise the JTAG link (`slow`); prefer
  `target tile C R` + a scoped read.
- Passthrough has a 120 s timeout (`AIEGDB_PASSTHROUGH_TIMEOUT`).
- On the **simulator** backend (`AIEMCP_BACKEND=simulator`) `_patch_gdb_for_simulator` replaces
  `_passthrough` with a stub: `reg read`, `mem read`, `scan` are unavailable and only decoded
  commands (`dma`, `pc`, `event`, `channels`, `bd`) work, via the IPC socket. Check
  `mcp__debugui__get_backend_status` first.

## Session gate — when you get `{"refused": true}`

`_run()` calls `_session_refusal(line)` before touching the device. `_needs_hw(line)` looks at
the **first token only**; these verbs never need a board (`_NO_HW_VERBS`):

```
target  tar  tile  channel  up  ..  top  where  info  pwd  set
help  ?  commands  cmds  spec  exit  quit  q  channels  chans
```

Exception coded explicitly: `tile list` (verb `tile`, arg `list`) *is* a passthrough and *is*
gated. Note also that a bare `mm2s0` (channel-select shortcut) is not in the set, so it is
gated even though it only navigates — use `target channel mm2s0` instead.

Everything else is gated on `backend_status.json > session.authorized`, written by the daemon
(`DebugState.session_state`). Authorized means the user pressed **Connect** (`connected`),
**Run test** (`ran`), or **Open Current Session** (`attached`). If not authorized, `aie_exec`
returns:

```json
{"output": "REFUSED: no board session ...", "scope": "...", "refused": true, "session": {...}}
```

When you see `refused: true`: **nothing was read.** Do not describe, infer, or guess board
state, and do not fall back to the `applog` as if it were this run. Tell the user to press
Connect / Run test / Open Current Session. (If `backend_status.json` has no `session` key —
aiemcp launched standalone — the gate is skipped and commands proceed.)

## Worked navigation

Everything that touches a register needs an authorized session; only `where`, `?`,
`target ...`, `channels`, `up` and `top` are session-free (`_NO_HW_VERBS`).

```
aie_exec("where")                    # scope + startcol/device/target, no board needed
aie_exec("?")                        # commands valid right here
aie_exec("target tile 0 3")          # -> "scope -> partition(startcol=N)/tile(0,3)  (phys_col=..., row=3)"
aie_exec("channels")                 # JSON-only: which channels this tile has
aie_exec("status")                   # core enable/reset/stall   [needs session]
aie_exec("pc")                       # PC -> file:line            [needs session]
aie_exec("target channel mm2s0")
aie_exec("event")                    # started / finished / stuck verdict   [needs session]
aie_exec("bd")                       # BD chain + live HW lengths           [needs session]
aie_exec("up")                       # back to tile scope
aie_exec("top")                      # back to partition
```

Decoded commands append a `[registers read] { … }` appendix listing each address and raw value —
quote those when reporting, they are the ground truth behind the decode.
