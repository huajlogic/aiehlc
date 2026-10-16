<!-- Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: shimbdindexoverflow
description: Debug an AIE2PS shim DMA channel stuck in "acquire lock" on the wrong BD (e.g. mm2s0 status = acquire-lock, current BD = 0) even though the code programmed a different BD id. Root cause is a shim BD index that runs one past the 16-BD limit (BD 16), which aie-rt's off-by-one guard (`BdNum > NumBds`, should be `>=`) fails to reject, so the 9-word BD write lands on the DMA channel-control registers at 0x9300 (S2MM_0/MM2S_0 CTRL + TASK_QUEUE) and hijacks a channel onto a stale locked BD. Use when a shim MM2S/S2MM channel stalls on a BD the code never selected, or when deriving a second shim BD as bd_id+1.
---

# AIE2PS Shim BD Index Overflow → Channel-Control Register Corruption

## Symptom

A shim DMA channel stalls and a live dump (aiediag/aiedbg) shows, for example:

```
mm2s0: status = Acquire_Lock, current BD = 0
```

but the source programmed a *different* BD id (e.g. `bd_id = 15`) and the BD it
programmed has **no** lock (word-7 `LockAcqEn = 0`). The channel is running a BD
the code never intended, and it is parked acquiring a lock that no intended BD
requested.

## Root cause

The AIE2PS shim (NOC) DMA has exactly **16 BDs**, ids `0..15`
(`Aie2PSShimDmaMod.NumBds = 16`, `xaie2psgbl_reginit.c`). Register layout
(`xaie2psgbl_params.h`):

| Reg | Addr |
|-----|------|
| `DMA_BD0_0` (BD base) | 0x9000 |
| BD stride (`IdxOffset`) | 0x30 |
| `DMA_S2MM_0_CTRL` | 0x9300 |
| `DMA_S2MM_0_TASK_QUEUE` | 0x9304 |
| `DMA_MM2S_0_CTRL` | 0x9310 |
| `DMA_MM2S_0_TASK_QUEUE` | 0x9314 |

`BD 16` base = `0x9000 + 16*0x30 = 0x9300` = **`S2MM_0_CTRL`**. A 9-word BD write
for "BD 16" therefore overwrites `S2MM_0`/`MM2S_0` `CTRL` + `TASK_QUEUE`:

- word5 → `MM2S_0_TASK_QUEUE` (0x9314): enqueues a garbage Start-BD (SMID=0 from
  `XAie_DmaSetAxi(..,0,..)` → Start-BD-ID = 0) on MM2S ch0.
- word4 → `MM2S_0_CTRL` (0x9310): perturbs the channel enable/reset.

MM2S ch0 then force-starts **BD 0**; if BD 0 carries a stale lock (e.g. left by an
earlier benchmark that wrote shim BD 0), the channel parks in **acquire-lock**. A
later legitimate push of the intended BD just queues behind the stuck BD 0.

## Why the bad write is not rejected

`XAie_DmaWriteBd` (`thirdparty/aie-rt/driver/src/dma/xaie_dma.c`) guards with
`if (BdNum > DmaMod->NumBds)` — an **off-by-one** (should be `>=`). With
`NumBds = 16`, `BdNum = 16` passes (`16 > 16` is false), so the out-of-range
write proceeds. `BdNum = 17` would be rejected. Third-party driver code — do not
edit it; fix on the caller side.

## Fix

Never let a derived shim BD run past `NumBds-1`. When a code path needs a second
shim BD alongside `bd_id` (e.g. a control-packet response S2MM alongside the
forward MM2S), pick an adjacent **in-range, distinct** slot:

```c
uint8_t num_bds = 16U;
(void)XAie_DmaGetNumBds(dev, shim, &num_bds);
int32_t s2mm_bd = (bd_id + 1 < (int32_t)num_bds) ? (bd_id + 1) : (bd_id - 1);
```

Applied in `rt_tct_s2mm_arm` (`src/mlir/runtime/aie_runtime.c`); previously it
used the fixed `c->bd_id + 1`, which overflowed to 16 when the caller
(`example/debug/aieml_controlperf.cc`, `RAW_BD_SLOT = 15`) used the top slot.

## Quick triage

1. Dump the stalled channel: note `status` and `current BD`.
2. If `current BD` != the id the code programmed, suspect a channel-control
   register overwrite, not a routing/lock-protocol bug.
3. Grep the send path for any shim BD derived as `bd_id + N`; check `bd_id + N <= 15`.
4. Confirm the derived BD is also **distinct** from every other BD the same send
   uses (a shared slot means one WriteBd clobbers the other's descriptor).
