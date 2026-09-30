#!/usr/bin/env bash
###############################################################################
# Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################

set -euo pipefail

mode="${1:-}"
log="ci-sim.log"
public="ci-public.log"
: >"$log"

redact() {
    local ws="${GITHUB_WORKSPACE:-}"
    if [ -n "${ws}" ]; then
        sed -E \
            -e "s|${ws}|.|g" \
            -e 's|/scratch/staff/[^[:space:]]+|<user>|g' \
            -e 's|/home/[^[:space:]]+|<user>|g' \
            -e 's|/Users/[^[:space:]]+|<user>|g' \
            -e 's|/proj/[^[:space:]]+|<tools>|g'
    else
        sed -E \
            -e 's|/scratch/staff/[^[:space:]]+|<user>|g' \
            -e 's|/home/[^[:space:]]+|<user>|g' \
            -e 's|/Users/[^[:space:]]+|<user>|g' \
            -e 's|/proj/[^[:space:]]+|<tools>|g'
    fi
}

finish_fail() {
    trap - ERR
    {
        echo "FAIL: ${label}"
        excerpt="$(grep -E 'Mismatch|Failure|failed|error:|Error|CMake Error|unbound|undefined|CRITICAL|axi_mm|Sim result|PASS:|passed' "$log" | tail -n 30 || true)"
        if [ -n "${excerpt}" ]; then
            printf '%s\n' "${excerpt}" | redact
        else
            tail -n 20 "$log" | redact
        fi
    } | tee "$public"
    exit 1
}

case "$mode" in
    tutorial)
        label="single-kernel tutorial/example.cpp"
        sim_dir="aout"
        src="tutorial/example.cpp"
        tiles="4:4"
        markers=(
            "Sucess: CPU result matches AIE."
            "Kernel test passed!"
            "Simulation Finished, Sim result: 0"
        )
        ;;
    passthrough)
        label="tilinglinalg passthrough_sim.cc"
        sim_dir="aout/worklocal"
        src="example/tileprogram/ccode/passthrough_sim.cc"
        tiles="0:3"
        markers=(
            "[passthrough] PASS:"
            "Kernel test passed!"
            "Simulation Finished, Sim result: 0"
        )
        ;;
    *)
        echo "usage: pr_sim_test.sh tutorial|passthrough"
        exit 2
        ;;
esac

shift
trap finish_fail ERR

root="$(pwd)"
llvm_dir="${LLVM_INSTALL_DIR:-}"
if [ -z "${llvm_dir}" ] || [[ "${llvm_dir}" == /Users/* ]]; then
    fallback="/scratch/staff/huaj/llvm-project/build"
    if [ -x "${fallback}/bin/llvm-config" ]; then
        llvm_dir="${fallback}"
    else
        echo "LLVM_INSTALL_DIR is not set."
        exit 1
    fi
fi

source script/setup.sh >>"$log" 2>&1
export LLVM_INSTALL_DIR="${llvm_dir}"
cd "${root}"

cmake -S . -B build -DLLVM_INSTALL_DIR="${LLVM_INSTALL_DIR}" -DCMAKE_BUILD_TYPE=Release -Wno-dev >>"$log" 2>&1
cmake --build build -j"$(nproc)" --target aiehlc >>"$log" 2>&1

source script/aiehlc.sh \
    --platform sim --aie-version 5 --sim-tiles "${tiles}" \
    --runtime-source-file "${src}" >>"$log" 2>&1
cd "${root}"

export AIEHLC_DBG_HOLD_SEC=0
set +e
bash script/runsim.sh "${sim_dir}" >>"$log" 2>&1
sim_rc=$?
set -e

missing=0
for marker in "${markers[@]}"; do
    if ! grep -q -F "${marker}" "$log"; then
        missing=1
    fi
done

if [ "${missing}" -ne 0 ] || [ "${sim_rc}" -ne 0 ]; then
    finish_fail
fi

{
    echo "PASS: ${label}"
    printf '%s\n' "${markers[@]}"
} | tee "$public"
exit 0
