---
name: resnetengine
description: Run/modify the persistent AIE conv engine that executes int8 ResNet-18 (stem+maxpool and all 19 other convs) bit-exact vs TVM in 2.8 ms; gen_engine.py "model mismatch", "core memory overflow", "residual moved", ENG FAIL on the board, adding a layer kind, changing the fabric.
---

# resnetengine: whole ResNet-18 on the AIE (src/aietensorop/resnetengine)

Design + measured optimization log: `doc/design/resnet_aie_engine.md`.

## Run
1. `worklocal/tvmrelay_deploy` from `deploy_flow.py`, then in `arm_build/`:
   `make local TRACE=1 TRACE_HEX_PARAMS=0 && ./main_local.elf` (layeriohex dumps;
   the generator reads call 00/01/02/40 dumps and every conv's golden).
2. `python3 src/aietensorop/resnetengine/gen_engine.py --out worklocal/resnetengine`
   -- prints the numpy model check per layer (must be all OK) and the core
   memory plan; writes `eng_net.h` + `.bin` blobs (absolute paths, incbin'd).
3. `bash src/aietensorop/resnetengine/build.sh eng [outdir]` (stages aielib if
   `thirdparty/alib/lib` was wiped; `KDEFS="X Y"` prepends `#define`s to
   kernel.cc; `EXTRA_DEFS=...` reaches the host/runtime compile).
4. `python3 script/test/apppaltest.py -y --netload <out>/aout/worklocal/build/host`
   -> `ENG isolated/chained call N: PASS`, `ENG image i: logits == (bit-exact)`,
   `PERF SUMMARY best X ms`, `ENG PASS`.

## Where things are
- `eng_desc.h`: header words (EH_*), flags (DOWN/GRAB/COMB/RES_IN/STEM), stem
  geometry. Kernel, host and generator share it: add a field in all three.
- `gen_engine.py`: TVM extraction (`conv_info` regexes over the generated C),
  layer fusion (`build_layers`), numpy model, core-memory plan (`plan`), blob
  packing (`chunk`, `chunk_stem`), CPU-tail constants (`cpu_tail`).
- `eng/kernel.cc`: persistent core program; `eng/host.cc`: shim BD arm over the
  control plane, verification, timed end-to-end runs, NEON quantize/dense.

## Traps
- The numpy model passing is the precondition for any board run; isolated mode
  (each layer on TVM's golden input) localizes a board failure to one layer.
- Core memory is 57 KB of arena; `plan` asserts. RES lives at the top so
  producer (GRAB/DOWN) and consumer (COMB) agree on its address.
- Stack: skill **aiecorestackoverflow**. Timing: skill **aiecoretimerlock**.
- Lock values are 6-bit: keep counts <= 31 (resident ring uses one BD use per
  chunk, release-only, for that reason).
- Never run two `aiehlc.sh`/`build.sh` at once (`thirdparty/alib/lib` restaging).
