---
name: kobjctrlpktheader
description: Host compile fails `fatal error: host_ctrlpkt.h: No such file or directory` right after `[hostcompile] KOBJ cache hit` on a control_packet_mode(aot) build -- the single-kernel ctrl-packet files were not stored in the kernel object cache
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# KOBJ cache hit without `host_ctrlpkt.h`

## Symptom

A build with `#pragma control_packet_mode(aot)` (AOT control packets) fails in the host compile:

```
[hostcompile] KOBJ cache hit gemm_ka (3fd8...)
.../aout/worklocal/build/host_fixed.cc:629:10: fatal error: host_ctrlpkt.h: No such file or directory
```

The first build of the same source passed (a cache miss: `kc.sh` ran and wrote the header); every later
build with the same key fails. Seen on `example/tileprogram/ccode/gemm_plan/step3..7_*.cc`.

## Cause

`kc.sh` writes the AOT files into its cwd. On the **multi-kernel** path they carry the kernel name
(`host_ctrlpkt_<f>.h`, `kernel_<f>_ctrlpkt.h`, `ctrlpkt_<f>/`); on the **single-kernel** path the host
sites header and debug dump are **unsuffixed** (`host_ctrlpkt.h`, `ctrlpkt/`). `kobj_cache_put` stored only
the suffixed names, so a hit restored `kernel.o` + the kernel ELF but not `host_ctrlpkt.h`, which the
generated `host.cc` `#include`s.

## Fix (`script/hostcompile.sh`)

The two single-kernel call sites run `KOBJ_SINGLE_KERNEL=1 compile_one_kernel ...`; `kobj_cache_put`
then also stores `./host_ctrlpkt.h` and `./ctrlpkt`. `kobj_cache_get` restores everything under the
entry's `cwd/` already. Copying the host header is valid because the key hashes `host.cc` and
`ctrlpkt_sites.txt` whenever the sites file exists. Changing `hostcompile.sh` changes every key (the
script's own hash is in it), so old entries without the header are never hit again.

## Workaround on an old tree

`AIEHLC_KOBJ_CACHE=off` or `HOSTCOMPILE_KERNEL_REBUILD=1`.
