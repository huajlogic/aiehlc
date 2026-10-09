#!/usr/bin/env bash
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
#
# buildtest.sh -- regenerate conv2dstem's data headers from the TVM flow, then
# build test_conv2d.cc with aiehlc.
#
# test_conv2d.cc runs the DEPLOYED graph's layer 01
#   (01_contrib_conv2d_NCHWc_subtract_add_subtract_fixed_point_multiply_per_axi)
# on the AIE and self-checks against that layer's own output. Both headers it
# needs are generated artifacts -- `layeriohex` dumps produced by running the
# TVM-generated C with tracing on -- so they are not committed, and this script
# is how you get them back.
#
#   1. make local TRACE=1   in worklocal/tvmrelay_deploy/arm_build
#   2. ./main_local.elf     there, which writes layeriohex/
#   3. copy  layeriohex/l01_nn_contrib_conv2d_NCHWc_in.h  -> conv2d_stem_in_weight.h
#            layeriohex/l01_nn_contrib_conv2d_NCHWc_out.h -> conv2d_stem_out_golden.h
#   4. source script/aiehlc.sh on test_conv2d.cc
#
# Usage:
#   ./buildtest.sh                 # all four steps
#   ./buildtest.sh --skip-trace    # reuse the layeriohex already on disk (1+2 are slow)
#   ./buildtest.sh --no-aiehlc     # stop after the headers are in place
#   ./buildtest.sh -h
#
# Env overrides:
#   AIE_VERSION      (default 5)
#   TRACE_HEX_PARAMS (default 0 -- see the note at step 1)
###############################################################################
set -u -o pipefail
# Deliberately NOT `set -e`: step 4 SOURCES script/aiehlc.sh, which is a long
# script with `return` at top level and intermediate commands that legitimately
# fail. Each step below checks its own status instead.

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${APP_DIR}/../../.." && pwd)"
ARM_BUILD="${REPO}/worklocal/tvmrelay_deploy/arm_build"
HEX_DIR="${ARM_BUILD}/layeriohex"

LAYER="l01_nn_contrib_conv2d_NCHWc"
IN_SRC="${HEX_DIR}/${LAYER}_in.h"
OUT_SRC="${HEX_DIR}/${LAYER}_out.h"
IN_DST="${APP_DIR}/conv2d_stem_in_weight.h"
OUT_DST="${APP_DIR}/conv2d_stem_out_golden.h"
ENTRY="${APP_DIR}/test_conv2d.cc"

AIE_VERSION="${AIE_VERSION:-5}"
# The standalone param_*.h set (~72 MB) is NOT needed: every parameter this
# layer uses is already one of its own inputs, so it is inside _in.h. Set to 1
# if you want the by-name copies too.
TRACE_HEX_PARAMS="${TRACE_HEX_PARAMS:-0}"

SKIP_TRACE=0
RUN_AIEHLC=1
for arg in "$@"; do
    case "$arg" in
    --skip-trace) SKIP_TRACE=1 ;;
    --no-aiehlc) RUN_AIEHLC=0 ;;
    -h | --help)
        sed -n '7,31p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
    *)
        echo "buildtest.sh: unknown argument '$arg' (try -h)" >&2
        exit 2
        ;;
    esac
done

say() { printf '\n\033[1m[buildtest] %s\033[0m\n' "$*"; }
die() {
    printf '\n\033[31m[buildtest] ERROR: %s\033[0m\n' "$*" >&2
    exit 1
}

[ -f "${ENTRY}" ] || die "no ${ENTRY}"

# ─────────────────────────────────────────────────────────────────────────────
# 1 + 2. Build and run the local ELF, which writes the layeriohex dumps.
# ─────────────────────────────────────────────────────────────────────────────
if [ "${SKIP_TRACE}" -eq 0 ]; then
    [ -f "${ARM_BUILD}/Makefile" ] ||
        die "no ${ARM_BUILD}/Makefile -- run the TVM flow first:
       PYTHONPATH=src python3 src/frontend/tvmrelay/deploy_flow.py --local"

    # Remove the two files we are about to regenerate, so a failed run is
    # caught at step 3 instead of silently copying yesterday's dump.
    rm -f "${IN_SRC}" "${OUT_SRC}"

    say "1/4  make local TRACE=1  (in ${ARM_BUILD#"${REPO}"/})"
    # clean-local first, and this is NOT belt-and-braces: the object files do
    # not depend on CFLAGS, so if a previous *untraced* `make local` left
    # localobj/ behind, make would relink a stale ELF that compiles none of the
    # trace code and writes no dumps at all -- a silent no-op. Costs a full
    # rebuild of the per-layer TUs every run.
    make -C "${ARM_BUILD}" clean-local >/dev/null 2>&1
    make -C "${ARM_BUILD}" local TRACE=1 "TRACE_HEX_PARAMS=${TRACE_HEX_PARAMS}" ||
        die "make local TRACE=1 failed"

    say "2/4  ./main_local.elf  (writes layeriohex/; this dumps every layer, ~100 MB)"
    # Must run FROM arm_build: graph_dump_hex writes to ./layeriohex relative to
    # the process's working directory, not to the ELF's location.
    ( cd "${ARM_BUILD}" && ./main_local.elf ) || die "main_local.elf failed"
else
    say "1-4  --skip-trace: reusing the layeriohex already on disk"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 3. Copy the layer's input and output dumps in under the names the entry file
#    includes. A plain copy is correct: the variable names inside carry the call
#    index and kernel slug, which is exactly what test_conv2d.cc's TVM_* macros
#    refer to, and the two include guards already differ (..._in_H / ..._out_H).
# ─────────────────────────────────────────────────────────────────────────────
say "3/4  copy the layer-01 dumps into ${APP_DIR#"${REPO}"/}/"
for f in "${IN_SRC}" "${OUT_SRC}"; do
    [ -f "$f" ] || die "missing $(basename "$f").
       The run produced no dump for this layer. Either tracing did not compile
       in (check that TRACE=1 reached CFLAGS) or the graph no longer has a call
       named ${LAYER} -- ls ${HEX_DIR#"${REPO}"/}"
done
cp -f "${IN_SRC}" "${IN_DST}" || die "copy failed: ${IN_DST}"
cp -f "${OUT_SRC}" "${OUT_DST}" || die "copy failed: ${OUT_DST}"
printf '    %-28s %s\n' "$(basename "${IN_DST}")" "$(du -h "${IN_DST}" | cut -f1)"
printf '    %-28s %s\n' "$(basename "${OUT_DST}")" "$(du -h "${OUT_DST}" | cut -f1)"

# Both land FLAT in the app dir on purpose: aiehlc.sh collects user headers with
# a non-recursive *.h glob flattened to basename, so one left in a subdirectory
# parses in the frontend and then fails at cross-g++ (skill conv2dstemfixture).

if [ "${RUN_AIEHLC}" -eq 0 ]; then
    say "--no-aiehlc: stopping with the headers in place"
    exit 0
fi

# ─────────────────────────────────────────────────────────────────────────────
# 4. Build with aiehlc. It must be SOURCED, not executed: it uses `return` at
#    top level and exports AIEHLC_DIR for the rest of the toolchain.
# ─────────────────────────────────────────────────────────────────────────────
say "4/4  aiehlc build of $(basename "${ENTRY}")"

# A freshness marker, because "the ELF exists" is not the same as "this run
# built it" -- see the cd below for how they came apart.
MARKER="$(mktemp "${TMPDIR:-/tmp}/buildtest.XXXXXX")"
trap 'rm -f "${MARKER}"' EXIT

# cd to the repo root FIRST. aiehlc.sh writes its aout/ tree relative to the
# CURRENT WORKING DIRECTORY, not relative to the entry file or to its own
# location, so running this script from the app directory silently produces
# src/aietensorop/conv2dstem/aout/ while leaving any older $REPO/aout/ in place
# -- and a check for the latter then passes against a stale ELF. Pinning the
# cwd here is what makes the output path mean something.
cd "${REPO}" || die "cannot cd to ${REPO}"

# shellcheck source=/dev/null
source "${REPO}/script/aiehlc.sh" --aie-version "${AIE_VERSION}" --runtime-source-file "${ENTRY}"
rc=$?

ELF="${REPO}/aout/worklocal/build/host"
if [ "${rc}" -ne 0 ]; then
    die "aiehlc build failed (rc=${rc})"
fi
[ -f "${ELF}" ] || die "aiehlc reported success but there is no ${ELF#"${REPO}"/}"
[ "${ELF}" -nt "${MARKER}" ] ||
    die "${ELF#"${REPO}"/} is older than this run -- the build did not produce it.
       Check where aiehlc.sh actually wrote its aout/ tree."

say "done"
printf '    ELF: %s  (%s)\n' "${ELF#"${REPO}"/}" "$(du -h "${ELF}" | cut -f1)"
printf '    run on hardware:  python3 script/test/apppaltest.py %s\n' "${ELF#"${REPO}"/}"
printf '    expect:           [conv2dstem] GOLDEN PASS 802816/802816\n'
