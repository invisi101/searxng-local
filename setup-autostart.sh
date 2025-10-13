#!/usr/bin/env bash
# setup-autostart.sh
# Enables SearxNG to auto-start on login (after manual mode install)

set -e

SERVICE_FILE="$HOME/.config/systemd/user/searxng.service"

echo "🔧 Setting up SearxNG auto-start ..."

mkdir -p "$(dirname "$SERVICE_FILE")"

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=SearxNG (user service)
After=network.target

[Service]
Type=simple
ExecStart=$HOME/Documents/searxng/searxngEnvironment/bin/python $HOME/Documents/searxng/searxng/searx/webapp.py
Restart=on-failure

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable searxng.service
systemctl --user start searxng.service

echo "✅ Auto-start enabled. SearxNG will launch automatically when you log in."
echo "To disable auto-start, run:"
echo "  systemctl --user disable --now searxng.service"

