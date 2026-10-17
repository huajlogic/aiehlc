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
KSRC="$W/kernel.cc"
if grep -q 'WE_PROG' "$W/kernel.cc" 2>/dev/null; then
    # one source, two programs (kernel.cc WE_PROG): hostcompile's multi-kernel mode
    # embeds _binary_kernel_eng_start (GEMM) and _binary_kernel_att_start (attention)
    mv "$W/kernel.cc" "$W/we_kernel.cc"
    KSRC="$W/we_kernel.cc"
    printf '#define WE_PROG 1\n#include "we_kernel.cc"\n' > "$W/kernel_eng.cc"
    printf '#define WE_PROG 2\n#include "we_kernel.cc"\n' > "$W/kernel_att.cc"
fi
for d in ${KDEFS:-}; do sed -i "1i #define ${d/=/ }" "$KSRC"; done
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
pm_ends=""
for MAP in "$W"/build/kernel_*.map "$W/build/kernel.map"; do
    [ -f "$MAP" ] || continue
    case "$MAP" in */kernel.map) ls "$W"/build/kernel_*.map >/dev/null 2>&1 && continue ;; esac
    pm_end=$(awk '/Memory map for memory .PM./{f=1} /Memory map for memory .DM/{f=0} f && /items\) :/{split($1,a,"\\.\\."); e=a[2]} END{print e}' "$MAP")
    pm_ends="$pm_ends $(basename "$MAP" .map)=$pm_end"
    if [ -n "$pm_end" ] && [ $((pm_end)) -ge $((0x4000)) ]; then
        echo "BUILD FAILED: $(basename "$MAP" .map) program memory ends at $pm_end, past 16 KB (0x4000)"; exit 1
    fi
done
if [ -f "$W/build/host" ]; then echo "built $W/build/host (PM end:${pm_ends:- ?})"; else echo "BUILD FAILED rc=$rc (log $OUT/build.log)"; grep -n 'error' "$OUT/build.log" | head; exit 1; fi
