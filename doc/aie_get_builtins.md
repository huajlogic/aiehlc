# aie::get_*() Built-in Query Functions

## Overview

The `aie::get_num_rounds()`, `aie::get_buffer_size()`, `aie::get_tile_rows()`, `aie::get_tile_cols()`, and `aie::get_k_dim()` functions are **compile-time built-in queries**. They appear as normal C++ function calls in the kernel source, but the `aiehlc` compiler replaces them with integer literals before the kernel is compiled. No runtime query occurs — the values are baked into the kernel binary.

## API Reference

| Function | Arguments | Returns |
|----------|-----------|---------|
| `aie::get_num_rounds(win)` | A port parameter (e.g. `win_a`) | Number of DMA input/output rounds for that port |
| `aie::get_buffer_size(win)` | A port parameter | Elements transferred per round |
| `aie::get_tile_rows()` | None | Output rows per tile (`M / HW_ROWS`) |
| `aie::get_tile_cols()` | None | Output cols per tile (`N / HW_COLS`) |
| `aie::get_k_dim()` | None | Inner product dimension `K` |

## Example Usage

```cpp
__global__ void matmul(aie::port<input_window_int8 *, RowBC> win_a,
                       aie::port<input_window_int8 *, ColBC> win_b,
                       aie::port<output_window_int8 *, LtoR_Merge> win_c) {

    const int num_a_rounds = aie::get_num_rounds(win_a);  // replaced with e.g. "4"
    const int buf_sz_a     = aie::get_buffer_size(win_a);  // replaced with e.g. "4096"
    const int tile_rows    = aie::get_tile_rows();          // replaced with e.g. "64"
    // ...
}
```

After compilation, the kernel binary contains literal constants (e.g. `4`, `4096`, `64`) — no function call overhead or runtime lookup.

## How It Works: Three-Stage Pipeline

### Stage 1: Stub Declarations for Clang Parsing

The compiler injects a synthetic `aie` namespace header so Clang can parse the kernel code without errors. These stubs always return 0 — their return values are never used:

```cpp
// Injected by aiehlc (src/llvm/aiehlc.cc ~line 1579)
namespace aie {
    template<typename T> constexpr int get_num_rounds(T) { return 0; }
    template<typename T> constexpr int get_buffer_size(T) { return 0; }
    constexpr int get_tile_rows() { return 0; }
    constexpr int get_tile_cols() { return 0; }
    constexpr int get_k_dim() { return 0; }
}
```

The stubs exist solely for type-checking and AST construction. The actual values are computed in Stage 2 and substituted in Stage 3.

### Stage 2: AST Extraction — Compute Derived Parameters

When the compiler encounters the kernel launch site (e.g. `matmul<<<mesh>>>(A, B, C, M, N, K)`), it extracts three categories of information from the Clang AST:

1. **GEMM dimensions**: `M`, `K`, `N` from `#define` macros or launch arguments
2. **Mesh dimensions**: `HW_ROWS`, `HW_COLS` from the `aieDim mesh(...)` constructor
3. **Per-port SpatialPolicy**: `pattern`, `distribution`, `pp_depth`, `max_buffer_bytes` from each `constexpr aie::SpatialPolicy` struct attached to the port

These are combined to compute `DerivedTilingParams` (defined at `aiehlc.cc:63`):

```cpp
struct DerivedTilingParams {
    int64_t tileRows;    // M / HW_ROWS
    int64_t tileCols;    // N / HW_COLS
    int64_t kDim;        // K
    struct PortParams {
        int64_t numRounds;
        int64_t bufferSize;  // elements per round
    };
    std::vector<PortParams> portParams;  // one per kernel parameter
};
```

#### Calculation Rules by Port Type

The formula differs based on the port's `SpatialPolicy`:

**Input A (Broadcast + Row)** — data is `tileRows × K` per tile:

```
rowsPerRound = tileRows / pp_depth
if (rowsPerRound * K > max_buffer_bytes):
    rowsPerRound = max_buffer_bytes / K        // clamp to buffer limit
numRounds  = tileRows / rowsPerRound
bufferSize = rowsPerRound * K
```

**Input B (Broadcast + Col)** — data is `tileCols × K` per tile:

```
colsPerRound = tileCols / pp_depth
if (colsPerRound * K > max_buffer_bytes):
    colsPerRound = max_buffer_bytes / K        // clamp to buffer limit
numRounds  = tileCols / colsPerRound
bufferSize = colsPerRound * K
```

**Output C (Gather)** — data is `tileRows × tileCols` per tile:

```
outputPerCore = tileRows * tileCols
bufSzOut = outputPerCore / pp_depth
if (bufSzOut > max_buffer_bytes):
    bufSzOut = max_buffer_bytes               // clamp to buffer limit
numRounds  = outputPerCore / bufSzOut
bufferSize = bufSzOut
```

**Other input patterns** (default fallback):

```
perTile    = totalElements / (meshRows * meshCols)
bufferSize = min(perTile / pp_depth, max_buffer_bytes)
numRounds  = perTile / bufferSize
```

### Stage 3: Text Replacement in Kernel Body

The compiler extracts the kernel body as raw text, then performs string find-and-replace (`aiehlc.cc:1762-1805`):

1. Build a map from parameter names to port indices: `{"win_a": 0, "win_b": 1, "win_c": 2}`
2. Find each `aie::get_num_rounds(win_a)` call, look up port index 0, replace with `derivedTilingParams.portParams[0].numRounds`
3. Find each `aie::get_buffer_size(win_a)` call, replace with `derivedTilingParams.portParams[0].bufferSize`
4. Replace `aie::get_tile_rows()` → `derivedTilingParams.tileRows`, etc.

The rewritten kernel body (now containing only integer literals) is then compiled by `xchesscc` (Synopsys AIE compiler) into the kernel ELF.

## Concrete Example: 256×256 GEMM on 4×4 Mesh

Given:
- `M=256, K=256, N=256`, mesh `4×4`
- `RowBC`: `pp_depth=2, max_buffer_bytes=4096`
- `ColBC`: `pp_depth=2, max_buffer_bytes=4096`
- `LtoR_Merge`: `pp_depth=2, max_buffer_bytes=4096`

**Derived base values:**
```
tileRows = 256 / 4 = 64
tileCols = 256 / 4 = 64
kDim     = 256
```

**Port A (Broadcast+Row):**
```
rowsPerRound = 64 / 2 = 32
32 * 256 = 8192 > 4096  →  rowsPerRound = 4096 / 256 = 16
numRounds  = 64 / 16 = 4
bufferSize = 16 * 256 = 4096
```

**Port B (Broadcast+Col):**
```
colsPerRound = 64 / 2 = 32
32 * 256 = 8192 > 4096  →  colsPerRound = 4096 / 256 = 16
numRounds  = 64 / 16 = 4
bufferSize = 16 * 256 = 4096
```

**Port C (Gather):**
```
outputPerCore = 64 * 64 = 4096
bufSzOut = 4096 / 2 = 2048
2048 <= 4096  →  no clamping
numRounds  = 4096 / 2048 = 2
bufferSize = 2048
```

**After replacement, the kernel sees:**
```cpp
const int num_a_rounds = 4;
const int num_b_rounds = 4;
const int num_c_rounds = 2;
const int buf_sz_a     = 4096;
const int buf_sz_b     = 4096;
const int buf_sz_c     = 2048;
const int tile_rows    = 64;
const int tile_cols    = 64;
const int k_dim        = 256;
```

## Why Text Replacement?

The kernel runs on AIE cores (a different ISA from the ARM host). The `aiehlc` Clang frontend only parses the user's C++ for AST extraction — it doesn't generate LLVM IR for the AIE target. Instead, the kernel body is handed off as C++ source text to `xchesscc` (Synopsys compiler for AIE cores). Textual replacement is the natural approach:

```
User C++                    aiehlc (Clang AST)              xchesscc
─────────                   ──────────────────              ────────
SpatialPolicy structs  ──►  Extract pp_depth,
M/K/N macros           ──►  max_buffer_bytes
mesh(rows, cols)       ──►  Compute numRounds,   ──►  Compile kernel.cc
                            bufferSize, etc.           with constants baked in
                            Replace text in                → kernel ELF
                            kernel body
```

## Host-Kernel Consistency

The host side independently configures DMA Buffer Descriptors through the MLIR pipeline (routing → dmap → dmaphop → blueprint → dfschedule → EmitC → host.cc). The same `M/K/N`, mesh dimensions, and `SpatialPolicy` parameters feed both paths, so the DMA transfer counts on the host match exactly what the kernel expects via `get_num_rounds()`.

## Source References

| What | File | Line |
|------|------|------|
| `DerivedTilingParams` struct | `src/llvm/aiehlc.cc` | 63-76 |
| Stub declarations injected | `src/llvm/aiehlc.cc` | 1579-1583 |
| AST extraction of SpatialPolicy | `src/llvm/aiehlc.cc` | 900-910 |
| numRounds/bufferSize calculation | `src/llvm/aiehlc.cc` | 954-1021 |
| Text replacement of get_*() calls | `src/llvm/aiehlc.cc` | 1762-1805 |
