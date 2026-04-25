# TilingLinalg Architecture Document

> Design document: How a single-kernel matmul gets offloaded to a 4x4 AIE tile array, end-to-end.
>
> **Example code:** `example/tileprogram/ccode/simplematmul.cc` — a complete CUDA-style C++ source that defines the kernel, host main(), and verification in a single file. The tilinglinalg compiler takes this as input and produces the three generated outputs below.

---

## 1. Overview: From C++ Matmul to 16-Tile Hardware Execution

The tilinglinalg pipeline takes a CUDA-style C++ source file (e.g., `example/tileprogram/ccode/simplematmul.cc`) that describes a 16×16 i8 GEMM operation (`C = A × B^T`) on a 4×4 AIE tile mesh, and produces three C++ source files:

- **`host.cc`** — DDR buffer allocation, DMA BD configuration, kernel loading, and I/O orchestration
- **`kernel.cc`** — Per-tile wrapper (window acquire/release protocol)
- **`routing.cc`** — Stream switch configuration for tile-to-tile and shim-to-tile data paths

**Key files:**
- Example input: `example/tileprogram/ccode/simplematmul.cc`
- Pipeline entry: `pass/unitest/test.cpp` → `routingtodfschedule()` (line 1024)
- Pipeline driver: `pass/tilinglinalg_pipeline.cpp` → `TilingLinalgPipeline::runPipeline()` (line 194)

---

## 2. Matmul Tiling: Single Kernel → 4×4 Mesh

### 2.1 Input Configuration

The user writes a CUDA-style C++ program (`simplematmul.cc`) that defines the mesh, matrices, and kernel launch:

```cpp
// simplematmul.cc — Host side
#define M 16
#define K 16
#define N 16
#define HW_ROWS 4
#define HW_COLS 4

int main() {
    aieSetDevice(0);
    aieDim mesh(HW_ROWS, HW_COLS);

    int8_t *A = (int8_t *)malloc(M * K * sizeof(int8_t));
    int8_t *B = (int8_t *)malloc(K * N * sizeof(int8_t));
    int8_t *C = (int8_t *)malloc(M * N * sizeof(int8_t));

    // Initialize A, B ...

    matmul<<<mesh>>>(A, B, C);   // CUDA-style kernel launch on AIE mesh
    aieDeviceSynchronize();

    // Verify output ...
    free(A); free(B); free(C);
}
```

The pipeline extracts tensor parameters from the kernel signature and mesh dimensions from the `<<<mesh>>>` launch:

```cpp
// Equivalent to what the compiler builds internally (test.cpp:1029-1033):
std::vector<TensorParam> tensors = {
    {{16, 16}, 8, true},   // A: 16×16 i8, input
    {{16, 16}, 8, true},   // B: 16×16 i8, input
    {{16, 16}, 8, false},  // C: 16×16 i8, output
};
module = TilingLinalgPipeline::buildRoutingIR(ctx, 4, 4, tensors);
```

### 2.2 SplitModel: How Tensors Map to Mesh Axes

The data distribution is expressed through kernel parameter annotations in `simplematmul.cc`:

```cpp
// simplematmul.cc:82-84 — annotations encode the SplitModel
__global__ void matmul(
    aie::row_broadcast_in<input_window_int8 *> window_in_0,   // A: split on rows, broadcast to cols
    aie::col_broadcast_in<input_window_int8 *> window_in_1,   // B: split on cols, broadcast to rows
    aie::row_major_out<output_window_int8 *> window_out_0);   // C: gathered row-major
```

The compiler maps these annotations to the internal `SplitModel::gemm()` factory (`tilinglinalg_pipeline.h:33`):

```
SplitModel::gemm() = {
    A: {splitDim=0, hwAxisOwner="row", replicateOn="col"}   ← row_broadcast_in
    B: {splitDim=0, hwAxisOwner="col", replicateOn="row"}   ← col_broadcast_in
    C: {splitDim=0, hwAxisOwner="row", replicateOn="col"}   ← row_major_out
}
```

This means:
- **Matrix A** — Split along rows (dim 0) across the 4 mesh rows. Each row-strip is **broadcast** to all 4 columns. Each tile gets a 4×16 strip of A.
- **Matrix B** — Split along rows (dim 0) across the 4 mesh columns. Each col-strip is **broadcast** to all 4 rows. Each tile gets a 4×16 strip of B (transposed view).
- **Matrix C** — Split along rows across mesh rows. Each tile **gathers** its 4×4 output block. All 16 tiles collectively produce the full 16×16 output.

### 2.3 Routing IR Construction

`buildRoutingIR()` (`tilinglinalg_pipeline.cpp:129`) creates the initial MLIR module:

```
routing.createhwmesh(4, 4)           → define 4×4 mesh
bufferization.to_tensor(memref_arg)  → convert DDR pointer to tensor
routing.createscheduletensor(tensor)  → register tensor for scheduling
```

Then `createroutingfuncBySplitModel()` (`routingmanager.cpp:666`) generates:
1. **Group tensors by axis** — A and C go to the "row" group, B goes to the "col" group
2. **For each axis group**, create an `scf.execute_region`:
   - `routing.partitionmesh(mesh, splitnum, axis)` — divide mesh along axis
   - `routing.partitiontensor(tensor, splitnum, ...)` — divide tensor
   - `scf.for` loop iterating over axis splits:
     - `routing.extract_data(partitioned_tensor, idx)` — get per-split slice
     - `routing.extract_tiles(partitioned_mesh, idx)` — get tile group
     - Input: `routing.createhwiowithtarget(tiles, "input", "mem2")` + `routing.movedatabyio(...)`
     - Output: `routing.routinggatherout(tiles, slice)` + `routing.createhwiowithtarget(tiles, "output", "mem2")` + `routing.movedatabyio(...)`

### 2.4 Concrete Data Partitioning (16×16 i8, 4×4 mesh)

Derived from `simplematmul.cc` defines:

```cpp
#define TILE_ROWS (M / HW_ROWS)          // 16/4 = 4: output rows per tile
#define TILE_COLS (N / HW_COLS)          // 16/4 = 4: output cols per tile
#define ROWS_PER_ROUND (TILE_ROWS / 2)  // 2: A/B rows per DMA input round (ping or pong)
#define BUF_SZ_OUT (ROWS_PER_ROUND * TILE_COLS) // 2*4 = 8: output bytes per DMA round
```

```
Matrix A (16×16, 256 bytes):
  Row 0 tiles: A[0:3, :] = 4×16 = 64 bytes → broadcast to columns 0-3
  Row 1 tiles: A[4:7, :] = 4×16 = 64 bytes → broadcast to columns 0-3
  Row 2 tiles: A[8:11,:] = 4×16 = 64 bytes → broadcast to columns 0-3
  Row 3 tiles: A[12:15,:] = 4×16 = 64 bytes → broadcast to columns 0-3

  Per-tile DMA: 2 rounds of 32 bytes each (ROWS_PER_ROUND × K_DIM = 2×16)
    Ping: A[0:1, 0:15]  →  Pong: A[2:3, 0:15]

Matrix B (16×16, 256 bytes):
  Col 0 tiles: B[0:3, :] = 4×16 = 64 bytes → broadcast to rows 0-3
  Col 1 tiles: B[4:7, :] = 4×16 = 64 bytes → broadcast to rows 0-3
  Col 2 tiles: B[8:11,:] = 4×16 = 64 bytes → broadcast to rows 0-3
  Col 3 tiles: B[12:15,:] = 4×16 = 64 bytes → broadcast to rows 0-3

  Per-tile DMA: 2 rounds of 32 bytes each (same as A)

Matrix C (16×16, 256 bytes):
  Tile(r,c) computes C[4r:4r+3, 4c:4c+3] = 4×4 = 16 bytes
  Per-tile DMA output: 2 rounds of BUF_SZ_OUT=8 bytes each
    Round 0: rows 0-1 (all 4 cols) = 8 bytes
    Round 1: rows 2-3 (all 4 cols) = 8 bytes
  Each row of 4 tiles gathers its 4×16 = 64 byte row-strip
```

---

## 3. Pipeline Architecture: Two Branches from One IR

### 3.1 Shared Stages (Routing → dfscheblueprint)

All paths start with four shared lowering passes:

```
     ┌─────────────────────────────────────────────────────────────────┐
     │                    SHARED PATH (1 module)                       │
     │                                                                 │
     │  1. RoutingUnrollingLowerPass                                   │
     │     routing.partitionmesh + scf.for → concrete per-tile ops     │
     │                                                                 │
     │  2. RoutingToDmapPass(rtopology)                                │
     │     routing dialect → dmap dialect (logical dataflow)           │
     │     creates dmap.port, dmap.stream, dmap.push/pull ops          │
     │                                                                 │
     │  3. DmapToDmaphopPass(rtopology)                                │
     │     dmap → dmaphop (physical tile-to-tile hops)                 │
     │     allocates packet IDs for per-tile data routing              │
     │                                                                 │
     │  4. DmaphopTodfscheblueprintPass                                │
     │     dmaphop → dfscheblueprint (schedule blueprints)             │
     │     creates TransferManifest + FlowConfig ops                   │
     │     computes shim_dim_strides/wraps for multi-dim DMA           │
     │                                                                 │
     └─────────────────┬────────────────────────┬──────────────────────┘
                       │                        │
              module.clone()             module.clone()
              (rename @main→@routing)    (keep @main)
                       │                        │
                       ▼                        ▼
              ┌────────────────┐     ┌──────────────────────┐
              │  ROUTING PATH  │     │  HOST + KERNEL PATH  │
              │  → routing.cc  │     │  → host.cc+kernel.cc │
              └────────────────┘     └──────────────────────┘
```

**Critical detail:** The module is cloned at the dmaphop stage (line 218 in `tilinglinalg_pipeline.cpp`) *before* `DmaphopTodfscheblueprintPass`. This ensures packet IDs allocated by `DmapToDmaphopPass` are shared between both branches — routing.cc and host.cc use identical packet IDs.

### 3.2 Routing Path (→ routing.cc)

The cloned module goes through routing-specific passes:

```
DmaphopToRoutinghwPass(rtopology)   → routinghw: physical tiles, stream switch ports
RoutingHWVerifyPass                 → validate port/connection consistency
RoutingHWLowerPass(rtopology)       → lower to emitc: XAie stream switch API calls
RoutingDeadArgPass                  → remove unused function arguments
RoutingConstantFoldPass             → fold constants
CanonicalizerPass                   → standard MLIR cleanup
    ↓
translateToCpp → routing.cc
```

**Output:** `routing.cc` contains `void routing()` that calls:
- `XAie_StrmConnCctEnable(dev, tile, SLAVE_port, MASTER_port)` — circuit-switched connections
- `XAie_StrmPktSwMstrPortEnable(dev, tile, ...)` — packet-switched master ports
- `XAie_StrmPktSwSlavePortEnable(dev, tile, ...)` — packet-switched slave ports
- `XAie_StrmPktSwSlaveSlotEnable(dev, tile, ..., pkt_id, mask)` — packet ID filtering

### 3.3 Host Path (→ host.cc)

```
BlueprintToSchedulePass(0.5)    → dfschedule: DMA BDs, locks, kernel config, IO handles
ScheduleCanonicalizePass        → canonicalize into host_canonicalized() function
DfscheduleToApiPass(debug=true) → emitc: __Runtime_* API calls
CanonicalizerPass               → standard cleanup
RoutingConstantFoldPass         → fold constants
    ↓
translateToCpp → host.cc
```

### 3.4 Kernel Path (→ kernel.cc)

```
BlueprintToScheduleKernelPass(0.5) → kernel-side schedule: window declarations
DfscheduleToKernelApiPass          → emitc: kernel wrapper with acquire/release
    ↓
translateToCpp → kernel.cc
```

---

## 4. DMA Channel and Port Handling

### 4.1 DMA Channels

Each AIE tile has DMA channels in two directions:
- **S2MM** (Stream-to-Memory): receives data from the stream network into local memory
- **MM2S** (Memory-to-Stream): sends data from local memory to the stream network

Channel allocation happens in `BlueprintToSchedulePass` (`passblueprinttoschedule.cpp:750-755`):

```cpp
auto coreDmaChannels = coreDmaAttr.getChannels();
int64_t coreChannel = coreDmaChannels.empty() ? 0 : coreDmaChannels[0];
auto coreDmaDir = coreDmaAttr.getDirection();
// direction: MM2S for outputs, S2MM for inputs
```

For the GEMM example:
- **Input flows (A, B):** S2MM channel on core tiles — data streams in from shim
- **Output flow (C):** MM2S channel on core tiles — data streams out to shim

### 4.2 Stream Switch Ports

Stream switch configuration is handled by the routing path. The `RoutingTopology` class (`routingimplement/routing/routingtopology.h`) models Gen2 AIE tile connectivity.

**Port types per tile:**
- **Core tiles:** NORTH, SOUTH, EAST, WEST ports + DMA ports
- **Shim tiles:** NORTH port (to array) + DMA ports (to DDR via NoC)
- **Mem tiles:** NORTH, SOUTH ports + DMA ports

Port allocation is tracked by `ResourceManager` (`routingimplement/hw/ResourceManager.cpp`):

```cpp
// RoutingTile tracks port banks per direction
struct PortBank {
    std::vector<PortSlot> master;  // outgoing ports
    std::vector<PortSlot> slave;   // incoming ports
};
// Per-direction banks: NORTH, SOUTH, EAST, WEST, DMA
```

### 4.3 Routing Types

**Circuit-switched** (input/broadcast):
- Used for input data (A, B) — shim broadcasts to all tiles in a row/column
- One-to-many: a single shim stream feeds multiple core tiles
- `XAie_StrmConnCctEnable()` at each hop tile

**Packet-switched** (output/gather):
- Used for output data (C) — each core tile sends its result with a unique packet ID
- Many-to-one: multiple core tiles merge into one shim stream
- Each core's DMA BD has `enable_packet=true` with a unique `packet_id`
- `XAie_StrmPktSwSlaveSlotEnable()` filters by packet ID at merge points

### 4.4 BFS Path Finding

`RoutingPath` (`routingimplement/routing/routingpath.cpp`) uses BFS to find paths between tiles:

```cpp
// Priority: Memory tiles > SHIM tiles > Core tiles
// Obstacle avoidance via wall_ grid
// Tree-based routing: subsequent paths reuse existing tree segments

const std::array<Point,4> kDirs{{ {-1,0},{1,0},{0,-1},{0,1} }};  // up,down,left,right
```

The BFS explores neighbors in priority order, preferring vertical movement (NORTH/SOUTH) for paths between shim and core tiles.

---

## 5. Lock Synchronization

### 5.1 Lock Allocation

Locks coordinate DMA and kernel execution on each core tile. The lock allocation scheme is defined in `BlueprintToSchedulePass` (`passblueprinttoschedule.cpp:852-868`):

```
Input 0 (e.g., A): acquireLockId=0, releaseLockId=1
Input 1 (e.g., B): acquireLockId=2, releaseLockId=3
Output 0 (e.g., C): acquireLockId=4, releaseLockId=5
```

The kernel adds a `LOCK_BASE=48` offset internally, so actual hardware lock IDs are 48, 49, 50, etc.

### 5.2 Ping-Pong Buffering Protocol

Each flow uses two DMA Buffer Descriptors (ping/pong) chained in a loop:

```
                    ┌──────────────────┐
                    │                  │
         ┌─────────▼──────────┐      │
         │  Ping BD (bd_id=0) │      │
         │  next_bd → pong    │──────┘
         │  acquire lock A    │     ┌──┐
         │  release lock B    │     │  │
         └─────────┬──────────┘     │  │
                   │                │  │
         ┌─────────▼──────────┐     │  │
         │  Pong BD (bd_id=1) │     │  │
         │  next_bd → ping    │─────┘  │
         │  acquire lock A    │        │
         │  release lock B    │────────┘
         └────────────────────┘
```

For **input (S2MM):**
- DMA acquires `acquireLockId` (value -1, meaning "buffer free")
- DMA releases `releaseLockId` (value +1, meaning "data ready")
- Kernel acquires `releaseLockId` to read, releases `acquireLockId` to free

For **output (MM2S):**
- Locks are **swapped** in BD config (`passblueprinttoschedule.cpp:1033-1035`):
  ```cpp
  bool isOutputFlow = (coreDmaDir == dfscheblueprint::bp_direction::MM2S);
  int bdAcquireLockId = isOutputFlow ? releaseLockId : acquireLockId;
  int bdReleaseLockId = isOutputFlow ? acquireLockId : releaseLockId;
  ```
- DMA acquires `releaseLockId` (kernel produced data), releases `acquireLockId` (buffer free)

### 5.3 Buffer Ratio and Iterations

The `bufferRatio` parameter (default 0.5) controls how much data each ping/pong buffer holds:

```
perCoreElements = total elements per core tile
pingPongBufferSize = perCoreElements * 0.5  // half the data per buffer
numIterations = ceil(perCoreElements / pingPongBufferSize)  // = 2 for 0.5
```

This creates a double-buffered pipeline: while the kernel processes data in one buffer, DMA fills/drains the other.

---

## 6. Runtime Architecture (aie_runtime.c)

### 6.1 Runtime Function Hierarchy

```
__Runtime_auto_init()        [constructor — runs before main()]
    ├── __Runtime_platform_init()    — disable caches
    ├── __Runtime_device_init()      — XAie_CfgInitialize + partition
    └── __Runtime_routing_init()     — XAie_InitRoutingHandler + routing()

host_canonicalized(void* A, void* B, void* C)  [generated by pipeline]
    ├── __Runtime_malloc/memcpy      — allocate DDR buffers, copy input data
    ├── __Runtime_dma_bd_config()    — configure shim DMA BDs (simple)
    ├── __Runtime_dma_bd_config_multidim() — configure shim multi-dim BDs
    ├── __Runtime_load_kernel_group_16t()  — load kernel ELF into all 16 tiles
    ├── __Runtime_startio()          — enqueue BDs to DMA channels
    ├── __Runtime_launch_kernel_group()   — enable all 16 cores
    ├── __Runtime_wait_event()       — poll XAie_CoreWaitForDone per tile
    ├── __Runtime_wait_io()          — poll XAie_DmaGetPendingBdCount
    └── __Runtime_free()             — dump debug data + free DDR buffers

__Runtime_auto_teardown()    [destructor — runs after main()]
    └── __Runtime_device_teardown()  — XAie_PartitionTeardown
```

### 6.2 Key Runtime Functions

| Function | Purpose | XAie API Called |
|----------|---------|-----------------|
| `__Runtime_device_init` | Initialize device, backend, NPI, partition | `XAie_CfgInitialize`, `XAie_PartitionInitialize` |
| `__Runtime_routing_init` | Initialize routing handler, call `routing()` | `XAie_InitRoutingHandler` |
| `__Runtime_dma_bd_config` | Configure a single DMA Buffer Descriptor | `XAie_DmaSetAddrLen`, `XAie_DmaSetLock`, `XAie_DmaSetNextBd`, `XAie_DmaSetPkt`, `XAie_DmaWriteBd` |
| `__Runtime_dma_bd_config_multidim` | Configure BD with multi-dim stride/wrap | `XAie_DmaSetMultiDimAddr` (strides ÷4 for word units) |
| `__Runtime_dma_createio` | Create IO channel struct (tile, channel, direction) | — (struct creation only) |
| `__Runtime_startio` | Enqueue BD to DMA channel start queue | `XAie_DmaChannelSetStartQueue` |
| `__Runtime_load_kernel_group_16t` | Load kernel ELF into 16 core tiles | `XAie_CoreReset`, `XAie_CoreUnreset`, `XAie_LoadElfMem` |
| `__Runtime_launch_kernel_group` | Enable all cores (transaction-batched) | `XAie_CoreEnable` via `XAie_StartTransaction` |
| `__Runtime_wait_event` | Poll until all cores done | `XAie_CoreWaitForDone` |
| `__Runtime_wait_io` | Poll until DMA channel idle | `XAie_DmaGetPendingBdCount` |
| `__Runtime_read_kernel_log` | Read kernel log from core data memory | `XAie_DataMemBlockRead` at offset 0xF800 |

### 6.3 DMA Multi-Dimensional Addressing

#### The Problem: Tile-Sequential → Row-Major Transpose

Each tile outputs its 4×4 sub-block in **sequential row-major order** (from `simplematmul.cc` step 6-7):

```
tile(0,3) outputs: [a,b,c,d, e,f,g,h, 1,2,3,4, 5,6,7,8]
                    ─row 0── ─row 1── ─row 2── ─row 3──

tile(1,3) outputs: [A,B,C,D, E,F,G,H, H,L,K,J, L,M,N,O]
                    ─row 0── ─row 1── ─row 2── ─row 3──
```

But in the full C[16×16] matrix, these tiles are at **adjacent column positions** in the same row-group. The DDR layout must be **row-major across all tiles**:

```
DDR row 0: [... a,b,c,d, A,B,C,D]     ← tile0 row0 + tile1 row0
DDR row 1: [... e,f,g,h, E,F,G,H]     ← tile0 row1 + tile1 row1
DDR row 2: [... 1,2,3,4, H,L,K,J]     ← tile0 row2 + tile1 row2
DDR row 3: [... 5,6,7,8, L,M,N,O]     ← tile0 row3 + tile1 row3
```

The shim DMA receives tile outputs **sequentially** (all 16 bytes of tile0, then all 16 bytes of tile1, etc.) but must **scatter-write** them to the correct DDR offsets so that rows from different tiles interleave properly. This is a transpose from tile-major order to row-major order.

#### 3D Stride/Wrap Configuration

The shim DMA uses 3 dimensions to perform this scatter-write:

```
Strides (in bytes):     [4, 16, 4]
Wraps (iteration count): [1, 4, 4]

D0 (innermost): stride=4, wrap=1  → transfer TILE_COLS=4 bytes (one tile-row)
D1 (middle):    stride=16, wrap=4 → step by N=16 bytes (full C row width), 4 tile-rows
D2 (outermost): stride=4, wrap=4  → step by TILE_COLS=4 bytes, 4 tile-columns
```

Iteration order is D0 (innermost) → D1 → D2 (outermost). D1 cycles through the 4 rows before D2 advances to the next tile-column position.

#### Concrete Address Computation

For each 4-byte chunk received, the DDR write offset is:

```
addr = base + d1 × 16 + d2 × 4     (d0 is always 0 since wrap=1)
```

Full iteration table for one row-group (64 bytes = 4 tiles × 16 bytes):

```
Stream     Tile data        d2  d1  DDR offset   DDR position
─────────────────────────────────────────────────────────────
bytes 0-3   tile col0 row0   0   0   0            C[r+0, 0:3]
bytes 4-7   tile col0 row1   0   1   16           C[r+1, 0:3]
bytes 8-11  tile col0 row2   0   2   32           C[r+2, 0:3]
bytes 12-15 tile col0 row3   0   3   48           C[r+3, 0:3]
bytes 16-19 tile col1 row0   1   0   4            C[r+0, 4:7]
bytes 20-23 tile col1 row1   1   1   20           C[r+1, 4:7]
bytes 24-27 tile col1 row2   1   2   36           C[r+2, 4:7]
bytes 28-31 tile col1 row3   1   3   52           C[r+3, 4:7]
bytes 32-35 tile col2 row0   2   0   8            C[r+0, 8:11]
bytes 36-39 tile col2 row1   2   1   24           C[r+1, 8:11]
bytes 40-43 tile col2 row2   2   2   40           C[r+2, 8:11]
bytes 44-47 tile col2 row3   2   3   56           C[r+3, 8:11]
bytes 48-51 tile col3 row0   3   0   12           C[r+0, 12:15]
bytes 52-55 tile col3 row1   3   1   28           C[r+1, 12:15]
bytes 56-59 tile col3 row2   3   2   44           C[r+2, 12:15]
bytes 60-63 tile col3 row3   3   3   60           C[r+3, 12:15]
```

#### Result: DDR Layout After Scatter-Write

Reading DDR sequentially, the 64 bytes form a proper 4×16 row-major strip:

```
Offset 0-15  (row 0): [tile0_r0][tile1_r0][tile2_r0][tile3_r0]
Offset 16-31 (row 1): [tile0_r1][tile1_r1][tile2_r1][tile3_r1]
Offset 32-47 (row 2): [tile0_r2][tile1_r2][tile2_r2][tile3_r2]
Offset 48-63 (row 3): [tile0_r3][tile1_r3][tile2_r3][tile3_r3]
```

Using the earlier concrete example (tile col2 = tile(0,3), tile col3 = tile(1,3)):

```
Input stream:  [..., a,b,c,d, e,f,g,h, 1,2,3,4, 5,6,7,8, A,B,C,D, E,F,G,H, H,L,K,J, L,M,N,O]
                     ──────── tile(0,3) ────────  ──────── tile(1,3) ────────

DDR output:    [..., a,b,c,d, A,B,C,D]   ← row 0: 4 bytes from each tile at same row
               [..., e,f,g,h, E,F,G,H]   ← row 1
               [..., 1,2,3,4, H,L,K,J]   ← row 2
               [..., 5,6,7,8, L,M,N,O]   ← row 3
```

#### Why This Is a Transpose

Conceptually, the data arrives in **tile-major** order (all rows of tile0, then all rows of tile1, ...):

```
Tile-major (input):          Row-major (DDR output):

tile0: [r0 r1 r2 r3]        row0: [t0_r0  t1_r0  t2_r0  t3_r0]
tile1: [r0 r1 r2 r3]   →    row1: [t0_r1  t1_r1  t2_r1  t3_r1]
tile2: [r0 r1 r2 r3]        row2: [t0_r2  t1_r2  t2_r2  t3_r2]
tile3: [r0 r1 r2 r3]        row3: [t0_r3  t1_r3  t2_r3  t3_r3]
```

This is equivalent to viewing the input as a 4×4 matrix of 4-byte blocks (tile × row) and transposing it to (row × tile). The D1 stride (N=16) spaces rows apart while D2 stride (TILE_COLS=4) positions tiles within each row.

#### Stride Encoding for Hardware

The runtime divides strides by 4 before passing to XAie because the DMA hardware operates in 32-bit word granularity:

```cpp
// aie_runtime.c — __Runtime_dma_bd_config_multidim()
// Hardware strides are in 32-bit words, not bytes
XAie_DmaTensorDim dims[3] = {
    {.StepSize = strides[0] / 4, .Wrap = wraps[0]},   // {1, 1}
    {.StepSize = strides[1] / 4, .Wrap = wraps[1]},   // {4, 4}
    {.StepSize = strides[2] / 4, .Wrap = wraps[2]},   // {1, 4}
};
```

---

## 7. Logging and Debug Mechanisms

### 7.1 Debug Levels (`g_runtime_debug_level`)

The global `g_runtime_debug_level` (weak symbol, default 0) controls runtime verbosity:

| Level | Behavior |
|-------|----------|
| 0 | Basic printf at each runtime API call (always on) |
| 1 | BD tracking: records all BD configs, dumps table at `__Runtime_free()`. Includes shim buffer contents (int8 dump). DMA wait_io logs. |
| 2 | Level 1 + core tile DMA write pattern + readback verification. Writes `col*100 + row*10 + bd_id` pattern into BD regions for debugging. |

Override via: `#pragma aie_debug_level N` in user source, or `int g_runtime_debug_level = N;` in generated host.cc.

### 7.2 BD Tracking System

```c
typedef struct {
    uint8_t col, row, bd_id, tile_type;
    void *buffer;       // DDR pointer (shim only)
    uint64_t dma_addr;  // physical address
    int32_t len, packet_id;
    int8_t direction, channel_id, next_bd;
} BdTrackEntry;

static BdTrackEntry g_bd_track[BD_TRACK_MAX];  // max 64 entries
```

Every `__Runtime_dma_bd_config*` call records an entry. Direction and channel are updated when `__Runtime_startio` is called. The full table is printed at `__Runtime_free()` when debug level >= 1.

### 7.3 Kernel Logging (`klog`)

Core tiles write log entries to a reserved 2KB region at data memory offset `0xF800`:

```
slot[0] = write_index (number of int32s written)
slot[1,2] = [tag_packed, value]    // first entry
slot[3,4] = [tag_packed, value]    // second entry
...
```

Tags are 4-char ASCII strings packed big-endian into int32 (e.g., "CENk", "IN0 ", "CLOP", "CEXT").

`__Runtime_read_kernel_log()` reads and decodes these after `__Runtime_wait_event()`.

### 7.4 IR Dump Files

Each pass dumps its output MLIR to numbered files:

```
ir/dfschedule/
  0_initial.mlir
  1_RoutingUnrollingLowerPass.mlir
  2_RoutingToDmapPass.mlir
  3_DmapToDmaphopPass.mlir
  4_DmaphopTodfscheblueprintPass.mlir
  5_BlueprintToSchedulePass.mlir
  6_ScheduleCanonicalizePass.mlir
  7_DfscheduleToApiPass.mlir
  8_CanonicalizerPass.mlir
  9_RoutingConstantFoldPass.mlir

ir/simplerouting/
  0_initial.mlir
  1_DmaphopToRoutinghwPass.mlir
  2_RoutingHWVerifyPass.mlir
  3_RoutingHWLowerPass.mlir
  4_RoutingDeadArgPass.mlir
  5_RoutingConstantFoldPass.mlir
  6_CanonicalizerPass.mlir
```

### 7.5 Buffer Content Dumps

`__Runtime_free()` prints DDR buffer contents in 64-byte chunks (int8 values) for verifying output correctness. `__Runtime_memcpy()` prints first 64 bytes of copied data.

---

## 8. Generated Code Structure

### 8.1 host.cc Structure

```cpp
// Override debug level (if #pragma aie_debug_level set)
int g_runtime_debug_level = N;

// MLIR-generated function
void host_canonicalized(void* arg0, void* arg1, void* arg2) {
    // 1. Declare shim tiles
    XAie_LocType shim_tile_0 = XAie_TileLoc(col, 0);

    // 2. Allocate DDR buffers + copy input data
    void* buf = __Runtime_malloc(256);
    __Runtime_memcpy(buf, input_data, 256);

    // 3. Configure shim DMA BDs (with multi-dim for scatter/gather)
    auto bd0 = __Runtime_dma_bd_config_multidim(dev, shim, buf, bd_id, ...
        strides, wraps);

    // 4. Configure core DMA BDs (ping-pong pairs with locks)
    auto core_bd = __Runtime_dma_bd_config(dev, core_tile, buffer, bd_id, ...
        acquire_lock, release_lock);

    // 5. Create IO handles
    auto io = __Runtime_dma_createio_4(tile, bd, channel, bd_id, direction);

    // 6. Load kernel ELF into all 16 tiles
    auto kg = __Runtime_load_kernel_group_16t(tile0..tile15, 16);

    // 7. Start shim DMA
    auto evt_io = __Runtime_startio(io, bd_id);

    // 8. Start core DMA (deferred until after ELF load)
    __Runtime_startio(core_io, core_bd_id);

    // 9. Launch kernels
    auto evt = __Runtime_launch_kernel_group(kg);

    // 10. Wait for completion
    __Runtime_wait_event(evt);
    __Runtime_wait_io(evt_io);

    // 11. Read output + cleanup
    __Runtime_free(buf);
}

// User source or auto-generated main()
int main() { ... host_canonicalized(A, B, C); ... }
```

### 8.2 routing.cc Structure

```cpp
#include <xaiengine.h>
XAie_DevInst* getOrCreateDeviceInstance();

void routing() {
    XAie_DevInst* dev = getOrCreateDeviceInstance();

    // Circuit-switched connections (input broadcast)
    XAie_StrmConnCctEnable(dev, XAie_TileLoc(col, row),
        SLAVE_direction, slave_port, MASTER_direction, master_port);

    // Packet-switched connections (output gather)
    XAie_StrmPktSwMstrPortEnable(dev, tile, MASTER_dir, port, ...);
    XAie_StrmPktSwSlavePortEnable(dev, tile, SLAVE_dir, port);
    XAie_StrmPktSwSlaveSlotEnable(dev, tile, SLAVE_dir, port,
        slot, XAie_PacketInit(pkt_id, 0), mask, msel, arbiter);
}
```

### 8.3 Kernel Code (`simplematmul.cc` — kernel section)

The kernel is defined in the same source file as the host, using CUDA-style annotations. The compiler extracts it and wraps it with the DMA/lock acquire/release protocol in the generated `kernel.cc`.

```cpp
// simplematmul.cc — Kernel declaration (lines 82-208)
// Annotations: aie::row_broadcast_in = split along rows, broadcast to columns
//              aie::col_broadcast_in = split along columns, broadcast to rows
//              aie::row_major_out     = output gathered row-major
__global__ void matmul(aie::row_broadcast_in<input_window_int8 *> window_in_0,
                       aie::col_broadcast_in<input_window_int8 *> window_in_1,
                       aie::row_major_out<output_window_int8 *> window_out_0) {

    int8_t cache_A[ROWS_PER_ROUND * K_DIM];  // 2×16 = 32 bytes
    int8_t cache_B[ROWS_PER_ROUND * K_DIM];  // 2×16 = 32 bytes
    int8_t local_out[TILE_ROWS * TILE_COLS];  // 4×4 = 16 bytes

    // Step 1: Receive-only ping — acquire+cache+release inputs (no output)
    int8_t *A0 = (int8_t *)acquire_input_window(window_in_0);
    int8_t *B0 = (int8_t *)acquire_input_window(window_in_1);
    for (int i = 0; i < ROWS_PER_ROUND * K_DIM; i++) {
        cache_A[i] = A0[i];
        cache_B[i] = B0[i];
    }
    release_input_window(window_in_0);
    release_input_window(window_in_1);

    // Step 2: Compute top-left quadrant C[0:1,0:1] from cached data
    for (int i = 0; i < ROWS_PER_ROUND; i++)
        for (int j = 0; j < COLS_PER_ROUND; j++) {
            int16_t sum = 0;
            for (int k = 0; k < K_DIM; k++)
                sum += (int16_t)cache_A[i*K_DIM+k] * (int16_t)cache_B[j*K_DIM+k];
            // saturate to int8 ...
            local_out[i * TILE_COLS + j] = (int8_t)sum;
        }

    // Step 3: Receive pong — acquire A1, B1
    int8_t *A1 = (int8_t *)acquire_input_window(window_in_0);
    int8_t *B1 = (int8_t *)acquire_input_window(window_in_1);

    // Step 4: Compute remaining 3 quadrants (top-right, bottom-left, bottom-right)
    // ... (uses cached A0/B0 × new B1/A1 combinations) ...

    // Step 5: Release pong inputs
    release_input_window(window_in_0);
    release_input_window(window_in_1);

    // Step 6-7: Output 2 rounds (8 bytes each, sequential row-major)
    for (int round = 0; round < 2; round++) {
        int8_t *out = (int8_t *)acquire_output_window(window_out_0);
        for (int i = 0; i < BUF_SZ_OUT; i++)
            out[i] = local_out[round * BUF_SZ_OUT + i];
        release_output_window(window_out_0);
    }
}
```

**Receive-first ping design:** The kernel caches the first input round locally before computing, allowing overlap between DMA and compute across the quadrants. Each tile computes a 4×4 sub-block of C from its 4×16 strips of A and B.

---

## 9. Resource Management

### 9.1 CoreMemAllocator

Manages core tile data memory addresses for DMA buffers (`ResourceManager.cpp:18-40`):

```
Base: 0x40000 (after reserved region)
Layout: [buf_in_ping_0][buf_in_pong_0][buf_in_ping_1][buf_in_pong_1][buf_out_ping_0][buf_out_pong_0]...
```

All tiles share the same kernel ELF, so buffer addresses are identical across tiles. The allocator deduplicates by symbol name.

### 9.2 BD Pool

Each tile has a finite pool of Buffer Descriptors:
- Core tiles: 16 BDs
- Shim tiles: 16 BDs

`RoutingTile::allocateBd()` tracks usage per tile. BD IDs are allocated in `BlueprintToSchedulePass` via `resourceMgr->allocateTileBd(row, col, flowIndex)`.

### 9.3 BCF/PRX Generation

After buffer allocation, the pipeline generates:
- **`aieml.bcf`** — Board Configuration File: symbol addresses for the linker
- **`aieml.prx`** — Project file for xchessmk kernel compilation

---

## 10. End-to-End Execution Flow

### From `simplematmul.cc` to hardware:

```
1. Build:      cd unitest/build && cmake .. && make -j4
2. Generate:   ./test dfschedule
               → worklocal/host.cc, kernel.cc, routing.cc, matmul.cc
               → worklocal/aieml.bcf, aieml.prx
3. Compile kernel:  cd worklocal && source compile_kernel.sh
                    → build/kernel (AIE ELF)
4. Compile host:    cd worklocal && source hostcompile.sh
                    → build/host (ARM ELF, kernel embedded via ld -r -b binary)
5. Deploy:     python3 script/test/apppaltest.py build/host
               → SSH to board, xsdb load, console capture
6. Verify:     "device_teardown done" = success
               Output buffer dump shows computed C matrix values
```

The `simplematmul.cc` host verification (`verify_matmul()`) computes a CPU-side reference `C_ref = A × B^T` and compares element-by-element against the AIE output.

### Hardware execution sequence:

```
ARM host boots
  → __Runtime_auto_init() [constructor]
    → device_init: XAie_CfgInitialize
    → routing_init: routing() configures stream switches
  → main() calls host_canonicalized()
    → Allocate DDR buffers, copy A and B data
    → Configure shim BDs (multi-dim for scatter/gather)
    → Load kernel ELF into 16 core tiles
    → Configure core BDs (ping-pong with locks)
    → Start shim DMAs (push A/B data into array)
    → Start core DMAs (receive into local memory)
    → Launch all 16 kernels
    → Each kernel: receive-first ping (7 steps from simplematmul.cc):
        Step 1: Acquire ping inputs, cache A0/B0, release
        Step 2: Compute top-left quadrant
        Step 3: Acquire pong inputs A1/B1
        Step 4: Compute remaining 3 quadrants
        Step 5: Release pong inputs
        Step 6-7: Output 2 rounds of 8 bytes each
    → Wait for kernel completion + DMA idle
    → Read output C from DDR
  → __Runtime_auto_teardown() [destructor]
    → XAie_PartitionTeardown
```
