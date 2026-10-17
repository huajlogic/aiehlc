---
name: memtilestalenan
description: A persistent AIE engine that passed before now fails on every run, even after reverting the change that first broke it. Outputs are all NaN (check reports N/N mismatched with max |diff| 0) and every token is 0. Memory-tile contents survive partition init and column reset.
---

# Stale NaN in memory tiles poisons later runs

## Symptom
whisperengine: one experimental build produced NaN. After that, the **committed,
previously passing** build failed the same way on every run. `check block0` read
576000 / 576000 with `max |diff| 0`, because a NaN comparison counts as a mismatch but
contributes no diff. The decoder emitted token 0 throughout. Reverting the source
changed nothing.

## Cause
`__Runtime_init_mesh_partition` uses `XAIE_PART_INIT_OPT_DEFAULT` (column reset,
shim reset, isolate), **not** `XAIE_PART_INIT_OPT_ZEROIZEMEM`. Memory tiles keep
their contents across runs and ELF loads. The engine reads some memtile bytes it
never fills, multiplied by zero (zero-weighted K padding, masked keys). Finite
garbage times zero is 0, but NaN times zero is NaN. The broken run left NaNs there.

## Fix
`we_init` (eng/we_host.h) zero-fills all eight memory tiles once from a zeroed DDR
buffer over the existing fill routes, and waits for both the memtile S2MM and the
shim MM2S.

Trap: a memtile BD's length field cannot hold 512 KB. A 0x80000-byte BD wraps to 0,
completes at once, and leaves the stream data for the next op's BDs, which then hang
(`WE HANG waiting output ... op seq 2`). Use two chained 256 KB BDs.

## Rule
After any run that may have produced NaN/Inf on the array, do not trust a
"regression" until memory has been cleared. Persistent engines should zero their
memtiles, or pass `ZEROIZEMEM`, at init.
