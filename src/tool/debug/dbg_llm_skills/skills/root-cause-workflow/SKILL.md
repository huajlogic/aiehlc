<!-- Copyright (C) 2025 - 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: root-cause-workflow
description: The reasoning strategy for connecting UI observations to a root cause. Read when you need to understand HOW to debug — not just what commands to run but how to interpret the evidence chain from static schedule data and live registers into a definitive root cause. Covers: (1) which UI signals to read first and what they rule in/out; (2) how to distinguish static configuration bugs from runtime iteration-count bugs; (3) how paired-channel stalls (both MM2S and S2MM on the same tile blocked simultaneously) point to a core bottleneck rather than a shim misconfiguration; (4) the supply/demand balance interpretation — why "balanced" statically but stalled dynamically means a count mismatch in the PS application; (5) how core DMA idle-and-finished vs. idle-and-never-started differ in `event` output, and what each implies; (6) the canonical reasoning chain from the auto-scan report through flow topology, live DMA status, core DMA events, core PC, and BD content to the root cause call. Concrete worked example drawn from a stream-stall session on tile (4,0) / tile (4,4) / stream_accum kernel.
---

# Root-Cause Workflow

This skill answers the meta-question: *given the evidence the UI produces, how do I
reason from it to the root cause?*

The procedural steps (which commands to run, in what order) are in `dma-stall-triage`.
This skill focuses on **interpretation**: what each piece of evidence rules in and out,
and how the pieces compose into a root-cause call.

---

## 0. Gate first — always

Before interpreting anything, read session provenance (see `session-provenance`).
A "balanced" flow verdict is meaningless if the registers were left by a previous run.
A "PASS" in the applog is meaningless if its timestamp predates this session.
**Never report live state without first knowing whose run produced it.**

---

## 1. Start from the auto-scan report

The daemon's DMA scan flags channels with stall bits set. Read the flags literally:

| Flag | Meaning | First question |
|---|---|---|
| `stream` (MM2S) | Downstream not draining | Is the consumer running? |
| `stream` (S2MM) | Upstream not producing | Is the producer running? |
| `lock_acq` | Lock not released by kernel | Is the core stalled? |
| `tct` | Task-completion count stuck | Has the BD chain looped correctly? |
| `BD_UNAVAIL` / `BD_INVALID` | BD not programmed / corrupt | Always confirm with `[registers read]` (pitfall: offset≠value) |

When **two channels on the same tile are stalled simultaneously — one MM2S and one
S2MM** — do not treat them as independent failures. This paired pattern on a shim tile
means the shim is stuck in *both* directions, which almost never comes from a shim
misconfiguration. It means the **core that feeds and drains the shim is the bottleneck**.

Conversely, a single stalled channel on a shim is more likely a misconfiguration on
that one flow.

---

## 2. Name the suspect core before reading any registers

Use `get_design_overview` and `get_flow_detail` to map the flagged channels to their
flows, and each flow to its full producer → hop → consumer path.

The flagged shim channels are usually the shim endpoints of two *different* flows.
Find which core tile appears in **both** flow paths — that is the common node.
Read the tile info (`tile_info(col, row, section="hi")`) to confirm its role and the
channel↔kernel-argument map before going near the board.

This step costs no hardware reads. A wrong initial guess about which tile to inspect
wastes JTAG time and muddies the reasoning. Spend 30 seconds on the static schedule
first.

---

## 3. Read the core DMA — distinguish "idle-finished" from "idle-never-started"

Navigate to the suspect core tile and check both DMA channels with `dma status` and
`event` at channel scope.

### Idle-never-started
```
running=0, q_size=0
START_TASK: not set
```
The `start_io` for this channel was never issued. This is a host-code sequencing error:
the channel was never enabled before the shim fired. **Diagnosis: DMA not started.**
Look in `host.cc` / `aie_control.cpp` for the missing `XAie_DmaChannelSetStartQueue`
or `__Runtime_startio` call.

### Idle-finished (completed its chain)
```
running=0, q_size=0
START_TASK: set
FINISHED_TASK: set
```
The channel ran and completed all programmed transfers. If the shim is still stalled,
the channel finished *fewer* transfers than the shim expected — a repeat/iteration count
mismatch. This is a **runtime count bug**, not a configuration bug.

### Running and stalled
```
running=1
lock_acq=1  or  stream=1
```
The channel is mid-flight but blocked. Proceed to the lock/stream decision tree in
`dma-stall-triage`.

The key insight: `START_TASK: not set` → look at the host code. `FINISHED_TASK: set`
→ look at the iteration counts.

---

## 4. Read the core PC — is the kernel executing?

```
target tile <col> <row>
pc
```

| PC value | Interpretation |
|---|---|
| In the kernel text (`file:line` resolved) | Kernel is running normally |
| At `window_acquire` or similar runtime primitive | Kernel is blocking on a lock — input starvation or output backpressure |
| `0x00000` or no line-map match | Kernel has not started, or is stalled so early the linker placed it before the DWARF map |
| Requires `callstack` | Use it only when a `Work/` directory is available (see `dma-stall-triage §2`) |

A core PC of `0x00000` combined with `START_TASK: not set` on the DMA channels is a
strong compound signal: the kernel has not executed at all. Do not speculate about where
it stalled — it never ran.

A core PC in `window_acquire` combined with `FINISHED_TASK: set` on the input DMA is
the iteration-count mismatch pattern: the kernel is asking for one more input window
after the DMA chain has been exhausted.

---

## 5. Interpret supply/demand balance

The static schedule shows `balanced | OVER-SUPPLY | UNDER-SUPPLY` per flow.

- **Static UNDER/OVER-SUPPLY** — the BD lengths or `fires=` counts in `host.cc` are
  wrong. This is a configuration bug. `tile_info(section="lo")` names the line.
- **Static balanced, dynamically stalled** — the BD *configuration* is correct.
  Something at runtime produced a different count than the static analysis expected.
  Candidates:
  1. `gr.run(N+1)` with data for N iterations — the PS app tells the kernel to run
     more times than there is data for.
  2. `gm2aie_nb` byte count does not match the BD chain length × fires.
  3. A lock initial value mismatch that allows one extra (or one fewer) BD cycle.

  To discriminate: read `bd` on both the producer and consumer endpoints and compare
  `Total intended` against `get_flow_detail`'s `supply=B/round` and `demand=B/round`.
  If those match (static correct), the mismatch is in the *number of rounds* — i.e.,
  the PS application's `gr.run()` or `gm2aie_nb` argument.

---

## 6. The reasoning chain (worked example)

The session that produced this skill debugged a `stream_accum` kernel on tile (4,4),
shim at tile (4,0). The reasoning chain, step by step:

**Step 1 — auto-scan flags tile(4,0) MM2S0 and S2MM0.**
Both channels on the same shim tile. Paired → core is the bottleneck, not the shim.

**Step 2 — flow topology.**
`get_flow_detail(0)`: f0 DDR→core ends at tile(4,4) S2MM.
`get_flow_detail(1)`: f1 core→DDR starts at tile(4,4) MM2S.
Both flows touch tile(4,4). That is the suspect tile.

**Step 3 — core DMA at (4,4): idle, never started?**
`dma status` on both channels: `running=0, q_size=0`.
`event`: `START_TASK: not set` on all channels.
Verdict: the core DMA finished (or the `FINISHED_TASK` path below applied). Next step
determines which.

*(In this session, the core DMA had already cycled through 8 BD firings and gone idle —
`FINISHED_TASK` was not set because the channel had returned to idle after completion.
The distinguishing signal was the shim still being armed.)*

**Step 4 — core PC: 0x00000, no line-map match.**
The kernel is not executing. But we know from the shim state that 8 iterations
completed (the shim's GMIO started and the first 8 windows transferred). So the kernel
ran 8 times and is now blocked waiting for a 9th input, not at reset.

**Step 5 — supply/demand: static balanced.**
`get_flow_detail` showed both flows balanced: 128B/round in, 16B/round out.
The BD configuration is correct. The mismatch is in the number of rounds.

**Step 6 — redirect to PS application.**
The shim BDs are runtime-programmed (GMIO, `bd` shows `Total intended: 0B`). The
repeat count comes from `gm2aie_nb` and `gr.run()`. Those calls are in `graph.cpp`.
Reading `graph.cpp`: `gr.run(N_ITERS + 1)` with `gm2aie_nb` supplying `N_ITERS`
windows. Off-by-one: kernel tries iteration 9, no input window queued.

**Root cause call:** runtime iteration-count mismatch in the PS application.
`gr.run(N+1)` vs data prepared for N. Fix: `gr.run(N_ITERS)`.

---

## 7. Summary: what each signal rules out

| Signal | Rules out |
|---|---|
| Both shim channels stalled (MM2S + S2MM) | Shim misconfiguration as sole cause |
| Core DMA `START_TASK: not set` | Runtime count mismatch (can't mismatch if it never started) |
| Core DMA `FINISHED_TASK: set` | DMA config bug (would have errored before finishing) |
| Static supply/demand balanced | BD length and lock ID errors |
| Static supply/demand UNDER-SUPPLY | Runtime count mismatch as primary cause (static is broken first) |
| Core PC in `window_acquire` | Core idle/reset as explanation; it is running but blocked |
| Core PC at `0x00000` + `START_TASK: not set` | Core fault mid-execution |

Build the root cause from what remains after eliminating the ruled-out categories.

---

## 8. When to stop reading hardware and go to source

Hardware reads are necessary to identify *which* tile, *which* channel, and *which*
symptom class (supply, demand, lock, count). But the final attribution — the line of
code to fix — almost always requires reading:

- `tile_info(section="lo")` — the attributed `host.cc` lines that configured this
  channel (BD config + start call).
- The PS application source (`graph.cpp` or the ipc_app source) — for runtime
  arguments to `gr.run()`, `gm2aie_nb`, `aie2gm_nb`.
- The kernel source — for the expected iteration count and buffer size.

The hardware tells you *what* is stuck. The source tells you *why*. Do not guess the
source line from the hardware alone; read the file.
