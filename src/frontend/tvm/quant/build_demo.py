###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Build the int8 ResNet-18 classifier: ONNX -> quantize -> C -> binary.

    python src/frontend/tvm/quant/build_demo.py [image] [-o OUTDIR] [--run]

Produces in ``OUTDIR``:

* ``weights.bin``     — 11.7 MB int8 weight blob
* ``resnet_int8.c``   — generated network (kernels + layer sequence)
* ``input.bin``       — the image, preprocessed and quantized to int8
* ``main.c``          — host entry printing the top-5
* ``labels.h``        — ImageNet class names

With ``--run`` it also compiles natively (gcc) and classifies, so the whole
chain is exercised in one command.

Preprocessing is **not** a free choice
--------------------------------------
The image must arrive in exactly the form the network was calibrated for:
resize-256 / center-crop-224 / ImageNet mean-std normalize (``classify.py``),
then quantized with the *calibrated input scale*. Feeding raw [0,255] pixels, or
quantizing with a different scale, silently produces garbage — the weights are
fine, the input simply is not on the scale the first layer expects. That is why
``input.bin`` is emitted here rather than left to the caller.
"""

import argparse
import os
import shutil
import subprocess
import sys

import numpy as np

_HERE = os.path.dirname(os.path.abspath(__file__))
_SRC = os.path.dirname(os.path.dirname(os.path.dirname(_HERE)))
_ROOT = os.path.dirname(_SRC)
for _p in (_SRC, os.path.join(_ROOT, "example", "model", "resnet18py")):
    if _p not in sys.path:
        sys.path.insert(0, _p)

from frontend.tvm.quant.emit_c import ResNetCEmitter          # noqa: E402
from frontend.tvm.quant.qresnet import QuantResNet18          # noqa: E402
from frontend.tvm.quant.resnet_np import ResNet18V2NP         # noqa: E402

MAIN_C = r"""
#include <stdint.h>
#include <stdio.h>
#include <math.h>
#include "labels.h"

void run_resnet(const int8_t *input, float *logits);

/* The preprocessed image as float32 (resize/crop/mean-std already applied),
 * linked in as a binary blob. It is quantized HERE, on target, rather than
 * host-side: that way the affine quantization is part of what the ELF
 * actually executes, matching how a camera-fed pipeline would work. */
extern const unsigned char _binary_input_f32_bin_start[];

#define NUM_CLASSES 1000
#define INPUT_LEN (3 * 224 * 224)

/* Calibrated input quantization params (see build_demo.py). */
#define INPUT_SCALE %INPUT_SCALE%f
#define INPUT_ZP %INPUT_ZP%

static int8_t quant_input[INPUT_LEN];

int main(void) {
    static float logits[NUM_CLASSES];

    /* Asymmetric quantize: q = round(x/scale) + zp, clamped to int8. The
     * scale/zp come from calibration, NOT from this image's own range -- the
     * network's first layer expects that specific scale. */
    const float *px = (const float *)_binary_input_f32_bin_start;
    for (int i = 0; i < INPUT_LEN; ++i) {
        float v = px[i] / INPUT_SCALE + (INPUT_ZP);
        int r = (int)(v < 0.0f ? v - 0.5f : v + 0.5f);   /* round half away */
        if (r < -128) r = -128;
        if (r >  127) r =  127;
        quant_input[i] = (int8_t)r;
    }
    run_resnet(quant_input, logits);

    /* Softmax. Subtracting the max before exp is not cosmetic: raw logits
     * reach ~13 here and expf() overflows to inf well before the sum is
     * formed, which would turn every probability into nan. */
    float mx = logits[0];
    for (int i = 1; i < NUM_CLASSES; ++i) if (logits[i] > mx) mx = logits[i];
    double sum = 0.0;
    for (int i = 0; i < NUM_CLASSES; ++i) sum += exp((double)(logits[i] - mx));

    /* Top-5 by repeated max: NUM_CLASSES is small and this avoids pulling in
     * qsort (and a comparator) on a baremetal target. */
    int taken[5];
    printf("ImageNet top-5:\n");
    for (int r = 0; r < 5; ++r) {
        int best = -1;
        for (int i = 0; i < NUM_CLASSES; ++i) {
            int used = 0;
            for (int j = 0; j < r; ++j) if (taken[j] == i) used = 1;
            if (!used && (best < 0 || logits[i] > logits[best])) best = i;
        }
        taken[r] = best;
        double prob = exp((double)(logits[best] - mx)) / sum * 100.0;
        printf("  %d. %-40s %6.2f%%   logit %8.4f  (class %d)\n",
               r + 1, imagenet_labels[best], prob, (double)logits[best], best);
    }

    /* Completion marker. script/test/apppaltest.py polls the console for
     * "device_teardown done" to know the program finished (apppaltest.py:719);
     * without it the harness sits until its 300 s no-output timeout and the
     * run looks like a hang even though the answer already printed. This
     * program owns no device -- there is nothing to tear down -- so the marker
     * is emitted directly rather than by calling into the AIE runtime. */
    printf("device_teardown done rc=0\n");
    return 0;
}
"""


def build(image_path: str, out_dir: str, run: bool = False,
          target: str = "x86") -> dict:
    """Quantize, emit, and compile. Returns the manifest.

    ``target="x86"`` compiles for the host (and runs it when ``run``);
    ``target="aarch64"`` links a baremetal ELF for the board instead.
    """
    from classify import (resolve, preprocess, load_labels,
                          DEFAULT_IMAGE_URL, DEFAULT_WEIGHTS_URL,
                          DEFAULT_LABELS_URL)
    os.makedirs(out_dir, exist_ok=True)
    img = resolve(image_path, DEFAULT_IMAGE_URL, "input_image")
    wts = resolve(None, DEFAULT_WEIGHTS_URL, "resnet18-v2-7.onnx")
    labels = load_labels(resolve(None, DEFAULT_LABELS_URL,
                                 "imagenet_classes.txt"))

    print(f"[1/5] preprocessing {img}")
    x = preprocess(img).numpy()

    print("[2/5] loading float model + calibrating activation ranges")
    net = ResNet18V2NP(wts)
    ref = net.forward(x)[0]
    print(f"      float reference: {labels[ref.argmax()]} (class {ref.argmax()})")
    qp = QuantResNet18.calibrate(net, [x])

    print("[3/5] quantizing weights to int8")
    q = QuantResNet18.from_float(net, qp)

    print("[4/5] emitting C + weight blob")
    man = ResNetCEmitter(q).emit(out_dir)
    # Embed the PREPROCESSED FLOAT image; the ELF quantizes it on target with
    # the calibrated scale/zp (baked into main.c below). Emitting int8 here
    # instead would move the quantizer out of the program being verified.
    x.astype(np.float32).tofile(os.path.join(out_dir, "input_f32.bin"))
    # input.bin (pre-quantized) is still written: the test suite and the
    # numpy-vs-C comparison use it as a reference input.
    qp["input"].quantize(x).astype(np.int8).tofile(
        os.path.join(out_dir, "input.bin"))
    with open(os.path.join(out_dir, "labels.h"), "w") as f:
        f.write("static const char *const imagenet_labels[] = {\n")
        for name in labels:
            f.write('    "%s",\n' % name.replace('"', r'\"'))
        f.write("};\n")
    with open(os.path.join(out_dir, "main.c"), "w") as f:
        f.write(MAIN_C.replace("%INPUT_SCALE%", repr(float(qp["input"].scale)))
                      .replace("%INPUT_ZP%", str(int(qp["input"].zp))))
    print(f"      weights.bin {man['blob_bytes']/1e6:.2f} MB, "
          f"{man['entries']} tensors")
    print(f"      input scale={qp['input'].scale:.6g} zp={qp['input'].zp}")

    if target == "aarch64":
        elf = build_aarch64(out_dir)
        print(f"[5/5] built baremetal ELF -> {elf}")
        print("      run on the board with:")
        print(f"        python3 script/test/apppaltest.py {elf}")
        return man

    if not run:
        print("[5/5] sources emitted (pass --run to compile and classify)")
        return man

    print("[5/5] compiling natively and classifying")
    for src, obj in (("weights.bin", "weights.o"),
                     ("input_f32.bin", "input_f32.o")):
        subprocess.run(["ld", "-r", "-b", "binary", "-o", obj, src],
                       cwd=out_dir, check=True)
    subprocess.run(["gcc", "-O2", "-o", "classify_int8", "resnet_int8.c",
                    "main.c", "weights.o", "input_f32.o", "-I.", "-lm"],
                   cwd=out_dir, check=True)
    subprocess.run([os.path.join(out_dir, "classify_int8")], check=True)
    return man


# ═══════════════════════════════════════════════════════════════════════════
#  Baremetal aarch64 build — the same sources, linked for the board
# ═══════════════════════════════════════════════════════════════════════════
#
# Deliberately NOT routed through script/hostcompile.sh. That script exists to
# link a *generated AIE host* (host.cc + aie_runtime.c + the XAie driver + an
# embedded kernel ELF); this program uses none of it -- no device, no DMA, no
# stream switches, just ~11.8 MB of int8 weights and integer arithmetic on the
# ARM core. Pulling in the runtime would add a dependency on XAie headers and
# the routing() extern for no benefit. So it links directly against the same
# BSP/linker script hostcompile.sh uses, and nothing else.

def build_aarch64(out_dir: str, repo_root: str = None) -> str:
    """Link the emitted sources into a baremetal aarch64 ELF for the board.

    Uses the Vitis aarch64-none-elf toolchain and the cortexa78 BSP
    (``thirdparty/arch/cortexa78_0``) so the result boots the same way the AIE
    host ELFs do. Returns the ELF path.

    Requires ``script/setup.sh --path-set-only`` to have been sourced (for
    ``$XILINX_VITIS`` and the cross toolchain on PATH).
    """
    # Absolute: the compiler runs with cwd=out_dir, so a relative output path
    # would be resolved twice (once by us, once by the compiler) and land in a
    # directory that does not exist.
    out_dir = os.path.abspath(out_dir)
    repo_root = repo_root or _ROOT
    cc = "aarch64-none-elf-gcc"
    ld = "aarch64-none-elf-ld"
    if not shutil.which(cc):
        raise RuntimeError(
            f"{cc} not on PATH; source script/setup.sh --path-set-only first")
    arch = os.path.join(repo_root, "thirdparty", "arch", "cortexa78_0")
    bsp = os.path.join(arch, "bsp")          # headers + libs live under bsp/
    lscript = os.path.join(arch, "lscript.ld")
    if not os.path.isfile(lscript):
        raise RuntimeError(f"linker script not found: {lscript}")

    # The image and weights ride along as binary blobs, exactly as on x86.
    for src, obj in (("weights.bin", "weights.o"),
                     ("input_f32.bin", "input_f32.o")):
        subprocess.run([ld, "-r", "-b", "binary", "-o", obj, src],
                       cwd=out_dir, check=True)
    elf = os.path.join(out_dir, "classify_int8.elf")
    cmd = [cc, "-Os", "-mcpu=cortex-a78",
           "-I", ".", "-I", os.path.join(bsp, "include"),
           "-o", elf, "resnet_int8.c", "main.c", "weights.o", "input_f32.o",
           "--specs=nosys.specs",
           "-Wl,--defsym,end=__bss_end__",
           "-Wl,-T", "-Wl," + lscript,
           "-L", os.path.join(bsp, "lib"),
           "-Wl,--start-group,-lm,-lxil,-lgcc,-lc,-lxiltimer,"
           "-lxilstandalone,-lxilpm_ng,--end-group"]
    r = subprocess.run(cmd, cwd=out_dir, capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"aarch64 link failed:\n{r.stderr[-3000:]}")
    return elf


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("image", nargs="?", default=None,
                    help="image path or URL (default: the sample dog)")
    ap.add_argument("-o", "--out", default="./worklocal/resnet_int8",
                    help="output directory")
    ap.add_argument("--run", action="store_true",
                    help="also compile natively (x86) and classify")
    ap.add_argument("--target", choices=("x86", "aarch64"), default="x86",
                    help="aarch64 => baremetal ELF for the board "
                         "(needs script/setup.sh --path-set-only)")
    a = ap.parse_args()
    build(a.image, a.out, a.run, a.target)
    return 0


if __name__ == "__main__":
    sys.exit(main())
