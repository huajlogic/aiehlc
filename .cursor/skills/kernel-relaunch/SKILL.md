---
name: kernel-relaunch
description: Diagnoses a second (or later) launch of the same generated host function on one partition — e.g. a loop of matmul<<<mesh>>> in simplematmul_ctrl_pkt.cc — that hangs in wait_io, returns all-zero or partly wrong output, or looks hung on the board right after launch 1 prints PASS. Use when adding repeat launches for steady-state timing or when a relaunch result depends on how many buffers the app allocates.
---

# Relaunching a kernel group on the same partition

`host_canonicalized` redoes everything on every call (`ctrl_plan_init`, ELF
load, launch, shim-BD window). Launch 1 starts from partition init; every later
launch starts from whatever launch 1 left behind. Four separate problems showed
up; check them in this order.

## 1. The board harness stops at the first verdict

`script/test/appvek385.py` treats `PASS:`, `FAIL:`, `test end` and
`device_teardown done` as program end and halts the CPU. A per-launch
`verify_matmul` therefore "hangs" launch 2 (xsdb stops it inside
`XAie_DmaGetPendingBdCount`). Run every launch first, print `[FINAL_PERF]` per
launch, compare later outputs against launch 1 silently, and print the verdict
last (see `main()` in `simplematmul_ctrl_pkt.cc`, `MATMUL_LAUNCHES`).

## 2. Stale DMA-buffer map entries (lost control packets)

`__vaddr_to_mem_offset` resolves a buffer's device address from `s_alloc_map`
(first match wins). `__Runtime_free_buffer` must remove the entry
(`rt_alloc_map_remove`): otherwise the freed `XAie_MemInst` stays mapped, the
heap reuses its addresses for the next control packet, and the DMA reads it from
a dangling `mem->DevAddr`. Symptom: every core reads `Core_Status 0x00100000`
(done, not enabled, PC 0) and the locks keep launch 1's final values, while all
16 ELF acknowledgments came back. Whether it hits depends on the heap layout
(it failed with 3 launches, passed with 2 and 4). The map holds 64 live
buffers; a full map prints `alloc_buffer WARNING`.

## 3. Core-tile DMA channels keep running

The ping-pong BDs chain to each other (BD 1 -> 0 -> 1), so after launch 1 every
core-tile S2MM channel is still running (waiting on stream data) and every MM2S
channel waits on a lock. Reprogramming BDs/locks underneath gives garbage
(61k of 65k elements wrong). Fix: reset all core-tile DMA channels on reload.
- Control-packet load: the ELF payload carries it — `rt_cpe_reset_accesses`
  = core reset, 4 x `DMA_*_Ctrl <- Reset.Mask`, 4 x `<- 0`, core unreset
  (`aie_ctrlpkt_encode.c`, `rt_ctrl_elf_core_reset`). Free on launch 1, 24 words.
  `rt_cpe_dev` carries the DmaMod fields; the blob version is 2.
- MMIO load (`__Runtime_load_kernel_group_nt`): `rt_relaunch_dma_reset`, only
  after a group was loaded. It costs ~141k cycles (128 read-modify-writes); do
  not use it on the control-packet path.
- Never write the channel registers as a block: the start-queue registers sit
  between them (`ChIdxOffset` 8) and a write there pushes a BD.

## 4. AOT shim-BD window on a later launch

The shim-row route (and its return-route prefix) is set up once per fabric
(`g_sb.routed`). The table's segments are `[prefix][body]`, so a later window
has no prefix; `rt_sb_aot_shift` drops the prefix words (and shifts patches and
`seg_last`) when `g_sb.route_now` is 0. Before the fix every later launch logged
`table or return-route prefix mismatch at call 40; JIT`.

## Diagnostics

- `rt_wait_io_timeout_dump` prints core status, core-tile DMA channels, locks
  and shim DMA once at the first `wait_io TIMEOUT`.
- Decode channel status with `AIERT_DMA_*` masks (`aie_runtime_debug.h`):
  `0x00080012` = running + stream stall, `0x05080006` = running, lock-acquire
  stall, BD 5.
- Build with `--profiling`, or the `[FINAL_PERF]` counters read 0.

## Result (VEK385 Rev A, 4x4, KCO + shim_bd_ctrl + AOT)

Launch 1 0.194 ms, launches 2-3 0.155 ms each, outputs identical.
