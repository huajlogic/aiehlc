---
name: ctrlpkt-aot-elf
description: Ahead-of-time (AOT) control-packet creation for the kernel ELF and every other control-packet site (ctrl_plan_init return routes, core enable, lock-init group writes, shim-BD window). Use when working on #pragma control_packet_mode(aot), APIToControlPacketPass, the aiehlc_ctrlpkt tool, aie_ctrlpkt_encode.c, aie_runtime_xaie_seq.c, rt_aot_table / host_ctrlpkt.h, rt_ctrl_load_elf_aot, an AOT mismatch / JIT fallback or aot_fallbacks>0, or reading kernel_<fn>_ctrlpkt.h / host_ctrlpkt.h to debug what the host sends.
---

# AOT control packets

JIT (default) builds the kernel-ELF control packets in the runtime at load time.
`#pragma control_packet_mode(aot)` precomputes the compile-time part at build time
into `aout/worklocal/kernel_<fn>_ctrlpkt.h`, which `host.cc` includes; the runtime
only prepends the deferred return-route prefix. The same pragma also precomputes every
other control-packet site into `aout/worklocal/host_ctrlpkt.h` (see "All other sites").

## Kernel ELF

### What is fixed at compile time
The body = reset accesses (`rt_cpe_reset_accesses`: Core_Control reset, the four
core-tile `DMA_*_Ctrl` channel resets and unresets, Core_Control unreset) + PT_LOAD
segments (`ACR_ID_BCAST` broadcast writes) + final broadcast write-with-return. The
channel resets make a relaunch work (skill **kernel-relaunch**); blob version 2. The
deferred return-route writes (`fab->ret_bcast_off/val`, from `ctrl_plan_init`) stay a
runtime prefix. Wire layout matches JIT exactly: `[ret prefix][AOT body]`, one BD, one
TLAST.

### Pieces
- `src/mlir/runtime/aie_ctrlpkt_encode.{c,h}` — XAie-free encoder. `rt_cpe_encode_body`
  is the single body encoder; `rt_cpe_target`/`rt_cpe_count_pkts` resolve addresses;
  `rt_cpe_fingerprint` hashes device params + stream id. Shared by runtime and tool.
- `aie_ctrlpkt_devparams.h` — per-gen `rt_cpe_dev` table (Gen5 from
  `xaie2psgbl_reginit.c`). Only the offline tool uses it; the runtime fills
  `rt_cpe_dev` from the live `XAie_DevInst` (`rt_ctrl_cpe_dev`).
- `APIToControlPacketPass` (`pass/passapitocontrolpacket/`) — host path, after
  GroupRegWrite, gated on `routing.control_packet_mode==1` + control kernel ops.
  Tags `load_kernel_group`, publishes `routing.control_packet_{aot,nresp,stream_id}`.
- Host emission (tilinglinalg_pipeline.cpp, `__aie_launch` block) — writes
  `aout/worklocal/ctrlpkt_manifest.json`, emits `#include "kernel_<fn>_ctrlpkt.h"` and
  `__Runtime_ctrl_kernel_pkt_set(kernel_<fn>_ctrlpkt, sizeof ...)` next to
  `__Runtime_set_kernel_elf`. (The kernel name lives here, not in DfscheduleToApi.)
- `src/tool/ctrlpkt/aiehlc_ctrlpkt.c` — offline tool: manifest + ELF -> commented C
  header (`--out`), optional raw blob (`--out-bin`). Rebuilt with host `cc` every run.
- `kc.sh encode_aot_ctrlpkt` — runs the tool after the kernel ELF is built and writes
  the header into the worklocal dir (on the host include path, next to the sim host
  source). Nothing extra to link.
- Runtime `rt_ctrl_load_elf_aot` (aie_runtime.c) — validate header, prepend ret
  prefix, `memcpy` body, push. JIT and AOT share `rt_cpe_encode_body`.

### Reading kernel_<fn>_ctrlpkt.h
- Top comment: kernel, stream id, tile count, body size, and the PT_LOAD segments
  not sent (`.bss` = filesz 0, neighbour-tile data) with the reason.
- First 8 words: `rt_cpe_blob_hdr`, each field commented (not sent on the wire).
- Then one control access per line: stream header, control header ([19:0] tile
  address, [21:20] words-1, [23:22] op), data words, and `/* acc N @W: ... */` where
  N is the access index and W the word offset in the body (add the return-route
  prefix length to get the offset on the wire).
- Banners group accesses by the API they replace: `XAie_CoreReset`/`XAie_CoreUnreset`
  (`Core_Control`), `XAie_DmaChannelResetAll` (`DMA_S2MM/MM2S_<n>_Ctrl`),
  `XAie_LoadElfMem` per PT_LOAD (paddr, size, tile address), and
  the final write-with-return completion barrier.
- Segments are attributed by order, not address: chess ELFs have overlapping
  PT_LOAD ranges (PT_LOAD[0] is a reset vector at paddr 0 inside the full `.text` at
  PT_LOAD[5]), so an address lookup mislabels them. The tool warns on stderr if an
  access falls outside its attributed segment.

### Invariants / gotchas
- AOT is only attempted when `g_ctrl_high_throughput_ready` (HT mode). The sim and
  compatibility mode never try it — clean fallback, no blob needed.
- A fingerprint / `nresp` / stream-id mismatch prints one `ctrl_pkt AOT mismatch`
  line and falls back to JIT (safe). The fingerprint deliberately omits col/row;
  for a checkerboard device the runtime also checks `enc_tile` == loc.
- The blob is the body only; the runtime always rebuilds the ret prefix, so a blob
  stays valid across `ctrl_plan_init` return-route changes.
- `elf_fill` (`__Runtime_kload_fill_cycles`) isolates the JIT body encode inside
  `elf`; AOT drives it to 0. `[FINAL_PERF]` prints `ctrlpkt=aot|jit`.
- Device params must match aie-rt's CoreMod and core-tile DmaMod (`xaie2psgbl_reginit.c`:
  ProgMemSize/HostOffset, DataMemAddr/Size, CoreCtrl offset+reset mask, ChCtrlBase,
  ChIdxOffset, NumChannels, ChProp->Reset mask). If they
  drift, the fingerprint mismatches and AOT silently falls back — check the
  mismatch line for the two fingerprints.

### Verify
- Encoder unit test (x86): `bash src/mlir/runtime/unitest/build_ctrlpkt_encode.sh`.
- Header bytes: compile a two-line C program that includes the header and
  `fwrite`s `kernel_<fn>_ctrlpkt`, then `cmp` it with the tool's `--out-bin` output.
- Runtime cross-check: build with `-DAIEHLC_CTRLPKT_AOT_VERIFY`; the runtime
  re-encodes the body from the live ELF and `memcmp`s it against the blob.
- HW: build with and without the pragma; the AOT run must print `ctrlpkt=aot`,
  PASS, a lower `elf`/`kload`, and 0 `ctrl_pkt AOT mismatch` lines.

## All other sites (host_ctrlpkt.h)

`aout/worklocal/host_ctrlpkt.h` holds one `rt_aot_table`
(`src/mlir/runtime/aie_ctrlpkt_aot.h`) with the `ctrl_plan_init` return-route prefix,
core enable, lock-init group writes and every in-window shim-BD call. host.cc keeps
every API call and adds `__Runtime_ctrl_aot_register(&host_ctrlpkt_table)`.

### How it is built
- `APIToControlPacketPass` collect phase (before DfscheduleToApi): plan rows + group
  writes into module attrs (they become verbatim C later). Emit phase (after
  CoreTraceInsertPass): folded emitc call args -> `ctrlpkt_sites.txt`, one API call per
  line (tile from `XAie_TileLoc`, buffer = host arg + byte offset, `createio`->`startio`).
- `aiehlc_ctrlpkt --sites` (`src/tool/ctrlpkt/aiehlc_ctrlpkt_sites.c`, built by
  `script/build_ctrlpkt_tool.sh`) links an x86 aie-rt (`build/aiert_host/`, ~5 s,
  rebuilt only when missing). It sets up an `XAie_DevInst` for the partition, swaps in a
  recording backend, and runs the runtime's own code: `aie_runtime_xaie_seq.c` (BD
  descriptor, out-of-order channel, start queue, planner-op stream-switch call),
  `aie_runtime_control_plan.c` (planner), `aie_ctrlpkt_encode.c` (shim-row segments,
  return-route split, pktize).
- Runtime wrappers call the same `rt_seq_*` functions, so drift is not possible by
  construction. Keep new aie-rt calls in those wrappers inside `aie_runtime_xaie_seq.c`.

### Runtime matching
- Writes (`__Runtime_ctrl_row_broadcast_write` / `_write_ack`, including core enable):
  matched by content (kind, row, address, data, stream id).
- Shim-BD window: matched in order (kind, tile, BD/channel, dir, repeat; BDs also an
  FNV hash of all 19 int args). A matched call skips aie-rt and records its args +
  DDR address; commit checks the captured return-route prefix equals the table's,
  copies the segments and ORs addresses into BD words 1/2/8. Any mismatch replays the
  recorded calls through JIT capture (`rt_sb_aot_fail`) and continues JIT.
- Plan: when `ctrl_plan_init`'s inputs equal the table's (`rt_ctrl_ret_aot_match`), it
  skips the return-route capture + split and writes the table's MMIO list
  (`rt_ctrl_ret_aot_apply`). A VERIFY build cannot check this (nothing to compare);
  the ELF load's 16 acknowledgments returning over those routes is the check. The tool
  omits the plan entry if any row's capture would fail at run time (`g_plan_bad`).
- Shim-row prefix: at begin, copied from the table (`prefix_len` / `prefix_last`) when
  the window's columns match, instead of captured. Only the window that sets up the
  shim-row route carries it (`g_sb.route_now`); a later window (relaunch) drops the
  table's prefix words and shifts the patches and `seg_last` (`rt_sb_aot_shift`).
  See skill **kernel-relaunch**.
- Stats: `__Runtime_ctrl_shim_bd_ctrl_stats_print()` -> `aot_calls`, `aot_fallbacks`,
  `[CTRLPKT_AOT] writes_hit/miss plan_hit/miss plan_aot sb_prefix bd_calls bd_pre
  bd_take bd_post` (the last three split a matched BD call: prep / table match / rest).
- Wrapper cost: keep the matched path free of unused work. `__Runtime_dma_bd_config_multidim_ooo`
  must not do the allocation-map lookup on hardware (its address is the raw pointer),
  and `__vaddr_to_mem_offset` must not fetch a device address just for a log line;
  together they were ~3.3k cycles over 24 BD calls.

### Batched shim-BD window
- The emit phase batches the window only if it is self-contained: known call kinds on
  shim-row tiles in the fabric's columns, constant args, each descriptor used only by its
  `createio` and each `io` only by its `startio`, no other call inside. Otherwise the
  per-call path stays (e.g. the 1x1 example's core-tile `startio`). `#pragma aie_trace`
  host markers (`__Runtime_core_trace_*`) may stay inside the window
  (`isWindowHelper`); without that, a traced build silently profiles the per-call path.
- host.cc then has `__Runtime_ctrl_aot_window(dev, &fab, nbuf, bufs...)` at the commit point
  and `__Runtime_ioevent_make(tile, ch, bd, dir)` in place of each `startio`. The table's
  `host_ctrlpkt_win_calls` holds every call's full arguments; the runtime replays through
  the wrappers whenever the segments cannot be used (sim, no HT, mismatch, late prefix
  mismatch via `g_sb_win`). VERIFY takes the replay path and compares bytes.
- `[CTRLPKT_AOT] window_fast win_addr win_fast win_commit` split the window. Expect ~17k
  cycles to land on whatever follows `rt_sb_begin`: its route + BD pre-arm register writes
  draining. Moving work around it does not change wall time (MMIO is serialized).

### Gotchas (learned the hard way)
- `XAie_GetTileTypefromLoc` is the AIE1 helper (col%4 in {0,1} -> SHIMPL): on AIE2PS it
  calls NOC shims PL, which have no DmaMod. Use `dev->DevOps->GetTTypefromLoc`, as
  `XAie_DmaDescInit` does (`rt_seq_shim_bd_addr_fields`).
- The tool proves the address patch before using it: it encodes each BD at address 0
  and at a test address and requires the diff to be exactly
  `rt_seq_shim_bd_addr_fields` in words 1/2/8; otherwise the window stays JIT.
- `startio` returns the `ioevent` the waits use, so calls are never deleted from host.cc;
  a skipped BD call returns a zeroed `XAie_DmaDesc` (nothing reads `io.desc`).
- `script/sim/Makefile` has its own runtime object list: add every new runtime `.c`
  there too, or the sim `.so` loads with undefined symbols.
- VERIFY: `export EXTRA_DEFS=-DAIEHLC_CTRLPKT_AOT_VERIFY` before `aiehlc.sh`; the
  runtime runs JIT for every site and prints `ok`/`MISMATCH` per site. Its UART prints
  inflate `elf`/`coreen`; do not benchmark it.

## Debug dump (`aout/worklocal/ctrlpkt/`)
- Written on every AOT build (`kc.sh` passes `--debug-dir ./ctrlpkt` to both tool runs and
  clears the dir first). Start at `index.h` (includes every site, `ctrlpkt_dbg_sites[]`).
- Per site: `<name>.h` = `static const uint32_t ctrlpkt_<name>[]`, one access per line with
  `/* @offset id op Nw address: register / API */` (`!PARITY` on a bad parity bit) and a banner
  per runtime API call with its host.cc line; compiles with `-Wall -Wextra`.
  `raw/<name>.bin` raw words, `raw/<name>.ann` banners/comments by word offset (for tools).
- `kernel_<fn>_wire.h` = `plan_ret` + kernel body, the exact ELF-load BD when
  `plan_aot=1`. Shim segments mark the relaunch-only prefix and the patched address words;
  `shim_bd_calls.h` is the match table plus batched replay arguments; `plan_ret.h` also
  holds `ctrlpkt_plan_ret_mmio[]`.
- The C headers are byte-identical with or without `--debug-dir`. Listing code:
  `src/tool/ctrlpkt/ctrlpkt_dbg.{h,c}`; kernel annotations come from `walk_body` (one walk
  feeds both the header sink and the debug sink, so they cannot diverge).

## Regression examples
- `simplematmul_ctrl_pkt.cc` + `KERNELCONFIGOFFLOAD` + `control_plan_shim_bd_ctrl` +
  `control_packet_mode(aot)`: 4x4, 40 window calls, no lock-init writes.
- `simplematmul_ctrl_pkt_1x1.cc` (pragmas already in the file): 1x1, nresp=1, 3 lock-init
  writes, one shim-row segment, a 3-dimension BD, core-tile `startio` inside the window
  (must stay out of the table). Run it with VERIFY after any change to the pass, tool or
  runtime matching: all sites must print `ok` (JIT 0.150 / AOT 0.138 ms on Rev A).

## Expected results (Rev A VEK385, HT, PMAP off)
A healthy 4x4 AOT build (KCO + `control_plan_shim_bd_ctrl`, batched window) runs about
0.194 ms cold and 0.155 ms warm, with `elf_fill` 0, `aot_fallbacks=0` and no
`ctrl_pkt AOT mismatch` line; JIT is about 0.221 ms. VERIFY must be byte-identical with
and without KERNELCONFIGOFFLOAD.

## Benchmark and encoder-speed lessons
- Compare against the full fast build: without `control_plan_shim_bd_ctrl` the
  shim BDs go over MMIO and wall time is ~0.25 ms, which hides what AOT is worth.
  Check `bdcfg`/`startio`/`wait_io` match the configuration you think you built.
- The shared encoder must stay as fast as the old fill: use `__builtin_parity`, a
  hoisted constant stream header and a direct chunk writer in `cpe_seg`. A
  shift-fold parity loop plus a generic per-chunk writer cost ~7k cycles of
  `elf_fill`. The unit test only checks bytes, not speed — compare `elf_fill`.
