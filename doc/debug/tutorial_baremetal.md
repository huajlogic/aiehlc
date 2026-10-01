# Debug UI Tutorial — aiebaremetal Hardware Flow

## 1. Build the app

From the naiebaremetal checkout:

```bash
cd /path/to/naiebaremetal/example/example_oob_4x4
./build.sh 5 -bootgen
```


## 2. Configure board

In the aiehlc repo:

```bash
cp script/test/envtemplate.sh script/test/envlocal.sh
# Set USERNAME and VEK385IP in envlocal.sh, then:
source script/test/envlocal.sh
```

## 3. Open one app in the UI

Pass the specific naiebaremetal example directory with `--app`:

```bash
cd /path/to/aiehlc
python3 src/tool/debug/schedule_debug_server.py \
  --app /path/to/naiebaremetal/example/example_oob_4x4 \
  --open --no-password
```

The server accepts either the app directory or its generated `worklocal`
provenance bundle. When given the app directory, it generates or refreshes
`worklocal` from `Work/` automatically. Because `--app` registers one app, the
UI displays its name instead of an App dropdown.

`--no-password` is appropriate only on a trusted network. For a local-only
server, also pass `--host 127.0.0.1`; otherwise configure a password.

## 4. UI basics

Four panes: **AIE Debug** (top-left, tile grid/map), **Execution** (bottom-left,
run controls and applog), **Info** (top-right, per-tile detail), and **Tools**
(bottom-right, aiegdb console and LLM).

**Run the app:** Select the board, click **Connect** to verify the JTAG link,
then **Run** to deploy and run. **Attach existing run** adopts a board
session started outside the UI; its earlier board history is unknown. The
applog streams in the Execution pane. Use **Stop run** if needed.

**Read tile state:** Pick **DMA**, **Cores**, or **Events**, then click **Scan**
for a one-shot register read. Toggle **live** for continuous polling. Changing
the selected mode does not read the board until Scan is clicked or live mode is
enabled. Click any tile for BD, lock, and kernel detail in the Info pane.

**Inspect code:** In **Info → Code**, `Default` shows the kernel-oriented view.
`Kernel files` groups the user kernel source, generated `kernel.cc`, and `.bcf`
address map when those artifacts are present.

**Source viewer:** Click any `file:line` reference in the Info pane, aiegdb
console, or LLM chat to open highlighted source. App-relative paths such as
`src/conv2.cc` resolve to the editable source rather than a generated copy.

**LLM tab:** Open **Tools → LLM**. Ask about stalls or BD chains; attach tile
details or aiegdb output as inline context chips.
