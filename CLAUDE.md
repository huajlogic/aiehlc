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

Concise index — open the referenced file/skill for full detail.

### Design & architecture docs
- **[doc/module_analysis.md](doc/module_analysis.md)** — 9-module (M1–M9) breakdown: key files, line counts, I/O, dependencies, data flow.
- **[doc/aieapi.md](doc/aieapi.md)** — XAie driver API guide: single-tile, multi-tile manual routing/DMA/locks, production call patterns.
- **[doc/tilinglinalg.md](doc/tilinglinalg.md)** — TilingLinalg deep dive: 6 dialects, 15 passes, routing engine, test/build/HW-run flow.
- **[doc/lowering.md](doc/lowering.md)** — Concrete IR lowering trace through every dialect stage with IR snippets and op→API tables.
- **[doc/design/tile_dim_structured_design.md](doc/design/tile_dim_structured_design.md)** — Structured `tile_dim` (size/stride/groups) for `aie::SpatialPolicy`; conv halo/overlap unification.
- **[doc/design/spatial_space_composition.md](doc/design/spatial_space_composition.md)** — Composition-based spatial op spaces (GemmSpace/Conv2dSpace compose a lean policy).
- **[doc/llvm_mlir_pitfalls.md](doc/llvm_mlir_pitfalls.md)** — Known LLVM/MLIR API pitfalls (ArrayRef, StringRef lifetime, RTTI, constant folding, etc.).
- **[doc/design/aiegdb_live_debug_framework.md](doc/design/aiegdb_live_debug_framework.md)** — Design for a live AIE debug/test daemon + polling JSON endpoints unifying static viewer with runtime tools.

### Verification skills (static, pre-HW)
- **Skill xaieapiverify** (`.cursor/skills/xaieapiverify/SKILL.md`) — Static verification of XAie API calls in generated code (ports, DMA/lock, path connectivity).
- **Skill routinghwdebug** (`.cursor/skills/routinghwdebug/SKILL.md`) — End-to-end routing debug: trace errors back EmitC→routinghw→dmaphop→dmap→routing.
- **Skill dmabdverify** (`.cursor/skills/dmabdverify/SKILL.md`) — Static verification of DMA BD config in host.cc (BD/lock IDs, ping-pong, lengths, packet IDs).
- **Skill datacorrectness** (`.cursor/skills/datacorrectness/SKILL.md`) — Pre-HW-run data-correctness checklist (type widths, direction, banks, addresses, locks).
- **Skill aiedriverkb** (`.cursor/skills/aiedriverkb/SKILL.md`) — AIE Driver Knowledge Base for XAie driver internals (ELF loading, bounds checking).
- **Command data-mismatch-debug** (`.claude/commands/data-mismatch-debug.md`) — Systematic DMA data-mismatch debug (supply/demand tables, root-cause patterns).

### Live HW / simulator debug skills
- **Skill aiehwdmadebug** (`.cursor/skills/aiehwdmadebug/SKILL.md`) — Live DMA debug over JTAG/XSDB; decodes AIE2PS DMA status regs; offset-as-value decode pitfall.
- **Skill aieswitchtrace** (`.cursor/skills/aieswitchtrace/SKILL.md`) — Live stream-switch read-back/flow-trace via aiegdb `show switch`/`scan switch`.
- **Skill aiesimloaddebug** (`.cursor/skills/aiesimloaddebug/SKILL.md`) — Debug AIE simulator segfaults at PS.so load (stale kernel_elf_init.cc symbol, missing stub).
- **Skill aiehwprofile** (`.cursor/skills/aiehwprofile/SKILL.md`) — Capture AIE HW perf counters via the Vitis `aieprofile` XSDB package; all-zero-CSV troubleshooting.
- **Skill debugui-llm-reset** (`.cursor/skills/debugui-llm-reset/SKILL.md`) — Diagnoses embedded-LLM context loss / stale live tools on dynamic target changes.
- **Skill plugin dbg-llm-skills** (`src/tool/debug/dbg_llm_skills/`) — Nine live-debug procedures for the embedded debug-UI assistant; loadable locally via `--plugin-dir`.
- **External aiedbg clone** (`/scratch/staff/bkirinci/aiedbg`, on PATH) — Tool that reaches hardware; ~2600 lines of docs live only in the clone; `reg lookup` runs offline (use `--device-type pal`).

### Debug tooling (source)
- **[src/tool/debug/aiediag.py](src/tool/debug/aiediag.py)** — Flow-aware DMA diagnostic: reads DMA status regs via aiedbg, cross-refs provenance JSONs, prints root cause.
- **[src/tool/debug/aiegdb.py](src/tool/debug/aiegdb.py)** — GDB-like scoped CLI over aiedbg (partition→tile→channel); `COMMAND_SPEC` is the machine-readable grammar.
- **[src/tool/debug/aiemcp.py](src/tool/debug/aiemcp.py)** — MCP server exposing aiegdb live debug to Claude Code (`aie_exec`, etc.); fd-level capture; session gating.
- **[src/tool/debug/xaiehost2provenance.py](src/tool/debug/xaiehost2provenance.py)** — Static provenance generator for the raw-XAie single-kernel aiehlc flow (no worklocal bundle).
- **[src/tool/debug/schedule_debug_server.py](src/tool/debug/schedule_debug_server.py)** — Live debug daemon. Notable areas: session provenance (states none/connected/attached/ran; app_paths); app capability detection (tags sim/hw; board resolved live, never baked into a profile); run-state reconciliation (`/runstate`, busy flags, unconditional `stop_run`); one-device-namespace (`st.device` unified with board dropdown); source viewer (`/source` Pygments + two-tier path resolution, auth-gated); source grounding (app source manifest + kernel→definition map).
- **[src/tool/debug/schedule_view.py](src/tool/debug/schedule_view.py)** — Static/live HTML viewer. Notable areas: aiegdb console tab (foldable per-command blocks, CON_RULES classifier); device-map flow lanes (one lane per flow); pane names (AIE Debug/Run/Info/Tools) + empty-tile handling; scan controls (pills select, Scan reads once, live polls 2s); LLM tool-call rendering (collapse markers, FIFO pairing); context pills inline (contenteditable prompt box); transcript bottom-pinning; working indicator driven by `/llm/poll` active flag.
- **[src/tool/debug/debug_ui_mcp.py](src/tool/debug/debug_ui_mcp.py)** — MCP tools for the debug UI (`get_pane`, `list_panes`, `app_sources`, `get_backend_status`).

### Build/profile scripts
- **[script/verify_env.sh](script/verify_env.sh)** — Environment verification (Vitis, LLVM, toolchain, aie-rt, BSP, board vars).
- **[script/debug/aieprofile.sh](script/debug/aieprofile.sh)** (+ `aieprofile.tcl`, `aierun_retrigger.tcl`, `aieprofile_summary.py`, `aieprofile_report.py`) — AIE HW performance-counter capture wrapper: the only Vitis path reaching a baremetal run; ordering (program-once→reload-ELF→profile→resume); event-id module offsets; tabular + visual readers.

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
