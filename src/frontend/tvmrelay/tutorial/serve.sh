#!/bin/bash
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################
# Serve the TVM -> AIE developer tutorial over HTTP.
#
#   bash src/frontend/tvmrelay/tutorial/serve.sh            # port 8781
#   PORT=9000 bash src/frontend/tvmrelay/tutorial/serve.sh
#
# Then open http://<this-host>:8781/ in a browser. index.html is
# self-contained (no CDN, no JS), so it also opens straight from disk.
# Binds 0.0.0.0 so it is reachable from your desktop; set BIND=127.0.0.1 to
# keep it local and use an ssh tunnel (ssh -L 8781:localhost:8781 <host>).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${PORT:-8781}"
BIND="${BIND:-0.0.0.0}"

if ss -ltn 2>/dev/null | grep -q ":${PORT} "; then
    echo "serve.sh: port ${PORT} is already in use on this host -- pick another: PORT=8790 bash $0" >&2
    exit 1
fi
echo "tutorial: http://$(hostname -f 2>/dev/null || hostname):${PORT}/"
# cd first instead of --directory: a stray http.py in the cwd (e.g. /tmp)
# would shadow the stdlib module and the server would not start.
cd "${HERE}"
exec python3 -m http.server "${PORT}" --bind "${BIND}"
