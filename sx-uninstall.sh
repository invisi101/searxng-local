#!/usr/bin/env bash
# sx-uninstall.sh — Remove SearxNG Local from Linux
set -e

INSTALL_DIR="$HOME/Documents/searxng"
CLI_BIN="$HOME/.local/bin/searxng"
SERVICE_FILE="$HOME/.config/systemd/user/searxng.service"

echo "Uninstalling SearxNG..."

# Stop service if active
systemctl --user stop searxng.service 2>/dev/null || true
systemctl --user disable searxng.service 2>/dev/null || true

# Kill manual process if any
pkill -f "searx/webapp.py" 2>/dev/null || true
sleep 1

# Remove service file
if [ -f "$SERVICE_FILE" ]; then
  rm -f "$SERVICE_FILE"
  systemctl --user daemon-reload 2>/dev/null || true
fi

# Remove CLI tool
rm -f "$CLI_BIN"

# Remove installation directory
if [ -d "$INSTALL_DIR" ]; then
  echo "Removing $INSTALL_DIR..."
  rm -rf "$INSTALL_DIR"
fi

echo "SearxNG has been removed."
