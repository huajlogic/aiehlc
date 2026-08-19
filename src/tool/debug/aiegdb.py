#!/usr/bin/env python3
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""aiegdb - a GDB-like scoped CLI frontend over aiedbg for live AIE debug.

A stateful, interactive console that keeps a *current scope*
(partition -> tile -> channel). A `target` command descends a level, e.g.

    partition(startcol=3)> target tile 0 0
    partition(startcol=3)/tile(0,0)> target channel mm2s0
    partition(startcol=3)/tile(0,0)/mm2s0> dma status

Commands default to the current scope; tile scope auto-injects col/row, channel
scope auto-injects col/row + direction/channel. Decoding/offsets come from
aiediag.py (imported as a library); raw register access shells out to `aiedbg`.

Design reference: doc/design/live_debug_framework.md
"""

import argparse
import json
import os
import re
import subprocess
import sys

# Import aiediag as a library (offsets, reg read via aiedbg --json, decoders,
# provenance, startcol). aiediag.py lives in the same dir (src/tool/debug/); it guards
# main() behind __main__, so importing it has no side effects. (Same shim as
# schedule_debug_server.py:48-52.)
_THIS_DIR = os.path.dirname(os.path.abspath(__file__))
if _THIS_DIR not in sys.path:
    sys.path.insert(0, _THIS_DIR)
import aiediag  # noqa: E402

try:
    import readline  # noqa: F401  (enables line editing + history)
    _HAVE_READLINE = True
except ImportError:
    _HAVE_READLINE = False

HISTORY_FILE = os.path.expanduser("~/.aiegdb_history")

# Framing marker for --server mode: a daemon writes a command to stdin and reads
# stdout until a line starting with this marker, whose remainder is the current
# prompt/scope. The record-separator prefix (\x1e) never appears in normal output.
_SERVER_MARKER = "\x1e@AIEGDB@ "

# ── Machine-readable command grammar ──────────────────────────────────────────
# Mirrors _dispatch / _tile_cmd / _channel_cmd. Exists so front-ends (the browser
# console's autocomplete, the MCP `aie_commands` tool) can offer scope-correct
# suggestions without hand-copying the grammar into JS, where it would silently
# drift from this file. `spec` prints it as JSON; `_commands` renders `?` from it,
# so a command added here shows up in every front-end at once.
#
#   args        arg template shown after the name in a suggestion
#   intrusive   WRITES to hardware — front-ends must flag these before firing
#   passthrough forwarded verbatim to `aiedbg` rather than decoded here
#   blocking    live/TUI command that never exits on its own. Fatal in the browser
#               console: _passthrough blocks for passthrough_timeout (120s) while
#               the daemon gives up reading at 60s and DISCARDS the aiegdb
#               subprocess, losing scope and leaving the child holding the JTAG
#               link. Front-ends must refuse or hard-warn these.
#   slow        array-wide; can monopolise the JTAG link for a long time
#   needs_work_dir  aiedbg requires --work-dir, which aiegdb does not pass
def _cmd(name, summary, args="", aliases=(), intrusive=False, passthrough=False,
         blocking=False, slow=False, needs_work_dir=False):
    return {"name": name, "summary": summary, "args": args,
            "aliases": list(aliases), "intrusive": intrusive,
            "passthrough": passthrough, "blocking": blocking, "slow": slow,
            "needs_work_dir": needs_work_dir}


COMMAND_SPEC = {
    # Available in every scope (handled at the top of _dispatch).
    "universal": [
        _cmd("target tile", "descend to a tile scope", "<col> <row>",
             aliases=("tar tile", "tile")),
        _cmd("target channel", "descend to a channel scope", "<dir_ch>",
             aliases=("tar channel", "channel")),
        _cmd("target partition", "return to partition scope, set its params",
             "[startcol=N] [target=..] [device=..] [aie=5|2ps]",
             aliases=("tar partition",)),
        _cmd("up", "pop one scope level", aliases=("..",)),
        _cmd("top", "jump straight back to partition scope"),
        _cmd("where", "breadcrumb + phys_col/row + target/device",
             aliases=("info", "pwd")),
        _cmd("set", "change a partition parameter in place",
             "startcol N | target .. | device .. | aie .."),
        _cmd("?", "list only the current scope's commands",
             aliases=("commands", "cmds")),
        _cmd("help", "full command reference"),
        _cmd("spec", "print this command grammar as JSON"),
        _cmd("exit", "leave the console", aliases=("quit", "q")),
    ],
    # Partition scope: no tile is selected, so aiegdb decodes nothing here —
    # everything is an aiedbg passthrough, discovered at runtime (see below).
    "partition": [],
    # Tile scope: col/row are auto-injected into the decoded commands.
    "tile": [
        _cmd("dma", "decoded DMA status for one channel", "<dir_ch>"),
        _cmd("pc", "core PC resolved to source via the line map"),
        _cmd("status", "decoded core status (enable/reset/stall)",
             aliases=("core", "core status")),
        _cmd("event", "memory-module DMA event-status registers",
             aliases=("event mem",)),
        _cmd("core event", "full core-module event list (0x34200..; core tiles)",
             aliases=("core events", "event core")),
        _cmd("channels", "list this tile's DMA channels", aliases=("chans",)),
        _cmd("log", "dump the kernel klog buffer (core tiles only)",
             aliases=("klog",)),
    ],
    # Channel scope: col/row AND direction/channel are auto-injected.
    "channel": [
        _cmd("dma status", "decoded DMA status register",
             aliases=("status", "dma")),
        _cmd("bd", "BD chain from provenance JSON + live HW lengths"),
        _cmd("event", "per-channel DMA start/finish/error events"),
        _cmd("dma counter", "AIE performance counters (read-only)",
             aliases=("counter",)),
        _cmd("dma counter setup", "arm a perf counter — WRITES to hardware",
             "[finished|started]", intrusive=True),
        _cmd("log", "dump the kernel klog buffer (core tiles only)",
             aliases=("klog",)),
    ],
}

# ── aiedbg passthrough grammar, discovered at runtime ─────────────────────────
# Anything aiegdb does not decode is forwarded verbatim to `aiedbg`, so *aiedbg*
# is the authority for those commands — hand-copying them here would drift the
# moment aiedbg is updated. Instead we parse the "Available Commands:" block of
# `aiedbg --help`, which is already name + args + summary per line:
#
#   reg read COL ROW OFFSET       Read register via tile coordinates or name
#   show {cores,dmaevent,dmastatus}   Real-time visualizations (...)
#   callstack show COL ROW        Enhanced GDB-style call stack (requires --work-dir)
#
# `--help` never touches hardware, so this is safe to run with no board attached.
# If aiedbg is missing we return nothing rather than inventing entries: without
# aiedbg those commands genuinely cannot run, so suggesting them would be a lie.
_AIEDBG_SPEC_CACHE = None

# Tile/channel scope auto-injects phys_col/row for exactly these aiedbg
# sub-commands (see _tile_cmd: `reg` guarded on read|write, and any `mem <sub>`,
# and callstack show/layers/stream which append logical col/row),
# so their COL/ROW placeholders must be dropped from the suggested template.
_COORD_INJECTED = ("reg read", "reg write", "mem read",
                   "callstack show", "callstack layers", "callstack stream")

# Safety must fail CLOSED. _blocked_tui() derives its refusal set from the parsed
# help, so if aiedbg is off PATH or the "Available Commands:" wording changes,
# discovery returns nothing and the refusal would silently vanish — reinstating
# the exact hang it exists to prevent. These names are checked in addition to
# whatever discovery finds, so the guard survives a broken parse.
_KNOWN_BLOCKING = ("show cores", "show dmaevent", "show dmastatus")

# Corrections for facts a one-line help summary cannot express. Kept as a small
# override table rather than a full curated copy, so aiedbg stays the source of
# truth for *which* commands exist and this only refines how they are presented.
#   - callstack --work-dir is auto-injected from self.work_dir (set by daemon or
#     AIEMCP_WORK_DIR env var); at tile scope col/row are also auto-filled.
#   - `show` grids take a refresh interval.
#   - `mem read` caps nwords at 256.
# Deliberately NOT surfaced: `scan --performance/--bandwidth/--timing`. They are
# in aiedbg's parser but ignored on the XSDB backend and raise ModuleNotFoundError
# on baremetal (aiedbg.dma_performance is not shipped). Do not add them.
# Commands that need --work-dir auto-injected (hidden from suggestions).
_NEEDS_WORK_DIR = {
    "callstack show", "callstack host", "callstack tiles",
    "callstack layers", "callstack stream",
}

_AIEDBG_ARG_OVERRIDES = {
    "show cores":       "[-i <sec>]",
    "show dmaevent":    "[-i <sec>]",
    "show dmastatus":   "[-i <sec>]",
    "mem read":         "<col> <row> <addr> <nwords 1-256>",
    "callstack show":   "[col] [row]",
    "callstack host":   "",
    "callstack tiles":  "",
    "callstack layers": "[col] [row]",
    "callstack stream": "[--enhanced] [col] [row]",
}


def _parse_aiedbg_help(text):
    """Extract command entries from the 'Available Commands:' block of aiedbg --help."""
    out = []
    lines = text.splitlines()
    try:
        start = next(i for i, l in enumerate(lines)
                     if l.strip().lower() == "available commands:")
    except StopIteration:
        return out
    for line in lines[start + 1:]:
        if not line.strip():
            break                      # blank line ends the block
        if not line.startswith(" "):
            break                      # a new unindented section heading
        m = re.match(r"^\s{2,}(\S.*?)\s{2,}(\S.*)$", line)
        if not m:
            continue
        sig, summary = m.group(1).strip(), m.group(2).strip()
        # `show {cores,dmaevent,dmastatus}` is three commands on one line.
        brace = re.search(r"\{([^}]*)\}", sig)
        sigs = ([sig[:brace.start()] + alt + sig[brace.end():]
                 for alt in brace.group(1).split(",")] if brace else [sig])
        for s in sigs:
            toks = s.split()
            # Placeholders are the SHOUTY tokens (COL, ROW, MMIO_ADDR, NWORDS).
            name = " ".join(t for t in toks if not t.isupper())
            args = " ".join("<" + t.lower() + ">" for t in toks if t.isupper())
            if not name:
                continue
            low = summary.lower()
            args = _AIEDBG_ARG_OVERRIDES.get(name, args)
            out.append(_cmd(
                name, summary, args, passthrough=True,
                # startswith, not equality: `reg write-mmio` writes too.
                intrusive=any(t.startswith("write") for t in name.split()),
                # aiedbg words its live TUI grids "Real-time …" / "Live … grid".
                blocking=("real-time" in low or low.startswith("live")),
                slow=name.startswith("scan"),
                needs_work_dir=name in _NEEDS_WORK_DIR))
    return out


_AIEDBG_ARGHELP_CACHE = {}


def _parse_positionals(text):
    """[{name, desc, values}] from the 'positional arguments:' block of a sub-help.

    An arg template like `<scope> <register>` says nothing about what to type.
    aiedbg's sub-help does — either as explicit `{a,b,c}` choices or as a
    comma-list inside the description, e.g.
        scope   tile type or module name (shim, tile, mem, core, ...)
    """
    out = []
    lines = text.splitlines()
    try:
        start = next(i for i, l in enumerate(lines)
                     if l.strip().lower() == "positional arguments:")
    except StopIteration:
        return out
    for line in lines[start + 1:]:
        if not line.strip() or not line.startswith(" "):
            break
        m = re.match(r"^\s{2,}(\S+)\s{2,}(\S.*)$", line)
        if not m:
            continue
        name, desc = m.group(1).strip(), m.group(2).strip()
        values = []
        brace = re.match(r"^\{(.*)\}$", name)
        if brace:
            values = [v.strip() for v in brace.group(1).split(",") if v.strip()]
            name = "choice"
        else:
            # A parenthesised group is only a value list if it actually has
            # commas — "(0-based)" and "(1-256)" are prose, not choices.
            for grp in re.findall(r"\(([^)]*)\)", desc):
                if "," in grp:
                    values = [v.strip() for v in grp.split(",")
                              if v.strip() and v.strip() != "..."]
                    break
        out.append({"name": name, "desc": desc, "values": values})
    return out


def arg_help(name, refresh=False):
    """Per-argument help for one aiedbg command, from `aiedbg <name> --help`.

    Fetched lazily (only when a front-end actually needs to complete an
    argument) and cached, so page render never pays for N subprocess calls."""
    if name in _AIEDBG_ARGHELP_CACHE and not refresh:
        return _AIEDBG_ARGHELP_CACHE[name]
    args = []
    if re.match(r"^[a-z][a-z0-9 _-]*$", name):        # never shell a typed string
        try:
            p = subprocess.run(["aiedbg"] + name.split() + ["--help"],
                               capture_output=True, text=True, timeout=15)
            args = _parse_positionals(p.stdout or "")
        except (OSError, subprocess.SubprocessError):
            args = []
    _AIEDBG_ARGHELP_CACHE[name] = args
    return args


def discover_aiedbg_spec(refresh=False):
    """aiedbg's own command list, parsed from `aiedbg --help` (cached per process)."""
    global _AIEDBG_SPEC_CACHE
    if _AIEDBG_SPEC_CACHE is not None and not refresh:
        return _AIEDBG_SPEC_CACHE
    try:
        p = subprocess.run(["aiedbg", "--help"], capture_output=True,
                           text=True, timeout=15)
        _AIEDBG_SPEC_CACHE = _parse_aiedbg_help(p.stdout or "")
    except (OSError, subprocess.SubprocessError):
        _AIEDBG_SPEC_CACHE = []        # no aiedbg → those commands cannot run
    return _AIEDBG_SPEC_CACHE


def _scope_passthrough_cmds(scope, discovered):
    """Adapt discovered aiedbg commands to one scope's argument conventions."""
    out = []
    for c in discovered:
        e = dict(c)
        if scope in ("tile", "channel") and c["name"] in _COORD_INJECTED:
            # aiegdb fills phys_col/row in, so drop them from the template.
            e["args"] = " ".join(a for a in c["args"].split()
                                 if a not in ("<col>", "<row>"))
            e["summary"] = c["summary"] + "  (col/row auto-filled)"
            # aiedbg's positional list still starts with col/row, so a front-end
            # mapping "what am I typing now?" onto arg_help() must skip them.
            e["coord_skip"] = 2
        out.append(e)
    return out


def command_spec(refresh=False):
    """The full grammar: aiegdb's decoded commands plus aiedbg's passthroughs.

    Single source of truth for the CLI `?` listing, the `spec` verb, the daemon's
    /aiegdb/spec endpoint and the copy schedule_view.py bakes into the page."""
    discovered = discover_aiedbg_spec(refresh)
    spec = {k: list(v) for k, v in COMMAND_SPEC.items()}
    for scope in ("partition", "tile", "channel"):
        spec[scope] = spec[scope] + _scope_passthrough_cmds(scope, discovered)
    return spec

# ── AIE performance-counter register offsets (AIE2PS) ─────────────────────────
# From thirdparty/alib/aie-rt/driver/src/global/xaie2psgbl_params.h.
# DMA start/finish events live in the MEMORY module on core tiles, which is why
# the runtime debug path counts "MM2S BD finished" via MEM_MOD perf counters
# (src/mlir/runtime/aie_runtime_debug.c:1494,1973).
PERF_OFFSETS = {
    # memory module of a core tile (DMA events counted here)
    "core_mem": {"ctrl0": 0x11000, "cnt": (0x11020, 0x11024)},
    # core (compute) module of a core tile
    "core":     {"ctrl0": 0x37500, "cnt": (0x37520, 0x37524)},
    # PL module of a shim tile (row 0)
    "shim_pl":  {"ctrl0": 0x31000, "cnt": (0x31020, 0x31024)},
}
# CONTROL0 field layout (7-bit event ids for core/mem; PL uses 8-bit but the
# same LSB positions, so a 7-bit read still yields the low 7 bits which cover
# the DMA event ids we care about).
_PERF_FIELDS = {
    "cnt0_start": (0, 0x7F),
    "cnt0_stop":  (8, 0x7F),
    "cnt1_start": (16, 0x7F),
    "cnt1_stop":  (24, 0x7F),
}


def _perf_key(tile_type):
    """Perf-counter register bank used for a tile's *DMA* counters."""
    return "shim_pl" if tile_type == "shim" else "core_mem"


def _reverse_event_ids():
    """Build {event_id: 'S2MM0.FINISHED_TASK'} for core-mem and shim DMA events."""
    core_rev = {}
    for (d, ch), m in aiediag.CORE_MEM_DMA_EVENT_IDS.items():
        for name, eid in m.items():
            core_rev[eid] = f"{d.upper()}{ch}.{name}"
    shim_rev = {}
    for (d, ch), m in aiediag.SHIM_DMA_EVENT_IDS.items():
        for name, eid in m.items():
            shim_rev[eid] = f"{d.upper()}{ch}.{name}"
    return core_rev, shim_rev


_CORE_EVT_REV, _SHIM_EVT_REV = _reverse_event_ids()


def _evt_label(tile_type, eid):
    rev = _SHIM_EVT_REV if tile_type == "shim" else _CORE_EVT_REV
    if eid == 0:
        return "NONE(0)"
    return rev.get(eid, f"evt{eid}")


# ── small parse helpers ───────────────────────────────────────────────────────

_DIR_CH_RE = re.compile(r"^(mm2s|s2mm)(\d+)$", re.IGNORECASE)


def _is_dir_ch(tok):
    return bool(_DIR_CH_RE.match(tok.strip().lstrip("-")))


def _parse_dir_ch(tok):
    """'mm2s0' / '-s2mm1' -> ('mm2s', 0). Returns (None, None) on bad input."""
    m = _DIR_CH_RE.match(tok.strip().lstrip("-"))
    if not m:
        return None, None
    return m.group(1).lower(), int(m.group(2))


def _expand_parens(line):
    """Turn parenthesized forms into space forms: tile(0,0) -> tile 0 0."""
    line = re.sub(r"\(\s*(\d+)\s*,\s*(\d+)\s*\)", r" \1 \2", line)
    line = re.sub(r"\(\s*(\d+)\s*\)", r" \1", line)
    return line


# ── the REPL ──────────────────────────────────────────────────────────────────

class AieGdb:
    """Stateful scoped console. Partition config always present; tile/channel
    are pushed/popped by `target`/`up`."""

    def __init__(self, target=None, device="pal", startcol=0, aie_version="5",
                 json_dir=None, dry_run=False, work_dir=None):
        # partition scope (always present)
        self.target = target
        self.device = device
        self.startcol = int(startcol) if startcol is not None else 0
        self.aie_version = str(aie_version)
        self.json_dir = json_dir
        self.dry_run = dry_run
        # Auto-injected into callstack commands that require --work-dir.
        self.work_dir = work_dir
        try:
            self.passthrough_timeout = float(
                os.environ.get("AIEGDB_PASSTHROUGH_TIMEOUT", "120"))
        except (TypeError, ValueError):
            self.passthrough_timeout = 120.0
        # Non-interactive front-ends (the browser console via --server, the MCP
        # server) cannot drive aiedbg's live TUI grids: the command never exits,
        # so it blocks for passthrough_timeout while the server read gives up.
        # callstack uses 300s regardless of this value (XSDB farm round-trip).
        self.no_tui = False
        # deeper scopes (None until pushed)
        self.tile = None       # dict {col, row, type}
        self.channel = None    # dict {direction, channel}
        # lazily-loaded provenance
        self._dfsche = None
        self._dmaphop = None
        self._jsons_loaded = False
        self._shim_events = None
        self._shim_loaded = False
        self._tiles = None     # schedule_view.json tiles
        # per-command register-read sink: run_line resets it at the start of
        # each command and flushes it as a light-yellow block at the bottom.
        self._reg_trace = []

    # ---- scope helpers ---------------------------------------------------
    @property
    def phys_col(self):
        if self.tile is None:
            return None
        return self.tile["col"] + self.startcol

    def prompt(self):
        s = f"partition(startcol={self.startcol})"
        if self.tile is not None:
            s += f"/tile({self.tile['col']},{self.tile['row']})"
        if self.channel is not None:
            s += f"/{self.channel['direction']}{self.channel['channel']}"
        return s + "> "

    def scope_name(self):
        """Bare current level — the COMMAND_SPEC key, as opposed to prompt()'s
        decorated breadcrumb. Front-ends use it to pick the suggestion set."""
        if self.channel is not None:
            return "channel"
        if self.tile is not None:
            return "tile"
        return "partition"

    def _load_jsons(self):
        if not self._jsons_loaded:
            self._dfsche, self._dmaphop = aiediag.load_jsons(self.json_dir)
            self._jsons_loaded = True
        return self._dfsche, self._dmaphop

    def _load_shim_events(self):
        if not self._shim_loaded:
            path = os.path.expanduser("~/aiejson/shimtile_events.json")
            self._shim_events = aiediag.load_shim_events_json(path)
            self._shim_loaded = True
        return self._shim_events

    def _load_tiles(self):
        """Tile list from schedule_view.json (for `channels`)."""
        if self._tiles is not None:
            return self._tiles
        import json
        candidates = []
        if self.json_dir:
            candidates.append(os.path.join(self.json_dir, "schedule_view.json"))
        candidates += [
            "./worklocal/schedule_view.json",
            "./aout/worklocal/schedule_view.json",
        ]
        for p in candidates:
            if os.path.isfile(p):
                with open(p) as f:
                    self._tiles = json.load(f).get("tiles", [])
                return self._tiles
        self._tiles = []
        return self._tiles

    # ---- aiedbg backends -------------------------------------------------
    def blocking_names(self):
        """Live-TUI command names a non-interactive front-end must refuse.

        Union of what `aiedbg --help` advertises and _KNOWN_BLOCKING: discovery
        keeps this current as aiedbg grows new live views, while the constant
        keeps the guard alive if aiedbg is absent or the help format changes."""
        names = set(_KNOWN_BLOCKING)
        names.update(c["name"] for c in discover_aiedbg_spec() if c["blocking"])
        return sorted(names)

    def _blocked_tui(self, args):
        """True (and explains) if this is a live TUI command a non-interactive
        front-end must not run."""
        if not self.no_tui:
            return False
        typed = " ".join(str(a) for a in args).lower()
        for name in self.blocking_names():
            if typed.startswith(name):
                print("error: '%s' is a live/interactive aiedbg view that never "
                      "exits, so it cannot run in this console — it would block "
                      "for %gs and drop the aiegdb session.\n"
                      "  Run it in a terminal instead:  aiedbg -d %s %s\n"
                      "  For a live view here, use the grid overlay in the UI."
                      % (name, self.passthrough_timeout, self.device, typed))
                return True
        return False

    def _passthrough(self, args):
        """Run a verbatim aiedbg command (raw passthrough). Echoes stdout."""
        if self._blocked_tui(args):
            return
        args = [str(a) for a in args]
        # Auto-inject --work-dir for callstack commands when the user has not
        # already supplied it and a work_dir is known from the active app.
        if (self.work_dir and "--work-dir" not in args
                and len(args) >= 2 and args[0] == "callstack"):
            # aiedbg callstack <subcommand> --work-dir <dir> [col row]
            args = [args[0], args[1], "--work-dir", self.work_dir] + args[2:]
        if args and args[0] == "callstack":
            # aiedbg's top-level dispatcher rewrites xsdb:// targets to
            # baremetal:// before forwarding to the callstack Click CLI, causing
            # a ~120s TCP timeout.  Invoke the Click CLI directly so the correct
            # backend type is preserved.
            #   aiedbg callstack show --work-dir W col row
            #   \u2192 python -m aiedbg.callstack.unified_cli
            #         --work-dir W --device-type D --target T show col row
            sub = args[1:]  # everything after "callstack"
            work_dir_val = self.work_dir
            # extract --work-dir from sub if user supplied it
            if "--work-dir" in sub:
                idx = sub.index("--work-dir")
                work_dir_val = sub[idx + 1]
                sub = sub[:idx] + sub[idx + 2:]
            cli_cmd = [sys.executable, "-m", "aiedbg.callstack.unified_cli",
                       "--device-type", self.device]
            if work_dir_val:
                cli_cmd += ["--work-dir", work_dir_val]
            if self.target:
                cli_cmd += ["--target", self.target]
            cli_cmd += sub
            cmd = cli_cmd
        else:
            cmd = ["aiedbg", "-d", self.device]
            if self.target:
                cmd += ["--target", self.target]
            cmd += args
        if self.dry_run:
            print("  [dry-run] would execute: " + " ".join(cmd))
            return
        timeout = self.passthrough_timeout
        try:
            subprocess.run(cmd, timeout=timeout)
        except FileNotFoundError:
            print("Error: 'aiedbg' not found in PATH", file=sys.stderr)
        except subprocess.TimeoutExpired:
            print("Error: aiedbg timed out after %gs (%s). The JTAG link may be "
                  "blocked \u2014 a board run can hold it, or the target/"
                  "hw_server is unresponsive. Prefer a scoped read (e.g. "
                  "'target tile C R' then 'dma status') over an array-wide "
                  "'scan'." % (timeout, " ".join(cmd[3:])),
                  file=sys.stderr)

    def _reg_read(self, phys_col, row, off):
        """Decoded-path register read via aiediag (respects dry_run).

        Collects the raw address + raw value into the per-command sink so
        run_line can flush a light-yellow block at the bottom of the output."""
        return aiediag.run_aiedbg_reg_read(
            phys_col, row, off, target=self.target, device=self.device,
            dry_run=self.dry_run, sink=self._reg_trace)

    # ---- dispatch --------------------------------------------------------
    def run_line(self, line):
        """Run one command, then flush any collected register reads as a
        light-yellow brace block at the bottom of the output.

        The per-command sink is reset here so each command shows only its own
        reads. Passthrough commands (reg/mem/scan) run aiedbg uncaptured and
        print addresses natively, so they don't feed the sink."""
        self._reg_trace = []
        try:
            return self._dispatch(line)
        finally:
            block = aiediag.format_reg_read_block(self._reg_trace)
            if block:
                print(block)

    def _dispatch(self, line):
        line = line.strip()
        if not line or line.startswith("#"):
            return True
        line = _expand_parens(line)
        parts = line.split()
        verb = parts[0].lower()
        args = parts[1:]

        # universal commands (available in every scope)
        if verb in ("exit", "quit", "q"):
            return False
        if verb == "help":
            self._help()
            return True
        if verb in ("?", "commands", "cmds"):
            self._commands()
            return True
        if verb == "spec":
            # Machine-readable grammar for front-ends (browser autocomplete).
            print(json.dumps({"scope": self.scope_name(),
                              "spec": command_spec()}, indent=1))
            return True
        if verb in ("where", "info", "pwd"):
            self._where()
            return True
        if verb in ("up", ".."):
            self._up()
            return True
        if verb == "top":
            self.tile = None
            self.channel = None
            return True
        if verb in ("target", "tar"):
            self._target(args)
            return True
        if verb == "set":
            self._set(args)
            return True

        # bare navigation shortcuts
        if verb == "tile":
            # `tile list` is an aiedbg passthrough; `tile 0 0` is navigation.
            if len(args) >= 2 and args[0].lstrip("-").isdigit():
                self._target(["tile"] + args)
                return True
            if len(args) == 1 and args[0].lower() == "list":
                self._scope_passthrough(parts)
                return True
            self._target(["tile"] + args)
            return True
        if verb == "channel":
            self._target(["channel"] + args)
            return True
        if _is_dir_ch(verb) and not args:
            # bare `mm2s0` selects a channel
            self._target(["channel", verb])
            return True

        # scope-specific handling
        if self.channel is not None:
            self._channel_cmd(verb, args, parts)
        elif self.tile is not None:
            self._tile_cmd(verb, args, parts)
        else:
            self._partition_cmd(verb, args, parts)
        return True

    # ---- navigation ------------------------------------------------------
    def _target(self, args):
        if not args:
            print("usage: target partition|tile <c> <r>|channel <dir_ch>")
            return
        obj = args[0].lower()
        rest = args[1:]
        if obj == "partition":
            self._config_partition(rest)
            self.tile = None
            self.channel = None
            print(f"scope -> {self.prompt().rstrip()}")
            return
        if obj == "tile":
            if len(rest) < 2 or not (rest[0].lstrip("-").isdigit()
                                     and rest[1].lstrip("-").isdigit()):
                print("usage: target tile <col> <row>   (e.g. tar tile(0,0))")
                return
            col, row = int(rest[0]), int(rest[1])
            self.tile = {"col": col, "row": row,
                         "type": aiediag.tile_type_for_row(row, self.aie_version)}
            self.channel = None
            print(f"scope -> {self.prompt().rstrip()}  "
                  f"(phys_col={self.phys_col}, row={row})")
            return
        if obj == "channel":
            if not rest:
                print("usage: target channel <dir_ch>   (e.g. mm2s0, s2mm1)")
                return
            self._push_channel(rest[0])
            return
        if _is_dir_ch(obj):
            self._push_channel(obj)
            return
        print(f"target: unknown object {obj!r} "
              f"(partition|tile|channel|<dir_ch>)")

    def _push_channel(self, tok):
        if self.tile is None:
            print("error: select a tile first (e.g. `target tile 0 0`)")
            return
        d, c = _parse_dir_ch(tok)
        if d is None:
            print(f"error: bad channel {tok!r}; expected mm2s0/s2mm1")
            return
        self.channel = {"direction": d, "channel": c}
        print(f"scope -> {self.prompt().rstrip()}")

    def _config_partition(self, kwargs):
        for kv in kwargs:
            key, _, val = kv.partition("=")
            key = key.lower()
            if key == "startcol":
                try:
                    self.startcol = int(val)
                except ValueError:
                    print(f"bad startcol: {val}")
            elif key == "target":
                self.target = val or None
            elif key == "device":
                self.device = val or self.device
            elif key in ("aie", "aie-version", "aie_version"):
                self.aie_version = val or self.aie_version
            else:
                print(f"unknown partition option: {kv}")

    def _set(self, args):
        if len(args) < 2:
            print("usage: set startcol N | set target ... | set device ... | "
                  "set aie 5|2ps")
            return
        self._config_partition([f"{args[0]}={args[1]}"])
        print(f"set {args[0]}={args[1]}")

    def _up(self):
        if self.channel is not None:
            self.channel = None
        elif self.tile is not None:
            self.tile = None
        else:
            print("already at partition scope")

    def _where(self):
        print(f"scope:     {self.prompt().rstrip()}")
        print(f"partition: startcol={self.startcol} device={self.device} "
              f"aie={self.aie_version} target={self.target or 'NONE'}")
        if self.tile is not None:
            print(f"tile:      logical col={self.tile['col']} row={self.tile['row']} "
                  f"type={self.tile['type']}  -> phys_col={self.phys_col}")
        if self.channel is not None:
            print(f"channel:   {self.channel['direction'].upper()} "
                  f"ch{self.channel['channel']}")

    # ---- partition scope -------------------------------------------------
    def _partition_cmd(self, verb, args, parts):
        # everything else is a verbatim aiedbg passthrough (explicit coords).
        self._scope_passthrough(parts)

    def _scope_passthrough(self, parts):
        self._passthrough(parts)

    # ---- tile scope ------------------------------------------------------
    def _tile_cmd(self, verb, args, parts):
        col, row = self.tile["col"], self.tile["row"]
        ttype = self.tile["type"]
        pc = self.phys_col

        if verb == "dma" and args:  # `dma <dir_ch>` decoded status
            self._dma_status_for(args[0])
            return
        if verb == "pc":
            self._pc()
            return
        if verb == "core" and args and args[0] in ("event", "events"):
            self._core_events()
            return
        if verb == "status" or (verb == "core" and (not args or args[0] == "status")):
            self._core_status()
            return
        if verb == "event":
            if args and args[0] in ("core", "module"):
                self._core_events()
            else:
                self._tile_events()
            return
        if verb in ("log", "klog"):
            self._klog()
            return
        if verb in ("channels", "chans"):
            self._list_channels()
            return
        if verb == "reg" and args and args[0] in ("read", "write"):
            self._passthrough(["reg", args[0], str(pc), str(row)] + args[1:])
            return
        if verb == "mem" and args:
            self._passthrough(["mem", args[0], str(pc), str(row)] + args[1:])
            return
        # callstack show/layers/stream: auto-append col row from current tile
        # scope when the user hasn't supplied them.  unified_cli uses Work/
        # directory coordinates (col_row dir names), where row is aierow_offset
        # less than the physical/schedule row (aierow_offset=3 is hardcoded in
        # the unified_cli CoordinateMapper and is the shim+mem tile count).
        if (verb == "callstack" and args
                and args[0] in ("show", "layers", "stream")):
            sub = args[0]
            extra = args[1:]  # user-supplied flags (e.g. --enhanced) or col row
            has_coords = len(extra) >= 2 and extra[-2].lstrip("-").isdigit()
            if not has_coords:
                _aie_row_offset = 3  # shim (row 0) + mem tiles; matches unified_cli
                work_row = max(0, row - _aie_row_offset)
                extra = extra + [str(col), str(work_row)]
            self._passthrough(["callstack", sub] + extra)
            return
        # scan / tile list / show / anything else: verbatim (array-wide)
        self._scope_passthrough(parts)

    def _dma_status_for(self, tok):
        d, c = _parse_dir_ch(tok)
        if d is None:
            print(f"error: bad channel {tok!r}")
            return
        ttype = self.tile["type"]
        off = aiediag.compute_reg_offset(ttype, d, c, self.aie_version)
        raw = self._reg_read(self.phys_col, self.tile["row"], off)
        if raw is None:
            return
        dec = aiediag.decode_dma_status(raw)
        print(aiediag.format_dma_status(self.phys_col, self.tile["row"],
                                        d, c, dec))

    def _pc(self):
        if self.tile["type"] != "core":
            print(f"error: {self.tile['type']} tiles have no core PC register")
            return
        raw = self._reg_read(self.phys_col, self.tile["row"],
                             aiediag.CORE_PC_OFFSET)
        if raw is None:
            return
        pc = raw & aiediag.CORE_PC_MASK
        entries, lm = aiediag.load_linemap()
        hit = aiediag.pc_to_source(entries, pc) if entries else None
        if hit:
            print(aiediag.green(f"  PC=0x{pc:05X} -> {hit['file']}:{hit['line']}"))
        else:
            print(f"  PC=0x{pc:05X} (no line-map match)")

    def _core_status(self):
        if self.tile["type"] != "core":
            print(f"error: {self.tile['type']} tiles have no core status register")
            return
        off = aiediag.core_status_offset(self.aie_version)
        raw = self._reg_read(self.phys_col, self.tile["row"], off)
        if raw is None:
            return
        dec = aiediag.decode_core_status(raw)
        print(aiediag.format_core_status(self.phys_col, self.tile["row"], dec))

    def _klog(self):
        if self.tile["type"] != "core":
            print(f"error: {self.tile['type']} tiles have no core klog buffer")
            return
        res = aiediag.read_klog(self.phys_col, self.tile["row"],
                                self.target, self.device, self.dry_run)
        if res is None:
            print(f"  klog read failed for tile({self.phys_col},{self.tile['row']})")
            return
        wi, words = res
        print(aiediag.format_klog(self.phys_col, self.tile["row"], wi, words))

    def _tile_events(self):
        ttype = self.tile["type"]
        pc, row = self.phys_col, self.tile["row"]
        if ttype == "shim":
            # _reg_read collects addr+value into the sink for each read.
            for off in (aiediag.SHIM_EVT_STATUS_REG0,
                        aiediag.SHIM_EVT_STATUS_REG1):
                self._reg_read(pc, row, off)
        elif ttype == "memtile":
            regs = [self._reg_read(pc, row, off)
                    for off in aiediag.MEMTILE_EVT_STATUS_REGS]
            sel_reg = self._reg_read(pc, row, aiediag.MEMTILE_DMA_EVENT_SEL_REG)
            if not all(v is None for v in regs):
                print(aiediag.format_memtile_dma_events(pc, row, regs, sel_reg))
        else:
            regs4 = [self._reg_read(pc, row, off)
                     for off in aiediag.MEM_EVT_STATUS_REGS]
            if not all(v is None for v in regs4):
                print(aiediag.format_core_mem_dma_events(pc, row, regs4))

    def _core_events(self):
        """Full core-MODULE event list (0x34200..) — distinct from `event`,
        which decodes the memory-module DMA events (0x14200..)."""
        if self.tile["type"] != "core":
            print(f"error: {self.tile['type']} tiles have no core module events")
            return
        pc, row = self.phys_col, self.tile["row"]
        regs4 = [self._reg_read(pc, row, off)
                 for off in aiediag.CORE_EVT_STATUS_REGS]
        if not all(v is None for v in regs4):
            print(aiediag.format_core_module_events(pc, row, regs4))

    def _list_channels(self):
        col, row = self.tile["col"], self.tile["row"]
        tiles = self._load_tiles()
        found = False
        for t in tiles:
            if t.get("loc", [None, None])[:2] == [col, row]:
                found = True
                chans = t.get("dma_channels", [])
                if not chans:
                    print("  (no dma channels)")
                for ch in chans:
                    print(f"  {ch.get('direction', '?')}{ch.get('channel', '?')}"
                          f"  flow_index={ch.get('flow_index')}")
                break
        if not found:
            print(f"  tile ({col},{row}) not found in schedule_view.json")

    # ---- channel scope ---------------------------------------------------
    def _channel_cmd(self, verb, args, parts):
        d = self.channel["direction"]
        c = self.channel["channel"]
        ttype = self.tile["type"]
        pc, row = self.phys_col, self.tile["row"]

        if verb in ("status",) or (verb == "dma" and args and args[0] == "status"):
            self._dma_status_for(f"{d}{c}")
            return
        if verb == "dma" and args and args[0] in ("counter",):
            self._dma_counter(args[1:])
            return
        if verb == "counter":
            self._dma_counter(args)
            return
        if verb == "dma":  # bare `dma` -> status
            self._dma_status_for(f"{d}{c}")
            return
        if verb == "bd":
            self._bd()
            return
        if verb == "event":
            self._channel_events()
            return
        if verb in ("log", "klog"):
            self._klog()
            return
        if verb == "reg" and args and args[0] in ("read", "write"):
            self._passthrough(["reg", args[0], str(pc), str(row)] + args[1:])
            return
        if verb == "mem" and args:
            self._passthrough(["mem", args[0], str(pc), str(row)] + args[1:])
            return
        self._scope_passthrough(parts)

    def _bd(self):
        d = self.channel["direction"]
        c = self.channel["channel"]
        col, row = self.tile["col"], self.tile["row"]
        dfsche, _ = self._load_jsons()
        tile = aiediag.find_tile_in_json(dfsche, col, row)
        ch = aiediag.find_channel_in_tile(tile, d, c) if tile else None
        if ch is None:
            print(f"  channel {d.upper()} ch{c} not found for tile({col},{row}) "
                  f"in provenance JSON")
            return
        bd_ids = [bd["bd_id"] for bd in ch.get("bd_chain", [])]
        if bd_ids:
            mask = aiediag.BD_LEN_MASK[aiediag._bd_type_key(
                self.tile["type"], self.aie_version)]
            hw = {}
            for bd_id in bd_ids:
                off = aiediag.bd_length_offset(
                    self.tile["type"], self.aie_version, bd_id)
                word0 = self._reg_read(self.phys_col, row, off)
                hw[bd_id] = None if word0 is None else (word0 & mask) * 4
            if all(v is None for v in hw.values()):
                hw = None
        else:
            hw = None
        print(aiediag.format_bd_chain(ch, hw))

    def _channel_events(self):
        d = self.channel["direction"]
        c = self.channel["channel"]
        ttype = self.tile["type"]
        pc, row = self.phys_col, self.tile["row"]
        if ttype == "shim":
            shim_ev = self._load_shim_events()
            reg0 = self._reg_read(pc, 0, aiediag.SHIM_EVT_STATUS_REG0)
            reg1 = self._reg_read(pc, 0, aiediag.SHIM_EVT_STATUS_REG1)
            bits = aiediag.decode_shim_event_status(d, c, reg0, reg1)
            if bits:
                print(aiediag.format_shim_event_status(pc, d, c, bits, shim_ev))
        elif ttype == "memtile":
            regs = [self._reg_read(pc, row, off)
                    for off in aiediag.MEMTILE_EVT_STATUS_REGS]
            sel_reg = self._reg_read(pc, row, aiediag.MEMTILE_DMA_EVENT_SEL_REG)
            if all(v is None for v in regs):
                return
            sel = aiediag.memtile_dma_sel_for_channel(sel_reg, d, c)
            if sel is None:
                print(f"  {d.upper()} ch{c} is not currently mapped to an event "
                      f"slot (DMA_EVENT_CHANNEL_SELECTION=0x{(sel_reg or 0):08X}); "
                      f"showing all slots:")
                print(aiediag.format_memtile_dma_events(pc, row, regs, sel_reg))
                return
            emap = aiediag.MEMTILE_DMA_EVENT_IDS[(d, sel)]
            started = aiediag._evt_active(emap["START_TASK"], regs)
            finished_bd = aiediag._evt_active(emap["FINISHED_BD"], regs)
            finished = aiediag._evt_active(emap["FINISHED_TASK"], regs)
            error = aiediag._evt_active(emap["ERROR"], regs)
            label = f"{d.upper()} ch{c} (SEL{sel})"
            print(f"  {label} events tile({pc},{row}):")
            print(f"    START_TASK:    {'SET' if started else 'not set'}")
            print(f"    FINISHED_BD:   {'SET' if finished_bd else 'not set'}")
            print(f"    FINISHED_TASK: {'SET' if finished else 'not set'}")
            print(f"    ERROR:         {'SET' if error else 'not set'}"
                  f"{'  (S2MM/MM2S direction-wide)' if error else ''}")
            print(aiediag._memtile_evt_verdict(label, started, finished_bd,
                                               finished, error))
        else:
            emap = aiediag.CORE_MEM_DMA_EVENT_IDS.get((d, c))
            if emap is None:
                print(f"  no event map for {d}{c}")
                return
            regs4 = [self._reg_read(pc, row, off)
                     for off in aiediag.MEM_EVT_STATUS_REGS]
            if all(v is None for v in regs4):
                return
            started = aiediag._evt_active(emap["START_TASK"], regs4)
            finished_bd = aiediag._evt_active(emap["FINISHED_BD"], regs4)
            finished = aiediag._evt_active(emap["FINISHED_TASK"], regs4)
            error = aiediag._evt_active(emap["ERROR"], regs4)
            print(f"  {d.upper()} ch{c} events tile({pc},{row}):")
            print(f"    START_TASK:    {'SET' if started else 'not set'}")
            print(f"    FINISHED_BD:   {'SET' if finished_bd else 'not set'}")
            print(f"    FINISHED_TASK: {'SET' if finished else 'not set'}")
            print(f"    ERROR:         {'SET' if error else 'not set'}")
            if error:
                print(aiediag.red("    >> DMA ERROR event active"))
            elif started and finished:
                print(aiediag.green("    >> started and finished (completed)"))
            elif started and finished_bd:
                print(aiediag.yellow("    >> started, some BD(s) finished, but "
                                     "task never finished (still running or stuck)"))
            elif started:
                print(aiediag.yellow("    >> started but never finished (stuck)"))
            else:
                print(aiediag.yellow("    >> never started (start_io not issued?)"))

    # ---- performance counters (dma counter) ------------------------------
    def _dma_counter(self, args):
        """Read (default) or set up AIE performance counters for this channel's
        DMA. Read-only unless `setup` is given (an explicit write)."""
        if args and args[0].lower() == "setup":
            self._dma_counter_setup(args[1:])
            return
        d = self.channel["direction"]
        c = self.channel["channel"]
        ttype = self.tile["type"]
        pc, row = self.phys_col, self.tile["row"]
        if ttype == "memtile":
            print("  memtile perf counters not supported (MEM_TILE module uses a "
                  "different counter bank than the core memory module)")
            return
        bank = PERF_OFFSETS[_perf_key(ttype)]
        print(f"  Perf counters ({_perf_key(ttype)}) tile({pc},{row}) "
              f"for {d.upper()} ch{c}:")
        ctrl = self._reg_read(pc, row, bank["ctrl0"])
        cnt0 = self._reg_read(pc, row, bank["cnt"][0])
        cnt1 = self._reg_read(pc, row, bank["cnt"][1])
        if self.dry_run:
            return
        fields = {}
        if ctrl is not None:
            for name, (lsb, mask) in _PERF_FIELDS.items():
                fields[name] = (ctrl >> lsb) & mask
        self._print_counter("cnt0", cnt0, fields.get("cnt0_start"),
                            fields.get("cnt0_stop"), ttype)
        self._print_counter("cnt1", cnt1, fields.get("cnt1_start"),
                            fields.get("cnt1_stop"), ttype)

    def _print_counter(self, label, val, start, stop, ttype):
        if start is None:
            print(f"    {label}: value={'?' if val is None else val} "
                  f"(control0 unread)")
            return
        if start == 0 and stop == 0:
            print(f"    {label}: value={val}  (inactive: start==stop==0)")
            return
        s_lbl = _evt_label(ttype, start)
        e_lbl = _evt_label(ttype, stop)
        print(f"    {label}: value={val}  (start={s_lbl} stop={e_lbl})")

    def _dma_counter_setup(self, args):
        """INTRUSIVE: program CNT0 to count this channel's FINISHED_TASK (default)
        or START_TASK event via a reg write to CONTROL0."""
        d = self.channel["direction"]
        c = self.channel["channel"]
        ttype = self.tile["type"]
        pc, row = self.phys_col, self.tile["row"]
        if ttype == "memtile":
            print("  memtile perf counters not supported (MEM_TILE module uses a "
                  "different counter bank than the core memory module)")
            return
        which = (args[0].lower() if args else "finished")
        evt_name = "START_TASK" if which.startswith("start") else "FINISHED_TASK"
        if ttype == "shim":
            emap = aiediag.SHIM_DMA_EVENT_IDS.get((d, c), {})
        else:
            emap = aiediag.CORE_MEM_DMA_EVENT_IDS.get((d, c), {})
        eid = emap.get(evt_name)
        if eid is None:
            print(f"  no {evt_name} event id for {d}{c} on {ttype}")
            return
        bank = PERF_OFFSETS[_perf_key(ttype)]
        # CNT0_START = CNT0_STOP = eid so the counter increments on each event.
        ctrl_val = (eid & 0x7F) | ((eid & 0x7F) << 8)
        print(aiediag.yellow(
            f"  [intrusive] programming CONTROL0=0x{ctrl_val:08X} "
            f"(CNT0 start/stop={evt_name}={eid})"))
        self._passthrough(["reg", "write", str(pc), str(row),
                           f"0x{bank['ctrl0']:X}", f"0x{ctrl_val:X}"])
        val = self._reg_read(pc, row, bank["cnt"][0])
        if not self.dry_run:
            print(f"  cnt0 value now: {val}")

    # ---- help ------------------------------------------------------------
    def _help(self):
        print("Navigation (any scope):")
        print("  target partition [startcol=N] [target=..] [device=..] [aie=5|2ps]")
        print("  target tile <col> <row>   (or: tile 0 0 / tar tile(0,0))")
        print("  target channel <dir_ch>   (or: channel mm2s0 / tar s2mm1)")
        print("  up | ..    pop one level      top    go to partition")
        print("  where|info breadcrumb + phys_col/row + target/device")
        print("  set startcol N | set target .. | set device .. | set aie ..")
        print("  ? | commands  list only the current-level commands")
        print("  help | exit | quit")
        if self.channel is not None:
            print("Channel scope:")
            print("  dma status | status     decoded DMA status register")
            print("  bd                      BD chain (JSON) + live HW lengths")
            print("  event                   per-channel DMA start/finish/error")
            print("  dma counter | counter   AIE perf counters (read-only)")
            print("  dma counter setup [finished|started]   (INTRUSIVE write)")
            print("  log | klog              dump kernel klog buffer (core tiles only)")
            print("  reg read OFF            passthrough (col/row auto-filled)")
        elif self.tile is not None:
            print("Tile scope (col/row auto-injected):")
            print("  dma <dir_ch>            decoded DMA status")
            print("  pc                      core PC -> source (linemap)")
            print("  status | core [status]  decoded core status (enable/reset/stall)")
            print("  event                   event-status regs (decoded)")
            print("  log | klog              dump kernel klog buffer (core tiles only)")
            print("  channels | chans        list this tile's channels")
            print("  reg read OFF | reg write OFF VAL | mem read ADDR LEN")
            print("  scan .. | tile list | show ..   (array-wide passthrough)")
        else:
            print("Partition scope (explicit col/row):")
            print("  reg read C R OFF | reg write C R OFF VAL | mem read ..")
            print("  scan dma|cores | tile list | show ..  (aiedbg passthrough)")

    def _commands(self):
        """List only the commands available at the *current* scope level
        (`?`). Unlike `help`, this omits the universal navigation block and
        shows just what applies here, plus how to descend/ascend.

        Rendered from COMMAND_SPEC rather than hand-written so this listing, the
        browser autocomplete and the MCP discovery tool always agree."""
        scope = self.scope_name()
        print(f"{scope} scope commands  ({self.prompt().rstrip()}):")
        for c in command_spec()[scope]:
            sig = c["name"] + (" " + c["args"] if c["args"] else "")
            alias = ("  [" + " | ".join(c["aliases"]) + "]") if c["aliases"] else ""
            flag = "  (INTRUSIVE write)" if c["intrusive"] else ""
            # Trailing two spaces are explicit, not padding: a long sig would
            # otherwise butt straight against the summary and the browser
            # console's `?`-output parser splits on that gap.
            print(f"  {sig:<36}  {c['summary']}{alias}{flag}")
        if scope == "channel":
            print("  up | ..    -> tile scope     top -> partition")
        elif scope == "tile":
            print("  target channel <dir_ch> (or: channel mm2s0) -> descend")
            print("  up | ..    -> partition scope")
        else:
            print("  target tile <col> <row> (or: tile 0 0) -> descend")
        print("Universal: target|tar | set | where|info | help | exit  "
              "(help = full reference)")

    # ---- loops -----------------------------------------------------------
    def interactive(self):
        if _HAVE_READLINE:
            try:
                readline.read_history_file(HISTORY_FILE)
            except (OSError, FileNotFoundError):
                pass
        print("aiegdb - GDB-like AIE debug console. Type 'help' or 'exit'.")
        print(f"  device={self.device} startcol={self.startcol} "
              f"aie={self.aie_version} target={self.target or 'NONE'}"
              f"{'  [DRY-RUN]' if self.dry_run else ''}")
        try:
            while True:
                try:
                    line = input(self.prompt())
                except EOFError:
                    print()
                    break
                except KeyboardInterrupt:
                    print("^C")
                    continue
                if not self.run_line(line):
                    break
        finally:
            if _HAVE_READLINE:
                try:
                    readline.write_history_file(HISTORY_FILE)
                except OSError:
                    pass

    def batch(self, commands):
        for line in commands:
            for sub in line.split(";"):
                sub = sub.strip()
                if not sub:
                    continue
                print(f"{self.prompt()}{sub}")
                if not self.run_line(sub):
                    return

    def serve_stdin(self):
        """Framed REPL over stdin/stdout for a long-lived daemon subprocess.

        One command per stdin line; after each, emit a marker line whose
        remainder is the current prompt/scope so the reader knows the command
        finished and can update its breadcrumb. An exception in run_line must
        not kill the server. Exit on EOF or an exit/quit command.
        """
        def emit_marker():
            sys.stdout.write(_SERVER_MARKER + self.prompt().rstrip() + "\n")
            sys.stdout.flush()

        emit_marker()  # initial scope so the daemon learns the starting prompt
        for raw in sys.stdin:
            line = raw.rstrip("\n")
            keep_going = True
            try:
                keep_going = self.run_line(line)
            except Exception as e:  # never let a bad command kill the server
                print(f"error: {e}")
            sys.stdout.flush()
            emit_marker()
            if keep_going is False:
                break


def main(argv=None):
    ap = argparse.ArgumentParser(
        prog="aiegdb",
        description="GDB-like scoped CLI frontend over aiedbg for live AIE debug")
    ap.add_argument("--target", default=None,
                    help="aiedbg target xsdb://host:port "
                         "(default: $AIEDBG_TARGET, then ~/.aiedbg_env)")
    ap.add_argument("--device", default="pal", help="aiedbg -d device (default pal)")
    ap.add_argument("--startcol", type=int, default=None,
                    help="physical column offset: phys_col = col + startcol "
                         "(default: read from provenance JSON, else 0)")
    ap.add_argument("--aie-version", default=None,
                    help="AIE version for register offsets; accepts compiler "
                         "numbers (1/2/5) or debug strings (2ps), normalized via "
                         "debug_aie_version_from_gen "
                         "(default: auto-detected from provenance JSON)")
    ap.add_argument("--json-dir", default=None,
                    help="dir with provenance/schedule_view JSONs (auto-detected)")
    ap.add_argument("--work-dir", default=None,
                    help="aiecompiler Work/ dir auto-injected into callstack commands "
                         "(e.g. /path/to/example/Work); skipped if the user supplies "
                         "--work-dir explicitly in the command")
    ap.add_argument("--dry-run", action="store_true",
                    help="print the aiedbg commands instead of running them")
    ap.add_argument("-c", "--command", default=None,
                    help="run ';'-separated commands non-interactively, then exit")
    ap.add_argument("--script", default=None,
                    help="run commands from FILE non-interactively, then exit")
    ap.add_argument("--server", action="store_true",
                    help="framed stdin/stdout REPL for a daemon subprocess "
                         "(one command per line; marker line after each)")
    args = ap.parse_args(argv)

    target = (args.target or os.environ.get("AIEDBG_TARGET")
              or _target_from_aiedbg_env())

    gdb = AieGdb(target=target, device=args.device, startcol=args.startcol,
                 aie_version=args.aie_version, json_dir=args.json_dir,
                 dry_run=args.dry_run, work_dir=args.work_dir)

    # Resolve startcol: explicit --startcol wins, else read from provenance JSON.
    if args.startcol is None:
        gdb._load_jsons()
        gdb.startcol = aiediag.startcol_from_jsons(gdb._dfsche, gdb._dmaphop) or 0
    else:
        gdb.startcol = args.startcol

    # Resolve aie_version (JSON wins so a compiler number from aiehlc.sh cannot
    # select the wrong offset map):
    #   1. provenance JSON aie_gen (authoritative, already a debug string)
    #   2. explicit --aie-version, normalized through the mapper (5 -> 2ps)
    #   3. warn loudly and fall back to a default
    gdb._load_jsons()
    ver = aiediag.aie_version_from_jsons(gdb._dfsche, gdb._dmaphop)
    if ver is None and args.aie_version is not None:
        ver = aiediag.debug_aie_version_from_gen(args.aie_version)
    if ver is None:
        ver = "2ps"
        print(f"warning: could not resolve aie_version from provenance JSON or "
              f"--aie-version flag; falling back to '{ver}'. Register reads may "
              f"be wrong.", file=sys.stderr)
    gdb.aie_version = ver

    if args.server:
        # Framed stdin/stdout for the daemon: no terminal, so a live TUI grid
        # would hang the caller rather than render.
        gdb.no_tui = True
        gdb.serve_stdin()
        return
    if args.command:
        gdb.batch([args.command])
        return
    if args.script:
        with open(args.script) as f:
            gdb.batch(f.readlines())
        return
    gdb.interactive()


def _target_from_aiedbg_env():
    """Read AIEDBG_TARGET from ~/.aiedbg_env (mirrors schedule_debug_server.py:690)."""
    path = os.path.expanduser("~/.aiedbg_env")
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                if line.startswith("export "):
                    line = line[len("export "):]
                key, _, val = line.partition("=")
                if key.strip() == "AIEDBG_TARGET":
                    return val.strip().strip('"').strip("'") or None
    except OSError:
        pass
    return None


if __name__ == "__main__":
    main()
