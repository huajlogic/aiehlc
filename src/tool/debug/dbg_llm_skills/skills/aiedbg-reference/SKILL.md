<!-- Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: aiedbg-reference
description: PRECEDENCE - this skill owns the UNDERLYING `aiedbg` tool and its local clone at <clone>; every other debug skill stops at aiegdb's wrapper, this one goes beneath it. Read when you need a raw aiedbg command or flag that aiegdb does NOT wrap (`scan cores`, `scan dma --performance`, `reg read-mmio`, `mem read`, `callstack layers/stream`, `aiedbg-deploy`), when you need a NAMED REGISTER or its numeric offset (`reg lookup` - offline, needs no board, and on this install `-d` CRASHES it with AttributeError so you must spell it `--device-type`), when aiediag's decode disagrees with what the board reports and you must settle it against aiedbg's own register tables, or when the device is NOT this repo's default `pal` (vek280 / vck190 / vek385 have different geometry AND different core-status offsets, and only vek385/pal have named registers or event decoding at all). Carries the question-to-document routing table for the clone's ~2600 lines of docs (CLAUDE.md, architecture.md, aiedbg-vek385.md, aiedbg-vek280.md, README.md, docs/manual-deployment-steps.md, docs/testkernel-debugging-scenarios.md, docs/aie-debug-framework/*), the TCP-vs-XSDB backend split with the VEK385-is-XSDB-only constraint, the device matrix straight from device_config.py, the tile-to-MMIO formula, and which README commands (`lock`, `debug`, `routing`) are documented but have no subparser and will simply fail. An index into another repo: aie_exec spelling is aiegdb-console's, symptom-to-root-cause procedure is dma-stall-triage's, permission to read the board at all is session-provenance's.
---

# aiedbg — the tool underneath aiegdb

**Audience: both.** (a) The embedded debug assistant spawned by
`schedule_debug_server.py` for the browser UI's LLM tab, and (b) ordinary Claude Code
sessions in `aiehlc_aiesim`. Both have file tools, so every "go read <path>" below is
actionable. The embedded assistant reaches aiedbg only *indirectly*, via
`mcp__aiegdb__aie_exec` passthrough — no shell — so use this file to decide **what to ask
for**, and read the clone's source when a decode is in doubt.

## 1. Where it lives — resolve it, do not assume it

**The clone path differs per machine. Never hardcode one.** Every `<clone>` below is a
placeholder you must resolve first, in this order:

1. **Your context.** The system prompt's "Where this app lives on disk" block carries an
   `aiedbg clone:` line, and `mcp__debugui__get_backend_status()` returns the same value
   under `aiedbg_paths.src`. This is the daemon's own resolution — prefer it.
2. **The repo's own clone.** `src/tool/debug/ensure_aiedbg.py` clones the repo to
   `<aiehlc_aiesim>/thirdparty/aiedbg` on first run of the debug UI (the daemon calls it at
   startup unless `--skip-aiedbg-bootstrap`), honouring `$AIEHLC_AIEDBG_SRC` as an override.
   If it is missing, that bootstrap has not run — running
   `python3 src/tool/debug/ensure_aiedbg.py` clones and pip-installs it.
3. **A pre-existing install elsewhere.** If the machine was set up against a clone outside
   the repo, its location is recorded in the installed dist's `direct_url.json`:
   `python3 -c "import importlib.metadata as m;print(m.distribution('aiedbg').read_text('direct_url.json'))"`

Confirm a candidate by checking `<clone>/CLAUDE.md` exists — that is the daemon's own test.

- **Executable:** `which aiedbg`
- **Installed package (code only, NO `.md` files):**
  `python3 -c "import aiedbg,os;print(os.path.dirname(aiedbg.__file__))"`

The install is a **non-editable copy**: site-packages is a *snapshot* of `<clone>/aiedbg/`
and can drift. Read the clone for docs and intent; read site-packages to explain what the
binary **actually just did**. The docs exist only in the clone.

## 2. Question → document routing table

| You need | Read (absolute path) |
|---|---|
| One-page orientation: modules, device matrix, connection env vars, key diagnostic registers | `<clone>/CLAUDE.md` |
| How the two backends actually work end to end; the proxy/JTAG topology diagrams; callstack architecture; per-device PC/SP addressing; what is *not* implemented yet | `<clone>/architecture.md` |
| A VEK385/PAL-flavoured 7-phase debug procedure; the largest raw register list (locks, stream switch, shim DMA status/current-addr/remaining-count); named-register names | `<clone>/aiedbg-vek385.md` |
| Same procedure for VEK280 (legacy, numeric addresses only) plus the TCP↔XSDB fallback troubleshooting ladder and `aiedbg-xsdb` alias pattern | `<clone>/aiedbg-vek280.md` |
| Install, the copy-paste command menu per method, XSDB speed expectations (`lock*` reads 4,864 registers → 2-5 min), which commands are offline | `<clone>/README.md` |
| Board bring-up by hand: cluster-ping, power cycle, hw_server, `tar` numbers, `device program`, `dow -force`, the 3-console sequencing | `<clone>/docs/manual-deployment-steps.md` |
| What a *known* bug looks like in registers — injected hang / memory violation / DMA corruption / early exit, each with expected `core_status_reg` and PC evidence | `<clone>/docs/testkernel-debugging-scenarios.md` |
| The formal CLI contract: global options, per-command syntax, JSON output shapes, `aieshow` options | `<clone>/docs/aie-debug-framework/aiedbg-cli-spec.md` |
| The TCP wire protocol: frame layout, 4 opcodes, error struct, and the tile→MMIO address formula | `<clone>/docs/aie-debug-framework/aiedbg-low-level-api.md` |

Code, when the docs are not enough: `aiedbg/__main__.py` (argparse = the real grammar),
`device_config.py`, `regaddr.py`, `event_decoder.py`, `core_status.py`, `dma_status.py`,
`xsdb_backend.py`, `baremetal.py`, `callstack/`.

## 3. Facts worth inlining

### Backend split
Two independent ways in, same JSON out:

- **TCP / baremetal** — `-t baremetal://HOST[:PORT]`, port 5555, needs a debug-server ELF
  running on the board's second APU core. Usually reached through a farm proxy
  (`AIEDBG_PROXY_HOST` / `AIEDBG_PROXY_PORT`, e.g. 15555). Length-prefixed binary
  protocol v1.2, opcodes `0x01` device info, `0x02` reg read, `0x03` reg write,
  `0x04` mem read (≤256 words).
- **XSDB / JTAG** — `-t xsdb://HOST[:PORT]` (3121), reads registers straight over JTAG
  through an existing `hw_server`; no board-side firmware. **XSDB requires an explicit
  `-d DEVICE`** — `__main__.py` refuses with "XSDB backend requires explicit device
  specification" otherwise.
- **VEK385 is XSDB-only**: the debug-server ELF is not supported there
  (CLAUDE.md, architecture.md, README.md all state this). This repo's target is an
  `xsdb://…:3121` URL, so you are on the XSDB path.

### Device matrix (verified against `aiedbg/device_config.py`)

| `-d` | Tiles (cols × rows) | reg_dir | core status offset | Named regs + event decode |
|---|---|---|---|---|
| `vck190` | 50 × 9 | none | `0x00032004` | no |
| `vek280` | 38 × 11 | none | `0x00032004` | no |
| `vek385` | 38 × 7 | `aie2ps` | `0x00038004` | yes |
| `pal` | 12 × 7 | `aie2ps` | `0x00038004` | yes |

"Legacy" (`vck190`, `vek280`) = numeric hex addresses only. "Enhanced"
(`vek385`, `pal`) = a register-name database ships with the package, so names resolve and
event-status registers are decoded to bit→event-name lists. **This repo defaults to
`pal`** (`aiegdb.py --device` default), i.e. the enhanced path.
`-d` also accepts `DEVICE-BOARD` (`vek280-4`); the prefix before the dash is the device.

### Named registers and register discovery — the distinguishing feature

`reg lookup SCOPE REGISTER` fuzzy-matches a register name and prints its offset. It is
handled **before any backend connection is opened** (`_cmd_reg_lookup`, "offline, no
backend"), so it works with no board, no session, and no target.

**Gotcha, reproduced on this install:** `aiedbg -d pal reg lookup …` dies with
`AttributeError: 'Namespace' object has no attribute 'device_type'` (`__main__.py:572`
reads `args.device_type`, but `-d` populates `args.device_spec`). The hidden
backward-compat alias works:

```
aiedbg --device-type pal reg lookup core status
aiedbg --json --device-type pal reg lookup mem dma
```

Scopes are fuzzy too; they match module names such as `aie2ps_core_module`,
`aie2ps_memory_module`, `aie2ps_mem_tile_module` — `core`, `mem`, `tile`, `shim` all hit.
The backing tables are `<clone>/aiedbg/regaddr_data/*.json` (mirrored at
`<clone>/device/aie2ps/`): `aie2ps{tile,mem,shim}.json`,
`aie2ps{tile,shim}dmastatus.json`, plus event-name maps `core_events.json`,
`core_mem_module_events.json`, `memtile_events.json`, `shimtile_events.json`. Grep them to
answer "what is at offset 0x…?" with no board.

### CLI command groups (from `__main__.py`'s subparsers, not from prose)

`tile list` · `scan cores|dma` (`--performance` `--bandwidth` `--timing`) ·
`reg read|write|read-mmio|write-mmio|lookup` · `mem read COL ROW ADDR NWORDS` (≤256) ·
`show cores|dmaevent|dmastatus` (`-i` interval, default 5 s) ·
`callstack show|host|tiles|layers|stream --work-dir Work/`.
Deprecated aliases still present: `callstack-legacy`, `advanced-callstack`.
Global: `--json` (always use it for machine parsing), `-t/--target`, `-d/--device`.

Tile→MMIO: `MMIO = 0x20000000000 + (col << 25) + (row << 20) + offset`
(so `0x20000332004` = col 0, row 3, offset `0x32004`) — that is what `read-mmio` takes.

**Documented but not real:** README lists `lock status|deadlock|contention|dependency`,
`debug analyze|comprehensive|correlate|report` and `routing parse|flows|kernels|…` as
[WIP]. There is **no subparser for any of them** in `__main__.py` — they will fail on
argument parsing. Do not suggest them.

**Destructive:** `reg write` / `reg write-mmio` are immediate and irreversible.
`show *` never exits (aiegdb blocks those three by name), and array-wide `scan` holds the
JTAG link for the whole sweep — prefer a scoped read.

## 4. Relationship to this repo (and how to settle a decode dispute)

- `src/tool/debug/aiegdb.py` shells out to
  `["aiedbg", "-d", self.device] + ["--target", target] + args` for every raw
  passthrough (`_passthrough`, ~line 567). Special case: `callstack` is re-routed to
  `python -m aiedbg.callstack.unified_cli` directly, because aiedbg's top-level
  dispatcher rewrites `xsdb://` to `baremetal://` and you eat a ~120 s TCP timeout.
- `src/tool/debug/aiediag.py` keeps its **own**
  offset tables — `DMA_STATUS_OFFSETS` (~L41), `CORE_PC_OFFSET` (~L50),
  `CORE_STATUS_OFFSET` / `CORE_CONTROL_OFFSET` (~L58), `BD_BASE_STRIDE` / `BD_LEN_MASK`
  (~L99), the `*_EVENT_IDS` maps (~L129-173) — and does the decoding itself. It only uses
  aiedbg as a transport: `run_aiedbg_reg_read` (~L530) runs
  `aiedbg --json [--target T] [--device D] reg read COL ROW 0xADDR` and takes
  `value_hex`/`value` out of the JSON.

**So when aiediag's decode looks wrong, the tables are the suspect, not the wire.** The
resolution path, all offline:

1. Read the raw value out of the `[registers read]` appendix that `run_line` prints — that
   is aiedbg's own number, undecoded.
2. Ask aiedbg what that offset *is*: `aiedbg --device-type pal reg lookup <scope> <name>`,
   or grep `<clone>/aiedbg/regaddr_data/*.json` for the offset.
   Worked example: aiediag's `DMA_STATUS_OFFSETS["core"]["mm2s"] = 0x1DF10` matches
   `aie2ps_memory_module dma_mm2s_status_0 = 0x0001DF10`. Agreement confirmed.
3. For bit meanings, read `<clone>/aiedbg/dma_status.py`, `core_status.py`,
   `event_decoder.py` and compare against `aiediag.decode_dma_status` /
   `decode_core_status` / `decode_shim_event_status`.
4. Only then call it a bug — and say which side you believe and why.

Related trap, owned by dma-stall-triage: aiediag can decode a register **offset** as if it
were the **value**, fabricating `BD_UNAVAIL`/`BD_INVALID`. Step 1 is how you catch it.
