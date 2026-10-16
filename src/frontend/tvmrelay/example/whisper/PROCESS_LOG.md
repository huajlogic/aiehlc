# Whisper → TVM → aiehlc: process log

A dated record of what was tried, what worked, and what did not, in the order it
happened. `GAP_ANALYSIS.md` is the distilled version; this file is the evidence.

## 2026-10-14

### 0. Setup

* Worktree `.worktrees/whisper` (branch `whisper`, from `main` @ `6f941fb`).
* Symlinked `thirdparty/{aie-rt,cardano,tvm-0.16}` and the BSP `workspace/` from
  the main checkout (memory: worktrees convention).
* **`thirdparty/alib` is a private copy, not a symlink.** `aiehlc.sh`'s
  `build_hw_lib` starts with `rm -rf alib/lib/*.a` and rebuilds the aie-rt
  driver on every run, so a symlink would mutate the main checkout's library
  under any other session using it.
* Own `build/` (cmake + `make aiehlc _aiebackend`, 2 min) — the main
  checkout's `build/aiehlc` is built from *its* sources, which carry uncommitted
  changes; a RowSpace edit here would never reach it.

### 1. Model + CPU reference — success

* Vendored OpenAI Whisper's architecture (`whisper_model.py`, MIT) instead of
  `pip install openai-whisper`: the package imports `numba` for timestamps and
  pins nothing about torch. Loads the official `tiny.pt` with `strict=True`,
  SHA-256 verified (the hex in the URL *is* the hash).
* `whisper_audio.py`: ffmpeg decode, upstream log-mel recipe with the official
  `mel_filters.npz`, BPE detokenizer from the `.tiktoken` rank file (no tiktoken
  needed), greedy no-cache decode.
* PyTorch greedy on the upstream `jfk.flac`:
  `' And so my fellow Americans ask not what your country can do for you ask what you can do for your country.'`
  — 23 tokens, 0.7 s.

### 2. ONNX → Relay → `target="c"` — success, and the layer census

* `torch.onnx.export(dynamo=False, opset 17)`; torch 2.10 defaults to the dynamo
  exporter, which TVM 0.16's importer has never seen.
* TVM's own fusion of the fp32 graphs (calls in the graph executor):

  | graph | calls | `__nop` | distinct kernels |
  |---|---|---|---|
  | encoder (mel 1×80×3000) | 102 | 8 | 20 |
  | decoder step (T=4) | 171 | 14 | 25 |

* What TVM's CPU-oriented fusion produces is *not* what an AIE wants:
  layer norm is **three** calls (`mean`, `variance`, `subtract_add_rsqrt_...`),
  every dense is a bare `contrib_dense_pack` with its bias pushed into the
  *next* kernel (`reshape_add_reshape_transpose_multiply_reshape` = bias +
  head split + q-scale), and the residual adds are separate
  (`reshape_add_add`). Mapping those names one-for-one onto AIE kernels (the
  approach of the `alllayer` branch for ResNet) would put a bias add, a
  transpose and a scale on the array as three separate launches.
  **Decision: partition AIE-first (BYOC) instead** — the AIE op set decides the
  layer boundaries, TVM only compiles what is left (which must be nothing).

### 3. aiehlc probes — what the GEMM path can and cannot express

* **fp32 GEMM, library mode, 64³** — success, 98 s. `input_window_int32`
  carries fp32 bit patterns; the kernel casts the window pointer to `float *`.
  `xchesscc` compiles scalar fp32 for aie2ps without complaint.
* **fp32 GEMM 1536×384×1536** — success, 83 s, `host.cc` 1543 lines (the
  rounds are loops, not unrolled). Resolved: `k_rounds=6 eff_k=64
  m_rounds=24 n_rounds=24`.
* **Row-wise kernel (layer-norm shape) on the GemmSpace path — FAILED**, and the
  reason is structural:
  * tensor shapes are *inferred from GEMM roles*: the launch's `(M,N,K)` make a
    Row input `[M,K]`, a Col input `[K,N]`, the output `[M,N]`. A layer-norm
    `gamma/beta` operand `[2,384]` became `win_b [384x384]`, and the output
    width is forced to `N`.
  * the tile-memory check is a GEMM working set (`A+B+C` tiles).
  * `aie::get_arg_per_round_size_in_dim` is unresolved outside a
    `fullconnect_auto=1` GEMM (`no member named ... in namespace 'aie'`).
  → No transformer non-GEMM operator (layer norm, softmax, residual add) is
  expressible. **This is the main aiehlc gap this work closes** (next item).
* Side finding: the per-port window budget compared an **element** count to
  `l1_budget` **bytes** (`perKRoundData <= maxBuf`), so every >8-bit window
  could silently be 2–4× its budget. Fixed (`elemBytesOf`).

### 4. New spatial type `aie::RowSpace` — success

* `struct RowSpace { SpatialPolicy policy; tile_dim rows; tile_dim cols; }` —
  every port names its own `[rows, cols]`; Row layout = split over mesh rows,
  Col-layout input = broadcast operand. Added to all **three** copies of the
  space preamble (two in `aiehlc.cc`, one in `tilinglinalg_pipeline.cpp` —
  itself a drift hazard, see GAP_ANALYSIS).
* `deriveRowSpaceTiling` evaluates, per port, the *pipeline's own* stream rule
  (`flowtransfer_kernel.cpp: window = min(perCore, maxPP/elemBytes)`) instead of
  inventing a second one, and rejects anything that would produce a short last
  window or split a row.
* Probe: layer-norm shape `[1536,384]` + `[2,384]` params on a 4×1 mesh → builds
  (87 s). Cross-checked the generated artefacts against the derivation:
  kernel `buf_in_ping_0[384]` v4int32 = 1536 floats = 4 rows ✓, params window
  768 floats ✓, core BDs 6144 B / 3072 B ✓, shim A BD 589 824 B = one tile's
  384 rows ✓, `num_a_rounds = num_c_rounds = 96` ✓.
* `aiehlc.sh`: `AIEHLC_SKIP_AIELIB=1` reuses the built aie-rt library instead of
  wiping it — the precondition for building many apps in parallel.

### 5. AIE-first partition — success

* `whisper_relay.py`: q/k attention scale (`d**-0.25`, applied after the head
  split) folded into the projection constants — a scalar commutes with the
  reshape/transpose chain. 8 projections (encoder), 16 (decoder). q/k/v/out
  then share one GEMM library. Weights lifted to graph inputs, de-duplicated by
  content: the decoder's `take` table and logits weight are one 80 MB input
  (117.6 MB instead of 197 MB).
* `aie_partition.py` first version: 56 encoder + 91 decoder layers, **0 ops
  left**. One trap: the decoder's mask `add` ran before its `softmax` in
  post-order and was taken as a residual `add` anchor — excluded when its
  single consumer is a softmax.
* The head **merge** (`[6,T,64] -> transpose -> [T,384]`) has no gather-form
  strided view (numpy had to copy); its inverse does → output views fall back
  to a *scatter* form. Every other chain is a plain view.

### 6. Library planning + builds — two more aiehlc bugs

* 147 layers → **24** signatures (17 GEMM, 7 RowSpace).
* First host compile failed: `extern "C" __Runtime_Alloc` vs the C++ linkage
  `aie_runtime.h` has in the host compile. Declared without `extern "C"`.
* The `expected_constants` check flagged `softmax_mask`: the kernel never
  queried B's rounds. Kernels that walk B in lockstep with A now query them so
  the check can prove they are equal.
* **4×1 RowSpace mesh was wrong** — tile groups showed 4 tiles per mesh row and
  `BUF_SZ_OUT_0 24` (96 floats) against a kernel writing 384. Root cause in
  `RoutingToDmapPass`: `tileNum = split_axis=="row" ? row : col` (should be
  `col : row`), duplicated in `routinglower.cpp`. Square meshes hide it.
  Tried first: `{0,0,0,6}` (1 column) → `No free shim DMA slot for dio3`;
  `{0,3,0,3}` → router segfault. Fixed the count; RowSpace now uses a 1×4 mesh
  on `{0,3,0,6}`: one tile per column, own shim.
* Added a kernel-window check (`BUF_SZ_*` in `kernel.cc` vs the kernel's
  `buf_sz`) → 6 GEMMs failed: **B window divided by M sub-tile rounds**
  (`flowtransfer_kernel.cpp` + `BlueprintToScheduleKernelPass`). Fixed to use
  N rounds for port 1. The check was then tightened from `>=` to `==` — with
  `>=` a 64×384 dense passed with a 1024-float DMA window and a 512-float
  kernel window.
* After both fixes: **24/24 ok** (59–88 s each, 8 in parallel).
* Regression A/B vs a pristine `HEAD` aiehlc on `simplematmul2.cc` and
  `conv2dstem.cc`: `kernel.cc`, `routing.cc`, `aieml.bcf` byte-identical;
  `host.cc` differs only by the `RowSpace` declaration.

### 7. Codegen, x86 network run, board link — success

* `relay.build(target="c")`: encoder 56 + decoder 91 graph calls, all
  `wsp_*` AIE wrappers, 0 `__nop`, 0 CPU kernels.
* First x86 run: `undefined symbol aiew_..._port` in the *CPU reference* DSO —
  `partition()` had mutated the caller's IRModule. Now works on a copy.
* x86, every layer through its resolved aiehlc kernel (emulated windows):
  encoder vs TVM CPU max |Δ| 1.46e-3 (8.4e-5 of range), decoder logits max
  |Δ| 5.7e-5, argmax 27/27; greedy transcript **identical to PyTorch**
  (23 tokens, 57 s).
* aarch64 link: `whisper_aie.elf` 157 MB, 24 libraries (host.o symbols
  localized to `<sig>_port/_run`), 24 embedded core ELFs. Not run.
