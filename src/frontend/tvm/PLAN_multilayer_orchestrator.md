# Multi-Layer Host Orchestrator — Remaining Plan (Tasks 6–9)

> **For Claude:** Execute via `superpowers:subagent-driven-development`
> (implementer → spec reviewer → code-quality reviewer per task). Never fake a
> build; the goal is a *real* `main.elf` that truly links and runs on board
> `palmyra`.

**Goal:** Produce ONE ARM `main.elf` that runs all ~29 TVM-frontend ResNet layers
in program order (conv layers on the AIE array, CPU ops on ARM, DDR buffers
chained), plus a standalone A1 reconstruction path.

**Architecture:** A2 primary → A1 reconstruction, both independently buildable.
- **A2:** drive the existing C++ multi-kernel plumbing via pybind
  `orchestrate_conv_layer` + Python `orchestrator.py` (emits `host.cc`,
  per-conv `kernel_<name>.cc` / `aieml_<name>.bcf|prx`, `main.cc`, CPU op `.c`),
  then link one `main.elf` through `script/hostcompile.sh`.
- **A1:** reconstruct a standalone `resnet.cc` from the A2 artifacts.
- CPU ops (`residual_add_relu`, `avgpool_fc`) run as plain aarch64 C, bit-exact
  with the numpy Q7 int8 oracle.

**Tech stack:** MLIR TilingLinalgPipeline (C++), pybind `_aietriton_core`,
Python `frontend/tvm/{orchestrator,_compiler,cpu_codegen,walk,model}.py`,
`script/hostcompile.sh` (multi-kernel), aarch64 cross g++, xchesscc/Vitis.

---

## Current State (as of this plan)

Tasks 1–5 implemented + reviewed. Task 5's `build_main_elf` exists but its test
`test_orchestrate_builds_elf` (test_tvm_frontend.py:490) SKIPS on a detected
emit defect rather than doing a real build.

**Task 9 (blocker fixes) — status: 5 of 5 defects fixed, real build verifying.**

Five blocker defects found while forcing a real end-to-end build:
1. **[FIXED]** Duplicated timer preamble (`XTime g_xtimer_start;`,
   `#include "aie_runtime.h"` emitted ~20×) — append-mode dedup now also erases
   `emitc::VerbatimOp` in `tilinglinalg_pipeline.cpp` (~797-817).
2. **[FIXED]** `__aie_launch` fixed-arity / weights buffer missing — dispatcher
   now takes `_t0,_t1,_t2` (input, weights, output) and forwards all 3;
   `orchestrator.py` emits weights as a DDR buffer (conv `tensor_specs` arity 3).
3. **[FIXED]** 2-arg `__Runtime_Alloc(dev, sz)` → 1-arg `__Runtime_Alloc(sz)`
   in `orchestrator.py` `_emit_allocs`.
4. **[FIXED]** AIE kernel link failure
   `cannot find free area with size 64 ... for space symbol 'buf_in_pong_0'`
   in `aieml_conv_bn_12.bcf`. Root cause: `CoreMemAllocator` (singleton
   `ResourceMgr`) **dedups by symbol name** and persists across the ~20
   `orchestrate_conv_layer` calls in one process, so every conv reused conv #0's
   buffer layout while each `kernel_<name>.cc` emitted its own (larger) `v4int8[N]`
   arrays → address/size mismatch the AIE linker rejects.
   **Fix:** reset the allocator at the start of `TilingLinalgPipeline::runPipeline`
   (tilinglinalg_pipeline.cpp ~456-474), wrapped in try/catch (on the first run
   `ResourceMgr::init()` has not run yet → instance() throws → empty allocator,
   safe no-op; later runs reset the persisted singleton before the host
   allocation pass repopulates it).
   **Verified:** regenerated BCFs now differ per conv — e.g. `conv_bn_12` has
   `buf_in_pong_1 @0x78140` (0x140=320B spacing, matching its `buf_in_ping_1[74]`
   v4int8 = 296B → 320B aligned) vs `conv_bn_relu_0`'s 0x20=32B spacing.
   With this fix ALL ~20 AIE kernels compile; the failure moved to the host link
   (defect #5).
5. **[FIXED]** Host compile error `cannot convert 'aieMesh' to 'int'` at every
   `__aie_launch(...)` call site. Root cause: `_fold_main_into_host`
   (orchestrator.py) appended the `_AIE_MESH_PREAMBLE` (the `struct aieMesh`
   definition) at the END of host.cc — i.e. AFTER the `__aie_launch` dispatcher
   that `orchestrate_plan` had already appended — so the dispatcher referenced
   `aieMesh` / `mesh.meshId` before the struct was defined (g++ recovered by
   treating the param as implicit `int`, then rejected the real `aieMesh` struct
   built in `main()`). The function's own comment already stated the intent
   ("right after host.cc's existing `#include \"aie_runtime.h\"`"); the code did
   not match. **Fix:** splice `_AIE_MESH_PREAMBLE` in right after the leading
   `#include "aie_runtime.h"` line instead of at end-of-file.
   **Verified:** freshly-folded host.cc now has `struct aieMesh {` at line 7,
   `inline void __aie_launch` at line 5111, folded main at 5376 — struct precedes
   both uses. Python-only change (no `.so` rebuild).

**Files changed by Task 9 (do NOT commit the `.so`):**
- `src/mlir/mlirfront/tilinglinalg/pass/tilinglinalg_pipeline.cpp`
  (VerbatimOp dedup + allocator reset)
- `src/frontend/tvm/orchestrator.py` (weights DDR buffer, 3-buffer launch,
  1-arg alloc, mesh-preamble ordering in `_fold_main_into_host`)
- `src/frontend/tvm/test_tvm_frontend.py` (un-skip once real ELF verified)

**Rebuild + install `.so` after any C++ change:**
```bash
cd build && cmake --build . --target _aietriton_core -j 8
cp build/src/mlir/mlirfront/frontend/aietriton/_aietriton_core.cpython-310-x86_64-linux-gnu.so \
   src/mlir/mlirfront/frontend/aietriton/
```

**Correct generation invocation (import from `src`, NOT the aietriton dir):**
```python
import sys; sys.path.insert(0, 'src')
from frontend.tvm import _compiler, orchestrator, build_plan
core = _compiler._core()
plan = build_plan(None)
launches = core.lower_aiegraph(_compiler.build_aiegraph_ir(plan))
bd = orchestrator.orchestrate_plan(plan, launches, '/tmp/claude/out')  # returns <out>/build
elf = orchestrator.build_main_elf(bd)   # arranges dir + runs hostcompile.sh; host ELF at <bd>/build/host
```

**Env quirks:** Bash needs `dangerouslyDisableSandbox: true`; a noisy env header
prints on every Bash and swallows short output — write to `/tmp/claude/*.txt`
then grep. Shell var assignments don't persist across the wrapper — use literal
absolute paths. Branch `cnn`. Use `python -m pytest`.

---

## Task 9: Finish the real `main.elf` build + un-skip the test  (IN PROGRESS)

**Files:**
- Verify: `/tmp/claude/a2_fix4b/build/build/host` (the real ARM ELF)
- Modify: `src/frontend/tvm/test_tvm_frontend.py:490-534`
  (`test_orchestrate_builds_elf`)

**Step 1: Confirm the real build produced a host ELF**
Background build was running `orchestrator.build_main_elf('/tmp/claude/a2_fix4b/build')`.
Check for `<bd>/build/host` existence and absence of
`cannot find free area` / `could not allocate` / `error:` in the log.
- If a NEW kernel/link defect appears: root-cause it (same discipline as
  defect #4), fix in the pipeline/orchestrator, rebuild `.so`, regenerate,
  rebuild. Do NOT skip.

**Step 2: Un-skip `test_orchestrate_builds_elf`**
Remove the `XTime g_xtimer_start` duplicated-preamble skip block
(test_tvm_frontend.py:525-532) and the stale NOTE docstring (500-507) now that
the emit defects are fixed. Keep the tool-gating skips (no aarch64 g++, no
xchesscc/XILINX_VITIS) — those are legitimate environment skips.
Assert `elf and os.path.exists(elf)`.

**Step 3: Run the full test suite**
```bash
python -m pytest src/frontend/tvm/test_tvm_frontend.py -v
```
Expected: `test_orchestrate_builds_elf` PASSES (real link) when toolchain present;
all other tests still pass.

**Step 4: Commit** (source only — NEVER the `.so`)
```bash
git add src/mlir/mlirfront/tilinglinalg/pass/tilinglinalg_pipeline.cpp \
        src/frontend/tvm/orchestrator.py \
        src/frontend/tvm/test_tvm_frontend.py
git commit -m "fix(orchestrator): real multi-kernel main.elf links (4 emit/alloc defects)"
```

**Step 5: Dispatch spec reviewer, then code-quality reviewer.**

---

## Task 6: A2 → A1 reconstruction

**Files:**
- Create: `src/frontend/tvm/a2_to_a1.py`
- Test: `src/frontend/tvm/test_tvm_frontend.py` (`test_a2_to_a1_reconstructs`)

**Intent:** From the A2 build artifacts, emit a single standalone `resnet.cc`
(the A1 path) that is independently buildable — a human-readable, self-contained
driver equivalent to the A2 `host.cc` + `main.cc` + dispatcher, with layer calls
inlined in program order.

**Step 1: Write the failing test**
```python
def test_a2_to_a1_reconstructs():
    try:
        core = _compiler._core()
    except Exception as e:
        print("  [skip] pybind not built:", e); return
    import tempfile
    from frontend.tvm import orchestrator, a2_to_a1
    plan = build_plan(None)
    launches = core.lower_aiegraph(_compiler.build_aiegraph_ir(plan))
    with tempfile.TemporaryDirectory() as d:
        bd = orchestrator.orchestrate_plan(plan, launches, d)
        out = os.path.join(d, "resnet.cc")
        a2_to_a1.reconstruct_resnet_cc(bd, plan, launches, out)
        src = open(out).read()
        # one entry point, all conv layers referenced, CPU ops inlined,
        # layers appear in program order.
        assert "int main(" in src
        for op in plan:                       # program order preserved
            assert op.name in src  # or the emitted per-layer symbol
```

**Step 2: Run it — expect FAIL** (`a2_to_a1` missing).

**Step 3: Implement `reconstruct_resnet_cc(build_dir, plan, launches, out_path)`**
- Read the A2 artifacts in `build_dir` (host.cc dispatcher, per-conv launch
  wrappers, CPU op `.c`, DDR buffer graph / sizes).
- Concatenate/inline into a single `resnet.cc` preserving program order and the
  DDR buffer chaining. Keep each emitted function < 200 lines (project rule).
- Reuse `orchestrator`'s buffer-graph + `_emit_*` helpers where possible (DRY);
  do NOT duplicate the alloc/dispatch logic — factor shared emit into a common
  helper if needed.

**Step 4: Run test — expect PASS.**

**Step 5: (optional, if toolchain present) compile-check** the reconstructed
`resnet.cc` through the same `hostcompile.sh` path to prove A1 is independently
buildable.

**Step 6: Commit, then spec + code-quality review.**

---

## Task 7: Dual-build parity + demo Stage 5 + real weights

**Files:**
- Modify: `src/frontend/tvm/demo_flow.py` (add Stage 5)
- Modify: `src/frontend/tvm/orchestrator.py` (`_emit_main`: real weights/params,
  currently memset-zeroed — see TODO)
- Modify/Create: `src/frontend/tvm/model.py` helpers (`make_conv_params`,
  `make_fc_params`) if not already producing real Q7 values
- Test: `src/frontend/tvm/test_tvm_frontend.py` (`test_dual_build_parity`)

**Intent:** Wire real conv weights + fc params (bit-exact with the numpy Q7
oracle) into `main.cc`, wire a real `demo_input`, add a demo_flow Stage 5 that
runs the full A2 build, and assert A2 and A1 produce identical artifacts/outputs.

**Step 1: Write `test_dual_build_parity`** — build both A2 (`main.elf`) and A1
(`resnet.cc`) from the SAME plan; assert the CPU-op numerics match the oracle
(`_compiler._cpu_add_relu`, `_compiler._cpu_avgpool_fc`) and the two build paths
agree (same buffer graph, same layer order, same emitted logits for a fixed
`demo_input`).

**Step 2:** Replace the memset-zero weights/params in `orchestrator._emit_main`
with real values from `model.make_conv_params` / `make_fc_params`
(headerless fc: `[:C*NC]=weights`, `[C*NC:]=bias`). Keep bit-exact with the
oracle.

**Step 3:** Add `demo_flow.py` Stage 5: run `orchestrate_plan` + `build_main_elf`,
report artifact locations; keep Stages 1–4 unchanged.

**Step 4:** Run tests; expect parity PASS.

**Step 5: Commit, then spec + code-quality review.**

---

## Task 8: HW smoke on `palmyra` + docs

**Files:**
- Use: `test/mainelfpaltest.py` (ELF path `/home/huaj/aiehlc/main.elf`)
- Modify: `doc/design/tvm_frontend.md` (new "multi-layer host orchestrator"
  section: A2/A1 paths, DDR buffer chaining, dispatcher, `__aie_launch` ABI,
  allocator-reset requirement, CPU-op fold-in)
- Modify: `.worktrees/cnn/CLAUDE.md` (note the orchestrator + A1/A2 split)

**Step 1:** Copy the built `main.elf` to `/home/huaj/aiehlc/main.elf`
(SSH `huaj@10.23.224.213`, board `palmyra`) and run
`python test/mainelfpaltest.py`. Pass = `device_teardown done`, fail = `AIE ERROR`.

**Step 2:** If HW passes, capture the run log; if it fails, triage via the
data-mismatch-debug command / aiegdb (do NOT fake a pass).

**Step 3:** Update `doc/design/tvm_frontend.md` + `CLAUDE.md`. Per the project
"Process transparent rule", list every changed/created file in the task report.

**Step 4: Commit, then final code review + `superpowers:finishing-a-development-branch`.**

---

## Out of scope (not doing now)
- BYOC graph partitioning; generic Relay→C for arbitrary unknown ops.
- Any change to the single-kernel `aiehlc` path or the GEMM pass pipeline beyond
  the allocator reset (which is a no-op there).

## Verification checklist (all tasks)
1. `.so` rebuilt + copied after every C++ change.
2. `python -m pytest src/frontend/tvm/test_tvm_frontend.py -v` green (real ELF
   test un-skipped when toolchain present).
3. A2 `main.elf` and A1 `resnet.cc` both link.
4. CPU-op numerics bit-exact with the numpy Q7 oracle.
5. HW smoke on palmyra: `device_teardown done`.
6. Docs updated; changed-file list reported per task.
