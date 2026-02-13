#!/usr/bin/env bash
###############################################################################
# toolenv.sh - Source this from ~/.bashrc to activate aiehlc shell tools
#
# What it does:
#   1. Adds script/tool to PATH (for any standalone scripts placed here)
#   2. Sources all *.sh tool files in this directory (shell functions)
###############################################################################

_AIEHLC_TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Add tool directory to PATH (for future standalone scripts)
case ":$PATH:" in
    *":$_AIEHLC_TOOL_DIR:"*) ;;  # already in PATH
    *) export PATH="$_AIEHLC_TOOL_DIR:$PATH" ;;
esac

# Source every tool definition (skip this file itself)
for _tool_file in "$_AIEHLC_TOOL_DIR"/*.sh; do
    [ "$_tool_file" = "$_AIEHLC_TOOL_DIR/toolenv.sh" ] && continue
    # shellcheck disable=SC1090
    source "$_tool_file"
done
unset _tool_file _AIEHLC_TOOL_DIR
