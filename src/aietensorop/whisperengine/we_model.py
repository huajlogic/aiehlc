###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Reference model of the Whisper AIE engine's arithmetic (torch, CPU).

The engine stores every tensor that crosses an op boundary in bf16 and does
all math in fp32 (bf16 x bf16 products accumulate in fp32 in the AIE mmul).
This module reproduces exactly those rounding points so it can (1) prove the
engine's precision choices keep Whisper's transcript, and (2) produce per-op
goldens for the board.

Rounding points (``bf()`` = round-to-nearest-even to bf16):
  * weights, biases: bf16; q projection pre-scaled by 1/8 (= dh^-0.5, exact);
  * every activation tensor written by an op: bf16 (residual stream included
    unless ``fp32_residual``);
  * GEMM: fp32 sum of bf16 products, + bias, [GELU], then bf16;
  * LayerNorm: fp32 stats of the bf16 input, output bf16;
  * attention: S = q k^T in fp32, softmax in fp32, P rounded to bf16, O = P v
    in fp32, output bf16 (flash form is the same math up to fp32 rounding);
  * decoder: self-attention K/V cache in bf16; cross-attention K/V computed
    once per audio clip from the encoder output.
"""

from __future__ import annotations

import math

import torch
import torch.nn.functional as F


def bf(t: torch.Tensor) -> torch.Tensor:
    return t.to(torch.bfloat16).to(torch.float32)


# tanh-GELU constants as the AIE holds them (bf16)
GELU_C1 = float(torch.tensor(0.7978845608).to(torch.bfloat16))
GELU_C2 = float(torch.tensor(0.044715 * 0.7978845608).to(torch.bfloat16))


def gelu_aie(y: torch.Tensor) -> torch.Tensor:
    """The engine's GELU, bit-exact: input rounded to bf16 (it is the GEMM's
    bf16 output before activation), then
      1/8 <= |x| < 4 : table of bf16(erf-GELU(x))       (eng/kernel.cc, WE_GELU_LUT)
      |x| <  1/8     : 0.5 x + bf16(x^2) * bf16(1/sqrt(2 pi))   (fp32 sum)
      x >= 4 : x       x <= -4 : 0
    and the result rounded to bf16 by the caller."""
    xb = bf(y)
    ax = xb.abs()
    small = 0.5 * xb + bf(xb * xb) * GELU_SQ
    out = torch.where(ax < 0.125, small, bf(F.gelu(xb)))
    out = torch.where(xb >= 4, xb, out)
    return torch.where(xb <= -4, torch.zeros_like(xb), out)


GELU_SQ = float(torch.tensor(0.3989422804).to(torch.bfloat16))


class EngineModel:
    def __init__(self, model, fp32_residual: bool = False, bf16_act: bool = True, gelu: str = "lut"):
        self.fp32_residual = fp32_residual
        self.gelu_mode = gelu
        self.act = bf if bf16_act else (lambda t: t)
        sd = {k: v.detach().float() for k, v in model.state_dict().items()}
        self.n_head = model.dims.n_audio_head
        dh = model.dims.n_audio_state // self.n_head
        # (dh^-0.25)^2 = 1/8 and log2(e) folded into q: scores come out in log2
        # units and the engine's softmax is exp2 (eng/kernel.cc att_softmax)
        self.qscale = dh ** -0.5 * math.log2(math.e)
        self.w = {}
        for k, v in sd.items():
            if k.endswith(("query.weight", "query.bias")):
                v = v * self.qscale
            self.w[k] = bf(v) if not k.endswith("positional_embedding") else v
        self.enc_pos = sd["encoder.positional_embedding"]
        self.dec_pos = sd["decoder.positional_embedding"]
        self.n_enc = model.dims.n_audio_layer
        self.n_dec = model.dims.n_text_layer

    # -- ops -----------------------------------------------------------------
    def gemm(self, a, w, b=None, gelu=False, res=None):
        """The engine GEMM epilogue: + bias, GELU (bf16 out), + residual, ONE rounding."""
        y = bf(a) @ w.t()
        if b is not None:
            y = y + b
        if gelu:
            y = bf(self.gelu(y))
        if res is not None:
            y = y + res
            if self.fp32_residual:  # residual stream kept in fp32 (no rounding of x)
                return y
        return self.act(y)

    def gelu(self, y):
        """erf GELU in fp32, or the engine's form ("aie"): tanh GELU on bf16(x) with the
        AIE's bf16 tanh, bf16 x bf16 -> fp32 products (the only native multiply)."""
        if self.gelu_mode == "erf":
            return F.gelu(y)
        if self.gelu_mode == "tanh":
            return F.gelu(y, approximate="tanh")
        if self.gelu_mode == "lut":
            return gelu_aie(y)
        # exactly the kernel's sequence (eng/kernel.cc gelu_aie): products of bf16
        # values are exact in fp32, so only the bf() calls below round
        xb = bf(y)
        a = bf(xb * xb)
        b = bf(a * GELU_C2)
        u = xb * GELU_C1 + b * xb
        t = bf(torch.tanh(u))
        h = 0.5 * xb
        return h + h * t

    def ln(self, x, p):
        y = F.layer_norm(x, (x.shape[-1],), self.w[p + ".weight"], self.w[p + ".bias"], 1e-5)
        return self.act(y)

    def res(self, x, d):
        y = x + d
        return y if self.fp32_residual else self.act(y)

    def attention(self, q, k, v, mask=None):
        """q [Tq,384], k/v [Tk,384] -> [Tq,384]; per head, softmax in fp32."""
        H = self.n_head
        Tq, Tk = q.shape[0], k.shape[0]
        qh = q.view(Tq, H, -1).transpose(0, 1)
        kh = k.view(Tk, H, -1).transpose(0, 1)
        vh = v.view(Tk, H, -1).transpose(0, 1)
        s = qh @ kh.transpose(1, 2)  # log2 units
        if mask is not None:
            s = s + mask
        # the kernel's online softmax (eng/kernel.cc att_softmax): 64-key chunks, a
        # per-row reference m raised to the row max only when a score passes m + 32;
        # P = bf16(exp2(s - m)) rescaled with m, denominator in fp32
        m = torch.full(s.shape[:-1] + (1,), -1e30)
        o = torch.zeros(qh.shape[0], Tq, vh.shape[-1])
        l = torch.zeros(s.shape[:-1] + (1,))
        for c0 in range(0, Tk, 64):
            sc = s[..., c0:c0 + 64]
            cmax = sc.max(dim=-1, keepdim=True).values
            raise_ = cmax > m + 32
            m_new = torch.where(raise_, torch.maximum(m, cmax), m)
            f = torch.exp2(m - m_new)
            o, l, m = o * f, l * f, m_new
            e = torch.exp2(sc - m)
            o = o + (e if getattr(self, "fp32_p", False) else bf(e)) @ vh[:, c0:c0 + 64]
            l = l + e.sum(dim=-1, keepdim=True)
        o = o / l
        return self.act(o.transpose(0, 1).reshape(Tq, -1))

    def mha(self, x, p, kv=None, cache=None, mask=None, res=None):
        w = self.w
        q = self.gemm(x, w[p + ".query.weight"], w[p + ".query.bias"])
        if kv is None:
            k = self.gemm(x, w[p + ".key.weight"])
            v = self.gemm(x, w[p + ".value.weight"], w[p + ".value.bias"])
            if cache is not None:
                cache[p] = (torch.cat([cache[p][0], k]), torch.cat([cache[p][1], v])) if p in cache else (k, v)
                k, v = cache[p]
        else:
            k, v = kv
        o = self.attention(q, k, v, mask)
        return self.gemm(o, w[p + ".out.weight"], w[p + ".out.bias"], res=res)

    def mlp(self, x, p, res=None):
        w = self.w
        h = self.gemm(x, w[p + ".mlp.0.weight"], w[p + ".mlp.0.bias"], gelu=True)
        return self.gemm(h, w[p + ".mlp.2.weight"], w[p + ".mlp.2.bias"], res=res)

    # -- network -------------------------------------------------------------
    def conv(self, x, name, stride, res=None):
        """conv1d k=3 pad=1 as a GEMM over im2col: x [T, Cin] -> [T/stride, Cout]."""
        w = self.w[name + ".weight"]  # [Cout, Cin, 3]
        T = x.shape[0]
        xp = F.pad(x, (0, 0, 1, 1))
        To = (T + stride - 1) // stride
        cols = torch.cat([xp[t:t + stride * (To - 1) + 1:stride] for t in range(3)], dim=1)  # [To, 3*Cin]
        wm = w.permute(0, 2, 1).reshape(w.shape[0], -1)  # [Cout, 3*Cin] tap-major
        return self.gemm(cols, wm, self.w[name + ".bias"], gelu=True, res=res)

    def encode(self, mel):
        """mel [80, 3000] -> audio features [1500, 384] (bf16 values)."""
        x = self.conv(bf(mel.t()), "encoder.conv1", 1)
        x = self.conv(x, "encoder.conv2", 2, res=bf(self.enc_pos))  # pos = conv2's bf16 residual
        for i in range(self.n_enc):
            p = f"encoder.blocks.{i}"
            x = self.mha(self.ln(x, p + ".attn_ln"), p + ".attn", res=x)
            x = self.mlp(self.ln(x, p + ".mlp_ln"), p, res=x)
        return self.ln(x, "encoder.ln_post")

    def cross_kv(self, xa):
        w = self.w
        out = {}
        for i in range(self.n_dec):
            p = f"decoder.blocks.{i}.cross_attn"
            out[p] = (self.gemm(xa, w[p + ".key.weight"]),
                      self.gemm(xa, w[p + ".value.weight"], w[p + ".value.bias"]))
        return out

    def decode_tokens(self, toks, pos0, xkv, cache):
        """Embed tokens at positions pos0.., run all decoder blocks with the KV
        cache, return logits of the last token."""
        w = self.w
        n = len(toks)
        x = self.act(w["decoder.token_embedding.weight"][toks] + self.dec_pos[pos0:pos0 + n])
        T = pos0 + n
        mask = torch.full((n, T), float("-inf")).triu_(pos0 + 1)
        for i in range(self.n_dec):
            p = f"decoder.blocks.{i}"
            x = self.mha(self.ln(x, p + ".attn_ln"), p + ".attn", cache=cache, mask=mask, res=x)
            x = self.mha(self.ln(x, p + ".cross_attn_ln"), p + ".cross_attn", kv=xkv[p + ".cross_attn"], res=x)
            x = self.mlp(self.ln(x, p + ".mlp_ln"), p, res=x)
        x = self.ln(x[-1:], "decoder.ln")
        return (bf(x) @ w["decoder.token_embedding.weight"].t())[0]  # fp32 logits (engine WE_F_F32)

    def transcribe(self, mel, sot=(50258, 50259, 50359, 50363), eot=50257, max_tokens=48):
        with torch.no_grad():
            xa = self.encode(mel)
            xkv = self.cross_kv(xa)
            cache = {}
            toks = list(sot)
            logits = self.decode_tokens(toks, 0, xkv, cache)
            out = []
            for _ in range(max_tokens):
                nxt = int(torch.argmax(logits))
                if nxt == eot:
                    break
                out.append(nxt)
                logits = self.decode_tokens([nxt], len(sot) + len(out) - 1, xkv, cache)
            return out
