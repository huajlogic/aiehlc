<!-- Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# dbg_llm_skills — skills for the *embedded* debug assistant

These are **not** Claude Code skills. They are written for the assistant that
`schedule_debug_server.py` spawns as a `claude -p` subprocess and surfaces in the
**LLM** tab of the browser debug UI.

That reader is a different audience from a developer browsing the repo:

- Its tools are only the file tools, `mcp__aiegdb__*` and `mcp__debugui__*`.
- It is talking about a *live* design, often with a board attached, so a wrong
  command is not a typo — it is a bad read (or worse, a write) against hardware.
- It has no persistent memory between conversations, so anything it must not get
  wrong has to be written down here.

So every file is written as **procedures and exact command strings**, not prose.

## How they reach the assistant

This directory is a **Claude Code plugin**, so the assistant loads these natively:

```
dbg_llm_skills/
  .claude-plugin/plugin.json     # manifest (name is the only required field)
  skills/<slug>/SKILL.md         # one directory per skill
  README.md                      # this file
```

`_llm_spawn()` in [`../schedule_debug_server.py`](../schedule_debug_server.py)
passes `--plugin-dir <this directory>` to the `claude -p` subprocess. Skills then
appear in the assistant's skill listing and are invoked through the `Skill` tool,
with only their `name` + `description` in context until one is opened.

Why a plugin rather than copying into the repo's `.claude/skills/`:

- **One copy.** A duplicate under `.claude/skills/` would drift from the tooling
  it documents. These live beside `aiegdb.py` / `aiediag.py` and version with them.
- **Explicit beats implicit.** `claude -p` auto-discovers project skills from cwd
  today, but `--bare` (no auto-discovery) is announced to become the `-p` default.
  Passing `--plugin-dir` is immune to that, and to the daemon ever being started
  from a different cwd.

`_llm_skills()` additionally scans `skills/` at prompt-build time and lists the
skill *names* in the system prompt. That is a deliberate backstop, not the primary
path: skill descriptions get truncated when the listing exceeds its context budget,
and if plugin loading ever breaks the assistant can still Read the files.

Consequence: **adding a skill requires no code change.** Drop in
`skills/<slug>/SKILL.md` with valid front matter.

To use these from an ordinary Claude Code session in this repo:
`claude --plugin-dir src/tool/debug/dbg_llm_skills`

## Front matter contract

```
<!-- Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: <slug>            # must match the directory name
description: <one dense paragraph, trigger conditions first>
---
```

`_read_skill_frontmatter()` is a hand-rolled scan (the daemon is stdlib-only, no
YAML dependency). It handles a leading copyright comment and folded
continuation lines on `description`. A file that does not match this shape is
**skipped silently** rather than breaking prompt construction — so if a new skill
never shows up, check the header first.

## Current skills

| Skill | Answers |
|---|---|
| `session-provenance` | *May I claim this?* The four session states, applog staleness, why a configured target proves nothing. Read before any register read or log quote. |
| `aiegdb-console` | The verified `aie_exec` command surface: scope model, per-scope commands, which verbs write hardware. |
| `debugui-tools` | The fourteen granted `mcp__debugui__*` tools (9 static-schedule + 5 app/UI-state) — names, params, returns, and which question each answers. |
| `dma-stall-triage` | Ordered producer→hop→consumer procedure for a hang, stall or data mismatch. |
| `app-layout` | Which file answers which question, and where the app actually is on disk. |
| `simulator-vs-hardware` | Discriminating the two backends and their different read paths and logs. |
| `aiedbg-reference` | Index into the external aiedbg clone — raw CLI, named registers, device matrix, and the authority when aiediag's decode is in doubt. |
| `root-cause-workflow` | HOW to reason from UI observations to a root cause: paired-channel stall interpretation, idle-finished vs idle-never-started, static-balanced-but-dynamically-stalled, when to stop reading hardware and go to source. Includes a worked example from a stream-stall session. |

## Writing a new one

0. **Never hardcode a machine-specific path.** Both readers run with cwd = the
   aiehlc_aiesim repo root, so refer to repo files repo-relatively
   (`src/tool/debug/aiegdb.py`). For things outside the repo, resolve at read
   time rather than baking in a path: the loaded app comes from the `App:` line
   in the message context / `backend_status.json > app_paths`, and the aiedbg
   clone from `backend_status.json > aiedbg_paths.src` (`_aiedbg_paths()` finds
   it via `$AIEHLC_AIEDBG_SRC`, `thirdparty/aiedbg`, or the installed dist's
   `direct_url.json`). A path that is right on the author's machine and wrong on
   everyone else's is the easiest way to make a skill actively harmful.
1. Ground every command, flag, register offset, JSON key and path in the actual
   source. Open the file and confirm it. An unverifiable claim gets **left out** —
   a confident wrong command is worse than a missing one, because the assistant
   will run it.
2. Lead the `description` with trigger conditions.
3. Prefer a decision procedure over an explanation.
4. State preconditions explicitly (most device-touching procedures must defer to
   `session-provenance` first).
5. Flag any intrusive (hardware-writing) command as such, every time it appears.
