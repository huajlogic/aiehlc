---
name: partitionrelativecol
description: "[AIE ERROR] _XAie2PS_GetTTypefromLoc(): Invalid column: N" / "Invalid Tile Type ... TileType:4" when a partition does not start at column 0 -- XAie_TileLoc columns are partition-relative, not absolute
---

# Partition-relative columns in XAie_TileLoc

## Symptom

On a board run of an app whose mesh partition does not start at column 0
(e.g. conv2dstem, `device.partition({3, 6, 0, 6}, ...)` = columns 3..6):

```
[AIE ERROR] _XAie2PS_GetTTypefromLoc():49: Invalid column: 4
[AIE ERROR] _XAie_CoreProcessorBusConfig():1080: Invalid Tile Type, Col:4 Row:3 TileType:4
[aie_runtime] enable_core_proc_bus col=4 row=3 rc=5
... (cols 4,5,6 x rows 3..6)
```

TileType 4 is `XAIEGBL_TILE_TYPE_MAX` = "lookup failed", not a real tile type.

## Cause

`__Runtime_explicit_init_partition(startCol, numCols)` calls
`XAie_SetupPartitionConfig(dev, XAIE_BASE_ADDR + (startCol << XAIE_COL_SHIFT),
startCol, numCols)`. The partition's **BaseAddr already includes startCol**, so
every `XAie_TileLoc(col, row)` passed to the driver must be **relative**:
`0 .. NumCols-1`. aie-rt enforces it (`xaie_device_aie2ps.c:48`,
`if (Loc.Col >= DevInst->NumCols) Invalid column`).

`__Runtime_enable_core_proc_bus` looped `col = dev->StartCol .. StartCol+NumCols`
(absolute). For {3..6}, NumCols = 4: col 3 passed the check but addressed
relative col 3 = absolute col 6; cols 4..6 failed; absolute cols 3..5 were
never enabled. With StartCol == 0 (most examples) the two conventions coincide,
which is why it went unnoticed.

## Fix

`src/mlir/runtime/aie_runtime.c`: loop `for (col = 0; col < dev->NumCols; col++)`.

## Impact

- Without `#pragma KERNELCONFIGOFFLOAD` the proc bus is unused, so the errors are
  noise: the return code is ignored and the run continues. conv2dstem doesn't use
  that pragma.
- **With** KERNELCONFIGOFFLOAD and StartCol != 0, the cores in absolute columns
  StartCol..2*StartCol-1 (clipped to the partition) never get their proc bus
  enabled. Their self-programmed DMA/lock writes don't land, and the run hangs.

## Rule

Anything that iterates a partition's tiles and calls an `XAie_*` API iterates
`0 .. dev->NumCols-1`. `dev->StartCol` belongs only in `XAie_SetupPartitionConfig`
and in log messages that convert to absolute columns for a human.

## Rebuild

The runtime is compiled into each app archive. Rerun `aiehlc.sh`, or
`deploy_flow.py --aie-offload` (which rebuilds `layers/01_*/aie/`), then relink
`main.elf`.
