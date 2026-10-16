###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""OpenAI Whisper, the network only -- loaded from the official checkpoint.

The architecture below is a transcription of ``whisper/model.py`` from
https://github.com/openai/whisper (MIT licence, Copyright (c) 2022 OpenAI),
cut down to what an export needs: no KV cache hooks, no SDPA fast path, no
``transcribe``/``decode`` helpers. It is vendored rather than ``pip install``ed
because ``import whisper`` drags in ``numba`` (word timestamps) and the decode
loop, neither of which a compile flow uses, and because the package pins
nothing about torch -- installing it into the shared venv is a bet on the
resolver leaving torch 2.10 alone.

The checkpoint is the one ``whisper.load_model("tiny")`` downloads, verified
by the SHA-256 that is part of its URL. It stores fp16 weights; they are cast
to fp32 here because the TVM flow is fp32 end to end (see README.md, "numeric
model").

Two pieces of the original are changed, both for export, neither for maths:

* ``MultiHeadAttention.qkv_attention`` returns only ``wv`` -- the ``qk``
  side output exists for alignment heads and would otherwise become a second
  graph output per block.
* ``TextDecoder.forward`` takes no KV cache: the decoder graph is one fixed-T
  step (``WhisperDecoderStep``), which is what a static-shape compiler can
  build. The incremental cache is a known gap, recorded in GAP_ANALYSIS.md.
"""

from __future__ import annotations

import hashlib
import urllib.request
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import torch
import torch.nn.functional as F
from torch import Tensor, nn

#: Official checkpoints. The hex path component IS the SHA-256 of the file.
MODEL_URLS = {
    "tiny": "https://openaipublic.azureedge.net/main/whisper/models/"
            "65147644a518d12f04e32d6f3b26facc3f8dd46e5390956a9424a650c0ce22b9/tiny.pt",
    "tiny.en": "https://openaipublic.azureedge.net/main/whisper/models/"
               "d3dd57d32accea0b295c96e26691aa14d8822fac7d9d27d5dc00b4ca2826dd03/tiny.en.pt",
    "base": "https://openaipublic.azureedge.net/main/whisper/models/"
            "ed3a0b6b1c0edf879ad9b11b1af5a0e6ab5db9205f891f668f8b0e6c6326e34e/base.pt",
}


@dataclass
class ModelDimensions:
    n_mels: int
    n_audio_ctx: int
    n_audio_state: int
    n_audio_head: int
    n_audio_layer: int
    n_vocab: int
    n_text_ctx: int
    n_text_state: int
    n_text_head: int
    n_text_layer: int


class LayerNorm(nn.LayerNorm):
    def forward(self, x: Tensor) -> Tensor:
        return super().forward(x.float()).type(x.dtype)


class Linear(nn.Linear):
    def forward(self, x: Tensor) -> Tensor:
        return F.linear(x, self.weight.to(x.dtype),
                        None if self.bias is None else self.bias.to(x.dtype))


class Conv1d(nn.Conv1d):
    def _conv_forward(self, x: Tensor, weight: Tensor, bias) -> Tensor:
        return super()._conv_forward(
            x, weight.to(x.dtype), None if bias is None else bias.to(x.dtype))


def sinusoids(length: int, channels: int, max_timescale: int = 10000) -> Tensor:
    """Returns sinusoids for positional embedding"""
    assert channels % 2 == 0
    log_timescale_increment = np.log(max_timescale) / (channels // 2 - 1)
    inv_timescales = torch.exp(-log_timescale_increment * torch.arange(channels // 2))
    scaled_time = torch.arange(length)[:, np.newaxis] * inv_timescales[np.newaxis, :]
    return torch.cat([torch.sin(scaled_time), torch.cos(scaled_time)], dim=1)


class MultiHeadAttention(nn.Module):
    def __init__(self, n_state: int, n_head: int):
        super().__init__()
        self.n_head = n_head
        self.query = Linear(n_state, n_state)
        self.key = Linear(n_state, n_state, bias=False)
        self.value = Linear(n_state, n_state)
        self.out = Linear(n_state, n_state)

    def forward(self, x: Tensor, xa: Tensor | None = None,
                mask: Tensor | None = None) -> Tensor:
        q = self.query(x)
        k = self.key(x if xa is None else xa)
        v = self.value(x if xa is None else xa)
        return self.out(self.qkv_attention(q, k, v, mask))

    def qkv_attention(self, q: Tensor, k: Tensor, v: Tensor,
                      mask: Tensor | None = None) -> Tensor:
        n_batch, n_ctx, n_state = q.shape
        scale = (n_state // self.n_head) ** -0.25
        q = q.view(*q.shape[:2], self.n_head, -1).permute(0, 2, 1, 3) * scale
        k = k.view(*k.shape[:2], self.n_head, -1).permute(0, 2, 3, 1) * scale
        v = v.view(*v.shape[:2], self.n_head, -1).permute(0, 2, 1, 3)
        qk = q @ k
        if mask is not None:
            qk = qk + mask[:n_ctx, :n_ctx]
        w = F.softmax(qk.float(), dim=-1).to(q.dtype)
        return (w @ v).permute(0, 2, 1, 3).flatten(start_dim=2)


class ResidualAttentionBlock(nn.Module):
    def __init__(self, n_state: int, n_head: int, cross_attention: bool = False):
        super().__init__()
        self.attn = MultiHeadAttention(n_state, n_head)
        self.attn_ln = LayerNorm(n_state)
        self.cross_attn = MultiHeadAttention(n_state, n_head) if cross_attention else None
        self.cross_attn_ln = LayerNorm(n_state) if cross_attention else None
        n_mlp = n_state * 4
        self.mlp = nn.Sequential(Linear(n_state, n_mlp), nn.GELU(), Linear(n_mlp, n_state))
        self.mlp_ln = LayerNorm(n_state)

    def forward(self, x: Tensor, xa: Tensor | None = None,
                mask: Tensor | None = None) -> Tensor:
        x = x + self.attn(self.attn_ln(x), mask=mask)
        if self.cross_attn is not None:
            x = x + self.cross_attn(self.cross_attn_ln(x), xa)
        x = x + self.mlp(self.mlp_ln(x))
        return x


class AudioEncoder(nn.Module):
    def __init__(self, n_mels: int, n_ctx: int, n_state: int, n_head: int, n_layer: int):
        super().__init__()
        self.conv1 = Conv1d(n_mels, n_state, kernel_size=3, padding=1)
        self.conv2 = Conv1d(n_state, n_state, kernel_size=3, stride=2, padding=1)
        self.register_buffer("positional_embedding", sinusoids(n_ctx, n_state))
        self.blocks = nn.ModuleList(
            [ResidualAttentionBlock(n_state, n_head) for _ in range(n_layer)])
        self.ln_post = LayerNorm(n_state)

    def forward(self, x: Tensor) -> Tensor:
        """x : (batch, n_mels, n_ctx * 2) log-mel spectrogram"""
        x = F.gelu(self.conv1(x))
        x = F.gelu(self.conv2(x))
        x = x.permute(0, 2, 1)
        x = (x + self.positional_embedding).to(x.dtype)
        for block in self.blocks:
            x = block(x)
        return self.ln_post(x)


class TextDecoder(nn.Module):
    def __init__(self, n_vocab: int, n_ctx: int, n_state: int, n_head: int, n_layer: int):
        super().__init__()
        self.token_embedding = nn.Embedding(n_vocab, n_state)
        self.positional_embedding = nn.Parameter(torch.empty(n_ctx, n_state))
        self.blocks = nn.ModuleList(
            [ResidualAttentionBlock(n_state, n_head, cross_attention=True)
             for _ in range(n_layer)])
        self.ln = LayerNorm(n_state)
        mask = torch.empty(n_ctx, n_ctx).fill_(-np.inf).triu_(1)
        self.register_buffer("mask", mask, persistent=False)

    def forward(self, x: Tensor, xa: Tensor) -> Tensor:
        """x : (batch, n_tokens) int64 token ids;  xa : encoder output"""
        x = self.token_embedding(x) + self.positional_embedding[: x.shape[-1]]
        x = x.to(xa.dtype)
        for block in self.blocks:
            x = block(x, xa, mask=self.mask)
        x = self.ln(x)
        return (x @ torch.transpose(self.token_embedding.weight.to(x.dtype), 0, 1)).float()


class Whisper(nn.Module):
    def __init__(self, dims: ModelDimensions):
        super().__init__()
        self.dims = dims
        self.encoder = AudioEncoder(dims.n_mels, dims.n_audio_ctx, dims.n_audio_state,
                                    dims.n_audio_head, dims.n_audio_layer)
        self.decoder = TextDecoder(dims.n_vocab, dims.n_text_ctx, dims.n_text_state,
                                   dims.n_text_head, dims.n_text_layer)


class WhisperDecoderStep(nn.Module):
    """One static decoder step: ``(tokens[1,T], audio_features) -> logits[1,T,V]``.

    The export unit for the decoder. A wrapper rather than the bare
    ``TextDecoder`` so the graph's inputs are named and ordered once, here.
    """

    def __init__(self, model: Whisper):
        super().__init__()
        self.decoder = model.decoder

    def forward(self, tokens: Tensor, audio_features: Tensor) -> Tensor:
        return self.decoder(tokens, audio_features)


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def fetch_checkpoint(name: str, cache_dir: Path, verbose: bool = True) -> Path:
    """Download (once) and SHA-verify the official checkpoint *name*."""
    url = MODEL_URLS[name]
    want = url.split("/")[-2]
    cache_dir.mkdir(parents=True, exist_ok=True)
    path = cache_dir / Path(url).name
    if not (path.is_file() and _sha256(path) == want):
        if verbose:
            print(f"  [whisper] downloading {url}")
        tmp = path.with_suffix(".part")
        urllib.request.urlretrieve(url, tmp)
        got = _sha256(tmp)
        if got != want:
            tmp.unlink()
            raise RuntimeError(f"{name}: SHA-256 mismatch ({got} != {want})")
        tmp.replace(path)
    elif verbose:
        print(f"  [whisper] cached {path} ({path.stat().st_size:,} B, sha256 ok)")
    return path


def load_whisper(name: str, cache_dir: Path, verbose: bool = True) -> Whisper:
    """The official *name* checkpoint as an fp32 ``Whisper`` in eval mode.

    ``strict=True``: a key the vendored architecture does not have (or lacks)
    means the transcription drifted from upstream, and a silently
    default-initialised tensor would still produce *a* transcript.
    """
    ckpt = torch.load(fetch_checkpoint(name, cache_dir, verbose),
                      map_location="cpu", weights_only=False)
    dims = ModelDimensions(**ckpt["dims"])
    model = Whisper(dims)
    model.load_state_dict({k: v.float() for k, v in ckpt["model_state_dict"].items()},
                          strict=True)
    return model.float().eval()
