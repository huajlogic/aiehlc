###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
# usage: memtile_split.py <aout/worklocal> <blen> <breps> <alen> <nt> <arounds>   (after memtile_ab.py)
# Apply AFTER memtile_ab.py: B stays on MemTile (c,1) ch0; A (3 buffers) moves to MemTile (c,2) ch1.
import sys, re
wl, blen, breps, alen, nt, ar = sys.argv[1], *map(int, sys.argv[2:7])
s = open(wl + '/host.cc').read()
i = s.index('static void memtile_ab('); j = s.index('void host_canonicalized(')
fn = '''static void memtile_ab(XAie_DevInst *dev, int col, unsigned blen, int breps, unsigned alen, int nt, int arounds) {
    /* B: MemTile (col,1) ch0, resident, replayed per m tile.
     * A: MemTile (col,2) ch1, 3 buffers, each replayed nt times -- one stream per MemTile. */
    XAie_LocType mb = XAie_TileLoc(col, 1), ma = XAie_TileLoc(col, 2);
    const unsigned B0 = 0x80000, bpart = blen / nt;
    for (int b = 0; b < 3; b++) {
        XAie_LockSetValue(dev, ma, XAie_LockInit(20 + b, 1));
        XAie_LockSetValue(dev, ma, XAie_LockInit(24 + b, 0));
    }
    for (int k = 0; k < nt; k++) {
        XAie_LockSetValue(dev, mb, XAie_LockInit(6 + k, 0));
        XAie_LockSetValue(dev, mb, XAie_LockInit(6 + nt + k, 1));
    }
    static int bds_written[8];
    if (!bds_written[col]) {
        bds_written[col] = 1;
        for (int k = 0; k < nt; k++) {
            mt_bd(dev, mb, k, B0 + k * bpart, bpart, 6 + nt + k, -1, 6 + k, 1, k + 1 < nt ? k + 1 : -1);
            mt_bd(dev, mb, 12 + k, B0 + k * bpart, bpart, 6 + k, -1, 6 + k, 1, k + 1 < nt ? 12 + k + 1 : -1);
        }
        for (int b = 0; b < 3; b++)
            mt_bd(dev, ma, 24 + b, 0x80000 + b * alen, alen, 20 + b, -1, 24 + b, 1, b < 2 ? 24 + b + 1 : -1);
        int bd = 27;
        for (int b = 0; b < 3; b++)
            for (int r = 0; r < nt; r++, bd++) {
                const int last = (b == 2 && r == nt - 1);
                mt_bd(dev, ma, bd, 0x80000 + b * alen, alen, 24 + b, -1, r == nt - 1 ? 20 + b : 24 + b, 1, last ? -1 : bd + 1);
            }
        XAie_DmaChannelEnable(dev, mb, 0, DMA_S2MM);
        XAie_DmaChannelEnable(dev, mb, 0, DMA_MM2S);
        XAie_DmaChannelEnable(dev, ma, 1, DMA_S2MM);
        XAie_DmaChannelEnable(dev, ma, 1, DMA_MM2S);
    }
    XAie_DmaChannelSetStartQueue(dev, mb, 0, DMA_S2MM, 0, 1, 0);
    XAie_DmaChannelSetStartQueue(dev, mb, 0, DMA_MM2S, 12, breps, 0);
    XAie_DmaChannelSetStartQueue(dev, ma, 1, DMA_S2MM, 24, arounds / 3, 0);
    XAie_DmaChannelSetStartQueue(dev, ma, 1, DMA_MM2S, 27, arounds / 3, 0);
}
'''
s = s[:i] + fn + s[j:]
open(wl + '/host.cc', 'w').write(s)
r = open(wl + '/routing.cc').read()
n = 0
for m in re.finditer(r'XAie_StrmConnCctEnable\(v1, XAie_TileLoc\((\d),1\), SOUTH, (\d), DMA, 1\); /\* MEMTILE A in \*/\n\s*\(void\)XAie_StrmConnCctEnable\(v1, XAie_TileLoc\(\1,1\), DMA, 1, NORTH, \2\); /\* MEMTILE A out \*/', r):
    n += 1
r, k1 = re.subn(r'XAie_StrmConnCctEnable\(v1, XAie_TileLoc\((\d),1\), SOUTH, (\d), DMA, 1\); /\* MEMTILE A in \*/\n(\s*)\(void\)XAie_StrmConnCctEnable\(v1, XAie_TileLoc\(\1,1\), DMA, 1, NORTH, \2\); /\* MEMTILE A out \*/',
                r'XAie_StrmConnCctEnable(v1, XAie_TileLoc(\1,1), SOUTH, \2, NORTH, \2); /* A passes row 1 */', r)
# at row 2: the A route passes SOUTH p -> NORTH p; stage it there
r, k2 = re.subn(r'XAie_StrmConnCctEnable\(v1, XAie_TileLoc\((\d),2\), SOUTH, ([1-9]), NORTH, \2\);',
                r'XAie_StrmConnCctEnable(v1, XAie_TileLoc(\1,2), SOUTH, \2, DMA, 1); /* MEMTILE(row 2) A in */\n    (void)XAie_StrmConnCctEnable(v1, XAie_TileLoc(\1,2), DMA, 1, NORTH, \2); /* MEMTILE(row 2) A out */', r)
print('A row1 restored', k1, 'A row2 staged', k2)
open(wl + '/routing.cc', 'w').write(r)
