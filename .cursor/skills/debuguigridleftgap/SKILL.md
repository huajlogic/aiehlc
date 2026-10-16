---
name: debuguigridleftgap
description: Debug UI (--prettydebug / host_schedule.html) tile grid has a big blank column on the LEFT of the AIE array. Happens when the data plane does not start at partition-relative col 0 -- e.g. conv2dstem's {2,6} control-plane partition, whose col 0 is the control spine. The grid used to draw 0..max(col) and hide empty cells, which still take 1fr.
---

# Blank left column in the debug UI tile grid

## Symptom

`aiehlc.sh --prettydebug` (or opening `aout/worklocal/host_schedule.html`)
shows the AIE array shifted right with an empty column-wide gap on the left.
Seen on `src/aietensorop/conv2dstem/test_conv2d.cc`.

## Cause

- `conv2dstem.cc` uses `device.partition({2, 6, 0, 6}, ...)`: five columns for
  a four-column mesh. `planControlColumn` takes partition-relative col 0 as the
  control spine and the data plane starts at `relStartCol + 1`.
- So `dfscheduleprovenancemap.json` has tiles only at cols **1..4**, and
  `schedule_view.json` carries `grid.cols = max(col)+1 = 5`,
  `col_list = [1,2,3,4]`.
- The tile grid in `schedule_view.py`'s JS used
  `gridTemplateColumns = repeat(g.cols, 1fr)` and looped `c = 0..g.cols-1`;
  a missing tile became a `visibility:hidden` cell, which **still occupies its
  1fr** -> 1/5 of the width blank.
- Rows never showed this because the row loop walks `row_list`, not
  `0..rows-1`. The SVG device map was also fine (it trims by `minC`).

## Fix (in place)

The grid now starts at `gColMin = min(g.col_list)` and spans
`gNCols = g.cols - gColMin` columns; the header says
`AIE Debug 4x7 grid (cols 1..4; lower cols have no data tiles, e.g. control spine)`.
Cell labels come from `t.loc`, so displayed coordinates are unchanged
(still partition-relative; `phys_col = col + startcol`).

`grid.cols` in the JSON is deliberately **not** changed: server code
(`_switch_tiles`, `/grid`) enumerates `col_list` and relies on the
`max+1` meaning.

## Verify

```bash
python3 src/tool/debug/schedule_view.py aout/worklocal   # regenerate the html
```
Render headless (Playwright + `/usr/bin/google-chrome`) and check
`#grid` has `repeat(4, 1fr)`, 0 hidden cells, first tile `(1,6)` flush left.
A **running** `schedule_debug_server.py` imported the old module -- restart it.
