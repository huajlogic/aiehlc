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
│           └── tilinglinalg/      # ★ Multi-tile GEMM pipeline
│               ├── routing/       # Abstract routing dialect
│               ├── routinghw/     # Physical routing dialect
│               ├── dataflowmap/   # dmap, dmaphop, dfscheblueprint, dfschedule dialects
│               └── pass/          # All lowering passes + unitest/
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
`aietriton_pybind.cpp`. Python entry: `_compiler.compile_plan(..., via_aiegraph=True)`.

### Pass Pipeline

**Shared stages** (produces dfscheblueprint IR, then module is cloned):

1. `RoutingUnrollingLowerPass` — unroll abstract routing into per-tile ops
2. `RoutingToDmapPass` — routing → logical dataflow
3. `DmapToDmaphopPass` — logical → physical hops
4. `DmaphopTodfscheblueprintPass` — hops → schedule blueprints

**Host path** → `host.cc`:

5. `BlueprintToSchedulePass` → `ScheduleCanonicalizePass` → `DfscheduleToApiPass` → `RoutingConstantFoldPass` → `CanonicalizerPass` → EmitC → `host.cc`

**Kernel path** → `kernel.cc`:

5. `BlueprintToScheduleKernelPass` → `DfscheduleToKernelApiPass` → EmitC → `kernel.cc`

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

### Design & Reference Docs
- **[doc/module_analysis.md](doc/module_analysis.md)** — 9-module breakdown (M1–M9) with key files, line counts, I/O, dependencies, data-flow diagram.
- **[doc/aieapi.md](doc/aieapi.md)** — XAie driver API guide: single-tile flow, multi-tile manual routing/DMA/locks, production call patterns.
- **[doc/tilinglinalg.md](doc/tilinglinalg.md)** — TilingLinalg deep dive: all 6 dialects, 15 passes, routing engine, test/build/HW-run flow.
- **[doc/lowering.md](doc/lowering.md)** — IR lowering trace of a 2x2 mesh / 16x16 tensor through every dialect stage, with IR snippets and op→API tables.
- **[doc/llvm_mlir_pitfalls.md](doc/llvm_mlir_pitfalls.md)** — Known LLVM/MLIR API pitfalls (ArrayRef dangling, StringRef lifetime, RTTI, SSA discipline, etc.).
- **[doc/design/tile_dim_structured_design.md](doc/design/tile_dim_structured_design.md)** — Structured `tile_dim` (size/stride/groups) for `aie::SpatialPolicy`; unifies conv halo/overlap.
- **[doc/design/spatial_space_composition.md](doc/design/spatial_space_composition.md)** — Composition-based op spaces (`GemmSpace`, `Conv2dSpace`) over a lean `SpatialPolicy`.
- **[doc/design/aiegdb_live_debug_framework.md](doc/design/aiegdb_live_debug_framework.md)** — Design for the live debug/test framework unifying the static schedule viewer with a runtime daemon.
- **[doc/design/tvm_frontend.md](doc/design/tvm_frontend.md)** — TVM ResNet-18 frontend (`src/frontend/tvm/`), a **third frontend into `TilingLinalgPipeline`** alongside C++ `aiehlc` and `aietriton`: ONNX→Relay→fused-graph walk→per-layer `run_aie_pipeline` launches, reusing `_aietriton_core`. Covers the op-mapping table, the bit-exact Q7 int8 CPU oracle, and the pybind `dma_specs` (generic `DmaAddressing`) extension for the im2col conv path.
- **[doc/design/tvm_custom_model_recipe.md](doc/design/tvm_custom_model_recipe.md)** — "bring your own model" how-to for the TVM frontend: take a customized model (contrasted with the full ImageNet `example/model/resnet18py`) through ONNX→Relay→`walk.build_plan`→`run_aie_pipeline`, editing `model.py`'s `layer_plan()`/`build_torch_model()` in lock-step. Step-by-step recipe plus the int8-config / fixed-op-set / placeholder-weight constraints and a scale-down mapping table.

### Skills (static verification & debug procedures)
- **xaieapiverify** — Static verification of XAie API calls in generated code (port limits, PortVerify, packet consistency, routing connectivity).
- **routinghwdebug** — End-to-end routing debug: scan routing.cc, trace errors back through the dialect stack to routingimplement root causes.
- **dmabdverify** — Static verification of DMA Buffer Descriptor config in host.cc (BD/lock IDs, ping-pong, lengths, packet IDs, channels).
- **datacorrectness** — Pre-HW-run checklist: type widths, direction, bank assignment, address validity, tensor coverage, lock protocol.
- **aiedriverkb** — AIE Driver Knowledge Base for XAie APIs in `thirdparty/alib/aie-rt` (e.g. KB-101 ELF loading).
- **aiehwdmadebug** — Live JTAG/XSDB DMA debug (aiediag/aiedbg/aieshow); decodes AIE2PS DMA status; offset-as-value pitfall.
- **aiesimloaddebug** — Debug sim (`aie2pssimmsm`) segfaults at PS.so load; usual cause is a stale `kernel_elf_init.cc` symbol.
- **aiehwprofile** — Capture AIE HW perf counters from a running board via the Vitis `aieprofile` XSDB package.
- **debugui-llm-reset** — Diagnose embedded-LLM context loss / stale live tools during target changes (retarget without restarting Claude).
- **dbg-llm-skills** (`src/tool/debug/dbg_llm_skills/`) — Plugin of 9 live-debug procedures loaded by the daemon via `--plugin-dir`.
- **Command: data-mismatch-debug** (`.claude/commands/data-mismatch-debug.md`) — Systematic DMA data-mismatch debug (supply/demand tables, root-cause patterns).

### Debug Tooling
- **External: aiedbg clone** (`/scratch/staff/bkirinci/aiedbg`, on PATH) — The tool reaching the hardware; docs live only in the clone. `reg lookup` runs offline (spell `--device-type pal`).
- **[src/tool/debug/aiediag.py](src/tool/debug/aiediag.py)** — Flow-aware DMA diagnostic: reads DMA status regs, cross-refs provenance JSONs, prints root-cause diagnosis. Also holds switch read-back/flow-trace (`show/scan switch`).
- **[src/tool/debug/aiegdb.py](src/tool/debug/aiegdb.py)** — GDB-like scoped CLI over aiedbg (partition→tile→channel). `COMMAND_SPEC` is the shared machine-readable grammar.
- **[src/tool/debug/aiemcp.py](src/tool/debug/aiemcp.py)** — MCP server exposing aiegdb to Claude Code (`aie_exec/scope/commands/help`); in-process singleton; session-gated.
- **[src/tool/debug/xaiehost2provenance.py](src/tool/debug/xaiehost2provenance.py)** — Static provenance generator for the raw-XAie single-kernel flow (parses host.cc XAie calls → provenance JSON).
- **[src/tool/debug/schedule_debug_server.py](src/tool/debug/schedule_debug_server.py)** — Live-debug daemon. Handles session provenance (none/connected/attached/ran), app capability detection (sim/hw), run-state reconciliation, board-per-run resolution, source grounding, one device namespace. See git history for the detailed rationale of each subsystem.
- **[src/tool/debug/schedule_view.py](src/tool/debug/schedule_view.py)** — Renders `host_schedule.html`: aiegdb console tab, source viewer, device-map flow lanes, pane names, scan controls, LLM tool-call rendering, inline context pills, transcript pinning, working indicator.
- **[src/tool/debug/debug_ui_mcp.py](src/tool/debug/debug_ui_mcp.py)** — MCP tools for the debug UI (`get_pane`, `list_panes`, `app_sources`, `get_backend_status`).
- **[script/debug/aieprofile.sh](script/debug/aieprofile.sh)** (+ `aieprofile.tcl`, `aierun_retrigger.tcl`, `aieprofile_summary.py`, `aieprofile_report.py`) — Wrapper around the Vitis `aieprofile` XSDB package; program-once → reload-ELF → profile → resume; two readers render the CSVs.
- **[script/verify_env.sh](script/verify_env.sh)** — Environment verification (Vitis, LLVM, cross-compiler, aie-rt, BSP, PAL/board vars). Run before build.

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

## never do
- the api function > 200 lines
## Learn rule
- create skill when a issue fixed
- when do somthing wrong that is fix by user guide create related skill
## Document rule
- Maintain and update architecture doc and keep update after do some changes
## Process transperent rule
- after each task done, list all files that change or new created
## Memory and Lock
- ./doc/aiedifferentview.md
