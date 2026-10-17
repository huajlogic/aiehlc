---
name: hosttimelinedistortion
description: Host-side per-op timing on the A78 baremetal board looks far too slow (whisper encoder 172 ms instead of ~34 ms) once timestamps are printed; or MMIO looks tunable via memory type (Device-nGnRE, Normal-NC). printf over UART inside the timed region; MMIO write cost is fixed.
---

# Measuring host time on the baremetal board

## printf distorts the timeline
`printf` to the console is synchronous UART: one line costs ~1 ms. Printing a
timestamp per op inside the timed region multiplied the whisper encoder from
33.7 ms to 172 ms and moved every gap. Buffer the events and print after:
`eng/we_host.h` `WE_TL` — `WE_EV(tag)` stores `(XTime, tag)` into a static array,
`we_tl_print()` dumps it after the run (host.cc prints it on run 2). Build with
`HDEFS=WE_TL`.

## MMIO cost does not depend on the page type
Probe `src/aietensorop/whisperengine/m7`: re-typing the AIE aperture
(`Xil_SetTlbAttributes`) as Device-nGnRE (posted) instead of nGnRnE gave the same
~350 ns per `XAie_Write32`; Normal non-cacheable **hung** the board. Per-op
register writes can only be hidden (overlap with the running op, BD shadow cache
writing only changed words), not made cheaper. Ctrl-packet shim BDs
(`WE_CTRL`) gave no net gain either: each batch pays the packet round-trip latency.
See also `doc/performance/register_write_cost.md`.

## Reads are as expensive as writes
`XAie_DmaUpdateBdAddr` is a `XAie_MaskWrite32` (read + write); the AIE2PS shim
version does one Write32 and two MaskWrite32, i.e. two ~400 ns reads. whisperengine
keeps a shadow of every BD's register words (`DmaMod->WriteBdPrep` encodes them
without writing). It writes only the changed words with plain `XAie_Write32`
(`we_bd_put`). That took the encoder from 32.6 to 30.6 ms.

## DDR, not MMIO, is the end of the line
Probe m4: one shim channel reads ~6 GB/s, but any channel/shim mix saturates at
~10.5 GB/s read, ~10 GB/s write and ~8 GB/s mixed. Adding shim columns does not add
bandwidth.
