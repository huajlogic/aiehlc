###############################################################################
# Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: MIT
###############################################################################
#!/usr/bin/env bash

GEN_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INC=$GEN_SCRIPT_DIR/inc
TD=$GEN_SCRIPT_DIR/td

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mlir-include)
      MLIR_INCLUDES+=(" -I$2 "); shift 2;;
    --llvm-bin)
      LLVM_BIN="$2"; shift 2;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

if [ ${#MLIR_INCLUDES[@]} -eq 0 ]; then
  echo "No --mlir-include provided, using default."
  #MLIR_INCLUDES=("-I/usr/local/include/mlir/")
  MLIR_INCLUDES=("-I/Users/llvm/llvm-project/mlir/include/")
fi
if [ ${#LLVM_BIN[@]} -eq 0 ]; then
  echo "No LLVM_BIN provided, using default."
  #LLVM_BIN=("/usr/local/bin/")
  LLVM_BIN=("/Users/llvm/llvm-project/build/bin/")
fi

echo $MLIR_INCLUDES
echo "Script is located in: $GEN_SCRIPT_DIR"
pushd ${GEN_SCRIPT_DIR}
echo ${LLVM_BIN}
${LLVM_BIN}/mlir-tblgen -gen-dialect-defs $TD/dskerneltype.td -dialect=dskernel -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include/ ${MLIR_INCLUDES} > $INC/dskerneldialect.cc.inc
${LLVM_BIN}/mlir-tblgen -gen-dialect-decls $TD/dskerneltype.td -dialect=dskernel -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} >  $INC/dskerneldialect.h.inc
${LLVM_BIN}/mlir-tblgen -gen-typedef-defs $TD/dskerneltype.td -typedefs-dialect=dskernel -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} >  $INC/dskerneltype.cc.inc
${LLVM_BIN}/mlir-tblgen -gen-typedef-decls $TD/dskerneltype.td -typedefs-dialect=dskernel -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} >  $INC/dskerneltype.h.inc
${LLVM_BIN}/mlir-tblgen --gen-attrdef-defs $TD/dskernelattr.td -attrdefs-dialect=dskernel -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} >  $INC/dskernelattr.cc.inc
${LLVM_BIN}/mlir-tblgen --gen-attrdef-decls $TD/dskernelattr.td -attrdefs-dialect=dskernel -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} >  $INC/dskernelattr.h.inc

#${LLVM_BIN}/mlir-tblgen --gen-enum-decls $TD/dskernelattr.td -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} >  $INC/dskernelenums.h.inc
#${LLVM_BIN}/mlir-tblgen --gen-enum-defs $TD/dskernelattr.td -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} >  $INC/dskernelenums.cc.inc

#${LLVM_BIN}/mlir-tblgen --gen-type-interface-defs $TD/dmamapterface.td -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} -o  $INC/dmamapterface.cc.inc
#${LLVM_BIN}/mlir-tblgen --gen-type-interface-decls $TD/dmamapterface.td -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} -o  $INC/dmamapterface.h.inc

${LLVM_BIN}/mlir-tblgen -gen-op-defs $TD/dskernelop.td -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} > $INC/dskernelop.cc.inc
${LLVM_BIN}/mlir-tblgen -gen-op-decls $TD/dskernelop.td -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} > $INC/dskernelop.h.inc
popd
