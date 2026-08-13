# Debug UI Tutorial — naiebaremetal Flow

Quick-start for building a naiebaremetal app and using the live debug UI from the aiehlc repo.

## 1. Build the app

From the naiebaremetal checkout:

```bash
cd ../naiebaremetal/example/example_oob_4x4   # or your target example
source ../../script/settings.sh 1
./build.sh 5 -bootgen
```

`-bootgen` produces `build/vek385.BIN` (the PDI), which is what the UI detects to mark the example as hardware-capable. Without it the UI lists the app as `view-only`.

Build outputs the daemon needs:
- `build/host` — host ELF
- `build/vek385.BIN` — board image
- `worklocal/` — provenance JSONs (`dfscheduleprovenancemap.json`, etc.)

## 2. Configure board environment

In the aiehlc repo, copy the env template and set your board:

```bash
cp script/test/envtemplate.sh script/test/envlocal.sh
# Edit envlocal.sh — set VEK385IP to your board's hostname or IP
```

```bash
VEK385IP=crimini2
AIEDBG_TARGET=xsdb://${VEK385IP}:3121
```

## 3. Open the debug UI

Run from the aiehlc repo, passing the naiebaremetal example directory as `--app-root`:

```bash
cd /path/to/aiehlc_aiesim
source script/test/envlocal.sh
python3 src/tool/debug/schedule_debug_server.py \
  --app-root ../naiebaremetal/example \
  --open --no-password
```

`--app-root` can be given multiple times to register several example trees at once. The daemon detects each example's capabilities (simulator, hardware) from build artifacts — no config file needed.

The UI opens at `http://localhost:8091`. Use the **App** dropdown in the Run pane to switch between registered examples.

## 4. Basic UI operations

Same four panes as the aiehlc flow:
- **AIE Debug** (top-left) — grid / device-map view
- **Run** (bottom-left) — app selector, run buttons, applog tail
- **Info** (top-right) — per-tile BDs, locks, kernel, backtrace
- **Tools** (bottom-right) — aiegdb console, LLM tab, search

### Connect and run

1. Confirm the correct app is selected in the **App** dropdown
2. **Connect** — verifies the JTAG link
3. **Run test** — deploys and runs the ELF; applog streams in the Run pane
4. **Force stop** — terminates a stuck run

### Read tile state

1. Choose **DMA**, **Cores**, or **Events** in the toolbar
2. **Scan** — one-shot register read with coloured tile overlay
3. **live** — continuous 2-second polling
4. Click a tile → **Info** pane shows BDs, lock counts, kernel assignment, and PC

### Source viewer

Click any `file:line` link in the Info pane or LLM chat to open the highlighted source panel. App sources (kernels under `src/`) are indexed per example, so bare filenames like `conv2.cc` resolve to the correct copy.

### LLM tab

**Tools** pane → **LLM** tab. Ask questions about stalls, BD chains, or tile behaviour. Attach tile data or aiegdb output as inline context chips. The agent reads the schedule and live registers to give grounded answers tied to your app's source.
