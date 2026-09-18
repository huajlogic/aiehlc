# passblueprintlowering

Blueprint lowering. Both passes here consume `dfscheblueprint` IR and lower it to
`dfschedule`, but for two different targets:

```
passblueprintlowering/
├── helper/                        ← SHARED (see below)
│   ├── flowtransfer_internal.h    FlowLoweringCtx, CoreTileCtx, BlueprintPassState
│   ├── flowtransfer_common.cpp    shared utilities (traceToFuncArgIndex, ...)
│   ├── flowtransfer_host.cpp      shim DMA + schedule orchestration
│   └── flowtransfer_kernel.cpp    core-tile config (ping-pong / single-buffer)
├── passblueprinttoschedule/       host path   → host.cc
└── passblueprinttoschedulekernel/ kernel path → kernel.cc
```

## Why helper/ sits above both passes

The two passes describe **the same physical core/kernel tiles**. Core-tile DMA BDs,
DMA channel starts, lock init values and lock ids must be identical whichever side
emits them — the hardware has one BD bank and one lock array per tile, and whoever
programs it must agree with whoever doesn't.

`helper/` is where that shared description lives. Put anything here that both paths
need to agree on; do not duplicate it inside either pass.

This matters most under `#pragma KERNELCONFIGOFFLOAD`, where ownership of core-tile
config moves from the host to the kernel: the host stops emitting it and the core
self-programs the same registers from `kernel.cc`. The two sides only stay consistent
because they derive from shared code and shared resource accounting.

## Resource accounting caveat

`BlueprintToSchedulePass` builds its **own** `ResourceMgr`
(`passblueprinttoschedule.cpp`, `std::make_shared<ResourceMgr>`) for BD/lock
allocation — that pool is local to the host pass. The `ResourceMgr::instance()`
singleton (init'd in `tilinglinalg_pipeline.cpp`) is a *different* object, and is the
only channel that crosses the host/kernel module clones (`coreMemAllocator` already
uses it). When passing per-tile facts from the host pass to the kernel pass, write
through `ResourceMgr::instance()`, not the pass-local manager.

Pass order in the pipeline is host first, then kernel — so host-computed facts can
flow forward, but not the reverse.
