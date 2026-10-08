---
name: baremetal-partition-init-noop
description: Diagnose a baremetal board hang on the first AIE tile register access, where XAie_PartitionInitialize returns XAIE_OK but never enables column clock buffers. Use when a raw-XAie example stops producing output right after partition init, with no AIE ERROR and no crash.
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# Baremetal `XAie_PartitionInitialize` Is a No-Op Without `XAIE_PROD`

## Symptom

A raw-XAie baremetal app prints normally through device init, then stops dead at the
first call that touches an **AIE tile** register. No error, no exception, no further
output. The board must be reset.

```
[app]   . XAie_PartitionInitialize
[app]   . device ready
[app] --- test ... ---
[app]   . XAie_DmaTxnCountEnable      <-- last line, hangs here forever
```

Shim and NPI accesses before this point succeed, which is why init appears to work.

## Root cause

`XAie_PartitionInitialize` dispatches on `DevInst->IsProd`:

| `IsProd` | Handler |
|---|---|
| 1 (default) | `_XAie_BaremetalIO_PrivilegeInitPart` (`xaie_baremetal.c`) |
| 0 | `_XAie_PrivilegeInitPart` (`xaie_io_privilege.c`) |

`IsProd` **defaults to `XAIE_ENABLE`**, resolved inside `XAie_CfgInitialize`
(`xaiegbl.c`), so the baremetal handler is chosen unless you opt out.

That handler's entire body sits behind `#ifdef XAIE_PROD`:

```c
static AieRC _XAie_BaremetalIO_PrivilegeInitPart(XAie_DevInst *DevInst,
						 XAie_PartInitOpts *Opts)
{
#ifdef XAIE_PROD
	/* ... AIE_OPS_ENB_COL_CLK_BUFF, REQUEST_TILES, isolation ... */
#endif
	return XAIE_OK;
}
```

`script/aiehlc.sh` builds the baremetal driver library with
`-g -Wall -Wextra -Dversal -DARMA72_EL3 -fno-tree-loop-distribute-patterns` — no
`-DXAIE_PROD`. `script/setup.sh` also strips `-DXAIE_PROD` from the driver Makefiles.

So the function compiles to `return XAIE_OK;`. `AIE_OPS_ENB_COL_CLK_BUFF` and
`XAIE_BACKEND_OP_REQUEST_TILES` never run, **column clock buffers stay gated**, and the
first AIE tile register access issues an AXI transaction that never completes. The CPU
stalls with no diagnostic.

### Confirming it

1. Build warnings name the giveaway: `xaie_baremetal.c: warning: unused parameter
   'DevInst'` in `_XAie_BaremetalIO_PrivilegeInitPart`. The parameters are unused
   precisely because the body was compiled out.
2. Print a tag (with `fflush(stdout)`) before each driver call after partition init.
   The last tag printed is the first AIE tile access, and the app never returns from it.

## Fix

Call `XAie_SetXprodEnable(DevInst, XAIE_DISABLE)` after `XAie_InstDeclare` and
**before** `XAie_CfgInitialize` (it rejects an instance whose `IsReady` is set):

```c
	XAie_InstDeclare(DevInst, &ConfigPtr);

#ifndef __AIESIM__
	RC = XAie_SetXprodEnable(&DevInst, XAIE_DISABLE);
	if (RC != XAIE_OK) { /* handle */ }
#endif

	RC = XAie_CfgInitialize(&DevInst, &ConfigPtr);
	...
	RC = XAie_PartitionInitialize(&DevInst, NULL);
```

This takes the generic privileged path, which performs the real sequence: gate clocks,
assert column reset, `_XAie_PmSetPartitionClock(XAIE_ENABLE)`, release column reset.

The alternative — building the driver with `-DXAIE_PROD` — pulls in `XAie_PmInit` and
the xplm/PM flow, which needs board support that the aiehlc baremetal BSP does not wire up.

## Notes

- Applies to any raw-XAie baremetal app in `example/`, and to the aiehlc runtime's
  `__Runtime_partition_initialize`, which calls `XAie_PartitionInitialize(dev, NULL)`
  the same way.
- Under `--platform sim` the SIM backend is used and none of this applies, so guard the
  call with `#ifndef __AIESIM__`.
- `src/mlir/runtime/aie_runtime.c` already applies this workaround, so generated hosts
  are covered; it is raw-XAie examples that must opt out themselves.
- aie-rt has changed this default before (`0e34796e` made it `XAIE_DISABLE`, `94c8f71f`
  reverted it). Whenever `thirdparty/alib/aie-rt` is re-synced, check the `IsProd` note on
  `XAie_SetXprodEnable` in `xaiegbl.c` before dropping the explicit call.

## Rule

When a baremetal app hangs with no output, instrument every driver call with a tag print
plus `fflush(stdout)` before the call. The last tag printed names the stalling call, which
is the only way to localize an AXI stall — there is no fault, no return code, and no log.
