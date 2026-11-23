# Hand edit: 2 x 8 SHARED-OPERAND layout for the K-accumulating GEMM (gemm_kacc_v2.cc built with
# KA_R 21, KA_NT 2, then memtile_ab.py / memtile_split.py / shim_bd_once.py as in the README).
#
# Logical grid: A in 2 strips (A0 = rows [0, M/2), A1), B in 8 strips of 64 rows (NT2 = 1). Core
# (pm, c) computes A strip pm >> 1 x B strip c + 4 * (pm & 1), 42 tiles of 64 x 64 x K.
# Each core TILE hosts exactly one operand stream in its memory -- mesh row 0: A0, 1: B_c,
# 2: B_{c+4}, 3: A1 -- and each core reads its operands from the host tiles directly below / above
# it (neighbour memory), so every tile receives one stream instead of two:
#   pm0: A own,   B north   pm1: A south, B north   pm2: A north, B south   pm3: A own, B south
# Hosted stream: chunk parity -> S2MM channel; 2 buffers per channel; each 8 KB chunk is split
# rows 0-31 -> bank 2 (0x78000 + q * 4 KB), rows 32-63 -> bank 3 (0x7c000 + q * 4 KB), q = 2 ch + slot.
# The two readers of a buffer walk it in opposite phase (A / B halves swapped by pm & 1 / pm >> 1),
# so they never hit the same bank in the same cycle (bench: 1120 vs 1113 cycles / chunk unshared).
# Locks per channel ch in the host tile: F = 6 + 4 ch (DMA -> first reader), G = 7 + 4 ch (first
# -> second reader, released right after the first acquire), E = 8 + 4 ch + slot (both readers of
# that slot -> DMA, which acquires -2; per slot, or a fast first reader frees a slot early).
# The shim walks are left as generated; the host lays A / B out in DDR in the order they emit.
# usage: share2x8.py <aout/worklocal> [bres]
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import share_route as SR
import share_host as SH

import argparse
ap = argparse.ArgumentParser()
ap.add_argument('wl')
ap.add_argument('--r2', type=int, default=42, help='m tiles per A strip (mesh rows 2 x R2 x 64 = M)')
ap.add_argument('--nt2', type=int, default=1, help='n tiles per B strip (8 x NT2 x 64 = N)')
ap.add_argument('--k', type=int, default=2560)
ap.add_argument('--bres', action='store_true', help='weight-resident B (loaded on the first launch only)')
ap.add_argument('--single', action='store_true', help='one tile per output packet (needs T <= 64); default two')
ap.add_argument('--persist', action='store_true', help='kernel stays loaded: later launches only release a go lock (no ELF reload / core reset)')
ap.add_argument('--tile', action='store_true', help='one software pipeline per tile across chunk boundaries (share2x8_tile.inc)')
ap.add_argument('--bench', action='store_true', help='before launch 0 each core runs 2 tiles of ka_tile with no lock waits; cycles stamped (needs --tile --kcyc)')
ap.add_argument('--zones', default='', help='DDR zone per operand, e.g. A=0x50000000000:0x200000000,C=0x60000000000:0x100000000 (base:size); default heap (DDR_LOW0)')
ap.add_argument('--kc', type=int, default=128, choices=(128, 256), help='K chunk of the tile kernel (256: needs --tile; each chunk arrives as two 8 KB halves, one per channel)')
ap.add_argument('--kcyc', action='store_true', help='cores stamp cycle split (total / input wait / mac / output wait / convert) into their last tile')
ap.add_argument('--a2ch', action='store_true', help='A on both shim MM2S channels (odd m tiles on B\'s channel, re-routed once B is loaded); needs --bres, R2 %% 4 == 0')
ap.add_argument('--dmaonly', action='store_true', help='measurement: the tile kernel does no MACs (locks / DMA unchanged) -- the data-delivery bound; output is garbage (needs --tile)')
ap.add_argument('--perfcnt', action='store_true', help='measurement: per-core active / memory-stall / lock-stall / vector-instr counters (+ DM bank 4 / 6 conflicts) over launch 3 (build without AIEHLC_PROFILING)')
ap.add_argument('--qslot', action='store_true', help='buffer address index 2 slot + ch (a channel\'s two slots in different DM banks) instead of 2 ch + slot (--tile, KC 128)')
ap.add_argument('--afine', action='store_true', help='row-2 MemTile A as a FIFO ring of 10 x 16 KB buffers with counting locks (first chunks flow after 16 KB, not a whole 80 KB m-tile half); needs NT2 1, R2 even')
ap.add_argument('--stress', type=int, default=0, help='N extra launches, each fully sampled-checked; failures listed per tile')
args = ap.parse_args()
wl, bres = args.wl, args.bres
R2, NT2, NK = args.r2, args.nt2, args.k // 128
T = R2 * NT2  # tiles per core
assert args.k % 256 == 0 and R2 % (4 if args.a2ch else 3) == 0 and T % 2 == 0 and T // 2 <= 64, 'shape'
assert not args.single or T <= 64, '--single needs <= 64 tiles per core'
assert 2 * NT2 * NK * 8192 <= 512 * 1024, 'B strips do not fit the row-1 MemTile'
NB = 4 if args.a2ch else 3  # A buffers in the row-2 MemTile
assert not args.afine or (NT2 == 1 and R2 % 2 == 0 and NK == 20 and not args.a2ch), '--afine shape (ring = 2 m-tile halves of 10 chunks)'
assert not args.a2ch or (bres and R2 % 4 == 0 and NB * NK // 2 * 8192 <= 512 * 1024 and 27 + NB * NT2 <= 48), '--a2ch shape'
assert R2 <= 64 and NT2 * NK // 2 <= 1023


def _macro(name):
    m = re.search(r'#define %s (\d+)' % name, open(wl + '/gemm_ka.cc').read())
    return int(m.group(1))


BASE_T = _macro('KA_R') * _macro('KA_NT')  # tiles per core of the base build (its output tasks)

# ---------------------------------------------------------------- routing.cc
rt = open(wl + '/routing.cc').read()
body_start = rt.index('void routing(XAie_DevInst* v1) {')
body_end = rt.index('  return;\n}', body_start)
body = rt[body_start:body_end]
inp, kept = SR.split_routing(body)
fab = SR.Fabric(cols=range(1, 5))
SR.book_kept(fab, kept)
new = []
for cc in range(1, 5):
    new.append('XAie_EnableShimDmaToAieStrmPort(v1, XAie_TileLoc(%d,0), 7);' % cc)
    new += SR.route_net(fab, (cc, 0, 'SOUTH', 7), [(cc, 2, 1)])  # A -> row-2 MemTile S2MM ch1
    new.append('XAie_EnableShimDmaToAieStrmPort(v1, XAie_TileLoc(%d,0), 3);' % cc)
    new += SR.route_net(fab, (cc, 0, 'SOUTH', 3), [(cc, 1, 0)])  # B -> row-1 MemTile S2MM ch0
for cc in range(1, 5):
    c = cc - 1
    h, p = c >> 1, c & 1
    new += SR.route_net(fab, (cc, 2, 'DMA', 1), [(x, 3 if h == 0 else 6, p) for x in range(1, 5)])
for cc in range(1, 5):
    for m, (row, ch) in enumerate([(4, 0), (4, 1), (5, 0), (5, 1)]):
        new += SR.route_net(fab, (cc, 1, 'DMA', m), [(cc, row, ch)])
reroute = []
if args.a2ch:  # B's shim channel -> row-2 MemTile S2MM ch0 once B is resident (host, after launch 0's B load)
    for cc in range(1, 5):
        sh = [l for l in new if 'TileLoc(%d,0), SOUTH, 3, NORTH,' % cc in l]
        assert len(sh) == 1, sh
        k = int(re.search(r'NORTH, (\d+)\);', sh[0]).group(1))
        m1 = [l for l in new if 'TileLoc(%d,1), SOUTH, %d, DMA, 0);' % (cc, k) in l]
        assert len(m1) == 1, m1
        reroute += [l.replace('StrmConnCctEnable', 'StrmConnCctDisable') for l in (sh[0], m1[0])]
        for u in ((cc, 0, 's', 'SOUTH', 3), (cc, 0, 'm', 'NORTH', k), (cc, 1, 's', 'SOUTH', k)):
            fab.used.discard(u)
        reroute += SR.route_net(fab, (cc, 0, 'SOUTH', 3), [(cc, 2, 0)])
kept_body = '\n'.join(kept)
rt = rt[:body_start] + kept_body + '\n  /* SHARE2X8 input routes */\n' + ''.join('  (void)%s\n' % l for l in new) + rt[body_end:]
open(wl + '/routing.cc', 'w').write(rt)
print('routing: %d input lines replaced by %d' % (len(inp), len(new)))

# ---------------------------------------------------------------- host.cc: MemTiles
hs = open(wl + '/host.cc').read()
MT = r'''/* SHARE2X8 MemTiles. Row 2, column c: A strip c >> 1, chunk parity c & 1 -- SH_NB (3, or 4 with SH_A2) buffers, each one
 * m-tile's parity half (NK/2 chunks of 8 KB), sent NT2 times to the 4 host tiles of mesh row 0 / 3.
 * Row 1, column c: B strips c and c+4 resident (NT2*NK chunks each, back to back); MM2S channel
 * m = (strip << 1) | parity walks every other chunk of its strip, once per tile (R2 times). */
#define SH_R2 %(R2)d
#define SH_NT2 %(NT2)d
#define SH_NK %(NK)d
#define SH_NB %(NB)d /* A buffers (row 2) */
#define SH_A2 %(A2)d /* A on both shim channels: even m tiles -> S2MM ch1, odd -> ch0 */
#define SH_FINE %(FINE)d /* A ring: SH_FB buffers of 2 chunks, counting locks E 20 (init SH_FB) / F 24 */
#define SH_FB 10
static void sh_mt_bd(XAie_DevInst *dev, XAie_LocType mt, int bd, unsigned addr, unsigned len, int acq, int acqv,
                     int rel, int relv, int next, int nchunk) {
    XAie_DmaDesc d;
    XAie_DmaDescInit(dev, &d, mt);
    if (nchunk > 0) { /* every other 8 KB chunk: 2 KB x 4, then +16 KB; wraps are 10-bit */
        XAie_DmaDimDesc dims[3];
        dims[0].AieMlDimDesc.StepSize = 1;
        dims[0].AieMlDimDesc.Wrap = 512;
        dims[1].AieMlDimDesc.StepSize = 512;
        dims[1].AieMlDimDesc.Wrap = 4;
        dims[2].AieMlDimDesc.StepSize = 4096;
        dims[2].AieMlDimDesc.Wrap = (u16)nchunk;
        XAie_DmaTensor t = {3, dims};
        XAie_DmaSetMultiDimAddr(&d, &t, addr, len);
    } else {
        XAie_DmaSetAddrLen(&d, addr, len);
    }
    XAie_DmaSetLock(&d, XAie_LockInit(64 + acq, acqv), XAie_LockInit(64 + rel, relv));
    if (next >= 0)
        XAie_DmaSetNextBd(&d, (u16)next, XAIE_ENABLE);
    XAie_DmaEnableBd(&d);
    XAie_DmaWriteBd(dev, &d, mt, (u8)bd);
}
static void sh_memtiles(XAie_DevInst *dev, int col) {
    XAie_LocType ma = XAie_TileLoc(col, 2), mb = XAie_TileLoc(col, 1);
    const unsigned half = SH_NK / 2 * 8192u, strip = SH_NT2 * SH_NK * 8192u;
    static int written[8], b_loaded[8];
    /* A: empty 20+b = 1, full 24+b = 0 */
    for (int b = 0; SH_FINE && b < 1; b++) {
        XAie_LockSetValue(dev, ma, XAie_LockInit(20, SH_FB));
        XAie_LockSetValue(dev, ma, XAie_LockInit(24, 0));
    }
    for (int b = 0; !SH_FINE && b < SH_NB; b++) {
        XAie_LockSetValue(dev, ma, XAie_LockInit(20 + b, 1));
        XAie_LockSetValue(dev, ma, XAie_LockInit(24 + b, 0));
    }
    /* B: 6 = parts available to the 4 MM2S channels (4 once loaded), 7 = B empty */
    const int keep_b = %(BRES)d && b_loaded[col];
    XAie_LockSetValue(dev, mb, XAie_LockInit(6, keep_b ? 4 : 0));
    XAie_LockSetValue(dev, mb, XAie_LockInit(7, keep_b ? 0 : 1));
    if (!written[col]) {
        written[col] = 1;
        for (int b = 0; SH_FINE && b < SH_FB; b++) { /* ring: S2MM BDs 24.., MM2S BDs 24 + SH_FB.. */
            sh_mt_bd(dev, ma, 24 + b, 0x80000 + b * 16384u, 16384, 20, -1, 24, 1, b < SH_FB - 1 ? 25 + b : -1, 0);
            sh_mt_bd(dev, ma, 24 + SH_FB + b, 0x80000 + b * 16384u, 16384, 24, -1, 20, 1, b < SH_FB - 1 ? 25 + SH_FB + b : -1, 0);
        }
        for (int b = 0; !SH_FINE && b < SH_NB; b++) {
            if (SH_A2) { /* chain (0, 2) on ch1 = BDs 24, 25; (1, 3) on ch0 = BDs 0, 1 */
                const int id = (b & 1) ? (b >> 1) : 24 + (b >> 1);
                sh_mt_bd(dev, ma, id, 0x80000 + b * half, half, 20 + b, -1, 24 + b, 1, (b >> 1) < SH_NB / 2 - 1 ? id + 1 : -1, 0);
            } else {
                sh_mt_bd(dev, ma, 24 + b, 0x80000 + b * half, half, 20 + b, -1, 24 + b, 1, b < SH_NB - 1 ? 25 + b : -1, 0);
            }
        }
        int bd = 27;
        for (int b = 0; !SH_FINE && b < SH_NB; b++)
            for (int r = 0; r < SH_NT2; r++, bd++) {
                const int last = (b == SH_NB - 1 && r == SH_NT2 - 1);
                sh_mt_bd(dev, ma, bd, 0x80000 + b * half, half, 24 + b, -1, r == SH_NT2 - 1 ? 20 + b : 24 + b, 1,
                         last ? -1 : bd + 1, 0);
            }
        sh_mt_bd(dev, mb, 0, 0x80000, 2 * strip, 7, -1, 6, 4, -1, 0);
        const int mbd[4] = {1, 24, 2, 25};
        for (int m = 0; m < 4; m++)
            sh_mt_bd(dev, mb, mbd[m], 0x80000 + (m >> 1) * strip + (m & 1) * 8192u, half * SH_NT2, 6, -1, 6, 1, -1,
                     SH_NT2 * SH_NK / 2);
        XAie_DmaChannelEnable(dev, ma, 1, DMA_S2MM);
        if (SH_A2)
            XAie_DmaChannelEnable(dev, ma, 0, DMA_S2MM);
        XAie_DmaChannelEnable(dev, ma, 1, DMA_MM2S);
        XAie_DmaChannelEnable(dev, mb, 0, DMA_S2MM);
        for (int m = 0; m < 4; m++)
            XAie_DmaChannelEnable(dev, mb, (u8)m, DMA_MM2S);
    }
    if (SH_FINE) { /* the ring holds 2 m-tile halves (SH_FB x 2 chunks = NK chunks) */
        XAie_DmaChannelSetStartQueue(dev, ma, 1, DMA_S2MM, 24, SH_R2 / 2, 0);
        XAie_DmaChannelSetStartQueue(dev, ma, 1, DMA_MM2S, 24 + SH_FB, SH_R2 / 2, 0);
    } else
    XAie_DmaChannelSetStartQueue(dev, ma, 1, DMA_S2MM, 24, SH_R2 / SH_NB, 0);
    if (SH_A2)
        XAie_DmaChannelSetStartQueue(dev, ma, 0, DMA_S2MM, 0, SH_R2 / SH_NB, 0);
    if (!SH_FINE)
        XAie_DmaChannelSetStartQueue(dev, ma, 1, DMA_MM2S, 27, SH_R2 / SH_NB, 0);
    if (!keep_b)
        XAie_DmaChannelSetStartQueue(dev, mb, 0, DMA_S2MM, 0, 1, 0);
    b_loaded[col] = 1;
    const int mbd[4] = {1, 24, 2, 25};
    for (int m = 0; m < 4; m++)
        XAie_DmaChannelSetStartQueue(dev, mb, (u8)m, DMA_MM2S, (u8)mbd[m], SH_R2, 0);
}
''' % {'R2': R2, 'NT2': NT2, 'NK': NK, 'NB': NB, 'A2': 1 if args.a2ch else 0, 'FINE': 1 if args.afine else 0, 'BRES': 1 if bres else 0}
hs = hs.replace('void host_canonicalized(', MT + 'void host_canonicalized(', 1)
hs, n = re.subn(r'  for \(int mc = 1; mc <= 4; mc\+\+\) memtile_ab\(v1, mc, [^)]*\); /\* MEMTILE B \+ A \*/',
                '  for (int mc = 1; mc <= 4; mc++) sh_memtiles(v1, mc); /* SHARE2X8 MemTiles */', hs)
assert n == 1, n
hs = SH.patch_shim_bds(hs, open(wl + '/routing.cc').read(), R2, NT2, NK, T, 1 if args.single else 2, args.a2ch)
if bres:  # B's shim transfer on the first launch only
    m = re.search(r'for \(size_t (v\d+) = v7; \1 < v7 \+ 1; \1 \+= v5\) \{', hs)
    assert m
    hs = hs.replace(m.group(0), 'for (size_t %s = v7; %s < v7 + (g_b_loaded ? 0 : 1); %s += v5) { /* B: first launch only */' % ((m.group(1),) * 3))
    hs = hs.replace('static int g_bd_once;', 'static int g_bd_once;\nstatic int g_b_loaded;', 1)
    hs = hs.replace('  g_bd_once = 1;', '  g_bd_once = 1;\n  g_b_loaded = 1;', 1)
if args.a2ch:  # after the B loop (B resident, its channel free): re-route + odd A tiles on ch0
    i = hs.index('/* B: first launch only */')
    j = hs.index('\n  }\n', i) + len('\n  }\n')
    hs = hs[:j] + SH.a_odd_block(hs, R2, NK) + hs[j:]
    assert hs.count('  g_bd_once = 1;\n') == 1
    hs = hs.replace('  g_bd_once = 1;\n', '  for (int c = 0; c < 4; c++) __Runtime_wait(v1, sh_ao[c]);\n  g_bd_once = 1;\n')
    rr = '/* SHARE2X8 --a2ch: B\'s shim channel -> row-2 MemTile S2MM ch0 (share_route) */\nstatic void sh_reroute(XAie_DevInst *v1) {\n'
    rr += '  for (int c = 1; c <= 4; c++) /* B fully in the row-1 MemTile, not just read from DDR */\n'
    rr += '    if (XAie_DmaWaitForDone(v1, XAie_TileLoc(c, 1), 0, DMA_S2MM, 1000000) != XAIE_OK) printf("sh_reroute: B S2MM col %d not done\\n", c);\n'
    rr += ''.join('  if (%s != XAIE_OK) printf("sh_reroute FAILED: %s\\n");\n' % (l.rstrip(';'), l.replace('"', '').rstrip(';')) for l in reroute) + '}\n'
    hs = hs.replace('void host_canonicalized(', rr + 'void host_canonicalized(', 1)

# ---------------------------------------------------------------- host.cc: DDR layout + golden
ARR = r'''/* SHARE2X8: lay A / B out in DDR as the shim streams them (share_host.py), contiguously:
 * A column c: m-tiles s = 0..R2-1 x chunks jj = 0..NK/2-1 of strip c >> 1, k-chunk 2 jj + (c & 1);
 * B column c: strip c then strip c+4, each NT2 n-tiles x NK chunks. Chunk = 64 rows x 128 B of the
 * packed operand (already in mmul order). */
static void sh_arrange(const int8_t *Ap, const int8_t *Bp, int8_t *A2, int8_t *B2, long M, long K) {
    const long nk = K / 128, hk = nk / 2;
    int8_t *a = A2;
    for (int c = 0; c < 4; c++)
        for (long s = 0; s < SH_R2; s++)
            for (long jj = 0; jj < hk; jj++)
                for (int r = 0; r < 64; r++, a += 128)
                    memcpy(a, Ap + ((c >> 1) * (M / 2) + s * 64 + r) * K + (2 * jj + (c & 1)) * 128, 128);
    int8_t *b = B2;
    for (int c = 0; c < 4; c++)
        for (int half = 0; half < 2; half++)
            for (long nt = 0; nt < SH_NT2; nt++)
                for (long kc = 0; kc < nk; kc++)
                    for (int r = 0; r < 64; r++, b += 128)
                        memcpy(b, Bp + (((c + 4 * half) * SH_NT2 + nt) * 64 + r) * K + kc * 128, 128);
}

'''
hs = hs.replace('int main() {', ARR + 'int main() {', 1)
md = re.search(r'const long M = KA_M, N = KA_N, K = KA_K, R = KA_R \* KA_NT', hs)
assert md
hs = hs.replace(md.group(0), 'const long M = 2L * 64 * SH_R2, N = 8L * 64 * SH_NT2, K = 128L * SH_NK, R = SH_R2 * SH_NT2 /* SHARE2X8 */')
old = 'int8_t *Ap = (int8_t *)__Runtime_alloc_uncached(M * K), *Bp = (int8_t *)__Runtime_alloc_uncached(N * K);'
assert old in hs
hs = hs.replace(old, 'int8_t *Ap = (int8_t *)malloc(M * K), *Bp = (int8_t *)malloc(N * K); /* SHARE2X8: packed, then re-laid */\n'
                '    int8_t *A2 = (int8_t *)__Runtime_alloc_uncached(M * K), *B2 = (int8_t *)__Runtime_alloc_uncached(N * K);')
old = '    ka_pack(B, Bp, N, K, KA_TN, 1);\n'
assert old in hs
hs = hs.replace(old, old + '    sh_arrange(Ap, Bp, A2, B2, M, K);\n')
n = hs.count('gemm_ka_run(Ap, Bp, Ct);')
assert n >= 1, n
hs = hs.replace('gemm_ka_run(Ap, Bp, Ct);', 'gemm_ka_run(A2, B2, Ct);')
old_g = '''        const long pm = i / (M / 4), s = (i % (M / 4)) / KA_TM, rr = i % KA_TM;
        for (long jj = 0; jj < N; jj += 3) {
            const long pn = jj / (KA_TN * KA_NT), nt = (jj % (KA_TN * KA_NT)) / KA_TN, cj = jj % KA_TN;
            const long q = ((rr / 8) * nti + cj / 8) * 64 + (rr % 8) * 8 + cj % 8;
            const int8_t got = Ct[((pm * 4 + pn) * R + s * KA_NT + nt) * blk + q];'''
assert old_g in hs
hs = hs.replace(old_g, '''        const long h = i / (M / 2), s = (i % (M / 2)) / KA_TM, rr = i % KA_TM; /* SHARE2X8 mapping */
        for (long jj = 0; jj < N; jj += 3) {
            const long nt2 = SH_NT2, sj = jj / (KA_TN * nt2), nt = (jj % (KA_TN * nt2)) / KA_TN, cj = jj % KA_TN;
            const long pn = sj & 3, pm = 2 * h + (sj >> 2);
            const long q = ((rr / 8) * nti + cj / 8) * 64 + (rr % 8) * 8 + cj % 8;
            const int8_t got = Ct[((pm * 4 + pn) * R + s * nt2 + nt) * blk + q];''')
if args.stress:
    # STRESS: N more launches after the timed ones, each checked (sampled); print per-tile failures
    SCHK = r"""static long sh_check(const int8_t *A, const int8_t *B, const int8_t *Ct, long M, long N, long K, long R, int verbose) {
    const long blk = 4096, nti = 8, nt2 = SH_NT2;
    long bad = 0;
    static long tb[16][128], rlo[16][128], rhi[16][128], clo[16][128], chi[16][128];
    memset(tb, 0, sizeof(tb));
    for (long i = 0; i < M; i += 7) {
        const long h = i / (M / 2), s = (i % (M / 2)) / 64, rr = i % 64;
        for (long jj = 0; jj < N; jj += 3) {
            const long sj = jj / (64 * nt2), nt = (jj % (64 * nt2)) / 64, cj = jj % 64;
            const long pn = sj & 3, pm = 2 * h + (sj >> 2), t = s * nt2 + nt, core = pm * 4 + pn;
            const long q = ((rr / 8) * nti + cj / 8) * 64 + (rr % 8) * 8 + cj % 8;
            int acc = 0;
            for (long k = 0; k < K; k++)
                acc += A[i * K + k] * B[jj * K + k];
            if (Ct[(core * R + t) * blk + q] != (int8_t)acc) {
                if (!tb[core][t]++) { rlo[core][t] = rhi[core][t] = rr; clo[core][t] = chi[core][t] = cj; }
                if (rr < rlo[core][t]) rlo[core][t] = rr;
                if (rr > rhi[core][t]) rhi[core][t] = rr;
                if (cj < clo[core][t]) clo[core][t] = cj;
                if (cj > chi[core][t]) chi[core][t] = cj;
                bad++;
            }
        }
    }
    if (bad && verbose)
        for (int c = 0; c < 16; c++)
            for (int t = 0; t < R; t++)
                if (tb[c][t])
                    printf("  bad tile core (%d,%d) t %d: %ld pts rows %ld..%ld cols %ld..%ld\n", c / 4, c % 4, t, tb[c][t],
                           rlo[c][t], rhi[c][t], clo[c][t], chi[c][t]);
    return bad;
}

"""
    hs = hs.replace('int main() {', SCHK + 'int main() {', 1)
    old = '    Xil_DCacheInvalidateRange((UINTPTR)Ct, M * N);\n'
    assert old in hs
    hs = hs.replace(old, old + """    {
        int fails = 0;
        for (int it = 0; it < %d; it++) {
            memset(Ct, 0x55, M * N);
            Xil_DCacheFlushRange((UINTPTR)Ct, M * N);
            gemm_ka_run(A2, B2, Ct);
            Xil_DCacheInvalidateRange((UINTPTR)Ct, M * N);
            const long b = sh_check(A, B, Ct, M, N, K, R, 1);
            if (b) { fails++; printf("STRESS launch %%d: %%ld bad\\n", it, b); }
        }
        printf("STRESS %%d / %%d launches bad\\n", fails, %d);
    }
""" % (args.stress, args.stress))
if args.kcyc:
    old = '    Xil_DCacheInvalidateRange((UINTPTR)Ct, M * N);\n'
    assert old in hs
    hs = hs.replace(old, old + """    for (int cr = 0; cr < 16; cr++) { /* KCYC stamps */
        const uint32_t *st = (const uint32_t *)(Ct + ((long)cr * R + R - 1) * 4096);
        if (st[0] != 0x4359434BU) { printf("KCYC core %%d: no stamp\\n", cr); continue; }
        printf("KCYC core %%2d: total %%u cyc | in-wait %%.1f %%%% mac %%.1f %%%% out-wait %%.1f %%%% cvt %%.1f %%%% other %%.1f %%%%\\n", cr,
               st[1], 100.0 * st[2] / st[1], 100.0 * st[3] / st[1], 100.0 * st[4] / st[1], 100.0 * st[5] / st[1],
               100.0 * ((double)st[1] - st[2] - st[3] - st[4] - st[5]) / st[1]);
    }
""".replace('%%', '%'))
if args.persist:
    m1 = re.search(r'  kernel_group (v\d+) = (__Runtime_load_kernel_group_16t_ctrl\([^;]*\));\n', hs)
    m2 = re.search(r'  event (v\d+) = (__Runtime_launch_kernel_group_ctrl\([^;]*\));\n', hs)
    assert m1 and m2
    kg, ev = m1.group(1), m2.group(1)
    hs = hs.replace(m1.group(0), '  /* SHARE2X8 persistent kernel: load + launch once; later launches release each core\'s go lock (14) */\n'
                    '  static int sh_launched;\n  const int sh_first = !sh_launched;\n  kernel_group %s;\n  event %s;\n'
                    '  if (sh_first) {\n    %s = %s;\n' % (kg, ev, kg, m1.group(2)))
    hs = hs.replace(m2.group(0), '    %s = %s;\n  } else {\n    for (int c = 1; c <= 4; c++)\n      for (int r = 3; r <= 6; r++)\n'
                    '        XAie_LockSetValue(v1, XAie_TileLoc(c, r), XAie_LockInit(14, 1));\n  }\n' % (ev, m2.group(2)))
    old = '  __Runtime_wait(v1, %s);\n' % ev
    assert hs.count(old) == 1
    hs = hs.replace(old, '  if (sh_first) __Runtime_wait(v1, %s);\n' % ev)
    hs = hs.replace('  g_bd_once = 1;\n', '  g_bd_once = 1;\n  sh_launched = 1;\n', 1)
if args.perfcnt:
    old = '        gemm_ka_run(A2, B2, Ct);\n        XTime_GetTime(&t1);\n'
    assert hs.count(old) == 1, hs.count(old)
    hs = hs.replace(old, """        XAie_DevInst *pdv = __Runtime_get_partition_dev(0);
        if (it == 3)
            for (int c = 1; c <= 4; c++)
                for (int r = 3; r <= 6; r++) { /* SHARE2X8 --perfcnt */
                    const XAie_LocType t = XAie_TileLoc(c, r);
                    const XAie_Events ev[4] = {XAIE_EVENT_ACTIVE_CORE, XAIE_EVENT_MEMORY_STALL_CORE, XAIE_EVENT_LOCK_STALL_CORE,
                                               XAIE_EVENT_INSTR_VECTOR_CORE};
                    for (int k = 0; k < 4; k++) {
                        XAie_PerfCounterSet(pdv, t, XAIE_CORE_MOD, (u8)k, 0);
                        XAie_PerfCounterControlSet(pdv, t, XAIE_CORE_MOD, (u8)k, ev[k], ev[k]);
                    }
                    const XAie_Events mv[2] = {XAIE_EVENT_CONFLICT_DM_BANK_4_MEM, XAIE_EVENT_CONFLICT_DM_BANK_6_MEM};
                    for (int k = 0; k < 2; k++) {
                        XAie_PerfCounterSet(pdv, t, XAIE_MEM_MOD, (u8)k, 0);
                        XAie_PerfCounterControlSet(pdv, t, XAIE_MEM_MOD, (u8)k, mv[k], mv[k]);
                    }
                }
""" + old + """        if (it == 3)
            for (int c = 1; c <= 4; c++)
                for (int r = 3; r <= 6; r++) {
                    const XAie_LocType t = XAie_TileLoc(c, r);
                    u32 v[6] = {0, 0, 0, 0, 0, 0};
                    for (int k = 0; k < 4; k++) XAie_PerfCounterGet(pdv, t, XAIE_CORE_MOD, (u8)k, &v[k]);
                    for (int k = 0; k < 2; k++) XAie_PerfCounterGet(pdv, t, XAIE_MEM_MOD, (u8)k, &v[4 + k]);
                    printf("PERFCNT core (%d,%d): active %u memstall %u (%.1f %%) lockstall %u (%.1f %%) vec %u | DM conflicts b4 %u b6 %u\\n", c, r,
                           v[0], v[1], 100.0 * v[1] / (v[0] ? v[0] : 1), v[2], 100.0 * v[2] / (v[0] ? v[0] : 1), v[3], v[4], v[5]);
                }
""")
# the launch's cache-maintenance sizes come from the BASE ports; with the target's smaller A the range
# ran past the non-cacheable mapping and every launch cleaned 13.8 MB of cache (~0.43 ms)
M_, N_, K_ = 2 * 64 * R2, 8 * 64 * NT2, 128 * NK
hs, nl = re.subn(r'__aie_launch\("gemm_ka", mesh, A, \(size_t\)\d+, B, \(size_t\)\d+, C, \(size_t\)\d+\)',
                 '__aie_launch("gemm_ka", mesh, A, (size_t)%d, B, (size_t)%d, C, (size_t)%d) /* SHARE2X8 target sizes */' % (M_ * K_, N_ * K_, M_ * N_), hs)
assert nl == 1, nl
if args.bench:
    hs = hs.replace('    for (int cr = 0; cr < 16; cr++) { /* KCYC stamps */', """    for (int cr = 0; cr < 16; cr++) { /* KBENCH */
        const uint32_t *st = (const uint32_t *)(Ct + ((long)cr * R + R - 1) * 4096);
        printf("KBENCH core %%2d: ka_tile no-wait %%.1f cycles / chunk (ideal 1024) -> %%.1f %%%%; live run %%.1f cycles / chunk\\n", cr,
               st[6] / (2.0 * %d), 100.0 * 1024 * 2 * %d / st[6], st[3] / (double)(R * %d));
    }
    for (int cr = 0; cr < 16; cr++) { /* KCYC stamps */""" % (NK, NK, NK))
if args.zones:
    zones = dict(kv.split('=') for kv in args.zones.split(','))
    def zal(name, size_expr, default):
        if name not in zones:
            return default
        base, size = zones[name].split(':')
        return '(int8_t *)__Runtime_alloc_zone(%sULL, %sULL, %s) /* zone */' % (base, size, size_expr)
    old = 'int8_t *A2 = (int8_t *)__Runtime_alloc_uncached(M * K), *B2 = (int8_t *)__Runtime_alloc_uncached(N * K);'
    assert old in hs
    hs = hs.replace(old, 'int8_t *A2 = %s, *B2 = %s;' % (zal('A', 'M * K', '(int8_t *)__Runtime_alloc_uncached(M * K)'),
                                                         zal('B', 'N * K', '(int8_t *)__Runtime_alloc_uncached(N * K)')))
    old = 'int8_t *Ct = (int8_t *)__Runtime_Alloc(M * N);'
    assert old in hs
    hs = hs.replace(old, 'int8_t *Ct = %s;' % zal('C', 'M * N', '(int8_t *)__Runtime_Alloc(M * N)'))
    hs = hs.replace('void *__Runtime_alloc_uncached(size_t bytes);', 'void *__Runtime_alloc_uncached(size_t bytes);\nvoid *__Runtime_alloc_zone(uint64_t zone_base, uint64_t zone_size, size_t bytes);', 1)
    hs = hs.replace('int main() {', 'int main() {\n    printf("[share2x8] zones: %s\\n");' % args.zones, 1)
if args.kc == 256:
    n_ = hs.count('#define KA_KC 128')
    assert n_ >= 1, n_
    hs = hs.replace('#define KA_KC 128', '#define KA_KC 256 /* SHARE2X8: packed in 256-wide chunks */')
    a_ = hs.index('static void sh_arrange(')
    b_ = hs.index('\n}\n', a_) + 3
    hs = hs[:a_] + """static void sh_arrange(const int8_t *Ap, const int8_t *Bp, int8_t *A2, int8_t *B2, long M, long K) {
    /* KC 256: a chunk = 64 rows x 256 (packed); column c's A stream = the (c & 1) half (rows 32 (c & 1) ..
       + 31, 8 KB) of every chunk of strip c >> 1; column c's B = strips c, c+4, whole 16 KB chunks. */
    const long nk = K / 256;
    int8_t *a = A2;
    for (int c = 0; c < 4; c++)
        for (long s = 0; s < SH_R2; s++)
            for (long j = 0; j < nk; j++)
                for (int r = 0; r < 32; r++, a += 256)
                    memcpy(a, Ap + ((c >> 1) * (M / 2) + s * 64 + 32 * (c & 1) + r) * K + j * 256, 256);
    int8_t *b = B2;
    for (int c = 0; c < 4; c++)
        for (int half = 0; half < 2; half++)
            for (long nt = 0; nt < SH_NT2; nt++)
                for (long j = 0; j < nk; j++)
                    for (int r = 0; r < 64; r++, b += 256)
                        memcpy(b, Bp + (((c + 4 * half) * SH_NT2 + nt) * 64 + r) * K + j * 256, 256);
}
""" + hs[b_:]
open(wl + '/host.cc', 'w').write(hs)
print('host: MemTiles, DDR layout, golden mapping%s' % (', weight-resident B' if bres else ''))

# ---------------------------------------------------------------- kernel.cc: hosted-stream DMA
kc = open(wl + '/kernel.cc').read()
a = kc.index('  { // KERNELCONFIGOFFLOAD S2MM window_in_0')
b = kc.index('  { // KERNELCONFIGOFFLOAD MM2S window_out_0')
KCO = r'''  { // SHARE2X8 S2MM: this tile hosts one operand stream; chunk parity -> channel, 2 buffers (slots) each;
    // chunk rows 0-31 -> bank 2 (0x78000 + q * 4 KB), rows 32-63 -> bank 3 (+16 KB), q = 2 ch + slot.
    // Locks per ch: F 6+4ch (DMA -> first reader), G 7+4ch (first -> second reader), and one E per SLOT,
    // 8+4ch+slot (both readers -> DMA, which acquires -2): a per-channel E would let a fast first reader's
    // releases of slot 0 AND slot 1 free slot 0 while the second reader is still in it (seen: corrupt rows).
    AieKcReg _kc[8];
    int _n;
    const AieKcDims _d = {1, 128, 128, 8, 4096, 0, 0}; // 512 B x 8 = 4 KB, then +16 KB (wraps are 8-bit: 256 = off)
    for (int _ch = 0; _ch < 2; _ch++) {
      for (int _k = 0; _k < 2; _k++) {
        const int _q = 2 * _ch + _k;
        _n = aie_kc_encode_bd_nd(_kc, (uint8_t)_q, (uintptr_t)(0x78000 + _q * 4096), 8192, 2 * _ch + (_k ^ 1),
                                 8 + 4 * _ch + _k, -2, 6 + 4 * _ch, 1, 0, 0, 0, -1, &_d);
        core_reg_write_block(_kc, _n);
        aie_kc_encode_lock(_kc, (uint8_t)(8 + 4 * _ch + _k), 2);
        core_reg_write(_kc[0].off, _kc[0].val);
      }
      aie_kc_encode_lock(_kc, (uint8_t)(6 + 4 * _ch), 0);
      core_reg_write(_kc[0].off, _kc[0].val);
      aie_kc_encode_lock(_kc, (uint8_t)(7 + 4 * _ch), 0);
      core_reg_write(_kc[0].off, _kc[0].val);
      aie_kc_encode_s2mm_start(_kc, (uint8_t)_ch, (uint8_t)(2 * _ch), 1, 0);
      core_reg_write(_kc[0].off, _kc[0].val);
    }
    aie_kc_encode_lock(_kc, 14, 1); // go lock: the first launch runs at once (persistent mode)
    core_reg_write(_kc[0].off, _kc[0].val);
    aie_kc_encode_lock(_kc, 15, 0); // dummy lock for the KC 256 tile (held at 0: acquire(..,0) / release(..,0) no-ops)
    core_reg_write(_kc[0].off, _kc[0].val);
  }
'''
if args.kc == 256:
    KCO = KCO.replace("const AieKcDims _d = {1, 128, 128, 8, 4096, 0, 0}; // 512 B x 8 = 4 KB, then +16 KB (wraps are 8-bit: 256 = off)",
                      "const AieKcDims _d = {0, 0, 0, 0, 0, 0, 0}; // KC 256: channel c's 8 KB half, contiguous in bank 2 + c")
    old_bd = "_n = aie_kc_encode_bd_nd(_kc, (uint8_t)_q, (uintptr_t)(0x78000 + _q * 4096), 8192, 2 * _ch + (_k ^ 1),"
    assert old_bd in KCO
    KCO = KCO.replace(old_bd, "_n = aie_kc_encode_bd_nd(_kc, (uint8_t)_q, (uintptr_t)(0x78000 + _ch * 0x4000 + _k * 8192), 8192, 2 * _ch + (_k ^ 1),")
if args.qslot:  # a channel's two slots in different DM banks (kernel: SH_QSLOT in share2x8_tile.inc)
    assert args.tile and args.kc == 128
    KCO = KCO.replace('(uintptr_t)(0x78000 + _q * 4096), 8192,', '(uintptr_t)(0x78000 + (2 * _k + _ch) * 4096), 8192,')
    assert '(2 * _k + _ch) * 4096' in KCO
kc = kc[:a] + KCO + kc[b:]
if not args.single:
    # output: two tiles per packet. The packet must not START before both tiles are written -- a packet
    # waiting mid-route for its second tile holds the row's merged output route, the other cores' outputs
    # back up, they stop releasing the shared input buffers, and the waiting core never gets its input
    # (deadlock, seen on the board). So ping BD 4 acquires the full lock with -2 (both tiles ready),
    # keeps the header and suppresses TLAST; pong BD 5 acquires nothing, has no header, ends the packet.
    kc, n4 = re.subn(r'_n = aie_kc_encode_bd\(_kc, 4, \(uintptr_t\)buf_out_ping_0, 4096, 5, 5, -1, (4, 1, 1, \d+, 0, \d+)\);\n(\s*)core_reg_write_block\(_kc, _n\);',
                     r'_n = aie_kc_encode_bd(_kc, 4, (uintptr_t)buf_out_ping_0, 4096, 5, 5, -2, \1);\n\2_kc[5].val |= 0x80000000u; /* SHARE2X8: TLAST suppressed, pong ends the packet */\n\2core_reg_write_block(_kc, _n);', kc)
    kc, n5 = re.subn(r'_n = aie_kc_encode_bd\(_kc, 5, \(uintptr_t\)buf_out_pong_0, 4096, 4, 5, -1, 4, 1, 1, (\d+), 0, (\d+)\);',
                     r'{ const AieKcDims _d1 = {0, 0, 0, 0, 0, 0, 0}; _n = aie_kc_encode_bd_nd(_kc, 5, (uintptr_t)buf_out_pong_0, 4096, 4, -1, 0, 4, 1, 0, \1, 0, \2, &_d1); } /* SHARE2X8: release-only, no header */', kc)
    assert n4 == 16 and n5 == 16, (n4, n5)
open(wl + '/kernel.cc', 'w').write(kc)
print('kernel.cc: hosted-stream DMA')

# ---------------------------------------------------------------- gemm_ka.cc: kernel body
gk = open(wl + '/gemm_ka.cc').read()
CHUNK = ('#define SH_QSLOT 1\n' if args.qslot else '') + ('#define SH_DMAONLY 1\n' if args.dmaonly else '') + ('#define K4_KC %d\n' % args.kc if args.tile else '') + open(os.path.join(os.path.dirname(os.path.abspath(__file__)), ('share2x8_tile256.inc' if args.kc == 256 else 'share2x8_tile.inc') if args.tile else 'share2x8_chunk.inc')).read()
gk = gk.replace('  void gemm_ka(', CHUNK + '\n  void gemm_ka(', 1)
a = gk.index('#if defined(__chess__)\n    // On the core')
b = gk.index('#else\n    // Traced')
m = re.search(r'aiehlc_store_buffer\(c, aiehlc_desc_c, aiehlc_cur_c, ([^{]*)\{', gk[a:b])
assert m
ids = m.group(1)
LOOP = r'''#if defined(__chess__)
#define KCYC_ON %(KCYC)d
#define PERSIST %(PERSIST)d
    // SHARE2X8: operands from the host tiles (own / north 0x60000 / south 0x40000 views; locks own 48+,
    // north 32+, south 0+). A first reader of a buffer hands it to the second right after acquiring.
    {
        const uintptr_t vA = (pm == 0 || pm == 3) ? 0x70000 : pm == 1 ? 0x40000 : 0x60000;
        const uintptr_t vB = pm < 2 ? 0x60000 : 0x40000;
        const int lA = (pm == 0 || pm == 3) ? 48 : pm == 1 ? 0 : 32;
        const int lB = pm < 2 ? 32 : 0;
        const int aFirst = (pm == 0 || pm == 2), bFirst = pm < 2;
        const int al = pm & 1, be = pm >> 1;
        unsigned gc = 0; /* chunks consumed this launch */
        for (int launch = 0; PERSIST || launch < 1; launch++) {
            if (PERSIST)
                acquire_greater_equal(48 + 14, 1); /* go: one launch */
            uint64_t k_in = 0, k_mac = 0, k_out = 0, k_cv = 0;
            const uint64_t k_beg = (uint64_t)aie::tile::current().cycles();
            for (int t = 0; t < %(T)d; t++) { /* tile t = (m tile t / NT2, n tile t %% NT2); 2 tiles per packet */
                uint64_t k0 = (uint64_t)aie::tile::current().cycles();
                int8_t *y = acquire_output_window(c);
                k_out += (uint64_t)aie::tile::current().cycles() - k0;
                for (int i = 0; i < KA_TM * KA_TN; i += 64)
                    aie::store_v(acc + i, aie::zeros<int32_t, 64>());
                for (int j = 0; j < %(NK)d; j++, gc++) { /* TARGET chunks per tile (not the base's KA_K) */
                    const int ch = gc & 1, sl = (gc >> 1) & 1, q = 2 * ch + sl; /* slot alternates per channel */
                    const uint64_t k1 = (uint64_t)aie::tile::current().cycles();
                    if (aFirst) {
                        acquire_greater_equal(lA + 6 + 4 * ch, 1);
                        release(lA + 7 + 4 * ch, 1);
                    } else {
                        acquire_greater_equal(lA + 7 + 4 * ch, 1);
                    }
                    if (bFirst) {
                        acquire_greater_equal(lB + 6 + 4 * ch, 1);
                        release(lB + 7 + 4 * ch, 1);
                    } else {
                        acquire_greater_equal(lB + 7 + 4 * ch, 1);
                    }
                    const int8_t *a0 = (const int8_t *)(vA + 0x8000 + q * 4096), *a1 = (const int8_t *)(vA + 0xc000 + q * 4096);
                    const int8_t *b0 = (const int8_t *)(vB + 0x8000 + q * 4096), *b1 = (const int8_t *)(vB + 0xc000 + q * 4096);
                    const uint64_t k2 = (uint64_t)aie::tile::current().cycles();
                    ka_chunk(al ? a1 : a0, al ? a0 : a1, be ? b1 : b0, be ? b0 : b1, acc, acc + 2048);
                    const uint64_t k3 = (uint64_t)aie::tile::current().cycles();
                    k_in += k2 - k1;
                    k_mac += k3 - k2;
                    release(lA + 8 + 4 * ch + sl, 1); /* E of THIS slot */
                    release(lB + 8 + 4 * ch + sl, 1);
                }
                const uint64_t k4 = (uint64_t)aie::tile::current().cycles();
                for (int bl = 0; bl < 16; bl++) { /* iteration block bl holds logical block bl ^ 8 al ^ 2 be */
                    const int L = bl ^ (al << 3) ^ (be << 1);
                    int8_t *tt = y + ((2 * (L >> 2)) * nti + 2 * (L & 3)) * 64;
                    const int32_t *ap = acc + KA_AO(bl);
                    KaMM Z0, Z1, Z2, Z3;
                    KA_LD4(Z, ap);
                    chess_separator_scheduler();
                    KA_ST8(tt, Z, nti);
                    chess_separator_scheduler();
                }
                k_cv += (uint64_t)aie::tile::current().cycles() - k4;
                if (KCYC_ON && t == %(T)d - 1) {
                    uint32_t *st = (uint32_t *)y;
                    st[0] = 0x4359434BU;
                    st[1] = (uint32_t)((uint64_t)aie::tile::current().cycles() - k_beg);
                    st[2] = (uint32_t)k_in;
                    st[3] = (uint32_t)k_mac;
                    st[4] = (uint32_t)k_out;
                    st[5] = (uint32_t)k_cv;
                }
                release_output_window(c);
            }
    }
    }
''' % {'T': T, 'NK': NK, 'KCYC': 1 if args.kcyc else 0, 'PERSIST': 1 if args.persist else 0}
gk = gk[:a] + LOOP + gk[b:]
if args.tile:
    a = gk.index('                for (int j = 0; j < %d; j++, gc++) {' % NK)
    b = gk.index('                const uint64_t k4 = ', a)
    gk = gk[:a] + ("""                const uint64_t k2 = (uint64_t)aie::tile::current().cycles();
                ka_tile(vA, vB, lA, lB, (aFirst ? 1 : 0) | (bFirst ? 2 : 0) | (al ? 4 : 0) | (be ? 8 : 0) | ZF, gc, %d, 1, acc,
                        acc + 2048, y, (al << 3) ^ (be << 1)); /* whole tile incl. the int8 output; lock waits inside (KCYC: mac) */
                gc += %d;
                k_mac += (uint64_t)aie::tile::current().cycles() - k2;
""" % (args.k // args.kc, args.k // args.kc)) + gk[b:]
    zero = '                for (int i = 0; i < KA_TM * KA_TN; i += 64)\n                    aie::store_v(acc + i, aie::zeros<int32_t, 64>());\n'
    gk = gk.replace(' | ZF, gc,', ', gc,')
    if args.kc == 128:  # sh_convert (share2x8_tile.inc) leaves acc zeroed: zero it once per launch, not per tile
        assert gk.count(zero) == 1
        gk = gk.replace(zero, '')
        gk = gk.replace('            for (int t = 0; t < %d; t++) {' % T, zero.replace('                ', '            ', 2) + '            for (int t = 0; t < %d; t++) {' % T, 1)
    a = gk.index('                for (int bl = 0; bl < 16; bl++) { /* iteration block bl holds logical block bl ^ 8 al ^ 2 be */')
    b = gk.index('                k_cv += ', a)
    gk = gk[:a] + ('' if args.kc == 128 else '                sh_convert(y, acc, (al << 3) ^ (be << 1));\n') + gk[b:]
if args.bench:
    old = '        unsigned gc = 0; /* chunks consumed this launch */\n'
    assert old in gk
    gk = gk.replace(old, old + """        uint32_t k_bench;
        { /* BENCH: 2 tiles with no lock waits (lock values 0), DMA live; results discarded */
            const uint64_t b0 = (uint64_t)aie::tile::current().cycles();
            for (int r = 0; r < 2; r++)
                ka_tile(vA, vB, lA, lB, (aFirst ? 1 : 0) | (bFirst ? 2 : 0) | (al ? 4 : 0) | (be ? 8 : 0), 0, %d, 0, acc, acc + 2048, (int8_t *)acc, 0);
            k_bench = (uint32_t)((uint64_t)aie::tile::current().cycles() - b0);
        }
""" % NK)
    gk = gk.replace('                    st[5] = (uint32_t)k_cv;\n', '                    st[5] = (uint32_t)k_cv;\n                    st[6] = k_bench;\n')
if args.kc != 128:  # share2x8_tile256.inc's ka_tile has no output arguments (sh_convert converts)
    gk = gk.replace(', y, (al << 3) ^ (be << 1)); /*', '); /*').replace(', (int8_t *)acc, 0);', ');')
open(wl + '/gemm_ka.cc', 'w').write(gk)
print('gemm_ka.cc: shared-operand kernel')
