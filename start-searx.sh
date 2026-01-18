#!/usr/bin/env bash
# start-searx.sh — Start SearxNG on Linux

set -e

INSTALL_DIR="$HOME/Documents/searxng"
VENV_DIR="$INSTALL_DIR/venv"
PY_APP="$INSTALL_DIR/searxng/searx/webapp.py"
CONFIG="$INSTALL_DIR/settings.yml"

if [ ! -d "$VENV_DIR" ]; then
  echo "Virtual environment not found. Please run the installer first."
  exit 1
fi

source "$VENV_DIR/bin/activate"
export SEARXNG_SETTINGS_PATH="$CONFIG"

nohup python "$PY_APP" >/dev/null 2>&1 &
disown

echo "SearxNG started at http://127.0.0.1:8888"
