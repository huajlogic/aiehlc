#!/usr/bin/env python3
"""Pick the int8 GEMM solution for a board from its memory system (MC count, DDR zones).

The two designs in example/tileprogram/ccode/gemm_memtile/ win on different boards:

  4x4  -- gemm_kacc_v2.cc + MemTile staging (memtile_ab / memtile_split / shim_bd_once
          [/ b_resident]). Fewest DDR bytes per MAC: the MemTiles replay A NT times and B R
          times. Core input caps it (~14 B/cycle/core, 64x64 tiles need 1/32 B/MAC).
  2x8  -- share2x8.py: each tile hosts ONE operand stream that two neighbours read, a
          persistent kernel, the cross-chunk tile pipeline. Core input is no longer the
          limit; it moves a little more DDR traffic per MAC (smaller N per launch).

A single-MC board is DDR-bound and wants the 4x4 design; a board whose DDR is not the limit
wants the 2x8 one. With separately addressable zones on different MCs the plan also spreads
A / B / C over them (reads and writes on different controllers); interleaved MCs need no
placement. Every constant in BOARDS / DESIGNS is a measurement (doc/performance/
gemm_e2e_progress.md); the model is calibrated against the measured runs (--check).

usage: gemm_plan.py --board palmyra|vek385|<profile.json> [--m M --n N --k K] [--weights-fixed] [--check]
"""
import argparse
import json

# Measured board facts. ddr_rd_gbps / ddr_wr_gbps: fitted on the DDR-bound palmyra runs, where
# time = reads / rd + writes / wr predicts all four within 0.1 ms -- reads and writes do NOT
# overlap on one controller, and writes are slow. VEK385 was never DDR-bound (lower bounds).
BOARDS = {
    'palmyra': {
        'aie_mhz': 1000, 'mcs': 1, 'ddr_rd_gbps': 16.1, 'ddr_wr_gbps': 3.58,
        # 0x8_0000_0000 mirrors 0x0 on palmyra (one controller, 2 GB)
        'zones': [{'name': 'DDR_LOW0', 'base': 0x0, 'size': 0x80000000, 'mc': 0, 'heap': True}],
        'shim_ch_gbps': 3.6,
    },
    'vek385': {
        'aie_mhz': 1250, 'mcs': 3, 'ddr_rd_gbps': 100.0, 'ddr_wr_gbps': 100.0, 'interleaved': True,
        # LOW0 / LOW1 present; DDR_CH_1 (0x500_0000_0000) hangs the A78 on this PDI (probed)
        'zones': [{'name': 'DDR_LOW0', 'base': 0x0, 'size': 0x80000000, 'mc': 'il', 'heap': True},
                  {'name': 'DDR_LOW1', 'base': 0x800000000, 'size': 0x180000000, 'mc': 'il'}],
        'shim_ch_gbps': 3.9,
    },
}

# Measured design constants. cyc_chunk: core cycles per 64x64x128 chunk in a live run, input
# waits included (4x4: 1.446 ms / 1260 chunks at 1.25 GHz; 2x8: KBENCH live 1262); launch_ms:
# fixed per-launch cost (2x8 is persistent: no ELF reload / core reset).
DESIGNS = {
    '4x4': {'cyc_chunk': 1375, 'launch_ms': 0.06},
    '2x8': {'cyc_chunk': 1262, 'launch_ms': 0.018},
}
MEMTILE = 512 * 1024


def shapes(design, m, n, k):
    """Feasible per-launch tilings (a launch may cover part of M; the plan repeats it)."""
    out = []
    # K is never split: the kernels emit the int8 low byte of each int32 sum, so partial
    # results of a split K could not be added afterwards
    for kk in [k] if k % 256 == 0 else []:
        nk = kk // 128
        if design == '4x4':
            for nt in range(1, 7):
                if nt * 64 * kk > 480 * 1024 or 3 * 64 * kk > MEMTILE:  # B per column, 3 A buffers
                    continue
                for r in range(3, 64 // nt + 1, 3):
                    out.append({'R': r, 'NT': nt, 'K': kk, 'M': 4 * 64 * r, 'N': 4 * 64 * nt, 'nk': nk})
        else:
            if nk % 2:
                continue
            for nt2 in range(1, 5):
                if 2 * nt2 * 64 * kk > MEMTILE - 8192 or 3 * (nk // 2) * 8192 > MEMTILE:
                    continue
                for r2 in range(3, 64 // nt2 + 1, 3):
                    out.append({'R': r2, 'NT': nt2, 'K': kk, 'M': 2 * 64 * r2, 'N': 8 * 64 * nt2, 'nk': nk})
    return [s for s in out if s['M'] <= m and s['N'] <= n and n % s['N'] == 0 and m % s['M'] == 0]


def predict(board, design, s, weights_fixed):
    """ms per launch and the binding term, for one launch of tiling s."""
    b, d = BOARDS[board] if isinstance(board, str) else board, DESIGNS[design]
    f = b['aie_mhz'] * 1e6
    macs = s['M'] * s['N'] * s['K']
    tiles = (s['M'] * s['N']) // (64 * 64) // 16
    t_core = tiles * s['nk'] * d['cyc_chunk'] / f
    terms = {'core': t_core}
    reads = s['M'] * s['K'] + (0 if weights_fixed else s['N'] * s['K'])
    terms['ddr'] = reads / (b['ddr_rd_gbps'] * 1e9) + s['M'] * s['N'] / (b['ddr_wr_gbps'] * 1e9)
    terms['shim-A'] = s['M'] * s['K'] / (4 * b['shim_ch_gbps'] * 1e9)
    # B reloaded every launch: the cores wait for their column's B before the first MAC
    prefill = 0.0 if weights_fixed else s['N'] * s['K'] / 4 / (2 * b['shim_ch_gbps'] * 1e9)
    bind = max(terms, key=lambda t: terms[t])
    ms = (terms[bind] + prefill) * 1e3 + d['launch_ms']
    peak_ms = macs / (16 * 512 * f) * 1e3
    return ms, bind, 100.0 * peak_ms / ms


def zone_plan(board):
    """A / B / C placement: separate MCs when the board has them as separate zones."""
    b = BOARDS[board] if isinstance(board, str) else board
    sep = {}
    for z in b['zones']:
        if z['mc'] != 'il' and z['mc'] not in sep:
            sep[z['mc']] = z
    if len(sep) < 2:
        why = 'one controller' if b['mcs'] == 1 else 'controllers interleaved behind one address range'
        return None, 'no placement: %s -- every buffer on the heap (DDR_LOW0)' % why
    zs = list(sep.values())
    assign = {'A': zs[0], 'C': zs[1], 'B': zs[2] if len(zs) > 2 else zs[0]}
    spec = ','.join('%s=0x%x:0x%x' % (k, v['base'], v['size']) for k, v in assign.items() if not v.get('heap'))
    return spec, 'A on %s, C on %s, B on %s (reads and writes on different controllers)' % (
        assign['A']['name'], assign['C']['name'], assign['B']['name'])


def commands(design, s, weights_fixed, zones):
    ex = 'example/tileprogram/ccode/gemm_memtile'
    if design == '4x4':
        blen, alen = s['NT'] * 64 * s['K'], 64 * s['K']
        lines = ['# gemm_kacc_v2.cc with KA_R %d, KA_NT %d, KA_K %d' % (s['R'], s['NT'], s['K']),
                 'AIEHLC_KB_CHECK_WARN=1 source script/aiehlc.sh --aie-version 5 --runtime-source-file $PWD/gemm_kacc_v2.cc',
                 'python3 %s/memtile_ab.py aout/worklocal %d %d %d %d %d x' % (ex, blen, s['R'], alen, s['NT'], s['R']),
                 'python3 %s/memtile_split.py aout/worklocal %d %d %d %d %d' % (ex, blen, s['R'], alen, s['NT'], s['R']),
                 'python3 %s/shim_bd_once.py aout/worklocal' % ex]
        if weights_fixed:
            lines.append('python3 %s/b_resident.py aout/worklocal' % ex)
    else:
        flags = '--r2 %d --nt2 %d --k %d --single --persist --tile' % (s['R'], s['NT'], s['K'])
        if weights_fixed:
            flags += ' --bres'
        if zones:
            flags += ' --zones ' + zones
        lines = ['# base: gemm_kacc_v2.cc with KA_R 21, KA_NT 2 (+ memtile_ab / memtile_split / shim_bd_once)',
                 'python3 %s/share2x8.py aout/worklocal %s' % (ex, flags)]
    lines.append('rm -f aout/worklocal/build/{host.o,routing.o,host}; WORKLOCAL_DIR=$PWD/aout/worklocal '
                 'AIE_VERSION=5 PLATFORM=baremetal bash script/hostcompile.sh')
    return lines


def plan(board, m, n, k, weights_fixed, top=3):
    rows = []
    for design in DESIGNS:
        for s in shapes(design, m, n, k):
            ms, bind, pct = predict(board, design, s, weights_fixed)
            rows.append((pct, design, s, ms, bind))
    rows.sort(key=lambda r: -r[0])
    return rows[:top]


# measured end-to-end % of the board's true peak (steady state), for --check
MEASURED = [
    ('palmyra', '4x4', {'R': 21, 'NT': 3, 'K': 2560}, True, 64.7),
    ('palmyra', '4x4', {'R': 21, 'NT': 3, 'K': 2560}, False, 58.4),
    ('palmyra', '2x8', {'R': 30, 'NT': 2, 'K': 1792}, True, 55.1),
    ('palmyra', '2x8', {'R': 42, 'NT': 1, 'K': 2560}, True, 52.2),
    ('vek385', '4x4', {'R': 21, 'NT': 3, 'K': 2560}, True, 71.5),
    ('vek385', '4x4', {'R': 21, 'NT': 3, 'K': 2560}, False, 67.9),
    ('vek385', '2x8', {'R': 42, 'NT': 1, 'K': 2560}, True, 77.4),
    ('vek385', '2x8', {'R': 30, 'NT': 2, 'K': 1792}, True, 76.5),
]


def check():
    worst = 0.0
    for board, design, s0, wf, meas in MEASURED:
        s = dict(s0)
        s['nk'] = s['K'] // 128
        s['M'] = (4 if design == '4x4' else 2) * 64 * s['R']
        s['N'] = (4 if design == '4x4' else 8) * 64 * s['NT']
        _, bind, pct = predict(board, design, s, wf)
        worst = max(worst, abs(pct - meas))
        print('%-8s %s R%-3d NT%d K%-5d %s: model %5.1f %% (%s-bound), measured %5.1f %%' % (
            board, design, s['R'], s['NT'], s['K'], 'weights fixed' if wf else 'A+B per launch', pct, bind, meas))
    print('worst model error %.1f points' % worst)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--board', default='vek385', help='palmyra | vek385 | a profile .json (BOARDS format)')
    ap.add_argument('--m', type=int, default=10752)
    ap.add_argument('--n', type=int, default=1536)
    ap.add_argument('--k', type=int, default=2560)
    ap.add_argument('--weights-fixed', action='store_true', help='B is the same on every launch (weight-resident)')
    ap.add_argument('--check', action='store_true', help='compare the model with the measured runs')
    a = ap.parse_args()
    if a.check:
        check()
        return
    board = a.board
    if board.endswith('.json'):
        board = json.load(open(board))
    rows = plan(board, a.m, a.n, a.k, a.weights_fixed)
    if not rows:
        raise SystemExit('no feasible tiling for %dx%dx%d' % (a.m, a.n, a.k))
    b = BOARDS[board] if isinstance(board, str) else board
    spec, why = zone_plan(board)
    print('board %s: %d MC, %s, AIE %d MHz' % (a.board, b['mcs'], ', '.join(z['name'] for z in b['zones']), b['aie_mhz']))
    print('memory placement: %s' % why)
    spec = spec or ''
    for pct, design, s, ms, bind in rows:
        launches = (a.m // s['M']) * (a.n // s['N']) * (a.k // s['K'])
        print('  %s  R %d NT %d K %d (%dx%dx%d per launch, %d launches): %.3f ms/launch, %.1f %% of peak (%s-bound)' % (
            design, s['R'], s['NT'], s['K'], s['M'], s['N'], s['K'], launches, ms, pct, bind))
    pct, design, s, ms, bind = rows[0]
    print('\nchosen: %s' % design)
    for line in commands(design, s, a.weights_fixed, spec):
        print('  ' + line)


if __name__ == '__main__':
    main()
