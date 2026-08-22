#!/usr/bin/env python3
"""Unit test for timeline_gui.py (src/tool/debug/timeline_gui.py).

Headless (Agg backend): no window, no board, no display. Asserts
  1. event_color maps each slot type + multi/other correctly,
  2. lane helpers split host vs tile lanes,
  3. render() writes a non-empty PNG,
  4. rendering a real timeline.json (built via host_aie_timeline.correlate)
     round-trips to a PNG,
  5. _self_test() returns 0.
"""

import os
import sys
import tempfile

# Force headless BEFORE timeline_gui imports pyplot.
import matplotlib  # noqa: E402
matplotlib.use("Agg")

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_HERE, ".."))   # timeline_gui, host_aie_timeline

import timeline_gui as tg  # noqa: E402


def test_event_color_known_slots():
    assert tg.event_color("ACTIVE") == tg.EVENT_COLORS["ACTIVE"]
    assert tg.event_color("LOCK_STALL") == tg.EVENT_COLORS["LOCK_STALL"]
    assert tg.event_color("STREAM_STALL") == tg.EVENT_COLORS["STREAM_STALL"]
    assert tg.event_color("MEMORY_STALL") == tg.EVENT_COLORS["MEMORY_STALL"]


def test_event_color_multi_prefers_stall():
    # A stall token wins over ACTIVE (core is ACTIVE even while blocked).
    assert tg.event_color("ACTIVE|LOCK_STALL") == tg.EVENT_COLORS["LOCK_STALL"]
    assert tg.event_color("ACTIVE|STREAM_STALL") == tg.EVENT_COLORS["STREAM_STALL"]
    assert tg.event_color("ACTIVE|MEMORY_STALL") == tg.EVENT_COLORS["MEMORY_STALL"]
    # No stall token: first recognised token wins.
    assert tg.event_color("STREAM_STALL|EVENT5") == tg.EVENT_COLORS["STREAM_STALL"]
    assert tg.event_color("ACTIVE|EVENT5") == tg.EVENT_COLORS["ACTIVE"]


def test_event_color_unknown_is_other():
    assert tg.event_color("EVENT5") == tg.OTHER_COLOR
    assert tg.event_color("EVENT6|EVENT7") == tg.OTHER_COLOR


def test_rasterize_dominant_active_over_minority_stall():
    # One bin covering [0,20]: 19.95us ACTIVE vs 0.05us LOCK_STALL -> green.
    events = [
        {"start_us": 0.0, "end_us": 10.0, "event": "ACTIVE"},
        {"start_us": 10.0, "end_us": 10.05, "event": "LOCK_STALL"},
        {"start_us": 10.05, "end_us": 20.0, "event": "ACTIVE"},
    ]
    assert tg.rasterize_lane(events, 0.0, 20.0, 1) == \
        [(0.0, 20.0, tg.EVENT_COLORS["ACTIVE"])]


def test_rasterize_dominant_stall():
    # A stall-dominated bin colours orange (event_color prefers the stall).
    events = [{"start_us": 0.0, "end_us": 20.0, "event": "ACTIVE|LOCK_STALL"}]
    assert tg.rasterize_lane(events, 0.0, 20.0, 1) == \
        [(0.0, 20.0, tg.EVENT_COLORS["LOCK_STALL"])]


def test_rasterize_merges_adjacent_and_splits_on_color():
    # 4 bins over [0,20]: first half ACTIVE, second half LOCK_STALL.
    events = [
        {"start_us": 0.0, "end_us": 10.0, "event": "ACTIVE"},
        {"start_us": 10.0, "end_us": 20.0, "event": "LOCK_STALL"},
    ]
    assert tg.rasterize_lane(events, 0.0, 20.0, 4) == [
        (0.0, 10.0, tg.EVENT_COLORS["ACTIVE"]),
        (10.0, 20.0, tg.EVENT_COLORS["LOCK_STALL"]),
    ]


def test_rasterize_skips_empty_bins():
    # bins [0,5] and [5,10] have no events -> no segment there.
    events = [{"start_us": 12.0, "end_us": 18.0, "event": "ACTIVE"}]
    assert tg.rasterize_lane(events, 0.0, 20.0, 4) == \
        [(10.0, 20.0, tg.EVENT_COLORS["ACTIVE"])]


def test_rasterize_short_active_burst_visible_when_dominant():
    # The real bug: a sub-pixel ACTIVE run interrupted by a 1-cycle stall.
    # Per-pixel dominance keeps the bin green instead of losing it to overpaint.
    events = [
        {"start_us": 0.0, "end_us": 0.05, "event": "ACTIVE"},
        {"start_us": 0.05, "end_us": 0.051, "event": "ACTIVE|LOCK_STALL"},
        {"start_us": 0.051, "end_us": 0.10, "event": "ACTIVE"},
    ]
    assert tg.rasterize_lane(events, 0.0, 0.10, 1) == \
        [(0.0, 0.10, tg.EVENT_COLORS["ACTIVE"])]


def test_lane_helpers_split_host_and_tiles():
    model = tg._synthetic_model()
    assert tg.host_lane(model)["name"] == "host"
    names = [l["name"] for l in tg.tile_lanes(model)]
    assert names == ["tile 4,4", "tile 5,5"]
    # host lane is excluded from tile lanes
    assert all(n != "host" for n in names)


def test_render_writes_nonempty_png():
    model = tg._synthetic_model()
    with tempfile.TemporaryDirectory() as d:
        png = os.path.join(d, "out.png")
        out = tg.render(model, save=png, want_window=False)
        assert out == png
        assert os.path.getsize(png) > 0


def test_render_real_correlated_model():
    # Build a real model from a [TIMESYNC] block via host_aie_timeline, render it.
    import host_aie_timeline as hat
    block = "\n".join([
        "[TIMESYNC] cps=1000000",
        "[TIMESYNC] anchor0 host=1000",
        "[TIMESYNC] anchor0 tile=4,4 aie=0",
        "[TIMESYNC] anchor1 host=2000",
        "[TIMESYNC] anchor1 tile=4,4 aie=1000",
        "[TIMESYNC] hostevt iter=0 phase=iter_start host=1000",
        "[TIMESYNC] hostevt iter=0 phase=run host=1500",
        "[TIMESYNC] hostevt iter=0 phase=wait_done host=1800",
        "[TIMESYNC] trace tile=4,4 words=16",
        "[TIMESYNC] trace tile=4,4 510 -- 799  ACTIVE  (290 cyc)",
    ])
    model = hat.correlate(hat.parse_timesync(block))
    with tempfile.TemporaryDirectory() as d:
        png = os.path.join(d, "real.png")
        assert tg.render(model, save=png, want_window=False) == png
        assert os.path.getsize(png) > 0


# --------------------------------------------------------------------------
# Pulse / edge events (DMA_FINISH, LOCK_*): single-cycle markers a span
# rectangle cannot show. They must be drawn as VERTICAL LINE markers.
# --------------------------------------------------------------------------
def test_pulse_tokens_extraction():
    # Combined with a stall level: only the pulse token(s) are returned.
    assert tg.pulse_tokens("DMA_FINISH|DMA_STALL_LOCK") == ["DMA_FINISH"]
    # A pure-pulse combo returns both, in EVENT_COLORS order (LOCK_GRP before REL).
    assert tg.pulse_tokens("LOCK_REL|LOCK_GRP") == ["LOCK_GRP", "LOCK_REL"]
    # A single pulse alone.
    assert tg.pulse_tokens("DMA_FINISH") == ["DMA_FINISH"]
    # No pulse: level/state events only.
    assert tg.pulse_tokens("ACTIVE|LOCK_STALL") == []
    assert tg.pulse_tokens("DMA_STALL_LOCK") == []


def _vertical_lines_by_color(ax):
    """Map colour-hex -> list of x for every vertical (x0==x1) Line2D on ax."""
    import matplotlib.colors as mcolors
    out = {}
    for ln in ax.get_lines():
        xd = ln.get_xdata()
        if len(xd) == 2 and xd[0] == xd[1]:
            hexc = mcolors.to_hex(ln.get_color())
            out.setdefault(hexc, []).append(xd[0])
    return out


def test_pulse_events_drawn_as_vertical_lines():
    import matplotlib.pyplot as plt
    # A mem-dma lane: a lone DMA_FINISH pulse, and one combined with a stall.
    model = {
        "meta": {}, "anchors": {}, "fit_per_tile": {},
        "lanes": [
            {"name": "tile 0,3 mem dma", "events": [
                {"event": "DMA_STALL_LOCK", "start_us": 0.0, "end_us": 50.0, "detail": ""},
                {"event": "DMA_FINISH", "start_us": 20.0, "end_us": 20.001, "detail": ""},
                {"event": "DMA_FINISH|DMA_STALL_LOCK", "start_us": 40.0, "end_us": 40.001, "detail": ""},
            ]},
        ],
    }
    fig, ax = plt.subplots()
    tg._draw(ax, model, nbins=100)
    vlines = _vertical_lines_by_color(ax)
    xs = vlines.get(tg.EVENT_COLORS["DMA_FINISH"], [])
    # Both DMA_FINISH pulses (lone + combined-with-stall) get a blue vline.
    assert 20.0 in xs and 40.0 in xs
    plt.close(fig)


def test_pulse_stacks_multiple_tokens():
    import matplotlib.pyplot as plt
    model = {
        "meta": {}, "anchors": {}, "fit_per_tile": {},
        "lanes": [
            {"name": "tile 0,3 mem dma", "events": [
                {"event": "LOCK_GRP|LOCK_REL", "start_us": 10.0, "end_us": 10.001, "detail": ""},
            ]},
        ],
    }
    fig, ax = plt.subplots()
    tg._draw(ax, model, nbins=100)
    vlines = _vertical_lines_by_color(ax)
    # Both pulse tokens draw their own coloured vertical marker at x=10.
    assert 10.0 in vlines.get(tg.EVENT_COLORS["LOCK_GRP"], [])
    assert 10.0 in vlines.get(tg.EVENT_COLORS["LOCK_REL"], [])
    plt.close(fig)


def test_parse_host_marker():
    assert tg._parse_host_marker("iter0.run") == (0, "run")
    assert tg._parse_host_marker("iter3.dma_in_done") == (3, "dma_in_done")
    assert tg._parse_host_marker("plainname") == (None, "plainname")


def test_host_intervals_running_and_waiting():
    model = tg._synthetic_model()
    bars = tg.host_intervals(tg.host_lane(model))
    # 7 markers -> 6 gaps.
    assert len(bars) == 6
    # The run->wait_done gap is the idle-waiting bar; all others are running.
    wait = [b for b in bars if b["waiting"]]
    assert len(wait) == 1
    assert wait[0]["phase"] == "run"
    assert wait[0]["start_us"] == 130.0
    assert wait[0]["end_us"] == 700.0
    assert all(not b["waiting"] for b in bars if b["phase"] != "run")


def test_host_intervals_empty_without_host():
    # A model with no host lane yields no host bars and still renders.
    model = tg._synthetic_model()
    model["lanes"] = tg.tile_lanes(model)
    assert tg.host_lane(model) is None
    assert tg.host_intervals(None) == []


def test_self_test_entry_point():
    assert tg._self_test() == 0


# --------------------------------------------------------------------------
# Standalone runner (works without pytest installed).
# --------------------------------------------------------------------------
def _main():
    fns = [g for n, g in sorted(globals().items())
           if n.startswith("test_") and callable(g)]
    passed = 0
    for fn in fns:
        try:
            fn()
            passed += 1
            print("PASS  %s" % fn.__name__)
        except AssertionError as e:
            print("FAIL  %s: %s" % (fn.__name__, e))
            return 1
        except Exception as e:  # noqa: BLE001
            print("ERROR %s: %r" % (fn.__name__, e))
            return 1
    print("\n%d passed" % passed)
    return 0


if __name__ == "__main__":
    sys.exit(_main())
