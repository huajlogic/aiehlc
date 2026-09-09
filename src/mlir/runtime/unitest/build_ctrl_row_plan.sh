#!/usr/bin/env bash
# Build and run the pure row-control planner unit tests.
# The planner is C; the test harness is C++ with extern "C", so compile the
# planner as C first, then link.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rt="$(cd "$here/.." && pwd)"
out="${TMPDIR:-/tmp}/acr_test"
gcc -c -I "$rt" -x c "$rt/aie_runtime_control_plan.c" -o "${TMPDIR:-/tmp}/acr_plan.o"
g++ -I "$rt" "$here/test_ctrl_row_plan.cpp" "${TMPDIR:-/tmp}/acr_plan.o" -o "$out"
"$out"
