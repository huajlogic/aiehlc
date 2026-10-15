# netboot: resident lwIP supervisor for the baremetal A78

Implements mode D of [doc/design/lwip_elf_bootloader.md](../../../doc/design/lwip_elf_bootloader.md).
A supervisor stays resident on **A78 core 0** at the top of DDR (`0x7800_0000`;
`0x8_0000_0000` mirrors `0x0` on this board, see design section 12). It receives an ELF
over TCP and runs it on **core 1** through the PLM, with a watchdog. The app's
console output stays on the board UART (com0) and is collected by
`apppaltest.py --netload` exactly as in the JTAG flow.

```
src/tool/netboot/
  build.sh              builds lwIP 2.2 + Xilinx GEM port for the A78 SDT BSP, then netboot.elf
  netboot_proto.h       wire protocol (64 B request, 48 B reply + text)
  netload.py            host client: load | rerun | kill | status (stdlib only, runs on PALIP)
  lwip/                 lwipopts.h, xlwipconfig.h, xtopology_g.c (what the Vitis BSP flow would generate)
  supervisor/
    main.c              lwIP init (static IP), poll loop, timers, watchdog, launch/kill
    server.c            TCP protocol on lwIP RAW; work runs from the main loop, not callbacks
    elfload.c           ELF64/AArch64 checks, PT_LOAD placement into DDR_LOW0, cache clean
    apu.c               app core via xilpm: XPm_RequestWakeUp / XPm_ForcePowerDown on PM_DEV_ACPU_0_1
    sha256.c            upload integrity check
```

lwIP follows the aiebaremetal `example_lwip_echo` reference: RAW API, `NO_SYS`,
polled `xemacif_input`. It is compiled from the Vitis embeddedsw sources
against this repo's A78 BSP, because the reference's `libxtflwipall.a` is an
xsct-generated A72 / Versal-Gen1 build.

## Build

```bash
src/tool/netboot/build.sh                       # -> src/tool/netboot/build/netboot.elf
NETBOOT_IP=10.10.70.50 NETBOOT_GW=10.10.70.101 src/tool/netboot/build.sh
```

The supervisor occupies `0x7800_0000..0x7A20_0000` (image, then the GEM BD ring
alone in its 2 MB MMU block at `0x7A00_0000`) and stages uploads at
`0x7A20_0000..0x7FFF_FFFF`. It refuses an app `PT_LOAD` reaching `0x7800_0000`.

The default IP sits on the lab board segment that `PALIP` serves on `eth1`
(10.10.70.0/24, dhcpd range .1-.5), outside the DHCP range. The build refuses a
supervisor image outside `0x7800_0000..0x7A20_0000`.

## Run

```bash
python3 script/test/apppaltest.py -y -nonreboot --netload aout/main.elf
```

1. stages `netload.py` and `netboot.elf` on `PALIP`, opens com0;
2. `netload.py status`. If nothing answers, loads the supervisor once over JTAG
   and waits for `[netboot] ready` on the console;
3. `netload.py load <elf>`: transfer, SHA-256 check, place, start on core 1;
4. collects the console until `device_teardown done` / `Not tearing down partition`,
   exactly like the JTAG flow;
5. leaves the board up with the supervisor resident.

**On the palmyra BOOT.BIN every run re-bootstraps.** The PDI does not let the
supervisor stop core 1 once an app has run on it (design section 12, item 4), so
`status` reports `app core busy` and `apppaltest` reloads the 200 KB supervisor
over JTAG first. That reset frees core 1. It costs ~40 s per run, against ~150 s
to `dow` the 15 MB ResNet ELF. With a PDI that grants core-1 reset permission,
the `apu.c` kill chain takes over and runs skip JTAG entirely.

**When `device program` happens.** A bootstrap is the full JTAG sequence:
`device program BOOT.BIN` (waited on until it reports success, then a 5 s PLM
settle), then `tar 20`, `rst -proc`, `dow -force netboot.elf`, `con`. Each step is
confirmed by its own completion token, not by an `xsdb%` prompt, which rlwrap
echoes twice. When a resident supervisor is **reused** (it answers with
`app core free`), nothing is reprogrammed and PL/AIE state carries over from the
previous run. Pass `--netload-bootstrap` to force a fresh PDI program.

Flags: `--netload-bootstrap` forces a supervisor reload (use it after rebuilding
`netboot.elf`); `--netload-ip IP`; `--netload-timeout-ms N` sets the board-side
watchdog.

By hand, on `PALIP`:

```bash
python3 ~/aiehlc/netboot/netload.py status
python3 ~/aiehlc/netboot/netload.py load ~/aiehlc/main.elf --timeout-ms 600000
python3 ~/aiehlc/netboot/netload.py rerun     # same image again, no transfer   (needs a free app core)
python3 ~/aiehlc/netboot/netload.py kill      # stop the app core               (refused by the palmyra PDI)
```

## Console lines from the supervisor

The supervisor prints nothing after it wakes the app core (except watchdog or
fault events), so the collected log is the app's own output:

```
[netboot] ready: 10.10.70.50 port 5155
[netboot] LOAD_RUN 15411872 B received in 200 ms, sha256 ok
[netboot] run 1: placed 13234248 bytes, zeroed 31436417 bss bytes, entry 0x0, start app core at 0x0 (watchdog 600000 ms)
resnet18: init                       <- from here on: the app on core 1
...
resnet18: top1 class=258 logit=12.017338
  inference    1270.868 ms   <- graph_run()
device_teardown done
```

On a fault the supervisor prints `[netboot] FATAL ...: ESR_EL3 .. FAR_EL3 .. ELR_EL3 ..`
instead of hanging silently.
