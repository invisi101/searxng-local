#!/usr/bin/env bash
# sx-deploy-fedora.sh — Fedora installer for SearxNG Local
# Installs to ~/Documents/searxng-fedora and offers:
#   1) Auto-start at login (systemd --user)
#   2) Manual start/stop via CLI (searxng-fedora)
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

echo "SearxNG Local Installer (Fedora)"
echo "--------------------------------"
echo "1) Full automatic mode (auto-start at login)"
echo "2) Manual mode (start/stop on demand)"
printf "Choose [1/2]: "
read -r MODE

echo
echo "[*] Checking prerequisites with dnf..."
sudo dnf install -y python3 python3-venv python3-pip git libnotify xdg-utils

# Ensure ~/.local/bin is on PATH for future shells and this session
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
  export PATH="$HOME/.local/bin:$PATH"
  echo "✅ Added ~/.local/bin to PATH"
fi

mkdir -p "$INSTALL_DIR"

# Clone or update SearxNG
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "[*] Cloning SearxNG repository..."
  git clone https://github.com/searxng/searxng "$REPO_DIR"
else
  echo "[*] Updating existing SearxNG repository..."
  (cd "$REPO_DIR" && git pull)
fi

# Create venv
if [ ! -d "$VENV_DIR" ]; then
  echo "[*] Creating Python virtual environment..."
  python3 -m venv "$VENV_DIR"
fi
source "$VENV_DIR/bin/activate"

# Python deps
echo "[*] Installing Python dependencies..."
pip install -U pip setuptools wheel pyyaml msgspec redis httpx uvloop
# Install SearxNG editable
( cd "$REPO_DIR" && pip install --use-pep517 --no-build-isolation -e . )
deactivate

# Config
echo "[*] Configuring SearxNG..."
cp "$REPO_DIR/searx/settings.yml" "$CONFIG"
# secret key
if command -v openssl >/dev/null 2>&1; then
  sed -i "s|ultrasecretkey|$(openssl rand -hex 32)|" "$CONFIG"
else
  # fallback random
  sed -i "s|ultrasecretkey|$(python3 - <<'PY'
import secrets;print(secrets.token_hex(32))
PY)|" "$CONFIG"
fi

# quiet logging
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

# Helper scripts (shared)
cat >"$INSTALL_DIR/start-searx-fedora.sh"<<'EOF'
#!/usr/bin/env bash
set -e
BASE="$HOME/Documents/searxng-fedora"
source "$BASE/venv/bin/activate"
export SEARXNG_SETTINGS_PATH="$BASE/settings.yml"
nohup python "$BASE/searxng/searx/webapp.py" >/dev/null 2>&1 &
disown
echo "SearxNG started at http://127.0.0.1:8888"
EOF
chmod +x "$INSTALL_DIR/start-searx-fedora.sh"

cat >"$INSTALL_DIR/stop-searx-fedora.sh"<<'EOF'
#!/usr/bin/env bash
set -e
if pgrep -f "searx/webapp.py" >/dev/null; then
  pkill -f "searx/webapp.py"
  echo "SearxNG stopped."
else
  echo "SearxNG is not running."
fi
EOF
chmod +x "$INSTALL_DIR/stop-searx-fedora.sh"

# CLI control tool
mkdir -p "$USER_BIN"
cat >"$CLI_BIN"<<'EOF'
#!/usr/bin/env bash
set -euo pipefail
BASE="$HOME/Documents/searxng-fedora"
START="$BASE/start-searx-fedora.sh"
STOP="$BASE/stop-searx-fedora.sh"
UNIT="searxng-fedora.service"

status() {
  if systemctl --user is-active --quiet "$UNIT" 2>/dev/null; then
    echo "🟢 Running (systemd)"
  elif pgrep -f "searx/webapp.py" >/dev/null; then
    echo "🟢 Running (manual)"
  else
    echo "🔴 Not running"
  fi
}

case "${1:-}" in
  start) systemctl --user start "$UNIT" 2>/dev/null || bash "$START" ;;
  stop)  systemctl --user stop "$UNIT"  2>/dev/null || bash "$STOP"  ;;
  status) status ;;
  *) echo "Usage: searxng-fedora {start|stop|status}" ;;
esac
EOF
chmod +x "$CLI_BIN"

# Auto-start for mode 1
if [ "$MODE" = "1" ]; then
  mkdir -p "$(dirname "$SYSTEMD_UNIT")"
  cat >"$SYSTEMD_UNIT"<<EOF
[Unit]
Description=SearxNG Local Search (Fedora)
After=network.target

[Service]
Environment=SEARXNG_SETTINGS_PATH=$CONFIG
ExecStart=$VENV_DIR/bin/python $PY_APP
WorkingDirectory=$INSTALL_DIR
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

  echo "[*] Enabling systemd-user service..."
  systemctl --user daemon-reload
  systemctl --user enable --now searxng-fedora.service &&     echo "✅ Auto-start enabled (systemd-user)."
else
  echo "✅ Manual mode selected. Use 'searxng-fedora' to control it."
fi

# Post-install info
echo
echo "✅ Installation complete."
echo
echo "Access: http://127.0.0.1:8888"
echo
echo "Control:"
echo "  searxng-fedora start    # start"
echo "  searxng-fedora stop     # stop"
echo "  searxng-fedora status   # status"
echo
echo "Uninstall:"
echo "  bash ~/Documents/searxng-local/sx-uninstall-fedora.sh"
echo
echo "To set as Firefox default search:"
echo "  http://127.0.0.1:8888/search?q=%s"
