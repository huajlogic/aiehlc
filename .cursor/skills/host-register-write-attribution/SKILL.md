---
name: host-register-write-attribution
description: Attributes host-side time in AIEHLC runtime paths that issue many XAie register writes (control-packet ELF load, shim BD/return arming, ctrl_plan_init, bdcfg). Use when a PMU breakdown shows one cheap-looking XAie call (a channel enable, a FoT write, the next push) costing thousands of cycles, when that cost moves when calls are reordered, or before optimizing a host phase by reordering calls.
---

# Attributing host register-write cost

## The trap

Device register writes do not stall the A78 at the store. A whole shim BD
(8 words) measured ~130 cycles between two `pmccntr_el0` reads. The writes
drain over the NoC at roughly the documented ~372 ns each
(`doc/performance/register_write_cost.md`), and the CPU pays the backlog at
the **next device read**, e.g. the read half of an `XAie_MaskWrite32`, a
`XAie_DmaGetChannelStatus` poll or `XAie_DmaGetPendingBdCount`.

Symptoms seen on the ELF load:

- The S2MM `XAie_DmaChannelEnable` (read-modify-write) took 8.1k cycles the
  first time, after ~28 BD/queue writes, and 62 cycles the second time.
- Moving the return-BD arming earlier moved a ~15k "stall" from the ACK push
  into the arming. The cost follows the writes, not the call.

## How to measure

1. Put `pmccntr_el0` markers around whole steps, not single writes. A tiny
   ring of `{label, cycles}` entries printed once after the step is enough;
   remove it before measuring wall time (the print lands inside `kload`).
2. Count register writes per step. Estimate time as roughly writes x ~370 ns,
   plus reads, plus polls that really wait on the hardware.
3. Treat a poll that follows a DMA push as transfer time, not overhead.

## What actually helps

- **Fewer writes.** Examples: fold a separate send into an existing BD (the
  ELF ACK became the payload's last access), use one BD with FoT disabled for
  N fixed-size responses instead of N FoT BDs, and skip idempotent re-arming
  (routes, FoT, channel enables) when state is known.
- **Moving writes around does not help** unless it overlaps them with real
  hardware work (DMA transfer, core compute).
- **CPU work overlaps posted writes.** Place necessary CPU work right after a
  burst of writes, not after the last one. `ctrl_plan_init`'s return-route
  capture cost 80.3k cycles when it ran at the end and 74.1k when it ran after
  each row's MMIO emission. Before the change, the last writes of plan init
  showed up as ~10k extra cycles in `kload`.
- Pure CPU loops (packing) are separate: measure them with no device access
  inside the timed region.

## Capturing driver writes without writing

To learn what (offset, value) an `XAie_*` call would write, e.g. to send it as a
control packet, do **not** use `XAie_StartTransaction`: it callocs a
1024-command buffer (17.5k cycles measured), more than the writes it replaces.
Swap `DevInst->Backend` for a copy whose `Ops.Write32` records the write, run
the calls, and restore it (`rt_ctrl_ret_capture_row` in `aie_runtime.c`). Make
`MaskWrite32` / `BlockWrite32` fail in the copy so an unexpected op falls back
to MMIO instead of silently reaching hardware. Only valid with no transaction
open (`DevInst->TxnList.Next == NULL`), since `XAie_Write32` checks that list
before calling the backend.

## Reference numbers (ELF load, 474 accesses / 2,829 words)

| Step | Before | After |
|------|-------:|------:|
| Pack on ARM | 29.0k | 14.3k (`rt_ctrl_elf_fill_seg_packed`) |
| Shim DMA handshake | 55.9k | ~28.5k (broadcast ACK in payload, 1 return BD) |
| ELF load total | 88.6k | 51.3k |
