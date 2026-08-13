#!/usr/bin/env bash
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
# Clone/install aiedbg for the live debug UI and write .aiehlc/aiedbg_env.sh.
#
# Usage:
#   script/debug/bootstrap_aiedbg.sh           # install if missing
#   script/debug/bootstrap_aiedbg.sh --update  # git pull + pip upgrade
#
# Environment:
#   AIEHLC_AIEDBG_REPO  git URL (default: AMD-AECG-SSWSIP/aiedbg on GitHub)
#   AIEHLC_AIEDBG_SRC   use an existing clone instead of thirdparty/aiedbg
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AIEHLC_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

exec python3 "${AIEHLC_DIR}/src/tool/debug/ensure_aiedbg.py" \
    --repo-root "${AIEHLC_DIR}" "$@"
