#!/bin/bash
###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: MIT
###############################################################################
# Minimal standalone AIE-2PS kernel compilation script
# Compiles kernel.cc (which includes compute_kernel.cc) to kernel ELF
###############################################################################

# Save the script directory BEFORE sourcing anything
# Use a unique name to avoid conflicts with setup.sh
KERNEL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${KERNEL_SCRIPT_DIR}/build"

# Source setup.sh to set XILINX_VITIS and other environment variables
# Navigate from: worklocal/ -> unitest/ -> pass/ -> tilinglinalg/ -> mlirfront/ -> mlir/ -> src/ -> aiehlc/
AIEHLC_DIR="$(cd "${KERNEL_SCRIPT_DIR}/../../../../../../.." && pwd)"
if [ -f "${AIEHLC_DIR}/script/setup.sh" ]; then
    echo "Sourcing Vitis environment from ${AIEHLC_DIR}/script/setup.sh..."
    # Save current directory to restore after sourcing
    SAVED_PWD="$(pwd)"
    source "${AIEHLC_DIR}/script/setup.sh" --path-set-only
    # Restore directory
    cd "${SAVED_PWD}"
    echo "✓ Environment loaded: XILINX_VITIS=${XILINX_VITIS}"
else
    echo "Warning: setup.sh not found at ${AIEHLC_DIR}/script/setup.sh"
    echo "Checking if XILINX_VITIS is already set..."
fi

# Check XILINX_VITIS is set
if [ -z "$XILINX_VITIS" ]; then
    echo "Error: XILINX_VITIS environment variable not set"
    echo "Please source Vitis settings: source /path/to/Vitis/settings64.sh"
    exit 1
fi

# Set up include paths
XILINX_VITIS_AIETOOLS="${XILINX_VITIS}/aietools"
LOCAL_ALIB_INCLUDE="${AIEHLC_DIR}/thirdparty/alib/include"
if [ -d "${LOCAL_ALIB_INCLUDE}/xaiengine" ] && [ "$(ls -A ${LOCAL_ALIB_INCLUDE}/xaiengine 2>/dev/null)" ]; then
    AIETOOLS_INCLUDE_BASE="${LOCAL_ALIB_INCLUDE}"
else
    AIETOOLS_INCLUDE_BASE="${XILINX_VITIS_AIETOOLS}/include/drivers/aiengine"
fi

INCLUDE_PATH="-I${XILINX_VITIS_AIETOOLS}/include -I${XILINX_VITIS_AIETOOLS}/include/aie_api -I${AIETOOLS_INCLUDE_BASE}"

# Create build directory
mkdir -p ${BUILD_DIR}

echo "============================================"
echo "AIE-2PS Kernel Compilation"
echo "============================================"
echo "Source: ${KERNEL_SCRIPT_DIR}/kernel.cc"
echo "Output: ${BUILD_DIR}/kernel"
echo ""

# Step 1: Compile kernel.cc to LLVM IR
echo "Step 1: Compiling kernel.cc to LLVM IR..."
arch_model_dir_aie2ps="${XILINX_VITIS}/aietools/data/aie2ps/lib"
xchesscc -aiearch aie2ps -s +f -p me -P ${arch_model_dir_aie2ps} +P 4 \
    +Wllvm,-O2,-fno-jump-tables,-fno-discard-value-names,-mllvm,-chess-collapse-struct-types-during-linking=0,-Xclang,-chess-only-info-critical-passes \
    -D__AIENGINE__ -D__AIE_ARCH__=22 -D__AIEARCH=22 -D__LOCK_FENCE_MODE__=0 \
    -DAIE_OPTION_SCALAR_FLOAT_ON_VECTOR -DAIE2_FP32_EMULATION_ACCURACY_FAST \
    ${INCLUDE_PATH} -o ${BUILD_DIR}/kernel_orig.ll ${KERNEL_SCRIPT_DIR}/kernel.cc
if [ $? -ne 0 ]; then
    echo "✗ Error: xchesscc compilation failed"
    exit 1
fi
echo "✓ Generated: ${BUILD_DIR}/kernel_orig.ll"
echo ""

# Step 2: Optimize LLVM IR (pass 1)
echo "Step 2: Optimizing LLVM IR (pass 1)..."
${XILINX_VITIS}/aietools/lnx64.o/tools/clang/bin/opt -S \
    -load-pass-plugin=${XILINX_VITIS}/aietools/lib/lnx64.o/libLLVMXLOpt.so \
    -passes=xlopt ${BUILD_DIR}/kernel_orig.ll -o ${BUILD_DIR}/kernel.ll
if [ $? -ne 0 ]; then
    echo "✗ Error: opt pass 1 failed"
    exit 1
fi
echo "✓ Optimization pass 1 completed"
echo ""

# Step 3: Optimize LLVM IR (pass 2)
echo "Step 3: Optimizing LLVM IR (pass 2)..."
${XILINX_VITIS}/aietools/lnx64.o/tools/clang/bin/opt -S \
    -load-pass-plugin=${XILINX_VITIS}/aietools/lib/lnx64.o/libLLVMXLOpt.so \
    -passes=xlopt ${BUILD_DIR}/kernel.ll -o ${BUILD_DIR}/kernel.ll
if [ $? -ne 0 ]; then
    echo "✗ Error: opt pass 2 failed"
    exit 1
fi
echo "✓ Optimization pass 2 completed"
echo ""

# Step 4: Link kernel ELF
echo "Step 4: Linking kernel ELF..."
xchessmk -aiearch aie2ps -s -C Release_LLVM +o ${BUILD_DIR} ${KERNEL_SCRIPT_DIR}/aie2ps.prx
if [ $? -eq 0 ]; then
    echo ""
    echo "============================================"
    echo "✓ Kernel compiled successfully!"
    echo "============================================"
    echo "Kernel ELF: ${BUILD_DIR}/kernel"
    ls -lh ${BUILD_DIR}/kernel
    echo ""
else
    echo "✗ Error: xchessmk linking failed"
    exit 1
fi
