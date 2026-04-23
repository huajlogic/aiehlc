# A/B Swap Bug: Debug Analysis and Solution

## Problem Statement

The host pass (`BlueprintToSchedulePass`) and kernel pass (`BlueprintToScheduleKernelPass`) used different ordering to name buffers and windows. This caused matrix A data to arrive at the kernel's `window_in_1` (B slot) and matrix B data to arrive at `window_in_0` (A slot), producing incorrect matmul results.

The kernel call is:
```cpp
computekernel(window_in_0, window_in_1, window_out_0)
//            ^ expects A    ^ expects B    ^ produces C
```

If `window_in_0` receives B and `window_in_1` receives A, the computation is `C = B * A` instead of `C = A * B`.

## Root Cause

Three resources must agree on ordering: **buffer names**, **lock IDs**, and **DMA channels**. The host assigns all three; the kernel assigns its own lock offsets (LOCK_BASE=48) and buffer addresses. If the host and kernel disagree on which "slot 0" means, data goes to the wrong window.

### Host pass (encounter order)

The host pass processes flows in the order `FlowConfigOp`s appear in the IR. With the col-axis partition (B, `data_id=0`) appearing before the row-axis partition (A, `data_id=1`):

```
FlowConfig for B (data_id=0) → encountered first → dirIdx=0 → buf_in_ping_0, lock 0/1
FlowConfig for A (data_id=1) → encountered second → dirIdx=1 → buf_in_ping_1, lock 2/3
```

### Kernel pass (declare_data walk order)

The kernel pass walks `declare_data` ops inside the module. A (`%arg0`) is walked first, B (`%arg1`) second:

```
declare_data for A (%arg0) → walked first → window_in_0, lock 48/49
declare_data for B (%arg1) → walked second → window_in_1, lock 50/51
```

### The mismatch

| Resource | Host assigns to B | Kernel expects at window_in_0 |
|----------|-------------------|-------------------------------|
| Buffer | `buf_in_ping_0` | `buf_in_ping_0` |
| Lock | 0/1 | 48/49 (= host 0/1) |
| Channel | S2MM ch 1 | — |

Host lock 0/1 protects B data, but kernel lock 48/49 (`window_in_0`) is the first input window (A). The kernel reads B data as A.

## Debug Methodology

### 1. Trace the SSA chain

Both passes ultimately derive their data from function arguments (`%arg0` = A, `%arg1` = B, `%arg2` = C). The key insight: every `FlowConfigOp`'s `view` value traces back through the SSA def-use chain to a specific `BlockArgument` of the entry `func::FuncOp`.

The chain typically looks like:
```
func.func @main(%arg0: memref<16x16xi8>, %arg1: memref<16x16xi8>, %arg2: memref<16x16xi8>)
  └─ bufferization.to_tensor %arg1
       └─ routing.routingcreatescheduletensor
            └─ routing.partitiontensor
                 └─ dfscheblueprint.declare_data
                      └─ tensor.extract_slice
                           └─ FlowConfigOp (view = this slice)
```

Walking backward from `FlowConfigOp.view` to `%arg1` yields `funcArgIndex = 1` (B).

### 2. Verify with debug output

Added `[HostParamMapping]` and `[KernelParamMapping]` debug lines:

```
[HostParamMapping] data_id=0 funcArgIdx=1 isInput=1 dirIdx=1    ← B → slot 1
[HostParamMapping] data_id=1 funcArgIdx=0 isInput=1 dirIdx=0    ← A → slot 0
[HostParamMapping] data_id=2 funcArgIdx=2 isInput=0 dirIdx=0    ← C → output slot 0

[KernelParamMapping] Parameter order mapping:
  funcArg=0 → window_in_0  → buf_in_ping_0/buf_in_pong_0 → lock=48/49
  funcArg=1 → window_in_1  → buf_in_ping_1/buf_in_pong_1 → lock=50/51
  funcArg=2 → window_out_0 → buf_out_ping_0/buf_out_pong_0 → lock=52/53
```

### 3. Cross-reference host/kernel

After the fix, the mapping is consistent:

| Param | funcArgIdx | Host Lock | Host Address (DMA) | Kernel Lock | Kernel Buffer | Kernel Address |
|-------|-----------|-----------|-------------------|-------------|---------------|----------------|
| A (v1) | 0 | 0/1 | 0x8040/0x8060 | 48/49 | buf_in_ping_0 | 0x78040/0x78060 |
| B (v2) | 1 | 2/3 | 0x8000/0x8020 | 50/51 | buf_in_ping_1 | 0x78000/0x78020 |
| C (v3) | 2 | 4/5 | 0x8080/0x80A0 | 52/53 | buf_out_ping_0 | 0x78080/0x780A0 |

Note: Core processor addresses = DMA addresses + 0x70000.

## Solution: SSA-traced `funcArgIndex` ordering

Instead of using encounter order (`data_id` first-seen) or walk order (`declare_data` iteration), both passes trace the SSA chain from the flow's view value back to the function argument and use `funcArgIndex` as the canonical ordering key.

### `traceToFuncArgIndex()` function

Added to both `passblueprinttoschedule.cpp` and `passblueprinttoschedulekernel.cpp`:

```cpp
static int traceToFuncArgIndex(Value v) {
    for (int depth = 0; depth < 20; ++depth) {
        if (auto blockArg = dyn_cast<BlockArgument>(v)) {
            if (auto funcOp = dyn_cast<func::FuncOp>(blockArg.getOwner()->getParentOp()))
                return static_cast<int>(blockArg.getArgNumber());
            break;
        }
        Operation *defOp = v.getDefiningOp();
        if (!defOp) break;
        // Walk through known forwarding ops
        if (defOp->getName().getStringRef() == "routing.routingextract_data" ||
            defOp->getName().getStringRef() == "routing.routingcreatescheduletensor" ||
            defOp->getName().getStringRef() == "routing.partitiontensor" ||
            defOp->getName().getStringRef() == "bufferization.to_tensor" ||
            defOp->getName().getStringRef() == "dfscheblueprint.declare_data" ||
            defOp->getName().getStringRef() == "tensor.extract_slice") {
            v = defOp->getOperand(0);
            continue;
        }
        if (defOp->getNumOperands() > 0) {
            v = defOp->getOperand(0);
            continue;
        }
        break;
    }
    return -1;
}
```

### Host pass changes (`passblueprinttoschedule.cpp`)

1. **Moved `dirIdx` computation before the tile loop** so it is available for both buffer naming and lock allocation.

2. **Changed lock allocation** from sequential `allocateTileLockPair(flowIndex)` to deterministic `dirIdx`-based:
   ```cpp
   if (isInput) {
       acquireLockId = dirIdx * 2;       // input 0 → lock 0/1, input 1 → lock 2/3
       releaseLockId = dirIdx * 2 + 1;
   } else {
       int outputLockBase = nextInputIdx * 2;  // outputs start after inputs
       acquireLockId = outputLockBase + dirIdx * 2;
       releaseLockId = outputLockBase + dirIdx * 2 + 1;
   }
   ```

3. **Changed buffer naming** from encounter-order `nextInputIdx++` to `funcArgIdx`:
   ```cpp
   dirIdx = (funcArgIdx >= 0) ? funcArgIdx : nextInputIdx;
   ```

### Kernel pass changes (`passblueprinttoschedulekernel.cpp`)

1. **Added `funcArgIndex` field** to `KernelParamInfo` struct.

2. **Two-phase analysis** in `analyzeKernelParams()`:
   - Phase 1 (walk): Collect params with `funcArgIndex` from SSA trace, no names/locks assigned.
   - Phase 2 (sort): Separate inputs/outputs, sort each by `funcArgIndex`, then assign sequential names (`window_in_0`, `window_in_1`, ...) and lock IDs.

3. **Lock ordering matches host**: The kernel's `KernelResourceManager` allocates locks sequentially (48, 49, 50, 51, 52, 53). Since params are now sorted by `funcArgIndex` before allocation, input 0 (A) gets 48/49 and input 1 (B) gets 50/51 — matching the host's lock 0/1 and 2/3.

## Files Modified

| File | Changes |
|------|---------|
| `pass/passblueprinttoschedule/passblueprinttoschedule.cpp` | Added `traceToFuncArgIndex()`, `traceFlowConfigToFuncArgIndex()`. Moved `dirIdx` before tile loop. Lock IDs from `dirIdx` not `flowIndex`. |
| `pass/passblueprinttoschedulekernel/passblueprinttoschedulekernel.cpp` | Added `traceToFuncArgIndex()`, `funcArgIndex` field. Two-phase analyze: collect then sort-and-assign. Debug output. |

## Verification

```bash
cd src/mlir/mlirfront/tilinglinalg/pass/unitest/build
cmake .. && make -j4
./test dfschedule
```

Check `build/worklocal/host.cc`:
- `v1` (A) flow uses `acquire_lock_id=0, release_lock_id=1` and address 0x8040/0x8060
- `v2` (B) flow uses `acquire_lock_id=2, release_lock_id=3` and address 0x8000/0x8020

Check `build/worklocal/kernel.cc`:
- `LOCK_window_in_0_ACQ = 48` (= host lock 0) → `buf_in_ping_0` → receives A data
- `LOCK_window_in_1_ACQ = 50` (= host lock 2) → `buf_in_ping_1` → receives B data

Check stderr for `[HostParamMapping]` and `[KernelParamMapping]` debug lines.

Full HW verification: tile(0,3) kernel log should show A data pattern in `window_in_0` (A0 = [-3, -2, -1, 0, 1, 2, 3, ...]).

## Key Insight

The fundamental lesson: when host and kernel are compiled from separate clones of the same IR module, any ordering that depends on processing/walk order is fragile. Use SSA provenance (trace to function arguments) as the single source of truth for parameter identity.
