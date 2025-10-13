#!/usr/bin/env bash
# sx-uninstall-mac.sh
# Completely remove SearxNG Local from macOS (user install)

set -e

APP_NAME="SearxNG"
INSTALL_DIR="$HOME/Documents/searxng"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/local.searxng.plist"
CLI_BIN="$HOME/.local/bin/searxng"

echo "🧹 Uninstalling $APP_NAME ..."

# Stop if running
if pgrep -f "searx/webapp.py" >/dev/null 2>&1; then
  echo "Stopping running instance..."
  pkill -f "searx/webapp.py" || true
fi

# Unload LaunchAgent if present
if [ -f "$LAUNCH_AGENT" ]; then
  echo "Unloading LaunchAgent..."
  launchctl unload "$LAUNCH_AGENT" 2>/dev/null || true
  rm -f "$LAUNCH_AGENT"
fi

# Remove main folder
if [ -d "$INSTALL_DIR" ]; then
  echo "Removing $INSTALL_DIR ..."
  rm -rf "$INSTALL_DIR"
fi

# Remove CLI helper
if [ -f "$CLI_BIN" ]; then
  echo "Removing CLI command..."
  rm -f "$CLI_BIN"
fi

echo
echo "✅ $APP_NAME completely uninstalled."
echo "You can reinstall anytime using sx-deploy-mac.sh"