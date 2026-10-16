###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Whisper -> ONNX -> Relay, canonicalized for an AIE-first partition.

Two graphs, both static:

* **encoder** ``mel[1,80,3000] -> audio_features[1,1500,384]``
* **decoder step** ``(tokens[1,T], audio_features) -> logits[1,T,V]``, no KV
  cache (each step recomputes the prefix; see GAP_ANALYSIS.md).

After import the graph is canonicalized so the partitioner sees one spelling
of each idiom:

1. ``FoldConstant`` + ``SimplifyExpr`` -- weight transposes from ONNX ``MatMul``
   fold into ``nn.dense`` weights; ``LayerNormalization`` arrives decomposed
   (``mean``/``variance``/...).
2. **Attention-scale folding** (``fold_attention_scale``). Whisper scales *both*
   q and k by ``d**-0.25`` after the projection and the head split. A scalar
   commutes with every reshape/transpose on the way back to the ``nn.dense``,
   so ``s * (x W^T + b) == x (sW)^T + sb``: the scale moves into the weight and
   bias constants at compile time and the multiply disappears. The q, k, v and
   out projections are then the *same* GEMM, which is one aiehlc library
   instead of two.
3. **Constant lifting** (``lift_constants``). Every non-scalar constant becomes
   a graph input (``wsp_p<n>``), de-duplicated by content: the decoder's
   ``token_embedding`` (the ``take`` table) and the logits weight are the same
   80 MB tensor after folding and now one parameter. Lifted weights reach the
   AIE functions as *arguments*, so the graph executor stores them in the
   params blob instead of a C source file carrying them as literals
   (``PartitionGraph(bind_constants=True)`` would inline 150 MB into C).
"""

from __future__ import annotations

import hashlib
from pathlib import Path

import numpy as np

ENCODER_INPUTS = {"mel": (1, 80, 3000)}


def decoder_inputs(n_tokens: int, n_audio_ctx: int = 1500, n_state: int = 384) -> dict:
    return {"tokens": (1, n_tokens), "audio_features": (1, n_audio_ctx, n_state)}


def export_onnx(model, out_dir: Path, n_tokens: int, verbose: bool = True) -> dict:
    """Export encoder and one decoder step to ONNX (TorchScript exporter, opset 17).

    The dynamo exporter (torch >= 2.9 default) emits opset-18+ graphs whose
    ``LayerNormalization``/``Split`` forms TVM 0.16's importer predates.
    """
    import warnings

    import torch

    from whisper_model import WhisperDecoderStep

    out_dir.mkdir(parents=True, exist_ok=True)
    dims = model.dims
    paths = {"encoder": out_dir / "whisper_encoder.onnx",
             "decoder": out_dir / f"whisper_decoder_t{n_tokens}.onnx"}
    mel = torch.zeros(ENCODER_INPUTS["mel"])
    tokens = torch.zeros((1, n_tokens), dtype=torch.int64)
    feats = torch.zeros((1, dims.n_audio_ctx, dims.n_audio_state))
    with warnings.catch_warnings(), torch.no_grad():
        warnings.simplefilter("ignore")
        if not paths["encoder"].is_file():
            torch.onnx.export(model.encoder, (mel,), str(paths["encoder"]),
                              input_names=["mel"], output_names=["audio_features"],
                              opset_version=17, dynamo=False)
        if not paths["decoder"].is_file():
            torch.onnx.export(WhisperDecoderStep(model), (tokens, feats), str(paths["decoder"]),
                              input_names=["tokens", "audio_features"],
                              output_names=["logits"], opset_version=17, dynamo=False)
    if verbose:
        for k, p in paths.items():
            print(f"  [onnx] {k}: {p.name} ({p.stat().st_size:,} B)")
    return paths


def _scalar(expr):
    from tvm import relay
    if isinstance(expr, relay.Constant):
        v = expr.data.numpy()
        if v.size == 1:
            return float(v.reshape(-1)[0])
    return None


def fold_attention_scale(mod):
    """Move ``multiply(<reshape/transpose chain>(dense [+ bias]), s)`` into W, b.

    Returns ``(mod, n_folded)``. Only a scalar ``s`` and only a chain of
    ``reshape``/``transpose`` between the multiply and the dense qualify --
    anything else is left alone.
    """
    import tvm
    from tvm import relay
    from tvm.relay.expr_functor import ExprMutator

    def push(expr, s):
        """Rebuild *expr* with *s* folded into its dense; None if not foldable."""
        if not isinstance(expr, relay.Call):
            return None
        name = getattr(expr.op, "name", "")
        if name in ("reshape", "transpose"):
            inner = push(expr.args[0], s)
            return None if inner is None else relay.Call(expr.op, [inner] + list(expr.args[1:]),
                                                         expr.attrs, expr.type_args)
        if name == "add":
            a, b = expr.args
            cst, other = (a, b) if isinstance(a, relay.Constant) else (b, a)
            if not isinstance(cst, relay.Constant):
                return None
            inner = push(other, s)
            if inner is None:
                return None
            scaled = relay.const((cst.data.numpy() * np.float32(s)).astype("float32"))
            return relay.add(scaled, inner) if cst is a else relay.add(inner, scaled)
        if name == "nn.dense" and isinstance(expr.args[1], relay.Constant):
            w = relay.const((expr.args[1].data.numpy() * np.float32(s)).astype("float32"))
            return relay.Call(expr.op, [expr.args[0], w], expr.attrs, expr.type_args)
        return None

    class Folder(ExprMutator):
        n = 0

        def visit_call(self, call):
            new = super().visit_call(call)
            if getattr(new.op, "name", "") == "multiply":
                for i in (0, 1):
                    s = _scalar(new.args[1 - i])
                    if s is not None:
                        folded = push(new.args[i], s)
                        if folded is not None:
                            Folder.n += 1
                            return folded
            return new

    folder = Folder()
    mod["main"] = folder.visit(mod["main"])
    mod = relay.transform.InferType()(mod)
    return mod, Folder.n


def lift_constants(mod, prefix: str = "wsp_p"):
    """Every non-scalar constant -> a graph input. Returns ``(mod, params)``.

    Identical tensors (by dtype, shape and bytes) share one input.
    """
    import tvm
    from tvm import relay
    from tvm.relay.expr_functor import ExprMutator

    params: dict = {}
    by_hash: dict = {}
    new_vars: list = []

    class Lifter(ExprMutator):
        def visit_constant(self, const):
            arr = const.data.numpy()
            if arr.size <= 1:
                return const
            key = (arr.dtype.str, arr.shape, hashlib.sha1(arr.tobytes()).hexdigest())
            if key not in by_hash:
                name = f"{prefix}{len(by_hash)}"
                var = relay.var(name, shape=arr.shape, dtype=str(arr.dtype))
                by_hash[key] = var
                params[name] = tvm.nd.array(arr)
                new_vars.append(var)
            return by_hash[key]

    fn = mod["main"]
    body = Lifter().visit(fn.body)
    mod["main"] = relay.Function(list(fn.params) + new_vars, body, fn.ret_type)
    mod = relay.transform.InferType()(mod)
    return mod, params


def import_relay(onnx_path: Path, shapes: dict, verbose: bool = True):
    """ONNX -> canonical Relay with lifted weights. Returns ``(mod, params)``."""
    import onnx
    import tvm
    from tvm import relay

    import frontend.tvmrelay  # noqa: F401  onnx.mapping shim + TVM 0.16 check

    model = onnx.load(str(onnx_path))
    mod, _ = relay.frontend.from_onnx(model, shape=shapes, freeze_params=True)
    seq = tvm.transform.Sequential([relay.transform.InferType(),
                                    relay.transform.FoldConstant(),
                                    relay.transform.SimplifyExpr(),
                                    relay.transform.FoldConstant()])
    with tvm.transform.PassContext(opt_level=3):
        mod = seq(mod)
    mod, n_fold = fold_attention_scale(mod)
    with tvm.transform.PassContext(opt_level=3):
        mod = relay.transform.FoldConstant()(mod)
    mod, params = lift_constants(mod)
    if verbose:
        nbytes = sum(v.numpy().nbytes for v in params.values())
        print(f"  [relay] {onnx_path.name}: scale folded into {n_fold} projection(s), "
              f"{len(params)} weight inputs ({nbytes / 1e6:.1f} MB)")
    return mod, params
