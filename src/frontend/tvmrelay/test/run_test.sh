#!/bin/bash
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
# Convenience wrapper for test_aie_offload.py.
#
# The Python test already pins its own cwd and PYTHONPATH -- deploy_flow.py's
# DEFAULT_OUT is ./worklocal/tvmrelay_deploy, relative to the cwd, so running it
# from the wrong directory silently writes a SECOND output tree elsewhere and
# the comparison then runs against a stale one.  This script exists only so the
# test can be invoked as `bash run_test.sh` with the repo's own bash rather than
# whatever /bin/sh or tcsh happens to be interactive here.
#
#   bash run_test.sh                      # full run + verify
#   bash run_test.sh --skip-run           # verify the tree already on disk
#   bash run_test.sh --update-golden      # capture today's layers/ as reference
#   bash run_test.sh --deploy-args "--no-arm"
#
# Stage 6 of deploy_flow.py needs the cross toolchain; source it first if you
# want the board ELF linked:
#
#   source script/setup.sh --path-set-only
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${HERE}/../../../../" && pwd)"
PYTHON="${PYTHON:-python3}"

exec "${PYTHON}" "${HERE}/test_aie_offload.py" "$@"
