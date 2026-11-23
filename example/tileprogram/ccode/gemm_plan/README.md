# 2 x 8 shared-operand int8 GEMM from an explicit dataflow plan (no hand edits)

The 84.5 % GEMM of `../gemm_memtile/share2x8.py` was reached by rewriting the generated
`host.cc`, `kernel.cc` and `routing.cc` after every build. Here the same dataflow is written
**once, in IR**, and the compiler generates all three files from it
(design: `doc/design/dmaphop_dataflow_plan.md`).

| file | what |
|---|---|
| `gemm_plan.cc` | kernel + host app; the kernel reads operand views / lock ids / roles from the generated `aiehlc_plan.h` |
| `gemm_plan_tile.h` | the tile kernel (`share2x8_tile.inc`) with its buffer offsets and lock ids taken from the plan |
| `gen_plan.py` | writes the dataflow as `dmaphop.plan*` ops into a dumped dmaphop IR |

## Build (dmaphop level)

```bash
# 1. ordinary build: dumps ir/dfschedule/3_DmapToDmaphopPass.mlir (the kernel compile stops at the
#    missing aiehlc_plan.h -- expected: the kernel needs the plan)
source script/aiehlc.sh --aie-version 5 --runtime-source-file $PWD/example/tileprogram/ccode/gemm_plan/gemm_plan.cc
# 2. add the plan
python3 example/tileprogram/ccode/gemm_plan/gen_plan.py ir/dfschedule/3_DmapToDmaphopPass.mlir /tmp/plan.mlir
# 3. rebuild from the plan IR
AIEHLC_DMAPHOP_IR_IN=/tmp/plan.mlir source script/aiehlc.sh --aie-version 5 \
    --runtime-source-file $PWD/example/tileprogram/ccode/gemm_plan/gemm_plan.cc
python3 script/test/apppaltest.py -board vek385-6 -host gomphus6 -y --netload aout/worklocal/build/host
```

The build log says what happened:
`[DataflowPlan] 8 generated flow(s) replaced by the plan`, `routed 28 plan net(s): 138 switch
connections`, `host: plan setup / launch / wait wired into host_canonicalized`.

## Result (VEK385, vek385-6, 1.25 GHz array, 2026-11-23)

| build | steady per launch (10.07 G MAC) | % of peak | check |
|---|---|---|---|
| hand edits (`share2x8.py ... --r2 60 --bres --single --persist --tile --afine`) | 1.155-1.189 ms | 82.7-85.1 % | GOLDEN PASS |
| **dmaphop dataflow plan (this directory)** | **1.160 ms mean, 1.154 best** | **84.8 % mean, 85.2 % best** | GOLDEN PASS 187,758 / 187,758 |

The plan describes exactly the hand-edited dataflow; the compiler emits the same 138 stream-switch
connections, the same MemTile / core BDs and locks, and the same shim walks.
