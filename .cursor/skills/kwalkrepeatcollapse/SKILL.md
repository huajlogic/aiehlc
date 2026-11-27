---
name: kwalkrepeatcollapse
description: A hand-written GemmSpace GEMM (simplematmul2.cc) that ran on an older aiehlc hangs in `wait_io TIMEOUT tile(c,0) ch=0 dir=1` and the netboot watchdog fires; host.cc's `__Runtime_startio(..., N, 1)` where it used to be `(..., N, 4)`; build log `[BlueprintToSchedule] 3D K BD is already the whole walk (... B) and does not iterate: repeat 4 -> 1`
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Whole-K-walk shim BD: repeat collapsed for a kernel that reads it k_rounds times

## Symptom

- `example/tileprogram/ccode/simplematmul2.cc` on VEK385: the launch never finishes,
  `[aie_runtime] wait_io TIMEOUT tile(0,0) ch=0 dir=1` and `tile(1,0)`, then
  `state=watchdog-timeout`. The same source built at 3ff40966 (main before the dataflow-plan
  merge) runs to the end.
- Plan-less build, yet `host.cc` differs from the old one in exactly the input starts:
  `__Runtime_startio(v1, v409, 3, 4)` became `(..., 3, 1)` (4 places). `kernel.cc` and `routing.cc`
  are identical.
- Build log: `[BlueprintToSchedule] 3D K BD is already the whole walk (4096 B) and does not
  iterate: repeat 4 -> 1`.

## Cause

`FlowTransferConversion::computeMultipleInputShimBd` (`pass/passblueprintlowering/helper/
flowtransfer_host.cpp`, commit 0a4ac5d1) collapses a shim BD that already walks the whole K range
and does not iterate from `repeat k_rounds` to 1. That fixed `simplegemm_kacc.cc`, a kernel-only
kernel whose core takes the walk ONCE per round (it hung with the repeat). A hand-written GemmSpace
kernel can take the same strip once per k-round: simplematmul2's core reads it 4 times, so with 1
the core starves and the output shim never completes. The rule assumed something only the kernel
trace can prove.

## Fix

Collapse only for a traced kernel-only port (`c.kb.attr`, a `#routing.kernel_block`): there the trace
says how many times the core takes the walk. Other inputs keep the repeat the GEMM model derived.
Not `c.kb.follow`: simplegemm_kacc's B is traced but does not follow its blocks (not row-contiguous),
and gating on `follow` brought its hang back (VEK385_2 `wait_io TIMEOUT ... ch=1`).

## Check

- simplematmul2: `host.cc` / `kernel.cc` / `routing.cc` byte-identical to a 3ff40966 build, and the
  board run ends (`aie matmul time: ... ms`, no `wait_io TIMEOUT`).
- simplegemm_kacc: the `repeat 16 -> 1` line is still printed (4 times), `host.cc` identical to a
  12109fc7 build, and the VEK385_2 run is `GOLDEN PASS: 112384 / 112384`.
- Build a plan-less baseline to compare against: `git worktree add --detach <dir> 3ff40966`, copy
  `thirdparty/alib`, `rsync thirdparty/arch`, symlink `thirdparty/tvm-0.16`, cmake + `make
  aiehlc`, run `aiehlc.sh` from that worktree (it writes `aout/` in the cwd).

## Lesson

A shared lowering change made for one kernel model (kernel-only, traced) must be gated on that model;
`flowtransfer_host.cpp` serves every op. Regress at least one GemmSpace GEMM and one conv on the board
after touching it (`doc/plan/dataflowplan_generalize.md` stage 0).
