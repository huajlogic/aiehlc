#!/usr/bin/env python3
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
"""Compare the MAC inner loops of two AIE kernel builds by instruction sequence.

chess does not emit exactly the same program on every rebuild (gemm_plan: 1833 and 1829 bundles), so a
bundle count cannot say whether the MAC loop changed. This reads the kernel listing (`kernel.lst`, next to
the kernel ELF in aout/worklocal/build/), cuts it into straight-line blocks (a label or directive line ends
a block), keeps the blocks that hold VMAC instructions, and reduces every bundle to its mnemonics (registers
and addresses differ between builds for the same code; NOP slot fillers too). Two blocks are the same MAC
loop when their VECTOR instructions (V*) match bundle by bundle -- the scalar address arithmetic moves
between bundles from one chess run to the next (gemm_plan, kernel.cc byte-identical: 1 of 5 blocks differs
by one ADD) and is reported, not counted. One listing: a table of the MAC blocks. Two listings: each MAC
block of the first is looked up in the second.

    python3 script/perf/macloop.py aout/worklocal/build/kernel.lst
    python3 script/perf/macloop.py old/kernel.lst new/kernel.lst      # exit 1 when a MAC block differs
"""
import hashlib
import re
import sys

# "        5532    0x65 0x84 ... 0x05  PADDA [p3], #128;   VMAC dm1, dm0, x10, x6, r9"
INSN = re.compile(r"^\s+(\d+)\s+((?:0x[0-9a-fA-F]{2}\s+)+)(.*)$")
MAC = re.compile(r"\bVMAC\w*\b")


def bundles(path):
    """Straight-line blocks of bundles: lists of (address, [mnemonic slots])."""
    blocks, cur = [], []
    with open(path, errors="replace") as f:
        for line in f:
            m = INSN.match(line)
            if not m:
                if cur:
                    blocks.append(cur)
                    cur = []
                continue
            slots = [s.strip() for s in m.group(3).split(";") if s.strip()]
            # NOP slot fillers (NOP, NOPX, NOPA, ...) vary between rebuilds of the same code: not part of it
            cur.append((int(m.group(1)), [s.split()[0] for s in slots if not s.split()[0].startswith("NOP")]))
    if cur:
        blocks.append(cur)
    return blocks


def mac_blocks(path, min_macs=4):
    out = []
    for b in bundles(path):
        macs = sum(1 for _, slots in b for s in slots if MAC.match(s))
        if macs >= min_macs:
            seq = "\n".join(" ".join(sorted(slots)) for _, slots in b)
            # the vector side alone (VMAC, VLDA / VLDB, VST, VMOV, ...): what the MAC loop is; the scalar address
            # arithmetic around it moves between bundles from one chess run to the next
            vseq = "\n".join(" ".join(sorted(s for s in slots if s.startswith("V"))) for _, slots in b)
            out.append({"addr": b[0][0], "bundles": len(b), "macs": macs,
                        "sig": hashlib.sha1(seq.encode()).hexdigest()[:12],
                        "vsig": hashlib.sha1(vseq.encode()).hexdigest()[:12], "seq": seq})
    return out


def table(blocks):
    for x in blocks:
        print(f"  @{x['addr']:<6} {x['bundles']:4d} bundles {x['macs']:4d} VMAC  "
              f"{x['macs'] / x['bundles']:.2f} VMAC/bundle  vector sig {x['vsig']}  sig {x['sig']}")


def main(argv):
    if len(argv) not in (2, 3):
        print(__doc__)
        return 2
    a = mac_blocks(argv[1])
    print(f"{argv[1]}: {len(a)} MAC block(s), {sum(x['macs'] for x in a)} VMAC")
    table(a)
    if len(argv) == 2:
        return 0
    b = mac_blocks(argv[2])
    print(f"{argv[2]}: {len(b)} MAC block(s), {sum(x['macs'] for x in b)} VMAC")
    table(b)
    sigs_b, vsigs_b = {x["sig"] for x in b}, {x["vsig"] for x in b}
    diff = [x for x in a if x["vsig"] not in vsigs_b]
    if not diff and len(a) == len(b):
        scalar = sum(1 for x in a if x["sig"] not in sigs_b)
        print("macloop: SAME -- every MAC block has the same vector instruction sequence"
              + (f" ({scalar} block(s) schedule their scalar instructions differently)" if scalar else ""))
        return 0
    for x in diff:
        print(f"macloop: block @{x['addr']} ({x['bundles']} bundles, {x['macs']} VMAC) has no match in the second")
    print(f"macloop: DIFFERENT -- {len(diff)} of {len(a)} MAC block(s) changed"
          + ("" if len(a) == len(b) else f", block count {len(a)} -> {len(b)}"))
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
