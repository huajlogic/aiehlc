# Hand edit: MemTile B (replayed breps times) + double-buffered A (each tile replayed nt times).
# usage: memtile_ab.py <aout/worklocal> <blen> <breps> <alen> <nt> <arounds> x
# then: rm build/host.o build/routing.o build/host; WORKLOCAL_DIR=... AIE_VERSION=5 PLATFORM=baremetal script/hostcompile.sh
import re, sys

FNS = r"""/* MEMTILE B + A (hand experiment). Memtile (col,1) holds the column's whole B slice
 * (S2MM ch0 BD0, once) and replays it `breps` times (MM2S ch0 BD1); and double-buffers the
 * mesh row's A tiles (S2MM ch1 BD24/25) replaying each one `nt` times (MM2S ch1 BD26..).
 * Memtile addressing is neighbourhood-relative: own memory 0x80000.., own locks 64.. in a BD.
 * Odd channels use BDs 24..47. Locks: 0 B empty, 1 B full... see below. */
static void mt_bd(XAie_DevInst *dev, XAie_LocType mt, int bd, unsigned addr, unsigned len, int acq, int acqv,
                  int rel, int relv, int next) {
    XAie_DmaDesc d;
    XAie_DmaDescInit(dev, &d, mt);
    XAie_DmaSetAddrLen(&d, addr, len);
    XAie_DmaSetLock(&d, XAie_LockInit(64 + acq, acqv), XAie_LockInit(64 + rel, relv));
    if (next >= 0)
        XAie_DmaSetNextBd(&d, (u16)next, XAIE_ENABLE);
    XAie_DmaEnableBd(&d);
    XAie_DmaWriteBd(dev, &d, mt, (u8)bd);
}
static void memtile_ab(XAie_DevInst *dev, int col, unsigned blen, int breps, unsigned alen, int nt, int arounds) {
    XAie_LocType mt = XAie_TileLoc(col, 1);
    const unsigned B0 = 0x80000, A0 = 0x80000 + blen, A1 = A0 + alen;
    /* locks: 0 B full, 1 B empty, 2 A0 empty, 3 A1 empty, 4 A0 full, 5 A1 full */
    XAie_LockSetValue(dev, mt, XAie_LockInit(0, 0));
    XAie_LockSetValue(dev, mt, XAie_LockInit(1, 1));
    XAie_LockSetValue(dev, mt, XAie_LockInit(2, 1));
    XAie_LockSetValue(dev, mt, XAie_LockInit(3, 1));
    XAie_LockSetValue(dev, mt, XAie_LockInit(4, 0));
    XAie_LockSetValue(dev, mt, XAie_LockInit(5, 0));
    mt_bd(dev, mt, 0, B0, blen, 1, -1, 0, 1, -1);
    mt_bd(dev, mt, 1, B0, blen, 0, -1, 0, 1, -1);
    mt_bd(dev, mt, 24, A0, alen, 2, -1, 4, 1, 25);
    mt_bd(dev, mt, 25, A1, alen, 3, -1, 5, 1, -1);
    int bd = 26;
    for (int b = 0; b < 2; b++)
        for (int r = 0; r < nt; r++, bd++) {
            const int last = (b == 1 && r == nt - 1);
            mt_bd(dev, mt, bd, b ? A1 : A0, alen, 4 + b, -1, r == nt - 1 ? 2 + b : 4 + b, 1, last ? -1 : bd + 1);
        }
    XAie_DmaChannelSetStartQueue(dev, mt, 0, DMA_S2MM, 0, 1, 0);
    XAie_DmaChannelEnable(dev, mt, 0, DMA_S2MM);
    XAie_DmaChannelSetStartQueue(dev, mt, 0, DMA_MM2S, 1, breps, 0);
    XAie_DmaChannelEnable(dev, mt, 0, DMA_MM2S);
    XAie_DmaChannelSetStartQueue(dev, mt, 1, DMA_S2MM, 24, arounds / 2, 0);
    XAie_DmaChannelEnable(dev, mt, 1, DMA_S2MM);
    XAie_DmaChannelSetStartQueue(dev, mt, 1, DMA_MM2S, 26, arounds / 2, 0);
    XAie_DmaChannelEnable(dev, mt, 1, DMA_MM2S);
}
"""
wl, blen, breps, alen, nt, ar, rdir = sys.argv[1], *map(int, sys.argv[2:7]), sys.argv[7]
s = open(wl + '/host.cc').read()
fns = FNS
s = s.replace('void host_canonicalized(', fns + 'void host_canonicalized(', 1)
i = s.index('  /* DMA BD Config: bd_id=1, len=%d' % alen)
s = s[:i] + '  for (int mc = 1; mc <= 4; mc++) memtile_ab(v1, mc, %d, %d, %d, %d, %d); /* MEMTILE B + A */\n' % (blen, breps, alen, nt, ar) + s[i:]
s, n = re.subn(r'for \(size_t (v\d+) = v7; \1 < v6; \1 \+= v5\) \{', r'for (size_t \1 = v7; \1 < v7 + 1; \1 += v5) { /* MEMTILE B: B sent once */', s)
assert n == 1, n
open(wl + '/host.cc', 'w').write(s)
r = open(wl + '/routing.cc').read()
for c in range(1, 5):
    old = 'XAie_StrmConnCctEnable(v1, XAie_TileLoc(%d,1), SOUTH, 0, NORTH, 0);' % c
    assert r.count(old) == 1, ('B', c)
    r = r.replace(old, 'XAie_StrmConnCctEnable(v1, XAie_TileLoc(%d,1), SOUTH, 0, DMA, 0); /* MEMTILE B in */\n    (void)XAie_StrmConnCctEnable(v1, XAie_TileLoc(%d,1), DMA, 0, NORTH, 0); /* MEMTILE B out */' % (c, c))
# A: the row routes enter each memtile (c,1) on SOUTH p -> NORTH p (p != 0)
for c in range(1, 5):
    m = re.findall(r'XAie_StrmConnCctEnable\(v1, XAie_TileLoc\(%d,1\), SOUTH, ([1-9]), NORTH, \1\);' % c, r)
    assert len(m) == 1, ('A', c, m)
    p = int(m[0])
    old = 'XAie_StrmConnCctEnable(v1, XAie_TileLoc(%d,1), SOUTH, %d, NORTH, %d);' % (c, p, p)
    r = r.replace(old, 'XAie_StrmConnCctEnable(v1, XAie_TileLoc(%d,1), SOUTH, %d, DMA, 1); /* MEMTILE A in */\n    (void)XAie_StrmConnCctEnable(v1, XAie_TileLoc(%d,1), DMA, 1, NORTH, %d); /* MEMTILE A out */' % (c, p, c, p))
open(wl + '/routing.cc', 'w').write(r)
print('edited')
