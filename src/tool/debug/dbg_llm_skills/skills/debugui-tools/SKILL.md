<!-- Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: debugui-tools
description: Catalogue of the SIXTEEN granted `mcp__debugui__*` tools - exact names, parameter names/types/defaults, return shapes, and the error string each one emits. Read when you need a fact out of the COMPILED STATIC SCHEDULE (which tiles exist; a tile's role, kernel and channel<->kernel-argument map; a flow's hops and stream-switch pairs; per-flow supply/demand; BD lengths; where a symbol occurs) or out of WHAT THE USER HAS ON SCREEN (`get_ui_state` is how "this tile" / "that flow" resolves to real coords; `get_pane` returns one UI pane verbatim; `list_apps` / `current_app` answer "which app is loaded, and what else could be"; `app_sources` lists that app's own source files so an explanation can cite code instead of stopping at the schedule), when the user has run a live overlay scan in the AIE Debug pane (`get_live_scan` returns the latest DMA/Cores/Events/Switch summary — pair with the `live-scan-results` skill), and when a debugui call returned something you must interpret: "daemon not reachable" from the daemon-backed tools, `_load_view()`'s tried-paths error, or a `kinds=` filter that is never validated and so silently matches nothing on a typo. Most of the sixteen touch only static schedule or disk logs; `get_live_scan` reads the last `/grid` overlay the user ran (still not a substitute for `get_backend_status` session gating). `select_app` is registered in debug_ui_mcp.py but deliberately NOT granted - never call it; ask the user to switch apps in the UI. Also documents the get_applog FRESH/STALE/UNVERIFIED banner and the get_ipc_log CSV columns. A tool catalogue, not a procedure: symptom triage is dma-stall-triage's, scan interpretation is live-scan-results's, an on-disk file's absolute path is app-layout's, what a banner lets you claim is session-provenance's.
---

# debugui MCP tools — the cheap static-schedule and UI-state layer

Source of truth: `src/tool/debug/debug_ui_mcp.py`.
The list is `_llm_spawn()`'s `--allowedTools` in `schedule_debug_server.py`. Note that
`--allowedTools` is a *permission* allowlist, not an availability filter, and the spawn also
sets `--permission-mode bypassPermissions` — so a tool the server exposes is callable whether
or not it is listed. Withholding one requires `--disallowedTools`, which the spawn uses for
exactly one tool (below).

**Sixteen** `mcp__debugui__*` tools are granted, in three groups:

- **Schedule-view tools** (9) — `get_design_overview`, `tile_list`, `tile_info`,
  `get_flow_detail`, `symbol_search`, `get_backend_status`, `get_applog`, `get_sim_log`,
  `get_ipc_log`. These read the **static compiled schedule** (`schedule_view.json`, the
  same blob that renders `host_schedule.html`) or a log file on disk.
- **Live scan tool** (1) — `get_live_scan`. Returns the latest **overlay scan** the user
  ran from the AIE Debug pane (DMA / Cores / Events / Switch). Does not touch the board
  itself; it reads `backend_status.json > last_scan` or `GET /live_scan`. Interpret with
  the `live-scan-results` skill; gate with `get_backend_status` / `session-provenance`.
- **App / UI tools** (6) — `list_apps`, `current_app`, `app_sources`, `get_ui_state`,
  `list_panes`, `get_pane`. See the second section below. None reads
  `schedule_view.json` except `get_pane`, and they fail differently:
  `list_apps` / `current_app` / `get_ui_state` are **daemon-backed** (HTTP),
  `app_sources` reads `backend_status.json` off disk, and `list_panes` is a static table.

Fifteen of the sixteen do not issue fresh hardware reads during the tool call itself.
`get_live_scan` surfaces a scan the user (or live overlay) already triggered via `/grid`.
None are gated by the session-authorization check that `mcp__aiegdb__aie_exec` enforces,
none write hardware, and none can fail a run. Use them freely.

`debug_ui_mcp.py` registers a seventeenth tool, `select_app(app_id)`, which the spawn
explicitly **denies** via `--disallowedTools mcp__debugui__select_app` — switching the app
reconfigures the whole server (board IPs, PDIs, ELF paths) and belongs to the user. Calling
it will be refused; if the user needs a different app, tell them to pick it in the UI.

**Coordinates.** `col`/`row` everywhere here are the *logical* grid coords shown in the UI
(row 0 = shim, rows >= 3 = core). They are the same coords `aie_exec("target tile C R")`
takes — `aiegdb` adds `startcol` itself (`phys_col = col + startcol`,
`aiegdb.py:449`). Do not pre-add `startcol`.

## Data resolution (why a tool may say "not found")

`_load_view()` tries, in order: the current app's `<path>/schedule_view.json` (asked of the
daemon via `/apps`), `$DEBUGUI_JSON_DIR/schedule_view.json`,
`$AIEMCP_JSON_DIR/schedule_view.json`, `./aout/worklocal/schedule_view.json`,
`./worklocal/schedule_view.json`. The error message lists exactly the paths it tried —
quote it rather than guessing. It is cached per resolved path.

---

## The schedule-view tools

### `mcp__debugui__get_design_overview()` → str
No parameters. **Call this first in a new session.** Three sections:
`=== Grid geometry ===` (`cols`, `rows`, `startcol`, `shim rows`, `core rows`),
`=== Communication flows (N) ===` one line per comm_path
(`f<idx> <direction>  <producer gmio/config_ref> → <direction> tile(c,r)`), and
`=== Supply/demand balance ===` one line per flow: either `f<i> balanced pattern=<p>` or
`f<i> OVER-SUPPLY|UNDER-SUPPLY supply=<N>B demand=<N>B [note]`.
Answers: *what is this design, how many flows, is anything unbalanced?*

### `mcp__debugui__tile_list()` → str
No parameters. One line per tile: `(col,row) <type> <role>`. Answers: *which tiles exist
and which are shim / core / compute?* Cheapest way to get valid coords before `tile_info`.

### `mcp__debugui__tile_info(col: int, row: int, section: str = "all")` → str
`section` ∈ `"hi" | "mid" | "lo" | "all"` (case-insensitive; anything else returns an
error string). Exactly what the human sees when clicking a tile:
- `hi` — role, kernel, `supply / demand:` per-flow verdict lines
  (`flow <i> (<pattern>): balanced|OVER-SUPPLY|UNDER-SUPPLY supply=..B/round demand=..B/round (delta ..B) [note]`),
  `transfers:`, `contracts:`, and the `channel <-> kernel argument (by BD buffer address)`
  map (`S2MM0 -> window <name> arg<N> [bd 0x.. = <bcf_sym>] via <method>`).
- `mid` — the tile's `dfschedule` IR slice, preceded by `file: <abs path>` and rows tagged
  `<basename>:<line> <code>`.
- `lo` — attributed `host.cc` lines: `file: <abs path>`, then `host.cc lines <start>-<end>:`,
  then rows tagged `host.cc:<line> <code>`.
Unknown tile → error listing every available `(col,row)`.
Answers: *what is this tile supposed to be doing, and which source line configured it?*

### `mcp__debugui__get_flow_detail(flow_index: int)` → str
The net-detail panel for one flow. Per stage: `[producer|consumer] tile(c,r) gmio=… contract=…`
then `hop: <from> → <to> [<hop_type>/<shmem_kind>]`; then
`[stream-switch connections]` as `(c,r) <slave dir>/<idx> → <master dir>/<idx>` for
`circuit_connect` entries; then `[supply/demand]` with `pattern / supply_per_round /
demand_per_round / balanced / note` and one `participants` line per endpoint:
`(c,r) <MM2S|S2MM> ch<N>  bd_len=<B>  fires=<N> [shim]`.
Bad index → error listing available indices.
Answers: *how does data actually get from the shim to this tile, and who over/under-supplies?*
The `participants` block is the table to reason over for a data-mismatch question.

### `mcp__debugui__symbol_search(query: str, kinds: str = "")` → str
Case-insensitive substring search, mirroring the UI search bar. `kinds` is a
comma-separated filter, empty = all. Valid kinds: `kernel`, `window`, `buffer`,
`contract`, `bd_len`, `net`, `flow`, `gmio`, `port`. Output: a count header then
`  <kind>  (col,row)  f<fi>  <label>  —  <description>`; `(-,-)` / `—` for design-wide
entries (kernel windows). Empty query is an error.
An unrecognised `kinds` value is **not** rejected (unlike `tile_info`'s `section`) — it is
split on commas and used as a set filter with no validation, so a typo just filters
everything out and you get the same `no matches for '<q>' (kinds: <k>)` string a genuine
absence produces. If a search you expected to hit comes back empty, retry with `kinds=""`
before concluding the symbol is absent.
Answers: *where does this name/number appear?* e.g. `symbol_search("1024", "bd_len")` to
find every BD of that length, `symbol_search("out", "window")` to locate an output buffer.
Feed the returned `(col,row)` straight into `tile_info`.

### `mcp__debugui__get_backend_status()` → dict
No parameters. Returns a **dict**, not text. Keys: `backend`
(`"simulator" | "hardware" | "unknown"`), `ipc_ready` (bool), `dbg_socket`, `target`,
`device`, `startcol`, `aie_version`, `sim_log`, `sim_applog`, `session` (dict),
`session_summary` (str), `note` (str).
Read `note` and `session` **before** any `aie_exec` that touches the device:
- `backend="simulator"`, `ipc_ready=false` → the sim is not running; live reads will fail.
  Tell the user to press Run.
- `backend="hardware"` with `session.authorized` falsy → `aie_exec` will *refuse* device
  reads. The user must press "Connect", "Run" or "Open Current Session" first. Do
  not describe board state.
Answers: *is a live read even possible right now?*

### `mcp__debugui__get_live_scan(detail: bool = True)` → str
No hardware read in the tool itself — returns the **latest overlay scan** the user
ran from the AIE Debug pane (DMA / Cores / Events / Switch selector + Scan or live
every ~2s). Sources, in order: `backend_status.json > last_scan`, then daemon
`GET /live_scan`. After each scan the browser also injects
`[context] Live scan (…)` into the LLM tab automatically.

When `detail=True` (default), returns a multi-line block:
`Live scan (<mode> @ <timestamp>)` plus mode-specific lines (tile state counts,
stalled channels with `stall=` / `err=` / `bd=`, mismatch tiles, dynamic flow
count, …). When `detail=False`, returns only the headline line.

If nothing was scanned yet:
`no live scan recorded yet — the user has not pressed Scan or enabled live overlay
in the AIE Debug pane`.

Answers: *what did the user's scan show?* Use before re-reading every tile with
`aie_exec`. Interpret with the **`live-scan-results`** skill; still call
`get_backend_status()` first so you know whose run the scan reflects.

### `mcp__debugui__get_applog(lines: int = 50)` → str
Tail of the run log — simulator `ipc_app.log` when `backend == "simulator"`, otherwise the
hardware applog. Prefixed with `[source: … path=…]` and then a **provenance banner**:
- `[FRESH: written by the run started from this UI]` — safe to treat as current.
- `[STALE: … BEFORE this debug session started …]` — describes a PREVIOUS run.
- `[UNVERIFIED: … no run was started here]` — external/unknown run.
A `PASS: all N elements match` under a STALE/UNVERIFIED banner proves **nothing** about
now. Always report which banner you got instead of presenting the tail as the current result.

### `mcp__debugui__get_sim_log(lines: int = 50)` → str
Tail of the simulator PS application log (`sim_applog` / `ipc_app.log`) specifically — no
provenance banner. Returns an error string when the sim applog path is unset or the file
does not exist ("start the simulator first"). Use `get_applog` in hardware mode.

### `mcp__debugui__get_ipc_log(lines: int = 100, side: str = "both")` → str
Simulator-only. `side` ∈ `"client" | "server" | "both"`. Reads `ipc_client.log` /
`ipc_server.log` from the directory containing the sim applog; errors if the simulator is
not configured. The first row (header) is always kept when truncating. CSV columns:
`seq, ts_ns, side, cmd, arg1, arg2, status, value, note`. `ts_ns` is CLOCK_MONOTONIC —
subtract the first row's value for elapsed time; a client↔server pair's delta is the
transaction round-trip. Commands: `WRITE32`/`READ32`, `NPI_WRITE32`/`NPI_READ32`,
`WRITE_GM`/`READ_GM`/`ALLOC_GM`/`FREE_GM`, `GRAPH_INIT`, `START_PLIO`, `EXIT`.
Answers: *what was the last transaction before the hang, and which address is it stuck on?*

---

## The app / UI tools

`list_apps`, `current_app` and `get_ui_state` do **not** read `schedule_view.json` — they
HTTP-GET the daemon (`/apps`, `/uistate`) via `$DEBUGUI_SERVER_URL`. When that variable is
unset or the server is down they return a `daemon not reachable …` string instead of data;
that is a *connectivity* answer, not "no apps exist". `app_sources` reads
`$DEBUGUI_JSON_DIR/backend_status.json`, which the daemon rewrites on every backend change —
so it needs no HTTP but does need the daemon to have written the file at least once.
`list_panes` is a static table and `get_pane` reads `schedule_view.json` like the tools above.

### `mcp__debugui__list_apps()` → str
No parameters. One row per registered app, newest first:
`<* if current> <id> <caps> <path>`, where `<caps>` is `sim`, `hw`, `sim,hw` or
`view-only` (derived from the app's `has_sim` / `has_hw`). `(no apps registered)` when the
registry is empty. Answers: *what else could be loaded, and does it even have a simulator
or a hardware run profile?*

### `mcp__debugui__current_app()` → str
No parameters. JSON dump of the current app's info dict: `id`, `label`, `path`, `mtime`,
`current`, plus the capability flags `has_ui_config`, `has_backend_status`, `has_sim`,
`has_hw`. `(no app selected)` if none is current. `path` is the app workdir — the anchor
every path in the app-layout skill hangs off. Answers: *which app am I actually looking at?*

### `mcp__debugui__app_sources()` → str
No parameters. The current app's own source files, grouped: **Entry source** (the file the
app was built from — aiehlc flow only), **Kernels** (each kernel name the schedule runs →
the `file:line` defining it, matched *by name*, so treat the line as a jump target and
confirm it), **Application** / **Headers** (hand-written `.cc`/`.cpp` and `.h`/`.hpp` found
under `app_dir`, with generated files filtered out), **Build** (`build.sh`, `Makefile`,
`.bif`), and **Generated** (`host.cc`, `kernel.cc`, the `.bcf`, the dfschedule MLIR —
compiler output, overwritten on the next build, never the place to propose a fix). Paths are
relative to `app_dir`. Answers: *what code is this app actually made of, and which file do I
open to explain this tile?* The system prompt carries the same inventory for the app loaded
at spawn — call this after an app switch to refresh it. Returns a
`no sources found …` or `daemon not reachable …` string rather than an empty list; when it
does, say so instead of guessing filenames. **Reading what this names, and citing it, is the
`source-grounding` skill** — that is where the rules for using it live.

### `mcp__debugui__get_ui_state()` → str
No parameters. JSON of what the browser last reported it had open. Keys: `selected_tile`
(`[col,row]` or null), `tile_tab` (`hi`/`mid`/`lo` — the same names `tile_info`'s `section`
takes), `net_tab`, `view` (`"grid"`|`"map"` — which view the AIE Debug pane is
showing), `console_pane` (default `"conpane"`, and which Tools tab is open), `flow`, `channel` (direction +
index, e.g. `S2MM0`), `search`, plus `app` (the app id) and `ts` (epoch seconds)
stamped by the daemon. Returns `(no UI state reported yet …)` when the user has not
interacted. Answers: *what is on the human's screen right now?* — use it so "this tile"
and "that flow" in a question resolve to what they are actually looking at.

### Citing source locations

Write every source reference as `<file>:<line>` — `host.cc:412`,
`src/tool/debug/aiegdb.py:88`, or an absolute path. The UI renders that as a click that
opens the file in the **Info** pane, syntax-highlighted and scrolled to the line. A bare
filename with the line given separately is not clickable, and neither is the old
`L<line>` form. Bare filenames resolve against the *currently loaded app*, so for
anything outside it give a path. `.elf` and other binaries are refused.

The same applies to `pc` output in the aiegdb console: its `PC -> file:line` lines are
clickable already.

### Window panes

The UI is four named panes, each labelled in its top-left corner. Users refer to them
by name, so map the name to the tool before answering:

| Pane | Position | Contains | Ask |
|---|---|---|---|
| **AIE Debug** | top-left | the array (Grid / Device Map views) + the DMA/Cores/Events pills, `Scan`, `live` overlay | `get_design_overview`, `tile_list`, `get_flow_detail` |
| **Execution** | bottom-left | app + board selection, `Connect` / `Run` / `Force stop`, run log | `get_backend_status`, `get_applog`, `get_sim_log` |
| **Info** | top-right | detail for the current selection, tile (Schedule/IR/Code) or net | `tile_info`, `get_flow_detail`, `get_pane` |
| **Tools** | bottom-right | aiegdb console, LLM chat, Search | `aie_exec`, `symbol_search` |

`get_ui_state()` resolves what is live in them; `get_pane` ids carry their pane in the
table below.

**The Execution pane's controls are not fixed.** A daemon serving ONE app has no
`App:` row at all — the app's name sits beside the `AIE Debug` pane title instead.
A daemon started `--sim-only` has no `Board:` row, no `Connect` and no `Attach
existing run`: the simulator is activated automatically on load so **`Run` is
the only button**, and `/ping`, `/attach`, `/run`, `/settarget` and
`/launch_hwserver` all refuse with `sim_only: true`. So before you tell the user to
"pick the board" or "press Connect", check `get_backend_status()`: under sim-only
neither control exists, and the simulator is the only thing that can produce live
state.


### `mcp__debugui__list_panes()` → str
No parameters. Prints the four window panes and their contents, then the
`get_pane` ids and the selector each needs.

### `mcp__debugui__get_pane(pane: str, col: int = -1, row: int = -1, flow: int = -1, query: str = "")` → str
Returns exactly the content of one UI pane. Valid `pane` ids (anything else returns
`unknown pane …` plus the list):

| `pane` | selector | window pane | content |
|---|---|---|---|
| `grid` | none | AIE Debug | tile grid overview (same as `tile_list()`) |
| `tile.hi` | `col`,`row` | Info | tile **Schedule** tab |
| `tile.mid` | `col`,`row` | Info | tile **IR** tab, `dfschedule` IR — aiehlc apps only |
| `tile.lo` | `col`,`row` | Info | tile **Code** tab: `host.cc` (rows tagged `host.cc:<line>`) under aiehlc, kernel source + `.bcf` + generated wrapper under naiebaremetal |
| `tile.kernel` | `col`,`row` | Info | kernel match / source |
| `tile.supply` | `col`,`row` | Info | tile supply/demand rollup |
| `net.flow` | `flow` | Info | flow / communication-path detail |
| `search` | `query` | Tools | Search tab results |

Missing selector → `error: pane '<p>' needs col and row` / `needs flow` / `needs query`.
Unknown tile → `error: no tile (c,r) in the current app`. An empty pane returns
`(pane <p> is empty for tile (c,r) in this app)`, which is information, not a failure.
Nothing here is unique to `get_pane`: `tile.kernel` and `tile.supply` are the kernel-match
and supply/demand blocks that `tile_info(col,row,"hi")` already includes, and `grid`,
`search`, `net.flow`, `tile.hi/mid/lo` delegate to `tile_list`, `symbol_search`,
`get_flow_detail` and `tile_info`. Reach for `get_pane` when the user is pointing at
something on screen and you want *just* that pane (pair it with `get_ui_state`); use
`tile_info` / `get_flow_detail` when you are driving the investigation yourself.

---

## Which tool first

| User asks | Order |
|---|---|
| anything, cold start | `current_app()` → `get_design_overview()` → `get_backend_status()` |
| "what am I looking at?" / "this tile", "that flow" | `get_ui_state()` → `get_pane(...)` on what it reports |
| "what's in the Info / Run / Tools pane?" | `list_panes()` for the layout, then the tool that pane maps to |
| "which app is loaded?" / "what else can I load?" | `current_app()` / `list_apps()` |
| "what does this kernel actually do?" / "where is this in my code?" | `app_sources()` → Read the file it names → cite `<file>:<line>` |
| "what's on tile (0,3)?" | `tile_list()` → `tile_info(0,3,"hi")` → `"mid"`/`"lo"` only if pressed |
| "why is the output wrong / zero?" | `get_design_overview()` (find the unbalanced flow) → `get_flow_detail(<fi>)` (participants table) → `tile_info` on the offending endpoint |
| "where is `<name>`?" | `symbol_search("<name>")` → `tile_info(col,row)` |
| "how is f3 routed?" | `get_flow_detail(3)` |
| "did the run pass?" | `get_applog(80)` — and state the provenance banner |
| sim hangs / no output | `get_backend_status()` → `get_sim_log(100)` → `get_ipc_log(120,"both")` |
| "is the DMA actually stuck?" | static first (`get_flow_detail`, `tile_info`) to know what *should* happen, `get_backend_status()` to confirm a live read is allowed, **`get_live_scan()` if the user scanned**, only then `aie_exec("target tile C R")` / `aie_exec("dma status")` / `aie_exec("bd")` |
| coloured tiles / switch mismatch / "what did scan show?" | `get_live_scan()` → **`live-scan-results`** skill → `get_flow_detail` / `tile_info` on named tiles |

**Rule:** never open with a hardware read. A live `dma status` is only interpretable once
you know from `get_flow_detail`/`tile_info` which channel, BD id and length that tile was
compiled to use — and `get_backend_status()` is what tells you the read will not simply be
refused.

**Do not** try to read `schedule_view.json` with the Read tool to answer these questions —
it is a large blob and every field above is already rendered for you.

**These tools return names and summaries, not file contents.** `tile_info` gives you the
kernel's *name*; `app_sources()` maps that name to the file and line defining it. For any
other on-disk artifact — the `.bcf` address map, `aie_control_config.json`, a per-tile
wrapper — switch to the **app-layout** skill for the absolute paths (anchored on the `path`
from `current_app()`) and open the file. **When** to open source rather than stop at the
schedule, and how to cite it, is **source-grounding** — the short version is that an answer
which never leaves the register dump is not finished.
