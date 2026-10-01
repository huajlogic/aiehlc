<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: live-scan-results
description: How to read and use the AIE Debug pane's live overlay scans (DMA / Cores / Events / Switch). Read when the user pressed Scan or enabled live overlay, when you receive a `[context] Live scan (...)` snippet, when they ask about coloured tiles, the issue bar, stalls, switch mismatches, or "what did the scan show". Covers the four scan modes, what each tile state means, when `get_live_scan()` is enough vs when you still need `aie_exec`, and how scan evidence chains into `dma-stall-triage` and `root-cause-workflow`. Session provenance still gates whether the scan describes the run you are debugging.
---

# Live scan results

The human drives scans from the **AIE Debug** pane (Grid or Device Map):

- **Selector** — `DMA`, `Cores`, `Events`, or `Switch`
- **Scan** — one read of every tile in the partition
- **live** — repeat the same read every ~2 s

Each successful `/grid` response is summarized for you in two ways:

1. **Automatic context** — after Scan/live, the browser pushes
   `[context] Live scan (<mode> @ <time>)\n…` into the LLM tab (channel `scan`).
2. **On demand** — `mcp__debugui__get_live_scan(detail=True)` returns the latest
   summary even if the user has not sent a message yet. Use `detail=False` for
   only the headline line.

You do **not** need to re-read every tile with `aie_exec` when a scan already
answered the question. Use the scan for *where* to look; use `aie_exec` for
*register-level proof* on one suspect tile/channel.

## 0. Gate — whose board state is this?

Before interpreting colours or stall lines, call `mcp__debugui__get_backend_status`
and apply `session-provenance`:

- `mode == "none"` → no live reads; the scan will fail or be stale UI state.
- `mode == "connected"` → registers may be from a **previous** run.
- Only in `mode == "ran"` (or `attached` with a current applog) should you tie
  scan findings to "this run stalled because …".

The scan timestamp in the summary is when **you** read the board, not when the
run started. Phrase findings accordingly.

## The four scan modes

| Mode | What it reads | Tile states you will see |
|---|---|---|
| **dma** | DMA channel status on every tile | `idle`, `running`, `stalled`, `error`, `unreachable` |
| **cores** | Core run/halt | `idle`, `running`, `unreachable` |
| **events** | DMA event status bits | `idle`, `running` (= event bit set), `unreachable` |
| **switch** | Stream-switch registers vs static routing map | `match`, `mismatch`, `unreachable`; plus optional **dynamic** routing rebuild |

### DMA scan — interpret channel lines

Summary shape:

```
Live scan (dma @ …)
DMA scan: tile states {idle=…, running=…, stalled=…, …}
active/problem channels:
  (col,row) mm2s0:stalled stall=stream; s2mm0:running bd=3
```

- **Tile state** is the worst channel on that tile.
- Per-channel tail:
  - `stall=…` — stall reason tokens (`stream`, `lock_acq`, `memory`, …)
  - `err=…` — error tokens (`BD_UNAVAIL`, `BD_INVALID`, …)
  - `bd=N` — current BD id on that channel

**Next steps:**

1. Map `(col,row)` + channel to a flow: `get_flow_detail` / `tile_info` (static).
2. Walk producer → hop → consumer with `dma-stall-triage` if stalls persist.
3. Drill one tile only: `aie_exec("target tile C R")` → `channels` →
   `target channel mm2s0` → `dma status` / `event` / `bd`.

Do not treat `err=BD_UNAVAIL` as gospel without `[registers read]` — see
`dma-stall-triage` offset-as-value pitfall.

### Cores scan — who is actually executing?

```
Cores scan: {idle=…, running=…}
running: (4,4), (5,4)
```

- **running** on a core tile → kernel still on-core (or spinning).
- Every core **idle** while DMA scan shows **stalled** shim channels → classic
  "core never started / finished early" vs "core blocked" fork (`root-cause-workflow` §4).
- Cores scan does **not** name which kernel; use `tile_info(col,row,"hi")`.

### Events scan — which tiles have DMA events latched?

```
Events scan: {idle=…, running=…}
event bits set: (0,3), (4,4)
```

Here `running` means **event status bit set**, not "DMA channel running".
Useful to see activity spread without parsing every channel line. Pair with a
**dma** scan when you need stall reasons.

### Switch scan — static map vs hardware vs dynamic routing

```
Switch scan: tile states {match=…, mismatch=…}
3 tile(s) disagree with the static routing map: (2,3), (4,0), …
dynamic routing: 42 flow(s) reconstructed from registers
```

- **mismatch** — live stream-switch registers decode to connections that differ
  from `routingprovenancemap.json` (compiler/static view). The UI tints those
  tiles; Device Map may show an **issue bar**.
- **Every tile matches** — hardware agrees with the static map; a data bug is
  unlikely to be "wrong routing.cc emitted" unless only some tiles were scanned
  (`unreachable` tiles were skipped).
- **dynamic routing** — a full rebuild from registers (`Dynamic` toggle in
  the UI). Flow count and comm_paths may differ from static when the map is
  stubbed, stale, or the design was partially reprogrammed. Use `get_flow_detail`
  on static flows first; treat dynamic paths as "what hardware actually wires
  today".

When the user stubbed routing for testing, mismatch tiles are **expected**;
explain static vs dynamic rather than calling it a compiler bug.

**What the user is looking at may not be what you were told.** The summary above
always compares the board against the static map, but the UI only shows that
comparison when the **diff** checkbox next to the routing dropdown is ticked.
With diff off, tiles are untinted (bar `unreachable`) and the tile panel draws
the selected map with no badges. So a scan can report mismatches to you while the
user sees a calm grid — if the mismatches matter, say where they are and tell
them to tick **diff**, rather than assuming they are already on screen.

Diff also runs in the direction of the selected source: on `Static` a row the
rebuild lacks is badged `static only`, on `Dynamic` a row the compiler's map
lacks is badged `dynamic only`. Same comparison, opposite vantage point — so
check which source they are on before reading their description of a badge.

## Which tool when?

| Situation | Tool |
|---|---|
| User just scanned / coloured grid | `[context]` snippet or `get_live_scan()` |
| "What's stalled?" without a recent scan | Ask them to Scan (DMA), or `get_live_scan()` then offer to scan |
| Confirm one channel's stall bit | `aie_exec` on that tile after scan names it |
| Switch colours / routing mismatch | `get_live_scan()` (switch mode) → `get_flow_detail` for static expectation |
| Hang / wrong output root cause | Scan summary → `root-cause-workflow` + `dma-stall-triage` |

## Colour / UI mapping (human questions)

The user may describe colours instead of scan JSON:

- **DMA stalled** — red/orange channel tint on grid or Device Map
- **Switch, diff off** — no tint at all; the scan's output is the `Dynamic (n)`
  routing source, not a colour
- **Switch, diff on** — green `sw ok` / red `sw ≠` swatch, plus per-row
  `static only` / `dynamic only` badges in the tile panel
- **Unreachable** — tile could not be read (not connected, wrong partition, sim down)

Always reconcile with `get_backend_status()` before blaming the design.

## Related skills

- `session-provenance` — may you claim this scan matches the current run?
- `debugui-tools` — `get_live_scan` parameters and return shape
- `dma-stall-triage` — walk stalls after the scan names the tile/channel
- `root-cause-workflow` — compose scan flags into a root-cause call
