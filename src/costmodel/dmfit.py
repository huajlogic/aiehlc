###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Static core-tile fit check for dataflow-plan input rings: data memory (DM) and core locks.

Shared costmodel module (stdlib only).  It answers "does this ring layout still fit one AIE core?" for a
design whose kernel memory map is already known, without building the variant:

DM rule (dataflowplan planresource.cpp assignCores, plandma.cpp:284 deriveCoreSlots, plansynth.cpp:176):
  the plan's hosted input chunks live in the core memory the allocator gave the replaced ports' windows,
  ONE contiguous region of channels x slots x chunk bytes per hosted stream.  So a variant's DM is
      dm_pred = <DM Used of the measured map> - <bytes of the measured in-region> + in_bytes(variant)
  with in_bytes = max over hosted streams (layout "hosted": every core runs the same program and keeps the
  deepest stream's region) or the sum over streams (layout "private": every core holds every stream itself).
  fit_dm = dm_pred <= cap.

Lock rule (planresource.cpp:186): per stream (readers + 1) x channels reader locks plus one E lock per buffer
  (channels x slots), then one sync lock and (persistent kernel) one go lock; compared with the free core locks
  (count only; the compiler additionally needs each group in a row, so fit_lock=1 is an upper bound).

CLI:
  python3 -m costmodel.dmfit --map K.map --stream a:2:2:8192:2 --stream b:1:3:8192:2 [--layout hosted]
  python3 -m costmodel.dmfit --gemm90 {calib,b1d3,kc64b3,mtb3} --map K.map   (exactly one line on stdout)
"""

import argparse
import re
import sys
from dataclasses import dataclass
from typing import List, Tuple

DM_CAP = 65536          # core data memory (64 KiB)
REGION_RE = r"buf_in_(ping|pong)_\d+$"   # the replaced ports' input windows in an aiehlc kernel map


@dataclass
class Stream:
    """One input ring a core hosts: channels x slots buffers of chunk bytes, read by `readers` cores."""
    name: str
    channels: int
    slots: int
    chunk: int
    readers: int = 1

    @property
    def buffers(self) -> int:
        return self.channels * self.slots

    @property
    def bytes(self) -> int:
        return self.buffers * self.chunk

    def locks(self) -> int:
        return (self.readers + 1) * self.channels + self.buffers


@dataclass
class LockRule:
    free: int               # free core locks before the plan's own locks
    sync: int = 1
    go: int = 1             # persistent kernel: one go lock (0 if not persistent)


@dataclass
class MapInfo:
    used: int
    region_lo: int
    region_hi: int
    region_bytes: int


def parse_map(path: str, memory: str = "DMb", region_re: str = REGION_RE) -> MapInfo:
    """`Used` of one memory of an AIE linker map and the extent of the symbols matching region_re in it."""
    used = None
    syms: List[Tuple[int, int]] = []
    cur = None
    head = re.compile(r"^Memory map for memory '([^']+)'")
    usedre = re.compile(r"^\s+Used\s*=\s*(\d+)")
    symre = re.compile(r"^\s+0x([0-9a-fA-F]+)\.\.0x([0-9a-fA-F]+)\s+\(\s*(\d+) items\)\s*:\s*\S*?::(\S+)")
    rx = re.compile(region_re)
    with open(path) as f:
        for line in f:
            m = head.match(line)
            if m:
                cur = m.group(1)
                continue
            if line.startswith("Section summary"):
                cur = None
            if cur != memory:
                continue
            m = usedre.match(line)
            if m and used is None:
                used = int(m.group(1))
                continue
            m = symre.match(line)
            if m and rx.search(m.group(4)):
                lo, hi = int(m.group(1), 16), int(m.group(2), 16) + 1
                syms.append((lo, hi))
    if used is None:
        raise ValueError("%s: no 'Used' line for memory %s" % (path, memory))
    if not syms:
        raise ValueError("%s: no symbol matching %r in memory %s" % (path, region_re, memory))
    lo, hi = min(s[0] for s in syms), max(s[1] for s in syms)
    total = sum(s[1] - s[0] for s in syms)
    if hi - lo != total:
        raise ValueError("%s: in-region %#x..%#x is not contiguous (%d B in %d B)" % (path, lo, hi, total, hi - lo))
    return MapInfo(used, lo, hi, total)


def in_bytes(streams: List[Stream], layout: str) -> int:
    if layout == "hosted":
        return max(s.bytes for s in streams)
    if layout == "private":
        return sum(s.bytes for s in streams)
    raise ValueError("layout must be hosted or private, not %r" % layout)


def locks_need(streams: List[Stream], layout: str, rule: LockRule) -> int:
    per = [s.locks() for s in streams]
    core = max(per) if layout == "hosted" else sum(per)
    return core + rule.sync + rule.go


def fit(info: MapInfo, streams: List[Stream], layout: str, rule: LockRule, cap: int = DM_CAP) -> dict:
    dm = info.used - info.region_bytes + in_bytes(streams, layout)
    need = locks_need(streams, layout, rule)
    return {"dm_pred": dm, "cap": cap, "fit_dm": int(dm <= cap), "locks_need": need,
            "locks_free": rule.free, "fit_lock": int(need <= rule.free)}


# ---------------------------------------------------------------- gemm90 4096^3 (m33621242222122212) instances
# Free core locks: what the compiler reported when it refused A1B3 (per-stream depth, PS probe
# xiaojiang/clones/gemm/tasks/ps/probe.out:764 "not enough free core locks (6 left; ...)").
G90_LOCKS = LockRule(free=6, sync=1, go=1)
G90_READERS = 2          # neighbor share: every chunk is read by 2 cores
# Variants (PR brief, des.py --gemm90-price-v): A ring keeps 2 channels x a_depth; B ring b_ch x b_depth.
G90_VARIANTS = {
    #          layout     streams
    "b1d3": ("hosted", [Stream("a", 2, 2, 8192, G90_READERS), Stream("b", 1, 3, 8192, G90_READERS)]),
    "kc64b3": ("hosted", [Stream("a", 2, 2, 4096, G90_READERS), Stream("b", 2, 3, 4096, G90_READERS)]),
    # MemTile broadcast: A and B private on every core, 1 channel each -> in-region A 2x4096 + B 3x4096
    "mtb3": ("private", [Stream("a", 1, 2, 4096, 1), Stream("b", 1, 3, 4096, 1)]),
}
# Calibration references (r2/pz.txt, r2/ps.txt): base map DM, PZ U/R arithmetic, the A1B3 lock refusal.
G90_CAL = {"dm": 61533, "pz_ur": 77917, "pz_ahost": 45149, "lock_ref_fit": 0, "lock_ref_free": 6}


def gemm90_line(v: str, map_path: str) -> str:
    info = parse_map(map_path)
    if v == "calib":
        ur = fit(info, [Stream("u", 2, 3, 8192, G90_READERS)], "hosted", G90_LOCKS)["dm_pred"]
        ah = fit(info, [Stream("a", 2, 1, 8192, G90_READERS)], "hosted", G90_LOCKS)["dm_pred"]
        ref = fit(info, [Stream("a", 2, 1, 8192, G90_READERS), Stream("b", 2, 3, 8192, G90_READERS)],
                  "hosted", G90_LOCKS)
        ok = int(info.used == G90_CAL["dm"] and info.region_bytes == 32768 and ur == G90_CAL["pz_ur"] and
                 ah == G90_CAL["pz_ahost"] and ref["fit_lock"] == G90_CAL["lock_ref_fit"] and
                 ref["locks_free"] == G90_CAL["lock_ref_free"])
        return "FITCAL dm=%d pz_ur=%d pz_ahost=%d lock_ref=A1B3:fit_lock=%d:free=%d ok=%d" % (
            info.used, ur, ah, ref["fit_lock"], ref["locks_free"], ok)
    if v not in G90_VARIANTS:
        raise ValueError("unknown gemm90 variant %r (calib, %s)" % (v, ", ".join(G90_VARIANTS)))
    layout, streams = G90_VARIANTS[v]
    r = fit(info, streams, layout, G90_LOCKS)
    return "FIT v=%s dm_pred=%d cap=%d fit_dm=%d locks_need=%d locks_free=%d fit_lock=%d" % (
        v, r["dm_pred"], r["cap"], r["fit_dm"], r["locks_need"], r["locks_free"], r["fit_lock"])


def parse_stream(s: str) -> Stream:
    p = s.split(":")
    if len(p) not in (4, 5):
        raise argparse.ArgumentTypeError("stream is name:channels:slots:chunk[:readers], not %r" % s)
    return Stream(p[0], *[int(x) for x in p[1:]])


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(prog="costmodel.dmfit", description=__doc__.splitlines()[0])
    ap.add_argument("--map", required=True, help="AIE kernel linker map of the measured base design")
    ap.add_argument("--gemm90", help="calib | b1d3 | kc64b3 | mtb3")
    ap.add_argument("--stream", action="append", type=parse_stream, default=[])
    ap.add_argument("--layout", default="hosted", choices=["hosted", "private"])
    ap.add_argument("--memory", default="DMb")
    ap.add_argument("--region-re", default=REGION_RE)
    ap.add_argument("--cap", type=int, default=DM_CAP)
    ap.add_argument("--locks-free", type=int, default=G90_LOCKS.free)
    ap.add_argument("--no-go", action="store_true", help="not a persistent kernel (no go lock)")
    a = ap.parse_args(argv)
    try:
        if a.gemm90:
            print(gemm90_line(a.gemm90, a.map))
            return 0
        if not a.stream:
            ap.error("give --gemm90 or at least one --stream")
        info = parse_map(a.map, a.memory, a.region_re)
        r = fit(info, a.stream, a.layout, LockRule(a.locks_free, 1, 0 if a.no_go else 1), a.cap)
        print(" ".join("%s=%s" % kv for kv in r.items()))
        return 0
    except (OSError, ValueError) as e:
        print("dmfit: error: %s" % e, file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
