---
name: aiehlcfastbuild
description: Rebuild an aiehlc app in seconds with `source script/aiehlc.sh ... --fast` -- skips the aie-rt/libxil rebuild when unchanged, reuses aiehlc's generated code when nothing it reads changed, caches the chess kernel build and the host objects. Use when iterating on an app (conv2dstem test_conv2d.cc: 100 s -> 1.6 s), when a --fast build unexpectedly rebuilds ("cache miss", "Compiling xaie"), when you suspect a stale --fast result, or when asked why xchesscc/xchessmk is slow.
---
<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# `aiehlc.sh --fast`

```bash
source script/aiehlc.sh --aie-version 5 --runtime-source-file <app>.cc --fast
```

Without `--fast` nothing changes: full console log, per-pass IR in `ir/`,
aie-rt/libxil rebuilt, chess every time, schedule view (verified: `main.elf`
byte-identical to the pre-change script).

## Where the 100 s go (conv2dstem test_conv2d.cc, cold)

| step | time | `--fast` |
|---|---|---|
| aie-rt + libxil rebuild (`build_hw_lib`) | ~25 s | skipped when `thirdparty/alib/lib/.aiehlc_hwlib.stamp` matches (`hw_lib_fingerprint`: aie-rt sources by **content**, BSP libs/headers by name/size/mtime, toolchain + flags) |
| aiehlc frontend + MLIR pipeline | ~1.9 s | reused when `frontend_cache_key` matches (binary, args, every file in the app dir, repo headers, hwlib fp); else run with `AIEHLC_NO_IR_DUMP=1`, log -> `aout/aiehlc.log` |
| xchesscc (16.5 s) + xlopt + xchessmk (48-51 s) | ~67 s | `.aiehlc/kernelcache/<key>` (kc.sh `kernel_cache_key`) |
| host objects | ~7 s | ccache (`.aiehlc/ccache`, BASEDIR=/, direct mode) |
| schedule view / raw-XAie debug view | <1 s | skipped |

Warm `--fast`: **1.6-1.7 s**, `main.elf` byte-identical to the cold build.

## Why chess is cached, not tuned

Measured: xchesscc has a ~3.2 s fixed start-up even for an empty file;
xchessmk spends 48-51 s on one translation unit whether or not `-g` is used,
and `+P 16` does not help (single TU). So an unchanged kernel must not be
recompiled. A changed kernel still pays chess (~65-160 s).

## Traps found while building it

* **aie-rt rewrites `driver/internal/*.h` on every build** (fresh mtimes): an
  mtime fingerprint never matches. Hash aie-rt by content (0.08 s).
* **`build_hw_lib` renames its `libxil.a` to `libxaienginea78.a`** -- there is no
  `alib/lib/libxil.a` afterwards; checking for it forces a rebuild every time.
* **The chess flags carry `-I<abs kernel dir>`** -- normalized in the key, else
  every working directory misses.
* **ccache across directories** needs `CCACHE_BASEDIR=/` + `CCACHE_NOHASHDIR`;
  generated `host_fixed.cc` / copied headers are "too new" for direct mode
  unless `CCACHE_SLOPPINESS=include_file_mtime,include_file_ctime,time_macros`.
* A semantically equivalent source edit (`v > 254 -> v = 255` vs `v > 255`) can
  produce a byte-identical kernel ELF: a "same ELF after an edit" is not proof
  of a stale cache. Test invalidation with a semantic change and compare against
  a default build of the same source (done: identical).

## Housekeeping

Caches never evict except ccache (5 GB). `rm -rf .aiehlc/kernelcache
.aiehlc/frontend` resets them; a default (non-fast) build is always a full
rebuild and is the reference when in doubt. Restored kernel debug artefacts
(`kernel.lst`, `.map`, `.linemap.json`) name the directory of the build that
populated the cache.
