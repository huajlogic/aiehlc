#!/usr/bin/env bash
# Build one resnetengine app (e0, ...) into a scratch worklocal and link a host ELF
# with hostcompile.sh. Usage: build.sh <app dir under resnetengine> [out dir]
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../../.." && pwd)"
APP="$1"; OUT="${2:-/tmp/claude/re_$APP}"
SRC="$HERE/$APP"
rm -rf "$OUT"; mkdir -p "$OUT/aout/worklocal"
W="$OUT/aout/worklocal"
cp "$SRC"/*.cc "$SRC"/*.h "$SRC"/aieml.bcf "$W"/ 2>/dev/null
cp "$HERE"/*.h "$W"/
# Generated inputs (e.g. layeriohex dumps) the app includes: paths relative to the repo.
if [ -f "$SRC/extra_inputs.txt" ]; then
    while read -r f; do [ -n "$f" ] && cp "$REPO/$f" "$W"/ || exit 1; done < "$SRC/extra_inputs.txt"
fi
cp "$HERE/fabric/routing.cc" "$HERE/fabric/aieml.prx" "$W"/
# Experiment knobs: KDEFS="A B" prepends #define A / #define B to kernel.cc.
for d in ${KDEFS:-}; do sed -i "1i #define $d" "$W/kernel.cc"; done
source "$REPO/script/setup.sh" >/dev/null 2>&1
# hostcompile links thirdparty/alib/lib/libxaienginea78.a, which aiehlc.sh
# (re)stages at the start of every run and wipes per run -- stage it if absent.
if [ ! -f "$REPO/thirdparty/alib/lib/libxaienginea78.a" ]; then
    (cd "$REPO" && source script/aiehlc.sh --aie-version 5 --aielib-only) > "$OUT/aielib.log" 2>&1 \
        || { echo "aielib staging failed (log $OUT/aielib.log)"; exit 1; }
fi
cd "$OUT"
WORKLOCAL_DIR="$W" AIE_VERSION=5 PLATFORM=baremetal AIEHLC_PROFILING="${PROFILING:-0}" \
    bash "$REPO/script/hostcompile.sh" > "$OUT/build.log" 2>&1
rc=$?
if [ -f "$W/build/host" ]; then echo "built $W/build/host"; else echo "BUILD FAILED rc=$rc (log $OUT/build.log)"; grep -n 'error' "$OUT/build.log" | head; exit 1; fi
