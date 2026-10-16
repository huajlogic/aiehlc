---
name: byocfusesplit
description: The TVM→AIE BYOC path as four steps (fuse → select → partition → codegen). Read when "fuse" seems to run in the wrong order relative to BYOC, when adding a second AIE kernel or pattern, when `--aie-layers N` offloads nothing without saying why, or when CPU-only layers change output after an offload run.
---

# BYOC: fuse → select → partition → codegen

`deploy_flow.py --aie-offload` is four steps, one per file under
`src/frontend/tvmrelay/byoc/`. Only the first is TVM's.

| step | file | what it does |
|------|------|--------------|
| 1 fuse | `aie_fuse.py` | `InferType → FoldConstant → qnn.CanonicalizeOps → FoldConstant → MergeComposite → InferType`, then stamp `aie.weight_fp` on every composite |
| 2 select | `aie_annotate.py` | fingerprint ∈ selection **and** `kernel_can_run` → stamp `aie.layer_id`, wrap in `compiler_begin`/`end`; everything else inlined back |
| 3 partition | `aie_byoc.py` | `MergeCompilerRegions → PartitionGraph` |
| 4 codegen | `aie_codegen.py` | `relay.ext.aie`, dispatched through `_EMITTERS[composite_name]` |

`aie_byoc.partition_for_aie` is orchestration only — it calls `fuse_layers`, runs
the annotator, then partitions.

## "Fuse" names two different things. They cannot be reordered.

This is the single most common confusion about this flow, and the answer is that
there is no bug to fix:

- **`MergeComposite`** (step 1) groups ops into the unit the AIE kernel takes.
  Runs *before* selection and partitioning.
- **TVM's `FuseOps`** is TE-level operator fusion for codegen. It is the **last**
  pass of `relay.build` (`thirdparty/tvm-0.16/src/relay/backend/build_module.cc:350`)
  and *must* run after partitioning, so that it only fuses what stayed on the CPU.

So "quantize → byoc → fuse" is an accurate description of `FuseOps` and a correct
ordering. Do not try to move BYOC after it.

Two more orderings that look wrong and are not:

- `_stage_aie_offload` runs *temporally* after the CPU `relay.build`, because it
  needs stage 5's `layers/` to resolve `--aie-layers`. But it partitions the
  **pre-build module snapshot** (`deploy_flow.py` passes the same `mod` the CPU
  build got). Both paths start from the same un-fused, un-legalized qnn graph.
- Partitioning must precede `AlterOpLayout` (`relay/backend/utils.cc:276`, inside
  `relay.build`), or the conv becomes 5-D `contrib_conv2d_NCHWc` and neither the
  pattern nor the kernel recognizes it. Hence partitioning outside the build.

Also: `qnn.CanonicalizeOps` is not independently schedulable. `qnn::transform::Legalize()`
is a `Sequential` of `QnnLegalize` + `QnnCanonicalize` (`src/relay/qnn/pass/legalize.cc:51-57`),
third of ~20 passes in `relay.build`. Anything that must happen before the four-term
expansion — `qnn_fold_zp.fold_scalar_zero_points`, for instance — has to run before
`relay.build` entirely. There is no hook between the two halves.

## Fusion is geometry-agnostic on purpose

`check_fused_qconv` tests **shape only**. `kernel_can_run` tests **capability**
(`uint8 × int8`, zero weight-zp, no left shift, clip `[0,255]`, exact
`STEM_GEOMETRY`) and is called during **selection**, returning `(ok, reason)`.

They used to be one function, with the geometry gate inside the `MergeComposite`
checker. Symptoms of that arrangement, if you ever reintroduce it:

- Only the one already-offloadable layer ever fused. `--aie-layers 7` could not
  report anything: "malformed" and "not the stem" were the same silence.
- The inline-back path in `aie_annotate.visit_call` was **unreachable** — a
  composite existed only if it was also selectable, so `take` was always true.
- No place to stand to add a second kernel.

`deploy_flow` now distinguishes `info["unmatched"]` (did not fuse — the pattern
does not describe this shape) from `info["rejected"]` (fused; the kernel said
why it cannot run it).

## The trap this created: inline-back is now hot

~12 of ResNet-18's convs fuse and are then **inlined back**
(`relay.bind(op.body, dict(zip(op.params, new_args)))`) on every offload run.
Stage 6a rebuilds the **whole** C from the partitioned module, not just the AIE
subgraph — so a non-bit-identical round-trip silently changes **every CPU layer**,
not only the offloaded one.

The gate is `verify_aie_stem.py` step 4: build the whole network twice on LLVM,
partitioned and unpartitioned, and require all 1000 logits identical. Its
docstring is explicit that this covers "the re-canonicalized CPU remainder of the
graph (partitioning changes how the rest is built)". If CPU-only layers start
differing after an offload run, that is this, not the kernel.

```bash
PYTHONPATH=src python3 src/frontend/tvmrelay/byoc/verify_aie_stem.py
```

If inline-back ever fails to round-trip, the fallback is to apply the capability
gate during fusion again for *unselected* layers only — smaller win, preserves
the old IR exactly.

## Adding a second AIE kernel

Two edits, and nothing else in the flow branches on the op:

1. `aie_patterns.pattern_table()` — add `(name, pattern, checker)`. If two
   patterns can match the same chain, put the most specific first:
   `MergeComposite` tries them in order.
2. `aie_codegen._EMITTERS` — add `name: emitter`, signature
   `(func, composite, symbol, label) -> C source`.

`_find_composite` looks up by **membership in `_EMITTERS`**, not against one
constant, so step 4 needs no other change. Write the pattern against the real
**post-canonicalize** IR (`nn.conv2d`, `fixed_point_multiply_per_axis`, …), not
`qnn.*` — see `aie_patterns`' module docstring for why matching qnn directly
fails.

## Layer identity lives in the IR

- `aie.weight_fp` — stamped on every composite in step 1. The sorted-weight SHA1
  (`weight_fingerprint`), which is layout- and dtype-independent.
- `aie.layer_id` — stamped in step 2 on selected composites only; the
  `--aie-layers` number, so codegen errors can name the argument that caused them.

**Never key selection on a position.** Relay's post-order and the graph
executor's order differ (TVM fuses each ResNet shortcut conv with its residual
add), so convs 5-7, 10-12, 15-17 swap. `deploy_flow` passes the full
`{fingerprint: layer}` mapping — not just its keys — so the layer number reaches
the IR.

`ConvSelectAnnotator._identity` **recomputes** the fingerprint when the tag is
absent. Keep that fallback: trusting the attribute alone turns a lost tag into
"selected nothing", which on the console is indistinguishable from a pattern
miss.

## Debugging

`AIE_BYOC_DEBUG=1` prints every non-match and every rejection reason. Without it,
"did not match" and "matched but rejected" look identical in the final IR.

```bash
AIE_BYOC_DEBUG=1 PYTHONPATH=src python3 src/frontend/tvmrelay/deploy_flow.py \
    --aie-offload --aie-layers 1 --local
```

Expect `1/4 fuse  : aie.qconv_fused x13`, `2/4 select: annotated 1`,
`3/4 part  : 1 AIE subgraph(s)`, and `local vs cpu: MATCH`. A fuse count of 1 means
a capability check has leaked back into `check_fused_qconv`.

## `1/4 fuse : nothing` under the default flow, with no debug rejection (2026-10-10)

`AIE_BYOC_DEBUG=1` printing *nothing* means the checker never ran, so the
pattern's **structure** missed. The cause is the qnn zero-point fold (default
on, `qnn_fold_zp`). Once the kernel zero-point is a scalar 0, canonicalization
emits the stem as
`nn.conv2d → subtract(C) → bias_add → cast → subtract(C4) → fpm → clip → cast`.
The input-zp term `113·Σw` has become a constant **subtract**, and the
window-sum term is gone. `fused_qconv_pattern` still requires
`add(acc, CONST)` (C2), which it was written for, against the unfolded IR.

Proof: `deploy_flow.py --aie-offload --no-fold-qnn-zp --aie-layers 6` (the
stem is layer 6 without the fold) prints `aie.qconv_fused x9`, `9/20 convs
fused` and `1 AIE subgraph(s)`.

Fix direction (not done): make the `add` optional and accept
`subtract(conv, CONST)`, and have `extract_fused` map it to C2 with the sign
flipped. Gate it with `verify_aie_stem.py`. Meanwhile layer 01 offloads via
the aiegraph path (skill aieoffloadaiegraph).
