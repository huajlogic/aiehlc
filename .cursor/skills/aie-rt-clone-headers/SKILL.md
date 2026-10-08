---
name: aie-rt-clone-headers
description: >-
  Fixes tutorial or raw-XAie compiles that fail with unknown XAie_RoutingInstance
  or XAie_InitRoutingHandler when aiehlc uses Vitis aie-codegen headers. Use when
  the sim-tutorial Action fails on those symbols, or when setup.sh has deleted
  the aie-rt clone.
---

# aie-rt clone headers

`XAie_RoutingInstance`, `XAie_InitRoutingHandler`, `XAie_MoveDataExternal2Aie`, and `XAie_RouteDmaWait` come from the aie-rt clone, not from Vitis.

Vitis `aietools/include/drivers/aiengine/xaiengine.h` only includes `aie_codegen.h`. That umbrella does not include `aie_codegen_inc/xaie_routing.h`, and the codegen routing header does not declare `XAie_MoveDataExternal2Aie`.

`script/aiehlc.sh` uses `thirdparty/alib/include` when `thirdparty/alib/include/xaiengine` is non-empty. Those headers are produced by:

```bash
cd thirdparty/alib/aie-rt/driver/src
make -f Makefile.Linux include INCLUDEDIR=../../../include INTERNALDIR=../../../internal
```

Default `source script/setup.sh` must clone aie-rt (`main-aie`) and run that install. Do not delete `thirdparty/alib/aie-rt` on the BSP path, and do not point the front end at the Vitis aie-codegen include to "fix" the missing type.

Override the clone URL with `AIE_RT_REPO`. `--bsp-use-git-repo=<url>` still skips BSP generation and clones that URL instead.
