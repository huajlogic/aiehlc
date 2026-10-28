# convtune — AutoTVM/XGBoost tuning of aiehlc conv2d tiling

Tunes the knobs of a declarative conv2d (`aie::Conv2d` + `aie::Mapping`, see
`doc/design/conv_autotiling.md`): `time_oh`, `time_ow` (→ IFM/OFM d1
`slice_tiling`, d2 halo), `pp_depth`, `l1_budget`. The C++ model
(`aiehlc-convtile`) defines the legal space and derives every d1/d2/d3; TVM's
`XGBTuner` searches it.

```bash
export PYTHONPATH=$REPO/src            # TVM 0.16 + xgboost must import
python -m frontend.convtune space  example/tileprogram/ccode/simpleconv2d_new_load.cc
python -m frontend.convtune derive example/tileprogram/ccode/simpleconv2d_new_load.cc --time-oh 14 --time-ow 16
python -m frontend.convtune tune   example/tileprogram/ccode/simpleconv2d_new_load.cc --mode analytic --n-trial 24
python -m frontend.convtune tune   ... --mode build  --n-trial 8          # every trial compiled by aiehlc.sh
python -m frontend.convtune tune   ... --mode board  --n-trial 16 --l1-budgets 4096,8192
```

Apply the result: `AIEHLC_CONV_TUNE=@<workdir>/best_knobs.json source script/aiehlc.sh ...`,
or paste the printed `.time = {...}` / hints into the `aie::Mapping`.

Python API:

```python
from frontend.convtune import autotvm_bridge as br
task, legal = br.create_task(src, pp_depths=[2], l1_budgets=[4096, 8192])   # tvm.autotvm Task
tuner = br.make_tuner(task, "xgb")                                          # XGBTuner(feature_type="knob")
opt = tvm.autotvm.measure_option(builder=br.AieConvBuilder("board", wd), runner=br.AieConvRunner("board"))
tuner.tune(n_trial=16, measure_option=opt, callbacks=[tvm.autotvm.callback.log_to_file("t.log")])
# or simply: br.tune(src, n_trial=16, mode="board")
```

`--run-cmd` replaces the board command (`{elf}`, `{repo}`, `{dir}` substituted);
the runner needs a `[BENCH] aie_wall_ms=<ms>` line and a `PASS: all N output
elements match` line, and treats `FAIL:`/`MISMATCH`/`AIE ERROR`/`TIMEOUT` as a
failed trial.

Self-check: `python src/frontend/convtune/test_convtune.py`.
