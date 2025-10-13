#!/usr/bin/env bash
# SearxNG macOS Uninstaller
# Safely removes all local files, venv, and LaunchAgent.

set -euo pipefail

APP_NAME="SearxNG"
INSTALL_DIR="$HOME/Documents/searxng"
USER_BIN="$HOME/.local/bin/searxng"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/local.searxng.plist"

echo "🧹 Uninstalling $APP_NAME from macOS..."
echo "----------------------------------------"

# Stop running instance
if pgrep -f "searx/webapp.py" >/dev/null; then
  echo "Stopping running instance..."
  pkill -f "searx/webapp.py" || true
  sleep 1
fi

# Unload LaunchAgent (if present)
if [ -f "$LAUNCH_AGENT" ]; then
  echo "Removing LaunchAgent..."
  launchctl unload "$LAUNCH_AGENT" 2>/dev/null || true
  rm -f "$LAUNCH_AGENT"
fi

# Remove user binary CLI
if [ -f "$USER_BIN" ]; then
  echo "Removing user CLI..."
  rm -f "$USER_BIN"
fi

# Remove SearxNG files
if [ -d "$INSTALL_DIR" ]; then
  echo "Removing SearxNG files..."
  rm -rf "$INSTALL_DIR"
fi

echo "----------------------------------------"
echo "✅ $APP_NAME has been completely removed."
echo
echo "If you want to reinstall later, run:"
echo "  bash ~/Documents/searxng-local/sx-deploy-mac.sh"
echo "----------------------------------------"