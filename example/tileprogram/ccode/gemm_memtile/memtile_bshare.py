###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
# Hand edit (after memtile_ab.py + memtile_split.py): B shared between core-row pairs.
# usage: bshare.py <aout/worklocal> <TN> <KC>
import re, sys
wl, TN, KC = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
H = TN // 2 * KC  # half-chunk bytes
# ---- kernel source (extracted) ----
s = open(wl + '/gemm_ka.cc').read()
old_w = '            const int8_t *w = aiehlc_load_buffer(b, aiehlc_desc_b, aiehlc_cur_b,'
i = s.index(old_w); j = s.index('\n', i)
s = s[:i] + '''            /* B SHARED: this core holds half of each B chunk (lower core of a row pair: first
             * TN/2 rows), the other half is read from the partner (north 0x60000 / south 0x40000).
             * Per-buffer locks 6/7 (ping empty/full), 8/9 (pong): own 48+id, north 32+id, south id. */
            const int bpar = (int)(bsh_n & 1);
            const int lower = (pm % 2) == 0;
            const int nb = lower ? 32 : 0;
            acquire_greater_equal(48 + 7 + 2 * bpar, 1);
            acquire_greater_equal(nb + 7 + 2 * bpar, 1);
            const int8_t *bown = bpar ? (const int8_t *)buf_in_pong_1 : (const int8_t *)buf_in_ping_1;
            const int8_t *bpart = (const int8_t *)((uintptr_t)bown - 0x70000u + (lower ? 0x60000u : 0x40000u));
            const int8_t *w0b = lower ? bown : bpart, *w1b = lower ? bpart : bown;
            const int8_t *w = w0b;''' + s[j:]
nbh = TN // 32  # 16-col blocks per half
s = re.sub(r'#define KA_PB\(b\) \(wr_ \+ \(2 \* \(\(b\) % \(KA_TN / 16\)\)\) \* kb \* 64\)',
           '#define KA_PB(b) ((((b) %% (KA_TN / 16)) < %d) ? (w0r_ + (2 * ((b) %% (KA_TN / 16))) * kb * 64) : (w1r_ + (2 * ((b) %% (KA_TN / 16)) - %d) * kb * 64))' % (nbh, 2 * nbh), s)
assert 'w0r_' in s
s = s.replace('        const int8_t *__restrict wr_ = w;', '        const int8_t *__restrict w0r_ = w0b;                                                                           \\\n        const int8_t *__restrict w1r_ = w1b;')
old_rel = '            aiehlc_release(b);\n'
k = s.index(old_rel, s.index('KA_CHUNK(1)'))
s = s[:k] + '''            chess_memory_fence();
            release(48 + 6 + 2 * bpar, 1);
            release(nb + 6 + 2 * bpar, 1);
            bsh_n++;
''' + s[k + len(old_rel):]
k = s.index('#if defined(__chess__)\n    // On the core'); k2 = s.index('\n', k)
s = s[:k2 + 1] + '    unsigned bsh_n = 0;\n' + s[k2 + 1:]
open(wl + '/gemm_ka.cc', 'w').write(s)
# ---- kernel.cc: B window = half chunk, per-buffer locks, 2 readers ----
k = open(wl + '/kernel.cc').read()
k, n = re.subn(r'_n = aie_kc_encode_bd\(_kc, 3, \(uintptr_t\)buf_in_pong_1, sizeof\(buf_in_pong_1\), 2, 2, -1, 3, 1, 0, 0, 0, -1\);',
               '_n = aie_kc_encode_bd(_kc, 3, (uintptr_t)buf_in_pong_1, %d, 2, 8, -2, 9, 2, 0, 0, 0, -1); /* B SHARED */' % H, k); assert n == 1
k, n = re.subn(r'_n = aie_kc_encode_bd\(_kc, 2, \(uintptr_t\)buf_in_ping_1, sizeof\(buf_in_ping_1\), 3, 2, -1, 3, 1, 0, 0, 0, -1\);',
               '_n = aie_kc_encode_bd(_kc, 2, (uintptr_t)buf_in_ping_1, %d, 3, 6, -2, 7, 2, 0, 0, 0, -1); /* B SHARED */' % H, k); assert n == 1
i = k.index('aie_kc_encode_lock(_kc, 2, 2);'); j = k.index('aie_kc_encode_lock(_kc, 3, 0);'); e = k.index('\n', j)
k = k[:i] + 'aie_kc_encode_lock(_kc, 6, 2);\n    core_reg_write(_kc[0].off, _kc[0].val);\n    aie_kc_encode_lock(_kc, 7, 0);\n    core_reg_write(_kc[0].off, _kc[0].val);\n    aie_kc_encode_lock(_kc, 8, 2);\n    core_reg_write(_kc[0].off, _kc[0].val);\n    aie_kc_encode_lock(_kc, 9, 0);' + k[e:]
open(wl + '/kernel.cc', 'w').write(k)
# ---- host.cc: MemTile replays B as two half streams (ch0 half 0, ch2 half 1), S2MM releases +2 ----
h = open(wl + '/host.cc').read()
Hw = H // 4
assert Hw % 512 == 0
helper = '''static void mt_bd_half(XAie_DevInst *dev, XAie_LocType mt, int bd, unsigned addr, unsigned nch, int lk, int next) {
    /* nch chunks of %d B; this BD reads one %d B half of each (B SHARED). Wraps are 10-bit. */
    XAie_DmaDesc d;
    XAie_DmaDimDesc dims[3];
    dims[0].AieMlDimDesc.StepSize = 1;
    dims[0].AieMlDimDesc.Wrap = 512;
    dims[1].AieMlDimDesc.StepSize = 512;
    dims[1].AieMlDimDesc.Wrap = %d;
    dims[2].AieMlDimDesc.StepSize = %d;
    dims[2].AieMlDimDesc.Wrap = (u16)nch;
    XAie_DmaTensor t = {3, dims};
    XAie_DmaDescInit(dev, &d, mt);
    XAie_DmaSetMultiDimAddr(&d, &t, addr, nch * %d);
    XAie_DmaSetLock(&d, XAie_LockInit(64 + lk, -1), XAie_LockInit(64 + lk, 1));
    if (next >= 0)
        XAie_DmaSetNextBd(&d, (u16)next, XAIE_ENABLE);
    XAie_DmaEnableBd(&d);
    XAie_DmaWriteBd(dev, &d, mt, (u8)bd);
}
''' % (2 * H, H, Hw // 512, 2 * Hw, H)
h = h.replace('static void memtile_ab(', helper + 'static void memtile_ab(', 1)
old = '            mt_bd(dev, mb, 12 + k, B0 + k * bpart, bpart, 6 + k, -1, 6 + k, 1, k + 1 < nt ? 12 + k + 1 : -1);'
assert old in h
h = h.replace(old, '''            mt_bd_half(dev, mb, 12 + k, B0 + k * bpart, bpart / %d, 6 + k, k + 1 < nt ? 12 + k + 1 : -1);
            mt_bd_half(dev, mb, 16 + k, B0 + k * bpart + %d, bpart / %d, 6 + k, k + 1 < nt ? 16 + k + 1 : -1);''' % (2 * H, H, 2 * H))
old = 'mt_bd(dev, mb, k, B0 + k * bpart, bpart, 6 + nt + k, -1, 6 + k, 1, k + 1 < nt ? k + 1 : -1);'
assert old in h
h = h.replace(old, 'mt_bd(dev, mb, k, B0 + k * bpart, bpart, 6 + nt + k, -1, 6 + k, 2, k + 1 < nt ? k + 1 : -1); /* 2 half-stream readers */')
h = h.replace('        XAie_DmaChannelEnable(dev, mb, 0, DMA_MM2S);', '        XAie_DmaChannelEnable(dev, mb, 0, DMA_MM2S);\n        XAie_DmaChannelEnable(dev, mb, 2, DMA_MM2S);', 1)
h = h.replace('    XAie_DmaChannelSetStartQueue(dev, mb, 0, DMA_MM2S, 12, breps, 0);', '    XAie_DmaChannelSetStartQueue(dev, mb, 0, DMA_MM2S, 12, breps, 0);\n    XAie_DmaChannelSetStartQueue(dev, mb, 2, DMA_MM2S, 16, breps, 0);', 1)
open(wl + '/host.cc', 'w').write(h)
# ---- routing.cc: half 0 to rows 3/5 only, half 1 (MemTile DMA 2) to rows 4/6 ----
r = open(wl + '/routing.cc').read()
conns = re.findall(r'TileLoc\((\d),(\d)\), ([A-Z]+), (\d+), ([A-Z]+), (\d+)\)', r)
def um(c, row, port): return any(int(a) == c and int(b) == row and m == 'NORTH' and int(q) == port for a, b, s_, p, m, q in conns)
def us(c, row, port): return any(int(a) == c and int(b) == row and s_ == 'SOUTH' and int(p) == port for a, b, s_, p, m, q in conns)
blocks = ''
for c in range(1, 5):
    q = next(x for x in (3, 2, 4, 5) if all(not um(c, rw, x) for rw in (1, 2, 3, 4, 5)) and all(not us(c, rw, x) for rw in (2, 3, 4, 5, 6)))
    for row, pat in ((4, 'SOUTH, 0, DMA, 1'), (6, 'SOUTH, 0, DMA, 1'), (5, 'SOUTH, 0, NORTH, 0')):
        old = 'XAie_StrmConnCctEnable(v1, XAie_TileLoc(%d,%d), %s);' % (c, row, pat)
        assert r.count(old) == 1, (c, row, pat)
        r = r.replace(old, '0; /* B SHARED: removed (%d,%d) %s */' % (c, row, pat))
    add = [(1, 'DMA, 2, NORTH, %d' % q), (2, 'SOUTH, %d, NORTH, %d' % (q, q)), (3, 'SOUTH, %d, NORTH, %d' % (q, q)),
           (4, 'SOUTH, %d, NORTH, %d' % (q, q)), (4, 'SOUTH, %d, DMA, 1' % q), (5, 'SOUTH, %d, NORTH, %d' % (q, q)), (6, 'SOUTH, %d, DMA, 1' % q)]
    blocks += '  { /* B SHARED: half-1 stream, column %d, port %d */\n' % (c, q) + ''.join('    (void)XAie_StrmConnCctEnable(v1, XAie_TileLoc(%d,%d), %s);\n' % (c, rw, a) for rw, a in add) + '  }\n'
i = r.index('  return;\n}')
r = r[:i] + blocks + r[i:]
open(wl + '/routing.cc', 'w').write(r)
print('B shared: half', H, 'B')
