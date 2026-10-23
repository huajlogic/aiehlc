# aiebackend — Python access to the AIE compiler backend

`_aiebackend` is the pybind11 module over the C++ `TilingLinalgPipeline`. It is
frontend-neutral: the Triton frontend (`../aietriton/`) and the TVM offload path
(`src/frontend/tvmrelay/`, `deploy_flow.py --aie-offload` / `--aiegraph`) both
drive it.

| File | Role |
|------|------|
| `aiebackend_pybind.cpp` | The `_aiebackend` module: `run_aie_pipeline`, `build_aiegraph_module`, `lower_aiegraph`, `build_kernel_body`, `orchestrate_conv_layer` |
| `kernel_body_emitter.{h,cpp}` | `KernelOp[]` → MLIR EmitC → C kernel body (behind `build_kernel_body`) |
| `CMakeLists.txt` | Builds `_aiebackend`, links `mlirtestlib` + MLIR libs |
| `__init__.py` | `find_module_dir()`, `load()` (in-process), `spawn()` → `BackendProcess` (child process) |
| `worker.py` | The child process behind `spawn()`; stdlib-only |

## Build

```bash
cd build
cmake .. -DPython3_EXECUTABLE=<venv>/bin/python3 \
         -Dpybind11_DIR=$(<venv>/bin/python3 -m pybind11 --cmakedir)
make _aiebackend -j$(nproc)
```

Without `-Dpybind11_DIR`, cmake prints `Skipping _aiebackend` and `make` quietly
builds no `.so` (skill: **mlirbuildsandbox**). `make install` is optional:
`find_module_dir()` searches `build/`, `build_claude/` and `$AIEHLC_BUILD_DIR`.
`-DAIEHLC_BUILD_AIEBACKEND=OFF` skips the module.

## `load()` vs `spawn()`

`_aiebackend` statically links LLVM/MLIR. TVM's `libtvm.so` carries another
LLVM, and the two abort on duplicate LLVM command-line options in either import
order. So:

- **`load()`** — Triton, and anything else with no second LLVM in the process.
- **`spawn()`** — anything that has TVM loaded. `aie_offload.aie_backend()` uses it.

Keep `__init__.py` and `worker.py` stdlib-only so `spawn()` never pulls TVM into
the worker (skill: **aiebackendtvmllvm**).
