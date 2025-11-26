#!/bin/bash
# =============================================================================
# Planning Copilot Installer - With Standards
# Installs the planning agent WITH language standards (Rust, Node.js)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run the main installer with standards flag
"$SCRIPT_DIR/install.sh" --with-standards
