# Debug UI Tutorial — aiehlc Simulator Flow

## 1. Build for simulation

```bash
source script/aiehlc.sh \
  --aie-version 5 \
  --platform sim \
  --runtime-source-file ./example/tileprogram/ccode/simplematmul2.cc \
  --debug-syms
```

`--platform sim` is required. It builds the simulator artifacts and writes
`sim_config.sh` beside `aout/worklocal/`; that file is how the debug server
detects an aiehlc simulator build. The build does not launch the simulator.
`--debug-syms` adds `-g` and skips `strip`.

To run without the UI after the build:

```bash
bash script/runsim.sh aout/worklocal
```

For the raw-XAie single-kernel flow, use:

```bash
source script/aiehlc.sh \
  --aie-version 5 \
  --platform sim \
  --runtime-source-file ./example/perf/aieml_perf.cc \
  --debug-syms
```

This flow writes `sim_config.sh` to `aout/` and the debug bundle to
`aout/worklocal/`; the server command below is the same for raw-XAie and
TilingLinalg apps. To launch the raw-XAie simulator without the UI, run
`bash script/runsim.sh aout`.

## 2. Open one app in the UI

```bash
python3 src/tool/debug/schedule_debug_server.py \
  --app aout/worklocal \
  --sim-only \
  --open --no-password
```

`--app` registers exactly one app, so the UI shows its name instead of an App
selector. It accepts either a provenance bundle such as `aout/worklocal` or an
app directory containing `Work/`. `--sim-only` hides board controls and refuses
hardware actions.

`--no-password` is appropriate only on a trusted network. For a local-only
server, also pass `--host 127.0.0.1`; otherwise configure a password.

If the server reports `no sim_config.sh`, the current `aout` was not built with
`--platform sim`; rebuild it using step 1.

To build and open the UI in one command, add `--prettydebug`:

```bash
source script/aiehlc.sh \
  --aie-version 5 \
  --platform sim \
  --runtime-source-file ./example/tileprogram/ccode/simplematmul2.cc \
  --debug-syms \
  --prettydebug
```

`--prettydebug` uses the same build-only behavior, then opens the UI; click
**Run** there to launch the simulator.

## 3. UI basics

Four panes: **AIE Debug** (top-left, tile grid/map), **Execution**
(bottom-left, run controls and simulator log), **Info** (top-right, per-tile
detail), and **Tools** (bottom-right, aiegdb console and LLM).

**Run the app:** Click **Run**. The simulator log streams live in the
Execution pane. Use **Stop run** if needed. Simulator-only mode has no Board,
Connect, or Attach controls.

**Read tile state:** Once the simulator is running, pick **DMA**, **Cores**, or
**Events**, then click **Scan** for a one-shot read overlaid on the grid. Toggle
**live** for continuous polling. Click any tile for BD, lock, and kernel detail
in the Info pane.

**Inspect code:** In **Info → Code**, `Default` shows the attributed host slice.
`Kernel files` groups the user kernel source, generated `kernel.cc`, and `.bcf`
physical-address map. Their sections collapse independently so the wrapper and
address map can remain open together.

**Source viewer:** Click any `file:line` reference in the Info pane, aiegdb
console, or LLM chat to open highlighted source.

**LLM tab:** Open **Tools → LLM**. Ask about stalls, routing, or data mapping;
attach tile details or aiegdb output as inline context chips.
