# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
"""Reference for the qwen engine: transformers' Qwen3.5 (text part) on the CPU.

  qwen_ref.py <model_dir> --prompt "..." [--chat] [--gen N] [--engine qwen_x86 --blob b.qwb]

Prints the prompt's token ids, the top-5 logits at its last position and the greedy continuation; with
--engine it runs the C engine on the same ids and reports where the two diverge.
"""
import argparse, re, subprocess, time

import torch
from transformers import AutoModelForCausalLM, AutoTokenizer


def top5(logits):
    v, i = torch.topk(logits.float(), 5)
    return " ".join(f"{a}:{b:.4f}" for a, b in zip(i.tolist(), v.tolist()))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("model_dir")
    ap.add_argument("--prompt", default="The capital of France is")
    ap.add_argument("--chat", action="store_true", help="wrap the prompt in the chat template (thinking off)")
    ap.add_argument("--gen", type=int, default=16)
    ap.add_argument("--dtype", default="bfloat16", choices=("bfloat16", "float32"))
    ap.add_argument("--engine")
    ap.add_argument("--blob")
    a = ap.parse_args()
    tok = AutoTokenizer.from_pretrained(a.model_dir)
    if a.chat:
        text = tok.apply_chat_template([{"role": "user", "content": a.prompt}], tokenize=False,
                                       add_generation_prompt=True, enable_thinking=False)
    else:
        text = a.prompt
    ids = tok(text, return_tensors="pt").input_ids
    print("IDS", ",".join(map(str, ids[0].tolist())))
    torch.set_num_threads(32)
    t0 = time.time()
    model = AutoModelForCausalLM.from_pretrained(a.model_dir, dtype=getattr(torch, a.dtype))
    model.eval()
    print(f"loaded in {time.time() - t0:.0f} s: {type(model).__name__}")
    with torch.no_grad():
        out = model(ids)
        print("REF TOP5", top5(out.logits[0, -1]))
        gen = model.generate(ids, max_new_tokens=a.gen, do_sample=False)
    g = gen[0, ids.shape[1]:].tolist()
    print("REF GEN", " ".join(map(str, g)))
    print("REF TEXT", repr(tok.decode(g)))
    if a.engine:
        r = subprocess.run([a.engine, a.blob, ",".join(map(str, ids[0].tolist())), str(a.gen)],
                           capture_output=True, text=True)
        print(r.stdout + r.stderr)
        m = re.search(r"^GEN (.*)$", r.stdout, re.M)
        e = list(map(int, m.group(1).split())) if m else []
        same = next((i for i, (x, y) in enumerate(zip(g, e)) if x != y), min(len(g), len(e)))
        print(f"ENGINE TEXT {tok.decode(e)!r}")
        print(f"MATCH first {same} of {len(g)} greedy tokens")


if __name__ == "__main__":
    main()
