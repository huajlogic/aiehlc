#!/bin/bash
# Copyright 2025-2026 Advanced Micro Devices, Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
# Environment setup for mainelfpaltest.py
# Source this file before running the test: source env.sh

# =============================================================================
# Required Environment Variables
# =============================================================================

# Your username for SSH login to the PAL board server
export USERNAME="h***"
export VEK385IP="" # for example: "crimini5"

# IP address of the PAL board server
export PALIP="10.23.***.***"
# Board name to use with 'become' command in systest
export BOARDNAME="pal***"

export AIEDBG_TARGET=xsdb://${VEK385IP}:3121

source /proj/xbuilds/HEAD_daily_latest/installs/lin64/HEAD/Vitis/settings64.sh


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
