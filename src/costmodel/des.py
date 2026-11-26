###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""Discrete-event model of ONE gemm_kacc launch on the 4x4 AIE mesh (AIE side, segment K of the cost layer).

Predicted quantity: the host time spent in ``__Runtime_wait_io`` per launch (``rt_wait_io`` of
``LAUNCH split_detail``, src/aiegraph/runtime/main_launch_line.c:49) = the AIE-side time the host's own BD issue
does not hide.  Host glue / launch overhead are NOT predicted here (segment L); the measured host BD-issue cost
per BD enters only as the unit of the issue/AIE overlap (``op['host']['bd_us']``, see host_from_split).

Launch structure (generated host.cc of every kacc instance, aiehlc DF schedule):
  * R = ntile rounds; per round the host issues 24 BDs (4 b-port BDs, one per mesh column and broadcast to its 4
    cores; then per mesh row 1 a-port BD + 4 c-port BDs), then waits on all 12 io events of the round.
  * per round and core: nkc K-chunks; chunk j = a rows 16 x kch bf16 + b rows 16*S x kch bf16 in 2-deep
    (ping-pong) windows, compute, release; one fp32 c-window commit (16 x 16*S x 4 B) after the last chunk.
  * broadcast + 2-deep windows => the 16 cores advance in lock step; one shim column per mesh column.

Event model per round (cycles at aie_clk_mhz): chunk j arrives at max(arrival j-1, release of chunk j-2) +
dma_chunk, starts at max(arrival, end of chunk j-1), takes 2 lock acquires + exposed compute; the round ends with
the c commit drain.  The host waits max(0, round - overlap) where overlap = overlap_bd host BD slots of the
round's own issue that the AIE work hides.

Terms:
  compute   core_cyc (ISS, one core, one launch: K1b) + chunk_ovh_cyc * R*nkc + round_ovh_cyc * R
            (window acquire/release + loop/commit overhead the ISS harness does not see; chunks/rounds as in
            board_compute.json: chunks = NT*NKC, rounds = NT output windows)
  dma_chunk max(tile stream (a+b)/nkc / dma_b_per_cyc, DDR round time / nkc) + bd_switch_cyc,
            + dma_first_byte_cyc for the first chunk.  DDR round time:
            * per burst (params carry ddr_burst_cyc0 + ddr_burst_b_per_cyc, run_microbench.sh --section ddr):
              bursts = mesh-unique bytes / run spread over 4 shim columns, each burst ddr_burst_cyc0 + run /
              ddr_burst_b_per_cyc AIE cycles (strided-burst microbenchmark), times ddr_bw_scale (calibrated:
              achieved / independent-column burst time of the concurrent 4-column kacc traffic); no long-run cap.
            * else bytes-only: bytes / ddr_eff, ddr_eff = ddr_bw_scale * ddr_rd_gbps/clk * run/(run+ddr_run0_b).
            run = kch*2 B = contiguous run of the multidim shim BD (d0_wrap = tkw words)
  lock      lock_acq_cyc per window acquire (2 per chunk + 1 per commit)
  stall     core idle inside the round (waiting for data) -- the board's lock_stall + stream_stall also counts the
            idle time while the host is still issuing (reported, not fitted)
  wait      WAIT WINDOW: the host enters __Runtime_wait_io only after its last BD of the round, while the b-port
            stream (BDs issued first) and the cores already run.  Only the DES timeline after the wait start is
            predicted: per round max(0, round + round_fixed_cyc - overlap - b_overlap_cyc * b/(a+b)), b/(a+b) = the
            b-port share of the round's bytes (S/(S+1)); sum over rounds.
Calibrated keys (src/costmodel/tools/costmodel_fit.py, defaults = uncalibrated physics): CAL_DEFAULTS.  The palmyra213
calibration (K2c) uses 6: chunk_ovh_cyc (compute), ddr_bw_scale + ddr_run0_b (bytes-only DDR, ddr_model="bytes"),
b_prefetch_b, round_fixed_cyc and compute_exposed.  compute_exposed calibrates to ~0: inside the host's wait window
the round is DDR-tail-limited; the board PERFIO split (R=1 yolo launches) shows >=88 % of the core compute runs
before the host enters __Runtime_wait_io, i.e. hidden behind the host BD issue.
"""
from __future__ import annotations

from typing import Any, Dict, Optional

CAL_DEFAULTS = {
    "chunk_ovh_cyc": 0.0,    # core cycles per K-chunk not in the ISS count
    "round_ovh_cyc": 0.0,    # core cycles per round (/S) not in the ISS count
    "compute_exposed": 1.0,  # fraction of the core compute on the round's critical path
    "ddr_bw_scale": 1.0,     # achieved / microbenchmark DDR read bandwidth for long runs
    "ddr_run0_b": 0.0,       # per-run DDR overhead in byte-equivalents
    "overlap_bd": 0.0,       # host BD slots of a round's issue that hide its AIE work
    "b_prefetch_b": 0.0,     # mesh bytes of the b-port stream that run ahead of the cores while the host is
                             # still issuing the round (b BDs go first; shim/stream FIFO + window slack)
    "round_fixed_cyc": 0.0,  # fixed per-round latency (DMA start / event round trip)
    "wait_call_cyc": 0.0,    # host cost per __Runtime_wait_io call (structural count per round)
    "b_overlap_cyc": 0.0,    # wait-window start offset: AIE cycles of the round that run before the host's wait
                             # starts, per unit b-port byte share (b streams while the host still issues a/c BDs)
}
BDS_PER_ROUND = 24  # 4 b + 4 * (1 a + 4 c)


def _p(params: Dict[str, Any], key: str) -> float:
    return float(params[key]) if key in params else float(CAL_DEFAULTS[key])


def geometry(op: Dict[str, Any]) -> Dict[str, Any]:
    """Per-round / per-chunk byte counts of a kacc instance (op['instance'] as in aie2ps_kernel_cycles.json)."""
    i = op["instance"]
    R, S, k, nkc, kch = int(i["ntile"]), int(i["S"]), int(i["k"]), int(i["nkc"]), int(i["kch"])
    a_b = 16 * k * 2            # a-port bytes per core per round
    b_b = S * 16 * k * 2        # b-port bytes per core per round
    c_b = 16 * S * 16 * 4       # c-port (fp32) bytes per core per round
    return {"R": R, "S": S, "k": k, "nkc": nkc, "kch": kch, "a_b": a_b, "b_b": b_b, "c_b": c_b,
            "chunks": R * nkc, "run_b": kch * 2,
            "ddr_rd_round_b": 4 * (a_b + b_b), "ddr_wr_round_b": 16 * c_b}


def compute_cycles(op: Dict[str, Any], params: Dict[str, Any], cycles: Dict[str, Any]) -> float:
    """DES compute term (core busy, no stalls) per launch, AIE cycles, slowest core.  Compared on the board with
    max-tile active_cyc - lock_stall - stream_stall."""
    g = geometry(op)
    return float(cycles["core_cyc"]) + _p(params, "chunk_ovh_cyc") * g["chunks"] + \
        _p(params, "round_ovh_cyc") * g["R"]


def ddr_eff_bpc(op: Dict[str, Any], params: Dict[str, Any]) -> float:
    """Achieved DDR read bytes per AIE cycle for this instance's shim BD run length."""
    g = geometry(op)
    bpc = float(params["ddr_rd_gbps"]) * 1e3 / float(params["aie_clk_mhz"])  # GB/s -> B per AIE cycle
    run = g["run_b"]
    return _p(params, "ddr_bw_scale") * bpc * run / (run + _p(params, "ddr_run0_b"))


def burst_model(params: Dict[str, Any]) -> bool:
    """Per-burst DDR model only if the params carry the burst microbenchmark and the calibration does not select the
    bytes-only model (cal key ddr_model="bytes": the single-column strided-burst time does not transfer to the
    concurrent 4-column kacc traffic on palmyra213, K2c: maxrel 0.309 per-burst vs 0.190 bytes-only)."""
    return params.get("ddr_model", "burst") != "bytes" and "ddr_burst_cyc0" in params and \
        "ddr_burst_b_per_cyc" in params


def ddr_burst_cyc(op: Dict[str, Any], params: Dict[str, Any]) -> float:
    """AIE cycles of one shim burst of this instance's run length (strided-burst microbenchmark, one column)."""
    run = geometry(op)["run_b"]
    return float(params["ddr_burst_cyc0"]) + run / float(params["ddr_burst_b_per_cyc"])


def ddr_read_cyc(op: Dict[str, Any], params: Dict[str, Any], nbytes: float) -> float:
    """AIE cycles to read nbytes mesh-unique DDR bytes of this instance (per burst if the params carry the burst
    microbenchmark, else bytes-only)."""
    if burst_model(params):
        run = geometry(op)["run_b"]
        return nbytes / run / 4.0 * ddr_burst_cyc(op, params) * _p(params, "ddr_bw_scale")
    return nbytes / ddr_eff_bpc(op, params)


def predict_launch(op: Dict[str, Any], params: Dict[str, Any], cycles: Dict[str, Any]) -> Dict[str, Any]:
    """Simulate one launch.  op = {'instance': {...}, 'host': {'bd_us': ...}}; params = palmyra213.json (+ cal);
    cycles = {'core_cyc': ...}.  Returns ms per launch:
    dict(compute_ms, dma_ms, lock_ms, stall_ms, wait_ms, bound, aie_ms, ddr_ms, rounds)."""
    g = geometry(op)
    clk_mhz = float(params["aie_clk_mhz"])
    host = op.get("host") or {}
    bd_cyc = float(host.get("bd_us", params.get("host_bd_us", 5.0))) * clk_mhz
    R, nkc = g["R"], g["nkc"]

    comp_total = compute_cycles(op, params, cycles)
    lock_acq = float(params["lock_acq_cyc"])
    comp_chunk = max(0.0, comp_total / (R * nkc) - 2 * lock_acq) * _p(params, "compute_exposed")

    dma_bpc = float(params["dma_b_per_cyc"])
    first = float(params["dma_first_byte_cyc"])
    ddr_eff = ddr_eff_bpc(op, params)
    ddr_wr_bpc = float(params["ddr_wr_gbps"]) * 1e3 / clk_mhz
    # b-port BDs are issued first (slots 0-3): while the host issues the other 20 BDs of the round, up to
    # b_prefetch_b bytes of b stream ahead; the rest (all of a + the remaining b) is paced by the 2-deep windows
    b_round = 4 * g["b_b"]
    pre = min(b_round, _p(params, "b_prefetch_b"), ddr_eff * (BDS_PER_ROUND - 4) * bd_cyc)
    rest_b = g["ddr_rd_round_b"] - pre
    tile_chunk = (g["a_b"] + g["b_b"]) / nkc / dma_bpc
    ddr_chunk = ddr_read_cyc(op, params, rest_b) / nkc
    dma_chunk = max(tile_chunk, ddr_chunk) + float(params["bd_switch_cyc"])
    # c commit: the core hands its fp32 window to the tile S2MM->shim path; the DDR write of the 16 windows overlaps
    # the next round's issue (output events are waited, but the write queue drains at ddr_wr while the host issues)
    c_drain = g["c_b"] / dma_bpc + first + lock_acq
    overlap = _p(params, "overlap_bd") * bd_cyc + \
        _p(params, "b_overlap_cyc") * g["b_b"] / (g["a_b"] + g["b_b"])
    wpr = float(host.get("waits_per_launch", 12 * R)) / R
    fixed = _p(params, "round_fixed_cyc") + _p(params, "wait_call_cyc") * wpr

    # one round after the host's last BD of the round (all rounds identical: the host serialises them by
    # waiting on the round's events); chunk j arrives when the window of chunk j-2 is released
    done = [0.0, 0.0]
    arr = first
    t_done = 0.0
    idle = 0.0
    dma_limited = 0
    for _j in range(nkc):
        arr = max(arr, done[-2]) + dma_chunk
        start = max(arr, t_done)
        if arr > t_done:
            dma_limited += 1
            idle += arr - t_done
        t_done = start + 2 * lock_acq + comp_chunk
        done.append(t_done)
    t_round = t_done + c_drain
    wait_round = max(0.0, t_round + fixed - overlap)

    to_ms = 1.0 / (clk_mhz * 1e3)
    return {
        "compute_ms": comp_total * to_ms,
        "dma_ms": R * (nkc * dma_chunk + first) * to_ms,
        "lock_ms": R * (2 * nkc + 1) * lock_acq * to_ms,
        "stall_ms": R * (idle + c_drain) * to_ms,
        "wait_ms": R * wait_round * to_ms,
        "aie_ms": R * t_round * to_ms,
        "ddr_ms": R * ddr_read_cyc(op, params, g["ddr_rd_round_b"]) * to_ms,
        "rounds": R,
        "bound": "ddr" if dma_limited * 2 > nkc else "compute",
    }


def host_from_split(split_detail: Dict[str, Any], rounds: int | None = None) -> Dict[str, Any]:
    """Host BD-issue cost of a measured launch (an INPUT of the DES; segment L later predicts it):
    host time per BD config = (rt_bdcfg + rt_startio + host_glue_bdcfg) / BD configs per launch.
    rt_wait_io (the predicted quantity) is never read here."""
    o = split_detail["other"]
    L = float(o.get("launches") or split_detail["calls"].get("coreen") or 1)
    bd_per_launch = split_detail["calls"]["bdcfg"] / L
    rt, hs = split_detail["rt"], split_detail["host"]
    host_ms = rt.get("bdcfg", 0.0) + rt.get("startio", 0.0) + hs.get("glue_bdcfg", 0.0)
    d = {"bd_us": host_ms * 1e3 / bd_per_launch, "bd_per_launch": bd_per_launch, "issue_ms": host_ms}
    if rounds is not None:
        d["bds_pre"] = max(0, int(round(bd_per_launch - BDS_PER_ROUND * rounds)))
    return d


# =====================================================================================================================
# gemm90 int8 4096^3 B-buffer DES (phase PM, sprint-1126092352): ``python3 -m costmodel.des --gemm90-price``.
# One launch = 8 slices x 32 tiles x 32 K-chunks per core (8192 chunks at KC=128).  Per mesh column the MemTile MM2S
# broadcasts B chunk j to the column's 4 cores (COLUMN COUPLING): it may send chunk j only when EVERY core of the
# column has released chunk j - depth (DEPTH: the core B slot ring, ppDepth 2 on the board), and the stream needs
# t_b = chunk bytes / stream_b_per_cyc.  At each slice start B is reloaded (breload / slices after the column's last
# core finished the slice).  Core i's work per chunk (everything but the B lock wait) is W_i + sigma*(E - 1),
# E ~ Exp(1) (deterministic seeds): W_i from the PB base_ml per-tile counters, sigma = per-core jitter, the ONE
# parameter fitted (bisection) so that depth 2 reproduces pb.txt:12 base_b_us(4,3).  Out of sample: the predicted
# lock_stall of the other 15 tiles vs base_ml.  KC=64 variants: twice the chunks, W, sigma and t_b halved (linear,
# ASSUMED).  Wall = max over the 16 tiles; des gain = wall(base) - wall(variant) with the base kernel's static work.
# =====================================================================================================================
import json as _json
import math as _math
import os as _os
import random as _random

_PM_JSON = _os.path.join(_os.path.dirname(_os.path.abspath(__file__)), "params", "gemm90_pm.json")
_LEV_JSON = _os.path.join(_os.path.dirname(_os.path.abspath(__file__)), "params", "levers_gemm90.json")
_TILES = [(c, r) for r in (3, 4, 5, 6) for c in (1, 2, 3, 4)]


def _f1(x: float) -> str:
    return f"{round(x + 0.0, 1):.1f}"


def g90_load() -> Dict[str, Any]:
    with open(_PM_JSON) as fh:
        P = _json.load(fh)
    with open(_LEV_JSON) as fh:
        P["levers"] = _json.load(fh)
    return P


def g90_work(P: Dict[str, Any]) -> Dict[tuple, float]:
    """W_i (cycles per KC=128 chunk, without the B lock wait) = (active - lock)/N + non-B lock share."""
    N = P["chunks_per_launch"]
    nonb = P["nonb_lock_us_4_3"] * P["clk_mhz"] / N
    W = {}
    for k, d in P["ml_tiles"].items():
        c, r = (int(x) for x in k.split(","))
        W[(c, r)] = (d["active"] - d["lock"]) / N + nonb
    return W


_E_CACHE: Dict[tuple, list] = {}


def _unit_exp(tile: tuple, n: int) -> list:
    key = (tile, n)
    if key not in _E_CACHE:
        rng = _random.Random(9001 + 10 * tile[0] + tile[1])
        _E_CACHE[key] = [-_math.log(1.0 - rng.random()) - 1.0 for _ in range(n)]
    return _E_CACHE[key]


def g90_sim(P: Dict[str, Any], W: Dict[tuple, float], sigma: float, depth: int, gran: int,
            a_depth: Optional[int] = None, t_a: float = 0.0) -> Dict[str, Any]:
    """gran = K sub-chunks per KC=128 chunk (1: KC=128, 2: KC=64).  Returns per-tile B wait / end (cycles).

    depth = B slot ring depth.  a_depth (phase PQ): A slot ring depth per core; None = A not modelled (the A wait
    stays inside W, phase PM behaviour, byte-identical).  With a_depth, A is a per-core stream (one MemTile MM2S per
    core, no broadcast): A chunk j arrives at max(arrival j-1, release of chunk j - a_depth) + t_a, and the core
    acquires A before B (lock order a2/b2 ACQ, pb.txt:6), so a chunk starts at max(end j-1, A arrival, B arrival);
    the A part of that wait is returned in 'await'."""
    N = P["chunks_per_launch"] * gran
    per_slice = N // P["slices"]
    t_b = P["b_chunk_bytes"] / gran / P["stream_b_per_cyc"]
    reload = P["breload_us"] * P["clk_mhz"] / P["slices"]
    bwait, end, await_ = {}, {}, {}
    for c in (1, 2, 3, 4):
        col = [(c, r) for r in (3, 4, 5, 6)]
        w = [W[t] / gran for t in col]
        s = sigma / gran
        E = [_unit_exp(t, N) for t in col]
        fin = [[0.0] * N for _ in col]
        t_end = [0.0] * 4
        bw = [0.0] * 4
        aw = [0.0] * 4
        a_arr = [0.0] * 4
        ta_g = t_a / gran
        arr = 0.0
        slice_ready = 0.0
        for j in range(N):
            if j % per_slice == 0:
                if j:
                    slice_ready = max(t_end) + reload
                a = max(arr + t_b, slice_ready)
            else:
                a = arr + t_b
            if j >= depth:
                a = max(a, max(f[j - depth] for f in fin) + t_b)
            arr = a
            for i in range(4):
                st = t_end[i]
                if a_depth is not None:
                    xa = a_arr[i] + ta_g
                    if j >= a_depth:
                        xa = max(xa, fin[i][j - a_depth] + ta_g)
                    a_arr[i] = xa
                    if xa > st:
                        aw[i] += xa - st
                        st = xa
                if a > st:
                    bw[i] += a - st
                    st = a
                e = st + w[i] + s * E[i][j]
                t_end[i] = e
                fin[i][j] = e
        for i, t in enumerate(col):
            bwait[t], end[t] = bw[i], t_end[i]
            await_[t] = aw[i]
    return {"bwait": bwait, "await": await_, "end": end, "wall": max(end.values())}


def g90_fit_sigma(P: Dict[str, Any], W: Dict[tuple, float]) -> tuple:
    meas = P["pb"]["base_b_us_4_3"] * P["clk_mhz"]
    lo, hi = 0.0, 0.5 * min(W.values())
    for _ in range(30):
        mid = 0.5 * (lo + hi)
        if g90_sim(P, W, mid, 2, 1)["bwait"][(4, 3)] < meas:
            lo = mid
        else:
            hi = mid
    return 0.5 * (lo + hi)


def g90_price(P: Dict[str, Any]) -> list:
    out = []
    clk, N = P["clk_mhz"], P["chunks_per_launch"]
    W = g90_work(P)
    sigma = g90_fit_sigma(P, W)
    base = g90_sim(P, W, sigma, 2, 1)
    b43 = base["bwait"][(4, 3)] / clk
    bmeas = P["pb"]["base_b_us_4_3"]
    b_err = abs(b43 - bmeas) / bmeas
    # out of sample: lock_stall of the 15 other tiles (B wait + the assumed non-B share) vs base_ml
    nonb = P["nonb_lock_us_4_3"] * clk
    errs = []
    for k, d in P["ml_tiles"].items():
        t = tuple(int(x) for x in k.split(","))
        if t != (4, 3):
            errs.append(abs(base["bwait"][t] + nonb - d["lock"]) / d["lock"])
    tile_mare = sum(errs) / len(errs)
    calib_err = max(b_err, tile_mare, P["pb"]["ml_spread_pct"] / 100.0)
    # lock-place calibration (attrib_pred, PK): end-to-end us per us of B lock wait moved off (4,3)
    lm = P["levers"]["classes"]["lock_move"]
    lp_pred = lm["disc"] * lm["dx_us"]
    ca = P["levers"]["classes"]["core_active"]
    ratio = round(ca["disc"], 1)
    out.append(f"CALIB src=pb lockplace_pred_us={_f1(lp_pred)} lockplace_meas_us={_f1(P['pb']['d_median_us'])} "
               f"core_active_ratio={_f1(ratio)} lock_move_disc={lm['disc']:.6f} dx_us={_f1(lm['dx_us'])} "
               f"n_samples={lm['n_samples']} pred_src=tools/attrib_pred.py")
    out.append(f"DES b_us(4,3)={_f1(b43)} b_meas_us={_f1(bmeas)} depth=2 col_coupling=1 sigma_cyc={_f1(sigma)} "
               f"t_b_cyc={_f1(P['b_chunk_bytes'] / P['stream_b_per_cyc'])} breload_us={_f1(P['breload_us'])} "
               f"b_err_pct={_f1(100 * b_err)} tile_lock_mare_pct={_f1(100 * tile_mare)} "
               f"calib_err_pct={_f1(100 * calib_err)} base_wall_us={_f1(base['wall'] / clk)}")
    gap = round(P["pb"]["base_median_us"] - P["gap"]["target85_int8_us"], 1)
    bs = P["base"]
    inner = (bs["chunk_cyc"] - bs["bnd_bundles"]) / bs["loop_bundles"]
    rows = []
    lo_band = P["compute_lo_band"]
    for v in P["variants"]:
        g = 128 // v["kc"]
        fits = int(v["link"] == "ok" and v["dm_used"] is not None and v["dm_used"] <= P["dm_cap"])
        bd = int(v["bd_ok"])
        if v["bnd_bundles"] is not None:
            d_bnd = g * v["bnd_bundles"] - bs["bnd_bundles"]
            d_loop = (g * v["loop_bundles"] - bs["loop_bundles"]) * inner
        else:
            d_bnd, d_loop = 0, 0.0  # not linked: priced with the base kernel's static schedule
        bnd_us = (d_bnd + d_loop) * N / clk       # extra boundary + loop cycles per launch (cost if > 0)
        csplit_us = 0.0                           # no linked variant uses GP_C_SPLIT=2 (pd.txt GAP rows)
        dm = v["dm_used"] if v["dm_used"] is not None else "-"
        if v["kind"] == "buffer":
            sim = g90_sim(P, W, sigma, v["depth"], g)
            gain = (base["wall"] - sim["wall"]) / clk
            pred = gain - bnd_us - csplit_us
            lo, hi = pred - abs(pred) * calib_err, pred + abs(pred) * calib_err
            st, ra = "-", "-"
            lim = "fit" if not fits else ("boundary" if bnd_us > max(gain, 0.0) else "des_gain")
            extra = f"des_gain_us={_f1(gain)} d_bnd_bundles={d_bnd} d_loop_cyc={_f1(d_loop)} csplit_us={_f1(csplit_us)}"
        else:
            static_cyc = -(d_bnd + d_loop)
            static_us = static_cyc * N / clk
            # a saving is scaled by the measured core_active ratio; a loss is charged 1:1 (never amplified)
            pred = static_us * ratio if static_us > 0 else static_us
            lo, hi = (pred * (1 - lo_band), pred) if pred > 0 else (pred - abs(pred) * lo_band, pred)
            st, ra = _f1(static_us), _f1(ratio)
            lim = "core_active_n1" if static_us > 0 else "boundary"
            extra = f"static_cyc_per_chunk={_f1(static_cyc)} d_bnd_bundles={d_bnd} d_loop_cyc={_f1(d_loop)}"
        el = int(fits and bd)
        rows.append(dict(v=v["v"], kind=v["kind"], el=el, pred=pred, lo=lo))
        out.append(f"LEVER v={v['v']} kind={v['kind']} dm_used={dm} fits={fits} bd_ok={bd} static_us={st} ratio={ra} "
                   f"pred_us={_f1(pred)} pred_lo_us={_f1(lo)} pred_hi_us={_f1(hi)} boundary_us={_f1(bnd_us)} "
                   f"limit={lim} {extra}")
    el = [r for r in rows if r["el"]]
    best = max(el, key=lambda r: (r["lo"], r["v"])) if el else None
    go = bool(best and round(best["lo"], 1) >= gap)
    out.append(f"LEVERTAB2 head={P['data_head']} vars_priced={len(el)} "
               f"buffer_priced={sum(1 for r in el if r['kind'] == 'buffer')} "
               f"compute_priced={sum(1 for r in el if r['kind'] == 'compute')} core_active_ratio={_f1(ratio)} "
               f"des_b_err_pct={_f1(100 * b_err)} des_tol_pct=10.0 lockplace_pred_us={_f1(lp_pred)} "
               f"verdict={'go' if go else 'lower_bound'} pick={best['v'] if best else 'none'} "
               f"pick_kind={best['kind'] if best else 'none'} pred_us={_f1(best['pred'] if best else 0.0)} "
               f"pred_lo_us={_f1(best['lo'] if best else 0.0)} "
               f"lb_file={'-' if go else 'm33621242222122211/LOWER_BOUND.md'} gap_us={_f1(gap)}")
    return out


# ---------------------------------------------------------------------------------------------------------------------
# Per-stream depths (phase PQ, sprint-1126121655): ``python3 -m costmodel.des --gemm90-price-ab A B``.
# Generic g90_sim(a_depth=..., t_a=...) models the A ring next to the B ring.  W_i no longer carries the A wait:
# W_i = (active - lock)/N + (nonb_lock_us_4_3 - base_a_us_4_3) per chunk (the rest, ASSUMED equal on every tile).
# TWO fitted parameters, jointly (alternating bisection) on the PB base at A depth 2 / B depth 2:
#   sigma (per-core jitter) -> base_b_us(4,3)=782.1 ; t_a (A per-chunk delivery, cycles) -> base_a_us(4,3)=152.0.
# base_a_us 152.0 is a MEASURED calibration target at A depth 2 only; it is never used as the cost of another
# A depth (the A wait at depth 1 is simulated: chunk j's A transfer cannot start before chunk j-1 is released).
# gain_us = DES wall(A2,B2) - DES wall(A,B) (positive = faster than base 10225.8 us, pb.txt:11).
# ---------------------------------------------------------------------------------------------------------------------
def g90_work_ab(P: Dict[str, Any]) -> Dict[tuple, float]:
    N = P["chunks_per_launch"]
    rest = (P["nonb_lock_us_4_3"] - P["pb"]["base_a_us_4_3"]) * P["clk_mhz"] / N
    return {tuple(int(x) for x in k.split(",")): (d["active"] - d["lock"]) / N + rest
            for k, d in P["ml_tiles"].items()}


def _bisect(f, lo: float, hi: float, target: float, n: int = 30) -> float:
    for _ in range(n):
        mid = 0.5 * (lo + hi)
        if f(mid) < target:
            lo = mid
        else:
            hi = mid
    return 0.5 * (lo + hi)


def g90_fit_ab(P: Dict[str, Any], W: Dict[tuple, float], rounds: int = 6) -> tuple:
    clk = P["clk_mhz"]
    bmeas = P["pb"]["base_b_us_4_3"] * clk
    ameas = P["pb"]["base_a_us_4_3"] * clk
    t_b = P["b_chunk_bytes"] / P["stream_b_per_cyc"]
    sigma, t_a = 0.0, t_b
    for _ in range(rounds):
        sigma = _bisect(lambda s: g90_sim(P, W, s, 2, 1, 2, t_a)["bwait"][(4, 3)], 0.0, 0.5 * min(W.values()), bmeas)
        t_a = _bisect(lambda x: g90_sim(P, W, sigma, 2, 1, 2, x)["await"][(4, 3)], 0.0, 2.0 * max(W.values()), ameas)
    return sigma, t_a


def g90_price_ab(P: Dict[str, Any], pairs: list) -> list:
    clk = P["clk_mhz"]
    W = g90_work_ab(P)
    sigma, t_a = g90_fit_ab(P, W)
    base = g90_sim(P, W, sigma, 2, 1, 2, t_a)
    out = []
    for a, b in pairs:
        r = base if (a, b) == (2, 2) else g90_sim(P, W, sigma, b, 1, a, t_a)
        out.append(f"DESAB a={a} b={b} gain_us={_f1((base['wall'] - r['wall']) / clk)} "
                   f"b_us={_f1(r['bwait'][(4, 3)] / clk)} a_us={_f1(r['await'][(4, 3)] / clk)}")
    return out, dict(sigma=sigma, t_a=t_a, base_wall_us=base["wall"] / clk)


if __name__ == "__main__":
    import sys as _sys
    _a = _sys.argv[1:]
    if _a == ["--gemm90-price"]:
        for _l in g90_price(g90_load()):
            print(_l)
    elif len(_a) == 3 and _a[0] == "--gemm90-price-ab" and _a[1].isdigit() and _a[2].isdigit() \
            and int(_a[1]) >= 1 and int(_a[2]) >= 1:
        print(g90_price_ab(g90_load(), [(int(_a[1]), int(_a[2]))])[0][0])
    elif _a == ["--gemm90-price-ab-fit"]:
        _o, _f = g90_price_ab(g90_load(), [(2, 2), (1, 3), (2, 3), (1, 2)])
        print(f"DESABFIT sigma_cyc={_f1(_f['sigma'])} t_a_cyc={_f1(_f['t_a'])} base_wall_us={_f1(_f['base_wall_us'])}")
        for _l in _o:
            print(_l)
    else:
        _sys.stderr.write("usage: des.py --gemm90-price | --gemm90-price-ab A B | --gemm90-price-ab-fit\n")
        _sys.exit(2)
