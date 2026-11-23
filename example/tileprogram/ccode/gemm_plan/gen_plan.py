#!/usr/bin/env python3
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
"""Add the 2 x 8 shared-operand dataflow plan to a dumped dmaphop IR.

    gen_plan.py <ir/dfschedule/3_DmapToDmaphopPass.mlir> <out.mlir> [--r2 60] [--k 2560] [--fb 10]

The output is the input IR plus `dmaphop.plan*` ops at the top of @main (doc/design/
dmaphop_dataflow_plan.md). Build with it:

    AIEHLC_DMAPHOP_IR_IN=<out.mlir> source script/aiehlc.sh ... --runtime-source-file gemm_plan.cc

What the plan says (VEK385 / AIE2PS, partition-relative columns 1..4, MemTile rows 1-2, cores 3-6):
  * A (arg 0): shim col c MM2S ch1 -> MemTile (c, 2) S2MM ch1, a FIFO ring of FB x 16 KB buffers
    with counting locks (20 empty, 24 full); its MM2S ch1 broadcasts to the 4 cores of mesh row 0
    (strip 0, c <= 2) or 3 (strip 1), core S2MM channel = chunk parity c & 1.
  * B (arg 1, weight-resident): shim col c MM2S ch0 -> MemTile (c, 1) S2MM ch0 once (first launch
    only); its 4 MM2S channels replay strips c and c + 4 (every other chunk) to cores (c, 4) and
    (c, 5), R2 times per launch.
  * Every core hosts one stream in 2 slots x 2 channels, each 8 KB chunk split over DM banks 2 / 3
    (rows 0-31 at 0x78000 + q * 4 KB, rows 32-63 at +16 KB, q = 2 ch + slot); locks per channel:
    F 6 + 4 ch (DMA -> first reader), G 7 + 4 ch (first -> second reader), E 8 + 4 ch + slot (both
    readers -> DMA, acquired with -2); go lock 14 (persistent kernel), dummy lock 15 (held at 0).
  * Kernel parameters: per mesh row the view / lock base / role / phase of each operand.
"""
import argparse
import re
import sys


def ilist(v):
    return '[' + ', '.join(str(x) for x in v) + ']'


def tiles(ts):
    return '[' + ', '.join('[%d, %d]' % t for t in ts) + ']'


def plan_ops(r2, nk, fb, cols=(1, 2, 3, 4), core_rows=(3, 4, 5, 6)):
    ops = []
    op = ops.append
    a_len, b_len = nk // 2 * 8192, nk * 8192  # A per m-tile per column (parity half), B strip
    op('dmaphop.plan {replace_args = [0, 1], persistent_go_lock = 14, bd_once = true}')
    # ---- routes: shim -> MemTiles, MemTile row 2 -> A host rows, MemTile row 1 -> B host rows
    for c in cols:
        op('dmaphop.plan_route {src = [%d, 0, 1], src_kind = "shim", dsts = [[%d, 2, 1]]}' % (c, c))
        op('dmaphop.plan_route {src = [%d, 0, 0], src_kind = "shim", dsts = [[%d, 1, 0]]}' % (c, c))
    for c in cols:
        h, p = (c - 1) >> 1, (c - 1) & 1
        row = core_rows[0] if h == 0 else core_rows[3]
        op('dmaphop.plan_route {src = [%d, 2, 1], src_kind = "dma", dsts = %s}'
           % (c, '[' + ', '.join('[%d, %d, %d]' % (x, row, p) for x in cols) + ']'))
    for c in cols:
        for m, (row, ch) in enumerate([(core_rows[1], 0), (core_rows[1], 1), (core_rows[2], 0), (core_rows[2], 1)]):
            op('dmaphop.plan_route {src = [%d, 1, %d], src_kind = "dma", dsts = [[%d, %d, %d]]}' % (c, m, c, row, ch))
    # ---- MemTile row 2: A ring (FB buffers of 2 chunks, counting locks 20 empty / 24 full)
    mt2 = [(c, 2) for c in cols]
    op('dmaphop.plan_lock {tiles = %s, id = 20, init = %d}' % (tiles(mt2), fb))
    op('dmaphop.plan_lock {tiles = %s, id = 24, init = 0}' % tiles(mt2))
    for b in range(fb):
        nxt = b + 1 if b < fb - 1 else -1
        op('dmaphop.plan_bd {tiles = %s, bd = %d, addr = %d, len = 16384, acq = [20, -1], rel = [24, 1], next = %d}'
           % (tiles(mt2), 24 + b, 0x80000 + b * 16384, 24 + nxt if nxt >= 0 else -1))
        op('dmaphop.plan_bd {tiles = %s, bd = %d, addr = %d, len = 16384, acq = [24, -1], rel = [20, 1], next = %d}'
           % (tiles(mt2), 24 + fb + b, 0x80000 + b * 16384, 24 + fb + nxt if nxt >= 0 else -1))
    rounds = r2 * a_len // (fb * 16384)
    op('dmaphop.plan_channel {tiles = %s, dir = "s2mm", ch = 1, start_bd = 24, repeat = %d}' % (tiles(mt2), rounds))
    op('dmaphop.plan_channel {tiles = %s, dir = "mm2s", ch = 1, start_bd = %d, repeat = %d}' % (tiles(mt2), 24 + fb, rounds))
    # ---- MemTile row 1: B resident (strips c, c + 4); lock 6 = parts available, 7 = B empty
    mt1 = [(c, 1) for c in cols]
    op('dmaphop.plan_lock {tiles = %s, id = 6, init = 0, later = 4}' % tiles(mt1))
    op('dmaphop.plan_lock {tiles = %s, id = 7, init = 1, later = 0}' % tiles(mt1))
    op('dmaphop.plan_bd {tiles = %s, bd = 0, addr = %d, len = %d, acq = [7, -1], rel = [6, 4], next = -1}'
       % (tiles(mt1), 0x80000, 2 * b_len))
    op('dmaphop.plan_channel {tiles = %s, dir = "s2mm", ch = 0, start_bd = 0, repeat = 1, first_launch_only = true}'
       % tiles(mt1))
    mbd = [1, 24, 2, 25]  # odd MemTile channels use BDs 24..47
    for m in range(4):
        op('dmaphop.plan_bd {tiles = %s, bd = %d, addr = %d, len = %d, dims = [[1, 512], [512, 4], [4096, %d]], '
           'acq = [6, -1], rel = [6, 1], next = -1}'
           % (tiles(mt1), mbd[m], 0x80000 + (m >> 1) * b_len + (m & 1) * 8192, b_len // 2, nk // 2))
    for m in range(4):
        op('dmaphop.plan_channel {tiles = %s, dir = "mm2s", ch = %d, start_bd = %d, repeat = %d}'
           % (tiles(mt1), m, mbd[m], r2))
    # ---- cores: one hosted stream each, 2 channels x 2 slots, bank-split chunks
    cores = [(c, r) for c in cols for r in core_rows]
    for ch in range(2):
        for k in range(2):
            q = 2 * ch + k
            op('dmaphop.plan_bd {tiles = %s, bd = %d, addr = %d, len = 8192, dims = [[1, 128], [128, 8], [4096, 0]], '
               'acq = [%d, -2], rel = [%d, 1], next = %d}'
               % (tiles(cores), q, 0x78000 + q * 4096, 8 + 4 * ch + k, 6 + 4 * ch, 2 * ch + (k ^ 1)))
    for ch in range(2):
        for k in range(2):
            op('dmaphop.plan_lock {tiles = %s, id = %d, init = 2}' % (tiles(cores), 8 + 4 * ch + k))
        op('dmaphop.plan_lock {tiles = %s, id = %d, init = 0}' % (tiles(cores), 6 + 4 * ch))
        op('dmaphop.plan_lock {tiles = %s, id = %d, init = 0}' % (tiles(cores), 7 + 4 * ch))
    op('dmaphop.plan_lock {tiles = %s, id = 14, init = 1}' % tiles(cores))
    op('dmaphop.plan_lock {tiles = %s, id = 15, init = 0}' % tiles(cores))
    for ch in range(2):
        op('dmaphop.plan_channel {tiles = %s, dir = "s2mm", ch = %d, start_bd = %d, repeat = 1}' % (tiles(cores), ch, 2 * ch))
    # ---- shim: A column c = R2 m-tiles of its parity half; B column c = strips c, c + 4 (first launch only)
    for c in cols:
        op('dmaphop.plan_shim_bd {col = %d, ch = 1, dir = "mm2s", arg = 0, bd = 14, offset = %d, len = %d, '
           'dims = [[4, 32], [128, 64], [8192, %d]], iter = [%d, %d], repeat = %d}'
           % (c, (c - 1) * r2 * a_len, a_len, nk // 2, a_len, r2, r2))
        op('dmaphop.plan_shim_bd {col = %d, ch = 0, dir = "mm2s", arg = 1, bd = 15, offset = %d, len = %d, '
           'dims = [[4, 32], [128, 64], [8192, %d]], iter = [%d, 2], repeat = 2, first_launch_only = true}'
           % (c, (c - 1) * 2 * b_len, b_len, nk, b_len))
    # ---- what the kernel body reads (aiehlc_plan.h)
    # mesh row 0 hosts A0 (own), 1 hosts B_c, 2 hosts B_c+4, 3 hosts A1; views: own 0x70000, north
    # 0x60000, south 0x40000; locks: own 48.., north 32.., south 0..
    params = {
        'A_VIEW': [0x70000, 0x40000, 0x60000, 0x70000], 'B_VIEW': [0x60000, 0x60000, 0x40000, 0x40000],
        'A_LOCK': [48, 0, 32, 48], 'B_LOCK': [32, 32, 0, 0],
        'A_FIRST': [1, 0, 1, 0], 'B_FIRST': [1, 1, 0, 0],
        'A_PHASE': [0, 1, 0, 1], 'B_PHASE': [0, 0, 1, 1]}
    for n, v in params.items():
        op('dmaphop.plan_kernel_param {name = "%s", per_mesh_row = %s}' % (n, ilist(v)))
    for n, v in (('SLOT_LO', 0x8000), ('SLOT_HI', 0xc000), ('SLOT_STRIDE', 4096), ('LOCK_F', 6), ('LOCK_G', 7),
                 ('LOCK_E', 8), ('LOCK_CH_STRIDE', 4), ('LOCK_NOP', 48 + 15)):
        op('dmaphop.plan_kernel_param {name = "%s", value = %d}' % (n, v))
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
