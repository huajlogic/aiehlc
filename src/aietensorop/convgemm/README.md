<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->

# convgemm — the int8 GEMM-tile basic op behind every non-stem conv offload

One fixed-shape GEMM tile on the 4×4 AIE mesh,
`C[256,64] int32 = A[256,256] int8 · Bt[64,256]ᵀ int8`, built **once** by aiehlc
and shared by every offloaded ResNet-18 conv layer except the stem. All
shape-dependent work is host code in `convgemm_host.h`: NCHWc im2col, splitting
any M/N/K into tiles, int32 accumulation across K tiles, and the scatter back to
NCHWc.

| file | role |
|---|---|
| `convgemm.h` | API: `conv2d_nchwc_i8(ifm, wts, acc, &geom)`, `convgemm_i8i32(A, Bt, C, M, N, K)`, `convgemm_launch_count()` |
| `convgemm.cc` | aiehlc source: kernel `gemm_i8i32` (int32 accumulate, int32 out as 4 LE bytes through the int8 window) + the one launch site |
| `convgemm_host.h` | plain C host logic; included by `convgemm.cc` **and** by the x86 harness in `frontend/tvmrelay/aie_conv_lib.py` |

It returns the **raw conv accumulator**. The fused epilogue TVM attached to the
conv is TVM's own C, transplanted into each layer's `aie/tail.c`
(`aie_conv_lib.transplant_tail`).

Build (normally done by `deploy_flow.py --aie-offload`, into
`worklocal/tvmrelay_deploy/aie_ops/convgemm/`):

```bash
mkdir /tmp/cg && cd /tmp/cg          # aiehlc writes aout/ relative to the CWD
source $REPO/script/aiehlc.sh --aie-version 5 --runtime-source-file $REPO/src/aietensorop/convgemm/convgemm.cc
# -> aout/libconvgemm.a (library mode: no main())
```

Before linking next to another aiehlc library (the stem's), isolate it. Each
library needs a private runtime because `aie_runtime.o` calls `routing()` by its
global name. Use `frontend/tvmrelay/aiehlc_build.isolate_archive` (`ld -r` +
`objcopy --keep-global-symbols`).

Traps, each one already hit:

- **No `#define M/N/K`.** They rewrite the `int M, int N, int K` parameters in
  the headers, and the build fails with `expected ')'`.
- **Never spell the kernel keyword or the launch syntax in a comment.**
- **Include `convgemm.h` only after the kernel body** (skill aiesourcetextrewrite).

Status: **verified on the board.**

- `test_convgemm.cc`: one tile `PASS 16384/16384`; a ragged 300×70×600 GEMM
  over 12 launches `PASS 21000/21000`.
- Full ResNet-18 with every conv offloaded: the top-5 equals `main_local.elf`
  down to the logits.

Two hardware-only fixes are in place:

1. **Descriptors.** They are byte-for-byte `simplematmul2`'s proven
   256×256×256. int32 is carried by replicating each B row 4× and storing byte
   `b` of `acc(r)` at virtual column `4r+b`. N = 64 with a 4×-wide C port
   made aiehlc derive inconsistent buffers, and the DMA hung.
2. **Cache.** `device.synchronizecpu(c, …)` runs after every launch, because the
   generated launch only flushes before the DMA, so stale C lines appeared from
   the second launch on.

```bash
# standalone board test
mkdir /tmp/cgt && cd /tmp/cgt
source $REPO/script/aiehlc.sh --aie-version 5 --runtime-source-file $REPO/src/aietensorop/convgemm/test_convgemm.cc
python3 $REPO/script/test/apppaltest.py -y -nonreboot aout/worklocal/build/host
```

Design and trade-offs:
`src/frontend/tvmrelay/tutorial/aietensorop_conv.html`.
