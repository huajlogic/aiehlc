#!/usr/bin/env python3
"""aiediag - Flow-aware DMA diagnostic tool for AIE.

Reads DMA status registers from live hardware via aiedbg, cross-references
with provenance map JSONs to identify connected tiles and routing paths,
and prints an automated diagnosis.
"""

import argparse
import json
import os
import re
import subprocess
import sys

# ─── ANSI color helpers ───────────────────────────────────────────────────────

def _supports_color():
    return hasattr(sys.stdout, "isatty") and sys.stdout.isatty()

_USE_COLOR = _supports_color()

def _c(code, text):
    if _USE_COLOR:
        return f"\033[{code}m{text}\033[0m"
    return text

def red(t):    return _c("31", t)
def green(t):  return _c("32", t)
def yellow(t): return _c("33", t)
def cyan(t):   return _c("36", t)
def bold(t):   return _c("1", t)

# ─── Constants ────────────────────────────────────────────────────────────────

DMA_STATUS_OFFSETS = {
    "core":    {"s2mm": 0x1DF00, "mm2s": 0x1DF10},
    "shim_5":  {"s2mm": 0x1D220, "mm2s": 0x1D228},
    "shim_2ps": {"s2mm": 0x9320, "mm2s": 0x9328},
}
CH_STRIDE = 0x4

# Shim PL module event status registers
SHIM_EVT_STATUS_REG0 = 0x00034200  # event IDs 0-31
SHIM_EVT_STATUS_REG1 = 0x00034204  # event IDs 32-63

# Event IDs for DMA channels on shim tiles (from shimtile_events.json)
# Keyed by (direction, channel) -> dict of event_name -> event_id
SHIM_DMA_EVENT_IDS = {
    ("s2mm", 0): {"START_TASK": 14, "FINISHED_TASK": 18, "STALLED_LOCK": 22,
                   "STREAM_STARVATION": 26, "MEMORY_BACKPRESSURE": 30},
    ("s2mm", 1): {"START_TASK": 15, "FINISHED_TASK": 19, "STALLED_LOCK": 23,
                   "STREAM_STARVATION": 27, "MEMORY_BACKPRESSURE": 31},
    ("mm2s", 0): {"START_TASK": 16, "FINISHED_TASK": 20, "STALLED_LOCK": 24,
                   "STREAM_BACKPRESSURE": 28, "MEMORY_STARVATION": 32},
    ("mm2s", 1): {"START_TASK": 17, "FINISHED_TASK": 21, "STALLED_LOCK": 25,
                   "STREAM_BACKPRESSURE": 29, "MEMORY_STARVATION": 33},
}

STATUS_NAMES = {0: "Idle", 1: "Running", 2: "Paused"}

# Bit positions
BIT_STALL_LOCK_ACQ = 2
BIT_STALL_LOCK_REL = 3
BIT_STALL_STREAM   = 4
BIT_STALL_TCT      = 5
BIT_ERR_BD_UNAVAIL  = 10
BIT_ERR_BD_INVALID  = 11
BIT_CH_RUNNING      = 19
Q_SIZE_LSB          = 20
Q_SIZE_BITS         = 3
CUR_BD_LSB          = 24
CUR_BD_BITS         = 4

# ─── Argument parsing ────────────────────────────────────────────────────────

def parse_args(argv=None):
    """Custom argument parser to handle -mm2s0/-s2mm1 style dir_ch args.

    argparse would interpret -mm2s0 as a flag, so we extract it manually
    from sys.argv before passing the rest to argparse.
    """
    raw_args = argv if argv is not None else sys.argv[1:]

    # Extract the dir_ch argument: first arg matching -mm2s\d or -s2mm\d
    dir_ch = None
    remaining = []
    for arg in raw_args:
        if dir_ch is None and re.match(r"^-(mm2s|s2mm)\d+$", arg, re.IGNORECASE):
            dir_ch = arg
        else:
            remaining.append(arg)

    parser = argparse.ArgumentParser(
        prog="aiediag",
        description="Flow-aware DMA diagnostic tool for AIE",
    )
    sub = parser.add_subparsers(dest="command")
    dig = sub.add_parser("dig", help="Dig into a tile's DMA channel")
    dig.add_argument("col", type=int, help="Logical column (from IR/JSON, 0-based)")
    dig.add_argument("row", type=int, help="Physical row (3-6 for core, 0 for shim)")
    dig.add_argument("startcol_kw", nargs="?", default=None,
                     help="Literal 'startcol' keyword")
    dig.add_argument("startcol_val", nargs="?", type=int, default=None,
                     help="startcol value (physical column offset)")
    dig.add_argument("--json-dir", default=None,
                     help="Directory containing JSON provenance maps (auto-searches common locations)")
    dig.add_argument("--aie-version", choices=["5", "2ps"], default="5",
                     help="AIE version: 5 (AIEML, default) or 2ps")
    dig.add_argument("--target", default=None,
                     help="Pass-through to aiedbg (e.g., baremetal://192.168.0.1:9999)")
    dig.add_argument("-dev", "--device", default=None,
                     help="Device type for aiedbg (e.g., pal)")
    dig.add_argument("--dry-run", action="store_true",
                     help="Skip aiedbg calls; print what would be read")
    dig.add_argument("--shim-events-json",
                     default=os.path.expanduser("~/aiejson/shimtile_events.json"),
                     help="Path to shimtile_events.json (default: ~/aiejson/shimtile_events.json)")

    args = parser.parse_args(remaining)
    args.dir_ch = dir_ch
    return args

def parse_dir_ch(raw):
    """Parse '-mm2s0' into ('mm2s', 0)."""
    s = raw.lstrip("-").lower()
    m = re.match(r"^(mm2s|s2mm)(\d+)$", s)
    if not m:
        print(f"Error: invalid dir_ch '{raw}'. Expected -mm2s0, -mm2s1, -s2mm0, -s2mm1", file=sys.stderr)
        sys.exit(1)
    return m.group(1), int(m.group(2))

# ─── JSON loading ─────────────────────────────────────────────────────────────

DFSCHE_FILENAME = "dfscheduleprovenancemap.json"
DMAPHOP_FILENAMES = ["dmaphopprovenacemap.json", "provenance_map.json"]

# Common directories to search (relative to cwd) when --json-dir is not given
_SEARCH_DIRS = [
    "./worklocal",
    "./aout/worklocal",
    "./src/mlir/mlirfront/tilinglinalg/pass/unitest/build/worklocal",
    "./src/mlir/mlirfront/tilinglinalg/pass/unitest/worklocal",
]

def _find_json_dir():
    """Auto-detect the directory containing the provenance map JSONs."""
    for d in _SEARCH_DIRS:
        if os.path.isfile(os.path.join(d, DFSCHE_FILENAME)):
            return d
    return None

def load_jsons(json_dir):
    if json_dir is None:
        json_dir = _find_json_dir()
        if json_dir is None:
            print(f"Error: cannot find {DFSCHE_FILENAME} in any of:", file=sys.stderr)
            for d in _SEARCH_DIRS:
                print(f"  {d}", file=sys.stderr)
            print("Use --json-dir to specify the directory.", file=sys.stderr)
            return None, None
        print(f"  Auto-detected JSON dir: {os.path.abspath(json_dir)}")

    dfsche_path = os.path.join(json_dir, DFSCHE_FILENAME)
    dmaphop_path = None
    for name in DMAPHOP_FILENAMES:
        candidate = os.path.join(json_dir, name)
        if os.path.exists(candidate):
            dmaphop_path = candidate
            break

    dfsche = None
    dmaphop = None

    if os.path.exists(dfsche_path):
        with open(dfsche_path) as f:
            dfsche = json.load(f)
    else:
        print(f"Warning: {dfsche_path} not found", file=sys.stderr)

    if dmaphop_path and os.path.exists(dmaphop_path):
        with open(dmaphop_path) as f:
            dmaphop = json.load(f)
    else:
        searched = [os.path.join(json_dir, n) for n in DMAPHOP_FILENAMES]
        print(f"Warning: dmaphop provenance map not found, searched: {searched}", file=sys.stderr)

    return dfsche, dmaphop

# ─── Register access ─────────────────────────────────────────────────────────

def compute_reg_offset(tile_type, direction, channel, aie_version):
    """Compute the register offset for DMA status."""
    if tile_type == "core":
        base_map = DMA_STATUS_OFFSETS["core"]
    elif tile_type == "shim":
        key = "shim_5" if aie_version == "5" else "shim_2ps"
        base_map = DMA_STATUS_OFFSETS[key]
    else:
        base_map = DMA_STATUS_OFFSETS["core"]
    base = base_map[direction]
    return base + channel * CH_STRIDE

def run_aiedbg_reg_read(phys_col, row, offset, target=None, device=None, dry_run=False):
    """Run aiedbg reg read and return the raw 32-bit value."""
    cmd = ["aiedbg"]
    if target:
        cmd += ["--target", target]
    if device:
        cmd += ["--device", device]
    cmd += ["reg", "read", str(phys_col), str(row), f"0x{offset:X}"]

    if dry_run:
        print(f"  [dry-run] would execute: {' '.join(cmd)}")
        return None

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
    except FileNotFoundError:
        print(f"Error: 'aiedbg' not found in PATH", file=sys.stderr)
        sys.exit(1)
    except subprocess.TimeoutExpired:
        print(f"Error: aiedbg timed out for tile({phys_col},{row})", file=sys.stderr)
        return None

    if result.returncode != 0:
        print(f"Warning: aiedbg returned error for tile({phys_col},{row}): {result.stderr.strip()}", file=sys.stderr)
        return None

    # Parse hex output from aiedbg
    out = result.stdout.strip()
    # Try to extract hex value — formats: "0xABCD", "ABCD", or "register = 0xABCD"
    m = re.search(r"(?:0x)?([0-9a-fA-F]+)", out)
    if m:
        return int(m.group(1), 16)
    print(f"Warning: could not parse aiedbg output: {out}", file=sys.stderr)
    return None

# ─── Status decode ────────────────────────────────────────────────────────────

def decode_dma_status(raw):
    """Decode the 32-bit DMA status register into a dict."""
    def bit(n):
        return bool(raw & (1 << n))
    def bits(lsb, width):
        return (raw >> lsb) & ((1 << width) - 1)

    return {
        "raw": raw,
        "status": raw & 0x3,
        "status_str": STATUS_NAMES.get(raw & 0x3, f"Unknown({raw & 0x3})"),
        "stall_lock_acq": bit(BIT_STALL_LOCK_ACQ),
        "stall_lock_rel": bit(BIT_STALL_LOCK_REL),
        "stall_stream":   bit(BIT_STALL_STREAM),
        "stall_tct":      bit(BIT_STALL_TCT),
        "err_bd_unavail":  bit(BIT_ERR_BD_UNAVAIL),
        "err_bd_invalid":  bit(BIT_ERR_BD_INVALID),
        "channel_running": bit(BIT_CH_RUNNING),
        "q_size":          bits(Q_SIZE_LSB, Q_SIZE_BITS),
        "cur_bd":          bits(CUR_BD_LSB, CUR_BD_BITS),
    }

def format_dma_status(col, row, direction, channel, decoded):
    """Format decoded DMA status as a multi-line string."""
    lines = []
    raw = decoded["raw"]
    lines.append(f"  raw=0x{raw:08X}  {decoded['status_str']}  "
                 f"running={int(decoded['channel_running'])}  "
                 f"q_size={decoded['q_size']}  "
                 f"cur_bd={decoded['cur_bd']}")

    stalls = []
    if decoded["stall_lock_acq"]: stalls.append("lock_acq")
    if decoded["stall_lock_rel"]: stalls.append("lock_rel")
    if decoded["stall_stream"]:   stalls.append("stream")
    if decoded["stall_tct"]:      stalls.append("tct")

    stall_line = (f"  STALLED: lock_acq={int(decoded['stall_lock_acq'])} "
                  f"lock_rel={int(decoded['stall_lock_rel'])} "
                  f"stream={int(decoded['stall_stream'])} "
                  f"tct={int(decoded['stall_tct'])}")
    lines.append(stall_line)

    errs = []
    if decoded["err_bd_unavail"]: errs.append("BD_UNAVAIL")
    if decoded["err_bd_invalid"]: errs.append("BD_INVALID")
    if errs:
        lines.append(red(f"  >> ERRORS: {', '.join(errs)}"))

    if decoded["stall_stream"]:
        if direction == "mm2s":
            lines.append(yellow(f"  >> STREAM STALL: backpressure from downstream"))
        else:
            lines.append(yellow(f"  >> STREAM STALL: no data from upstream"))
    if decoded["stall_lock_acq"]:
        if direction == "mm2s":
            lines.append(yellow(f"  >> LOCK ACQ STALL: kernel hasn't released output buffer"))
        else:
            lines.append(yellow(f"  >> LOCK ACQ STALL: DMA waiting for buffer to be available"))
    if decoded["stall_lock_rel"]:
        lines.append(yellow(f"  >> LOCK REL STALL: cannot release lock"))
    if decoded["status"] == 0 and not decoded["channel_running"]:
        lines.append(f"  >> IDLE: channel completed or never started")

    return "\n".join(lines)

# ─── Shim event status ────────────────────────────────────────────────────

def load_shim_events_json(path):
    """Load shimtile_events.json. Returns events dict or None if not found."""
    if not os.path.isfile(path):
        print(yellow(f"Warning: {path} not found, skipping shim event check"), file=sys.stderr)
        return None
    with open(path) as f:
        return json.load(f)

def read_shim_event_status(phys_col, direction, channel, target, device, dry_run):
    """Read event_status reg0+reg1 from shim tile (row=0), decode DMA events.

    Returns dict {event_name: bool} or None on failure.
    """
    key = (direction.lower(), channel)
    if key not in SHIM_DMA_EVENT_IDS:
        return None

    event_map = SHIM_DMA_EVENT_IDS[key]

    # Read reg0 (events 0-31) and reg1 (events 32-63)
    reg0 = run_aiedbg_reg_read(phys_col, 0, SHIM_EVT_STATUS_REG0,
                                target=target, device=device, dry_run=dry_run)
    reg1 = run_aiedbg_reg_read(phys_col, 0, SHIM_EVT_STATUS_REG1,
                                target=target, device=device, dry_run=dry_run)

    if dry_run:
        return None  # no data in dry-run, but commands were printed

    if reg0 is None and reg1 is None:
        return None

    result = {}
    for name, eid in event_map.items():
        if eid < 32:
            result[name] = bool((reg0 or 0) & (1 << eid))
        else:
            result[name] = bool((reg1 or 0) & (1 << (eid - 32)))
    return result

def format_shim_event_status(phys_col, direction, channel, event_bits, shim_events):
    """Format the shim event status for printing.

    Args:
        phys_col: physical column
        direction: 'mm2s' or 's2mm'
        channel: channel number
        event_bits: dict {event_name: bool} from read_shim_event_status
        shim_events: loaded shimtile_events.json (for display names), may be None
    """
    lines = []
    lines.append(f"  Shim events for {direction.upper()} ch{channel} (col {phys_col}):")

    key = (direction.lower(), channel)
    event_map = SHIM_DMA_EVENT_IDS.get(key, {})

    for name, eid in event_map.items():
        fired = event_bits.get(name, False)
        # Build display name from json if available
        display = f"DMA_{direction.upper()}_{channel}_{name}"
        if shim_events and str(eid) in shim_events:
            display = shim_events[str(eid)]
        tag = red("SET") if fired else "not set"
        lines.append(f"    {display + ':':<44s} {tag}")

    # Summary line
    started = event_bits.get("START_TASK", False)
    finished = event_bits.get("FINISHED_TASK", False)
    if started and finished:
        lines.append(green(f"    >> {direction.upper()} ch{channel} started and finished (DMA completed)"))
    elif started and not finished:
        lines.append(yellow(f"    >> {direction.upper()} ch{channel} was started but never finished (still running or stuck)"))
    elif not started:
        lines.append(yellow(f"    >> {direction.upper()} ch{channel} was never started (start_io not issued?)"))

    return "\n".join(lines)

# ─── JSON lookup helpers ──────────────────────────────────────────────────────

def find_tile_in_json(dfsche, col, row):
    """Find the tile entry matching (col, row) in tiles[]."""
    if not dfsche or "tiles" not in dfsche:
        return None
    for t in dfsche["tiles"]:
        if t["col"] == col and t["row"] == row:
            return t
    return None

def find_channel_in_tile(tile_entry, direction, channel):
    """Find the dma_channels entry matching direction+channel."""
    if not tile_entry or "dma_channels" not in tile_entry:
        return None
    dir_upper = direction.upper()
    for ch in tile_entry["dma_channels"]:
        if ch["channel"] == channel and ch["direction"] == dir_upper:
            return ch
    return None

def find_flow(dfsche, flow_index):
    """Find the flow_summary entry for the given flow_index."""
    if not dfsche or "flow_summary" not in dfsche:
        return None
    for f in dfsche["flow_summary"]:
        if f["flow_index"] == flow_index:
            return f
    return None

def find_connected_tiles(flow_entry, col, row, direction):
    """Given a flow_summary entry, find tiles that are NOT the queried tile.

    Returns list of dicts with tile_col, tile_row, channel, io_direction, etc.
    """
    if not flow_entry:
        return []
    connected = []
    for entry in flow_entry.get("entries", []):
        ec, er = entry["tile_col"], entry["tile_row"]
        if ec == col and er == row and entry["io_direction"].lower() == direction:
            continue
        connected.append(entry)
    return connected

def find_routing_paths(dmaphop, flow_index, flow_entry):
    """Find communication_paths from dmaphopprovenacemap.json that match this flow.

    Matching strategy: the path's producer+consumer tile set must match
    the flow_summary's tile set closely (endpoints, not just any overlap).
    We require that the path's endpoint tiles (producer+consumer, excluding
    passthrough hops) are a subset of the flow's tiles.
    """
    if not dmaphop or "communication_paths" not in dmaphop:
        return []

    if not flow_entry:
        return []

    # Build set of (col, row) from flow_summary entries
    flow_tiles = set()
    for e in flow_entry.get("entries", []):
        flow_tiles.add((e["tile_col"], e["tile_row"]))

    matches = []
    for path in dmaphop["communication_paths"]:
        path_endpoint_tiles = set()
        for stage in path.get("stages", []):
            if stage["role"] in ("producer", "consumer"):
                if "tile" in stage:
                    t = stage["tile"]
                    path_endpoint_tiles.add((t["col"], t["row"]))
                if "tiles" in stage:
                    for t in stage["tiles"]:
                        path_endpoint_tiles.add((t["col"], t["row"]))

        # Match if ALL path endpoint tiles are in the flow's tile set
        if path_endpoint_tiles and path_endpoint_tiles <= flow_tiles:
            matches.append(path)

    return matches

# ─── BD chain printing ───────────────────────────────────────────────────────

def format_bd_chain(channel_entry):
    """Format the BD chain from a dma_channels entry."""
    lines = []
    bd_chain = channel_entry.get("bd_chain", [])
    bd_ids = []
    for bd in bd_chain:
        bd_id = bd["bd_id"]
        bd_ids.append(bd_id)
        offset = bd.get("buffer_offset", 0)
        length = bd.get("len", 0)
        pkt_id = bd.get("packet_id", 0)
        enable_pkt = bd.get("enable_packet", False)
        next_bd = bd.get("next_bd", -1)
        ooo = bd.get("out_of_order_bd_id", None)

        acq = bd.get("acquire_lock", [{}])
        rel = bd.get("release_lock", [{}])
        acq_str = ",".join(f"lock({l['id']},{l['val']:+d})" for l in acq) if acq else "none"
        rel_str = ",".join(f"lock({l['id']},{l['val']:+d})" for l in rel) if rel else "none"

        pkt_str = f" pkt_id={pkt_id}" if enable_pkt else ""
        next_str = f" next->BD{next_bd}" if next_bd >= 0 else " next->NONE"
        ooo_str = f" ooo_bd={ooo}" if ooo is not None else ""

        # Shim-specific fields
        dim_str = ""
        if "dim_strides" in bd:
            strides = bd["dim_strides"]
            wraps = bd.get("dim_wraps", [])
            dim_str += f" strides={strides} wraps={wraps}"
        if "iter_step_size" in bd:
            dim_str += f" iter_step={bd['iter_step_size']} iter_wrap={bd.get('iter_wrap', 0)}"

        lines.append(f"  BD{bd_id}: offset={offset} len={length}B{pkt_str}{next_str}"
                     f" acq={acq_str} rel={rel_str}{ooo_str}{dim_str}")

    # Check ping-pong cycle
    if len(bd_ids) == 2:
        bd_a, bd_b = bd_chain[0], bd_chain[1]
        if bd_a.get("next_bd") == bd_b["bd_id"] and bd_b.get("next_bd") == bd_a["bd_id"]:
            lines.append(green(f"  Ping-pong: BD{bd_b['bd_id']}↔BD{bd_a['bd_id']} cycle OK"))
        elif bd_a.get("next_bd", -1) < 0 and bd_b.get("next_bd", -1) < 0:
            lines.append(f"  No ping-pong chain (next_bd=-1, likely shim OOO)")
        else:
            lines.append(yellow(f"  WARNING: ping-pong chain broken"))

    contract = channel_entry.get("contract", "")
    if contract:
        lines.append(f"  Contract: \"{contract}\"")

    start_io = channel_entry.get("start_io", [])
    for si in start_io:
        repeat = si.get("repeat_count", 0)
        scf = si.get("inside_scf_for", False)
        lr = si.get("loop_range", "")
        scf_str = f" (inside scf.for {lr})" if scf else ""
        lines.append(f"  start_io: repeat={repeat}{scf_str}")

    return "\n".join(lines)

# ─── Routing path printing ───────────────────────────────────────────────────

def format_routing_path(path):
    """Format a communication_path entry."""
    lines = []
    pid = path.get("id", "?")
    direction = path.get("direction", "?")
    lines.append(f"  {pid} ({direction}):")

    for stage in path.get("stages", []):
        role = stage["role"]
        if role == "producer":
            if "tile" in stage:
                t = stage["tile"]
                lines.append(f"    producer: tile({t['col']},{t['row']}) [{t['type']}]"
                             f" ch={stage.get('channel', '?')}")
            if "tiles" in stage:
                for t in stage["tiles"]:
                    pkt = t.get("pkt_id", "")
                    pkt_str = f" pkt_id={pkt}" if pkt else ""
                    lines.append(f"    producer: tile({t['col']},{t['row']}) [{t['type']}]"
                                 f" port={t.get('dma_port', '?')}{pkt_str}")
        elif role == "channel":
            for hop in stage.get("hops", []):
                lines.append(f"    hop: {hop['from']} -> {hop['to']}")
        elif role == "consumer":
            if "tile" in stage:
                t = stage["tile"]
                lines.append(f"    consumer: tile({t['col']},{t['row']}) [{t['type']}]"
                             f" ch={stage.get('channel', '?')}")
            if "tiles" in stage:
                for t in stage["tiles"]:
                    pkt = t.get("pkt_id", "")
                    pkt_str = f" pkt_id={pkt}" if pkt else ""
                    lines.append(f"    consumer: tile({t['col']},{t['row']}) [{t['type']}]"
                                 f" port={t.get('dma_port', '?')}{pkt_str}")

    return "\n".join(lines)

# ─── Diagnosis engine ────────────────────────────────────────────────────────

def diagnose(direction, queried_decoded, connected_results,
             queried_shim_events=None, connected_shim_events=None,
             queried_row=None):
    """Produce diagnostic messages based on status of queried and connected tiles.

    Args:
        direction: 'mm2s' or 's2mm'
        queried_decoded: decoded status dict of the queried tile (or None)
        connected_results: list of (col, row, dir, ch, decoded_or_None) for connected tiles
        queried_shim_events: dict {event_name: bool} for queried tile if shim, or None
        connected_shim_events: dict keyed by (col, row, dir, ch) -> {event_name: bool}
        queried_row: row of queried tile (0 = shim)
    """
    if connected_shim_events is None:
        connected_shim_events = {}
    lines = []

    if queried_decoded is None:
        lines.append("Cannot diagnose: no register data for queried tile (dry-run or error)")
        return "\n".join(lines)

    q = queried_decoded

    # Check errors first
    if q["err_bd_unavail"]:
        lines.append(red("HW ERROR: BD_UNAVAIL — no BD queued for this channel"))
    if q["err_bd_invalid"]:
        lines.append(red("HW ERROR: BD_INVALID — BD configuration error"))

    # Idle
    if q["status"] == 0 and not q["channel_running"]:
        # Use shim events to disambiguate "never started" vs "completed"
        if queried_shim_events and queried_row == 0:
            started = queried_shim_events.get("START_TASK", False)
            finished = queried_shim_events.get("FINISHED_TASK", False)
            if started and finished:
                lines.append("Channel is IDLE — completed all programmed transfers")
            elif started and not finished:
                lines.append(yellow("Channel is IDLE (status) but START_TASK set without FINISHED — abnormal"))
            else:
                lines.append("Channel is IDLE — never started (START_TASK not set)")
        else:
            lines.append("Channel is IDLE — completed all transfers or never started")
        # Check if connected tiles are still active
        for cc, cr, cd, cch, cdec in connected_results:
            if cdec and (cdec["channel_running"] or cdec["status"] != 0):
                lines.append(yellow(f"  But connected tile({cc},{cr}) {cd.upper()} ch{cch} is still active!"))
        return "\n".join(lines)

    # Stream stall diagnosis
    # Track which connected tiles were already diagnosed via shim events
    shim_diagnosed = set()
    if q["stall_stream"]:
        if direction == "mm2s":
            lines.append(f"{direction.upper()} ch has STREAM BACKPRESSURE")
            for cc, cr, cd, cch, cdec in connected_results:
                if cdec is None:
                    lines.append(f"  tile({cc},{cr}) {cd.upper()} ch{cch}: no register data")
                    continue
                if cd.lower() == "s2mm":
                    if cdec["status"] == 0 and not cdec["channel_running"]:
                        # Use shim events to disambiguate idle shim tiles
                        evt = connected_shim_events.get((cc, cr, cd, cch))
                        if evt:
                            shim_diagnosed.add((cc, cr, cd, cch))
                            started = evt.get("START_TASK", False)
                            finished = evt.get("FINISHED_TASK", False)
                            if started and finished:
                                lines.append(yellow(f"  >> Receiver tile({cc},{cr}) S2MM ch{cch} completed all programmed transfers — repeat/iter_wrap too low?"))
                            elif not started:
                                lines.append(yellow(f"  >> Receiver tile({cc},{cr}) S2MM ch{cch} never started (START_TASK not set — start_io not issued)"))
                            else:
                                lines.append(yellow(f"  >> Receiver tile({cc},{cr}) S2MM ch{cch} started but not finished — stuck"))
                        else:
                            lines.append(yellow(f"  >> Receiver tile({cc},{cr}) S2MM ch{cch} is IDLE — never started or completed"))
                    elif cdec["stall_stream"]:
                        lines.append(yellow(f"  >> Receiver tile({cc},{cr}) S2MM ch{cch} also stream-stalled — possible routing congestion"))
                    elif cdec["stall_lock_acq"]:
                        lines.append(yellow(f"  >> Receiver tile({cc},{cr}) S2MM ch{cch} lock-stalled — kernel not consuming input"))
        else:
            lines.append(f"{direction.upper()} ch has STREAM STARVATION")
            for cc, cr, cd, cch, cdec in connected_results:
                if cdec is None:
                    lines.append(f"  tile({cc},{cr}) {cd.upper()} ch{cch}: no register data")
                    continue
                if cd.lower() == "mm2s":
                    if cdec["status"] == 0 and not cdec["channel_running"]:
                        # Use shim events to disambiguate idle shim tiles
                        evt = connected_shim_events.get((cc, cr, cd, cch))
                        if evt:
                            shim_diagnosed.add((cc, cr, cd, cch))
                            started = evt.get("START_TASK", False)
                            finished = evt.get("FINISHED_TASK", False)
                            if started and finished:
                                lines.append(yellow(f"  >> Sender tile({cc},{cr}) MM2S ch{cch} completed all programmed transfers — repeat/iter_wrap too low?"))
                            elif not started:
                                lines.append(yellow(f"  >> Sender tile({cc},{cr}) MM2S ch{cch} never started (START_TASK not set — start_io not issued)"))
                            else:
                                lines.append(yellow(f"  >> Sender tile({cc},{cr}) MM2S ch{cch} started but not finished — stuck"))
                        else:
                            lines.append(yellow(f"  >> Sender tile({cc},{cr}) MM2S ch{cch} is IDLE — never started (check start_io)"))
                    elif cdec["stall_lock_acq"]:
                        lines.append(yellow(f"  >> Sender tile({cc},{cr}) MM2S ch{cch} lock-stalled — kernel hasn't produced output"))

    # Lock stall diagnosis
    if q["stall_lock_acq"]:
        if direction == "mm2s":
            lines.append(f"{direction.upper()} ch stalled on LOCK ACQUIRE — kernel hasn't released output buffer (check core status)")
        else:
            lines.append(f"{direction.upper()} ch stalled on LOCK ACQUIRE — DMA waiting for kernel to consume input buffer")

    if q["stall_lock_rel"]:
        lines.append(f"{direction.upper()} ch stalled on LOCK RELEASE")

    if q["stall_tct"]:
        lines.append(f"{direction.upper()} ch stalled on TCT (task count)")

    if not lines:
        if q["status"] == 1:
            lines.append(green("Channel is Running normally"))
        elif q["status"] == 2:
            lines.append(yellow("Channel is Paused"))
        else:
            lines.append(f"Channel status: {q['status_str']}")

    # Shim event diagnosis (only for tiles not already diagnosed above)
    # Queried tile shim events
    if queried_shim_events and queried_row == 0:
        started = queried_shim_events.get("START_TASK", False)
        finished = queried_shim_events.get("FINISHED_TASK", False)
        if not started:
            lines.append(yellow(f"Shim {direction.upper()}: START_TASK not set — start_io not issued"))
        elif started and not finished:
            lines.append(yellow(f"Shim {direction.upper()}: started but not finished (transfer in progress or stuck)"))
        elif started and finished:
            lines.append(green(f"Shim {direction.upper()}: DMA completed normally"))

    # Connected shim tile events — skip tiles already covered in stream stall diagnosis
    for cc, cr, cd, cch, cdec in connected_results:
        if (cc, cr, cd, cch) in shim_diagnosed:
            continue
        evt = connected_shim_events.get((cc, cr, cd, cch))
        if not evt:
            continue
        started = evt.get("START_TASK", False)
        finished = evt.get("FINISHED_TASK", False)
        if not started:
            lines.append(yellow(f"Shim tile({cc},{cr}) {cd.upper()} ch{cch}: START_TASK not set — start_io not issued"))
        elif started and not finished:
            lines.append(yellow(f"Shim tile({cc},{cr}) {cd.upper()} ch{cch}: started but not finished (transfer in progress or stuck)"))
        elif started and finished:
            lines.append(green(f"Shim tile({cc},{cr}) {cd.upper()} ch{cch}: DMA completed normally"))

    return "\n".join(lines)

# ─── Main ─────────────────────────────────────────────────────────────────────

def main(argv=None):
    args = parse_args(argv)

    if args.command != "dig":
        print("Usage: aiediag dig COL ROW -DIR_CH [startcol N] [--json-dir PATH]", file=sys.stderr)
        sys.exit(1)

    if args.dir_ch is None:
        print("Error: missing -DIR_CH argument (e.g., -mm2s0, -s2mm1)", file=sys.stderr)
        sys.exit(1)

    col = args.col
    row = args.row
    direction, channel = parse_dir_ch(args.dir_ch)

    startcol = 0
    if args.startcol_kw and args.startcol_kw.lower() == "startcol" and args.startcol_val is not None:
        startcol = args.startcol_val
    elif args.startcol_kw is not None:
        # Maybe user passed startcol as a positional without the keyword
        try:
            startcol = int(args.startcol_kw)
        except ValueError:
            if args.startcol_kw.lower() == "startcol":
                pass  # startcol keyword without value, default 0
            else:
                print(f"Error: unexpected argument '{args.startcol_kw}'", file=sys.stderr)
                sys.exit(1)

    phys_col = col + startcol
    tile_type = "shim" if row == 0 else "core"
    aie_version = args.aie_version
    dry_run = args.dry_run
    target = args.target
    device = args.device
    json_dir = args.json_dir

    # ── Header ────────────────────────────────────────────────────────────
    print(bold("=" * 58))
    print(bold(" aiediag: DMA Diagnostic"))
    print(bold("=" * 58))
    print(f"Target tile: ({phys_col},{row})  [logical: col={col}, row={row}, startcol={startcol}]")
    print(f"Channel: {direction.upper()} ch{channel}")
    print(f"Tile type: {tile_type}, AIE version: {aie_version}")
    print()

    # ── Load JSONs ────────────────────────────────────────────────────────
    dfsche, dmaphop = load_jsons(json_dir)
    shim_events = load_shim_events_json(args.shim_events_json)

    # ── Step 1: Read DMA status of queried tile ───────────────────────────
    offset = compute_reg_offset(tile_type, direction, channel, aie_version)
    print(bold(f"--- [1] DMA Status: tile({phys_col},{row}) {direction.upper()} ch{channel} ---"))
    raw = run_aiedbg_reg_read(phys_col, row, offset, target=target, device=device, dry_run=dry_run)
    queried_decoded = None
    if raw is not None:
        queried_decoded = decode_dma_status(raw)
        print(format_dma_status(phys_col, row, direction, channel, queried_decoded))
    print()

    # ── Step 2: BD chain from JSON ────────────────────────────────────────
    tile_entry = find_tile_in_json(dfsche, col, row)
    ch_entry = find_channel_in_tile(tile_entry, direction, channel) if tile_entry else None
    flow_index = None

    print(bold(f"--- [2] BD Chain (from JSON) ---"))
    if ch_entry:
        flow_index = ch_entry.get("flow_index")
        print(f"  Flow index: {flow_index} ({ch_entry.get('direction', '').upper()})")
        print(format_bd_chain(ch_entry))
    else:
        if tile_entry:
            avail = [(c["direction"], c["channel"]) for c in tile_entry.get("dma_channels", [])]
            print(f"  Channel {direction.upper()} ch{channel} not found for tile({col},{row})")
            print(f"  Available channels: {avail}")
        else:
            print(f"  Tile ({col},{row}) not found in dfscheduleprovenancemap.json")
    print()

    # ── Step 3: Find connected tiles ──────────────────────────────────────
    flow_entry = find_flow(dfsche, flow_index) if flow_index is not None else None

    print(bold(f"--- [3] Connected tiles (flow {flow_index}) ---"))
    connected = []
    if flow_entry:
        flow_dir = flow_entry.get("direction", "?")
        print(f"  Flow direction: {flow_dir}")
        connected = find_connected_tiles(flow_entry, col, row, direction)
        if connected:
            senders = [c for c in connected if c["io_direction"].upper() == "MM2S"]
            receivers = [c for c in connected if c["io_direction"].upper() == "S2MM"]

            if receivers:
                print("  Receivers:")
                for c in receivers:
                    scf_str = ""
                    if c.get("inside_scf_for"):
                        scf_str = f" (scf.for {c.get('loop_range', '')})"
                    print(f"    tile({c['tile_col']},{c['tile_row']}) "
                          f"{c['io_direction']} ch{c['channel']} "
                          f"repeat={c.get('repeat_count', '?')} "
                          f"bd_len={c.get('bd_len', '?')}B{scf_str}")
            if senders:
                print("  Senders:")
                for c in senders:
                    scf_str = ""
                    if c.get("inside_scf_for"):
                        scf_str = f" (scf.for {c.get('loop_range', '')})"
                    print(f"    tile({c['tile_col']},{c['tile_row']}) "
                          f"{c['io_direction']} ch{c['channel']} "
                          f"repeat={c.get('repeat_count', '?')} "
                          f"bd_len={c.get('bd_len', '?')}B{scf_str}")
        else:
            print("  No other tiles found in this flow")
    else:
        print("  Flow summary not available")
    print()

    # ── Step 4: Read DMA status of connected tiles ────────────────────────
    print(bold(f"--- [4] Connected tile DMA Status ---"))
    connected_results = []
    for c in connected:
        cc = c["tile_col"]
        cr = c["tile_row"]
        c_dir = c["io_direction"].lower()
        c_ch = c["channel"]
        c_type = "shim" if cr == 0 else "core"
        c_phys_col = cc + startcol
        c_offset = compute_reg_offset(c_type, c_dir, c_ch, aie_version)

        print(f"  tile({c_phys_col},{cr}) {c_dir.upper()} ch{c_ch}:")
        c_raw = run_aiedbg_reg_read(c_phys_col, cr, c_offset, target=target, device=device, dry_run=dry_run)
        c_decoded = None
        if c_raw is not None:
            c_decoded = decode_dma_status(c_raw)
            print(format_dma_status(c_phys_col, cr, c_dir, c_ch, c_decoded))
        connected_results.append((cc, cr, c_dir, c_ch, c_decoded))
    if not connected:
        print("  (none)")
    print()

    # ── Step 4b: Shim event status ───────────────────────────────────────
    queried_shim_events = None
    connected_shim_events = {}  # keyed by (col, row, dir, ch)
    if shim_events is not None:
        print(bold(f"--- [4b] Shim Event Status ---"))
        # Queried tile
        if row == 0:
            queried_shim_events = read_shim_event_status(
                phys_col, direction, channel, target, device, dry_run)
            if queried_shim_events:
                print(format_shim_event_status(phys_col, direction, channel,
                                               queried_shim_events, shim_events))
            elif not dry_run:
                print(f"  Could not read shim events for tile({phys_col},0)")
        # Connected shim tiles
        for c in connected:
            cc = c["tile_col"]
            cr = c["tile_row"]
            if cr != 0:
                continue
            c_dir = c["io_direction"].lower()
            c_ch = c["channel"]
            c_phys_col = cc + startcol
            evt = read_shim_event_status(c_phys_col, c_dir, c_ch, target, device, dry_run)
            if evt:
                print(format_shim_event_status(c_phys_col, c_dir, c_ch, evt, shim_events))
                connected_shim_events[(cc, cr, c_dir, c_ch)] = evt
            elif not dry_run:
                print(f"  Could not read shim events for tile({c_phys_col},0)")
        if row != 0 and not any(c["tile_row"] == 0 for c in connected):
            print("  No shim tiles in this flow")
        print()
    else:
        print(bold(f"--- [4b] Shim Event Status ---"))
        print(yellow("  Skipped (shimtile_events.json not loaded)"))
        print()

    # ── Step 5: BD info for connected tiles ───────────────────────────────
    print(bold(f"--- [5] Connected tile BD chains ---"))
    for c in connected:
        cc = c["tile_col"]
        cr = c["tile_row"]
        c_dir = c["io_direction"]
        c_ch = c["channel"]
        c_tile = find_tile_in_json(dfsche, cc, cr)
        c_ch_entry = find_channel_in_tile(c_tile, c_dir.lower(), c_ch) if c_tile else None
        if c_ch_entry:
            print(f"  tile({cc},{cr}) {c_dir} ch{c_ch}:")
            print(format_bd_chain(c_ch_entry))
        else:
            print(f"  tile({cc},{cr}) {c_dir} ch{c_ch}: not found in JSON")
    if not connected:
        print("  (none)")
    print()

    # ── Step 6: Routing path from dmaphopprovenacemap.json ────────────────
    print(bold(f"--- [6] Routing path (from dmaphopprovenacemap.json) ---"))
    paths = find_routing_paths(dmaphop, flow_index, flow_entry)
    if paths:
        for p in paths:
            print(format_routing_path(p))
    else:
        print("  No matching routing path found")
    print()

    # ── Step 7: Diagnosis ─────────────────────────────────────────────────
    print(bold(f"--- [7] Diagnosis ---"))
    diag = diagnose(direction, queried_decoded, connected_results,
                    queried_shim_events=queried_shim_events,
                    connected_shim_events=connected_shim_events,
                    queried_row=row)
    print(diag)
    print()
    print(bold("=" * 58))


if __name__ == "__main__":
    main()
