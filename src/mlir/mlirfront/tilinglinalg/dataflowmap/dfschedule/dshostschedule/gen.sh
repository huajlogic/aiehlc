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
${LLVM_BIN}/mlir-tblgen -gen-dialect-defs $TD/dshosttype.td -dialect=dshost -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include/ ${MLIR_INCLUDES} > $INC/dshostdialect.cc.inc
${LLVM_BIN}/mlir-tblgen -gen-dialect-decls $TD/dshosttype.td -dialect=dshost -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} >  $INC/dshostdialect.h.inc
${LLVM_BIN}/mlir-tblgen -gen-typedef-defs $TD/dshosttype.td -typedefs-dialect=dshost -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} >  $INC/dshosttype.cc.inc
${LLVM_BIN}/mlir-tblgen -gen-typedef-decls $TD/dshosttype.td -typedefs-dialect=dshost -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} >  $INC/dshosttype.h.inc
${LLVM_BIN}/mlir-tblgen --gen-attrdef-defs $TD/dshostattr.td -attrdefs-dialect=dshost -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} >  $INC/dshostattr.cc.inc
${LLVM_BIN}/mlir-tblgen --gen-attrdef-decls $TD/dshostattr.td -attrdefs-dialect=dshost -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} >  $INC/dshostattr.h.inc

${LLVM_BIN}/mlir-tblgen --gen-enum-decls $TD/dshostattr.td -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} >  $INC/dshostenums.h.inc
${LLVM_BIN}/mlir-tblgen --gen-enum-defs $TD/dshostattr.td -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} >  $INC/dshostenums.cc.inc

#${LLVM_BIN}/mlir-tblgen --gen-type-interface-defs $TD/dmamapterface.td -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} -o  $INC/dmamapterface.cc.inc
#${LLVM_BIN}/mlir-tblgen --gen-type-interface-decls $TD/dmamapterface.td -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} -o  $INC/dmamapterface.h.inc

${LLVM_BIN}/mlir-tblgen -gen-op-defs $TD/dshostop.td -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} > $INC/dshostop.cc.inc
${LLVM_BIN}/mlir-tblgen -gen-op-decls $TD/dshostop.td -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} > $INC/dshostop.h.inc
popd
