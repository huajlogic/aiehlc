#!/usr/bin/env python3
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
"""Add the 2 x 8 shared-operand dataflow plan to a dumped dmaphop IR.

    gen_plan.py <ir/dfschedule/3_DmapToDmaphopPass.mlir> <out.mlir> [--r2 60] [--k 2560] [--fb 10]

The output is the input IR plus `dmaphop.plan*` ops at the top of @main (doc/design/
dmaphop_dataflow_plan.md). Build with it:

    AIEHLC_DMAPHOP_IR_IN=<out.mlir> source script/aiehlc.sh ... --runtime-source-file gemm_plan.cc

What the plan says -- the DATAFLOW decisions (dmaphop); the compiler allocates the BD / lock ids and
buffer addresses against the generated flows (planresource.cpp), derives the DMA program that realizes
the decisions and writes it as dfschedule ops (doc/design/dmaphop_dataflow_plan.md, plandma.cpp).
Every route names the stream it carries (arg):
  * routes: shim col c MM2S ch1 (A) -> MemTile (c, 2), ch0 (B) -> MemTile (c, 1); MemTile (c, 2)
    MM2S ch1 broadcasts A strip c >> 1, chunk parity c & 1, to the 4 cores of mesh row 0 / 3;
    MemTile (c, 1) MM2S m replays B strip c + 4 (m >> 1), parity m & 1, to core (c, 4 + (m >> 1)).
  * stream a (arg 0): staged through a MemTile FIFO ring of FB buffers, hosted by mesh rows 0 / 3,
    read first by rows 0 / 2;
  * stream b (arg 1): held in a MemTile across launches (loaded on the first launch only), hosted by
    mesh rows 1 / 2, read first by rows 0 / 1.
"""
import argparse
import re
import sys


def plan_ops(r2, nk, fb, cols=(1, 2, 3, 4), core_rows=(3, 4, 5, 6), m=7680, n=512, k=2560):
    """The dataflow decisions (dmaphop): header, stream routes, the two shared streams. The DMA program
    that realizes them (MemTile / core / shim BDs, locks, channels) is derived by the compiler and written
    as dfschedule ops (plandma.cpp) -- it is not part of the dmaphop IR."""
    ops = []
    op = ops.append
    op('dmaphop.plan {replace_args = [0, 1], share_args = [0, 1], persistent = true, bd_once = true}')
    # ---- routes: shim -> MemTiles, MemTile row 2 -> A host rows, MemTile row 1 -> B host rows
    for c in cols:
        op('dmaphop.plan_route {arg = 0, src = [%d, 0, 1], src_kind = "shim", dsts = [[%d, 2, 1]]}' % (c, c))
        op('dmaphop.plan_route {arg = 1, src = [%d, 0, 0], src_kind = "shim", dsts = [[%d, 1, 0]]}' % (c, c))
    for c in cols:
        h, p = (c - 1) >> 1, (c - 1) & 1
        row = core_rows[0] if h == 0 else core_rows[3]
        op('dmaphop.plan_route {arg = 0, src = [%d, 2, 1], src_kind = "dma", dsts = %s}'
           % (c, '[' + ', '.join('[%d, %d, %d]' % (x, row, p) for x in cols) + ']'))
    for c in cols:
        for mm, (row, ch) in enumerate([(core_rows[1], 0), (core_rows[1], 1), (core_rows[2], 0), (core_rows[2], 1)]):
            op('dmaphop.plan_route {arg = 1, src = [%d, 1, %d], src_kind = "dma", dsts = [[%d, %d, %d]]}'
               % (c, mm, c, row, ch))
    # ---- the streams: A strips hosted by mesh rows 0 / 3 (read first by rows 0 / 2), B halves by 1 / 2
    op('dmaphop.plan_stream {arg = 0, role = "a", share = "neighbor", stage = "memtile_ring", ring = %d, '
       'resident = "launch", chunk = [64, 128], chunks = %d, rounds = %d, tensor = [%d, %d], host_rows = [0, 3], '
       'first_rows = [0, 2]}' % (fb, nk, r2, m, k))
    op('dmaphop.plan_stream {arg = 1, role = "b", share = "neighbor", stage = "memtile", resident = "launches", '
       'chunk = [64, 128], chunks = %d, rounds = %d, tensor = [%d, %d], host_rows = [1, 2], first_rows = [0, 1]}'
       % (nk, r2, n, k))
    return ops


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('ir')
    ap.add_argument('out')
    ap.add_argument('--r2', type=int, default=60, help='m tiles per A strip (tiles per core)')
    ap.add_argument('--k', type=int, default=2560)
    ap.add_argument('--fb', type=int, default=10, help='A ring buffers (16 KB each) per row-2 MemTile')
    a = ap.parse_args()
    nk = a.k // 128
    assert a.r2 <= 64 and nk % 2 == 0 and (a.r2 * nk // 2 * 8192) % (a.fb * 16384) == 0, 'shape'
    text = open(a.ir).read()
    m = re.search(r'(func\.func @main\([^\n]*\{\n)', text)
    if not m:
        sys.exit('no func.func @main in %s' % a.ir)
    body = ''.join('    %s\n' % o for o in plan_ops(a.r2, nk, a.fb))
    text = text[:m.end()] + body + text[m.end():]
    open(a.out, 'w').write(text)
    print('plan: %d ops -> %s' % (len(plan_ops(a.r2, nk, a.fb)), a.out))


if __name__ == '__main__':
    main()
