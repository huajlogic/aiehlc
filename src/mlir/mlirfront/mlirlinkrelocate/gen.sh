###############################################################################
# Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: MIT
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Script is located in: $SCRIPT_DIR"
pushd ${SCRIPT_DIR}
mlir-tblgen -gen-dialect-defs ./aielinkops.td -dialect=AieLink -I /usr/local/include/ > ./aielinkdialect.cc.inc
mlir-tblgen -gen-dialect-decls ./aielinkops.td -dialect=AieLink -I /usr/local/include/ > ./aielinkdialect.h.inc
mlir-tblgen -gen-op-defs ./aielinkops.td -I /usr/local/include/ > ./aielinkop.cc.inc
mlir-tblgen -gen-op-decls ./aielinkops.td -I /usr/local/include/ > ./aielinkop.h.inc

mlir-tblgen -gen-typedef-defs ./aielinktypes.td --typedefs-dialect=AieLink -I /usr/local/include/ -asmformat-error-is-fatal=false > ./aielinktype.cc.inc
mlir-tblgen -gen-typedef-decls ./aielinktypes.td --typedefs-dialect=AieLink -I /usr/local/include/ -asmformat-error-is-fatal=false > ./aielinktype.h.inc
popd
