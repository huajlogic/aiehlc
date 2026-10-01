---
name: debug-ui-framework
description: AIEHLC schedule debug UI — schedule_debug_server daemon, schedule_view browser UI, aiegdb/aiemcp live debug, session provenance, sim/hw capability detection, and UI feature map. Read when working on debug UI, live board or simulator debug, the embedded LLM tab, or changes to schedule_view.py or schedule_debug_server.py.
---

# Debug UI Framework

## Entry points

| Resource | Role |
|----------|------|
| [src/tool/debug/README.md](../../src/tool/debug/README.md) | User guide, CLI, endpoints |
| [doc/design/aiegdb_live_debug_framework.md](../../doc/design/aiegdb_live_debug_framework.md) | Original design doc |
| [reference.md](reference.md) | Implementation notes moved from CLAUDE.md |
| [dbg_llm_skills/](../../src/tool/debug/dbg_llm_skills/) | Ten embedded-LLM plugin skills |

## Quick launch

```bash
# TilingLinalg bundle (sim or hw)
python3 src/tool/debug/schedule_debug_server.py aout/worklocal --open

# Single-app sim-only (raw-XAie or tiling sim)
python3 src/tool/debug/schedule_debug_server.py --app aout/worklocal --sim-only --open

# Bare multi-app daemon
python3 src/tool/debug/schedule_debug_server.py --app-root .
```

Build with live UI: `aiehlc.sh --prettydebug` (sim: build-only; launch via **Run** or `runsim.sh`).

## Core components

| File | Purpose |
|------|---------|
| `schedule_view.py` | Static + live HTML/JS (`host_schedule.html`, daemon-served JS) |
| `schedule_debug_server.py` | `http.server` daemon: run orchestration, `/grid`, LLM tab, MCP bridge |
| `aiegdb.py` | Scoped CLI over `aiedbg`; `COMMAND_SPEC` is the grammar source |
| `aiemcp.py` | MCP server wrapping in-process `AieGdb` |
| `aiediag.py` | Flow-aware DMA diagnosis via provenance JSONs |
| `xaiehost2provenance.py` | Static provenance for raw-XAie `host.cc` (no tiling bundle) |
| `debug_ui_mcp.py` | MCP server for UI state / panes / source manifest |

## Session states (read before quoting hardware)

Four states from `session_state()` / `backend_status.json`:

| State | Meaning |
|-------|---------|
| `none` | No Connect yet — do not treat board reads as current |
| `connected` | `/ping` passed |
| `attached` | Adopted an external run — prior board history unknown |
| `ran` | Started from this UI — only here may applog + live state be current |

Embedded LLM: read plugin skill `session-provenance` before any register or log claim.

## Related skills

| Task | Skill |
|------|-------|
| LLM context loss on retarget | debugui-llm-reset |
| Raw-XAie missing worklocal bundle | raw-xaie-sim-debug-bundle |
| Sim build must not launch sim | sim-build-run-separation |
| Live DMA stall triage | aiehwdmadebug (+ plugin `dma-stall-triage`) |
| HW performance counters | aiehwprofile |

## Feature reference

Detailed per-feature notes (daemon endpoints, UI behaviour, pitfalls) live in
[reference.md](reference.md). Read that file when editing a specific subsystem
rather than searching CLAUDE.md.

Sections: tools (aiediag, xaiehost2provenance, aiegdb, aiemcp), daemon (session,
app detection, run-state, sim-only, source grounding), browser UI (panes, device
map, LLM tab, source viewer, scan controls).
