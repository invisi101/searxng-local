#!/usr/bin/env bash
# setup-autostart.sh
# Enables SearxNG to auto-start on login (after manual mode install)

set -e

echo "🔧 Setting up SearxNG auto-start ..."

SERVICE_FILE="$HOME/.config/systemd/user/searxng.service"
mkdir -p "$(dirname "$SERVICE_FILE")"

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=SearxNG (user service)
After=network.target

[Service]
Type=simple
ExecStart=%h/Documents/searxng/venv/bin/python %h/Documents/searxng/searxng/searx/webapp.py
WorkingDirectory=%h/Documents/searxng
Restart=always
RestartSec=5
Environment=SEARXNG_SETTINGS_PATH=%h/Documents/searxng/settings.yml

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now searxng.service

echo
echo "✅ Auto-start enabled. SearxNG will launch automatically when you log in."
echo "To disable auto-start, run:"
echo "  systemctl --user disable --now searxng.service"