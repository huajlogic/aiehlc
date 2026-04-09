#!/bin/bash
make -j4 -C /scratch/staff/huaj/amdaiehlc/aiehlc/src/mlir/mlirfront/tilinglinalg/pass/unitest/build > /scratch/staff/huaj/amdaiehlc/aiehlc/build_out3.txt 2>&1
echo "EXIT:$?" >> /scratch/staff/huaj/amdaiehlc/aiehlc/build_out3.txt
