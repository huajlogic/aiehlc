# Gap Analysis: tile_m=64, tile_n=64, tile_k=64 on simplematmul2.cc

## Scenario

- Source: `example/tileprogram/ccode/simplematmul2.cc`
- M=N=K=256, HW_ROWS=HW_COLS=4
- Change all three SpatialPolicy structs (RowBC, ColBC, LtoR_Merge) to set `tile_m=64, tile_n=64, tile_k=64`

### Derived Parameters (from aiehlc.cc:1094-1219)

| Parameter | Value | Derivation |
|-----------|-------|------------|
| tileRows | 64 | M/HW_ROWS = 256/4 |
| tileCols | 64 | N/HW_COLS = 256/4 |
| kDim | 256 | full K |
| tileM_eff | 64 | = tileRows (no spatial sub-tiling) |
| tileN_eff | 64 | = tileCols (no spatial sub-tiling) |
| effectiveK | 64 | tile_k from SpatialPolicy |
| kRounds | 4 | kDim/effectiveK = 256/64 |
| spatialMRounds | 1 | tileRows/tileM_eff = 64/64 |
| spatialNRounds | 1 | tileCols/tileN_eff = 64/64 |

Memory per tile: A_local=64×64=4KB, B_local=64×64=4KB, C_local=64×64=4KB → **12KB** (fits in 48KB)

---

## Gap #1: Kernel matmul logic MUST change

### Problem

The kernel uses `aie::get_k_dim()` which is replaced with **full K=256** (not effectiveK=64).

**Evidence** — `aiehlc.cc:2183` and `aiehlc.cc:2475`:
```cpp
replaceSimpleCall("aie::get_k_dim()", mkd.derivedParams.kDim);  // kDim = 256
```

The kernel (simplematmul2.cc:41-49):
```cpp
const int tile_rows = aie::get_tile_rows();   // → 64
const int tile_cols = aie::get_tile_cols();    // → 64
const int k_dim     = aie::get_k_dim();        // → 256 (FULL K, not 64!)
```

This causes:
1. `all_A[tile_rows * k_dim]` = `all_A[64*256]` = **16KB** — defeats memory savings
2. Inner loop `for (k=0; k<k_dim; k++)` runs 256 iterations but only 64 elements arrive per k-round
3. **No k_rounds concept** — the "cache all A, stream B" algorithm has no outer K-accumulation loop

### What the kernel needs

Replace the single-pass algorithm with a k-rounds accumulation loop:
```cpp
const int tile_m = aie::get_tile_m();       // 64
const int tile_n = aie::get_tile_n();       // 64
const int eff_k  = aie::get_effective_k();  // 64
const int k_rnds = aie::get_k_rounds();    // 4

int8_t local_A[tile_m * eff_k];              // 4KB
int16_t accum_C[tile_m * tile_n];            // 8KB (int16 for accumulation)
memset(accum_C, 0, sizeof(accum_C));

for (int kr = 0; kr < k_rnds; kr++) {
    // Receive A chunk [tile_m × eff_k] for this k-round
    // Receive B chunk [tile_n × eff_k] for this k-round
    // Accumulate partial products into accum_C
}
// Saturate int16→int8 and output
```

**Severity: BLOCKING** — kernel will produce wrong results without this change.

---

## Gap #2: Shim MM2S DMA needs 2D addressing for inputs

### Problem

With tile_k=64 and K=256, each DMA transfer for matrix A needs a sub-block of 64 columns from a 256-wide DDR row. These are **non-contiguous**.

DDR layout for A (row-major, stride=K=256):
```
Row 0: [a(0,0)..a(0,63) | a(0,64)..a(0,127) | a(0,128)..a(0,191) | a(0,192)..a(0,255)]
Row 1: [a(1,0)..a(1,63) | a(1,64)..a(1,127) | ... ]
```

For k-round 0, the shim needs to read: `a(0,0..63), a(1,0..63), ..., a(31,0..63)` — 32 rows × 64 bytes each, but separated by 256-byte strides.

### Where the stride logic lives (corrected)

The multi-dim DMA addressing flows through **three passes**:

| Pass | Dialect | Role |
|------|---------|------|
| **DmaphopTodfscheblueprintPass** (`passdmaphoptodfscheblueprint.cpp`) | dfscheblueprint | **Computes** stride/wrap values, stores as `shim_dim_strides`/`shim_dim_wraps` on `dfscheblueprint.flowconfig` ops |
| **BlueprintToSchedulePass** (`passblueprinttoschedule.cpp`) | dfschedule | **Propagates** stride/wrap from flowconfig → `dfschedule.ConfigDmaBdOp` as `dim_strides`/`dim_wraps` |
| **DfscheduleToApiPass** (`passdfscheduletoapi.cpp`) | emitc | **Emits** `__Runtime_dma_bd_config_multidim` or `_multidim_ooo` C API calls |

The stride/wrap **computation** happens in `passdmaphoptodfscheblueprint.cpp`. The dfscheblueprint dialect carries the attributes. The dfschedule dialect consumes them.

### Current state

At `passdmaphoptodfscheblueprint.cpp:822` (PushOpConversion for inputs):
```cpp
nullptr,  // shim_dim_strides (input scatter: contiguous DDR, no multi-dim needed)
nullptr,  // shim_dim_wraps
```

The 3D addressing logic exists **only for output S2MM** (lines 1106-1170):
```cpp
// 3D addressing for shim S2MM output assembly:
// D0: contiguous within tile row (wrap=tileW, stride=1)
// D1: next row in DDR (wrap=stripH, stride=outW)
// D2: next tile column (wrap=numTileCols, stride=tileW)
```

### What needs to be added

For input MM2S when tile_k < K, add 2D addressing in PushOpConversion:
```
D0: wrap = effectiveK / elemsPerWord    stride = 1 word         (contiguous within K-chunk)
D1: wrap = rowsPerRound                 stride = K / elemsPerWord (full DDR row width)
```
Plus DDR offset = kr * effectiveK bytes for each k-round.

**Severity: BLOCKING** — shim will read wrong DDR locations.

---

## Gap #3: Routing IR tensor shapes don't reflect effectiveK

### Problem

Tensor shapes passed to the routing pipeline are always full macro dimensions.

At `aiehlc.cc:1070`:
```cpp
pti.shape = {macroDimM, macroDimK};  // {256, 256}, never {256, 64}
```

At `aiehlc.cc:1318-1319`, these shapes flow into `TensorParam` for `buildRoutingIR`:
```cpp
mkd.tensors.push_back({pt.shape, pt.elementBitWidth, pt.isInput});
```

The routing IR then creates partition slices like `tensor<64x256xi8>` per tile row for A (64 rows × full 256 K). With tile_k=64, each DMA round should only deal with `tensor<64x64xi8>`.

### Design decision

Two approaches:
1. **Change routing IR shapes** to use {M, effectiveK} — invasive, affects all downstream passes
2. **Keep full shapes, add 2D DMA striding** — surgical, only modify DmaphopTodfscheblueprintPass

**Recommended: Approach 2** — the routing IR models spatial data distribution correctly. K-tiling is temporal (within a single core), not spatial. The stride logic handles the DDR layout.

---

## Gap #4: B matrix has the same 2D addressing gap

B is stored as B^T[N × K] row-major. For column broadcast, each column of tiles gets rows [col×64..(col+1)×64-1] of B.

With tile_k=64, k-round 0 needs columns 0-63 of those B rows — same non-contiguous pattern as A. Same fix needed in `passdmaphoptodfscheblueprint.cpp` PushOpConversion.

---

## Gap #5: DMA round count doesn't account for kRounds

### Problem

At `aiehlc.cc:1233-1241`, for input A:
```cpp
pp.numRounds = tileM_eff / rowsPerRound;  // 64/32 = 2 (for ONE k-round)
pp.bufferSize = rowsPerRound * dmaK;       // 32*64 = 2048
```

This computes rounds for **one k-round only**. With kRounds=4, the total should be 2×4=8 rounds (or the pipeline needs to loop the shim DMA 4 times).

### Where this affects

The routing pipeline generates one set of FlowTransferOps per tensor. There's no loop or repetition mechanism to re-execute the shim DMA for each k-round. Either:
- `numRounds` should be multiplied by `kRounds`, OR
- The pipeline needs a new concept of k-round repetition

**Severity: BLOCKING** — only 1/4 of the data would be sent.

---

## Gap #6: No k-round orchestration mechanism

### Problem

Currently there is no mechanism to:
1. Tell the host DMA to advance the DDR offset by `effectiveK` bytes between k-rounds
2. Synchronize k-round transitions between A and B streams
3. Ensure kernel receives A-chunk-k0, B-chunk-k0 (compute), then A-chunk-k1, B-chunk-k1, etc.

This is fundamentally new scheduling logic that doesn't exist in the pipeline.

**Severity: BLOCKING** — data ordering would be wrong.

---

## Summary

| # | Component | File(s) | Gap | Severity |
|---|-----------|---------|-----|----------|
| 1 | Kernel | `simplematmul2.cc` | No k_rounds loop; uses `get_k_dim()`=256 | BLOCKING |
| 2 | Shim MM2S DMA (A) | `passdmaphoptodfscheblueprint.cpp` | No 2D stride for input when tile_k < K | BLOCKING |
| 3 | Routing IR shapes | `aiehlc.cc` | Shapes = {M,K} not {M,effectiveK} | Design decision |
| 4 | Shim MM2S DMA (B) | `passdmaphoptodfscheblueprint.cpp` | Same as #2 for B matrix | BLOCKING |
| 5 | DMA rounds | `aiehlc.cc` | numRounds doesn't multiply by kRounds | BLOCKING |
| 6 | k-round orchestration | `passblueprinttoschedule.cpp` | No mechanism to loop shim DMA over k-rounds | BLOCKING |

## Confidence: 90%

- **95%+ confident** on gaps #1, #2, #4: directly confirmed in code — kernel uses `get_k_dim()` (full K), input DMA passes `nullptr` for stride/wrap
- **90% confident** on gap #5: round computation at aiehlc.cc:1240 clearly shows `tileM_eff / rowsPerRound` without kRounds factor
- **80% confident** on gap #6: the routing pipeline generates one set of flows per tensor; I see no loop mechanism, but there might be an iteration feature I haven't fully traced (the OOO iter_step/iter_wrap exists for outputs but is not used for inputs)
