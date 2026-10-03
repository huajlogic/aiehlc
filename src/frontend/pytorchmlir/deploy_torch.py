###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""PyTorch ResNet-18 -> PT2E int8 -> torch-mlir -> MLIR on disk.

Five stages::

    env -> model -> PT2E int8 quantize -> torch-mlir import -> linalg + verify

The sibling ``src/frontend/tvmrelay`` reaches int8 the other way (ONNX ->
onnxruntime PTQ -> Relay) and needs a TVM 0.16 source build. This path shares
none of that: torch, torchvision and a torch-mlir wheel, nothing compiled.

Scope ends at MLIR. No aiegraph, no AIE backend -- wiring the output into the
AIE pipeline is a separate change.

Run it::

    PYTHONPATH=src python src/frontend/pytorchmlir/deploy_torch.py
    PYTHONPATH=src python src/frontend/pytorchmlir/deploy_torch.py --image cat.jpg
    PYTHONPATH=src python src/frontend/pytorchmlir/deploy_torch.py --output-type tosa
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Optional, Sequence

# Running this file directly (`python .../deploy_torch.py`) leaves it outside any
# package, so the relative imports below would fail. Put `.../src` on sys.path --
# NOT `.../src/frontend`, which shadows real third-party packages with the
# sibling directories of the same name -- and re-enter as a package.
if __package__ in (None, ""):  # pragma: no cover - only on direct execution
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
    __package__ = "frontend.pytorchmlir"

__all__ = ["DEFAULT_OUT", "main", "run"]

#: Output directory, relative like ``tvmrelay``'s ``DEFAULT_OUT``.
DEFAULT_OUT = Path("./worklocal/pytorchmlir_deploy")

#: Backends ``--output-type`` accepts, for the **final** artifact.
OUTPUT_TYPES = ("linalg", "tosa", "torch")

#: Activation observers. ``minmax`` matches ONNX PTQ's ``CalibrationMethod``,
#: which is the apples-to-apples setting against the tvmrelay flow.
OBSERVERS = ("histogram", "minmax")


# ═══════════════════════════════════════════════════════════════════════════
#  Stage 1 -- environment
# ═══════════════════════════════════════════════════════════════════════════

def stage_env(verbose: bool = True) -> bool:
    """Report torch/torchvision/torch-mlir and which PT2E tree answered."""
    from .torch_deps import deps_status, pt2e_api

    status = deps_status()
    if not status.ok:
        print(f"[1/5] env    : {status.describe()}", file=sys.stderr)
        print(f"[1/5]          install with: python "
              f"src/frontend/pytorchmlir/setup_torchmlir.py --yes",
              file=sys.stderr)
        return False

    try:
        provenance = pt2e_api().provenance
    except ImportError as exc:
        print(f"[1/5] env    : PT2E unavailable -- {exc}", file=sys.stderr)
        return False

    if verbose:
        print(f"[1/5] env    : {status.describe()} | pt2e via {provenance}")
    return True


# ═══════════════════════════════════════════════════════════════════════════
#  Stages 2-3 -- model and quantization
# ═══════════════════════════════════════════════════════════════════════════

def stage_quantize(images: Optional[Sequence], *, per_channel: bool,
                   observer: str, verbose: bool = True):
    """Load ResNet-18 v1 and quantize it. Returns a ``QuantizeResult``."""
    from .quantize_pt2e_flow import load_resnet18, quantize_resnet18

    model, detail = load_resnet18(verbose=False)
    if verbose:
        print(f"[2/5] model  : {detail}")

    result = quantize_resnet18(model, images, per_channel=per_channel,
                               observer=observer, verbose=False)
    if verbose:
        scheme = ("per-channel symmetric w / affine act" if per_channel
                  else "per-tensor symmetric w / affine act")
        print(f"[3/5] int8   : {result.describe()}")
        print(f"[3/5]          {scheme} | {observer} observer | "
              f"calib {result.calib_count} image(s) | capture {result.capture}")
        ops = sum(result.quant_ops.values())
        print(f"[3/5]          {ops} quantized_decomposed ops after convert")
    return result


# ═══════════════════════════════════════════════════════════════════════════
#  Stages 4-5 -- MLIR
# ═══════════════════════════════════════════════════════════════════════════

def stage_mlir(quantized, out_dir: Path, *, output_type: str, fuse: bool,
               verbose: bool = True):
    """Import to MLIR and report the evidence counts. Returns ``ImportResult``."""
    import torch

    from .quantize_pt2e_flow import INPUT_SHAPE
    from .torch_import import import_to_mlir

    example = torch.randn(*INPUT_SHAPE)
    result = import_to_mlir(quantized.module, example, out_dir,
                            output_type=output_type, fuse=fuse, verbose=False)

    if verbose:
        tev = result.evidence.get("torch", {})
        print(f"[4/5] mlir   : {result.paths['torch'].name} | "
              f"{tev.get('quantize_per_tensor', 0)} quantize_per_tensor, "
              f"{tev.get('int8_literal', 0)} int8 weight literals")
        unmatched = result.evidence.get("raw", {}).get("unmatched_custom", 0)
        if unmatched:
            print(f"[4/5]          {unmatched} unmatched torch.operator customs")
        if fuse:
            fev = result.evidence.get("fused", {})
            qint8 = fev.get("fused_qint8", 0)
            if result.fusion_error:
                # A crashed pass also leaves 0 fused ops, so say which it was.
                note = f"FAILED -- {result.fusion_error}"
            elif qint8:
                note = f"{qint8} qint8 values"
            else:
                note = "no-op (upstream matcher wants the unregistered op form)"
            print(f"[4/5]          fuse: {note}")
        print(f"[5/5] {output_type:<6} : {result.summary()}")
        print(f"[5/5]          -> {result.paths['final']}")
    return result


def compare_topk(quantized, images: Optional[Sequence], topk: int = 5,
                 verbose: bool = True) -> dict:
    """fp32 vs int8 top-*k* on the calibration image.

    A class index alone hides the small numeric drift a miscompiled kernel
    produces, so logits are printed too -- the bar ``tvmrelay``'s
    ``onnx_ptq.compare_topk`` sets.
    """
    import torch

    from .quantize_pt2e_flow import calibration_tensors

    try:
        tensor = calibration_tensors(images, verbose=False)[0]
        labels = _labels()
    except Exception as exc:
        if verbose:
            print(f"[5/5]          accuracy check skipped: {str(exc)[:120]}")
        return {}

    def top(mod):
        with torch.no_grad():
            out = mod(tensor)
        vals, idx = torch.topk(out.flatten().float(), topk)
        return [(int(i), labels[int(i)] if labels else str(int(i)), float(v))
                for v, i in zip(vals, idx)]

    fp32, int8 = top(quantized.fp32_module), top(quantized.module)
    same_top1 = fp32[0][0] == int8[0][0]
    same_order = [a[0] for a in fp32] == [b[0] for b in int8]

    if verbose:
        verdict = "top-1 match" if same_top1 else "TOP-1 CHANGED"
        order = "order identical" if same_order else "2-5 reordered"
        print(f"[5/5] check  : fp32 vs int8 -- {verdict}, {order}")
        for rank, ((fi, fl, fv), (qi, ql, qv)) in enumerate(zip(fp32, int8), 1):
            print(f"[5/5]          {rank}. fp32 {fi:>4} {fl[:24]:<24} {fv:8.4f}"
                  f"  | int8 {qi:>4} {ql[:24]:<24} {qv:8.4f}")

    return {"same_top1": same_top1, "same_order": same_order,
            "fp32": fp32, "int8": int8}


def _labels() -> list:
    """ImageNet class names, or ``[]`` when unavailable."""
    try:
        from .quantize_pt2e_flow import _classify_mod

        classify = _classify_mod()
        path = classify.resolve(None, classify.DEFAULT_LABELS_URL,
                                "imagenet_classes.txt")
        return classify.load_labels(path)
    except Exception:
        return []


# ═══════════════════════════════════════════════════════════════════════════
#  Orchestration
# ═══════════════════════════════════════════════════════════════════════════

def run(out_dir: Path = DEFAULT_OUT, *, images: Optional[Sequence] = None,
        per_channel: bool = True, observer: str = "histogram",
        output_type: str = "linalg", fuse: bool = True,
        accuracy: bool = True, verbose: bool = True) -> dict:
    """Run every stage. Returns a result dict; ``None`` for what did not run."""
    if not stage_env(verbose=verbose):
        return {"ok": False, "stage": "env"}

    out_dir = Path(out_dir)
    quantized = stage_quantize(images, per_channel=per_channel,
                               observer=observer, verbose=verbose)
    try:
        imported = stage_mlir(quantized, out_dir, output_type=output_type,
                              fuse=fuse, verbose=verbose)
    except RuntimeError as exc:
        # A backend that cannot legalize the graph is a real answer, not a
        # crash: the earlier artifacts are written and worth keeping.
        print(f"[5/5] {output_type:<6} : FAILED -- {exc}", file=sys.stderr)
        return {"ok": False, "stage": output_type, "out_dir": str(out_dir),
                "error": str(exc), "annotations": quantized.counts}
    acc = compare_topk(quantized, images, verbose=verbose) if accuracy else {}

    ok = imported.ok
    if verbose:
        note = "" if ok else "  (WARNING: no int8 evidence in the final IR)"
        print(f"\ndone: {output_type} MLIR in {out_dir}{note}")
        for key, path in imported.paths.items():
            print(f"      {key:<6} {path}")

    return {
        "ok": ok,
        "out_dir": str(out_dir),
        "artifacts": {k: str(v) for k, v in imported.paths.items()},
        "evidence": imported.evidence,
        "annotations": quantized.counts,
        "quant_ops": quantized.quant_ops,
        "calib_count": quantized.calib_count,
        "output_type": output_type,
        "accuracy": acc or None,
    }


def main(argv: Optional[Sequence[str]] = None) -> int:
    """CLI. ``0`` ok, ``1`` the flow ran but failed, ``2`` bad arguments."""
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--out-dir", type=Path, default=DEFAULT_OUT,
                    help=f"output directory (default: {DEFAULT_OUT})")
    ap.add_argument("--image", default=None,
                    help="calibration image path or URL (default: the cached "
                         "pytorch/hub dog photo)")
    ap.add_argument("--calib-images", default=None,
                    help="comma-separated calibration images; overrides --image")
    ap.add_argument("--observer", choices=OBSERVERS, default="histogram",
                    help="activation observer (default: histogram; minmax "
                         "matches the tvmrelay ONNX PTQ path)")
    ap.add_argument("--per-tensor", action="store_true",
                    help="per-tensor instead of per-channel weight scales")
    ap.add_argument("--output-type", choices=OUTPUT_TYPES, default="linalg",
                    help="final artifact dialect (default: linalg)")
    ap.add_argument("--no-fuse", action="store_true",
                    help="skip the quantized-op fusion passes (they are no-ops "
                         "on current torch-mlir; see README)")
    ap.add_argument("--no-accuracy", action="store_true",
                    help="skip the fp32-vs-int8 top-5 comparison")
    ap.add_argument("--quiet", action="store_true", help="suppress stage output")
    args = ap.parse_args(argv)

    images = None
    if args.calib_images:
        images = [s.strip() for s in args.calib_images.split(",") if s.strip()]
        if not images:
            print(f"error: --calib-images {args.calib_images!r} lists no images",
                  file=sys.stderr)
            return 2
    elif args.image:
        images = [args.image]

    try:
        result = run(args.out_dir, images=images,
                     per_channel=not args.per_tensor, observer=args.observer,
                     output_type=args.output_type, fuse=not args.no_fuse,
                     accuracy=not args.no_accuracy, verbose=not args.quiet)
    except KeyboardInterrupt:
        print("interrupted", file=sys.stderr)
        return 130

    return 0 if result.get("ok") else 1


if __name__ == "__main__":
    raise SystemExit(main())
