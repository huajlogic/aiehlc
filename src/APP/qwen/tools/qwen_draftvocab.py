# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
"""Order the vocabulary by token frequency for the MTP draft's reduced vocabulary.

  qwen_draftvocab.py <model_dir> <out.npy> <text file | .parquet>... [--mb 40]

Tokenizes up to --mb MB of text per corpus, normalizes each corpus's counts to the same total (so each
language weighs the same), adds the chat-template special tokens on top, and writes the token ids in
descending frequency (unseen ids last, in id order) as int32. qwen_convert.py --lm-order permutes lm_head's rows
by it, so the draft can score only the first rows (the most frequent tokens) of every language.
"""
import argparse, collections

import numpy as np
from transformers import AutoTokenizer


def texts(path, mb):
    budget = mb << 20
    if path.endswith(".parquet"):
        import pyarrow.parquet as pq
        t = pq.read_table(path)
        col = "text" if "text" in t.column_names else t.column_names[-1]
        for s in t.column(col).to_pylist():
            if not s:
                continue
            yield s
            budget -= len(s.encode())
            if budget <= 0:
                return
    else:
        with open(path, encoding="utf-8", errors="replace") as f:
            while budget > 0:
                s = f.read(1 << 20)
                if not s:
                    return
                budget -= len(s.encode())
                yield s


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("model_dir")
    ap.add_argument("out")
    ap.add_argument("corpora", nargs="+")
    ap.add_argument("--mb", type=int, default=40)
    a = ap.parse_args()
    tok = AutoTokenizer.from_pretrained(a.model_dir)
    V = len(tok)
    total = np.zeros(V + 1024, dtype=np.float64)
    for path in a.corpora:
        c = collections.Counter()
        for s in texts(path, a.mb):
            c.update(tok(s).input_ids)
        n = sum(c.values())
        for k, v in c.items():
            total[k] += v / n
        print(f"{path}: {n} tokens, {len(c)} distinct")
    for t in tok.all_special_ids:  # the chat template's tokens always in the draft
        total[t] += 1.0
    order = np.argsort(-total, kind="stable").astype(np.int32)
    np.save(a.out, order)
    for k in (8192, 16384, 32768, 65536):
        print(f"top {k}: {total[order[:k]].sum() / total.sum():.4f} of the frequency mass")


if __name__ == "__main__":
    main()
