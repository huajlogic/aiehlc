#!/usr/bin/env python3
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: MIT
"""
Stream switch hardware configuration visualizer.

Parses the JSON output produced by AieRt_PrintStreamSwitchConfig / All
(from src/mlir/runtime/aie_runtime_debug.c) and renders an interactive
HTML page showing the tile grid with stream switch state per tile:

  - Master ports: PKT / CIRC / CTRL, drop-header annotation
  - Slave ports + slots: match mode (exact / wildcard / partial), pkt_id
  - Inter-tile arrows derived from master port directions (NORTH/SOUTH/EAST/WEST)
  - Color coding: PKT=purple, CIRC=blue, CTRL=grey, exact-match slot=red warn
  - Tooltip on every arrow and slot showing event 148 risk

Default input:  src/mlir/mlirfront/tilinglinalg/pass/data/streamswitch.log
Default output: streamswitch_hw.html  (then served via HTTP)

Usage:
    python streamswitch_hw_viz.py                          # uses default log
    python streamswitch_hw_viz.py hwlog2                   # positional log file
    python streamswitch_hw_viz.py --input path/to/log      # named argument
    python streamswitch_hw_viz.py hwlog2 -o out.html --no-serve
    python streamswitch_hw_viz.py hwlog2 --port 8090
"""

import argparse
import http.server
import json
import re
import socket
import sys
import webbrowser
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# ---------------------------------------------------------------------------
# Default log path (absolute)
# ---------------------------------------------------------------------------

_DEFAULT_LOG = Path(
    "/scratch/staff/huaj/amdaiehlc/aiehlc/src/mlir/mlirfront/tilinglinalg/pass/data/streamswitch.log"
)

# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------

DIRECTIONS = {"NORTH", "SOUTH", "EAST", "WEST"}
DIRECTION_DELTA = {"NORTH": (0, 1), "SOUTH": (0, -1), "EAST": (1, 0), "WEST": (-1, 0)}
DIRECTION_OPPOSITE = {"NORTH": "SOUTH", "SOUTH": "NORTH", "EAST": "WEST", "WEST": "EAST"}


def _dir_of(port_name: str) -> Optional[str]:
    """Return canonical direction string if port is a directional port, else None."""
    for d in DIRECTIONS:
        if port_name.startswith(d):
            return d
    return None


# ---------------------------------------------------------------------------
# Parser — the log is a sequence of JSON objects, possibly not wrapped in [ ]
# ---------------------------------------------------------------------------

def parse_log(text: str) -> List[dict]:
    """Parse a stream of JSON objects from the log file.

    AieRt_PrintStreamSwitchConfig emits one JSON object per tile without
    commas between them.  AieRt_PrintStreamSwitchConfigAll wraps them in
    [ ... ].  Both formats are supported.
    """
    text = text.strip()
    if not text:
        return []

    # Try direct array parse first
    if text.startswith("["):
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            pass

    # Split on top-level { ... } objects
    tiles: List[dict] = []
    depth = 0
    start = -1
    for i, ch in enumerate(text):
        if ch == "{":
            if depth == 0:
                start = i
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0 and start >= 0:
                fragment = text[start : i + 1]
                try:
                    obj = json.loads(fragment)
                    tiles.append(obj)
                except json.JSONDecodeError:
                    pass
                start = -1
    return tiles


# ---------------------------------------------------------------------------
# Derive inter-tile connections from master port directions
# ---------------------------------------------------------------------------

def _port_num(port_name: str) -> int:
    """Extract trailing port number from port name, e.g. 'EAST1' -> 1."""
    m = re.search(r"(\d+)$", port_name)
    return int(m.group(1)) if m else 0


def build_cross_tile_arrows(tiles: List[dict]) -> List[dict]:
    """For each enabled master port pointing in a cardinal direction, emit an arrow
    to the neighbouring tile.  The arrow carries switch_type, pkt_id (if PKT),
    and drop_header metadata for rendering."""
    arrows = []
    tile_set = {
        (t["tile"]["col"], t["tile"]["row"])
        for t in tiles
    }
    for tile in tiles:
        col = tile["tile"]["col"]
        row = tile["tile"]["row"]
        for master in tile.get("masters", []):
            if not master.get("enabled"):
                continue
            port = master["port"]
            d = _dir_of(port)
            if d is None:
                continue
            dc, dr = DIRECTION_DELTA[d]
            nb = (col + dc, row + dr)
            # Only draw if neighbour tile is in the log
            if nb not in tile_set:
                continue
            opp_dir = DIRECTION_OPPOSITE[d]
            port_num = _port_num(port)
            arrow = {
                "from_tile": [col, row],
                "to_tile": list(nb),
                "from_dir": d,
                "to_dir": opp_dir,
                "port": port_num,
                "port_name": port,
                "slave_port_name": f"{opp_dir}{port_num}",
                "switch_type": master.get("switch_type", "CIRC"),
                "drop_header": master.get("drop_header", False),
                "drop_header_note": master.get("drop_header_note", ""),
                "pkt_id": None,  # will be resolved below if PKT
            }
            arrows.append(arrow)
    return arrows


# ---------------------------------------------------------------------------
# Color helpers
# ---------------------------------------------------------------------------

_TYPE_COLORS = {
    "PKT":  {"bg": "#EDE7F6", "border": "#7B1FA2", "fg": "#4A148C"},
    "CIRC": {"bg": "#E3F2FD", "border": "#1565C0", "fg": "#0D47A1"},
    "CTRL": {"bg": "#F5F5F5", "border": "#9E9E9E", "fg": "#616161"},
}

_MATCH_COLORS = {
    "exact":    {"bg": "#FFEBEE", "border": "#C62828", "fg": "#B71C1C"},
    "wildcard": {"bg": "#E8F5E9", "border": "#2E7D32", "fg": "#1B5E20"},
    "partial":  {"bg": "#FFF3E0", "border": "#E65100", "fg": "#BF360C"},
}

_ARROW_COLORS = {
    "PKT":  "#7B1FA2",
    "CIRC": "#1565C0",
    "CTRL": "#9E9E9E",
}


def _type_style(sw_type: str) -> str:
    c = _TYPE_COLORS.get(sw_type, _TYPE_COLORS["CTRL"])
    return f"background:{c['bg']};border-color:{c['border']};color:{c['fg']}"


def _match_style(mode: str) -> str:
    c = _MATCH_COLORS.get(mode, _MATCH_COLORS["partial"])
    return f"background:{c['bg']};border:1px solid {c['border']};color:{c['fg']}"


# ---------------------------------------------------------------------------
# HTML rendering
# ---------------------------------------------------------------------------

def _esc(s: str) -> str:
    return str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


def _render_master(m: dict, col: int, row: int) -> str:
    sw = m.get("switch_type", "CIRC")
    enabled = m.get("enabled", False)
    pkt = m.get("packet_switch", False)
    drop = m.get("drop_header", False)
    note = m.get("drop_header_note", "")
    port = m.get("port", "?")
    style = _type_style(sw)
    opacity = "1" if enabled else "0.4"
    elem_id = f"mport-{col}-{row}-{port}"

    drop_badge = ""
    if pkt:
        if drop:
            drop_badge = '<span class="badge badge-drop" title="Drops header before forwarding">DROP_HDR</span>'
        else:
            drop_badge = '<span class="badge badge-keep" title="Preserves header for downstream slave">KEEP_HDR</span>'

    tooltip = _esc(note) if note else _esc(f"port={port} type={sw}")
    return (
        f'<div id="{elem_id}" class="port-row" style="{style};opacity:{opacity}" title="{tooltip}">'
        f'<span class="port-name">{_esc(port)}</span>'
        f'<span class="type-badge">{_esc(sw)}</span>'
        f'{drop_badge}'
        f'</div>'
    )


def _render_slot(slot: dict) -> str:
    mode = slot.get("match_mode", "partial")
    pkt_id = slot.get("pkt_id", "?")
    mask = slot.get("pkt_mask", "?")
    note = slot.get("match_note", "")
    style = _match_style(mode)
    tooltip = _esc(note) if note else _esc(f"mode={mode} pkt_id={pkt_id} mask={mask}")
    warn = ' &#x26A0;' if mode == "exact" else ""
    return (
        f'<span class="slot-badge" style="{style}" title="{tooltip}">'
        f'slot:{slot.get("slot","?")} id={pkt_id} {_esc(mode)}{warn}'
        f'</span>'
    )


def _render_slave(s: dict, col: int, row: int) -> str:
    sw = s.get("switch_type", "CIRC")
    enabled = s.get("enabled", False)
    port = s.get("port", "?")
    style = _type_style(sw)
    opacity = "1" if enabled else "0.4"
    elem_id = f"sport-{col}-{row}-{port}"
    slots_html = ""
    active_slots = [sl for sl in s.get("slots", []) if sl.get("enabled")]
    if active_slots:
        slots_html = "".join(_render_slot(sl) for sl in active_slots)

    return (
        f'<div id="{elem_id}" class="port-row slave-row" style="{style};opacity:{opacity}">'
        f'<span class="port-name">{_esc(port)}</span>'
        f'<span class="type-badge">{_esc(sw)}</span>'
        f'{slots_html}'
        f'</div>'
    )


def _render_tile_card(tile: dict, min_col: int, max_row: int) -> str:
    col = tile["tile"]["col"]
    row = tile["tile"]["row"]
    tile_type = tile["tile"]["type"]

    gc = col - min_col + 1
    gr = max_row - row + 1

    type_cls = tile_type.lower()

    masters = tile.get("masters", [])
    slaves  = tile.get("slaves", [])
    active_masters = [m for m in masters if m.get("enabled")]
    active_slaves  = [s for s in slaves  if s.get("enabled") or any(sl.get("enabled") for sl in s.get("slots", []))]

    is_active = bool(active_masters or active_slaves)

    masters_html = ""
    if active_masters:
        rows = "".join(_render_master(m, col, row) for m in active_masters)
        masters_html = (
            f'<div class="section-hdr" onclick="toggleSection(this)">&#x25BC; Masters ({len(active_masters)})</div>'
            f'<div class="section-body expanded">{rows}</div>'
        )

    slaves_html = ""
    if active_slaves:
        rows = "".join(_render_slave(s, col, row) for s in active_slaves)
        slaves_html = (
            f'<div class="section-hdr slave-hdr" onclick="toggleSection(this)">&#x25BC; Slaves ({len(active_slaves)})</div>'
            f'<div class="section-body expanded">{rows}</div>'
        )

    return (
        f'<div class="tile-card {type_cls}{"" if is_active else " inactive"}" '
        f'id="tile-{col}-{row}" data-col="{col}" data-row="{row}" '
        f'style="grid-column:{gc};grid-row:{gr}">'
        f'<div class="tile-hdr">({col},{row}) {tile_type}</div>'
        f'{slaves_html}'
        f'{masters_html}'
        f'</div>'
    )


# ---------------------------------------------------------------------------
# Full HTML page
# ---------------------------------------------------------------------------

def render_html(tiles: List[dict], arrows: List[dict], output_path: str) -> str:
    if not tiles:
        print("No tiles to render.", file=sys.stderr)
        return output_path

    all_cols = sorted({t["tile"]["col"] for t in tiles})
    all_rows = sorted({t["tile"]["row"] for t in tiles}, reverse=True)
    min_col = all_cols[0]
    max_row = all_rows[0]
    ncols = len(all_cols)
    nrows = len(all_rows)

    tile_cards = "".join(
        _render_tile_card(t, min_col, max_row) for t in sorted(
            tiles, key=lambda t: (-t["tile"]["row"], t["tile"]["col"])
        )
    )

    arrows_json = json.dumps(arrows)

    html = f"""\
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AIE Stream Switch HW Configuration</title>
<style>
* {{ margin:0; padding:0; box-sizing:border-box; }}
body {{
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    background: #f0f2f5; padding: 20px; color: #333;
}}
h1 {{ text-align:center; margin-bottom:6px; font-size:21px; color:#1a1a2e; }}
.subtitle {{ text-align:center; margin-bottom:14px; font-size:12px; color:#888; }}

/* ---- controls ---- */
.controls {{
    display:flex; justify-content:center; gap:10px;
    margin-bottom:14px; flex-wrap:wrap;
}}
.controls button {{
    padding:5px 14px; border:1px solid #bbb; border-radius:6px;
    background:#fff; cursor:pointer; font-size:12px; font-weight:600;
    transition:all .15s;
}}
.controls button:hover {{ background:#e3f2fd; border-color:#42a5f5; }}
.controls button.active {{ background:#1976d2; color:#fff; border-color:#1976d2; }}

/* ---- legend ---- */
.legend {{
    display:flex; gap:12px; justify-content:center;
    margin-bottom:14px; font-size:11px; flex-wrap:wrap;
    align-items:center;
}}
.legend-item {{ display:flex; align-items:center; gap:4px; }}
.legend-swatch {{
    width:13px; height:13px; border-radius:3px; border:2px solid;
    flex-shrink:0;
}}

/* ---- grid ---- */
.grid-outer {{ display:flex; justify-content:center; }}
.grid-wrapper {{ position:relative; display:inline-block; }}
.grid {{
    display:grid;
    grid-template-columns: repeat({ncols}, 260px);
    grid-template-rows: repeat({nrows}, auto);
    gap:12px;
    position:relative; z-index:1;
}}
svg.overlay {{
    position:absolute; top:0; left:0;
    width:100%; height:100%;
    pointer-events:none; z-index:10;
}}

/* ---- tile cards ---- */
.tile-card {{
    border:2px solid #bbb; border-radius:10px;
    padding:8px; min-height:60px;
    background:#fff; transition:box-shadow .15s, transform .15s;
}}
.tile-card:hover {{ box-shadow:0 4px 16px rgba(0,0,0,.15); transform:translateY(-1px); }}
.tile-card.inactive {{ opacity:0.35; }}
.tile-card.shim {{ background:#c8e6c9; border-color:#2e7d32; }}
.tile-card.core {{ background:#fffde7; border-color:#fdd835; }}
.tile-card.mem  {{ background:#e8f5e9; border-color:#66bb6a; }}
.tile-hdr {{
    font-weight:700; font-size:13px;
    padding-bottom:4px; border-bottom:1px solid #ddd;
    margin-bottom:5px;
}}
.section-hdr {{
    font-size:11px; font-weight:700; color:#555;
    cursor:pointer; padding:2px 0; user-select:none;
    transition:color .1s;
}}
.section-hdr:hover {{ color:#1976d2; }}
.slave-hdr {{ color:#5d4037; }}
.slave-hdr:hover {{ color:#bf360c; }}
.section-body {{ overflow:hidden; transition:max-height .3s ease; }}
.section-body.expanded {{ max-height:600px; }}
.section-body.collapsed {{ max-height:0; }}

/* ---- port rows ---- */
.port-row {{
    display:flex; align-items:center; gap:4px; flex-wrap:wrap;
    padding:3px 6px; margin:2px 0; border-radius:4px;
    border-left:3px solid transparent; font-size:10px;
    font-family:monospace;
}}
.slave-row {{ border-left-width:2px; border-style:dashed; }}
.port-name {{ font-weight:700; min-width:52px; }}
.type-badge {{
    font-size:9px; font-weight:800; padding:1px 5px;
    border-radius:3px; background:rgba(0,0,0,.08);
    flex-shrink:0;
}}

/* ---- badges ---- */
.badge {{
    font-size:9px; font-weight:700; padding:1px 5px; border-radius:3px; flex-shrink:0;
}}
.badge-drop {{ background:#fce4ec; color:#c62828; border:1px solid #ef9a9a; }}
.badge-keep {{ background:#e8f5e9; color:#2e7d32; border:1px solid #a5d6a7; }}

/* ---- slot badges ---- */
.slot-badge {{
    font-size:9px; padding:1px 5px; border-radius:3px; margin-left:2px;
    flex-shrink:0;
}}

/* ---- tooltip ---- */
.arrow-tip {{
    position:absolute; background:rgba(30,30,30,.92); color:#fff;
    padding:4px 10px; border-radius:5px; font-size:11px;
    pointer-events:none; z-index:100; white-space:nowrap;
    display:none; font-family:monospace;
}}
</style>
</head>
<body>
<h1>AIE Stream Switch — HW Configuration</h1>
<div class="subtitle">Parsed from AieRt_PrintStreamSwitchConfig JSON output</div>

<div class="controls">
    <button onclick="expandAll()">Expand All</button>
    <button onclick="collapseAll()">Collapse All</button>
    <button id="btn-arrows" class="active" onclick="toggleArrows(this)">Stream Arrows</button>
</div>

<div class="legend">
    <div class="legend-item">
        <div class="legend-swatch" style="background:#EDE7F6;border-color:#7B1FA2"></div> PKT (packet-switch)
    </div>
    <div class="legend-item">
        <div class="legend-swatch" style="background:#E3F2FD;border-color:#1565C0"></div> CIRC (circuit-switch)
    </div>
    <div class="legend-item">
        <div class="legend-swatch" style="background:#F5F5F5;border-color:#9E9E9E"></div> CTRL / FIFO / TRACE
    </div>
    <div class="legend-item">
        <div class="legend-swatch" style="background:#FFEBEE;border-color:#C62828"></div> exact slot (event 148 risk)
    </div>
    <div class="legend-item">
        <div class="legend-swatch" style="background:#E8F5E9;border-color:#2E7D32"></div> wildcard slot (merge point)
    </div>
    <div class="legend-item">
        <div class="legend-swatch" style="background:#fce4ec;border-color:#ef9a9a"></div> DROP_HEADER
    </div>
    <div class="legend-item">
        <div class="legend-swatch" style="background:#e8f5e9;border-color:#a5d6a7"></div> KEEP_HEADER
    </div>
    <div class="legend-item">
        <div class="legend-swatch" style="background:#fffde7;border-color:#fdd835"></div> CORE tile
    </div>
    <div class="legend-item">
        <div class="legend-swatch" style="background:#c8e6c9;border-color:#2e7d32"></div> SHIM tile
    </div>
</div>

<div class="grid-outer">
<div class="grid-wrapper">
<div class="grid" id="tile-grid">
{tile_cards}
</div>
<svg class="overlay" id="routing-svg">
<defs>
    <marker id="arr-pkt"  markerWidth="8" markerHeight="6" refX="7" refY="3" orient="auto">
        <polygon points="0 0,8 3,0 6" fill="#7B1FA2"/>
    </marker>
    <marker id="arr-circ" markerWidth="8" markerHeight="6" refX="7" refY="3" orient="auto">
        <polygon points="0 0,8 3,0 6" fill="#1565C0"/>
    </marker>
    <marker id="arr-ctrl" markerWidth="8" markerHeight="6" refX="7" refY="3" orient="auto">
        <polygon points="0 0,8 3,0 6" fill="#9E9E9E"/>
    </marker>
</defs>
</svg>
<div class="arrow-tip" id="arrow-tip"></div>
</div>
</div>

<script>
const ARROWS = {arrows_json};
let arrowsVisible = true;

/* ---- section toggle ---- */
function toggleSection(hdr) {{
    const body = hdr.nextElementSibling;
    if (body.classList.contains('collapsed')) {{
        body.classList.remove('collapsed'); body.classList.add('expanded');
        hdr.innerHTML = hdr.innerHTML.replace('\\u25B6','\\u25BC');
    }} else {{
        body.classList.remove('expanded'); body.classList.add('collapsed');
        hdr.innerHTML = hdr.innerHTML.replace('\\u25BC','\\u25B6');
    }}
    setTimeout(drawArrows, 320);
}}
function expandAll() {{
    document.querySelectorAll('.section-body').forEach(b => {{
        b.classList.remove('collapsed'); b.classList.add('expanded');
    }});
    document.querySelectorAll('.section-hdr').forEach(h => {{
        h.innerHTML = h.innerHTML.replace('\\u25B6','\\u25BC');
    }});
    setTimeout(drawArrows, 320);
}}
function collapseAll() {{
    document.querySelectorAll('.section-body').forEach(b => {{
        b.classList.remove('expanded'); b.classList.add('collapsed');
    }});
    document.querySelectorAll('.section-hdr').forEach(h => {{
        h.innerHTML = h.innerHTML.replace('\\u25BC','\\u25B6');
    }});
    setTimeout(drawArrows, 320);
}}
function toggleArrows(btn) {{
    arrowsVisible = !arrowsVisible;
    btn.classList.toggle('active', arrowsVisible);
    document.getElementById('routing-svg').style.display = arrowsVisible ? '' : 'none';
}}

/* ---- arrow drawing ---- */
function drawArrows() {{
    const svg     = document.getElementById('routing-svg');
    const wrapper = document.querySelector('.grid-wrapper');
    const wRect   = wrapper.getBoundingClientRect();

    svg.setAttribute('width',   wrapper.offsetWidth);
    svg.setAttribute('height',  wrapper.offsetHeight);
    svg.setAttribute('viewBox', `0 0 ${{wrapper.offsetWidth}} ${{wrapper.offsetHeight}}`);

    [...svg.querySelectorAll('.data-arrow')].forEach(el => el.remove());

    // Build tile-card element map for fallback positioning
    const tileEls = {{}};
    document.querySelectorAll('.tile-card').forEach(card => {{
        tileEls[card.dataset.col + ',' + card.dataset.row] = card;
    }});

    const tip   = document.getElementById('arrow-tip');
    const dedup = new Set();

    ARROWS.forEach(arrow => {{
        const fromKey = arrow.from_tile[0] + ',' + arrow.from_tile[1];
        const toKey   = arrow.to_tile[0]   + ',' + arrow.to_tile[1];

        const deKey = `${{fromKey}}-${{toKey}}-${{arrow.port_name}}-${{arrow.switch_type}}`;
        if (dedup.has(deKey)) return;
        dedup.add(deKey);

        // Try exact port-element lookup first
        const fromPortId = `mport-${{arrow.from_tile[0]}}-${{arrow.from_tile[1]}}-${{arrow.port_name}}`;
        const toPortId   = `sport-${{arrow.to_tile[0]}}-${{arrow.to_tile[1]}}-${{arrow.slave_port_name}}`;
        const fromPortEl = document.getElementById(fromPortId);
        const toPortEl   = document.getElementById(toPortId);

        let x1, y1, x2, y2;
        const portLevelConnect = fromPortEl && toPortEl;

        if (portLevelConnect) {{
            // Port-to-port: connect right edge midpoint of master row
            // to left edge midpoint of slave row (or top/bottom for N/S)
            const fPR = fromPortEl.getBoundingClientRect();
            const tPR = toPortEl.getBoundingClientRect();
            const d   = arrow.from_dir;

            if (d === 'EAST') {{
                x1 = fPR.right  - wRect.left;
                y1 = fPR.top + fPR.height / 2 - wRect.top;
                x2 = tPR.left   - wRect.left;
                y2 = tPR.top + tPR.height / 2 - wRect.top;
            }} else if (d === 'WEST') {{
                x1 = fPR.left   - wRect.left;
                y1 = fPR.top + fPR.height / 2 - wRect.top;
                x2 = tPR.right  - wRect.left;
                y2 = tPR.top + tPR.height / 2 - wRect.top;
            }} else if (d === 'NORTH') {{
                x1 = fPR.left + fPR.width / 2 - wRect.left;
                y1 = fPR.top    - wRect.top;
                x2 = tPR.left + tPR.width / 2 - wRect.left;
                y2 = tPR.bottom - wRect.top;
            }} else {{ // SOUTH
                x1 = fPR.left + fPR.width / 2 - wRect.left;
                y1 = fPR.bottom - wRect.top;
                x2 = tPR.left + tPR.width / 2 - wRect.left;
                y2 = tPR.top    - wRect.top;
            }}
        }} else {{
            // Fallback: tile-edge midpoint (slave port not rendered / not active)
            const fromEl = tileEls[fromKey];
            const toEl   = tileEls[toKey];
            if (!fromEl || !toEl) return;

            const fR  = fromEl.getBoundingClientRect();
            const tR  = toEl.getBoundingClientRect();
            const off = (arrow.port - 0.5) * 14;

            switch (arrow.from_dir) {{
                case 'NORTH':
                    x1 = fR.left + fR.width/2 + off - wRect.left; y1 = fR.top    - wRect.top;
                    x2 = tR.left + tR.width/2 + off - wRect.left; y2 = tR.bottom - wRect.top;
                    break;
                case 'SOUTH':
                    x1 = fR.left + fR.width/2 + off - wRect.left; y1 = fR.bottom - wRect.top;
                    x2 = tR.left + tR.width/2 + off - wRect.left; y2 = tR.top    - wRect.top;
                    break;
                case 'EAST':
                    x1 = fR.right - wRect.left; y1 = fR.top + fR.height/2 + off - wRect.top;
                    x2 = tR.left  - wRect.left; y2 = tR.top + tR.height/2 + off - wRect.top;
                    break;
                case 'WEST':
                    x1 = fR.left  - wRect.left; y1 = fR.top + fR.height/2 + off - wRect.top;
                    x2 = tR.right - wRect.left; y2 = tR.top + tR.height/2 + off - wRect.top;
                    break;
            }}
        }}

        const sw       = arrow.switch_type;
        const color    = sw === 'PKT' ? '#7B1FA2' : sw === 'CIRC' ? '#1565C0' : '#9E9E9E';
        const markerId = sw === 'PKT' ? 'arr-pkt'  : sw === 'CIRC' ? 'arr-circ' : 'arr-ctrl';
        const dashArr  = sw === 'PKT' ? '6,3' : 'none';

        const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
        line.classList.add('data-arrow');
        line.setAttribute('x1', x1); line.setAttribute('y1', y1);
        line.setAttribute('x2', x2); line.setAttribute('y2', y2);
        line.setAttribute('stroke', color);
        line.setAttribute('stroke-width', sw === 'CIRC' ? '2.5' : '2');
        if (dashArr !== 'none') line.setAttribute('stroke-dasharray', dashArr);
        line.setAttribute('marker-end', `url(#${{markerId}})`);
        line.style.pointerEvents = 'stroke';
        line.style.cursor = 'pointer';

        const drop    = arrow.drop_header ? 'DROP_HEADER' : (sw === 'PKT' ? 'KEEP_HEADER' : '');
        const portTgt = portLevelConnect
            ? `${{arrow.port_name}} → ${{arrow.slave_port_name}}`
            : `${{arrow.port_name}} → (tile edge fallback)`;
        const tipText = `(${{fromKey}}) ${{portTgt}} (${{toKey}}) [${{sw}}${{drop ? ' ' + drop : ''}}]${{arrow.drop_header_note ? ': ' + arrow.drop_header_note : ''}}`;

        line.addEventListener('mouseenter', () => {{
            tip.textContent = tipText;
            tip.style.display = 'block';
        }});
        line.addEventListener('mousemove', e => {{
            tip.style.left = (e.clientX - wRect.left + 10) + 'px';
            tip.style.top  = (e.clientY - wRect.top  - 24) + 'px';
        }});
        line.addEventListener('mouseleave', () => {{ tip.style.display = 'none'; }});

        svg.appendChild(line);
    }});
}}

window.addEventListener('load', () => {{ drawArrows(); }});
window.addEventListener('resize', drawArrows);
</script>
</body>
</html>
"""
    Path(output_path).write_text(html)
    print(f"HTML saved to {output_path}")
    return output_path


# ---------------------------------------------------------------------------
# HTTP server
# ---------------------------------------------------------------------------

def serve_html(html_path: str, port: int) -> None:
    abs_path = Path(html_path).resolve()
    directory = str(abs_path.parent)
    filename = abs_path.name

    class Handler(http.server.SimpleHTTPRequestHandler):
        def __init__(self, *a, **kw):
            super().__init__(*a, directory=directory, **kw)
        def log_message(self, fmt, *args):
            pass

    hostname = socket.gethostname()
    local_url  = f"http://localhost:{port}/{filename}"
    remote_url = f"http://{hostname}:{port}/{filename}"
    print("Serving stream switch visualization:")
    print(f"  Local:  {local_url}")
    print(f"  Remote: {remote_url}")
    print("  (Ctrl+C to stop)")

    server = http.server.HTTPServer(("0.0.0.0", port), Handler)
    try:
        webbrowser.open(local_url)
    except Exception:
        pass
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
        server.shutdown()


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Visualize AIE stream switch HW configuration from "
            "AieRt_PrintStreamSwitchConfig JSON log."
        )
    )
    parser.add_argument(
        "logfile",
        nargs="?",
        default=None,
        help=f"Log file to visualize (default: {_DEFAULT_LOG})",
    )
    parser.add_argument(
        "--input", "-i",
        default=None,
        help=f"Path to streamswitch.log (default: {_DEFAULT_LOG})",
    )
    parser.add_argument(
        "-o", "--output",
        default="streamswitch_hw.html",
        help="Output HTML file (default: streamswitch_hw.html)",
    )
    parser.add_argument(
        "--no-serve", action="store_true",
        help="Write HTML only, do not start HTTP server",
    )
    parser.add_argument(
        "--port", type=int, default=8091,
        help="HTTP server port (default: 8091)",
    )
    args = parser.parse_args()

    # Positional arg takes priority, then --input, then default
    input_path = Path(args.logfile if args.logfile else (args.input if args.input else str(_DEFAULT_LOG)))
    if not input_path.exists():
        print(f"Error: log file not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    text = input_path.read_text()
    tiles = parse_log(text)
    if not tiles:
        print("No tile data found in log.", file=sys.stderr)
        sys.exit(1)

    active = [t for t in tiles if t.get("masters") or t.get("slaves")]
    print(f"Parsed {len(tiles)} tiles ({len(active)} with active ports)")

    arrows = build_cross_tile_arrows(tiles)
    print(f"Derived {len(arrows)} cross-tile stream arrows")

    render_html(tiles, arrows, args.output)

    if not args.no_serve:
        serve_html(args.output, args.port)


if __name__ == "__main__":
    main()
