---
name: flowbalancebroadcast
description: Debug UI tile grid shows every compute tile with a red border and a ⚠ badge ("supply/demand mismatch") on every launch, with nothing wrong on hardware. It is the static compute_flow_balance check in schedule_view.py, baked into schedule_view.json at build time; it used to treat every one-shim-to-N-cores flow as a split and flagged true (replicating) broadcasts as 4x under-supply.
---

# Red tiles + ⚠ in the debug UI grid = static supply/demand check

## What it is

`schedule_view.py:compute_flow_balance()` compares, per DMA flow, producer
(MM2S) bytes per fire vs consumer (S2MM) bytes. A tile whose channel sits on a
flow with `balanced is False` gets `.tile.sdmismatch` (red border) and the
`badge sdwarn` ⚠ (tooltip "supply/demand mismatch"). It is **not live data**:
`aiehlc.sh` computes it into `worklocal/schedule_view.json` at build time and
the server just reads that back -- hence "every launch".

## The false alarm (fixed)

One shim → N cores was always scored as a SPLIT (`demand = sum(core reads)`).
A replicating broadcast (ColBC filter window: the same 3136 B to all 4 cores of
a column) then reads 4 x 3136 = 12544 ≠ 3136 → every compute tile red.

Now: `broadcast` if every read == supply (replicate), `scatter` if sum == supply
(split), mismatch only if neither. The flow summary has no replicate/split
flag; the bytes decide it.

## After changing the check

Existing builds keep the stale verdict until the view is regenerated:

```bash
python3 src/tool/debug/schedule_view.py <worklocal>     # e.g. aout/worklocal
python3 src/tool/debug/tests/test_flow_balance.py
```

Gather and p2p are unchanged. `fires`/`repeat_count` are recorded but not
used by the check.
