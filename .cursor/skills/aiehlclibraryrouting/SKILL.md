---
name: aiehlclibraryrouting
description: An aiehlc library (`lib<app>.a`, source without main()) linked into your own ELF hangs on the first launch (`wait_io TIMEOUT`, or `routing_init: no routing() linked`), although the archive contains `routing.o`; `nm` shows `w _Z7routingP12XAie_DevInst` in host.o and the routing symbol is missing from the ELF; an old link line carries `-Wl,--undefined=_Z7routingP12XAie_DevInst`.
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# aiehlc library mode: routing.o was never pulled from lib<app>.a

## Symptom
A user program links an aiehlc library archive (`hostcompile.sh` library mode, skill
**hostlibrarymode**) and calls its entry. It builds and links cleanly, but the first launch hangs
-- the stream switches were never programmed. `aarch64-none-elf-nm <app>.elf | grep routingP12`
prints nothing.

## Cause
The generated `host.cc` declares the library's stream-switch setup **weak**:

    void routing(XAie_DevInst *dev) __attribute__((weak));   // aiehlc.cc / tilinglinalg_pipeline.cpp

(weak so a host-only build without routing.cc still links; the runtime's own reference in
`aie_runtime.c` is weak too). `aieArray::partition` passes `routing` to
`__Runtime_init_mesh_partition_with`. A **weak undefined reference never pulls an archive member**,
so `ld` took `host.o` from `lib<app>.a` but not `routing.o`; `routing` resolved to NULL and the
partition came up with no routes. `aiekernel`'s isolate step (`ld -r` of the own objects) happened to
hide this for TVM offloads; an archive linked directly (Qwen: `src/aietensorop/qwen/`) hit it.

## Fix (in the tree)
`script/hostcompile.sh`, library branch: when routing.cc exists, `ld -r host.o routing.o ->
.libmerge/host.o` and archive that as the `host.o` member (no separate `routing.o`). The weak
reference resolves inside one object, so pulling host.o brings `routing` along. The archive cache
key went `hca1` -> `hca2`, so an old unmerged archive is not served from `~/.cache`.

Check an archive:

    aarch64-none-elf-ar p lib<app>.a host.o > /tmp/h.o && aarch64-none-elf-nm /tmp/h.o | grep routingP12
    # want:  T _Z7routingP12XAie_DevInst      (w = an archive from before the fix: rebuild it)

## Old workaround
`-Wl,--undefined=_Z7routingP12XAie_DevInst` on the consumer's link forced the member in. It is no
longer needed for a rebuilt library; drop it (it is harmless but hides a stale archive).

Verified 2026-11-27 on palmyra-14: Qwen 9B ELF linked without `--undefined`, 17,462 AIE launches,
6.52 tok/s decode. Related: **hostlibrarymode**, **multiaiehlclibrary**.
