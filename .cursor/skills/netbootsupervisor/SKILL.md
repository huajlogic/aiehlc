---
name: netbootsupervisor
description: Working on src/tool/netboot (lwIP ELF supervisor on the baremetal A78, `apppaltest.py --netload`). Use when the supervisor dies or goes silent during LOAD_RUN, uploads crawl, the app core will not relaunch ("app core busy", PLM 0x7DB / 0x7D2 / "ERR XPm_ForcePowerdown: 0x2"), the watchdog fires right after launch, or when choosing memory for any second resident program on palmyra.
---

# netboot supervisor: board facts that are not in the design's assumptions

Design and status: `doc/design/lwip_elf_bootloader.md` (section 12). Usage:
`src/tool/netboot/README.md`.

## 1. `0x8_0000_0000` is NOT free memory on palmyra

"DDR_LOW1" mirrors the 2 GB DDR_LOW0. Proven with xsdb physical writes: a value
written at `0x8_0000_0000` reads back at `0x0`. A program linked there physically
sits under the app at `0x0`. Placing the app then overwrites that program's MMU
tables and code:
- `ESR_EL3 0x9600004A`: data abort, write, access-flag fault at level 2;
- then an `EC 0` (undefined instruction) loop inside the fault handler.

The supervisor therefore lives at `0x7800_0000` (top of DDR_LOW0), and the
loader refuses app `PT_LOAD`s that reach it. To check physical aliasing, use
xsdb on target 1/19/37 with `mwr -force`/`mrd -force`. The core target (20) goes
through that core's MMU.

## 2. `Xil_SetTlbAttributes` above 4 GB rewrites a whole 1 GB block

The GEM lwIP port makes `emac_bd_space` non-cacheable. In `.bss` above 4 GB that
turned the entire GB uncached, and uploads crawled until the client timed out.
Keep the BD ring alone in its own MMU block. Below 4 GB that block is 2 MB:
`.netboot_bd` at `0x7A00_0000`.

## 3. `p_memsz` includes the 1 GB `.heap` and `.stack`

The BSP `lscript` folds them into the one `PT_LOAD`. Copy `p_filesz` only, and
zero exactly the allocated `SHT_NOBITS` sections except `.heap`/`.stack`. Do not
rely on `crt0`: it skips BSS clearing when `APU_PWRCTL` reports a warm boot.

## 4. This PDI gives no way to stop a running app core

| call | PLM answer |
|---|---|
| `XPm_ForcePowerDown(PM_DEV_ACPU_0_1)` | `ERR XPm_ForcePowerdown: 0x2` |
| `XPm_ResetAssert(PM_RST_APU0_CORE1_WARM/COLD)` | `0x7D2` `XPM_PM_NO_ACCESS` (even after `XPm_RequestNode`) |
| `XPm_ReleaseNode` | returns success, core keeps running (do not use) |
| `XPm_RequestWakeUp` on a running core | `0x7DB` `XPM_ERR_WAKEUP` |

So `STATUS` says `app core busy` after any run, and `apppaltest --netload`
re-bootstraps the supervisor (`device program` frees core 1). Only a BOOT.BIN
subsystem-permission change lifts this.

## 5. Watchdog firing a few ms into every run was OUR bug

The main loop sampled `now` before `server_poll()` launched the run, so
`now - run_start_ms` underflowed. `watchdog()` reads its own clock. It is not
the system counter: switching to `PMCCNTR_EL0` changed nothing.

## Debugging rules that paid off

- A silent death needs a fault handler that prints `ESR/FAR/ELR/SP` with fixed
  label strings. The BSP handler's data argument is not reliably yours.
- Trace with prints first, then remove them: anything the supervisor prints
  after the wake interleaves with the app's output on the shared UART.
- The board is shared. Another user's `device program` / `rst -proc` kills the
  supervisor, so get exclusive use before chasing a "hang".
