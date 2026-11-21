# Apply AFTER memtile_ab.py: replaces memtile_ab() with a 3-buffer A version (A refill overlaps the replay).
# usage: memtile_a3.py <aout/worklocal> <blen> <breps> <alen> <nt> <arounds>   (arounds % 3 == 0; 3*nt + 3 <= 24 BDs)
# memtile_ab with 3 A buffers (S2MM chain A0->A1->A2, MM2S replays each nt times)
import sys, re
wl, blen, breps, alen, nt, ar = sys.argv[1], *map(int, sys.argv[2:7])
s = open(wl + '/host.cc').read()
i = s.index('static void memtile_ab('); j = s.index('void host_canonicalized(')
fn = '''static void memtile_ab(XAie_DevInst *dev, int col, unsigned blen, int breps, unsigned alen, int nt, int arounds) {
    XAie_LocType mt = XAie_TileLoc(col, 1);
    const unsigned B0 = 0x80000, bpart = blen / nt;
    /* locks: 20+b A buffer b empty, 24+b A buffer b full; 6+k / 6+nt+k B part k full / empty */
    for (int b = 0; b < 3; b++) {
        XAie_LockSetValue(dev, mt, XAie_LockInit(20 + b, 1));
        XAie_LockSetValue(dev, mt, XAie_LockInit(24 + b, 0));
    }
    for (int k = 0; k < nt; k++) {
        XAie_LockSetValue(dev, mt, XAie_LockInit(6 + k, 0));
        XAie_LockSetValue(dev, mt, XAie_LockInit(6 + nt + k, 1));
    }
    static int bds_written[8];
    if (!bds_written[col]) {
        bds_written[col] = 1;
        for (int k = 0; k < nt; k++) {
            mt_bd(dev, mt, k, B0 + k * bpart, bpart, 6 + nt + k, -1, 6 + k, 1, k + 1 < nt ? k + 1 : -1);
            mt_bd(dev, mt, 12 + k, B0 + k * bpart, bpart, 6 + k, -1, 6 + k, 1, k + 1 < nt ? 12 + k + 1 : -1);
        }
        for (int b = 0; b < 3; b++)
            mt_bd(dev, mt, 24 + b, 0x80000 + blen + b * alen, alen, 20 + b, -1, 24 + b, 1, b < 2 ? 24 + b + 1 : -1);
        int bd = 27;
        for (int b = 0; b < 3; b++)
            for (int r = 0; r < nt; r++, bd++) {
                const int last = (b == 2 && r == nt - 1);
                mt_bd(dev, mt, bd, 0x80000 + blen + b * alen, alen, 24 + b, -1, r == nt - 1 ? 20 + b : 24 + b, 1, last ? -1 : bd + 1);
            }
        XAie_DmaChannelEnable(dev, mt, 0, DMA_S2MM);
        XAie_DmaChannelEnable(dev, mt, 0, DMA_MM2S);
        XAie_DmaChannelEnable(dev, mt, 1, DMA_S2MM);
        XAie_DmaChannelEnable(dev, mt, 1, DMA_MM2S);
    }
    XAie_DmaChannelSetStartQueue(dev, mt, 0, DMA_S2MM, 0, 1, 0);
    XAie_DmaChannelSetStartQueue(dev, mt, 0, DMA_MM2S, 12, breps, 0);
    XAie_DmaChannelSetStartQueue(dev, mt, 1, DMA_S2MM, 24, arounds / 3, 0);
    XAie_DmaChannelSetStartQueue(dev, mt, 1, DMA_MM2S, 27, arounds / 3, 0);
}
'''
s = s[:i] + fn + s[j:]
open(wl + '/host.cc', 'w').write(s)
print('3-buffer A')
