# Whisper → TVM → aiehlc: every layer on the AI Engine (compile level)

OpenAI **Whisper-tiny** (official checkpoint, 37 M parameters, fp32) imported
through TVM 0.16 Relay and compiled so that **every layer of the encoder and of
a decoder step is an aiehlc-built AIE kernel**. Nothing runs on hardware here:
the deliverable is the compiled artefacts plus an x86 check that the compiled
kernels compute Whisper.

```bash
source script/setup.sh --path-set-only          # aarch64 toolchain + Vitis (xchesscc)
PYTHONPATH=src python src/frontend/tvmrelay/example/whisper/whisper_flow.py
#   --decoder-tokens 32   static decoder length (default)
#   --jobs 8              parallel aiehlc builds
#   --no-verify           skip the x86 network run (stage 7, ~8 min)
#   --no-board            skip the aarch64 link (stage 8)
```

Prerequisites: `build/aiehlc` built from **this** tree (it carries the
`RowSpace` support and three pipeline fixes, see GAP_ANALYSIS.md), TVM 0.16
with LLVM (`setup_tvm016.py --llvm`), `ffmpeg`, network access for the first
run (checkpoint + JFK sample + assets are cached under `--out-dir/cache`).

## Result (2026-10-14)

| | |
|---|---|
| Relay ops left on the CPU after partitioning | **0** (encoder and decoder) |
| AIE layers | **147** — encoder 56, decoder step 91 |
| TVM graph-executor calls | 56 + 91, **all** AIE wrappers, 0 `__nop`, 0 CPU kernels |
| distinct aiehlc libraries | **24/24 built** (17 `GemmSpace` GEMMs, 7 `RowSpace` row ops) |
| per-library checks | resolved `aie::get_*` = plan; core window = kernel window; `<sig>_port/_run` + core ELF in the archive |
| x86 network run (resolved kernels, emulated windows) vs TVM CPU | encoder max \|Δ\| 1.5e-3 (8e-5 of range); decoder logits max \|Δ\| 5.7e-5, argmax 27/27 |
| transcript of `jfk.flac`, greedy, AIE encoder + AIE decoder | **identical to PyTorch**: *"And so my fellow Americans ask not what your country can do for you ask what you can do for your country."* |
| baremetal ELF `board/whisper_aie.elf` | **linked**: 157 MB, 24 aiehlc archives, 24 embedded AIE core ELFs (not run) |
| launches per inference | encoder 96, decoder step 171 (batched matmuls launch once per head) |
| padded-GEMM efficiency (useful / issued MACs) | encoder 94 % (18.5 GMAC), decoder step 70 % (2.8 GMAC) |

## Pipeline

```
whisper_model.py   official tiny.pt (SHA-256 checked) -> torch nn.Module (vendored arch, MIT)
whisper_audio.py   ffmpeg -> log-mel (upstream recipe) ; BPE detokenizer ; greedy decode
        │
whisper_relay.py   torch.onnx.export (opset 17) -> relay.frontend.from_onnx
                   FoldConstant/SimplifyExpr ; q/k attention scale folded into W,b ;
                   every weight lifted to a graph input (de-duplicated)
        │
aie_partition.py   AIE-FIRST partition: anchors (dense, batch_matmul, conv1d, layer norm,
                   softmax, add, take) absorb bias/GELU/mask and all reshape/transpose
                   chains -> 147 functions with Compiler="aie_whisper"; strided PortViews
        │
aie_kernels_whisper.py   layer -> library plan (padded dims, tiling, signature)
                         -> aiehlc app source (library mode):
                            gemm : aie::GemmSpace, 4x4 mesh, bias as extra K column, GELU epilogue
                            row  : aie::RowSpace (NEW), 1x4 mesh: layernorm/softmax/masked softmax/add
aie_build.py       aiehlc.sh per signature (parallel, AIEHLC_SKIP_AIELIB=1) + checks
        │
aie_codegen_whisper.py   relay.ext.aie_whisper: one C wrapper per layer
                         (stage via PortView -> aiew_<sig>_run() -> collect)
        │                                  │
whisper_verify.py (x86)             whisper_board.py (aarch64)
 aie_emu_whisper.py: resolved        static graph driver from graph JSON,
 kernel + window feeder, linked      wrappers, weights blob, every lib<sig>.a
 into TVM llvm DSO; compare with     (host.o symbols localized) -> whisper_aie.elf
 TVM CPU + PyTorch transcript
```

### The layer set

| AIE op | template | covers (Relay ops absorbed) |
|---|---|---|
| `conv1d+bias+gelu` | gemm (im2col staged) | `nn.conv1d, nn.bias_add, divide, erf, add, multiply×2 [, transpose]` |
| `dense[+bias][+gelu]` | gemm | `reshape, nn.dense, reshape, add, [GELU], [head split: reshape, transpose, reshape, transpose]` |
| `bmm` | gemm, one launch per head | `nn.batch_matmul, [head merge: reshape, transpose, reshape]` |
| `layernorm` | row | `mean, variance, add(eps), subtract, rsqrt, multiply×3, add` |
| `softmax` / `softmax_mask` | row | `[add(mask)], nn.softmax, reshape` |
| `add` | row | residual join / positional embedding (`add` of two tensors) |
| `embed` | row (`add`) | `less, add, where, take, add(pos)` — row gather staged |

`layers.md` (in `--out-dir`) lists every one of the 147 layers with the Relay
ops it absorbed and its library.

### What "offloaded" means here, precisely

Every arithmetic operation of the network is in an AIE core kernel. The host
wrapper does **data movement only**: copy TVM's tensor into the library's DMA
buffer through a strided view (this is where the absorbed reshape/transpose
chains, zero padding, the conv1d im2col, the bias `1.0` column and the token
gather happen), launch, copy back. On silicon those copies are BD address
patterns; aiehlc cannot yet express them from the frontend (GAP_ANALYSIS.md
G6–G10), so they are host copies — the same staging the existing
`conv2dstem` offload does.

### What is verified, and what is not

* **Verified (compile level):** every library builds through the real aiehlc
  frontend → MLIR pipeline → `xchesscc` → archive; the constants aiehlc
  resolved and the window buffers its pipeline allocated match the plan; the
  ELF links; and the *resolved* kernel bodies, fed windows the way the
  spatial spaces declare, reproduce the PyTorch transcript.
* **Not verified:** that the shim/tile BDs aiehlc generated deliver the bytes
  in the order the emulator assumes, timing, or anything on a board or in
  aiesim. The emulator is order-insensitive for the GEMM (any consistent
  pairing of M/N sub-tiles computes A·Bᵀ) but it is a model of the DMA, not
  the DMA.

## Files

| file | role |
|---|---|
| `whisper_flow.py` | the 8-stage driver, writes `report.json` and `layers.md` |
| `whisper_model.py` / `whisper_audio.py` | model + checkpoint; audio front end, detokenizer, greedy decode |
| `whisper_relay.py` | ONNX export, Relay import, scale folding, weight lifting |
| `aie_partition.py` | AIE-first grouping, Relay function cut-out, `AieLayer` + `PortView` |
| `aie_kernels_whisper.py` | library planning, GEMM / RowSpace app-source generation, device math macros |
| `aie_build.py` | parallel aiehlc builds and the per-library checks |
| `aie_codegen_whisper.py` | `relay.ext.aie_whisper` C wrappers |
| `aie_emu_whisper.py` | x86 emulator around the resolved kernels |
| `whisper_verify.py` | stage 7 |
| `whisper_board.py` | stage 8 (driver generation + link) |
| `GAP_ANALYSIS.md` | aiehlc gaps, fixes made, advantages/disadvantages, proposals, lessons |
| `PROCESS_LOG.md` | dated log of what was tried |
