#!/usr/bin/env bash
###############################################################################
# Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: MIT
###############################################################################
#
# aiehlcpysetup.sh - Install AIEHLC Python packages into the current
#                     Python environment (pip install -e).
#
# Usage:
#     source script/aiehlcpysetup.sh
#
# After sourcing, these packages are available from anywhere:
#
#   1) aietriton         - Runtime/compiler: @aie_triton.jit decorator,
#                          language stubs (tl.*), AST-to-KernelOps,
#                          compile_and_run pipeline.
#
#   2) aie_triton_conv   - Pure Python Triton-to-C converter:
#                          convert_triton_to_c("input.py", "output_dir")
#
# Example after install:
#     from aietriton import jit, mesh
#     from aie_triton_conv import convert_triton_to_c
#
###############################################################################

_aiehlcpy_setup() {
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local ROOT_DIR
    ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

    # --- Verify Python/pip availability ---
    local PIP_CMD=""
    if command -v pip >/dev/null 2>&1; then
        PIP_CMD="pip"
    elif command -v pip3 >/dev/null 2>&1; then
        PIP_CMD="pip3"
    else
        echo "ERROR: pip/pip3 not found. Please activate a Python environment first."
        return 1
    fi

    local PYTHON_CMD=""
    if command -v python >/dev/null 2>&1; then
        PYTHON_CMD="python"
    elif command -v python3 >/dev/null 2>&1; then
        PYTHON_CMD="python3"
    else
        echo "ERROR: python/python3 not found."
        return 1
    fi

    echo "Using: $($PYTHON_CMD --version) at $(which $PYTHON_CMD)"
    echo "Using: $PIP_CMD at $(which $PIP_CMD)"
    echo ""

    # -----------------------------------------------------------------------
    # 1) aietriton package  (src/mlir/mlirfront/aietriton/)
    # -----------------------------------------------------------------------
    local AIETRITON_PKG_DIR="${ROOT_DIR}/src/mlir/mlirfront"

    # Create pyproject.toml if not already present
    if [ ! -f "${AIETRITON_PKG_DIR}/pyproject.toml" ]; then
        echo "Creating pyproject.toml for aietriton..."
        cat > "${AIETRITON_PKG_DIR}/pyproject.toml" << 'PYEOF'
[build-system]
requires = ["setuptools>=64"]
build-backend = "setuptools.build_meta"

[project]
name = "aietriton"
version = "0.1.0"
description = "AIE Triton runtime: @aie_triton.jit decorator, language stubs, AST-to-KernelOps, compile_and_run"
requires-python = ">=3.8"
dependencies = ["numpy"]

[tool.setuptools.packages.find]
include = ["aietriton*"]
PYEOF
    fi

    echo "Installing aietriton (editable)..."
    $PIP_CMD install -e "${AIETRITON_PKG_DIR}" --quiet
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to install aietriton package."
        return 1
    fi
    echo "  aietriton installed."

    # -----------------------------------------------------------------------
    # 2) aie_triton_conv package  (src/python/)
    # -----------------------------------------------------------------------
    local CONV_PKG_DIR="${ROOT_DIR}/src/python"

    # Create pyproject.toml if not already present
    if [ ! -f "${CONV_PKG_DIR}/pyproject.toml" ]; then
        echo "Creating pyproject.toml for aie_triton_conv..."

        # Rename the package directory for pip: src/python/ contains the
        # modules directly, so we create a thin wrapper package alongside.
        # Instead, we use a flat-layout pointing at src/python as package dir.
        cat > "${CONV_PKG_DIR}/pyproject.toml" << 'PYEOF'
[build-system]
requires = ["setuptools>=64"]
build-backend = "setuptools.build_meta"

[project]
name = "aie-triton-conv"
version = "0.1.0"
description = "Pure Python Triton-to-C converter for AIEHLC"
requires-python = ">=3.8"
dependencies = ["aietriton"]

[project.scripts]
aie-triton-conv = "aie_triton_conv.ast_to_c:_cli_main"

[tool.setuptools.packages.find]
include = ["aie_triton_conv*"]
PYEOF

        # The existing code lives in src/python/ and uses relative imports
        # (from .kernel_emitter import ...). We need a proper package name.
        # Create aie_triton_conv/ alongside that re-exports from src/python/.
        # Actually, the simplest approach: make src/python/ itself the package
        # "aie_triton_conv" by adding a package-dir mapping.
        #
        # Use setuptools package_dir to map aie_triton_conv -> . (the src/python/ dir).
        cat > "${CONV_PKG_DIR}/pyproject.toml" << 'PYEOF'
[build-system]
requires = ["setuptools>=64"]
build-backend = "setuptools.build_meta"

[project]
name = "aie-triton-conv"
version = "0.1.0"
description = "Pure Python Triton-to-C converter for AIEHLC"
requires-python = ">=3.8"
dependencies = ["aietriton"]

[project.scripts]
aie-triton-conv = "aie_triton_conv.cli:main"

[tool.setuptools.package-dir]
aie_triton_conv = "."
PYEOF

        # Create a CLI entry point
        if [ ! -f "${CONV_PKG_DIR}/cli.py" ]; then
            cat > "${CONV_PKG_DIR}/cli.py" << 'PYEOF'
#!/usr/bin/env python3
###############################################################################
# Copyright (C) 2025 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: MIT
###############################################################################
"""CLI entry point for aie-triton-conv."""

import argparse
import sys

from .ast_to_c import convert_triton_to_c


def main():
    parser = argparse.ArgumentParser(
        description="Convert @aie_triton.jit Python kernel to C code"
    )
    parser.add_argument("input", help="Path to .py file with @aie_triton.jit kernel")
    parser.add_argument(
        "-o", "--output-dir", default="./output",
        help="Output directory for kernel.c and host.c (default: ./output)"
    )
    args = parser.parse_args()

    result = convert_triton_to_c(args.input, args.output_dir)
    print(f"kernel.c -> {result['kernel_file']}")
    print(f"host.c   -> {result['host_file']}")


if __name__ == "__main__":
    main()
PYEOF
        fi

        # Update __init__.py to work with the new package name
        # The existing __init__.py uses `from .ast_to_c import convert_triton_to_c`
        # which already works fine as a relative import.
    fi

    echo "Installing aie_triton_conv (editable)..."
    $PIP_CMD install -e "${CONV_PKG_DIR}" --quiet
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to install aie_triton_conv package."
        return 1
    fi
    echo "  aie_triton_conv installed."

    # -----------------------------------------------------------------------
    # Summary
    # -----------------------------------------------------------------------
    echo ""
    echo "============================================"
    echo "  AIEHLC Python packages installed"
    echo "============================================"
    echo ""
    echo "Packages:"
    echo "  1) aietriton          - import aietriton"
    echo "  2) aie-triton-conv    - import aie_triton_conv"
    echo ""
    echo "Verify:"
    echo "  $PYTHON_CMD -c \"import aietriton; print('aietriton OK')\""
    echo "  $PYTHON_CMD -c \"from aie_triton_conv import convert_triton_to_c; print('aie_triton_conv OK')\""
    echo ""
    echo "CLI:"
    echo "  aie-triton-conv input.py -o output_dir"
    echo ""

    # Quick verification
    $PYTHON_CMD -c "import aietriton; print('  [OK] aietriton')" 2>/dev/null || echo "  [WARN] aietriton import failed"
    $PYTHON_CMD -c "from aie_triton_conv import convert_triton_to_c; print('  [OK] aie_triton_conv')" 2>/dev/null || echo "  [WARN] aie_triton_conv import failed"
}

_aiehlcpy_setup "$@"
unset -f _aiehlcpy_setup
