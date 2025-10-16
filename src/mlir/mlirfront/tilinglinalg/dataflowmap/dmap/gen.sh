###############################################################################
# Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: MIT
###############################################################################
#!/usr/bin/env bash

GEN_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INC=$GEN_SCRIPT_DIR/inc
TD=$GEN_SCRIPT_DIR/td

MLIR_INCLUDES=-I/usr/local/include/mlir/
LLVM_BIN=/usr/local/bin/

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mlir-include)
      MLIR_INCLUDES+=(" -I$2 "); shift 2;;
    --llvm-bin)
      LLVM_BIN="$2"; shift 2;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

echo "Script is located in: $GEN_SCRIPT_DIR"
pushd ${GEN_SCRIPT_DIR}
#${LLVM_BIN}/mlir-tblgen -gen-dialect-defs $TD/dmamaptype.td -dialect=dmamap -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include/ ${MLIR_INCLUDES} > $INC/dmamapdialect.cc.inc
#${LLVM_BIN}/mlir-tblgen -gen-dialect-decls $TD/dmamaptype.td -dialect=dmamap -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} >  $INC/dmamapdialect.h.inc
${LLVM_BIN}/mlir-tblgen -gen-typedef-defs $TD/dmaptype.td -typedefs-dialect=dmamap -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} >  $INC/dmamaptype.cc.inc
${LLVM_BIN}/mlir-tblgen -gen-typedef-decls $TD/dmaptype.td -typedefs-dialect=dmamap -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} >  $INC/dmamaptype.h.inc
${LLVM_BIN}/mlir-tblgen --gen-attrdef-defs $TD/dmapattr.td -attrdefs-dialect=dmamap -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} >  $INC/dmamapattr.cc.inc
${LLVM_BIN}/mlir-tblgen --gen-attrdef-decls $TD/dmapattr.td -attrdefs-dialect=dmamap -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} >  $INC/dmamapattr.h.inc

#${LLVM_BIN}/mlir-tblgen --gen-type-interface-defs $TD/dmamapterface.td -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} -o  $INC/dmamapterface.cc.inc
#${LLVM_BIN}/mlir-tblgen --gen-type-interface-decls $TD/dmamapterface.td -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} -o  $INC/dmamapterface.h.inc

${LLVM_BIN}/mlir-tblgen -gen-op-defs $TD/dmapop.td -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} > $INC/dmamapop.cc.inc
${LLVM_BIN}/mlir-tblgen -gen-op-decls $TD/dmapop.td -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include ${MLIR_INCLUDES} > $INC/dmamapop.h.inc
popd
