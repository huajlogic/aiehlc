#!/usr/bin/env python3
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
"""Turn the LOSS lines of a board log into a per-core loss table (skill coreloss).

The lines come from __Runtime_core_loss_arm / __Runtime_core_loss_read (runtime_coreloss.patch in this
directory), printed by the app around one launch each, e.g. gemm_plan_body.cc with gemm_plan_loss.patch and
--define GP_LOSS=1:

  LOSS launch=3 banks=0,1 window_us=.. launch_us=.. wait_us=.. tile=c,r active=.. memstall=.. lockstall=..
       vec=.. conflA=.. conflB=..

The counters run from arm to read, which is longer than the launch: the extra cycles are a persistent
kernel waiting for its go lock, so they are counted as active AND lock stall. They are subtracted from
both: for a core whose active count exceeds the launch (enabled all the time) the excess is exact; arming
writes every tile over MMIO, so the host window stamp is NOT when a tile's counters started. Every launch time is spent as

  VMAC (vector instructions) + other instructions + memory stall + lock stall + core not active

where "other" = active - vec - memstall - lockstall, and "not active" is the launch time the core did
not run (launch fill / drain at the edges, host launch cost). Usage:

  python3 perftest/gemm90/losstable.py applog_pal [--mhz 1000] [--macs 1228800]
"""
import argparse
import re
import statistics
import sys

LINE = re.compile(r'LOSS launch=(\d+) banks=(\d+),(\d+) window_us=([\d.]+) launch_us=([\d.]+) wait_us=([\d.]+) '
                  r'tile=(\d+),(\d+) active=(\d+) memstall=(\d+) lockstall=(\d+) vec=(\d+) conflA=(\d+) conflB=(\d+)(?=\s|$)', re.M)


def parse(text):
    # a serial console can echo or interleave lines (VEK385 com port): keep the first well-formed line per
    # (launch, tile); a spliced line can still carry a wrong number, hence medians over cores below
    rows, seen = [], set()
    for m in LINE.finditer(text):
        g = m.groups()
        key = (g[0], g[6], g[7])
        if key in seen:
            continue
        seen.add(key)
        rows.append(dict(launch=int(g[0]), banks=(int(g[1]), int(g[2])), window=float(g[3]), launch_us=float(g[4]),
                         wait_us=float(g[5]), tile=(int(g[6]), int(g[7])), active=int(g[8]), mem=int(g[9]),
                         lock=int(g[10]), vec=int(g[11]), confl=(int(g[12]), int(g[13]))))
    return rows


def per_core(r, mhz):
    total = r['launch_us'] * mhz
    # Cycles counted outside the launch. Arming walks every tile over MMIO, so a tile's counters start
    # before the host's window stamp; a core that is enabled the whole time (persistent kernel) counts
    # active every cycle, so its own excess active over the launch is exact. Otherwise use the window.
    idle = r['active'] - total if r['active'] > total else max(0.0, (r['window'] - r['launch_us']) * mhz)
    active = max(0.0, r['active'] - idle)
    lock = max(0.0, r['lock'] - idle)
    other = max(0.0, active - r['vec'] - r['mem'] - lock)
    return dict(total=total, vec=r['vec'], other=other, mem=r['mem'], lock=lock, off=max(0.0, total - active))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('log')
    ap.add_argument('--mhz', type=float, default=0, help='AIE clock; default: the GPLAN aie_mhz line, else 1000')
    ap.add_argument('--macs', type=int, default=0, help='expected MAC instructions per core (checks vec)')
    a = ap.parse_args()
    text = re.sub(r'\x1b\[[0-9;]*[A-Za-z]', '', open(a.log, errors='replace').read())
    mhz = a.mhz
    if not mhz:
        m = re.search(r'aie_mhz=([\d.]+)', text)
        mhz = float(m.group(1)) if m and float(m.group(1)) > 0 else 1000.0
    allrows = parse(text)
    # cores that ran no vector instruction are not the kernel's (other enabled cores of the partition)
    rows = [r for r in allrows if r['vec'] > 0]
    if len(rows) < len(allrows):
        print('ignored %d core sample(s) with vec = 0 (not running this kernel)' % (len(allrows) - len(rows)))
    if not rows:
        sys.exit('no LOSS lines in %s (apply perftest/gemm90/runtime_coreloss.patch + gemm_plan_loss.patch, build with --define GP_LOSS=1)' % a.log)
    launches = sorted({r['launch'] for r in rows})
    print('AIE clock %.1f MHz, %d launch(es), %d cores per launch' % (mhz, len(launches),
                                                                        len([r for r in rows if r['launch'] == launches[0]])))
    keys = ('vec', 'other', 'mem', 'lock', 'off')
    names = {'vec': 'VMAC (vector instructions)', 'other': 'other instructions', 'mem': 'memory stall (bank conflicts)',
             'lock': 'lock stall (waiting for data / buffer)', 'off': 'core not active (fill / drain, host launch)'}
    agg = {k: [] for k in keys}
    totals, crit = [], []
    for L in launches:
        cs = [per_core(r, mhz) for r in rows if r['launch'] == L]
        totals.append(cs[0]['total'])
        for k in keys:
            agg[k].append(statistics.median(c[k] for c in cs))
        crit.append(max(c['vec'] for c in cs))
    T = statistics.mean(totals)
    print('\nper core, median over cores, mean over launches (launch = %.0f cycles):\n' % T)
    print('| item | cycles | share |\n|---|---|---|')
    for k in keys:
        v = statistics.mean(agg[k])
        print('| %s | %.0f | %.1f %% |' % (names[k], v, 100.0 * v / T))
    hl = statistics.mean(r['launch_us'] - r['wait_us'] for r in rows)
    print('\nhost launch cost (launch - wait_io): %.1f us = %.1f %% (part of "not active" / "lock stall")' %
          (hl, 100.0 * hl * mhz / T))
    if a.macs:
        print('vector instructions per core %.0f vs expected MAC instructions %d' % (statistics.mean(agg['vec']), a.macs))
    print('\nDM bank conflicts per core per launch (median over cores):')
    for r0 in sorted({r['banks'] for r in rows}):
        sel = [r for r in rows if r['banks'] == r0]
        print('  bank %d: %8.0f   bank %d: %8.0f' % (r0[0], statistics.median(r['confl'][0] for r in sel), r0[1],
                                                    statistics.median(r['confl'][1] for r in sel)))
    worst = max(rows, key=lambda r: per_core(r, mhz)['mem'] + per_core(r, mhz)['lock'])
    w = per_core(worst, mhz)
    print('\nmost stalled core: tile %s launch %d (memory stall %.1f %%, lock stall %.1f %%)' % (
        worst['tile'], worst['launch'], 100.0 * w['mem'] / w['total'], 100.0 * w['lock'] / w['total']))


if __name__ == '__main__':
    main()
