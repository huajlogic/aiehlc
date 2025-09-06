###############################################################################
# Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: MIT
###############################################################################

GEN_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INC=$GEN_SCRIPT_DIR/inc
TD=$GEN_SCRIPT_DIR/td
echo "Script is located in: $GEN_SCRIPT_DIR"
pushd ${GEN_SCRIPT_DIR}
mlir-tblgen -gen-dialect-defs $TD/routingtype.td -dialect=routing -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include/ > $INC/routingdialect.cc.inc
mlir-tblgen -gen-dialect-decls $TD/routingtype.td -dialect=routing -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include >  $INC/routingdialect.h.inc
mlir-tblgen -gen-typedef-defs $TD/routingtype.td -typedefs-dialect=routing -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include >  $INC/routingtype.cc.inc
mlir-tblgen -gen-typedef-decls $TD/routingtype.td -typedefs-dialect=routing -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include >  $INC/routingtype.h.inc
mlir-tblgen --gen-attrdef-defs $TD/routingattr.td -attrdefs-dialect=routing -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include >  $INC/routingattr.cc.inc
mlir-tblgen --gen-attrdef-decls $TD/routingattr.td -attrdefs-dialect=routing -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include >  $INC/routingattr.h.inc

mlir-tblgen --gen-type-interface-defs $TD/routinginterface.td -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include -o  $INC/routinginterface.cc.inc
mlir-tblgen --gen-type-interface-decls $TD/routinginterface.td -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include -o  $INC/routinginterface.h.inc

mlir-tblgen -gen-op-defs $TD/routingop.td -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include > $INC/routingop.cc.inc
mlir-tblgen -gen-op-decls $TD/routingop.td -I $TD -I $GEN_SCRIPT_DIR -I /usr/local/include > $INC/routingop.h.inc
popd
