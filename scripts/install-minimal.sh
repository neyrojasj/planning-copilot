#!/bin/bash
# =============================================================================
# Planning Copilot Installer - Minimal (No Standards)
# Installs only the planning agent without language standards
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run the main installer with minimal flag
"$SCRIPT_DIR/install.sh" --minimal
