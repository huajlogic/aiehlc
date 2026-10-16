---
name: aiecoretimerlock
description: AIE core cycle counters (aie::tile::current().cycles()) bracketing acquire_greater_equal read ~2 cycles of "wait" and per-layer totals larger than the host's wall time; chess moves the timer read across the lock acquire even with chess_separator_scheduler.
---

# Core-side timer reads do not bracket lock waits

## Symptom
Kernel instrumentation `t0 = cycles(); acquire_greater_equal(lock, v); wait += cycles() - t0;`
reports ~2 cycles per wait everywhere, while per-layer totals (taken right after
acquiring a "header full" lock) exceed the host-measured layer time by 4-5x --
they include host idle time that should have been outside the interval.

## Cause
The timer read is not ordered against the lock-acquire instruction by the chess
scheduler; `chess_separator_scheduler()` around the read did not change it.
The acquire stalls *after* both reads were issued.

## What to do instead
- Attribute time with host-side A/B builds: e.g. resnetengine `KDEFS=ENG_NO_MAC
  bash build.sh eng /tmp/x` compiles the MAC loops out (compute vs data
  movement), resident-input on/off, etc.
- Measure the AIE clock from the host: `XAie_ReadTimer(dev, tile,
  XAIE_CORE_MOD, &t)` twice around a 2 ms `XTime` window (VEK385: 998 MHz).
- If a core-side number is needed, store the timer at points that are not
  adjacent to a lock (e.g. before/after a compute loop) and check the sum
  against the host wall time before trusting it.
