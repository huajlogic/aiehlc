# aiehlc on a transformer: gaps, advantages, proposals, lessons

What offloading every layer of Whisper-tiny (fp32, encoder + decoder step,
147 layers, 24 distinct kernels) through TVM and aiehlc showed about aiehlc.
Evidence for every claim is in `PROCESS_LOG.md`; numbers are from
`worklocal/whisper_deploy/report.json`.

## 1. Where this landed

| goal | status |
|---|---|
| every Relay op of the network inside an AIE layer | **yes** — 0 CPU ops, 0 TVM CPU kernels |
| every AIE layer built by aiehlc (frontend → MLIR → xchesscc → archive) | **yes** — 24/24 libraries |
| compiled kernels compute Whisper | **yes, on x86** — resolved kernels reproduce the PyTorch transcript |
| a board image | **linked** (157 MB ELF), never run |
| new aiehlc spatial type where the DSL could not express a layer | **`aie::RowSpace`** |
| aiehlc bugs found and fixed on the way | **4** (G2–G5) |

## 2. Gaps

Severity: **B** = blocked a layer outright, **C** = silently wrong output or a
hang-in-waiting, **P** = performance/scale cost, **U** = usability.

### Fixed in this branch

| id | gap | sev | what was done |
|---|---|---|---|
| G1 | **The DSL only speaks GEMM.** Tensor shapes are *inferred from GEMM roles* (`(M,N,K)` of the launch → Row input `[M,K]`, Col input `[K,N]`, output `[M,N]`), the memory check is an A+B+C tile working set, and the per-port window math is A/B/C-specific. Layer norm (`[M,W]` + `gamma/beta [2,W]` → `[M,W]`), softmax and a two-tensor add have no GEMM reading: `gamma/beta` became `win_b [384x384]`. Transformers are ~half non-GEMM layers (here 49 of 147). | B | **New spatial type `aie::RowSpace {policy, rows, cols}`**: every port names its own `[rows, cols]`; Row-layout ports are row-split, a Col-layout input is broadcast. `deriveRowSpaceTiling` evaluates the *pipeline's own* stream rule per port (`window = min(perTile, maxPP/elemBytes)`) and refuses short last windows or row-splitting windows instead of guessing. Realized on a 1×N mesh (one tile per array column, each with its shim). |
| G2 | **Non-square meshes were silently wrong.** `RoutingToDmapPass` (and `routinglower.cpp`) take the tile count of a mesh *row* from the mesh *row* count: `tileNum = split_axis=="row" ? row : col`. Every example is 4×4, so it never showed; a 4×1 mesh got 4 tiles per mesh row (16 total) and its gather divided each row block by 4 (core window 96 floats, kernel writing 384). | C | One-character-class fix (`? col : row`), commented. A/B against pristine HEAD on `simplematmul2` and `conv2dstem`: kernel.cc, routing.cc, aieml.bcf byte-identical. |
| G3 | **GEMM B window sized with A's sub-tile count.** For K-rounded GEMMs the core window of *every* input is divided by `tileRows/tileM`; B walks `tileCols/tileN`. Square GEMMs agree by coincidence. A 1536×384 dense got a B window of `4·k_chunk` while the kernel walks `16·k_chunk` — a DMA/acquire mismatch that compiles cleanly and would deadlock or read garbage. 7 of 17 GEMMs here were affected. | C | `BlueprintToScheduleKernelPass` + `flowtransfer_kernel.cpp` divide port 1 by its N rounds. Caught by a check this work added (G17), not by aiehlc. |
| G4 | **`l1_budget` bytes compared with element counts** in the frontend's per-port window derivation (`perKRoundData <= maxBuf`), while the pipeline clamps in bytes. Harmless for int8 (every existing app), 4× off for fp32/int32. | C | `elemBytesOf()`; compare elements with `maxBuf / elemBytes`. |
| G5 | **`aiehlc.sh` is not re-entrant**: `build_hw_lib` wipes and rebuilds `thirdparty/alib/lib/*.a` on every run, so parallel builds race and a symlinked `alib` mutates the main checkout. | U/P | `AIEHLC_SKIP_AIELIB=1` reuses the built driver library; the flow builds it once, then 8 apps in parallel (24 libraries in ~5 min instead of ~25 serially). |

### Worked around (open in aiehlc)

| id | gap | sev | workaround here | proposal |
|---|---|---|---|---|
| G6 | **Three ports.** No kernel in the repo has a fourth `aie::port`, and `run_aie_pipeline`'s default split model crashes on one (alllayer branch). A dense needs `x, W, bias`; dense+residual needs a fourth. | P | Bias rides as an **extra K column** (`A[:,K]=1`, `B[:,K]=b`, +0.3–17 % K). Residual adds are their own `RowSpace add` layer (24 launches). | N-port SplitModel with per-port spaces (RowSpace already derives per port); a "broadcast-row" epilogue port for bias/scale. |
| G7 | **No batch dimension** in `GemmSpace`. | P | `bmm` launches once per head: 6 launches per attention matmul, each re-programming the array (encoder 96 launches, decoder step 171). | `d0 = batch` on GemmSpace: batch rounds as an outer BD iteration (the host round loop already exists for M/N). |
| G8 | **No layout transform on ports from the frontend.** Head split `[T,384]→[6,T,64]`, head merge, k/v transposes, conv output `NCW→NWC` are pure address patterns, but `DmaTransform` only exists for conv im2col on inputs; outputs cannot carry one. | P | The partitioner absorbs every reshape/transpose into neighbours and the wrapper stages through a strided `PortView` (host copy). | Accept a `PortView`-like `(shape, strides)` on any port, lower to BD dims + iteration (≤3 dims + iter covers every view here, including the scatter form of the head merge). |
| G9 | **im2col via DMA is tied to the conv2d spatial-halo path.** | P | conv1d im2col in staging (3× input duplication on the host). | `Im2col::Dma` honoured on a plain GemmSpace A port. |
| G10 | **No data-dependent DMA** (gather). | B for `take` | Token rows gathered by the wrapper. | Runtime-patched BD base address (`__Runtime_dma_bd_config` already takes the buffer per call) exposed as a gather port. |
| G11 | **No float window types.** Windows are `int8/int16/int32`; kernels are scalar C. | P | fp32 bit patterns in `input_window_int32`, cast to `float*`; `exp/erf/rsqrt` as macro polynomials (no libm on the core). | `input_window_float` / `bf16`, and a vector GEMM body (`aie::mmul`) behind GemmSpace; bf16 for the transformer is the realistic deployment type. |
| G12 | **Fixed tile grid** (16×16 sub-tiles, 4×4 mesh) → padding: M 32→64, N 51865→51904, K+bias rounding. | P | Accepted: encoder 94 %, decoder step 70 % useful MACs. | Let the planner pick `tile_m` per layer (aiehlc already auto-tiles when no explicit tile is given); small-M (decode) GEMMs want a 1×N mesh. |
| G13 | **Every layer is staged** through host copies into private DMA buffers; libraries cannot share or alias them. | P | 2 copies per tensor per layer; per-library buffers (the logits B is 80 MB). | Allocate graph tensors with `__Runtime_Alloc` and let layers DMA from each other's outputs (needs G8). |
| G14 | **One kernel per launch, array re-programmed per launch.** `doc/performance/register_write_cost.md`: ~372 ns per `XAie_Write32`. | P | 267 launches per encoder + one decoder step. | Lower a whole `aiegraph.func` as one multi-kernel schedule (the multi-kernel `host_canonicalized_<suffix>` path exists); keep weights resident in memtiles across steps. |
| G15 | **The DSL is defined three times** (two string preambles in `aiehlc.cc`, one in `tilinglinalg_pipeline.cpp`). | U | `RowSpace` added to all three. | One `include/aie_spaces.h`, `#include`d by all three emitters. |
| G16 | **Kernel helpers must be macros** — the kernel extractor copies only `#define`s. | U | exp/erf/rsqrt as statement macros. | Extract `static inline` functions reachable from the kernel. |
| G17 | **No protocol self-check.** Nothing in aiehlc compares the kernel's acquire/release counts and window sizes with the BDs it emits; G2 and G3 both compile with rc=0. | C | `aie_build.check_library`: resolved `aie::get_*` vs plan, `kernel.cc` window vs kernel walk; the emulator counts acquisitions per port per tile. | A verifier pass after `BlueprintToSchedule*`: per port per tile, Σ BD bytes == Σ kernel window bytes, fail the build otherwise. |
| G18 | **Static shapes, no KV cache.** | P | Decoder step at fixed T=32 (causal, so padding is inert); each step recomputes the prefix and the cross-attention K/V (2 × 1500×384×384 per block). | Cache K/V in DDR across steps (an output port that persists); dynamic-T needs runtime round counts. |
| G19 | **Build time**: 59–88 s per library, mostly fixed cost (frontend + pipeline + xchesscc + host compile). | U | 24 libraries, parallel. | Cache by signature (done here); skip host recompilation of the shared runtime per app. |
| G20 | **Weights inside the ELF** (157 MB) — JTAG `dow` is known to fail on ELFs this size (memory: palboard). | U | Not addressed (compile only). | Load weights as a data image at a fixed DDR address. |

### Not aiehlc, but in the way

* TVM's `FuseOps` fuses for a CPU: bias into the next kernel, layer norm as
  three reductions, head-split transposes as their own kernels (encoder: 94
  calls / 20 kernels). Mapping those one-for-one would put a bias add and a
  transpose on the array as separate launches. AIE-first partitioning
  (56 layers instead of 94) is the fix and needs nothing from TVM but
  `Compiler`-attributed functions.
* TVM 0.16 is the last Relay; the Relax frontend (`src/frontend/tvm`) cannot do this.
* torch 2.10 exports with dynamo by default; TVM 0.16 needs the TorchScript
  exporter (`dynamo=False`, opset 17).

## 3. Advantages and disadvantages observed

**Advantages**

* **The spatial DSL is the right abstraction level.** A GEMM is three
  `constexpr` spaces and a kernel; the compiler derives rounds, window sizes,
  BDs, locks and routing. Generating 24 kernels from two Python templates was
  practical *only* because of that; nothing per-layer was hand-tuned.
* **Library mode** (`main()`-less app → `lib<app>.a` with the core ELF embedded)
  made per-layer artefacts composable, and a 147-layer network linked with a
  generic graph driver.
* **The MLIR pipeline is inspectable.** IR dumps per pass (`ir/dfschedule/*`)
  made G2 and G3 diagnosable in minutes: the tile groups and `BUF_SZ` defines
  say exactly what was decided.
* **Resolved kernel source** (`aout/worklocal/<kernel>.cc` with every
  `aie::get_*` as a literal) is a clean seam for host-side emulation; that is
  what turned "it compiles" into "it computes Whisper".
* **fp32 works unchanged** through `int32` windows: the pipeline is
  element-size aware where it matters (BD bytes, window alloc).

**Disadvantages**

* GEMM-centrism (G1) reaches from shape inference to DMA sizing; every
  non-GEMM operator needed a compiler change.
* Square-mesh and square-GEMM assumptions hide bugs (G2, G3): the examples
  never exercise the other case, and nothing checks the protocol (G17).
* Three ports, no batch, no output transforms (G6–G8): attention is expressible
  only by moving work to the host or to extra launches.
* Many silent text-level traps in the frontend (`__global__` in comments,
  prototype order, launch syntax in comments, macro-only helpers) — fine for
  hand-written apps, dangerous for generated ones (we generated around them).
* Every launch is a full re-programming; there is no notion of a persistent
  multi-layer schedule yet (G14).

## 4. Proposed changes, in order of value

1. **Protocol verifier pass** (G17) — would have caught G2/G3 at their first
   build. Cheap: all the numbers are in the dfschedule IR.
2. **RowSpace → general per-port spaces** (G1, G6): RowSpace proves the
   per-port derivation works; extend to N ports and to 2-D grids so row ops use
   all 16 tiles instead of 4.
3. **Strided port views** (G8, G9) → host staging disappears for every layout op
   in a transformer; the `PortView` descriptors here are the exact input format.
4. **Batch dimension in GemmSpace** (G7) — attention on one launch.
5. **Float/bf16 windows + vector GEMM body** (G11) — the performance step.
6. **Whole-graph schedule** (G14) — one configuration for all layers, weights
   resident, no per-layer re-programming.
7. Single DSL header (G15); `static inline` extraction (G16).

## 5. Experience

**What worked**

* *Probing aiehlc with tiny generated apps before designing anything* — the
  fp32 GEMM probe (98 s) and the layer-norm-shape probe exposed G1 on day one.
* *AIE-first partitioning*: decide layer boundaries from what the array can
  do, absorb every layout op; then "all offloaded" is a check (`leftover_ops`
  == ∅, graph has only `wsp_*` calls) rather than a claim.
* *One descriptor, three consumers*: `AieLayer` + `PortView` drive the aiehlc
  app, the C wrapper and the emulator, so they cannot disagree.
* *Checking the compiler against an independent plan*: the planner computes
  what aiehlc must resolve; disagreement is a build error. This found G3 in
  7 libraries.
* *Teacher-forced + greedy transcript* as the end-to-end oracle: a token-exact
  transcript is a much stronger statement than a max-error number.
* *A/B against pristine HEAD* for every compiler change: generated code for
  existing apps is byte-identical.

**What failed first, and why**

* RowSpace on a **4×1 mesh** compiled, built, and was wrong (G2): mesh rows
  expanded to the partition width. A single-column partition then ran out of
  shim channels ("No free shim DMA slot"); a 1-row partition `{0,3,0,3}`
  segfaulted the router. Only 1×4 on the normal partition is sound.
* The first kernel-window check used `>=` and passed libraries whose DMA
  window was *larger* than the kernel's — a count mismatch. It must be `==`.
* `extern "C" void *__Runtime_Alloc(size_t)` clashes with `aie_runtime.h`'s C++
  linkage in the host compile; the frontend parse accepted it.
* `aie_partition` mutated the caller's `IRModule` in place, so the "CPU
  reference" was the partitioned graph (caught by an undefined `aiew_*` symbol).
* A scratch `TMPDIR` holding a stray `http.py` shadowed the stdlib for scripts
  placed there — keep generated scripts under `worklocal/`.
