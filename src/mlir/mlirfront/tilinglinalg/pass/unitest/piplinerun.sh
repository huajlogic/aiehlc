#!/bin/bash
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: MIT
###############################################################################
set -e

# Parse arguments: accept 'rebuild' or '-rebuild' to force steps 2-3 (cmake/make/test)
REBUILD=0
for arg in "$@"; do
    if [[ "$arg" == "rebuild" || "$arg" == "-rebuild" ]]; then
        REBUILD=1
    fi
done

echo "=== Step 1: Source environment ==="
pushd .
source ../../../../../../script/setup.sh --path-set-only
popd

pushd .
source ../../../../../../script/aiehlc.sh --aielib-only --aie-version 5
popd

if [ "${REBUILD}" -eq 1 ]; then
    echo "=== Step 2: Build unitest ==="
    if [ ! -d "./build" ]; then
        mkdir -p ./build
        pushd ./build
        cmake ..
    else
        pushd ./build
    fi
    make -j4
    popd

    echo "=== Step 3: Run unitest (generate host.cc + kernel.cc) ==="
    pushd ./build/
    ./test
    popd
else
    echo "=== Step 2+3: Skipped (pass 'rebuild' or '-rebuild' to regenerate host.cc + kernel.cc) ==="
fi

echo "=== Step 4: Compile host + kernel (hostcompile.sh) ==="
pushd ./worklocal/
REBUILD_ARG=""
[ "${REBUILD}" -eq 1 ] && REBUILD_ARG="rebuild"
source hostcompile.sh
popd

echo "=== Step 5: Run on HW (apppaltest) ==="
source ~/palmtest/envlocal.sh
apppaltest.py ./worklocal/build/host

echo "=== Pipeline completed successfully ==="