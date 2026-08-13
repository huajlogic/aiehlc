# Debug Analysis: C-Accumulate Data Incorrect — SHIM DMA BD Len and Channel Repeat Count

**Date:** 2026-05-27
**Symptom:** 129 output mismatches out of 65536; SHIM DMA advances by 4 bytes (1 word) between k-rounds instead of 64 bytes (16 words); kr=0 correct but kr=1,2,3 read wrong column positions
**Root Cause:** Two bugs in SHIM BD iteration config: (1) BD `len` was set to the full partition size instead of per-iteration size, (2) channel repeat count was `1` instead of `iter_wrap`. With `len=16384` and D0/D1 describing only a 4096-byte pattern, the DMA read beyond the defined pattern producing undefined addressing.
**Fix:** Divide SHIM BD `len` by `kRounds` for sender flows; set channel repeat count = `kRounds`.

---

## 1. Background: BD Iteration for K-Rounds

### 1.1 How SHIM BD Iteration Works

For K-tiled GEMM (e.g. 256x256, effectiveK=64, kRounds=4), each SHIM input BD uses iteration to advance through K chunks in DDR:

```
DDR partition layout (64 rows x 256 cols, row-major):
  ┌──────────┬──────────┬──────────┬──────────┐
  │ K-chunk 0│ K-chunk 1│ K-chunk 2│ K-chunk 3│
  │ cols 0-63│cols 64-127│cols128-191│cols192-255│
  │ 4096 B   │ 4096 B   │ 4096 B   │ 4096 B   │
  └──────────┴──────────┴──────────┴──────────┘
  offset:  0        64       128       192

BD iteration parameters:
  iter_step_size = 64 bytes (= effectiveK * elemBytes)
  iter_wrap      = 4 (= kRounds)

Each iteration: DMA reads 4096 bytes using D0/D1 strided pattern,
then advances base address by iter_step_size for next iteration.
```

### 1.2 XAie API Contract for BD Iteration

Per the Xilinx reference test `xaie_dmabd_iter.c`:

```c
// From .worktrees/matrix/aiemltest/aieml-tests/src/xaie_dmabd_iter.c

#define DMA_BD_ITERATION_STEP_SIZE  32
#define DMA_BD_ITERATION_WRAP       4
#define DMA_CHANNEL_REPEAT_COUNT    4   // = iter_wrap

// Rule 1: len = per-iteration transfer size (NOT total)
XAie_DmaSetAddrLen(&Tile_1_MM2S, addr, 128 * 4 / 8);  // per-iteration len

// Rule 2: iteration config
XAie_DmaSetBdIteration(&Tile_1_MM2S, 32, 4, 0);  // step=32, wrap=4

// Rule 3: channel repeat = iter_wrap
XAie_DmaChannelSetStartQueue(DevInst, Tile_1, 0, DMA_MM2S, 1,
        DMA_CHANNEL_REPEAT_COUNT, 0);  // repeat = 4
```

Two invariants:
1. **BD `len` = per-iteration transfer size**, not total across all iterations
2. **Channel repeat count = `iter_wrap`**, so the DMA re-fires the BD for each iteration

---

## 2. The Bug

### 2.1 Symptom: Wrong Column Advance Pattern

Kernel debug output for input A (row 0, 4 k-rounds):

```
Actual (buggy):
  kr=0: A0 = -3   (col 0)     correct
  kr=1: A0 =  1   (col 4)     WRONG — advanced 4 bytes, not 64
  kr=2: A0 = -2   (col 8)     WRONG
  kr=3: A0 =  2   (col 12)    WRONG

Expected (correct):
  kr=0: A0 = -3   (col 0)
  kr=1: A0 = -2   (col 64)    64-byte advance
  kr=2: A0 = -1   (col 128)   64-byte advance
  kr=3: A0 =  0   (col 192)   64-byte advance
```

### 2.2 Root Cause: Two Bugs in SHIM BD Config

**Bug A — BD len too large:**

```
WRONG:  len = 16384 (full 64x256 partition = all 4 k-rounds)
RIGHT:  len =  4096 (per k-round = 64x64 sub-block = 16384 / 4)
```

With `len=16384` and D0/D1 wraps describing only a 4096-byte access pattern, the DMA reads 4x more data than the D0/D1 pattern defines. The excess 12288 bytes are addressed with undefined behavior, producing the observed 4-byte column advance instead of 64-byte.

**Bug B — Channel repeat count wrong:**

```
WRONG:  repeat = 1 (BD fires once)
RIGHT:  repeat = 4 (BD fires kRounds times, once per iteration)
```

With `repeat=1`, the BD only fires once (kr=0). The DMA never re-executes the BD to advance to kr=1,2,3 via `iter_step_size`.

### 2.3 Why kr=0 Was Correct

The first iteration always reads from the original base address with the correct D0/D1 pattern. The bugs only manifest on subsequent iterations (kr=1,2,3) where the DMA must advance the base address and re-execute.

### 2.4 Why B0 Values Appeared Correct

B0 values showed no mismatches due to mathematical coincidence. The B matrix values satisfied `(4*n) mod 5 == (64*n) mod 5` for all n (since 60 is divisible by 5), masking the wrong column advance in B data.

---

## 3. Investigation Trace

### 3.1 Register Verification (Ruled Out HW Programming)

Checked the full code path from IR to register:

```
Module attrs: routing.effective_k=64, routing.full_k=256, routing.k_rounds=4

passblueprinttoschedule.cpp:
  iter_step_size = effectiveK * elemBytes = 64 * 1 = 64 bytes  ← correct

Generated IR (5_BlueprintToSchedulePass.mlir):
  len=16384, iter_step_size=64, iter_wrap=4  ← len is wrong

Generated host.cc:
  __Runtime_dma_bd_config_multidim_ooo(..., len=16384, ..., 64, 4)

aie_runtime.c:804:
  iterStepWords = 64 / 4 = 16  ← byte-to-word conversion correct

XAie register write:
  BdWord[6] = (16-1) | ((4-1) << 20) = 15 | (3<<20)  ← correct encoding

Register read-back:
  Iter(step=16, wrap=4, curr=1)  ← HW programmed correctly
```

The iteration step and wrap were programmed correctly in hardware. The problem was upstream: wrong BD `len` and wrong channel repeat count.

### 3.2 Key Insight: len vs D0/D1 Pattern Size

The D0/D1 multi-dimensional addressing describes how to access data within `len` bytes:

```
D0: stride=2, wrap=4    → 4 elements per inner loop
D1: stride=16, wrap=4   → 4 rows

Total pattern = 4 * 4 * (element_size) = 64 bytes per D0/D1 cycle
Total bytes described = pattern repeats to fill len

With len=4096:  pattern fits exactly (4096/64 = 64 repeats) ← correct
With len=16384: pattern repeats 256 times, last 192 repeats
                access addresses beyond the intended K-chunk ← BUG
```

---

## 4. The Fix

### 4.1 File Modified

`src/mlir/mlirfront/tilinglinalg/pass/passblueprinttoschedule/passblueprinttoschedule.cpp`

### 4.2 Change A: Divide BD len by kRounds (line ~697)

Before:
```cpp
int64_t perTileShimLen = shimBdLen;

// K-round note: do NOT divide perTileShimLen by kRounds here.
// The shim BD len must equal the full partition size (e.g. 64*256=16384).
// ...
```

After:
```cpp
int64_t perTileShimLen = shimBdLen;

// K-round iteration: when iter_wrap > 1, BD len must be the per-iteration
// transfer size, NOT the full partition size.
{
    auto moduleOp = op->getParentOfType<ModuleOp>();
    if (moduleOp) {
        auto kRoundsAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.k_rounds");
        if (kRoundsAttr && kRoundsAttr.getInt() > 1 && shimIsSender) {
            perTileShimLen = shimBdLen / kRoundsAttr.getInt();
        }
    }
}
```

### 4.3 Change B: Set channel repeat = kRounds for SHIM startio (line ~1508)

Before:
```cpp
int32_t repeatCount = useOOO ? (int32_t)(numCoreTiles * ooNumIterations) : 1;
```

After:
```cpp
int32_t repeatCount = 1;
if (useOOO) {
    repeatCount = (int32_t)(numCoreTiles * ooNumIterations);
} else if (shimIsSender) {
    auto moduleOp = op->getParentOfType<ModuleOp>();
    if (moduleOp) {
        auto kRoundsAttr = moduleOp->getAttrOfType<IntegerAttr>("routing.k_rounds");
        if (kRoundsAttr && kRoundsAttr.getInt() > 1)
            repeatCount = (int32_t)kRoundsAttr.getInt();
    }
}
```

### 4.4 No Change Needed in aie_runtime.c

The `/4` byte-to-word conversion at line 804 (`iterStepWords = iter_step_size / 4`) is correct per XAie API. The driver expects word-granularity step sizes.

---

## 5. Before/After Values

### 5.1 SHIM Input BD (256x256 GEMM, kRounds=4)

| Parameter | Before (Bug) | After (Fix) |
|-----------|-------------|-------------|
| BD `len` | 16384 (full partition) | 4096 (per iteration) |
| `iter_step_size` | 64 bytes | 64 bytes (unchanged) |
| `iter_wrap` | 4 | 4 (unchanged) |
| Channel `repeat` | 1 | 4 (= kRounds) |

### 5.2 Runtime API Calls

Before:
```c
XAie_DmaSetAddrLen(..., 16384);                          // too large
XAie_DmaSetBdIteration(..., 16, 4, 0);                   // correct
XAie_DmaChannelSetStartQueue(..., repeat=1, ...);         // fires once
```

After:
```c
XAie_DmaSetAddrLen(..., 4096);                           // per-iteration len
XAie_DmaSetBdIteration(..., 16, 4, 0);                   // unchanged
XAie_DmaChannelSetStartQueue(..., repeat=4, ...);         // fires 4 times
```

### 5.3 Data Correctness After Fix

```
kr=0: A0 = -3  (col 0)     base + 0*64
kr=1: A0 = -2  (col 64)    base + 1*64   64-byte advance
kr=2: A0 = -1  (col 128)   base + 2*64   64-byte advance
kr=3: A0 =  0  (col 192)   base + 3*64   64-byte advance

0 mismatches out of 65536
```

---

## 6. Diagnostic Checklist

When debugging BD iteration data correctness issues:

### 6.1 Verify BD len = per-iteration size

```bash
# In generated host.cc, find SHIM multidim BD configs:
grep "__Runtime_dma_bd_config_multidim" worklocal/host.cc

# The 5th parameter is len. It must equal:
#   partition_size / kRounds  (for sender SHIM with iteration)
#   e.g., 16384 / 4 = 4096
```

### 6.2 Verify channel repeat = iter_wrap

```bash
# In generated host.cc, find SHIM startio calls:
grep "__Runtime_startio" worklocal/host.cc

# The 4th parameter is repeat. For sender SHIMs with iteration:
#   repeat must equal kRounds (= iter_wrap)
```

### 6.3 Verify total data volume is preserved

```
total_bytes = len_per_iteration * repeat_count
            = 4096 * 4 = 16384
            = partition_rows * full_K * elem_bytes
            = 64 * 256 * 1 = 16384  ✓
```

### 6.4 Verify D0/D1 pattern fits within len

```
D0/D1 total pattern bytes must be <= len

If pattern_bytes < len:
  DMA repeats pattern to fill len — verify this is intended

If pattern_bytes > len:
  DMA truncates — data will be incomplete
```

### 6.5 Check kernel A0 debug values

If A0 values for kr>0 show unexpected column offsets, the SHIM iteration is likely misconfigured. The A0 value directly reveals which DDR column the DMA is reading from.

---

## 7. Verification

```bash
# Rebuild
cd src/mlir/mlirfront/tilinglinalg/pass/unitest/build && make -j4

# Regenerate host.cc/kernel.cc
./test dfschedule

# Verify generated code
grep "__Runtime_dma_bd_config_multidim" worklocal/host.cc  # len should be divided
grep "__Runtime_startio" worklocal/host.cc                  # repeat should be kRounds

# Full HW run
cd worklocal && source hostcompile.sh   # builds kernel + host
python3 script/test/apppaltest.py build/host
# Expected: 0 mismatches, "device_teardown done"
```

---

## 8. Lessons Learned

1. **BD `len` is per-iteration, not total.** When BD iteration is enabled (`iter_wrap > 1`), the XAie API expects `len` to be the transfer size for a single iteration. The DMA repeats the BD `iter_wrap` times via the channel repeat count. Setting `len` to the total size causes the DMA to read beyond the D0/D1 access pattern, producing undefined addressing.

2. **Channel repeat count must match iter_wrap.** Without the correct repeat count, the BD fires fewer times than intended. The DMA completes after one iteration, leaving subsequent k-rounds without data.

3. **D0/D1 pattern size and BD len must be consistent.** The D0/D1 multi-dimensional strides describe an access pattern within `len` bytes. If `len` exceeds the pattern, the DMA extends beyond the intended memory region. Always verify `D0_wrap * D1_wrap * element_size <= len`.

4. **kr=0 correctness does not validate the full pipeline.** The first iteration always reads from the correct base address. Iteration bugs only manifest on kr=1+ where `iter_step_size` advancement and repeat count come into play. Always check data across all k-rounds.

5. **Mathematical coincidences can mask bugs.** B matrix values appeared correct despite wrong column offsets because the value function was periodic with a period that divided both the wrong and correct strides. Use prime-sized test values or explicit column-index checks to avoid this trap.

6. **Register read-back can confirm HW programming but not semantic correctness.** The iteration step and wrap were correctly programmed in registers, but the BD `len` and channel repeat were wrong at a higher level. Correct register values do not guarantee correct DMA behavior if the BD parameters are semantically wrong.
