# `tvmrelay` — the Relay-era TVM frontend

Targets **TVM 0.16**, the last release with a complete `tvm.relay`.

`src/frontend/tvm` targets the modern Relax-era TVM (0.25+). **The two are
mutually exclusive** — one Python environment holds one TVM — so exactly one of
them works at a time. Which one is live is whichever `setup_tvm016.py` left
behind.

## Why 0.16

Relay was removed in the Relax/Unity transition. On 0.26 this is unconditional:

```
>>> from tvm import relay
ImportError: cannot import name 'relay' from 'tvm'
```

That is also why `src/frontend/tvm/relay_import.py` has been silently inert —
its `tvm_available()` catches that ImportError and returns False on every run,
so `walk.build_plan` always falls through to `model.layer_plan()` and the ONNX
graph never influences the result.

## Provisioning

```bash
python src/frontend/tvmrelay/setup_tvm016.py --verify-only   # report, change nothing
python src/frontend/tvmrelay/setup_tvm016.py --dry-run       # print every command
python src/frontend/tvmrelay/setup_tvm016.py --yes           # uninstall + build + install
```

It detects the installed TVM (out-of-process), uninstalls anything newer than
0.16, tries a 0.16 wheel, and falls back to a source build at tag `v0.16.0` in
`thirdparty/tvm-0.16/` (gitignored). It finishes by **importing a real ONNX
model through Relay** — not by reading a version string.

No 0.16 wheel exists on PyPI or tlcpack, so the source build is the real path.
Budget 10–25 min. Every removal is recorded to
`thirdparty/tvm-0.16/uninstalled.json` with a one-line restore command.

Flags: `--yes --src-dir PATH --jobs N --llvm[=PATH] --force-source --dry-run
--verify-only --allow-system`.

`USE_LLVM` is **OFF** by default. The Relay ONNX importer, the graph walk and
`target="c"` codegen need no LLVM; only `target="llvm"` JIT does. This host
carries LLVM 19, which postdates TVM 0.16. Pass `--llvm` to opt in.

## Importing it

Follow the `src/frontend` convention — put `.../src` on `sys.path` and import
`frontend.tvmrelay`:

```python
import sys, os
sys.path.insert(0, os.path.abspath("src"))
import frontend.tvmrelay        # installs the onnx.mapping shim
from tvm import relay
```

Putting `.../src/frontend` on the path instead shadows the real `tvm` and `onnx`
with the empty sibling directories of those names, and fails as
`module 'tvm' has no attribute '__version__'`.

### Importing self-provisions

`import frontend.tvmrelay` calls `ensure_tvm016()`, which checks that the
importable TVM is 0.16 **with a working `tvm.relay`** and, if it is not, runs
`setup_tvm016.provision()` to install it. On a healthy environment this costs
about a second; otherwise the import uninstalls the current TVM and runs the
source build.

That is a large side effect for an `import`, so it announces itself on stderr,
and:

```bash
AIEHLC_TVM_AUTO_INSTALL=0 python your_script.py   # report and continue instead
```

After a successful install the new TVM is made importable **in the same
process** — the `.pth` file is only read at interpreter startup, so
`ensure_tvm016` adds the path and purges any stale `tvm` from `sys.modules`
itself. No restart needed.

`ensure_tvm016()` never fires recursively: `setup_tvm016.verify()` runs a
subprocess that imports this package, so it sets `_TVMRELAY_PROVISIONING=1` in
that subprocess's environment, and `ensure_tvm016` refuses to provision while
that sentinel is set. Without it, verify → import → provision → verify loops
forever.

Use `tvm016_status()` for a cheap `(ok, detail)` check with no side effects.

### The onnx.mapping shim

Importing the package installs the `onnx.mapping` compatibility shim
(`onnx_compat.py`). That is **required, not decorative**: onnx 1.16 deleted
`onnx.mapping`, TVM 0.16 imports `TENSOR_TYPE_TO_NP_TYPE` from it, and without
the shim `relay.frontend.from_onnx` raises `ImportError` on any current onnx.
The shim rebuilds the table from `onnx.helper` rather than pinning onnx back
below 1.16, which would put `torch` and `onnxruntime` — sharing this
environment — into a version fight over one dict.

## `deploy_flow.py` — ONNX ResNet-18 → Relay → int8 → C → layers → board ELF → CPU check

```bash
source script/setup.sh --path-set-only        # stage 6 needs the cross toolchain
PYTHONPATH=src python src/frontend/tvmrelay/deploy_flow.py
PYTHONPATH=src python src/frontend/tvmrelay/deploy_flow.py --image cat.jpg
PYTHONPATH=src python src/frontend/tvmrelay/deploy_flow.py --skip-quantize
PYTHONPATH=src python src/frontend/tvmrelay/deploy_flow.py --no-fuse
PYTHONPATH=src python src/frontend/tvmrelay/deploy_flow.py --no-arm
```

Seven stages: `ensure_tvm016()` → download + Relay import → int8 quantize →
`target="c"` codegen (then a `gcc -fsyntax-only` check) → split into
per-layer folders → baremetal aarch64 `main.elf` → CPU reference
classification.

Flags: `--out-dir --image --skip-quantize --global-scale --no-split --no-fuse
--flat --no-arm`.

### The image, and what the two ends print

The ELF classifies a **real photo**, baked in as `input_image.h`. Default is
the pytorch/hub dog; `--image path-or-url` takes any other. Preprocessing is
*called*, not reimplemented — `example/model/resnet18py/classify.py:preprocess`,
the same function the reference classifier uses (resize shorter side to 256,
center-crop 224, `/255`, mean `[0.485,0.456,0.406]`, std `[0.229,0.224,0.225]`,
NCHW). Reimplementing it would be the easiest way to make the board and the CPU
disagree for a reason that has nothing to do with the compiler.

`imagenet_labels.h` rides along so the board prints a name, not an index.

Stage 7 then classifies the same image with **onnxruntime on the same folded
ONNX** — an independent implementation, not a second call into the generated C
— and prints the top-5 in the same format the ELF does:

```
[7/7] cpu    : onnxruntime reference on dog.jpg
               1. class=258  Samoyed                        logit=12.4359
               2. class=279  Arctic fox                     logit=8.6504
               ...
[7/7]          the ELF prints these same lines; top1 must be class 258 (Samoyed)
```

Logits are printed, not just the class: a class index alone hides the small
numeric drift a miscompiled kernel actually produces.

Verified by compiling the ELF's exact sources for x86 and running them — both
images match the oracle on all five entries including logits (dog → Samoyed
12.4359; cat → Egyptian cat 15.6039).

### What a no-LLVM TVM costs you

This tree's TVM 0.16 is built `USE_LLVM=OFF`. Four separate things break, and
each fails in a way that does not name LLVM:

| Symptom | Cause | Handled by |
|---|---|---|
| `AttributeError: ... no attribute 'target_has_feature'` | `topi.x86.dense_alter_op` probes AVX-512 via an LLVM-only FFI symbol. Fires even at `opt_level=0` on a 2-line model. | `_shim_target_features()` → False |
| `RuntimeError: LLVM version is not available` | `topi.x86.conv2d_int8.is_int8_hw_support` calls `llvm_version_major()` | same shim → 0 |
| `target.build.llvm is not enabled` | `target_host` defaults to `llvm`; the host module is built separately from the kernels | `Target("c", host="c")` |
| `target.build.llvm is not enabled` (again) | `FoldConstant` JIT-executes constant subgraphs against a target hardcoded in C++ (`fold_constant.cc:403`) | disable `FoldConstant` + `AlterOpLayout` |

**int8 quantization is genuinely unavailable without LLVM.** `relay.quantize` →
`prerequisite_optimize` → `FoldConstant`, and that target is not reachable from
Python. Disabling `FoldConstant` does not help either: calibration then asserts
on `isinstance(expr.args[0], Constant)` (`_calibrate.py:154`) because it
*requires* folded constants. So stage 3 detects this, prints the root cause and
the fix, and continues in fp32 rather than mislabelling the output. To enable:

```bash
sudo apt install zlib1g-dev libzstd-dev     # the only two things missing
python src/frontend/tvmrelay/setup_tvm016.py --yes \
    --llvm /scratch/staff/huaj/llvm-project/build/bin/llvm-config
```

Host LLVM 19 is already detected as compatible — zlib/zstd were the sole cmake
failures.

### Two non-obvious choices

**ResNet-18 v1, not v2.** With `FoldConstant` off, TVM's `SimplifyInference`
rewrites BatchNorm into arithmetic containing `sqrt` over the variance
constants and leaves them unevaluated → `Unresolved call Op(tir.sqrt)`. So BN
is folded in *ONNX* first, via onnxruntime at `ORT_ENABLE_BASIC`. That works
only for v1 (post-activation, Conv→BN, all 19 BN nodes fold into the preceding
conv). v2 is pre-activation (BN→Conv) with nothing to fold into — 10 BN nodes
survive and `sqrt` returns. `ORT_ENABLE_EXTENDED` is also avoided: it emits
`FusedConv`, a Microsoft-domain op the Relay importer rejects.

**`tir.disable_vectorize`.** Without it the emitted C contains `int32_t16`,
which is not a C type; gcc rejects it. The file otherwise looks correct — right
size, right kernel count — so `verify_c` compiles it rather than trusting it.

Verified output: 340,219 chars, 22 kernels, compiles clean.

## `split_layers.py` — stage 5, one folder per layer

`relay.build` emits every kernel into one 4.5k-line translation unit. Stage 5
splits it into `layers/` beside it — **one folder per layer, in graph execution
order**:

```
layers/
  layers_common.h              includes + every forward declaration
  00_conv2d_add_relu/          stem conv
  01_max_pool2d/
  02_conv2d_add_relu/          ─┐
  03_conv2d_add_add_relu/       ┘ residual block 1
  04_conv2d_add_relu/  05_conv2d_add/  06_conv2d_add_add_relu/
  ...
  19_global_avg_pool2d/  20_dense_add/  21_batch_flatten/
  manifest.json  Makefile  README.md
```

The folder is a **per-layer working directory**, which is the point: reading
`layers/` top to bottom is reading the network in the order it executes, and
each folder is where that layer's AIE artifacts belong — `.bcf`, kernel
sources, the generated `host.cc`/`routing.cc` — sitting next to the C it
replaces. Those are per-layer, not per-op-kind, which is why the folder is
keyed by execution index rather than by operator.

`--flat` gives a single directory of `.c` files with no per-layer folders;
useful only when nothing else will ever sit beside them.

Each file is a **complete translation unit** — it includes
`../layers_common.h` and compiles alone, which the splitter verifies per file
with `gcc -fsyntax-only` rather than assuming. In `layers/`, `make` builds all
22 and `make 00_conv2d_add_relu` builds one layer.

Folder numbers are **graph execution order**, read from `resnet18_graph.json`,
so the listing reads like the network — stem conv, maxpool, eight residual
blocks, avgpool, dense.

Names are the fused op list with `nn_` stripped and `expand_dims` dropped (it
is a bias broadcast, not a layer). So `conv2d_add_add_relu` reads as conv,
bias, residual, activation. The full TVM symbol is never lost — it is in each
file's header comment and in `manifest.json`.

Run it standalone against an already-generated tree:

```bash
PYTHONPATH=src python src/frontend/tvmrelay/split_layers.py worklocal/tvmrelay_deploy
PYTHONPATH=src python src/frontend/tvmrelay/split_layers.py worklocal/tvmrelay_deploy --flat
```

Re-splitting is safe to repeat: it clears previously-generated `.c`/`.o` from
`layers/` and its immediate subfolders, then removes whatever folders that
leaves empty. Files you add yourself — an AIE kernel beside the generated C,
a notes file — are left alone, and their folder survives with them.

## `arm_build.py` — stage 6, the board ELF

```bash
source script/setup.sh --path-set-only        # cross toolchain + XILINX_VITIS
PYTHONPATH=src python src/frontend/tvmrelay/deploy_flow.py
PYTHONPATH=src python src/frontend/tvmrelay/arm_build.py worklocal/tvmrelay_deploy
PYTHONPATH=src python src/frontend/tvmrelay/arm_build.py --no-make   # generate only
```

`relay.build(target="c")` gives kernels but **not a program**: no `main`, no
weights in memory, nothing calling the kernels in order. TVM normally supplies
that from its C++ graph *runtime*, which is host-side. Stage 6 generates the
missing pieces from `resnet18_graph.json` instead, into `arm_build/`:

| file | what it is |
|---|---|
| `graph_driver.c` | one static buffer per `storage_id`, weights pointed into the blob, one kernel call per graph node in order |
| `tvm_runtime_shim.c` | the four runtime symbols the kernels reference — a bump allocator plus an error sink |
| `main.c` | entry point, feeds `input_image.h`, prints the top-5 with names and logits, and the `device_teardown done` line `verify_host.sh` greps |
| `input_image.h` | the preprocessed photo as `static const float[150528]` |
| `imagenet_labels.h` | the 1000 class names |
| `tvm/runtime/c_*_api.h` | baremetal stand-ins so `resnet18.c` is used **verbatim**, not patched |
| `weights.bin` | `resnet18_params.bin`, linked in via `ld -r -b binary` |
| `Makefile` | the build recipe |

### Python generates, `make` builds

The recipe lives in the generated `Makefile`, not inside Python, so the build
the flow ran is the same one you re-run by hand:

```bash
make -C worklocal/tvmrelay_deploy/arm_build                     # rebuild changed
make -C worklocal/tvmrelay_deploy/arm_build clean && make -C ... # from scratch
make -C ... CROSS=aarch64-linux-gnu- CPU=cortex-a72             # retarget
make -C ... -j8
```

Edit a generated `.c`, run `make`, and only that file recompiles — the 340 KB
kernel translation unit is not rebuilt. `--no-make` (or `run_make=False`) stops
after generating. Without `setup.sh` sourced the sources and Makefile are
**still written**; only the build is skipped, with the `make -C ...` line to run
once the toolchain is on PATH. No traceback.

Toolchain matches `script/hostcompile.sh` and `quant/build_demo.build_aarch64`:
`aarch64-none-elf-gcc`, `-mcpu=cortex-a78`, cortexa78 BSP, `--specs=nosys.specs`,
BSP linker script.

One Makefile subtlety worth not re-discovering: `LDLIBS` must stay a single
unbroken token. The commas are `-Wl` separators, so a `\` line continuation
splits it and ld goes looking for a library literally named
`-lxilstandalone,...`.

**Why not TVM's AOT executor.** `Executor("aot")` does emit a real
`tvmgen_default_run`, which looks like the obvious answer. It was tried and
rejected: AOT inlines every weight into the C source as initializer text — a
**188 MB** `.c` for ResNet-18 — and `link-params=False` does not prevent it.
Reading weights from a linked blob keeps the source at 340 KB and the weights
in `.rodata`.

**Verified numerically, not just linked.** The same generated driver compiled
for x86 and run against the same ramp input matches onnxruntime on the folded
ONNX: identical top-5 (`858, 539, 430, 852, 553`), max abs diff **7.2e-06**.
A driver that links but computes nonsense would pass every other check here.

Footprint: 69 MB `.bss` (52 MB graph buffers + 16 MB kernel workspace) and
46 MB `.data` of weights, topping out at 0x470971C0 — inside the 2 GB DDR the
BSP maps, with ~956 MB spare. Note `size` reports ~1.1 GB of bss because it
counts the BSP's 1 GB `.heap` reservation, which this program does not use.

**No AIE yet.** This is the CPU path only. `aie_runtime.c`, `routing.cc` and an
embedded kernel ELF are what `hostcompile.sh` adds, and no layer has them yet —
when a layer folder grows a `.bcf` and a kernel, that layer's call site in
`graph_driver.c` is what changes.

### There is no `relu.c` by default, and that is not a bug

TVM's `FuseOps` welds elementwise ops into their producer, so the compiled unit
genuinely *is* conv2d+bias+residual+relu: one loop nest, one function. No
amount of text splitting recovers a separate relu — it was never emitted. For
true per-op files, build with fusion off:

```bash
PYTHONPATH=src python src/frontend/tvmrelay/deploy_flow.py --no-fuse
# -> 30 layers: 00_conv2d.c  01_add.c  02_relu.c  03_max_pool2d.c ...
```

giving folders `conv2d/`, `add/`, `relu/`, `max_pool2d/`, …

`--no-fuse` is **not** `disabled_pass=["FuseOps"]`. FuseOps does two jobs —
grouping ops, and wrapping each group in a primitive `Function` — and the graph
executor codegen needs the second unconditionally; disabling the pass outright
fails with `Expected the operator to be a global var, but got Op`
(`graph_executor_codegen.cc:452`). Instead `build_c` runs
`FuseOps(fuse_opt_level=0)` itself, which returns right after `InitGroups`
(`graph_partitioner.cc:104`) so each node is its own group *and still wrapped*,
then disables the build's own FuseOps so it cannot re-fuse.

### Two details worth knowing

**`21_batch_flatten.c` has zero callers.** Its header says so
(`invoked : never -- not reached by the graph (dead kernel)`). The graph elides
the flatten into a `__nop` because the reshape is layout-free. Uncalled kernels
are emitted anyway, after the reachable ones — worth seeing, not hiding.

**A stem can repeat; the index disambiguates.** ResNet has eight
`conv2d_add_relu` kernels, so files are `00_`, `02_`, `04_`… — the execution
index is what makes each filename unique, not the name.

## Verified state

```
tvm 0.16.0 | numpy 2.2.6 | onnx 1.22.0 (shim)
relay.frontend.from_onnx(resnet18-v2-7.onnx) ->
  20 nn.conv2d, 19 nn.batch_norm, 18 nn.relu, 9 add,
  1 nn.max_pool2d, 1 nn.global_avg_pool2d, 1 reshape, 1 nn.dense
  ret type: Tensor[(1, 1000), float32]
```

Note the ONNX initializers (99 of them) arrive as inline `relay.Constant` nodes,
**not** in the returned `params` dict — which comes back empty, and stays empty
under `freeze_params=True`. Anything walking this IR for weights must read the
constants out of the graph.
