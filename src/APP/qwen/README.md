<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# qwen — Qwen3.5-9B on vek385_2 (baremetal A78 + AIE)

A 9B language model answering on one vek385_2 board, with no OS and no llama.cpp. The weight matrices run on
the AIE array as int4 x int8 GEMVs. Everything else runs on one A78 core: embedding, RMSNorm, the Gated
DeltaNet recurrence, attention, MTP speculative decoding and sampling. The whole thing is a C engine linked
with an aiehlc library.

Measured on a farm vek385_2 (palmyra-14, 2026-11-26/27, 1 GHz AIE, weights int4 group 64):

| | |
|---|---|
| decode | **5.3–6.5 tok/s**, depending on the prompt (MTP acceptance 47–66 %) |
| end to end on the board | ~5 tok/s (prefill 1.5–2 s for a 20–27 token prompt) |
| one 4096 x 4096 AIE launch | 0.355 ms (persistent kernel), ~25 GB/s of weights |
| per decode step (~250 ms) | AIE ~190 ms (verify 477 launches + draft ~19), CPU ~24 ms per token (DeltaNet 13 ms) |
| AIE GEMM, weights streamed / activations resident, Qwen shapes | 85–87 % of the int8 peak (goal 1, GEMMOP chapter 12) |

The plan, the budget and the log are in [`doc/plan/qwen_palmyra.md`](../../../doc/plan/qwen_palmyra.md).

## Layout

| dir | file | what |
|---|---|---|
| `tools/` | `qwen_convert.py` | safetensors (bf16) → weight blob `.qwb` (v7): Q4G64 int4, each launch put in the plan's DDR order by the compiler's `aiehlc_plan_arrange` (`--plan-header`), bf16 scales, 1.75 GB segments, lm_head rows by token frequency (`--lm-order`) |
| | `qwen_draftvocab.py` | token frequency order from text corpora → the MTP draft's 16 K vocabulary |
| | `qwen_tok.py` | chat template + tokenizer: a prompt → token ids / header; board log → text |
| | `qwen_ref.py` | transformers reference; `--engine` compares the C engine against it |
| `aie/` | `qwen_gemv_kernel.cc` | the AIE kernel, written as the data is laid out: w = `[row block][k chunk][8704 B]` read by the linear core index `4·pm + pn`, x loaded whole, y = row blocks; the compiler derives the per-core MemTile-ring streams, x broadcast, rings and BD dims (skill **naturalkernelplan**); y[4096][M≤4] = W[4096x4096]·x, `mmul<4,16,16,int8,int4>`; `QG_PERSISTENT` = persistent kernel |
| | `qwen_gemv_lib.cc` | library entry (no `main()`) → `libqwen_gemv_lib.a`, exports `qwen_gemv_launch(w, x, y)` |
| | `qwen_gemv.cc`, `qwen_gemv_host.h` | standalone self-test ELF (golden check) |
| `engine/` | `qwen_engine.c/.h` | the C engine: Gated DeltaNet (two-bank state, commit / rollback, lazy decay) + gated attention, MTP drafts, NEON helpers |
| | `qwen_aie.c/.h` | every weight matmul as AIE launches: x quantization (NEON), cache flush / invalidate, timing |
| | `qwen_blob.h` | the blob format |
| | `qwen_x86.c` | the engine on x86 (AIE emulated / CPU / null modes) |
| `board/` | `qwen_main.c` | the baremetal app: open the blob segments, prefill, generate, `QWT <id>` per token, `QW PERF / PROF / AIE` lines |
| | `qwen_load.c`, `qwen_board.py` | loader ELFs that put the blob into DDR_LOW1; ELF link helper |
| `web/` | `qwen_web.py`, `index.html` | chat page (port 8101): per question a prompt object is linked and run on the board, tokens are streamed, the AIE / A78 / DDR panel is colored from the measured times, answers are rendered as Markdown |

## Run it

Boards: farm vek385_2 boards, held with `python3 script/test/hws.py --board <farm host> up`
(e.g. palmyra-14 @ gomphus12). Every board command below takes `-board palmyra-N -host <farm host>`.

```bash
# 1. the AIE library (aiehlc library mode, persistent kernel); its aiehlc_plan.h fixes the weights' DDR order
AIEHLC_DEFINES="-DQG_PERSISTENT=1" source script/aiehlc.sh --aie-version 5 \
        --runtime-source-file $PWD/src/APP/qwen/aie/qwen_gemv_lib.cc
mkdir -p $LIB && cp aout/worklocal/build/libqwen_gemv_lib.a aout/worklocal/aiehlc_plan.h \
        thirdparty/alib/lib/libxaienginea78.a $LIB/

# 2. weights -> blob (host; the model and the blob stay out of the repo). Every launch is put in the order
#    the plan's shim BDs read, by the generated aiehlc_plan_arrange -- rebuild the blob when the plan changes
python3 src/APP/qwen/tools/qwen_draftvocab.py $MODEL lm_order.npy corpus_en.txt corpus_zh.txt
python3 src/APP/qwen/tools/qwen_convert.py $MODEL qwen35_9b.qwb --lm-order lm_order.npy \
        --plan-header $LIB/aiehlc_plan.h

# 3. blob -> the board's DDR_LOW1 (0x8_0000_0000; DDR keeps it until the board is power cycled)
python3 src/APP/qwen/board/qwen_board.py loaders qwen35_9b.qwb loaders/ \
        --bases 0x800000000,0x870000000,0x8E0000000
python3 src/APP/qwen/board/qwen_board.py load loaders/ --board palmyra-14 --host gomphus12

# 4. the chat page (builds the engine objects once, then one ELF per question)
python3 src/APP/qwen/web/qwen_web.py --model $MODEL --lib $LIB \
        --board palmyra-14 --host gomphus12 --port 8101
```

A single app run without the page: `qwen_tok.py $MODEL encode "question" --header qwen_prompt.h --ngen 64`,
then `qwen_board.py elf` on `board/qwen_main.c` + the engine sources with
`-D QW_AIE -D QW_SEGS=0x800000000ULL,0x870000000ULL,0x8E0000000ULL` (`QW_VERIFY=1` checks the blob's sums
first), linked with `--obj $LIB/libqwen_gemv_lib.a -L $LIB -l xaienginea78`, and run with
`apppaltest.py --netload`.

## Traps

- **Rebuild the library with a current `hostcompile.sh`.** The generated host.cc references `routing` only
  weakly, and an archive built before the fix did not bring `routing.o` along: the first launch hung unless
  the link carried `-Wl,--undefined=_Z7routingP12XAie_DevInst`. Skill **aiehlclibraryrouting**.
- **vek385_2, not VEK385.** VEK385's A78 sees 2 + 2 GB (the other DDR windows hang it, and AIE reads there
  are ~25 % wrong), so the 4.98 GB blob does not fit. On vek385_2 DDR_LOW1 is 6 GB on the 2026-11-25 PDI.
- **netboot places segments in DDR_LOW0 only**, so a loader carries its chunk there and copies it up.
- **x / y buffers are cached** with an explicit flush / invalidate around each launch. Uncached A78 stores
  run at ~0.5 GB/s. Forgetting the flush gives stale x (MTP acceptance drops to 0 %).
- **A polynomial `expf` or an fp16 DeltaNet state was slower** than libm / fp32 on the A78. The NEON
  `exp4` / `silu_vec` / `dot` helpers are what gained.
- MTP decoding emits exactly the plain greedy sequence (the drafts are verified), so the text does not depend
  on acceptance.
