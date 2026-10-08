---
name: control-plane-dataplane-coexistence
description: Diagnoses control-packet sends that stall when the row-control fabric shares an AIE array with a live data plane (tiling GEMM). Use when ctrl_push / ctrl_elf times out, the shim MM2S never drains, program memory stays zero, or a broadcast wedges after a few dozen packets.
---

# Control plane next to a live data plane

Three independent stalls hit `simplematmul_ctrl_pkt.cc` on VEK385. All three
present as the same symptom — `ctrl MM2S idle TIMEOUT ... running=1 queued=0` —
so check them in this order.

## 1. Shim MM2S mux port shared with the data plane

`rt_ctrl_row_shim_entry` drops the control stream on shim SOUTH mux port 3 (ch0)
or 7 (ch1), then circuit-hops SOUTH -> NORTH `RT_CTRL_VFWD`. `routing.cc` has
usually already circuit-routed that *same* slave port to its own NORTH master:

```
XAie_StrmConnCctEnable(v1, XAie_TileLoc(0,0), SOUTH, 3, NORTH, 1);  // data plane
XAie_StrmConnCctEnable(dev,  XAie_TileLoc(0,0), SOUTH, 3, NORTH, 4);  // control
```

A circuit slave feeding two masters is a legal multicast, so every control packet
is replicated into the data-plane climb and lands on a core-tile DMA whose BDs
and locks are not configured yet. That branch never drains and the shim MM2S
backpressures on the *first* push.

Control sends only happen during load/launch, before any data DMA, so the fix is
temporal, not spatial:

- `rt_ctrl_shim_park_data_masters(f, fport)` disables every NORTH master on the
  spine shim before the entry is programmed.
- `__Runtime_ctrl_plan_release(f, mm2s_ch)` cuts SOUTH->NORTH VFWD and re-runs
  `routing()` (idempotent, stream-switch only) to restore the data plane. It is
  called at the end of `__Runtime_launch_kernel_group_ctrl`.

`XAie_StrmConnCctDisable` takes the slave port too, but rewrites the *master*
register with enable=0 — so the data-plane master is parked whatever slave it
came from. Pass the control entry's own mux port so the slave-side disable lands
on a port the caller re-enables immediately.

Verify the restore worked: `wait_io` cycles must match the mmio baseline to
within ~0.1%.

**Spatial alternative: automatic placement.** The compiler places control
itself; check the build log for `control plane:`:
- `dedicated shim col 0`: the partition had a spare column. Column 0 carries
  only the spine, and the mesh moved east.
- `free shim channels on col N`: control owns a free MM2S/S2MM pair on a data
  shim.
- `WARNING: no free shim MM2S/S2MM pair`: time-shared, and the park/release
  above applies.

A 4x4 GEMM in 4 columns fills all 8 shim MM2S (4 A + 4 B), so widen the
partition to `{0, HW_COLS, 0, 6}` to get a dedicated column. In exclusive or
dedicated placement, `host.cc` calls `__Runtime_ctrl_plan_set_exclusive`, and
park/`plan_release` are skipped. If such a build still stalls, check that
`routing.cc` does not use the spine column's ports 3/4 or control's shim
mux/demux port.

## 2. Batched ELF wedges with program memory empty

Not a coexistence problem: the high-throughput ELF send itself (TLAST-error disable
missing, or a zero-length packed BD). Diagnose it with skill
**control-kernel-packet-load** ("Failure signatures").

## 3. Top row's head climbs north into nothing

`acr_plan_chain_ex` gave *every* spine head a TRANSIT_N slot and a NORTH master.
On the topmost configured row there is no row above whose ingress slave was
armed, so that master stalls — and because CTRL/EAST/NORTH multicast the same
slot, the stall blocks the entire forward broadcast once the switch FIFOs fill.

The tell is a **partial** broadcast: it runs a few dozen packets, then wedges
(`ctrl_elf_dma stalled on access 19/108`), with program memory populated on the
lower rows and near-empty on the upper ones.

`acr_plan_chain_ex` now takes `is_top` and clears `is_spine_head` for it,
omitting both the transit-north slot and the NORTH master. This mirrors the
RET_NORTH omission already in `acr_plan_return_chain`. Locked in by
`test_ctrl_row_plan.cpp::test_top_head_no_north_climb`.

**Keep the two directions in sync:** any "is this the edge of the fabric?"
condition added to the return chain needs the same treatment on the forward
chain, and vice versa.

## Trace collides with the return spine

`#pragma aie_trace((0, 3), (STREAM, "s2mm", 1))` routes the trace stream out
(0,3) SOUTH master and through (0,2) NORTH slave — exactly the ports the
control-plane return spine (VRET) owns, and it programs them with arbiter 0
against the return chain's arbiter 1. The runtime trace resource-map does not
consult the control-plane reservation table, so it silently wins (it runs after
`plan_init`). Disable trace when the control plane is enabled, or move it off
the spine column.

## Diagnostics

`ctrl_path` run/stall/idle readings are only meaningful on tiles whose port event
selectors were configured — an all-zero `fwd[run=0 stall=0 idle=0]` row means
"not instrumented", not "idle". Prefer:

- `__Runtime_ctrl_pmap_enable(1)` for full port provenance, but note the
  ~180 `CONTROLPAN-PMAP` lines can overflow the serial console and drop the very
  log lines you need. Turn it off for the confirming run; its timing cost is in
  skill **profile-full-app-span**.
- `ctrl_elf pmem tile(c,r)` readback to see how far the broadcast got.
