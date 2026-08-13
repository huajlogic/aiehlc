# Debug UI Tutorial — naiebaremetal Flow

## 1. Build the app

From the aiebaremetal checkout:

```bash
cd aiebaremetal/example/example_oob
./build.sh 5 -bootgen
```


## 2. Configure board

In the aiehlc repo:

```bash
cp script/test/envtemplate.sh script/test/envlocal.sh
# Set USERNAME and VEK385IP in envlocal.sh, then:
source script/test/envlocal.sh
```

## 3. Open the UI

Pass the naiebaremetal example directory as `--app-root`:

```bash
cd /path/to/aiehlc
python3 src/tool/debug/schedule_debug_server.py \
  --app-root ../aiebaremetal/example \
  --open --no-password
```

Use the **App** dropdown in the Run pane to switch examples.

## 4. UI basics

Four panes: **AIE Debug** (top-left, tile grid/map), **Run** (bottom-left, run controls and applog), **Info** (top-right, per-tile detail), **Tools** (bottom-right, aiegdb console and LLM).

**Run the app:** Select the app in the dropdown, click **Connect** to verify the JTAG link, then **Run test** to deploy and run. Use **Force stop** if needed.

**Read tile state:** Pick **DMA**, **Cores**, or **Events** in the toolbar, then **Scan** for a register read. Toggle **live** for continuous polling. Click any tile for BD, lock, and kernel detail in the **Info** pane.

**Source viewer:** Click any `file:line` reference in the Info pane or LLM chat to open a highlighted source panel. Bare filenames like `conv2.cc` resolve to the correct copy in the app's `src/` directory.

**LLM tab:** Open **Tools → LLM**. Ask questions about stalls or BD chains; attach tile info or aiegdb output as context.
