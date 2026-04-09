# ScheduleCanonicalizePass Redesign

## 1. What the Pass Does

The `ScheduleCanonicalizePass` transforms a **distributed** schedule IR (multiple `routing.RoutingCreate` regions, each containing per-tile dfschedule ops) into a **flat, canonical** schedule IR (a single `dfschedule.host` block at module level).

### Input (Stage 5 — BlueprintToSchedulePass output)

```
func.func @main() {
  scf.execute_region {
    routing.RoutingCreate<Memo = "row">(scf_idx = 0) {
      // Tile (2,0) — shim
      %tile_shim = dfschedule.declaretile {col=2, row=0}
      %bd_shim  = dfschedule.config.dma_bd(%buf, %tile_shim, %bd_id_0) {...}
      %io_shim  = dfschedule.config.create_io(%bd_shim, %tile_shim) {channel=0, dir="S2MM"}

      // Tile (0,3) — core, ping-pong pair
      %tile_core = dfschedule.declaretile {col=0, row=3}
      %pong = dfschedule.config.dma_bd(%buf2, %tile_core, %bd_id_1) {next_bd=0}
      %ping = dfschedule.config.dma_bd(%buf2, %tile_core, %bd_id_0, %pong) {next_bd=1}
      //                                                          ^^^^^ linked_bd operand
      %io_core = dfschedule.config.create_io(%ping, %tile_core) {channel=0, dir="MM2S"}
      //                                     ^^^^^ references PING bd_handle

      %start = dfschedule.schedule.start_io(%io_core, ...)
      %kernel = dfschedule.config.load_kernel_group(%tile_core) {...}
      %launch = dfschedule.schedule.launch_kernel_group(%kernel)
      dfschedule.schedule.wait(%launch, %start)
    }
    routing.RoutingCreate<Memo = "row">(scf_idx = 1) {
      // Same structure for tiles (0,4), (1,3), (1,4) — DUPLICATED
    }
  }
}
```

Key observations about the input:
- **Tiles are duplicated** across `RoutingCreate` regions (e.g., shim tile (2,0) appears in both)
- **Kernel groups are split** (each region has its own `load_kernel_group`)
- **SSA links are correct**: `create_io` operand directly references the BD handle it uses

### Output (Stage 6 — ScheduleCanonicalizePass output)

```
dfschedule.host @host_canonicalized {
  // Deduplicated data flow: declare_data -> partition -> slices -> tensors
  // Deduplicated tiles
  // Merged kernel group (all 4 core tiles in one load_kernel_group)
  // Deduplicated shim BDs/IOs
  // Core BDs with preserved ping-pong linked_bd relationships
  // Core IOs referencing correct BD handles
  // Single schedule.wait with all events
}
func.func @main() {
  dfschedule.launchhost @host_canonicalized
}
```

### Canonicalization tasks

| Task | Description |
|------|------------|
| **Tile dedup** | Merge duplicate `declaretile` ops for same (col, row) |
| **Tensor dedup** | Merge duplicate `declaretensor` / `extract_slice` chains |
| **Shim BD dedup** | Merge duplicate shim DMA BDs (same data_id + slice) |
| **Shim IO dedup** | Merge duplicate shim IOs (same channel + direction) |
| **Kernel merge** | Combine per-region `load_kernel_group` into one with all tiles |
| **Core BD preserve** | Recreate core BDs preserving ping-pong `linked_bd` + `next_bd` |
| **Core IO preserve** | Recreate core IOs referencing the correct BD handle |
| **Event merge** | Collect all events into one `schedule.wait` |
| **Restructure** | Move everything into `dfschedule.host`, remove old ops |

---

## 2. Current Implementation Problems

### Problem A: "Flatten-and-Rebuild" Anti-Pattern

The current implementation follows this flow:

```
Original IR (SSA graph) 
  → collectScheduleOps() — walk IR, store ops in flat lists
  → Extract scalar attributes into C++ structs (CoreDmaBdParams, CoreIoConfigParams)
  → DISCARD all SSA relationships
  → createCanonicalizedSchedule() — rebuild from structs using positional indices
```

This is fundamentally wrong because **MLIR's power is the SSA use-def graph**. The relationships between operations (which BD does this IO reference? which tile does this BD belong to?) are encoded as **SSA operands**, not as positional indices. By extracting attributes into plain structs and discarding the operands, the pass must reconstruct relationships using fragile heuristics.

### Problem B: Hardcoded Assumptions (5 instances)

#### B1. BD ID assignment by walk order (line 759)

```cpp
params.bdIndex = coreBdCounter[key]++;  // sequential counter
```

New BD IDs are assigned by the order operations are encountered during `walk()`. If `BlueprintToSchedulePass` emits pong (bd_id=1) before ping (bd_id=0), the counter assigns:
- Original BD(id=1) → new bdIndex=0
- Original BD(id=0) → new bdIndex=1

This swaps the ping and pong IDs.

#### B2. Ping-pong detection by count (line 1234)

```cpp
if (paramIndices.size() == 2) {
    // "pong is first, ping is second"
```

Uses BD count per tile as proxy for ping-pong. Does not check the `linked_bd` operand.

#### B3. Ping-pong ordering by position (line 1235-1237)

```cpp
Value pongHandle = createCoreBd(allCoreDmaBdParams[paramIndices[0]], ...);  // assumes [0]=pong
Value pingHandle = createCoreBd(allCoreDmaBdParams[paramIndices[1]], ...);  // assumes [1]=ping
```

Hardcodes that the first collected BD is pong and the second is ping.

#### B4. IO-to-BD mapping by sequential counter (line 808)

```cpp
params.bdIndex = coreIoCounter[key]++;
```

The IO's reference to its BD is a sequential counter, not traced from the original `create_io(%bd_handle)` SSA operand. The original operand link — which tells exactly which BD the IO should reference — is thrown away.

#### B5. IO-to-BD lookup by position (line 1256-1259)

```cpp
bdHandle = coreBdHandles[params.coreKey][params.bdIndex];
```

Picks BD by positional index into an array whose ordering depends on the hardcoded ping-pong assumption (B3).

### Problem C: Fragile Deduplication

Shim BD deduplication uses `(shimKey, data_id, sliceIndex)` as the merge key, and shim IO deduplication uses `(shimKey, channel, direction)`. These rely on scalar attribute comparison rather than SSA value identity.

---

## 3. New Design: SSA-Preserving Canonicalization

### Core Principle

**Never discard SSA relationships. Use `IRMapping` to remap values when restructuring.**

### Architecture

```
Phase 1: Analysis (read-only)
  ├── Identify dedup groups (tiles, tensors, BDs, IOs)
  ├── Detect ping-pong pairs via linked_bd SSA operand
  └── Build merge plan (which ops are duplicates of which)

Phase 2: Construction (write)
  ├── Create dfschedule.host block
  ├── Build IRMapping: old Value → new Value
  ├── Clone/remap operations using IRMapping
  └── Merge kernel groups

Phase 3: Cleanup (write)
  ├── Remove old ops (bottom-up, respecting use-def)
  └── Remove execute_region / routing scaffolding
```

### Phase 1: Analysis

#### 1a. Tile Deduplication

Group all `DeclareTileOp` by `(col, row)`. Pick one canonical representative per group:

```cpp
std::map<TileKey, Value> canonicalTile;  // (col,row) → representative tile Value

moduleOp.walk([&](dfschedule::DeclareTileOp op) {
    TileKey key = {op.getCol(), op.getRow()};
    if (canonicalTile.find(key) == canonicalTile.end()) {
        canonicalTile[key] = op.getTile();
    }
    // All tile values for same key will be remapped to the canonical one
});
```

#### 1b. Ping-Pong Detection via SSA

Instead of counting BDs per tile, check the `linked_bd` operand:

```cpp
struct PingPongPair {
    Value pingBd;   // the BD with linked_bd set
    Value pongBd;   // the BD referenced by linked_bd
    int64_t pingOriginalId;
    int64_t pongOriginalId;
};

std::map<TileKey, PingPongPair> pingPongPairs;

moduleOp.walk([&](dfschedule::ConfigDmaBdOp op) {
    if (Value linkedBd = op.getLinkedBd()) {
        // This op is the PING — it references a PONG via linked_bd
        TileKey key = getTileKey(op.getTile());
        PingPongPair pair;
        pair.pingBd = op.getBdHandle();
        pair.pongBd = linkedBd;
        pair.pingOriginalId = extractBdId(op);
        pair.pongOriginalId = extractBdId(linkedBd.getDefiningOp<ConfigDmaBdOp>());
        pingPongPairs[key] = pair;
    }
});
```

This is **order-independent** — it works no matter which BD was emitted first.

#### 1c. IO-to-BD Tracing via SSA

Directly read the `create_io`'s operand to know which BD it references:

```cpp
struct IoInfo {
    Value originalBdHandle;  // the BD handle this IO references
    int64_t originalBdId;    // the BD's bd_id
    int64_t channel;
    std::string direction;
    std::string ioOperation;
    TileKey tileKey;
};

std::vector<IoInfo> coreIoInfos;

moduleOp.walk([&](dfschedule::ConfigCreateIoOp op) {
    TileKey key = getTileKey(op.getTile());
    if (isShimTile(key)) return;

    IoInfo info;
    info.originalBdHandle = op.getBdConfig();  // SSA operand — the exact BD
    info.originalBdId = extractBdId(info.originalBdHandle);
    info.channel = op.getChannel();
    info.direction = op.getDirection().str();
    info.ioOperation = op.getIoOperation().str();
    info.tileKey = key;
    coreIoInfos.push_back(info);
});
```

No counters, no positional guessing.

### Phase 2: Construction with IRMapping

Use MLIR's `IRMapping` to track old→new value correspondence:

```cpp
IRMapping mapping;

// 2a. Create canonical tiles in dfschedule.host
std::map<TileKey, Value> newTileMap;
for (auto &[key, oldTileVal] : canonicalTile) {
    auto newTile = builder.create<dfschedule::DeclareTileOp>(loc, ...);
    newTileMap[key] = newTile.getTile();
    // Map ALL old tile values for this key to the new one
    for (Value oldVal : allTileValuesForKey[key]) {
        mapping.map(oldVal, newTile.getTile());
    }
}

// 2b. Create tensors/buffers, map old → new
for (...) {
    auto newTensor = builder.create<dfschedule::DeclareTensorOp>(loc, ...);
    mapping.map(oldTensorVal, newTensor.getResult());
}

// 2c. Create core BDs — use IRMapping for tile + buffer, use SSA for ping-pong
std::map<TileKey, std::map<int64_t, Value>> newBdByOriginalId;

for (auto &[key, pair] : pingPongPairs) {
    Value coreTile = newTileMap[key];

    // Remap buffer via IRMapping
    Value newBuffer = mapping.lookup(oldPongBuffer);

    // Create pong first (no linked_bd)
    Value pongHandle = createBd(builder, newBuffer, coreTile,
                                pair.pongOriginalId, ...);  // preserve original bd_id
    newBdByOriginalId[key][pair.pongOriginalId] = pongHandle;

    // Create ping (linked_bd = pong) — preserves original bd_id
    Value pingHandle = createBd(builder, newBuffer, coreTile,
                                pair.pingOriginalId, ..., pongHandle);
    newBdByOriginalId[key][pair.pingOriginalId] = pingHandle;
}

// 2d. Create core IOs — look up BD by ORIGINAL bd_id (traced from SSA in Phase 1)
for (auto &ioInfo : coreIoInfos) {
    Value bdHandle = newBdByOriginalId[ioInfo.tileKey][ioInfo.originalBdId];
    //                                                 ^^^^^^^^^^^^^^^^
    //                 Traced from create_io's SSA operand, not a counter!
    builder.create<dfschedule::ConfigCreateIoOp>(
        loc, ..., bdHandle, newTileMap[ioInfo.tileKey], ...);
}
```

### Phase 3: Cleanup

Same as current — remove old ops bottom-up, erase `scf.execute_region`.

---

## 4. Comparison: Current vs New

| Aspect | Current (Broken) | New (SSA-Preserving) |
|--------|-----------------|---------------------|
| **BD-to-IO link** | Sequential counter (`bdIndex++`) | Trace `create_io.getBdConfig()` SSA operand |
| **Ping-pong detect** | `paramIndices.size() == 2` | Check `op.getLinkedBd()` SSA operand |
| **Ping vs pong** | `paramIndices[0]` = pong (hardcoded) | BD with `linked_bd` = ping (SSA-based) |
| **BD ID assignment** | `coreBdCounter[key]++` (walk order) | Preserve `originalBdId` from input IR |
| **Value remapping** | Manual positional arrays | `IRMapping` (MLIR standard) |
| **Order dependency** | Breaks if emission order changes | Order-independent by design |
| **Correctness** | Correct only if BlueprintToSchedulePass emits pong before ping | Correct for any input ordering |

---

## 5. Implementation Checklist

### Step 1: Add `hasLinkedBd` and `originalBdId` to structs

```cpp
struct CoreDmaBdParams {
    // ... existing fields ...
    bool hasLinkedBd = false;      // true if this BD has a linked_bd operand
    int64_t originalBdId = -1;     // BD ID from original IR
};

struct CoreIoConfigParams {
    // ... existing fields ...
    int64_t originalBdId = 0;      // BD ID traced from create_io's bd_config operand
};
```

### Step 2: Fix BD collection — preserve original BD ID

```cpp
// BEFORE (line 759):
params.bdIndex = coreBdCounter[key]++;

// AFTER:
Value bdIdValue = dmaBd.getBdId();
if (auto constOp = bdIdValue.getDefiningOp<arith::ConstantOp>()) {
    params.originalBdId = cast<IntegerAttr>(constOp.getValue()).getInt();
}
params.bdIndex = params.originalBdId;  // new BD ID = original BD ID
params.hasLinkedBd = (dmaBd.getLinkedBd() != Value());
```

### Step 3: Fix IO collection — trace SSA operand

```cpp
// BEFORE (line 808):
params.bdIndex = coreIoCounter[key]++;

// AFTER:
Value bdConfig = createIo.getBdConfig();
if (auto dmaBd = bdConfig.getDefiningOp<dfschedule::ConfigDmaBdOp>()) {
    Value bdIdVal = dmaBd.getBdId();
    if (auto constOp = bdIdVal.getDefiningOp<arith::ConstantOp>()) {
        params.originalBdId = cast<IntegerAttr>(constOp.getValue()).getInt();
    }
}
```

### Step 4: Fix BD creation — detect ping/pong by `hasLinkedBd`

```cpp
// BEFORE (line 1234-1240):
if (paramIndices.size() == 2) {
    Value pongHandle = createCoreBd(allCoreDmaBdParams[paramIndices[0]], coreTile, Value());
    Value pingHandle = createCoreBd(allCoreDmaBdParams[paramIndices[1]], coreTile, pongHandle);
    coreBdHandles[tileKey].push_back(pingHandle);
    coreBdHandles[tileKey].push_back(pongHandle);
}

// AFTER:
if (paramIndices.size() == 2) {
    size_t pingIdx, pongIdx;
    if (allCoreDmaBdParams[paramIndices[0]].hasLinkedBd) {
        pingIdx = paramIndices[0];
        pongIdx = paramIndices[1];
    } else {
        pongIdx = paramIndices[0];
        pingIdx = paramIndices[1];
    }
    Value pongHandle = createCoreBd(allCoreDmaBdParams[pongIdx], coreTile, Value());
    Value pingHandle = createCoreBd(allCoreDmaBdParams[pingIdx], coreTile, pongHandle);
    // Map by original BD ID, not position
    coreBdHandleMap[tileKey][allCoreDmaBdParams[pingIdx].originalBdId] = pingHandle;
    coreBdHandleMap[tileKey][allCoreDmaBdParams[pongIdx].originalBdId] = pongHandle;
}
```

### Step 5: Fix IO creation — look up BD by original ID

```cpp
// BEFORE (line 1255-1259):
if (params.bdIndex < (int)coreBdHandles[params.coreKey].size()) {
    bdHandle = coreBdHandles[params.coreKey][params.bdIndex];
}

// AFTER:
auto &bdMap = coreBdHandleMap[params.coreKey];
auto it = bdMap.find(params.originalBdId);
if (it != bdMap.end()) {
    bdHandle = it->second;
} else if (!bdMap.empty()) {
    bdHandle = bdMap.begin()->second;  // fallback
}
```

### Step 6: Remove next_bd remapping block

Since `bdIndex = originalBdId` (BD IDs are preserved), the old-to-new remapping (lines 1220-1232) becomes a no-op. It can be removed or kept as a safety check.

---

## 6. Long-Term Recommendation

The step-by-step fixes above address the immediate bugs while keeping the current "extract-and-rebuild" architecture. For long-term maintainability, the pass should be refactored to use `IRMapping`-based cloning:

1. **Phase 1**: Walk input IR, build dedup groups and `IRMapping` entries
2. **Phase 2**: Clone ops from input into `dfschedule.host` using `builder.clone(*op, mapping)` — all operands are automatically remapped
3. **Phase 3**: Remove old ops

This eliminates all intermediate structs (`CoreDmaBdParams`, `CoreIoConfigParams`, etc.) and makes the pass ~60% shorter while being correct by construction.
