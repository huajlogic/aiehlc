###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
# Shim BD rewrite for share2x8.py: the base build's generated host_canonicalized() programs one A
# BD and one B BD per shim column and one output (S2MM, out-of-order) BD per core; this rewrites
# them for the 2 x 8 target shape, with the DMA streams laid out CONTIGUOUSLY in DDR:
#   A, column c:  R2 m tiles x NK/2 chunks (strip c >> 1, chunk parity c & 1), 8 KB each
#   B, column c:  strip c then strip c+4, NT2 x NK chunks each
#   C, core k:    T tiles of 4 KB, tile-major; the core sends 2 tiles per packet, so one
#                 output BD use lands 8 KB and T / 2 iterations cover the launch.
# Classification follows the address chain back to the launch argument (v2 = A, v3 = B, v4 = C);
# a core's output BD is identified by its packet id (routing.cc: the core DMA's packet slot).
import re

CALL = re.compile(r'__Runtime_dma_bd_config_multidim_ooo\(v1, (v\d+), (v\d+), ([^;]*)\)')


def _vars(hs):
    tiles = {m.group(1): (int(m.group(2)), int(m.group(3)))
             for m in re.finditer(r'XAie_LocType (v\d+) = XAie_TileLoc\((\d+), (\d+)\);', hs)}
    root = {}
    for m in re.finditer(r'void\* (v\d+) = __runtime_buffer_(?:offset|arg)\((v\d+)(?:, v?\d+)?\);', hs):
        root[m.group(1)] = root.get(m.group(2), m.group(2))  # textual order: definitions come first
    return tiles, root


def packet_cores(routing):
    """packet id -> core index pm * 4 + pn, from each core DMA's packet slot"""
    out = {}
    for m in re.finditer(r'XAie_StrmPktSwSlaveSlotEnable\(v1, XAie_TileLoc\((\d+),(\d+)\), DMA, 0, 0, XAie_PacketInit\((\d+), 0\)', routing):
        col, row, pid = int(m.group(1)), int(m.group(2)), int(m.group(3))
        out[pid] = (row - 3) * 4 + (col - 1)
    return out


def patch_shim_bds(hs, routing, R2, NT2, NK, T, per_pkt=2, a2=False):
    """a2: this BD streams only the even m tiles (the odd ones go out on channel 0, a_odd_block)"""
    ra = 2 if a2 else 1
    tiles, root = _vars(hs)
    pkt = packet_cores(routing)
    a_len, b_len = NK // 2 * 8192, NT2 * NK * 8192
    kinds = {}  # desc var -> 'A' | 'B' | 'C'
    n = {'A': 0, 'B': 0, 'C': 0}

    def repl(m):
        tile, addr, rest = m.group(1), m.group(2), m.group(3)
        a = [x.strip() for x in rest.split(',')]
        base = root.get(addr)
        col = tiles[tile][0]
        if base == 'v2':  # A: column col's stream, contiguous
            kind, off = 'A', (col - 1) * R2 * a_len
            a[1] = str(a_len)
            a[-9:] = ['3', '4', '32', '128', '64', '8192', str(NK // 2), str(ra * a_len), str(R2 // ra)]
        elif base == 'v3':  # B: strip c, strip c+4
            kind, off = 'B', (col - 1) * 2 * b_len
            a[1] = str(b_len)
            a[-9:] = ['3', '4', '32', '128', '64', '8192', str(NT2 * NK), str(b_len), '2']
        elif base == 'v4':  # C: core's T tiles, two per BD use
            kind, off = 'C', pkt[int(a[4])] * T * 4096
            a[1] = str(4096 * per_pkt)
            a[-9:] = ['2', '4', '16', '64', str(64 * per_pkt), '0', '0', str(4096 * per_pkt), str(T // per_pkt)]
        else:
            return m.group(0)
        n[kind] += 1
        root_var = next(v for v, r in root.items() if r == base and re.search(
            r'void\* %s = __runtime_buffer_offset\(%s, 0\);' % (v, base), hs))
        new_addr = '__runtime_buffer_offset(__runtime_buffer_arg(%s), (int64_t)%d)' % (root_var, off)
        return '__Runtime_dma_bd_config_multidim_ooo(v1, %s, %s, %s)' % (tile, new_addr, ', '.join(a))

    out_lines = []
    for line in hs.split('\n'):
        m = re.search(r'XAie_DmaDesc (v\d+) = .*' + CALL.pattern, line)
        if m:
            line2 = CALL.sub(repl, line)
            addr = m.group(3)
            b = root.get(addr)
            if b in ('v2', 'v3', 'v4'):
                kinds[m.group(1)] = {'v2': 'A', 'v3': 'B', 'v4': 'C'}[b]
            line = line2
        out_lines.append(line)
    hs = '\n'.join(out_lines)
    io_kind = {m.group(1): kinds.get(m.group(2)) for m in
               re.finditer(r'io (v\d+) = __Runtime_dma_createio_4\(v\d+, (v\d+),', hs)}

    def rep_start(m):
        k = io_kind.get(m.group(1))
        rep = {'A': R2 // ra, 'B': 2, 'C': 4 * T // per_pkt}.get(k or '')
        if rep is None:
            return m.group(0)
        return '__Runtime_startio(v1, %s, %s, %d)' % (m.group(1), m.group(2), rep)

    hs = re.sub(r'__Runtime_startio\(v1, (v\d+), (\d+), (\d+)\)', rep_start, hs)
    assert n['A'] == 4 and n['B'] == 4 and n['C'] == 16, n
    return hs


def a_odd_block(hs, R2, NK, bd=14):
    """host code: the odd m tiles of each column's A stream on shim MM2S channel 0 (B's channel,
    free once B is resident), into the row-2 MemTile's S2MM ch0; re-routes on first use"""
    _, root = _vars(hs)
    root_var = next(v for v, r in root.items() if r == 'v2' and re.search(
        r'void\* %s = __runtime_buffer_offset\(v2, 0\);' % v, hs))
    a_len = NK // 2 * 8192
    return '''  /* SHARE2X8 --a2ch: odd m tiles of A on shim MM2S ch0 (B's channel; re-routed once B is resident) */
  static int sh_rerouted;
  if (!sh_rerouted) {
    sh_rerouted = 1;
    sh_reroute(v1);
  }
  ioevent sh_ao[4];
  for (int c = 1; c <= 4; c++) {
    XAie_DmaDesc d = g_bd_once ? XAie_DmaDesc() : __Runtime_dma_bd_config_multidim_ooo(v1, XAie_TileLoc(c, 0), __runtime_buffer_offset(__runtime_buffer_arg(%(rv)s), (int64_t)((c - 1) * %(R2)dLL * %(al)d + %(al)d)), %(bd)d, %(al)d, -1, 0, 0, 0, 0, 0, 0, -1, 3, 4, 32, 128, 64, 8192, %(hk)d, %(al2)d, %(r2h)d);
    io o = __Runtime_dma_createio_4(XAie_TileLoc(c, 0), d, 0, %(bd)d, DMA_MM2S);
    sh_ao[c - 1] = __Runtime_startio(v1, o, %(bd)d, %(r2h)d);
  }
''' % {'rv': root_var, 'R2': R2, 'al': a_len, 'bd': bd, 'hk': NK // 2, 'al2': 2 * a_len, 'r2h': R2 // 2}
