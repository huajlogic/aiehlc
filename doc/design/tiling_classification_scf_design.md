# Tiling Classification & Host-Side SCF Loop Design

## 1. Problem Statement

### Current State

When `tile_m < tileRows` (i.e., the user-specified sub-tile height is smaller than the per-tile partition height), the current implementation handles the M-round iteration **inside the kernel**. The kernel pass (`BlueprintToScheduleKernelPass`) multiplies `numRounds` by `mRounds` so that the kernel's ping-pong window covers all M sub-tile iterations:

```
// passblueprinttoschedulekernel.cpp:887-900
if (tileM > 0 && tileM < tileRows) {
    int64_t mRounds = tileRows / tileM;
    paramInfo.numRounds *= mRounds;  // output: numRounds * mRounds
}
```

The host fires DMA once with `repeat = mRounds` (for shim input sender) and `repeat = mRounds` (for core MM2S output), then calls `launch_kernel_group` once. The kernel internally loops `m_rounds` times via `aie::get_spatial_m_rounds()`.

### Limitation

This couples DMA repeat counts to the kernel's internal iteration structure:

1. **Kernel complexity** -- The kernel must manage M-round iteration, including zeroing accumulators per sub-tile, managing local buffers sized for the full tile, and coordinating window acquire/release across `mRounds * kRounds` iterations.

2. **DMA inflexibility** -- The shim DMA `repeat` count is baked into the `start_io` call. With iter_wrap-based repetition, the DMA engine replays the same BD chain. This works for uniform sub-tiles but cannot handle variable BD offsets per M-round iteration (e.g., different DDR source addresses for each sub-tile of A).

3. **No host-level visibility** -- The host has no per-sub-tile synchronization point. If one sub-tile produces incorrect results, there is no way to insert host-side checking between iterations.

### Goal

Move M/N sub-tile iteration to the host via MLIR SCF loops. The kernel becomes a single-invocation unit that processes one `(tile_m x tile_n)` output block per launch, while the host loops over sub-tiles, re-arming DMA BDs with correct offsets each iteration.

---

## 2. Tiling Classification

### Per-Dataflow Analysis

For each data port (A, B, C), compare the user-specified sub-tile dimension against the per-tile spatial partition:

| Dimension | User param | Spatial partition | Relationship |
|-----------|-----------|-------------------|-------------|
| M (rows) | `tile_m` | `tileRows = M / meshRows` | `tile_m` vs `tileRows` |
| N (cols) | `tile_n` | `tileCols = N / meshCols` | `tile_n` vs `tileCols` |

### Classification Modes

| Mode | Condition | Rounds | Action |
|------|-----------|--------|--------|
| **Match** | `tile_m == tileRows` (or `tile_m == 0`) | `mRounds = 1` | No loop needed; current single-fire behavior |
| **Multiple** | `tile_m < tileRows && tileRows % tile_m == 0` | `mRounds = tileRows / tile_m` | Generate `scf.for` loop on host |
| **Invalid** | `tile_m > tileRows` OR `tileRows % tile_m != 0` | N/A | Emit compile-time error diagnostic |

The same classification applies independently to `tile_n` vs `tileCols`, producing `nRounds`.

### Module Attributes (Available in IR)

From `ir/dfschedule/0_initial.mlir`:

```mlir
module attributes {
    routing.tile_m = 4 : i64,
    routing.tile_rows = 16 : i64,
    routing.m_rounds = 4 : i64,
    routing.effective_k = 16 : i64,
    routing.full_k = 64 : i64,
    routing.k_rounds = 4 : i64
}
```

These attributes are set by `aiehlc.cc` during `buildRoutingIR()` and are available to all passes in the pipeline.

### Classification Utility (Pseudocode)

```cpp
enum class TilingMode { Match, Multiple, Invalid };

struct TilingClassification {
    TilingMode mMode;
    int64_t mRounds;   // 1 for Match, tileRows/tileM for Multiple
    TilingMode nMode;
    int64_t nRounds;   // 1 for Match, tileCols/tileN for Multiple
};

TilingClassification classifyTiling(ModuleOp moduleOp) {
    auto tileM = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_m");
    auto tileRows = moduleOp->getAttrOfType<IntegerAttr>("routing.tile_rows");
    // ... similarly for tile_n, tile_cols

    TilingClassification result;

    int64_t m = tileM ? tileM.getInt() : 0;
    int64_t rows = tileRows ? tileRows.getInt() : 0;

    if (m == 0 || m == rows) {
        result.mMode = TilingMode::Match;
        result.mRounds = 1;
    } else if (m < rows && rows % m == 0) {
        result.mMode = TilingMode::Multiple;
        result.mRounds = rows / m;
    } else {
        result.mMode = TilingMode::Invalid;
        result.mRounds = 0;
    }
    // Same logic for N dimension...
    return result;
}
```

---

## 3. Host Schedule -- Match Mode (Current Behavior)

When `mRounds == 1` and `nRounds == 1`, the host schedule is a straight-line sequence with no loops:

```
// Host schedule (dfschedule IR, Match mode):

// 1. Configure shim DMA BDs (BD offsets, lengths, packet IDs)
config_dma_bd(shim_tile, ...)

// 2. Arm shim DMA channel
start_io(shim, repeat = kRounds)    // input: kRounds BD replays
                                     // output: repeat = 1

// 3. Load ELF onto core tiles
load_kernel_group(core_tiles, dskernel_receiver, ...)

// 4. Launch kernel execution
launch_kernel_group(kernel_group)

// 5. Arm core DMA channels (AFTER ELF load to avoid BSS race)
start_io(core_s2mm, repeat = 1)     // per core tile, input direction
start_io(core_mm2s, repeat = 1)     // per core tile, output direction

// 6. Wait for completion
wait(launch_event, shim_io_event)
```

This is the pattern currently generated by `FlowTransferOpConversion::matchAndRewrite()` in `passblueprinttoschedule.cpp:1666-1735`.

Key properties:
- `load_kernel_group` called once
- `launch_kernel_group` called once
- Kernel internally loops `m_rounds * k_rounds` times
- DMA repeat count handles all iterations via BD chain replay

---

## 4. Host Schedule -- Multiple Mode (Proposed)

When `mRounds > 1` or `nRounds > 1`, the host wraps the input DMA sequence in SCF loops. Key design decisions:

- **`load_kernel_group` and `launch_kernel_group` are both OUTSIDE the loop.** The ELF is loaded once, and the kernel is launched once. The kernel runs continuously, consuming data as the host re-arms input DMAs per sub-tile.
- **`shim_output_c` is configured OUTSIDE the loop.** The output shim DMA collects all sub-tile outputs with `repeat = mRounds * nRounds`. The output BD length covers one sub-tile (`tile_m * tile_n`), and the DMA engine replays it for each iteration.
- **Inside the loop**, only input DMAs (A, B) are re-armed with updated BD offsets, and `wait_io` synchronizes input completion before the next iteration.

```
// Host schedule (dfschedule IR, Multiple mode):

// 1. Load ELF onto core tiles -- ONCE, outside all loops
load_kernel_group(core_tiles, dskernel_receiver, ...)

// 2. Configure and arm shim output C -- ONCE, outside all loops
//    Output DMA repeats mRounds*nRounds times, collecting all sub-tiles
config_dma_bd(shim_output_c, offset = 0, len = tile_m * tile_n)
start_io(shim_output_c, repeat = mRounds * nRounds)

// 3. Arm core DMA channels -- ONCE, outside all loops
//    Core DMAs use ping-pong BD chaining and run continuously
start_io(core_s2mm_a, repeat = mRounds * nRounds * kRounds)  // per core tile
start_io(core_s2mm_b, repeat = mRounds * nRounds * kRounds)
start_io(core_mm2s_c, repeat = mRounds * nRounds)

// 4. Launch kernel -- ONCE, outside all loops
//    Kernel runs continuously, processing sub-tiles as data arrives
launch_kernel_group(kernel_group)

// 5. M sub-tile loop
scf.for %mr = 0 to mRounds step 1 {
    // This iteration processes rows [mr*tile_m .. (mr+1)*tile_m)

    // 6. N sub-tile loop (if nRounds > 1)
    scf.for %nr = 0 to nRounds step 1 {
        // This iteration processes cols [nr*tile_n .. (nr+1)*tile_n)

        // 7. Re-configure shim input DMA BDs with sub-tile offsets
        //    Input A: DDR offset = mr * tile_m * K (row-major)
        //    Input B: DDR offset = nr * tile_n * K (row-major, B^T layout)
        config_dma_bd(shim_input_a, offset = f(%mr, tile_m, K), len = tile_m * effectiveK)
        config_dma_bd(shim_input_b, offset = f(%nr, tile_n, K), len = tile_n * effectiveK)

        // 8. Arm shim input DMA
        start_io(shim_input_a, repeat = kRounds)   // K-accumulation rounds
        start_io(shim_input_b, repeat = kRounds)

        // 9. Wait for input A and B IO to complete before next iteration
        //    This ensures the shim input DMA has finished sending this
        //    sub-tile's data before we re-arm BDs with new offsets
        wait_io(shim_input_a_event, shim_input_b_event)
    }
}

// 10. Wait for overall completion (kernel launch + output shim)
wait(launch_event, shim_output_c_event)

// 11. Free DDR allocations
free_device_mem(...)
```

### Key Properties

| Property | Match Mode | Multiple Mode |
|----------|-----------|---------------|
| `load_kernel_group` | 1 call | 1 call (outside loops) |
| `launch_kernel_group` | 1 call | 1 call (outside loops) |
| `shim_output_c` | 1 start_io | 1 start_io, repeat = mRounds*nRounds (outside loops) |
| Kernel `m_rounds` | `tileRows / tile_m` | `mRounds * nRounds` (host feeds data, kernel consumes) |
| DMA BD offsets (input) | Fixed (computed once) | Vary per loop iteration |
| Per-iteration sync | None | `wait_io(input_a, input_b)` before next BD re-arm |
| Final sync | `wait(launch, shim_io)` | `wait(launch, shim_output_c)` after all loops |

### BD Offset Computation

For each loop iteration `(%mr, %nr)`, the shim **input** DMA BD base addresses are:

```
// Input A (broadcast per row): each core tile gets the same A sub-tile
//   DDR base for A sub-tile = A_base + mr * tile_m * K * elemBytes
//   BD length per k-round = tile_m * effectiveK * elemBytes
offset_A = mr * tile_m * K

// Input B (broadcast per col): each core tile gets the same B sub-tile
//   DDR base for B sub-tile = B_base + nr * tile_n * K * elemBytes
//   BD length per k-round = tile_n * effectiveK * elemBytes
offset_B = nr * tile_n * K
```

These offsets are computed using `arith.muli` / `arith.addi` from the SCF induction variables.

Output C shim DMA is configured once outside the loop:
```
// Output C (gather per row): BD replays mRounds*nRounds times
//   BD length = tile_m * tile_n * elemBytes (one sub-tile per replay)
//   The shim DMA iter_wrap/repeat handles address advancement automatically
//   based on the output gather pattern (LeftToRight merge order)
offset_C = 0   // configured once; DMA engine advances per repeat
```

---

## 5. Kernel-Side Changes

With host-side looping, the kernel becomes simpler:

### Current Kernel (kernel internally loops M)

```cpp
// simplematmul2.cc (current)
const int m_rounds = aie::get_spatial_m_rounds();  // = tileRows / tile_m
const int k_rounds = aie::get_k_rounds();

for (int mr = 0; mr < m_rounds; mr++) {     // M sub-tile loop IN KERNEL
    for (int kr = 0; kr < k_rounds; kr++) {  // K accumulation
        // acquire A, B windows
        // compute partial products
    }
    // output C sub-tile
}
```

Window initialization (from `passblueprinttoschedulekernel.cpp`):
```
window_in_0 (A):  bufSize = tile_m * effectiveK / vectorWidth
                   numRounds = ppDepth * kRounds * mRounds
window_in_1 (B):  bufSize = tile_n * effectiveK / vectorWidth
                   numRounds = ppDepth * kRounds * mRounds
window_out_0 (C): bufSize = tile_m * tile_n / vectorWidth
                   numRounds = ppDepth * mRounds
```

### Proposed Kernel (host controls input data, kernel runs continuously)

Since `launch_kernel_group` is called once outside the loop and the kernel runs continuously, the kernel still has an `m_rounds` loop internally. However, the key difference is that the **host SCF loop controls which data is fed** to the kernel per sub-tile iteration. The kernel simply consumes whatever the DMA delivers.

```cpp
// simplematmul2.cc (proposed, with host-side SCF)
// m_rounds = mRounds * nRounds (total sub-tile iterations fed by host)
const int m_rounds = aie::get_spatial_m_rounds();  // = mRounds * nRounds
const int k_rounds = aie::get_k_rounds();

for (int mr = 0; mr < m_rounds; mr++) {
    for (int kr = 0; kr < k_rounds; kr++) {
        // acquire A, B windows -- data arrives from host SCF loop's DMA
        // compute partial products
    }
    // output one C sub-tile
}
```

The kernel code structure is unchanged. What changes is the **host's DMA feeding pattern**: instead of a single `start_io` with `repeat = mRounds * kRounds`, the host re-arms input BDs per sub-tile with different DDR offsets.

Window initialization (unchanged from current):
```
window_in_0 (A):  bufSize = tile_m * effectiveK / vectorWidth
                   numRounds = ppDepth * kRounds * mRounds * nRounds
window_in_1 (B):  bufSize = tile_n * effectiveK / vectorWidth
                   numRounds = ppDepth * kRounds * mRounds * nRounds
window_out_0 (C): bufSize = tile_m * tile_n / vectorWidth
                   numRounds = ppDepth * mRounds * nRounds
```

### What Stays in the Kernel

- **K-accumulation loop** (`k_rounds`): The K dimension is always iterated inside the kernel because it involves accumulating partial products into local registers/accumulators. Moving K iteration to the host would require flushing partial sums to DDR between k-rounds, which defeats the purpose of local accumulation.

- **Ping-pong window protocol**: `acquire_input_window` / `release_input_window` remain unchanged per k-round.

### What Moves to Host

- **Input DMA data selection**: The host SCF loop controls *which* DDR sub-tile is sent to the kernel each iteration by re-arming input shim BDs with different offsets. The kernel's `m_rounds` loop still exists but is now data-driven by the host.
- **Per-sub-tile synchronization**: The host `wait_io(shim_a, shim_b)` ensures each sub-tile's input data has been fully sent before reconfiguring BDs for the next sub-tile.

---

## 6. Implementation Sketch

### Where to Add Classification

**File**: `passblueprinttoschedule.cpp` (host pass)

Add the `classifyTiling()` utility function in the anonymous namespace, before `FlowTransferOpConversion`.

### Where to Add SCF Generation

**File**: `passblueprinttoschedule.cpp`, in `FlowTransferOpConversion::matchAndRewrite()`

Currently, the code at lines 1666-1735 generates a straight-line sequence:
```
getbdid -> start_io(shim) -> load_kernel_group -> launch_kernel_group
  -> start_io(core) -> wait
```

For Multiple mode, this becomes:
```cpp
// In FlowTransferOpConversion::matchAndRewrite():

auto classification = classifyTiling(moduleOp);

if (classification.mMode == TilingMode::Match &&
    classification.nMode == TilingMode::Match) {
    // === Current behavior: straight-line schedule ===
    // ... existing code (lines 1666-1735) ...
} else {
    // === Multiple mode: SCF loop schedule ===

    // 1. Emit load_kernel_group BEFORE the loop
    auto loadKernelGroupOp = rewriter.create<dfschedule::LoadKernelGroupOp>(...);

    // 2. Configure and arm shim output C BEFORE the loop
    //    repeat = mRounds * nRounds (all sub-tiles)
    config_dma_bd(shim_output_c, ...);
    start_io(shim_output_c, repeat = mRounds * nRounds);

    // 3. Arm core DMAs BEFORE the loop (continuous ping-pong)
    start_io(core_s2mm, repeat = mRounds * nRounds * kRounds);
    start_io(core_mm2s, repeat = mRounds * nRounds);

    // 4. Launch kernel BEFORE the loop (runs continuously)
    auto launchOp = rewriter.create<dfschedule::LaunchKernelGroupOp>(...);

    // 5. Create SCF loop bounds
    auto lb = rewriter.create<arith::ConstantIndexOp>(loc, 0);
    auto ub_m = rewriter.create<arith::ConstantIndexOp>(loc, classification.mRounds);
    auto step = rewriter.create<arith::ConstantIndexOp>(loc, 1);

    // 6. Build scf.for for M dimension
    auto mLoop = rewriter.create<scf::ForOp>(loc, lb, ub_m, step);
    rewriter.setInsertionPointToStart(mLoop.getBody());

    // 7. (Optional) Build nested scf.for for N dimension
    if (classification.nRounds > 1) {
        auto ub_n = rewriter.create<arith::ConstantIndexOp>(loc, classification.nRounds);
        auto nLoop = rewriter.create<scf::ForOp>(loc, lb, ub_n, step);
        rewriter.setInsertionPointToStart(nLoop.getBody());
    }

    // 8. Inside the loop body:
    //    - Compute BD offsets from induction variables
    //    - config_dma_bd for input A, B with new offsets
    //    - start_io(shim_input_a), start_io(shim_input_b)
    //    - wait_io(shim_input_a_event, shim_input_b_event)

    // 9. After the loops: wait for kernel launch + output shim
    rewriter.setInsertionPointAfter(mLoop);
    wait(launchOp.getEvent(), shim_output_c_event);
}
```

### Kernel Pass Changes

**File**: `passblueprinttoschedulekernel.cpp`

When host-side looping is active (classification is Multiple), the kernel pass should:
1. Set `m_rounds = 1` (not multiply `numRounds` by `mRounds`)
2. Set `n_rounds = 1` (not multiply `numRounds` by `nRounds`)
3. Keep `k_rounds` multiplication unchanged

This requires a coordination mechanism -- either a module attribute (`routing.host_side_m_loop = true`) or the kernel pass can simply re-run the same classification logic.

### New Module Attribute (Suggested)

```mlir
module attributes {
    routing.host_side_m_loop = true,    // host generates SCF loop for M
    routing.host_side_n_loop = false    // N loop stays in kernel (or also hoisted)
}
```

This allows the kernel pass to know whether to include the `mRounds` multiplier in `numRounds`.

---

## 7. Concrete Example

### Configuration

```
M = 64, K = 64, N = 64
HW_ROWS = 4, HW_COLS = 4
tile_m = 4, tile_n = 4, tile_k = 16
```

### Derived Parameters

```
tileRows = M / HW_ROWS = 64 / 4 = 16
tileCols = N / HW_COLS = 64 / 4 = 16
effectiveK = tile_k = 16
kRounds = K / effectiveK = 64 / 16 = 4
```

### Classification

```
M dimension: tile_m = 4, tileRows = 16
  -> 4 < 16 && 16 % 4 == 0
  -> Mode: Multiple, mRounds = 16 / 4 = 4

N dimension: tile_n = 4, tileCols = 16
  -> 4 < 16 && 16 % 4 == 0
  -> Mode: Multiple, nRounds = 16 / 4 = 4
```

### Per-Core Data Sizes

```
A partition per core: tileRows * K = 16 * 64 = 1024 elements (int8)
B partition per core: tileCols * K = 16 * 64 = 1024 elements (int8)
C partition per core: tileRows * tileCols = 16 * 16 = 256 elements (int8)
```

### Per-Iteration Sub-tile Sizes (what kernel sees each launch)

```
A sub-tile: tile_m * effectiveK = 4 * 16 = 64 elements
B sub-tile: tile_n * effectiveK = 4 * 16 = 64 elements
C sub-tile: tile_m * tile_n = 4 * 4 = 16 elements
```

### Window Init (kernel-side, per launch)

```
window_in_0 (A): bufSize = 64 / 4 = 16 vectors, numRounds = 2 * 4 = 8
                  (ppDepth=2, kRounds=4; no mRounds multiplier)
window_in_1 (B): bufSize = 64 / 4 = 16 vectors, numRounds = 2 * 4 = 8
window_out_0 (C): bufSize = 16 / 4 = 4 vectors, numRounds = 2
                   (ppDepth=2; no mRounds/nRounds multiplier)
```

### Host SCF Loop (pseudocode)

```
// === Outside the loop ===
load_kernel_group(cores=[16 tiles], elf="dskernel_receiver")

// Shim output C: configured once, replays 4*4=16 times
config_dma_bd(shim_c, offset = 0, len = 16)   // tile_m * tile_n = 4*4 = 16
start_io(shim_c, repeat = 16)                  // mRounds * nRounds = 4*4

// Core DMAs: configured once, run continuously
start_io(core_s2mm_a, repeat = 64)   // mRounds*nRounds*kRounds = 4*4*4
start_io(core_s2mm_b, repeat = 64)
start_io(core_mm2s_c, repeat = 16)   // mRounds*nRounds = 4*4

// Launch kernel once (runs continuously, consuming data as it arrives)
launch_kernel_group(kernel_group)

// === Inside the loop: only input DMA re-arm + wait ===
for mr = 0 to 4:       // M sub-tile loop
  for nr = 0 to 4:     // N sub-tile loop

    // --- Shim DMA for Input A ---
    // A sub-tile rows: [mr*4 .. mr*4+4), all K columns
    // DDR offset = mr * tile_m * K = mr * 4 * 64 = mr * 256 bytes
    // Per k-round BD length = tile_m * effectiveK = 4 * 16 = 64 bytes
    config_dma_bd(shim_a, offset = mr * 256, len = 64)
    start_io(shim_a, repeat = 4)   // kRounds = 4

    // --- Shim DMA for Input B ---
    // B sub-tile cols: [nr*4 .. nr*4+4), all K columns
    // DDR offset = nr * tile_n * K = nr * 4 * 64 = nr * 256 bytes
    // Per k-round BD length = tile_n * effectiveK = 4 * 16 = 64 bytes
    config_dma_bd(shim_b, offset = nr * 256, len = 64)
    start_io(shim_b, repeat = 4)   // kRounds = 4

    // --- Wait for input IO completion ---
    // Ensures shim input DMAs finish sending this sub-tile's A,B data
    // before the next iteration re-arms BDs with new offsets
    wait_io(shim_a_event, shim_b_event)

// === After all loops: wait for kernel + output completion ===
wait(launch_event, shim_c_event)

// Total kernel launches: 1 (runs continuously)
// Total shim input DMA transactions: A: 16 * 4 = 64, B: 16 * 4 = 64
// Total shim output DMA replays: C: 16
```

### Iteration Trace (input DMA re-arm per loop iteration)

| `(mr, nr)` | A DDR offset | A BD len | A repeat | B DDR offset | B BD len | B repeat |
|-------------|-------------|----------|----------|-------------|----------|----------|
| `(0, 0)` | 0 | 64 | 4 | 0 | 64 | 4 |
| `(0, 1)` | 0 | 64 | 4 | 256 | 64 | 4 |
| `(0, 2)` | 0 | 64 | 4 | 512 | 64 | 4 |
| `(0, 3)` | 0 | 64 | 4 | 768 | 64 | 4 |
| `(1, 0)` | 256 | 64 | 4 | 0 | 64 | 4 |
| ... | ... | ... | ... | ... | ... | ... |

Note: A offset only changes with `mr` (broadcast per row). B offset only changes with `nr` (broadcast per col). Output C is handled outside the loop with `repeat = 16`.

### Verification Checklist

1. **Total data volume matches**:
   - A total: `mRounds * kRounds * tile_m * effectiveK * numCoreTiles = 4 * 4 * 64 * 16 = 16384` -- but each core gets the same A (broadcast), so per-shim total = `4 * 4 * 64 = 1024` per row, times 4 rows = 4096 = M*K. Correct.
   - C total: `mRounds * nRounds * tile_m * tile_n * numCoreTiles = 4 * 4 * 16 * 16 = 4096 = M*N`. Correct.

2. **`load_kernel_group` and `launch_kernel_group` are outside the loop**: The ELF is loaded once and the kernel is launched once. The kernel runs continuously, consuming data as the host feeds it through the SCF loop.

3. **`shim_output_c` is outside the loop**: Output shim DMA is armed once with `repeat = mRounds * nRounds = 16`. The DMA engine replays the BD 16 times, collecting one sub-tile per replay.

4. **`wait_io` inside the loop**: Each loop iteration waits for input A and B shim DMA completion before re-arming BDs with new offsets. This prevents BD reconfiguration while DMA is still active.

5. **SCF iteration count matches expected DMA transactions**: `mRounds * nRounds = 4 * 4 = 16` iterations, each with `kRounds = 4` input BD replays. Total shim input transactions = `16 * 4 = 64` per input port.

---

## 8. Comparison: Kernel-Side vs Host-Side Looping

| Aspect | Kernel-Side (Current) | Host-Side SCF (Proposed) |
|--------|----------------------|--------------------------|
| M-loop location | Inside kernel ELF | Host `scf.for` in dfschedule IR |
| Kernel launches | 1 | 1 (runs continuously) |
| `launch_kernel_group` | Inside schedule, 1 call | Outside loop, 1 call |
| `shim_output_c` | 1 start_io | 1 start_io outside loop, repeat = mRounds*nRounds |
| Input DMA (A, B) | Fixed BD, repeat = mRounds*kRounds | Re-armed per iteration, repeat = kRounds |
| Input sync | None (implicit via kernel window protocol) | `wait_io(A, B)` per iteration in SCF loop |
| DMA BD offsets | Fixed (one config) | Input offsets recomputed per iteration |
| Kernel complexity | Higher (manages m_rounds loop) | Lower (single sub-tile, m_rounds=1) |
| Host complexity | Lower (fire-and-forget) | Higher (SCF loop + offset math + wait_io) |
| Debugging | Harder (opaque kernel) | Easier (host-visible iteration) |
| Performance overhead | Lower (no BD re-arm) | Higher (BD re-arm + wait_io per iteration) |

### When to Use Each

- **Kernel-side** (current): Best for production when sub-tile count is small and kernel re-launch overhead matters.
- **Host-side SCF**: Better for development/debug, and necessary when BD offsets must vary per iteration (non-uniform sub-tiles, future extensions).

---

## 9. Open Questions

1. **Kernel m_rounds in continuous mode**: Since `launch_kernel_group` is called once and the kernel runs continuously, the kernel's `m_rounds` must equal the total number of sub-tile iterations (`mRounds * nRounds`), not 1. The kernel still loops internally but is driven by the host's input DMA feeding pace. The host SCF loop controls *which* data is sent, while the kernel controls *how many* times it acquires/releases windows.

2. **Core DMA repeat counts**: Core tile DMAs (S2MM for input, MM2S for output) are armed once outside the loop with `repeat = mRounds * nRounds * kRounds` (input) or `repeat = mRounds * nRounds` (output). This assumes ping-pong BD chains run continuously without needing re-arm. Need to verify the BD chain doesn't terminate mid-way.

3. **N-dimension**: Should N sub-tile iteration also move to host, or only M? The plan includes both, but N iteration could stay in kernel if B data is streamed (no caching needed per N sub-tile).

4. **Backward compatibility**: The classification logic should default to Match mode (no loops) when `tile_m == 0` or `tile_m == tileRows`, preserving existing behavior for all current test cases.

5. **wait_io granularity**: The `wait_io` inside the loop waits for both input A and input B shim DMAs. This is necessary to ensure the BD can be safely reconfigured with new offsets. Need to confirm that `wait_io` on a shim input channel returns after the `repeat` count is exhausted (all kRounds BDs have been sent).

---

## 10. DfscheduleToApi: EmitC Conversion Logic

### Current Conversion Pipeline

The dfschedule IR is lowered to C++ through two stages:

```
dfschedule IR  --[DfscheduleToApiPass]--> EmitC IR  --[translateToCpp]--> host.cc
```

**DfscheduleToApiPass** (`passdfscheduletoapi.cpp`) converts each dfschedule op into an `emitc.call_opaque` that invokes a `__Runtime_*` C function. The pass uses MLIR's `DialectConversion` framework with benefit-ordered patterns:

| dfschedule Op | EmitC Call | Benefit | Dependencies |
|---------------|-----------|---------|--------------|
| `DeclareTileOp` | `XAie_TileLoc(col, row)` | 100 | None |
| `DeclareTensorOp` | `emitc.global` array decl | 100 | None |
| `ConfigDmaBdOp` | `__Runtime_dma_bd_config(dev, tile, bd_id, offset, len, ...)` | 50 | DeclareTile |
| `ConfigCreateIoOp` | `__Runtime_create_io(dev, tile, bd_handle, ch, dir)` | 10 | ConfigDmaBd |
| `LoadKernelGroupOp` | `__Runtime_load_kernel_group_Nt(dev, t0..tN, numTiles)` | 2 | DeclareTile |
| `StartIoOp` | `__Runtime_startio(dev, io, bd_id, repeat)` | 1 | ConfigCreateIo |
| `LaunchKernelGroupOp` | `__Runtime_launch_kernel_group(dev, kernel_group)` | 1 | LoadKernelGroup |
| `ScheduleWaitOp` | `__Runtime_wait(dev, event)` (one per event) | 1 | StartIo, LaunchKernelGroup |

**Key detail**: The SCF dialect is already marked **legal** in the conversion target:
```cpp
// passdfscheduletoapi.cpp:3125
innerTarget.addLegalDialect<scf::SCFDialect>();
```

This means `scf.for` ops pass through DfscheduleToApiPass unchanged. The MLIR `translateToCpp` emitter natively handles `scf.for` → C++ `for` loop translation.

### Current Generated host.cc Pattern (Match Mode)

The existing generated host.cc is a flat sequence with no loops:

```cpp
// host.cc (current, Match mode -- abbreviated)
void main(...) {
    XAie_DevInst v1 = __Runtime_device_init(...);

    // 1. Declare tiles
    XAie_LocType v6 = XAie_TileLoc(0, 0);   // shim tile
    XAie_LocType v10 = XAie_TileLoc(0, 2);  // core tile (0,2)
    // ... 16 core tiles ...

    // 2. Configure shim DMA BDs (input A, row 0)
    XAie_DmaDesc v8 = __Runtime_dma_bd_config_multidim_ooo(v1, v6, v7, 0, 256, ...);
    // ... core tile BDs ...
    ioevent v34 = __Runtime_startio(v1, v9, 0, 4);    // shim input, repeat=4

    // ... repeat for rows 1-3 ...

    // 3. Load + launch kernel
    kernel_group v401 = __Runtime_load_kernel_group_16t(v1, v10, ..., 16);
    event v402 = __Runtime_launch_kernel_group(v1, v401);

    // 4. Core start_io (after ELF load)
    ioevent v403 = __Runtime_startio(v1, v15, 0, 1);  // core S2MM
    // ... all core tiles ...

    // 5. Wait for all events
    __Runtime_wait(v1, v402);   // launch event
    __Runtime_wait(v1, v34);    // shim io events
    // ...

    __Runtime_device_teardown(v1);
}
```

### Proposed Generated host.cc Pattern (Multiple Mode)

With the SCF loop, the generated host.cc will contain a C `for` loop. The `scf.for` in dfschedule IR passes through DfscheduleToApiPass (legal dialect), then `translateToCpp` converts it to a C `for` loop.

**dfschedule IR (after BlueprintToSchedulePass, before DfscheduleToApiPass):**

```mlir
func.func @main(%arg0: memref<64x64xi8>, %arg1: memref<64x64xi8>, %arg2: memref<64x64xi8>) {
    // Tile declarations
    %shim0 = dfschedule.declare_tile col=0, row=0
    %core0 = dfschedule.declare_tile col=0, row=2
    // ... more tiles ...

    // === Outside loop: load + output DMA + core DMA + launch ===

    // Load kernel ELF
    %kg = dfschedule.config.load_kernel_group tiles=[%core0, ...] ...

    // Output C shim DMA (configured once, repeat = mRounds*nRounds)
    %out_bd = dfschedule.config_dma_bd %out_buf, %shim0, %out_bd_id, offset=0, len=16, ...
    %out_io = dfschedule.config.create_io %out_bd, %shim0, ch=0, dir="s2mm", ...
    %out_evt = dfschedule.schedule.start_io %out_io, %out_bd_id, repeat=16

    // Core DMAs (armed once, continuous)
    // ... core S2MM and MM2S start_io with repeat = mRounds*nRounds*kRounds ...

    // Launch kernel (runs continuously)
    %launch_evt = dfschedule.schedule.launch_kernel_group %kg

    // === SCF loop: re-arm input shim DMAs per sub-tile ===
    %c0 = arith.constant 0 : index
    %c4 = arith.constant 4 : index
    %c1 = arith.constant 1 : index

    scf.for %mr = %c0 to %c4 step %c1 {
        scf.for %nr = %c0 to %c4 step %c1 {
            // Compute input A offset: mr * tile_m * K
            %mr_i32 = arith.index_cast %mr : index to i32
            %a_offset = arith.muli %mr_i32, %c256_i32 : i32

            // Compute input B offset: nr * tile_n * K
            %nr_i32 = arith.index_cast %nr : index to i32
            %b_offset = arith.muli %nr_i32, %c256_i32 : i32

            // Re-configure shim input A BD with new offset
            %a_bd = dfschedule.config_dma_bd %a_buf, %shim_a, %a_bd_id,
                        offset=%a_offset, len=64, ...
            %a_io = dfschedule.config.create_io %a_bd, %shim_a, ch=0, dir="mm2s", ...
            %a_evt = dfschedule.schedule.start_io %a_io, %a_bd_id, repeat=4

            // Re-configure shim input B BD with new offset
            %b_bd = dfschedule.config_dma_bd %b_buf, %shim_b, %b_bd_id,
                        offset=%b_offset, len=64, ...
            %b_io = dfschedule.config.create_io %b_bd, %shim_b, ch=0, dir="mm2s", ...
            %b_evt = dfschedule.schedule.start_io %b_io, %b_bd_id, repeat=4

            // Wait for input A and B to complete this sub-tile
            dfschedule.schedule.wait events=[%a_evt, %b_evt]
        }
    }

    // === After loops: wait for launch + output ===
    dfschedule.schedule.wait events=[%launch_evt, %out_evt]

    return
}
```

**After DfscheduleToApiPass (EmitC IR):**

The dfschedule ops are converted to `emitc.call_opaque`, but `scf.for` remains as-is:

```mlir
func.func @main(...) {
    // ... emitc.call_opaque for tile decl, BD config, etc. ...

    %kg = emitc.call_opaque "__Runtime_load_kernel_group_16t"(...) : ... -> !emitc.opaque<"kernel_group">
    // ... output BD config, start_io outside loop ...
    %launch_evt = emitc.call_opaque "__Runtime_launch_kernel_group"(...) : ... -> !emitc.opaque<"event">

    scf.for %mr = %c0 to %c4 step %c1 {
        scf.for %nr = %c0 to %c4 step %c1 {
            // arith ops compute offsets from %mr, %nr
            %a_offset = arith.muli ...
            // emitc.call_opaque "__Runtime_dma_bd_config"(...)
            // emitc.call_opaque "__Runtime_startio"(...)
            // emitc.call_opaque "__Runtime_wait"(...)  // wait for input A, B
        }
    }

    emitc.call_opaque "__Runtime_wait"(%dev, %launch_evt)
    emitc.call_opaque "__Runtime_wait"(%dev, %out_evt)
    return
}
```

**After translateToCpp (host.cc):**

```cpp
void main(int8_t arg0[64][64], int8_t arg1[64][64], int8_t arg2[64][64]) {
    XAie_DevInst v1 = __Runtime_device_init(...);

    // Tile declarations
    XAie_LocType v6 = XAie_TileLoc(0, 0);
    XAie_LocType v10 = XAie_TileLoc(0, 2);
    // ...

    // Load kernel (once)
    kernel_group v_kg = __Runtime_load_kernel_group_16t(v1, v10, ..., 16);

    // Output C: configure + arm (once, repeat=16)
    XAie_DmaDesc v_out_bd = __Runtime_dma_bd_config(v1, v6, ...);
    ioevent v_out_evt = __Runtime_startio(v1, v_out_io, 0, 16);

    // Core DMAs: arm once
    ioevent v_core_s2mm_0 = __Runtime_startio(v1, v_core_io_0, 0, 64);
    // ... all core tiles ...

    // Launch kernel (once)
    event v_launch = __Runtime_launch_kernel_group(v1, v_kg);

    // === SCF loop becomes C for-loop ===
    for (size_t mr = 0; mr < 4; mr += 1) {
        for (size_t nr = 0; nr < 4; nr += 1) {
            // Compute offsets
            int32_t a_offset = mr * 256;
            int32_t b_offset = nr * 256;

            // Re-configure input A BD
            XAie_DmaDesc v_a_bd = __Runtime_dma_bd_config(v1, v_shim_a, v_a_bd_id,
                                                           a_offset, 64, ...);
            ioevent v_a_evt = __Runtime_startio(v1, v_a_io, 0, 4);

            // Re-configure input B BD
            XAie_DmaDesc v_b_bd = __Runtime_dma_bd_config(v1, v_shim_b, v_b_bd_id,
                                                           b_offset, 64, ...);
            ioevent v_b_evt = __Runtime_startio(v1, v_b_io, 0, 4);

            // Wait for input completion before next iteration
            __Runtime_wait(v1, v_a_evt);
            __Runtime_wait(v1, v_b_evt);
        }
    }

    // Wait for launch + output
    __Runtime_wait(v1, v_launch);
    __Runtime_wait(v1, v_out_evt);

    __Runtime_device_teardown(v1);
}
```

### Conversion Patterns: What Exists vs. What's New

| Pattern | Exists? | Notes |
|---------|---------|-------|
| `ConfigDmaBdInnerPattern` | Yes | Currently uses **static** offset/len from op attrs. For SCF loop mode, offset must come from an SSA value (SCF induction var arithmetic). Need to extend to accept dynamic offset operand. |
| `StartIoInnerPattern` | Yes | `repeat` is currently a static attribute (`op.getRepeatCount()`). Works for both modes -- repeat is known at compile time. |
| `ScheduleWaitInnerPattern` | Yes | Emits `__Runtime_wait(dev, event)` for each event. Works unchanged for `wait_io` inside loop. |
| `LoadKernelGroupInnerPattern` | Yes | Unchanged -- called once outside loop. |
| `LaunchKernelGroupInnerPattern` | Yes | Unchanged -- called once outside loop. |
| `scf.for` handling | Yes (legal) | SCF is legal in DfscheduleToApiPass target. `translateToCpp` handles `scf.for` → `for` loop natively. No new pattern needed. |
| Dynamic BD offset | **New** | `ConfigDmaBdOp` currently takes `offset` as an `I32IntegerAttr` (static). For SCF loop, offset depends on induction variable. Two options: (a) Change offset to an SSA `Value` operand, or (b) Emit verbatim C with the computed offset expression. |

### Key Implementation Consideration: Dynamic BD Offset

The critical new requirement is that `ConfigDmaBdOp`'s offset must be dynamic inside the SCF loop body. Currently:

```cpp
// ConfigDmaBdOp (current): offset is a static integer attribute
int32_t offset = op.getOffset();  // e.g., 0, fixed at IR construction time
```

For the SCF loop, the offset depends on induction variables:
```
offset_A = %mr * tile_m * K   // computed from scf.for induction var %mr
```

**Option A -- Add dynamic offset operand to ConfigDmaBdOp:**

Extend the op definition to accept an optional SSA value for offset:
```tablegen
// In dfschedule dialect .td:
def ConfigDmaBdOp : ... {
    let arguments = (ins
        ...,
        OptionalAttr<I32Attr>:$static_offset,    // existing static path
        Optional<I32>:$dynamic_offset             // new: from arith ops
    );
}
```

The `ConfigDmaBdInnerPattern` then checks:
```cpp
Value offset;
if (auto dynOffset = op.getDynamicOffset())
    offset = adaptor.getDynamicOffset();  // SSA value from arith
else
    offset = rewriter.create<emitc::ConstantOp>(..., op.getStaticOffset());
```

**Option B -- Emit verbatim C expression:**

Use `emitc.verbatim` to emit inline C with the computed offset. Simpler but less clean:
```cpp
// In SCF loop body:
rewriter.create<emitc::VerbatimOp>(loc,
    "XAie_DmaSetAddrLen(&bd, " + offsetExpr + ", 64);");
```

Option A is recommended for maintainability and MLIR verification.

---

## 11. Asymmetric Sub-Tiling: `tile_m != tile_n` (Nested M×N Host Loop)

### Problem

The existing host-side SCF design (Section 4) assumes either M-only looping or symmetric `tile_m == tile_n`. In practice, `tile_m` and `tile_n` are independent parameters that control different subtile dimensions:

- **A matrix**: partitioned along M → `tileRows = M / meshRows`, subtile height = `tile_m`, so `mRounds = tileRows / tile_m`
- **B matrix**: partitioned along N → `tileCols = N / meshCols`, subtile width = `tile_n`, so `nRounds = tileCols / tile_n`

When `tile_m != tile_n`, we get `mRounds != nRounds`. The kernel must produce `mRounds × nRounds` output sub-tiles (each of size `tile_m × tile_n`), and the host must feed the correct A and B data for each `(mr, nr)` pair.

### Key Insight: A Reuse, B Cycling

For the GEMM `C[m,n] = A[m,k] × B[k,n]`:
- **A** depends only on the M index — the same A sub-tile is reused across all N iterations
- **B** depends only on the N index — B cycles through `nRounds` sub-tiles for each M iteration

This gives us a natural nested loop structure:

```
for mr = 0 to mRounds-1:          // outer: advance M sub-tile of A
    for nr = 0 to nRounds-1:      // inner: cycle through N sub-tiles of B
        feed A[mr], B[nr]  →  kernel produces C[mr, nr]
```

Within the inner loop, A stays fixed (same `mr`) while B iterates. When the outer loop advances `mr`, A changes to the next M sub-tile, and B restarts from sub-tile 0.

### DMA Data Feeding Pattern

For each `(mr, nr)` iteration, the host re-arms shim input DMA BDs:

| Iteration | A shim DMA | B shim DMA | Kernel output |
|-----------|-----------|-----------|---------------|
| `(0, 0)` | A sub-tile 0, repeat `kRounds` | B sub-tile 0, repeat `kRounds` | C[0,0] |
| `(0, 1)` | A sub-tile 0, repeat `kRounds` | B sub-tile 1, repeat `kRounds` | C[0,1] |
| ... | ... | ... | ... |
| `(0, nRounds-1)` | A sub-tile 0, repeat `kRounds` | B sub-tile `nRounds-1`, repeat `kRounds` | C[0, nRounds-1] |
| `(1, 0)` | A sub-tile 1, repeat `kRounds` | B sub-tile 0, repeat `kRounds` | C[1,0] |
| ... | ... | ... | ... |
| `(mRounds-1, nRounds-1)` | A sub-tile `mRounds-1` | B sub-tile `nRounds-1` | C[mRounds-1, nRounds-1] |

**A is repeated `nRounds` times per M sub-tile** (same DDR offset for all `nr` in one `mr`).
**B cycles from sub-tile 0 to `nRounds-1`** for each M iteration, then resets to 0 when `mr` advances.

Total iterations: `mRounds × nRounds`, each producing one `tile_m × tile_n` output block.

### BD Offset Formulas

```
// Input A: offset depends only on mr
offset_A(mr) = mr × tile_m × K × elemBytes
bd_len_A     = tile_m × effective_k × elemBytes
repeat_A     = kRounds

// Input B: offset depends only on nr
offset_B(nr) = nr × tile_n × K × elemBytes
bd_len_B     = tile_n × effective_k × elemBytes
repeat_B     = kRounds

// Output C: configured once outside loop
bd_len_C     = tile_m × tile_n × elemBytes
repeat_C     = mRounds × nRounds
```

### Host SCF IR (Nested Loop)

```mlir
// === Outside all loops ===
%kg = dfschedule.config.load_kernel_group ...
%launch_evt = dfschedule.schedule.launch_kernel_group %kg

// Output C: armed once, replays mRounds × nRounds times
%out_evt = dfschedule.schedule.start_io %out_io, repeat = mRounds * nRounds

// Core DMAs: armed once, continuous
// Input:  repeat = mRounds × nRounds × kRounds
// Output: repeat = mRounds × nRounds

// === Nested SCF loops ===
scf.for %mr = 0 to mRounds step 1 {
    // A offset = mr × tile_m × K × elemBytes
    %a_offset = arith.muli(%mr, stride_A)

    scf.for %nr = 0 to nRounds step 1 {
        // B offset = nr × tile_n × K × elemBytes
        %b_offset = arith.muli(%nr, stride_B)

        // Re-arm shim input A with a_offset (same for all nr in this mr)
        config_dma_bd(shim_a, offset = %a_offset, len = tile_m × eff_k)
        start_io(shim_a, repeat = kRounds)

        // Re-arm shim input B with b_offset
        config_dma_bd(shim_b, offset = %b_offset, len = tile_n × eff_k)
        start_io(shim_b, repeat = kRounds)

        // Wait for both inputs to complete before next BD re-arm
        wait_io(shim_a_evt, shim_b_evt)
    }
}

// === After loops: final sync ===
wait(launch_evt, out_evt)
```

Note: `%a_offset` is computed in the outer loop body but consumed in the inner loop. This is valid MLIR — SSA values defined in an outer `scf.for` body are visible in nested regions.

### Generated host.cc (C for-loops)

```cpp
// ... load_kernel_group, launch, output DMA, core DMA armed once ...

for (size_t mr = 0; mr < mRounds; mr++) {
    int32_t a_offset = mr * tile_m * K * elemBytes;

    for (size_t nr = 0; nr < nRounds; nr++) {
        int32_t b_offset = nr * tile_n * K * elemBytes;

        // Re-arm A input (same a_offset for all nr in this mr)
        __Runtime_dma_bd_config(dev, shim_a, bd_id_a, a_offset, tile_m * eff_k, ...);
        ioevent a_evt = __Runtime_startio(dev, io_a, bd_id_a, kRounds);

        // Re-arm B input (b_offset changes per nr)
        __Runtime_dma_bd_config(dev, shim_b, bd_id_b, b_offset, tile_n * eff_k, ...);
        ioevent b_evt = __Runtime_startio(dev, io_b, bd_id_b, kRounds);

        // Wait for this iteration's input DMAs
        __Runtime_wait(dev, a_evt);
        __Runtime_wait(dev, b_evt);
    }
}

// Final sync
__Runtime_wait(dev, launch_evt);
__Runtime_wait(dev, out_evt);
```

### Kernel Perspective

The kernel is unchanged — it does not know or care about the M/N loop structure. It simply:

1. Runs `m_rounds × n_rounds` total sub-tile iterations (set as `m_rounds = mRounds * nRounds` from the kernel pass, or equivalently the kernel loops `m_rounds` with an inner flat iteration)
2. Each iteration: acquires A window (`kRounds` times), acquires B window (`kRounds` times), accumulates, outputs one `tile_m × tile_n` block
3. The host's nested loop controls **which** A and B data arrives — the kernel just consumes in order

Window init (kernel-side):
```
window_in_0 (A):  numRounds = ppDepth × kRounds × mRounds × nRounds
window_in_1 (B):  numRounds = ppDepth × kRounds × mRounds × nRounds
window_out_0 (C): numRounds = ppDepth × mRounds × nRounds
```

### Concrete Example: Asymmetric Sub-Tiling

```
M = 64, K = 64, N = 64
HW_ROWS = 4, HW_COLS = 4
tile_m = 4, tile_n = 8, tile_k = 16    ← tile_m ≠ tile_n
```

Derived:
```
tileRows = 64 / 4 = 16,  tileCols = 64 / 4 = 16
mRounds  = 16 / 4 = 4,   nRounds  = 16 / 8 = 2
kRounds  = 64 / 16 = 4
Total iterations = 4 × 2 = 8
```

Per-iteration data:
```
A sub-tile: tile_m × eff_k = 4 × 16 = 64 elements
B sub-tile: tile_n × eff_k = 8 × 16 = 128 elements
C sub-tile: tile_m × tile_n = 4 × 8 = 32 elements
```

Iteration trace:

| `(mr, nr)` | A offset | A len | A repeat | B offset | B len | B repeat | C sub-tile |
|-------------|---------|-------|----------|---------|-------|----------|------------|
| `(0, 0)` | 0 | 64 | 4 | 0 | 128 | 4 | C[0:4, 0:8] |
| `(0, 1)` | 0 | 64 | 4 | 512 | 128 | 4 | C[0:4, 8:16] |
| `(1, 0)` | 256 | 64 | 4 | 0 | 128 | 4 | C[4:8, 0:8] |
| `(1, 1)` | 256 | 64 | 4 | 512 | 128 | 4 | C[4:8, 8:16] |
| `(2, 0)` | 512 | 64 | 4 | 0 | 128 | 4 | C[8:12, 0:8] |
| `(2, 1)` | 512 | 64 | 4 | 512 | 128 | 4 | C[8:12, 8:16] |
| `(3, 0)` | 768 | 64 | 4 | 0 | 128 | 4 | C[12:16, 0:8] |
| `(3, 1)` | 768 | 64 | 4 | 512 | 128 | 4 | C[12:16, 8:16] |

Observations:
- A offset changes every `nRounds = 2` iterations (only advances with `mr`)
- B offset cycles `{0, 512}` for every M iteration (resets when `mr` advances)
- Total: 8 C sub-tiles of 32 elements = 256 = 16 × 16 = tileRows × tileCols ✓

### Verification Checklist for Asymmetric Case

1. **Data volume**:
   - A total per shim row: `mRounds × kRounds × tile_m × eff_k = 4 × 4 × 64 = 1024 = tileRows × K` ✓
   - B total per shim col: `nRounds × kRounds × tile_n × eff_k = 2 × 4 × 128 = 1024 = tileCols × K` ✓
   - C total per core: `mRounds × nRounds × tile_m × tile_n = 4 × 2 × 32 = 256 = tileRows × tileCols` ✓

2. **A reuse correctness**: A sub-tile `mr` is sent `nRounds` times (once per inner iteration). The BD offset `mr × tile_m × K` is constant within the inner loop — only `mr` changes it.

3. **B cycling correctness**: B cycles from sub-tile 0 to `nRounds-1` for each M iteration. The BD offset `nr × tile_n × K` resets to 0 when the inner loop restarts.

4. **Kernel window protocol**: The kernel acquires `mRounds × nRounds = 8` sets of (A, B) windows. Each set consists of `kRounds = 4` acquire/release pairs for A and B. Total: `8 × 4 = 32` A acquires, `8 × 4 = 32` B acquires, `8` C releases.

5. **Memory budget**: Local buffers sized for one sub-tile:
   - `all_A[tile_m × eff_k] = 64 bytes` (was `tile_rows × eff_k = 256` in match mode)
   - `accum[tile_m × tile_n] = 32 × 2 = 64 bytes` (int16)
   - `local_out[tile_m × tile_n] = 32 bytes`
   - Total: 160 bytes — well within 48KB data memory ✓

### Relationship to Current Single-Loop Implementation

The current implementation (Section 4, lines 1750-1873 in `passblueprinttoschedule.cpp`) generates a single `scf.for` from 0 to `mRounds` for input flows. This handles the case where only M sub-tiling is active (`nRounds == 1`).

To support asymmetric sub-tiling, the implementation needs:

1. **Nest an inner `scf.for` for `nRounds`** when `classification.nMode == TilingMode::Multiple`
2. **Separate A and B offset computation**: A offset in outer loop body, B offset in inner loop body
3. **Both A and B re-armed per inner iteration**: even though A offset is constant within the inner loop, the BD must still be re-armed because `wait_io` consumes the start_io event
4. **Classification extension**: `classifyTiling()` already computes both `mRounds` and `nRounds` independently — the loop generation code needs to use both

The key code change is in the `Multiple mode` branch of `FlowTransferOpConversion::matchAndRewrite()`: wrap the existing single loop with an outer M loop, add a nested N loop, and compute A/B offsets from the respective induction variables.

### Edge Cases

| Scenario | mRounds | nRounds | Loop structure |
|----------|---------|---------|---------------|
| `tile_m == tileRows, tile_n == tileCols` | 1 | 1 | No loop (Match mode) |
| `tile_m < tileRows, tile_n == tileCols` | >1 | 1 | Single M loop (current) |
| `tile_m == tileRows, tile_n < tileCols` | 1 | >1 | Single N loop |
| `tile_m < tileRows, tile_n < tileCols` | >1 | >1 | Nested M×N loop (this section) |

All four cases are handled uniformly by the nested loop — when `mRounds == 1` or `nRounds == 1`, the corresponding loop body executes exactly once, equivalent to no loop.

---

## 12. Shim S2MM Receiving Plan for OOO Output with tile_m/tile_n Sub-Tiling

### Problem: Incorrect 3D Stride for Output Receiving

When both `tile_m < tileRows` and `tile_n < tileCols`, the shim S2MM (output receiving) BD must use **4D addressing** (3 address dimensions + 1 iteration dimension) to correctly place each sub-tile block into the DDR output matrix.

The current code (lines 944-966 of `passblueprinttoschedule.cpp`) uses 3D addressing with a "diagonal shift" D2 stride that conflates the N-column stepping with the M-row stepping. This produces incorrect DDR placement.

### Analysis: Data Arrival Order

The kernel produces output in the order dictated by the host SCF loop (or kernel internal `m_rounds × n_rounds` iteration):

```
For each m_round (M sub-tile iteration):
  For each n_round (N sub-tile iteration):
    Output one tile_m × tile_n block
```

For a 4-core-column shim receiving with OOO BDs (one BD per source core tile), each BD must independently receive `mRounds × nRounds` sub-tile blocks and place them into the correct DDR positions.

### DDR Output Layout (Per-Tile Column)

Each shim S2MM BD handles one source core tile's output. The core tile produces a `tileRows × tileN` region in DDR, subdivided into `mRounds × nRounds` sub-tile blocks of size `tile_m × tile_n`.

```
Example: M=64, N=64, HW_ROWS=4, HW_COLS=4, tile_m=8, tile_n=8
  tileRows = 16, tileCols = 16
  mRounds = 2, nRounds = 2
  Per-tile: tileN = 16 columns
  Output block: 8×8 = 64 elements (int8)

Per-tile DDR layout (16 rows × 16 cols within the tile's column range):

  +--------+--------+
  | (0,0)  | (0,1)  |   ← m=0: rows 0-7
  | 8×8    | 8×8    |
  +--------+--------+
  | (1,0)  | (1,1)  |   ← m=1: rows 8-15
  | 8×8    | 8×8    |
  +--------+--------+
     n=0      n=1

Block (mr,nr) occupies:
  rows: [mr*tile_m .. (mr+1)*tile_m)
  cols: [tile_col_start + nr*tile_n .. tile_col_start + (nr+1)*tile_n)
```

### DMA Dimension Plan

The kernel sends blocks in the inner loop order: n iterates faster than m (A is repeated, B cycles). So the DMA receives blocks in order: `(0,0), (0,1), (1,0), (1,1)`.

**4D DMA addressing (3 address dims + 1 iteration):**

| Dim | Purpose | Stride (bytes) | Wrap | Formula |
|-----|---------|---------------|------|---------|
| D0 | Contiguous word within tile row | `wordBytes` = 4 | `tile_n / elemsPerWord` | For i8: tile_n=8, ePW=4 → wrap=2; but current code uses wrap=1 (no-op, len handles contiguous) |
| D1 | Next row within sub-tile block | `outW / elemsPerWord * wordBytes` | `tile_m` | DDR row stride in bytes; tile_m rows per block |
| D2 | Next N sub-tile (column advance) | `tile_n / elemsPerWord * wordBytes` | `nRounds` | Step tile_n elements to next column block |
| D3 (iter) | Next M sub-tile (row advance) | `tile_m * outW / elemsPerWord * wordBytes` | `mRounds` | Step tile_m DDR rows to next row block |

### Concrete Values (M=64, N=64, HW=4×4, tile_m=8, tile_n=8, int8)

```
outW = 64 elements = 16 words
elemsPerWord = 4 (int8)
wordBytes = 4

D0: stride = 4 bytes,  wrap = 1 (pass-through; contiguous handled by len)
D1: stride = 16*4 = 64 bytes,  wrap = 8 (tile_m rows)
D2: stride = 8/4*4 = 8 bytes,  wrap = 2 (nRounds, column advance)
D3: stride = 8*16*4 = 512 bytes,  wrap = 2 (mRounds, row advance)

len = tile_m * tile_n * mRounds * nRounds = 8*8*2*2 = 256 bytes
num_dims = 4 (3 address + 1 iteration)
```

### Expected API Call

```cpp
__Runtime_dma_bd_config_multidim(dev, shim_tile, buffer,
    bd_id, 256,          // len = tileM * tileN * mRounds * nRounds
    -1,                  // next_bd (disabled for OOO)
    0, pkt_id,           // enable_packet=false, packet_id (for debug)
    -1, 0, -1, 0, -1,   // no locks, no ooo_bd_id
    4,                   // num_dims = 4 (3 address + 1 iteration)
    4, 1,                // D0: stride=4, wrap=1 (contiguous pass-through)
    64, 8,               // D1: stride=64, wrap=8 (tile_m rows, DDR row stride)
    8, 2,                // D2: stride=8, wrap=2 (nRounds, column advance by tile_n)
    512, 2               // D3/iter: stride=512, wrap=2 (mRounds, row advance by tile_m*outW)
)
```

### Current (Incorrect) vs Expected (Correct)

| Parameter | Current (3D diagonal) | Expected (4D: N-col + M-iter) |
|-----------|----------------------|-------------------------------|
| `num_dims` | 3 | **4** |
| D0 | stride=4, wrap=1 | stride=4, wrap=1 (same) |
| D1 | stride=64, wrap=8 | stride=64, wrap=8 (same) |
| D2 | stride=**516**, wrap=**2** | stride=**8**, wrap=**2** |
| D3 | stride=0, wrap=0 (unused) | stride=**512**, wrap=**2** |

The current D2 stride=516 = `tileM * outW_w * wordBytes + 1 * wordBytes` = 8×16×4 + 4 = 516 conflates the M-row advance with a 1-word column shift, which is incorrect. The correct approach separates N-column stepping (D2) from M-row stepping (D3/iteration).

### Generalized Formulas

For any combination of tile_m, tile_n, outW, elemsPerWord:

```
D0_stride = wordBytes                            (= 4)
D0_wrap   = 1                                    (pass-through)

D1_stride = (outW / elemsPerWord) * wordBytes    (DDR row stride in bytes)
D1_wrap   = tile_m                               (rows per sub-tile)

D2_stride = (tile_n / elemsPerWord) * wordBytes   (column advance by tile_n)
D2_wrap   = nRounds                               (= tileCols / tile_n)

D3_stride = tile_m * (outW / elemsPerWord) * wordBytes  (row advance by tile_m DDR rows)
D3_wrap   = mRounds                                      (= tileRows / tile_m)

num_dims = 4                                     (3 address + 1 iteration)
len = tile_m * tile_n * mRounds * nRounds * elemBytes
```

### Edge Cases

| Condition | nRounds | mRounds | Solution |
|-----------|---------|---------|----------|
| tile_n == tileCols (N-match) | 1 | >1 | D2 wrap=1 (no-op), D3 handles mRounds. Equivalent to current 2D + iteration. |
| tile_m == tileRows (M-match) | >1 | 1 | D3 wrap=1 (no-op), D2 handles nRounds. Effectively 3D only. |
| Both match | 1 | 1 | D2 wrap=1, D3 wrap=1. Degenerates to 2D (current Match mode). |
| Both sub-tiled | >1 | >1 | Full 4D as described above. |

All four cases are handled uniformly by the 4D formula — when a wrap value is 1, the corresponding dimension is a no-op.

### Verification Trace

For BD on tile (3,0) receiving from core tile column 3 (the user's line 355 example):

```
M=64, N=64, HW=4×4, tile_m=8, tile_n=8, int8
Per-tile tileN = 16, tileRows = 16
mRounds = 2, nRounds = 2

Block (0,0): rows 0-7, cols 0-7 within tile column
  DDR base + 0 → D1 sweeps 8 rows at stride 64
Block (0,1): rows 0-7, cols 8-15
  D2 advances by 8 bytes → same rows, next tile_n columns
Block (1,0): rows 8-15, cols 0-7
  D3 (iter) advances by 512 bytes (8 rows × 64 bytes/row)
  D2 resets to column 0
Block (1,1): rows 8-15, cols 8-15
  D2 advances by 8 bytes again

Total: 4 blocks × 64 bytes = 256 bytes ✓
```

---

## 13. Fix Plan: Shim S2MM OOO BD 4D Addressing

### Root Cause

In `passblueprinttoschedule.cpp` lines 944-966, the OOO shim S2MM BD dimension computation uses 3D addressing with a "diagonal shift" D2 that combines M-row and N-column advances into a single stride. This is incorrect when both `tile_m < tileRows` and `tile_n < tileCols`.

### Fix Location

**File**: `src/mlir/mlirfront/tilinglinalg/pass/passblueprinttoschedule/passblueprinttoschedule.cpp`

**Lines**: 944-972 (the `if (tileM > 0 && tileM < tileRowsVal && !shimIsSender)` block)

### Fix Steps

#### Step 1: Read tile_n and tile_cols attributes

Currently the code only reads `routing.tile_m` and `routing.tile_rows`. Add reading of `routing.tile_n` and `routing.tile_cols` to compute `nRounds`.

```cpp
auto tileNAttr = moduleOp ? moduleOp->getAttrOfType<IntegerAttr>("routing.tile_n") : nullptr;
auto tileColsAttr = moduleOp ? moduleOp->getAttrOfType<IntegerAttr>("routing.tile_cols") : nullptr;
int64_t tileMVal = tileMAttr ? tileMAttr.getInt() : 0;
int64_t tileNVal = tileNAttr ? tileNAttr.getInt() : 0;
int64_t tileRowsVal = tileRowsAttr ? tileRowsAttr.getInt() : 0;
int64_t tileColsVal = tileColsAttr ? tileColsAttr.getInt() : 0;
```

#### Step 2: Compute nRounds

```cpp
int64_t nRounds = 1;
int64_t tileN_sub = tileN; // per-tile column width (outW / numCoreTiles)
if (tileNVal > 0 && tileNVal < tileColsVal) {
    nRounds = tileColsVal / tileNVal;
    tileN_sub = tileNVal; // use sub-tile width, not full per-tile width
}
```

Note: `tileN` (= outW / numCoreTiles) is the per-tile column width. `tile_n` (from module attr) is the sub-tile width. When nRounds > 1, each BD must use `tile_n` for D2 stepping, not `tileN`.

#### Step 3: Replace 3D diagonal with 4D addressing

Replace the current 3D stride computation with:

```cpp
SmallVector<Attribute> strides4d, wraps4d;
// D0: contiguous word (pass-through)
strides4d.push_back(rewriter.getI32IntegerAttr(1 * wordBytes));
wraps4d.push_back(rewriter.getI32IntegerAttr(1));

// D1: DDR row stride, tile_m rows
strides4d.push_back(rewriter.getI32IntegerAttr(outW_w * wordBytes));
wraps4d.push_back(rewriter.getI32IntegerAttr(tileM));

// D2: N column advance by tile_n
int64_t tileN_sub_w = tileN_sub / elemsPerWord;
strides4d.push_back(rewriter.getI32IntegerAttr(tileN_sub_w * wordBytes));
wraps4d.push_back(rewriter.getI32IntegerAttr(nRounds));

// D3: M row advance by tile_m DDR rows (becomes iteration dim)
int64_t d3Stride = tileM * outW_w * wordBytes;
strides4d.push_back(rewriter.getI32IntegerAttr(d3Stride));
wraps4d.push_back(rewriter.getI32IntegerAttr(mRounds));

perTileDimStrides = rewriter.getArrayAttr(strides4d);
perTileDimWraps = rewriter.getArrayAttr(wraps4d);
```

#### Step 4: Update perRoundBytes (BD len)

The BD `len` must cover the full D0×D1×D2×D3 volume:

```cpp
perRoundBytes = tileM * tileN_sub * mRounds * nRounds * ooElementSizeBytes;
```

This replaces the current `tileM * tileN * mRounds` formula (which didn't account for nRounds and used the wrong tileN).

#### Step 5: Ensure num_dims=4 in ConfigDmaBdOp

The `ConfigDmaBdOp` must emit `num_dims=4` when 4 dimension pairs are provided. Check that `passdfscheduletoapi.cpp` correctly counts dimensions from the dim_strides array length. Since we now push 4 strides + 4 wraps, the op should emit `num_dims=4`.

Verify in `passdfscheduletoapi.cpp` (around ConfigDmaBdInnerPattern) that the dim count is derived from the array size, not hardcoded to 3.

#### Step 6: Handle edge case nRounds=1

When `tile_n == tileCols` (N-match), `nRounds = 1`. The formula still works: D2 wrap=1 is a no-op, and D3 handles mRounds. This degenerates to the equivalent of the current 2D+iteration path, so no special casing is needed.

Similarly, when `tile_m == tileRows` (M-match) but `tile_n < tileCols`, we need D2 for nRounds and D3 wrap=1. The current code path (lines 944) only triggers when `tileM > 0 && tileM < tileRowsVal`, so this case would not enter the 3D block. A separate condition should handle N-only sub-tiling if needed.

### Testing

After the fix, regenerate host.cc and verify:

1. **Line 355 specifically**: The call should become:
   ```
   __Runtime_dma_bd_config_multidim(v1, v39, v188, 5, 256, -1, 0, 4, -1, 0, -1, 0, -1, 4, 4, 1, 64, 8, 8, 2, 512, 2)
   ```

2. **All 4 per-tile OOO BDs** (bd_id=2,3,4,5 on tile (3,0)): same dimension pattern, different packet_ids and buffer offsets.

3. **HW verification**: Run with `apppaltest.py` and check output matrix matches golden reference.

### Files Changed

| File | Change |
|------|--------|
| `passblueprinttoschedule.cpp:944-972` | Replace 3D diagonal strides with 4D (D2=N-col, D3=M-iter) |
| `passblueprinttoschedule.cpp:991-1010` | Update perRoundBytes to include nRounds |

---

## References

- `src/mlir/mlirfront/tilinglinalg/pass/passblueprinttoschedule/passblueprinttoschedule.cpp` -- host schedule generation (lines 1666-1735: load/launch/start_io/wait pattern; lines 1676-1701: current mRounds repeat logic)
- `src/mlir/mlirfront/tilinglinalg/pass/passblueprinttoschedulekernel/passblueprinttoschedulekernel.cpp` -- kernel window_init/numRounds (lines 820-940: mRounds/kRounds multiplication)
- `src/mlir/mlirfront/tilinglinalg/pass/passdfscheduletoapi/passdfscheduletoapi.cpp` -- dfschedule-to-EmitC conversion (ConfigDmaBdInnerPattern:1127, StartIoInnerPattern:1748, ScheduleWaitInnerPattern:1796, LoadKernelGroupInnerPattern:1857, LaunchKernelGroupInnerPattern:2010; SCF legal at line 3125)
- `example/tileprogram/ccode/simplematmul2.cc` -- kernel m_rounds/k_rounds loop structure
- `doc/design/tile_m_n_k_analysis.md` -- existing analysis of tile_m/n/k pipeline flow
- `ir/dfschedule/0_initial.mlir` -- module attributes (routing.tile_m, routing.tile_rows, routing.m_rounds, etc.)
- `src/mlir/mlirfront/tilinglinalg/pass/unitest/worklocal/host.cc` -- generated host.cc sample (current flat sequence)
