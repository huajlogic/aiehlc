#!/usr/bin/env python3
# ******************************************************************************
# * Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# * SPDX-License-Identifier: Apache-2.0
# ******************************************************************************
"""aieperf.py -- AIE performance timeline post-processor.

Parses the [PERF] lines emitted by AieRt_PerfProfile* / AieRt_PerfPhase*
(runtime, gated by AIEHLC_PERF=1) from an applog and produces:

  1. A Chrome trace JSON (open in https://ui.perfetto.dev or chrome://tracing)
     with three process lanes sharing one nanosecond time axis:
        pid "APU"       -- one duration slice per host phase.
        pid "AIE cores" -- per (col,row) tid: a "kernel window" slice plus
                           stacked active / lock / stream / (mem+cascade) /
                           disabled cycle slices (converted to ns).
        pid "DMA"       -- per channel tid: a status marker.
  2. An ASCII summary: per-core active%/stall% breakdown and APU overhead vs
     compute verdict.

Counter model (whole-run level counting, see aie_runtime_debug.h):
    total  = XAie_ReadTimer window cycles (denominator)
    active = ACTIVE cycles            (C0)
    gstall = GROUP_CORE_STALL cycles  (C1, total stall)
    lock   = LOCK_STALL cycles        (C2)
    stream = STREAM_STALL cycles      (C3)
  Derived:
    disabled     = total - active - gstall           (core idle / not running)
    mem+cascade  = gstall - lock - stream            (remaining stall)

Usage:
    python3 src/tool/debug/aieperf.py applog -o perf_trace.json
    python3 src/tool/debug/aieperf.py applog --clock-mhz 1000 --json-dir ./worklocal
"""

import argparse
import json
import os
import re
import sys

# Best-effort reuse of aiediag provenance loaders (for startcol / aie-version).
_HERE = os.path.dirname(os.path.abspath(__file__))
if _HERE not in sys.path:
    sys.path.insert(0, _HERE)
try:
    import aiediag  # type: ignore
    _HAVE_AIEDIAG = True
except Exception:
    _HAVE_AIEDIAG = False

# Default AIE core clock. AIE2PS runs ~1.25 GHz; override with --clock-mhz.
DEFAULT_CLOCK_MHZ = 1250.0


# ─── Parsing ──────────────────────────────────────────────────────────────

_RE_KV = re.compile(r"(\w+)=([^\s]+)")


def _parse_kv(rest):
    """Parse 'k=v k=v ...' into a dict of str->str."""
    return {m.group(1): m.group(2) for m in _RE_KV.finditer(rest)}


def _to_int(s, default=0):
    try:
        return int(s)
    except (TypeError, ValueError):
        return default


def parse_perf_lines(text):
    """Extract structured perf records from applog text.

    Returns dict with keys: cores (list), dmas (list), phases (list).
    """
    cores, dmas, phases = [], [], []
    for line in text.splitlines():
        idx = line.find("[PERF]")
        if idx < 0:
            continue
        body = line[idx + len("[PERF]"):].strip()
        if body.startswith("core "):
            kv = _parse_kv(body[len("core "):])
            cores.append({
                "col": _to_int(kv.get("c")),
                "row": _to_int(kv.get("r")),
                "total": _to_int(kv.get("total")),
                "active": _to_int(kv.get("active")),
                "gstall": _to_int(kv.get("gstall")),
                "lock": _to_int(kv.get("lock")),
                "stream": _to_int(kv.get("stream")),
            })
        elif body.startswith("dma "):
            kv = _parse_kv(body[len("dma "):])
            dmas.append({
                "col": _to_int(kv.get("c")),
                "row": _to_int(kv.get("r")),
                "dir": kv.get("dir", "?"),
                "ch": _to_int(kv.get("ch")),
                "status": _to_int(kv.get("status")),
                "cur_bd": _to_int(kv.get("cur_bd")),
                "qsize": _to_int(kv.get("qsize")),
                "stall_lock": _to_int(kv.get("stall_lock")),
                "stall_stream": _to_int(kv.get("stall_stream")),
            })
        elif body.startswith("apu "):
            kv = _parse_kv(body[len("apu "):])
            phases.append({
                "phase": kv.get("phase", "?"),
                "start_ns": _to_int(kv.get("start_ns")),
                "end_ns": _to_int(kv.get("end_ns")),
            })
    return {"cores": cores, "dmas": dmas, "phases": phases}


# ─── Derived quantities ────────────────────────────────────────────────────

def core_breakdown(c):
    """Return a dict of cycle buckets that sum to total (clamped >= 0)."""
    total = c["total"]
    active = c["active"]
    gstall = c["gstall"]
    lock = c["lock"]
    stream = c["stream"]
    mem_casc = max(0, gstall - lock - stream)
    disabled = max(0, total - active - gstall)
    return {
        "active": active,
        "lock": lock,
        "stream": stream,
        "mem_cascade": mem_casc,
        "disabled": disabled,
        "total": total,
    }


# ─── Chrome trace emission ─────────────────────────────────────────────────

_PID_APU = 1
_PID_CORES = 2
_PID_DMA = 3

# Distinct color names recognized by chrome://tracing / perfetto.
_COLOR = {
    "active": "good",           # green
    "lock": "bad",             # red
    "stream": "terrible",       # dark red
    "mem_cascade": "yellow",
    "disabled": "grey",
    "window": "thread_state_runnable",
}


def cycles_to_ns(cycles, clock_mhz):
    return (cycles * 1000.0) / clock_mhz  # cycles / (MHz) * 1e3 ns


def build_trace(records, clock_mhz, kernel_window_ns):
    """Build a Chrome trace event list."""
    ev = []

    def meta(pid, tid, name):
        ev.append({"ph": "M", "pid": pid, "tid": tid, "name": "thread_name",
                   "args": {"name": name}})

    # Process names.
    ev.append({"ph": "M", "pid": _PID_APU, "name": "process_name", "args": {"name": "APU (host)"}})
    ev.append({"ph": "M", "pid": _PID_CORES, "name": "process_name", "args": {"name": "AIE cores"}})
    ev.append({"ph": "M", "pid": _PID_DMA, "name": "process_name", "args": {"name": "DMA"}})

    # ── APU lane: one duration slice per phase ──
    apu_origin = min((p["start_ns"] for p in records["phases"]), default=0)
    for i, p in enumerate(records["phases"]):
        meta(_PID_APU, i, p["phase"])
        ev.append({
            "ph": "X", "pid": _PID_APU, "tid": i, "name": p["phase"],
            "ts": (p["start_ns"] - apu_origin) / 1000.0,   # trace ts is microseconds
            "dur": max(0, p["end_ns"] - p["start_ns"]) / 1000.0,
            "args": {"start_ns": p["start_ns"], "end_ns": p["end_ns"]},
        })

    # ── AIE cores lane: per (col,row) tid, stacked cycle slices ──
    # Lay each core's buckets end-to-end on its own tid, starting at ts=0.
    for c in records["cores"]:
        tid = c["col"] * 100 + c["row"]
        meta(_PID_CORES, tid, f"core({c['col']},{c['row']})")
        bd = core_breakdown(c)
        cursor_us = 0.0
        # Full kernel-window marker on top (translucent) if provided.
        win_ns = kernel_window_ns if kernel_window_ns else cycles_to_ns(bd["total"], clock_mhz)
        ev.append({
            "ph": "X", "pid": _PID_CORES, "tid": tid, "name": "kernel window",
            "ts": 0.0, "dur": win_ns / 1000.0, "cname": _COLOR["window"],
            "args": {"total_cycles": bd["total"]},
        })
        for bucket in ("active", "lock", "stream", "mem_cascade", "disabled"):
            cyc = bd[bucket]
            if cyc <= 0:
                continue
            dur_us = cycles_to_ns(cyc, clock_mhz) / 1000.0
            ev.append({
                "ph": "X", "pid": _PID_CORES, "tid": tid, "name": bucket,
                "ts": cursor_us, "dur": dur_us, "cname": _COLOR[bucket],
                "args": {"cycles": cyc},
            })
            cursor_us += dur_us

    # ── DMA lane: per channel tid, an instant/status marker ──
    for d in records["dmas"]:
        tid = (d["col"] * 100 + d["row"]) * 10 + d["ch"]
        label = f"{d['col']},{d['row']} {d['dir']} ch{d['ch']}"
        meta(_PID_DMA, tid, label)
        ev.append({
            "ph": "X", "pid": _PID_DMA, "tid": tid, "name": f"status={d['status']}",
            "ts": 0.0, "dur": 1.0,
            "cname": _COLOR["stream"] if d["stall_stream"] else _COLOR["active"],
            "args": {k: d[k] for k in ("status", "cur_bd", "qsize", "stall_lock", "stall_stream")},
        })

    return {"traceEvents": ev, "displayTimeUnit": "ns"}


# ─── ASCII summary ─────────────────────────────────────────────────────────

def _pct(part, whole):
    return (100.0 * part / whole) if whole else 0.0


def print_summary(records, clock_mhz):
    print("=" * 72)
    print("AIE Performance Summary  (clock = %.1f MHz)" % clock_mhz)
    print("=" * 72)

    if not records["cores"]:
        print("  (no [PERF] core lines found -- was AIEHLC_PERF=1 set at runtime?)")
    for c in records["cores"]:
        bd = core_breakdown(c)
        t = bd["total"]
        verdict = _core_verdict(bd)
        print("core(%d,%d)  total=%d cyc  active=%.1f%%  lock=%.1f%%  "
              "stream=%.1f%%  mem+casc=%.1f%%  disabled=%.1f%%   -> %s" % (
                  c["col"], c["row"], t,
                  _pct(bd["active"], t), _pct(bd["lock"], t), _pct(bd["stream"], t),
                  _pct(bd["mem_cascade"], t), _pct(bd["disabled"], t), verdict))

    # APU overhead vs kernel-window compute.
    phases = records["phases"]
    if phases:
        span = max(p["end_ns"] for p in phases) - min(p["start_ns"] for p in phases)
        window = sum((p["end_ns"] - p["start_ns"]) for p in phases if p["phase"] == "kernel_window")
        overhead = max(0, span - window)
        print("-" * 72)
        print("APU wall-clock span = %d ns" % span)
        print("  kernel_window     = %d ns (%.1f%%)" % (window, _pct(window, span)))
        print("  other/overhead    = %d ns (%.1f%%)" % (overhead, _pct(overhead, span)))
        if span and _pct(window, span) < 25.0:
            print("  VERDICT: runtime-overhead bound (kernel window is a small "
                  "fraction of wall-clock).")
    print("=" * 72)


def _core_verdict(bd):
    t = bd["total"]
    if not t:
        return "no data"
    a = _pct(bd["active"], t)
    lk = _pct(bd["lock"], t)
    st = _pct(bd["stream"], t)
    dis = _pct(bd["disabled"], t)
    if dis > 60.0:
        return "mostly disabled (core idle -- launch/sync overhead?)"
    if st >= lk and st > 20.0:
        return "STREAM-stall bound (DMA-starved: widen BDs / more channels)"
    if lk > 20.0:
        return "LOCK-stall bound (sync/dependency: ping-pong depth / credits)"
    if a > 50.0:
        return "compute bound (tiling / vectorization)"
    return "mixed"


# ─── Main ──────────────────────────────────────────────────────────────────

def resolve_clock_mhz(args):
    if args.clock_mhz:
        return args.clock_mhz
    # Try to infer from provenance aie-version (best effort).
    if _HAVE_AIEDIAG and not args.no_json:
        try:
            dfsche, dmaphop = aiediag.load_jsons(args.json_dir)
            ver = aiediag.aie_version_from_jsons(dfsche, dmaphop)
            if ver == "5":       # AIEML
                return 1000.0
            if ver == "2ps":     # AIE2PS
                return 1250.0
        except Exception:
            pass
    return DEFAULT_CLOCK_MHZ


def main(argv=None):
    ap = argparse.ArgumentParser(description="AIE performance timeline post-processor")
    ap.add_argument("applog", help="applog file containing [PERF] lines")
    ap.add_argument("-o", "--output", default="perf_trace.json",
                    help="output Chrome trace JSON path (default: perf_trace.json)")
    ap.add_argument("--clock-mhz", type=float, default=0.0,
                    help="AIE core clock in MHz (default: auto ~1250 for AIE2PS)")
    ap.add_argument("--json-dir", default=None,
                    help="directory with provenance JSONs (for clock/label inference)")
    ap.add_argument("--no-json", action="store_true",
                    help="skip provenance JSON lookups")
    ap.add_argument("--summary-only", action="store_true",
                    help="print ASCII summary only; do not write trace JSON")
    args = ap.parse_args(argv)

    if not os.path.isfile(args.applog):
        print("Error: applog not found: %s" % args.applog, file=sys.stderr)
        return 2

    with open(args.applog, errors="replace") as f:
        text = f.read()

    records = parse_perf_lines(text)
    n = len(records["cores"]) + len(records["dmas"]) + len(records["phases"])
    if n == 0:
        print("Warning: no [PERF] lines found in %s.\n"
              "  Did you run with AIEHLC_PERF=1 and regenerate with perf "
              "instrumentation?" % args.applog, file=sys.stderr)

    clock_mhz = resolve_clock_mhz(args)

    print_summary(records, clock_mhz)

    if not args.summary_only:
        # Kernel window ns from the APU phase (if present) for the core overlay.
        window_ns = 0
        for p in records["phases"]:
            if p["phase"] == "kernel_window":
                window_ns = max(0, p["end_ns"] - p["start_ns"])
                break
        trace = build_trace(records, clock_mhz, window_ns)
        with open(args.output, "w") as f:
            json.dump(trace, f, indent=1)
        print("Wrote Chrome trace: %s  (%d events)" % (args.output, len(trace["traceEvents"])))
        print("  Open in https://ui.perfetto.dev or chrome://tracing")
    return 0


if __name__ == "__main__":
    sys.exit(main())
