# Hand edit (after memtile_ab.py, memtile_split.py, shim_bd_once.py): WEIGHT-RESIDENT B.
# B is loaded into the MemTiles on the first launch only; later launches mark its parts
# full again and skip B's shim transfer and MemTile S2MM. A and C still move every launch.
# Only valid when B is the same on every launch (fixed weights).
# usage: b_resident.py <aout/worklocal>
import re, sys
wl = sys.argv[1]
s = open(wl + '/host.cc').read()
old = '''    for (int k = 0; k < nt; k++) {
        XAie_LockSetValue(dev, mb, XAie_LockInit(6 + k, 0));
        XAie_LockSetValue(dev, mb, XAie_LockInit(6 + nt + k, 1));
    }'''
assert old in s
s = s.replace(old, '''    static int b_resident[8];
    for (int k = 0; k < nt; k++) { /* WEIGHT-RESIDENT B */
        XAie_LockSetValue(dev, mb, XAie_LockInit(6 + k, b_resident[col] ? 1 : 0));
        XAie_LockSetValue(dev, mb, XAie_LockInit(6 + nt + k, b_resident[col] ? 0 : 1));
    }''')
old2 = '    XAie_DmaChannelSetStartQueue(dev, mb, 0, DMA_S2MM, 0, 1, 0);'
assert old2 in s
s = s.replace(old2, '    if (!b_resident[col]) XAie_DmaChannelSetStartQueue(dev, mb, 0, DMA_S2MM, 0, 1, 0);\n    b_resident[col] = 1;')
m = re.search(r'for \(size_t (v\d+) = v7; \1 < v7 \+ 1; \1 \+= v5\) \{', s)
assert m
s = s.replace(m.group(0), 'for (size_t %s = v7; %s < v7 + (g_b_loaded ? 0 : 1); %s += v5) { /* WEIGHT-RESIDENT B: first launch only */' % ((m.group(1),) * 3))
s = s.replace('static int g_bd_once;', 'static int g_bd_once;\nstatic int g_b_loaded;', 1)
s = s.replace('  g_bd_once = 1;', '  g_bd_once = 1;\n  g_b_loaded = 1;', 1)
open(wl + '/host.cc', 'w').write(s)
print('weight-resident B')
