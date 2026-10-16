<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: aieconvgemmoffload
description: "Offloading every ResNet-18 fused conv op to the AIE with ONE basic op (src/aietensorop/convgemm) plus TVM's own epilogue transplanted into layers/NN/aie/tail.c. Use when the transplant raises 'epilogue not found' / 'MAC statements not recognized', when two aiehlc libraries collide at link (routing, host_canonicalized, g_runtime_debug_level), when make fails with 'libaielayers.a: .../aie/entry.o: No such file', or when adding a conv shape / tail / basic op."
---

# All conv layers on the AIE: convgemm basic op + transplanted TVM tail

## Shape of the solution

- **Layer 01 (stem):** `aie_stem_lib` builds `conv2dstem.cc` with aiehlc, a hand-fused kernel.
- **Every other conv layer:** `aiegraph_partition._build_conv` → `aie_conv_lib`:
  - `build_shared` runs aiehlc on `src/aietensorop/convgemm/convgemm.cc` **once per run**
    and installs it in `<out>/aie_ops/convgemm/build/libconvgemm.a` (isolated).
  - `transplant_tail` turns the layer's TVM C into `aie/tail.c`.
  - `aie/entry.c` defines `aie_<symbol>()`: `conv2d_nchwc_i8()` → `aie_tail_<symbol>(…, acc)`.
  - `verify_layer` runs an x86 bit-exactness harness, recorded as `partition.json` `verify`.
- **Board link:** `arm_build` compiles `layers/*/aie/*.c` → `libaielayers.a`, then links
  `-Wl,--start-group libaielayers.a <per-layer libs> <aie_ops libs> -Wl,--end-group`.
  `graph_driver.c` swaps each call under `#ifdef GRAPH_AIE_OFFLOAD`.

## Traps (each one hit while building it)

1. **The epilogue reads a copy of the accumulator.** In layers 01/04/06/08, TVM stages
   `conv2d_NCHWc_global` into a local/workspace `conv2d_NCHWc`, and the epilogue reads that.
   Redirecting only the MAC target matched 0 reads ("epilogue not found"). Treat every
   `conv2d_NCHWc*` array as the accumulator.
2. **The rewrite index is the store's index.** Rewrite every accumulator read in the block
   that ends in `((T*)OUT_1)[IDX] = …` to `aie_acc[(IDX)]`. This is exact because the tail
   is element-wise and acc has the output's NCHWc layout.
3. **Two aiehlc libraries cannot share a runtime.** `aie_runtime.o` calls `routing(dev)` by
   global name (`__Runtime_routing_init`, `ctrl_plan_release`). Renaming symbols is not
   enough; `aiehlc_build.isolate_archive` does `ld -r --whole-archive` + `objcopy
   --keep-global-symbols=<API>` so each library carries a private runtime. Check with
   `ld -r --whole-archive libA.a libB.a` (fails on duplicates).
4. **`#define M/N/K` in an aiehlc source** rewrites the headers' `int M, int N, int K`
   parameters → `expected ')'`. Use TM/TN/TK.
5. **Editing `_MAKEFILE_TMPL`:** a recipe line separated from its rule becomes the recipe of
   whatever rule precedes it. Inserting a rule before `main.elf`'s last line
   (`@$(CROSS)size $@`) gave `$(AIE_GLUE_OBJS)` an explicit recipe, so they were never
   compiled → `ar: …/aie/entry.o: No such file`.
6. **`deploy_flow.py` exits 0 when `make` fails.** `run_test.sh`'s `[elf ]` check
   (fresh `main.elf`, one `aie_tvmgen_*` per conv folder, `conv2d_nchwc_i8` and
   `conv2d_stem_nchwc` defined) is what catches it.

## Verify

```bash
bash src/frontend/tvmrelay/test/run_test.sh --clean     # ~5.5 min; [aie ] 19/19, [elf ] 19 entries
aarch64-none-elf-objdump -d worklocal/tvmrelay_deploy/arm_build/main.elf | grep -c "bl.*<aie_tvmgen"   # 20
```

x86: every layer's `aie/README.md` and its `partition.json` `verify` field say
`N/N output bytes identical`. Hardware: not yet run for convgemm. Expect one
`[aie-offload] layer NN … ENTER/EXIT` pair per layer, and top-5 equal to `main_local.elf`.

## Extending

- **New shape:** nothing to do.
- **New element-wise tail:** nothing to do. The transplant refuses with a reason if it cannot be exact.
- **Grouped/depthwise/dilated conv:** im2col + weight pack in `convgemm_host.h`, plus `conv_geometry`.
- **New basic op:** `src/aietensorop/<op>/`, `aiehlc_build` + `isolate_archive` into
  `aie_ops/<op>/build/` (`AIE_SHARED_LIBS` picks it up).

Design and cost model: `src/frontend/tvmrelay/tutorial/aietensorop_conv.html`.

## Hardware-only bugs (found on the board 2026-10-10, both fixed)

7. **aiehlc buffer derivation vs. a non-proven descriptor.** With `ColBB.d1 =
   64` (one N-tile per mesh column) and a C port declared 4× wider than B's
   tiling, the resolved constants disagreed with the generated windows: in the
   generated `gemm_i8i32.cc`, `buf_sz_b = 4096` against `BUF_SZ_IN_1 = 64` words
   in `kernel.cc` (words = 4 bytes). The kernel over-acquired and the shim DMA
   hung (`wait_io TIMEOUT tile(c,0) … pending`). **Always diff the resolved
   `buf_sz_*` against `BUF_SZ_*` × 4 before going to the board.** Fix: keep
   simplematmul2's exact 256×256×256 descriptors and carry int32 as byte planes
   (4 virtual B rows per channel; virtual column `4r+b` = byte `b` of acc).
8. **No post-launch cache invalidate.** `__aie_launch` calls
   `__Runtime_sync_for_dev` on all buffers before the DMA and nothing after. One
   launch was exact; from the second launch on, ~4% of C was stale. Fix:
   `device.synchronizecpu(c, size)` after the launch.
9. **`PLM stalled during ELF download`** in apppaltest is board-side and
   transient. Re-run it; it is not the ELF.

Board result: `src/frontend/tvmrelay/test/applog_aie_offload_all.txt`. All
20 conv calls `rc=0`, top-5 = `main_local.elf`, inference 13.0 s.
