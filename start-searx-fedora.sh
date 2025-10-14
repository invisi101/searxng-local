#!/usr/bin/env bash
# start-searx-fedora.sh — helper to start SearxNG manually on Fedora
set -euo pipefail
BASE="$HOME/Documents/searxng-fedora"
source "$BASE/venv/bin/activate"
export SEARXNG_SETTINGS_PATH="$BASE/settings.yml"
nohup python "$BASE/searxng/searx/webapp.py" >/dev/null 2>&1 &
disown
echo "SearxNG started at http://127.0.0.1:8888"
