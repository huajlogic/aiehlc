###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""kcyc_lst on a minimal chess listing: a ZLS loop whose trip count is set by MOVA lc (gemm_plan's kernel), and a
persistent kernel's main that loops forever (no counted back branch: main is skipped, the kernel still counts)."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "src" / "costmodel" / "tools"))

import kcyc_lst  # noqa: E402

B = "    0x00 0x00 0x00 0x00  "  # bundle bytes (content irrelevant)


def _lst(tmp_path, lc_insn):
    lines = [
        ".label _main", ".function_start",
        "        0" + B + "NOP",
        ".loop_nesting 1",
        ".label __ll1__main",
        "        4" + B + "JL #100",
        "        8" + B + "J #4",
        ".loop_nesting 0",
        ".label _Z7gemm_kaP12input_window",
        ".function_start",
        "      100" + B + "%s" % lc_insn,
        "      104" + B + "NOP",
        ".loop_nesting 1",
        ".label ZLS_F_gemm_ka_108",
        "      108" + B + "VMAC dm0, dm0, x0, x1, r9",
        "      112" + B + "VLDA x0, [p0], #64; VMAC dm1, dm1, x0, x1, r9",
        ".label ZLE_F_gemm_ka_116",
        "      116" + B + "VMAC dm2, dm2, x0, x1, r9",
        ".loop_nesting 0",
        "      120" + B + "RET lr",
    ]
    p = tmp_path / "kernel.lst"
    p.write_text("\n".join(lines) + "\n")
    return str(p)


def test_mova_lc_and_persistent_main(tmp_path):
    for insn in ("MOVA lc, #7", "MOVX lc, #7", "MOV lc, #7"):
        r = kcyc_lst.analyse(_lst(tmp_path, insn), "gemm_ka")
        # 2 bundles before the loop + 7 x 3 loop bundles + RET
        assert r["kernel"] == 2 + 7 * 3 + 1, (insn, r)
        assert r["vmac"] == 7 * 3
        assert abs(r["static_eff"] - 21 / 24) < 1e-4
        assert r["main"] == 0 and "main_error" in r  # _main's endless J loop is not counted
