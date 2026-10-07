## Role
- MLIR and Spatial computing expert

# AIEHLC Project Architecture

AIEHLC (AIE High-Level Compiler) is a compilation/deployment solution for AMD Versal AI Engine. It has **two parts**:

1. **aiehlc** — Clang-based tool that compiles C++ (AIE driver C API) into host + kernel binaries for single-kernel AIE apps.
2. **tilinglinalg** — MLIR progressive lowering pipeline that offloads a GEMM operation across multiple AIE tiles, generating host, kernel, and routing C++ code through 6 custom dialects.

Both share the AIE runtime (`include/aie_runtime.h`) and target Versal AI Core Series with pre-built PDI.

## Directory Layout

```
aiehlc/
├── include/                   # aie_runtime.h, aie_device_map.h
├── src/
│   ├── llvm/aiehlc.cc         # Main aiehlc Clang tool
│   └── mlir/
│       ├── runtime/aie_runtime.c  # Runtime wrappers over XAie_* APIs
│       └── mlirfront/
│           ├── AieFrontEnd.cc     # Clang AST → MLIR
│           ├── AieDialect.cc      # AIE dialect (LoadKernel, etc.)
│           ├── frontend/aiebackend/  # _aiebackend pybind over TilingLinalgPipeline (Triton + TVM share it)
│           └── tilinglinalg/      # ★ Multi-tile GEMM pipeline
│               ├── routing/       # Abstract routing dialect
│               ├── routinghw/     # Physical routing dialect
│               ├── dataflowmap/   # dmap, dmaphop, dfscheblueprint, dfschedule dialects
│               └── pass/          # All lowering passes + unitest/
│                   └── passblueprintlowering/  # host+kernel blueprint lowering
│                       ├── helper/             # SHARED core-tile DMA/lock config
│                       ├── passblueprinttoschedule/       # → host.cc
│                       └── passblueprinttoschedulekernel/ # → kernel.cc
├── script/                    # setup.sh, aiehlc.sh, kc.sh, test/apppaltest.py
├── example/                   # AIE examples (perf, matmul, multi-kernel)
└── thirdparty/alib/           # XAie driver (excluded from this doc)
```

## Part 1: aiehlc (Single Kernel)

Compiles a user C++ file into a host ELF (ARM) + kernel ELF (AIE core):

```
User C++ → aiehlc (Clang AST) → AieFrontEnd (MLIR)
  → Kernel: xchesscc → xchessmk → kernel ELF (embedded in host via ld -r -b binary)
  → Host: aarch64-g++ (host.cc + aie_runtime.c + routing + kernel.o) → host ELF
```

Key runtime API: `__Runtime_device_init`, `__Runtime_load_kernel_group`, `__Runtime_launch_kernel_group`, `__Runtime_dma_bd_config`, `__Runtime_wait_event`, `__Runtime_device_teardown`.

**Entry file may `#include` its kernel.** The `__global__` kernel does not have to
sit in the file passed to `--runtime-source-file`: a thin `main.cc` may
`#include "kernel.cc"`. `inlineSourceIncludes()` (`src/llvm/aiehlc.cc`) splices
quoted `.cc`/`.cpp` includes into the text *before* the rewrites run, so the
kernel is annotated, body-guarded and launch-lowered as if written inline. The
artifact kind follows `main()`: present → ELF, absent → `lib<app>.a` (skill:
hostlibrarymode). `src/aietensorop/conv2dstem/` ships both entries over one
kernel. The splice is deliberately **opaque** (no `#line`) because kernel export
and the host `RewriteBuffer` both key off the kernel's `FileID` — see skill
**aiehlcincludekernel** before changing it.

**conv2dstem runs on real data.** `src/aietensorop/conv2dstem/data/` generates
three committed-or-derived headers from a photo and the int8-quantized
ResNet-18: `conv2dstem_image.h` (`int8[230,230,4]`, already preprocessed,
quantized, **zero-point**-padded and channel-aligned — byte-for-byte
`g_ifm_pad`, so the board does no scatter), `conv2dstem_weights.h` (real conv1
weights + 64 folded qparams), and `conv2dstem_golden.h` (CPU ground truth, which
`main.cc` self-checks against and `groundtruth.py --applog` reads back; a
baremetal board under xsdb has no channel but the console). This matters: with
real weights the peak accumulator is **1,023,225**, so an int16 accumulator
wraps — the old synthetic `[-4,4]×{-1,0,1}` fixture could not show that.
Generated headers must land **flat** in the app source dir, not in `data/` —
`aiehlc.sh:532` copies user headers with a non-recursive `*.h` glob flattened to
basename and the host compile only gets `-I<worklocal>`, so a `data/` header
parses in the frontend and then fails at cross-g++. See
`src/aietensorop/conv2dstem/data/README.md` and skill **conv2dstemfixture**.

**Control-packet plane** — register access over the stream fabric instead of the host
config bus. See **[doc/controlplane.md](doc/controlplane.md)** for the full API,
encoding, and fabric layout. In brief:

| Layer | Entry points |
|-------|--------------|
| Packet encode/parse | `__Runtime_ctrl_pktize_write` / `_pktize_read`, `_parse_ctrl_hdr` / `_parse_pkt_hdr` |
| Single-target send | `__Runtime_CtrlInstance` + `_setup_routing` / `_push` / `_tct_poll`; composed by `_read_target` / `_push_target` |
| Row/broadcast fabric | `__Runtime_ctrl_plan_init` (one-shot planner, `aie_runtime_control_plan.c`), then `_row_broadcast_write` / `_row_whole_row_write` / `_row_read` / `_row_write_ack` |
| Transaction capture | `__Runtime_control_start_transaction` → `_write_pkt_commit_transaction` → `_control_push` (WRITE-only ops → broadcast/multicast packet buffer) |
| Resource reservation | `aie_runtime_resource.{c,h}` — single source of truth for slots/arbiters/msel/pkt-ids; `RT_RES_*` constants aliased by the planner's `ACR_*` |

Key invariants worth knowing before touching it:

- Completion is the **control-packet response** draining at the shim S2MM
  (`resp_words` words), not a DMA TCT token.
- The return route KEEPS each response's stream header
  (`XAIE_SS_PKT_DONOT_DROP_HEADER`); it is stripped host-side in `rt_ctrl_read_extract`.
- Forward routing arms a **uniform slot superset** on every chain tile — all columns of
  a row respond; there is no last-tile special case.
- Provenance `dir=fwd|ret` comes from the planner's `acr_op.is_ret` tag, **not** the port
  type (both fabrics use the same ports). A slot and every master pulling it must share
  a `dir`, or the debug switch-detail view silently drops the link.
- `ResourceMgr::reserveControlPlaneResources` is **opt-in** via
  `#pragma control_plan_op_control_packet`; default off.

Platforms: baremetal (`aarch64-none-elf-g++`) or Linux (`aarch64-linux-gnu-g++`).

## Part 2: tilinglinalg (Multi-Tile GEMM)

### Six Custom MLIR Dialects

| Dialect | Purpose |
|---------|---------|
| **routing** | Abstract tile arrays, data IO, broadcast, mesh partitioning |
| **routinghw** | Physical tiles, stream switch ports, packet flows |
| **dmap** | Logical dataflow: ports, streams, push/pull |
| **dmaphop** | Physical hops: tile-to-tile paths, DMA, buffers |
| **dfscheblueprint** | Schedule blueprint: transfer manifests, flow configs |
| **dfschedule** | Executable schedule: DMA BD, kernel launch, locks |

### High-level frontend dialect (`aiegraph`)

Sits **above** `routing` — a fused/quantized op-level graph (TVM/Relay → aiegraph
→ per-op `run_aie_pipeline`). Not part of the GEMM pass pipeline; it lowers each
op to an independent launch on the existing backend.

**Runtime op split.** The `run_aie_pipeline` backend implements only the conv2d
family (`conv_bn`, `conv_bn_relu`). The other aiegraph ops (`residual_add_relu`,
`avgpool_fc`) are **not** sent to AIE; they are emitted as bit-exact CPU C by TVM
(`target="c"`, `src/frontend/tvm/cpu_codegen.py`). Non-conv ops still build/verify/
lower in the aiegraph IR — only the emit path forks (dispatch via
`cpu_codegen.is_aie_op`). See `doc/design/tvm_frontend.md` §"CPU fallback".

| Dialect | Purpose |
|---------|---------|
| **aiegraph** | Fused int8 tensor ops (`conv_bn_relu`, `conv_bn`, `residual_add_relu`, `avgpool_fc`) as SSA def-use over `tensor<Nxi8>`, with per-op quant attrs + weights `SymbolRefAttr`; `func`/`yield` container. Buffer wiring is verified SSA, not string names. |

Location: `src/mlir/mlirfront/frontend/aiegraph/` (`td/`, `gen.sh`, `inc/`,
`aiegraphmanager.{h,cpp}`, `lower/AiegraphLowerDriver.{h,cpp}`, `unitest/`).
pybind: `build_aiegraph_module(ops)` (build+verify → textual IR) and
`lower_aiegraph(mlir_text)` (walk → per-launch `tensor_specs`) in
`aiebackend/aiebackend_pybind.cpp`. Python entry: `_compiler.compile_plan(..., via_aiegraph=True)`.

### PyTorch → PT2E int8 → MLIR (`src/frontend/pytorchmlir/`)

A **second model-ingest frontend**, independent of TVM: torchvision ResNet-18
**v1** → `torch.export` → PT2E int8 (`NPUQuantizer`, per-channel symmetric
weights / affine activations) → `torch_mlir.fx` → torch dialect →
linalg-on-tensors. **Scope ends at MLIR** — no aiegraph, no AIE backend.
Needs no compiled TVM, so it coexists with `tvmrelay`.

```bash
PYTHONPATH=src python src/frontend/pytorchmlir/deploy_torch.py
python src/frontend/pytorchmlir/setup_torchmlir.py --verify-only
```

Verified on torch 2.10.0 / torchvision 0.25.0 / torchao 0.18.0 /
torch-mlir 20261001: 20 int8 convs + int8 fc, fp32-vs-int8 top-1 match with
identical top-5 order. Details in
**[src/frontend/pytorchmlir/README.md](src/frontend/pytorchmlir/README.md)**.

Three non-obvious things, each of which silently misleads if forgotten:

- **`0 fused *_q` is expected, not a failure.** torch-mlir registers
  `quantized_decomposed.*` as native ODS ops, but `torch-match-quantized-custom-ops`
  matches only the *unregistered* `torch.operator` spelling — so the matcher
  never fires and no `!torch.qint8` appears. int8 still reaches linalg as
  explicit `arith.extsi/subi/mulf` around `linalg.conv_2d_nchw_fchw`.
- **`--output-type tosa` needs `--per-tensor`** — TOSA marks
  `dequantize_per_channel` illegal with no lowering pattern.
- **PT2E lives in `torchao`**, not `torch.ao` (deprecated, deletion planned).
  All PT2E symbols resolve in `torch_deps.pt2e_api()`.
- Do **not** reuse `example/model/resnet18py/resnet18.py:resnet18()` here — it
  builds ResNet-18 **v2** from ONNX weights. Only `classify.preprocess` is shared.

**The board ELF links from the per-layer split, not the monolithic C.** Stage 5
(`split_layers.py`, on by default; `--no-split` disables) writes one translation
unit per operator to `worklocal/tvmrelay_deploy/layers/NN_op/NN_op.c`; stage 6
(`arm_build.py`) compiles each to a `.o` **beside its source** and archives them
into `arm_build/liblayers.a`, which `graph_driver.c` + `main.c` link against.
Editing one operator recompiles one TU. `resnet18.c` remains the fallback when
`layers/` is absent; exactly one of the two is wired in, and `make` stops with a
named error if neither resolves. Cost measured on ResNet-18 int8: **+0.02%**
`.text`. Because every layer includes `layers_common.h`, that header now also
carries mid-file material (a BYOC prelude) and a synthesized prototype for any
function defined but not pre-declared — so **BYOC codegen must keep weights as
function-scope statics**, or they duplicate into all 65 TUs and collide at link.

### TVM `--aie-offload` → AIE via BYOC

`deploy_flow.py --aie-offload --aie-layers N` (default 1, the stem) puts layer N
on the AIE: after the CPU build, Relay `MergeComposite` → `PartitionGraph` →
`relay.ext.aie` codegen, the C is rebuilt, and TVM's graph executor calls the
generated wrapper → `conv2d_stem_prepadded()` in `aout/libconv2dstem.a` (built
from `src/aietensorop/conv2dstem/conv2dstem.cc` by `aiehlc.sh` in library mode —
skill **hostlibrarymode**; aiehlc generates the init/partition/launch caller).
`--byoc-aie` was merged into this flag. Code: `src/frontend/tvmrelay/byoc/`
(`aie_patterns`, `aie_annotate`, `aie_codegen`, `aie_byoc`) + `aie_offload.py`;
design **[doc/design/aie_offload_byoc.md](doc/design/aie_offload_byoc.md)**; check
`byoc/verify_aie_stem.py` (bit-exact vs TVM, incl. all 1000 logits).

Non-obvious and each one silently wrong if broken — see skill **byocaieoffload**:
the subgraph is the **fused** op (conv → requantize → ReLU → uint8), because that
is all the AIE kernel can emit; the uint8 input (zero-point 113) goes in as
**`x − 128`** with `+128·Σw` folded into the bias — a plain cast corrupts every
pixel ≥ 128; TVM pads with the **zero-point**, so the library takes the
**pre-padded** 230×230 tensor; layers map onto Relay convs by **weight
fingerprint**, not position (shortcut convs run in a different order); the
accumulator must be **int32**; per-channel quant params hide in the filter
window's **pad channel**; kernel-visible helpers must be **macros**; and the link
needs the BSP's `libxil.a` de-duplicated against `libxaienginea78.a`.

### Pass Pipeline

**Shared stages** (produces dfscheblueprint IR, then module is cloned):

1. `RoutingUnrollingLowerPass` — unroll abstract routing into per-tile ops
2. `RoutingToDmapPass` — routing → logical dataflow
3. `DmapToDmaphopPass` — logical → physical hops
4. `DmaphopTodfscheblueprintPass` — hops → schedule blueprints

**Host path** → `host.cc`:

5. `BlueprintToSchedulePass` → `ScheduleCanonicalizePass` → (`GroupRegWritePass`, opt-in) → `DfscheduleToApiPass` → `RoutingConstantFoldPass` → `CanonicalizerPass` → EmitC → `host.cc`

`GroupRegWritePass` is **gated** on `routing.control_plan_group_reg_write`, published by
aiehlc only for `#pragma CONTROL_PLAN_GROUP_REG_WRITE`. Off (the default), per-tile lock
inits emit as individual `XAie_LockSetValue` writes instead of coalesced control-packet
group writes (`__Runtime_ctrl_row_write_ack`), and the pipeline logs
`GroupRegWritePass skipped`.

**Kernel path** → `kernel.cc`:

5. `BlueprintToScheduleKernelPass` → (`DfscheduleKernelAggregationPass`, offload-only) → `DfscheduleToKernelApiPass` → EmitC → `kernel.cc`

`DfscheduleKernelAggregationPass` (`pass/passdfschedulekernelaggregation/`, gated on
`routing.kernel_config_offload`) collapses the per-core-tile DMA config onto
`dfschedule.declaretile.self` — one BD group per window instead of one per tile
(96 → 6 `dma_bd`). `packet_id` / `out_of_order_bd_id` are **SSA operands, not
attributes**, and must stay `arith.constant`-foldable. See
**[doc/design/kernel_dma_aggregation.md](doc/design/kernel_dma_aggregation.md)** — it
covers why `declaretile.self` is its own op (fail-closed on `getDefiningOp`), why
`ooo_bd_id` needs the `ResourceMgr` singleton fallback on the kernel clone, and why
erasure must be a fixpoint sweep.

**KERNELCONFIGOFFLOAD** (gated on `routing.kernel_config_offload`, set by
`#pragma KERNELCONFIGOFFLOAD`, default off, Gen5 only): the core self-configures all of
its own core-tile DMA from `kernel.cc` via MMIO instead of the host programming it over
the config bus, using `src/mlir/runtime/aie_kernel_runtime.h` (encoders + `core_reg_*`
apply, the latter going through `kernel_tm.h`'s `TM_W` — a plain pointer cast never
reaches the processor bus). See
**[doc/design/kernel_config_offload.md](doc/design/kernel_config_offload.md)** for that
TM rule, the direction asymmetry, the cross-clone plan channel, and the BD-id reservation
contract — each one deadlocks or silently corrupts registers if broken.

**Pass layout.** Both blueprint-lowering passes live under `pass/passblueprintlowering/`, with the shared `helper/` hoisted **above** them (`passblueprintlowering/helper/`) rather than nested inside the host pass. The two paths describe the same physical core tiles — one BD bank, one lock array per tile — so whoever programs it must agree with whoever doesn't. Anything both paths must agree on belongs in `helper/`. See `passblueprintlowering/README.md`.

**Routing path** (alternative, Path A) → `routing.cc`:

1. `RoutingUnrollingLowerPass` → `RoutingLowerPass` → `RoutingHWLowerPass` → `RoutingDeadArgPass` → `RoutingConstantFoldPass` → `CanonicalizerPass` → EmitC → `routing.cc`

### Routing Implementation (`pass/routingimplement/`)

- **RoutingTopology**: Gen2 AIE tile topology model
- **RoutingPath**: BFS path finding (priority: Memory > SHIM > Core)
- **ResourceManager**: Tracks link/port usage to avoid conflicts

## Build

```bash
# Main aiehlc binary
mkdir build && cd build && cmake .. -DLLVM_INSTALL_DIR=/path/to/llvm/build && make -j$(nproc)

# TilingLinalg unitest (standalone)
 source script/aiehlc.sh --aie-version 5 --runtime-source-file ./example/tileprogram/ccode/simplematmul2.cc
 python3 ./script/test/apppaltest.py -y  -nonreboot > ./applog 2>&1
```

Each dialect has `td/` (TableGen), `gen.sh` (runs mlir-tblgen), and `inc/` (generated .inc files).

## Test and Verification

### Unitest CLI

```bash
source script/aiehlc.sh --aie-version 5 --runtime-source-file ./example/tileprogram/ccode/simplematmul.cc
```

### End-to-End Flow

```
1. Generate    source script/aiehlc.sh --aie-version 5 --runtime-source-file ./example/tileprogram/ccode/simplematmul.cc
2. HW run      python3 script/test/apppaltest.py aout/worklocal/build/host  → SSH+xsdb+console
3. Verify      script/test/verify_host.sh → pass: "device_teardown done", fail: "AIE ERROR"
```

### Per-Dialect Unit Tests

Each dialect has its own `unitest/` directory with independent CMake build:
- `routing/unitest/`, `routinghw/unitest/`
- `dataflowmap/{dmap,dmaphop,dfschedule,dfscheblueprint}/unitest/`
- `pass/routingimplement/{routing,hw}/unitest/`

## Additional Documentation

### Design docs

- **[doc/module_analysis.md](doc/module_analysis.md)** — 9-module project breakdown (M1–M9), key files, dependencies, data-flow diagram
- **[doc/aieapi.md](doc/aieapi.md)** — XAie driver API guide (single-tile, multi-tile manual, production AEG patterns)
- **[doc/controlplane.md](doc/controlplane.md)** — Control-packet plane: encoding, `CtrlInstance` send/recv, row/broadcast fabric, transaction capture, resource reservation, provenance
- **[doc/performance/register_write_cost.md](doc/performance/register_write_cost.md)** — **Measured** host↔AIE register access cost: ~372 ns per 32-bit `XAie_Write32` (non-posted Device-nGnRnE NoC round trip; an N-word BD is N serial writes) vs ~2.9 ns via control packets. Cite this instead of deriving ns/write from a timeline span.
- **[doc/tilinglinalg.md](doc/tilinglinalg.md)** — TilingLinalg deep dive: dialects, passes, routing engine, build/HW-run flow
- **[doc/design/kernel_config_offload.md](doc/design/kernel_config_offload.md)** — `#pragma KERNELCONFIGOFFLOAD`: core self-configured DMA, lock asymmetry, BD-id reservation
- **[doc/design/aie_offload_byoc.md](doc/design/aie_offload_byoc.md)** — `--aie-offload`: TVM BYOC → `libconv2dstem.a`, fused boundary, uint8 shift, weight-fingerprint layer mapping
- **[doc/design/kernel_dma_aggregation.md](doc/design/kernel_dma_aggregation.md)** — `DfscheduleKernelAggregationPass`, `declaretile.self`, `packet_id`/`ooo_bd_id` operands
- **[doc/debug/tutorial_aiehlc.md](doc/debug/tutorial_aiehlc.md)** — aiehlc simulator + debug UI (`--platform sim`, `--sim-only`)
- **[doc/debug/tutorial_baremetal.md](doc/debug/tutorial_baremetal.md)** — naiebaremetal VEK385 boot + debug UI
- **[doc/design/tile_dim_structured_design.md](doc/design/tile_dim_structured_design.md)** — Structured `tile_dim` for `aie::SpatialPolicy`
- **[doc/design/spatial_space_composition.md](doc/design/spatial_space_composition.md)** — Composition-based spatial op spaces (GemmSpace, Conv2dSpace)
- **[doc/design/aiegdb_live_debug_framework.md](doc/design/aiegdb_live_debug_framework.md)** — Live debug framework design (static view + daemon)
- **[doc/llvm_mlir_pitfalls.md](doc/llvm_mlir_pitfalls.md)** — Known LLVM/MLIR API pitfalls
- **[doc/aiedifferentview.md](doc/aiedifferentview.md)** — Memory and lock semantics

### Agent skills (`.cursor/skills/<name>/SKILL.md`)

Read the matching skill when the task fits:

| Topic | Skill |
|-------|-------|
| Debug UI, daemon, live session, browser UI features | **debug-ui-framework** (+ [reference.md](.cursor/skills/debug-ui-framework/reference.md)) |
| Embedded LLM context loss on retarget | debugui-llm-reset |
| Debug UI grid: every tile red border + ⚠ "supply/demand mismatch" on every launch | flowbalancebroadcast |
| Static XAie API verify (routing.cc, host.cc) | xaieapiverify |
| Routing debug (IR → generated code) | routinghwdebug |
| DMA BD verify in host.cc | dmabdverify |
| Pre-HW data correctness | datacorrectness |
| XAie driver internals | aiedriverkb |
| Live HW DMA stall debug | aiehwdmadebug |
| Core register write succeeds on-core but host reads 0 / DMA never starts (`ST` vs `ST.TM`) | coretmregisterwrite |
| Shim BD stuck on wrong/locked BD (index overflow into channel-control regs) | shimbdindexoverflow |
| Sim PS.so load segfault | aiesimloaddebug |
| aiesim live debug register socket | aiesim-debug-socket |
| HW performance counters | aiehwprofile |
| Raw-XAie sim debug bundle | raw-xaie-sim-debug-bundle |
| Sim build/run separation | sim-build-run-separation |
| Build fails on missing snap cmake / libz.so / ZLIB::ZLIB; fast single-file compile check | mlirbuildsandbox |
| Gen2-only build break: missing `xpseudo_asm_armclang.h`, or `XPAR_CPU_TIMESTAMP_CLK_FREQ` undeclared | bspheadergen2 |
| hostcompile / missing compile_kernel.sh | hostcompile-entrypoint |
| App source with no `main()` → static lib; "return-statement with a value, in function returning 'void'" | hostlibrarymode |
| Entry file `#include`s a kernel `.cc`; `unknown type name '__global__'` or `acquire_input_window` errors pointing at an INCLUDED file | aiehlcincludekernel |
| Pipeline "succeeds" but emits an EMPTY module (0 routing connections, no BCF/PRX → `Couldn't open aie2ps.prx`): `__global__` in a comment, or a prototype above the kernel | aiesourcetextrewrite |
| `deploy_flow.py` emits fp32 instead of the default int8, `target.build.llvm is not enabled`, missing `onnx`, or stage-5 split silently skipped | tvmrelaynollvm |
| PT2E int8 → torch-mlir yields no `!torch.qint8` / no `linalg.*_q` (fusion passes look like no-ops); TOSA "failed to legalize `dequantize_per_channel`"; `pip install torchvision` upgrading torch | torchmlirquantfusion |
| TVM `--aie-offload` (BYOC → AIE): fused boundary, uint8 shift, zero-point padding, weight-fingerprint layer mapping, conv2dstem int32/epilogue, duplicate `XAie_*` at link | byocaieoffload |
| conv2dstem real-data fixture: generated header can't live in a subdir; zero-point border; `shift = -exponent`; golden self-check over the console | conv2dstemfixture |
| `--aie-offload` says `non-4D shapes; not a conv2d` for every layer, or a layer gets another layer's geometry (`K=0`); TVM 5-D NCHWc vs aiehlc's d1..d4 | nchwclayoutfold |
| `Option '...' registered more than once` / `Option 'basic' already exists` when TVM flow loads `_aiebackend` (two LLVMs) | aiebackendtvmllvm |
| Frontend prints "OVER BUDGET" / gates offload on tile memory — don't; offload is blind, aiehlc tiles | aieoffloadblind |
| AEG IPC sim C++ headers | aeg-sim-cxx-headers |
| Host codegen | hostcodegen |
| Kernel codegen | kernelcodegen |

**Embedded LLM plugin** (`src/tool/debug/dbg_llm_skills/`): nine skills for the browser LLM tab. Launch locally with `claude --plugin-dir src/tool/debug/dbg_llm_skills`. Listed in **debug-ui-framework** reference.

**External:** aiedbg clone at `/scratch/staff/bkirinci/aiedbg` — see plugin skill `aiedbg-reference`.

**Command:** [data-mismatch-debug](.claude/commands/data-mismatch-debug.md) — systematic DMA data-mismatch triage.

### Browser automation (MCP)

`mcp-browser` (configured in `.mcp.json`, built at `thirdparty/mcp-browser/`) gives live
Playwright browser control. **Use it for any debug-UI work** — verifying
`schedule_debug_server.py` / `schedule_view.py` renders, reproducing UI bugs, and
confirming a server-side change actually reaches the page.

Workflow: start the debug server → `browser_navigate` to `http://localhost:<port>` →
`browser_screenshot` → interact with `browser_click` / `browser_extract_text`.
Other tools: `browser_type`, `browser_wait_for_element`, `browser_execute_script`.

After changing it: `cd thirdparty/mcp-browser && npm run build`, then restart Claude Code
to reload the MCP server.

### Debug tools

- **[src/tool/debug/README.md](src/tool/debug/README.md)** — user guide and CLI for all debug tools
- **Skill: debug-ui-framework** — implementation map for `schedule_debug_server.py`, `schedule_view.py`, `aiegdb.py`, `aiemcp.py`, `aiediag.py`, `xaiehost2provenance.py` (detail in [reference.md](.cursor/skills/debug-ui-framework/reference.md))

### Build notes

- **[script/verify_env.sh](script/verify_env.sh)** — validate Vitis, LLVM, toolchain, board vars before build
- **[script/hostcompile.sh](script/hostcompile.sh)** — kernel build via `compile_one_kernel()` → `kc.sh`; do not restore deleted `compile_kernel.sh` (skill: hostcompile-entrypoint). Picks `HOST_ENTRY_KIND` from the generated `host.cc`: `int main()` / `void main()` link an ELF, **no main() archives `lib<app>.a`** instead (skill: hostlibrarymode). The `return;`→`return 0;` fixup is main-only — it rewrites the *first* `return;` in the file and corrupts `host_canonicalized` if applied without a main.
- **[script/aiehlc.sh](script/aiehlc.sh)** — `--platform sim` is build-only; launch sim separately via `runsim.sh` or debug UI **Run** (skills: sim-build-run-separation, raw-xaie-sim-debug-bundle)
- **`include/bspcompat/`** — shims for standalone-BSP headers present only on the armclang branch (`thirdparty/alib/include/` is a flattened copy of *one* BSP, picked by `--aie-version`, wiped every run, gitignored). `aiehlc.sh` appends `-I${AIEHLC_DIR}/include/bspcompat` **last** in `AIEHLC_ARGS` so the real Gen5 header still wins — add it to the **front-end only**, never to the host/kernel compiles. Details and the related `AIE_GEN > 2` XTime gate: skill **bspheadergen2**.
- **[script/kc.sh](script/kc.sh)** — after linking the kernel ELF, `strip_kernel_debug_loc` drops `.debug_loc` + the `.debug_info` group via `llvm-objcopy` (13.7 MB → 82 KB on matmul; this is JTAG download time, since the kernel ELF is embedded into the host ELF and `dow -force`d). `.debug_line` is kept, so `kernel.linemap.json` / aiediag pc are unaffected; the full-DWARF original is parked at `<out>/kernel_debug`. `--keep-debug-loc` opts out. Must be `llvm-objcopy` — GNU binutils rejects the chess `e_machine 0x108`.

## Key Terms

| Term | Definition |
|------|------------|
| **PDI** | Pre-built hardware design; decouples HW/SW development |
| **GMIO** | Global Memory I/O; DDR ↔ AIE via NoC |
| **Shim tile** | Row-0 tile bridging NoC/DDR and AIE array |
| **MemTile** | Large-memory tile for caching between DDR and compute tiles |
| **BD** | Buffer Descriptor; configures a DMA transfer |
| **DSKernel** | Data-streaming kernel (receives via DMA, computes, outputs via DMA) |
| **EmitC** | MLIR dialect for C/C++ emission; final stage before `translateToCpp` |
| **xchesscc** | Synopsys compiler for AIE cores (from Vitis) |
| **PAL** | Board environment for running ELFs on real AIE hardware |

## Working rules

- **Never** let an API function exceed 200 lines.
- **Create a skill** whenever an issue is fixed, or whenever the user has to correct
  something you did wrong.
- **Keep the architecture docs current** — update them as part of the change, not after.
- **After each task, list every file changed or created.**
