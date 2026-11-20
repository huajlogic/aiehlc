# K-accumulating GEMM with MemTile-staged operands (hand experiment)

`gemm_kacc_ntile.cc`: int8 GEMM, int32 C tile per core across K chunks, n-tile loop.
The traced (x86) path describes what the shim sends (each A / B block once); the core
path consumes A(m) NT times and B(n) R times -- `memtile_ab.py` makes the MemTiles
replay them (B resident per column, A double-buffered per mesh row).

    AIEHLC_KB_CHECK_WARN=1 source script/aiehlc.sh --aie-version 5 --runtime-source-file $PWD/gemm_kacc_ntile.cc
    python3 memtile_ab.py aout/worklocal 294912 16 73728 4 16 x
    rm -f aout/worklocal/build/{host.o,routing.o,host}
    WORKLOCAL_DIR=$PWD/aout/worklocal AIE_VERSION=5 PLATFORM=baremetal bash script/hostcompile.sh
    python3 script/test/apppaltest.py aout/worklocal/build/host -y --netload

palmyra: 2.51 ms per 4.83 G MAC = 23.5 % of peak end to end, GOLDEN PASS.
Details: doc/performance/gemm_e2e_progress.md section 8.
