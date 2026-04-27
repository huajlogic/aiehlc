# Tutorial: Writing, Compiling, and Testing a Triton-style AIE Program

This step-by-step tutorial walks through writing a Triton-style Python kernel for AMD Versal AI Engine, converting it to C, compiling to ELF binaries, and running on hardware.

---

## Prerequisites

- **Vitis** installed (XILINX_VITIS set via `source script/setup.sh`)
- **Cross-compiler** toolchain (`aarch64-none-elf-g++` for baremetal)
- **Python 3.8+** (no external packages needed for the pure Python path)
- **aiehlc repo** cloned with submodules (`thirdparty/alib`, BSP)
- **AIE board** accessible for HW testing (optional for pure C generation)

Verify your environment:

```bash
cd <aiehlc_root>
source script/setup.sh
source script/verify_env.sh    # checks Vitis, toolchains, BSP, etc.
```

---

## Step 1: Write the Triton-style Python Kernel

Create a new `.py` file (or copy `triton_matmul.py` as a starting point):

```bash
cp triton_matmul.py my_matmul.py
```

A Triton-style AIE program has three parts:

### Part A: Imports

```python
import aie_triton
import aie_triton.language as tl
import numpy as np
```

### Part B: Kernel Function (decorated with `@aie_triton.jit`)

```python
@aie_triton.jit
def matmul_simple(
    a_ptr,                          # input tensor pointer → window_in_0
    b_ptr,                          # input tensor pointer → window_in_1
    c_ptr,                          # output tensor pointer → window_out_0
    M, N, K,                        # matrix dimensions (scalars)
    BLOCK_M: tl.constexpr = 8,      # compile-time block sizes
    BLOCK_N: tl.constexpr = 8,
    BLOCK_K: tl.constexpr = 8,
):
    # 1. Get tile identity (which AIE tile am I?)
    tile_row = tl.program_id(axis=0)    # → coreid & 0x1F
    tile_col = tl.program_id(axis=1)    # → coreid >> 16

    # 2. Compute block offsets
    row_start = tile_row * BLOCK_M
    col_start = tile_col * BLOCK_N

    # 3. Allocate accumulator in tile-local memory
    acc = tl.zeros((BLOCK_M, BLOCK_N), dtype=tl.int32)

    # 4. K-dimension loop: each iteration is one DMA acquire/compute/release cycle
    for k_start in range(0, K, BLOCK_K):
        a_block = tl.load(a_ptr + ...)     # → acquire_input_window(window_in_0)
        b_block = tl.load(b_ptr + ...)     # → acquire_input_window(window_in_1)
        acc += tl.dot(a_block, b_block)    # → vector MAC

    # 5. Store result: saturate and write back via DMA
    result = acc.to(tl.int8)
    tl.store(c_ptr + ..., result)          # → acquire/write/release output window
```

**Rules for writing kernels:**

| Rule | Why |
|------|-----|
| Parameters ending in `_ptr` or named `A`/`B`/`C` are treated as tensors | Determines input/output windows |
| Tensors used in `tl.load()` become input windows | `tl.load(a_ptr + ...)` → `acquire_input_window()` |
| Tensors used in `tl.store()` become output windows | `tl.store(c_ptr + ...)` → `acquire_output_window()` |
| `tl.constexpr` annotated params are compile-time constants | Resolved at AST parse time |
| Block sizes must fit in 32 KB tile-local memory | Typically 4-16 for int8 |
| `tl.program_id(0)` = tile row, `tl.program_id(1)` = tile col | AIE mesh is 2D |

### Part C: Host `main()` Function

```python
def main():
    M, N, K = 16, 16, 16

    aie_triton.set_device(0)                              # → aieSetDevice(0)

    A = np.arange(1, M * K + 1, dtype=np.int8).reshape(M, K)
    B = np.arange(1, K * N + 1, dtype=np.int8).reshape(K, N)
    C = np.zeros((M, N), dtype=np.int8)

    mesh = aie_triton.mesh(rows=2, cols=2)                # → aieDim mesh(2, 2)
    grid = (mesh.rows, mesh.cols)

    matmul_simple[grid](A, B, C, M, N, K,                # → matmul<<<mesh>>>(...)
                        BLOCK_M=8, BLOCK_N=8, BLOCK_K=8)

    aie_triton.synchronize()                              # → aieDeviceSynchronize()

    # Verify against CPU reference
    C_ref = (A.astype(np.int16) @ B.astype(np.int16)).clip(-128, 127).astype(np.int8)
    mismatches = np.sum(C != C_ref)
    if mismatches == 0:
        print(f"PASS: all {M * N} elements match.")
    else:
        print(f"FAIL: {mismatches} mismatches.")

if __name__ == "__main__":
    main()
```

---

## Step 2: Generate C Code (Pure Python — No Build Required)

The pure Python converter at `src/python/` translates your `.py` file into `kernel.c` + `host.c` without needing any C++ build or MLIR libraries.

### Option A: Using the standalone test script

```bash
cd <aiehlc_root>/.worktrees/triton/src/python

# Convert triton_matmul.py → kernel.c + host.c
python test_triton_to_c.py \
    ../../example/tileprogram/design/triton/triton_matmul.py
```

This runs 4 verification tests and writes output to `/tmp/claude/triton_output/`.

### Option B: Using the Python API

```python
import sys, os
sys.path.insert(0, "<aiehlc_root>/.worktrees/triton/src")
sys.path.insert(0, "<aiehlc_root>/.worktrees/triton/src/mlir/mlirfront")

from python.ast_to_c import convert_triton_to_c

result = convert_triton_to_c(
    "example/tileprogram/design/triton/triton_matmul.py",
    "./output"
)
print(result["kernel_c"])    # kernel C code
print(result["host_c"])      # host C code
# Files written: ./output/kernel.c, ./output/host.c
```

### Option C: Using the full aietriton pipeline (requires C++ build)

```bash
cd <aiehlc_root>/.worktrees/triton/src/mlir/mlirfront

# AST → KernelOps verification only (no C++ .so needed)
python -m aietriton.aie_pass.test_ast_to_c

# Full pipeline including C generation (needs built _aietriton_core.so)
python -m aietriton.aie_pass.test_ast_to_c --full
```

### What Gets Generated

**kernel.c** — the AIE tile kernel function:

```c
void matmul_simple(input_window_int8 *window_in_0,
                  input_window_int8 *window_in_1,
                  output_window_int8 *window_out_0) {
    unsigned coreid = get_coreid();
    int col = coreid >> 16;
    int row = coreid & 0x1F;
    for (int iter = 0; iter < 2; iter++) {
        klog("CENk", iter);
        int8_t *in0 = (int8_t *)acquire_input_window(window_in_0);
        int8_t *in1 = (int8_t *)acquire_input_window(window_in_1);
        for (int i = 0; i < 8; i++) {
            for (int j = 0; j < 8; j++) {
                int16_t sum = 0;
                for (int kk = 0; kk < 8; kk++)
                    sum += (int16_t)in0[i * 8 + kk] * (int16_t)in1[kk * 8 + j];
                if (sum > 127) sum = 127;
                else if (sum < -128) sum = -128;
                out0[i * 8 + j] = (int8_t)sum;
            }
        }
        klog("CLOP", 64);
        release_input_window(window_in_0);
        release_input_window(window_in_1);
        klog("CEXT", 1);
    }
        int8_t *out0 = acquire_output_window(window_out_0);
        release_output_window(window_out_0);
}
```

**host.c** — the host main() program:

```c
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "aie_runtime.h"

int main() {
    const int M = 16, N = 16, K = 16;
    aieSetDevice(0);
    aieDim mesh(2, 2);

    int8_t *A = (int8_t *)malloc(M * K * sizeof(int8_t));
    int8_t *B = (int8_t *)malloc(K * N * sizeof(int8_t));
    int8_t *C = (int8_t *)malloc(M * N * sizeof(int8_t));

    for (int i = 0; i < M * K; i++) A[i] = (int8_t)(i + 1);
    for (int i = 0; i < K * N; i++) B[i] = (int8_t)(i + 1);
    for (int i = 0; i < M * N; i++) C[i] = 0;

    matmul_simple<<<mesh>>>(A, B, C, M, N, K);
    aieDeviceSynchronize();

    // ... verification loop ...
    free(A); free(B); free(C);
    return 0;
}
```

---

## Step 3: Generate Routing + DMA Code via MLIR Pipeline

The pure Python converter produces kernel and host C code but does **not** generate `routing.cc` (stream switch configuration) or DMA buffer descriptor setup. For the full pipeline that produces all artifacts, use the MLIR-based unitest:

```bash
cd <aiehlc_root>/src/mlir/mlirfront/tilinglinalg/pass/unitest

# Build the unitest binary (first time only)
mkdir -p build && cd build && cmake .. && make -j4
cd ..

# Run the full pipeline
./build/test dfschedule     # → worklocal/host.cc + worklocal/kernel.cc
./build/test hw             # → worklocal/routing.cc
./build/test                # both dfschedule + hw (default)
```

Output files in `worklocal/`:

| File | Content |
|------|---------|
| `host.cc` | Host program with DMA BD configuration, lock setup, kernel launch |
| `kernel.cc` | AIE tile kernel with acquire/release/compute |
| `routing.cc` | Stream switch routing configuration |
| `aieml.bcf` | Board configuration for xchesscc |
| `aieml.prx` | Project file for xchesscc |

---

## Step 4: Compile Kernel ELF

The kernel runs on the AIE core and must be compiled with xchesscc (the Synopsys compiler for AIE, bundled with Vitis):

```bash
cd <aiehlc_root>/src/mlir/mlirfront/tilinglinalg/pass/unitest/worklocal

# Compile kernel.cc → kernel ELF → kernel.o (binary blob for embedding in host)
source compile_kernel.sh [func_name]
```

**What `compile_kernel.sh` does:**
1. Sources Vitis environment (`XILINX_VITIS`)
2. Runs `kc.sh` which invokes `xchesscc` to compile kernel.cc
3. Uses the generated `aieml.prx` / `aieml.bcf` for memory layout
4. Produces `build/kernel.o` with embedded binary symbols:
   - `_binary_kernel_<func_name>_start`
   - `_binary_kernel_<func_name>_end`
   - `_binary_kernel_<func_name>_size`

---

## Step 5: Compile Host ELF

The host program runs on the ARM Cortex-A72/A78 and configures the AIE array:

```bash
cd <aiehlc_root>/src/mlir/mlirfront/tilinglinalg/pass/unitest/worklocal

# Compile host.cc + routing.cc + aie_runtime + kernel.o → host ELF
source hostcompile.sh
```

**What `hostcompile.sh` does:**
1. Calls `compile_kernel.sh` to build kernel.o
2. Compiles `host.cc` with `aarch64-none-elf-g++`
3. Compiles `aie_runtime.c` (runtime wrappers over XAie driver)
4. Compiles `routing.cc` (if present)
5. Links everything together with the XAie driver library and BSP

Output: `worklocal/build/host` (ARM ELF binary)

---

## Step 6: Run on AIE Hardware

### Automated (using `piplinerun.sh`)

The pipeline script automates steps 3-6:

```bash
cd <aiehlc_root>/src/mlir/mlirfront/tilinglinalg/pass/unitest

# Full run: build → generate → compile → deploy to HW
source piplinerun.sh rebuild

# Skip rebuild, just recompile and deploy
source piplinerun.sh
```

### Manual (using `apppaltest.py`)

```bash
# 1. Set up board connection
source ~/palmtest/envlocal.sh     # sets PALIP, BOARDNAME, USERNAME

# 2. Deploy and run on AIE board
python3 script/test/apppaltest.py worklocal/build/host
```

`apppaltest.py` does:
1. SSH to the board (`$USERNAME@$PALIP`)
2. Upload the host ELF
3. Launch via xsdb
4. Capture console output
5. Report pass/fail

### Expected Output

**PASS:**
```
PASS: all 256 elements match.
device_teardown done
```

**FAIL:**
```
MISMATCH C[0][0]: got 42, expected 36
AIE ERROR: ...
```

---

## Step 7: Verify Results

### Quick Verification Checklist

```
[ ] kernel.c contains: function signature, acquire/release, GEMM loops
[ ] host.c contains: main(), aieSetDevice, aieDim, kernel launch, free
[ ] Kernel compiles with xchesscc without errors
[ ] Host compiles with aarch64-g++ without errors
[ ] HW output shows "PASS" and "device_teardown done"
```

### Running the Python Unit Tests

```bash
# Test 1: AST → KernelOps (no C++ build needed)
cd <aiehlc_root>/.worktrees/triton/src/mlir/mlirfront
python -m aietriton.aie_pass.test_ast_to_c

# Test 2: Pure Python converter (no C++ build needed)
cd <aiehlc_root>/.worktrees/triton/src/python
python test_triton_to_c.py \
    ../../example/tileprogram/design/triton/triton_matmul.py

# Test 3: Full pipeline (requires _aietriton_core.so)
cd <aiehlc_root>/.worktrees/triton/src/mlir/mlirfront
python -m aietriton.aie_pass.test_ast_to_c --full
```

---

## Writing a New Kernel: Checklist

1. **Create your `.py` file** with `@aie_triton.jit` kernel + `def main()`
2. **Choose data types**: `np.int8`, `np.int16`, `np.int32`
3. **Choose block sizes**: must fit in 32 KB tile memory (with ping-pong = 2x)
   - int8 8x8 block = 64 bytes
   - int16 8x8 block = 128 bytes
   - Budget: ~32 KB / (num_buffers * 2 for ping-pong)
4. **Choose mesh size**: `aie_triton.mesh(rows=R, cols=C)` — R*C tiles
   - Matrix dims must be divisible by BLOCK_M*R and BLOCK_N*C
5. **Run the converter**: `python test_triton_to_c.py your_kernel.py`
6. **Inspect generated C**: check kernel.c and host.c match expectations
7. **Compile and test**: use the MLIR pipeline + cross-compile scripts

---

## Example: Creating a 32x32 int8 Matmul on a 4x4 Mesh

```python
@aie_triton.jit
def matmul_32x32(
    a_ptr, b_ptr, c_ptr,
    M, N, K,
    BLOCK_M: tl.constexpr = 8,    # 32/4 = 8 rows per tile
    BLOCK_N: tl.constexpr = 8,    # 32/4 = 8 cols per tile
    BLOCK_K: tl.constexpr = 8,
):
    tile_row = tl.program_id(axis=0)
    tile_col = tl.program_id(axis=1)
    row_start = tile_row * BLOCK_M
    col_start = tile_col * BLOCK_N
    acc = tl.zeros((BLOCK_M, BLOCK_N), dtype=tl.int32)

    for k_start in range(0, K, BLOCK_K):    # K=32, BLOCK_K=8 → 4 iterations
        a_block = tl.load(
            a_ptr + (row_start + tl.arange(0, BLOCK_M)[:, None]) * K
                  + (k_start  + tl.arange(0, BLOCK_K)[None, :])
        )
        b_block = tl.load(
            b_ptr + (k_start  + tl.arange(0, BLOCK_K)[:, None]) * N
                  + (col_start + tl.arange(0, BLOCK_N)[None, :])
        )
        acc += tl.dot(a_block, b_block)

    result = acc.to(tl.int8)
    tl.store(c_ptr + (row_start + tl.arange(0, BLOCK_M)[:, None]) * N
                   + (col_start + tl.arange(0, BLOCK_N)[None, :]), result)


def main():
    M, N, K = 32, 32, 32
    aie_triton.set_device(0)

    A = np.arange(1, M * K + 1, dtype=np.int8).reshape(M, K)
    B = np.arange(1, K * N + 1, dtype=np.int8).reshape(K, N)
    C = np.zeros((M, N), dtype=np.int8)

    mesh = aie_triton.mesh(rows=4, cols=4)
    grid = (mesh.rows, mesh.cols)
    matmul_32x32[grid](A, B, C, M, N, K, BLOCK_M=8, BLOCK_N=8, BLOCK_K=8)

    aie_triton.synchronize()
    # ... verify ...
```

Data partitioning: 4x4 mesh, each tile computes an 8x8 block of C, with 4 K-iterations of 8x8 chunks each.

---

## Quick Reference: End-to-End Commands

```bash
# --- Pure Python path (C code generation only) ---
cd <aiehlc_root>/.worktrees/triton/src/python
python test_triton_to_c.py ../../example/tileprogram/design/triton/triton_matmul.py
cat /tmp/claude/triton_output/kernel.c
cat /tmp/claude/triton_output/host.c

# --- Full MLIR pipeline + HW path ---
cd <aiehlc_root>/src/mlir/mlirfront/tilinglinalg/pass/unitest

# 1. Build unitest
mkdir -p build && cd build && cmake .. && make -j4 && cd ..

# 2. Generate C code via MLIR pipeline
./build/test dfschedule     # → worklocal/{host,kernel}.cc
./build/test hw             # → worklocal/routing.cc

# 3. Cross-compile
cd worklocal
source compile_kernel.sh    # → build/kernel.o
source hostcompile.sh       # → build/host (ARM ELF)

# 4. Deploy to AIE board
source ~/palmtest/envlocal.sh
python3 <aiehlc_root>/script/test/apppaltest.py worklocal/build/host

# Or use the all-in-one script:
source piplinerun.sh rebuild
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `ImportError: aietriton` | `src/mlir/mlirfront` not on PYTHONPATH | Run from `src/python/` or add to sys.path |
| `No @aie_triton.jit function found` | Missing decorator on kernel | Add `@aie_triton.jit` before `def` |
| `xchesscc: command not found` | Vitis not sourced | `source script/setup.sh` |
| `aarch64-none-elf-g++: not found` | Cross-compiler not installed | Install from Vitis or PetaLinux |
| `MISMATCH C[i][j]` on HW | Kernel logic error or DMA misconfiguration | Check block sizes, verify with CPU reference |
| `AIE ERROR` in console | Stream switch or lock deadlock | Run xaieapiverify skill, check routing.cc |
| Kernel compiles but output is all zeros | Output window not written | Check `tl.store` targets the output pointer |
| `device_teardown done` not printed | Kernel hangs (lock deadlock) | Check acquire/release pairing, ping-pong BD setup |

---

## File Reference

| File | Location | Purpose |
|------|----------|---------|
| `triton_matmul.py` | `example/tileprogram/design/triton/` | Reference Triton-style matmul example |
| `resnet18_triton.py` | `example/tileprogram/design/triton/` | ResNet18 inference example (advanced) |
| `simplematmul.cc` | `example/tileprogram/ccode/` | C equivalent of matmul (proposal3.cc style) |
| `ast_to_kernelops.py` | `src/mlir/mlirfront/aietriton/aie_pass/` | Python AST → KernelOp list |
| `kernel_body_emitter.cpp` | `src/mlir/mlirfront/aietriton/aie_pass/` | C++ KernelOps → MLIR EmitC → C (pybind11) |
| `kernel_emitter.py` | `src/python/` | Pure Python KernelOps → C (no C++ build) |
| `host_emitter.py` | `src/python/` | Pure Python host main() → C |
| `ast_to_c.py` | `src/python/` | Top-level orchestrator |
| `test_triton_to_c.py` | `src/python/` | Standalone test for the converter |
| `_compiler.py` | `src/mlir/mlirfront/aietriton/` | aietriton compilation entry point |
| `compile_kernel.sh` | `pass/unitest/worklocal/` | Kernel ELF compilation (xchesscc) |
| `hostcompile.sh` | `pass/unitest/worklocal/` | Host ELF compilation (aarch64-g++) |
| `piplinerun.sh` | `pass/unitest/` | All-in-one: build + generate + compile + HW run |
| `apppaltest.py` | `script/test/` | Deploy ELF to AIE board and capture output |
