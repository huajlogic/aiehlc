<!-- Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# HW test

VEK385 boards: `script/test/appvek385.py`, see skill **vek385-board-benchmark** (and
**vek385-revb-boot** for Rev B). The rest of this page is the PAL harness.

## apppaltest.py (PAL boards)

```bash
python3 script/test/apppaltest.py [-nonreboot] [path-to-ELF]
```

| Variable | Meaning |
|----------|---------|
| `USERNAME` | SSH login on the PAL host |
| `PALIP` | PAL host address |
| `BOARDNAME` | board name for systest `become` |

If they are unset, the script sources `script/test/envlocal.sh`. With no ELF argument it
looks for `aout/main.elf`. Steps: SSH to `PALIP`, systest `become BOARDNAME`, program the
device with xsdb, copy and `dow` the ELF, `con`, and capture the console on a second
connection. `-nonreboot` reuses a running xsdb instead of power-cycling.

Needs SSH key access to the PAL host and `pexpect` (`pip install pexpect`).

## verify_host.sh

`.cursor/skills/hostcodegen/scripts/verify_host.sh [--compile] [elf_path]` runs
`apppaltest.py` and greps the console. Fail: `AIE ERROR`, `Invalid Tile Type`, `Cannot find
Tile Type`. Pass: `device_teardown done`, `device_init OK`. Default worklocal:
`pass/unitest/build/worklocal` (override with `WORKLOCAL_DIR`).

## Common failures

| Symptom | Check |
|---------|-------|
| Env vars not set | export them or create `script/test/envlocal.sh` |
| SSH timeout | network, `PALIP`, SSH keys |
| `device program` / `dow` fails | board state and the boot image path on the host; targets `tar 1`, `tar 20` |
| No console output | second connection must reach the console; the first must `dow` + `con` |
| XAie error on the board | generated host.cc or runtime; rerun the same ELF and read the console |
