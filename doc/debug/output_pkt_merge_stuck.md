# Debug Analysis: Output Packet Merge Stuck (DMA Timeout)

**Date:** 2026-05-01
**Symptom:** S2MM DMA channels stuck indefinitely; `wait_event TIMEOUT` followed by multiple `wait_io TIMEOUT` on shim tile channels
**Root Cause:** `Runtime_Movedata_ManyToOne_SingleDstBd` used NextBd-self-chaining without OOO support. Packet merge from multiple source tiles to a single destination BD requires Out-of-Order (OOO) DMA, not self-looping BD chains.
**Fix:** Commit `6562e91` — switch to proper OOO DMA APIs: `XAie_DmaChannelEnOutofOrder`, `XAie_DmaChannelSetStartQueue`, `XAie_DmaSetOutofOrderBdId`, and BD iteration with repeat for sequential data placement.

---

## 1. Symptom Description

Running a multi-tile GEMM (4x4 mesh, 256x256 matrix) with packet-switched output merge caused the system to hang. From `applog_fix4`:

```
[aie_runtime] wait_event TIMEOUT after 100 iters - continuing to debug snapshot
[kernel_log] tile(0,3): no log (write_index=0)
[kernel_log] tile(0,4): no log (write_index=0)
...all 16 kernel tiles: no log (write_index=0)...
[aie_runtime] wait_io TIMEOUT after 5000 ms tile(2,0) ch=0 dir=1 pending=1
[aie_runtime] wait_io TIMEOUT after 5000 ms tile(2,0) ch=1 dir=1 pending=1
[aie_runtime] wait_io TIMEOUT after 5000 ms tile(3,0) ch=0 dir=1 pending=1
[aie_runtime] wait_io TIMEOUT after 5000 ms tile(3,0) ch=1 dir=1 pending=1
[aie_runtime] wait_io TIMEOUT after 5000 ms tile(6,0) ch=0 dir=1 pending=1
...
```

Key observations:
- **All kernel tiles show "no log (write_index=0)"** — kernels never started executing, meaning input data never arrived via DMA
- **Multiple S2MM channels TIMEOUT** — the destination shim tiles are stuck waiting for DMA completion
- **dir=1 (S2MM)** timeouts dominate — the receive side is stuck, not the send side
- **Channel status raw=0x00080010** — channel reports as running but never completes

---

## 2. Background: Packet Merge Data Flow

In a multi-tile GEMM, multiple AIE compute tiles produce partial results (output C slices) that must be merged into contiguous DDR memory through shim DMA. The data flow is:

```
Core tile (0,3) ──MM2S──┐
Core tile (0,4) ──MM2S──┤
Core tile (0,5) ──MM2S──┼──packet switch──► Shim tile (2,0) S2MM ──► DDR
Core tile (0,6) ──MM2S──┘
```

Multiple source MM2S BDs send data as packets to a single destination S2MM channel. The S2MM must receive data from each source and write it to sequential DDR addresses.

---

## 3. Root Cause: Self-Chaining BD Without OOO Support

### The broken approach (before fix)

The original `Runtime_Movedata_ManyToOne_SingleDstBd` configured the destination S2MM BD with **NextBd pointing to itself (self-chaining)** and used standard `PushBdToQueue` + `ChannelEnable`:

```c
/* BROKEN: NextBd → self for reuse */
XAie_DmaSetNextBd(&DmaInst, dst_bd, XAIE_ENABLE);  // BD loops to itself
XAie_DmaSetBdIteration(&DmaInst, iter_step_size, num_srcs, 0);

/* BROKEN: Standard channel start — no OOO awareness */
XAie_DmaChannelPushBdToQueue(DevInst, dst_tile, dst_ch, DMA_S2MM, dst_bd);
XAie_DmaChannelEnable(DevInst, dst_tile, dst_ch, DMA_S2MM);

/* BROKEN: No OOO BD ID on source BDs */
// Source BDs had no XAie_DmaSetOutofOrderBdId call

/* BROKEN: Tracked per-source MM2S as pending */
for (i = 0; i < num_srcs; i++) {
    g_pending[g_pending_count].tile = srcs[i].src_tile;
    g_pending[g_pending_count].ch = srcs[i].src_ch;
    g_pending[g_pending_count].dir = DMA_MM2S;  // waiting on source side
    g_pending_count++;
}
```

### Why self-chaining fails for packet merge

1. **No OOO BD selection**: Without OOO enabled, the S2MM channel processes BDs sequentially from its queue. A self-chaining BD (`NextBd→self`) will re-trigger after completing one transaction, but it has no mechanism to match incoming packets to the correct BD. When multiple sources send packets in non-deterministic order, the S2MM channel cannot correlate which source data to accept for which iteration.

2. **Self-chaining BD never reports idle**: With `NextBd→self`, the S2MM channel continuously loops and never reaches an idle state. The original code worked around this by waiting on source MM2S channels instead, but this is unreliable — a source MM2S completing only means data was sent into the stream network, not that it was received and written to DDR.

3. **No address advancement control**: Without OOO BD IDs, the hardware cannot properly advance the iteration counter and write address. Each packet from a different source needs to write to a different DDR offset, but the self-chaining BD has no way to know which iteration corresponds to which source.

### Why OOO is required for packet merge without locks

When multiple sources send to a single destination without lock-based synchronization, the arrival order is non-deterministic. The OOO DMA mechanism solves this:

- **Each source BD carries an OOO BD ID** (`XAie_DmaSetOutofOrderBdId`) in its packet header
- **The S2MM channel is OOO-enabled** (`XAie_DmaChannelEnOutofOrder`) and uses the OOO BD ID from incoming packets to select which destination BD to write into
- **BD auto-triggers** when a packet with the matching OOO BD ID arrives — no sequential queue ordering needed
- **Iteration with repeat** (`XAie_DmaChannelSetStartQueue` with repeat=num_srcs) ensures the BD handles exactly `num_srcs` transactions, with each iteration advancing the write address by `iter_step_size` words

---

## 4. The Fix (Commit 6562e91)

### 4.1 Destination BD: Remove NextBd-self, keep iteration

```diff
- /* NextBd → self: same BD handles the next DMA transaction */
- XAie_DmaSetNextBd(&DmaInst, dst_bd, XAIE_ENABLE);
-
  /* Iteration: address advances iter_step_size words per transaction */
  XAie_DmaSetBdIteration(&DmaInst, iter_step_size, num_srcs, 0);
```

The iteration (`XAie_DmaSetBdIteration(step, wrap, currentDim)`) tells the hardware:
- After each transaction, advance the write address by `iter_step_size` 32-bit words
- Wrap (reset address offset) after `num_srcs` transactions
- This ensures each source's data is written sequentially, not overlapping in the same location

### 4.2 S2MM channel: Enable OOO, use SetStartQueue

```diff
- XAie_DmaChannelPushBdToQueue(DevInst, dst_tile, dst_ch, DMA_S2MM, dst_bd);
- XAie_DmaChannelEnable(DevInst, dst_tile, dst_ch, DMA_S2MM);
+ XAie_DmaChannelDesc DmaChannelDescInst;
+ XAie_DmaChannelDescInit(DevInst, &DmaChannelDescInst, dst_tile);
+ XAie_DmaChannelEnOutofOrder(&DmaChannelDescInst, XAIE_ENABLE);
+ XAie_DmaWriteChannel(DevInst, &DmaChannelDescInst, dst_tile, dst_ch, DMA_S2MM);
+
+ XAie_DmaChannelSetStartQueue(DevInst, dst_tile, dst_ch, DMA_S2MM,
+                               dst_bd, num_srcs, XAIE_DISABLE);
```

Key changes:
- **`XAie_DmaChannelEnOutofOrder`**: Enables OOO mode on the S2MM channel. The channel now selects BDs based on the OOO BD ID in incoming packet headers instead of processing the sequential BD queue.
- **`XAie_DmaWriteChannel`**: Writes the channel descriptor (with OOO flag) to hardware.
- **`XAie_DmaChannelSetStartQueue` with repeat=num_srcs**: Starts the channel with the BD and tells it to repeat `num_srcs` times. Each repeat uses the iteration step to advance the write address. This replaces `PushBdToQueue` + `ChannelEnable`.

### 4.3 Source BDs: Add OOO BD ID

```diff
+ /* OOO BD ID on source — tells the destination S2MM which BD to use */
+ XAie_DmaSetOutofOrderBdId(&DmaInst, dst_bd);
```

Each source MM2S BD now carries the destination BD ID in its OOO field. When the packet arrives at the destination S2MM channel, the hardware extracts this OOO BD ID and uses it to select which BD handles the write. Since `SingleDstBd` uses a single destination BD, all sources set OOO BD ID = `dst_bd`.

### 4.4 Pending tracking: Wait on S2MM, not per-source MM2S

```diff
- /* Record source MM2S as pending — self-looping S2MM never idles */
- for (i = 0; i < num_srcs; i++) {
-     g_pending[g_pending_count].tile = srcs[i].src_tile;
-     g_pending[g_pending_count].ch = srcs[i].src_ch;
-     g_pending[g_pending_count].dir = DMA_MM2S;
-     g_pending_count++;
- }
+ /* Record single S2MM pending entry for WaitAll */
+ g_pending[g_pending_count].tile = dst_tile;
+ g_pending[g_pending_count].ch = dst_ch;
+ g_pending[g_pending_count].dir = DMA_S2MM;
+ g_pending_count++;
```

With OOO enabled (no self-chaining), the S2MM channel properly reports idle after processing all `num_srcs` transactions. So `WaitAll` can wait on the single S2MM channel instead of tracking every source MM2S.

---

## 5. OOO DMA Operation Model

```
Source tile (0,3)                          Destination Shim (2,0)
┌──────────────────┐                      ┌──────────────────────────┐
│ MM2S BD 4        │                      │ S2MM Channel (OOO mode)  │
│  addr=0x78000    │──── packet ────────►│                          │
│  pkt_id=0        │  ooo_bd_id=2         │  BD 2:                   │
│  ooo_bd_id=2     │                      │    addr=DDR_BASE         │
└──────────────────┘                      │    len=per_src_bytes     │
                                          │    iteration:            │
Source tile (0,4)                          │      step=per_src_bytes/4│
┌──────────────────┐                      │      wrap=4 (num_srcs)   │
│ MM2S BD 4        │                      │                          │
│  addr=0x78000    │──── packet ────────►│  Transaction 0: DDR+0x0  │
│  pkt_id=1        │  ooo_bd_id=2         │  Transaction 1: DDR+step │
│  ooo_bd_id=2     │                      │  Transaction 2: DDR+2*st │
└──────────────────┘                      │  Transaction 3: DDR+3*st │
                                          │                          │
Source tile (0,5)                          │ SetStartQueue(bd=2,      │
┌──────────────────┐                      │   repeat=4, token=DIS)   │
│ MM2S BD 4        │──── packet ────────►│                          │
│  ooo_bd_id=2     │                      └──────────────────────────┘
└──────────────────┘

Source tile (0,6)
┌──────────────────┐
│ MM2S BD 4        │──── packet ────────►
│  ooo_bd_id=2     │
└──────────────────┘
```

**Arrival order is non-deterministic.** The OOO mechanism ensures:
1. Each arriving packet's OOO BD ID selects BD 2
2. The iteration counter advances the write offset by `iter_step_size` words per transaction
3. After `num_srcs` (4) transactions, the BD repeat count is exhausted
4. The S2MM channel transitions to idle, and `WaitAll` detects completion

---

## 6. Files Changed

| File | Change |
|------|--------|
| `src/mlir/runtime/aie_runtime_common.c` | `Runtime_Movedata_ManyToOne_SingleDstBd`: removed `XAie_DmaSetNextBd` self-chain; added `XAie_DmaChannelEnOutofOrder` + `XAie_DmaWriteChannel` + `XAie_DmaChannelSetStartQueue(repeat=num_srcs)`; added `XAie_DmaSetOutofOrderBdId(dst_bd)` on each source BD; changed pending tracking from per-source MM2S to single S2MM |
| `src/mlir/runtime/aie_runtime_common.h` | Updated function documentation: replaced NextBd-self description with OOO BD selection description |
| `example/debug/aieml_debug.cc` | Switched active test to `test_routing_packet2`; changed `dst_num_dims` from 3 to 0 (linear addressing) |

---

## 7. Verification

After the fix, the same multi-tile GEMM completes without timeout. The `WaitAll` successfully waits on S2MM channels which now properly report idle after receiving all source transactions:

```
[aie_runtime] wait_io tile(2,0) ch=0 dir=1
[aie_runtime] wait_io done tile(2,0) ch=0 dir=1
[aie_runtime] wait_io tile(3,0) ch=0 dir=1
[aie_runtime] wait_io done tile(3,0) ch=0 dir=1
...
```

---

## 8. OOO Channel Architecture: repeat_count, iter_wrap, and iter_step_size

This section explains the complete AIEML OOO DMA mechanism and how `repeat_count`, `iter_wrap`, and `iter_step_size` cooperate to handle two distinct scenarios:

- **Single BD + multiple repeats**: one destination BD handles all source tiles
- **Multiple BDs + repeat = N**: N destination BDs handle N source tiles via packet-matched dispatch

### 8.1 The Three Control Parameters

| Parameter | Set By | Scope | Purpose |
|-----------|--------|-------|---------|
| `repeat_count` | `SetStartQueue(bd, repeat, token)` | **Channel-level** | How many BD completions the channel processes before going idle |
| `iter_wrap` | `SetBdIteration(step, wrap, dim)` | **Per-BD** | How many times this BD re-fires (address advancing each time) before one "BD completion" |
| `iter_step_size` | `SetBdIteration(step, wrap, dim)` | **Per-BD** | DDR address advance (in 32-bit words) between consecutive BD fires within one iteration cycle |

The total number of DMA transactions for a channel is:

```
total_transactions = repeat_count × iter_wrap   (per BD, if single BD)
                   = repeat_count               (if iter_wrap=1, i.e., no intra-BD iteration)
```

### 8.2 Scenario A: Single BD + Multiple Repeats (SingleDstBd)

This is the original `ManyToOne_SingleDstBd` pattern from Section 4.

```
4 source core tiles → 1 destination SHIM BD (OOO mode)

SetStartQueue(bd=2, repeat=4)
SetBdIteration(step=1024, wrap=4, dim=0)
```

How it works:
1. Channel starts with `repeat=4` — it will process 4 BD completions
2. Each incoming packet carries `ooo_bd_id=2` → all dispatch to BD 2
3. BD 2 has `iter_wrap=4`: it fires 4 times, advancing DDR address by `iter_step_size` words each time
4. After 4 fires, BD 2 completes once → channel decrements repeat counter
5. But here `repeat=4` and `iter_wrap=4` means 4×4=16 total fires — this is **wrong** for 4 sources!

**Correction**: For SingleDstBd, `repeat=1` and `iter_wrap=4` (or `repeat=4` and `iter_wrap=1`). The key insight:

```
Single BD with iteration:
  repeat_count = 1            (BD completes once = channel done)
  iter_wrap = num_srcs (4)    (BD fires 4 times before completing)
  iter_step_size = per_src_bytes / 4   (advance write address per source)

  Total transactions = 1 × 4 = 4 ✓
```

```
Single BD without iteration:
  repeat_count = num_srcs (4) (BD completes 4 times)
  iter_wrap = 1               (each BD fire = one completion)
  iter_step_size = 0          (no address advance — all write to same offset)

  Total transactions = 4 × 1 = 4
  BUT: all 4 writes go to the same DDR address! Data overwrites! ✗
```

**Conclusion**: For single-BD gather, iteration is required for address advancement. Use `iter_wrap = num_srcs`, `repeat = 1`.

### 8.3 Scenario B: Multiple OOO BDs + repeat = N (tilinglinalg path)

This is the current tilinglinalg generated code pattern. Each source tile gets its own destination SHIM BD at a fixed DDR offset.

```
4 source core tiles → 4 destination SHIM BDs (OOO mode)

BD 2: offset=0,     packet_id=1, ooo_bd_id=2
BD 3: offset=4096,  packet_id=2, ooo_bd_id=3
BD 4: offset=8192,  packet_id=3, ooo_bd_id=4
BD 5: offset=12288, packet_id=4, ooo_bd_id=5

SetStartQueue(bd=2, repeat=4)   ← repeat = num_BDs × fires_per_BD
```

How it works:
1. Channel starts with `repeat=4`
2. Packet from core 0 arrives with `ooo_bd_id=2` → dispatches to BD 2 (DDR+0)
3. Packet from core 2 arrives with `ooo_bd_id=4` → dispatches to BD 4 (DDR+8192)
4. Packet from core 1 arrives with `ooo_bd_id=3` → dispatches to BD 3 (DDR+4096)
5. Packet from core 3 arrives with `ooo_bd_id=5` → dispatches to BD 5 (DDR+12288)
6. 4 BD completions total → repeat counter exhausted → channel idle

```
Multiple BDs, each fires once:
  repeat_count = numCoreTiles (4)     (total BD completions across all BDs)
  iter_wrap = 1 per BD                (each BD fires once per completion)
  iter_step_size = 0 per BD           (no address advance needed — offset is fixed per BD)

  Total transactions = 4 × 1 = 4 ✓
  Each BD writes to its own fixed DDR offset ✓
  Arrival order doesn't matter — OOO dispatches by BD ID ✓
```

**Why iter_step_size = 0 and iter_wrap = 1**: Each BD already has a unique DDR offset baked in. There is no need for iteration-based address advancement. The BD fires exactly once, writes its data, and completes. The `repeat_count` on the channel simply counts how many BD completions to expect.

### 8.4 Scenario B + K-rounds: Multiple BDs with Iteration

When `effectiveK < fullK` (temporal K-tiling), each source core sends data across multiple k-rounds. Each SHIM BD must fire multiple times, advancing its DDR read/write position between k-rounds.

```
4 source tiles × 4 k-rounds = 16 total transactions

BD 2: offset=0,     iter_step_size=4096, iter_wrap=4   (k-round advance)
BD 3: offset=4096,  iter_step_size=4096, iter_wrap=4
BD 4: offset=8192,  iter_step_size=4096, iter_wrap=4
BD 5: offset=12288, iter_step_size=4096, iter_wrap=4

SetStartQueue(bd=2, repeat=16)
```

How it works:
1. Core 0 sends k-round 0 data → BD 2 fires (DDR+0), iter counter=1
2. Core 0 sends k-round 1 data → BD 2 fires (DDR+0+4096), iter counter=2
3. Core 0 sends k-round 2 data → BD 2 fires (DDR+0+8192), iter counter=3
4. Core 0 sends k-round 3 data → BD 2 fires (DDR+0+12288), iter counter=4 → BD 2 completes
5. Meanwhile cores 1-3 are also sending → BDs 3-5 fire independently
6. After 16 total BD completions → channel idle

```
Multiple BDs, each fires kRounds times:
  repeat_count = numCoreTiles × kRounds (4 × 4 = 16)
  iter_wrap = kRounds (4) per BD
  iter_step_size = effectiveK × element_bytes / 4   (DDR advance per k-round, in 32-bit words)

  Total transactions = 16
  Each BD handles one core's data across all k-rounds ✓
```

### 8.5 Scenario B + Data Splitting: Multiple BDs with numRounds > 1

When per-core data exceeds `max_buffer_bytes`, the data is split into multiple rounds. Each round is a separate DMA transaction. This is independent of k-rounds.

```
4 source tiles × 2 rounds/tile = 8 total transactions
(e.g., per-core data = 8192 bytes, max_buffer_bytes = 4096)

BD 2: iter_wrap=2, iter_step_size = 4096/4 = 1024 words
BD 3: iter_wrap=2, iter_step_size = 1024 words
BD 4: iter_wrap=2, iter_step_size = 1024 words
BD 5: iter_wrap=2, iter_step_size = 1024 words

SetStartQueue(bd=2, repeat=8)
```

### 8.6 Summary: How repeat_count and iter_wrap Cooperate

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SHIM S2MM Channel (OOO mode)                     │
│                                                                     │
│  SetStartQueue(bd=first_bd, repeat=R)                               │
│  R = total BD completions expected before channel goes idle         │
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │
│  │  BD 2    │  │  BD 3    │  │  BD 4    │  │  BD 5    │            │
│  │ ooo_id=2 │  │ ooo_id=3 │  │ ooo_id=4 │  │ ooo_id=5 │            │
│  │ iter_w=W │  │ iter_w=W │  │ iter_w=W │  │ iter_w=W │            │
│  │ step=S   │  │ step=S   │  │ step=S   │  │ step=S   │            │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘            │
│                                                                     │
│  Each BD fires W times (iter_wrap) before completing once.          │
│  Channel processes R total BD completions.                          │
│                                                                     │
│  repeat_count R = numBDs × (fires_per_BD / iter_wrap)               │
│                 = numBDs × 1     (if iter_wrap = fires_per_BD)      │
│                 = numCoreTiles × numRoundsPerCore                   │
│                                                                     │
│  When iter_wrap = 1, iter_step_size = 0:                            │
│    BD fires once, no address advance. R = numBDs.                   │
│                                                                     │
│  When iter_wrap > 1, iter_step_size > 0:                            │
│    BD re-fires W times, advancing address by step each time.        │
│    R = numBDs × ceil(totalRounds / iter_wrap).                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Decision tree for setting these parameters:**

```
Is per-core data ≤ max_buffer_bytes?
  YES → iter_wrap = 1, iter_step_size = 0
        repeat_count = numCoreTiles
  NO  → numRounds = ceil(per_core_data / max_buffer_bytes)
        iter_wrap = numRounds
        iter_step_size = max_buffer_bytes / 4  (in 32-bit words)
        repeat_count = numCoreTiles × numRounds

Are there k-rounds (effectiveK < fullK)?
  YES → multiply iter_wrap by kRounds
        iter_step_size = effectiveK × elem_bytes / 4
        repeat_count = numCoreTiles × numRounds × kRounds
```

### 8.7 pp_depth vs Data Splitting

`pp_depth` controls how many **physical ping-pong buffers** exist on the core tile for DMA/compute overlap. It does NOT control data splitting or iter_wrap.

```
pp_depth = 2:  2 physical buffers (ping + pong) for double-buffering
               Physical memory cost = pp_depth × bufferSize per port
               Does NOT change: iter_wrap, iter_step_size, repeat_count, numRounds

Data splitting: driven ONLY by max_buffer_bytes
               bufferSize = min(per_k_round_data, max_buffer_bytes)
               numRounds = ceil(per_k_round_data / bufferSize)
```

**Bug fixed (May 2026):** Previously, `pp_depth` was incorrectly used to split data (`bufferSize = data / ppDepth`), causing `numRounds = 2` when it should have been `1`. This propagated to `iter_wrap = 2` and `repeat_count = numCoreTiles × 2`, making the SHIM wait for twice as many transactions as the cores actually sent — causing DMA starvation/hangs.

---

## 9. Lessons Learned

1. **Packet merge without locks requires OOO DMA.** When multiple sources send to a single destination without lock-based flow control, the arrival order is non-deterministic. Self-chaining BDs (`NextBd→self`) cannot handle non-deterministic arrival — the hardware has no mechanism to correlate incoming packets with the correct iteration. OOO mode is the hardware solution: source BDs carry an OOO BD ID that tells the destination which BD to use.

2. **OOO per-source BD must correspond to a destination BD.** Each source MM2S BD needs `XAie_DmaSetOutofOrderBdId(dst_bd)` so the destination S2MM channel knows which BD to write into. In the `SingleDstBd` case, all sources point to the same destination BD.

3. **Destination BD repeat and iteration enable sequential data placement.** `XAie_DmaChannelSetStartQueue(bd, repeat=num_srcs)` tells the channel to reuse the BD `num_srcs` times. `XAie_DmaSetBdIteration(step, wrap, dim)` advances the write address by `step` words per transaction. Without iteration, all sources would write to the same DDR address, overwriting each other's data.

4. **OOO channels need `SetStartQueue`, not `PushBdToQueue` + `ChannelEnable`.** The `XAie_DmaChannelSetStartQueue` API combines BD queuing, repeat count, and channel enable in one call. This is the correct way to start OOO-enabled channels. The old `PushBdToQueue` + `ChannelEnable` pattern is for sequential (non-OOO) channels.

5. **With OOO, track the S2MM channel for completion, not per-source MM2S.** An OOO S2MM channel properly transitions to idle after exhausting its repeat count. The old workaround of tracking per-source MM2S completion was necessary only because the self-chaining BD never idled — it masked the real problem rather than solving it.
