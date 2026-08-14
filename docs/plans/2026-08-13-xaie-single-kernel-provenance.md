# Static Provenance Map for Raw-XAie Single-Kernel Flow — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Generate a coarse provenance map + `host_schedule.html` for the raw-XAie single-kernel aiehlc flow (e.g. `example/perf/aieml_perf.cc`), which today produces `main.elf` but no IR/provenance/view.

**Architecture:** A new standalone Python source-parser (`src/tool/debug/xaiehost2provenance.py`) statically extracts tiles/kernel-placement/flows from raw `XAie_*` driver calls in the generated `aout/host.cc`, emitting the existing `dfscheduleprovenancemap.json` + `dmaphopprovenacemap.json` schema. A non-fatal block wired into the single-kernel branch of `script/aiehlc.sh` runs the generator, then reuses `schedule_view.py` / `schedule_debug_server.py` unchanged.

**Tech Stack:** Python 3 (stdlib only: `re`, `json`, `argparse`), Bash, pytest for tests.

**Design doc:** `docs/plans/2026-08-13-xaie-single-kernel-provenance-design.md`

**Reference files (read before starting):**
- Schema authority: `src/mlir/mlirfront/tilinglinalg/pass/passdfscheduleprovenancemap/passdfscheduleprovenancemap.cpp` (lines 564-822 emit the exact JSON keys).
- Sibling generator to mirror: `src/tool/debug/work2provenance.py` (`_hw_gen_str`, `gen_dfschedule`, `gen_dmaphop` output shapes).
- View consumer contract: `src/tool/debug/schedule_view.py` `build_view()` (line ~1715) — hard-requires `dfscheduleprovenancemap.json` + `host.cc`; everything else degrades.
- Example input: `example/perf/aieml_perf.cc` (raw XAie app; gen5 baremetal → shimcol=10).
- Wiring template: `script/aiehlc.sh:526-562` (tiling branch schedule_view + --prettydebug block).
- Insertion point: `script/aiehlc.sh:686` (after `echo "    $HOST_BUILD_DIR/main.elf"`, before closing `}` at 687).

**Test layout:** Create `src/tool/debug/tests/test_xaiehost2provenance.py`. Run with `python3 -m pytest src/tool/debug/tests/test_xaiehost2provenance.py -v`.

---

## Task 1: Macro / const resolver — branch selection

**Files:**
- Create: `src/tool/debug/xaiehost2provenance.py`
- Test: `src/tool/debug/tests/test_xaiehost2provenance.py`

**Step 1: Write the failing test**

```python
# src/tool/debug/tests/test_xaiehost2provenance.py
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import xaiehost2provenance as x

SHIMCOL_SRC = """
#ifdef __AIESIM__
    int shimcol = 3;
#elif AIE_GEN == 5
    int shimcol = 10;
#else
    int shimcol = 6;
#endif
"""

def test_resolve_shimcol_gen5_baremetal():
    r = x.MacroResolver(aie_gen=5, aiesim=False)
    active = r.active_source(SHIMCOL_SRC)
    assert "int shimcol = 10;" in active
    assert "int shimcol = 3;" not in active
    assert "int shimcol = 6;" not in active

def test_resolve_shimcol_gen2_baremetal():
    r = x.MacroResolver(aie_gen=2, aiesim=False)
    active = r.active_source(SHIMCOL_SRC)
    assert "int shimcol = 6;" in active

def test_resolve_shimcol_aiesim():
    r = x.MacroResolver(aie_gen=5, aiesim=True)
    active = r.active_source(SHIMCOL_SRC)
    assert "int shimcol = 3;" in active
```

**Step 2: Run test to verify it fails**

Run: `python3 -m pytest src/tool/debug/tests/test_xaiehost2provenance.py -v`
Expected: FAIL — `ModuleNotFoundError` / `AttributeError: MacroResolver`.

**Step 3: Write minimal implementation**

Create `xaiehost2provenance.py` with a `MacroResolver` that walks the source line-by-line,
tracking a stack of `#if/#elif/#ifdef/#else/#endif` active-flags, and returns only the lines
in the active branches. Seed `AIE_GEN` from `aie_gen` and `__AIESIM__` from `aiesim`.

```python
#!/usr/bin/env python3
# src/tool/debug/xaiehost2provenance.py
"""Static provenance-map generator for raw-XAie single-kernel aiehlc apps.

Extracts coarse tile / kernel-placement / flow structure from the XAie driver
calls in a generated aout/host.cc and emits the dfscheduleprovenancemap.json +
dmaphopprovenacemap.json schema consumed by schedule_view.py. Runtime-decided
BD/lock/port values are NOT statically visible and are emitted as placeholders.
"""
import argparse, json, os, re, sys


class MacroResolver:
    def __init__(self, aie_gen, aiesim):
        self.defs = {"AIE_GEN": aie_gen}
        if aiesim:
            self.defs["__AIESIM__"] = 1

    def _defined(self, name):
        return name in self.defs

    def _eval_cond(self, expr):
        # Substitute known macros, then eval a simple integer comparison.
        e = expr.strip()
        for name, val in self.defs.items():
            e = re.sub(r"\b%s\b" % re.escape(name), str(val), e)
        # Unknown identifiers -> 0 (undefined macro in #if).
        e = re.sub(r"\b[A-Za-z_]\w*\b", "0", e)
        try:
            return bool(eval(e, {"__builtins__": {}}, {}))
        except Exception:
            return False

    def active_source(self, src):
        out, stack = [], []  # stack entries: (parent_active, this_taken, done)
        def active():
            return all(s[0] and s[1] for s in stack) if stack else True
        for line in src.splitlines():
            s = line.strip()
            m = re.match(r"#\s*(ifdef|ifndef|if|elif|else|endif)\b(.*)", s)
            if not m:
                if active():
                    out.append(line)
                continue
            kw, rest = m.group(1), m.group(2).strip()
            parent = all(x[0] and x[1] for x in stack) if stack else True
            if kw == "ifdef":
                taken = self._defined(rest)
                stack.append((parent, taken, taken))
            elif kw == "ifndef":
                taken = not self._defined(rest)
                stack.append((parent, taken, taken))
            elif kw == "if":
                taken = self._eval_cond(rest)
                stack.append((parent, taken, taken))
            elif kw == "elif":
                p, _, done = stack[-1]
                taken = (not done) and self._eval_cond(rest)
                stack[-1] = (p, taken, done or taken)
            elif kw == "else":
                p, _, done = stack[-1]
                stack[-1] = (p, not done, True)
            elif kw == "endif":
                if stack:
                    stack.pop()
        return "\n".join(out)
```

**Step 4: Run test to verify it passes**

Run: `python3 -m pytest src/tool/debug/tests/test_xaiehost2provenance.py -v`
Expected: PASS (3 tests).

**Step 5: Commit**

```bash
git add src/tool/debug/xaiehost2provenance.py src/tool/debug/tests/test_xaiehost2provenance.py
git commit -m "feat(xaiehost2provenance): add macro resolver for #if branch selection"
```

---

## Task 2: Integer expression evaluator (sizes)

**Files:**
- Modify: `src/tool/debug/xaiehost2provenance.py`
- Test: `src/tool/debug/tests/test_xaiehost2provenance.py`

**Step 1: Write the failing test**

```python
def test_eval_int_with_defines():
    r = x.MacroResolver(aie_gen=5, aiesim=False)
    defs = {"N": 4, "MAT_SIZE": "(N * N)"}
    assert x.eval_int("MAT_SIZE * 2", defs) == 32
    assert x.eval_int("mlen * sizeof(u32)", {"mlen": 32}) == 128
    assert x.eval_int("unknown_thing", {}) is None
```

`sizeof(u32)` must fold to 4. Unresolvable expressions return `None`.

**Step 2: Run test to verify it fails**

Run: `python3 -m pytest src/tool/debug/tests/test_xaiehost2provenance.py::test_eval_int_with_defines -v`
Expected: FAIL — `AttributeError: eval_int`.

**Step 3: Write minimal implementation**

Add a module-level `eval_int(expr, defs)` that: replaces `sizeof(u32|uint32_t|int32_t|int|u32)`
→ `4`, `sizeof(u16|...)` → `2`, `sizeof(u8|char)` → `1`; iteratively substitutes `defs`
(bounded to ~10 passes to expand nested macros like `MAT_SIZE`→`(N*N)`); then evals the
arithmetic in a restricted namespace. Returns `None` on any failure or leftover identifier.

```python
_SIZEOF = {"u32": 4, "uint32_t": 4, "int32_t": 4, "int": 4, "float": 4,
           "u16": 2, "int16_t": 2, "u8": 1, "char": 1, "uint8_t": 1}

def eval_int(expr, defs):
    e = expr
    e = re.sub(r"sizeof\s*\(\s*(\w+)\s*\)",
               lambda m: str(_SIZEOF.get(m.group(1), 4)), e)
    for _ in range(10):
        prev = e
        for name, val in defs.items():
            e = re.sub(r"\b%s\b" % re.escape(name), "(%s)" % str(val), e)
        if e == prev:
            break
    if re.search(r"[A-Za-z_]", e):
        return None
    try:
        v = eval(e, {"__builtins__": {}}, {})
        return int(v)
    except Exception:
        return None
```

**Step 4: Run test to verify it passes**

Run: `python3 -m pytest src/tool/debug/tests/test_xaiehost2provenance.py::test_eval_int_with_defines -v`
Expected: PASS.

**Step 5: Commit**

```bash
git add src/tool/debug/xaiehost2provenance.py src/tool/debug/tests/test_xaiehost2provenance.py
git commit -m "feat(xaiehost2provenance): add eval_int for size/const folding"
```

---

## Task 3: `#define` table + extract tiles, kernel placement, flows

**Files:**
- Modify: `src/tool/debug/xaiehost2provenance.py`
- Test: `src/tool/debug/tests/test_xaiehost2provenance.py`

**Step 1: Write the failing test**

```python
PERF_SNIPPET = """
#define N 4
#define MAT_SIZE (N * N)
    int shimcol = 10;
    XAie_LoadElfMem(DevInst, XAie_TileLoc(4, 4), (unsigned char *)perf);
    XAie_Route(routingInstance, NULL, XAie_TileLoc(shimcol, 0), XAie_TileLoc(4, 4));
    XAie_Route(routingInstance, NULL, XAie_TileLoc(4, 4), XAie_TileLoc(shimcol, 0));
    u32 mlen = MAT_SIZE * 2;
    XAie_MoveDataExternal2Aie(routingInstance, XAie_TileLoc(shimcol, 0), in,
                              mlen * sizeof(u32), CORE_IP_MEM, XAie_TileLoc(4, 4));
    XAie_MoveDataAie2External(routingInstance, XAie_TileLoc(4, 4), CORE_OP_MEM,
                              mlen * sizeof(u32), out, XAie_TileLoc(shimcol, 0));
"""

def test_extract_model_gen5():
    model = x.extract_model(PERF_SNIPPET, aie_gen=5, aiesim=False)
    # tiles
    tiles = {(t["col"], t["row"]): t["type"] for t in model["tiles"]}
    assert tiles[(4, 4)] == "core"
    assert tiles[(10, 0)] == "shim"
    # kernel placement
    assert model["kernel_placements"][(4, 4)] == "perf"
    # flows: push shim->core S2MM 128B, pull core->shim MM2S 128B
    dirs = {(f["src"], f["dst"], f["direction"]): f["len"] for f in model["flows"]}
    assert dirs[((10, 0), (4, 4), "S2MM")] == 128
    assert dirs[((4, 4), (10, 0), "MM2S")] == 128
```

**Step 2: Run test to verify it fails**

Run: `python3 -m pytest src/tool/debug/tests/test_xaiehost2provenance.py::test_extract_model_gen5 -v`
Expected: FAIL — `AttributeError: extract_model`.

**Step 3: Write minimal implementation**

Add:
- `collect_defines(src)` → `{name: body}` from `#define NAME body` (object-like only).
- `resolve_tileloc(col_expr, row_expr, defs)` → `(int,int)` via `eval_int`, with `shimcol`
  seeded into `defs` from `int shimcol = N;` in the active source.
- `extract_model(raw_src, aie_gen, aiesim)`:
  1. `active = MacroResolver(aie_gen, aiesim).active_source(raw_src)`.
  2. `defs = collect_defines(active)`; add `shimcol` from a `int shimcol = (\d+)` match; add
     any `u32 mlen = ...;` locals via `eval_int`.
  3. Regex-scan `active` for the five call shapes in the design table; build `tiles` (dedup,
     `type = "shim" if row == 0 else "core"`), `kernel_placements`, `flows`
     (`{src,dst,direction,len}`; `MoveDataExternal2Aie`→S2MM on dst, `MoveDataAie2External`→
     MM2S on src; `XAie_Route` only adds connectivity if no MoveData covers that pair).

Regexes (tolerate whitespace/newlines — use `re.DOTALL` on the arg span):

```python
RE_LOADELF = re.compile(
    r"XAie_LoadElfMem\s*\([^,]+,\s*XAie_TileLoc\s*\(([^,]+),([^)]+)\)\s*,"
    r"\s*\(unsigned char\s*\*\)\s*(\w+)")
RE_MOVE_IN = re.compile(
    r"XAie_MoveDataExternal2Aie\s*\([^,]+,\s*XAie_TileLoc\s*\(([^,]+),([^)]+)\)\s*,"
    r"[^,]+,\s*([^,]+),[^,]+,\s*XAie_TileLoc\s*\(([^,]+),([^)]+)\)", re.DOTALL)
RE_MOVE_OUT = re.compile(
    r"XAie_MoveDataAie2External\s*\([^,]+,\s*XAie_TileLoc\s*\(([^,]+),([^)]+)\)\s*,"
    r"[^,]+,\s*([^,]+),[^,]+,\s*XAie_TileLoc\s*\(([^,]+),([^)]+)\)", re.DOTALL)
RE_ROUTE = re.compile(
    r"XAie_Route\s*\([^,]+,\s*[^,]+,\s*XAie_TileLoc\s*\(([^,]+),([^)]+)\)\s*,"
    r"\s*XAie_TileLoc\s*\(([^,]+),([^)]+)\)", re.DOTALL)
```

`extract_model` returns a plain dict:
`{"tiles":[{"col","row","type"}], "kernel_placements":{(c,r):name},
"flows":[{"src":(c,r),"dst":(c,r),"direction":"S2MM|MM2S","len":int}]}`.

**Step 4: Run test to verify it passes**

Run: `python3 -m pytest src/tool/debug/tests/test_xaiehost2provenance.py::test_extract_model_gen5 -v`
Expected: PASS.

**Step 5: Commit**

```bash
git add src/tool/debug/xaiehost2provenance.py src/tool/debug/tests/test_xaiehost2provenance.py
git commit -m "feat(xaiehost2provenance): extract tiles/kernel/flows from XAie calls"
```

---

## Task 4: Emit `dfscheduleprovenancemap.json` in the existing schema

**Files:**
- Modify: `src/tool/debug/xaiehost2provenance.py`
- Test: `src/tool/debug/tests/test_xaiehost2provenance.py`

**Step 1: Write the failing test**

```python
def test_build_dfschedule_json():
    model = x.extract_model(PERF_SNIPPET, aie_gen=5, aiesim=False)
    doc = x.build_dfschedule(model, aie_gen=5)
    assert doc["version"] == 1
    assert doc["startcol"] == 0
    assert doc["aie_gen"] == "Gen5"
    assert doc["provenance_source"] == "static-xaie"
    tiles = {(t["col"], t["row"]): t for t in doc["tiles"]}
    core = tiles[(4, 4)]
    # core tile has both an S2MM (input) and MM2S (output) channel
    dirs = {c["direction"] for c in core["dma_channels"]}
    assert {"S2MM", "MM2S"} <= dirs
    # placeholder BD signals runtime-decided
    bd = core["dma_channels"][0]["bd_chain"][0]
    assert bd["bd_id"] == "runtime"
    assert bd["len"] == 128
    assert bd["acquire_lock"][0]["id"] == -1
    # load_kernel_group references the core tile
    assert [4, 4] in [list(t) for t in doc["load_kernel_group"]["tiles"]]
```

**Step 2: Run test to verify it fails**

Run: `python3 -m pytest src/tool/debug/tests/test_xaiehost2provenance.py::test_build_dfschedule_json -v`
Expected: FAIL — `AttributeError: build_dfschedule`.

**Step 3: Write minimal implementation**

Add `hw_gen_str(g)` (`5→"Gen5"`, `2→"Gen2"`, mirror `work2provenance.py`), a `placeholder_bd(length)`
helper, and `build_dfschedule(model, aie_gen)`. For each tile, gather the flows whose src/dst
touch it; each becomes a `dma_channel` with a synthetic incrementing `channel` index,
`direction`, `flow_index`, a single placeholder `bd_chain` entry, and `start_io:[{repeat_count:1}]`.
Emit `kernel_configs` (one per kernel placement, `sym_name`), `load_kernel_group{callee,tiles}`,
and `flow_summary` (one entry per flow). Keys must match `passdfscheduleprovenancemap.cpp:564-822`.

```python
def placeholder_bd(length):
    return {"bd_id": "runtime", "buffer_offset": 0, "len": int(length),
            "enable_packet": False, "packet_id": 0, "next_bd": -1,
            "acquire_lock": [{"id": -1, "val": 0}],
            "release_lock": [{"id": -1, "val": 0}]}

def build_dfschedule(model, aie_gen):
    tiles_out, ch_counter = [], {}
    for t in model["tiles"]:
        key = (t["col"], t["row"])
        chans = []
        for fi, f in enumerate(model["flows"]):
            touches = (f["src"] == key and f["direction"] == "MM2S") or \
                      (f["dst"] == key and f["direction"] == "S2MM")
            if not touches:
                continue
            idx = ch_counter.get(key, 0); ch_counter[key] = idx + 1
            chans.append({"channel": idx, "direction": f["direction"],
                          "enable_out_of_order": False, "flow_index": fi,
                          "bd_chain": [placeholder_bd(f["len"])],
                          "start_io": [{"repeat_count": 1}]})
        tiles_out.append({"col": t["col"], "row": t["row"], "type": t["type"],
                          "dma_channels": chans})
    kernel_cfgs, kg_tiles = [], []
    for (c, r), name in model["kernel_placements"].items():
        kernel_cfgs.append({"sym_name": name, "flow_index": 0, "packet_id": 0,
                            "dma_channel": 0, "tile_index": 0})
        kg_tiles.append([c, r])
    flow_summary = []
    for fi, f in enumerate(model["flows"]):
        flow_summary.append({"flow_index": fi, "direction": f["direction"]})
    return {"version": 1, "startcol": 0, "aie_gen": hw_gen_str(aie_gen),
            "provenance_source": "static-xaie", "module_attrs": [],
            "tiles": tiles_out, "kernel_configs": kernel_cfgs,
            "load_kernel_group": {"callee": "__Runtime_load_kernel_group",
                                  "tiles": kg_tiles},
            "flow_summary": flow_summary, "invariant_checks": []}
```

**Step 4: Run test to verify it passes**

Run: `python3 -m pytest src/tool/debug/tests/test_xaiehost2provenance.py::test_build_dfschedule_json -v`
Expected: PASS.

**Step 5: Verify against the real view consumer keys**

Read `src/tool/debug/schedule_view.py` `build_view()` and confirm every key it dereferences on
the dfschedule doc is present in `build_dfschedule` output. If `build_view` requires a key not
yet emitted, add it (defaulted) and extend the test. Note any additions in the commit message.

**Step 6: Commit**

```bash
git add src/tool/debug/xaiehost2provenance.py src/tool/debug/tests/test_xaiehost2provenance.py
git commit -m "feat(xaiehost2provenance): emit dfscheduleprovenancemap.json schema"
```

---

## Task 5: Emit `dmaphopprovenacemap.json` + CLI main + graceful degrade

**Files:**
- Modify: `src/tool/debug/xaiehost2provenance.py`
- Test: `src/tool/debug/tests/test_xaiehost2provenance.py`

**Step 1: Write the failing test**

```python
def test_build_dmaphop_and_degrade():
    model = x.extract_model(PERF_SNIPPET, aie_gen=5, aiesim=False)
    hop = x.build_dmaphop(model)
    paths = hop["communication_paths"]
    assert len(paths) == 2
    p = paths[0]
    assert "producer" in p and "consumer" in p
    # graceful: pure-compute source yields empty model -> no flows/tiles
    empty = x.extract_model("int main(){return 0;}", aie_gen=5, aiesim=False)
    assert empty["flows"] == [] and empty["tiles"] == []
    assert x.model_is_empty(empty) is True
```

**Step 2: Run test to verify it fails**

Run: `python3 -m pytest src/tool/debug/tests/test_xaiehost2provenance.py::test_build_dmaphop_and_degrade -v`
Expected: FAIL — `AttributeError: build_dmaphop`.

**Step 3: Write minimal implementation**

Add `build_dmaphop(model)` → `{"communication_paths":[...]}`, one path per flow with
`producer`/`consumer` stages `{"tile":[c,r],"channel":i,"direction":...}` (mirror
`work2provenance.gen_dmaphop` shape). Add `model_is_empty(model)` (`not tiles and not flows`).
Add `main()`:

```python
def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("host_cc")
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--aie-version", type=int, required=True)
    ap.add_argument("--platform", default="baremetal")
    a = ap.parse_args(argv)
    with open(a.host_cc) as f:
        raw = f.read()
    model = extract_model(raw, a.aie_version, a.platform == "sim")
    if model_is_empty(model):
        print("[xaiehost2provenance] no XAie routing found - skipping provenance")
        return 0
    os.makedirs(a.out_dir, exist_ok=True)
    with open(os.path.join(a.out_dir, "dfscheduleprovenancemap.json"), "w") as f:
        json.dump(build_dfschedule(model, a.aie_version), f, indent=2)
    with open(os.path.join(a.out_dir, "dmaphopprovenacemap.json"), "w") as f:
        json.dump(build_dmaphop(model), f, indent=2)
    print("[xaiehost2provenance] wrote provenance to %s" % a.out_dir)
    return 0

if __name__ == "__main__":
    sys.exit(main())
```

**Step 4: Run test to verify it passes**

Run: `python3 -m pytest src/tool/debug/tests/test_xaiehost2provenance.py -v`
Expected: PASS (all tests).

**Step 5: End-to-end smoke against the real example**

Run:
```bash
python3 src/tool/debug/xaiehost2provenance.py example/perf/aieml_perf.cc \
    --out-dir /tmp/claude/xaieprov --aie-version 5 --platform baremetal
python3 -c "import json;d=json.load(open('/tmp/claude/xaieprov/dfscheduleprovenancemap.json'));\
print(sorted((t['col'],t['row']) for t in d['tiles']))"
```
Expected: prints `[(4, 4), (10, 0)]`, and both JSON files exist.

> Note: `aieml_perf.cc` is the *user source*; the wired flow runs against the generated
> `aout/host.cc`, which contains the same XAie calls. The smoke test against the user source
> is a valid parser check.

**Step 6: Commit**

```bash
git add src/tool/debug/xaiehost2provenance.py src/tool/debug/tests/test_xaiehost2provenance.py
git commit -m "feat(xaiehost2provenance): emit dmaphop json + CLI main + graceful degrade"
```

---

## Task 6: Wire the generator + view into `aiehlc.sh` single-kernel branch

**Files:**
- Modify: `script/aiehlc.sh` (insert after line 686, before closing `}` at 687)

**Step 1: Add the non-fatal provenance/view block**

Insert immediately after `echo "    $HOST_BUILD_DIR/main.elf"` (line 686). Guarded so
`set -eo pipefail` cannot change the build exit code (`|| true` / `if` guards throughout):

```bash
# --- Static provenance + schedule view for the raw-XAie single-kernel flow. ---
# Non-fatal: never change the build's exit code (set -e/-o pipefail active).
if [[ "$platform" != "sim" ]] && [ -f "$host_file" ]; then
    SK_WORKLOCAL="${HOST_BUILD_DIR}/worklocal"
    mkdir -p "${SK_WORKLOCAL}"
    cp -f "$host_file" "${SK_WORKLOCAL}/host.cc" 2>/dev/null || true
    echo "${runtime_source_file}" > "${SK_WORKLOCAL}/app_source.txt" 2>/dev/null || true

    echo "Generating static provenance (raw-XAie flow)..."
    if python3 "${AIEHLC_DIR}/src/tool/debug/xaiehost2provenance.py" \
            "${SK_WORKLOCAL}/host.cc" --out-dir "${SK_WORKLOCAL}" \
            --aie-version "${aie_version}" --platform "${platform}"; then
        if [ -f "${SK_WORKLOCAL}/dfscheduleprovenancemap.json" ]; then
            echo "Generating readable schedule view..."
            if python3 "${AIEHLC_DIR}/src/tool/debug/schedule_view.py" "${SK_WORKLOCAL}"; then
                echo "    ${SK_WORKLOCAL}/host_schedule.html"
            else
                echo "    warning: schedule_view.py failed (non-fatal); skipping view."
            fi
        fi
    else
        echo "    warning: provenance generation failed (non-fatal)."
    fi

    if [ "$PRETTY_DEBUG" -eq 1 ] && [ -f "${SK_WORKLOCAL}/host_schedule.html" ]; then
        if ! command -v aiedbg &>/dev/null; then
            echo "aiedbg not found - bootstrapping (clone + pip install)..."
            python3 "${AIEHLC_DIR}src/tool/debug/ensure_aiedbg.py" \
                --repo-root "${AIEHLC_DIR}" || \
                echo "    warning: aiedbg bootstrap failed; live HW reads disabled."
            if [[ -f "${AIEHLC_DIR}.aiehlc/aiedbg_env.sh" ]]; then
                # shellcheck disable=SC1091
                source "${AIEHLC_DIR}.aiehlc/aiedbg_env.sh"
            fi
        fi
        echo "Launching live schedule-debug server (--prettydebug)..."
        python3 "${AIEHLC_DIR}/src/tool/debug/schedule_debug_server.py" \
            "${SK_WORKLOCAL}" \
            --elf "${HOST_BUILD_DIR}/main.elf" \
            --aie-version "${aie_version}" \
            --open
    fi
fi
```

**Step 2: Verify shell syntax**

Run: `bash -n script/aiehlc.sh`
Expected: no output (syntax OK).

**Step 3: End-to-end run**

Run:
```bash
source script/aiehlc.sh --aie-version 5 --runtime-source-file ./example/perf/aieml_perf.cc --debug-syms
ls aout/worklocal/dfscheduleprovenancemap.json aout/worklocal/dmaphopprovenacemap.json \
   aout/worklocal/host.cc aout/worklocal/host_schedule.html aout/main.elf
```
Expected: `main.elf` builds, "Build complete." prints, and all five files listed exist.

**Step 4: Regression — tiling flow untouched**

Run:
```bash
source script/aiehlc.sh --aie-version 5 --runtime-source-file ./example/tileprogram/ccode/simplematmul2.cc
```
Expected: tiling branch runs as before (it returns at line 562, never reaching the new block);
`aout/main.elf` builds.

**Step 5: Commit**

```bash
git add script/aiehlc.sh
git commit -m "feat(aiehlc): emit provenance + schedule view for single-kernel flow"
```

---

## Task 7: Documentation

**Files:**
- Modify: `CLAUDE.md` (add a one-line entry for `xaiehost2provenance.py` under the debug tools list)

**Step 1: Add the tool entry**

Add a bullet describing `src/tool/debug/xaiehost2provenance.py`: static provenance generator for
the raw-XAie single-kernel flow; extracts coarse tiles/kernel/flows from `aout/host.cc` XAie
driver calls; emits the dfschedule + dmaphop provenance JSONs consumed by `schedule_view.py`;
runtime-decided BD/lock/port values are placeholders; wired non-fatally into `aiehlc.sh`.

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: document xaiehost2provenance single-kernel provenance tool"
```

---

## Final Verification Checklist

- [ ] `python3 -m pytest src/tool/debug/tests/test_xaiehost2provenance.py -v` → all pass.
- [ ] `bash -n script/aiehlc.sh` → clean.
- [ ] Single-kernel run produces `aout/worklocal/{dfscheduleprovenancemap.json, dmaphopprovenacemap.json, host.cc, host_schedule.html}` + `aout/main.elf`.
- [ ] Device map opens tiles (4,4) and (10,0); `--prettydebug` server launches; `aiegdb target tile 4 4` resolves.
- [ ] Tiling flow (`simplematmul2.cc`) still builds unchanged.
- [ ] Build exit code unchanged when the generator fails (force a bad arg to confirm).

## Files Changed / Created

- **NEW** `src/tool/debug/xaiehost2provenance.py`
- **NEW** `src/tool/debug/tests/test_xaiehost2provenance.py`
- **EDIT** `script/aiehlc.sh` (non-fatal block after line 686)
- **EDIT** `CLAUDE.md` (tool doc entry)
- **REUSED unchanged** `src/tool/debug/schedule_view.py`, `schedule_debug_server.py`
