---
name: aieuserkernel
description: Offload one TVM layer, or every layer a spec fits, with a USER-written AIE kernel (`include/aie_user_kernel.h`, `frontend/tvmrelay/aiekernel`, `deploy_flow.py --aie-kernel`). Use when someone wants to plug in their own kernel, asks "can this C file be offloaded / which layers does it fit", gets an `aiekernel` lint code (L0xx), a calibrate MISMATCH, an emulate FAIL, or a `rejected at link -- ... routing()` message.
---

# User kernels: AIEK_ENTRY + AIEK_SPEC, checked on x86 before aiehlc

Tutorial: `doc/tutorial_userkernel.md`. Examples: `src/aietensorop/conv2dstem/conv2dstem_uk.cc`
(+ `_ref.c`, the stem, real AIE kernel) and `example/userkernel/conv3x3_requant_ref.c`
(reference-only; one spec matches 7 ResNet-18 layers / 8 calls).

## The contract

aiehlc source, library mode (no `main()`): kernel + launch as in `conv2dstem.cc`, then

* `AIEK_ENTRY(name) { ... }` — `const aiek_tensor *args` in **TVM call order** (inputs
  incl. constants interleaved as the graph passes them, then outputs);
* `AIEK_SPEC(name, "in|param|out <dtype> [dims] [name] [require=..|tol=..]\n" ...)` — dims
  int / `*` / NAME (bound once, must agree); `require=zero|nonzero|uniform|nonneg|range(a,b)`
  checked on `params.bin` values per call; `match`, `reference`, `export` lines;
* `AIEK_REFERENCE(name)` in an x86 C file — models the AIE path (its folds/rounding/layouts).

The `aie_<tvm symbol>()` packed-call adapter is GENERATED (`aiekernel/adapter.py`), the
same text for the board (`host.cc`, calls the entry) and x86 (calls `<name>_ref`).

## Commands (PYTHONPATH=src; no board anywhere)

```
python3 -m frontend.tvmrelay.aiekernel lint    SRC
python3 -m frontend.tvmrelay.aiekernel detect  SRC [--all]
python3 -m frontend.tvmrelay.aiekernel check   SRC[@1,4]...      # lint+detect+calibrate+emulate
python3 -m frontend.tvmrelay.aiekernel offload SRC[@1] --make    # + aiehlc build, partition.json, main.elf link
python3 src/frontend/tvmrelay/deploy_flow.py --aie-kernel SRC[@1]
python3 -m pytest -q src/frontend/tvmrelay/aiekernel/test        # 50 tests
```

## Traps this caught or encodes

* **One aiehlc library per ELF.** `aie_runtime.c:__Runtime_routing_init` calls ONE global
  `routing(dev)`; partition init is cached per `meshId`. Two separately built libraries
  either collide (`multiple definition of routing`) or — if `routing` were weak — run
  kernel B with kernel A's switch config. `build.isolate_archive` therefore localizes
  everything EXCEPT adapters, entry, `export`s and the runtime hooks (kept strong), and
  `flow._check_one_aie_library` rejects later kernels at the `link` gate. A user kernel
  that builds displaces an `--aie-offload` stem library in `partition.json`.
* **`hostcompile.sh` skips existing objects** (`host.o exists; pass 'rebuild'`). After
  appending adapters to `host.cc`, delete `build/host.o` or the adapters silently never
  compile (`build.install` does).
* **The adapter is C AND C++.** `static const uint8_t none[8];` compiles as C and is an
  error in C++ (uninitialized const) — only `g++ -fsyntax-only` on the generated text
  catches it before the board build does (test `test_adapter_runs_and_checks`).
* **Package attributes shadow submodules**: exporting a function `lint`/`offload` from
  `aiekernel/__init__.py` hides the module of the same name; hence `lint_source` and
  the module `flow.py`.
* A failed/impossible build rejects the layer at `build` and leaves `partition.json`
  untouched; only `--no-build` records a decision without an archive (not swapped).
* Emulation regenerates `arm_build/` when `graph_driver.c`'s `graph-sha` differs from the
  graph — the driver bakes buffer sizes and weights offsets as literals.

## Verify

`offload ... --make` must end with `OFFLOAD <name>: libaiek_<name>.a -> graph_driver.c calls N adapter(s)`;
`aarch64-none-elf-nm arm_build/main.elf | grep -E "T aie_tvmgen|T <entry>"`; on a board the
adapter's `EXIT ... hash=` must equal the one in `<out>/aiek/emul/emulated.log`.
