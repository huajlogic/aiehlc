#!/usr/bin/env bash
# Build one whisperengine app (m0, eng, ...) into a scratch worklocal and link a
# host ELF with hostcompile.sh. Usage: build.sh <app dir> [out dir]
# Fabric: FABRIC=<dir> (default ./fabric) supplies routing.cc + aieml.prx +
# engine_fabric.h. KDEFS="A=1 B" prepends #defines to kernel.cc.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../../.." && pwd)"
APP="$1"; OUT="${2:-$REPO/worklocal/whisperengine/build_$APP}"
SRC="$HERE/$APP"
FAB="${FABRIC:-$HERE/fabric}"
rm -rf "$OUT"; mkdir -p "$OUT/aout/worklocal"
W="$OUT/aout/worklocal"
cp "$SRC"/*.cc "$SRC"/aieml.bcf "$W"/
cp "$SRC"/*.h "$W"/ 2>/dev/null
cp "$HERE"/*.h "$W"/ 2>/dev/null
cp "$FAB/routing.cc" "$FAB/aieml.prx" "$FAB/engine_fabric.h" "$W"/
if [ -f "$SRC/extra_inputs.txt" ]; then
    while read -r f; do [ -n "$f" ] && cp "$REPO/$f" "$W"/ || exit 1; done < "$SRC/extra_inputs.txt"
fi
for d in ${KDEFS:-}; do sed -i "1i #define ${d/=/ }" "$W/kernel.cc"; done
source "$REPO/script/setup.sh" >/dev/null 2>&1
if [ ! -f "$REPO/thirdparty/alib/lib/libxaienginea78.a" ]; then
    (cd "$REPO" && source script/aiehlc.sh --aie-version 5 --aielib-only) > "$OUT/aielib.log" 2>&1 \
        || { echo "aielib staging failed (log $OUT/aielib.log)"; exit 1; }
fi
cd "$OUT"
WORKLOCAL_DIR="$W" AIE_VERSION=5 PLATFORM=baremetal AIEHLC_PROFILING="${PROFILING:-0}" \
    bash "$REPO/script/hostcompile.sh" > "$OUT/build.log" 2>&1
rc=$?
if [ -f "$W/build/host" ]; then echo "built $W/build/host"; else echo "BUILD FAILED rc=$rc (log $OUT/build.log)"; grep -n 'error' "$OUT/build.log" | head; exit 1; fi
