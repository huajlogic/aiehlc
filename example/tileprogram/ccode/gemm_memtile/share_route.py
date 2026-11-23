# Stream-route helper for the hand-built 2x8 shared-operand GEMM (share2x8.py).
# Parses a generated routing.cc, separates the input routes (everything reachable from a shim MM2S
# port, through MemTile staging) from the rest (outputs, packet switching), books every port the
# kept lines use plus the control-packet fabric's row ports, and routes new circuit-switched
# multicast nets on the free lanes (BFS from the net's current tree).
import re
from collections import deque

# AIE2PS stream-switch port counts (xaie2psgbl_reginit.c): (masters, slaves) per direction / DMA
CORE = {'m': {'NORTH': 6, 'SOUTH': 4, 'EAST': 4, 'WEST': 4, 'DMA': 2},
        's': {'SOUTH': 6, 'NORTH': 4, 'EAST': 4, 'WEST': 4, 'DMA': 2}}
MEM = {'m': {'NORTH': 6, 'SOUTH': 4, 'DMA': 6}, 's': {'SOUTH': 6, 'NORTH': 4, 'DMA': 6}}
SHIM = {'m': {'NORTH': 6, 'SOUTH': 6, 'EAST': 4, 'WEST': 4}, 's': {'SOUTH': 8, 'NORTH': 4, 'EAST': 4, 'WEST': 4}}
STEP = {'NORTH': (0, 1), 'SOUTH': (0, -1), 'EAST': (1, 0), 'WEST': (-1, 0)}
OPP = {'NORTH': 'SOUTH', 'SOUTH': 'NORTH', 'EAST': 'WEST', 'WEST': 'EAST'}

CCT = re.compile(r'XAie_StrmConnCctEnable\(v1, XAie_TileLoc\((\d+),(\d+)\), (\w+), (\d+), (\w+), (\d+)\);')
SHIM_IN = re.compile(r'XAie_EnableShimDmaToAieStrmPort\(v1, XAie_TileLoc\((\d+),(\d+)\), (\d+)\);')
PKT_SLV = re.compile(r'XAie_StrmPktSwSlave(?:Slot|Port)Enable\(v1, XAie_TileLoc\((\d+),(\d+)\), (\w+), (\d+)')
PKT_MST = re.compile(r'XAie_StrmPktSwMstrPortEnable\(v1, XAie_TileLoc\((\d+),(\d+)\), (\w+), (\d+)')


def kind(row):
    return SHIM if row == 0 else MEM if row in (1, 2) else CORE


class Fabric:
    def __init__(self, cols, rows=7):
        self.cols, self.rows = cols, rows
        self.used = set()  # (col, row, 'm'|'s', type, idx)

    def free(self, c, r, ms, t, i):
        return i < kind(r)[ms].get(t, 0) and (c, r, ms, t, i) not in self.used

    def book(self, c, r, ms, t, i):
        assert self.free(c, r, ms, t, i), ('port taken', c, r, ms, t, i)
        self.used.add((c, r, ms, t, i))

    def lane(self, c, r, d, need=None):
        """lowest index k with master d k free here and the matching slave free on the neighbour;
        need: the only allowed k (a MemTile passes SOUTH / NORTH slave k only to SOUTH / NORTH master k --
        _XAie2PS_MemTile_StrmSwCheckPortValidity; anything else is silently not connected)"""
        dc, dr = STEP[d]
        nc, nr = c + dc, r + dr
        if not (nc in self.cols and 0 <= nr < self.rows):
            return None
        for k in range(kind(r)['m'].get(d, 0)):
            if need is not None and k != need:
                continue
            if self.free(c, r, 'm', d, k) and self.free(nc, nr, 's', OPP[d], k):
                return k
        return None


def split_routing(text):
    """(input_lines, kept_lines) of a generated routing.cc body"""
    lines = text.splitlines()
    cct = {}
    for n, l in enumerate(lines):
        m = CCT.search(l)
        if m:
            c, r, st, si, mt, mi = m.groups()
            cct[n] = (int(c), int(r), st, int(si), mt, int(mi))
    # frontier: slave ports carrying input data
    live = set()
    for l in lines:
        m = SHIM_IN.search(l)
        if m:
            live.add((int(m.group(1)), int(m.group(2)), 'SOUTH', int(m.group(3))))
    inputs = set()
    changed = True
    while changed:
        changed = False
        for n, (c, r, st, si, mt, mi) in cct.items():
            if n in inputs or (c, r, st, si) not in live:
                continue
            inputs.add(n)
            changed = True
            if mt == 'DMA':
                if r in (1, 2):  # MemTile staging: what goes in comes out again
                    live.add((c, r, 'DMA', mi))
                continue
            dc, dr = STEP[mt]
            live.add((c + dc, r + dr, OPP[mt], mi))
    in_lines = [lines[n] for n in sorted(inputs)]
    in_lines += [l for l in lines if SHIM_IN.search(l)]
    kept = [l for n, l in enumerate(lines) if n not in inputs and not SHIM_IN.search(l)]
    return in_lines, kept


def book_kept(fab, kept, ctrl_rows=(3, 4, 5, 6)):
    for l in kept:
        m = CCT.search(l)
        if m:
            c, r, st, si, mt, mi = m.groups()
            fab.used.add((int(c), int(r), 's', st, int(si)))
            fab.used.add((int(c), int(r), 'm', mt, int(mi)))
        m = PKT_SLV.search(l)
        if m:
            fab.used.add((int(m.group(1)), int(m.group(2)), 's', m.group(3), int(m.group(4))))
        m = PKT_MST.search(l)
        if m:
            fab.used.add((int(m.group(1)), int(m.group(2)), 'm', m.group(3), int(m.group(4))))
    # control-packet row fabric: forward EAST / return WEST on port 0 through every data tile
    for r in ctrl_rows:
        for c in fab.cols:
            for ms, t in (('s', 'WEST'), ('m', 'EAST'), ('s', 'EAST'), ('m', 'WEST')):
                fab.used.add((c, r, ms, t, 0))


def route_net(fab, src, dests):
    """src = (col, row, slave_type, slave_idx); dests = [(col, row, dma_ch)].
    Returns XAie_StrmConnCctEnable lines. Every tile of the tree has one incoming slave."""
    fab.book(src[0], src[1], 's', src[2], src[3])
    tree = {(src[0], src[1]): (src[2], src[3])}  # tile -> its incoming slave
    out = []
    for (dc, dr, ch) in dests:
        if (dc, dr) not in tree:
            # BFS from all tree tiles; state = (tile, incoming slave), since a MemTile's pass-through
            # lane is tied to the lane it came in on
            start = [(t[0], t[1], tree[t]) for t in tree]
            prev: dict = {st: None for st in start}
            q = deque(start)
            goal = None
            while q and goal is None:
                st = q.popleft()
                c, r, sl = st
                for d in ('NORTH', 'EAST', 'WEST', 'SOUTH'):
                    nc, nr = c + STEP[d][0], r + STEP[d][1]
                    if (nc, nr) in tree or not (nc in fab.cols and 0 <= nr < fab.rows):
                        continue
                    tied = r in (1, 2) and sl[0] in ('SOUTH', 'NORTH') and d in ('SOUTH', 'NORTH')
                    for k in range(kind(r)['m'].get(d, 0)):
                        if tied and k != sl[1]:
                            continue
                        if not (fab.free(c, r, 'm', d, k) and fab.free(nc, nr, 's', OPP[d], k)):
                            continue
                        ns = (nc, nr, (OPP[d], k))
                        if ns in prev:
                            continue
                        prev[ns] = (st, d, k)
                        if (nc, nr) == (dc, dr):
                            goal = ns
                            break
                        q.append(ns)
                    if goal is not None:
                        break
            if goal is None:
                raise RuntimeError('no route %s -> %s' % (src, (dc, dr, ch)))
            path = []
            st = goal
            while prev[st] is not None:
                ps, d, k = prev[st]
                path.append((ps[0], ps[1], d, k))
                st = ps
            for (c, r, d, k) in reversed(path):
                sl = tree[(c, r)]
                fab.book(c, r, 'm', d, k)
                nc, nr = c + STEP[d][0], r + STEP[d][1]
                fab.book(nc, nr, 's', OPP[d], k)
                tree[(nc, nr)] = (OPP[d], k)
                out.append('XAie_StrmConnCctEnable(v1, XAie_TileLoc(%d,%d), %s, %d, %s, %d);' % (c, r, sl[0], sl[1], d, k))
        sl = tree[(dc, dr)]
        fab.book(dc, dr, 'm', 'DMA', ch)
        out.append('XAie_StrmConnCctEnable(v1, XAie_TileLoc(%d,%d), %s, %d, DMA, %d);' % (dc, dr, sl[0], sl[1], ch))
    return out
