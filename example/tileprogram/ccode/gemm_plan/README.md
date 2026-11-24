# 2 x 8 shared-operand int8 GEMM, 84.9 % of the VEK385 peak, from the C source alone

The 84.5 % GEMM of `../gemm_memtile/share2x8.py` was reached by rewriting the generated
`host.cc`, `kernel.cc` and `routing.cc` after every build. Here the dataflow is stated in the
kernel source and the compiler generates all three files (design:
`doc/design/dmaphop_dataflow_plan.md`).

| file | what |
|---|---|
| `gemm_plan.cc` | kernel + host app. ONE kernel body (no `#if defined(__chess__)`): `aie::load_buffer` / `release` / `store_buffer` / `commit` with the true 2 x 8 offsets and `{.share / .stage / .ring / .keep / .parts / .align}`; `#pragma persistent_kernel` |
| `gemm_plan_tile.h` | compute macros of the tile (mmul<8,8,8>, chunk pipeline); no locks, addresses or layout |
| `gen_plan.py` | the same dataflow written by hand as `dmaphop.plan*` ops (the dmaphop-level way in) |

## Build and run (C level)

```bash
source script/aiehlc.sh --aie-version 5 --runtime-source-file $PWD/example/tileprogram/ccode/gemm_plan/gemm_plan.cc
python3 script/test/apppaltest.py -board vek385-6 -host gomphus6 -y --netload aout/worklocal/build/host
```

The log shows each level: `tensor_0 dataflow={ring = 10 : i64, share = "neighbor", ...}`,
`[DataflowPlan] synthesized from the routing IR: A strips 2 x B strips 8, 60 tiles / core, ...`,
`8 generated flow(s) replaced by the plan`, `routed 28 plan net(s): 138 switch connections`,
`flowcheck: OK -- 32 flows, 8 replaced by the dataflow plan, 0 error(s)`.

## The two lower ways in

* **Routing IR**: drop the options, dump `ir/dfschedule/0_initial.mlir`, add
  `dataflow = {share = "neighbor", stage = "memtile_ring", ring = 10 : i64}` (A),
  `dataflow = {share = "neighbor", stage = "memtile", resident = "launches"}` (B) and the module switch
  `routing.persistent_kernel = 1 : i64`, rebuild with `AIEHLC_ROUTING_IR_IN=<file>`.
* **dmaphop IR**: `python3 gen_plan.py ir/dfschedule/3_DmapToDmaphopPass.mlir /tmp/plan.mlir`, rebuild
  with `AIEHLC_DMAPHOP_IR_IN=/tmp/plan.mlir`. Explicit plan ops win over the routing-level
  attributes. The synthesized plan (`ir/dfschedule/4_DataflowPlan.mlir`) equals `gen_plan.py`'s
  105 ops.

## Results (vek385-6, 1.25 GHz array, 2026-11-23; GOLDEN PASS 187,758 / 187,758 every row)

| build | steady per launch (10.07 G MAC) | % of peak |
|---|---|---|
| hand edits (`share2x8.py ... --r2 60 --bres --single --persist --tile --afine`) | 1.155-1.189 ms | 82.7-85.1 % |
| dmaphop plan (`gen_plan.py`) | 1.160 ms mean, 1.154 best | 84.8 % / 85.2 % |
| routing IR attributes | 1.160 ms mean, 1.154 best | 84.7 % / 85.2 % |
| C source, `#if __chess__` kernel (commit 3ca2c9c4) | 1.158 ms mean, 1.154 best | 84.9 % / 85.2 % |
| **C source, one `load_buffer` body (as committed)** | **1.160-1.168 ms typical, 1.159 best** | **84.4-84.7 % / 84.8 %** |

The first launch (2.18 ms) also loads the kernel and B; it is excluded from the steady mean.
