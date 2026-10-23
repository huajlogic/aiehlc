# BYOC → AIE integration plan (option A: single ELF)

> **Superseded in part — see [aie_offload_byoc.md](aie_offload_byoc.md) for what
> is implemented.** The subgraph boundary is the *fused* op (not the raw conv),
> the kernel is the aiehlc-built `libconv2dstem.a` (not `run_aie_pipeline`, which
> emits no caller), and layers are matched by weight fingerprint. Kept as the
> original plan.

Wire the convolution subgraphs TVM BYOC partitions out onto aiehlc-generated AIE
kernels, with **everything linked into one `main.elf`** and TVM's graph executor
doing the scheduling.

**Spatial tiling, halo, mesh partitioning, routing, DMA and tile budgeting are
all aiehlc's job (`run_aie_pipeline`).** Nothing in this plan implements any of
them; our side only translates and wires.

---

## 0. Where things stand (measured, not assumed)

The four BYOC pieces are written and working (`src/frontend/tvmrelay/byoc/`):

```
MergeComposite matched 20 aie.qconv
annotated 5 for AIE offload (limit 5)
partitioned into 5 AIE subgraphs
relay.build OK -> 6 C modules (1 TVM kernels + 5 AIE wrappers), 430,743 chars
cross-compiles clean (aarch64-none-elf-gcc -fsyntax-only)
```

**But the wrapper bodies are placeholders** (per-element copy + clamp), so the
classification result is wrong. This plan is about replacing them with real AIE
calls.

Downstream compatibility, already confirmed:

| Stage | Verdict | Evidence |
|---|---|---|
| `graph.json` | no change | the 5 AIE subgraphs are ordinary `tvm_op` nodes, sitting normally among 119 |
| `arm_build.py` driver | no change | it emits calls by `func_name`, indifferent to who implements them |
| `split_layers.py` | adapts itself | its split regex is `extern "C" + TVM_DLL`, so wrappers become their own layer folders |
| `params.bin` | no change | 177 entries, same as the non-BYOC path |
| `build_c` | **must change** | `lib.lib.get_source()` throws `Module[const_loader] does not support GetSource` on a composite module |

---

## 1. The interfaces (read out of the code, not guessed)

### What aiehlc exposes

`orchestrate_conv_layer(..., host_func_suffix=name)` produces:

```c
void host_canonicalized_<name>(XAie_DevInst* dev, void* in, void* params, void* out);
extern unsigned char _binary_kernel_<name>_start[];
```

The calling contract, taken from `orchestrator._emit_dispatcher` (which mirrors
`aiehlc.cc:4711-4734`):

```c
XAie_DevInst* dev = __Runtime_get_partition_dev(mesh.meshId);
__Runtime_set_kernel_elf(_binary_kernel_<name>_start);
__Runtime_sync_for_dev(dev, t0, s0);          // once per DDR argument
__Runtime_sync_for_dev(dev, t1, s1);
host_canonicalized_<name>(dev, t0, t1, t2);
```

### params buffer layout (`model.make_conv_params`)

```
[config:12B][weights:Cin*Cout*K*K][bn_scale:Cout][bn_bias:Cout]
 ^ six uint16 LE fields: H, W, Cin, Cout, K, stride
```

**This header has ~6 readers that must stay in lock-step** (already recorded in
CLAUDE.md: one stale reader computes garbage silently).

### What TVM expects (the wrapper I generate)

```c
TVM_DLL int tvmgen_default_aie_main_0(void* args, int* type_codes, int num_args,
                                      void* out_value, int* out_type_code);
```

**The glue between these two is exactly what I have to implement.**

---

## 2. The four things I write (all translation and wiring)

### 2.1 Geometry extraction — read parameters off the Relay subgraph
Read `H/W/Cin/Cout/K/stride/padding/groups` from the subgraph's `nn.conv2d`
attrs and `checked_type`. Pure attribute lookup.
**Acceptance**: the geometry of all 20 convolutions matches what the
`graph.json` shapes imply, one by one.

### 2.2 `tensor_specs` — declare tensors, do not decide how to split
Convert to the `[(shape, bits, is_input), ...]` form `run_aie_pipeline` wants.
This only declares *which tensors exist, how big, input or output*; how they map
onto the mesh is aiehlc's decision.

### 2.3 params blob packing — real weights, not placeholders
`make_conv_params` today fills in **fake** alternating ±1 weights. Replace with
the real int8 weights and bias read out of the Relay Constants, packed in the
layout above.
**Acceptance**: unpacking the blob reproduces the Relay Constants byte for byte.

### 2.4 ABI glue — the only piece with real work in it
The wrapper body in `aie_codegen.py` goes from copy-and-clamp to:

```c
TVM_DLL int tvmgen_default_aie_main_0(void* args, ...) {
    /* 1. unpack DLTensor -> raw pointers */
    /* 2. __Runtime_set_kernel_elf(_binary_kernel_<name>_start); */
    /* 3. __Runtime_sync_for_dev(dev, p, size) per DDR argument */
    /* 4. host_canonicalized_<name>(dev, in, params, out); */
}
```

---

## 3. Phases

### Phase 1 — close the pipeline (low risk, do first)
- Change `build_c` to walk the module tree, collect every `type_key=='c'`
  source and concatenate (**already verified**: 6 modules → 430,743 chars →
  cross-compiles clean)
- Add `--byoc-aie [N]` to `deploy_flow`, off by default
- **Acceptance**: the ELF produced with `N=0` is **byte-identical** to the
  non-BYOC path

### Phase 2 — one real kernel (the core)
Do a **single layer** (`N=1`) end to end, exercising all four items in §2.
- Call `run_aie_pipeline` to generate that layer's
  `host.cc`/`kernel.cc`/`routing.cc`/`.bcf`
- Swap the wrapper over to the real call
- **Acceptance**: that layer's output compared element-wise against the TVM CPU
  reference (quantization error allowed; garbage is not)
- **Risk**: if it does not fit a tile, aiehlc reports it; our side neither
  predicts nor pre-rejects

### Phase 3 — linking it together
- Add aiehlc's generated `.cc` files to `arm_build.py`'s `SRCS`
- Embed the kernel ELF via `ld -r -b binary` (reuse the existing weights.bin
  mechanism)
- Device lifecycle: `__Runtime_device_init` at the top of `main.c`, teardown at
  the end
- **Acceptance**: `main.elf` links, and a board run prints `device_teardown done`

### Phase 4 — scale to N layers and verify accuracy
- `N=5` → `N=20`
- Compare the board's top-5 against the CPU reference; top-1 must still be
  Samoyed (258)
- Measure `inference` ms with the timer already added, against the pure-CPU
  baseline

### Phase 5 — converge and document
- **The three AIE paths must be merged**: `--aie-offload`, `--aiegraph`,
  `--byoc-aie`. The first two are already dead under the ONNX-PTQ default
  (0/28 eligible, confirmed). Proposal: BYOC becomes the only path, the other
  two get deprecated.
- README plus a skill recording the three TVM 0.16 traps

---

## 4. Known risks

| Risk | Nature | Response |
|---|---|---|
| does not fit a tile | **aiehlc's job** | no prediction on our side; revisit once aiehlc reports |
| params header's 6 readers drift | silent miscompute | phase 2 adds an unpack-and-compare assertion |
| device lifecycle under TVM scheduling | unverified | the main unknown in phase 3: TVM may call a subgraph more than once, and init is not re-entrant |
| int16 storage (not int8) | known | `target="c"` has no int8 qnn legalization; orthogonal to this plan |

**The biggest unknown is the device lifecycle in phase 3** — when the TVM graph
executor calls a subgraph, whether calls can overlap, and how `XAie_DevInst` is
shared. That is the main cost of option A (single ELF) over option B.
