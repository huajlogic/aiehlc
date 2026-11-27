# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
"""Put the qwen weight blob into a palmyra's DDR_LOW1 and build the baremetal apps.

  qwen_board.py loaders <blob> <outdir>     one loader ELF per <= 1.75 GiB chunk (qwen_load.c + the chunk)
  qwen_board.py load <outdir>               run them in order on the board (apppaltest --netload), check sums
  qwen_board.py elf <out> <src.c>... [-D..] a plain baremetal A78 ELF (BSP, newlib) from C sources

netboot places ELF segments in DDR_LOW0 only, so a loader carries its chunk at QW_STAGE and copies it to
QW_BASE + offset in DDR_LOW1 (0x8_0000_0000, 6 GiB on this design); DDR keeps it between runs.
"""
import argparse, os, re, subprocess, sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "../../../.."))
BSP = os.path.join(REPO, "thirdparty/arch/cortexa78_0/workspace/platform_baremetal/cortexa78_0/"
                         "standalone_cortexa78_0/bsp")
LSCRIPT = os.path.join(REPO, "thirdparty/arch/cortexa78_0/lscript.ld")
CROSS = os.environ.get("CROSS_COMPILE", "aarch64-none-elf-")
QW_BASE = 0x8_0000_0000
QW_STAGE = 0x0400_0000
CHUNK = 0x7000_0000  # QW_STAGE + CHUNK stays below the supervisor (0x7800_0000)


def sh(cmd, **kw):
    print("+", " ".join(cmd) if isinstance(cmd, list) else cmd, flush=True)
    subprocess.run(cmd, check=True, **kw)


def build_elf(out, srcs, defs=(), objs=(), heap=0x0100_0000, extra_ld=(), opt="-O2", incs=(), libs=()):
    cflags = [opt, "-mcpu=cortex-a78", "-I" + os.path.join(BSP, "include"), "-ffunction-sections", "-fdata-sections"]
    cflags += ["-I" + i for i in incs] + ["-D" + d for d in defs]
    ld = ["--specs=nosys.specs", "-Wl,--defsym,end=__bss_end__", f"-Wl,--defsym,_HEAP_SIZE=0x{heap:x}",
          "-Wl,-T," + LSCRIPT, "-L" + os.path.join(BSP, "lib"), *extra_ld,
          "-Wl,--start-group,-lm," + "".join(f"-l{l}," for l in libs) +
          "-lxil,-lgcc,-lc,-lstdc++,-lxiltimer,-lxilstandalone,-lxilpm_ng,--end-group"]
    sh([CROSS + "g++" if libs or objs else CROSS + "gcc", *cflags, "-o", out, *srcs, *objs, *ld])


def compile_objs(outdir, srcs, defs=(), incs=(), opt="-O3"):
    """cross-compile C / C++ sources (as C++, like build_elf with archives) to objects in outdir"""
    os.makedirs(outdir, exist_ok=True)
    objs = []
    for src in srcs:
        o = os.path.join(outdir, os.path.splitext(os.path.basename(src))[0] + ".o")
        sh([CROSS + "g++", "-x", "c++", opt, "-mcpu=cortex-a78", "-I" + os.path.join(BSP, "include"),
            "-ffunction-sections", "-fdata-sections", *["-I" + i for i in incs], *["-D" + d for d in defs],
            "-c", "-o", o, src])
        objs.append(o)
    return objs


def qw_sum(b):
    w = np.frombuffer(b, dtype="<u8")
    return int(np.bitwise_xor(w, np.arange(len(w), dtype=np.uint64)).sum(dtype=np.uint64))


def loaders(blob, outdir, bases=None):
    os.makedirs(outdir, exist_ok=True)
    size = os.path.getsize(blob)
    manifest = []
    with open(blob, "rb") as f:
        for i, off in enumerate(range(0, size, CHUNK)):
            dst = bases[i] if bases else QW_BASE + off
            data = f.read(min(CHUNK, size - off))
            data += b"\0" * (-len(data) % 8)
            d = os.path.join(outdir, f"chunk{i}")
            os.makedirs(d, exist_ok=True)
            with open(os.path.join(d, "payload.bin"), "wb") as p:
                p.write(data)
            sh([CROSS + "objcopy", "-I", "binary", "-O", "elf64-littleaarch64", "-B", "aarch64",
                "--rename-section", ".data=.qwpayload,alloc,load,readonly,data,contents", "payload.bin", "payload.o"],
               cwd=d)
            os.remove(os.path.join(d, "payload.bin"))
            elf = os.path.join(d, "qwen_load.elf")
            build_elf(elf, [os.path.join(HERE, "qwen_load.c")],
                      defs=[f"QW_DST=0x{dst:x}ULL", f"QW_BYTES={len(data)}ULL"],
                      objs=[os.path.join(d, "payload.o")],
                      extra_ld=[f"-Wl,--section-start=.qwpayload=0x{QW_STAGE:x}"])
            os.remove(os.path.join(d, "payload.o"))
            manifest.append((elf, dst, len(data), qw_sum(data)))
            print(f"chunk {i}: 0x{dst:x} {len(data)} B sum 0x{manifest[-1][3]:016x}", flush=True)
    with open(os.path.join(outdir, "manifest.txt"), "w") as m:
        for e in manifest:
            m.write(f"{e[0]} 0x{e[1]:x} {e[2]} 0x{e[3]:016x}\n")


def load(outdir, board="palmyra", host=None):
    ok = True
    for line in open(os.path.join(outdir, "manifest.txt")):
        elf, dst, n, want = line.split()
        cmd = [sys.executable, os.path.join(REPO, "script/test/apppaltest.py"), "-board", board, "-y", "--netload",
               "--netload-max-run-ms", "120000", "--lock-wait", "7200"] + (["-host", host] if host else []) + [elf]
        r = subprocess.run(cmd, capture_output=True, text=True, cwd=REPO)
        log = r.stdout + r.stderr
        open(elf + ".applog", "w").write(log)
        m = re.search(r"QWLOAD dst=(0x[0-9a-f]+) bytes=(\d+) sum=(0x[0-9a-f]+)", log)
        got = m.group(3) if m else None
        good = m is not None and int(m.group(1), 16) == int(dst, 16) and int(got, 16) == int(want, 16)
        ok &= good
        print(f"{'OK  ' if good else 'FAIL'} {dst} {n} B sum {got} (want {want})", flush=True)
        if not good:
            print(log[-3000:])
            break
    return ok


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sp = ap.add_subparsers(dest="cmd", required=True)
    a1 = sp.add_parser("loaders"); a1.add_argument("blob"); a1.add_argument("outdir")
    a1.add_argument("--bases", help="comma list: segment i's DDR address (default: consecutive from 0x8_0000_0000)")
    a2 = sp.add_parser("load"); a2.add_argument("outdir")
    a2.add_argument("--board", default="palmyra"); a2.add_argument("--host")
    a3 = sp.add_parser("elf"); a3.add_argument("out"); a3.add_argument("srcs", nargs="+")
    a3.add_argument("-D", dest="defs", action="append", default=[])
    a3.add_argument("-I", dest="incs", action="append", default=[])
    a3.add_argument("--heap", type=lambda v: int(v, 0), default=0x1000_0000)
    a3.add_argument("--opt", default="-O3")
    a3.add_argument("--obj", action="append", default=[], help="extra object / archive (e.g. libqwen_gemv_lib.a)")
    a3.add_argument("-L", dest="libdirs", action="append", default=[])
    a3.add_argument("-l", dest="libs", action="append", default=[])
    a3.add_argument("--ld", action="append", default=[], help="extra link flag, e.g. -Wl,--defsym=SYM=ADDR")
    a = ap.parse_args()
    if a.cmd == "loaders":
        loaders(a.blob, a.outdir, [int(x, 0) for x in a.bases.split(",")] if a.bases else None)
    elif a.cmd == "load":
        sys.exit(0 if load(a.outdir, a.board, a.host) else 1)
    else:
        build_elf(a.out, a.srcs, defs=a.defs, heap=a.heap, opt=a.opt, incs=a.incs, objs=a.obj,
                  extra_ld=["-L" + d for d in a.libdirs] + a.ld, libs=a.libs)


if __name__ == "__main__":
    main()
