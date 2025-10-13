#!/usr/bin/env bash
set -e
echo "Stopping SearxNG..."
pkill -f "searx/webapp.py" >/dev/null 2>&1 || true
echo "Removing ~/Documents/searxng..."
rm -rf "$HOME/Documents/searxng"
echo "✅ Uninstall complete."

