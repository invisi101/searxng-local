#!/usr/bin/env bash
# stop-searx-fedora.sh — helper to stop SearxNG manually on Fedora
set -euo pipefail
if pgrep -f "searx/webapp.py" >/dev/null; then
  pkill -f "searx/webapp.py"
  echo "SearxNG stopped."
else
  echo "SearxNG is not running."
fi
