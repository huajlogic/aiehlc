#!/usr/bin/env python3
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
"""attrib_pred.py -- price levers from measured attribution rows with a formula file.

Generic, stdlib only.  No workload constants live here: every number that is not a
measurement comes from the formula JSON.

Inputs
  --attrib FILE   text with `<TAG> key=value key=value ...` rows (default TAG=ATTRIB).
                  Numeric values become formula variables under their key name
                  (e.g. a_us, b_us, gap_slack_us, gap_slope_after).  When several rows
                  carry the tag, --row selects one (default: the last).
  --formulas JSON {"<param>": <number>, ...,                       scalar parameters (variables)
                   "formulas": {"<lever>": "<expression>", ...},   one expression per lever
                   "b_group": ["<lever>", ...],                    optional: mutually exclusive levers,
                                                                   only the best one counts
                   "go_rule_us": <number>}                         optional: go = sum >= go_rule_us
  Expressions: + - * / ** unary -, numbers, variable names, max(), min(), abs().
  --round K       input rounding as printed by the attribution tool, e.g. `b_us=1 gap_slope_after=2`
                  (decimal places; applied to the numbers before evaluation; default: none).

--calibrate --levers JSON --ab FILE --src-name NAME [--ab FILE --src-name NAME ...] [--write]
  Per-class discount calibration from committed board A/B files.  The JSON "classes" map says,
  per class, which source (matched ONLY by --src-name, because --ab may be /dev/fd/NN), which
  lines and which keys/regex give the numbers.  Kinds:
    delta  disc = <meas_key> / (<x_base_key> - <x_lever_key>); check pred = dx * disc vs meas.
    ratio  ratio = meas / pred from one regex match (n_samples=1 is allowed; it is a ratio
           source, not a measurement source, and never raises).
    uncalibrated  no source; priced elsewhere (e.g. des.py); never ASSUMED.
  disc_src is written as <src-name>:<line>[-<line>].  --write stores the calibrated numbers in
  the JSON (so no number in it is typed by hand).  Last line:
  `CALIB classes=... <class>_disc=... ok=<0|1>`.

Output (stdout): one `PRED name=<lever> pred_us=<x>` line per lever and a final summary line
  `LEVERTAB <lever>_us=... sum_pred_us=... go=<0|1> pick=<best group>+<best other> [extra k=v]`.
  sum = best lever of the exclusive group + best lever outside it (each lever counted once).
"""
import argparse
import ast
import json
import operator
import re
import sys

_BIN = {ast.Add: operator.add, ast.Sub: operator.sub, ast.Mult: operator.mul,
        ast.Div: operator.truediv, ast.Pow: operator.pow}
_UN = {ast.USub: operator.neg, ast.UAdd: operator.pos}
_FN = {"max": max, "min": min, "abs": abs}


def evaluate(expr, env):
    """safe arithmetic evaluation of `expr` over the variables in env."""
    def ev(n):
        if isinstance(n, ast.Expression):
            return ev(n.body)
        if isinstance(n, ast.Constant) and isinstance(n.value, (int, float)):
            return float(n.value)
        if isinstance(n, ast.Name):
            if n.id not in env:
                raise KeyError(f"formula variable '{n.id}' not in attrib row / params")
            return float(env[n.id])
        if isinstance(n, ast.BinOp) and type(n.op) in _BIN:
            return _BIN[type(n.op)](ev(n.left), ev(n.right))
        if isinstance(n, ast.UnaryOp) and type(n.op) in _UN:
            return _UN[type(n.op)](ev(n.operand))
        if (isinstance(n, ast.Call) and isinstance(n.func, ast.Name) and n.func.id in _FN
                and not n.keywords):
            return float(_FN[n.func.id](*[ev(a) for a in n.args]))
        raise ValueError(f"unsupported expression element: {ast.dump(n)}")
    return ev(ast.parse(expr, mode="eval"))


def num(s):
    try:
        return float(s)
    except (TypeError, ValueError):
        return None


def read_rows(path, tag):
    rows = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            p = line.split()
            if not p or p[0] != tag:
                continue
            rows.append(dict(x.split("=", 1) for x in p[1:] if "=" in x))
    return rows


def price(row, spec, rnd=None):
    env = {}
    for k, v in row.items():
        x = num(v)
        if x is not None:
            if rnd and k in rnd:
                x = float(f"{x:.{rnd[k]}f}")
            env[k] = x
    for k, v in spec.items():
        if isinstance(v, (int, float)) and not isinstance(v, bool):
            env[k] = float(v)
    for cn, c in (spec.get("classes") or {}).items():
        if c.get("disc") is not None:
            env[f"{cn}_disc"] = float(c["disc"])
    formulas = spec.get("formulas") or {}
    if not formulas:
        raise ValueError("formula file has no 'formulas'")
    lcls = spec.get("lever_class") or {}
    cls = spec.get("classes") or {}
    # levers of an uncalibrated class are not priced here (e.g. buffer_decouple -> des.py)
    formulas = {n: e for n, e in formulas.items()
                if cls.get(lcls.get(n), {}).get("kind") != "uncalibrated"}
    pred = {n: evaluate(e, env) for n, e in formulas.items()}
    order = list(formulas)
    group = [n for n in (spec.get("b_group") or []) if n in pred]
    rest = [n for n in order if n not in group]
    key = lambda n: (-pred[n], order.index(n))
    pick = [sorted(s, key=key)[0] for s in (group, rest) if s]
    total = sum(pred[n] for n in pick)
    gr = spec.get("go_rule_us")
    go = int(total >= float(gr)) if gr is not None else None
    return pred, pick, total, go


def _ident(k):
    """RESULT key -> variable name: base_b_us(4,3) -> base_b_us_4_3."""
    return re.sub(r"_+$", "", re.sub(r"[^0-9A-Za-z_]+", "_", k))


def read_kv_lines(path, tag, lines):
    """{var: (value, line_no)} from `<tag> k=v ...` rows on the given 1-based lines."""
    out = {}
    with open(path, encoding="utf-8") as f:
        for i, line in enumerate(f, 1):
            if lines and i not in lines:
                continue
            p = line.split()
            if not p or p[0] != tag:
                continue
            for x in p[1:]:
                if "=" in x:
                    k, v = x.split("=", 1)
                    if num(v) is not None:
                        out[_ident(k)] = (float(v), i)
    return out


def _span(src, lines):
    lo, hi = min(lines), max(lines)
    return f"{src}:{lo}" if lo == hi else f"{src}:{lo}-{hi}"


def calibrate(spec, srcs):
    """srcs: {src_name: path}.  Returns (updated class dict, report dict)."""
    classes = spec.get("classes") or {}
    if not classes:
        raise ValueError("levers JSON has no 'classes'")
    rep = {"order": list(classes)}
    for name, c in classes.items():
        kind = c.get("kind")
        if kind == "uncalibrated":
            c["disc"] = None
            c["disc_src"] = "UNCALIBRATED: " + str(c.get("priced_by", "not priced here"))
            c["n_samples"] = 0
            continue
        src = c["src"]
        if src not in srcs:
            raise KeyError(f"class {name}: source {src} not given (--src-name)")
        lines = [int(x) for x in c.get("lines", [])]
        if kind == "delta":
            kv = read_kv_lines(srcs[src], c.get("tag", "RESULT"), lines)
            for k in (c["meas_key"], c["x_base_key"], c["x_lever_key"]):
                if k not in kv:
                    raise KeyError(f"class {name}: key {k} not on {_span(src, lines)}")
            meas = kv[c["meas_key"]][0]
            dx = kv[c["x_base_key"]][0] - kv[c["x_lever_key"]][0]
            if dx == 0:
                raise ValueError(f"class {name}: zero delta")
            disc = meas / dx
            used = sorted({kv[k][1] for k in (c["meas_key"], c["x_base_key"], c["x_lever_key"])})
            c.update(disc=round(disc, 6), disc_src=_span(src, used), n_samples=1,
                     meas_us=meas, dx_us=round(dx, 6))
            pred = dx * disc
            rep[name] = dict(disc=disc, pred=pred, meas=meas, src=src)
        elif kind == "ratio":
            rx = re.compile(c["regex"])
            hit = None
            with open(srcs[src], encoding="utf-8") as f:
                for i, line in enumerate(f, 1):
                    if lines and i not in lines:
                        continue
                    m = rx.search(line)
                    if m:
                        hit = (m, i)
                        break
            if hit is None:
                raise ValueError(f"class {name}: regex not found in {_span(src, lines or [0])}")
            m, i = hit
            meas, pred = float(m.group("meas")), float(m.group("pred"))
            ratio = meas / pred
            c.update(disc=round(ratio, 6), disc_src=f"{src}:{i}", n_samples=1,
                     source_kind="ratio", meas_us=meas, pred_us=pred)
            rep[name] = dict(ratio=ratio, n=1)
        else:
            raise ValueError(f"class {name}: unknown kind {kind}")
    return classes, rep


def main_calibrate(a):
    if len(a.ab) != len(a.src_name):
        print("attrib_pred: each --ab needs one --src-name", file=sys.stderr)
        return 2
    with open(a.levers, encoding="utf-8") as f:
        spec = json.load(f)
    classes, rep = calibrate(spec, dict(zip(a.src_name, a.ab)))
    chk = spec.get("calib_check") or {}
    cn = chk.get("class", "lock_move")
    tol = float(chk.get("tol_us", 0.0))
    r = rep.get(cn)
    err = abs(r["pred"] - r["meas"]) if r else float("inf")
    ok = int(r is not None and err <= tol)
    if a.write:
        spec["classes"] = classes
        with open(a.levers, "w", encoding="utf-8") as f:
            json.dump(spec, f, indent=1)
            f.write("\n")
    out = ["CALIB", "classes=" + ",".join(rep["order"])]
    for n in rep["order"]:
        c = classes[n]
        if c.get("kind") == "delta":
            out.append(f"{n}_disc={c['disc']:.2f}")
        elif c.get("kind") == "ratio":
            out += [f"{n}_ratio={rep[n]['ratio']:.1f}", f"{n}_n={rep[n]['n']}"]
        else:
            out.append(f"{n}=uncalibrated")
    if r:
        out += [f"{chk.get('label', cn)}_pred_us={r['pred']:.1f}",
                f"{chk.get('label', cn)}_meas_us={r['meas']:.1f}",
                f"abs_err_us={err:.1f}", f"tol_us={tol:.1f}", f"src={r['src']}"]
    out.append(f"ok={ok}")
    print(" ".join(out))
    return 0 if ok else 1


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--attrib")
    ap.add_argument("--formulas", "--levers", dest="levers", required=True)
    ap.add_argument("--calibrate", action="store_true")
    ap.add_argument("--ab", action="append", default=[])
    ap.add_argument("--src-name", action="append", default=[])
    ap.add_argument("--write", action="store_true", help="store calibrated classes in --levers")
    ap.add_argument("--tag", default="ATTRIB")
    ap.add_argument("--row", type=int, default=-1)
    ap.add_argument("--round", nargs="*", default=[], metavar="KEY=DP")
    ap.add_argument("--extra", nargs="*", default=[], metavar="K=V",
                    help="k=v fields appended verbatim to the LEVERTAB line")
    a = ap.parse_args(argv)
    if a.calibrate:
        return main_calibrate(a)
    if not a.attrib:
        ap.error("--attrib is required unless --calibrate")
    rows = read_rows(a.attrib, a.tag)
    if not rows:
        print(f"attrib_pred: no {a.tag} row in {a.attrib}", file=sys.stderr)
        return 2
    with open(a.levers, encoding="utf-8") as f:
        spec = json.load(f)
    rnd = dict((k, int(v)) for k, v in (x.split("=", 1) for x in a.round))
    pred, pick, total, go = price(rows[a.row], spec, rnd)
    for n, v in pred.items():
        print(f"PRED name={n} pred_us={v:.1f} formula={spec['formulas'][n].replace(' ', '')}")
    out = ["LEVERTAB"] + [f"{n}_us={v:.1f}" for n, v in pred.items()]
    lcls, cls = spec.get("lever_class") or {}, spec.get("classes") or {}
    out += [f"{n}=uncalibrated" for n in spec["formulas"]
            if cls.get(lcls.get(n), {}).get("kind") == "uncalibrated"]
    if "disc" in spec:
        out.append(f"disc={float(spec['disc']):.2f}")
    out += [f"sum_pred_us={total:.1f}"]
    if go is not None:
        out.append(f"go={go}")
    out.append("pick=" + "+".join(pick))
    out += a.extra
    print(" ".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
