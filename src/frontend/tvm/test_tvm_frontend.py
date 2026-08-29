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

from frontend.tvm import model, kernels, _compiler, cpu_codegen
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


def test_orchestrate_conv_layer_appends():
    """orchestrate_conv_layer appends host_canonicalized_<suffix> into ONE host.cc."""
    try:
        core = _compiler._core()
    except Exception as e:
        print("SKIP (pybind not built):", e); return
    import tempfile
    plan = build_plan(None)
    launches = core.lower_aiegraph(_compiler.build_aiegraph_ir(plan))
    convs = [(op, L) for op, L in zip(plan, launches) if cpu_codegen.is_aie_op(op.op)][:2]
    with tempfile.TemporaryDirectory() as d:
        for i, (op, L) in enumerate(convs):
            specs = [(list(s), int(b), bool(x)) for (s, b, x) in L["tensor_specs"]]
            body = kernels.kernel_body_for(op.op, L["func_name"])
            n = core.orchestrate_conv_layer(2, 2, specs, d, body, L["func_name"],
                                            host_func_suffix=L["func_name"],
                                            append_mode=(i > 0))
            assert isinstance(n, int) and n >= 1
        host = open(os.path.join(d, "host.cc")).read()
        for _, L in convs:
            assert f"host_canonicalized_{L['func_name']}(" in host
        assert host.count("host_canonicalized_") >= 2


def test_cpu_codegen_bit_exact():
    """TVM CPU codegen is bit-exact with the numpy Q7 oracle.

    Builds the SAME TE ``cpu_codegen`` emits, runs it on ``target="llvm"`` over
    random int8 inputs, and asserts elementwise equality with
    ``_compiler._cpu_add_relu`` / ``_compiler._cpu_avgpool_fc``. Also asserts the
    emitted ``target="c"`` source carries the requested entry name. Skipped if
    TVM is unavailable.
    """
    if not cpu_codegen.available():
        print("  [skip] TVM not available for cpu_codegen")
        return
    import tvm

    rng = np.random.default_rng(0)
    dev = tvm.cpu()

    # residual_add_relu: full int8 range on both inputs.
    n = 40
    res_op = model.LayerOp(op="residual_add_relu", out="o",
                           ins=["a", "b"], length=n)
    rmod, _ = cpu_codegen.build_llvm(res_op, "residual_add_relu_k")
    a = rng.integers(-128, 128, n).astype(np.int8)
    b = rng.integers(-128, 128, n).astype(np.int8)
    ro = tvm.runtime.tensor(np.zeros(n, np.int8), dev)
    rmod(tvm.runtime.tensor(a, dev), tvm.runtime.tensor(b, dev), ro)
    ref = _compiler._cpu_add_relu(a, b)
    assert np.array_equal(ro.numpy(), ref), \
        f"residual: {list(ro.numpy())} != {list(ref)}"
    src = cpu_codegen.cpu_c_source(res_op, "residual_add_relu_k")
    assert "residual_add_relu_k" in src, "func_name missing from emitted C"

    # avgpool_fc: feature is post-ReLU (>= 0), weights/bias full int8 range.
    sh, sw, ch, nc = 2, 2, 8, 4
    ap_op = model.LayerOp(op="avgpool_fc", out="logits", ins=["f", "params"],
                          spatial_h=sh, spatial_w=sw, channels=ch, num_classes=nc)
    amod, _ = cpu_codegen.build_llvm(ap_op, "avgpool_fc_k")
    feat = rng.integers(0, 128, ch * sh * sw).astype(np.int8)
    wts = rng.integers(-128, 128, ch * nc).astype(np.int8)
    bias = rng.integers(-128, 128, nc).astype(np.int8)
    lo = tvm.runtime.tensor(np.zeros(nc, np.int8), dev)
    amod(tvm.runtime.tensor(feat, dev), tvm.runtime.tensor(wts, dev),
         tvm.runtime.tensor(bias, dev), lo)
    fc = np.concatenate([wts, bias]).astype(np.int8)  # headerless: weights|bias
    ref = _compiler._cpu_avgpool_fc(feat, fc, sh, sw, ch, nc)
    assert np.array_equal(lo.numpy(), ref), \
        f"avgpool_fc: {list(lo.numpy())} != {list(ref)}"
    src = cpu_codegen.cpu_c_source(ap_op, "avgpool_fc_k")
    assert "avgpool_fc_k" in src, "func_name missing from emitted C"


def test_cpu_codegen_rejects_aie_op():
    """CPU codegen refuses conv2d-family ops (they belong to the AIE path)."""
    conv = model.layer_plan()[0]
    assert cpu_codegen.is_aie_op(conv.op)
    try:
        cpu_codegen.op_tensors(conv)
    except ValueError:
        return
    assert False, "expected ValueError for an AIE op on the CPU path"


def test_dispatch_routes_non_conv_to_cpu():
    """The compile dispatch sends conv ops to AIE and non-conv ops to CPU C.

    Runs ``compile_plan_via_aiegraph`` on a small valid sub-plan (three convs +
    one residual): each conv dir must contain the AIE file set (``host.cc``); the
    residual dir must contain ``<func_name>.c`` and NO ``host.cc``. Needs both
    the built ``_aietriton_core`` (conv path) and TVM (CPU path).
    """
    try:
        _compiler._core()
    except RuntimeError:
        print("  [skip] _aietriton_core not built")
        return
    if not cpu_codegen.available():
        print("  [skip] TVM not available for cpu_codegen")
        return
    import tempfile
    sub = model.layer_plan()[:4]  # conv, conv, conv, residual (valid dataflow)
    assert sub[3].op == "residual_add_relu"
    with tempfile.TemporaryDirectory() as d:
        results = _compiler.compile_plan(sub, out_root=d, via_aiegraph=True)
        assert len(results) == 4
        for op, out_dir, ok in results:
            assert ok, f"{op.op} launch failed"
            produced = set(os.listdir(out_dir))
            if cpu_codegen.is_aie_op(op.op):
                assert "host.cc" in produced, \
                    f"conv {out_dir} missing host.cc; got {sorted(produced)}"
                assert not any(f.endswith(".c") for f in produced), \
                    f"conv {out_dir} unexpectedly has a .c file: {sorted(produced)}"
            else:
                assert "host.cc" not in produced, \
                    f"CPU op {out_dir} must not emit host.cc; got {sorted(produced)}"
                assert any(f.endswith(".c") for f in produced), \
                    f"CPU op {out_dir} missing <func_name>.c; got {sorted(produced)}"


def test_plain_c_cpu_bit_exact():
    """plain_c_source emits self-contained C that is bit-exact with the numpy oracle."""
    import shutil, subprocess, ctypes, tempfile
    cc = shutil.which("cc") or shutil.which("gcc")
    if cc is None:
        print("  [skip] no C compiler"); return

    # ── residual_add_relu: length-parametric plain C entry ──────────────────
    res_op = model.LayerOp(op="residual_add_relu", out="o", ins=["a", "b"],
                           length=64)
    src = cpu_codegen.plain_c_source(res_op, "res_test")
    assert "void res_test(" in src
    with tempfile.TemporaryDirectory() as d:
        cpath = os.path.join(d, "res.c"); sopath = os.path.join(d, "res.so")
        open(cpath, "w").write(src)
        subprocess.run([cc, "-shared", "-fPIC", "-O2", cpath, "-o", sopath],
                       check=True)
        lib = ctypes.CDLL(sopath)
        n = 64
        rng = np.random.default_rng(1)
        a = rng.integers(-128, 128, n).astype(np.int8)
        b = rng.integers(-128, 128, n).astype(np.int8)
        out = np.zeros(n, dtype=np.int8)
        p = ctypes.POINTER(ctypes.c_int8)
        lib.res_test(a.ctypes.data_as(p), b.ctypes.data_as(p),
                     out.ctypes.data_as(p), ctypes.c_int(n))
        ref = _compiler._cpu_add_relu(a, b)
        assert np.array_equal(out, ref), f"residual {list(out)} != {list(ref)}"

    # ── avgpool_fc: fixed-geometry plain C entry ────────────────────────────
    sh, sw, ch, nc = 2, 2, 8, 4
    ap_op = model.LayerOp(op="avgpool_fc", out="logits", ins=["f", "params"],
                          spatial_h=sh, spatial_w=sw, channels=ch, num_classes=nc)
    asrc = cpu_codegen.plain_c_source(ap_op, "fc_test")
    assert "void fc_test(" in asrc
    with tempfile.TemporaryDirectory() as d:
        cpath = os.path.join(d, "fc.c"); sopath = os.path.join(d, "fc.so")
        open(cpath, "w").write(asrc)
        subprocess.run([cc, "-shared", "-fPIC", "-O2", cpath, "-o", sopath],
                       check=True)
        lib = ctypes.CDLL(sopath)
        rng = np.random.default_rng(2)
        feat = rng.integers(0, 128, ch * sh * sw).astype(np.int8)   # post-ReLU >=0
        wts = rng.integers(-128, 128, ch * nc).astype(np.int8)
        bias = rng.integers(-128, 128, nc).astype(np.int8)
        out = np.zeros(nc, dtype=np.int8)
        p = ctypes.POINTER(ctypes.c_int8)
        lib.fc_test(feat.ctypes.data_as(p), wts.ctypes.data_as(p),
                    bias.ctypes.data_as(p), out.ctypes.data_as(p))
        fc = np.concatenate([wts, bias]).astype(np.int8)  # headerless: weights|bias
        ref = _compiler._cpu_avgpool_fc(feat, fc, sh, sw, ch, nc)
        assert np.array_equal(out, ref), f"avgpool_fc {list(out)} != {list(ref)}"


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
        ("orchestrate_conv_layer appends (if built)", test_orchestrate_conv_layer_appends),
        ("cpu codegen bit-exact (if TVM)", test_cpu_codegen_bit_exact),
        ("cpu codegen rejects AIE op", test_cpu_codegen_rejects_aie_op),
        ("dispatch routes non-conv to CPU (if built)", test_dispatch_routes_non_conv_to_cpu),
        ("plain-C CPU bit-exact (if cc)", test_plain_c_cpu_bit_exact),
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
