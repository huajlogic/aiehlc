###############################################################################
# Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: MIT
###############################################################################

GEN_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Script is located in: $GEN_SCRIPT_DIR"
pushd ${GEN_SCRIPT_DIR}
mlir-tblgen -gen-dialect-defs ./aieops.td -dialect=Aie -I /usr/local/include/ > ./aiedialect.cc.inc
mlir-tblgen -gen-dialect-decls ./aieops.td -dialect=Aie -I /usr/local/include/ > ./aiedialect.h.inc
mlir-tblgen -gen-op-defs ./aieops.td -I /usr/local/include/ > ./aieop.cc.inc
mlir-tblgen -gen-op-decls ./aieops.td -I /usr/local/include/ > ./aieop.h.inc

mlir-tblgen -gen-typedef-defs ./aietypes.td --typedefs-dialect=Aie -I /usr/local/include/ -asmformat-error-is-fatal=false > ./aietype.cc.inc
mlir-tblgen -gen-typedef-decls ./aietypes.td --typedefs-dialect=Aie -I /usr/local/include/ -asmformat-error-is-fatal=false > ./aietype.h.inc
popd
