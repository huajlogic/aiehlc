#!/usr/bin/env python3
"""Matplotlib GUI for the host<->AIE merged timeline (timeline.json).

Reads the JSON produced by host_aie_timeline.py (schema: meta / anchors /
fit_per_tile / lanes[{name, events:[{event,start_us,end_us,detail}]}]) and draws
a Gantt-style diagram of HORIZONTAL timelines on ONE microsecond axis:

  * one horizontal lane per model["lanes"] entry (host first, then tiles),
  * the "host" lane is a horizontal timeline of BARS between consecutive phase
    markers -- BLUE where the host is running (setup / DMA-in / DMA-out / verify)
    and GREY HATCHED where the host is idle-WAITING on the AIE (the run->wait_done
    gap that brackets XAie_CoreWaitForDone),
  * every tile event is a horizontal bar start_us..end_us, COLOURED by event
    type (ACTIVE=AIE running / LOCK_STALL / STREAM_STALL / MEMORY_STALL / other),
    so the tile's green ACTIVE bar lines up UNDER the host's waiting bar,
  * light dashed vertical guides mark the host phase boundaries across all lanes,
  * pan/zoom via matplotlib's built-in toolbar, hover for per-event detail.

Headless-safe: with no $DISPLAY (or with --save) it uses the Agg backend and
writes a PNG instead of opening a window.

Usage:
    timeline_gui.py <timeline.json>                 # window (or PNG if headless)
    timeline_gui.py <timeline.json> --save out.png  # force PNG
    timeline_gui.py --self-test                     # synthetic render, no file
"""

import argparse
import json
import os
import sys

# --------------------------------------------------------------------------
# Event-type -> colour. Slots 0..3 follow __Runtime_core_trace_setup.
# --------------------------------------------------------------------------
EVENT_COLORS = {
    "ACTIVE": "#2ca02c",        # green
    "LOCK_STALL": "#ff7f0e",    # orange
    "STREAM_STALL": "#d62728",  # red
    "MEMORY_STALL": "#9467bd",  # purple
    # Stream-switch port state (slots 4..6), rendered on the per-tile port lane.
    "PORT_RUNNING_0": "#17becf",  # teal
    "PORT_STALLED_0": "#e377c2",  # pink
    "PORT_IDLE_0": "#bcbcbc",     # light grey
}
# Stall slots take colour priority over ACTIVE in a combined label: a core is
# reported ACTIVE even while blocked, so the stall should be what you see.
STALL_ORDER = ("LOCK_STALL", "STREAM_STALL", "MEMORY_STALL")
OTHER_COLOR = "#7f7f7f"         # grey (multi-event or unknown)
HOST_LINE_COLOR = "#1f77b4"     # blue guide lines / host-running bars
HOST_RUNNING_COLOR = "#1f77b4"  # blue: host busy (setup / DMA / verify)
HOST_WAIT_COLOR = "#c7c7c7"     # grey hatched: host idle-waiting on the AIE

# The host phase whose *following* gap is spent blocked in XAie_CoreWaitForDone:
# the bar from the "run" marker to the next marker ("wait_done") is host-idle.
HOST_WAIT_PHASES = {"run"}


def rasterize_lane(events, x_lo, x_hi, nbins):
    """Per-pixel dominant-state colouring for one tile lane.

    Splits [x_lo, x_hi] into `nbins` equal bins (one per rendered pixel column)
    and, for each bin, sums how long each colour occupies it; the colour with
    the most time wins. This makes a short burst survive as its bin's dominant
    colour instead of being overpainted by an adjacent bar (the failure mode of
    per-event rectangles). Empty bins produce no segment. Adjacent bins with the
    same colour are merged into one span.

    Returns [(seg_start_us, seg_end_us, color_hex), ...] left-to-right.
    """
    if nbins < 1 or x_hi <= x_lo or not events:
        return []
    bw = (x_hi - x_lo) / nbins
    # Per-bin colour->overlap-duration accumulator.
    acc = [dict() for _ in range(nbins)]
    for ev in events:
        s = max(ev["start_us"], x_lo)
        e = min(ev["end_us"], x_hi)
        if e <= s:
            continue
        col = event_color(ev["event"])
        b0 = int((s - x_lo) / bw)
        b1 = int((e - x_lo) / bw)
        if b1 >= nbins:
            b1 = nbins - 1
        for b in range(b0, b1 + 1):
            bin_lo = x_lo + b * bw
            bin_hi = bin_lo + bw
            overlap = min(e, bin_hi) - max(s, bin_lo)
            if overlap > 0.0:
                acc[b][col] = acc[b].get(col, 0.0) + overlap

    # Dominant colour per bin (None when empty), then merge adjacent runs.
    segs = []
    for b in range(nbins):
        if not acc[b]:
            continue
        col = max(acc[b].items(), key=lambda kv: kv[1])[0]
        bin_lo = x_lo + b * bw
        bin_hi = bin_lo + bw
        if segs and segs[-1][2] == col and abs(segs[-1][1] - bin_lo) < bw * 1e-6:
            segs[-1] = (segs[-1][0], bin_hi, col)
        else:
            segs.append((bin_lo, bin_hi, col))
    return segs


def event_color(event):
    """Colour for an event label. A '|'-joined multi-event prefers a stall
    token over ACTIVE, so an ACTIVE|LOCK_STALL span shows the stall colour
    (a core can be ACTIVE while blocked on a lock/stream/memory). Falls back
    to the first recognised token, else grey."""
    toks = str(event).split("|")
    for tok in toks:
        if tok in STALL_ORDER:
            return EVENT_COLORS[tok]
    for tok in toks:
        if tok in EVENT_COLORS:
            return EVENT_COLORS[tok]
    return OTHER_COLOR


# --------------------------------------------------------------------------
# Model access.
# --------------------------------------------------------------------------
def load_model(path):
    with open(path) as f:
        return json.load(f)


def is_host_lane(lane):
    return lane.get("name") == "host"


def tile_lanes(model):
    return [l for l in model["lanes"] if not is_host_lane(l)]


def host_lane(model):
    for l in model["lanes"]:
        if is_host_lane(l):
            return l
    return None


def _parse_host_marker(event):
    """Split a host event label 'iter<N>.<phase>' into (iter, phase).
    Returns (None, event) if it does not match that shape."""
    s = str(event)
    if s.startswith("iter") and "." in s:
        head, phase = s.split(".", 1)
        try:
            return int(head[4:]), phase
        except ValueError:
            return None, s
    return None, s


def host_intervals(hl):
    """Turn the host lane's phase markers into horizontal bars, one per gap
    between consecutive markers. Each bar is a dict:
        {start_us, end_us, phase, iter, waiting, label, detail}
    'waiting' is True for the run->wait_done gap (host blocked in
    XAie_CoreWaitForDone); every other gap is host-running work."""
    if hl is None:
        return []
    evs = sorted(hl["events"], key=lambda e: e["start_us"])
    bars = []
    for cur, nxt in zip(evs, evs[1:]):
        it, phase = _parse_host_marker(cur["event"])
        x0 = cur["start_us"]
        x1 = nxt["start_us"]
        if x1 <= x0:
            continue
        waiting = phase in HOST_WAIT_PHASES
        bars.append({
            "start_us": x0, "end_us": x1, "phase": phase, "iter": it,
            "waiting": waiting,
            "label": ("wait" if waiting else phase),
            "detail": "%s -> %s" % (cur["event"], nxt["event"]),
        })
    return bars


# --------------------------------------------------------------------------
# Rendering.
# --------------------------------------------------------------------------
def _pick_backend(save, want_window):
    """Choose a matplotlib backend BEFORE importing pyplot. Returns
    (show_window, save_path_or_None)."""
    has_display = bool(os.environ.get("DISPLAY")) or sys.platform == "darwin"
    if save or not (want_window and has_display):
        import matplotlib
        matplotlib.use("Agg")
        return False, (save or "timeline.png")
    return True, None


def _draw(ax, model, nbins=2000):
    """Draw all lanes onto ax as HORIZONTAL timelines on one us axis. Returns a
    hover index: a list of (x0, x1, y0, y1, event_dict, lane_name) tuples.

    `nbins` is the number of rasterisation columns for tile lanes (set by
    render() to the figure's pixel width).

    Row 0 is the host lane: one bar per gap between consecutive phase markers,
    BLUE where the host is running and GREY HATCHED where it is idle-waiting on
    the AIE (the run->wait_done gap). Rows 1.. are the tiles, bars coloured by
    event type, so a tile's green ACTIVE bar lines up under the host wait bar."""
    hl = host_lane(model)
    tiles = tile_lanes(model)
    row_names = (["host"] if hl is not None else []) + [l["name"] for l in tiles]
    host_row = 0 if hl is not None else None
    tile_row0 = 1 if hl is not None else 0
    n_rows = len(row_names)
    row_h = 0.8
    hover = []  # (x0, x1, y0, y1, event, lane_name)

    # Full x-range across every lane; tile lanes are rasterised into `nbins`
    # columns over this range so per-pixel dominant colouring is stable.
    all_x = [e["start_us"] for l in model["lanes"] for e in l["events"]] + \
            [e["end_us"] for l in model["lanes"] for e in l["events"]]
    x_lo = min(all_x) if all_x else 0.0
    x_hi = max(all_x) if all_x else 1.0

    # Host lane (row 0): running vs idle-waiting bars.
    if hl is not None:
        y0 = host_row - row_h / 2.0
        for bar in host_intervals(hl):
            x0 = bar["start_us"]
            w = bar["end_us"] - bar["start_us"]
            kw = dict(edgecolors="black", linewidth=0.4)
            if bar["waiting"]:
                kw.update(facecolors=HOST_WAIT_COLOR, hatch="//")
            else:
                kw.update(facecolors=HOST_RUNNING_COLOR)
            ax.broken_barh([(x0, w)], (y0, row_h), **kw)
            ax.text(x0 + w / 2.0, host_row, bar["label"], fontsize=6,
                    color="black", va="center", ha="center", zorder=5)
            ev = {"event": bar["label"], "start_us": bar["start_us"],
                  "end_us": bar["end_us"], "detail": bar["detail"]}
            hover.append((x0, x0 + w, y0, y0 + row_h, ev, "host"))

    # Tile lanes: one row each, drawn with per-pixel dominant-state colouring.
    # Each bin (~one screen column) is filled with the colour that occupies most
    # of its time, so a short burst survives as its bin's dominant colour instead
    # of being overpainted by an adjacent bar. Hover still reports true per-event
    # spans (unaffected by rasterisation).
    for i, lane in enumerate(tiles):
        row = tile_row0 + i
        y0 = row - row_h / 2.0
        for s_us, e_us, color in rasterize_lane(lane["events"], x_lo, x_hi, nbins):
            ax.broken_barh([(s_us, e_us - s_us)], (y0, row_h),
                           facecolors=color, edgecolors="none")
        for ev in lane["events"]:
            x0 = ev["start_us"]
            x1 = x0 + max(ev["end_us"] - ev["start_us"], 0.0)
            hover.append((x0, x1, y0, y0 + row_h, ev, lane["name"]))

    # Light dashed vertical guides at each host phase boundary, across all rows.
    if hl is not None and n_rows > 0:
        ytop = n_rows - 1 + row_h
        ybot = -row_h
        for ev in hl["events"]:
            x = ev["start_us"]
            ax.plot([x, x], [ybot, ytop], linestyle="--", linewidth=0.6,
                    color=HOST_LINE_COLOR, alpha=0.35, zorder=0)
            ax.text(x, ybot, ev["event"], rotation=90, fontsize=5,
                    color=HOST_LINE_COLOR, va="top", ha="center", alpha=0.8)

    ax.set_yticks(range(n_rows))
    ax.set_yticklabels(row_names)
    ax.set_ylim(-1.0, max(n_rows - 1 + 1.0, 1.0))
    ax.invert_yaxis()  # host on top, then tiles
    ax.set_xlabel("time (us, t=0 at host anchor0)")

    meta = model.get("meta", {})
    ax.set_title("AIE/host timeline  cps=%s  tiles=%s  host_span=%.2f us" % (
        meta.get("cps", "?"), meta.get("num_tiles", len(tiles)),
        meta.get("host_span_us", 0.0)))
    return hover


def _add_legend(ax, model):
    from matplotlib.patches import Patch
    handles = []
    # Host running/waiting bars, if a host lane is present.
    hl = host_lane(model)
    if hl is not None:
        bars = host_intervals(hl)
        if any(not b["waiting"] for b in bars):
            handles.append(Patch(facecolor=HOST_RUNNING_COLOR, edgecolor="black",
                                 label="host running"))
        if any(b["waiting"] for b in bars):
            handles.append(Patch(facecolor=HOST_WAIT_COLOR, edgecolor="black",
                                 hatch="//", label="host waiting (AIE)"))
    present = set()
    for lane in tile_lanes(model):
        for ev in lane["events"]:
            present.add(ev["event"])
    friendly = {
        "ACTIVE": "AIE running",
        "PORT_RUNNING_0": "port running",
        "PORT_STALLED_0": "port stalled",
        "PORT_IDLE_0": "port idle",
    }
    for name, col in EVENT_COLORS.items():
        if any(name in p.split("|") for p in present):
            label = friendly.get(name, name)
            handles.append(Patch(facecolor=col, edgecolor="black", label=label))
    if any(not set(p.split("|")) & set(EVENT_COLORS) for p in present):
        handles.append(Patch(facecolor=OTHER_COLOR, edgecolor="black", label="other"))
    if handles:
        ax.legend(handles=handles, loc="upper right", fontsize=7, framealpha=0.9)


def _attach_hover(fig, ax, hover):
    """Show an annotation with the event under the cursor."""
    ann = ax.annotate("", xy=(0, 0), xytext=(12, 12), textcoords="offset points",
                      bbox=dict(boxstyle="round", fc="#ffffcc", ec="black", alpha=0.95),
                      fontsize=7, zorder=10)
    ann.set_visible(False)

    def find(x, y):
        # Prefer a bar hit; a host marker matches within a small x tolerance.
        xtol = (ax.get_xlim()[1] - ax.get_xlim()[0]) * 0.004 + 1e-9
        for x0, x1, y0, y1, ev, lane in hover:
            if y0 <= y <= y1:
                if x0 == x1:
                    if abs(x - x0) <= xtol:
                        return ev, lane
                elif x0 <= x <= x1:
                    return ev, lane
        return None

    def on_move(event):
        if event.inaxes != ax or event.xdata is None:
            if ann.get_visible():
                ann.set_visible(False)
                fig.canvas.draw_idle()
            return
        hit = find(event.xdata, event.ydata)
        if hit is None:
            if ann.get_visible():
                ann.set_visible(False)
                fig.canvas.draw_idle()
            return
        ev, lane = hit
        ann.xy = (event.xdata, event.ydata)
        ann.set_text("%s / %s\n%.3f .. %.3f us\n%s" % (
            lane, ev["event"], ev["start_us"], ev["end_us"], ev.get("detail", "")))
        ann.set_visible(True)
        fig.canvas.draw_idle()

    fig.canvas.mpl_connect("motion_notify_event", on_move)


def render(model, save=None, want_window=True):
    """Build the figure. If not showing a window, write a PNG to `save`
    (default 'timeline.png') and return its path; else show() and return None."""
    show_window, save_path = _pick_backend(save, want_window)
    import matplotlib.pyplot as plt

    n = len(tile_lanes(model)) + (1 if host_lane(model) is not None else 0)
    n = max(n, 1)
    fig, ax = plt.subplots(figsize=(12, 1.2 + 0.6 * n))
    # One rasterisation bin per horizontal pixel of the figure.
    nbins = max(int(fig.get_figwidth() * fig.dpi), 100)
    hover = _draw(ax, model, nbins)
    _add_legend(ax, model)
    ax.grid(True, axis="x", linestyle=":", alpha=0.4)
    fig.tight_layout()

    if show_window:
        _attach_hover(fig, ax, hover)
        plt.show()
        return None
    fig.savefig(save_path, dpi=130)
    plt.close(fig)
    return save_path


# --------------------------------------------------------------------------
# Self-test: synthetic 2-tile model (no file, no board).
# --------------------------------------------------------------------------
def _synthetic_model():
    return {
        "meta": {"cps": 1000000, "num_tiles": 2, "host_span_us": 1000.0},
        "anchors": {},
        "fit_per_tile": {"4,4": {"counts_per_cycle": 1.0, "aie_hz": 1e9},
                         "5,5": {"counts_per_cycle": 1.0, "aie_hz": 1e9}},
        "lanes": [
            {"name": "host", "events": [
                {"event": "iter0.iter_start", "start_us": 0.0, "end_us": 0.0, "detail": "host=1000"},
                {"event": "iter0.dma_in_start", "start_us": 50.0, "end_us": 50.0, "detail": "host=1050"},
                {"event": "iter0.dma_in_done", "start_us": 120.0, "end_us": 120.0, "detail": "host=1120"},
                {"event": "iter0.run", "start_us": 130.0, "end_us": 130.0, "detail": "host=1130"},
                {"event": "iter0.wait_done", "start_us": 700.0, "end_us": 700.0, "detail": "host=1700"},
                {"event": "iter0.dma_out_start", "start_us": 720.0, "end_us": 720.0, "detail": "host=1720"},
                {"event": "iter0.dma_out_done", "start_us": 800.0, "end_us": 800.0, "detail": "host=1800"},
            ]},
            {"name": "tile 4,4", "events": [
                {"event": "ACTIVE", "start_us": 135.0, "end_us": 690.0, "detail": "cycles 135..689"},
            ]},
            {"name": "tile 5,5", "events": [
                {"event": "ACTIVE", "start_us": 140.0, "end_us": 520.0, "detail": "cycles 140..519"},
                {"event": "LOCK_STALL", "start_us": 520.0, "end_us": 690.0, "detail": "cycles 520..689"},
            ]},
        ],
    }


def _self_test():
    import tempfile
    model = _synthetic_model()
    with tempfile.TemporaryDirectory() as d:
        png = os.path.join(d, "timeline.png")
        out = render(model, save=png, want_window=False)
        assert out == png and os.path.getsize(png) > 0, "PNG not written"
    print("self-test OK: rendered synthetic 2-tile timeline to a PNG")
    return 0


# --------------------------------------------------------------------------
# CLI.
# --------------------------------------------------------------------------
def main(argv):
    ap = argparse.ArgumentParser(description="Draw a host<->AIE timeline from timeline.json.")
    ap.add_argument("json", nargs="?", help="timeline.json produced by host_aie_timeline.py")
    ap.add_argument("--save", metavar="PNG", help="write a PNG instead of opening a window")
    ap.add_argument("--self-test", action="store_true", help="render a synthetic model and exit")
    args = ap.parse_args(argv[1:])

    if args.self_test:
        return _self_test()
    if not args.json:
        ap.error("json is required (or use --self-test)")

    model = load_model(args.json)
    out = render(model, save=args.save, want_window=True)
    if out:
        print("[timeline_gui] wrote %s" % out)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
