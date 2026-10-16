---
name: kcocoreidpartition
description: An AIE app with `#pragma KERNELCONFIGOFFLOAD` hangs (`wait_io TIMEOUT`, cores LOCK_STALL_E) on a partition whose start column is not 0, e.g. after widening to `{2,6}` for `control_plan_dedicated_shim`. Some core columns show MM2S `Idle running=0` (never armed) while others are armed with another tile's packet_id. Use when KCO + non-zero partition start col, or when bisecting a control-plane pragma set that hangs.
---

# KCO dispatch uses absolute columns: rebase by the partition start

## Symptom

`--aie-offload` (or standalone) prints `ENTER` without `EXIT`, then
`wait_io TIMEOUT` on the output shims. With `#pragma aie_debug_level(... | AIE_DEBUG_LOG)`
the timeout dump shows the core MM2S split by column: low columns are
`Paused running=1`, high columns are `Idle running=0`. S2MM and core PC are the
same on every core.

## Cause

KCO emits a `get_coreid()` dispatch in `kernel.cc`, one arm per tile.
`get_coreid() >> 16` is the **absolute** column, but the arms carry
**partition-relative** columns. Partition start col *s* shifts every core by *s*,
so a core either takes another tile's arm (wrong packet_id) or matches none (its
MM2S is never armed). Same class as commit `de26c81`
(`__Runtime_enable_core_proc_bus`).

## Fix (in tree)

`DfscheduleToKernelApiPass(partStartCol)` emits
`int _col = (int)(_cid >> 16) - <s>; // partition start col`.
Verify: `grep -n "int _col =" aout/worklocal/kernel.cc` shows `- <s>`.
After a compiler change, rebuild the tool
(`make -C build CMAKE_COMMAND=/scratch/staff/huaj/aiehlc/.venv/bin/cmake aiehlc -j16`).

## Second trap: MM2S BD length

After the rebase the mesh still hung. The arms used `sizeof(buf_out_ping_0)`
(784 B, declared `v4int8[196]`), while the host BD, the BCF slot and the plan's
`bdLenBytes` are 3136 B. The arms now take `CoreOffloadEntry::bdLenBytes`. Check:
`grep -c "buf_out_ping_0, 3136" aout/worklocal/kernel.cc` should be non-zero. In
general, when KCO hangs and KCO-off passes, diff one tile's host `dma_bd_config`
against its `aie_kc_encode_bd` arguments field by field.

## Bisection recipe

Comment pragmas out one at a time in the app source, then
`source script/aiehlc.sh --aie-version 5 --runtime-source-file <test>.cc` and
`python3 script/test/apppaltest.py -y -nonreboot aout/main.elf`. Check
`Detected #pragma` lines so you know what was actually built.
