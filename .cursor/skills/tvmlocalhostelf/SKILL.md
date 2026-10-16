<!-- Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
     SPDX-License-Identifier: Apache-2.0 -->
---
name: tvmlocalhostelf
description: Building, running or TRACING the TVM-generated ResNet-18 C on x86 instead of the board -- deploy_flow.py --local, arm_build.py --local, `make local` / `make run-local` / `make TRACE=1` in worklocal/tvmrelay_deploy/arm_build. Covers "fatal error: xtime_l.h: No such file or directory" out of aie_timer.h, "'CLOCK_MONOTONIC' undeclared" inside aie_timer.h, make's "Circular localobj/x.o <- local dependency dropped" then "can't create local/x.o: No such file or directory", "*** stack smashing detected ***" in graph_run(), undefined _binary_weights_bin_start, undefined XAie_* when a local link is attempted on an --aie-offload build, and dumping per-layer tensors -- including decoding a DLDataType printed as a raw integer ("Input tensor data type: 69632" = int16, 67585 = uint8).
---

# Running the TVM-generated ResNet-18 C locally (x86), not on the board

## What this is for

`relay.build(target="c")` emits portable C. Stage 6 (`arm_build.py`) wraps it in
a driver, a runtime shim, a `main.c` and a weight blob, then cross-links a
baremetal aarch64 `main.elf`. Checking that ELF against stage 7's onnxruntime
reference normally means flashing a board and reading a console.

`--local` links **the same generated sources** — same `graph_driver.c`, same
`layers/*/*.c`, same `weights.bin`, same `main.c` — with the host gcc into
`main_local.elf`. It prints the identical top-5-with-logits, so the comparison
takes a second:

```bash
PYTHONPATH=src python src/frontend/tvmrelay/deploy_flow.py --local
PYTHONPATH=src python src/frontend/tvmrelay/deploy_flow.py --local --no-arm
PYTHONPATH=src python src/frontend/tvmrelay/deploy_flow.py --local --no-local-run

PYTHONPATH=src python src/frontend/tvmrelay/arm_build.py worklocal/tvmrelay_deploy --local

make -C worklocal/tvmrelay_deploy/arm_build local       # build main_local.elf
make -C worklocal/tvmrelay_deploy/arm_build run-local   # build it and run it
make -C worklocal/tvmrelay_deploy/arm_build clean-local # just the local artifacts
```

`deploy_flow.py` ends with the verdict:

```
      local ELF: .../arm_build/main_local.elf
      local vs cpu: MATCH class=258 (Samoyed) logit 12.0173 vs 12.4359
```

Measured on ResNet-18 int8, this host: ~1.3 s per inference (unvectorized
portable C), 24 MB ELF, top-5 order identical to the reference with the small
int8 logit drift you would expect.

It needs **no Vitis toolchain**. That is why it composes with `--no-arm`, and
why `build_arm_elf` runs it *before* the cross-toolchain gate rather than after.

## The two flags that have to be ADDED

A local build is not the cross build with a different `-mcpu`. The BSP include
and lib paths and the whole baremetal link recipe (`--specs=nosys.specs`,
`-Wl,--defsym,end=__bss_end__`, `-Wl,-T lscript.ld`) are **dropped** — none of
them mean anything to a hosted x86 link. Two flags must be added, and both
failures point *into* `include/aie_timer.h`, not at your own code:

| symptom | flag | why |
|---|---|---|
| `aie_timer.h:22: fatal error: xtime_l.h: No such file or directory` | `-D__AIESIM__` | `aie_timer.h` branches on `__AIESIM__` → `AIE_GEN==5` → else. The `else` includes `xtime_l.h`, a standalone-BSP header that only exists on target. `__AIESIM__` selects the portable `clock_gettime` branch. **Do not** instead pass `-DAIE_GEN=5` on the host — that wants the BSP's `xiltimer.h`. |
| `aie_timer.h:16: error: 'CLOCK_MONOTONIC' undeclared` | `-std=gnu11`, **not** `-std=c11` | `clock_gettime`/`CLOCK_MONOTONIC` are POSIX, and strict ISO mode hides them behind the feature-test macros. The cross build gets away with `-std=c11` because newlib does not gate them. `-D_POSIX_C_SOURCE=199309L` also works; `gnu11` is what the generated Makefile uses. |

Plus `-lm`: the BSP supplied libm inside `-lxil`'s `--start-group`; here it is
explicit.

## Why the object directory is `localobj/` and not `local/`

Do not "tidy" this. The phony target is named `local`, so a rule written

```make
LOCAL := local
$(LOCAL)/%.o: %.c | $(LOCAL)
```

makes `local/graph_driver.o` depend (order-only) on the phony target `local`,
which depends on `main_local.elf`, which depends on `local/graph_driver.o`.
make reports

```
make: Circular local/graph_driver.o <- local dependency dropped.
```

and then **drops the order-only prerequisite**, so nothing ever creates the
directory and the very next line is

```
Assembler messages:
Fatal error: can't create local/graph_driver.o: No such file or directory
```

which looks like a permissions problem and is not. The directory is
`localobj/`; the targets are `local`, `run-local`, `clean-local`.

Flattening is safe because layer basenames carry their `NN_` prefix. `vpath`
is what lets a flat `localobj/NN_op.o` find its source back under
`$(LAYERS)/NN_op/`:

```make
vpath %.c . $(sort $(dir $(LAYER_SRCS) $(KERNELS)))
```

It cannot disturb the cross rules — those name their prerequisites by absolute
path, and `vpath` only searches when the literal path is missing. Keeping the
local objects out of the layer directories is what stops a local build from
clobbering the aarch64 `.o` that sit next to their `.c`.

## `*** stack smashing detected ***` in graph_run()

This was a **real bug in the generated driver**, found precisely because x86
has a stack protector and baremetal aarch64 does not. `graph_driver.c` used to
declare

```c
TVMValue args[8];
int32_t  codes[8];
```

but the NCHWc convs take **10** arguments (7 inputs + 3 outputs), so
`args[8]`/`args[9]` wrote past the end into `codes[0..1]`. The kernels ignore
`arg_type_ids`, which is the only reason the board tolerated it; any other
stack layout would have corrupted something that matters.

Both widths now come from the graph — `arm_build.graph_widths(nodes, shapes)`,
emitted as `GRAPH_MAX_NDIM` / `GRAPH_MAX_ARGS`. If you touch the driver
generator, size arrays from the graph, never from a round number. Check with:

```bash
grep -n "GRAPH_MAX" worklocal/tvmrelay_deploy/arm_build/graph_driver.c
python3 -c "
import json; g=json.load(open('worklocal/tvmrelay_deploy/resnet18_graph.json'))
print(max(len(n['inputs'])+int(n['attrs'].get('num_outputs',1))
          for n in g['nodes'] if n.get('op')=='tvm_op'))"
```

An existing `graph_driver.c` from before this fix is **stale** — regenerate it
(re-run `deploy_flow.py`, or `arm_build.generate_driver`) rather than patching
the two numbers by hand, because the file is also offset-matched to
`weights.bin`.

## Dumping tensors between layers — `TRACE=1`, not a hand edit

`graph_driver.c` is **generated**. A `printf` added to it by hand is gone the
next time `deploy_flow.py` or `arm_build.py` runs. The trace is built in:

```bash
make local TRACE=1 run-local        # host, traced, run it
make TRACE=1                        # board ELF, traced
make local TRACE=1 TRACE_ELEMS=16   # 16 elements per tensor (default 8)
```

```
[00] tvmgen_default_fused_divide_round_add_clip_cast_subtract_layout_transform
   in  tensors[0] float32 [1,3,224,224] = -1.929532 -1.929532 -1.912407 ...
   in  tensors[1] int16 [] = 113
   out tensors[2] int16 [1,1,224,224,3] = -104 -98 -87 -104 -98 -86
```

Everything is behind `#ifdef GRAPH_TRACE`, so an untraced build is unchanged —
measured: `.text` 782,088 bytes with and without the helpers present.

### `Input tensor data type: 69632`

That is a `DLDataType` **struct** printed with `%d`. It is 4 bytes
`{uint8_t code; uint8_t bits; uint16_t lanes;}`, and `printf("%d", t.dtype)` is
undefined behaviour that happens to print the little-endian packing:

```
value = code | (bits << 8) | (lanes << 16)
69632 = 0x00011000  ->  code 0 (int), bits 16, lanes 1  ->  int16
67585 = 0x00010101  ->  code 1 (uint), bits 8, lanes 1  ->  uint8
```

Codes: 0 `int`, 1 `uint`, 2 `float`, 4 `bfloat`. Common values in this graph:
`67584` int8, `67585` uint8, `69632` int16, `66304` int32, `73730` float32.
`dl_dtype_str()` in the generated driver decodes it; it and `dl_code_name()`
and `graph_dump_tensor()` are `static inline` and always emitted, so an ad-hoc
`printf` can call them.

### Dump elements, not bytes

A byte dump of an int16 tensor reads `98 ff 9e ff a9 ff` — that is
little-endian `-104, -98, -87`, and reading it as bytes is the single most
common way to misread this output (it is also why `conv2dstem_image.h` and
TVM's layer 0 look like different data; see skill **conv2dstemfixture**).
`graph_dump_tensor` switches on `(code, bits)` and prints decoded values.

It also clamps the count to the tensor's element count: the zero-point
parameters are `ndim 0`, `numel 1`, and dumping 8 elements of those reads past
the end of a 2-byte buffer.

### Changing the trace

`arm_build._DEBUG_HELPERS_C` (the helpers) and `arm_build._trace_lines` (the
per-node `#ifdef` block). The `TRACE`/`TRACE_ELEMS` plumbing is in
`_MAKEFILE_TMPL`, appending to **both** `CFLAGS` and `LOCAL_CFLAGS`.

## All of this is also in the generated `arm_build/README.md`

`worklocal/tvmrelay_deploy/arm_build/README.md` is written by
`arm_build.write_readme` alongside the sources, so it carries this run's real
numbers (call count, buffer bytes, layer count) and cannot drift from the
Makefile it documents. Source is `arm_build._README_MD`; placeholders are
`@@NAME@@` rather than `{}` or `$`, because the text is full of literal C
braces and make `$(VAR)` references that both `str.format` and
`string.Template` would choke on.

Point people there first — it is next to the files they are looking at. Edit
the template, never the generated copy.

## `undefined reference to _binary_weights_bin_start`

`ld -r -b binary` derives the symbol from the path it is **given**, not from
the output path. The rule must keep the input relative and in the build
directory even though the output goes elsewhere:

```make
$(LOCALOBJ)/weights.o: weights.bin | $(LOCALOBJ)
	$(HOST_LD) -r -b binary -o $@ weights.bin
```

Writing `-o $@ $<` is fine here (`$<` is `weights.bin`), but naming the input
as `localobj/weights.bin` would produce `_binary_localobj_weights_bin_start`
and `main.c`'s `extern` would never resolve.

## An AIE-offloaded build cannot be linked locally

`make local` stops with a named error when `AIE_LIB` or `AIE_LAYER_LIBS` is
non-empty:

```
*** make local cannot link an AIE-offloaded build -- the archives are aarch64
and their kernels run on the array. Re-run deploy_flow.py without
--aie-offload/--aiegraph for a local ELF, or use plain make for the board.
```

This is deliberate and should stay. `aout/libconv2dstem.a` and the per-layer
`libNN_op.a` are aarch64 baremetal and carry the AIE runtime; the computation
they wrap happens on the array, not on any CPU. Without the guard the link
dies in a wall of undefined `XAie_*` references that says nothing about the
cause. There is no host emulation of the AIE kernel to fall back on — and a
stub would silently compute garbage, which is worse than not building.

To validate an offload, build the CPU-only local ELF first as the reference,
then compare the board run against it.

## Where the code is

| thing | where |
|---|---|
| `--local` / `--no-local-run` CLI | `src/frontend/tvmrelay/deploy_flow.py` (`main`, `run`) |
| MATCH/MISMATCH verdict | `deploy_flow._report_local_vs_cpu` |
| `make local` driver | `arm_build.build_local_elf`, `arm_build.build_arm_elf(local=...)` |
| the Makefile LOCAL section | `arm_build._MAKEFILE_TMPL` (search `LOCAL (x86`) |
| array widths | `arm_build.graph_widths` |
| the portable timer branch | `include/aie_timer.h`, `#ifdef __AIESIM__` |

Related: **tvmrelaynollvm** (getting the int8 path to run at all),
**byocaieoffload** (the AIE offload this cannot link).
