# TVM-no-fuse + aiegraph-fuse + offload Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Move graph fusion out of TVM's `FuseOps` into our own `walk.py` fusion pass — import the primitive Relay graph, fuse primitives into the existing 4 aiegraph fused ops, and reuse the existing `is_aie_op` offload split — so the frontend tolerates any TVM grouping while staying bit-exact.

**Architecture:** Python-only change to the TVM frontend. `relay_import.py` drops `FuseOps`. `walk.py` gains `recover_primitives()` (flat primitive walk, distinguishing BN mul/add-const from residual add-tensor) and `fuse_primitives()` (greedy matcher → `List[LayerOp]`). `build_plan` calls these, keeps `validate_against_canonical` + canonical fallback (bit-exact). The aiegraph dialect, pybind, `cpu_codegen.py`, and `model.py` are untouched.

**Tech Stack:** Python, TVM Relay (`relay.ExprVisitor`, `tvm.relay.Constant`), numpy. Tests run under plain `python test_tvm_frontend.py` (custom PASS/FAIL harness, TVM-gated with `tvm_available()`).

**Design doc:** `docs/plans/2026-09-09-aiegraph-primitive-fusion-offload-design.md`

---

## Background the executor needs

- `model.LayerOp` (`src/frontend/tvm/model.py:52`) fields used here: `op` (str),
  `H, W, Cin, Cout, K, stride`, plus `spatial_h, spatial_w, channels, num_classes`
  (fc), `length` (residual), `bn_scale` (default `BN_SCALE_DEFAULT=64`), `bn_bias=0`.
  `LayerOp.signature()` (`model.py:125`) is the structural tuple.
- `model.layer_plan()` (`model.py:169`) is the canonical ~29-op plan (hand-verified
  buffer wiring). Input geometry: `INPUT_H, INPUT_W, INPUT_C = 8, 8, 1` (`model.py:35`).
- Current `walk.py`: `recover_signatures()` walks the FUSED graph and records
  `conv2d/relu/add/gap/dense` tuples; `validate_against_canonical()` compares
  ordered conv geometry + counts; `build_plan()` returns canonical on match/fallback.
- After `SimplifyInference`, BatchNorm becomes `multiply(x, const)` + `add(x, const)`.
  With `FuseOps` dropped these are TOP-LEVEL Calls. A residual is `add(tensorA, tensorB)`
  where NEITHER arg is a `relay.Constant`. This is the key discriminator.
- Test harness pattern (`test_tvm_frontend.py`): each test is a function; a runner
  at the bottom calls them and prints PASS/FAIL. TVM-only tests early-return (skip)
  when `not tvm_available() or not onnx_available()`.

**Verification command for every task:** `python src/frontend/tvm/test_tvm_frontend.py`
(must end with all PASS and no FAIL, both with and without TVM installed).

---

## Task 1: Drop FuseOps from the Relay import pipeline

**Files:**
- Modify: `src/frontend/tvm/relay_import.py:66-72`

**Step 1: Write the failing test**

Add to `src/frontend/tvm/test_tvm_frontend.py` (above the runner):

```python
def test_import_is_unfused():
    """After dropping FuseOps, BN multiply/add appear as top-level primitives."""
    if not tvm_available() or not onnx_available():
        print("SKIP test_import_is_unfused (no tvm/onnx)")
        return
    import tvm
    from tvm import relay
    from frontend.tvm.relay_import import import_relay
    onnx_path = os.path.join(_HERE, "_plan_unfused.onnx")
    model.export_onnx(onnx_path)
    mod, _ = import_relay(onnx_path, input_name="input",
                          input_shape=(1, model.INPUT_C, model.INPUT_H, model.INPUT_W))
    names = []
    class _V(relay.ExprVisitor):
        def visit_call(self, call):
            for a in call.args:
                self.visit(a)
            names.append(getattr(call.op, "name", ""))
    _V().visit(mod["main"])
    # No FuseOps => primitive conv2d and folded-BN multiply/add are all top level.
    assert "nn.conv2d" in names
    assert "multiply" in names, "BN scale should be a top-level multiply"
    assert "add" in names, "BN shift / residual should be a top-level add"
    os.remove(onnx_path)
    print("PASS test_import_is_unfused")
```

Register it in the runner list at the bottom of the file.

**Step 2: Run to verify it fails**

Run: `python src/frontend/tvm/test_tvm_frontend.py`
Expected: `test_import_is_unfused` FAILs (with TVM installed) because `multiply`/`add`
are hidden inside fused inner functions — the top-level visitor won't see them.
(If TVM is not installed it SKIPs; in that case this task's behavior can't be
verified locally — note it and proceed, later tasks are TVM-gated too.)

**Step 3: Make the minimal change**

In `src/frontend/tvm/relay_import.py`, remove the `FuseOps` line from the
`Sequential` (lines 66-72):

```python
    seq = tvm.transform.Sequential([
        relay.transform.InferType(),
        relay.transform.SimplifyInference(),  # BN -> multiply + add
        relay.transform.FoldConstant(),
        relay.transform.InferType(),
    ])
```

Also update the module docstring (`relay_import.py:7-17`) to drop the `FuseOps`
line and say the graph is left in primitive form for our own fusion pass.

**Step 4: Run to verify it passes**

Run: `python src/frontend/tvm/test_tvm_frontend.py`
Expected: `test_import_is_unfused` PASS; all other tests still PASS.

**Step 5: Commit**

```bash
git add src/frontend/tvm/relay_import.py src/frontend/tvm/test_tvm_frontend.py
git commit -m "feat(tvm): drop FuseOps so Relay import yields primitive graph"
```

---

## Task 2: `recover_primitives()` — flat primitive walk with BN/residual discrimination

**Files:**
- Modify: `src/frontend/tvm/walk.py` (add function; keep `recover_signatures` for now)
- Test: `src/frontend/tvm/test_tvm_frontend.py`

**Step 1: Write the failing test**

```python
def test_recover_primitives():
    """Primitive walk records conv/mul-const/add-const/add-tensor/relu/gap/dense."""
    if not tvm_available() or not onnx_available():
        print("SKIP test_recover_primitives (no tvm/onnx)")
        return
    from frontend.tvm import walk
    onnx_path = os.path.join(_HERE, "_plan_prims.onnx")
    model.export_onnx(onnx_path)
    prims = walk.recover_primitives(onnx_path)
    kinds = [p[0] for p in prims]
    assert "conv2d" in kinds
    assert "bn_mul" in kinds, "BN multiply(const) must be tagged bn_mul"
    assert "bn_add" in kinds, "BN add(const) must be tagged bn_add"
    assert "res_add" in kinds, "residual add(tensor,tensor) must be tagged res_add"
    assert "relu" in kinds and "gap" in kinds and "dense" in kinds
    # first op is the stem conv, with geometry (H,W,Cin,Cout,K,stride)
    first_conv = next(p for p in prims if p[0] == "conv2d")
    assert first_conv[1:] == (model.INPUT_H, model.INPUT_W, model.INPUT_C,
                              first_conv[4], first_conv[5], first_conv[6])
    os.remove(onnx_path)
    print("PASS test_recover_primitives")
```

Register it in the runner.

**Step 2: Run to verify it fails**

Run: `python src/frontend/tvm/test_tvm_frontend.py`
Expected: FAIL — `walk.recover_primitives` does not exist (`AttributeError`).

**Step 3: Implement `recover_primitives`**

Add to `src/frontend/tvm/walk.py`:

```python
def _is_const(expr) -> bool:
    """True iff a Relay expr is a compile-time constant (BN scale/shift/bias)."""
    import tvm
    from tvm import relay
    return isinstance(expr, relay.Constant)


def recover_primitives(onnx_path: str) -> List[tuple]:
    """Walk the UNFUSED Relay graph; return primitive ops in dataflow order.

    Tags each recorded op so the fusion matcher can group them:
      ("conv2d", H, W, Cin, Cout, K, stride)
      ("bn_mul",)   multiply(x, Constant)     -> BN scale
      ("bn_add",)   add(x, Constant)          -> BN shift
      ("res_add",)  add(tensorA, tensorB)     -> residual join
      ("relu",)
      ("gap",)
      ("dense", channels, nclass)
      ("bias_add",) add(x, Constant) following a dense  (fc bias)

    A residual add is distinguished from a BN/bias add by the constant test:
    BN/bias adds have exactly one Constant operand; a residual add has none.
    Raises RuntimeError if TVM/onnx are unavailable.
    """
    import tvm
    from tvm import relay

    mod, _params = import_relay(onnx_path, input_name="input",
                               input_shape=(1, model.INPUT_C, model.INPUT_H, model.INPUT_W))
    prims: List[tuple] = []
    saw_dense = {"v": False}

    class _Walker(relay.ExprVisitor):
        def visit_call(self, call):
            for a in call.args:
                self.visit(a)
            name = getattr(call.op, "name", "")
            if name == "nn.conv2d":
                cin, cout, k, stride = _conv_signature(call)
                h, w = _feature_hw(call)
                prims.append(("conv2d", h, w, cin, cout, k, stride))
            elif name == "multiply":
                if any(_is_const(a) for a in call.args):
                    prims.append(("bn_mul",))
            elif name == "add":
                has_const = any(_is_const(a) for a in call.args)
                if has_const:
                    prims.append(("bias_add",) if saw_dense["v"] else ("bn_add",))
                else:
                    prims.append(("res_add",))
            elif name == "nn.relu":
                prims.append(("relu",))
            elif name == "nn.global_avg_pool2d":
                prims.append(("gap",))
            elif name == "nn.dense":
                wshape = [int(x) for x in call.args[1].checked_type.shape]
                prims.append(("dense", wshape[1], wshape[0]))  # (channels, nclass)
                saw_dense["v"] = True

    _Walker().visit(mod["main"])
    return prims
```

**Step 4: Run to verify it passes**

Run: `python src/frontend/tvm/test_tvm_frontend.py`
Expected: `test_recover_primitives` PASS; others still PASS.

**Step 5: Commit**

```bash
git add src/frontend/tvm/walk.py src/frontend/tvm/test_tvm_frontend.py
git commit -m "feat(tvm): recover_primitives walks unfused graph, tags BN vs residual add"
```

---

## Task 3: `fuse_primitives()` — greedy matcher → LayerOp structure

**Files:**
- Modify: `src/frontend/tvm/walk.py` (add `fuse_primitives`)
- Test: `src/frontend/tvm/test_tvm_frontend.py`

**Step 1: Write the failing tests**

```python
def test_fuse_primitives_structure():
    """fuse_primitives groups tagged primitives into the canonical op sequence."""
    from frontend.tvm import walk
    # Synthetic primitive stream (no TVM needed): stem conv+bn+relu, a residual,
    # and the gap+dense tail. Geometry values are placeholders for structure only.
    prims = [
        ("conv2d", 8, 8, 1, 8, 3, 1), ("bn_mul",), ("bn_add",), ("relu",),
        ("conv2d", 8, 8, 8, 8, 3, 1), ("bn_mul",), ("bn_add",),        # conv_bn
        ("res_add",), ("relu",),                                        # residual
        ("gap",), ("dense", 8, 4), ("bias_add",),                      # avgpool_fc
    ]
    ops = [op.op for op in walk.fuse_primitives(prims)]
    assert ops == ["conv_bn_relu", "conv_bn", "residual_add_relu", "avgpool_fc"]
    print("PASS test_fuse_primitives_structure")


def test_fuse_primitives_conv_geometry():
    """Conv geometry is carried onto the fused LayerOp."""
    from frontend.tvm import walk
    prims = [("conv2d", 8, 8, 1, 8, 3, 1), ("bn_mul",), ("bn_add",), ("relu",)]
    op = walk.fuse_primitives(prims)[0]
    assert (op.op, op.H, op.W, op.Cin, op.Cout, op.K, op.stride) == \
        ("conv_bn_relu", 8, 8, 1, 8, 3, 1)
    print("PASS test_fuse_primitives_conv_geometry")
```

Register both in the runner. (These need NO TVM — pure structure logic.)

**Step 2: Run to verify they fail**

Run: `python src/frontend/tvm/test_tvm_frontend.py`
Expected: FAIL — `walk.fuse_primitives` does not exist.

**Step 3: Implement `fuse_primitives`**

Add to `src/frontend/tvm/walk.py`. Keep it well under 200 lines:

```python
def fuse_primitives(prims: List[tuple]) -> List[LayerOp]:
    """Greedily fuse the tagged primitive stream into fused LayerOps.

    Grouping windows (left to right):
      conv2d [bn_mul] [bn_add] relu       -> conv_bn_relu
      conv2d [bn_mul] [bn_add]            -> conv_bn
      res_add relu                        -> residual_add_relu
      gap dense [bias_add]                -> avgpool_fc

    Geometry is carried from the conv/dense primitive; buffer wiring (ins/out
    names, residual length) is NOT recovered here — build_plan validates this
    structure against the canonical plan and returns the canonical (wired) plan.
    Placeholder buffer names keep the LayerOps constructible/inspectable.
    """
    ops: List[LayerOp] = []
    i, n = 0, len(prims)
    idx = 0
    while i < n:
        tag = prims[i][0]
        if tag == "conv2d":
            _, h, w, cin, cout, k, stride = prims[i]
            j = i + 1
            while j < n and prims[j][0] in ("bn_mul", "bn_add"):
                j += 1
            relu = j < n and prims[j][0] == "relu"
            opname = "conv_bn_relu" if relu else "conv_bn"
            ops.append(LayerOp(op=opname, out=f"_f{idx}", ins=(f"_i{idx}",),
                               H=h, W=w, Cin=cin, Cout=cout, K=k, stride=stride))
            i = j + 1 if relu else j
        elif tag == "res_add":
            relu = i + 1 < n and prims[i + 1][0] == "relu"
            ops.append(LayerOp(op="residual_add_relu", out=f"_f{idx}",
                               ins=(f"_a{idx}", f"_b{idx}"), length=0))
            i = i + 2 if relu else i + 1
        elif tag == "gap":
            channels, nclass = 0, 0
            j = i + 1
            if j < n and prims[j][0] == "dense":
                channels, nclass = prims[j][1], prims[j][2]
                j += 1
            if j < n and prims[j][0] == "bias_add":
                j += 1
            ops.append(LayerOp(op="avgpool_fc", out=f"_f{idx}", ins=(f"_i{idx}",),
                               spatial_h=1, spatial_w=1,
                               channels=channels, num_classes=nclass))
            i = j
        else:
            i += 1  # stray primitive (already consumed by a window); skip
            continue
        idx += 1
    return ops
```

NOTE: verify the exact `LayerOp` constructor kwargs against `model.py:52-90`
before running — adjust `out`/`ins` names to the real field names (they may be
`out`/`ins`). If a required field has no default, pass a benign placeholder.

**Step 4: Run to verify they pass**

Run: `python src/frontend/tvm/test_tvm_frontend.py`
Expected: both new tests PASS; all others PASS.

**Step 5: Commit**

```bash
git add src/frontend/tvm/walk.py src/frontend/tvm/test_tvm_frontend.py
git commit -m "feat(tvm): fuse_primitives greedily groups primitives into fused ops"
```

---

## Task 4: Route `build_plan` through primitive-walk + fuse

**Files:**
- Modify: `src/frontend/tvm/walk.py` (`build_plan`, `validate_against_canonical`)
- Test: `src/frontend/tvm/test_tvm_frontend.py`

**Step 1: Write the failing test**

```python
def test_build_plan_via_fusion_matches_canonical():
    """build_plan (now primitive-walk + fuse) still yields the canonical plan."""
    if not tvm_available() or not onnx_available():
        print("SKIP test_build_plan_via_fusion (no tvm/onnx)")
        return
    from frontend.tvm import walk
    onnx_path = os.path.join(_HERE, "_plan_fuse.onnx")
    model.export_onnx(onnx_path)
    plan = walk.build_plan(onnx_path, strict=True)   # strict: must match, no silent fallback
    canonical = model.layer_plan()
    assert [op.op for op in plan] == [op.op for op in canonical]
    os.remove(onnx_path)
    print("PASS test_build_plan_via_fusion")
```

**Step 2: Run to verify it fails**

Run: `python src/frontend/tvm/test_tvm_frontend.py`
Expected (with TVM): may FAIL if `build_plan` still calls `recover_signatures`
and the new validation path isn't wired. (Skips without TVM.)

**Step 3: Rewire `build_plan`**

In `src/frontend/tvm/walk.py`, change `build_plan` to use the new functions:

```python
    try:
        prims = recover_primitives(onnx_path)
        fused = fuse_primitives(prims)
    except Exception:
        if strict:
            raise
        return canonical

    recovered = [(op.op, op.H, op.W, op.Cin, op.Cout, op.K, op.stride)
                 if op.op in ("conv_bn_relu", "conv_bn") else (op.op,)
                 for op in fused]
    ok = validate_fused_against_canonical(fused, canonical)
    if not ok and strict:
        raise RuntimeError(
            "Fused-primitive structure does not match the canonical plan:\n"
            f"  recovered ops: {[op.op for op in fused]}")
    return canonical
```

Add a fused-plan validator (compare `LayerOp` structure directly, DRY with the
existing conv-geometry check):

```python
def validate_fused_against_canonical(fused: List[LayerOp],
                                     canonical: List[LayerOp]) -> bool:
    """True iff the fused op sequence matches the canonical plan structurally."""
    rec_convs = [(op.H, op.W, op.Cin, op.Cout, op.K, op.stride)
                 for op in fused if op.op in ("conv_bn_relu", "conv_bn")]
    can_convs = [(op.H, op.W, op.Cin, op.Cout, op.K, op.stride)
                 for op in canonical if op.op in ("conv_bn_relu", "conv_bn")]
    if rec_convs != can_convs:
        return False
    rec_res = sum(1 for op in fused if op.op == "residual_add_relu")
    can_res = sum(1 for op in canonical if op.op == "residual_add_relu")
    if rec_res < can_res:
        return False
    has_fc = any(op.op == "avgpool_fc" for op in canonical)
    if has_fc and not any(op.op == "avgpool_fc" for op in fused):
        return False
    return True
```

Delete `recover_signatures` and the old `validate_against_canonical` ONLY if no
other module imports them (grep first: `grep -rn recover_signatures src/`). If
referenced elsewhere, leave them; otherwise remove to avoid dead code.

**Step 4: Run to verify it passes**

Run: `python src/frontend/tvm/test_tvm_frontend.py`
Expected: `test_build_plan_via_fusion` PASS; `test_plan_matches_canonical` PASS;
all others PASS.

**Step 5: Commit**

```bash
git add src/frontend/tvm/walk.py src/frontend/tvm/test_tvm_frontend.py
git commit -m "feat(tvm): build_plan uses primitive-walk + fuse_primitives"
```

---

## Task 5: Offload transparency log

**Files:**
- Modify: `src/frontend/tvm/_compiler.py:323-330` (the `compile_plan_via_aiegraph` loop)
- Test: `src/frontend/tvm/test_tvm_frontend.py`

**Step 1: Write the failing test**

```python
def test_offload_dispatch_labels():
    """is_aie_op labels each op's backend (pure predicate, no build needed)."""
    plan = model.layer_plan()
    labels = [("AIE" if cpu_codegen.is_aie_op(op.op) else "CPU") for op in plan]
    assert "AIE" in labels and "CPU" in labels
    # conv ops -> AIE, residual/avgpool -> CPU
    for op, lab in zip(plan, labels):
        if op.op in ("conv_bn", "conv_bn_relu"):
            assert lab == "AIE"
        else:
            assert lab == "CPU"
    print("PASS test_offload_dispatch_labels")
```

**Step 2: Run to verify it fails/passes**

Run: `python src/frontend/tvm/test_tvm_frontend.py`
Expected: this test PASSES already (predicate exists) — it documents/locks the
offload contract. If it fails, `is_aie_op` semantics changed; stop and review.

**Step 3: Add the transparency log**

In `_compiler.compile_plan_via_aiegraph`, inside the loop, before the
`if cpu_codegen.is_aie_op(op.op):` branch, add:

```python
        backend = "AIE" if cpu_codegen.is_aie_op(op.op) else "CPU"
        print(f"[tvm-offload] launch {idx:02d} {op.op} -> {backend}")
```

**Step 4: Run to verify it passes**

Run: `python src/frontend/tvm/test_tvm_frontend.py`
Expected: all PASS.

**Step 5: Commit**

```bash
git add src/frontend/tvm/_compiler.py src/frontend/tvm/test_tvm_frontend.py
git commit -m "feat(tvm): log per-launch offload backend (AIE|CPU)"
```

---

## Task 6: Update documentation

**Files:**
- Modify: `doc/design/tvm_frontend.md` ("Fused-graph walk (walk.py)" section)

**Step 1: Edit the doc**

Rewrite the "Fused-graph walk" section to describe the new flow:
- `relay_import` no longer runs `FuseOps`; the graph is left primitive.
- `recover_primitives()` walks the flat primitive graph, tagging BN
  `multiply(const)`/`add(const)` vs residual `add(tensor,tensor)` vs `bias_add`.
- `fuse_primitives()` is OUR fusion pass producing the 4 fused ops.
- `validate_fused_against_canonical` + canonical fallback keeps it bit-exact.
- Offload is unchanged (`is_aie_op`), now with a per-launch log line.

Add a one-line pointer to the design doc
`docs/plans/2026-09-09-aiegraph-primitive-fusion-offload-design.md`.

**Step 2: Verify docs build/readable**

Run: (no build) re-read the section for accuracy against the final `walk.py`.

**Step 3: Commit**

```bash
git add doc/design/tvm_frontend.md
git commit -m "docs(tvm): describe primitive-walk + our-fusion + offload flow"
```

---

## Final verification

Run: `python src/frontend/tvm/test_tvm_frontend.py`
Expected: every test prints PASS (or SKIP where TVM/onnx/extension absent), no FAIL.

If TVM is installed, additionally sanity-check end-to-end:
Run: `python -c "from frontend.tvm import run_resnet; r=run_resnet(emit_aie=False); print(len(r.plan), r.predicted_class)"`
(from `src/`) — expect a full plan length and a valid class, unchanged from before.

## Risks / watch-items for the executor

1. **`LayerOp` constructor kwargs** — confirm real field names (`out`, `ins`,
   etc.) at `model.py:52-90`; the plan's placeholders must match or use defaults.
2. **Constant detection** — `FoldConstant` may wrap BN scale/shift so the operand
   is a `relay.Constant`; if a build represents it as a bound var instead, the
   `_is_const` test needs to also treat 0-d/param-bound operands as const. Verify
   on the real graph in Task 2; if `bn_mul`/`bn_add` don't appear, inspect the
   actual `add`/`multiply` arg types and widen `_is_const`.
3. **`bias_add` vs `bn_add` ordering** — the `saw_dense` flag assumes dense is
   visited before its bias add (post-order guarantees args first, so dense (arg)
   is visited before the enclosing add). Confirm in Task 2's output.
4. Keep every new function well under 200 lines (project rule).
