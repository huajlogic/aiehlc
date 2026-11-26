#!/bin/bash
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
# Regression gate of doc/plan/dataflowplan_unify_ir.md.
#
#   script/test/plan_regress.sh snapshot <dir> [source ...]   build each gate source, keep its generated files
#   script/test/plan_regress.sh compare  <dir> [source ...]   build again, compare with <dir>, check flowcheck
#
# Sources default to the gate list below (paths relative to example/tileprogram/ccode, without .cc).
# compare exits 0 when every non-plan source is byte-identical and every source has `flowcheck: OK`;
# a plan source whose files changed is listed (`plan files changed: ...`), not failed: the stage decides.
# Each build's log and generated files stay in <dir>/<tag>.new/ (compare) or <dir>/<tag>/ (snapshot).
# Run from anywhere; builds run in the repository root, one at a time (never two aiehlc.sh at once).
set -uo pipefail
MODE=${1:?snapshot|compare}
REF=${2:?reference dir}
shift 2
R=$(cd "$(dirname "$0")/../.." && pwd)
C=$R/example/tileprogram/ccode
NONPLAN="simplematmul2 simplegemm_kernel_port simplegemm_dataflow simpleconv2d simpleconv2dkernel_port_less"
PLAN="simpleeltwise_add_none gemm_plan/gemm_plan gemm_plan/gemm_plan_4x2 gemm_plan/gemm_plan_bring simpleeltwise_add_plan simpleconv2dkernel_port_plan"
SRCS=${*:-$NONPLAN $PLAN}
FILES="host.cc kernel.cc routing.cc aiehlc_plan.h"
mkdir -p "$REF"
rc=0
for s in $SRCS; do
    tag=$(basename "$s")
    case " $NONPLAN " in *" $s "*) kind=nonplan ;; *) kind=plan ;; esac
    if [ "$MODE" = snapshot ]; then out=$REF/$tag; else out=$REF/$tag.new; fi
    rm -rf "$out"
    mkdir -p "$out"
    touch "$out/.start"
    (cd "$R" && bash -c "source script/aiehlc.sh --aie-version 5 --runtime-source-file $C/$s.cc") >"$out/build.log" 2>&1
    brc=$?
    fc=$(grep -a 'flowcheck' "$out/build.log" | tail -1)
    if [ $brc -ne 0 ] || [ ! -f "$R/aout/worklocal/build/host" ] || [ "$R/aout/worklocal/build/host" -ot "$out/.start" ]; then
        echo "$tag: FAIL build rc=$brc ($(grep -a -m1 -E 'ERROR|error:' "$out/build.log" | cut -c1-160))"
        rc=1
    else
        for f in $FILES; do cp "$R/aout/worklocal/$f" "$out/" 2>/dev/null; done
        cp "$R/aout/worklocal/build/host" "$out/host"
    fi
    # the build rewrites tracked IR dumps and generated .inc files: put them back
    (cd "$R" && git checkout -- ir/ src/mlir/mlirfront/*.inc src/mlir/mlirfront/mlirlinkrelocate/*.inc 2>/dev/null)
    [ $brc -ne 0 ] && continue
    if [ "$MODE" = snapshot ]; then
        echo "$tag: snapshot ($kind; $fc)"
        continue
    fi
    d=""
    for f in $FILES; do
        [ -f "$REF/$tag/$f" ] || [ -f "$out/$f" ] || continue
        cmp -s "$REF/$tag/$f" "$out/$f" || d="$d $f"
    done
    if [ -n "$d" ] && [ $kind = nonplan ]; then
        echo "$tag: FAIL non-plan files differ:$d"
        rc=1
    elif ! echo "$fc" | grep -q 'flowcheck: OK'; then
        echo "$tag: FAIL $fc"
        rc=1
    else
        echo "$tag: ok ($kind${d:+; plan files changed:$d}; $fc)"
    fi
done
exit $rc
