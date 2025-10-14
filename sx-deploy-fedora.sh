#!/usr/bin/env bash
# sx-deploy-fedora.sh — Fedora installer for SearxNG Local
set -euo pipefail

APP_NAME="SearxNG"
INSTALL_DIR="$HOME/Documents/searxng-fedora"
REPO_DIR="$INSTALL_DIR/searxng"
VENV_DIR="$INSTALL_DIR/venv"
PY_APP="$REPO_DIR/searx/webapp.py"
CONFIG="$INSTALL_DIR/settings.yml"
USER_BIN="$HOME/.local/bin"
CLI_BIN="$USER_BIN/searxng-fedora"
SYSTEMD_UNIT="$HOME/.config/systemd/user/searxng-fedora.service"

# ------------------------------------------------------------
echo "SearxNG Local Installer (Fedora)"
echo "--------------------------------"
echo "1) Full automatic mode (auto-start at login)"
echo "2) Manual mode (start/stop on demand)"
printf "Choose [1/2]: "
read -r MODE

echo

echo "[*] Checking prerequisites with dnf..."
sudo dnf install -y python3 python3-pip python3-virtualenv git libnotify xdg-utils || true

mkdir -p "$INSTALL_DIR"

# ------------------------------------------------------------
# Clone or update SearxNG
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "[*] Cloning SearxNG repository..."
  git clone https://github.com/searxng/searxng "$REPO_DIR"
else
  echo "[*] Updating existing SearxNG repository..."
  (cd "$REPO_DIR" && git pull)
fi

# ------------------------------------------------------------
# Create venv
if [ ! -d "$VENV_DIR" ]; then
  echo "[*] Creating Python virtual environment..."
  python3 -m venv "$VENV_DIR"
fi
source "$VENV_DIR/bin/activate"

echo "[*] Installing Python dependencies..."
pip install -U pip setuptools wheel pyyaml msgspec redis httpx uvloop
(cd "$REPO_DIR" && pip install --use-pep517 --no-build-isolation -e .)
deactivate

# ------------------------------------------------------------
# Config
echo "[*] Configuring SearxNG..."
cp "$REPO_DIR/searx/settings.yml" "$CONFIG"
sed -i "s|ultrasecretkey|$(openssl rand -hex 32)|" "$CONFIG"
cat >>"$CONFIG" <<'YAML'

logging:
  version: 1
  disable_existing_loggers: true
  root:
    level: CRITICAL
    handlers: []
  loggers:
    searx:
      level: CRITICAL
      handlers: []
      propagate: false
YAML

# ------------------------------------------------------------
# Helper scripts
cat >"$INSTALL_DIR/start-searx-fedora.sh"<<EOF
#!/usr/bin/env bash
source "$VENV_DIR/bin/activate"
export SEARXNG_SETTINGS_PATH="$CONFIG"
nohup python "$PY_APP" >/dev/null 2>&1 &
disown
echo "$APP_NAME started at http://127.0.0.1:8888"
EOF
chmod +x "$INSTALL_DIR/start-searx-fedora.sh"

cat >"$INSTALL_DIR/stop-searx-fedora.sh"<<'EOF'
#!/usr/bin/env bash
if pgrep -f "searx/webapp.py" >/dev/null; then
  pkill -f "searx/webapp.py"
  echo "SearxNG stopped."
else
  echo "SearxNG is not running."
fi
EOF
chmod +x "$INSTALL_DIR/stop-searx-fedora.sh"

# ------------------------------------------------------------
# CLI control tool
mkdir -p "$USER_BIN"
cat >"$CLI_BIN"<<EOF
#!/usr/bin/env bash
set -euo pipefail
BASE="$INSTALL_DIR"
START="\$BASE/start-searx-fedora.sh"
STOP="\$BASE/stop-searx-fedora.sh"
UNIT="searxng-fedora.service"

status() {
  if systemctl --user is-active --quiet "\$UNIT" 2>/dev/null; then
    echo "🟢 Running (systemd)"
  elif pgrep -f "\$BASE/searxng/searx/webapp.py" >/dev/null; then
    echo "🟢 Running (manual)"
  else
    echo "🔴 Not running"
  fi
}

stop_all() {
  echo "🧹 Stopping all SearxNG instances..."
  systemctl --user stop "\$UNIT" 2>/dev/null || true
  pkill -f "\$BASE/searxng/searx/webapp.py" 2>/dev/null || true
  sleep 1
  echo "✅ All SearxNG processes stopped."
}

case "\${1:-}" in
  start) systemctl --user start "\$UNIT" 2>/dev/null || bash "\$START" ;;
  stop)  stop_all ;;
  restart) stop_all; sleep 1; systemctl --user start "\$UNIT" 2>/dev/null || bash "\$START" ;;
  status) status ;;
  *) echo "Usage: searxng-fedora {start|stop|restart|status}" ;;
esac
EOF
chmod +x "$CLI_BIN"

# ------------------------------------------------------------
# Auto-start setup
if [ "$MODE" = "1" ]; then
  mkdir -p "$(dirname "$SYSTEMD_UNIT")"
  cat >"$SYSTEMD_UNIT"<<EOF
[Unit]
Description=SearxNG (Fedora user service)
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

  echo "✅ Auto-start enabled (systemd-user)."
else
  echo "✅ Manual mode selected. Use 'searxng-fedora' to control it."
fi

# ------------------------------------------------------------
# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
  export PATH="$HOME/.local/bin:$PATH"
  echo "✅ Added ~/.local/bin to PATH"
fi

# ------------------------------------------------------------
# Post-install info
if command -v firefox >/dev/null 2>&1; then
  (nohup firefox "http://127.0.0.1:8888" >/dev/null 2>&1 || true) &
fi

echo
cat <<'INFO'
✅ Installation complete.

Access: http://127.0.0.1:8888

Control:
  searxng-fedora start    # start
  searxng-fedora stop     # stop
  searxng-fedora restart  # restart
  searxng-fedora status   # status

Uninstall:
  bash ~/Documents/searxng-local/sx-uninstall-fedora.sh
INFO