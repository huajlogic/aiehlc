#!/bin/bash
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: MIT
###############################################################################
# Compile generated host.cc with aie_runtime and Xilinx AIE libs.
# Uses the same env and link recipe as script/aiehlc.sh (baremetal).
# Usage: run from worklocal/ or: ./hostcompile.sh [--aie-version 2] [--platform baremetal]
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Repo root: script in script/ -> one level up; script in worklocal/ -> 7 levels up
if [[ "${SCRIPT_DIR}" == *"/script" ]]; then
    AIEHLC_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
else
    AIEHLC_ROOT="$(cd "${SCRIPT_DIR}/../../../../../../../" && pwd)"
fi
AIEHLC_DIR="${AIEHLC_ROOT}"
WORKLOCAL_DIR="${AIEHLC_ROOT}/src/mlir/mlirfront/tilinglinalg/pass/unitest/worklocal"
BUILD_DIR="${WORKLOCAL_DIR}/build"

# Defaults (match aiehlc.sh)
aie_version="${AIE_VERSION:-2}"
platform="${PLATFORM:-baremetal}"

if [ ! -f "${WORKLOCAL_DIR}/host.cc" ]; then
    echo "Error: host.cc not found in ${WORKLOCAL_DIR}"
    echo "Run the unitest (e.g. ./test dfschedule) to generate host.cc first."
    exit 1
fi

# pushd to the script directory
pushd "${SCRIPT_DIR}"
# Source env (XILINX_VITIS, etc.) same as aiehlc.sh
# Export PATH_SET_ONLY so setup.sh's first test does not see unset (avoids "integer expression expected")
if [ -f "${AIEHLC_ROOT}/script/setup.sh" ]; then
    export PATH_SET_ONLY="${PATH_SET_ONLY:-1}"
    source "${AIEHLC_ROOT}/script/setup.sh" --path-set-only
fi

if [ -z "${XILINX_VITIS}" ]; then
    echo "Warning: XILINX_VITIS not set. Link may fail (undefined XAie_*)."
    echo "Source script/setup.sh from repo root or set XILINX_VITIS."
fi

# Toolchain: same as aiehlc.sh (baremetal -> aarch64-none-elf-g++/gcc, linux -> aarch64-linux-gnu-).
# Override with CROSS_COMPILE (e.g. CROSS_COMPILE=aarch64-none-elf- ./hostcompile.sh) when another toolchain is first in PATH.
if [[ -n "${CROSS_COMPILE}" ]]; then
    TOOL_PREFIX="${CROSS_COMPILE}"
    [[ "${TOOL_PREFIX}" != *"-" ]] && TOOL_PREFIX="${TOOL_PREFIX}-"
elif [[ "$platform" == "linux" ]]; then
    TOOL_PREFIX="aarch64-linux-gnu-"
elif [[ "$platform" == "baremetal" ]]; then
    TOOL_PREFIX="aarch64-none-elf-"
else
    echo "Unsupported platform: $platform (use baremetal or linux)"
    exit 1
fi

XILINX_VITIS_AIETOOLS="${XILINX_VITIS}/aietools"
LOCAL_ALIB_INCLUDE="${AIEHLC_DIR}/thirdparty/alib/include"
if [ -d "${LOCAL_ALIB_INCLUDE}/xaiengine" ] && [ "$(ls -A ${LOCAL_ALIB_INCLUDE}/xaiengine 2>/dev/null)" ]; then
    AIETOOLS_INCLUDE_BASE="${LOCAL_ALIB_INCLUDE}"
else
    AIETOOLS_INCLUDE_BASE="${XILINX_VITIS_AIETOOLS}/include/drivers/aiengine"
fi

ARCH_DIR="${AIEHLC_DIR}/thirdparty/arch"
ARCH_72_DIR="${ARCH_DIR}/psv_cortexa72_0/workspace/platform_baremetal/psv_cortexa72_0/standalone_psv_cortexa72_0/bsp"
ARCH_78_DIR="${ARCH_DIR}/cortexa78_0/workspace/platform_baremetal/cortexa78_0/standalone_cortexa78_0/bsp"
AIE_DRIVER_PARENT_DIR="${AIEHLC_DIR}/thirdparty/alib"
ALIB_LIB_DIR="${AIEHLC_ROOT}/thirdparty/alib/lib"
USE_LOCAL_AIERT_BSP=0
if [ -d "${AIE_DRIVER_PARENT_DIR}/aie-rt/driver/" ]; then
    USE_LOCAL_AIERT_BSP=1
fi
USE_LOCAL_AIERT_BSP="${USE_LOCAL_AIERT_BSP:-0}"

# If default aie_version=2 but only libxaienginea78.a exists, use aie version 5
if [[ "$aie_version" == "2" ]] && [ -d "${ALIB_LIB_DIR}" ]; then
    if [ ! -f "${ALIB_LIB_DIR}/libxaienginea72.a" ] && [ -f "${ALIB_LIB_DIR}/libxaienginea78.a" ]; then
        aie_version="5"
        echo "Using AIE version 5 (libxaienginea78.a found; libxaienginea72.a not in ${ALIB_LIB_DIR})"
    fi
fi

if [ "$USE_LOCAL_AIERT_BSP" -eq 0 ]; then
    BAREMETAL_AIENGINE_INCLUDE="${XILINX_VITIS_AIETOOLS}/include/drivers/aiengine"
else
    BAREMETAL_AIENGINE_INCLUDE="${AIE_DRIVER_PARENT_DIR}/include"
fi

# Fallback xaiengine path when headers live under huaj-aie-rt/driver/include (for XAie_MemInst etc.)
XAIE_INCLUDE="${AIEHLC_ROOT}/thirdparty/alib/huaj-aie-rt/driver/include"

if [[ "$aie_version" == "1" || "$aie_version" == "2" ]]; then
    ARCH_APU_ALIB="${ARCH_72_DIR}/lib"
    ARCH_APU_AINC="${ARCH_72_DIR}/include"
    SECONDARY_ARCH_APU_AINC="${ARCH_DIR}/psv_cortexa72_0/bsp/include"
    AIELIB_APU_NAME="libxaienginea72.a"
    ARCH_APU_LD="${ARCH_DIR}/psv_cortexa72_0/lscript.ld"
    compiler_cpu_flag="-mcpu=cortex-a72"
    LINK_EXTRA="-lxilstandalone"
elif [[ "$aie_version" == "5" ]]; then
    ARCH_APU_ALIB="${ARCH_78_DIR}/lib"
    ARCH_APU_AINC="${ARCH_78_DIR}/include"
    SECONDARY_ARCH_APU_AINC="${ARCH_DIR}/cortexa78_0/bsp/include"
    AIELIB_APU_NAME="libxaienginea78.a"
    ARCH_APU_LD="${ARCH_DIR}/cortexa78_0/lscript.ld"
    compiler_cpu_flag="-mcpu=cortex-a78"
    LINK_EXTRA="-lxiltimer,-lxilstandalone"
else
    echo "Unsupported AIE version: $aie_version"
    exit 1
fi

# AIENGINE_LIB_DIR: Vitis BSP build output for aienginev2 (same as aiehlc.sh)
AIENGINE_LIB_DIR="${ARCH_APU_ALIB}/../libsrc/build_configs/gen_bsp/libsrc/aienginev2/src"
if [ "$USE_LOCAL_AIERT_BSP" -eq 0 ]; then
    BAREMETAL_AIENGINE_LIB="aienginev2"
else
    BAREMETAL_AIENGINE_LIB="${AIELIB_APU_NAME:3:-2}"
fi

# Include options: aiehlc host + aie_runtime.h; add xaiengine path when present (xaiengine.h, xaiengine/*.h)
INCLUDE_OPTS="-I${AIEHLC_ROOT}/include -I${AIETOOLS_INCLUDE_BASE} -I${AIE_DRIVER_PARENT_DIR}/include -I${ARCH_APU_AINC} -I${SECONDARY_ARCH_APU_AINC}"
if [ -d "${XAIE_INCLUDE}" ]; then
    INCLUDE_OPTS="${INCLUDE_OPTS} -I${XAIE_INCLUDE}"
fi
DEFS="-DAIE_GEN=${aie_version}"

mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

echo "============================================"
echo "Host compilation (host.cc + aie_runtime)"
echo "============================================"
echo "Source: ${WORKLOCAL_DIR}/host.cc"
echo "Output: ${BUILD_DIR}/host"
echo "Platform: $platform  AIE version: $aie_version"
echo ""

# Fix generated host.cc for C++: forward decl, int main(), return 0 in main, __global__
HOST_FIXED="${BUILD_DIR}/host_fixed.cc"
sed -e '/#include "aie_runtime.h"/a\
void host_canonicalized();\
#define __global__
' \
    -e 's/void main()/int main()/' \
    -e '0,/^  return;$/s/^  return;$/  return 0;/' \
    "${WORKLOCAL_DIR}/host.cc" > "${HOST_FIXED}"
HOST_SRC="${HOST_FIXED}"

# Compile host
set -x
echo "Compiling host..."
${TOOL_PREFIX}g++ -Os -std=c++17 ${DEFS} ${INCLUDE_OPTS} ${compiler_cpu_flag} -c "${HOST_SRC}" -o host.o
if [ $? -ne 0 ]; then
    echo "Error: failed to compile host.cc"
    exit 1
fi
set +x
# Compile aie_runtime.c
echo "Compiling aie_runtime.c..."
${TOOL_PREFIX}g++ -Os -std=c++17 ${DEFS} ${INCLUDE_OPTS} ${compiler_cpu_flag} -c "${AIEHLC_ROOT}/src/mlir/runtime/aie_runtime.c" -o aie_runtime.o
if [ $? -ne 0 ]; then
    echo "Error: failed to compile aie_runtime.c"
    exit 1
fi
set -x
# Link (same libs as aiehlc.sh baremetal host link: -L and -l for XAie_* and BSP)
# --specs=nosys.specs provides stubs for _exit, _close, _fstat, etc. (baremetal/newlib)
# -Wl,--defsym,end=__bss_end__ defines 'end' for newlib _sbrk (lscript.ld defines __bss_end__)
echo "Linking host..."
${TOOL_PREFIX}g++ -Os -o host host.o aie_runtime.o \
    --specs=nosys.specs \
    -Wl,--defsym,end=__bss_end__ \
    -Wl,-T -Wl,${ARCH_APU_LD} \
    -L"${ALIB_LIB_DIR}" \
    -L"${AIENGINE_LIB_DIR}" \
    -L"${ARCH_APU_ALIB}" \
    -L"${AIE_DRIVER_PARENT_DIR}/lib" \
    -Wl,--start-group,-lm,-l${BAREMETAL_AIENGINE_LIB},-lxil,-lgcc,-lc,-lstdc++,${LINK_EXTRA},--end-group
if [ $? -ne 0 ]; then
    echo "Error: link failed (check XILINX_VITIS and BSP libs)"
    exit 1
fi

echo ""
echo "============================================"
echo "Host built successfully: ${BUILD_DIR}/host"
echo "============================================"
ls -l host
# popd to the original directory
popd
