# AIEHLC

App Writing and Deployment Tutorial: [tutorial.md](tutorial/tutorial.md)

## What is the aiehlc?

AIEHLC(AIE high‑level compiler) is a lightweight, efficient high level compilation integration solution for AIE (AI Engine) applications on Versal AI Core Series. It integrates with pre-built hardware designs (PDI) to effectively decouple hardware and software application development, providing a comprehensive end-to-end deployment solution.

Key features:

> Integrate and Support the [Synopsys](https://www.synopsys.com/) chess compiler (from the [Vitis](https://www.amd.com/en/products/software/adaptive-socs-and-fpgas/vitis.html) package) for kernel code compilation

> It Also Integrate and Supports the opensource [LLVM-AIE](https://github.com/Xilinx/llvm-aie) compiler solution for kernel compilation

> Simplifies the AIE application development learning curve for rapid prototyping


AIEHLC empowers users to develop straightforward AIE applications using only the AIE driver C API, eliminating the need to learn additional domain-specific languages (DSLs). This streamlined approach target to accelerates the development process and reduces barriers to entry for AIE application development.

### Architecture

![architecture diagram](doc/diagram/architecture.png)

### What it is Not

1. It serves as a complementary solution and is not intended to replace the official AIE software application compilation tools.
2. It focuses solely on software compilation and does not function as a hardware design compilation tool.
3. It currently supports only Versal AI Core Series devices and does not provide compatibility with Ryzen AI SOCs.

### What are the Limitations

Its primary goal is to help system engineers simplify the learning curve for AIE application development and enable quick prototyping. As a result, it may not be as feature-complete as the official tools available.

### What are the Trade-Offs

1. The pre-built PDI (hardware design) supports only GMIO interfaces. For PLIO (FPGA) support, users must implement a customized hardware design with the appropriate PLIO logic components.

2. The pre-built hardware design (PDI) delivers adequate performance for most applications. However, for use cases requiring optimal Network-on-Chip (NOC) performance, the official Vitis hardware/software tools are recommended.

3. Users must configure routing at runtime. For Ahead-of-Time (AOT) routing support, it is recommended to utilize Vitis or AIECompiler tools instead.


## Examples

```bash
source script/setup.sh
#or
source ./script/setup.sh --bsp-use-git-repo=https://path/to/aie-rt.git

source script/aiehlc.sh --runtime-source-file example/perf/aieml_perf.cc 
```

Using llvm-aie (experimental):

```bash
source script/setup.sh
#or
source ./script/setup.sh --bsp-use-git-repo=https://path/to/aie-rt.git

source script/aiehlc.sh --use-llvm-aie --runtime-source-file example/other/multikernel.cc
```

AIE2PS Compilation Support

```bash
source script/setup.sh
#or
source ./script/setup.sh --bsp-use-git-repo=https://path/to/aie-rt.git

source script/aiehlc.sh --aie-version 5 --runtime-source-file example/perf/aieml_perf.cc
```

PetaLinux Support

```bash
source script/setup.sh
#or
source ./script/setup.sh --bsp-use-git-repo=https://path/to/aie-rt.git

source script/aiehlc.sh --platform linux --aie-version 2 --runtime-source-file tutorial/example.cpp
```

## Runtime Debug Level

Control runtime diagnostic verbosity and feature flags from your source file using `#pragma aie_debug_level`:

```cpp
#pragma aie_debug_level 2

__global__ void mykernel(const int32_t *A, int32_t *B) {
    // kernel code
}

int main() {
    // host code
}
```

The debug level value is a bitfield:
- **Bits 0-3**: verbosity level (0-15)
- **Bits 4-31**: feature flags

### Verbosity Levels (bits 0-3)

| Level | Behavior |
|-------|----------|
| `0` | Silent (default when pragma is absent) |
| `1` | BD tracking and IO logs |
| `2` | Full diagnostics: DMA address log, write pattern, readback |

### Feature Flags (bits 4+)

| Flag | Bit | Value | Behavior |
|------|-----|-------|----------|
| `DISABLE_MULTID_DIM_DMA` | 4 | `16` | Suppress multi-dimensional DMA; force linear `__Runtime_dma_bd_config` |

### Examples

| Pragma Value | Verbosity | Flags | Effect |
|-------------|-----------|-------|--------|
| `0` | 0 | none | Silent, multi-dim DMA enabled |
| `1` | 1 | none | BD tracking, multi-dim DMA enabled |
| `2` | 2 | none | Full diagnostics, multi-dim DMA enabled |
| `16` | 0 | `DISABLE_MULTID_DIM_DMA` | Silent, multi-dim DMA suppressed |
| `18` | 2 | `DISABLE_MULTID_DIM_DMA` | Full diagnostics + multi-dim DMA suppressed |

The pragma is detected during preprocessing and emits a strong symbol override of `g_runtime_debug_level` into the generated `host.cc`. The runtime in `aie_runtime.c` defines this variable as a weak symbol with default `0`, so the linker picks the user-specified value when present.

This works for both single-tile (`aiehlc`) and multi-tile (`tilinglinalg`) compilation paths.

## Debug Tools

### aiediag — Flow-Aware DMA Diagnostic

`aiediag` (`script/aiediag.py`) is a post-deployment diagnostic tool for debugging DMA stalls and data flow issues on live AIE hardware. It reads DMA status registers via `aiedbg`, cross-references them with compile-time provenance JSONs to identify connected tiles and routing paths, and prints an automated diagnosis.

#### When to Use

- A DMA channel is stuck (stream starvation, backpressure, lock stall)
- Output data is missing or incomplete after a HW run
- You need to determine whether `start_io` was actually issued on a shim tile
- You want to trace a data flow from shim through core tiles and identify where it stalls

#### Usage

```bash
# Basic: diagnose MM2S ch0 on logical tile (1,4) with startcol offset 3
python3 script/aiediag.py dig 1 4 -mm2s0 startcol 3 -dev pal

# Dry-run (no HW access, prints what would be read)
python3 script/aiediag.py dig 1 4 -mm2s0 startcol 3 --dry-run

# Specify AIE version and custom JSON directory
python3 script/aiediag.py dig 0 3 -s2mm1 --aie-version 2ps --json-dir ./my_worklocal

# Custom shim events JSON location
python3 script/aiediag.py dig 0 0 -mm2s0 --shim-events-json /path/to/shimtile_events.json -dev pal
```

#### Arguments

| Argument | Description |
|----------|-------------|
| `COL` | Logical column (from IR/JSON, 0-based) |
| `ROW` | Physical row (0=shim, 1=memtile, 3-6=core for AIEML) |
| `-mm2s0`, `-s2mm1`, etc. | Direction and channel number |
| `startcol N` | Physical column offset; physical_col = COL + startcol |
| `--aie-version` | `5` (AIEML, default) or `2ps` |
| `-dev`, `--device` | Device type passed to aiedbg (e.g., `pal`) |
| `--target` | Target passed to aiedbg (e.g., `baremetal://192.168.0.1:9999`) |
| `--json-dir` | Directory containing provenance JSON files |
| `--shim-events-json` | Path to `shimtile_events.json` (default: `~/aiejson/shimtile_events.json`) |
| `--dry-run` | Print aiedbg commands without executing |

#### Diagnostic Steps

The tool runs 7 steps in sequence:

1. **DMA Status** — Read the queried tile's DMA status register (running/idle/stalled, stall cause, current BD, queue size)
2. **BD Chain** — Show the buffer descriptor chain from JSON (BD IDs, lengths, locks, ping-pong, packet IDs, repeat count)
3. **Connected Tiles** — Use the flow summary to find all senders/receivers in the same data flow
4. **Connected Tile DMA Status** — Read DMA status registers of all connected tiles
4b. **Shim Event Status** — For shim tiles (row=0), read hardware event status registers to determine whether DMA start/finish/stall events have fired
5. **Connected Tile BD Chains** — Show BD chains of connected tiles
6. **Routing Path** — Show the physical routing hops from dmaphop provenance map
7. **Diagnosis** — Automated root-cause analysis combining all data sources

#### Prerequisites

##### aiedbg

`aiedbg` must be in `PATH`. It is the Xilinx/AMD AIE debug CLI that reads/writes AIE tile registers over JTAG or network. It is part of the Vitis installation (`$XILINX_VITIS/bin/aiedbg`) or can be installed separately.

The tool invokes it as:
```
aiedbg [--target TARGET] [--device DEVICE] reg read PHYS_COL ROW 0xOFFSET
```

##### Provenance Map JSONs

These JSON files are generated by the tilinglinalg compilation pipeline and describe the compiled data flow. The tool auto-searches these directories (in order):

1. `./worklocal/`
2. `./aout/worklocal/`
3. `./src/mlir/mlirfront/tilinglinalg/pass/unitest/build/worklocal/`
4. `./src/mlir/mlirfront/tilinglinalg/pass/unitest/worklocal/`

Or use `--json-dir` to specify explicitly.

**`dfscheduleprovenancemap.json`** — Generated by `DfscheduleToApiPass` / `DfscheduleToKernelApiPass`. Contains:
- `tiles[]` — Every tile with its DMA channels, BD chains (bd_id, buffer_offset, len, locks, packet_id, next_bd, dim_strides, iter_wrap), start_io repeat counts, and contracts
- `flow_summary[]` — Each data flow with its participants (tile_col, tile_row, io_direction, channel, repeat_count, bd_len)

**`dmaphopprovenacemap.json`** (or `provenance_map.json`) — Generated by `DmaphopTodfscheblueprintPass`. Contains:
- `communication_paths[]` — Each path with producer/consumer tiles, physical hop chain, tensor shape, partition info, and port symbols

##### shimtile_events.json

Default location: **`~/aiejson/shimtile_events.json`**

This file maps hardware event IDs to human-readable names for the shim tile PL module. It is derived from the AIE driver source (`aie_runtime_debug.c :: s_pl_evt_names`). The file structure:

```json
{
  "module": "PL",
  "description": "Shim tile (PL module) events ...",
  "source": "aie_runtime_debug.c :: s_pl_evt_names[117]",
  "max_id": 116,
  "events": {
    "0": "NONE",
    "14": "DMA_S2MM_0_START_TASK",
    "15": "DMA_S2MM_1_START_TASK",
    "16": "DMA_MM2S_0_START_TASK",
    "17": "DMA_MM2S_1_START_TASK",
    "18": "DMA_S2MM_0_FINISHED_TASK",
    "19": "DMA_S2MM_1_FINISHED_TASK",
    "...": "..."
  }
}
```

Key DMA event IDs used by aiediag (all in the shim PL event status registers at `0x34200`-`0x34204`):

| Event ID | Name | What It Means |
|----------|------|---------------|
| 14-17 | `DMA_*_START_TASK` | DMA channel was started (start_io was issued) |
| 18-21 | `DMA_*_FINISHED_TASK` | DMA channel completed all programmed transfers |
| 22-25 | `DMA_*_STALLED_LOCK` | DMA stalled waiting for lock |
| 26-27 | `DMA_S2MM_*_STREAM_STARVATION` | S2MM has no data arriving from stream |
| 28-29 | `DMA_MM2S_*_STREAM_BACKPRESSURE` | MM2S cannot push data (downstream full) |
| 30-33 | `DMA_*_MEMORY_*` | Memory-side stall (backpressure or starvation) |

The `~/aiejson/` directory also contains event JSONs for other tile types (`core_events.json`, `memtile_events.json`) and register address maps (`aie2ps*.json`). If `shimtile_events.json` is missing, aiediag prints a warning and skips the shim event check; all other diagnostic steps still run.

## Compiling aiehlc (Optional)

Building aiehlc is only necessary if you intend to develop or compile aiehlc itself. If your aim is simply to use aiehlc, this step is not required.

Build Tutorial: [build.md](doc/build.md)

## Contributing

If you plan to contibute code then make sure you set up the clang-format pre-commit hook.

```bash
source script/precommitsetup.sh
```

<p align="center">Copyright&copy; 2025 Advanced Micro Devices, Inc</p>
