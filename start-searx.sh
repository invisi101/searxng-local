#!/usr/bin/env bash
source "$HOME/Documents/searxng/venv/bin/activate"
export SEARXNG_SETTINGS_PATH="$HOME/Documents/searxng/settings.yml"
nohup python "$HOME/Documents/searxng/searxng/searx/webapp.py" >/dev/null 2>&1 &
disown
echo "SearxNG started at http://127.0.0.1:8888"

