#!/usr/bin/env python3
import subprocess
r = subprocess.run(
    ['make', '-j4', '-C', '/scratch/staff/huaj/amdaiehlc/aiehlc/src/mlir/mlirfront/tilinglinalg/pass/unitest/build'],
    capture_output=True, text=True
)
out = r.stdout + r.stderr + f'\nEXIT:{r.returncode}\n'
open('/scratch/staff/huaj/amdaiehlc/aiehlc/build_out3.txt', 'w').write(out)
