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


def test_event_color_multi_uses_first_known():
    # First recognised token wins.
    assert tg.event_color("ACTIVE|LOCK_STALL") == tg.EVENT_COLORS["ACTIVE"]
    assert tg.event_color("STREAM_STALL|EVENT5") == tg.EVENT_COLORS["STREAM_STALL"]


def test_event_color_unknown_is_other():
    assert tg.event_color("EVENT5") == tg.OTHER_COLOR
    assert tg.event_color("EVENT6|EVENT7") == tg.OTHER_COLOR


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


def test_bar_draw_span_left_anchored():
    # A sub-pixel bar is widened to min_w by growing RIGHTWARD only: the drawn
    # left edge stays at the true start, so it can never appear before `run`.
    assert tg._bar_draw_span(2266.69, 0.37, 77.1) == (2266.69, 77.1)
    # An already-wide bar is untouched.
    assert tg._bar_draw_span(100.0, 50.0, 10.0) == (100.0, 50.0)


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
