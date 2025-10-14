#!/usr/bin/env bash
# setup-autostart-fedora.sh — enable auto-start (systemd --user) for Fedora install
set -euo pipefail

SERVICE_FILE="$HOME/.config/systemd/user/searxng-fedora.service"
INSTALL_DIR="$HOME/Documents/searxng-fedora"
VENV_DIR="$INSTALL_DIR/venv"
PY_APP="$INSTALL_DIR/searxng/searx/webapp.py"
CONFIG="$INSTALL_DIR/settings.yml"

echo "🔧 Setting up SearxNG auto-start (Fedora) ..."

mkdir -p "$(dirname "$SERVICE_FILE")"

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=SearxNG (user service, Fedora)
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
systemctl --user enable --now searxng-fedora.service

echo
if systemctl --user is-active --quiet searxng-fedora.service; then
  echo "✅ Auto-start enabled and SearxNG is now running."
  echo "   It will automatically launch whenever you log in."
  echo "   Access it at: http://127.0.0.1:8888"
else
  echo "⚠️  Auto-start enabled, but SearxNG didn’t start immediately."
  echo "   Try starting it manually with: searxng-fedora start"
fi

echo
echo "To disable auto-start later, run:"
echo "  systemctl --user disable --now searxng-fedora.service"
