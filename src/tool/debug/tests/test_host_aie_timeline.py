#!/usr/bin/env python3
"""Unit test for host_aie_timeline.py (src/tool/debug/host_aie_timeline.py).

Feeds a synthetic [TIMESYNC] block -- known host/AIE anchors plus the decoded
AIE interval lines the unified dump (__Runtime_aie_trace_profile_dump) emits --
and asserts:
  1. the per-tile linear fit recovers a known cycle->us mapping (exact float),
  2. host phase events land at their expected us,
  3. CSV/JSON row counts and lane ordering are correct,
  4. two tiles with different timer offsets both map correctly.

Pure Python: no board, no compiler. The dump already decoded the raw trace into
absolute-AIE-cycle interval lines, so the tool parses them directly.
"""

import json
import os
import sys
import tempfile

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_HERE, ".."))   # host_aie_timeline

import host_aie_timeline as hat  # noqa: E402


# --------------------------------------------------------------------------
# A synthetic capture. cps=1e6 so 1 host count == 1 us. Slope 1 count/cycle.
#   tile 4,4: a0=0,    a1=1000  -> us(cycle) = cycle
#   tile 5,5: a0=500,  a1=1500  -> us(cycle) = cycle - 500   (offset by 500)
# Decoded trace intervals (both tiles): ACTIVE@10 (1 cyc), STREAM_STALL@110.
# --------------------------------------------------------------------------
# What parse_timesync should yield for each tile's interval list.
_TRACE_INTERVALS = [(10, 10, ["ACTIVE"]), (110, 110, ["STREAM_STALL"])]


def _trace_lines(tile):
    c, r = tile
    return [
        "[TIMESYNC] trace tile=%d,%d words=16" % (c, r),
        "[TIMESYNC] trace tile=%d,%d 10  ACTIVE" % (c, r),
        "[TIMESYNC] trace tile=%d,%d 110  STREAM_STALL" % (c, r),
    ]


def _block(two_tiles=True):
    lines = [
        "[TIMESYNC] cps=1000000",
        "[TIMESYNC] anchor0 host=1000",
        "[TIMESYNC] anchor0 tile=4,4 aie=0",
    ]
    if two_tiles:
        lines.append("[TIMESYNC] anchor0 tile=5,5 aie=500")
    lines += [
        "[TIMESYNC] anchor1 host=2000",
        "[TIMESYNC] anchor1 tile=4,4 aie=1000",
    ]
    if two_tiles:
        lines.append("[TIMESYNC] anchor1 tile=5,5 aie=1500")
    lines += [
        "[TIMESYNC] hostevt iter=0 phase=iter_start host=1000",
        "[TIMESYNC] hostevt iter=0 phase=run host=1500",
        "[TIMESYNC] hostevt iter=1 phase=dma_out_done host=2000",
    ]
    lines += _trace_lines((4, 4))
    if two_tiles:
        lines += _trace_lines((5, 5))
    return "\n".join(lines) + "\n"


# --------------------------------------------------------------------------
def test_parse_extracts_all_records():
    ts = hat.parse_timesync(_block())
    assert ts["cps"] == 1000000
    assert ts["anchors"][0]["host"] == 1000
    assert ts["anchors"][1]["host"] == 2000
    assert ts["anchors"][0]["tiles"][(4, 4)] == 0
    assert ts["anchors"][1]["tiles"][(4, 4)] == 1000
    assert ts["anchors"][0]["tiles"][(5, 5)] == 500
    assert len(ts["hostevts"]) == 3
    assert ts["hostevts"][0] == (0, "iter_start", 1000)
    assert (4, 4) in ts["traces"] and (5, 5) in ts["traces"]
    assert ts["traces"][(4, 4)] == _TRACE_INTERVALS
    assert ts["traces"][(5, 5)] == _TRACE_INTERVALS


def test_linear_fit_recovers_cycle_to_us():
    # tile 4,4: identity; tile 5,5: shifted by -500 us.
    fit44 = hat.TileFit((4, 4), 1000000, 1000, 2000, 0, 1000)
    assert fit44.counts_per_cycle == 1.0
    assert fit44.aie_hz == 1000000.0
    assert fit44.cycle_to_us(0) == 0.0
    assert fit44.cycle_to_us(10) == 10.0
    assert fit44.cycle_to_us(1000) == 1000.0

    fit55 = hat.TileFit((5, 5), 1000000, 1000, 2000, 500, 1500)
    assert fit55.cycle_to_us(500) == 0.0
    assert fit55.cycle_to_us(510) == 10.0


def test_nonunit_slope_fit():
    # 2 counts per cycle, cps=2e6 -> counts/us=2 -> us(cycle)=cycle.
    fit = hat.TileFit((4, 4), 2000000, 0, 2000, 0, 1000)
    assert fit.counts_per_cycle == 2.0
    assert fit.cycle_to_us(100) == 100.0
    assert fit.aie_hz == 1000000.0


def test_host_events_land_at_expected_us():
    model = hat.correlate(hat.parse_timesync(_block()))
    host = next(l for l in model["lanes"] if l["name"] == "host")
    us = {e["event"]: e["start_us"] for e in host["events"]}
    assert us["iter0.iter_start"] == 0.0
    assert us["iter0.run"] == 500.0
    assert us["iter1.dma_out_done"] == 1000.0
    # Host markers are zero-width.
    for e in host["events"]:
        assert e["start_us"] == e["end_us"]


def test_tile_intervals_mapped():
    model = hat.correlate(hat.parse_timesync(_block()))
    t44 = next(l for l in model["lanes"] if l["name"] == "tile 4,4")
    ev = {e["event"]: e for e in t44["events"]}
    assert ev["ACTIVE"]["start_us"] == 10.0
    assert ev["ACTIVE"]["end_us"] == 11.0        # end_cycle+1 -> 1-cycle width
    assert ev["STREAM_STALL"]["start_us"] == 110.0
    # Offset tile maps the same cycles 500 us earlier.
    t55 = next(l for l in model["lanes"] if l["name"] == "tile 5,5")
    ev5 = {e["event"]: e for e in t55["events"]}
    assert ev5["ACTIVE"]["start_us"] == -490.0
    assert ev5["STREAM_STALL"]["start_us"] == -390.0


def test_lane_ordering_host_first_then_tiles_sorted():
    model = hat.correlate(hat.parse_timesync(_block()))
    names = [l["name"] for l in model["lanes"]]
    assert names == ["host", "tile 4,4", "tile 5,5"]


def test_csv_json_row_counts_and_ordering():
    model = hat.correlate(hat.parse_timesync(_block()))
    with tempfile.TemporaryDirectory() as d:
        csv_path, json_path, nrows = hat.emit(model, d)
        # 3 host events + 2 intervals/tile x 2 tiles = 7 rows.
        assert nrows == 7
        with open(csv_path) as f:
            lines = f.read().splitlines()
        assert lines[0] == "lane,event,start_us,end_us,detail"
        assert len(lines) == 1 + 7
        # Host rows come first, then tile 4,4, then tile 5,5.
        assert lines[1].startswith("host,")
        assert lines[2].startswith("host,")
        assert lines[3].startswith("host,")
        assert lines[4].startswith('"tile 4,4"')
        assert lines[6].startswith('"tile 5,5"')

        with open(json_path) as f:
            model2 = json.load(f)
        assert model2["meta"]["cps"] == 1000000
        assert model2["meta"]["num_tiles"] == 2
        assert set(model2["fit_per_tile"]) == {"4,4", "5,5"}
        assert model2["fit_per_tile"]["4,4"]["counts_per_cycle"] == 1.0
        assert [l["name"] for l in model2["lanes"]] == ["host", "tile 4,4", "tile 5,5"]


def test_single_tile_block():
    model = hat.correlate(hat.parse_timesync(_block(two_tiles=False)))
    names = [l["name"] for l in model["lanes"]]
    assert names == ["host", "tile 4,4"]
    assert model["meta"]["num_tiles"] == 1


def test_missing_cps_raises():
    ts = hat.parse_timesync("[TIMESYNC] anchor0 host=1\n[TIMESYNC] anchor1 host=2\n")
    try:
        hat.correlate(ts)
        assert False, "expected ValueError for missing cps"
    except ValueError:
        pass


def test_self_test_entry_point():
    assert hat._self_test() == 0


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
