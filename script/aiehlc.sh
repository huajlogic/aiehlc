#!/usr/bin/env bash  
###############################################################################
# Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: MIT
###############################################################################

dbg_echo() {
    if [ "$DEBUG_OUTPUT" = 1 ]; then
        echo "$@"
    fi
}

run_cmd() {
    local command="$1"
    if [ "$DEBUG_OUTPUT" = 0 ]; then
        $command > /dev/null 2>&1
    else
        $command
    fi
}

usage() {
    echo "Usage: $0 --runtime-source-file <path> --aie-version <version> [--kernel-count <count>] [--kernel <source> [<directory>]]"
    exit 1
}

build_hw_lib() {
    set -e

    local header_dir="$1"
    local compiler="$2"
    local assembler="$3"
    local archiver="$4"
    local compiler_flags="$5"
    local extra_flags="$6"
    local output_lib="$7"
    local lib_dir="$8"
    local ld_dir="$9"
    local lplatform="${10}"

        if [ -d "${AIE_DRIVER_PARENT_DIR}/aie-rt/driver/" ] ; then
            dbg_echo "header_dir is $header_dir"

            dbg_echo "[INFO] Cleaning include and lib folders..."
            rm -rf "$AIE_DRIVER_PARENT_DIR/include/"*.h
            rm -rf "$AIE_DRIVER_PARENT_DIR/lib/"*.a
            rm -rf "$AIE_DRIVER_PARENT_DIR/include/xaiengine"

            dbg_echo "[INFO] Copying headers..."
            dbg_echo "$lplatform is lplatform"

            if [[ "$lplatform" == "linux" ]]; then
                bash -c "cd $AIE_DRIVER_PARENT_DIR/aie-rt/driver/src; make -C ./ CC=aarch64-linux-gnu-gcc CFLAGS='-Wall -g -Wextra --std=c11 -D__AIELINUX__ -fpermissive'  -f Makefile.Linux"
                ##keep the order, first copy bsp header, then copy the aiert header, then even bsp header have old aiegnine header
                ##we still get the latest aiert header
                cp -rf "$header_dir"/*.h "$AIE_DRIVER_PARENT_DIR/include/"
                cp -rf "$AIE_DRIVER_PARENT_DIR/aie-rt/driver/internal/"* "$AIE_DRIVER_PARENT_DIR/include/"
                
            elif [[ "$platform" == "baremetal" ]]; then
                bash -c "cd $AIE_DRIVER_PARENT_DIR/aie-rt/driver/src; make -f Makefile.Linux"
                ##keep the order, first copy bsp header, then copy the aiert header, then even bsp header have old aiegnine header
                ##we still get the latest aiert header
                cp -rf "$header_dir"/*.h "$AIE_DRIVER_PARENT_DIR/include/"
                cp -rf "$AIE_DRIVER_PARENT_DIR/aie-rt/driver/internal/"* "$AIE_DRIVER_PARENT_DIR/include/"


                dbg_echo "[INFO] Cleaning previous build..."
                make clean -C "$AIE_DRIVER_PARENT_DIR/aie-rt/driver/src/"

                dbg_echo "[INFO] Copying extra libs and ld script..."
                cp "$lib_dir"/*.a "$AIE_DRIVER_PARENT_DIR/lib/"
                cp "$ld_dir" "$AIE_DRIVER_PARENT_DIR/lib/"  

                dbg_echo "[INFO] Building library with $compiler"
                make -C "$AIE_DRIVER_PARENT_DIR/aie-rt/driver/src" -s libs \
                    SHELL=/bin/sh \
                    COMPILER="$compiler" \
                    ASSEMBLER="$assembler" \
                    ARCHIVER="$archiver" \
                    COMPILER_FLAGS="$compiler_flags -DAIE_GEN=$AIE_GEN" \
                    EXTRA_COMPILER_FLAGS="$extra_flags"        

                dbg_echo "[INFO] Moving libxil.a to $output_lib"
                bash -c "mv $AIE_DRIVER_PARENT_DIR/lib/libxil.a $AIE_DRIVER_PARENT_DIR/lib/$output_lib"
            fi
        fi
    }


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export AIEHLC_DIR="${SCRIPT_DIR}/../"
runtime_source_file=""
aie_version="2"
use_llvm_aie="false"
DEBUG_OUTPUT=0
platform="baremetal"
USE_LOCAL_AIERT_BSP=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -help)
            usage
            ;;
        --runtime-source-file)
            runtime_source_file="$2"
            shift 2
            ;;
        --aie-version)
            aie_version="$2"
            shift 2
            ;;
        --platform)
            platform="$2"
            shift 2
            ;;
        --kernel)
            kernel_source="$2"
            shift 2
            ;;
        --use-llvm-aie)
            use_llvm_aie="true"
            shift
            ;;
        --debug-output)
            DEBUG_OUTPUT=1
            shift
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

#set up env
run_cmd "source $SCRIPT_DIR/setup.sh --path-set-only"

if [[ "$platform" == "linux" ]]; then
    TOOL_PREFIX="aarch64-linux-gnu-"
elif [[ "$platform" == "baremetal" ]]; then
    TOOL_PREFIX="aarch64-none-elf-"
fi

KERNEL_DIR=$(pwd)/aout/
rm -rf $KERNEL_DIR
XILINX_VITIS_AIETOOLS=$XILINX_VITIS/aietools
CARDANO_AIE_ARCH_MODEL_DIR="$XILINX_VITIS_AIETOOLS/data/versal_prod/lib"

# Check if local thirdparty/alib/include has xaiengine headers
LOCAL_ALIB_INCLUDE="${AIEHLC_DIR}/thirdparty/alib/include"
echo "Local include directory: ${LOCAL_ALIB_INCLUDE}"
if [ -d "${LOCAL_ALIB_INCLUDE}/xaiengine" ] && [ "$(ls -A ${LOCAL_ALIB_INCLUDE}/xaiengine 2>/dev/null)" ]; then
    echo "Using local aie-rt headers from ${LOCAL_ALIB_INCLUDE}"
    AIETOOLS_INCLUDE_BASE="${LOCAL_ALIB_INCLUDE}"
else
    echo "Using Vitis aie-rt headers from $XILINX_VITIS_AIETOOLS//include/drivers/aiengine"
    AIETOOLS_INCLUDE_BASE="$XILINX_VITIS_AIETOOLS//include/drivers/aiengine"
fi

# Arch paths
ARCH_DIR=$AIEHLC_DIR/thirdparty/arch/
ARCH_72_DIR=$ARCH_DIR/psv_cortexa72_0/workspace/platform_baremetal/psv_cortexa72_0/standalone_psv_cortexa72_0/bsp/
ARCH_53_DIR=$ARCH_DIR/psv_cortexr5_0/workspace/platform_baremetal/psv_cortexr5_0/standalone_psv_cortexr5_0/bsp/
ARCH_78_DIR=$ARCH_DIR/cortexa78_0/workspace/platform_baremetal/cortexa78_0/standalone_cortexa78_0/bsp/

# A72 
ARCH_APU_A72_INC=${ARCH_72_DIR}/include/
SECONDARY_ARCH_APU_A72_INC=${ARCH_DIR}/psv_cortexa72_0/bsp/include/
ARCH_APU_A72_LIB=${ARCH_72_DIR}/lib/
AIELIB_APU_A72_NAME=libxaienginea72.a
ARCH_APU_A72_LD=$ARCH_DIR/psv_cortexa72_0/lscript.ld

# A78
ARCH_APU_A78_INC=${ARCH_78_DIR}/include/
SECONDARY_ARCH_APU_A78_INC=${ARCH_DIR}/cortexa78_0/bsp/include/
ARCH_APU_A78_LIB=${ARCH_78_DIR}/lib/
AIELIB_APU_A78_NAME=libxaienginea78.a
ARCH_APU_A78_LD=$ARCH_DIR/cortexa78_0/lscript.ld

AIE_GEN=$aie_version
AIE_DRIVER_PARENT_DIR=$AIEHLC_DIR/thirdparty/alib/
AIE_DRIVER_LIB_DIR=$XILINX_VITIS/aietools/include/drivers/aiengine/xaiengine
AIE_DRIVER_INCLUDE_DIR=$XILINX_VITIS/aietools/lib/lnx64.o/

if [[ $aie_version == "1" || $aie_version == "2" ]]; then
    ARCH_APU_ALIB=$ARCH_APU_A72_LIB
    ARCH_APU_AINC=$ARCH_APU_A72_INC
    SECONDARY_ARCH_APU_AINC=$SECONDARY_ARCH_APU_A72_INC
    AIELIB_APU_NAME=$AIELIB_APU_A72_NAME
    ARCH_APU_LD=$ARCH_APU_A72_LD
    hw_lib_flag="-DARMA72_EL3"
    compiler_cpu_flag="-mcpu=cortex-a72"
    EXTRA_LIBS="-lxiltimer,-lxilstandalone,"
elif [[ $aie_version == "5" ]]; then
    ARCH_APU_ALIB=$ARCH_APU_A78_LIB
    ARCH_APU_AINC=$ARCH_APU_A78_INC
    SECONDARY_ARCH_APU_AINC=$SECONDARY_ARCH_APU_A78_INC
    AIELIB_APU_NAME=$AIELIB_APU_A78_NAME
    ARCH_APU_LD=$ARCH_APU_A78_LD
    hw_lib_flag="-DARMA78_EL3"
    compiler_cpu_flag="-mcpu=cortex-a78"
    EXTRA_LIBS="-lxiltimer,-lxilstandalone,"
else
    echo "Unsupported AIE version: $aie_version"
    exit 1
fi
AIENGINE_LIB_DIR=$ARCH_APU_ALIB/../libsrc/build_configs/gen_bsp/libsrc/aienginev2/src

AIEHLC="${AIEHLC_DIR}/build/aiehlc"
if [[ ! -f "${AIEHLC_DIR}/build/aiehlc" ]]; then
    AIEHLC="${AIEHLC_DIR}/release/prebuild/aiehlc"
fi

# compile aie-rt, if the local aie-rt exist
if [ -d "${AIE_DRIVER_PARENT_DIR}/aie-rt/driver/" ] ; then
    USE_LOCAL_AIERT_BSP=1
    build_hw_lib \
        "${ARCH_APU_AINC}" \
        ${TOOL_PREFIX}gcc \
        ${TOOL_PREFIX}as \
        ${TOOL_PREFIX}ar \
        "-O2 -c" \
        "-g -Wall -Wextra -Dversal ${hw_lib_flag} -fno-tree-loop-distribute-patterns" \
        "$AIELIB_APU_NAME" \
        "$ARCH_APU_ALIB" \
        "$ARCH_APU_LD" \
                "$platform"

    if [[ $aie_version == "1" || $aie_version == "2" ]]; then
        EXTRA_LIBS=""
    elif [[ $aie_version == "5" ]]; then
        EXTRA_LIBS="-lxiltimer,-lxilstandalone,"
    else
        echo "aie_version $aie_version is unknown"
    fi
fi

#Set the aie-rt include path FOR aiehlc 
if [ "$USE_LOCAL_AIERT_BSP" -eq 0 ]; then
    BAREMETAL_AIENGINE_INCLUDE=$XILINX_VITIS_AIETOOLS/include/drivers/aiengine/
else
    BAREMETAL_AIENGINE_INCLUDE=${AIEHLC_DIR}/thirdparty/alib/include/
fi

dbg_echo $BAREMETAL_AIENGINE_INCLUDE
echo -e "\nStarting Merged File Compilation..."
echo -e "    ${runtime_source_file}\n"
#Convert the host&kernel merged source code
set -x
if [[ "$use_llvm_aie" == "true" ]]; then
    "$LD_SO" --library-path "${LIB_PATH}:${LIB_BASE_PATH}" "${AIEHLC}" --use-llvm-aie --extra-arg="-DAIE_GEN=${aie_version}" \
        --extra-arg="-I${AIETOOLS_INCLUDE_BASE}" --extra-arg="-I$BAREMETAL_AIENGINE_INCLUDE" \
        --extra-arg="-I${ARCH_APU_AINC}" --extra-arg="-I${SECONDARY_ARCH_APU_AINC}" \
        --extra-arg="-I$XILINX_VITIS_AIETOOLS/include" --extra-arg="-I${CLANG_INCLUDE_PATH}" --extra-arg="-I${AIEHLC_DIR}/include/llvm" \
        --extra-arg="-include"aie_compat.h"" ${runtime_source_file} --
else
    "$LD_SO" --library-path "${LIB_PATH}:${LIB_BASE_PATH}" "${AIEHLC}" --extra-arg="-DAIE_GEN=${aie_version}" \
        --extra-arg="-I${AIETOOLS_INCLUDE_BASE}" --extra-arg="-I$BAREMETAL_AIENGINE_INCLUDE" \
        --extra-arg="-I${ARCH_APU_AINC}" --extra-arg="-I${SECONDARY_ARCH_APU_AINC}" \
        --extra-arg="-I$XILINX_VITIS_AIETOOLS/include" --extra-arg="-I${CLANG_INCLUDE_PATH}" --extra-arg="-I${AIEHLC_DIR}/include/llvm" \
        --extra-arg="-include"aie_compat.h"" ${runtime_source_file} --
fi
set +x
HOST_BUILD_DIR=$(pwd)/aout/
mkdir -p $HOST_BUILD_DIR

# compile kernels
kernel_list_file="$(pwd)/aout/kernel_list"
final_obj_file="$(pwd)/aout/build/final_kernel.o"
temp_obj_files=()
kernel_names=()

rm -f $final_obj_file

echo -e "\nStarting Kernel Compilation..."
while IFS= read -r kernel_source_file; do
    kernel_names+=("$kernel_source_file")
    func_name=$(basename "$kernel_source_file" .cc)

    KERNEL_SRC=$KERNEL_DIR/kernelcfg/${kernel_source_file}
    KERNEL_BUILD_DIR=$(pwd)/aout/build/${kernel_source_file}/obj/
    obj_file="${KERNEL_BUILD_DIR}/kernel.o"
    temp_obj_files+=("$obj_file")

    compile_args=(
        --kernel-cc "$KERNEL_SRC/wrapper.cc"
        --output-dir "$KERNEL_BUILD_DIR"
        --func-name "$func_name"
        --aie-version "$aie_version"
        --platform "$platform"
        --include-base "$AIETOOLS_INCLUDE_BASE"
    )

    if [[ "$use_llvm_aie" == "true" ]]; then
        compile_args+=(--use-llvm-aie --ld-script "$KERNEL_SRC/main.ld.script")
    else
        compile_args+=(--prx "$KERNEL_SRC/aieml.prx" --commons-dir "$KERNEL_DIR/TheHouseOfCommons/")
    fi

    if [ "$DEBUG_OUTPUT" = 1 ]; then
        compile_args+=(--debug-output)
    fi

    "source" "$SCRIPT_DIR/kernelcompile.sh" "${compile_args[@]}"
done < "$kernel_list_file"

#Compile host
host_file=$(pwd)/aout/host.cc
dbg_echo "INCLUDE_DIR: ${AIE_DRIVER_PARENT_DIR}include/"
dbg_echo "LIB_DIR: ${AIE_DRIVER_PARENT_DIR}lib/"
dbg_echo "ARCH_APU_AINC: $ARCH_APU_AINC"
dbg_echo "SECONDARY_ARCH_APU_AINC: $SECONDARY_ARCH_APU_AINC"
dbg_echo "ARCH_APU_ALIB: $ARCH_APU_ALIB"
dbg_echo "ARCH_APU_LD: ${ARCH_APU_LD}"
dbg_echo -e "OBJ FILES: ${temp_obj_files[@]}\n"
dbg_echo "AIENGINE_LIB_DIR: ${AIENGINE_LIB_DIR}"

# when use local aiert_bsp then set the local aiengine lib name
if [ "$USE_LOCAL_AIERT_BSP" -eq 0 ]; then
    BAREMETAL_AIENGINE_LIB=aienginev2
else
    BAREMETAL_AIENGINE_LIB=${AIELIB_APU_NAME:3:-2}
fi
dbg_echo "BAREMETAL_AIENGINE_LIB: ${BAREMETAL_AIENGINE_LIB}"

echo -e "\n"
echo "Targeting $platform platform..."
echo "Compiling host..."
echo "    $host_file"
echo "Linking kernels..."
echo "    ${temp_obj_files[@]}"
set -x
if [[ "$platform" == "baremetal" ]]; then
    dbg_echo ${TOOL_PREFIX}g++ -Os -L$XILINX_VITIS/aietools/lib/lnx64.o/ -L$AIENGINE_LIB_DIR -DAIE_GEN=${aie_version} ${compiler_cpu_flag} -Wl,-T -Wl,${ARCH_APU_LD} -I${AIETOOLS_INCLUDE_BASE} -I$AIE_DRIVER_PARENT_DIR/include/ -I$ARCH_APU_AINC -I$SECONDARY_ARCH_APU_AINC -L$ARCH_APU_ALIB -L$AIE_DRIVER_PARENT_DIR/lib/ -o $HOST_BUILD_DIR/main.elf $host_file ${temp_obj_files[@]} -Wl,--start-group,-lm,-l${BAREMETAL_AIENGINE_LIB},-lxil,-lgcc,-lc,-lstdc++,${EXTRA_LIBS}--end-group
    ${TOOL_PREFIX}g++ -Os -L$XILINX_VITIS/aietools/lib/lnx64.o/ -L$AIENGINE_LIB_DIR -DAIE_GEN=${aie_version} ${compiler_cpu_flag} -Wl,-T -Wl,${ARCH_APU_LD} -I${AIETOOLS_INCLUDE_BASE} -I$AIE_DRIVER_PARENT_DIR/include/ -I$ARCH_APU_AINC -I$SECONDARY_ARCH_APU_AINC -L$ARCH_APU_ALIB -L$AIE_DRIVER_PARENT_DIR/lib/ -o $HOST_BUILD_DIR/main.elf $host_file ${temp_obj_files[@]} -Wl,--start-group,-lm,-l${BAREMETAL_AIENGINE_LIB},-lxil,-lgcc,-lc,-lstdc++,${EXTRA_LIBS}--end-group
elif [[ "$platform" == "linux" ]]; then
    dbg_echo ${TOOL_PREFIX}g++ -Os -D__AIELINUX__ -DAIE_GEN=${aie_version} ${compiler_cpu_flag} \
        -I${AIETOOLS_INCLUDE_BASE} -I$AIE_DRIVER_PARENT_DIR/include/ -I${AIE_DRIVER_DIR}/include -I$ARCH_APU_AINC -I$SECONDARY_ARCH_APU_AINC \
        -L${AIE_DRIVER_DIR}/src -L$ARCH_APU_ALIB -L$AIE_DRIVER_PARENT_DIR/lib/ -L$AIE_DRIVER_PARENT_DIR/aie-rt/driver/src/ \
        -o $HOST_BUILD_DIR/main.elf $host_file ${temp_obj_files[@]} \
        -Wl,--start-group,-lxaiengine,-lxil,--end-group
    ${TOOL_PREFIX}g++ -Os -D__AIELINUX__ -DAIE_GEN=${aie_version} ${compiler_cpu_flag} \
        -I${AIETOOLS_INCLUDE_BASE} -I$AIE_DRIVER_PARENT_DIR/include/ -I${AIE_DRIVER_DIR}/include -I$ARCH_APU_AINC -I$SECONDARY_ARCH_APU_AINC \
        -L${AIE_DRIVER_DIR}/src -L$ARCH_APU_ALIB -L$AIE_DRIVER_PARENT_DIR/lib/ -L$AIE_DRIVER_PARENT_DIR/aie-rt/driver/src/  \
        -o $HOST_BUILD_DIR/main.elf $host_file ${temp_obj_files[@]} \
        -Wl,--start-group,-lxaiengine,-lxil,--end-group
fi
set +x
echo "Stripping extra ELF symbols..."
${TOOL_PREFIX}strip $HOST_BUILD_DIR/main.elf

echo "Build complete."
echo "    $HOST_BUILD_DIR/main.elf"