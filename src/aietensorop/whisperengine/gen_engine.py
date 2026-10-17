###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Whisper-tiny -> whisper engine description.

Writes, into --out (default worklocal/whisperengine/net):
  blob.bin    every weight in the engine's layouts (bf16, we_desc.h / we_host.h),
              the JFK mel (time-major, padded) and the decoder positional table
  gold.bin    checkpoints from we_model.EngineModel (the engine's exact numerics)
  eng_net.h   offsets + shapes for eng/host.cc, the expected transcript tokens

Packing mirrors eng/we_host.h exactly (we_pack_w, we_head_col, BLK); the pass
counts (mbp) used here are the ones eng/host.cc passes to we_gemm, because
they decide how a GEMM splits into sub-ops and therefore the weight order.
"""
from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import numpy as np
import torch

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
sys.path.insert(0, str(REPO / "src/frontend/tvmrelay/example/whisper"))
sys.path.insert(0, str(HERE))
from we_model import EngineModel, bf, fold, ln_consts  # noqa: E402

SOT = (50258, 50259, 50359, 50363)
EOT = 50257
NVOCAB = 51865
LOGIT_SLICE = 768  # rows per logits GEMM: hi/lo weights per mesh column must fit one memtile
NSLICE = -(-NVOCAB // LOGIT_SLICE)  # 34


def u16(t: torch.Tensor) -> np.ndarray:
    return t.to(torch.bfloat16).contiguous().view(torch.int16).numpy().view(np.uint16)


def head_col(h, d):
    return (2 * (d // 16) + h // 3) * 48 + ((h % 3) * 2 + (d % 16) // 8) * 8 + d % 8


def head_perm():
    """perm[new_col] = old_col for one 384 block"""
    p = np.zeros(384, np.int64)
    for h in range(6):
        for d in range(64):
            p[head_col(h, d)] = h * 64 + d
    return p


def gemm_nbs(n, passes):
    nbc = n // 192
    if passes > 1 or passes < 0:
        return 1
    for d in (4, 3, 2):
        if nbc % d == 0:
            return d
    return 1


def pack_w(w: np.ndarray, passes: int) -> np.ndarray:
    """we_pack_w: W [N][K] -> [c 4][sub][nb][kc][kt 6][nt 6][kk 8][nn 8]"""
    n, k = w.shape
    nbs = gemm_nbs(n, passes)
    nsub, kcn = n // 192 // nbs, k // 48
    t = w.reshape(nsub, 4, nbs, 6, 8, kcn, 6, 8)        # [s][c][nb][nt][nn][kc][kt][kk]
    t = t.transpose(1, 0, 2, 5, 6, 3, 7, 4)               # [c][s][nb][kc][kt][nt][kk][nn]
    return np.ascontiguousarray(t).reshape(-1)


def blk(x: np.ndarray, rb: int) -> np.ndarray:
    """[4*rb][C] -> BLK [r][cb][rg][kt 6][4][8]"""
    m, c = x.shape
    assert m == 4 * rb and c % 48 == 0
    t = x.reshape(4, rb // 4, 4, c // 48, 6, 8)            # [r][rg][i][cb][kt][j]
    return np.ascontiguousarray(t.transpose(0, 3, 1, 4, 2, 5)).reshape(-1)


class Blob:
    def __init__(self):
        self.parts, self.off = [], 0

    def add(self, arr: np.ndarray, name: str, sym: list) -> int:
        b = arr.tobytes()
        pad = (-self.off) % 64
        if pad:
            self.parts.append(b"\0" * pad)
            self.off += pad
        off = self.off
        self.parts.append(b)
        self.off += len(b)
        sym.append((name, off, len(b)))
        return off


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(REPO / "worklocal/whisperengine/net"))
    ap.add_argument("--cache", default=str(REPO / "worklocal/whisper_deploy/cache"))
    args = ap.parse_args()
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    from whisper_model import load_whisper
    from whisper_audio import jfk_mel, Detokenizer
    cache = Path(args.cache)
    model = load_whisper("tiny", cache, verbose=False)
    em = EngineModel(model)
    sd32 = {k: v.detach().float() for k, v in model.state_dict().items()}
    for k in list(em.w):  # decoder GEMM weights carried as hi+lo bf16 pairs (see add_gemm)
        if k.startswith("decoder.") and k.endswith("weight") and "_ln" not in k and not k.startswith("decoder.ln"):
            full = sd32[k] * (em.qscale if k.endswith("query.weight") else 1)
            hi = bf(full)
            em.w[k] = hi + bf(full - hi)
    em.hilo_dec = True
    W = em.w
    # token embedding as the engine reads it back for the lookup: the packed logits
    # weight holds gamma_ln (.) E (hi/lo), divided by gamma_ln in fp32 (eng/host.cc emb_row)
    g_dln = W["decoder.ln.weight"].float()
    eh, el = fold(W["decoder.token_embedding.weight"], g_dln, True)
    em.emb_lookup = (eh + el) / g_dln[None, :]
    perm = head_perm()
    blob, sym = Blob(), []

    def wt(name):
        return W[name].float()

    def add_gemm(name, w: torch.Tensor, b, passes, k_pad=None, hilo=False, nchunk=None, ln=None):
        """hilo: W' = [bf16(W) | bf16(W - bf16(W))] (K' = 2K), ~16-bit weights for the
        decoder (eng/we_host.h WeGemm.wsplit). nchunk: pack N in independent chunks.
        ln: LayerNorm prefix folded in (we_desc.h WE_F_LN): W' = gamma (.) W and
        <name>_ln = [d fp32 N][c_hi bf16 N][c_lo bf16 N] instead of <name>_b."""
        w = w.float()
        if ln is not None:
            hi, lo = fold(w, wt(ln + ".weight"), hilo)
            ch, cl, d = ln_consts(w, hi if lo is None else hi + lo, b, wt(ln + ".bias"))
            blob.add(np.concatenate([d.numpy().astype(np.float32).view(np.uint16), u16(ch), u16(cl)]),
                     name + "_ln", sym)
            b = None
            w = hi if lo is None else torch.cat([hi, lo], dim=1)
            hilo = False
        if k_pad and w.shape[1] < k_pad:
            w = torch.nn.functional.pad(w, (0, k_pad - w.shape[1]))
        if hilo:
            hi = bf(w)
            w = torch.cat([hi, bf(w - hi)], dim=1)
        n = w.shape[0]
        step = nchunk or n
        parts = [pack_w(u16(w[c0:c0 + step]).reshape(step, w.shape[1]), passes) for c0 in range(0, n, step)]
        blob.add(np.concatenate(parts), name + "_w", sym)
        if b is not None:
            blob.add(u16(b.float()), name + "_b", sym)

    def add_vec(name, v):
        blob.add(u16(v.float()), name, sym)

    def qkv_rows(prefix, with_k=True):
        """[q (scaled, head-permuted) | k | v] weight rows + biases"""
        q, k, v = wt(prefix + ".query.weight"), wt(prefix + ".key.weight"), wt(prefix + ".value.weight")
        bq, bv = wt(prefix + ".query.bias"), wt(prefix + ".value.bias")
        pw = torch.cat([q[perm], k[perm], v[perm]])
        pb = torch.cat([bq[perm], torch.zeros(384), bv[perm]])
        return pw, pb

    # ---- encoder ----
    mel = torch.from_numpy(jfk_mel(cache)[0])               # [80, 3000]
    mel_rm = torch.zeros(3080, 80)
    mel_rm[1:3001] = mel.t()
    blob.add(u16(bf(mel_rm)), "mel", sym)
    for i, nm in ((1, "encoder.conv1"), (2, "encoder.conv2")):
        w = wt(nm + ".weight")                               # [384, Cin, 3] -> tap-major [384, 3*Cin]
        add_gemm(f"conv{i}", w.permute(0, 2, 1).reshape(384, -1), wt(nm + ".bias"),
                 -1 if i == 1 else 3, k_pad=288 if i == 1 else None)
    pos = torch.zeros(1536, 384)
    pos[:1500] = em.enc_pos
    blob.add(blk(u16(bf(pos)).reshape(1536, 384), 384), "pos_enc", sym)
    for l in range(4):
        p = f"encoder.blocks.{l}"
        pw, pb = qkv_rows(p + ".attn")
        add_gemm(f"e{l}_qkv", pw, pb, 1, ln=p + ".attn_ln")
        add_gemm(f"e{l}_out", wt(p + ".attn.out.weight")[:, perm], wt(p + ".attn.out.bias"), 2)
        add_gemm(f"e{l}_fc1", wt(p + ".mlp.0.weight"), wt(p + ".mlp.0.bias"), 1, ln=p + ".mlp_ln")
        add_gemm(f"e{l}_fc2", wt(p + ".mlp.2.weight"), wt(p + ".mlp.2.bias"), 3)
    # ---- cross K/V (one GEMM per decoder layer on the encoder output) ----
    for l in range(4):
        p = f"decoder.blocks.{l}.cross_attn"
        k, v = wt(p + ".key.weight"), wt(p + ".value.weight")
        add_gemm(f"x{l}_kv", torch.cat([k[perm], v[perm]]),
                 torch.cat([torch.zeros(384), wt(p + ".value.bias")[perm]]), 1, hilo=True, ln="encoder.ln_post")
    # ---- decoder ----
    for l in range(4):
        p = f"decoder.blocks.{l}"
        pw, pb = qkv_rows(p + ".attn")
        add_gemm(f"d{l}_qkv", pw, pb, 1, hilo=True, ln=p + ".attn_ln")
        add_gemm(f"d{l}_out", wt(p + ".attn.out.weight")[:, perm], wt(p + ".attn.out.bias"), 1, hilo=True)
        add_gemm(f"d{l}_q", wt(p + ".cross_attn.query.weight")[perm], wt(p + ".cross_attn.query.bias")[perm], 1,
                 hilo=True, ln=p + ".cross_attn_ln")
        add_gemm(f"d{l}_xout", wt(p + ".cross_attn.out.weight")[:, perm], wt(p + ".cross_attn.out.bias"), 1,
                 hilo=True)
        add_gemm(f"d{l}_fc1", wt(p + ".mlp.0.weight"), wt(p + ".mlp.0.bias"), 1, hilo=True, nchunk=768,
                 ln=p + ".mlp_ln")
        add_gemm(f"d{l}_fc2", wt(p + ".mlp.2.weight"), wt(p + ".mlp.2.bias"), 1, hilo=True, nchunk=192)
    add_vec("lnd_g", wt("decoder.ln.weight")); add_vec("lnd_b", wt("decoder.ln.bias"))
    E = wt("decoder.token_embedding.weight")
    Ep = torch.zeros(NSLICE * LOGIT_SLICE, 384)
    Ep[:NVOCAB] = E
    for s in range(NSLICE):
        add_gemm(f"emb{s}", Ep[s * LOGIT_SLICE:(s + 1) * LOGIT_SLICE], None, 1, hilo=True, ln="decoder.ln")
    blob.add(em.dec_pos[:48].float().numpy().astype(np.float32), "dec_pos", sym)
    (out / "blob.bin").write_bytes(b"".join(blob.parts))

    # ---- goldens: engine-exact model ----
    det = Detokenizer(cache)
    gold, gsym = Blob(), []
    with torch.no_grad():
        x = em.conv(bf(mel.t()), "encoder.conv1", 1)
        x = em.conv(x, "encoder.conv2", 2, res=bf(em.enc_pos))
        g0 = torch.zeros(1536, 384); g0[:1500] = x
        gold.add(blk(u16(g0).reshape(1536, 384), 384), "g_x0", gsym)
        for i in range(em.n_enc):
            p = f"encoder.blocks.{i}"
            x = em.mha(em.ln(x, p + ".attn_ln"), p + ".attn", res=x)
            x = em.mlp(em.ln(x, p + ".mlp_ln"), p, res=x)
            g1 = torch.zeros(1536, 384); g1[:1500] = x
            gold.add(blk(u16(g1).reshape(1536, 384), 384), f"g_x{i + 1}", gsym)
        xa = em.ln(x, "encoder.ln_post")
        toks = em.transcribe(mel)
        xkv = em.cross_kv(xa)
        lg0 = em.decode_tokens(list(SOT), 0, xkv, {})
        gold.add(lg0.float().numpy().astype(np.float32), "g_logits0", gsym)
        # decoder step 0 checkpoints (4 tokens, rows 0..3 of a 64-row block)
        n = len(SOT)
        def dblk(t):
            z = torch.zeros(256, 384); z[:n] = t
            return blk(u16(z).reshape(256, 384), 64)
        xd = em.act(em.emb_lookup[list(SOT)] + em.dec_pos[:n])
        gold.add(dblk(xd), "g_d_x0", gsym)
        mask = torch.full((n, n), float("-inf")).triu_(1)
        p = "decoder.blocks.0"
        xd = em.mha(em.ln(xd, p + ".attn_ln"), p + ".attn", cache={}, mask=mask, res=xd)
        gold.add(dblk(xd), "g_d_sa", gsym)
        xd = em.mha(em.ln(xd, p + ".cross_attn_ln"), p + ".cross_attn", kv=xkv[p + ".cross_attn"], res=xd)
        gold.add(dblk(xd), "g_d_ca", gsym)
        xd = em.mlp(em.ln(xd, p + ".mlp_ln"), p, res=xd)
        gold.add(dblk(xd), "g_d_l0", gsym)
    (out / "gold.bin").write_bytes(b"".join(gold.parts))
    print("engine-model transcript:", det.decode(toks), toks)

    L = ["/* Generated by gen_engine.py -- do not edit. */", "#ifndef ENG_NET_H", "#define ENG_NET_H",
         f'#define WN_BLOB_PATH "{(out / "blob.bin").resolve()}"', f"#define WN_BLOB_BYTES {blob.off}u",
         f'#define WN_GOLD_PATH "{(out / "gold.bin").resolve()}"', f"#define WN_GOLD_BYTES {gold.off}u",
         f"#define WN_NVOCAB {NVOCAB}", f"#define WN_NSLICE {NSLICE}", f"#define WN_LOGIT_SLICE {LOGIT_SLICE}",
         f"#define WN_EOT {EOT}", f"#define WN_NSOT {len(SOT)}",
         "static const int wn_sot[] = {" + ", ".join(map(str, SOT)) + "};",
         f"#define WN_NEXP {len(toks)}", "static const int wn_expect[] = {" + ", ".join(map(str, toks)) + "};"]
    for name, off, n in sym:
        L.append(f"#define WN_{name.upper()} {off}u /* {n} B */")
    for name, off, n in gsym:
        L.append(f"#define WN_{name.upper()} {off}u /* {n} B */")
    L += ["#endif", ""]
    (out / "eng_net.h").write_text("\n".join(L))
    print(f"blob {blob.off / 1e6:.1f} MB, gold {gold.off / 1e6:.2f} MB -> {out}")


if __name__ == "__main__":
    main()
