###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Audio in, text out -- the parts of Whisper around the network.

Everything here runs on the host CPU in a deployment, as it does in upstream
Whisper: decoding the audio file (``ffmpeg``), the log-mel front end
(STFT + mel filterbank), and the byte-level BPE detokenizer. None of it is a
network layer, so none of it is an AIE offload candidate; it exists so the
flow can check the compiled graph against a *transcript*, not just a tensor.

Assets are fetched once from the upstream repository and cached next to the
checkpoint: the JFK sample the upstream test-suite uses, the precomputed mel
filterbank (``mel_filters.npz``) and the multilingual BPE ranks.

Constants and the log-mel recipe follow ``whisper/audio.py`` (MIT, OpenAI).
"""

from __future__ import annotations

import base64
import subprocess
import urllib.request
from pathlib import Path

import numpy as np
import torch

SAMPLE_RATE = 16000
N_FFT = 400
HOP_LENGTH = 160
CHUNK_LENGTH = 30
N_SAMPLES = CHUNK_LENGTH * SAMPLE_RATE  # 480000 samples in a 30-second chunk
N_FRAMES = N_SAMPLES // HOP_LENGTH  # 3000 frames in a mel spectrogram input

_RAW = "https://raw.githubusercontent.com/openai/whisper/main"
ASSETS = {
    "jfk.flac": f"{_RAW}/tests/jfk.flac",
    "mel_filters.npz": f"{_RAW}/whisper/assets/mel_filters.npz",
    "multilingual.tiktoken": f"{_RAW}/whisper/assets/multilingual.tiktoken",
}

# Special tokens of the multilingual vocabulary (n_vocab = 51865). The base
# BPE has 50257 entries; the specials follow in upstream's fixed order.
EOT = 50257
SOT = 50258
LANG_EN = 50259
TRANSCRIBE = 50359
NO_TIMESTAMPS = 50363
SOT_SEQUENCE = (SOT, LANG_EN, TRANSCRIBE, NO_TIMESTAMPS)


def fetch_asset(name: str, cache_dir: Path) -> Path:
    cache_dir.mkdir(parents=True, exist_ok=True)
    path = cache_dir / name
    if not path.is_file() or path.stat().st_size == 0:
        tmp = path.with_suffix(path.suffix + ".part")
        urllib.request.urlretrieve(ASSETS[name], tmp)
        tmp.replace(path)
    return path


def load_audio(path: Path) -> np.ndarray:
    """Decode any audio file to mono float32 at 16 kHz with ffmpeg."""
    cmd = ["ffmpeg", "-nostdin", "-threads", "0", "-i", str(path), "-f", "s16le",
           "-ac", "1", "-acodec", "pcm_s16le", "-ar", str(SAMPLE_RATE), "-"]
    out = subprocess.run(cmd, capture_output=True, check=True).stdout
    return np.frombuffer(out, np.int16).flatten().astype(np.float32) / 32768.0


def pad_or_trim(audio: np.ndarray, length: int = N_SAMPLES) -> np.ndarray:
    if audio.shape[-1] > length:
        return audio[..., :length]
    return np.pad(audio, (0, length - audio.shape[-1]))


def log_mel_spectrogram(audio: np.ndarray, cache_dir: Path, n_mels: int = 80) -> np.ndarray:
    """``[n_mels, 3000]`` float32 log-mel of a 30 s chunk, as upstream computes it."""
    filters = torch.from_numpy(np.load(fetch_asset("mel_filters.npz", cache_dir))[f"mel_{n_mels}"])
    x = torch.from_numpy(pad_or_trim(audio))
    stft = torch.stft(x, N_FFT, HOP_LENGTH, window=torch.hann_window(N_FFT),
                      return_complex=True)
    magnitudes = stft[..., :-1].abs() ** 2
    log_spec = torch.clamp(filters @ magnitudes, min=1e-10).log10()
    log_spec = torch.maximum(log_spec, log_spec.max() - 8.0)
    return ((log_spec + 4.0) / 4.0).numpy().astype(np.float32)


def jfk_mel(cache_dir: Path) -> np.ndarray:
    """The upstream test clip ("And so my fellow Americans ...") as ``[1, 80, 3000]``."""
    audio = load_audio(fetch_asset("jfk.flac", cache_dir))
    return log_mel_spectrogram(audio, cache_dir)[None]


class Detokenizer:
    """Byte-level BPE ids -> text, from the ``.tiktoken`` rank file.

    Decoding needs no merge logic: each id names a byte string, and the text is
    their concatenation. Special tokens (``>= EOT``) are dropped.
    """

    def __init__(self, cache_dir: Path):
        self.bytes_of = {}
        for line in fetch_asset("multilingual.tiktoken", cache_dir).read_text().splitlines():
            if line:
                tok, rank = line.split()
                self.bytes_of[int(rank)] = base64.b64decode(tok)

    def decode(self, ids) -> str:
        return b"".join(self.bytes_of[i] for i in ids if i < EOT).decode("utf-8", "replace")


def greedy_decode(encode, decode_step, mel: np.ndarray, max_tokens: int = 48):
    """Greedy transcription with a no-cache decoder.

    *encode* maps mel -> audio features; *decode_step* maps
    ``(tokens[1,T], features) -> logits[1,T,V]``. Both are plain callables so
    the same loop drives PyTorch, onnxruntime or the TVM graph executor.
    """
    feats = encode(mel)
    tokens = list(SOT_SEQUENCE)
    for _ in range(max_tokens):
        logits = decode_step(np.asarray([tokens], np.int64), feats)
        nxt = int(np.argmax(logits[0, -1]))
        if nxt == EOT:
            break
        tokens.append(nxt)
    return tokens[len(SOT_SEQUENCE):]
