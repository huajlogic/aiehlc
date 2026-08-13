<!-- Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: app-layout
description: Question -> ABSOLUTE PATH for the on-disk artifacts of the app currently loaded in the UI. Read BEFORE any Read / Grep / Glob aimed at the kernel's real algorithm source, the generated per-tile kernel wrapper, a .bcf symbol->address map, aie_control_config.json, aie_control.cpp, the three provenance JSONs (dfscheduleprovenancemap.json; dmaphopprovenacemap.json, misspelled on disk; routingprovenancemap.json), schedule_view.json, debugcache/code/tile_c<C>_r<R>*.cc, router_soln.json, or the host ELF. Two structural traps make a cwd-relative search wrong: the app is usually NOT under cwd (the aiehlc_aiesim repo root), so a Glob from there quietly returns another app's files or nothing; and the path you are handed is the BUNDLE (app_dir/worklocal), not the app root, with Work/ a sibling of it - this file gives the app_dir / bundle_dir / work_dir / elf inverse plus the per-question file table. Also the gotchas that route you to the wrong copy: a compiler <label> is NOT <col>_<row>, top-level kernel.cc and *.bcf are first-core-only on a multi-core design, bundle host.cc is generated (aie_control.cpp verbatim) not hand-written, aiehlc-built apps have no Work/ at all, and the bundle can be regenerated mid-conversation. Opening files only: "which app is loaded?" as a tool call belongs to debugui-tools - this skill starts from that answer and re-resolves every path when the `App:` context field changes.
---

# Where the app lives, and which file answers which question

Source of truth: `schedule_debug_server.py` (`app_paths`:1563, `_resolve_work_dir`:260,
`_resolve_default_elf`:280, `class App`:370, `class AppRegistry`:469, `select_app`:673),
`work2provenance.py` (`work_to_provenance`:1270, `collect_tile_artifacts`:1212),
`schedule_view.py` (`build_view`:1692, `write_code_cache`:7438).

## Step 0 — resolve the app before you open anything

Your cwd is the **aiehlc_aiesim repo root** (its absolute path is stated in the
"Where this app lives on disk" block of your system prompt). **The loaded app is usually not
under it** — a second repo checked out alongside it (e.g. `../naiebaremetal/example/*/`)
is a normal source of apps. Never `Glob` from cwd for these files.

Authoritative sources, in this order. The first two need no path knowledge at all — do not
start at step 3, and never Glob to find the app.

1. **The `App:` field on the context line of the message you just received.** The daemon
   injects `[context] Backend: … Session: … App: <label> at <app_dir> (Work/: <work_dir>).`
   into *every* message (`_llm_backend_context`). The system prompt's "Where this app lives"
   block is only sent on turn 1 — **if the two disagree, the `App:` line wins**, because
   the daemon's `select_app` re-resolves workdir/ELF/startcol/aie_version on an app switch
   and the system prompt is never re-sent.
2. **`mcp__debugui__current_app()`** — one call, no path required. Returns the current app's
   JSON dict: `{id, label, path, mtime, current, has_ui_config, has_backend_status, has_sim,
   has_hw}` (`App.info`). **`path` is the *bundle*, not the app root** — apply the same
   inverse below to get `app_dir`. `mcp__debugui__list_apps()` answers "which apps exist":
   one text row per app, `*` marking the current one, columns `id`, capabilities
   (`sim`/`hw`, or `view-only`), `path`. Both go to the daemon's `/apps`, so they are the
   freshest source; both degrade to a `daemon not reachable …` string when
   `DEBUGUI_SERVER_URL` is unset, in which case fall back to source 1.
   Switching apps is the **user's** action (the UI app picker / `POST /apps/select`) — you
   are not granted `select_app`, so do not try to call it; ask the user instead.
3. **`<bundle_dir>/backend_status.json`**, key `app_paths` — the full set `{app, app_dir,
   bundle_dir, work_dir, elf}`, rewritten by `_write_backend_status`. Read it with the Read
   tool once you know the bundle from step 1 or 2; this is the only place `work_dir` and
   `elf` come pre-resolved. Note `mcp__debugui__get_backend_status()` does **not** return
   `app_paths` — it carries backend/session fields only.

Given `app_dir` (source 1) the bundle is `<app_dir>/worklocal` if that directory exists,
else `<app_dir>` itself. Given the bundle (source 2) the app root is the inverse, exactly as
`app_paths` computes it: `app_dir = dirname(bundle) if basename(bundle) == "worklocal"`,
else `bundle`.

## The four locations

| # | Location | What is in it |
|---|----------|---------------|
| 1 | `app_dir` — **the app root** | Hand-written sources (`src/`), `build.sh`, `Makefile`, the host ELF, `AIECompiler.log`, `Work/`, `worklocal/` |
| 2 | `bundle_dir` = `app_dir/worklocal` — **the provenance bundle** | Everything the static debug tools read: the three provenance JSONs, `schedule_view.json`, `host.cc`, `kernel.cc`, `kernels/`, `debugcache/`, `backend_status.json`, `llm_*.log` |
| 3 | `work_dir` = `app_dir/Work` — **aiecompiler output**, sibling of the bundle | `ps/c_rts/aie_control_config.json`, `ps/c_rts/aie_control.cpp`, `aie/<label>/src/<label>.cc`, `aie/<label>/scripts/<label>.bcf`, `reports/`, `temp/router_soln.json` |
| 4 | `elf` — the host ELF | naiebaremetal: `app_dir/vek385.elf`; aiehlc: `bundle_dir/build/host` |

**The bundle is NOT the app root.** It is generated output — a flat directory of copies and
derived JSON. Grepping it for "the kernel" gives you a *machine-generated wrapper*, not the
user's algorithm. `App` ids are derived from the bundle's parent (`class App.__init__`:
`id = parent if basename == "worklocal"`), which is exactly why the parent is the app.

`work_dir` may be empty (`""`). aiehlc-built apps (e.g. `aout/worklocal`) have no `Work/`
at all — their compiler passes emit the provenance JSONs directly. In that case items in
row 3 below do not exist; say so instead of hunting.

## Question -> file

Paths are relative to `bundle_dir` / `work_dir` / `app_dir` as marked.

Before hand-resolving a source path, try `mcp__debugui__app_sources()` — it returns the
app's hand-written files already grouped, plus the `file:line` defining each kernel the
schedule names, which is faster and less error-prone than the table for the "where is this
kernel?" case. This table remains the authority for everything it does not cover (the
provenance JSONs, `Work/` artifacts, per-tile caches) and for cross-checking what it
returns. **`source-grounding`** covers when to open these files at all and how to cite them.

| Question | Open |
|---|---|
| What algorithm does the kernel on tile (C,R) run? | `app_dir/src/*.cc` (the human source), and `bundle_dir/kernels/<C>_<R>/src/…` — `work2provenance` copies each `#include "*.cc"` dependency alongside the wrapper (`_copy_kernel_with_includes`) |
| The generated kernel wrapper for tile (C,R) | `bundle_dir/kernels/<C>_<R>/kernel.cc` (copy of `work_dir/aie/<label>/src/<label>.cc`; its line 2 comment names the original) |
| Generated kernel wrapper, single-core / fallback | `bundle_dir/kernel.cc` — copy of the **first** mapped core only (`collect_kernel_src` + `work_to_provenance`) |
| Buffer symbol -> tile address for tile (C,R) | `bundle_dir/kernels/<C>_<R>/tile.bcf` — lines `_symbol <name> 0xADDR`; `_reserved DMb 0x0 0x<n>` is `win_base` |
| Buffer map, single-core / fallback | `bundle_dir/<label>.bcf` (e.g. `4_1.bcf`, `0_0.bcf`, `aieml.bcf`) — `schedule_view.find_bcf` just globs `*.bcf` in the bundle and takes the first |
| HW geometry, GMIOs, kernel->tile mapping, `hw_gen`, `startcol` | `work_dir/ps/c_rts/aie_control_config.json` -> `aie_metadata.{driver_config,GMIOs,TileMapping.AIEKernelToTileMapping,graphs}` |
| BD/lock programming as the compiler emitted it | `work_dir/ps/c_rts/aie_control.cpp` — and `bundle_dir/host.cc` is that file verbatim plus a generated `host_canonicalized()` wrapper appended |
| Per-tile DMA channels, BD chains, flow summary, `win_base` | `bundle_dir/dfscheduleprovenancemap.json` — keys `version, startcol, aie_gen, module_attrs, tiles[] {col,row,type,dma_channels}, flow_summary, load_kernel_group, win_base` |
| Routing hops for a flow (producer -> hop -> consumer tiles) | `bundle_dir/dmaphopprovenacemap.json` (filename is misspelled on disk — `provenace`, no second `n`; copy it literally) — keys `version, startcol, aie_gen, module_attrs, communication_paths[] {id, direction, data, stages[]}` |
| Stream-switch / shim mux-demux configuration | `bundle_dir/routingprovenancemap.json` — keys `version, startcol, aie_gen, module_attrs, routing_groups` |
| Everything the UI renders (grid + per-tile hi/mid/lo) | `bundle_dir/schedule_view.json` — top-level `grid, tiles, comm_paths, flow_summary, supply_demand, buffers, kernel, bcf, dfschedule_ir, invariant_checks, module_attrs, global, source` |
| Which host.cc lines implement tile (C,R) / channel X | `bundle_dir/debugcache/code/tile_c<C>_r<R>.cc` and `tile_c<C>_r<R>_<dir><n>.cc` (e.g. `tile_c4_r4_mm2s0.cc`) — written by `write_code_cache`; the same path is in `schedule_view.json` as the tile's/channel's `code_file` |
| Absolute path of a tile's own kernel.cc / .bcf, already resolved | `schedule_view.json` -> `tiles[i].kernel.path`, `tiles[i].bcf.path` (`mcp__debugui__tile_info` does *not* surface these) |
| Raw router solution, compiler + DMA/lock reports | `work_dir/temp/router_soln.json`, `work_dir/reports/{compiler_report.json,dma_lock_report.json}` |
| Which source an **aiehlc** app was built from | `bundle_dir/app_source.txt` — one absolute path, written by `aiehlc.sh` from `--runtime-source-file`. The only record of it: `app_dir` is `aout/`, which holds generated code only. Fallback for older builds: `HOST_SRC="…"` in `sim_config.sh` |
| Which devices / sim script this app can run | `bundle_dir/debug_ui_config.json` (`extra_devices[]`), optional |
| Run profile + session/app state as the daemon sees it now | `bundle_dir/backend_status.json` |

## Gotchas that will send you to the wrong file

- **`<label>` != `<col>_<row>`.** `work_dir/aie/4_1/` is a *compiler* label; the kernel it
  holds can run on physical tile (4,4). `collect_tile_artifacts` resolves that and names the
  bundle directory `kernels/<col>_<abs_row>/`. Verified case: `example/stream` has
  `Work/aie/4_1/src/4_1.cc` -> `worklocal/kernels/4_4/kernel.cc`. Index by the physical
  `(col,row)` you get from the UI, never by the label.
- **Top-level `bundle_dir/kernel.cc` and `bundle_dir/*.bcf` are first-core-only.** On a
  multi-core design (`example_oob_4x4` has 16 `kernels/<c>_<r>/` dirs) they are the wrong
  tile for 15 of them. Prefer `kernels/<C>_<R>/`.
- **`host.cc` in the bundle is not hand-written host code.** It is `aie_control.cpp` plus a
  generated wrapper; blame the compiler, not the user, for what is in it.
- **The bundle can be regenerated under you.** `_try_generate_worklocal` reruns
  `work_to_provenance` + `build_view` + `write_code_cache` when
  `Work/ps/c_rts/aie_control_config.json` is newer than `worklocal/schedule_view.json`.
  Re-Read rather than trusting a path you cached several turns ago.
- **App switch invalidates everything.** After the user switches apps (`select_app` in the
  daemon), `bundle_dir`, `elf`, `startcol` and `aie_version` all change. Check the `App:`
  field on each message, or re-call `mcp__debugui__current_app()`; if it moved, discard
  cached paths *and* cached tile coordinates.

## Two producer flows, same bundle shape

`class App` identifies an app purely by "a directory containing `schedule_view.json`", so
both flows are read identically:

- **aiehlc** (this repo) — passes emit the provenance JSONs straight into the bundle.
  Example: `aout/worklocal` — has `aieml.bcf`,
  `build/host`, no `Work/`, no `kernels/`.
- **aiecompiler / naiebaremetal** — `work2provenance.py` derives the bundle from `Work/`.
  Examples: `example/stream/worklocal` (1 core, in this repo) and
  `../naiebaremetal/example/example_oob_4x4/worklocal` (16 cores, in a sibling repo —
  plus `debug_ui_config.json`).

Do not use `host_schedule.html` to tell the flows apart — `schedule_view.py` writes it into
both bundles. The discriminators are the ones above: aiehlc has `build/host` and no `Work/`
or `kernels/`; aiecompiler has `kernels/<C>_<R>/` and a sibling `Work/`.

Check for the file before quoting it — `has_ui_config` / `has_backend_status` /
`has_sim` / `has_hw` differ per app (`App.caps`), and so do the optional bundle files.
