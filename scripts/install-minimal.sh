#!/bin/bash
# =============================================================================
# Smart Agent Installer - Minimal (No Standards)
# Installs only the Smart Agent without language standards
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run the main installer with minimal flag
"$SCRIPT_DIR/install.sh" --minimal
