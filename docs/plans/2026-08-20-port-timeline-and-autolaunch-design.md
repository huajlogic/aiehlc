# Port timeline + auto-launch on run end/stop

Date: 2026-08-20

## Motivation

The core-tile trace unit now programs three stream-switch port events in slots
4-6 (`PORT_IDLE_0`, `PORT_RUNNING_0`, `PORT_STALLED_0`) alongside the core-state
events (`ACTIVE`, `LOCK_STALL`, `STREAM_STALL`, `MEMORY_STALL`) in slots 0-3. In
the applog these arrive combined in one run-length interval per line, e.g.

    [TIMESYNC] trace tile=0,3 96714211 -- 96714214  ACTIVE|LOCK_STALL|PORT_RUNNING_0  (4 cyc)

Two improvements:

1. **Port timeline** — `timeline.py` should draw a *second* horizontal lane per
   tile dedicated to the port state (idle / running / stalled), separate from the
   core ACTIVE/stall lane.
2. **Auto-launch** — the schedule debug HTML page should auto-run
   `python3 src/tool/debug/timeline.py <applog> --show` after a run finishes or
   the Force-stop button is clicked.

## Task B — port timeline (data + rendering)

### `host_aie_timeline.py` — `correlate()`

Each decoded interval carries a `|`-joined name set that mixes core and port
tokens. Split by category (the same rule the decoder uses: `PORT_*` = the
"event" category, everything else = "core"):

- New helper `_split_names(names) -> (core_names, port_names)`.
- For each traced tile emit up to two lanes, in this order:
  - `tile C,R`      — intervals whose **core** subset is non-empty (existing
    lane, minus PORT tokens).
  - `tile C,R port` — intervals whose **port** subset is non-empty (new lane),
    placed directly beneath its tile's core lane.
- A lane is omitted entirely when its subset is empty across all intervals, so
  runs with no port data render exactly as before.

Both split intervals reuse the same `start_us`/`end_us` from the tile's linear
fit; only the `event` string differs (core tokens vs port tokens).

### `timeline_gui.py`

Add the port colours to `EVENT_COLORS` so the port lane renders through the
existing tile-lane path (rasterisation, hover, legend all unchanged):

| Event | Colour | Legend label |
|-------|--------|--------------|
| `PORT_RUNNING_0` | teal `#17becf` | port running |
| `PORT_STALLED_0` | pink `#e377c2` | port stalled |
| `PORT_IDLE_0`    | light-grey `#bcbcbc` | port idle |

`event_color()` picks these up automatically. `_add_legend()` gets friendly
labels for the PORT tokens.

## Task A — auto-launch on run end/stop

### `schedule_debug_server.py`

New `POST /timeline` endpoint: spawn `python3 <dir>/timeline.py <self.applog>
--show` **detached** (`start_new_session=True`, non-blocking) so the blocking
matplotlib window does not tie up the daemon. No-op with an error payload when
the applog is missing. Returns `{started: bool, applog: str}`.

`--show` opens the window on the *server host* (the machine running the daemon),
per the chosen behaviour — intended for a locally-run daemon with a display.

### `schedule_view.py`

- `triggerTimeline()` — `POST /timeline`, fired at most once per run.
- Call sites:
  - `pollLog()` `r.running === false` branch — natural completion.
  - `stopbtn` `/stop` handler — force stop.
- `LIVE.tlFired` guard, reset to `false` when a run starts (`runbtn`), prevents
  a double launch when both paths race.

## Testing

- `host_aie_timeline.py --self-test` extended with a combined `ACTIVE|PORT_*`
  block asserting the `tile C,R` and `tile C,R port` split lanes.
- `timeline_gui.py --self-test` still passes (synthetic model has no port data).
- `timeline.py <applog>` run headless on the real capture confirms the port lane
  appears in the PNG.

## Files touched

- `src/tool/debug/host_aie_timeline.py` — `_split_names()`, two-lane emission,
  self-test.
- `src/tool/debug/timeline_gui.py` — PORT colours + legend labels.
- `src/tool/debug/schedule_debug_server.py` — `POST /timeline` endpoint.
- `src/tool/debug/schedule_view.py` — `triggerTimeline()` + call sites + guard.
