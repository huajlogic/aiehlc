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

## 8. Lessons Learned

1. **Packet merge without locks requires OOO DMA.** When multiple sources send to a single destination without lock-based flow control, the arrival order is non-deterministic. Self-chaining BDs (`NextBd→self`) cannot handle non-deterministic arrival — the hardware has no mechanism to correlate incoming packets with the correct iteration. OOO mode is the hardware solution: source BDs carry an OOO BD ID that tells the destination which BD to use.

2. **OOO per-source BD must correspond to a destination BD.** Each source MM2S BD needs `XAie_DmaSetOutofOrderBdId(dst_bd)` so the destination S2MM channel knows which BD to write into. In the `SingleDstBd` case, all sources point to the same destination BD.

3. **Destination BD repeat and iteration enable sequential data placement.** `XAie_DmaChannelSetStartQueue(bd, repeat=num_srcs)` tells the channel to reuse the BD `num_srcs` times. `XAie_DmaSetBdIteration(step, wrap, dim)` advances the write address by `step` words per transaction. Without iteration, all sources would write to the same DDR address, overwriting each other's data.

4. **OOO channels need `SetStartQueue`, not `PushBdToQueue` + `ChannelEnable`.** The `XAie_DmaChannelSetStartQueue` API combines BD queuing, repeat count, and channel enable in one call. This is the correct way to start OOO-enabled channels. The old `PushBdToQueue` + `ChannelEnable` pattern is for sequential (non-OOO) channels.

5. **With OOO, track the S2MM channel for completion, not per-source MM2S.** An OOO S2MM channel properly transitions to idle after exhausting its repeat count. The old workaround of tracking per-source MM2S completion was necessary only because the self-chaining BD never idled — it masked the real problem rather than solving it.
