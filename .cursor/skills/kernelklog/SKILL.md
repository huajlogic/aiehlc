---
name: kernelklog
description: Printing values from inside an AIE kernel with klog (kernel_log.h). Use when a kernel needs a debug print, when klog output never appears on the console, or when someone writes a printf-style `aie::print_log(...)` (it does not exist).
---

# Kernel logging with klog

## API (the only one)

`src/mlir/runtime/kernel_log.h`, force-included into every kernel by `kc.sh`:

```cpp
klog("TAG4", int32_value);   // 4-char tag (shorter is null-padded) + ONE int32
```

No format strings, no `aie::print_log`, no host-side call needed. The generated
kernel `main()` already calls `klog_init()` (`passdfscheduletokernelapi.cpp`).
Storage: last 2 KB of core DM (offset `0xF800`), max 255 entries, then silently dropped
-- don't klog inside hot loops.

## Switches

| Pragma | What the console shows after the launch |
|---|---|
| `#pragma aie_debug_level(AIE_KERNEL_CONFIG_TRACE)` | **klog only**: `[kernel_log] ===== Kernel Log ... =====` + per-core entries |
| `... \| AIE_KERNEL_CONFIG_TRACE \| AIE_DEBUG_LOG` | full runtime log + `AieRt_DebugSnapshot`, klog inside it |
| neither | nothing -- klog() compiled out |

- `AIE_KERNEL_CONFIG_TRACE` (1<<10): aiehlc writes `aout/kernel_build_flags.sh`
  (`AIEHLC_KERNEL_LOG=1`) → kc.sh adds `-DKERNEL_LOG_ENABLED` (+ `-DKERNELCONFIGOFFLOAD_TRACE`).
  The runtime sees the same bit as `AIEHLC_KLOG_ENABLED()`
  (`AIE_DEBUG_FLAG_KERNEL_CONFIG_TRACE`, `aie_runtime.h`).
- Generated `host.cc` (`DfscheduleToApiPass::emitKernelLogVerbatim`) ends with
  `if (AIEHLC_KLOG_ENABLED() && !AIEHLC_LOG_ENABLED()) __Runtime_read_kernel_logs(dev, cols, rows, n)`
  over the launched core tiles; the `AIE_DEBUG_LOG` snapshot covers the other case.
- Verbosity bits 0-3 and flags like `AIE_DMA_ISSUE_COUNT` print their own logs; leave
  them out for a klog-only console. Errors always print.
- `__Runtime_read_kernel_log(dev, tile)` prints unconditionally (calling it is the request).

## Verify before a board run

- aiehlc log: `Detected #pragma aie_debug_level N` with bit 1024 set
  (not shown → stale aiehlc binary, skill **stalepragmabinary**)
- `cat aout/kernel_build_flags.sh` → `AIEHLC_KERNEL_LOG=1`
- `grep klog aout/worklocal/conv2d_spatial.cc` (your calls) and `kernel.cc` (`klog_init`)
- `grep -A4 'Kernel klog only' aout/worklocal/host.cc` (needs an aiehlc built after this change, skill **stalepragmabinary**)

## Trap: build run outside the repo root -> no klog at all

`aiehlc.sh` writes `aout/` in its CWD, and `kc.sh` used to read the switch
only from `${AIEHLC_ROOT_DIR}/aout/kernel_build_flags.sh` (the repo's). A build
in a scratch dir got `AIEHLC_KERNEL_LOG=1` in its own `aout/` and was compiled
without `-DKERNEL_LOG_ENABLED`: the console printed `no log (write_index=0)`
for every tile. Fixed: kc.sh reads `${WORKLOCAL_DIR}/../kernel_build_flags.sh`
(hostcompile.sh always sets it), the repo root only when run by hand. Check:
`grep -c KERNEL_LOG_ENABLED build.log` > 0. Override: `AIEHLC_KERNEL_LOG=1`.

## Trap

Kernel locals must be declared before the klog that reads them; host variables
(`mesh`, `device`) are not visible in the `__global__` body.
