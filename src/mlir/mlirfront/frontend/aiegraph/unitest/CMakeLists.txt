###############################################################################
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
###############################################################################

cmake_minimum_required(VERSION 3.5)
project(tablegen)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread")

# Set the C++ standard to C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(DEFINED ENV{AIEHLCLOCALBUILD})
    set(LLVM_ROOT "/Users/llvm/llvm-project/build")
    message(STATUS "AIEHLCLOCALBUILD is defined: using local LLVM at ${LLVM_ROOT}")
else()
    set(LLVM_ROOT "/usr/local")
    message(STATUS "AIEHLCLOCALBUILD is NOT defined: using system LLVM at ${LLVM_ROOT}")
endif()

if(DEFINED LLVM_INSTALL_DIR AND NOT "${LLVM_INSTALL_DIR}" STREQUAL "")
  set(LLVM_ROOT "${LLVM_INSTALL_DIR}" CACHE PATH "Root of LLVM/Clang/MLIR install" FORCE)
endif()

message(STATUS "Using LLVM_ROOT: ${LLVM_ROOT}")

if(LLVM_ROOT)
  list(APPEND CMAKE_PREFIX_PATH
       "${LLVM_ROOT}"
       "${LLVM_ROOT}/lib/cmake"
       "${LLVM_ROOT}/lib/cmake/llvm"
       "${LLVM_ROOT}/lib/cmake/clang"
       "${LLVM_ROOT}/lib/cmake/mlir")
endif()

set(LLVM_ROOT_BIN_ARG "")
list(APPEND LLVM_ROOT_BIN_ARG --llvm-bin "${LLVM_ROOT}/bin/")

find_package(Clang REQUIRED CONFIG)
find_package(LLVM  REQUIRED CONFIG)
find_package(MLIR  REQUIRED CONFIG)

message(STATUS "Found Clang ${Clang_PACKAGE_VERSION}")

include_directories(${Clang_INCLUDE_DIRS})
include_directories(${CLANG_INCLUDE_DIRS})
include_directories(${MLIR_INCLUDE_DIRS})
include_directories(${LLVM_INCLUDE_DIRS})

set(CMAKE_BUILD_TYPE Debug)

# aiegraph dialect headers: generated .inc, the manager, and the lower driver.
include_directories(../inc/)
include_directories(../)
include_directories(../lower/)
include_directories(./)

set(SOURCE_FILES ./test.cpp ../aiegraphmanager.cpp ../lower/AiegraphLowerDriver.cpp)

add_executable(test ${SOURCE_FILES})

set(MLIR_INC_ARGS "")
foreach(dir IN LISTS MLIR_INCLUDE_DIRS)
  list(APPEND MLIR_INC_ARGS --mlir-include "${dir}")
endforeach()

add_custom_target(
	aiegraphdialecttablegen ALL
  COMMAND ${CMAKE_COMMAND} -E echo "Running aiegraph tablegen..."
	COMMAND bash ${CMAKE_CURRENT_SOURCE_DIR}/../gen.sh ${MLIR_INC_ARGS} ${LLVM_ROOT_BIN_ARG}
  COMMENT "Executing aiegraph tablegen before building the unit test"
)

add_dependencies(test aiegraphdialecttablegen)

set(LLVM_PATH /scratch/staff/huaj/mlirdocker/)
set(LLVM_LIBRARY_DIR ${LLVM_PATH}/llvm-project/build/lib/)
if(NOT MLIR_DIR)
	set(MLIR_DIR ${LLVM_LIBRARY_DIR}/cmake/mlir)
endif()

find_package(MLIR REQUIRED CONFIG PATHS ${MLIR_DIR})

include_directories(${MLIR_INCLUDE_DIRS})
include_directories(${LLVM_INCLUDE_DIRS})

target_link_libraries(test PUBLIC
    clangTooling
    clangBasic
    clangASTMatchers
	${ANTLR4_LIBRARY_PATHS_LIST}
    MLIRAMDGPUDialect
    MLIRNVVMDialect
    MLIRNVVMToLLVMIRTranslation
    MLIRGPUToNVVMTransforms
    MLIRGPUToGPURuntimeTransforms
    MLIRGPUTransforms
	MLIRIR
	MLIRControlFlowToLLVM
	MLIRBytecodeWriter
    MLIRParser
	MLIRPass
	MLIRTransforms
	MLIRLLVMDialect
	MLIRSupport
	MLIRTargetLLVMIRExport
	MLIRMathToLLVM
      MLIRFuncDialect
      MLIRFuncTransforms
      MLIRLinalgDialect
      MLIRLinalgTransforms
      MLIRMemRefDialect
      MLIRTransformDialect
      MLIRTransformUtils
      MLIRLinalgTransformOps
      MLIRTransformDialectTransforms
    LLVMPasses
    dl
)
target_link_options(test PRIVATE ${LLVM_LDFLAGS})
