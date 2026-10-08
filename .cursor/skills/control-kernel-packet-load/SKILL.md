---
name: control-kernel-packet-load
description: Diagnoses and verifies pragma-enabled AIE2PS kernel ELF loading and core launch over the reserved row-control packet fabric. Use when control kernel loading stalls, returns missing acknowledgments, leaves program memory empty, or the launched core does not run.
---

# Control-packet kernel loading

## Required sequence

1. Materialize `__Runtime_ctrl_plan_init` before `load_kernel_group`. In
   high-throughput mode plan init leaves the uniform core-tile return-route
   writes pending (`ret_bcast_pending`); the packed ELF payload carries them
   first, ahead of the reset. A response-expecting send before the load writes
   them over MMIO (`rt_ctrl_ret_flush_mmio`).
2. Reset the cores with two accesses at the front of the ELF payload
   (`rt_ctrl_elf_core_reset`): whole-register `Core_Control` writes of
   `CtrlRst.Mask`, then 0. On AIE2PS the register has only enable and reset,
   so this matches disable + reset + unreset without 96 serial MMIO accesses.
   Unreset must land before the first program-memory word (see the first
   failure signature), and the core stays disabled until launch.
3. Translate ELF program addresses to
   `CoreMod->ProgMemHostOffset + p_paddr`. Translate local data memory to
   `p_paddr & (DataMemSize - 1)`.
4. Reject ELF data sections whose core-view address maps to a neighboring tile.
5. Pktize ELF PT_LOAD bytes as 4-word broadcast writes, skipping `.bss` and
   neighbor-tile data. On AIE2PS, call
   `__Runtime_ctrl_high_throughput_enable(1)` before device initialization:
   partition init disables CTRL TLAST errors and all self-delimiting accesses
   are packed into one shim MM2S BD with one final TLAST. Compatibility mode
   uses one BD/TLAST per access and cycles four BD ids. In high-throughput
   mode the final write-with-return is the payload's last access, broadcast,
   so all `nresp` fabric tiles answer into one S2MM BD (BD 12, `nresp` words,
   FoT disabled; each response is one kept header word). Compatibility mode
   keeps a separate whole-row ACK packet drained in waves of 3 on BDs 12–14.
6. Enable cores with one broadcast write of `CoreMod->CoreCtrl->CtrlEn.Mask`.

## DMA response allocation

For large request buffers, do not allocate the one-word ACK landing buffer as a
second DMA object. AIE2PS can assign that object an address rejected by
`XAie_DmaSetAddrLen`. Allocate request and response storage together and place
the response at a 16-byte-aligned word offset after the request capacity.

The completion barrier is the shim S2MM BD drain. Do not require the kept ACK
header to be cache-visible.

## Failure signatures

- ACK never drains on the first ELF write: core is still held in reset
  (`Core_Control` resets to `0x2`; the unreset access is missing or placed
  after the ELF words).
- `Invalid buffer starting Address`: request and ACK use separate DMA objects.
- ACKs drain but program memory remains zero: wrong PM address translation,
  high-throughput packing without `XAIE_PART_INIT_OPT_CTRL_TLASTERROR_DISABLE`
  applied (clock-control 0x60000 bit 4 still set), or a zero-length packed BD
  (`rt_ctrl_elf_fill` did not set `*payload_words_out`). The last case loads in
  about 80k cycles and "succeeds", because only the separate final ACK packet
  is sent. Check what went out before blaming the board or PDI: a temporary
  `__Runtime_ctrl_push(..., log=1)` on the high-throughput push prints `len=`
  (remove it again; see skill **profile-full-app-span** for what `log=1` costs).
- Core control reads `1` but output DMA times out: verify ELF program memory
  before changing launch.
- HT ELF ACK times out with program memory populated, or a pre-load
  `row_write_ack` / `row_read` never drains: the deferred return route never
  reached the tiles. Check that `rt_ctrl_elf_ret_config` ran (payload starts
  with `ret_bcast_n` one-word writes) or that the send hit
  `rt_ctrl_ret_flush_mmio`.

## Verification

Build `example/tileprogram/ccode/simplematmul_ctrl_pkt.cc` for AIE generation 5
(`--platform baremetal --profiling`). Confirm the generated `aout/worklocal/host.cc`
calls the `*_ctrl` load and launch variants (`__Runtime_load_kernel_group_16t_ctrl`,
`__Runtime_launch_kernel_group_ctrl`) only when `#pragma control_plan_op_control_packet`
is present. On VEK385 (skill **vek385-board-benchmark**), require:

```text
[FINAL_PERF] wall_ms=... ctrlpkt=... elf=<tens of thousands, not ~80k with a timeout> ...
[RELAUNCH] launch=2 differs_from_launch1=0 of 65536
PASS: all 65536 elements match.
```
