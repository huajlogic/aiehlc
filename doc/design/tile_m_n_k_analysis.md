# Analysis: How tile_m/tile_n/tile_k Support Works

## Overview

This document traces how `tile_m`, `tile_n`, `tile_k` fields in `SpatialPolicy` flow through the entire aiehlc compilation pipeline — from user source to generated kernel/host C++ code — and what MLIR IR is impacted.

---

## 1. Where tile_m/tile_n/tile_k Are Defined (User Source)

**File**: `example/tileprogram/ccode/simplematmul2.cc`

```cpp
constexpr aie::SpatialPolicy RowBC = {
    .pattern = aie::Pattern::Broadcast,
    .distribution = aie::Layout::Row,
    .pp_depth = 2,
    .max_buffer_bytes = 4096,
    .tile_m = 64,    // explicit sub-tile rows
    .tile_n = 0,     // 0 = auto (uses tileCols)
    .tile_k = 64     // K chunk size
};
```

The struct definition (emitted by the compiler as a stub):
```cpp
struct SpatialPolicy {
  Pattern pattern; Layout distribution; Flow merge_order;
  int pp_depth = 2;
  int max_buffer_bytes = 4096;
  int tile_m = 0;   // fields 5,6,7 in Clang APValue
  int tile_n = 0;
  int tile_k = 0;
};
```

---

## 2. AST Extraction (aiehlc.cc)

**File**: `src/llvm/aiehlc.cc:1035-1051`

The Clang frontend extracts `tile_m/n/k` from the APValue struct literal:

```cpp
// Fields 5,6,7 of SpatialPolicy struct
if (apval->getStructNumFields() >= 6)
    pti.tileM = (int)apval->getStructField(5).getInt().getExtValue();
if (apval->getStructNumFields() >= 7)
    pti.tileN = (int)apval->getStructField(6).getInt().getExtValue();
if (apval->getStructNumFields() >= 8)
    pti.tileK = (int)apval->getStructField(7).getInt().getExtValue();
```

These are stored in `ParsedTensorInfo` (per-port) with fields `tileM`, `tileN`, `tileK`.

---

## 3. Derived Tiling Computation (aiehlc.cc:1090-1300)

**File**: `src/llvm/aiehlc.cc:1090-1300`

After AST extraction, the compiler computes derived tiling parameters:

### Input
- `macroDimM/N/K` = 256/256/256 (from GEMM launch args or macros M, N, K)
- `effectiveMeshRows/Cols` = 4/4
- `explicitTileM/N/K` = extracted from SpatialPolicy (64/0/64 for simplematmul2.cc)

### Computation Steps

1. **L1 spatial tiling** (always computed):
   ```
   tileRows = M / meshRows = 256/4 = 64
   tileCols = N / meshCols = 256/4 = 64
   kDim = K = 256
   ```

2. **L2 temporal tiling** (new -- tile_m/n/k):
   ```
   tileM_eff = explicitTileM > 0 ? explicitTileM : tileRows  -> 64
   tileN_eff = explicitTileN > 0 ? explicitTileN : tileCols   -> 64 (auto)
   tileK_eff = explicitTileK > 0 ? explicitTileK : K          -> 64
   ```

3. **Memory validation**: checks `A_local + B_local + C_local` fits in 48KB:
   ```
   A = tileM * tileK = 64*64 = 4096 bytes
   B = tileK * tileN = 64*64 = 4096 bytes
   C = tileM * tileN = 64*64 = 4096 bytes
   Total = 12288 bytes -- fits
   ```

4. **Auto-tiling** (when explicit=0 and working set exceeds budget):
   - Phase A: reduce K to fit A+B alongside fixed C
   - Phase B: if C alone exceeds budget, reduce M/N heuristically

5. **Round counts**:
   ```
   kRounds = K / tileK_eff = 256/64 = 4
   spatialMRounds = tileRows / tileM = 64/64 = 1
   spatialNRounds = tileCols / tileN = 64/64 = 1
   ```

### Output: `DerivedTilingParams` struct
**File**: `src/mlir/mlirfront/tilinglinalg/pass/tilinglinalg_pipeline.h:68-91`

```cpp
struct DerivedTilingParams {
    int64_t tileRows, tileCols, kDim;        // L1 spatial
    int64_t tileM, tileN, effectiveK;        // L2 temporal
    int64_t spatialMRounds, spatialNRounds;   // host re-launch rounds
    int64_t kRounds;                          // kernel K-accumulation rounds
    struct PortParams { int64_t numRounds, bufferSize; };
    std::vector<PortParams> portParams;       // per-port DMA params
};
```

---

## 4. Per-Port DMA Parameters (aiehlc.cc:1221-1282)

The DMA buffer sizes use `tileM_eff` / `tileN_eff` / `effectiveK` (NOT the full M/K/N):

| Port | Pattern | Buffer sizing |
|------|---------|---------------|
| A (input) | Broadcast+Row | `rowsPerRound = tileM_eff / ppDepth`, `bufferSize = rowsPerRound * effectiveK` |
| B (input) | Broadcast+Col | `colsPerRound = tileN_eff / ppDepth`, `bufferSize = colsPerRound * effectiveK` |
| C (output) | Gather | `outputPerCore = tileM_eff * tileN_eff`, `bufferSize = outputPerCore / ppDepth` |

For simplematmul2.cc with tile_m=64, tile_n=64, tile_k=64, pp_depth=2:
- A: numRounds=2, bufferSize=32*64=2048
- B: numRounds=2, bufferSize=32*64=2048
- C: numRounds=1 (pp_depth=1), bufferSize=4096

---

## 5. Kernel Body Rewriting (aiehlc.cc:2130-2192, 2424-2481)

**This is the key mechanism** -- the compiler does **string replacement** on the kernel body text, replacing `aie::get_*()` calls with integer literals:

```cpp
// Both single-kernel and multi-kernel paths do the same:
replaceSimpleCall("aie::get_tile_rows()", derivedTilingParams.tileRows);   // 64
replaceSimpleCall("aie::get_tile_cols()", derivedTilingParams.tileCols);   // 64
replaceSimpleCall("aie::get_k_dim()", derivedTilingParams.kDim);          // 256

// NEW two-level tiling functions:
replaceSimpleCall("aie::get_tile_m()", tileM > 0 ? tileM : tileRows);     // 64
replaceSimpleCall("aie::get_tile_n()", tileN > 0 ? tileN : tileCols);     // 64
replaceSimpleCall("aie::get_effective_k()", effectiveK > 0 ? effectiveK : kDim); // 64
replaceSimpleCall("aie::get_k_rounds()", kRounds);                        // 4
replaceSimpleCall("aie::get_spatial_m_rounds()", spatialMRounds);         // 1
replaceSimpleCall("aie::get_spatial_n_rounds()", spatialNRounds);         // 1

// Per-port functions (match by argument variable name):
// aie::get_num_rounds(win_a) -> portParams[0].numRounds = 2
// aie::get_buffer_size(win_a) -> portParams[0].bufferSize = 2048
```

After rewriting, the kernel body becomes the `computekernel.cc` file with all integer literals.

---

## 6. MLIR IR Impact

### Which dialects are affected?

The tile_m/tile_n/tile_k values affect the **tensor shapes** passed to `buildRoutingIR()`, which flow through all 6 dialects.

### Tensor shapes passed to routing IR

**File**: `src/llvm/aiehlc.cc:958-974` -- shapes use **full M/K/N**, not tile_m/tile_n/tile_k:
```cpp
// A: shape = {M, K} = {256, 256}
// B: shape = {K, N} = {256, 256}
// C: shape = {M, N} = {256, 256}
```

The MLIR pipeline does NOT see tile_m/tile_n/tile_k at all. The routing/dmap/dmaphop/dfscheblueprint/dfschedule passes work with the **full tensor shapes** and the L1 spatial tiling (mesh rows/cols). The L2 temporal tiling is handled entirely by:
1. The kernel body rewriting (string replacement, no MLIR)
2. The DMA buffer sizing (computed in aiehlc.cc, passed to MLIR via `maxPingPongBytes`)

### IR pass pipeline trace (unchanged by tile_m/n/k)

```
routing IR: createhwmesh(4,4) + createscheduletensor({256,256}, i8)
  | RoutingUnrollingLowerPass -- unrolls per-tile routing
  | RoutingToDmapPass -- creates dmap port/stream ops
  | DmapToDmaphopPass -- creates physical tile-to-tile hops
  | DmaphopTodfscheblueprintPass -- creates schedule blueprints
  | (clone)
  | Host: BlueprintToSchedulePass(maxPPBytes) -> ScheduleCanonicalizePass -> DfscheduleToApiPass -> EmitC -> host.cc
  | Kernel: BlueprintToScheduleKernelPass(maxPPBytes) -> DfscheduleToKernelApiPass -> EmitC -> kernel.cc
```

**What changes with tile_m/tile_n/tile_k**: The `maxPingPongBytes` parameter and the derived `BUF_SZ` values change. The `BlueprintToSchedulePass` uses `maxPingPongBytes` to determine ping-pong buffer allocation in the DMA BD configuration. With two-level tiling, buffers are sized for `tileM * effectiveK` instead of `tileRows * K`.

### Kernel IR impact

The kernel MLIR path (`DfscheduleToKernelApiPass`) emits:
```mlir
emitc.verbatim "#define BUF_SZ_IN_0 2048"   // was 4096 with single-level
emitc.verbatim "#define BUF_SZ_IN_1 2048"
emitc.verbatim "#define BUF_SZ_OUT_0 4096"
```

The buffer sizes in kernel.cc are determined by `BlueprintToScheduleKernelPass`, which reads the tensor shapes from the MLIR IR and the `maxPingPongBytes` module attribute.

### Host IR impact

The host path computes DMA BD lengths from the blueprint/schedule. With two-level tiling:
- BD transfer lengths = `tileM * effectiveK` (input A) instead of `tileRows * K`
- Number of BDs may change (more rounds, smaller transfers)
- Lock counts remain the same (ping-pong depth unchanged)

---

## 7. Generated Code Impact

### kernel.cc (generated by kernel MLIR path)

Buffer sizes change:
```cpp
// Single-level: BUF_SZ_IN_0 = tileRows * K / ppDepth = 64*256/2 = 8192
// Two-level:    BUF_SZ_IN_0 = tileM * effectiveK / ppDepth = 64*64/2 = 2048
```

The **kernel body** (from `computekernel.cc`) is the user's code with `aie::get_*()` replaced:
```cpp
// simplematmul2.cc kernel after rewriting:
const int tile_m = 64;            // aie::get_tile_m()
const int tile_n = 64;            // aie::get_tile_n()
const int eff_k = 64;             // aie::get_effective_k()
const int k_rounds = 4;           // aie::get_k_rounds()
const int num_a_rounds = 2;       // aie::get_num_rounds(win_a)
const int buf_sz_a = 2048;        // aie::get_buffer_size(win_a)
```

### host.cc (generated by host MLIR path + aiehlc.cc post-processing)

DMA BD configuration changes:
```cpp
// Single-level: XAie_DmaSetAddrLen(&bd, addr, tileRows * K)
// Two-level:    XAie_DmaSetAddrLen(&bd, addr, tileM * effectiveK)
```

The host also needs to handle `kRounds` -- each K-round sends a different slice of the A and B data. The host DMA must be configured to send `kRounds` batches.

### routing.cc (generated by routing MLIR path)

Routing is **unaffected** by tile_m/tile_n/tile_k. Stream switch configuration, packet routing, and port assignments depend only on the mesh topology and broadcast/gather patterns -- not on buffer sizes.

---

## 8. The "Stuck" Problem with simplematmul2.cc

### Why the ELF compilation hangs

The kernel body rewriting correctly replaces `aie::get_tile_m()` -> 64, etc. However, the MLIR pipeline that generates `kernel.cc` still uses the **old single-level** buffer sizes because `buildRoutingIR` receives the full tensor shapes {256,256} and the pipeline doesn't know about `effectiveK`.

The mismatch:
- Kernel body expects: `buf_sz_a = tileM * effectiveK / ppDepth = 2048`
- Kernel MLIR emits: `BUF_SZ_IN_0 = tileRows * K / ppDepth = 8192` (based on full tensor)

The kernel code tries to `acquire_input_window` for 2048 bytes but the hardware window is configured for 8192 bytes. This mismatch causes the lock protocol to deadlock -- the kernel releases after reading 2048 bytes, but the DMA expects to fill 8192 bytes before signaling.

### Where the fix is needed

The `maxPingPongBytes` parameter passed to `runPipeline()` and `BlueprintToSchedulePass` needs to reflect the two-level tiling buffer sizes. Currently:

```cpp
// aiehlc.cc line 2496-2498 (single-kernel path):
TilingLinalgPipeline::runPipeline(ctx, module, outputDir, kernelBodyWithMacros,
    singleKernelFuncName, parsedDebugLevel, userRewrittenSource, {},
    effectiveMaxPPBytes, aieGenStr);
```

The `effectiveMaxPPBytes` and the tensor shapes need to be consistent with the two-level tiling so that:
- `BUF_SZ_IN_0` in kernel.cc matches `buf_sz_a` in the rewritten kernel body
- BD lengths in host.cc match what the kernel expects
- Lock acquire/release sequences don't deadlock

---

## 9. Summary: Data Flow Diagram

```
User Source (.cc)
  +-- SpatialPolicy { tile_m=64, tile_n=0, tile_k=64 }
  +-- Kernel body: aie::get_tile_m(), aie::get_effective_k(), ...
       |
       v
Clang AST Extraction (aiehlc.cc:1035)
  +-- ParsedTensorInfo.tileM/N/K = 64/0/64
  +-- DerivedTilingParams computed (aiehlc.cc:1090)
       |
       +----------------------------------------------+
       v                                              v
  Kernel Body String Rewrite (aiehlc.cc:2424)    buildRoutingIR(shapes={256,256})
  |  aie::get_tile_m() -> "64"                         |
  |  aie::get_effective_k() -> "64"                    v
  |  aie::get_k_rounds() -> "4"                    MLIR Pipeline
  |  aie::get_num_rounds(win_a) -> "2"             (routing->dmap->dmaphop->blueprint)
  |  aie::get_buffer_size(win_a) -> "2048"              |
  |                                               +----+----+
  v                                               v         v
computekernel.cc                              host.cc   kernel.cc
(user kernel with                             (DMA BD   (BUF_SZ, window_init,
 integer literals)                             config)   lock macros)
  |                                               |         |
  +----- #include'd by kernel.cc -----------------+---------+
                                                      |
                                                      v
                                              xchesscc -> kernel ELF
                                              aarch64-g++ -> host ELF
```

**Key insight**: The MLIR pipeline and the kernel body rewriting are **two independent paths** that must agree on buffer sizes. Currently, the MLIR path doesn't receive the two-level tiling parameters -- it only sees full tensor shapes and `maxPingPongBytes`. This is the source of the mismatch that causes simplematmul2.cc to hang.

---

## 10. Difference: simplematmul.cc vs simplematmul2.cc

| Aspect | simplematmul.cc | simplematmul2.cc |
|--------|----------------|------------------|
| Tiling | Single-level (L1 spatial only) | Two-level (L1 spatial + L2 temporal) |
| SpatialPolicy | No tile_m/n/k fields | Uses .tile_m=64, .tile_n=64, .tile_k=64 |
| Kernel strategy | "Cache all A, stream B" -- stores all A rows | C-stationary with K-accumulation -- stores tile_m x eff_k chunk |
| K loop | None -- single pass | Outer k_rounds loop, accumulates partial sums |
| Output init | No init needed (write-only) | local_out[] zeroed before accumulation |
| Accumulation | Overwrites output each round | Reads local_out[], adds partial product, writes back |
| Output pp_depth | pp_depth = 2 | pp_depth = 1 (output written once) |
| Kernels | Two: matmul + mul2 | One: matmul only |
| Query APIs | get_tile_rows/cols, get_k_dim | get_tile_m/n, get_effective_k, get_k_rounds |
