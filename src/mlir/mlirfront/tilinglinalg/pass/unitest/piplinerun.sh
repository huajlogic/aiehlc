#!/bin/bash
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: MIT
###############################################################################
set -e

echo "=== Step 1: Source environment ==="
source ../../../../../../script/setup.sh --path-set-only

source .../../../../../../script/aiehlc.sh --aielib-only

echo "=== Step 2: Build unitest ==="
pushd ./build
make -j4
popd

echo "=== Step 3: Run unitest (generate host.cc + kernel.cc) ==="
./build/test dfschedule

echo "=== Step 4: Compile host + kernel (hostcompile.sh) ==="
pushd ./worklocal/
source hostcompile.sh
popd

echo "=== Step 5: Run on HW (apppaltest) ==="
source ../../../../../../script/test/envlocal.sh
apppaltest.py ./worklocal/build/host

echo "=== Pipeline completed successfully ==="
