---
name: whisperaieoffload
description: Run, debug or extend the Whisper -> TVM -> aiehlc all-layer offload (src/frontend/tvmrelay/example/whisper). Use when a Relay op is "left on the CPU", a layer's aiehlc library fails a check (resolved constant != plan, core window != kernel window), the x86 emulated network diverges from TVM/PyTorch, the transcript differs, or the aarch64 link of whisper_aie.elf fails (duplicate host_canonicalized, missing aiew_* symbol).
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Whisper all-layer AIE offload

```bash
source script/setup.sh --path-set-only
PYTHONPATH=src python src/frontend/tvmrelay/example/whisper/whisper_flow.py [--no-verify] [--no-board]
```

Needs `build/aiehlc` from this tree (RowSpace + window fixes), TVM 0.16 with LLVM.

| failing stage | look at |
|---|---|
| 4 partition: `{op: n} left on the CPU` | `aie_partition.find_groups`: add an anchor or let a group absorb it; layout ops must be absorbed, never anchors |
| 4: `layout chain is not a strided view` | the chain needs the scatter form (`output_view`), or it really copies |
| 5 aiehlc: `aiehlc resolved X=..., plan says ...` | planner vs compiler derivation drift -- compare `aie_kernels_whisper.expected_constants` with the `[TilingLinalg]` log |
| 5: `core window IN_k is A elements, kernel walks B` | skill **nonsquaremeshgemmwindow** |
| 5: `aiehlc.sh rc=..` | `aie_libs/<sig>/aiehlc.log`; text traps: skill **aiesourcetextrewrite** |
| 7: emulator `window count A=.. DMA delivers ..` | kernel body walks a different number of windows than the space declares |
| 7: undefined `aiew_*` in the *cpu* DSO | the reference module got partitioned (partition must copy) |
| 8: `multiple definition of host_canonicalized` | `whisper_board.localize_archive` must run on every archive |

Generated test scripts go under `worklocal/`, not `$TMPDIR` (a stray `http.py`
there shadowed the stdlib). Do not run two flows at once: they share
`worklocal/whisper_deploy/aie_libs`.

Design + numbers: `README.md`, `GAP_ANALYSIS.md`, `PROCESS_LOG.md` in the example dir.
