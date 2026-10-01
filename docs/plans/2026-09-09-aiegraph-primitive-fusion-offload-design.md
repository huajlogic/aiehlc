# Design: TVM-no-fuse → aiegraph-fuse → offload

Date: 2026-09-09
Scope: **B** — Python fusion, reuse the existing 4 aiegraph fused ops. No new
dialect ops, no new C++ passes. Python-only change plus tests/doc.

## Motivation

Today the TVM frontend relies on TVM's `FuseOps` to fuse the graph, and
`walk.py` only *records op signatures* and validates them against the canonical
`model.layer_plan()`. The fusion decision is TVM's; we merely check it. This
couples correctness to TVM producing exactly the fused shape we expect, and is
why the walk must "validate rather than rebuild".

This change **moves fusion out of TVM and into our frontend**: import the
*primitive* Relay graph (no `FuseOps`), then fuse the primitives ourselves into
the existing 4 fused ops, then offload-split (AIE vs CPU) via the existing
`cpu_codegen.is_aie_op` dispatch. This makes the frontend tolerant of whatever
grouping TVM would have chosen (we ignore it) while preserving bit-exactness
(on a structural match we still return the canonical plan).

## Data flow

```
ONNX
  └─ relay_import.import_relay  (NO FuseOps):
       InferType → SimplifyInference → FoldConstant → InferType
        └─ walk.recover_primitives()   flat primitive Call list
             (conv2d, multiply, add, relu, global_avg_pool2d, dense)
             └─ walk.fuse_primitives()  OUR fusion pass → List[LayerOp]
                  └─ validate_against_canonical()
                       match  → return canonical plan (bit-exact wiring)
                       diverge→ fallback to canonical (or raise if strict)
                        └─ model.plan_to_aiegraph_dicts
                             → build_aiegraph_module (build+verify)
                             → lower_aiegraph (tensor_specs)
                             → offload split (is_aie_op):
                                  conv_*          → run_aie_pipeline (AIE)
                                  residual/avgpool→ cpu_codegen (CPU)
```

Fusion moves from TVM into `walk.py`. The offload split is the **existing**
`AIE_OPS`/`CPU_OPS` dispatch — unchanged; it already works once the plan is
fused.

## The fusion matcher (core new logic)

With `FuseOps` dropped, BatchNorm's `multiply`/`add` (from `SimplifyInference`)
appear as **top-level** ops, so the matcher must distinguish them from a
residual `add`. Discrimination rule (robust, graph-derivable):

- `multiply(x, Constant)` → **BN scale** (part of a conv block)
- `add(x, Constant)`      → **BN shift** (part of a conv block)
- `add(tensorA, tensorB)` (both non-constant) → **residual join**

Greedy left-to-right grouping over the primitive list:

| Primitive window                                   | Fused `LayerOp`     |
|----------------------------------------------------|---------------------|
| `conv2d [→ mul(const)] [→ add(const)] → relu`      | `conv_bn_relu`      |
| `conv2d [→ mul(const)] [→ add(const)]` (no relu)   | `conv_bn`           |
| `add(tensor,tensor) → relu`                        | `residual_add_relu` |
| `global_avg_pool2d → dense [→ add(const bias)]`    | `avgpool_fc`        |

Geometry recovery is unchanged (`_conv_signature`, `_feature_hw`). The matcher
emits the same fused-op *structure* the canonical plan has;
`validate_against_canonical` confirms ordered conv geometry + residual/GAP/FC
counts, and on a match `build_plan` returns `model.layer_plan()` (hand-verified
buffer wiring → bit-exact). On divergence: fall back to canonical, or raise when
`strict=True`.

## Offload

Unchanged mechanism: `cpu_codegen.is_aie_op` (`conv_bn`, `conv_bn_relu` → AIE;
`residual_add_relu`, `avgpool_fc` → CPU), applied at emit in
`_compiler.compile_plan_via_aiegraph` / `compile_launch` / `demo_flow.py`.
For transparency, add a one-line log per launch ("launch N <op> → AIE|CPU").
No IR-level target attribute (that would be Scope A).

## Files

Changed:
- `src/frontend/tvm/relay_import.py` — remove `FuseOps` from the `Sequential`.
- `src/frontend/tvm/walk.py` — add `recover_primitives()` (records
  mul-const / add-const / add-tensor / relu / gap / dense in dataflow order) and
  `fuse_primitives()` (the matcher → `List[LayerOp]`); `build_plan` calls these
  instead of `recover_signatures`. Keep `validate_against_canonical` + fallback.
- `src/frontend/tvm/test_tvm_frontend.py` — new tests (see Verification).
- `doc/design/tvm_frontend.md` — update the "Fused-graph walk" section to
  "primitive walk + our fusion".

NOT changed: aiegraph dialect (`td/`, `aiegraphmanager`, `AiegraphLowerDriver`),
`aietriton_pybind.cpp`, `cpu_codegen.py`, `model.py`.

## Verification

`python src/frontend/tvm/test_tvm_frontend.py` — passes with and without TVM.

New / updated tests:
1. `recover_primitives` on the no-fuse graph yields the expected primitive
   sequence (includes the BN mul/add-const ops now visible at top level).
2. `fuse_primitives` produces a plan structurally equal to `model.layer_plan()`.
3. BN-`add`(const) vs residual-`add`(tensor,tensor) discrimination is correct.
4. Existing `test_plan_matches_canonical` still passes (bit-exact preserved).
5. No-TVM path still returns the canonical plan (graceful degradation).

## Non-goals (would be Scope A)

- Primitive ops in the aiegraph TableGen dialect.
- A C++ `FusionLegalizePass` / `OffloadPartitionPass`.
- IR-level target attribute / region outlining for offload.
- Emitting bare unfused primitives to CPU (we keep the canonical fallback).
