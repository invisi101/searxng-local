#!/usr/bin/env bash
# setup-autostart.sh — Enable SearxNG auto-start on login (after manual mode install)
set -e

INSTALL_DIR="$HOME/Documents/searxng"
VENV_DIR="$INSTALL_DIR/venv"
PY_APP="$INSTALL_DIR/searxng/searx/webapp.py"
CONFIG="$INSTALL_DIR/settings.yml"
SERVICE_FILE="$HOME/.config/systemd/user/searxng.service"

if [ ! -d "$INSTALL_DIR" ]; then
  echo "SearxNG is not installed. Please run the installer first."
  exit 1
fi

echo "Setting up SearxNG auto-start..."

mkdir -p "$(dirname "$SERVICE_FILE")"

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=SearxNG Local Search
After=network.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
ExecStart=$VENV_DIR/bin/python $PY_APP
Environment=SEARXNG_SETTINGS_PATH=$CONFIG
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now searxng.service

echo
if systemctl --user is-active --quiet searxng.service; then
  echo "Auto-start enabled and SearxNG is now running."
  echo "It will automatically launch whenever you log in."
  echo "Access it at: http://127.0.0.1:8888"
else
  echo "Auto-start enabled, but SearxNG didn't start immediately."
  echo "Try starting it manually with: searxng start"
fi

echo
echo "To disable auto-start later, run:"
echo "  systemctl --user disable --now searxng.service"
