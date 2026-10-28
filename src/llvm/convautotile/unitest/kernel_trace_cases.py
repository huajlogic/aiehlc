#!/usr/bin/env python3
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Kernel-analysis regression: each case mutates the kernel-only conv example
(example/tileprogram/ccode/simpleconv2dkernel.cc) into one logic bug and checks
`aiehlc-convtile trace` rejects it with the expected diagnostic.

    python3 src/llvm/convautotile/unitest/kernel_trace_cases.py [build/aiehlc-convtile]
"""
import pathlib
import shutil
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parents[4]
CCODE = REPO / "example" / "tileprogram" / "ccode"
BASE = CCODE / "simpleconv2dkernel.cc"
LOAD_X = "const int8_t *x = aie::load_buffer(win_a, {oh0 * S, ow0 * S, 0}, {ih_t, iw_t, C});"

# (name, [(old, new), ...], expected substring in the output; None = must pass)
CASES = [
    ("baseline", [], None),
    ("load too big",
     [(LOAD_X, LOAD_X.replace("{ih_t, iw_t, C}", "{ih_t + 1, iw_t, C}"))],
     "is too big in dim 0 (rows): it takes 20, the DMA block is 19"),
    # A slab narrower than the conv footprint makes the compute read past it:
    # caught first as data used without being loaded (at the exact line).
    ("load too small",
     [(LOAD_X, LOAD_X.replace("{ih_t, iw_t, C}", "{ih_t, iw_t - 2, C}"))],
     "data used without being loaded"),
    ("weights offset out of the tensor (pid_c * oc_t * 20)",
     [("{pid_c * oc_t, 0, 0, 0}", "{pid_c * oc_t * 20, 0, 0, 0}")],
     "outside the tensor extent 64"),
    ("data used without load (reads past the block)",
     [("x[((oh * S + kh) * iw_t + ow * S + kw) * C + c]", "x[((oh * S + kh + 1) * iw_t + ow * S + kw) * C + c]")],
     "data used without being loaded"),
    ("data used after release",
     [("            int8_t *y = aie::store_buffer(", "            aie::release(win_a);\n            int8_t *y = aie::store_buffer("),
      ("            aie::release(win_a);\n            aie::commit(win_c);", "            aie::commit(win_c);")],
     "uses a block after aie::release"),
    ("output never committed",
     [("            aie::commit(win_c);\n", "")],
     "never committed"),
    ("loop order swapped (j outer)",
     [("for (int i = 0; i < oh_core / oh_t; i++) {   // 4 row blocks", "for (int j = 0; j < 112 / ow_t; j++) {"),
      ("for (int j = 0; j < 112 / ow_t; j++) {   // 4 column blocks", "for (int i = 0; i < oh_core / oh_t; i++) {")],
     "visited column-outer"),
    ("schedule depends on data",
     [("            aie::release(win_a);\n", "            if (x[0] > 0) { aie::release(win_a); x = aie::load_buffer(win_a, {oh0 * S, ow0 * S, 0}, {ih_t, iw_t, C}); }\n            aie::release(win_a);\n")],
     "depends on the data"),
    ("output not fully written",
     [("for (int j = 0; j < 112 / ow_t; j++) {   // 4 column blocks", "for (int j = 0; j < 112 / ow_t - 1; j++) {")],
     "never stored"),
    ("weights never loaded",
     [("    const int8_t *w = aie::load_buffer(win_b, {pid_c * oc_t, 0, 0, 0}, {oc_t, KH, KW, C});",
       "    static int8_t w[16 * 196];"),
      ("    aie::release(win_b);\n", "")],
     "is never loaded"),
    ("store on an input port",
     [("int8_t *y = aie::store_buffer(win_c,", "int8_t *y = aie::store_buffer(win_a,")],
     "aie::store_buffer on an input port"),
    ("block larger than core memory",
     [(LOAD_X, LOAD_X.replace("{oh0 * S, ow0 * S, 0}, {ih_t, iw_t, C}", "{0, 0, 0}, {230, 230, 4}"))],
     "larger than the core data memory"),
]


def run_case(cli, name, edits, expect):
    src = BASE.read_text()
    for old, new in edits:
        if old not in src:
            return False, f"mutation anchor not found: {old[:60]!r}"
        src = src.replace(old, new, 1)
    with tempfile.TemporaryDirectory() as tmp:
        for h in CCODE.glob("*.h"):
            shutil.copy(h, tmp)
        path = pathlib.Path(tmp) / "case.cc"
        path.write_text(src)
        p = subprocess.run([cli, "trace", str(path)], capture_output=True, text=True, timeout=600)
        out = p.stdout + p.stderr
    if expect is None:
        return p.returncode == 0, out
    return p.returncode == 2 and expect in out, out


def main():
    cli = sys.argv[1] if len(sys.argv) > 1 else str(REPO / "build" / "aiehlc-convtile")
    failed = 0
    for name, edits, expect in CASES:
        ok, out = run_case(cli, name, edits, expect)
        print(f"{'ok  ' if ok else 'FAIL'} {name}")
        if not ok:
            failed += 1
            print("     expected:", expect)
            print("     " + "\n     ".join(out.strip().splitlines()[-8:]))
        elif expect:
            line = next((l for l in out.splitlines() if expect in l), "")
            print("     " + line.strip()[:200])
    print(f"kernel_trace_cases: {len(CASES) - failed} passed, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
