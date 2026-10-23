# `test/` — `deploy_flow.py --aie-offload` regression test

```bash
source script/setup.sh --path-set-only        # stage 6's cross toolchain
bash src/frontend/tvmrelay/test/run_test.sh
```

Three checks, reported separately so a failure names what broke:

| # | check | fails when |
|---|-------|-----------|
| 1 | `run` | `python3 src/frontend/tvmrelay/deploy_flow.py --aie-offload` exits non-zero (full log: `test/deploy_flow.log`) |
| 2 | `tree` | `worklocal/tvmrelay_deploy/layers/` differs from `layers-golden/` |
| 3 | `aie/` | the offloaded conv layer folder has no non-empty `aie/` subdirectory |

Exit codes: `0` pass, `1` a check failed, `2` `deploy_flow.py` itself failed,
`3` the test could not run (no golden, no `layers/`).

## Why it is written the way it is

* **The cwd is pinned to the repo root.** `deploy_flow.DEFAULT_OUT` is
  `./worklocal/tvmrelay_deploy` — *relative to the cwd*. Run from anywhere else
  it writes a second output tree there, and the comparison then passes or fails
  against a stale one.
* **The layer folder is resolved by glob, not by index.** Stage 5 renumbers
  `layers/` whenever a pass adds or removes graph nodes — the conv stem has been
  index 1 (fp32), 6 (int8 legalized), then 1 again (int8 + the qnn zero-point
  fold). `--aie-layer-glob` defaults to `*conv2d*`, which survives that; today
  it matches
  `01_contrib_conv2d_NCHWc_subtract_add_subtract_fixed_point_multiply_per_axi`.
* **The folder list comes from `manifest.json`, not from `ls`.**
  `split_layers._clear_stale` deliberately keeps a *non-empty* layer folder —
  that is exactly how an offloaded layer's `aie/` artifacts survive the re-split
  `--aie-offload` triggers — so two `01_*` folders from different builds can sit
  side by side and only one belongs to this graph. Pass `--clean` to make the
  verdict about this run only.
* **Absolute paths are normalized before comparing.** `layers/Makefile` bakes in
  `TVM_HOME` and `manifest.json` records `source`/`graph` as written; both are
  rewritten to `$REPO` / `$TVM_HOME` so the golden is portable between
  checkouts.
* **Build products are skipped by default** (`*.o`, `*.a`, `*.elf`, `*.log`,
  `*/build/*`): their bytes depend on the toolchain, not on anything this flow
  decides. The *sources* under `aie/` are compared. `--only-ignore` turns the
  built-in list off; `--ignore GLOB` adds to it.

## First run

There is no golden until one is captured. Run the flow, check the output by
hand, then:

```bash
bash run_test.sh --skip-run --update-golden
```

It refuses to overwrite an existing `layers-golden/` without `--force`: the
golden is the only record of what the tree looked like when it was last known
good.

## Useful flags

```bash
bash run_test.sh --skip-run            # verify what is already on disk
bash run_test.sh --clean               # wipe layers/ first
bash run_test.sh --no-aie-check        # checks 1+2 only
bash run_test.sh --deploy-args "--no-arm --aie-layers 1"
bash run_test.sh --context 80          # more diff lines per differing file
```

## Where `aie/` comes from

`--aie-offload` runs BYOC (which swaps the call in `resnet18.c` and writes no
per-layer folder) **and** the aiegraph lift over the same `--aie-layers`
selection: `aiegraph_partition._offload` → `run_aie_pipeline` →
`layers/NN_op/aie/`, archived by `aie_layer_lib.py`. The lift is additive —
no layer's `.c` changes — which is why `layers/` still equals the
**default-flow** golden.

So the tree check excludes the AIE-only outputs (`*/aie/*`, `aiegraph.mlir`,
`partition.json`) and check 3 owns them. It fails unless the `aie/` holds
`host.cc`, `kernel.cc` and `routing.cc`, `partition.json` sends that layer to
AIE as an aiegraph `conv_*` op, and the op is in `aiegraph.mlir`. The last two
catch a stale `aie/` that `_clear_stale` kept from an older build.

**BYOC still fuses 0/20 convs** under the int8 default (`[aie-byoc] 1/4 fuse :
nothing`). If it starts fusing, it rebuilds the C and layer 01's `.c` will
differ from the golden. That is a real change to review, not noise.

**Layer 01 (the stem) is aiehlc's build of `conv2dstem.cc`**, the same
source `test_conv2d.cc` `#include`s and verifies bit-exact against this layer
(`aiegraph_partition._build_stem` → `aie_stem_lib`). Check 3 enforces it for the
`01_contrib_conv2d_NCHWc*` folder. `partition.json` `source` must be
`conv2dstem.cc`, `aie/conv2d_spatial.cc` must carry the int32 accumulator and
the `(sh + 31)` requant, and the generic `conv_bn_0.cc` must be absent. Other
convs, if selected, still get the generic placeholder body (int16 accumulator,
dummy quant).
