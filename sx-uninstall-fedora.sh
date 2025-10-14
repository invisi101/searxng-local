#!/usr/bin/env bash
# sx-uninstall-fedora.sh — remove Fedora SearxNG Local
set -euo pipefail

INSTALL_DIR="$HOME/Documents/searxng-fedora"
CLI_BIN="$HOME/.local/bin/searxng-fedora"
SERVICE_FILE="$HOME/.config/systemd/user/searxng-fedora.service"

echo "🧹 Uninstalling SearxNG (Fedora) ..."

# Stop service if active
systemctl --user stop searxng-fedora.service 2>/dev/null || true
systemctl --user disable searxng-fedora.service 2>/dev/null || true

# Kill manual process if any
pkill -f "searx/webapp.py" 2>/dev/null || true

# Remove service
rm -f "$SERVICE_FILE"
systemctl --user daemon-reload 2>/dev/null || true

# Remove CLI
rm -f "$CLI_BIN"

# Remove install dir
rm -rf "$INSTALL_DIR"

echo "✅ Uninstall complete."
