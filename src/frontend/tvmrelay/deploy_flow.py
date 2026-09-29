###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Deploy a real ONNX ResNet-18 through Relay to a board ELF, stage by stage.

    ensure_tvm016()  ->  download resnet18-v1-7.onnx  ->  Relay
                     ->  int8 quantize  ->  target="c" codegen
                     ->  per-layer folders  ->  baremetal aarch64 main.elf
                     ->  CPU reference classification

Seven stages, matching the seven things this flow has to prove:

1. **Environment** — ``onnx_compat.ensure_tvm016()`` guarantees TVM 0.16 with a
   working ``tvm.relay`` (Relay was removed in the Relax transition, so the
   modern TVM in ``src/frontend/tvm`` cannot do this at all), and
   ``ensure_onnx_mapping()`` restores the ``onnx.mapping`` module that onnx 1.16
   deleted and TVM 0.16 still imports. Both come from importing the package.

2. **Import** — fetch the pretrained ImageNet ResNet-18 (opset 7, 46 MB) and run
   ``relay.frontend.from_onnx``. The 99 initializers arrive as inline
   ``relay.Constant`` nodes, *not* in the returned ``params`` dict (which comes
   back empty even under ``freeze_params=True``), so anything wanting weights
   must read them out of the graph.

3. **Quantize** — ``relay.quantize`` to int8. **Gated**: see the LLVM note
   below. When the gate is shut this stage is skipped and the flow continues in
   fp32 rather than emitting something mislabelled as int8.

4. **Codegen** — ``relay.build(target="c")`` and write the C source + header,
   then ``gcc -fsyntax-only`` it (TVM can emit C that does not compile).

5. **Split** — one folder per layer under ``layers/``, in graph execution
   order, so each layer has a working directory for its AIE artifacts
   (``split_layers.py``).

6. **ARM** — link a baremetal aarch64 ``main.elf`` for the board
   (``arm_build.py``). The generated C is kernels only -- no ``main``, no
   weights in memory, nothing calling the kernels in order -- so that module
   generates the graph driver, a small TVM runtime shim, and an entry point,
   then links them with the cortexa78 BSP using the same recipe as
   ``script/hostcompile.sh``. Needs ``source script/setup.sh --path-set-only``
   for the cross toolchain; without it the stage reports and is skipped.

   The image the ELF classifies is baked in as ``input_image.h``: a real photo
   (the pytorch/hub dog by default, ``--image`` for another) run through the
   standard ImageNet preprocessing, plus ``imagenet_labels.h`` so the board
   prints "Samoyed" rather than "class 258". Preprocessing is *called*, not
   reimplemented -- ``example/model/resnet18py/classify.py:preprocess`` -- so
   the board and the CPU reference cannot disagree over normalization.

7. **CPU** — classify the same image with onnxruntime on the same folded ONNX
   and print the top-5. This is the answer the ELF has to reproduce, from an
   **independent** implementation rather than a second call into the generated
   C, so matching means the compile path is right rather than self-consistent.
   The ELF prints the same five lines in the same format, logits included --
   a class index alone would hide the small numeric drift a miscompiled kernel
   actually produces.

Two host-specific fixups this flow has to make, both load-bearing:

``target_has_feature``
    ``topi.x86.dense_alter_op`` calls ``target_has_features(["avx512bw", ...])``
    during legalization, which reaches an FFI symbol that only exists in an
    LLVM-enabled build. Without a shim *any* ``relay.build(target="c")`` dies
    with ``AttributeError: module 'tvm.target._ffi_api' has no attribute
    'target_has_feature'`` — even for a two-line dense model, and even at
    ``opt_level=0``. ``_shim_target_features()`` answers False (no AVX-512),
    which is the right answer for a C-source target anyway.

``FoldConstant`` needs LLVM
    ``relay.quantize`` calls ``prerequisite_optimize`` ->  ``FoldConstant``,
    which *JIT-executes* constant subgraphs against a target hardcoded as
    ``Target eval_cpu_target_{"llvm"}`` (``src/relay/transforms/fold_constant.cc:403``)
    — not overridable from Python. On a ``USE_LLVM=OFF`` build that raises
    ``target.build.llvm is not enabled``. Disabling ``FoldConstant`` does not
    help: calibration then asserts on ``isinstance(expr.args[0], Constant)``
    (``_calibrate.py:154``), because it *requires* folded constants. So int8
    quantization is genuinely unavailable without LLVM, and this module reports
    that rather than pretending. ``llvm_status()`` is the single predicate.

Run::

    source script/setup.sh --path-set-only          # for stage 6's toolchain
    PYTHONPATH=src python src/frontend/tvmrelay/deploy_flow.py
    PYTHONPATH=src python src/frontend/tvmrelay/deploy_flow.py --image cat.jpg
    PYTHONPATH=src python src/frontend/tvmrelay/deploy_flow.py --skip-quantize
    PYTHONPATH=src python src/frontend/tvmrelay/deploy_flow.py --no-arm
"""

from __future__ import annotations

import argparse
import os
import sys
import urllib.request
from pathlib import Path

# Repo convention: .../src on sys.path, packages reached as frontend.<name>.
# Putting .../src/frontend on the path instead shadows the real `tvm` and `onnx`
# with the empty sibling directories of those names.
_HERE = Path(__file__).resolve().parent
_SRC = _HERE.parent.parent
if str(_SRC) not in sys.path:
    sys.path.insert(0, str(_SRC))

#: Pretrained ImageNet ResNet-18, **v1**. The choice of v1 over v2 is
#: load-bearing on a no-LLVM build, not cosmetic -- see ``prefold_onnx``.
MODEL_URL = (
    "https://github.com/onnx/models/raw/main/validated/vision/"
    "classification/resnet/model/resnet18-v1-7.onnx"
)
MODEL_NAME = "resnet18-v1-7.onnx"
FOLDED_NAME = "resnet18-v1-7.folded.onnx"
INPUT_NAME = "data"
INPUT_SHAPE = (1, 3, 224, 224)

#: Passes ``relay.build`` must not run on a no-LLVM build. ``FoldConstant``
#: JIT-executes constant subgraphs against a hardcoded ``"llvm"`` target
#: (``fold_constant.cc:403``); ``AlterOpLayout`` rewrites conv into x86 layouts
#: whose schedules then need the LLVM codegen. Both are optimizations, so
#: dropping them costs performance in the emitted C, not correctness.
NO_LLVM_DISABLED_PASSES = ["AlterOpLayout", "FoldConstant"]

DEFAULT_OUT = Path("./worklocal/tvmrelay_deploy")


# ═══════════════════════════════════════════════════════════════════════════
#  Host fixups
# ═══════════════════════════════════════════════════════════════════════════

def _shim_target_features() -> list:
    """Supply the LLVM-only FFI probes x86 legalization calls. Returns names added.

    TVM's x86 legalization asks two questions that only an LLVM-enabled build
    can answer, and both are fatal on a ``USE_LLVM=OFF`` build even when the
    target is ``"c"``:

    * ``target_has_feature`` — ``topi.x86.dense_alter_op`` probing for AVX-512
      (``AttributeError`` otherwise, even at ``opt_level=0``);
    * ``llvm_version_major`` — ``topi.x86.conv2d_int8.is_int8_hw_support``
      (``RuntimeError: LLVM version is not available`` otherwise).

    Both are shimmed to "this host has no LLVM vector ISA", which is the
    correct answer when emitting portable C: it steers legalization away from
    AVX-512-specific int8 rewrites rather than faking support for them.
    """
    from tvm.target import _ffi_api

    added = []
    if not hasattr(_ffi_api, "target_has_feature"):
        _ffi_api.target_has_feature = lambda feature, target=None: False
        added.append("target_has_feature")
    if not hasattr(_ffi_api, "llvm_version_major"):
        # 0 => "older than every version gate", so int8 HW paths stay off.
        _ffi_api.llvm_version_major = lambda: 0
        added.append("llvm_version_major")
    return added


def llvm_status() -> tuple:
    """Return ``(has_llvm, detail)`` for the *running* TVM. Never raises.

    This is the gate for stage 3. It asks the build config rather than trying a
    quantize, so callers can report the situation before spending minutes.
    """
    try:
        import tvm

        cfg = {}
        try:
            cfg = dict(tvm.support.libinfo())
        except Exception:
            pass
        use_llvm = str(cfg.get("USE_LLVM", "")).strip()
        if use_llvm and use_llvm.upper() not in ("OFF", "FALSE", "0", ""):
            return True, f"USE_LLVM={use_llvm}"
        # Fall back to asking the codegen registry directly.
        enabled = bool(tvm.get_global_func("target.build.llvm", allow_missing=True))
        return enabled, (f"USE_LLVM={use_llvm or 'OFF'}"
                         f"{' but target.build.llvm is registered' if enabled else ''}")
    except Exception as exc:
        return False, f"{type(exc).__name__}: {exc}"


_LLVM_HINT = """\
  int8 quantization needs an LLVM-enabled TVM. relay.quantize runs
  prerequisite_optimize -> FoldConstant, which JIT-executes constant
  subgraphs against a target hardcoded as "llvm" in C++
  (src/relay/transforms/fold_constant.cc:403), so it cannot be retargeted
  from Python. Disabling FoldConstant does not work either -- calibration
  asserts on isinstance(expr.args[0], Constant) (_calibrate.py:154).

  To enable it, install the two dev packages LLVM links against, then
  rebuild (host LLVM 19 is already detected as compatible):

      sudo apt install zlib1g-dev libzstd-dev
      python src/frontend/tvmrelay/setup_tvm016.py --yes \\
          --llvm /scratch/staff/huaj/llvm-project/build/bin/llvm-config
"""


# ═══════════════════════════════════════════════════════════════════════════
#  Stage 1 — environment
# ═══════════════════════════════════════════════════════════════════════════

def stage_env(verbose: bool = True) -> bool:
    """Guarantee TVM 0.16 + Relay + the ``onnx.mapping`` shim are in place.

    Importing ``frontend.tvmrelay`` is what does the work: its ``__init__``
    calls ``ensure_tvm016()`` (auto-installing TVM 0.16 if absent -- disable
    with ``AIEHLC_TVM_AUTO_INSTALL=0``) and then ``ensure_onnx_mapping()``.
    """
    import frontend.tvmrelay as tvmrelay  # noqa: F401  (side effects are the point)

    ok, detail = tvmrelay.tvm016_status()
    if not ok:
        print(f"[1/7] TVM 0.16 unavailable: {detail}", file=sys.stderr)
        return False

    shimmed = _shim_target_features()
    has_llvm, llvm_detail = llvm_status()
    if verbose:
        import onnx

        print(f"[1/7] env    : tvm {detail} | onnx {onnx.__version__} | "
              f"llvm {'yes' if has_llvm else 'no'} ({llvm_detail})")
        if shimmed:
            print(f"[1/7]          shimmed {', '.join(shimmed)} (no-LLVM build)")
    return True


# ═══════════════════════════════════════════════════════════════════════════
#  Stage 2 — download + Relay import
# ═══════════════════════════════════════════════════════════════════════════

def fetch_model(out_dir: Path, url: str = MODEL_URL, verbose: bool = True) -> Path:
    """Download the ONNX model into ``out_dir``, reusing a cached copy."""
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / MODEL_NAME
    if path.exists() and path.stat().st_size > 0:
        if verbose:
            print(f"[2/7] model  : cached {path} ({path.stat().st_size:,} B)")
        return path
    if verbose:
        print(f"[2/7] model  : downloading {url}")
    tmp = path.with_suffix(".part")
    urllib.request.urlretrieve(url, tmp)
    tmp.replace(path)
    if verbose:
        print(f"[2/7]          saved {path} ({path.stat().st_size:,} B)")
    return path


def prefold_onnx(model_path: Path, verbose: bool = True) -> Path:
    """Fold BatchNorm into Conv **in ONNX**, before Relay ever sees the graph.

    This exists because of the no-LLVM constraint. TVM's own BN removal
    (``SimplifyInference``) rewrites BN into arithmetic containing ``sqrt`` over
    the variance *constants*, and leaves evaluating them to ``FoldConstant`` --
    which needs LLVM. With ``FoldConstant`` disabled those survive into codegen
    and it dies with ``Unresolved call Op(tir.sqrt)``. Folding in ONNX first
    means there is no BN, hence no ``sqrt``, hence nothing to constant-fold.

    onnxruntime's BASIC optimization level is used deliberately: EXTENDED emits
    ``FusedConv``, a Microsoft-domain op the Relay importer does not know.
    BASIC keeps the graph to standard ONNX ops.

    **This only works on ResNet-v1.** v1 is post-activation (Conv -> BN), so BN
    folds into the preceding conv's weights and all 19 BN nodes disappear. v2 is
    pre-activation (BN -> Conv); there is no preceding conv to fold into, 10 BN
    nodes survive BASIC folding, and the ``sqrt`` problem comes back. That is
    why ``MODEL_URL`` points at v1.
    """
    folded = model_path.with_name(FOLDED_NAME)
    if folded.exists() and folded.stat().st_size > 0:
        if verbose:
            print(f"[2/7] fold   : cached {folded.name}")
        return folded

    import onnxruntime as ort

    opts = ort.SessionOptions()
    opts.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_BASIC
    opts.optimized_model_filepath = str(folded)
    ort.InferenceSession(str(model_path), opts, providers=["CPUExecutionProvider"])

    if verbose:
        import onnx

        counts = {}
        for node in onnx.load(str(folded)).graph.node:
            counts[node.op_type] = counts.get(node.op_type, 0) + 1
        kept = " ".join(f"{k}={v}" for k, v in sorted(counts.items()))
        print(f"[2/7] fold   : BN folded into Conv -> {kept}")
    return folded


def import_relay(model_path: Path, verbose: bool = True):
    """ONNX -> Relay. Returns ``(mod, params)``.

    ``params`` comes back **empty**: this model's 99 initializers are imported
    as inline ``relay.Constant`` nodes rather than free variables, and stay that
    way under ``freeze_params=True``. That is expected, not a failure -- but it
    means a weight-extracting walk must read the graph constants.
    """
    import onnx
    from tvm import relay

    model = onnx.load(str(model_path))
    mod, params = relay.frontend.from_onnx(
        model, shape={INPUT_NAME: INPUT_SHAPE}, freeze_params=True
    )
    mod = relay.transform.InferType()(mod)
    if verbose:
        print(f"[2/7] relay  : imported | params={len(params)} "
              f"(initializers are inline Constants) | {_op_summary(mod)}")
    return mod, params


def _op_summary(mod, top: int = 6) -> str:
    """Compact ``op=count`` summary of a Relay module's calls."""
    from tvm import relay

    counts = {}

    def visit(expr):
        if isinstance(expr, relay.expr.Call) and hasattr(expr.op, "name"):
            counts[expr.op.name] = counts.get(expr.op.name, 0) + 1

    relay.analysis.post_order_visit(mod["main"], visit)
    ranked = sorted(counts.items(), key=lambda kv: -kv[1])[:top]
    return " ".join(f"{name}={n}" for name, n in ranked)


# ═══════════════════════════════════════════════════════════════════════════
#  Stage 3 — int8 quantization (gated on LLVM)
# ═══════════════════════════════════════════════════════════════════════════

def quantize_int8(mod, params, *, global_scale: float = 8.0,
                  skip_conv_layers=(0,), verbose: bool = True):
    """Quantize to int8. Returns ``(mod, did_quantize)``.

    Returns the module **unchanged** with ``did_quantize=False`` when the
    running TVM has no LLVM, because ``relay.quantize`` cannot run at all in
    that case (see the module docstring). Reporting that is the point -- a flow
    that silently emitted fp32 while claiming int8 would be worse than one that
    stops.

    ``global_scale`` calibration is used rather than KL-divergence because it
    needs no calibration dataset; ``skip_conv_layers=(0,)`` leaves the first
    conv in fp32, the usual accuracy-preserving convention.
    """
    from tvm import relay

    has_llvm, detail = llvm_status()
    if not has_llvm:
        if verbose:
            print(f"[3/7] int8   : SKIPPED -- this TVM has no LLVM ({detail})")
            print(_LLVM_HINT, end="")
            print("[3/7]          continuing in fp32; stage 4 output is NOT int8")
        return mod, False

    with relay.quantize.qconfig(
        calibrate_mode="global_scale",
        global_scale=global_scale,
        weight_scale="power2",
        skip_conv_layers=list(skip_conv_layers),
    ):
        qmod = relay.quantize.quantize(mod, params)
    if verbose:
        print(f"[3/7] int8   : quantized (global_scale={global_scale}, "
              f"skip_conv_layers={list(skip_conv_layers)}) | {_op_summary(qmod)}")
    return qmod, True


# ═══════════════════════════════════════════════════════════════════════════
#  Stage 4 — C codegen
# ═══════════════════════════════════════════════════════════════════════════

def build_c(mod, params, out_dir: Path, *, opt_level: int = 3, fuse: bool = True,
            verbose: bool = True) -> Path:
    """``relay.build(target="c")`` and write the C source. Returns its path.

    ``fuse=False`` gives one kernel per Relay op instead of per fused group --
    a real ``relu`` kernel, a real ``add`` kernel -- which is what stage 5
    needs to emit genuinely per-op layer files. It is slower code: fusion
    exists to keep intermediates in registers.

    Note it is **not** implemented as ``disabled_pass=["FuseOps"]``. FuseOps
    does two jobs -- grouping ops, and wrapping each group in a primitive
    ``Function`` -- and the graph executor codegen needs the second one
    unconditionally (``graph_executor_codegen.cc:452``:
    ``Expected the operator to be a global var, but got Op``). Instead we run
    ``FuseOps(fuse_opt_level=0)`` ourselves, which short-circuits at
    ``graph_partitioner.cc:104`` after ``InitGroups`` so every node is its own
    group, still wrapped -- then disable the build's own FuseOps so it cannot
    re-fuse what we just split.

    ``target="c"`` emits portable C rather than machine code, so it needs no
    LLVM -- with two caveats, both of which bite on a ``USE_LLVM=OFF`` build:

    * the FFI shims from stage 1 are required to get past x86 legalization;
    * ``target_host`` must be set to ``"c"`` explicitly. It defaults to
      ``llvm``, and the *host* module is built separately from the operator
      modules, so leaving it implicit fails in ``TIRToRuntime`` with
      ``target.build.llvm is not enabled`` even though every kernel compiled;
    * ``NO_LLVM_DISABLED_PASSES`` must be dropped (only when LLVM is absent --
      with LLVM they are kept, since they make the output faster);
    * ``tir.disable_vectorize`` is required for the C to *compile*. TVM's x86
      schedules vectorize, and the C backend renders a 16-lane int32 as the
      type ``int32_t16``, which is not a C type -- gcc rejects it with
      ``unknown type name 'int32_t16'``. The emitted file looks fine and is
      only caught by actually compiling it, so ``verify_c`` does.
    """
    import tvm
    from tvm import relay

    out_dir.mkdir(parents=True, exist_ok=True)
    disabled = [] if llvm_status()[0] else list(NO_LLVM_DISABLED_PASSES)
    if not fuse:
        with tvm.transform.PassContext(opt_level=opt_level,
                                       disabled_pass=disabled):
            mod = relay.transform.InferType()(mod)
            mod = relay.transform.FuseOps(fuse_opt_level=0)(mod)
        disabled.append("FuseOps")
    with tvm.transform.PassContext(opt_level=opt_level, disabled_pass=disabled,
                                   config={"tir.disable_vectorize": True}):
        lib = relay.build(mod, target=tvm.target.Target("c", host="c"),
                          params=params)

    source = lib.lib.get_source()
    c_path = out_dir / "resnet18.c"
    c_path.write_text(source)

    graph_path = out_dir / "resnet18_graph.json"
    graph_path.write_text(lib.get_graph_json())

    params_path = out_dir / "resnet18_params.bin"
    params_path.write_bytes(relay.save_param_dict(lib.get_params()))

    if verbose:
        # Count definitions, not occurrences of the signature: every kernel is
        # named twice, once forward-declared and once defined, so a plain
        # `source.count(...)` reports exactly double.
        from frontend.tvmrelay.split_layers import iter_c_functions
        n_fns = sum(1 for _ in iter_c_functions(source))
        print(f"[4/7] codegen: {c_path} ({len(source):,} chars, {n_fns} kernels)")
        print(f"[4/7]          {graph_path.name}, {params_path.name} "
              f"({params_path.stat().st_size:,} B)")
    return c_path


def verify_c(c_path: Path, verbose: bool = True) -> bool:
    """Syntax-check the emitted C with the host compiler.

    Worth doing as a step rather than trusting the file size: TVM will happily
    emit C containing vector types like ``int32_t16`` that no C compiler
    accepts (see ``build_c``). That output *looks* correct -- right length,
    right kernel count -- and only fails when someone finally compiles it.
    """
    import shutil
    import subprocess

    cc = shutil.which("gcc") or shutil.which("cc")
    if cc is None:
        if verbose:
            print("[4/7] verify : skipped (no gcc/cc on PATH)")
        return True

    tvm_root = Path(__file__).resolve().parents[3] / "thirdparty" / "tvm-0.16"
    cmd = [cc, "-fsyntax-only",
           "-I", str(tvm_root / "include"),
           "-I", str(tvm_root / "3rdparty" / "dlpack" / "include"),
           str(c_path)]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        first = (proc.stderr.strip().splitlines() or ["(no output)"])[0]
        print(f"[4/7] verify : FAILED -- emitted C does not compile: {first}",
              file=sys.stderr)
        return False
    if verbose:
        print(f"[4/7] verify : {c_path.name} compiles ({cc} -fsyntax-only)")
    return True


# ═══════════════════════════════════════════════════════════════════════════
#  Driver
# ═══════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════
#  Stage 7 — CPU reference classification
# ═══════════════════════════════════════════════════════════════════════════

def cpu_reference(out_dir: Path, image=None, topk: int = 5,
                  verbose: bool = True):
    """Classify the same image on the CPU and print the top-k. Returns it.

    This is the answer the board ELF has to reproduce. It is deliberately an
    **independent** implementation -- onnxruntime on the same folded ONNX, not
    a second call into the generated C -- so agreeing means the compile path
    is right, rather than only self-consistent.

    Compare it against the ELF by eye, or diff the printed logits: the ELF
    prints the same five lines in the same format. A class index alone would
    hide a small numeric drift, and drift is what a miscompiled kernel
    produces.
    """
    onnx_path = Path(out_dir) / FOLDED_NAME
    if not onnx_path.is_file():
        if verbose:
            print(f"[7/7] cpu    : skipped -- {onnx_path.name} not found")
        return None
    try:
        from frontend.tvmrelay import image_input

        tensor, path = image_input.preprocess_image(image, verbose=False)
        labels = image_input.load_labels(verbose=False)
        top = image_input.classify_reference(tensor, onnx_path, labels,
                                             topk=topk)
    except Exception as exc:                     # torch/PIL/onnxruntime absent
        if verbose:
            print(f"[7/7] cpu    : skipped -- {type(exc).__name__}: {exc}")
        return None

    if verbose:
        print(f"[7/7] cpu    : onnxruntime reference on {Path(path).name}")
        for rank, idx, name, logit in top:
            print(f"               {rank}. class={idx:<4d} {name:<30s} "
                  f"logit={logit:.4f}")
        print(f"[7/7]          the ELF prints these same lines; "
              f"top1 must be class {top[0][1]} ({top[0][2]})")
    return top


def run(out_dir: Path = DEFAULT_OUT, *, skip_quantize: bool = False,
        global_scale: float = 8.0, fuse: bool = True, split: bool = True,
        flat: bool = False, arm: bool = True, image=None,
        verbose: bool = True) -> dict:
    """Run all seven stages. Returns a dict of what happened."""
    if not stage_env(verbose=verbose):
        return {"ok": False, "stage": "env"}

    model_path = fetch_model(out_dir, verbose=verbose)
    model_path = prefold_onnx(model_path, verbose=verbose)
    mod, params = import_relay(model_path, verbose=verbose)

    quantized = False
    if skip_quantize:
        if verbose:
            print("[3/7] int8   : skipped (--skip-quantize)")
    else:
        mod, quantized = quantize_int8(mod, params, global_scale=global_scale,
                                       verbose=verbose)

    c_path = build_c(mod, params, out_dir, fuse=fuse, verbose=verbose)
    compiles = verify_c(c_path, verbose=verbose)

    layers = None
    if not split:
        if verbose:
            print("[5/7] split  : skipped (--no-split)")
    elif not compiles:
        # Splitting C that does not compile just multiplies the broken file by
        # 22. Fail at the source instead.
        if verbose:
            print("[5/7] split  : skipped -- the emitted C does not compile")
    else:
        from frontend.tvmrelay.split_layers import split_layers
        layers = split_layers(c_path, out_dir=out_dir / "layers",
                              group=not flat, verbose=False)
        if verbose:
            check = layers.get("syntax_check")
            note = ("all compile" if check == "pass"
                    else f"{len(check)} FAILED" if isinstance(check, list)
                    else str(check))
            print(f"[5/7] split  : {layers['layer_count']} layers -> "
                  f"{out_dir / 'layers'}/ ({note})")
            # One folder per layer, already in execution order -- just show the
            # first few so the ordering is visible at a glance.
            key = "path" if flat else "dir"
            shown = [f"{e[key]}{'' if flat else '/'}"
                     for e in layers["layers"][:4]]
            print(f"[5/7]          {', '.join(shown)}, ... "
                  f"({layers['layer_count']} in execution order)")

    elf = None
    if not arm:
        if verbose:
            print("[6/7] arm    : skipped (--no-arm)")
    elif not compiles:
        if verbose:
            print("[6/7] arm    : skipped -- the emitted C does not compile")
    else:
        from frontend.tvmrelay.arm_build import build_arm_elf

        if verbose:
            print("[6/7] arm    : linking baremetal aarch64 ELF")
        built = build_arm_elf(out_dir, c_name=Path(c_path).name,
                              image=image, verbose=verbose)
        if built.get("ok"):
            elf = built["elf"]
        elif verbose and built.get("stderr"):
            print(f"[6/7]          {built['reason']}:")
            for line in built["stderr"].strip().splitlines()[:5]:
                print(f"              {line}")

    cpu = cpu_reference(out_dir, image=image, verbose=verbose)

    if verbose:
        kind = "int8" if quantized else "fp32"
        print(f"\ndone: {kind} C in {out_dir}"
              f"{'' if compiles else '  (WARNING: does not compile)'}")
        if elf:
            print(f"      board ELF: {elf}")
    return {"ok": compiles, "quantized": quantized, "c_path": str(c_path),
            "out_dir": str(out_dir), "fused": fuse,
            "layer_count": layers["layer_count"] if layers else None,
            "elf": elf, "cpu_top1": (cpu[0][1] if cpu else None),
            "cpu_top": cpu}


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--out-dir", type=Path, default=DEFAULT_OUT,
                    help=f"output directory (default: {DEFAULT_OUT})")
    ap.add_argument("--skip-quantize", action="store_true",
                    help="emit fp32 C without attempting stage 3")
    ap.add_argument("--global-scale", type=float, default=8.0,
                    help="relay.quantize global_scale (default: 8.0)")
    ap.add_argument("--no-split", action="store_true",
                    help="skip stage 5 (do not write layers/)")
    ap.add_argument("--flat", action="store_true",
                    help="stage 5 writes one flat layers/ directory of .c "
                         "files instead of a folder per layer")
    ap.add_argument("--no-fuse", action="store_true",
                    help="disable FuseOps, so stage 5 emits one file per Relay "
                         "op (a real relu.c) instead of per fused group")
    ap.add_argument("--no-arm", action="store_true",
                    help="skip stage 6 (do not link the aarch64 board ELF)")
    ap.add_argument("--image", default=None,
                    help="image path or URL to classify "
                         "(default: the pytorch/hub dog.jpg sample)")
    args = ap.parse_args(argv)

    result = run(args.out_dir, skip_quantize=args.skip_quantize,
                 global_scale=args.global_scale, fuse=not args.no_fuse,
                 split=not args.no_split, flat=args.flat,
                 arm=not args.no_arm, image=args.image)
    return 0 if result.get("ok") else 1


if __name__ == "__main__":
    raise SystemExit(main())
