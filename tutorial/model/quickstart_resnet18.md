# Quickstart: download ResNet-18 and offload its first conv2d to an AIE kernel

This tutorial walks through
[`example/aiegraph/quickstart_onnx.py`](../../example/aiegraph/quickstart_onnx.py)
step by step. In about ten lines of Python you will:

1. download ResNet-18 (ONNX, ImageNet, `1x3x224x224 -> 1000` logits),
2. quantize it to int8 and turn every layer into C code for the A78 (the Arm
   application processor on the board),
3. prove on x86 that a local AIE kernel computes the first conv2d layer
   bit-exactly,
4. build that kernel with aiehlc and swap it into the network,
5. link `main.elf`, which runs every other layer on the A78 and the first conv
   on the AIE.

The kernel is the stem convolution that ships with the repo:
[`src/aietensorop/conv2dstem/conv2dstem_uk.cc`](../../src/aietensorop/conv2dstem/conv2dstem_uk.cc)
(7x7, stride 2, 3 -> 64 channels, int8 in, uint8 out, fused requantize + ReLU).

For the full API see the [aiegraph user guide](../../doc/tutorial_aiegraph.md).
For a deployment that puts **all** 21 weighted layers on the AIE, see
[resnet18.md](resnet18.md).

---

## The whole thing

```python
import aiegraph as ag

m = ag.load("resnet18")                          # 1. download (once) + load
emod = ag.embedded_convert(m, target="a78")      # 2. int8 + one C file per layer
print(emod)

kernel = "src/aietensorop/conv2dstem/conv2dstem_uk.cc"
print(emod.detect(kernel))                       # 3. which layers can it take?
rep = emod.offload_check("layer1", kernel)       # 4. prove it on x86
print(rep); rep.raise_for_status()
print(emod.offload(("layer1", kernel)))          # 5. aiehlc build + swap the call
print(emod.build())                              # 6. link main.elf
# emod.run()                                     # 7. optional: run on a lab board
```

Or run the ready-made script from the repo root:

```bash
python example/aiegraph/quickstart_onnx.py
```

The rest of this page explains each step.

---

## Step 0. Install and check the machine

```bash
cd <repo>                 # your aiehlc checkout
pip install -e .          # once; editable install only, the flow needs the checkout
aiegraph doctor
```

`pip install -e .` installs the `aiegraph` package and the `aiegraph` command.
TVM 0.16 has no wheel. If it is missing, the first import of the TVM frontend
provisions it from `thirdparty/tvm-0.16` (10-25 minutes, once).

`aiegraph doctor` lists every dependency and ends with what the machine can do:

```text
  ok   aiehlc binary            /.../build/aiehlc
  ok   Vitis (xchesscc)         XILINX_VITIS=/.../Vitis, xchesscc=/.../aietools/bin/xchesscc
  ok   aarch64 cross toolchain  /.../aarch64-none-elf-gcc
  ready for: convert, check, offload
```

| Steps | Need |
|---|---|
| 1-4 (download, convert, detect, check) | Python packages + host gcc only |
| 5-6 (offload, build) | Vitis (`source <Vitis>/settings64.sh`) for `xchesscc` and the aarch64 cross compiler, and a built `build/aiehlc` |
| 7 (run) | a lab board (`script/test/apppaltest.py` environment) |

The script calls `ag.doctor()` itself. It stops after step 4 when Vitis is
missing, so you can still do all the x86 work on a plain machine.

---

## Step 1. Download ResNet-18

```python
m = ag.load("resnet18")
print(m)
```

`"resnet18"` is a name in the aiegraph model zoo
([`src/aiegraph/zoo.json`](../../src/aiegraph/zoo.json)). The first call
downloads `resnet18-v1-7.onnx` from the ONNX model zoo into
`~/.cache/aiegraph/models/` (set `AIEGRAPH_CACHE` to move it). Later calls reuse
the file.

Why v1 and not v2? v1 is post-activation, so each BatchNorm folds into the conv
before it, and every conv becomes one quantized conv layer.

Other ways to get a model, all returning the same `Model`:

```python
m = ag.load("my_model.onnx")                     # your own ONNX file
m = ag.from_torch(net, example_inputs=(x,))      # a torch.nn.Module (exported to ONNX)
```

The input must be `[1, 3, 224, 224]`; other shapes are refused here, at `load`.

If the machine has no internet access, download the URL from `zoo.json` by hand
and pass the file path to `ag.load()`.

---

## Step 2. Convert: int8 + one C file per layer

```python
emod = ag.embedded_convert(m, target="a78")
print(emod)
```

This runs the TVM deploy flow (`src/frontend/tvmrelay/deploy_flow.py`):

1. fold BatchNorm into the convs,
2. quantize to int8 (per-channel symmetric weights, affine activations),
3. compile with TVM's C backend,
4. split the result into one C file per operator
   (`layers/NN_op/NN_op.c`),
5. generate the A78 driver `arm_build/graph_driver.c`, which calls the layers
   in order.

The output goes to `worklocal/aiegraph/resnet18/`. It takes a few minutes the
first time. The result is cached by a hash of the model and the options, so a
second run returns at once.

`print(emod)` shows the layer table:

```text
EmbeddedModel resnet18 -> a78   int8   workdir .../worklocal/aiegraph/resnet18
  layer    calls  op                            in -> out                                       on
  layer0   1      divide round add clip cast a  float32[1,3,224,224] -> int8[1,1,230,230,3]     cpu
  layer1   1      conv7x7/2 ->uint8             int8[1,1,230,230,3] -> uint8[1,16,112,112,4]    cpu
  layer2   1      max pool2d                    uint8[1,16,112,112,4] -> uint8[1,16,56,56,4]    cpu
  layer4   2      conv3x3/1 ->int8              int8[1,16,58,58,4] -> int8[1,16,56,56,4]        cpu
  ...
  33 layers, 41 calls
```

How to read it:

- **`layer1` is the first conv2d**, the 7x7 stride-2 stem. `layer0` before it
  is the input quantizer: it turns the float image into int8 and pads it by 3
  pixels on each side (224 -> 230) with the zero point.
- The shapes are TVM's **NCHWc** layout: `[1,16,112,112,4]` is 64 output
  channels stored as 16 blocks of 4.
- Every row says `cpu`: right after a conversion, the whole network runs on
  the A78.
- `layerN` means **TVM kernel N**. It is not torchvision's `layer1` stage. To
  pick layers by model names (`conv1`, `layer1.0.conv1`), use the region API
  ([`quickstart_regions.py`](../../example/aiegraph/quickstart_regions.py)).

---

## Step 3. Detect: which layers can the kernel take?

```python
kernel = "src/aietensorop/conv2dstem/conv2dstem_uk.cc"
print(emod.detect(kernel))
```

The kernel file declares what it accepts with an `AIEK_SPEC` from
[`include/aie_user_kernel.h`](../../include/aie_user_kernel.h): every argument
in TVM call order, with its dtype, shape and value requirements, for example
`require=range(-30,32)` on the requantize shift. `detect` checks every call of
every layer against that spec, using the real weights and quantization
parameters of **your** model. It reports which layers fit, and for each one
that does not, why:

```text
layer4 NO ... stopped at detect: call [04]: arg 0 (ifm_pad): dim 1 is 16, spec says 1
```

For this kernel, only `layer1` fits.

---

## Step 4. Offload check: prove it on x86

```python
rep = emod.offload_check("layer1", kernel)
print(rep)
if not rep.ok:
    raise SystemExit(1)
```

`offload_check` runs four gates. None of them needs a board or Vitis:

| Gate | What it checks |
|---|---|
| **lint** | the source for known aiehlc traps (codes `L0xx`) |
| **detect** | the spec against every call of the layer, on real values (step 3) |
| **calibrate** | the kernel's x86 reference (`AIEK_REFERENCE`) against the layer's own TVM C, on the real constants and on adversarial inputs, byte for byte |
| **emulate** | the **whole network** on x86, with layer 1 replaced through the generated adapter (the same text the board will use). The 1000 logits must be byte-identical to the all-CPU build |

Expected output:

```text
offload_check  READY
  layer1   ok  conv2dstem_uk.cc: lint ok | detect 1 call(s) | calibrate BIT-EXACT (1 call(s))
  emulate: PASS -- logits BIT-IDENTICAL; top1 baseline (258, 12.017338) vs emulated (258, 12.017338); swapped L01 x1/1
  next: emod.offload(('layer1', 'conv2dstem_uk.cc'))
```

`offload_check` writes only under `<workdir>/aiek/`. Your converted model is
not changed until step 5.

---

## Step 5. Offload: build the kernel and swap the call

```python
print(emod.offload(("layer1", kernel)))
```

This needs Vitis. It does three things:

1. Runs the same gates as step 4 again.
2. Builds the kernel with aiehlc in library mode into
   `layers/01_*/aie/build/libaiek_<name>.a`. aiehlc compiles the
   `__global__` kernel for the AIE core with `xchesscc`, generates the DMA,
   routing and launch code, and appends an adapter `aie_<symbol>()` with TVM's
   call signature to the generated `host.cc`.
3. Records the decision in `partition.json` (`backend: aiehlc-user`) and
   regenerates `graph_driver.c`. Layer 1's call is now routed to the AIE
   adapter. Every other layer is unchanged.

`print(emod)` now shows `layer1 ... aie:<kernel>` instead of `cpu`.

To undo it, run `emod.offload("layer1", False)`. Layer 1 goes back to the A78.

---

## Step 6. Build `main.elf`

```python
print(emod.build())
```

This links `worklocal/aiegraph/resnet18/arm_build/main.elf` with the aarch64
cross compiler: the driver, every CPU layer (`liblayers.a`), and the AIE
library from step 5 (which carries the AIE runtime and the embedded kernel
ELF).

The ELF is self-contained. It initializes the AIE partition, runs the network
on a built-in test image, and prints the top-5 classes.

The script then calls `ag.guide()`, which prints the next steps.

---

## Step 7 (optional). Run it

On a lab board:

```python
r = emod.run()                    # palmyra by default; emod.run(ag.VEK385, "<host>") for a VEK385
print(r.ok, r.top1, r.inference_ms)
```

`run` rebuilds `main.elf` if it is older than its inputs, loads it on the board
(palmyra uses netboot), and parses the console. The proof that layer 1 ran on
the array is one `ENTER` / `EXIT rc=0` pair from the AIE adapter in the log
(`r.log`).

Without a board, `emod.run_local()` builds and runs the same generated C on x86
as `main_local.elf`. An AIE-offloaded layer cannot link on x86, so use it
before step 5, or after `emod.offload("layer1", False)`.

---

## The same from the command line

```bash
aiegraph convert resnet18
aiegraph detect  src/aietensorop/conv2dstem/conv2dstem_uk.cc
aiegraph check   "layer1=src/aietensorop/conv2dstem/conv2dstem_uk.cc"
aiegraph offload "layer1=src/aietensorop/conv2dstem/conv2dstem_uk.cc"
aiegraph build

# or everything in one call:
aiegraph compile resnet18 aie "layer1=src/aietensorop/conv2dstem/conv2dstem_uk.cc"
```

`--workdir` defaults to `worklocal/aiegraph/resnet18`.

---

## Using your own kernel

To put a kernel you wrote on layer 1, or on any other layer:

```python
proto = emod.offload_prototype("layer1")   # the layer's args, roles and a proven AIEK_SPEC
proto.write("my_kernels/")                 # aiek_layer01.cc + aiek_layer01_ref.c + test_aiek_layer01.cc
# fill in the TODO(...) parts (the compute, staging, unpacking), then:
print(emod.offload_check("layer1", "my_kernels/aiek_layer01.cc"))
print(emod.offload(("layer1", "my_kernels/aiek_layer01.cc")))
```

The backbone already has the ports, the mesh split, the block loop and the
host launch for that layer. You write the math. See section 4b of the
[aiegraph user guide](../../doc/tutorial_aiegraph.md) and the
[user-kernel tutorial](../../doc/tutorial_userkernel.md).

---

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `download failed` at `ag.load` | No internet. Fetch the URL in `src/aiegraph/zoo.json` by hand and pass the file path to `ag.load()`. |
| `offload_check` stops at `detect ... require=range(-30,32)` | The model's own quantization parameters fall outside what the kernel supports (for example, torchvision's `IMAGENET1K_V1` weights give requantize shifts up to 50). The layer stays on the A78, or use `strict=False` with `ag.compile`. |
| `doctor` says not ready for `offload` | Vitis is not sourced, or `build/aiehlc` is not built. |
| A previous offload disappeared | `ag.embedded_convert` starts FRESH: earlier offloads are reset to the CPU. Pass `keep_offloads=True`, or use `ag.open(workdir)` to adopt the tree as it is. |
| Strange build failures in `thirdparty/alib` | Two `aiehlc.sh` builds ran at the same time. Each run wipes `thirdparty/alib/lib`, so run one at a time. |
