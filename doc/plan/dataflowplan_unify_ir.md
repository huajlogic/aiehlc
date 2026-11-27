<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Dataflow plan: one representation per IR level -- Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the dataflow plan (MemTile staging, rings, residency, shared readers) a first-class part of
each IR level instead of a parallel side channel, so every level has exactly one way to say "data moves
from A to B", while every build without a plan stays byte-identical and every plan kernel keeps its board
result.

**Architecture:** Today the plan rides next to the generic lowering: an untyped `dataflow` dictionary on
the routing tensor, `dmaphop.plan*` attribute-only ops beside the `create_hop` / `create_path` graph, stand-in
flows generated only to be replaced (`dmaphop.plan_replaced`), a second router (`planroutes.cpp`), a DMA
derivation that skips dfscheblueprint (`plandma.cpp`), a second family of dfschedule DMA ops
(`config.tile_bd` / `lock_set` / `channel_*` vs `config.dma_bd`), and a second kernel block-IO runtime
(`aie_block_io_plan.h`). The plan removes these one level at a time, top down, each stage gated by the same
regression script.

**Tech Stack:** MLIR (TableGen dialects under `src/mlir/mlirfront/tilinglinalg/`), C++ passes, `script/aiehlc.sh`,
`script/test/flowcheck.py`, `script/test/routing_ir_roundtrip.sh`, board runs via `script/test/apppaltest.py`.

---

## Status (evidence per stage)

- [x] **Stage 0** (2026-11-26): open work committed (`97dac2e2`), main merged (`9315c6b2`), gate script
      `script/test/plan_regress.sh`, snapshot of 11 sources, all `flowcheck: OK` (`simpleeltwise_add_none` is a plan
      source -- per-core copies, "8 replaced by the dataflow plan" -- so it moved to the plan list).
- [x] **Stage 1** (2026-11-26): `#routing.dataflow` typed; `compare` -> 11 / 11 `ok`, every generated file of every
      source (plan sources included) byte-identical; `routing_ir_roundtrip.sh gemm_plan.cc` PASS (37 IR stage dumps
      identical). Printed form: `#routing.dataflow<share = "neighbor", stage = "memtile_ring", ring = 10, keep = false,
      parts = 2, axis = "", base_p0 = [], base_p1 = []>`. No board run needed: host.cc / kernel.cc / routing.cc identical.
- [x] **Stages 3.1 + 4** (2026-11-26, `planpaths.cpp`): the plan's routes are `dmaphop.create_hop`s of one
      `dmaphop.create_path` per stream, the stream a typed `#dmaphop.stream` on it; `plan_route` / `plan_stream` are
      an input form only (converted on entry, `gen_plan.py` keeps working), never in the IR after the plan step.
      The paths sit in the `routing.RoutingCreate` region of their tensor's generated flow (ports are symbols);
      DmaphopToRoutinghwPass takes the routes out of them before the generated-flow conversion and emits them at
      the front of the routing function, as before. Evidence: gate 11 / 11 byte-identical (plan sources included);
      `routing_ir_roundtrip.sh --stage dmaphop` PASS on `gemm_plan.cc` and `simpleeltwise_add_plan.cc` (36 IR stage
      dumps identical); `gen_plan.py` old-op form -> its plan-path dump re-entered -> identical files.
- [x] **Stage 3.2 [ASK] -> no** (default without an answer): the IR is one representation; which BFS routes the plan's
      hops is an implementation detail, and one router would change every non-plan `routing.cc`.
- [x] **Stage 6, first part** (2026-11-26): dfscheblueprint carries the WHOLE plan, typed -- `#dmaphop.stream` on each
      shared tensor's `declare_data`, `#dmaphop.route`s + the plan-level facts (args, persistent, BD write-once,
      mesh, pinned resources) on the module (`annotateBlueprint`) -- and the DMA program is derived from what
      `planFromBlueprint` reads back (checked equal to the dmaphop plan, then adopted). Evidence (with 3.1 + 4):
      gate 11 / 11 byte-identical; dmaphop round trips PASS (37 IR stage dumps); the read-back dmaphop dump (plan
      paths + header) re-entered -> identical files; `gen_plan.py` ops -> plan-path dump re-entered -> identical.
      The `dmaphop.plan` header stays next to the paths until `erasePlanPaths`, so the plan-step dump is a complete,
      re-enterable plan; the paths' streams are ordered by `replace_args` on reading (IR order follows the flows).
- [x] **Board, with the unified compiler** (2026-11-26, VEK385_2, every run GOLDEN PASS): `gemm_plan/step0..7` =
      0.012 / 0.389 / 19.6 / 66.1 / 68.3 / 76.4 / 85.67 / 85.68 % of peak; `gemm_plan.cc` (= step 7) 85.68 % >= 85 %.
      The blueprint dump of its own stage (`6_DmaphopTodfscheblueprintPass.mlir`) now shows the plan it carries.
      Tutorial `tutorial/compilerinside/` walks these levels through the IR.
- [ ] **Stage 2 + Stage 6 second part** (the transfer manifests): NOT done. The replaced generated flow still
      exists, tagged `dmaphop.plan_replaced`; its only remaining roles are the kernel's window (window_init, its
      core memory = the plan's chunk slots) and the blueprint transfer the core-side window config is derived from.
      Removing it needs a blueprint transfer that names a plan stream as its source (staged, multi-reader), so the
      kernel-side window / memory come from the plan -- the two belong together; a follow-up.
- [x] **Stage 5 [ASK] -> no** (default without an answer): `config.dma_bd` (a buffer operand, SSA packet / OOO ids, a
      BD handle that must be consumed) and `config.tile_bd` (a hardware BD over a tile's own memory, no handle) are
      different abstractions; one op would be a union of both.
- [x] **Stage 7 -> evaluated, not changed**: the kernel already has ONE block-IO API; `aie_block_io_plan.h` is the
      implementation the IR's plan selects (hosted slots, hand-on locks) and falls back to the window per operand.
      Making a window "the one-reader case of the slot protocol" changes every non-plan kernel's code for no IR gain;
      `aiehlc_plan.h` stays the one constant source both the host and the kernel compile read.

## Where the two representations meet today (survey 2026-11-26)

| level | generic | plan | where |
|---|---|---|---|
| routing | `#routing.tiling`, `#routing.kernel_block` (typed) | `dataflow` DictionaryAttr (untyped) on `routingcreatescheduletensor` | set `pass/tilinglinalg_pipeline.cpp:720-743`, read `pass/dataflowplan/plansynth.cpp:622` |
| dmap | -- | special case for `dataflow` tensors | `pass/passdmaptodmaphop/dmaptodmaphop.cpp:352-355` (`createDataIOAtPoint` stand-in) |
| dmaphop | `port`, `create_hop`, `create_path`, `alloc_buffer`, `push` / `pull` | `plan`, `plan_route`, `plan_stream`, `plan_resources` (attr-only); replaced flows tagged `dmaphop.plan_replaced` | `dataflowmap/dmaphop/td/dmaphopop.td:256-302, 386-407`; tagging `pass/dataflowplan/dataflowplan.cpp:293-384` |
| routing (switches) | `RoutingPath` BFS | `planroutes.cpp` BFS with the router port model | `pass/routingimplement/`, `pass/passdmaphoptoroutinghw/planroutes.cpp:284` |
| dfscheblueprint | full transfer manifests | absent (record only: `dfscheblueprint.plan` from read-back) | `pass/dataflowplan/planreadback.cpp:466` |
| dfschedule | `config.dma_bd` (shim, core) | `config.tile_bd`, `config.lock_set`, `config.channel_enable`, `config.channel_start` (MemTile, core) + `config.dma_bd` for its shims | `dataflowmap/dfschedule/td/dfscheduleop.td:174, 226-280`; derived `pass/dataflowplan/plandma.cpp` |
| kernel lowering | `declaretile.self` DMA config | the same, plus the `dfschedule.core_offload_plan` fallback channel | `pass/passdfscheduletokernelapi/passdfscheduletokernelapi.cpp:51-129` |
| routinghw | -- | **already one**: `plan_route` lowered to ordinary routinghw ops | `planroutes.cpp` |
| runtime / generated code | `aie_block_io.h` windows | `aie_block_io_plan.h` slots + locks, selected by `AIEHLC_PLAN_SHARED`; constants in a separate `aiehlc_plan.h` | `src/mlir/runtime/aie_block_io.h:152-154` |
| core memory | allocator windows | plan reuses the **replaced** ports' windows | `pass/dataflowplan/planresource.cpp:159, 257-277, 406, 458-516` |

## Rules for every stage

- One `aiehlc.sh` at a time; board runs serial. Never touch another session's worktree.
- **Regression gate** (Task 0's script, run at the end of every stage, output pasted as evidence):
  1. non-plan sources: every generated file byte-identical to the stage-0 snapshot;
  2. plan sources: flowcheck OK; generated files identical unless the stage says which may change and why;
  3. `routing_ir_roundtrip.sh` (routing and dmaphop stage) OK on one plan and one non-plan source;
  4. board: `gemm_plan.cc` VEK385_2 GOLDEN PASS and steady >= 85.4 % (stage 0: 85.63 %); `gemm_plan_4x2.cc`,
     `simpleeltwise_add_plan.cc`, `simpleconv2dkernel_port_plan.cc` GOLDEN PASS; non-plan sources need a board
     run only if any generated file changed.
- Close a stage with: design doc `doc/design/dmaphop_dataflow_plan.md` + CLAUDE.md + skill
  `dmaphopdataflowplan` updated, `python3 script/ci/check_opensource.py --all` PASS, one commit. Never push.
- **Stop and ask the user** at the checkpoints marked **[ASK]** (a stage that changes non-plan output on purpose,
  or deletes a user-visible op / attribute).
- Tick a check only with its evidence (command output, GOLDEN / PERF SUMMARY line, commit) next to it.

Sources used by the gate:

| kind | source |
|---|---|
| non-plan | `example/tileprogram/ccode/simplematmul2.cc`, `simplegemm_kernel_port.cc`, `simplegemm_dataflow.cc`, `simpleconv2d.cc`, `simpleconv2dkernel_port_less.cc` |
| plan | `simpleeltwise_add_none.cc` (per-core copies), `gemm_plan/gemm_plan.cc`, `gemm_plan/gemm_plan_4x2.cc`, `gemm_plan/gemm_plan_bring.cc`, `simpleeltwise_add_plan.cc`, `simpleconv2dkernel_port_plan.cc` |

---

## Stage 0: clean baseline

### Task 0.1: bring the branch up to main and commit the open work

**Files:** none new (merge + the uncommitted files of 2026-11-25/26).

**Step 1:** `git status --short` -- list the uncommitted files; check each against the copyright and
English-only rules (CLAUDE.md "Working rules"). `perftest/gemm90/*.patch` are our own diffs.
**Step 2:** commit the open work on `gemm-dmaphop-ir` (message: "gemm 90 % study: loss tables, wait_io basis,
kcyc_lst for gemm_plan, perftest/gemm90").
**Step 3:** `git merge main` (13 commits: docker / LLVM / setup; one runtime `#error` guard in `aie_runtime.c`).
**Step 4:** build `gemm_plan.cc`, run on VEK385_2. Expected: `GOLDEN PASS ... | PERF SUMMARY gemm_plan steady
1.43x ms median (85.6x % ...)`.
**Step 5:** commit the merge.

### Task 0.2: the regression script

**Files:**
- Create: `script/test/plan_regress.sh`

**Step 1: write it**

```bash
#!/bin/bash
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
# Regression gate of doc/plan/dataflowplan_unify_ir.md.
#   script/test/plan_regress.sh snapshot <dir>   build every gate source, keep its generated files in <dir>
#   script/test/plan_regress.sh compare  <dir>   build again, diff against <dir>, check flowcheck
# Exit 0 = every non-plan source byte-identical, every plan source flowcheck OK (diffs listed, not fatal).
set -uo pipefail
MODE=${1:?snapshot|compare}; REF=${2:?reference dir}
R=$(cd "$(dirname "$0")/../.." && pwd); C=$R/example/tileprogram/ccode
NONPLAN="simplematmul2 simplegemm_kernel_port simplegemm_dataflow simpleconv2d simpleconv2dkernel_port_less simpleeltwise_add_none"
PLAN="gemm_plan/gemm_plan gemm_plan/gemm_plan_4x2 gemm_plan/gemm_plan_bring simpleeltwise_add_plan simpleconv2dkernel_port_plan"
FILES="host.cc kernel.cc routing.cc aiehlc_plan.h"
rc=0
for s in $NONPLAN $PLAN; do
    tag=$(basename "$s"); out=$(mktemp -d)
    (cd "$R" && bash -c "source script/aiehlc.sh --aie-version 5 --runtime-source-file $C/$s.cc") > "$out/build.log" 2>&1
    fc=$(grep -a 'flowcheck' "$out/build.log" | tail -1)
    (cd "$R" && git checkout -- ir/ 2>/dev/null)
    if [ "$MODE" = snapshot ]; then
        mkdir -p "$REF/$tag"; for f in $FILES; do cp "$R/aout/worklocal/$f" "$REF/$tag/" 2>/dev/null; done
        echo "$tag: snapshot ($fc)"; continue
    fi
    d=""; for f in $FILES; do
        [ -f "$REF/$tag/$f" ] || continue
        cmp -s "$REF/$tag/$f" "$R/aout/worklocal/$f" || d="$d $f"
    done
    case " $NONPLAN " in *" $s "*) kind=nonplan ;; *) kind=plan ;; esac
    if [ -n "$d" ] && [ $kind = nonplan ]; then echo "$tag: FAIL differs:$d"; rc=1
    elif ! echo "$fc" | grep -q 'flowcheck: OK'; then echo "$tag: FAIL $fc"; rc=1
    else echo "$tag: ok${d:+ (plan files changed:$d)} ($fc)"; fi
done
exit $rc
```

**Step 2:** `bash script/test/plan_regress.sh snapshot ${TMPDIR:-/tmp}/unify_ref` -- expected 11 `snapshot` lines,
every one with `flowcheck: OK`.
**Step 3:** `bash script/test/plan_regress.sh compare ${TMPDIR:-/tmp}/unify_ref` with no source change -- expected
exit 0, all `ok`. (If a source is not deterministic, fix that first: the gate is useless otherwise.)
**Step 4:** commit the script.

---

## Stage 1: routing -- a typed `#routing.dataflow`

### Task 1.1: the attribute

**Files:**
- Modify: `src/mlir/mlirfront/tilinglinalg/routing/td/routingattr.td` (after `KernelBlockAttr`)
- Regenerate: `routing/inc/*` via `routing/gen.sh`

**Step 1: TableGen**

```tablegen
// A tensor's dataflow intent from load_buffer {.share / .stage / .ring / .keep / .parts / .axis}
// (doc/design/dmaphop_dataflow_plan.md). Replaces the untyped `dataflow` dictionary. Every field is
// printed (skill mlirattrarrayroundtrip: optional / defaulted fields do not parse back).
def DataflowAttr : routingattr<"Dataflow"> {
  let mnemonic = "dataflow";
  let cppNamespace = "routing";
  let parameters = (ins
    "::mlir::StringAttr":$share,          // neighbor | broadcast | none
    "::mlir::StringAttr":$stage,          // memtile | memtile_ring | "" (no staging)
    "int64_t":$ring,                      // 0 = not given
    "bool":$keep,                         // resident across launches
    "int64_t":$parts,                     // 1 = one part
    "::mlir::StringAttr":$axis,           // row | column | "" (broadcast only)
    ArrayRefParameter<"int64_t">:$base_p0, // per-core block origin (share != neighbor), else []
    ArrayRefParameter<"int64_t">:$base_p1
  );
  let assemblyFormat = [{
    `<` `share` `=` $share `,` `stage` `=` $stage `,` `ring` `=` $ring `,` `keep` `=` $keep `,`
    `parts` `=` $parts `,` `axis` `=` $axis `,` `base_p0` `=` `[` $base_p0 `]` `,` `base_p1` `=` `[` $base_p1 `]` `>`
  }];
}
```

and `OptionalAttr<DataflowAttr>:$dataflow` on `routingcreatescheduletensor` (`routingop.td:161`, next to
`kernel_block`).

**Step 2:** `cd src/mlir/mlirfront/tilinglinalg/routing && bash gen.sh`; build aiehlc (skill **mlirbuildsandbox**
for a single-file check).

### Task 1.2: producer and consumers

**Files:**
- Modify: `pass/tilinglinalg_pipeline.cpp:720-743` -- build `routing::DataflowAttr::get(...)`, `decl.setDataflowAttr(..)`.
- Modify: `pass/dataflowplan/plansynth.cpp:622` and its `Operand::df` uses -- read the typed fields.
- Modify: `pass/passdmaptodmaphop/dmaptodmaphop.cpp:352` -- `t.getDataflowAttr()`.
- Modify: `routing/collectTensorRoutingInfo` if it copies tensor attrs (skill **routingirtilingcarriers**).

**Step 1:** grep every `"dataflow"` string use: `grep -rn '"dataflow"' src/mlir/mlirfront/tilinglinalg --include=*.cpp`;
each one is replaced, none left.
**Step 2:** build; `script/test/routing_ir_roundtrip.sh example/tileprogram/ccode/gemm_plan/gemm_plan.cc` -- expected
exit 0 (the dumped `#routing.dataflow<...>` parses back).
**Step 3:** gate. Expected: non-plan identical; plan sources' generated files identical too (only the IR dumps
change spelling).
**Step 4:** docs (design doc "routing level", CLAUDE.md "Explicit dataflow plans" paragraph says `#routing.dataflow`),
commit.

---

## Stages 2-4, revised (2026-11-26): the plan IS the flow

Reading the lowering showed the "stand-in" flow is not dead weight: its core end is the kernel's window argument
(`window_init` in kernel.cc, the kernel signature) and its core memory, which the plan's chunk slots live in
(`planresource.cpp`, "the replaced windows"); only its host part (shim BDs, `create_io`, schedule) is already
skipped (`passblueprinttoschedule.cpp:194`). Deleting the flow (Stage 2 as first written) would mean rebuilding the
window and its memory from the plan. The cleaner unification keeps ONE flow per tensor and makes it the plan's:

1. `#dmaphop.stream<...>` (typed, every `PlanStream` field) on the tensor's `create_path`(s); the plan's routes are
   `create_hop`s of those paths (source `dmaphop.port` = the route's MM2S channel on a shim / MemTile / core tile,
   destination ports = its S2MM channels; `route = i` on each hop keeps the router's order); the plan header
   (persistent, bd_once) becomes module control switches.
2. `collectDataflowPlan` reads the paths (old `dmaphop.plan*` ops, e.g. from `gen_plan.py` or an old
   `AIEHLC_DMAPHOP_IR_IN` file, are converted to paths on entry -- one reader downstream); `plan_route` /
   `plan_stream` / `plan` ops and the `dmaphop.plan_replaced` tag disappear from the IR after the plan step.
3. Downstream keys on "the path carries a stream": DmaphopToRoutinghw lowers such a path's hops with the plan
   router (`planroutes.cpp`) instead of erasing it, the provenance map / flowcheck JSON keep their keys
   (`plan_routes`, `plan_replaced`), the blueprint host lowering keeps skipping the host part.
4. The read-back dump (`DataflowPlanReadback(dmaphop)`) writes the same form.

Gate: every generated file of every source byte-identical (plan included), dmaphop-stage round trip
(`routing_ir_roundtrip.sh --stage dmaphop`) PASS on `gemm_plan.cc` and `simpleeltwise_add_plan.cc`, the old-op form
(`gen_plan.py` output) still builds identically. The original Tasks 2.x-4 below stay as the record of the first
design; 2.1 (plan-owned core memory) is not needed once the window is the plan flow's own.

## Stage 2: no stand-in flows

The plan's tensors still get a generic flow (stand-in DataIO, shim BDs, core windows) that the plan then
replaces; `planresource.cpp` puts the chunk slots in the **replaced windows' memory**. After this stage a plan
tensor generates no generic flow and the plan owns its core memory.

### Task 2.1: the plan allocates its own core memory

**Files:**
- Modify: `pass/dataflowplan/planresource.cpp:159, 257-277, 406, 458-516`
- Look up: the core memory allocator the windows use (`CoreMemAllocator`, skill **dmbufferregion**).

**Step 1:** in a build with stage 1, record what the plan uses today: `[DataflowPlan] resources (aie2ps): ... chunk
slots 0x78000+32768 (the replaced windows)` and `core memory: windows 40960 B ...` from `build.log`.
**Step 2:** allocate `slots x parts` chunk slots (and, when it does not fit, the K accumulator) from the allocator
directly, at the same bank alignment the windows had (`{.align}`, two parts in different 16 KB banks). Keep
the read-back check (`planresource.cpp:406`) but against the allocator's region.
**Step 3:** build `gemm_plan.cc` with both the replaced windows still present: expected the slots at a NEW address
and core memory over budget (both windows and slots) -- this is the signal Task 2.2 is needed; do not run it.

### Task 2.2: do not create the replaced flows

**Files:**
- Modify: `pass/passdmaptodmaphop/dmaptodmaphop.cpp:352-355` -- a tensor with `#routing.dataflow` (and a plan) gets
  no `createDataIOAtPoint` stand-in.
- Modify: everything that keyed on `dmaphop.plan_replaced`: `pass/dataflowplan/dataflowplan.cpp:293-384` (tagging),
  `pass/passdmaphoptoroutinghw/passdmaphoptoroutinghw.cpp:860`, `pass/passdmaphopprovenancemap/passdmaphopprovenancemap.cpp:430, 723`.
- Modify: the kernel side that declared the replaced ports' windows (kernel.cc window globals for the plan ports;
  find with `grep -n "buf_in_ping" aout/worklocal/kernel.cc` on a plan build).

**Step 1:** build `gemm_plan.cc`. Expected `[DataflowPlan] core memory: ...` with no replaced windows, slots from the
allocator; `flowcheck: OK -- N flows` with N = 32 - 8 (no replaced flows).
**Step 2:** gate. Expected: non-plan identical. Plan sources: `host.cc`, `kernel.cc`, `routing.cc` differ (no stand-in
BDs / windows); list the diff kinds in the evidence.
**Step 3:** board: the four plan sources GOLDEN PASS, `gemm_plan.cc` >= 85.4 %.
**Step 4:** `AIEHLC_DFSCHEDULE_PLAN_IN` read-back (`planreadback.cpp`) still regenerates identically:
`AIEHLC_DFSCHEDULE_PLAN_IN=ir/dfschedule/NN_DataflowPlanProgram.mlir` build, diff the generated files.
**Step 5:** docs (design doc: "the plan owns its core memory"; remove `plan_replaced` from CLAUDE.md, skill
**dmaphopdataflowplan**), commit.

---

## Stage 3: `plan_route` into the hop graph

### Task 3.1: MemTile ports and staged paths in dmaphop

**Files:**
- Modify: `dataflowmap/dmaphop/td/dmaphopop.td` -- `dmaphop.tile` accepts a MemTile; `create_path` gets an optional
  `stages` array (the ports where the stream is stored and re-sent by a DMA: a MemTile S2MM -> MM2S, or a host core
  S2MM read by neighbours) so one path = several DMA segments.
- Modify: `pass/passdmaptodmaphop/dmaptodmaphop.cpp` -- emit plan streams as `create_hop` chains through the MemTile
  ports with `stages`.

**Step 1:** write the target IR by hand for one A stream of `gemm_plan.cc` (shim -> MemTile -> host core -> neighbour)
next to today's `plan_route` op from `ir/dfschedule/*Dmaphop*.mlir`; check both carry the same channels.
**Step 2:** implement; dump; `routing_ir_roundtrip.sh --stage dmaphop` on `gemm_plan.cc` -- exit 0.
**Step 3:** `planroutes.cpp` reads the hop chains instead of `plan_route`; `plan_route` no longer emitted.
**Step 4:** gate: non-plan identical; plan `routing.cc` identical (same router, same nets).

### Task 3.2 [ASK]: one router

Two BFS routers exist. Proposal: route every `create_path` with `planroutes.cpp`'s port model and retire the
`RoutingPath` BFS for dmaphop paths. This **changes non-plan `routing.cc`** (other hops, same connectivity), so the
byte-identical rule is replaced by: flowcheck OK + board GOLDEN PASS for every non-plan gate source.
**Step 1:** ask the user; if no, keep two routers and close the stage.
**Step 2 (if yes):** switch; gate with the relaxed rule; board-run the six non-plan sources.

---

## Stage 4: `plan_stream` into path attributes

**Files:**
- Modify: `dmaphopop.td` / `dmaphopattr.td` -- `#dmaphop.stream<staging, ring, keep, chunk geometry, readers, parts,
  host rows, elem_bytes>` on `create_path` (or its `alloc_buffer`).
- Modify: `pass/dataflowplan/dataflowplan.cpp` (`collectDataflowPlan`), `plansynth.cpp`, `plandma.cpp`,
  `planreadback.cpp` -- read / write the attribute instead of `plan_stream`; `plan` header keeps only module facts
  (persistent, BD write-once) or moves to module attributes (control switches only, rule in CLAUDE.md).

**Step 1:** emit both (attribute + old op) and assert in `collectDataflowPlan` that they agree on every gate source.
**Step 2:** read only the attribute; delete `plan_stream` emission. **[ASK]** before deleting the op definitions
(`AIEHLC_DMAPHOP_IR_IN` files written by users would stop parsing).
**Step 3:** gate: all generated files identical (plan included); `routing_ir_roundtrip.sh --stage dmaphop` OK.
**Step 4:** docs, commit.

---

## Stage 5: one dfschedule DMA op family [ASK]

**Files:**
- Modify: `dataflowmap/dfschedule/td/dfscheduleop.td:174, 226-280`
- Modify: `pass/passdfscheduletoapi/*`, `pass/passdfscheduletokernelapi/passdfscheduletokernelapi.cpp`,
  `pass/passblueprintlowering/helper/*`, `pass/dataflowplan/plandma.cpp`

Proposal: `config.tile_bd` (BD over a tile's own memory, hardware values) becomes the only BD op; a shim BD is a
`config.tile_bd` whose address is a DDR buffer operand. `config.dma_bd` producers (blueprint lowering) emit it;
`DfscheduleToApi` / `DfscheduleToKernelApi` lower one op. The `core_offload_plan` attribute channel goes away.
**Step 1:** ask the user (largest stage: host and kernel lowering, every example).
**Step 2:** add the shim form to `config.tile_bd`; lower it; assert equal API calls for `config.dma_bd` on the gate
(emit both, compare the generated calls).
**Step 3:** switch the producers; delete `config.dma_bd`.
**Step 4:** gate: every generated file identical (the API calls must not change).

---

## Stage 6: the plan through dfscheblueprint

**Files:**
- Modify: `dataflowmap/dfscheblueprint/td/*` -- transfer manifests for staged paths (segments) and shared readers
  (reader count, hand-on lock protocol).
- Modify: `pass/passdmaphoptodfscheblueprint/*`, `pass/passblueprintlowering/*`; `plandma.cpp` becomes the
  blueprint -> schedule lowering of those manifests (moved, not duplicated).

**Step 1:** blueprint dump of `gemm_plan.cc` describes every transfer (today the plan's are missing).
**Step 2:** gate: all generated files identical.

---

## Stage 7: one kernel block-IO runtime

**Files:**
- Modify: `src/mlir/runtime/aie_block_io.h`, delete `src/mlir/runtime/aie_block_io_plan.h` (content merged): a window
  is the one-reader, no-MemTile case of the slot protocol.
- Modify: `pass/tilinglinalg_pipeline.cpp:400` and the plan emitter -- constants into `kernel.cc` / `host.cc`
  instead of `aiehlc_plan.h` (`aiehlc_plan_arrange` into `host.cc`).

**Step 1:** kernel listing check: `python3 src/costmodel/tools/kcyc_lst.py kernel.lst --func gemm_ka` and
`script/perf/macloop.py old/kernel.lst new/kernel.lst` -- the MAC loop and the static cycles must not change
(gemm_plan: 1,312,595 cycles, `static_eff` 0.9362).
**Step 2:** gate; board GOLDEN PASS on all plan sources, `gemm_plan.cc` >= 85.4 %.

---

## Order, size, checkpoints

| stage | size | changes non-plan output | ask first |
|---|---|---|---|
| 0 baseline + script | S | no | -- |
| 1 typed `#routing.dataflow` | S | no | -- |
| 2 no stand-in flows | M | no | -- |
| 3.1 hop chains for plan routes | M | no | -- |
| 3.2 one router | M | **yes** (`routing.cc`) | yes |
| 4 `plan_stream` -> path attribute | M | no | before deleting the op |
| 5 one dfschedule DMA op family | L | no (must stay identical) | yes |
| 6 plan through dfscheblueprint | L | no | -- |
| 7 one block-IO runtime | M | no | -- |

Stages 1-2 remove the mixing at its source (routing + stand-in flows) and are worth doing alone; 3-4 make dmaphop
one graph; 5-7 are the heavy, separate project.
