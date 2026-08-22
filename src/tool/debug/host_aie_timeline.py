#!/usr/bin/env python3
"""Correlate the ARM host clock with per-tile AIE core timers into ONE us axis.

The perf example (example/perf/aieml_perf.cc), built with TIMESYNC=1, prints a
machine-readable [TIMESYNC] block to stdout/applog:

    [TIMESYNC] cps=<COUNTS_PER_SECOND>
    [TIMESYNC] anchor0 host=<h0>
    [TIMESYNC] anchor0 tile=4,4 aie=<a0_44>
    [TIMESYNC] anchor1 host=<h1>
    [TIMESYNC] anchor1 tile=4,4 aie=<a1_44>
    [TIMESYNC] hostevt iter=<i> phase=<name> host=<counts>
    [TIMESYNC] aiehz tile=4,4 hz=<f>            (optional, sanity only)
    [TIMESYNC] trace tile=4,4 words=<n>         (header, count only)
    [TIMESYNC] trace tile=4,4 <start>  <NAME>                    (1-cycle event)
    [TIMESYNC] trace tile=4,4 <start> -- <end>  <NAME>  (<N> cyc) (interval)

The trace interval lines are emitted by __Runtime_aie_trace_profile_dump AFTER
the core-trace decoder has already turned the raw words into absolute-AIE-cycle
run-length intervals, so this tool parses them directly -- no re-decode. <NAME>
is a '|'-joined slot set (ACTIVE / LOCK_STALL / STREAM_STALL / MEMORY_STALL).

CLOCK MODEL. The host clock XTime_GetTime() counts at COUNTS_PER_SECOND Hz. Each
AIE tile has an independent free-running core timer (XAie_ReadTimer, XAIE_CORE_MOD)
in the SAME clock domain as its core event trace -- the Start frame's 56-bit
timer base and the trace's delta-cycle accumulation. Two anchor records bracket
the run; each records the host clock alongside every tile's timer, so we fit a
per-tile linear map from AIE cycles to host counts:

    host_counts(cycle) = h0 + (cycle - a0) * (h1 - h0) / (a1 - a0)

then to microseconds relative to host anchor0 (t=0 at anchor0):

    us(cycle) = (host_counts(cycle) - h0) / (COUNTS_PER_SECOND / 1e6)

Each tile gets its OWN (a0,a1): tile timers are unsynchronized, and reading each
from the host yields an independent fit -- no XAie_SyncTimer needed. The slope
is empirical, so no AIE frequency is hardcoded; the effective AIE Hz is
(a1-a0)/(h1-h0) * COUNTS_PER_SECOND (printed by the example for sanity).

This tool maps every parsed AIE interval and every host phase event onto the
shared us axis, and emits timeline.csv + timeline.json for external plotting
(no in-repo drawing).

Usage:
    host_aie_timeline.py <applog> --out-dir <dir>
    host_aie_timeline.py --self-test
"""

import argparse
import json
import os
import re
import sys


# --------------------------------------------------------------------------
# Parse the [TIMESYNC] block.
# --------------------------------------------------------------------------
_TS = re.compile(r"^\[TIMESYNC\]\s+(.*)$")

# A decoded AIE interval line body:
#   "trace tile=4,4 1010  ACTIVE"                        (core, 1-cycle event)
#   "trace tile=4,4 1010 -- 1012  ACTIVE|LOCK  (3 cyc)"  (core interval)
#   "trace tile=4,4 stream=mem 2005  DMA_START"          (mem-module DMA stream)
# The optional "stream=<tag>" marks the mem-module DMA trace (pkt id 2); it is
# absent on core lines (pkt id 1). The "trace tile=4,4 words=N" header has
# "words=" (not "stream="/a digit) after the tile, so it never matches here.
_TRACE_IV = re.compile(
    r"^trace tile=(\d+),(\d+) (?:stream=(\w+) )?(\d+)(?:\s+--\s+(\d+))?\s+(\S+?)(?:\s+\(\d+ cyc\))?$")

# The runtime prints one core_trace_stream_json line per traced tile carrying the
# monitored event-port selection, e.g.
#   [aie_runtime] core_trace_stream_json: {..."evt_port":{"tile":[0,3],
#     "port":"south","intf":"slave","num":0},...}
# whose PORT_*_0 IDLE/RUNNING/STALLED state feeds the port lane. Parsed to name
# that lane after the physical port ("tile 0,3 south slave 0").
_STREAM_JSON = re.compile(r"core_trace_stream_json:\s*(\{.*\})\s*$")


def _tile_key(s):
    """'4,4' -> (4, 4)."""
    c, r = s.split(",")
    return (int(c), int(r))


def _split_names(names):
    """Partition a trace interval's slot names into (core, port), mirroring the
    decoder's category rule: the stream-switch PORT_* events are the 'event'
    (port) category, everything else (ACTIVE / *_STALL / LOCK) is 'core'.
    Order within each subset is preserved so the '|'-joined label is stable."""
    core = [n for n in names if not n.startswith("PORT_")]
    port = [n for n in names if n.startswith("PORT_")]
    return core, port


def _evt_port_from_json(obj):
    """Extract ((col,row), 'south slave 0') from a core_trace_stream_json object's
    evt_port field, or None if it's absent/malformed. The tuple keys the traced
    tile; the string is the port-lane suffix (port direction, interface, index)."""
    ep = obj.get("evt_port")
    if not isinstance(ep, dict):
        return None
    tl = ep.get("tile")
    if not (isinstance(tl, list) and len(tl) == 2):
        return None
    suffix = "%s %s %s" % (ep.get("port", "?"), ep.get("intf", "?"), ep.get("num", "?"))
    return (int(tl[0]), int(tl[1])), suffix


def parse_timesync(text):
    """Extract the TIMESYNC records from an applog/stdout capture.

    Returns a dict:
        cps       : int host counts per second
        anchors   : {0: {"host": h0, "tiles": {(c,r): a0}},
                     1: {"host": h1, "tiles": {(c,r): a1}}}
        hostevts  : [(iter, phase, host_counts), ...] in emission order
        aiehz     : {(c,r): float}  (empirical, optional)
        traces    : {(c,r): [(start_cycle, end_cycle, [names]), ...]}
                    absolute-AIE-cycle intervals, in emission order
        evt_ports : {(c,r): "south slave 0"}  monitored port-lane suffix, from
                    the core_trace_stream_json evt_port field (may be empty)
    """
    cps = None
    anchors = {0: {"host": None, "tiles": {}}, 1: {"host": None, "tiles": {}}}
    hostevts = []
    aiehz = {}
    traces = {}
    evt_ports = {}

    for line in text.splitlines():
        # The evt_port descriptor rides a plain [aie_runtime] line, not a
        # [TIMESYNC] one, so scan for it before the TIMESYNC gate below.
        sj = _STREAM_JSON.search(line)
        if sj:
            try:
                ep = _evt_port_from_json(json.loads(sj.group(1)))
            except (ValueError, KeyError):
                ep = None
            if ep:
                evt_ports[ep[0]] = ep[1]
            continue
        m = _TS.match(line.strip())
        if not m:
            continue
        body = m.group(1).strip()
        tok = body.split()
        kind = re.split(r"[=\s]", body, 1)[0]  # "cps=1000000" -> "cps"

        if kind == "cps":
            cps = int(body.split("=", 1)[1])
        elif kind in ("anchor0", "anchor1"):
            idx = 0 if kind == "anchor0" else 1
            fields = dict(t.split("=", 1) for t in tok[1:])
            if "host" in fields and "tile" not in fields:
                anchors[idx]["host"] = int(fields["host"])
            elif "tile" in fields:
                anchors[idx]["tiles"][_tile_key(fields["tile"])] = int(fields["aie"])
        elif kind == "hostevt":
            fields = dict(t.split("=", 1) for t in tok[1:])
            hostevts.append((int(fields["iter"]), fields["phase"], int(fields["host"])))
        elif kind == "aiehz":
            fields = dict(t.split("=", 1) for t in tok[1:])
            aiehz[_tile_key(fields["tile"])] = float(fields["hz"])
        elif kind == "trace":
            iv = _TRACE_IV.match(body)
            if iv:
                tile = (int(iv.group(1)), int(iv.group(2)))
                stream = iv.group(3) or "core"  # "mem" for the DMA stream, else core
                s_cyc = int(iv.group(4))
                e_cyc = int(iv.group(5)) if iv.group(5) else s_cyc
                names = iv.group(6).split("|")
                traces.setdefault(tile, []).append((s_cyc, e_cyc, names, stream))
            # else: "trace tile=4,4 words=N" header -- count only, ignored.

    return {"cps": cps, "anchors": anchors, "hostevts": hostevts,
            "aiehz": aiehz, "traces": traces, "evt_ports": evt_ports}


# --------------------------------------------------------------------------
# Per-tile linear fit AIE cycle -> host microseconds (t=0 at host anchor0).
# --------------------------------------------------------------------------
class TileFit:
    """Linear map from a tile's AIE cycles to host microseconds.

    us(cycle) = (h0 + (cycle-a0)*(h1-h0)/(a1-a0) - h0) / (cps/1e6)
    """

    def __init__(self, tile, cps, h0, h1, a0, a1):
        if a1 == a0:
            raise ValueError(f"tile {tile}: degenerate anchors a0==a1=={a0}")
        self.tile = tile
        self.cps = cps
        self.h0, self.h1 = h0, h1
        self.a0, self.a1 = a0, a1
        self.counts_per_cycle = (h1 - h0) / (a1 - a0)
        self.counts_per_us = cps / 1e6
        # Effective AIE Hz from the empirical slope (no hardcoded frequency).
        self.aie_hz = (a1 - a0) / (h1 - h0) * cps if h1 != h0 else float("nan")

    def cycle_to_us(self, cycle):
        counts = self.h0 + (cycle - self.a0) * self.counts_per_cycle
        return (counts - self.h0) / self.counts_per_us

    def as_dict(self):
        return {"tile": "%d,%d" % self.tile, "h0": self.h0, "h1": self.h1,
                "a0": self.a0, "a1": self.a1,
                "counts_per_cycle": self.counts_per_cycle,
                "aie_hz": self.aie_hz}


def host_counts_to_us(counts, cps, h0):
    """Host counts -> microseconds relative to host anchor0."""
    return (counts - h0) / (cps / 1e6)


# --------------------------------------------------------------------------
# Correlate everything onto one us axis.
# --------------------------------------------------------------------------
def correlate(ts):
    """Build the merged timeline model from a parsed TIMESYNC dict.

    Returns {meta, anchors, fit_per_tile, lanes}. Lanes:
      - "host": zero-width phase markers (start_us == end_us).
      - "tile C,R core": ACTIVE/stall spans; end_us covers the interval width
        (end_cycle+1) so a single-cycle event has non-zero duration.
      - "tile C,R <port> <intf> <num>": the monitored stream-switch port's
        PORT_* spans (falls back to "tile C,R port" without an evt_port record).
    """
    cps = ts["cps"]
    if cps is None:
        raise ValueError("no [TIMESYNC] cps= record found")
    a0 = ts["anchors"][0]
    a1 = ts["anchors"][1]
    h0, h1 = a0["host"], a1["host"]
    if h0 is None or h1 is None:
        raise ValueError("missing anchor0/anchor1 host record")

    fits = {}
    for tile, av0 in a0["tiles"].items():
        av1 = a1["tiles"].get(tile)
        if av1 is None:
            continue
        fits[tile] = TileFit(tile, cps, h0, h1, av0, av1)

    lanes = []

    # Host lane: one zero-width marker per phase event.
    host_events = []
    for it, phase, counts in ts["hostevts"]:
        us = host_counts_to_us(counts, cps, h0)
        host_events.append({"event": "iter%d.%s" % (it, phase),
                            "start_us": us, "end_us": us,
                            "detail": "iter=%d phase=%s host=%d" % (it, phase, counts)})
    lanes.append({"name": "host", "events": host_events})

    # Per traced tile: a core lane ("tile C,R core") and, directly beneath it, a
    # port lane. The decoder combines core-state and stream-switch PORT_* events
    # into one run-length interval, so each interval is split by category and its
    # span emitted into whichever lane(s) its subset is non-empty. The port lane
    # is named after the monitored physical port ("tile C,R south slave 0") when
    # the evt_port descriptor is present, else "tile C,R port". A lane with no
    # events across the whole run is dropped, so port-less captures still render.
    evt_ports = ts.get("evt_ports", {})
    for tile in sorted(ts["traces"]):
        fit = fits.get(tile)
        intervals = ts["traces"][tile]
        core_events, port_events, mem_events = [], [], []
        if fit is not None:
            for s_cyc, e_cyc, names, stream in intervals:
                span = {
                    "start_us": fit.cycle_to_us(s_cyc),
                    "end_us": fit.cycle_to_us(e_cyc + 1),
                    "detail": "cycles %d..%d (%d cyc)" % (s_cyc, e_cyc, e_cyc - s_cyc + 1),
                }
                # The mem-module DMA stream (pkt id 2) is its own lane: its slot
                # names (DMA_START/.../LOCK_REL, and a STREAM_STALL that
                # collides with the core one) are NOT the core/port categories.
                if stream == "mem":
                    mem_events.append({"event": "|".join(names), **span})
                    continue
                core_names, port_names = _split_names(names)
                if core_names:
                    core_events.append({"event": "|".join(core_names), **span})
                if port_names:
                    port_events.append({"event": "|".join(port_names), **span})
        lanes.append({"name": "tile %d,%d core" % tile, "events": core_events})
        if port_events:
            suffix = evt_ports.get(tile, "port")
            lanes.append({"name": "tile %d,%d %s" % (tile[0], tile[1], suffix),
                          "events": port_events})
        if mem_events:
            lanes.append({"name": "tile %d,%d mem dma" % tile, "events": mem_events})

    meta = {"cps": cps, "counts_per_us": cps / 1e6,
            "host_span_us": host_counts_to_us(h1, cps, h0),
            "num_tiles": len(fits), "num_host_events": len(ts["hostevts"])}
    anchors = {
        "anchor0": {"host": h0, "tiles": {"%d,%d" % k: v for k, v in a0["tiles"].items()}},
        "anchor1": {"host": h1, "tiles": {"%d,%d" % k: v for k, v in a1["tiles"].items()}},
    }
    fit_per_tile = {"%d,%d" % t: f.as_dict() for t, f in fits.items()}
    return {"meta": meta, "anchors": anchors, "fit_per_tile": fit_per_tile, "lanes": lanes}


# --------------------------------------------------------------------------
# Emit CSV + JSON.
# --------------------------------------------------------------------------
def _csv_escape(s):
    s = str(s)
    if any(c in s for c in ',"\n'):
        return '"' + s.replace('"', '""') + '"'
    return s


def emit(model, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    csv_path = os.path.join(out_dir, "timeline.csv")
    json_path = os.path.join(out_dir, "timeline.json")

    rows = []
    for lane in model["lanes"]:
        for ev in lane["events"]:
            rows.append((lane["name"], ev["event"], ev["start_us"], ev["end_us"], ev["detail"]))

    with open(csv_path, "w") as f:
        f.write("lane,event,start_us,end_us,detail\n")
        for lane, event, s_us, e_us, detail in rows:
            f.write("%s,%s,%.6f,%.6f,%s\n" % (
                _csv_escape(lane), _csv_escape(event), s_us, e_us, _csv_escape(detail)))

    with open(json_path, "w") as f:
        json.dump(model, f, indent=2, sort_keys=True)
        f.write("\n")

    return csv_path, json_path, len(rows)


# --------------------------------------------------------------------------
# Self-test: synthetic TIMESYNC block with a known cycle->us mapping.
# --------------------------------------------------------------------------
def _self_test():
    # cps=1e6 -> 1 count == 1 us. Slope 1 count/cycle. Tile (4,4): a0=0,a1=1000.
    # h0=1000,h1=2000 -> us(cycle)=cycle. The dump already decoded the trace into
    # absolute-cycle interval lines: ACTIVE@10 (1 cyc), STREAM_STALL@110 (1 cyc).
    block = "\n".join([
        "[TIMESYNC] cps=1000000",
        "[TIMESYNC] anchor0 host=1000",
        "[TIMESYNC] anchor0 tile=4,4 aie=0",
        "[TIMESYNC] anchor1 host=2000",
        "[TIMESYNC] anchor1 tile=4,4 aie=1000",
        "[TIMESYNC] hostevt iter=0 phase=iter_start host=1000",
        "[TIMESYNC] hostevt iter=0 phase=run host=1500",
        "[TIMESYNC] aiehz tile=4,4 hz=1000000.000",
        # evt_port descriptor: names the port lane after the monitored port.
        '[aie_runtime] core_trace_stream_json: {"src_tile":[4,4],'
        '"evt_port":{"tile":[4,4],"port":"south","intf":"slave","num":0},'
        '"slots":["ACTIVE"],"hops":[]}',
        "[TIMESYNC] trace tile=4,4 words=16",
        "[TIMESYNC] trace tile=4,4 10  ACTIVE",
        "[TIMESYNC] trace tile=4,4 108 -- 112  STREAM_STALL  (5 cyc)",
        # Combined core+port interval: splits into the core lane (ACTIVE) and the
        # port lane (PORT_RUNNING_0) sharing the same span.
        "[TIMESYNC] trace tile=4,4 200 -- 209  ACTIVE|PORT_RUNNING_0  (10 cyc)",
        "[TIMESYNC] trace tile=4,4 210 -- 219  PORT_IDLE_0  (10 cyc)",
        # Mem-module DMA stream (pkt id 2): its own lane, own event names. Note
        # STREAM_STALL collides with the core table but stream=mem disambiguates.
        "[TIMESYNC] trace tile=4,4 stream=mem 300  DMA_START",
        "[TIMESYNC] trace tile=4,4 stream=mem 305 -- 309  STREAM_STALL  (5 cyc)",
    ])
    ts = parse_timesync(block)
    assert ts["cps"] == 1000000
    assert ts["evt_ports"] == {(4, 4): "south slave 0"}, ts["evt_ports"]
    assert ts["traces"][(4, 4)] == [
        (10, 10, ["ACTIVE"], "core"), (108, 112, ["STREAM_STALL"], "core"),
        (200, 209, ["ACTIVE", "PORT_RUNNING_0"], "core"), (210, 219, ["PORT_IDLE_0"], "core"),
        (300, 300, ["DMA_START"], "mem"), (305, 309, ["STREAM_STALL"], "mem")], ts["traces"]
    model = correlate(ts)
    host = next(l for l in model["lanes"] if l["name"] == "host")
    assert host["events"][0]["start_us"] == 0.0
    assert host["events"][1]["start_us"] == 500.0
    tile = next(l for l in model["lanes"] if l["name"] == "tile 4,4 core")
    # Two ACTIVE intervals share the same event name, so collect tuples (a dict
    # keyed by name would collapse them). us(cycle)==cycle; end covers end_cycle+1.
    spans = [(e["event"], e["start_us"], e["end_us"]) for e in tile["events"]]
    assert ("ACTIVE", 10.0, 11.0) in spans, spans
    assert ("STREAM_STALL", 108.0, 113.0) in spans, spans
    # The combined interval contributed ACTIVE to the core lane, not PORT_*.
    assert ("ACTIVE", 200.0, 210.0) in spans, spans
    assert not any("PORT_" in e for e, _, _ in spans), spans
    # The port lane is named after the monitored port and carries only PORT_*.
    port = next(l for l in model["lanes"] if l["name"] == "tile 4,4 south slave 0")
    pspans = {e["event"]: (e["start_us"], e["end_us"]) for e in port["events"]}
    assert pspans == {"PORT_RUNNING_0": (200.0, 210.0),
                      "PORT_IDLE_0": (210.0, 220.0)}, pspans
    # The port lane sits directly beneath its tile's core lane.
    names = [l["name"] for l in model["lanes"]]
    assert names.index("tile 4,4 south slave 0") == names.index("tile 4,4 core") + 1, names
    # The mem-module DMA stream is its OWN lane; its STREAM_STALL (cyc 305) must
    # NOT leak into the core lane (which only holds the core STREAM_STALL @108).
    mem = next(l for l in model["lanes"] if l["name"] == "tile 4,4 mem dma")
    mspans = {e["event"]: (e["start_us"], e["end_us"]) for e in mem["events"]}
    assert mspans == {"DMA_START": (300.0, 301.0),
                      "STREAM_STALL": (305.0, 310.0)}, mspans
    assert ("STREAM_STALL", 305.0, 310.0) not in spans, spans
    print("self-test OK: host, AIE core, AIE port, and AIE mem-dma lanes on one us axis")
    print("  host events:", [(e["event"], e["start_us"]) for e in host["events"]])
    print("  tile 4,4 core:", [(e["event"], e["start_us"], e["end_us"]) for e in tile["events"]])
    print("  tile 4,4 port:", port["name"],
          [(e["event"], e["start_us"], e["end_us"]) for e in port["events"]])
    print("  tile 4,4 mem :", [(e["event"], e["start_us"], e["end_us"]) for e in mem["events"]])
    return 0


# --------------------------------------------------------------------------
# CLI.
# --------------------------------------------------------------------------
def main(argv):
    ap = argparse.ArgumentParser(description="Merge host + AIE timelines from a [TIMESYNC] applog.")
    ap.add_argument("applog", nargs="?", help="applog / stdout capture containing the [TIMESYNC] block")
    ap.add_argument("--out-dir", default="/tmp/claude/tl", help="output directory for timeline.csv/json")
    ap.add_argument("--self-test", action="store_true", help="run the built-in synthetic self-test and exit")
    args = ap.parse_args(argv[1:])

    if args.self_test:
        return _self_test()

    if not args.applog:
        ap.error("applog is required (or use --self-test)")

    with open(args.applog) as f:
        text = f.read()

    ts = parse_timesync(text)
    model = correlate(ts)
    csv_path, json_path, nrows = emit(model, args.out_dir)

    m = model["meta"]
    print("[host_aie_timeline] cps=%d  tiles=%d  host_events=%d  rows=%d" % (
        m["cps"], m["num_tiles"], m["num_host_events"], nrows))
    print("[host_aie_timeline] host span: %.2f us" % m["host_span_us"])
    for t, f in sorted(model["fit_per_tile"].items()):
        print("[host_aie_timeline] tile %s: %.4f counts/cycle  aie=%.3f Hz" % (
            t, f["counts_per_cycle"], f["aie_hz"]))
    print("[host_aie_timeline] wrote %s" % csv_path)
    print("[host_aie_timeline] wrote %s" % json_path)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
