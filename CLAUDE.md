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
cd src/mlir/mlirfront/tilinglinalg/pass/unitest && mkdir -p build && cd build && cmake .. && make -j4
```

Each dialect has `td/` (TableGen), `gen.sh` (runs mlir-tblgen), and `inc/` (generated .inc files).

## Test and Verification

### Unitest CLI (`pass/unitest/test.cpp`)

```bash
./test dfschedule    # Full pipeline → host.cc + kernel.cc
./test hw            # Routing path → routing.cc
./test test          # Path contiguity verification
./test               # Default: runs both dfschedule and hw
```

### End-to-End Flow

```
1. Generate    cd unitest/build && ./test dfschedule     → worklocal/{host,kernel}.cc
2. Kernel      cd worklocal && source compile_kernel.sh  → build/kernel (ELF)
3. Host        cd worklocal && source hostcompile.sh     → build/host (ELF)
4. HW run      python3 script/test/apppaltest.py build/host  → SSH+xsdb+console
5. Verify      script/test/verify_host.sh → pass: "device_teardown done", fail: "AIE ERROR"
```

`piplinerun.sh` automates steps 1-4.

### Per-Dialect Unit Tests

Each dialect has its own `unitest/` directory with independent CMake build:
- `routing/unitest/`, `routinghw/unitest/`
- `dataflowmap/{dmap,dmaphop,dfschedule,dfscheblueprint}/unitest/`
- `pass/routingimplement/{routing,hw}/unitest/`

## Additional Documentation

- **[doc/aieapi.md](doc/aieapi.md)** — XAie driver API guide covering: simple single-tile flow (`aieml_perf.cc`), multi-tile manual routing/DMA/locks (`aie_control.cpp`), and production XAie call patterns from `common_layer/aeg_runtime_api.cpp` (transaction batching, broadcast core enable, BD recycling, ping-pong RTP, advanced DMA config)
- **[doc/tilinglinalg.md](doc/tilinglinalg.md)** — TilingLinalg deep dive: all 6 custom dialects (ops, types, attrs), 15 pass transformations, routing engine internals, and complete test/build/HW-run/verification flow including remote board login
- **[doc/lowering.md](doc/lowering.md)** — Concrete IR lowering trace: walks a 2x2 mesh / 16x16 tensor through every dialect stage (routing→dmap→dmaphop→blueprint→dfschedule→EmitC and routing→routinghw→EmitC) with actual IR snippets, op-to-API mapping tables, tile/lock/BD allocation, and data partitioning breakdown
- **Skill: xaieapiverify** (`.cursor/skills/xaieapiverify/SKILL.md`) — Agent-driven static verification of XAie API calls in generated code (routing.cc, host.cc). Checks port number limits, tile-type-aware PortVerify rules, packet switch consistency, DMA/Lock constraints, and routing path connectivity against driver validation rules
- **Skill: routinghwdebug** (`.cursor/skills/routinghwdebug/SKILL.md`) — End-to-end routing debug: scans routing.cc with xaieapiverify, traces errors backward through EmitC -> routinghw -> dmaphop -> dmap -> routing, examines routingimplement (hwresource port templates, BFS path finding, ResourceManager) to find root causes, and provides targeted fixes
- **Skill: dmabdverify** (`.cursor/skills/dmabdverify/SKILL.md`) — Static verification of DMA Buffer Descriptor configuration in generated host.cc. Checks BD IDs, lock IDs/values, ping-pong chaining, buffer lengths, packet IDs, and channel assignments against AIEML hardware limits. Catches DMA/lock issues before HW deployment
- **Skill: datacorrectness** (`.cursor/skills/datacorrectness/SKILL.md`) — Pre-HW-run checklist for data correctness: type width consistency, input/output direction, buffer bank assignment, address validity, tensor slice coverage, and lock protocol. Catches output-wrong/output-zero bugs before board runs
- **Skill: aiedriverkb** (`.cursor/skills/aiedriverkb/SKILL.md`) — AIE Driver Knowledge Base: structured reference for XAie driver APIs in `thirdparty/alib/aie-rt`. Covers ELF loading (KB-101: PT_LOAD-only segment loading, PM/DM bounds checking, file size vs loadable size distinction), and other driver internals. Use when analyzing HW logs or verifying assumptions about driver behavior
- **[doc/llvm_mlir_pitfalls.md](doc/llvm_mlir_pitfalls.md)** — Known LLVM/MLIR API pitfalls: ArrayRef dangling references, FileEntry/Rewrite crashes, StringRef lifetime, RTTI requirements, getBuffer null dereference, recursive TableGen, constant propagation pattern match, integer overflow, and MLIR SSA discipline
- **[script/verify_env.sh](script/verify_env.sh)** — Environment verification script: validates Vitis, LLVM, cross-compiler toolchain, aie-rt driver, BSP directories, Docker timezone, build directories, and PAL/board test variables. Run before build to catch setup issues early

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


## Team Chat (Mattermost)

Self-bootstrapping Mattermost deployment for team communication and Claude Code integration.

### Quick Start

```bash
# One command to set up everything and launch Claude Code with chat
.claude/skills/chatsupport/claude-chat.sh

# Or manage Mattermost independently
.claude/skills/chatsupport/mattermost-setup.sh start    # Bootstrap or start
.claude/skills/chatsupport/mattermost-setup.sh stop     # Stop containers
.claude/skills/chatsupport/mattermost-setup.sh status   # Check health
.claude/skills/chatsupport/mattermost-setup.sh backup   # Database backup
.claude/skills/chatsupport/mattermost-setup.sh destroy  # Tear down everything
.claude/skills/chatsupport/mattermost-setup.sh token    # Show bot token
```

### Chat in Claude Code

Use `/chat` slash command (requires Mattermost running + MCP configured):
- `/chat` -- read recent messages from `aiehlc-dev`
- `/chat read build-status` -- read specific channel
- `/chat post <message>` -- post to `claude-assistant` channel
- `/chat status` -- post build/test status to `build-status`

### Files

| File | Purpose |
|------|---------|
| `.claude/skills/chatsupport/mattermost-setup.sh` | Bootstrap & lifecycle management |
| `.claude/skills/chatsupport/docker-compose.yml` | Mattermost + PostgreSQL containers |
| `.claude/skills/chatsupport/claude-chat.sh` | One-command launcher |
| `.claude/skills/chatsupport/chat.md` | `/chat` slash command definition |

### Infrastructure

- **Deploy location**: `/scratch/staff/huaj/mattermost/` (persistent, outside repo)
- **Web UI**: `http://<hostname>:8065`
- **PostgreSQL**: `localhost:5433` (avoids conflict with standard 5432)
- **Bot token**: `~/.mattermost-claude-token`
- **MCP**: Auto-configured in `.mcp.json` via `@nicobailon/mattermost-mcp-server`

## Learn rule
- create skill when a issue fixed
- when do somthing wrong that is fix by user guide create related skill
## Document rule
- Maintain and update architecture doc and keep update after do some changes
## Process transperent rule
_ after each task done, list all files that change or new created

