# Out-of-Order (OOO) DMA Buffer Descriptor Dispatch

## 1. Problem Statement

In a multi-tile GEMM, N compute tiles produce output results that must converge on a single shim tile for write-back to DDR. This is a **many-to-one output gather** pattern.

The fundamental problem: tile completion order is **non-deterministic**. Network contention, varying kernel execution times, and DMA scheduling all affect which tile's data arrives first at the shim. Sequential BD processing would require a fixed arrival order -- if tile 2's data arrives before tile 0's, a sequential S2MM BD chain stalls or writes data to the wrong DDR location.

**OOO DMA dispatch** solves this: each source tile's MM2S BD carries an OOO BD ID in its packet header. The destination shim's S2MM channel, with OOO mode enabled, reads this ID from incoming packets and dispatches to the correct BD -- regardless of arrival order.

## 2. Hardware OOO Mechanism

Three XAie APIs form the core of OOO DMA:

### Source side (MM2S BD)
```c
XAie_DmaSetOutofOrderBdId(&srcDmaInst, dstBdId);
```
Embeds `dstBdId` into the packet header of the source MM2S BD. This tells the destination S2MM channel which BD should process the incoming transfer.

### Destination side (S2MM channel)
```c
XAie_DmaChannelDesc channelDesc;
XAie_DmaChannelDescInit(DevInst, &channelDesc, dst_tile);
XAie_DmaChannelEnOutofOrder(&channelDesc, XAIE_ENABLE);
XAie_DmaWriteChannel(DevInst, &channelDesc, dst_tile, dst_ch, DMA_S2MM);
```
Enables OOO mode on the S2MM channel. Instead of processing BDs sequentially from the queue, the channel reads the OOO BD ID from each incoming packet header to select which BD handles the transfer.

### Channel start
```c
XAie_DmaChannelSetStartQueue(DevInst, dst_tile, dst_ch, DMA_S2MM,
                             bdId, repeat_count, XAIE_DISABLE);
```
Starts the S2MM channel with `repeat_count` = number of source transactions. Each incoming packet consumes one repeat.

**Key principle**: The OOO BD ID is set on the **source side only**. Destination BDs are passive -- they do NOT need `XAie_DmaSetOutofOrderBdId`. The S2MM channel reads the OOO BD ID from the packet header to dispatch.

## 3. Two OOO Modes

### Mode A: Many Source BDs -> Many Destination BDs

**API**: `Runtime_Movedata_ManyToOne(DevInst, srcs, num_srcs, dst_tile, dst_ch)`

Each source tile gets its own source BD and maps to a unique destination BD on the shim. Multiple source BDs can share the same destination BD (BD grouping).

**Flow**:
1. Group source descriptors by `dst_bd` -- sources sharing the same `dst_bd` form a BD group
2. For each unique `dst_bd`, configure one shim S2MM BD:
   - Address = `srcs[first_in_group].recv_phy`
   - Length = `dst_len` (or `data_bytes` if `dst_len == 0`)
   - If group count > 1: `XAie_DmaSetBdIteration(StepSize=dst_len/4, Wrap=group_count)` -- address advances by `dst_len` bytes between transactions within the group
3. Enable OOO on S2MM channel
4. `SetStartQueue(bdId=0, repeat=num_srcs)` -- one repeat per source transaction
5. For each source: configure MM2S BD with `XAie_DmaSetOutofOrderBdId(srcs[i].dst_bd)`

**BD grouping validation**: all sources in a group must have matching `dst_len` and `recv_phy`.

### Mode B: Many Source BDs -> Single Destination BD

**API**: `Runtime_Movedata_ManyToOne_SingleDstBd(DevInst, srcs, num_srcs, dst_tile, dst_ch, dst_bd, dst_addr, per_src_bytes, dst_num_dims, dst_dims, iter_step_size)`

One shim BD handles all incoming transfers via iteration (address advancement):

**Flow**:
1. Configure one shim S2MM BD:
   - Address = `dst_addr`
   - Length = `per_src_bytes` (per transaction, not total)
   - `XAie_DmaSetBdIteration(StepSize=iter_step_size, Wrap=num_srcs, CurrentDim=0)` -- address advances by `iter_step_size` words after each transaction
   - Optional multi-dim addressing via `dst_dims/dst_num_dims`
2. Enable OOO on S2MM channel
3. `SetStartQueue(bdId=dst_bd, repeat=num_srcs)`
4. All source MM2S BDs carry the same `ooo_bd_id = dst_bd`

**Default `iter_step_size`**: if 0, auto-computed as `per_src_bytes / 4` (contiguous placement).

## 4. Example Walkthrough (aieml_debug.cc)

### test_routing_packet -- Mode A with BD Grouping

**Configuration**: `SRCNUM=3` tiles, `SRCNUM_DUP_ROUND=2` -> 6 total source descriptors.

**Source descriptor setup** (loop: `k` over rounds, `i` over tiles):
```
idx = k * SRCNUM + i

srcs[idx].src_tile  = XAie_TileLoc(i, 3)       // tiles (0,3), (1,3), (2,3)
srcs[idx].src_addr  = 0x0 + (k * 256)          // round offset in tile memory
srcs[idx].src_ch    = 0
srcs[idx].src_bd    = k                         // BD 0 for round 0, BD 1 for round 1
srcs[idx].dst_bd    = 2 + i                     // dst BDs 2, 3, 4 on shim
srcs[idx].data_bytes = 256                      // 64 words * 4 bytes
srcs[idx].src_pkt_id = 1 + i                    // pkt_id 1, 2, 3
srcs[idx].recv_phy  = ddr_base + i * 256 * 2    // per-tile DDR region
```

**BD grouping result**:
| dst_bd | Sources sharing it | Iteration |
|--------|-------------------|-----------|
| 2 | srcs[0] (tile 0, round 0), srcs[3] (tile 0, round 1) | StepSize=64 words, Wrap=2 |
| 3 | srcs[1] (tile 1, round 0), srcs[4] (tile 1, round 1) | StepSize=64 words, Wrap=2 |
| 4 | srcs[2] (tile 2, round 0), srcs[5] (tile 2, round 1) | StepSize=64 words, Wrap=2 |

**DDR layout** (per tile: 2 rounds * 256 bytes = 512 bytes contiguous):
```
ddr_base + 0:     tile 0, round 0 (256 bytes)
ddr_base + 256:   tile 0, round 1 (256 bytes)  <- iteration advances here
ddr_base + 512:   tile 1, round 0 (256 bytes)
ddr_base + 768:   tile 1, round 1 (256 bytes)
ddr_base + 1024:  tile 2, round 0 (256 bytes)
ddr_base + 1280:  tile 2, round 1 (256 bytes)
```

**Test data pattern**: `(round << 28) | (src_index << 24) | word_index`

**Verification**: iterates over all rounds x sources, checking each word against the expected pattern.

### test_routing_packet2 -- Mode B with Single BD

**Configuration**: `SRCNUM2=3` tiles, one destination BD (`dst_bd=2`) on shim.

```
iter_step_size = TEST_DATA_SIZE = 64 words (= 256 bytes)
```

All sources share `ooo_bd_id = dst_bd = 2`. The single shim BD iterates 3 times (Wrap=3), advancing the write address by 64 words each time.

**DDR layout** (contiguous, 3 * 256 bytes):
```
ddr_phy2 + 0:    source 0 (256 bytes)
ddr_phy2 + 256:  source 1 (256 bytes)
ddr_phy2 + 512:  source 2 (256 bytes)
```

**Test data pattern**: `(src_index << 28) | word_index`

Optional 3D multi-dim dims are defined but used with `dst_num_dims=0` (linear mode).

## 5. Routing Requirements

OOO DMA dispatch requires that **packet headers are preserved** all the way to the shim S2MM DMA engine. The S2MM OOO engine reads the OOO BD ID from the packet header to dispatch BDs.

### DONOT_DROP_HEADER

At every packet-switched master port along the output gather path, the header policy must be `XAIE_SS_PKT_DONOT_DROP_HEADER`:

```c
XAie_StrmPktSwMstrPortEnable(DevInst, tile, masterPort,
    XAIE_SS_PKT_DONOT_DROP_HEADER, arbiter, msel);
```

**If headers are dropped** (`XAIE_SS_PKT_DROP_HEADER`), OOO fails -- the S2MM channel cannot read the OOO BD ID and falls back to sequential BD processing. This causes:
- Data written to wrong DDR locations
- DMA stalls when packets arrive out of expected order

### MLIR pipeline: preserveheader

In `routinghwlower.cpp`, the `preserveheader` attribute on `ConnectStreamPktSwitchPort` ops controls the DROP/DONOT_DROP decision:

```cpp
// routinghwlower.cpp lines 299-305
bool preserveHeader = false;
if (auto phAttr = op->getAttrOfType<BoolAttr>("preserveheader"))
    preserveHeader = phAttr.getValue();
bool isLastPktHop = (...);
auto headerPolicy = (isLastPktHop && !preserveHeader)
    ? dropheader : nodropheader;
```

When OOO is enabled (default), `preserveheader=true` is set on all output gather routing ops by both:
- `routinglower.cpp` (Path A: routing -> routinghw)
- `passdmaphoptoroutinghw.cpp` (Path B: dmaphop -> routinghw)

## 6. MLIR Pipeline Integration

### dfschedule dialect attributes

**ConfigDmaBdOp** (`dfscheduleop.td:163`):
```tablegen
DefaultValuedAttr<I32Attr, "-1">:$out_of_order_bd_id
```
When `>= 0`, the `DfscheduleToApiPass` emits `XAie_DmaSetOutofOrderBdId` on the source MM2S BD. Value `-1` means "not used" (backward compatible).

**ConfigCreateIoOp** (`dfscheduleop.td:185-188`):
```tablegen
DefaultValuedAttr<BoolAttr, "false">:$enable_out_of_order
```
When `true`, the pass emits `__Runtime_dma_channel_enable_ooo` on the S2MM channel, which calls `XAie_DmaChannelEnOutofOrder` + `XAie_DmaChannelSetStartQueue`.

### BlueprintToSchedulePass (OOO path)

**Activation** (`passblueprinttoschedule.cpp:740-741`):
```cpp
bool isManyToOne = (transferType == "many_to_one");
bool useOOO = isManyToOne && !isOOODisabled();
```

**`DISABLEOOO` env var** controls fallback:
- `DISABLEOOO` unset or `false` (default): OOO path
- `DISABLEOOO=true` or `DISABLEOOO=1`: sequential 3D BD fallback

**OOO path (lines 749-868)** -- when `useOOO && numCoreTiles > 1`:

1. Compute per-tile DDR byte size and stride from `shimDimStrides` D2 dimension
2. Allocate N shim BD IDs via `resourceMgr->allocateTileBd()`
3. Create N shim BDs in reverse SSA order, each with:
   - `offset` = `tileIndex * perTileStrideFromDims` (per-tile DDR position)
   - `len` = `perTileDdrBytes` (per-tile portion)
   - `enable_packet = false` (OOO dispatch handles packet selection; PktEn=true would cause double header stripping)
   - `next_bd = self` (self-chain for BD reuse after each packet)
   - 2D addressing from D0 + D1 of shimDimStrides
   - `out_of_order_bd_id = -1` (N/A for shim S2MM BDs)
4. Core MM2S BDs get `out_of_order_bd_id = shimBdIds[tileIndex]`
5. `ConfigCreateIoOp` gets `enable_out_of_order = true`

**Non-OOO path (lines 870-895)** -- single shim BD with sequential 3D addressing.

### ScheduleCanonicalizePass

Skips merging for OOO-related BDs (`passschedulecanonicalize.cpp:80-85`):
- BDs with `enable_packet = true` (packet-enabled shim BDs)
- BDs with `out_of_order_bd_id >= 0` (core MM2S OOO BDs)

This prevents the canonicalizer from combining BDs that must remain distinct for OOO dispatch.

### DfscheduleToApiPass

Reads `out_of_order_bd_id` from `ConfigDmaBdOp` and emits it as a parameter to the runtime BD configuration call (`passdfscheduletoapi.cpp:1286-1361`).

Reads `enable_out_of_order` from `ConfigCreateIoOp` and emits `__Runtime_dma_channel_enable_ooo` (`passdfscheduletoapi.cpp:1638-1656`).

## 7. Runtime API Reference

### MovedataSrcDesc struct

```c
typedef struct {
    XAie_LocType src_tile;       // source tile location
    uint32_t src_addr;           // source memory offset
    uint8_t src_ch;              // source DMA channel
    uint8_t src_bd;              // source BD ID
    uint8_t dst_bd;              // destination BD ID on the shim (OOO BD ID)
    uint32_t data_bytes;         // bytes this source sends
    uint32_t dst_len;            // dst BD length (0 = use data_bytes)
    int src_pkt_id;              // packet ID (>=0), or <0 for circuit-switched
    int dst_num_dims;            // 0 = linear, >0 = stride/wrap on dst BD
    XAie_DmaDimDesc dst_dims[4]; // stride/wrap per dimension for dst BD
    XAie_MemInst *recv_buf;      // DDR MemInst (for sync)
    u64 recv_phy;                // DDR physical address for this dst BD
} MovedataSrcDesc;
```

### API signatures

```c
// Mode A: Many BDs with BD grouping
AieRC Runtime_Movedata_ManyToOne(
    XAie_DevInst *DevInst,
    MovedataSrcDesc *srcs,   // source descriptors
    int num_srcs,            // 1..MOVEDATA_MAX_SOURCES
    XAie_LocType dst_tile,   // shim tile (row==0)
    uint8_t dst_ch           // S2MM channel
);

// Mode B: Single BD with iteration
AieRC Runtime_Movedata_ManyToOne_SingleDstBd(
    XAie_DevInst *DevInst,
    MovedataSrcDesc *srcs,
    int num_srcs,
    XAie_LocType dst_tile,
    uint8_t dst_ch,
    uint8_t dst_bd,          // single destination BD ID
    u64 dst_addr,            // DDR physical base address
    uint32_t per_src_bytes,  // bytes per transaction
    int dst_num_dims = 0,    // multi-dim dimensions (0 = linear)
    XAie_DmaDimDesc *dst_dims = nullptr,
    int iter_step_size = 0   // iteration step (words), 0 = auto
);

// Wait for all pending OOO transfers
AieRC Runtime_Movedata_WaitAll(XAie_DevInst *DevInst);
```

## 8. BD Grouping Design (Many-src-same-dst-bd)

When multiple source descriptors share the same `dst_bd`, they form a **BD group**. This enables the `SRCNUM_DUP_ROUND` pattern where the same physical tiles produce multiple rounds of data.

### How it works

1. **Grouping pass**: `Runtime_Movedata_ManyToOne` iterates through all source descriptors and groups them by `dst_bd` using a hash map
2. **Validation**: all members of a group must have matching `dst_len` and `recv_phy`
3. **Iteration setup**: when `group_count > 1`:
   ```c
   XAie_DmaSetBdIteration(&DmaInst,
       g.dst_len / 4,    // StepSize in 32-bit words
       g.count,           // Wrap = number of sources sharing this BD
       0);                // CurrentDim = 0
   ```
4. **Effect**: each time the BD is triggered by an OOO packet, the write address advances by `dst_len` bytes, placing each round's data contiguously

### Example

With `SRCNUM=3, SRCNUM_DUP_ROUND=2`:
- Sources 0,3 share `dst_bd=2` -> iteration Wrap=2, StepSize=64 words
- Sources 1,4 share `dst_bd=3` -> iteration Wrap=2, StepSize=64 words
- Sources 2,5 share `dst_bd=4` -> iteration Wrap=2, StepSize=64 words

## 9. Constraints and HW Limits

| Parameter | Limit | Notes |
|-----------|-------|-------|
| Max pending OOO transfers | 16 | `MOVEDATA_MAX_PENDING` in `aie_runtime_common.h` |
| Max sources per ManyToOne | 16 | `MOVEDATA_MAX_SOURCES` in `aie_runtime_common.h` |
| BD iteration wrap | HW dependent | Shim tile iteration dimension |
| BD iteration step size | HW dependent | Shim tile limit (in words) |
| S2MM OOO | Shim tiles only | Core/Mem tiles do not support OOO channel mode |
| Packet headers | Must be preserved | `XAIE_SS_PKT_DONOT_DROP_HEADER` required at all master ports |
| Source MM2S BDs | Must have packet | `XAie_DmaSetPkt` required for OOO BD ID delivery |
| Destination S2MM BDs | No packet enable | `enable_packet=false` -- OOO dispatch handles selection |

## 10. Data Flow Diagram

```
                   Packet-Switched Network
                   (DONOT_DROP_HEADER)
  Core Tiles                                         Shim Tile
  +-----------+                                    +-----------------+
  | Tile(0,3) |     pkt_id=1, ooo_bd_id=2         |                 |
  | MM2S BD 0 |--+                            +--->| S2MM BD 2       |---> DDR[tile0]
  +-----------+  |                            |    |   (recv_phy[0]) |
                 |   +--------+  +--------+   |    |                 |
  +-----------+  +-->| PKT SW |->| PKT SW |---+    |                 |
  | Tile(1,3) |  +-->| merge  |  | merge  |---+--->| S2MM BD 3       |---> DDR[tile1]
  | MM2S BD 0 |--+   +--------+  +--------+   |   |   (recv_phy[1]) |
  +-----------+  |     pkt_id=2, ooo_bd_id=3   |   |                 |
                 |                             |   |                 |
  +-----------+  |     pkt_id=3, ooo_bd_id=4   |   |                 |
  | Tile(2,3) |--+                             +--->| S2MM BD 4       |---> DDR[tile2]
  | MM2S BD 0 |                                    |   (recv_phy[2]) |
  +-----------+                                    |                 |
                                                   | S2MM Channel:   |
                                                   |  OOO=enabled    |
                                                   |  repeat=N       |
                                                   +-----------------+
                                                          |
                                                          v
                                                   DDR (NoC/GMIO)
```

**Mode A** (shown above): N source BDs -> N destination BDs, each at distinct DDR offsets.

**Mode B** (single BD variant):
```
  Core Tiles                                       Shim Tile
  +-----------+                                  +-----------------+
  | Tile(0,3) |  ooo_bd_id=2                     |                 |
  | MM2S BD 0 |---+                         +--->| S2MM BD 2       |
  +-----------+   |                         |    |  iter_step=64w  |
  | Tile(1,3) |   +-- PKT SW merge --------+    |  wrap=3         |
  | MM2S BD 0 |---+  (DONOT_DROP_HEADER)         |  addr advances  |
  +-----------+   |                              |  per transaction |
  | Tile(2,3) |---+                              +-----------------+
  | MM2S BD 0 |   ooo_bd_id=2 (all same)               |
  +-----------+                                         v
                                                  DDR[0]: tile 0
                                                  DDR[256]: tile 1
                                                  DDR[512]: tile 2
```

## Source Files

| File | Role |
|------|------|
| `example/debug/aieml_debug.cc` | HW test: `test_routing_packet` (Mode A), `test_routing_packet2` (Mode B) |
| `example/debug/routing4x4.cc` | 4x4 packet-switched routing with `DONOT_DROP_HEADER` |
| `src/mlir/runtime/aie_runtime_common.h` | `MovedataSrcDesc`, API declarations |
| `src/mlir/runtime/aie_runtime_common.c` | `Runtime_Movedata_ManyToOne`, `_SingleDstBd`, `_WaitAll` |
| `src/mlir/mlirfront/tilinglinalg/dataflowmap/dfschedule/td/dfscheduleop.td` | `out_of_order_bd_id`, `enable_out_of_order` attrs |
| `src/mlir/mlirfront/tilinglinalg/pass/passblueprinttoschedule/passblueprinttoschedule.cpp` | OOO path (lines 749-904) |
| `src/mlir/mlirfront/tilinglinalg/pass/passdfscheduletoapi/passdfscheduletoapi.cpp` | EmitC codegen for OOO APIs |
| `src/mlir/mlirfront/tilinglinalg/pass/passschedulecanonicalize/passschedulecanonicalize.cpp` | Skip-merge for OOO BDs |
| `src/mlir/mlirfront/tilinglinalg/pass/routinghwlower.cpp` | `preserveheader` -> `DONOT_DROP_HEADER` |
| `src/mlir/mlirfront/tilinglinalg/pass/routinglower.cpp` | `isOOODisabled()`, preserve headers for output flows |
| `src/mlir/mlirfront/tilinglinalg/pass/passdmaphoptoroutinghw/passdmaphoptoroutinghw.cpp` | `isOOODisabled()`, `preserveheader` on output gather |
