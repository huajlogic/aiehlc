# K-accumulating GEMM with MemTile-staged operands (hand experiment)

`gemm_kacc_ntile.cc`: int8 GEMM, int32 C tile per core across K chunks, n-tile loop.
The traced (x86) path describes what the shim sends (each A / B block once); the core
path consumes A(m) NT times and B(n) R times -- `memtile_ab.py` makes the MemTiles
replay them (B resident per column, A double-buffered per mesh row).

    AIEHLC_KB_CHECK_WARN=1 source script/aiehlc.sh --aie-version 5 --runtime-source-file $PWD/gemm_kacc_ntile.cc
    python3 memtile_ab.py aout/worklocal 221184 21 73728 3 21 x
    python3 memtile_a3.py aout/worklocal 221184 21 73728 3 21
    rm -f aout/worklocal/build/{host.o,routing.o,host}
    WORKLOCAL_DIR=$PWD/aout/worklocal AIE_VERSION=5 PLATFORM=baremetal bash script/hostcompile.sh
    python3 script/test/apppaltest.py aout/worklocal/build/host -y --netload

palmyra: **2.20 ms per 4.83 G MAC = 26.8 % of peak end to end**, GOLDEN PASS (two 16x16 blocks per step; 2.24 ms / 26.3 % with one)
(MemTile BDs written once and only re-armed per launch: 2.51 -> 2.25 ms; B received in
NT parts so replay starts on part 0: 2.25 -> 2.24 ms; uncached C instead of the
invalidate contract: slower, 2.43 ms).
Details: doc/performance/gemm_e2e_progress.md section 8.

**Best: 2.906 ms per 10.57 G MAC = 44.5 % of peak end to end** (steady state; KA_K 2560, KA_KC 128; `memtile_ab.py ... 491520 21 163840 3 21 x` then `memtile_split.py ... 491520 21 163840 3 21`), GOLDEN PASS. 41.5 % at K 1152 with `memtile_a3.py`. Earlier: 1.80 ms = 32.3 %,
A triple-buffered in the MemTile (`memtile_a3.py`), NT 3, R 21. With two A buffers,
refilling a tile from DDR did not overlap the replay of the other, and A reached the
cores at ~4.5 GB/s instead of ~8.
