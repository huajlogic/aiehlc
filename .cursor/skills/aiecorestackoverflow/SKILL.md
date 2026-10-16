---
name: aiecorestackoverflow
description: AIE kernel gives +1 off-by-one errors in a few pixels and/or constant garbage in some layers right after an unrelated code path was ADDED (not changed); per-lane requant constants (EpSet) or other statics sit right above DM_stack. Kernel stack overflow, check kernel.calltree.
---

# AIE core stack overflow masquerading as rounding errors

## Symptom
Layers that passed bit-exact start failing after new code was added to the
kernel (resnetengine: adding the stem path): a handful of outputs off by exactly
+1 (looks like an SRS rounding-mode problem), and residual/epilogue layers
producing a constant. Isolated per-layer runs still fail, so it is not data
flowing between layers.

## Cause
Chess inlined the new path into `main`; `main`'s frame grew and the deepest
call chain (main -> run_layer -> finish -> req_acc) went past the end of
`_stack DM_stack`. The linker puts the kernel's statics directly ABOVE the
stack (here the decoded requant constants `ep_main`), so the overflow rewrites
rounding constants mid-layer: +1 errors, broken multipliers.
`kernel.calltree`'s "Maximum stack size" was 4032 B against a 4608 B stack and
still overflowed; treat it as a lower bound.

## Fix
- `__attribute__((noinline))` on the big per-mode functions so their frames are
  siblings, not added onto `main` (`kernel.calltree` shows the tree).
- Give the stack real headroom (resnetengine: `_stack DM_stack 0x70000 0x1400`,
  arena moved up to `0x71C00`; `gen_engine.DM_W` and `ENG_W_BASE` must match).

## Check
`grep -A1 'Maximum stack size' build/kernel.calltree` and in `build/kernel.map`
the last static before your fixed arena (`atexit_cnt` etc.) must end below it.
Keep >= ~1 KB between the calltree maximum and the stack size.
