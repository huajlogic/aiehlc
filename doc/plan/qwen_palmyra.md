<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Plan: Qwen3.5-9B / Qwen3.8-9B-Distill on palmyra (baremetal A78 + AIE), >= 6 token/s

Goals (2026-11-26):

1. The GEMM in the "activations resident, weights streamed once" form, measured on Qwen's real layer shapes,
   target 80 % of the 16-core int8 peak; written up in the GEMMOP report.
2. A 9B Qwen (Qwen3.5-9B, or the Qwen3.8-9B-Distill built on it) answering on palmyra at >= 6 token/s, and
   answering fast (short time to the first token).
3. Baremetal and the aiehlc framework; llama.cpp ported to baremetal only if it is the shortest way.

## 1. The model (Qwen3.5-9B `config.json`, text part)

| | |
|---|---|
| layers | 32: 24 Gated DeltaNet (linear attention) + 8 gated full attention (every 4th) |
| hidden / FFN | 4096 / 12288 (SiLU-gated) |
| full attention | 16 q heads, 4 kv heads, head dim 256, output gate, partial RoPE (0.25 of the dims) |
| linear attention | 16 key heads, 32 value heads, dims 128, causal conv1d kernel 4, fp32 state |
| vocabulary | 248,320; embedding and lm_head not tied (1.0 B parameters each) |
| MTP | one extra layer (speculative decoding) |

Parameters (computed): 8.9 B text (embedding 1.0, lm_head 1.0, FFN 4.8, linear attention 1.6, full
attention 0.5) + 0.4 B vision (not loaded). Per decoded token everything but the embedding is read:
~7.9 B parameters.

## 2. Budget

Decode reads every weight once per token, so its speed is bytes / DDR bandwidth.

| weights | bytes / token | tok/s at 26 GB/s (measured AIE read) |
|---|---|---|
| int4, one fp16 scale per 32 (4.5 bit) | 4.4 GB | 5.9 |
| int4, one fp16 scale per 64 (4.25 bit) | 4.2 GB | 6.2 |
| + MTP: draft (MTP layer + lm_head 0.7 GB) + verify 2 tokens per weight pass (4.2 GB) | ~2.9 GB per accepted token at 70 % acceptance | ~9 |

6 tok/s from plain int4 decode needs the DDR at 100 %: the plan is int4 (group 64) on the AIE at the DDR's
speed **plus** MTP speculative decoding. KV cache is small (8 full-attention layers x 4 heads x 256 x 2 x 2 B =
32 KB / token); the DeltaNet state is 24 x 32 x 128 x 128 x 4 B = 48 MB (read + written per token).

## 3. Board facts to establish first

| fact | status |
|---|---|
| DDR beyond 2 GB: `0x8_0000_0000` measured as a mirror of `0x0` (netboot doc section 12) -- a 9B model needs >= 5 GB | probing every DDR window (`ddrprobe`, xsdb) |
| weights into DDR: netboot streams an ELF > its staging area straight to its segments (<= 4 GB per ELF) | data ELFs, one segment each; the app finds them by address + header |
| A78 cores the app can use (core 0 runs the supervisor) | to check |

## 4. Architecture

```
host (x86)                        palmyra
----------                        -------
convert.py: safetensors bf16 ->   DDR: weight blob (int4 + scales, AIE tiled layout), header, vocab
  int4 blob + header + vocab      A78 (baremetal, aiehlc host): token loop -- embedding lookup, RMSNorm,
tokenize the prompt (python)        DeltaNet recurrence + conv, attention + KV, MTP draft, sampling, detokenize
qwen_ref.py: torch reference      AIE (persistent kernel): small-M GEMM -- int4 weights streamed from DDR once
  (layer-by-layer check)            per pass, M = 1..32 activations resident in every core
```

* **AIE kernel: small-M int4 GEMM.** Decode is M = 1 (2 with MTP), prefill takes the prompt 32 tokens per
  weight pass. Every core owns a slice of the output rows; the activations (int8 + scale, or bf16) are resident;
  weight blocks stream from >= 4 shim channels. int4 x int8 `mmul` exists on AIE2PS (`aie2p/mmul_8_4.hpp`) but
  unpacks to int8 (int8 rate), which is plenty: decode needs ~3 weights / cycle / core.
* **CPU part.** Everything that is not a weight matrix: per token ~100 MB of state traffic, ~10-20 ms.
* **Launches.** ~4 weight passes per layer (fused qkvz / gate+up), ~130 per token; a persistent-kernel launch
  costs ~12 us -> < 2 ms per token.
* **Prefill = answer fast.** 32 tokens per pass: a 100-token prompt in 4 passes (~0.7 s). The goal-1 GEMM
  (80 % peak) is the path for long prompts.

## 5. Milestones (each ends in a measurement)

| # | milestone | done when |
|---|---|---|
| G1 | GEMM, weights streamed / activations resident, Qwen shapes | board % of peak per shape, GEMMOP chapter |
| M0 | board DDR size, data-ELF load | probe result; a 4 GB blob loaded and checksummed |
| M1 | x86 C engine + converter, checked against the torch reference | same greedy tokens as bf16 torch on test prompts (int4: logits close, text sane) |
| M2 | the same C on the baremetal A78, CPU only | runs, tok/s (CPU bandwidth baseline) |
| M3 | AIE small-M int4 GEMM in the token loop | tok/s, bit-exact vs the CPU path |
| M4 | MTP speculative decoding, prefill in 32-token passes | >= 6 tok/s, time to first token |

## 6. Log

* 2026-11-26: G1 first try 6144 x 512 x 4096 (W as A, 512 tokens as B): B per MemTile is exactly 512 KiB, one
  MemTile BD holds 524,284 B -> the plan streamed B (re-read per output tile). Fix: a held B loads through a
  chain of BDs (`plandma.cpp` `deriveResident`, runtime `__Runtime_tile_bd_config` one-sided locks).
  M = 12288 in one launch exceeds the 64 output tiles per core (6-bit OOO counter): a layer is 2 launches.
* 2026-11-26: G1 done -- with the BD chain the weights-streamed GEMM reaches 86.55 % (6144 x 512 x 4096),
  86.15 % (5120), 85.41 % (4096) on palmyra; 36.20 % before the fix. GEMMOP chapter 12.
* 2026-11-26: M0 -- DDR_LOW1 (`0x8_0000_0000`) is 6 GB of real DDR on the 2026-11-25 PDI, readable and
  writable by the AIE; the blob goes there in 3 segments of <= 1.75 GB via loader ELFs (checksummed).
  VEK385 ruled out: its A78 hangs on the 0x500_/0x600_/0x700_ windows and AIE accesses there are ~25 % wrong.
* 2026-11-26: M1-M3 -- the C engine matches the torch reference's greedy tokens on x86; on the board every
  weight matmul runs as qwen_gemv launches (4096 rows x K 4096 x M <= 4, persistent kernel 0.355 ms).
* 2026-11-26: M4 -- MTP speculative decoding (post-norm hidden, two-bank DeltaNet state with commit /
  rollback, 16 K draft vocabulary from frequency-ordered lm_head rows). Lazy decay (3 FMA per state element),
  NEON x quantization (x prep 1.24 -> 0.20 s), NEON exp / SiLU / dot. Decode 6.49 / 5.90 / 5.28 tok/s on the
  en / zh / poem prompts (palmyra-14); output identical to plain greedy. Did not help: fp16 state, a scalar
  polynomial exp, MTP gap fill.
* 2026-11-27: library-mode routing fix (`hostcompile.sh` merges routing.o into host.o; no more
  `--undefined`), verified on palmyra-14: 17,462 launches, 6.52 tok/s.
  Next: the other A78 cores for the CPU part (DeltaNet), an M = 8 prefill kernel for the time to first token.
