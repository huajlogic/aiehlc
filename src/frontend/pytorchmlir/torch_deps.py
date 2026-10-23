###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Resolve the PT2E quantization API, which lives in two places depending on age.

PyTorch is migrating ``torch.ao.quantization`` into **torchao**
(`pytorch/ao#2259 <https://github.com/pytorch/ao/issues/2259>`_). The pt2e entry
points exist in both trees today and the ``torch.ao`` copy is scheduled for
deletion in torch 2.10+, so every symbol this package needs is resolved **once,
here**, newest-first::

    torchao.quantization.pt2e.*      preferred
    torch.ao.quantization.*          fallback, deprecated

Nothing else in the package may import ``prepare_pt2e`` / ``convert_pt2e`` /
``Quantizer`` directly. When the migration finishes, this is the one file that
changes.

Why a resolver rather than a hard import
----------------------------------------
Both trees are moving. ``torchao`` 0.18 keeps ``XNNPACKQuantizer`` under
``torchao/testing/pt2e/_xnnpack_quantizer.py`` -- a *private* path inside a
``testing`` package -- while the stable observer/spec types sit in
``torchao.quantization.pt2e``. A hard import of the wrong one breaks on a routine
dependency bump, and the traceback points at an import line rather than at the
real problem. :func:`pt2e_api` instead reports which tree answered, so stage 1 of
the flow prints the provenance and a silent fallback is visible rather than
inferred.

The resolved bundle is cached, so repeated calls are free.
"""

from __future__ import annotations

import importlib
import os
import sys
from dataclasses import dataclass, field
from typing import Any, Callable, Optional

__all__ = [
    "AUTO_INSTALL_ENV",
    "PROVISION_SENTINEL",
    "Pt2eApi",
    "DepStatus",
    "deps_status",
    "ensure_torchmlir",
    "pt2e_api",
    "torch_export_module",
]

#: Set by :func:`setup_torchmlir.verify` in the environment of its own probe
#: subprocess. That probe imports this package, whose import calls
#: :func:`ensure_torchmlir`, which would call ``provision()``, which calls
#: ``verify()`` again -- forever. The sentinel breaks the cycle: while a
#: provision is in flight, never provision.
PROVISION_SENTINEL = "_PYTORCHMLIR_PROVISIONING"

#: Set to ``0``/``false``/``no``/``off`` to make :func:`ensure_torchmlir` report
#: and return instead of installing.
AUTO_INSTALL_ENV = "AIEHLC_TORCH_AUTO_INSTALL"

#: Every module this frontend needs at runtime, in import-failure report order.
REQUIRED_MODULES = ("torch", "torchvision", "torch_mlir")


def _auto_install_enabled() -> bool:
    """True when :func:`ensure_torchmlir` may install. Honors the recursion guard."""
    if os.environ.get(PROVISION_SENTINEL):
        return False  # a provision is already running; do not recurse
    flag = os.environ.get(AUTO_INSTALL_ENV, "1").strip().lower()
    return flag not in ("0", "false", "no", "off")


def _try_import(path: str):
    """Import *path*, returning the module or ``None``. Never raises."""
    try:
        return importlib.import_module(path)
    except Exception:  # ImportError, but also partial-install AttributeErrors
        return None


# ═══════════════════════════════════════════════════════════════════════════
#  PT2E symbol resolution
# ═══════════════════════════════════════════════════════════════════════════

@dataclass(frozen=True)
class Pt2eApi:
    """The PT2E symbols this package uses, plus where they came from.

    ``provenance`` is ``"torchao"`` or ``"torch.ao"`` and is printed by stage 1,
    so a fallback onto the deprecated tree is never silent.

    ``annotation`` carries the symbols the quantizer needs that live on the
    ``quantizer`` package rather than on ``quantize_pt2e`` -- ``QuantizationConfig``,
    the ``get_*_qspec`` helpers, ``SharedQuantizationSpec``, ``Q_ANNOTATION_KEY``.
    They are resolved here, with everything else, so that ``npu_quantizer`` never
    hardcodes a tree: hardcoding ``torchao`` there would crash on exactly the
    ``torch.ao`` fallback this resolver exists to support.
    """

    prepare_pt2e: Callable
    convert_pt2e: Callable
    Quantizer: type
    QuantizationSpec: type
    QuantizationAnnotation: type
    observers: dict = field(default_factory=dict)
    annotation: dict = field(default_factory=dict)
    move_to_eval: Optional[Callable] = None
    provenance: str = "unknown"

    def describe(self) -> str:
        """One line naming the tree that answered and the observers found."""
        obs = ",".join(sorted(self.observers)) or "none"
        return f"pt2e via {self.provenance} (observers: {obs})"


#: ``(quantize_pt2e module, quantizer module, observer module)`` per tree, newest
#: first. Resolution takes the first tree where **all three** import.
_PT2E_TREES = (
    (
        "torchao",
        "torchao.quantization.pt2e.quantize_pt2e",
        "torchao.quantization.pt2e.quantizer",
        "torchao.quantization.pt2e",
    ),
    (
        "torch.ao",
        "torch.ao.quantization.quantize_pt2e",
        "torch.ao.quantization.quantizer",
        "torch.ao.quantization.observer",
    ),
)

#: Annotation-side symbols ``npu_quantizer`` needs. Resolved here so that module
#: never names a tree; see :class:`Pt2eApi`.
_ANNOTATION_NAMES = (
    "QuantizationConfig",
    "SharedQuantizationSpec",
    "get_input_act_qspec",
    "get_output_act_qspec",
    "get_weight_qspec",
    "Q_ANNOTATION_KEY",
)

#: Observer classes pulled from whichever tree answered. Absent names are skipped
#: rather than fatal -- the quantizer only needs the two it actually uses.
_OBSERVER_NAMES = (
    "HistogramObserver",
    "MinMaxObserver",
    "PerChannelMinMaxObserver",
    "MovingAverageMinMaxObserver",
    "MovingAveragePerChannelMinMaxObserver",
)

_API_CACHE: Optional[Pt2eApi] = None


def _resolve_quantizer_types(qmod) -> tuple:
    """``(Quantizer, QuantizationSpec, QuantizationAnnotation)`` from *qmod*.

    The three types are re-exported from the ``quantizer`` package in both trees,
    but torchao also keeps them in a ``quantizer.quantizer`` submodule. Try the
    package first, then the submodule.
    """
    candidates = [qmod]
    nested = _try_import(qmod.__name__ + ".quantizer")
    if nested is not None:
        candidates.append(nested)

    for mod in candidates:
        got = tuple(getattr(mod, n, None) for n in
                    ("Quantizer", "QuantizationSpec", "QuantizationAnnotation"))
        if all(g is not None for g in got):
            return got
    raise ImportError(
        f"{qmod.__name__} exposes no Quantizer/QuantizationSpec/QuantizationAnnotation"
    )


def pt2e_api(refresh: bool = False) -> Pt2eApi:
    """Resolve the PT2E API, preferring torchao. Cached after the first call.

    Raises ``ImportError`` naming every tree tried when none works -- a single
    message listing the attempts beats three separate tracebacks.
    """
    global _API_CACHE
    if _API_CACHE is not None and not refresh:
        return _API_CACHE

    attempts = []
    for provenance, quant_path, quantizer_path, observer_path in _PT2E_TREES:
        qp = _try_import(quant_path)
        qz = _try_import(quantizer_path)
        if qp is None or qz is None:
            attempts.append(f"{provenance}: {quant_path} or {quantizer_path} missing")
            continue
        try:
            Quantizer, Spec, Annotation = _resolve_quantizer_types(qz)
        except ImportError as exc:
            attempts.append(f"{provenance}: {exc}")
            continue

        obs_mod = _try_import(observer_path)
        observers = {}
        if obs_mod is not None:
            observers = {n: getattr(obs_mod, n) for n in _OBSERVER_NAMES
                         if getattr(obs_mod, n, None) is not None}

        # Annotation helpers: on the quantizer package in both trees, with
        # Q_ANNOTATION_KEY hiding in .utils. Missing names are simply absent
        # from the dict; npu_quantizer reports what it could not find.
        annotation = {}
        for mod in (qz, _try_import(quantizer_path + ".utils")):
            if mod is None:
                continue
            for name in _ANNOTATION_NAMES:
                if name not in annotation and getattr(mod, name, None) is not None:
                    annotation[name] = getattr(mod, name)
        # Pre-torchao trees spell the metadata key as a plain string.
        annotation.setdefault("Q_ANNOTATION_KEY", "quantization_annotation")

        # move_exported_model_to_eval is re-exported from the pt2e *package*
        # (torchao) rather than the quantize_pt2e module, and torch.ao keeps it
        # on quantize_pt2e itself. torchao's export_utils spells it with a
        # leading underscore. Try all four; it is optional and the quantize flow
        # degrades to a plain .eval() without it.
        move = getattr(qp, "move_exported_model_to_eval", None)
        pkg = quant_path.rsplit(".", 1)[0]
        for path, attr in ((pkg, "move_exported_model_to_eval"),
                           (f"{pkg}.export_utils", "move_exported_model_to_eval"),
                           (f"{pkg}.export_utils", "_move_exported_model_to_eval")):
            if move is not None:
                break
            em = _try_import(path)
            move = getattr(em, attr, None) if em is not None else None

        _API_CACHE = Pt2eApi(
            prepare_pt2e=qp.prepare_pt2e,
            convert_pt2e=qp.convert_pt2e,
            Quantizer=Quantizer,
            QuantizationSpec=Spec,
            QuantizationAnnotation=Annotation,
            observers=observers,
            annotation=annotation,
            move_to_eval=move,
            provenance=provenance,
        )
        return _API_CACHE

    raise ImportError("no PT2E implementation found. Tried:\n  " + "\n  ".join(attempts))


# ═══════════════════════════════════════════════════════════════════════════
#  Export capture
# ═══════════════════════════════════════════════════════════════════════════

def torch_export_module(model, example_args: tuple):
    """``(GraphModule, how)`` -- capture *model* for quantization.

    ``export_for_training`` is the PT2E-sanctioned capture and is what the
    torchao tutorials use; it keeps BatchNorm as a separate node so the
    conv+bn fusion patterns still match. Plain ``torch.export.export`` is the
    fallback for older torch, where BN may already be folded.
    """
    import torch

    if hasattr(torch.export, "export_for_training"):
        ep = torch.export.export_for_training(model, example_args)
        return ep.module(), "export_for_training"

    ep = torch.export.export(model, example_args)
    return ep.module(), "export"


# ═══════════════════════════════════════════════════════════════════════════
#  Dependency status / provisioning
# ═══════════════════════════════════════════════════════════════════════════

@dataclass(frozen=True)
class DepStatus:
    """What is importable right now. ``ok`` means the flow can run."""

    ok: bool
    versions: dict
    missing: tuple

    def describe(self) -> str:
        """``torch 2.10.0+cu128 | torchvision 0.25.0 | torch-mlir 20261001``."""
        if self.missing:
            return "missing: " + ", ".join(self.missing)
        return " | ".join(f"{k} {v}" for k, v in self.versions.items())


def _module_version(mod, dist_name: str) -> str:
    """Version of *mod*, falling back to installed-distribution metadata.

    ``torch_mlir`` defines no ``__version__`` -- its wheel carries the date-stamped
    version (``20261001``) only in package metadata -- so reading the attribute
    alone reports every torch-mlir as "unknown".
    """
    version = getattr(mod, "__version__", None)
    if version:
        return str(version)
    try:
        import importlib.metadata as md

        return md.version(dist_name)
    except Exception:
        return "unknown"


def deps_status() -> DepStatus:
    """Check the runtime deps **in this process**, with no side effects."""
    versions, missing = {}, []
    for name in REQUIRED_MODULES:
        mod = _try_import(name)
        if mod is None:
            missing.append(name)
            continue
        dist = name.replace("_", "-")
        versions[dist] = _module_version(mod, dist)
    return DepStatus(ok=not missing, versions=versions, missing=tuple(missing))


def ensure_torchmlir(auto_install: Optional[bool] = None,
                     verbose: bool = True) -> bool:
    """Make torch/torchvision/torch-mlir importable. Returns True when usable.

    Called at package import. On a healthy environment this costs one import of
    each module. Otherwise it provisions -- which installs packages -- so it
    announces itself on stderr first. ``AIEHLC_TORCH_AUTO_INSTALL=0`` downgrades
    that to a report.
    """
    status = deps_status()
    if status.ok:
        return True

    if auto_install is None:
        auto_install = _auto_install_enabled()

    if not auto_install:
        if verbose:
            print(f"[pytorchmlir] {status.describe()}; auto-install disabled.\n"
                  f"[pytorchmlir] install with: python src/frontend/pytorchmlir/"
                  f"setup_torchmlir.py --yes", file=sys.stderr)
        return False

    if verbose:
        print(f"[pytorchmlir] {status.describe()} -- provisioning "
              f"(set {AUTO_INSTALL_ENV}=0 to disable)", file=sys.stderr)

    try:
        from . import setup_torchmlir
    except ImportError:  # running as a loose script rather than a package
        import setup_torchmlir  # type: ignore

    try:
        setup_torchmlir.provision(assume_yes=True)
    except Exception as exc:
        if verbose:
            print(f"[pytorchmlir] provisioning failed: {exc}", file=sys.stderr)
        return False

    importlib.invalidate_caches()
    for stale in [m for m in sys.modules if m.split(".")[0] in REQUIRED_MODULES]:
        del sys.modules[stale]
    return deps_status().ok
