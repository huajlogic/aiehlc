<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: aieoffloadaiegraph
description: "`run_test.sh` check 3 fails with `none of the N matching layer folder(s) has a non-empty aie/ subdirectory`; `--aiegraph` lifts 0 convs / partition says `non-4D shapes; not a conv2d` under int8; deciding whether `--aie-offload` may change `layers/` vs `layers-golden/`."
---

# `--aie-offload` → aiegraph → `layers/NN/aie/`

## Symptoms

```
[aie ] FAIL -- none of the 19 matching layer folder(s) has a non-empty aie/ subdirectory
[aie-byoc] 1/4 fuse  : nothing ... 0/20 convs fused
```

## Two causes, both needed

1. **BYOC writes no per-layer folder.** It only swaps the call inside
   `resnet18.c`, and under the int8 default it fuses nothing anyway. Only the
   aiegraph path (`aiegraph_partition._offload` → `run_aie_pipeline`) writes
   `layers/NN_op/aie/`. So `deploy_flow.run()` now runs the aiegraph lift when
   `aiegraph or aie_offload`, over the same `--aie-layers`.
2. **aiegraph lifted 0 convs under int8.** `aiegraph_partition._conv_geometry`
   read 4-D only, while the int8 graph is NCHWc (5-D maps, 6-D weights). It now
   delegates the 5-D case to `aie_offload._layer_geometry` (skill:
   nchwclayoutfold). Result: 20 `aiegraph.conv_bn` ops. Layer 1 gives
   `H=230 W=230 Cin=3 Cout=64 K=7 stride=2` (pre-padded input, the stem).

## Invariant the test relies on

The lift is **additive**: no layer's `.c` changes. That is why
`test_aie_offload.py` compares `layers/` to the *default-flow*
`layers-golden/` and ignores `*/aie/*`, `aiegraph.mlir` and `partition.json`.
Check 3 owns those three. It requires `host.cc`/`kernel.cc`/`routing.cc`, a
`partition.json` verdict of `target: aie` with a `conv_*` op, and that op in
`aiegraph.mlir`, so a stale `aie/` kept by `_clear_stale` cannot pass.
Do **not** refresh the golden to make an offload run pass. The golden is the
default flow; verify it with `rm -rf layers && deploy_flow.py` then
`test_aie_offload.py --skip-run --no-aie-check`.

## Still open

- If BYOC starts fusing, it rebuilds the C and layer 01's `.c` diverges from
  the golden. Treat that as a real change to review.
- Non-stem convs still get the generic `conv_bn` body (int16 acc, `_QUANT`
  placeholder params). Their geometry is right but their arithmetic is not
  TVM's.

## The stem is built from `conv2dstem.cc`, not the generic body

`_build_one` dispatches a conv whose geometry equals
`byoc.aie_patterns.STEM_GEOMETRY` (230x230x3 → 64, K7 s2) to
`aie_stem_lib.build_stem_layer`. That runs `source script/aiehlc.sh
--runtime-source-file src/aietensorop/conv2dstem/conv2dstem.cc` in a
**scratch cwd**, because aiehlc writes and `rm -rf`s `aout/` relative to the
cwd. It then replaces the layer's `aie/` with `aout/worklocal/`, leaving out the
two ~6 MB `layeriohex` data headers that aiehlc's `*.h` glob drags along.

Proof that this is `test_conv2d.cc`'s logic: diffed against the
`test_conv2d.cc` build, `kernel.cc`, `routing.cc`, `aieml.bcf/.prx` and
`aie_resource_map.h` are byte-identical. `host.cc` (−261 lines) and
`conv2d_spatial.cc` (−9) lose only `test_conv2d.cc`'s driver (`main`,
`fold_qparams`, `check_against_golden`, the `TVM_*` macros) and gain nothing.
No `main()` means aiehlc archives `aie/build/libconv2dstem.a`, which
`arm_build`'s `AIE_LAYER_LIBS` wildcard links, and `main.elf` calls into it
through the entry described below.

## Layer 01 really runs on the AIE in `main.elf` (verified on the board)

`aie_stem_lib` appends `aie_<kernel>()` to the stem's `aie/host.cc`. That
entry has TVM's packed-call signature and does `test_conv2d.cc`'s
`fold_qparams` + `conv2d_stem_nchwc`. It is re-archived with
`hostcompile.sh`, and `graph_driver.c` calls it under
`#ifdef GRAPH_AIE_OFFLOAD`, which only the board Makefile defines. So
`make local` → `main_local.elf` is the CPU reference built from the same
driver.

Measured 2026-10-09 (`apppaltest.py -y -nonreboot`, log in
`src/frontend/tvmrelay/test/applog_aie_offload.txt`):

```
[aie-offload] layer 01 ...: ENTER aiehlc conv2dstem (conv2d_stem_nchwc on the AIE mesh), 9 args
[aie-offload] layer 01: EXIT rc=0, ofm[0..7]= 2e 61 0e 00 1e 59 2b 1c, hash=2aeeab65
1. class=258 Samoyed logit=12.0173  ... identical top-5 and logits to main_local.elf
```

`hash=2aeeab65` is `h = h*31 + byte` over all 802,816 output bytes. It equals
the same hash of TVM's own layer-01 output (`conv2d_stem_out_golden.h`), so
the AIE layer is **bit-exact**, not just top-5-equal. The 24
`[AIE ERROR] Invalid column: 4..6` lines also appear in the standalone
`test_conv2d` run (`applog.huaj`, which still says `GOLDEN PASS`). They come
from the conv2dstem library's partition/bus config and are not caused by the
offload.

Board gotchas:
- `-y` (reboot mode) fails with `/dev/ttyACM0 could not be opened` /
  `No such device: ctl` while your long-lived systest session owns the board.
- `-nonreboot` needs an `hw_server` on the lab host's port 3121
  (`connect -url TCP:<PALIP>:3121`). Without one you get `Connection refused`,
  then `dow` → `Invalid target`. The `hw_server` wrapper forks the real
  binary, so killing the wrapper PID alone leaves port 3121 listening.
- `deploy_flow.py` exits 0 even when `make` fails. The `[elf ]` check in
  `run_test.sh` catches that. The first link failed on the hostcompile archive
  bug (skill hostlibrarymode).
