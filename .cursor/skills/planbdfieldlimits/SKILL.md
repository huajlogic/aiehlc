---
name: planbdfieldlimits
description: A dataflow-plan GEMM at a new shape hangs in `wait_io TIMEOUT tile(c,0) ch=0 dir=1` (B input shims) or runs with GOLDEN FAIL on ~96 % of outputs while the 7680 x 512 x 2560 build passes; B held whole exactly fills a MemTile (512 KiB); B streamed as memtile_ring; a shim BD with `iter_step_size=0, iter_wrap=N`; a channel started more than 256 times
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Dataflow plan: DMA descriptor fields that silently truncate

Three AIE2PS fields the plan derivation (`pass/dataflowplan/plandma.cpp`) must respect. None of them
is reported by the driver at run time in a way the launch notices -- the DMA just moves the wrong
amount or the wrong place. The limits live in `plantarget.h` and `deriveDmaProgram` rejects a plan
that breaks them, naming the BD / channel.

## 1. MemTile BD length: 17 bits of 32-bit words

`XAIE2PSGBL_MEM_TILE_MODULE_DMA_BD0_0_BUFFER_LENGTH_MASK` = `0x1FFFF` (core tile: `0x3FFF`). A
resident B whose column strips are exactly 512 KiB (int8 4096 x 512 x 4096: 2 strips x 64 rows x 4096 B)
is 131072 words = 2^17: written as 0. Symptom: launch 0 hangs on the B input shims.
Limit: `memBdMaxLenWords` / `coreBdMaxLenWords`. plansynth treats a B that does not fit ONE BD as not
fitting the MemTile and streams it (`[DataflowPlan] stream 1: held whole it needs ... one BD holds
524284 B): streamed as memtile_ring`).

## 2. BD iteration step: the field holds step - 1

`_XAieMl_DmaSetBdIteration` stores `StepSize`; the BD word is written with `StepSize - 1U`. A step of 0
(meant: "read the same data every iteration") becomes the largest step, so every round after the first
reads far outside the buffer. Symptom: no hang, GOLDEN FAIL on almost every output (96-98 %), at the
re-read stream (B ring: `iter_step_size=0, iter_wrap=60` on the B shim BDs in host.cc).
Fix: the same data again = no iteration (`iter_wrap` 1; the runtime only programs iteration for wrap > 1)
and the channel start's repeat count re-reads the BD. `deriveDmaProgram` rejects any shim BD with
wrap > 1 and a step under one word.

## 3. Channel start repeat: at most 256 per start, 4 starts queued

`MaxRepeatCount = 256U`, `StartQSizeMax = 4U` (`xaie2psgbl_reginit.c`) for core, MemTile and shim
channels. A ring's MemTile channels walk `rounds x chunks per tile / (ring x k)` times per launch; with B
streamed (k = groups x channels = 4) that is 600 at bf16 7680 x 512 x 2560 for ring 2. plandma splits a
walk over up to `chStartQueue` equal starts (`__Runtime_dma_channel_start` twice or more = queued, tags
`.../q1`); plansynth picks the shallowest B ring whose walk splits that way. A deeper ring instead runs
out of MemTile BDs: a bank (24 BDs) serves 3 channels, so 4 MM2S replays of ring 5 + its 20-BD S2MM
chain cannot be placed (`MemTile (1, 1): out of DMA channels for B's replays`). Limits: `chMaxRepeat`,
`chStartQueue`; a walk beyond 256 x 4 or not divisible is a build error.

## Check

`[DataflowPlan] stream ...` lines in the build log; grep host.cc for `iter_step_size=0` with
`iter_wrap>1` (must not exist); `__Runtime_startio(..., N)` with N <= 256.
