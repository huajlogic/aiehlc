# Provenance Hierarchy for Communication Debugging

This document defines the **provenance hierarchy** — a layered contract-based model that enables systematic root-cause localization when an AIE communication path is stuck or produces incorrect data.

## 1. Core Principle: Contracts, Not State

The top layer records **contracts** (expected behavior), not runtime state. Each communication is decomposed into participants with explicit responsibilities. Diagnosis becomes "actual vs. contract" comparison per participant, rather than undirected state inspection.

A communication's contract splits it into responsibility-bearing stages:

```
producer --> channel --> consumer
(config)    (routing)   (config + processing)
```

Given a contract, a "stuck" symptom can be decomposed into **which stage violated its contract**.

## 2. Communication Contract (Basic Model)

```
CommunicationContract {
  id:      unique identifier
  intent:  linalg-level semantics (e.g. "matmul K-tile #3, A operand transfer")

  producer: {
    endpoint:       tile / shim
    expected_rate:  token production rate (contract value)
    config_ref:     pointer to lowering decision (provenance link)
    contract:       "produce N elements of shape X"
  }
  consumer: {
    endpoint:       tile
    expected_rate:  token consumption rate
    config_ref:     pointer to lowering decision
    contract:       "consume N elements"
  }
  channel: {
    depth:          buffer depth (e.g. ping-pong = 2)
    expected_path:  logical route (producer -> consumer)
  }

  invariants: [
    "producer.produced == consumer.consumed (steady state)",
    "producer must not be long-term blocked-on-acquire-empty",
    "consumer must not be long-term blocked-on-acquire-full",
    "depth must cover producer/consumer rate difference"
  ]
}
```

**Key design**: the top layer stores contract values + invariants, not runtime counters. Runtime measurements come from lower-level provenance; diagnosis = checking lower-level actuals against top-level invariants.

## 3. Differential Diagnosis: Locating the Responsible Party

The critical insight: **"stuck" as a whole symptom points to nobody, but "stuck at which handshake point" precisely identifies the responsible party.** The acquire/release protocol makes "who holds the data" explicit at all times.

### 3.1 Diagnosis Truth Table

| Observed State | Violated Invariant | Responsible Party | Root Cause Category |
|---|---|---|---|
| Producer blocked on acquire-empty (cannot get empty buffer) | Consumer did not release in time | **Consumer** (processing) | Processing too slow / deadlocked |
| Producer never produced (produced = 0) | Producer did not start | **Producer** (sender) | Sender misconfigured / not triggered |
| Producer produced, but consumer acquire-full blocked (consumed < produced, stalled) | Data did not reach consumer | **Channel** (routing) | Route misconfigured / physical path broken |
| Consumer acquired successfully but errored after release | Data arrived but processing failed | **Consumer** (processing) | Processing logic / config error |
| Consumer's expected shape != producer's actual output | Endpoint contract mismatch | **Config mismatch** | Lowering configs inconsistent between ends |

### 3.2 Decision Tree (Max 3 Hops)

```
STUCK detected
  |
  +-> Read producer state: did it produce?
       |
       +-> No  --> Producer problem (config/trigger)             [DONE]
       +-> Yes --> Read consumer state: did it receive?
                    |
                    +-> No  --> Channel problem (routing/path)   [DONE]
                    +-> Yes, but consumer blocked on acquire-empty
                         --> Consumer processing too slow         [DONE]
                    +-> Yes, but error after release
                         --> Consumer processing/config error     [DONE]
                    +-> Yes, but shape/count mismatch
                         --> Cross-endpoint config inconsistency  [DONE]
```

Each step examines one state. At most 3 hops to lock down the responsible party.

### 3.3 Why This Works

The acquire/release protocol makes data ownership explicit: at any moment, who holds data and who is waiting for whom is unambiguous. A "stuck" is not a vague "system stopped" — it is "X is waiting for Y to release / Y to produce." This **wait-edge is a causal edge** pointing directly to the party being waited on.

This is why the top layer must model communication as a **directional handshake contract** rather than an undirected "pipe": a stuck pipe tells you nothing about blame, but "A is blocked on acquire-empty waiting for B to release" tells you B is the bottleneck.

### 3.4 Drill-Down via config_ref

Identifying the responsible party ("consumer is slow") is step 1. To answer "why is it slow", each endpoint's `config_ref` links to lower-level provenance. This is the provenance hierarchy's layer-by-layer composition: the top layer answers **who**, the lower layers answer **why**.

## 4. Extended Model: Staged Path with Spatial/Temporal Dimensions

The basic 3-party model breaks down in real AIE paths for two reasons:

1. **Multi-hop paths**: The real path is `producer -> channel -> PE -> channel -> consumer`, with transit PEs adding intermediate stages.
2. **Internal complexity per stage**: Each stage may involve multi-dimensional DMA (A) and multi-round temporal processing (B).

### 4.1 CommunicationPath Schema

```
CommunicationPath {
  id, intent
  stages: [ Stage ]       // ordered, variable length
}

Stage {
  role:            producer | channel | transit_PE | consumer
  endpoint:        physical entity (tile/shim/switch)

  // Two orthogonal internal dimensions:
  spatial_fanout:  [ SubAction{ dim, bd_ref, expected_len, expected_stride, config_ref } ]
  temporal_rounds: [ Round{ round_idx, expected_count, sync_ref, config_ref } ]

  contract:        what this stage should accomplish
  invariants:      [ health criteria for this stage ]
  config_ref:      drill-down entry point to lower provenance
}
```

### 4.2 Why Separate Spatial (A) and Temporal (B) Dimensions

They have fundamentally different fault signatures and drill-down directions:

**A -- Multi-dimensional DMA (spatial_fanout):**
- One transfer = multiple BDs across multiple dimensions.
- Fault signature: **partial completion** -- some dimensions succeed, one dimension's BD address/stride/length is misconfigured.
- Diagnosis needs precision down to "which dimension's BD is wrong."
- Drill-down direction: BD configuration (address/stride/len).

```
spatial_fanout: [
  { dim: 0, bd_ref: ..., expected_len: ..., expected_stride: ... },
  { dim: 1, bd_ref: ..., expected_len: ..., expected_stride: ... },  // <-- stride misconfigured
]
```

**B -- Multi-round processing (temporal_rounds):**
- Same stage runs R rounds sequentially.
- Fault signature: **stall at round boundary** -- first k rounds succeed, round k+1 stalls.
- Points to synchronization/counting issues (double-buffer flip errors, round counter bugs, cross-round dependencies).
- Drill-down direction: round synchronization / double-buffer state.

```
temporal_rounds: [
  { round: 0, status: done },
  { round: 1, status: done },
  { round: 2, status: STUCK },   // <-- first two rounds OK, third stalls -> cross-round sync issue
]
```

**Separation rationale**: A-type stalls are spatial ("which dimension") configuration issues. B-type stalls are temporal ("which round") synchronization issues. These require completely different drill-down paths. Merging them would force manual guessing after identifying the responsible stage.

### 4.3 Three-Level Drill-Down

```
STUCK
  |
  [L1] Scan stages in order -> find first incomplete stage  (WHO)
  |
  [L2] Within that stage: A or B?                          (WHAT CLASS)
  |     - spatial_fanout: some dims done, one stuck -> A (DMA config)
  |     - temporal_rounds: first k done, k+1 stuck   -> B (sync/counting)
  |     - entire stage never started                  -> trigger/enable config
  |
  [L3] Lock specific sub-action + config_ref drill-down    (WHY)
        - A type -> specific dimension's BD
        - B type -> specific round's sync state
```

**Level 1 -- Find the responsible stage:**

```
Stage0  producer(ShimDMA)  : produced normally      -> OK
Stage1  channel(->memtile) : consumed == produced   -> OK
Stage2  transit_PE(MemTile): acquire/release normal  -> OK
Stage3  channel(->(3,3))   : data arrived           -> OK
Stage4  consumer(tile 3,3) : blocked-on-acquire     -> STUCK
```

Conclusion: responsibility = Stage 4 consumer. Upstream is eliminated.

**Level 2 -- A or B within the stuck stage:**

```
spatial_fanout:  [ dim0(M): done,  dim1(K): STUCK ]  -> partial dim stuck -> A
temporal_rounds: [ round0: stuck from the start ]     -> not "stalled at round boundary" -> not B
```

Conclusion: A-type (multi-dim DMA config). Drill-down target = Stage4, dimension 1 (K) BD.

**Level 3 -- Specific sub-action + config_ref:**

```
Stage4.spatial_fanout[1] (K dim, BD#2):
   expected_stride: 4
   actual_stride:   0        <- MISMATCH
   config_ref -> lowering pass: "compute tile A-operand DMA BD gen"
```

**Root cause**: consumer tile (3,3) A-operand DMA, K-dimension BD stride misconfigured as 0 (should be 4). K-dimension writes to the same address repeatedly, transfer never completes, consumer stalls on acquire from round 0. `config_ref` points to the responsible lowering pass.

### 4.4 Design Summary

```
STUCK -> [L1] which stage (who)
      -> [L2] which dimension: A spatial or B temporal (what class)
      -> [L3] which sub-action + config_ref (why)
```

Three hops, each examining one type of information. The acquire/release protocol guarantees wait-edge = causal-edge, now precise to "which stage's which dimension/round."

### 4.5 Three Key Design Points

1. **`stages` is a variable-length ordered list** -- not hardcoded to 3 parties. Multi-hop paths with transit PEs are naturally accommodated. Fault localization uses "first stuck stage."
2. **Each stage decomposes along two orthogonal dimensions**: `spatial_fanout` (A) x `temporal_rounds` (B). A handles spatial/multi-dim faults (configuration class), B handles temporal/multi-round faults (synchronization class). Different drill-down directions require separation.
3. **Every level (stage / sub-dimension / round) carries `config_ref`** -- guarantees drill-down can continue from any granularity. Provenance layer-by-layer composition manifests as: path stage -> intra-stage sub-action -> underlying config.

## 5. Concrete Example: GEMM A-Operand Data Path

**Scenario**: `C[M,N] += A[M,K] * B[K,N]`, tiled. A-operand (`A[M,K]`) transfer from DDR to compute tile.

Physical path: `DDR -> ShimDMA(2D) -> MemTile -> [forward] -> ComputeTile(PE)`

A is a 2D tile, so ShimDMA uses 2D addressing (spatial_fanout). K-dimension is partitioned into multiple chunks, requiring multiple rounds (temporal_rounds). Both A and B dimensions are exercised.

```
CommunicationPath {
  id:     "A_operand_feed"
  intent: "linalg.matmul: feed A[M_tile, :] in K-chunks to compute tile (3,3)"

  stages: [
    Stage {                                    // Stage 0: producer
      role:     producer
      endpoint: ShimDMA(col=0)
      spatial_fanout: [
        { dim:0 (M), bd_ref:BD#4, expected_len:32, expected_stride:K*4 },
        { dim:1 (K), bd_ref:BD#5, expected_len:64, expected_stride:4   }
      ]
      temporal_rounds: [
        {round:0, expected_count:1}, {round:1, ...}, {round:2, ...}
      ]
      contract:   "produce one 32x64 A sub-tile per round"
      config_ref: lowering -> objectfifo @A_of, shim BD allocation
    },

    Stage {                                    // Stage 1: channel
      role:     channel
      endpoint: stream_switch col0 -> memtile
      spatial_fanout: [ {path: shim.MM2S[0] -> memtile.S2MM[0]} ]
      contract:   "lossless delivery of producer tokens to memtile"
      config_ref: lowering -> stream switch route config
    },

    Stage {                                    // Stage 2: transit PE
      role:     transit_PE
      endpoint: MemTile(1)
      spatial_fanout: [ {memtile buffer alloc, 2 banks} ]
      temporal_rounds: [
        {round:0, status:?}, {round:1, status:?}, {round:2, status:?}
      ]
      contract:   "buffer one A sub-tile per round and forward to compute tile"
      config_ref: lowering -> memtile objectfifo depth=2
    },

    Stage {                                    // Stage 3: channel
      role:     channel
      endpoint: stream_switch memtile -> (3,3)
      contract:   "lossless delivery to compute tile"
      config_ref: lowering -> stream route config
    },

    Stage {                                    // Stage 4: consumer
      role:     consumer
      endpoint: ComputeTile(3,3)
      spatial_fanout: [
        { dim:0 (M), bd_ref:BD#1, expected_len:32, expected_stride:64*4 },
        { dim:1 (K), bd_ref:BD#2, expected_len:64, expected_stride:4    }
      ]
      temporal_rounds: [ {round:0}, {round:1}, {round:2} ]
      contract:   "acquire one A sub-tile per round, MAC accumulate, release"
      config_ref: lowering -> compute tile objectfifo consume + kernel
    }
  ]
}
```

## 6. Related Work: hgdb

[hgdb](https://github.com/Kuree/hgdb) provides source-level debugging for hardware generated by HDL generators (e.g., Chisel). Its core mechanism extracts a **symbol table** from compiler IR to map RTL simulation signals back to source-level variables and line numbers.

Key techniques relevant to provenance hierarchy design:

| Technique | Description | Relevance |
|---|---|---|
| **Three-component architecture** | Simulator / debugger / symbol table decoupled via minimal primitive interfaces. Cross-simulator, cross-generator reusability. | Clean interface separation is analogous to our provenance layers. |
| **Symbol table from IR** | Two-pass extraction on Chisel's FIRRTL IR: Pass 1 annotates nodes in High-form (closest to source), Pass 2 collects in Low-form (closest to RTL). | "Annotate at high level, collect at low level" parallels our provenance layer-by-layer mapping. |
| **Breakpoint emulation** | External breakpoint simulation exploiting synchronous design (signals stable at clock rising edge). Overhead < 5%. | Shows runtime contract checking can be low-overhead. |
| **SSA for combinational aliases** | Loop unrolling + conditional flattening to recover "under what condition should this line break." | Relevant to resolving multi-round temporal aliasing in our B-dimension. |
| **Hardware concurrency as threads** | Multiple hardware "threads" share source locations but process different data. Thread selection UI borrowed from software debuggers. | Maps to our spatial_fanout -- multiple tiles share the same lowering source but operate on different data partitions. |
| **Reverse debugging** | Software-emulated breakpoints allow reverse evaluation order, creating "time reversal" illusion. Trace replay enables cross-cycle rollback. | Could enable reverse diagnosis along temporal_rounds. |

## 7. Automation: Pre-HW Static Verification

The contract-based invariants described above are partially automated by `script/verify_generated.py`. This script parses the generated `host.cc` and `kernel.cc` and checks 8 invariant families **before** deploying to hardware:

| Check | Invariant | Historical Bug Caught |
|-------|-----------|----------------------|
| 1 | Buffer size: host BD len vs kernel BUF_SZ | `k_accumulate_c_stationary_shim_stuck` |
| 2 | Total data volume across SHIM/core | `c_accumulate_data_incorrect` |
| 3 | SHIM BD len vs iteration pattern | `c_accumulate_data_incorrect` |
| 4 | Channel repeat count sanity | `c_accumulate_data_incorrect`, `k_accumulate_c_stationary_shim_stuck` |
| 5 | iter_step_size sanity | Confusing non-functional values |
| 6 | OOO BD ID presence | `output_pkt_merge_stuck` |
| 7 | Lock credit symmetry | Lock deadlock scenarios |
| 8 | Kernel window_init vs host startio | `k_accumulate_c_stationary_shim_stuck` |

Usage:
```bash
python3 script/verify_generated.py worklocal/host.cc worklocal/kernel.cc
```
