# Whisper on the AIE: data movement and placement (core SRAM / memory tile / DDR)

What the Whisper engine (`src/aietensorop/whisperengine/`) taught about where data
should live on AIE2PS (VEK385), and a decision procedure for the next model —
including the case where the weights do not fit on chip. Every number below was
measured on the board (probes `m0`–`m12`, the engine's own `we_ddr` byte counter and
profiles); see `doc/web/whisper_aie/index.html` for the full story.

## 1. The three levels

| Level | Size | Bandwidth into the cores | Who programs it | Lives for |
|---|---|---|---|---|
| **Core data memory** ("SRAM") | 64 KB per core (8 banks × 8 KB), 16 cores | the core's own load/store units (2 loads + 1 store per cycle) | the core itself (`aie_kernel_runtime.h` encoders, from the op header) | one chunk / one block |
| **Memory tile** | 512 KB each; 8 in the mesh + 16 "storage" tiles = 12 MB | ~7.9 B/cycle per stream to the cores (≈ 8 GB/s), broadcast to a whole row or column at no extra cost | the host (`we_host.h`, XAie BDs + locks) | one op (mesh tiles) or op → next ops (storage tiles) |
| **DDR** | 2 GB | **~10.5 GB/s read, ~10 GB/s write, ~8.3 GB/s mixed — for the whole array**, independent of the number of shims (`m4`) | the host (shim BDs) | the run |

Two other facts shaped every decision:
- Memory tiles have **no east/west stream ports** and their DMA reaches only the
  adjacent tiles' memory, so data far from the mesh moves over the **shim row**
  (7.45 GB/s per lane, 14 GB/s for two — `m11`), memtile → shim → shim … → memtile.
- **Host register access is slow** (~350 ns per write, ~400 ns per read): who
  programs a transfer matters as much as where the bytes live. The engine lets the
  cores program their own DMAs and the host only re-arms memory-tile/shim BDs, ahead
  of time, writing only changed BD words.

## 2. What goes where — the rule that emerged

**Core SRAM holds only the inner loop's working set**, sized so the core neither
waits for data nor spills:

| GEMM program | bytes | | Attention program | bytes |
|---|---|---|---|---|
| A chunk ping/pong (64×48 bf16) | 2 × 6 KB | | Q chunk ping/pong (32×64) | 2 × 4 KB |
| B chunk ping/pong (48×48 bf16) | 2 × 4.5 KB | | own Q copy (+ next q-block's) | 2 × 4 KB |
| C accumulators (64×48 fp32) | 12 KB | | K / V chunk ping/pong (64 keys) | 2 × 8 KB |
| output block | 6 KB | | S / P (32×64 fp32, P in place) | 8 KB |
| per-op parameters, LN stats | 6.5 KB | | O (32×64 fp32), m, l | 10 KB |
| GELU table (2 bank copies) | 10 KB | | output block | 4 KB |

The chunk shape is a **balance**, not a maximum: a 64×48×48 chunk is 147 K MACs ≈
1040 cycles of `mmul`, against 6 KB + 4.5 KB of operands arriving at ~5–8 B/cycle.
Larger K per chunk (64×48×96) is more efficient (71 % vs 55 % of peak, `m6`) but does
not fit 64 KB with double buffering. Attention at 32 query rows is already
**stream-bound** (2083 cycles per K/V chunk with no compute at all, 2532 with), and
64-row q-blocks would need ~62 KB — the 64 KB limit sets the ceiling.

**Memory tiles hold anything that is read more than once, plus hand-offs.**
- *Reuse inside an op* (the original reason for memory tiles): the A block of a mesh
  row is replayed once per output tile (8× for FC1), a weight panel once per row
  block (6×), an attention head's K/V once per q-block (12×). Fetching from DDR once
  and replaying from the memory tile divides DDR traffic by the reuse factor.
- *Broadcast*: one memory-tile stream feeds a whole mesh row (A) or column (B), so a
  4×4 mesh needs 8 operand streams, not 32.
- *Hand-offs between consecutive ops* (storage tiles): the producer's output never
  goes to DDR if its consumer is the next op(s).

**DDR holds what is too big, too long-lived, or consumed far away**: the weights
(read once per op), residual streams consumed several ops later, tensors consumed by
every mesh column from every mesh row (attention K/V), and results that outlive the
encoder (the cross-attention K/V used by every decoder step).

## 3. Whisper-tiny, tensor by tensor (encoder, per layer, 1536 padded rows)

| Tensor | Size | Producer → consumer(s) | Reuse | Placement | Why |
|---|---|---|---|---|---|
| layer input x | 1.18 MB | FC2 → Q/K/V (A), out-proj (residual) | 2 ops, 3 ops apart | DDR | consumed again after attention + out-proj |
| Q | 1.18 MB | Q/K/V → attention | 1 | **storage tile** (r,0) | next op; per-row hand-off, same rows |
| K, V | 2.36 MB | Q/K/V → attention | 12× per q-block | DDR → MT_B | every column needs one head from **all four** rows' tiles (4×4 fan-in) — not a lane-per-row pattern |
| attention output o | 1.18 MB | attention → out-proj (A) | 1 | **storage** (r,1) | next op |
| x2 | 1.18 MB | out-proj → FC1 (A), FC2 (residual) | 2 ops | DDR | consumed two ops apart; FC1 is compute-bound anyway |
| FC1 hidden h | **4.72 MB** | FC1 → FC2 (A) | 1 (+ replays) | **storage** (r,0..2), 3 passes | the largest intermediate; FC2 was DDR-bound |
| encoder output | 1.18 MB | last FC2 → 4 cross-K/V GEMMs | 4× | **storage** (r,3) | read four times |
| cross K/V | 9.4 MB total | encoder → 24 decoder steps | 24× | DDR | lives across the whole decode |
| weights (per layer) | 3.54 MB | — | 1536 rows per weight byte | DDR → MT_B, once per op | no reuse across ops; per-column slice ≤ 295 KB fits a memory tile |

Measured effect of moving the four hand-offs on chip: encoder DDR traffic
**152 → 91 MB**, encoder **26.2 → 24.3 ms**, transcript unchanged. The DDR floor of the
encoder fell from 15–18 ms to 9–11 ms, below core arithmetic (~15.8 ms), so DDR is no
longer the limit.

Lessons from the gains that did *not* materialise at first:
- A hand-off only pays if the consumer was **data-bound**. FC2 (DDR-bound) gained
  1.5 ms; FC1 (compute-bound) lost time when it was split into more passes.
- **Pass granularity is the hidden cost**: moving a tensor on chip by forcing the
  consumer to 1 block per pass made out-proj and cross K/V *slower* (more passes,
  more route switches) until the storage reads gathered 3 blocks per pass with a
  4-D memory-tile pattern.
- **Layout is free only if a memory-tile DMA can express it**: 4 dimensions,
  wraps ≤ 1023 (1024 silently wraps to 0), 4-byte granularity. The engine stores each
  hand-off in the layout its consumer wants ([K chunk][block] for FC2,
  [block][tile] for cross K/V), or gathers it on the way out.
- **Fan-in patterns stay in DDR**: anything a column must collect from all rows (K/V)
  needs packet-switched merges on the shim row; not done.

## 4. Strategy when the weights do not fit on chip

Whisper-tiny's encoder weights are 3.5 MB per layer (14 MB total) against 12 MB of
memory tiles — and the decoder carries ~33 MB of hi/lo weights per step plus an 80 MB
logits matrix. The engine never tried to keep all weights resident. The decision
procedure it follows, made explicit:

**Step 1 — count reuse per byte, per level.** For an op `C[M×N] = A[M×K]·W[N×K]ᵀ`:
- each weight byte is used by **M** rows (encoder 1536, decoder ≤ 64 tokens);
- each activation byte is used by **N** columns;
- across ops, a weight is reused only if the same op runs again (decoder: once per
  token step; encoder: never within a run).

**Step 2 — put the operand with reuse inside the op in the memory tile, stream the
other.** In the engine the *weights* are resident per op (one column slice per MT_B,
≤ 295 KB) and the *activations* stream in row-block passes through MT_A, because the
column split makes each weight slice small while A must be broadcast to all columns.

**Step 3 — if the resident operand does not fit, split the dimension it does not
reuse.** Rules used in practice:
- *Split N* (output columns): each chunk is its own op; the cost is re-reading A once
  per chunk. Used for the decoder FC1/FC2 (hi/lo weights in 768-/192-column chunks) and
  the logits (68 slices × 768 vocabulary rows). Cheap when A is small (decoder: ≤ 64
  rows, so A re-reads cost almost nothing).
- *Split M* (passes): when the streamed operand plus residual plus headers exceeds
  512 KB — FC2 runs 3 passes, out-proj 2. Weights stay resident across passes, so
  passes cost only per-pass setup (and are double-buffered when two passes fit).
- *Never split K* across ops: partial sums would have to leave the core in fp32 and
  come back (2 × 4 B per element), and an extra rounding changes the numerics.

**Step 4 — rank what stays on chip by DDR bytes saved per memory-tile byte, weighted
by whether the consumer is DDR-bound.** Fill memory tiles greedily in that order;
everything else streams from DDR with prefetch overlapped with compute:
1. operands reused inside an op (always: the saving is the reuse factor);
2. large hand-offs whose consumer is DDR-bound (FC1 hidden → FC2: 9.4 MB per layer);
3. tensors read several times soon after (encoder output → 4 cross-K/V GEMMs);
4. small hand-offs only when they come almost free (same rows, next op, layout
   expressible by one DMA pattern);
5. weights reused across steps — **only** when a model step re-runs with the same
   weights and the step is weight-bandwidth-bound (see below).

**Step 5 — check the floor before building.** DDR time ≈ bytes / 8–10 GB/s (use the
*mixed* rate for ops that read and write together); compute time from the per-chunk
cycle counts. Build the on-chip path only for ops where DDR time > compute time.

### The decoder: the case where weights really do not fit
A decoder step streams ~113 MB of weights (33 MB of hi/lo GEMM weights + 80 MB logits)
for ≤ 64 tokens: each weight byte is used ≤ 64 times, so the step is **weight-bandwidth
bound** (~11 ms of its ~26 ms at 10.5 GB/s). The same weights are used by all 24
steps. The placement rule above says:
- the 12 MB of memory tiles cannot hold 113 MB, so keep resident the weights with the
  best **(steps × bytes saved) / memory-tile bytes** that the rest of the step does not
  need on chip. The per-layer attention weights (Q/K/V, out, cross-Q, cross-out) are
  3.5 MB hi/lo per layer, 14 MB for all four. That is more than the 12 MB, so the
  candidate is a subset: e.g. three layers' attention weights, or FC weights split so
  the resident part is the one read by the most steps;
- keep the logits (80 MB, read once per step, highest volume) in DDR and **cut its
  bytes instead**: only the argmax is needed, so a top-k over a pruned vocabulary or a
  bf16-only first pass with an hi/lo re-check of the top candidates would halve them;
- stream the remaining FC weights from DDR with double-buffered prefetch (they already
  stream per op through MT_B).
None of the decoder placements were implemented — the encoder was the target.

## 5. Who should make these decisions (compiler vs hand)

In this engine all of it was decided and coded by hand (`we_host.h`); aiehlc's
compiler has a shim → memory tile → core path in its dmap/dmaphop lowering, but it is
switched off (`RoutingmovedatabyioConvertdmap(..., 0 /*op through memtile or not*/)`)
and has no notion of a multi-op schedule or of storage placement. A compiler pass that
reproduced the engine would need, per model graph:
1. a resident, multi-op schedule (not one launch per op — `GAP_ANALYSIS.md` G14);
2. per op: which operand is memory-tile-resident, the pass split (M) and the chunk
   split (N), from the sizes in §1 and the reuse counts in §4 step 1;
3. per tensor: DDR or storage tile, by the ranking in §4 step 4, with the consumer's
   layout produced by memory-tile DMA patterns (≤ 4-D, wraps ≤ 1023);
4. the lane/route plan on the shim row and the BD/lock banks so the next op's
   transfers are armed while the current one runs.
