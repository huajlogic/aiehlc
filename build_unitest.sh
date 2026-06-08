#!/bin/bash
cd /scratch/staff/huaj/aiehlc/aiehlc/src/mlir/mlirfront/tilinglinalg/pass/unitest/build
cmake --build . -- -j4 > /scratch/staff/huaj/aiehlc/aiehlc/compilelog 2>&1
echo "BUILDRESULT=$?" >> /scratch/staff/huaj/aiehlc/aiehlc/compilelog
