# Shim Tile Output Assembly: Multi-Dimensional BD Solution

## 1. Problem Statement

### Context

In the TilingLinalg pipeline, the `BlueprintToSchedulePass` must generate shim-side DMA BD configurations to receive tiled output data from compute tiles and assemble it into a contiguous 2D result in DDR.

### Concrete Example

A 16x16 output matrix (int32, 1024 bytes total) is tiled into a 4x4 grid of tiles, each producing a 4x4 sub-block (16 elements = 64 bytes). Tiles transfer their output to the shim tile in this order:

- **Within each tile**: data arrives as 1D linear stream (row-major within the 4x4 block)
- **Tile order**: row-first left-to-right, then bottom-to-top

```
DDR output layout (16x16):
     col 0-3      col 4-7      col 8-11     col 12-15
    +-----------+-----------+-----------+-----------+
r0  | tile(0,3) | tile(1,3) | tile(2,3) | tile(3,3) |  tile_row=0
r3  |           |           |           |           |
    +-----------+-----------+-----------+-----------+
r4  | tile(0,4) | tile(1,4) | tile(2,4) | tile(3,4) |  tile_row=1
r7  |           |           |           |           |
    +-----------+-----------+-----------+-----------+
r8  | tile(0,5) | tile(1,5) | tile(2,5) | tile(3,5) |  tile_row=2
r11 |           |           |           |           |
    +-----------+-----------+-----------+-----------+
r12 | tile(0,6) | tile(1,6) | tile(2,6) | tile(3,6) |  tile_row=3
r15 |           |           |           |           |
    +-----------+-----------+-----------+-----------+
```

Each tile (e.g., tile(0,3)) produces 16 elements as a flat 1D stream:

```
Stream: [a0 a1 a2 a3 | a4 a5 a6 a7 | a8 a9 a10 a11 | a12 a13 a14 a15]
         ^^^ row 0      ^^^ row 1     ^^^ row 2       ^^^ row 3
```

These must be **scattered** into the correct 2D positions in the 16x16 DDR buffer:

```
row 0:  [a0  a1  a2  a3   ...  ...  ...  ...  ...  ...  ...  ...  ...  ...  ...  ... ]
row 1:  [a4  a5  a6  a7   ...  ...  ...  ...  ...  ...  ...  ...  ...  ...  ...  ... ]
row 2:  [a8  a9  a10 a11  ...  ...  ...  ...  ...  ...  ...  ...  ...  ...  ...  ... ]
row 3:  [a12 a13 a14 a15  ...  ...  ...  ...  ...  ...  ...  ...  ...  ...  ...  ... ]
```

### The BD Exhaustion Problem

**Naive approach**: one BD per tile, each doing a simple 1D transfer. This requires rearrangement via multiple BDs per tile:
- 4 BDs per tile (one per row of the 4x4 block) x 16 tiles = **64 BDs** for output
- Plus 2+ BDs for input
- **But a shim tile only has 16 BDs total**

Even with BD chaining and recycling, 16 tiles x 4 rows = 64 sequential BD configurations is impractical within hardware limits.

---

## 2. Hardware Capabilities: Multi-Dimensional DMA Addressing

### AIE-ML DMA BD Dimension Support by Tile Type

| Feature | Shim Tile | MemTile | AIE Tile |
|---------|-----------|---------|----------|
| Number of BDs | 16 | 48 | 16 |
| Multi-dim addressing (D0-D2) | 3 dims | 4 dims | 3 dims |
| Iteration dimension (D3) | Yes | Yes | Yes |
| Addressing granularity | 4 bytes (32-bit) | 4 bytes | 4 bytes |
| D0_StepSize | implicit 1 | configurable | implicit 1 |
| Iteration StepSize max | 8192 | 1048576 | 131072 |
| Iteration Wrap range | 1-64 | 1-64 | 1-64 |

Source: XAie driver `src/dma/xaie_dma.c`, register spec from AM020/AM027.

### Address Generation Model

The DMA hardware generates addresses as a nested loop. For a shim tile BD with 3 dimensions + iteration:

```
for iter = 0 .. Iteration_Wrap-1:            // D3 (outermost)
    for d2 = 0 .. D2_Wrap-1:                 // D2
        for d1 = 0 .. D1_Wrap-1:             // D1
            for d0 = 0 .. D0_Wrap-1:         // D0 (innermost, contiguous)
                addr = base_addr
                     + d0 * 1                // D0_StepSize = 1 (implicit)
                     + d1 * D1_StepSize
                     + d2 * D2_StepSize
                     + iter * Iter_StepSize
                transfer 4 bytes at addr
```

All stepsizes are in units of **4 bytes** (32-bit words). The total number of elements transferred = `D0_Wrap * D1_Wrap * D2_Wrap * Iteration_Wrap`.

### XAie API for Multi-Dimensional BD

```c
// Dimensions D0, D1, D2 (up to 3 for shim, up to 4 for memtile)
XAie_DmaDimDesc dimDescs[] = {
    {.AieMlDimDesc = {.StepSize = stepsize0, .Wrap = wrap0}},   // D0
    {.AieMlDimDesc = {.StepSize = stepsize1, .Wrap = wrap1}},   // D1
    {.AieMlDimDesc = {.StepSize = stepsize2, .Wrap = wrap2}},   // D2
};
XAie_DmaTensor tensor = {3, dimDescs};
XAie_DmaSetMultiDimAddr(&dmaInst, &tensor, base_addr, total_length_bytes);

// Iteration dimension (D3) — separate API
XAie_DmaSetBdIteration(&dmaInst, iterStepSize, iterWrap, iterCurrent);
```

Constraints (shim tile):
- `iterStepSize` <= 8192
- `iterWrap` range 1-64 (0 is invalid)
- `iterCurrent` <= 63

---

## 3. Solution: Single-BD Assembly Using 4D Addressing

### Key Insight

The 4 addressing dimensions (D0 + D1 + D2 + Iteration) map naturally to the 4 levels of the tiling pattern:

| Dimension | Maps To | Wrap | StepSize | Purpose |
|-----------|---------|------|----------|---------|
| **D0** (innermost) | Elements within one tile-row | `tile_width` | 1 (implicit) | 4 contiguous elements |
| **D1** | Rows within one tile | `tile_height` | `output_width` | Jump to next row in DDR buffer |
| **D2** | Tiles across columns | `num_tile_cols` | `tile_width` | Jump to next tile column |
| **Iteration/D3** (outermost) | Tile rows (vertical) | `num_tile_rows` | `tile_height * output_width` | Jump to next tile row band |

### Concrete Configuration: 16x16 Output, 4x4 Tiles

Parameters:
- `output_width` = 16 (elements per DDR row)
- `tile_width` = 4, `tile_height` = 4
- `num_tile_cols` = 4, `num_tile_rows` = 4
- Total elements = 256 (1024 bytes)

```c
// Single BD to assemble all 16 tiles' output into 16x16 DDR buffer
XAie_DmaDesc dmaInst;
XAie_DmaDescInit(&DevInst, &dmaInst, XAie_TileLoc(shim_col, 0));

// D0: 4 contiguous elements per tile-row (StepSize=1 implicit)
// D1: 4 rows per tile, jumping output_width=16 between rows
// D2: 4 tiles horizontally, jumping tile_width=4 between tile columns
XAie_DmaDimDesc dims[3] = {
    {.AieMlDimDesc = {.StepSize = 1,  .Wrap = 4}},   // D0: tile-row width
    {.AieMlDimDesc = {.StepSize = 16, .Wrap = 4}},   // D1: stride=output_width, 4 rows
    {.AieMlDimDesc = {.StepSize = 4,  .Wrap = 4}},   // D2: stride=tile_width, 4 cols
};
XAie_DmaTensor tensor = {3, dims};
XAie_DmaSetMultiDimAddr(&dmaInst, &tensor, ddr_out_addr, 256 * 4);

// Iteration (D3): 4 tile-rows vertically, stride = tile_height * output_width = 64
XAie_DmaSetBdIteration(&dmaInst, /*StepSize=*/64, /*Wrap=*/4, /*IterCurr=*/0);

// Lock, enable, write
XAie_DmaSetLock(&dmaInst,
    XAie_LockInit(acq_lock, acq_val),
    XAie_LockInit(rel_lock, rel_val));
XAie_DmaEnableBd(&dmaInst);
XAie_DmaWriteBd(&DevInst, &dmaInst, XAie_TileLoc(shim_col, 0), bd_id);
XAie_DmaChannelSetStartQueue(&DevInst, XAie_TileLoc(shim_col, 0),
    ch, DMA_S2MM, bd_id, 1, XAIE_DISABLE);
```

### Address Trace

The nested loop generates addresses that exactly place each tile's data in the correct DDR position:

```
iter=0 (tile_row=0, base offset +0):
  d2=0 (tile_col=0):                        d2=1 (tile_col=1):
    d1=0: addr +0,+1,+2,+3      (row0,c0-3)   d1=0: addr +4,+5,+6,+7      (row0,c4-7)
    d1=1: addr +16,+17,+18,+19  (row1,c0-3)   d1=1: addr +20,+21,+22,+23  (row1,c4-7)
    d1=2: addr +32,+33,+34,+35  (row2,c0-3)   d1=2: addr +36,+37,+38,+39  (row2,c4-7)
    d1=3: addr +48,+49,+50,+51  (row3,c0-3)   d1=3: addr +52,+53,+54,+55  (row3,c4-7)
  d2=2 (tile_col=2):                        d2=3 (tile_col=3):
    d1=0: addr +8..+11           (row0,c8-11)  d1=0: addr +12..+15          (row0,c12-15)
    ...                                         ...

iter=1 (tile_row=1, base offset +64):
  d2=0: rows 4-7, cols 0-3
  d2=1: rows 4-7, cols 4-7
  ...

iter=2 (tile_row=2, base offset +128): rows 8-11
iter=3 (tile_row=3, base offset +192): rows 12-15
```

Total: 4 x 4 x 4 x 4 = 256 elements = full 16x16 output. **One single BD.**

### Hardware Limit Validation

| Field | Value | Limit | Status |
|-------|-------|-------|--------|
| D0_StepSize | 1 (implicit) | - | OK |
| D0_Wrap | 4 | - | OK |
| D1_StepSize | 16 | - | OK |
| D1_Wrap | 4 | - | OK |
| D2_StepSize | 4 | - | OK |
| D2_Wrap | 4 | - | OK |
| Iter_StepSize | 64 | <= 8192 | OK |
| Iter_Wrap | 4 | 1-64 | OK |
| Buffer_Length | 1024 bytes | - | OK |

---

## 4. Critical Constraint: Data Arrival Order

The single-BD approach **requires** that tile output data arrives at the shim DMA channel in exactly the order dictated by the dimension nesting:

```
Required arrival order (matches D0 → D1 → D2 → Iteration):
  tile(0,3) → tile(1,3) → tile(2,3) → tile(3,3)    // tile_row 0, left-to-right
  tile(0,4) → tile(1,4) → tile(2,4) → tile(3,4)    // tile_row 1, left-to-right
  tile(0,5) → tile(1,5) → tile(2,5) → tile(3,5)    // tile_row 2, left-to-right
  tile(0,6) → tile(1,6) → tile(2,6) → tile(3,6)    // tile_row 3, left-to-right
```

This matches the document's description: "row from left to right order and tile from bottom to top order."

**If arrival order is guaranteed** (via packet-switched routing with ordered delivery, or circuit-switched time-division), the single-BD approach works directly.

**If arrival order cannot be guaranteed** (e.g., tiles finish at different times with non-deterministic arbitration), fall back to the per-tile BD approach (Section 5).

---

## 5. Fallback: One BD per Tile with 2D Addressing

If arrival order is not guaranteed, or if different tiles arrive on different DMA channels, use one BD per tile with 2D addressing:

```c
// For tile at grid position (tc, tr), tc=0..3, tr=0..3
// tc = tile column index, tr = tile row index
int base_offset = tr * tile_height * output_width + tc * tile_width;

XAie_DmaDesc dmaInst;
XAie_DmaDescInit(&DevInst, &dmaInst, XAie_TileLoc(shim_col, 0));

XAie_DmaDimDesc dims[2] = {
    {.AieMlDimDesc = {.StepSize = 1,  .Wrap = 4}},    // D0: 4 elements per tile-row
    {.AieMlDimDesc = {.StepSize = 16, .Wrap = 4}},    // D1: jump output_width, 4 rows
};
XAie_DmaTensor tensor = {2, dims};
XAie_DmaSetMultiDimAddr(&dmaInst, &tensor, ddr_out_addr + base_offset * 4, 16 * 4);

XAie_DmaSetLock(&dmaInst, ...);
XAie_DmaEnableBd(&dmaInst);
XAie_DmaWriteBd(&DevInst, &dmaInst, XAie_TileLoc(shim_col, 0), bd_id);
```

BD consumption: **1 BD per tile** (16 BDs for 16 tiles). This exactly fits the shim's 16-BD limit but leaves **0 BDs for input**, so input must use a different shim column or BD recycling.

---

## 6. Solution Comparison

| Approach | BDs for Output | BDs for Input | Total BDs | Fits 16-BD Limit? | Constraint |
|----------|---------------|---------------|-----------|-------------------|------------|
| Naive 1D (4 BDs/tile) | 64 | 2+ | 66+ | No | - |
| **4D single BD (D0+D1+D2+Iter)** | **1** | **15 available** | **1+** | **Yes** | Ordered arrival required |
| 2D per-tile BD (D0+D1) | 16 | 0 remaining | 16 | Barely | Input needs separate shim col |
| 2D per-tile + BD recycling | 2 (ping-pong) | 2 | 4 | Yes | Sequential tile processing, slower |

### Recommendation

**Use the 4D single-BD approach** (Section 3) as the primary strategy in `BlueprintToSchedulePass`. The tile arrival order is already deterministic in the current pipeline (packet-switched with ordered IDs, or circuit-switched with time-division scheduling from `DfscheduleToApiPass`).

This frees 15 BDs for input, ping-pong buffering, or other data movement, completely eliminating the BD exhaustion problem.

---

## 7. Generalized Formula

For an `M x N` output tiled into `tile_h x tile_w` blocks:

```
num_tile_cols = N / tile_w
num_tile_rows = M / tile_h

D0: StepSize = 1,                    Wrap = tile_w
D1: StepSize = N,                    Wrap = tile_h
D2: StepSize = tile_w,               Wrap = num_tile_cols
Iteration: StepSize = tile_h * N,    Wrap = num_tile_rows

Total elements = tile_w * tile_h * num_tile_cols * num_tile_rows = M * N
BDs used = 1
```

API calls:

```c
XAie_DmaDimDesc dims[3] = {
    {.AieMlDimDesc = {.StepSize = 1,      .Wrap = tile_w}},
    {.AieMlDimDesc = {.StepSize = N,      .Wrap = tile_h}},
    {.AieMlDimDesc = {.StepSize = tile_w, .Wrap = num_tile_cols}},
};
XAie_DmaTensor tensor = {3, dims};
XAie_DmaSetMultiDimAddr(&dmaInst, &tensor, base_addr, M * N * 4);
XAie_DmaSetBdIteration(&dmaInst, tile_h * N, num_tile_rows, 0);
```

### Scalability Limits (Shim Tile)

| Parameter | Max Value | Max Output Size (assuming tile_w=4) |
|-----------|-----------|-------------------------------------|
| Iter_StepSize | 8192 | output rows * cols < 8192 words => ~362x362 |
| Iter_Wrap | 64 | up to 64 tile-rows |
| D2_Wrap | hardware-dependent | up to hundreds of tile-cols |

For larger outputs exceeding `Iter_StepSize = 8192`, split across multiple shim columns or use MemTile (which supports `Iter_StepSize` up to 1048576).

---

## 8. References

- [AMD Versal AIE-ML Architecture Manual (AM020)](https://docs.amd.com/r/en-US/am020-versal-aie-ml) -- BD register fields, DMA dimension specs
- [AMD Ryzen AI NPU: Multi-Dimensional Shim DMA](https://www.hackster.io/ajoejose/amd-ryzen-ai-npu-multi-dimensional-shim-dma-9b8afd) -- Practical multi-dim shim DMA examples
- [AMD Ryzen AI NPU: Image Transpose using Multi-Dim DMA](https://www.hackster.io/ajoejose/amd-ryzen-ai-npu-image-transpose-using-multi-dim-dma-13b5b0) -- Transpose via multi-dim addressing
- XAie driver source: `thirdparty/alib/aie-rt/driver/src/dma/xaie_dma.c`
- Validation rules: `.cursor/skills/xaieapiverify/references/validation-rules.md`
- Existing multi-dim API: `src/mlir/runtime/aie_runtime.c:428` (`__Runtime_dma_bd_config_multidim`)
- Existing aieapi doc: `doc/aieapi.md` (Step 6, Advanced DMA BD Configuration)
