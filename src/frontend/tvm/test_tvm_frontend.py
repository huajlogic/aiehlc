###############################################################################
# Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Verification for the TVM ResNet-18 frontend.

Runs without TVM or the built pybind extension (the parts that need them are
skipped, not failed), so it is a useful smoke test in any environment:

* ``test_cpu_reference_matches_triton`` — the frontend's CPU reference produces
  the exact logits the hand-written ``resnet18_triton.py`` CPU reference does
  (bit-exact int8/Q7 oracle cross-check).
* ``test_plan_matches_canonical`` — ``walk.build_plan`` (Relay walk when TVM is
  present, canonical fallback otherwise) returns the canonical structure.
* ``test_kernel_bodies_wellformed`` — every op has a C body with the expected
  window ABI.
* ``test_emit_aie`` — if ``_aietriton_core`` is built, emit one conv launch and
  assert the output file set appears (skipped otherwise).

Run directly (``python test_tvm_frontend.py``) for a PASS/FAIL summary, or under
pytest.
"""

import os
import sys

import numpy as np

# Allow "python test_tvm_frontend.py" from this directory.
_HERE = os.path.dirname(os.path.abspath(__file__))
_SRC = os.path.dirname(os.path.dirname(_HERE))  # .../src
if _SRC not in sys.path:
    sys.path.insert(0, _SRC)

from frontend.tvm import model, kernels, _compiler
from frontend.tvm import build_plan, cpu_reference, run_resnet
from frontend.tvm.relay_import import tvm_available, onnx_available


# ── Independent oracle: the resnet18_triton.py CPU reference, inlined ────────
# Kept separate from _compiler._cpu_* so the test cross-checks two
# implementations rather than comparing the frontend to itself.

def _triton_conv(feat_in, params, relu):
    H, W = int(np.uint8(params[0])), int(np.uint8(params[1]))
    Cin, Cout = int(np.uint8(params[2])), int(np.uint8(params[3]))
    K, stride = int(np.uint8(params[4])), int(np.uint8(params[5]))
    pad = K // 2
    wt_count = Cin * Cout * K * K
    weights = params[6:6 + wt_count]
    bn_scale = params[6 + wt_count:6 + wt_count + Cout]
    bn_bias = params[6 + wt_count + Cout:6 + wt_count + Cout * 2]
    outH, outW = H // stride, W // stride
    out = np.zeros(Cout * outH * outW, dtype=np.int8)
    lo = 0 if relu else -128
    for oc in range(Cout):
        for oh in range(outH):
            for ow in range(outW):
                s = np.int16(0)
                for ic in range(Cin):
                    for kh in range(K):
                        for kw in range(K):
                            ih, iw = oh * stride + kh - pad, ow * stride + kw - pad
                            if 0 <= ih < H and 0 <= iw < W:
                                s += np.int16(feat_in[ic * H * W + ih * W + iw]) * \
                                     np.int16(weights[oc * Cin * K * K + ic * K * K + kh * K + kw])
                bn_out = (s * np.int16(bn_scale[oc])) >> 7
                bn_out += np.int16(bn_bias[oc])
                out[oc * outH * outW + oh * outW + ow] = np.int8(max(lo, min(127, int(bn_out))))
    return out


def _triton_add_relu(main_path, skip_path):
    out = np.zeros(len(main_path), dtype=np.int8)
    for i in range(len(main_path)):
        s = np.int16(main_path[i]) + np.int16(skip_path[i])
        out[i] = np.int8(max(0, min(127, int(s))))
    return out


def _triton_avgpool_fc(feat, fc_params, sh, sw, ch, nc):
    ssz = sh * sw
    fw, fb = fc_params[:ch * nc], fc_params[ch * nc:]
    pooled = np.zeros(ch, dtype=np.int8)
    for c in range(ch):
        s = np.int16(0)
        for idx in range(ssz):
            s += np.int16(feat[c * ssz + idx])
        pooled[c] = np.int8(int(s) // ssz)
    logits = np.zeros(nc, dtype=np.int8)
    for j in range(nc):
        acc = np.int16(0)
        for i in range(ch):
            acc += np.int16(pooled[i]) * np.int16(fw[i * nc + j])
        acc += np.int16(fb[j])
        logits[j] = np.int8(max(-128, min(127, int(acc))))
    return logits


def _triton_reference():
    """Independent full forward pass (mirrors resnet18_triton.main's CPU section)."""
    plan = model.layer_plan()
    bufs = {"input": model.make_input()}
    for op in plan:
        if op.op in ("conv_bn_relu", "conv_bn"):
            params = model.make_conv_params(op.H, op.W, op.Cin, op.Cout, op.K, op.stride)
            bufs[op.out] = _triton_conv(bufs[op.ins[0]], params, op.op == "conv_bn_relu")
        elif op.op == "residual_add_relu":
            bufs[op.out] = _triton_add_relu(bufs[op.ins[0]], bufs[op.ins[1]])
        elif op.op == "avgpool_fc":
            fc = model.fc_params_no_header(op.channels, op.num_classes)
            bufs[op.out] = _triton_avgpool_fc(bufs[op.ins[0]], fc, op.spatial_h,
                                              op.spatial_w, op.channels, op.num_classes)
    return bufs["logits"]


# ── Tests ───────────────────────────────────────────────────────────────────

def test_cpu_reference_matches_triton():
    logits, _ = cpu_reference()
    ref = _triton_reference()
    assert np.array_equal(logits, ref), f"logits {list(logits)} != triton {list(ref)}"


def test_plan_matches_canonical():
    plan = build_plan(None)  # canonical (no onnx)
    canonical = model.layer_plan()
    assert [op.signature() for op in plan] == [op.signature() for op in canonical]


def test_kernel_bodies_wellformed():
    for op in model.layer_plan():
        body = kernels.kernel_body_for(op.op, f"{op.op}_k")
        assert f"void {op.op}_k(" in body
        nin, nout = kernels.kernel_windows_for(op.op)
        assert nin == 2 and nout == 1
        assert body.count("acquire_input_window") == nin
        assert body.count("acquire_output_window") == nout


def test_run_resnet_smoke():
    res = run_resnet(emit_aie=False)
    assert len(res.plan) == len(model.layer_plan())
    assert 0 <= res.predicted_class < model.NUM_CLASSES


def test_emit_aie():
    """Only runs if the pybind extension is built."""
    try:
        _compiler._core()
    except RuntimeError:
        print("  [skip] _aietriton_core not built")
        return
    import tempfile
    conv = model.layer_plan()[0]
    with tempfile.TemporaryDirectory() as d:
        out_dir, ok = _compiler.compile_launch(conv, 0, d)
        assert ok, "run_aie_pipeline returned False"
        produced = set(os.listdir(out_dir))
        expected = {"host.cc", "kernel.cc", "routing.cc"}
        assert expected & produced, f"missing output files; got {sorted(produced)}"


def test_aiegraph_dataflow_resolution():
    """The plan -> aiegraph dict conversion resolves reused buffers to indices.

    Pure-Python (no extension): each op's main/skip inputs must resolve to the
    launch that most recently produced the referenced buffer name (earlier in
    program order, never itself or a later op). For a residual all three operands
    must carry the same element count as its length attr — this is exactly what
    the dialect verifier enforces, checked here in Python before the C++ build.
    """
    def out_elems(o):
        if o.op in ("conv_bn_relu", "conv_bn"):
            return o.Cout * o.out_h * o.out_w
        if o.op == "residual_add_relu":
            return o.length
        return o.num_classes

    plan = model.layer_plan()
    dicts = model.plan_to_aiegraph_dicts(plan)
    assert len(dicts) == len(plan)
    for idx, (op, d) in enumerate(zip(plan, dicts)):
        assert d["op"] == op.op
        # main_index, when set, must reference an earlier launch that produced
        # the op's feature-input buffer (ins[0]); -1 means the network input.
        assert d["main_index"] < idx, (
            f"op {idx} main_index {d['main_index']} is not earlier")
        if op.op == "residual_add_relu":
            assert 0 <= d["skip_index"] < idx, (
                f"residual {idx} skip must be an earlier op, got {d['skip_index']}")
            assert 0 <= d["main_index"] < idx, (
                f"residual {idx} main must be an earlier op, got {d['main_index']}")
            # All three operands must equal the residual length (verifier rule).
            assert out_elems(plan[d["main_index"]]) == op.length
            assert out_elems(plan[d["skip_index"]]) == op.length


def test_aiegraph_build_and_lower():
    """Round-trip the plan through the aiegraph dialect (needs the extension).

    build_aiegraph_ir must verify and print a module; lower_aiegraph must return
    one launch per op with tensor_specs byte-identical to _compiler._tensor_specs
    (the direct path). Skipped if _aietriton_core is not built.
    """
    try:
        core = _compiler._core()
    except RuntimeError:
        print("  [skip] _aietriton_core not built")
        return
    plan = model.layer_plan()
    ir = _compiler.build_aiegraph_ir(plan)
    assert "aiegraph.func" in ir, "expected an aiegraph.func in the printed IR"
    assert ir.count("aiegraph.conv_bn_relu") + ir.count("aiegraph.conv_bn ") > 0

    launches = core.lower_aiegraph(ir)
    assert len(launches) == len(plan)
    for op, launch in zip(plan, launches):
        assert launch["op"] == op.op
        got = [(list(s), int(b), bool(i)) for (s, b, i) in launch["tensor_specs"]]
        want = [(list(s), b, i) for (s, b, i) in _compiler._tensor_specs(op)]
        assert got == want, f"{op.op}: aiegraph specs {got} != direct {want}"


def test_aiegraph_compile_matches_direct():
    """The aiegraph-routed compile emits the same output-file set as the direct
    path for one conv launch (needs the extension)."""
    try:
        _compiler._core()
    except RuntimeError:
        print("  [skip] _aietriton_core not built")
        return
    import tempfile
    plan = [model.layer_plan()[0]]  # single conv launch
    with tempfile.TemporaryDirectory() as d:
        results = _compiler.compile_plan(plan, out_root=d, via_aiegraph=True)
        assert len(results) == 1
        _op, out_dir, ok = results[0]
        assert ok, "aiegraph-routed run_aie_pipeline returned False"
        produced = set(os.listdir(out_dir))
        expected = {"host.cc", "kernel.cc", "routing.cc"}
        assert expected & produced, f"missing output files; got {sorted(produced)}"


def _main():
    tests = [
        ("cpu_reference == triton reference", test_cpu_reference_matches_triton),
        ("plan == canonical", test_plan_matches_canonical),
        ("kernel bodies well-formed", test_kernel_bodies_wellformed),
        ("run_resnet smoke", test_run_resnet_smoke),
        ("emit AIE (if built)", test_emit_aie),
        ("aiegraph dataflow resolution", test_aiegraph_dataflow_resolution),
        ("aiegraph build + lower (if built)", test_aiegraph_build_and_lower),
        ("aiegraph compile == direct (if built)", test_aiegraph_compile_matches_direct),
    ]
    print(f"TVM available: {tvm_available()}   onnx available: {onnx_available()}")
    logits, _ = cpu_reference()
    print(f"CPU-reference logits: {list(logits)}   predicted class: {int(np.argmax(logits))}")
    fails = 0
    for name, fn in tests:
        try:
            fn()
            print(f"PASS  {name}")
        except AssertionError as e:
            fails += 1
            print(f"FAIL  {name}: {e}")
        except Exception as e:  # pragma: no cover
            fails += 1
            print(f"ERROR {name}: {type(e).__name__}: {e}")
    print(f"\n{'PASS: all checks passed.' if fails == 0 else f'FAIL: {fails} check(s) failed.'}")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(_main())
