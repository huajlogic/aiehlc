###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Unit tests that run **without** torch, torchvision or torch-mlir.

The real flow needs ~2.5 GB of dependencies and minutes per run, so the parts
that are plain Python -- the PT2E import resolver, the IR evidence counters, the
provisioner's probe parsing, CLI validation -- are tested here against fixtures
and injected fake modules.

    PYTHONPATH=src python -m pytest src/frontend/pytorchmlir/unitest/ -v

The end-to-end test is opt-in, because it downloads weights and takes minutes::

    AIEHLC_PYTORCHMLIR_E2E=1 PYTHONPATH=src python -m pytest \\
        src/frontend/pytorchmlir/unitest/ -v -k e2e
"""

from __future__ import annotations

import json
import os
import sys
import types
from pathlib import Path

import pytest

_SRC = Path(__file__).resolve().parents[3]
if str(_SRC) not in sys.path:
    sys.path.insert(0, str(_SRC))

from frontend.pytorchmlir import torch_deps  # noqa: E402
from frontend.pytorchmlir import torch_import  # noqa: E402


# ═══════════════════════════════════════════════════════════════════════════
#  IR evidence counting
# ═══════════════════════════════════════════════════════════════════════════

#: A trimmed but real stage-02 dump: int8 weights, per-channel dequant, a
#: quantized activation. Taken from an actual ResNet-18 run.
TORCH_IR_FIXTURE = """
  %1 = torch.vtensor.literal(dense_resource<w> : tensor<64x3x7x7xsi8>) : !torch.vtensor<[64,3,7,7],si8>
  %2 = torch.vtensor.literal(dense_resource<s> : tensor<64xf32>) : !torch.vtensor<[64],f32>
  %4 = torch.quantized_decomposed.dequantize_per_channel %1, %2, %3, %int0, %int-127, %int127, %int1, %none : !torch.vtensor<[64,3,7,7],si8>
  %5 = torch.quantized_decomposed.quantize_per_tensor %arg0, %float, %int6, %int-128, %int127, %int1 : !torch.vtensor<[1,3,224,224],f32>
  %6 = torch.quantized_decomposed.dequantize_per_tensor %5, %float, %int6, %int-128, %int127, %int1, %none : !torch.vtensor<[1,3,224,224],si8>
"""

#: The linalg artifact: a plain conv plus explicit dequant arithmetic. Note the
#: absence of any ``linalg.*_q`` op -- that is the documented upstream gap.
LINALG_IR_FIXTURE = """
  %3 = linalg.conv_2d_nchw_fchw {dilations = dense<1>} ins(%0, %1 : tensor<1x3x224x224xf32>, tensor<64x3x7x7xf32>)
      %4 = arith.extsi %in : i8 to i64
      %5 = arith.subi %4, %c6_i64 : i64
      %8 = arith.mulf %7, %6 : f32
"""

#: What the IR would look like if quantization silently reverted to fp32 -- the
#: failure this whole counting apparatus exists to catch.
FP32_REGRESSION_FIXTURE = """
  %1 = torch.vtensor.literal(dense_resource<w> : tensor<64x3x7x7xf32>) : !torch.vtensor<[64,3,7,7],f32>
  %3 = torch.aten.convolution %0, %1 : !torch.vtensor<[1,3,224,224],f32>
"""


def test_counts_quantization_evidence():
    counts = torch_import.count_evidence(TORCH_IR_FIXTURE)
    assert counts["quantize_per_tensor"] == 1
    assert counts["dequantize_per_channel"] == 1
    assert counts["int8_literal"] == 1
    assert counts["unmatched_custom"] == 0


def test_counts_linalg_int8_arithmetic():
    counts = torch_import.count_evidence(LINALG_IR_FIXTURE)
    assert counts["conv_nchw"] == 1
    assert counts["extsi_i8"] == 1
    # The documented gap: no fused *_q ops on current torch-mlir.
    assert counts["fused_conv_q"] == 0
    assert counts["fused_qint8"] == 0


def test_detects_silent_fp32_regression():
    """An fp32 graph must show zero int8 evidence -- it parses and lowers fine."""
    counts = torch_import.count_evidence(FP32_REGRESSION_FIXTURE)
    assert counts["int8_literal"] == 0
    assert counts["quantize_per_tensor"] == 0


def test_counts_unmatched_custom_ops():
    ir = '%0 = torch.operator "torch.quantized_decomposed.quantize_per_tensor"(%a)'
    assert torch_import.count_evidence(ir)["unmatched_custom"] == 1


def _result(torch_ev: dict, final_ev: dict, **kw):
    return torch_import.ImportResult(
        paths={}, evidence={"torch": torch_ev, "final": final_ev},
        fused=kw.pop("fused", False), output_type=kw.pop("output_type", "linalg"),
        **kw)


def test_fusion_error_is_recorded_not_just_printed():
    """A crashed fusion pass and the benign upstream no-op both leave 0 fused
    ops, so the error text is the only thing that tells them apart."""
    crashed = _result({}, {}, fusion_error="RuntimeError: bad pass name")
    benign = _result({}, {})
    assert crashed.fusion_error and not crashed.fused
    assert benign.fusion_error is None


def test_output_type_reports_the_backend():
    """It must name the backend, not the internal evidence key."""
    assert _result({}, {}, output_type="tosa").output_type == "tosa"


def test_import_result_ok_on_native_int8_path():
    """ok must not require the fused ops -- they are 0 on every current build."""
    assert _result(
        torch_import.count_evidence(TORCH_IR_FIXTURE),
        torch_import.count_evidence(LINALG_IR_FIXTURE),
    ).ok


def test_import_result_not_ok_when_quantization_lost():
    assert not _result(
        torch_import.count_evidence(FP32_REGRESSION_FIXTURE),
        torch_import.count_evidence(LINALG_IR_FIXTURE),
    ).ok


def test_summary_flags_the_upstream_gap():
    summary = _result(
        torch_import.count_evidence(TORCH_IR_FIXTURE),
        torch_import.count_evidence(LINALG_IR_FIXTURE),
    ).summary()
    assert "upstream gap" in summary


#: A TOSA lowering: same int8 graph, entirely different op set.
TOSA_IR_FIXTURE = """
  %240 = tosa.conv2d %238, %239, %19, %42, %42 {acc_type = f32} : (tensor<1x224x224x3xi8>, tensor<64x7x7x3xi8>)
  %18 = "tosa.const"() <{values = dense_resource<w> : tensor<1000x512xi8>}> : () -> tensor<1000x512xi8>
"""


def test_counts_tosa_int8():
    """``xi8>``, not ``\\bi8\\b`` -- MLIR writes ``tensor<1000x512xi8>``, and a
    word boundary before ``i8`` never matches because ``x`` is a word char.
    That regex bug reported a perfectly good TOSA lowering as having no int8."""
    counts = torch_import.count_evidence(TOSA_IR_FIXTURE)
    assert counts["tosa_conv"] == 1
    # Two int8 tensors on the conv line (input + weights), two on the const line.
    assert counts["tosa_i8"] == 4


def test_import_result_ok_on_tosa_backend():
    """`ok` must not be linalg-only -- TOSA carries int8 in its own ops."""
    assert _result(
        torch_import.count_evidence(TORCH_IR_FIXTURE),
        torch_import.count_evidence(TOSA_IR_FIXTURE),
    ).ok


def test_summary_switches_on_backend():
    summary = _result(
        torch_import.count_evidence(TORCH_IR_FIXTURE),
        torch_import.count_evidence(TOSA_IR_FIXTURE),
    ).summary()
    assert "tosa.conv2d" in summary
    assert "conv_2d_nchw_fchw" not in summary


def test_artifact_keys_are_unique():
    """A duplicated key would overwrite an earlier dump (the 'torch' collision)."""
    keys = [k for k, _ in torch_import.ARTIFACTS]
    assert len(keys) == len(set(keys))
    assert "final" in keys


# ═══════════════════════════════════════════════════════════════════════════
#  PT2E resolver
# ═══════════════════════════════════════════════════════════════════════════

def _fake_pt2e_tree(monkeypatch, name: str):
    """Install a minimal importable PT2E tree named *name*."""
    quantize = types.ModuleType(f"{name}.quantize_pt2e")
    quantize.prepare_pt2e = lambda *a, **k: None
    quantize.convert_pt2e = lambda *a, **k: None

    quantizer = types.ModuleType(f"{name}.quantizer")
    quantizer.Quantizer = type("Quantizer", (), {})
    quantizer.QuantizationSpec = type("QuantizationSpec", (), {})
    quantizer.QuantizationAnnotation = type("QuantizationAnnotation", (), {})

    observers = types.ModuleType(f"{name}.observer")
    observers.MinMaxObserver = type("MinMaxObserver", (), {})

    return {f"{name}.quantize_pt2e": quantize,
            f"{name}.quantizer": quantizer,
            f"{name}.observer": observers}


def test_resolver_prefers_torchao(monkeypatch):
    """When both trees import, torchao must win over the deprecated torch.ao."""
    modules = {}
    modules.update(_fake_pt2e_tree(monkeypatch, "torchao.quantization.pt2e"))
    modules.update(_fake_pt2e_tree(monkeypatch, "torch.ao.quantization"))

    def fake_import(path):
        return modules.get(path)

    monkeypatch.setattr(torch_deps, "_try_import", fake_import)
    api = torch_deps.pt2e_api(refresh=True)
    assert api.provenance == "torchao"


def test_resolver_falls_back_to_torch_ao(monkeypatch):
    modules = _fake_pt2e_tree(monkeypatch, "torch.ao.quantization")

    monkeypatch.setattr(torch_deps, "_try_import", lambda p: modules.get(p))
    api = torch_deps.pt2e_api(refresh=True)
    assert api.provenance == "torch.ao"
    assert "MinMaxObserver" in api.observers


def test_annotation_symbols_resolve_from_the_winning_tree(monkeypatch):
    """The quantizer must not hardcode torchao -- doing so crashes on exactly
    the torch.ao fallback, and only *after* stage 1 reports a healthy env."""
    modules = _fake_pt2e_tree(monkeypatch, "torch.ao.quantization")
    quantizer = modules["torch.ao.quantization.quantizer"]
    quantizer.QuantizationConfig = type("QuantizationConfig", (), {})
    quantizer.get_weight_qspec = lambda cfg: None

    monkeypatch.setattr(torch_deps, "_try_import", lambda p: modules.get(p))
    api = torch_deps.pt2e_api(refresh=True)
    assert api.annotation["QuantizationConfig"] is quantizer.QuantizationConfig
    assert "get_weight_qspec" in api.annotation
    # Older trees have no Q_ANNOTATION_KEY constant; the literal is the default.
    assert api.annotation["Q_ANNOTATION_KEY"] == "quantization_annotation"


def test_missing_annotation_symbol_names_the_tree(monkeypatch):
    from frontend.pytorchmlir.npu_quantizer import _annotation_symbol

    api = torch_deps.Pt2eApi(
        prepare_pt2e=lambda *a: None, convert_pt2e=lambda *a: None,
        Quantizer=object, QuantizationSpec=object,
        QuantizationAnnotation=object, annotation={}, provenance="torch.ao")
    with pytest.raises(RuntimeError) as exc:
        _annotation_symbol(api, "get_weight_qspec")
    assert "torch.ao" in str(exc.value)
    assert "get_weight_qspec" in str(exc.value)


def test_annotated_patterns_matches_what_the_code_emits():
    """ANNOTATED_PATTERNS is the documented contract for `counts` keys; it drifted
    once already (it listed a conv+bn+relu pattern PT2E folds away first)."""
    from frontend.pytorchmlir.npu_quantizer import ANNOTATED_PATTERNS

    assert "conv2d + bn + relu" not in ANNOTATED_PATTERNS
    assert set(ANNOTATED_PATTERNS) == {
        "conv2d + relu", "conv2d", "linear", "add + relu", "add",
        "adaptive_avg_pool2d"}


def test_resolver_reports_every_tree_tried(monkeypatch):
    monkeypatch.setattr(torch_deps, "_try_import", lambda p: None)
    with pytest.raises(ImportError) as exc:
        torch_deps.pt2e_api(refresh=True)
    assert "torchao" in str(exc.value) and "torch.ao" in str(exc.value)


@pytest.fixture(autouse=True)
def _clear_api_cache():
    """The resolver caches; tests must not leak a fake API into each other."""
    yield
    torch_deps._API_CACHE = None


# ═══════════════════════════════════════════════════════════════════════════
#  Auto-install guards
# ═══════════════════════════════════════════════════════════════════════════

def test_recursion_sentinel_blocks_provisioning(monkeypatch):
    """verify()'s subprocess must never re-enter provisioning."""
    monkeypatch.setenv(torch_deps.PROVISION_SENTINEL, "1")
    assert not torch_deps._auto_install_enabled()


@pytest.mark.parametrize("value", ["0", "false", "no", "off", "OFF"])
def test_auto_install_opt_out(monkeypatch, value):
    monkeypatch.delenv(torch_deps.PROVISION_SENTINEL, raising=False)
    monkeypatch.setenv(torch_deps.AUTO_INSTALL_ENV, value)
    assert not torch_deps._auto_install_enabled()


def test_auto_install_default_on(monkeypatch):
    monkeypatch.delenv(torch_deps.PROVISION_SENTINEL, raising=False)
    monkeypatch.delenv(torch_deps.AUTO_INSTALL_ENV, raising=False)
    assert torch_deps._auto_install_enabled()


# ═══════════════════════════════════════════════════════════════════════════
#  Provisioner
# ═══════════════════════════════════════════════════════════════════════════

def test_probe_parses_sentinel_line(monkeypatch):
    from frontend.pytorchmlir import setup_torchmlir

    payload = {"torch": "2.10.0", "torchvision": "0.25.0",
               "torchao": None, "torch_mlir": "20261001", "error": ""}

    class _Proc:
        stdout = "noise\n@@PROBE@@" + json.dumps(payload) + "\nmore noise"
        stderr = ""
        returncode = 0

    monkeypatch.setattr(setup_torchmlir.subprocess, "run",
                        lambda *a, **k: _Proc())
    inst = setup_torchmlir.detect()
    assert inst.torch == "2.10.0"
    assert inst.complete  # torchao is optional


def test_probe_survives_a_crashing_interpreter(monkeypatch):
    """A segfaulting torch must yield a report, not an exception."""
    from frontend.pytorchmlir import setup_torchmlir

    class _Proc:
        stdout = ""
        stderr = "Segmentation fault"
        returncode = -11

    monkeypatch.setattr(setup_torchmlir.subprocess, "run",
                        lambda *a, **k: _Proc())
    inst = setup_torchmlir.detect()
    assert not inst.complete
    assert "probe crashed" in inst.error


def test_incomplete_when_torch_mlir_missing():
    from frontend.pytorchmlir.setup_torchmlir import Installed

    inst = Installed(torch="2.10.0", torchvision="0.25.0",
                     torchao="0.18.0", torch_mlir=None)
    assert not inst.complete
    assert "MISSING" in inst.describe()


def test_manifest_records_a_restore_command(tmp_path):
    from frontend.pytorchmlir import setup_torchmlir

    inst = setup_torchmlir.Installed(torch="2.10.0", torchvision="0.25.0",
                                     torchao=None, torch_mlir=None)
    setup_torchmlir._record_plan(tmp_path, ["torch-mlir==20261001"], inst,
                                 dry_run=False)
    record = json.loads((tmp_path / setup_torchmlir.MANIFEST_NAME).read_text())
    assert "torch==2.10.0" in record["restore_hint"]
    assert "torchvision==0.25.0" in record["restore_hint"]


def test_dry_run_writes_no_manifest(tmp_path):
    from frontend.pytorchmlir import setup_torchmlir

    inst = setup_torchmlir.Installed(None, None, None, None)
    setup_torchmlir._record_plan(tmp_path, ["torch"], inst, dry_run=True)
    assert not (tmp_path / setup_torchmlir.MANIFEST_NAME).exists()


# ═══════════════════════════════════════════════════════════════════════════
#  CLI
# ═══════════════════════════════════════════════════════════════════════════

def test_cli_rejects_empty_calib_list():
    from frontend.pytorchmlir import deploy_torch

    assert deploy_torch.main(["--calib-images", " , , "]) == 2


def test_cli_rejects_unknown_output_type():
    from frontend.pytorchmlir import deploy_torch

    with pytest.raises(SystemExit) as exc:
        deploy_torch.main(["--output-type", "stablehlo"])
    assert exc.value.code == 2


def test_default_out_dir_is_relative():
    """Matches tvmrelay's DEFAULT_OUT convention."""
    from frontend.pytorchmlir import deploy_torch

    assert not deploy_torch.DEFAULT_OUT.is_absolute()


# ═══════════════════════════════════════════════════════════════════════════
#  Opt-in end-to-end
# ═══════════════════════════════════════════════════════════════════════════

@pytest.mark.skipif(os.environ.get("AIEHLC_PYTORCHMLIR_E2E") != "1",
                    reason="set AIEHLC_PYTORCHMLIR_E2E=1 (downloads weights, minutes)")
def test_e2e_resnet18_emits_int8_mlir(tmp_path):
    from frontend.pytorchmlir import deploy_torch

    result = deploy_torch.run(tmp_path, accuracy=False, verbose=False)
    assert result["ok"]

    torch_ev = result["evidence"]["torch"]
    assert torch_ev["quantize_per_tensor"] > 0
    assert torch_ev["int8_literal"] == 21      # 20 convs + the fc layer
    assert result["evidence"]["final"]["conv_nchw"] == 20
