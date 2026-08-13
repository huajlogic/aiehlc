<!-- Copyright (C) 2025 - 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: source-grounding
description: Read BEFORE writing any user-facing explanation of what a tile computes, why a transfer is the size it is, what a stall means, or what to change to fix it - i.e. before nearly every answer. The user is debugging code they wrote; a register value is the symptom, their source is where the cause lives and where the fix has to go, so an answer assembled only from live registers and the compiled schedule describes the machine rather than their program and never reaches a line they can edit. Covers: the source inventory and where it comes from (app_sources(), the system-prompt block, backend_status.json > app_sources) so you never guess a filename; the kernel-name -> file:line map and how far to trust it; which files are hand-written and which are compiler output that is overwritten on the next build (never propose editing host.cc, kernel.cc, the .bcf or the MLIR as a fix); the four evidence chains that tie a schedule number back to the declaration that set it (window size, repetition count, lock protocol, buffer address); the <file>:<line> citation form the UI turns into a click, including line ranges; and the two honesty rules - read before you cite, and when source and registers disagree say so instead of smoothing it over, because that gap is usually the bug.
---

# Grounding an answer in the application's source

Source of truth: `schedule_debug_server.py` (`_app_source_manifest`:779,
`_app_kernel_defs`:714, `_app_def_line`:693, `_app_entry_source`:639,
`DebugState.app_sources`:2575, `_fmt_app_sources`:823, `_resolve_source`:862),
`debug_ui_mcp.py` (`app_sources`:953), `schedule_view.py` (`srcParseRef`:5632,
`srcOpen`:5697).

## Why this is a rule and not a preference

Three things describe the design, and they are not interchangeable:

| Layer | Answers | Where it comes from |
|---|---|---|
| Live registers | what the hardware **did** | `aie_exec` |
| Compiled schedule | what the tools **built** | `tile_info`, `get_flow_detail`, `get_design_overview` |
| Application source | what the developer **asked for** | the app's own `.cc` / `.cpp` / `.h` |

A diagnosis needs all three. The first two are the ones you get for free from
tool calls, which is exactly why answers drift into being about DMA channels and
BD chains — true, complete-sounding, and impossible for the user to act on
because nothing in them is a line they can change. The third layer is the one
that makes an answer a fix.

## Step 1 — get the inventory, never guess a filename

Three routes to the same manifest, all built by `_app_source_manifest`:

1. **The system prompt's "The application's own source" block** — the app that
   was loaded when this conversation started. Paths there are relative to the app
   directory.
2. **`mcp__debugui__app_sources()`** — the same thing, refreshed. Call it after an
   app switch (the `App:` field on the message context line changed), or whenever
   you suspect the prompt copy is stale.
3. **`<bundle_dir>/backend_status.json`** — key `app_sources` (structured) and
   `app_sources_text` (the rendered form). Rewritten by `_write_backend_status`.

The groups mean different things:

- **Entry source** — the file the app was built from. aiehlc only: that flow's
  `app_dir` is `aout/`, a build output directory holding nothing hand-written,
  and the real source lives anywhere in the tree, so it is recorded at build time
  in `worklocal/app_source.txt` (fallback: `sim_config.sh`'s `HOST_SRC`).
- **Kernels** — each kernel name the schedule runs, mapped to the `file:line`
  defining it. See the caveat below.
- **Application / Headers** — hand-written sources found by walking `app_dir`.
  Files carrying a generated banner are filtered out, so what remains is the
  user's code.
- **Build** — `build.sh`, `Makefile`, `.bif` at the app root. Read these when the
  question is "why was it compiled this way".
- **Generated** — read-only evidence. See step 3.

If a group is empty it is empty. Say "this app has no hand-written sources under
`<app_dir>`" and ask the user where the source lives. Do **not** Glob the repo
root hoping to find something plausible — a confidently-cited file that turns out
to belong to a different app is worse than admitting the inventory came up short.

## Step 2 — the kernel -> source map, and how far to trust it

`_app_kernel_defs` takes the kernel names the schedule attributes to tiles
(`high_level.kernel`, plus `kernel.function` from the view) and finds where each
is defined by searching the app's `.cc`/`.cpp` files for the name followed by
`(`. `_app_def_line` prefers a match whose line does not end in `;` — a signature
with a body, rather than a prototype or a call site.

That is a **name match, not a parse**. Treat the line as a jump target, not a
citation: open the file, confirm you are looking at the definition, then cite the
line you actually read. Two known ways it comes up short, both harmless if you
check:

- Overloads and same-named statics in several files — you get the first hit in
  walk order.
- Names that no source defines. The aiehlc flow labels tiles with *roles*
  (`dskernel_receiver`), not function names, so those show
  `(definition not found by name)`. That is correct output, not a failure — use
  the entry source and `kernel.function` instead.

## Step 3 — hand-written vs generated, and why the difference is load-bearing

The **Generated** group is `host.cc`, `kernel.cc`, the `.bcf` and the dfschedule
MLIR. They are the best evidence you have for what the compiler decided — exact
BD lengths, lock ids, addresses, stream-switch config — and `tile_info` already
quotes them for you.

They are also **regenerated on every build**. So:

- Quote them freely as evidence of a decision.
- **Never propose editing one as the fix.** A patch to `host.cc` is erased by the
  next `build.sh`, and a user who applies it loses time twice — once making the
  change, once discovering it did nothing.
- When a generated file contains something wrong, the finding is "the compiler
  emitted X"; the *fix* is upstream, in the source or the build config that drove
  it. Trace it there before recommending anything.

`bundle_dir/host.cc` in particular is not hand-written host code — it is
`aie_control.cpp` verbatim plus a generated wrapper. Blaming the user for what is
in it is a real failure mode. See `app-layout` for the full path table.

## Step 4 — the four chains worth following

Each ties a number the schedule reports back to the declaration that set it. A
number that matches on both sides is a fact; a number that appears on only one
side is where the bug usually is.

| Schedule / register says | Go read | The mismatch means |
|---|---|---|
| BD length, transfer bytes per iteration | the window / buffer declaration in the kernel signature and the `connect<>` or buffer size in the graph source | producer and consumer disagree on element count or type width |
| Repetition / iteration count, `startio` repeat | the graph's run count and the kernel's loop bounds | one side sends fewer iterations than the other waits for — the classic stall |
| Lock ids and acquire/release ordering | the kernel's window acquire/release calls (or the buffer API's implicit ones) | a path through the kernel that skips a release, so credit is never returned |
| BD buffer address, `win_base`, ping-pong pair | the `.bcf` symbol map **and** the buffer the kernel actually writes | the kernel is computing into a buffer the DMA is not reading |

For the first three, the kernel source is the second half of the answer. Reading
it costs one Read once you have the `file:line` from step 1.

## Step 5 — cite so the user can click

Write source locations as **`<file>:<line>`** inline in your prose:
`stream_accum.cc:23`, `src/graph.cpp:138`, `worklocal/host.cc:412`. The UI parses
that form (`srcParseRef`) and turns it into a click that opens the file in the
**Info** pane highlighted at that line (`srcOpen`).

- A range works: `graph.cpp:138-145`.
- **Cite the path form the inventory gave you**, not a bare basename. A bare name
  does resolve, but `_source_name_index` puts the paths the *view* names ahead of
  its walk of the app directory — and `work2provenance` copies each kernel into
  the bundle (`worklocal/src/…`, `worklocal/kernels/<C>_<R>/src/…`). So bare
  `stream_accum.cc` opens the bundle's copy while `src/stream_accum.cc` opens the
  one the user actually edits. Verified: both exist for `example/stream`, and the
  bundle copy goes stale the moment they edit and have not rebuilt.
- "`host.cc`, line 412" does **not** parse. Neither does a filename with the line
  mentioned in the next sentence. Keep the colon and the number adjacent.
- For files outside the loaded app, give a path rather than a bare name.

Quote the two or three lines that carry the point, inline. Do not paste whole
functions — the user has the file one click away, and a wall of pasted code
buries the finding.

## The two honesty rules

These override everything above.

1. **Read before you cite.** Never emit a line number you have not opened. Do not
   reconstruct what a kernel "must" contain from its name, its window signature
   or what the schedule implies — a fabricated citation is worse than no citation,
   because it is clickable and the user will check it.
2. **When source and registers disagree, say so.** Registers are ground truth for
   what the hardware did; source is ground truth for what was intended. If they
   conflict, report both sides explicitly with the evidence for each. That gap is
   usually the bug itself — it is the most valuable thing in your answer, not an
   inconsistency to reconcile away or split the difference on.

And the precondition that outranks both: if there is no board session, you have
no register layer at all. Read `session-provenance` — the source layer is still
fully available offline, and an explanation grounded only in the source is a
legitimate answer as long as you say that is what it is.
