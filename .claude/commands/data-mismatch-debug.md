# Data Mismatch Debug

Systematic debug procedure for AIE data mismatch issues: stream starvation, DMA stall, output-wrong, or output-zero. Traces data volume from shim tiles through core tiles to kernels, identifying supply/demand mismatches.

## Inputs

The user provides:
- `host.cc` path (generated host code, e.g. `aout/worklocal/host.cc`)
- `applog` path (HW run log with DMA status/events)
- Target tile or symptom (e.g. "tile(3,0) stream starvation")

If not provided, use defaults:
- host.cc: `aout/worklocal/host.cc` or `src/mlir/mlirfront/tilinglinalg/pass/unitest/worklocal/host.cc`
- applog: `./applog`

## Step 1: Identify the Stalled Tile from applog

Search applog for the symptom. Common patterns:

```
STREAM_STARVATION  → DMA S2MM waiting for data from stream (producer not sending enough)
MEMORY_STARVATION  → DMA MM2S waiting for DDR data (host-side buffer issue)
STREAM_BACKPRESSURE → DMA MM2S blocked because downstream is full
MEMORY_BACKPRESSURE → DMA S2MM blocked because local buffer is full
STALLED: stream=1  → DMA channel waiting for stream data
STALLED: lock_acq=1 → DMA channel waiting for lock (ping-pong not cycling)
```

Search commands:
```
grep -n "STARVATION\|BACKPRESSURE\|STALLED" applog
grep -n "tile(X,Y)" applog   # for specific tile status
```

Extract from the DMA status section:
- Which channels are stalled (S2MM vs MM2S, ch0 vs ch1)
- Current BD contents (addr, len, dims, iter curr vs wrap)
- Whether the channel is Idle (finished) or Running+Stalled

## Step 2: Map Tile Roles from host.cc

For the stalled tile, determine its role:

### Shim tile (row=0): XAie_TileLoc(col, 0)

Find the variable name:
```
grep "XAie_TileLoc(COL, 0)" host.cc
```

Then find ALL DMA BD configs on that tile:
```
grep "__Runtime_dma_bd_config.*TILE_VAR" host.cc
grep "__Runtime_dma_bd_config_multidim_ooo.*TILE_VAR" host.cc
```

Classify each channel:
- **MM2S** = sending data FROM DDR TO cores (input broadcast)
- **S2MM** = receiving data FROM cores TO DDR (output gather)

### Core tile (row>=3): XAie_TileLoc(col, row)

Find DMA configs:
```
grep "__Runtime_dma_bd_config.*TILE_VAR" host.cc
```

Core tiles typically have:
- **S2MM ch0**: receives input A (from shim broadcast)
- **S2MM ch1**: receives input B (from shim broadcast)
- **MM2S ch0**: sends output C (to shim gather)

## Step 3: Compute Data Volumes

For each DMA channel involved, compute the total data volume.

### 3a. Shim BD volume

For `__Runtime_dma_bd_config_multidim_ooo` (22-arg):
```
args: (DevInst, tile, buf, bd_id, len, next_bd,
       enable_packet, packet_id, acq_lock_id, acq_lock_val,
       rel_lock_id, rel_lock_val, ooo_bd_id,
       num_dims, d0_stride, d0_wrap, d1_stride, d1_wrap, d2_stride, d2_wrap,
       iter_step_size, iter_wrap)
```

**Per-BD transfer** = `len` bytes (single BD fire)
**With iteration** = `len * iter_wrap` bytes (if iter_wrap > 1)

Find the startio for this channel:
```
grep "__Runtime_startio.*IO_VAR" host.cc
```
Format: `__Runtime_startio(DevInst, io_var, bd_id, repeat_count)`

**Total channel volume** = For OOO channels: `num_BDs * len * iter_wrap`
Or for non-OOO: `len * repeat_count` (repeat re-fires the BD)

### 3b. Core BD volume

For `__Runtime_dma_bd_config` (13-arg):
```
args: (DevInst, tile, buf, bd_id, len, next_bd,
       enable_packet, packet_id, acq_lock_id, acq_lock_val,
       rel_lock_id, rel_lock_val, ooo_bd_id)
```

Core input BDs use ping-pong chains (`next_bd` links BD0->BD1->BD0...):
- **Per-fire**: `len` bytes
- **Total fires**: controlled by lock credits and data availability
- **startio repeat**: usually 1 (lock-driven re-arm)

Core output BDs:
- **Per-fire**: `len` bytes
- **startio repeat**: the number of times the BD is queued
- **Lock-driven**: kernel acquire/release output window triggers each fire

### 3c. Kernel volume (from kernel.cc / matmul.cc)

Read the kernel source for:
```c
const int k_rounds = N;        // K-accumulation iterations
const int num_a_rounds = N;    // DMA rounds for input A per k-round
const int num_b_rounds = N;    // DMA rounds for input B per k-round
const int num_c_rounds = N;    // output DMA rounds
const int buf_sz_a = N;        // bytes per A DMA round
const int buf_sz_b = N;        // bytes per B DMA round
const int buf_sz_c = N;        // bytes per C DMA round
```

Kernel total I/O:
- **Input A**: `k_rounds * num_a_rounds * buf_sz_a` bytes
- **Input B**: `k_rounds * num_b_rounds * buf_sz_b` bytes
- **Output C**: `num_c_rounds * buf_sz_c` bytes

Each `acquire_input_window` consumes `buf_sz` bytes (1 BD fire).
Each `release_output_window` produces `buf_sz` bytes (1 BD fire).

## Step 4: Build the Supply/Demand Table

For the stalled channel, fill in this table:

```
| Data Path              | Producer           | Volume      | Consumer           | Volume      | Match? |
|------------------------|--------------------|-------------|--------------------|-------------|--------|
| Input A: DDR→Shim→Core | Shim MM2S ch0      | len*repeat  | Core S2MM ch0/ch1  | kernel need | ?      |
| Input B: DDR→Shim→Core | Shim MM2S ch1      | len*repeat  | Core S2MM ch0/ch1  | kernel need | ?      |
| Output C: Core→Shim→DDR| Core MM2S ch0      | len*repeat  | Shim S2MM ch0/ch1  | expected    | ?      |
```

Key relationships:
- **Shim MM2S** sends input → **Core S2MM** receives (broadcast: same data to N cores)
- **Core MM2S** sends output → **Shim S2MM** receives (gather: OOO from N cores)
- **Shim S2MM repeat_count** = `num_core_tiles * output_rounds_per_core`
- **Core MM2S repeat_count** should = `num_c_rounds` (output rounds per kernel invocation)

## Step 5: Identify the Mismatch

Common mismatch patterns:

### Pattern A: Core output repeat too low
**Symptom**: Shim S2MM stream starvation, Core MM2S Idle
**Cause**: Core output `startio repeat=1` but kernel has `num_c_rounds > 1`
**Fix**: Set core output startio repeat = `num_c_rounds`
**Where to fix**: `BlueprintToSchedulePass` — core output startio repeat computation

### Pattern B: Shim MM2S iter_wrap mismatch
**Symptom**: Core S2MM stream starvation, Shim MM2S Idle
**Cause**: Shim input BD `iter_wrap` doesn't match `k_rounds`
**Fix**: Set shim MM2S iter_wrap = `k_rounds`
**Where to fix**: `DmaphopTodfscheblueprintPass` — shim dim computation

### Pattern C: Lock credit exhaustion
**Symptom**: Core DMA stalled on lock, not on stream
**Cause**: Lock init value too low for the number of ping-pong rounds
**Fix**: Adjust lock init values
**Where to fix**: `BlueprintToSchedulePass` — lock init computation

### Pattern D: BD chain length mismatch
**Symptom**: Core S2MM finishes early, kernel blocks on acquire
**Cause**: Ping-pong BD chain runs out of iterations
**Fix**: Ensure BD chain length * repeat covers all kernel rounds

## Step 6: Trace Back to Pass

Once the mismatch is identified, trace back to the responsible pass:

1. **startio repeat_count** → `BlueprintToSchedulePass` (lines ~1507-1530)
2. **shim dim_strides/wraps** → `DmaphopTodfscheblueprintPass` (lines ~820-862 for input, ~1163-1227 for output)
3. **core BD len/chain** → `BlueprintToSchedulePass` (lines ~1080-1450)
4. **OOO BD assignment** → `BlueprintToSchedulePass` (lines ~700-965)
5. **iter_step/iter_wrap** → `DmaphopTodfscheblueprintPass` and `BlueprintToSchedulePass`

## Step 7: Verify with Visualization

Run the host.cc visualization tool:
```bash
python3 ./script/visualization/host_cc_control.py HOST_CC_PATH --no-serve -m html -o /tmp/claude/debug.html
```

Check the generated HTML for:
- Complete shim tile chains (buffer_offset → dma_bd → create_io → start_io)
- Multidim BD parameters (strides, wraps, iter)
- Repeat counts on start_io nodes
- OOO BD cross-links

## Output Format

Present findings as:

```
=== Data Mismatch Analysis: tile(X,Y) ===

Symptom: [starvation/backpressure/stall type] on [channel]
Applog evidence: [line numbers and key status]

Q1. Shim tile expects to RECEIVE: N bytes (channels, BDs, repeat)
Q2. Core tiles expected to SEND:  N bytes (per tile, total)
Q3. Shim tile expects to SEND:   N bytes (channels, BDs, repeat)
Q4. Kernel I/O per core:
    - Input A:  N bytes (rounds)
    - Input B:  N bytes (rounds)
    - Output C: N bytes (rounds)

Supply/Demand Table:
[table as in Step 4]

Root Cause: [Pattern A/B/C/D description]
Fix Location: [pass name, approximate line range]
```

## Reference: Key Files

| File | Purpose |
|------|---------|
| `aout/worklocal/host.cc` | Generated host code with all DMA BD configs |
| `aout/worklocal/kernel.cc` | Generated kernel wrapper (buf sizes, rounds) |
| `aout/worklocal/matmul.cc` | User kernel (acquire/release loop counts) |
| `applog` | HW run log with DMA status and events |
| `pass/passblueprinttoschedule/` | Pass that generates startio, BD configs |
| `pass/passdmaphoptodfscheblueprint/` | Pass that generates shim dim strides/wraps |

## Reference: API Signatures

```
__Runtime_dma_bd_config(DevInst, tile, buf, bd_id, len, next_bd,
    enable_packet, packet_id, acq_lock_id, acq_lock_val,
    rel_lock_id, rel_lock_val, ooo_bd_id)

__Runtime_dma_bd_config_multidim_ooo(DevInst, tile, buf, bd_id, len, next_bd,
    enable_packet, packet_id, acq_lock_id, acq_lock_val,
    rel_lock_id, rel_lock_val, ooo_bd_id,
    num_dims, d0_stride, d0_wrap, d1_stride, d1_wrap, d2_stride, d2_wrap,
    iter_step_size, iter_wrap)

__Runtime_dma_createio_4(tile, bd, channel_id, start_bd, direction)

__Runtime_startio(DevInst, io_var, bd_id, repeat_count)
```
