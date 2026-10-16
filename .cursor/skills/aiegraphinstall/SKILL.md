---
name: aiegraphinstall
description: Installing or importing the `aiegraph` Python package (`pip install -e .`, `src/aiegraph`, `aiegraph doctor`/`setup`, the `aiehlc` console command). Use when `import aiegraph` / `ag.embedded_convert` cannot find TVM 0.16, starts a TVM source build unexpectedly, says `no aiehlc checkout`, refuses a workdir (`exists and was not written by aiegraph`), returns stale results after a model/calibration change, or when changing `pyproject.toml`.
---

# aiegraph install: one pip command, three things pip cannot do

`pip install -e .` from the repo root (in a venv) installs `aiegraph`, the `frontend.*`
packages, numpy/onnx/onnxruntime/pillow/torch + TVM's runtime deps, and the `aiegraph` and
`aiehlc` commands. Verified in a FRESH venv: no `PYTHONPATH`, no setup step, `aiegraph doctor`
all green, `example/aiegraph/quickstart_onnx.py` converts, checks, offloads and links.

## What pip cannot install, and how it is handled

* **The checkout itself.** The flow uses `script/aiehlc.sh`, `include/`, `thirdparty/`, the
  example kernels. Hence EDITABLE only; `_env.repo_root()` (= `src/aiegraph/../..`, or
  `AIEHLC_ROOT`) raises `no aiehlc checkout` + the fix otherwise.
* **TVM 0.16** (PyPI starts at 0.25). `_env.attach_tvm()` probes `import tvm` in a CHILD
  process; if not 0.16 and `thirdparty/tvm-0.16/build/libtvm.so` exists, it prepends
  `thirdparty/tvm-0.16/python` to `sys.path` AND `PYTHONPATH` (TVM finds `libtvm.so`
  relative to its package dir, so nothing is copied). No build → `aiegraph setup`
  (`setup_tvm016.provision`, 10–25 min). Do NOT call `provision()` when a build exists: it
  re-runs cmake/ninja and may rebuild with different LLVM settings.
* **Vitis** (`xchesscc`, aarch64 cross gcc): licensed; only `offload`/`build` need it.

## Traps

* Importing ANY `frontend.tvmrelay.*` module runs the package `__init__` →
  `ensure_tvm016()` → provisions TVM if missing. `doctor` imports with
  `AIEHLC_TVM_AUTO_INSTALL=0` (`_env.frontend(mod, auto_install=False)`).
* `src/frontend/` has no `__init__.py`: `[tool.setuptools.packages.find] namespaces = true`,
  or `frontend` silently is not installed.
* `deploy_flow` caches by FIXED file names (`resnet18-v1-7.onnx`, `.folded`, `.op13`,
  `.int8.qdq`) and file existence. `embedded_convert` therefore copies the model to
  `<workdir>/resnet18-v1-7.onnx`, keeps one workdir per model, stamps
  `aiegraph.json` (model sha + quantize + calib + image) and WIPES the workdir on a
  mismatch -- but refuses a non-empty dir without that stamp (use `ag.open(dir)`).
* Never run two `aiehlc.sh` concurrently: `thirdparty/alib/lib` is wiped per run.
* `pyproject.toml` `readme` must exist (`doc/tutorial_aiegraph.md`) or the build fails.
* `from_torch` uses `torch.onnx.export(..., dynamo=False, opset_version=13)`: the dynamo
  exporter needs `onnxscript`; the TorchScript one works on torch 2.10–2.14.

## `ModuleNotFoundError: No module named 'aiegraph'`

The package is in `src/aiegraph/` but was never installed into the interpreter in
use (`python3 -m pip show aiegraph` says "not found"; a stray `src/aiegraph.egg-info`
from another env proves nothing). Run `python3 -m pip install -e .` with *that* python.
Two ways it then still fails:

* `--no-build-isolation` uses the venv's own setuptools; below 64 there is no PEP 660
  `build_editable` hook -> "missing the 'build_editable' hook". Drop the flag (pip
  fetches `setuptools>=64` into the isolated build env) or upgrade setuptools.
* Started from a directory holding a file that shadows the stdlib (e.g. `/tmp/http.py`):
  `import aiegraph` dies inside `urllib.request` with an unrelated error such as
  `No module named 'fastapi'`. The cwd is `sys.path[0]`; start elsewhere.

No install at all: `PYTHONPATH=src python3` from the repo root.

## Verify

```bash
python -m venv /scratch/x && /scratch/x/bin/pip install -e . && env -u PYTHONPATH /scratch/x/bin/aiegraph doctor
python3 -m pytest -q src/aiegraph/test src/frontend/tvmrelay/aiekernel/test
```
