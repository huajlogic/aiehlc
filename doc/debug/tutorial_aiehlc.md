# Debug UI Tutorial — aiehlc Flow

Quick-start for compiling an aiehlc tiling-linalg app, running it on hardware, and using the live debug UI.

## 1. Compile

```bash
source script/aiehlc.sh \
  --aie-version 5 \
  --runtime-source-file ./example/tileprogram/ccode/simplematmul2.cc \
  --debug-syms
```

`--debug-syms` adds `-g` to every host compiler invocation and skips `strip`, so the UI can resolve PC addresses to source lines.

Output artifacts live under `aout/worklocal/`:
- `build/host` — host ELF
- `host_schedule.html` — static schedule viewer (no daemon needed for offline use)
- `dfscheduleprovenancemap.json`, `dmaphopprovenacemap.json` — provenance maps read by the daemon

## 2. Configure board environment

Copy the template and fill in your board hostname:

```bash
cp script/test/envtemplate.sh script/test/envlocal.sh
# Edit envlocal.sh — set VEK385IP to your board's hostname or IP
```

Key variables:
```bash
VEK385IP=crimini2               # board hostname
AIEDBG_TARGET=xsdb://${VEK385IP}:3121
# XILINX_VITIS=/path/to/vitis  # uncomment if not already in PATH
```

Source it before starting the UI:
```bash
source script/test/envlocal.sh
```

## 3. Open the debug UI

**Option A — via aiehlc.sh** (rebuilds first, then opens browser):
```bash
source script/aiehlc.sh ... --prettydebug
```

**Option B — daemon directly** (use after an existing build):
```bash
source script/test/envlocal.sh
python3 src/tool/debug/schedule_debug_server.py --open --no-password
```

The daemon starts on `http://localhost:8091` and opens the browser automatically with `--open`.

## 4. Basic UI operations

The UI has four panes:
- **AIE Debug** (top-left) — grid or device-map view of the tile array
- **Run** (bottom-left) — app/board selection, run buttons, applog tail
- **Info** (top-right) — per-tile schedule detail (BDs, locks, kernel, stack trace)
- **Tools** (bottom-right) — aiegdb console, LLM tab, search

### Connect and run

1. **Connect** — verifies the link to `hw_server` on the board (JTAG must be running)
2. **Run test** — deploys the ELF, runs the app, and tails `applog` in real time
3. **Force stop** — terminates a stuck run; available once a run is in progress

### Read tile state

1. In the toolbar, choose **DMA**, **Cores**, or **Events**
2. Click **Scan** — reads registers once and overlays colour on each tile
3. Toggle **live** for continuous 2-second polling
4. Click any tile to open its detail in the **Info** pane (BDs, lock state, kernel name, high/medium/low/PC tabs)

### Source viewer

Click any `file:line` reference in the Info pane or LLM chat to open a syntax-highlighted panel scrolled to that line.

With `--debug-syms`, the **Targets** card in the Info pane shows the APU backtrace with resolved function names and source locations.

### LLM tab

Open the **Tools** pane → **LLM** tab. Type a question; use **+ Add context** (or drag) to attach tile info or aiegdb output as context chips inline in your message. The agent can run `aiegdb` commands and read the schedule to answer questions about stalls and routing.
