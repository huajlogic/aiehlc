###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Import the quantized FX graph into MLIR and dump one artifact per stage.

What this actually emits, and why it is not what the docs suggest
-----------------------------------------------------------------
``convert_pt2e`` produces ``quantized_decomposed.{quantize,dequantize}_per_tensor``
and ``dequantize_per_channel``. torch-mlir's upstream lit tests
(``test/Dialect/Torch/{match-quantized-customs-ops,fuse-quantized-ops}.mlir``)
describe a chain that turns those into ``!torch.qint8`` and then into
``linalg.conv_2d_nhwc_hwcf_q``. **That chain does not run here**, and the reason
is worth writing down because the symptom is silence, not an error:

* those three ops are **registered ODS ops** in this torch-mlir build, so
  ``fx_importer`` emits them as native ``torch.quantized_decomposed.*``;
* ``torch-match-quantized-custom-ops`` matches **only** the *unregistered*
  ``torch.operator "torch.quantized_decomposed.*"`` spelling;
* so the match pass never fires, ``torch-fuse-quantized-ops`` finds no
  ``aten``-form QDQ pair to fuse, and no ``!torch.qint8`` is ever created.

Verified both directions with ``torch-mlir-opt`` on hand-written IR: the native
form passes through untouched; the ``torch.operator`` form is rewritten exactly
as the lit test says. This is an upstream gap, not a defect in the flow.

**The output is still genuinely int8.** The backend lowers the native ops to
explicit dequant arithmetic -- ``arith.extsi i8->i64``, ``arith.subi`` for the
zero-point, ``arith.mulf`` for the scale -- around a plain
``linalg.conv_2d_nchw_fchw``. int8 weight literals, per-channel scales and
zero-points are all present.

Both fusion passes are still run: they are harmless no-ops today and start
working the day upstream teaches the matcher the registered form. The op counts
are reported either way, so the day that changes is visible rather than assumed.
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Optional

__all__ = [
    "ARTIFACTS",
    "FUSION_PIPELINE",
    "ImportResult",
    "count_evidence",
    "import_to_mlir",
]

#: ``(key, filename)`` per dumped stage, in pipeline order. The ``final`` name
#: is filled in per-run from ``output_type`` (``resnet18_04_linalg.mlir``,
#: ``_tosa``, ``_torch``).
ARTIFACTS = (
    ("raw", "resnet18_01_torch_raw.mlir"),
    ("torch", "resnet18_02_torch.mlir"),
    ("fused", "resnet18_03_torch_fused.mlir"),
    ("final", "resnet18_04_linalg.mlir"),
)

#: Run the matcher *and* the fuser. Both are no-ops on the registered op form
#: (see the module docstring); kept so the flow improves automatically if
#: upstream closes the gap.
FUSION_PIPELINE = ("builtin.module(func.func(torch-match-quantized-custom-ops),"
                   "func.func(torch-fuse-quantized-ops))")

#: Patterns counted in each dump. The first group is evidence that *must* be
#: present; the ``fused_*`` group is expected to be 0 today and is informational.
_EVIDENCE = {
    "quantize_per_tensor": r"quantized_decomposed\.quantize_per_tensor",
    "dequantize_per_tensor": r"quantized_decomposed\.dequantize_per_tensor",
    "dequantize_per_channel": r"quantized_decomposed\.dequantize_per_channel",
    "int8_literal": r"torch\.vtensor\.literal[^\n]*si8",
    "conv_nchw": r"linalg\.conv_2d_nchw_fchw\b",
    "extsi_i8": r"arith\.extsi[^\n]*i8",
    # TOSA carries the same int8 graph with its own op set, so the final-artifact
    # evidence has to be backend-aware -- counting only linalg patterns reports a
    # perfectly good TOSA lowering as "no int8".
    "tosa_conv": r"tosa\.conv2d\b",
    # `xi8>` not `\bi8\b`: MLIR spells int8 tensors `tensor<1000x512xi8>`, so a
    # word boundary before `i8` never matches -- the `x` is a word character.
    "tosa_i8": r"xi8>",
    "fused_qint8": r"!torch\.qint8",
    "fused_conv_q": r"linalg\.conv_2d_n\w+_\w+_q\b",
    "fused_matmul_q": r"linalg\.quantized_matmul",
    "unmatched_custom": r'torch\.operator "torch\.quantized_decomposed',
}


def count_evidence(text: str) -> dict:
    """Count each :data:`_EVIDENCE` pattern in *text*.

    Counting beats eyeballing: a quantized import that silently reverts to f32
    still parses, still lowers, and still passes every structural check -- the
    op counts are the only thing that catches it. (Same lesson as
    ``tvmrelay``'s ``to_integer_ops``.)
    """
    return {name: len(re.findall(pat, text)) for name, pat in _EVIDENCE.items()}


class ImportResult:
    """Artifacts written plus the evidence counts for each."""

    def __init__(self, paths: dict, evidence: dict, fused: bool,
                 output_type: str, fusion_error: Optional[str] = None):
        self.paths = paths            #: key -> Path
        self.evidence = evidence      #: key -> {pattern: count}
        self.fused = fused            #: did the fusion pipeline run cleanly
        self.output_type = output_type  #: "linalg" | "tosa" | "torch"
        #: Why fusion failed, when it did. A *crashed* pass and the expected
        #: upstream no-op both leave 0 fused ops behind, so without this the
        #: two are indistinguishable and a real regression reads as "normal".
        self.fusion_error = fusion_error

    @property
    def ok(self) -> bool:
        """True when int8 actually survived to the final artifact.

        Deliberately **not** keyed on ``fused_*``: those are 0 on every current
        torch-mlir and requiring them would fail a run that is working.
        """
        torch_ev = self.evidence.get("torch", {})
        final = self.evidence.get("final", {})
        reached_backend = (final.get("extsi_i8", 0) > 0
                           or final.get("fused_conv_q", 0) > 0
                           or (final.get("tosa_conv", 0) > 0
                               and final.get("tosa_i8", 0) > 0))
        return (torch_ev.get("quantize_per_tensor", 0) > 0
                and torch_ev.get("int8_literal", 0) > 0
                and reached_backend)

    def summary(self) -> str:
        """One line of the counts that matter for the final artifact."""
        final = self.evidence.get("final", {})
        if final.get("tosa_conv", 0):
            return (f"{final['tosa_conv']} tosa.conv2d, "
                    f"{final.get('tosa_i8', 0)} i8 references")

        parts = [f"{final.get('conv_nchw', 0)} conv_2d_nchw_fchw",
                 f"{final.get('extsi_i8', 0)} int8 extends"]
        fused = final.get("fused_conv_q", 0) + final.get("fused_matmul_q", 0)
        parts.append(f"{fused} fused *_q" + ("" if fused else " (upstream gap)"))
        return ", ".join(parts)


def _write(path: Path, text: str) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    return path


def import_to_mlir(module, example_input, out_dir: Path, *,
                   output_type: str = "linalg", fuse: bool = True,
                   verbose: bool = True) -> ImportResult:
    """Import *module* to MLIR, writing the :data:`ARTIFACTS` into *out_dir*.

    *output_type* is ``linalg`` (default), ``tosa`` or ``torch``; it selects the
    **final** artifact only -- the raw and torch-level dumps are always written,
    because when something goes wrong they are where it is visible.
    """
    from torch_mlir import fx
    from torch_mlir.compiler_utils import OutputType, run_pipeline_with_repro_report

    final_type = {"linalg": OutputType.LINALG_ON_TENSORS,
                  "tosa": OutputType.TOSA,
                  "torch": OutputType.TORCH}[output_type]

    out_dir = Path(out_dir)
    names = dict(ARTIFACTS)
    paths: dict = {}
    evidence: dict = {}

    def dump(key: str, text: str) -> None:
        paths[key] = _write(out_dir / names[key], text)
        evidence[key] = count_evidence(text)
        if verbose:
            print(f"  [mlir] {names[key]} ({len(text.splitlines()):,} lines)")

    # Stage 01 -- straight out of the importer. The one place an unmatched
    # custom op would be visible as torch.operator "...".
    raw = fx.export_and_import(module, example_input, output_type=OutputType.RAW)
    dump("raw", str(raw))

    # Stage 02 -- torch dialect proper.
    torch_mod = fx.export_and_import(module, example_input,
                                     output_type=OutputType.TORCH)
    torch_text = str(torch_mod)
    dump("torch", torch_text)

    # Stage 03 -- fusion attempt. No-op on current torch-mlir (see docstring),
    # run anyway so the flow improves for free when upstream changes.
    fused_ok = False
    fusion_error = None
    if fuse:
        try:
            run_pipeline_with_repro_report(
                torch_mod, FUSION_PIPELINE,
                "Fusing quantized ops (match + fuse)")
            fused_ok = True
        except Exception as exc:
            # Always recorded, never merely printed: `verbose` controls progress
            # output, and losing a real pass crash to a display flag would hide
            # a regression behind the documented no-op.
            fusion_error = f"{type(exc).__name__}: {str(exc)[:300]}"
        dump("fused", str(torch_mod))
    elif verbose:
        print("  [mlir] fusion skipped (--no-fuse)")

    # Stage 04 -- the requested backend. Re-imported from the original module
    # rather than lowered from the (possibly mutated) stage-03 module, so the
    # backend sees exactly what torch-mlir's own pipeline expects.
    #
    # The final artifact always gets its own key and filename, even for
    # output_type="torch": reusing the "torch" key would overwrite the stage-02
    # dump and leave `ok` reading its own input as evidence.
    names["final"] = f"resnet18_04_{output_type}.mlir"
    try:
        final = fx.export_and_import(module, example_input,
                                     output_type=final_type)
    except Exception as exc:
        # TOSA is the known casualty: its conversion marks
        # `quantized_decomposed.dequantize_per_channel` explicitly illegal and
        # provides no pattern for it, so per-channel weights cannot legalize.
        # Surface that rather than a bare pass-pipeline traceback -- the stages
        # already on disk are still useful.
        hint = ""
        if output_type == "tosa":
            hint = (" -- the TOSA backend has no legalization for "
                    "quantized_decomposed.dequantize_per_channel; retry with "
                    "--output-type linalg, or --per-tensor")
        raise RuntimeError(
            f"lowering to {output_type} failed{hint}\n{str(exc)[:400]}") from None
    dump("final", str(final))

    return ImportResult(paths=paths, evidence=evidence, fused=fused_ok,
                        output_type=output_type, fusion_error=fusion_error)
