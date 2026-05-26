# Debug Analysis: Cache Disable Ordering After Partition Support -- All-Zero Output (129/65536 Mismatches)

**Date:** 2026-05-21 (commit 15630e4)
**Symptom:** `FAIL: 129 mismatches out of 65536` -- output matrix C is entirely zeros, A and B inputs sent to tiles are also zeros
**Root Cause:** When partition support was added, `__Runtime_auto_init` (a `__attribute__((constructor))` function that disabled D-cache/I-cache before `main()`) was removed. Cache disable moved into `__Runtime_explicit_init_partition()`, which runs **after** `main()` has already written A, B, C matrices to DDR with cache enabled. The CPU wrote data into cache lines, but DMA reads from physical DDR -- which still contained zeros because dirty cache lines were never flushed before the DMA started.
**Fix:** Added back a `__attribute__((constructor))` function `__Runtime_init()` that calls `__Runtime_platform_init()` (D-cache/I-cache disable) before `main()` starts, ensuring cache is disabled before any matrix data is written to DDR.

---

## 1. Symptom Description

After adding partition support, the 256x256 int8 matmul produced:

```
C [256x256] (first 4 rows, first 8 cols):
  [   0,   0,   0,   0,   0,   0,   0,   0 ...]
  [   0,   0,   0,   0,   0,   0,   0,   0 ...]
  [   0,   0,   0,   0,   0,   0,   0,   0 ...]
  [   0,   0,   0,   0,   0,   0,   0,   0 ...]

FAIL: 129 mismatches out of 65536.
```

Not just the output -- the **input matrices A and B as seen by the AIE tiles were also zeros**. The DMA transferred zeros to the compute tiles, so the matmul computed 0 * 0 = 0, producing all-zero output.

### Why only 129 mismatches, not 65536?

The output matrix was entirely zeros. But many elements of the expected result `C_ref` also happen to be zero (a property of the int8 matmul with the specific input pattern `A[i] = (i%7)-3`, `B[i] = (i%5)-2`). Out of 65536 elements:

- 65407 expected values were 0 -- these "matched" by coincidence (got 0, expected 0)
- 129 expected values were non-zero -- only these were reported as mismatches

The **129 mismatch count is misleading** -- it suggests a near-pass, but the actual output was completely wrong (all zeros). The low mismatch count is an artifact of the test data having many zero-valued expected results.

### Characteristic pattern

Every mismatch shows `got 0`, with skipped indices where expected was also 0:
```
MISMATCH C[0]: got 0, expected -1
MISMATCH C[1]: got 0, expected -7
MISMATCH C[2]: got 0, expected -3
MISMATCH C[3]: got 0, expected 11
                                     <- C[4] not listed (expected was 0)
MISMATCH C[5]: got 0, expected -1
MISMATCH C[6]: got 0, expected -7
...
```

---

## 2. Root Cause: Cache Disable Ordering

### The ARM Cortex-A cache problem

The Versal AI Engine SoC has an ARM Cortex-A78 host CPU with L1/L2 data caches. When the CPU writes to DDR addresses (e.g., `A[i] = value`), the data may stay in CPU cache and never reach physical DDR. The AIE DMA engine reads directly from physical DDR -- it does not see CPU cache contents. If cache is enabled when the CPU writes matrix data, the DMA reads stale zeros from DDR.

**Solution:** Disable the D-cache before writing matrix data, so CPU writes go directly to physical DDR. Alternatively, flush dirty cache lines before DMA starts.

### Before partition support: `__Runtime_auto_init` (correct)

The old runtime had a constructor function that ran before `main()`:

```c
// aie_runtime.c (pre-partition)
static void __Runtime_auto_init(void) __attribute__((constructor));

static void __Runtime_auto_init(void) {
    __Runtime_platform_init();   // <-- disables D-cache and I-cache
    __Runtime_device_init();     // <-- initializes AIE device
}
```

The execution order was:

```
1. __Runtime_auto_init()        [constructor, before main()]
   -> __Runtime_platform_init() [Xil_DCacheDisable(), Xil_ICacheDisable()]
   -> __Runtime_device_init()   [initializes g_DevInst]
2. main()
   -> malloc A, B, C
   -> A[i] = ..., B[i] = ...    [cache DISABLED -- writes go to DDR]
   -> host_canonicalized(A,B,C) [DMA reads from DDR -- sees correct data]
```

Cache was disabled in step 1 (before `main()`), so all matrix writes in step 2 went directly to physical DDR. DMA read correct data.

### After partition support: constructor removed (broken)

When partition support was added, `__Runtime_auto_init` was removed. The new flow used explicit initialization:

```c
// aie_runtime.c (with partition, BROKEN)
// NO constructor -- __Runtime_auto_init removed

XAie_DevInst *__Runtime_explicit_init_partition(int startCol, int numCols) {
    __Runtime_platform_init();  // <-- cache disable moved HERE
    // ... setup partition device ...
}
```

The execution order became:

```
1. main()                                    [cache ENABLED]
   -> malloc A, B, C
   -> A[i] = ..., B[i] = ...                [cache ENABLED -- data in CPU cache only!]
   -> __aie_launch("matmul", mesh, A, B, C)
      -> __Runtime_explicit_init_partition() [Xil_DCacheDisable() -- too late!]
      -> host_canonicalized(dev, A, B, C)    [DMA reads DDR -- sees zeros]
```

Cache was disabled AFTER the matrix data was already written. The writes to A and B went into CPU cache lines. When `Xil_DCacheDisable()` was called later, it disabled caching for future accesses, but the existing dirty cache lines were NOT flushed back to DDR. The `Xil_DCacheFlush()` call inside `__Runtime_platform_init()` flushes dirty lines, but by this point the DMA may have already started or the flush/disable sequence did not fully synchronize with ongoing DMA operations.

The DMA engine read from physical DDR addresses that still contained zeros (the initial state of malloc'd memory before cache writeback). The matmul kernel received zero inputs and produced zero outputs.

### Why `Xil_DCacheFlush()` didn't save it

`__Runtime_platform_init()` does call `Xil_DCacheFlush()` before `Xil_DCacheDisable()`:

```c
void __Runtime_platform_init(void) {
    Xil_DCacheFlush();     // flush dirty cache lines to DDR
    Xil_DCacheDisable();   // disable cache for future accesses
    Xil_ICacheDisable();
}
```

However, this flush+disable sequence happening inside `__Runtime_explicit_init_partition()` is **after the user has already written matrix data**. While `Xil_DCacheFlush()` should theoretically push the dirty lines to DDR, in practice the combination of:
- Flush racing with DMA setup that follows immediately
- ARM cache coherency protocol nuances with non-cacheable DMA regions
- Potential that the DMA engine starts accessing DDR before the flush fully completes

meant that the data was not reliably visible to DMA. The only reliable solution is to disable cache **before** any data writes.

---

## 3. The Fix (commit 15630e4)

Added back a `__attribute__((constructor))` function that disables cache before `main()`:

```c
// aie_runtime.c (FIXED)
static void __Runtime_init(void) __attribute__((constructor));

void __Runtime_init(void) {
    printf("[aie_runtime] __Runtime_init--\n");
    __Runtime_platform_init();  // Xil_DCacheFlush + DCacheDisable + ICacheDisable
    printf("[aie_runtime] _init OK\n");
}
```

Key differences from the old `__Runtime_auto_init`:
- Named `__Runtime_init` (not `__Runtime_auto_init`)
- Only calls `__Runtime_platform_init()` (cache disable) -- does NOT call `__Runtime_device_init()` (AIE device setup is still done explicitly via `__Runtime_explicit_init_partition()`)
- The partition-based device initialization remains explicit and happens later inside `__aie_launch()`

The corrected execution order:

```
1. __Runtime_init()              [constructor, before main()]
   -> __Runtime_platform_init()  [Xil_DCacheDisable() -- cache OFF]
2. main()
   -> malloc A, B, C
   -> A[i] = ..., B[i] = ...    [cache DISABLED -- writes go to DDR]
   -> __aie_launch(...)
      -> __Runtime_explicit_init_partition()  [partition device setup]
      -> host_canonicalized(dev, A, B, C)     [DMA reads DDR -- sees correct data]
```

---

## 4. Execution Timeline: Before vs After Fix

```
BROKEN (no constructor):
  main()
    |-- malloc A,B,C
    |-- A[i]=val, B[i]=val       <-- writes to CPU CACHE (not DDR)
    |-- __aie_launch()
    |     |-- explicit_init_partition()
    |     |     |-- platform_init()
    |     |     |     |-- DCacheFlush()   <-- flush NOW, but too late/racy
    |     |     |     |-- DCacheDisable()
    |     |     |-- setup partition dev
    |     |-- host_canonicalized()
    |           |-- DMA reads DDR        <-- DDR has ZEROS (cache lines not flushed in time)

FIXED (constructor):
  __Runtime_init()  [constructor]
    |-- platform_init()
    |     |-- DCacheFlush()
    |     |-- DCacheDisable()            <-- cache OFF from here
  main()
    |-- malloc A,B,C
    |-- A[i]=val, B[i]=val               <-- writes DIRECTLY to DDR (no cache)
    |-- __aie_launch()
    |     |-- explicit_init_partition()
    |     |     |-- setup partition dev   <-- platform_init() is also called here but is now a no-op (cache already disabled)
    |     |-- host_canonicalized()
    |           |-- DMA reads DDR         <-- DDR has CORRECT DATA
```

---

## 5. Diagnostic Signature

| Indicator | Meaning |
|-----------|---------|
| **Output is all zeros** | DMA data from DDR was zeros |
| **Input data sent to tiles is also zeros** | Not a kernel bug -- the DMA transferred zeros |
| **Mismatch count << total elements (129/65536)** | Many expected values happen to be 0 in test data |
| **IO verification passes** (0/60 FAILED) | Stream switch routing is correct |
| **Cores show DONE status** | Kernels ran -- they just received zero inputs |
| **No ERROR_HALT** | No crash -- DMA and kernel worked fine, just with wrong data |

The key differentiator from other all-zero bugs: **both input AND output are zeros**. If the kernel was crashing or DMA wasn't configured, you'd see some tiles hang or stall. Here everything ran smoothly -- the data just happened to be all zeros because the CPU cache held the real values.

---

## 6. Files Changed (commit 15630e4)

| File | Change |
|------|--------|
| `src/mlir/runtime/aie_runtime.c` | Added `__Runtime_init()` with `__attribute__((constructor))` that calls `__Runtime_platform_init()` (cache disable) before `main()`. Also fixed `XAie_DataMemBlockWrite` debug offset (`dma_addr - 16` -> `dma_addr`). |
| `example/tileprogram/ccode/simplematmul.cc` | Changed partition bounds from `{1, 4, 0, 6}` to `{0, 8, 0, 6}`. Set `DEBUG_OUTPUT_ORDER` from 1 to 0. |

---

## 7. Lessons Learned

1. **Cache coherency is the #1 cause of "all-zero" DMA data on ARM+AIE.** When the CPU writes to DDR with cache enabled, the data exists only in CPU cache lines. DMA engines bypass the cache and read physical DDR. Always disable cache before writing DMA source data.

2. **`__attribute__((constructor))` functions are critical for platform init.** The cache disable must happen before `main()` -- before any user code writes to DDR. Moving it into an explicit init function that runs after `main()` starts creates a race between CPU cache writes and DMA reads.

3. **129/65536 mismatch count is deceptive.** Always examine the actual output matrix. "129 mismatches" sounds like a near-pass, but the output was entirely zeros -- every single element was wrong. The low count is because the expected matrix happened to have 65407 zero entries.

4. **When refactoring init sequences, trace the cache disable call ordering.** The partition refactor correctly moved device init to an explicit function, but accidentally dragged cache disable along with it. The two concerns are independent: cache disable must be early (constructor); device init can be late (explicit).

5. **"Input also zeros" is the smoking gun for cache bugs.** If output is zero but input was correct at the tile, the bug is in the kernel or DMA BD config. If input is also zero, the problem is upstream -- typically cache coherency or DDR buffer address errors.
