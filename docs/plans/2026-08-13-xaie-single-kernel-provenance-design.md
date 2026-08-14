# Static Provenance Map for the Raw-XAie Single-Kernel Flow

**Date:** 2026-08-13
**Status:** Design approved (brainstorming) — pending implementation plan

## Problem

Running

```bash
source script/aiehlc.sh --aie-version 5 --runtime-source-file ./example/perf/aieml_perf.cc --debug-syms
```

produces `aout/main.elf` but **no IR, no provenance map, and no `host_schedule.html`**. The
Debug UI device map and the `aiegdb` tile navigation therefore have nothing to load for this
app, and there is no way to visualise its schedule.

### Root cause

`aiehlc.sh` has two flow branches:

| Branch | Trigger | Produces provenance? |
|--------|---------|----------------------|
| **tiling** (tilinglinalg pipeline) | `aout/worklocal/host.cc` exists | Yes — C++ passes emit `dfscheduleprovenancemap.json` etc., then `schedule_view.py` renders `host_schedule.html` |
| **single-kernel** (raw pass-through) | fall-through | **No** — compiles kernel + host into `main.elf` and stops |

`example/perf/aieml_perf.cc` is a hand-written standalone XAie-driver app: the tile / DMA /
route structure is expressed through **runtime driver calls** (`XAie_InitRoutingHandler`,
`XAie_Route`, `XAie_MoveDataExternal2Aie`, `XAie_MoveDataAie2External`, `XAie_TileLoc`). It
goes through the single-kernel branch, which emits no `dfschedule` IR and no aiecompiler
`Work/` dir — so **neither** existing provenance generator (the C++ passes, nor
`work2provenance.py`) applies. A **third** generator is needed.

### What is statically recoverable

Because routing is decided at runtime by the driver, exact **BD IDs, lock IDs, and
stream-switch ports are NOT visible** in the source. Only the **coarse structure** can be
extracted: which tiles exist, where the kernel is placed, flow directions, byte sizes, and the
shim column. This is sufficient for the stated goal — Debug UI device map + `aiegdb` tile
navigation — and matches the "coarse structure is enough" decision.

## Goal & Scope (decided)

- **Goal:** enable the Debug UI device map and `aiegdb` tile navigation. Exact
  runtime-decided BD/lock/port data is **not** required.
- **Scope:** GENERAL — any raw-XAie single-kernel aiehlc app, not just `aieml_perf.cc`.
- **Resolver:** light Python const/macro propagation — no `clang -E`, no include resolution.
- **Also required:** generate `host_schedule.html` and the schedule logic for the general flow
  (reuse `schedule_view.py` / `schedule_debug_server.py` unchanged), including the optional
  `--prettydebug` live server.
- The generator stays **independent of the `AIEHLC_PROFILING` path** (`aie_runtime.c:49`).

## Approach (chosen: Approach A)

A standalone Python source-parser plus non-fatal wiring in `aiehlc.sh`. **No C++ changes**;
`schedule_view.py` and `schedule_debug_server.py` are reused unchanged.

```
single-kernel branch (main.elf built)
  └─ stage aout/worklocal/{host.cc, kernel.cc copies}
  └─ xaiehost2provenance.py  (NEW)
       ├─ dfscheduleprovenancemap.json
       └─ dmaphopprovenacemap.json
  └─ schedule_view.py aout/worklocal/
       ├─ schedule_view.json
       └─ host_schedule.html
  └─ (optional --prettydebug) schedule_debug_server.py aout/worklocal/ --elf ... --open
```

### Why not the alternatives

- **B — extend a C++ pass:** the raw flow never builds `dfschedule` IR, so there is nothing for
  a pass to walk. Rejected.
- **C — full clang preprocess + AST:** heavyweight, pulls in include resolution and toolchain
  deps for what is a handful of well-known driver call shapes. Rejected in favour of the light
  Python resolver.

## Component 1 — `src/tool/debug/xaiehost2provenance.py` (NEW)

Mirrors `work2provenance.py` as its sibling (`_hw_gen_str` → `"Gen5"`, same output shapes).

### Light macro / const resolver

- Seed `AIE_GEN` from `--aie-version` (2 or 5) and `__AIESIM__` from `--platform`.
- Evaluate `#if AIE_GEN <= N`, `#elif AIE_GEN == N`, `#ifdef __AIESIM__`, `#else`, `#endif`
  to select the live branch (so `shimcol` resolves to **10** for gen5 baremetal, 6 for gen2,
  3 for sim).
- `eval_int(expr)` folds simple integer/macro arithmetic for sizes (e.g.
  `mlen * sizeof(u32)` where `mlen = MAT_SIZE*2 = (N*N)*2`).
- `#define` table built from the file; function-like macros expanded shallowly.

### Regex extractors (well-known driver call shapes)

| Source construct | Extracts |
|------------------|----------|
| `XAie_LoadElfMem(_, XAie_TileLoc(c,r), (unsigned char*)kern)` | kernel placement (kernel name on tile `(c,r)`) |
| `XAie_TileLoc(c,r)` | tile set; `type = row==0 ? "shim" : "core"` |
| `XAie_MoveDataExternal2Aie(_, src, _, bytes, _, dst)` | push flow src→dst, **S2MM** on dst, `len=bytes` |
| `XAie_MoveDataAie2External(_, src, _, bytes, dst, _)` | pull flow src→dst, **MM2S** on src, `len=bytes` |
| `XAie_Route(_, _, src, dst)` | connectivity fallback when no MoveData present |

### JSON emission (existing schema)

Reuses the exact keys `schedule_view.build_view()` reads, from
`passdfscheduleprovenancemap.cpp`:

`dfscheduleprovenancemap.json`:
- top level: `version:1`, `startcol:0`, `aie_gen:"Gen5"`, `provenance_source:"static-xaie"`.
- `tiles[]`: `{col, row, type, dma_channels[]}` where each channel is
  `{channel, direction, flow_index, bd_chain[], start_io[]}`.
- synthetic **placeholder BD**: `{bd_id:"runtime", buffer_offset:0, len:bytes, next_bd:-1,`
  `acquire_lock:[{id:-1,val:0}], release_lock:[{id:-1,val:0}]}` — signals "runtime-decided".
- `kernel_configs[]`, `load_kernel_group{callee, tiles[]}`, `flow_summary[]`.

`dmaphopprovenacemap.json`: `communication_paths[]` with producer / channel-hop / consumer
stages, one per flow.

`startcol=0` is correct here because the raw flow uses **absolute physical columns**
(`XAie_TileLoc(4,4)`), so `phys_col = col + startcol = col`.

### Degrade gracefully

If zero tiles or zero flows are recognised → write **no JSON**, print a clear
`no XAie routing found — skipping provenance` note, exit 0.

## Component 2 — `aiehlc.sh` wiring (single-kernel branch)

A **non-fatal** block placed after "Build complete" in the single-kernel fall-through:

- Guard: only when `main.elf` exists, platform is baremetal/linux (skip sim early-return).
- Stage `aout/worklocal/` with `host.cc` (+ `kernel.cc`) copies.
- Run `xaiehost2provenance.py --aie-version $AIE_VERSION --platform $PLATFORM`.
- Run `schedule_view.py "${WORKLOCAL_DIR}"` (guarded `if ... then ... else warning; fi`).
- Reuse the tiling branch's `--prettydebug` logic to launch `schedule_debug_server.py`.
- Everything wrapped so `set -eo pipefail` cannot change the overall build exit code — a
  generator/view failure prints a warning but the build still reports success.

## Testing & Verification

**Unit (generator in isolation):**
1. `aieml_perf.cc --aie-version 5 --platform baremetal` → one core tile `(4,4)` with kernel
   `perf`; one shim `(10,0)`; two flows (shim→core S2MM 128B, core→shim MM2S 128B);
   `startcol=0`, `aie_gen="Gen5"`, `provenance_source="static-xaie"`.
2. Macro resolver: `AIE_GEN=2`→shimcol 6; `__AIESIM__`→shimcol 3.
3. Schema validation: both JSONs load with every key `build_view()` requires.

**Integration:** feed `aout/worklocal/` to `schedule_view.py`; `host_schedule.html` +
`schedule_view.json` produced without exception; device map lists `(4,4)` and `(10,0)`.

**End-to-end:** re-run the original command; `main.elf` still builds (exit code unchanged);
`aout/worklocal/{dfscheduleprovenancemap.json, dmaphopprovenacemap.json, host.cc,
host_schedule.html}` exist; `--prettydebug` launches the server and `aiegdb target tile 4 4`
resolves.

**Negative / robustness:** a pure-compute file → no JSON, clear note, build succeeds; a forced
non-zero generator exit → build still reports success.

**Regression:** the tiling flow (`simplematmul2.cc`) is untouched — the new block only runs in
the fall-through where `aout/worklocal/host.cc` did not already exist from tiling.

## Files

- **NEW** `src/tool/debug/xaiehost2provenance.py`
- **EDIT** `script/aiehlc.sh` (non-fatal provenance/view block in single-kernel branch)
- **REUSED unchanged** `src/tool/debug/schedule_view.py`, `schedule_debug_server.py`
