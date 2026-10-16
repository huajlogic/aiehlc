---
name: aiegraphregion
description: The `aiegraph` region API — `ag.convert`, `module.regions`, `register_kernel`, `check_offload(region=, kernel=)`, `assign`, `partition(fallback=, optimize_for=)`, `build(target=, output=)` (`src/aiegraph/region.py`, `contract.py`, `partition.py`). Use when a region name does not resolve (`no region matches 'layer1.0.conv1'`), a region drags a sibling onto the AIE (`move together` / dragged), `region="layer1"` does something different from `offload_check("layer1")`, `partition` undid an earlier offload, `register_kernel` says "contract contradicts", or when adding a region source (a new model family / exporter naming).
---

# aiegraph regions: model op names -> TVM kernels -> placement

```python
module = ag.convert(ag.load("resnet18"), target="a78")
module.register_kernel(name="conv2dstem", source=".../conv2dstem_uk.cc", op="conv2d",
                       target="a78", constraints={"dtype": "int8", "quantization": "per_channel"})
print(module.check_offload(region="conv1", kernel="conv2dstem").summary())
module.assign(region="conv1", backend="aie:conv2dstem")
print(module.partition(fallback="cpu", optimize_for="latency").report())
module.build(target="a78", output="resnet18_a78")
```

## What a region is

One `Conv` / `Gemm` node of `<workdir>/*.int8.qdq.onnx` (the model the flow actually
compiled), with its weight found through the `DequantizeLinear` feeding input 1.
`Region.name` is canonical, `aliases` are extra names, and `label` is what reports print
(`layer1.0.conv1 (resnetv15_stage1_conv0)`).

* **torch export**: `/layer1/layer1.0/conv1/Conv` -> `layer1.0.conv1`. Each scope repeats
  only its **parent's** attribute (`/downsample/downsample.0/`), so walk a component list
  and let a part replace the last component when it starts with `last + "."`. Building a
  dotted string and testing `startswith(path + ".")` gives
  `layer2.0.downsample.downsample.0` (that bug was caught by `test_region_names`).
* **zoo gluon ResNet v1**: `resnetv15_stage2_conv2_fwd` -> `resnetv15_stage2_conv2`, plus a
  torchvision alias. Aliases come from the **`convK` index** and the **1x1 kernel**
  (`downsample.0`), NOT node order. The ONNX graph lists `stage2_conv2` (the 1x1) before
  `conv1`, so node order would mislabel every block. Only basic-block stages are aliased
  (all convs 3x3 or 1x1); a bottleneck net gets no aliases rather than wrong ones.

## Region -> TVM call: weight fingerprint, never position

`np.sort(w.astype(int64).ravel())` -> sha1, the same function as
`byoc.aie_annotate.weight_fingerprint`. Layout and dtype drop out: ONNX `int8[64,3,7,7]`
equals TVM `int8[16,1,7,7,3,4]`. TVM side: every `param` arg with an int8/uint8 dtype and
rank >= 2 (`fc` is rank 3 in TVM, `[125,512,8]`). Verified 21/21 (20 convs + fc) on the zoo
and torch trees. If a new model shows `unmapped` regions, check that its QDQ weights really
are the values TVM stores. Folding or legalization that *changes values* (not layout)
breaks the match. fp32 flows have no QDQ file, and `build_regions` refuses them.

## Traps

* **One TVM kernel, several regions.** A TVM layer is a distinct kernel, and
  `arm_build.aie_entries` swaps it **by symbol** for every call. `layer1.0.conv1` and
  `layer1.1.conv1` are both TVM layer 4. `check_offload` prints `move together`,
  `partition` lists an unassigned sibling as *dragged*, and siblings assigned to different
  backends fail as a `conflict` (then fallback).
* **"layer1" means two things.** `region="layer1"` = every region under torchvision's
  stage 1 (prefix match). `emod.offload_check("layer1", k)` / `emod.resolve("layer1")` =
  TVM kernel 1 = the stem. `Regions.find` deliberately does NOT fall back to TVM layer
  indices, so the two never blur. It accepts exact name/alias, prefix, glob, and `call[NN]`.
* **Contract vs AIEK_SPEC.** The contract is model-level (ONNX `Conv` is NCHW/OIHW; `dtype`
  = region weight dtype; `quantization` from the weight-scale rank). The spec is call-level
  (NCHWc, exact shapes) and is enforced by detect/calibrate/emulate. `register_kernel`
  refuses only what the spec contradicts: `op` not in the spec's `op`/`match` text, or
  `dtype` != the spec's first weight param. Don't "fix" an NCHW contract to NCHWc. That
  would describe the TVM call, which the spec already does.
* **`partition()` is the whole placement.** `reset_aie_rows` puts every AIE row of
  `layers/partition.json` back on the CPU, then `aiekernel.flow.offload` runs for the
  assigned layers (one call, all kernels; flow's one-library-per-ELF gate still applies).
  With nothing to offload it still regenerates `arm_build/` (`build_arm_elf(run_make=False)`)
  so the driver matches the reset. A failed gate or build leaves that layer on the CPU.
  `fallback=None` raises instead.
* **`optimize_for`** accepts `"latency"` / `None` and is reported as "no cost model yet".
  Don't let it imply a search.
* Kernel `target` is `"aie"` or `"a78"` (the ELF that launches it); both mean the board
  build. `build(target="x86")` builds `main_local.elf` without running it.

## Verify

```bash
python3 -m pytest -q src/aiegraph/test          # 18 tests; deployed ones need worklocal/tvmrelay_deploy
python example/aiegraph/quickstart_regions.py layer1.0.conv1   # NOT READY at detect, partition FELL BACK
python example/aiegraph/quickstart_regions.py                  # conv1 on the AIE, main.elf links it
nm resnet18_a78/main.elf | grep ' T aie_tvmgen'                # the adapter is really linked
```
