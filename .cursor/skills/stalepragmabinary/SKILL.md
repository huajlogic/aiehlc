<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: stalepragmabinary
description: A #pragma you added to an app source is never "Detected" in the aiehlc log and its feature silently does nothing -- the build still succeeds. Use when control_plan_shim_bd_ctrl / control_packet_mode / any newer marker pragma is ignored, when some pragmas in a block are detected and others are not, or before trusting a control-plane feature that leaves no WARNING behind.
---

# A marker pragma the aiehlc binary does not know is silently ignored

## Symptom

You add a block of pragmas and the build succeeds, but one is missing from the log:

```
[aiehlc] Detected #pragma control_plan_op_control_packet
[aiehlc] Detected #pragma CONTROL_PLAN_GROUP_REG_WRITE
[aiehlc] Detected #pragma control_plan_dedicated_shim
[aiehlc] Detected #pragma KERNELCONFIGOFFLOAD
```

`control_plan_shim_bd_ctrl` was in the source, between `dedicated_shim` and
`KERNELCONFIGOFFLOAD`, and is simply absent. No error, no warning, `rc=0`.

The feature is off. Nothing downstream says so: a pragma that is never parsed
publishes no module attr, so the pipeline's own "you asked for X but ..."
WARNING — which fires on a *parsed-but-unsatisfiable* request — never runs
either. **Two different silences look identical.**

## Cause

`#pragma` is defined to be ignorable. Clang routes an unrecognized one to no
handler and (unless `-Wunknown-pragmas` is on *and* fatal) carries on. So the
gate is not the source and not the pipeline — it is whether the `aiehlc`
**binary** has a `PragmaHandler` registered for that name.

`script/aiehlc.sh` picks `${AIEHLC_DIR}/build/aiehlc`, falling back to
`${AIEHLC_DIR}/release/prebuild/aiehlc`. Either can predate the pragma: the
prebuilt binary is a checked-in artifact, and `build/aiehlc` is only as new as
the last `make`. Editing `src/llvm/aiehlc.cc` does **not** change the tool that
`aiehlc.sh` runs.

## Check

Ask the binary, not the source:

```bash
strings build/aiehlc | grep -c control_plan_shim_bd_ctrl   # 0 == stale
```

Count the detections against the pragmas you wrote — the pipeline will not do it
for you. The full registered set is one grep away:

```bash
grep -n 'PragmaHandler("' src/llvm/aiehlc.cc
```

## Fix

Rebuild the tool. The tree hard-codes a cmake path that may be unreachable, so
override it (skill **mlirbuildsandbox**):

```bash
make -C build CMAKE_COMMAND=/scratch/staff/huaj/aiehlc/.venv/bin/cmake aiehlc -j16
```

~5 min, mostly `aiehlc.cc.o` plus the link. Then re-run `aiehlc.sh` and confirm
every pragma appears.

## Rule

A marker pragma is an **unverified request** until the log echoes it. For any
control-plane feature, pair the `Detected` line with a second, independent
check on the generated artifact — the two failure modes (not parsed / parsed but
refused) are indistinguishable from the log alone:

| Pragma | Artifact check |
|---|---|
| `control_plan_op_control_packet` | `grep __Runtime_load_kernel_group_.*_ctrl aout/worklocal/host.cc` |
| `CONTROL_PLAN_GROUP_REG_WRITE` | `grep __Runtime_ctrl_row_write_ack aout/worklocal/host.cc` |
| `control_plan_shim_bd_ctrl` | `grep __Runtime_ctrl_shim_bd_begin aout/worklocal/host.cc` |
| `KERNELCONFIGOFFLOAD` | `grep -cE '\.TM' aout/worklocal/build/kernel.lst` (non-zero) |

## See also

- **mlirbuildsandbox** — building `aiehlc` when the configured cmake/libz is unreachable
- **shim-row-ctrl-bd-config** — what `control_plan_shim_bd_ctrl` needs besides a current binary (spare column, HT mode)
- **aiesourcetextrewrite** — the other class of silent aiehlc no-op, in the text rewriter rather than the pragma table
