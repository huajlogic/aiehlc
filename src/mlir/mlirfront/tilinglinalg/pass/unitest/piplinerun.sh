#!/bin/bash
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: MIT
###############################################################################
source ../../../../../../script/setup.sh --path-set-only
pushd ./build
make -j4
popd
./build/test
pushd ./worklocal/
source hostcompile.sh
popd
apppaltest.py ./worklocal/build/host
