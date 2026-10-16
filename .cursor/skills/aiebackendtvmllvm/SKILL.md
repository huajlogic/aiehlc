---
name: aiebackendtvmllvm
description: "`CommandLine Error: Option 'disable-gisel-legality-check' registered more than once!` / `LLVM ERROR: Option 'basic' already exists!` when a TVM frontend (deploy_flow.py --aie-offload / --aiegraph) loads the `_aiebackend` pybind module — two LLVMs in one process. Use `aiebackend.spawn()` (out of process), never `aiebackend.load()`, next to TVM."
---

# `_aiebackend` cannot share a process with TVM

## Symptom

```
: CommandLine Error: Option 'disable-gisel-legality-check' registered more than once!
LLVM ERROR: inconsistency in registered CommandLine options
```
(or `LLVM ERROR: Option 'basic' already exists!` if `_aiebackend` loads first).
The process aborts — no Python traceback, so it can look like a crash in the pipeline.

## Root cause

`_aiebackend` (the pybind module over `TilingLinalgPipeline`,
`src/mlir/mlirfront/frontend/aiebackend/`) statically links LLVM/MLIR; TVM 0.16's
`libtvm.so` (LLVM-enabled build) carries its own LLVM. Both register LLVM's global
`cl::opt`s at load time. Either import order aborts. Nothing to fix in either build.

Any import of the `frontend.tvmrelay` package loads TVM (`__init__` runs
`ensure_tvm016()`), so `import frontend.tvmrelay.aie_offload` alone is enough.

## Fix (in place)

The `aiebackend` package has two entry points:

| Call | Where it runs | Use from |
|---|---|---|
| `aiebackend.load()` | in-process import | Triton frontend (`aietriton/_compiler.py`) — no other LLVM |
| `aiebackend.spawn()` → `BackendProcess` | child `python3` running `aiebackend/worker.py` | TVM path — `aie_offload.aie_backend()` |

`BackendProcess` forwards `build_aiegraph_module` / `lower_aiegraph` /
`run_aie_pipeline` as JSON lines. The worker moves fd 1 to stderr so the pipeline's
C++ logging cannot corrupt a reply. `aiegraph_partition.py` uses the same
`aie_backend()`.

Rules:
- `aiebackend/__init__.py` and `worker.py` must stay **stdlib-only** — never import
  `frontend.tvmrelay` (that drags TVM back in).
- Args/results must be JSON-able; tuples come back as lists (callers already
  normalise with `list()/int()/bool()`).
- Never call `aiebackend.load()` / `import _aiebackend` in a module that may run
  next to TVM.

## Verify

```bash
PYTHONPATH=src python3 -c "import tvm; from frontend.tvmrelay.aie_offload import aie_backend; print(aie_backend().__file__)"
```
