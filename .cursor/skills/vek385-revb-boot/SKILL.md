---
name: vek385-revb-boot
description: Runs an AIEHLC app on a VEK385 Rev B board with script/test/appvek385.py, which must program the boot PDI and then the PLD PDI back to back (Rev A uses one PDI). Use when targeting a Rev B VEK385, when a Rev B board boots with PS but no AIE/PL, or when comparing Rev A and Rev B timings.
---

# VEK385 Rev B boot

Rev B boards run a segmented-configuration platform: the boot image is split into a
boot PDI (PLM, PS, NoC) and a PLD PDI (PL + AIE), and both must be programmed, in that
order, before the PS POR wait. Rev A boots from a single PDI.

## Run

```bash
USERNAME=<you> VEK385IP=<board> python3 script/test/appvek385.py -y <elf> --board-rev b
```

- `--board-rev b` (or `VEK385_REV=b`, which also works from a debug UI `hw_env`) programs
  `$VEK385_BOOT_PDI`, then `$VEK385_PLD_PDI`. Rev A programs `$VEK385PDI`.
- Defaults (paths on the board host): `/home/$USERNAME/aiehlc/vek385.pdi` (Rev A) and
  `/home/$USERNAME/aiehlc/vek385revb_{boot,pld}.pdi` (Rev B). Override with the env vars.
- `--stage-pdi [DIR]` first copies `*_boot.pdi` / `*_pld.pdi` from a local DIR over the
  Rev B paths; only needed when the PDIs change. Put the ELF **before** `--stage-pdi`:
  the flag takes an optional DIR and would swallow a following ELF path.
- Each `device program` waits for a `PDIRES_OK` / `PDIRES_FAIL: <msg>` marker and fails fast
  on `PLM stalled`. A missing PLD PDI would otherwise leave a board with PS up but no AIE.
  UART and other harness behaviour: skill **vek385-board-benchmark**.

## Timing across revisions

The same ELF runs on both revisions with no rebuild. Rev B is faster on it (4x4 AOT
GEMM: 0.155 / 0.125 ms vs 0.195 / 0.155 ms on Rev A; CPU scalar matmul 25.9 vs 36.7 ms)
because its APU is clocked about 1.4x higher, so PMU cycle counts go *up* while wall
time goes down. Compare across revisions in wall time, and keep Rev B numbers out of
the Rev A benchmark tables.
