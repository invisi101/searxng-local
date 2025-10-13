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
ExecStart=%h/Documents/searxng/venv/bin/python %h/Documents/searxng/searxng/searx/webapp.py
WorkingDirectory=%h/Documents/searxng
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now searxng.service

echo
if systemctl --user is-active --quiet searxng.service; then
  echo "✅ Auto-start enabled and SearxNG is now running."
  echo "   It will automatically launch whenever you log in."
  echo "   Access it at: http://127.0.0.1:8888"
else
  echo "⚠️  Auto-start enabled, but SearxNG didn’t start immediately."
  echo "   Try starting it manually with: searxng start"
fi

echo
echo "To disable auto-start later, run:"
echo "  systemctl --user disable --now searxng.service"