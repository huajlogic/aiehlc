#!/bin/bash
#MIT License
# Copyright (C) 2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: MIT
# Environment setup for mainelfpaltest.py
# Source this file before running the test: source env.sh

# =============================================================================
# Required Environment Variables
# =============================================================================

# Your username for SSH login to the PAL board server
export USERNAME="h***"

# IP address of the PAL board server
export PALIP="10.23.***.***"

# Board name to use with 'become' command in systest
export BOARDNAME="pal***"

# =============================================================================
# Verify settings
# =============================================================================

echo "Environment variables set:"
echo "  USERNAME  = $USERNAME"
echo "  PALIP     = $PALIP"
echo "  BOARDNAME = $BOARDNAME"
echo ""
echo "SSH target: $USERNAME@$PALIP"
echo "ELF path:   /home/$USERNAME/aiehlc/main.elf"
echo ""
echo "To run the test:"
echo "  python test/mainelfpaltest.py"
