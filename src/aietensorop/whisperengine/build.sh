#!/usr/bin/env bash
# Build one whisperengine app (m0, eng, ...) into a scratch worklocal and link a
# host ELF with hostcompile.sh. Usage: build.sh <app dir> [out dir]
# Fabric: FABRIC=<dir> (default ./fabric) supplies routing.cc + aieml.prx +
# engine_fabric.h. KDEFS="A=1 B" prepends #defines to kernel.cc, HDEFS to host.cc.
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
for d in ${HDEFS:-}; do sed -i "1i #define ${d/=/ }" "$W/host.cc"; done
source "$REPO/script/setup.sh" >/dev/null 2>&1
if [ ! -f "$REPO/thirdparty/alib/lib/libxaienginea78.a" ]; then
    (cd "$REPO" && source script/aiehlc.sh --aie-version 5 --aielib-only) > "$OUT/aielib.log" 2>&1 \
        || { echo "aielib staging failed (log $OUT/aielib.log)"; exit 1; }
fi
cd "$OUT"
# The persistent kernel runs every op from one 16 KB program memory: size-optimize
# the LLVM front end (hot MAC loops keep their chess schedule, checked in kernel.lst).
export KC_OPT_LEVEL="${KC_OPT_LEVEL:--Os}"
WORKLOCAL_DIR="$W" AIE_VERSION=5 PLATFORM=baremetal AIEHLC_PROFILING="${PROFILING:-0}" \
    bash "$REPO/script/hostcompile.sh" > "$OUT/build.log" 2>&1
rc=$?
# AIE2PS program memory is 16 KB and an overflow only shows at load time
# ("Overflow of program memory", the tail silently dropped). The map's "Used" omits
# alignment padding: check the end address of the last PM item instead.
MAP="$W/build/kernel.map"
if [ -f "$MAP" ]; then
    pm_end=$(awk '/Memory map for memory .PM./{f=1} /Memory map for memory .DM/{f=0} f && /items\) :/{split($1,a,"\\.\\."); e=a[2]} END{print e}' "$MAP")
    if [ -n "$pm_end" ] && [ $((pm_end)) -ge $((0x4000)) ]; then
        echo "BUILD FAILED: kernel program memory ends at $pm_end, past 16 KB (0x4000)"; exit 1
    fi
fi
if [ -f "$W/build/host" ]; then echo "built $W/build/host (kernel PM end ${pm_end:-?})"; else echo "BUILD FAILED rc=$rc (log $OUT/build.log)"; grep -n 'error' "$OUT/build.log" | head; exit 1; fi
