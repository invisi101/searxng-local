#!/usr/bin/env bash
# sx-deploy-fedora.sh — Fedora installer for SearxNG Local
set -euo pipefail

APP_NAME="SearxNG"
INSTALL_DIR="$HOME/Documents/searxng"
REPO_DIR="$INSTALL_DIR/searxng"
VENV_DIR="$INSTALL_DIR/venv"
PY_APP="$REPO_DIR/searx/webapp.py"
CONFIG="$INSTALL_DIR/settings.yml"
USER_BIN="$HOME/.local/bin"
CLI_BIN="$USER_BIN/searxng"
SYSTEMD_UNIT="$HOME/.config/systemd/user/searxng.service"

# ------------------------------------------------------------
echo "$APP_NAME Local Installer (Fedora)"
echo "------------------------------------"
echo "1) Full automatic mode (auto-start at login)"
echo "2) Manual mode (start/stop on demand)"
printf "Choose [1/2]: "
read -r MODE

echo
echo "[*] Installing prerequisites..."
sudo dnf install -y \
    python3 python3-pip python3-devel \
    git gcc gcc-c++ \
    libxml2-devel libxslt-devel libffi-devel openssl-devel \
    libnotify xdg-utils

mkdir -p "$INSTALL_DIR"

# ------------------------------------------------------------
# Clone or update SearxNG
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "[*] Cloning SearxNG repository..."
  git clone --depth 1 https://github.com/searxng/searxng.git "$REPO_DIR"
else
  echo "[*] Updating existing SearxNG repository..."
  (cd "$REPO_DIR" && git pull)
fi

# ------------------------------------------------------------
# Create venv
echo "[*] Creating Python virtual environment..."
python3 -m venv "$VENV_DIR"

echo "[*] Installing Python dependencies..."
"$VENV_DIR/bin/pip" install --upgrade pip setuptools wheel pybind11
"$VENV_DIR/bin/pip" install lxml babel flask-babel pyyaml msgspec httpx uvloop
"$VENV_DIR/bin/pip" install --use-pep517 --no-build-isolation -e "$REPO_DIR"

# ------------------------------------------------------------
# Config
echo "[*] Configuring SearxNG..."
cp "$REPO_DIR/utils/templates/etc/searxng/settings.yml" "$CONFIG"
sed -i "s|secret_key:.*|secret_key: \"$(openssl rand -hex 16)\"|" "$CONFIG"

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
# Copy start/stop scripts to install directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/start-searx.sh" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/stop-searx.sh" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/start-searx.sh" "$INSTALL_DIR/stop-searx.sh"

# ------------------------------------------------------------
# CLI control tool
mkdir -p "$USER_BIN"
cat >"$CLI_BIN"<<EOF
#!/usr/bin/env bash
set -euo pipefail
BASE="$INSTALL_DIR"
START="\$BASE/start-searx.sh"
STOP="\$BASE/stop-searx.sh"
UNIT="searxng.service"

status() {
  if systemctl --user is-active --quiet "\$UNIT" 2>/dev/null; then
    echo "Running (systemd)"
  elif pgrep -f "searx/webapp.py" >/dev/null; then
    echo "Running (manual)"
  else
    echo "Not running"
  fi
}

stop_all() {
  echo "Stopping all SearxNG instances..."
  systemctl --user stop "\$UNIT" 2>/dev/null || true
  pkill -f "searx/webapp.py" 2>/dev/null || true
  sleep 1
  echo "All SearxNG processes stopped."
}

case "\${1:-}" in
  start) systemctl --user start "\$UNIT" 2>/dev/null || bash "\$START" ;;
  stop)  stop_all ;;
  restart) stop_all; sleep 1; systemctl --user start "\$UNIT" 2>/dev/null || bash "\$START" ;;
  status) status ;;
  *) echo "Usage: searxng {start|stop|restart|status}" ;;
esac
EOF
chmod +x "$CLI_BIN"

# ------------------------------------------------------------
# Auto-start setup
if [ "$MODE" = "1" ]; then
  mkdir -p "$(dirname "$SYSTEMD_UNIT")"
  cat >"$SYSTEMD_UNIT"<<EOF
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

  echo "[*] Enabling systemd-user service..."
  systemctl --user daemon-reload
  systemctl --user enable --now searxng.service
  echo "Auto-start enabled (systemd-user)."
else
  echo "Manual mode selected. Use 'searxng' to control it."
fi

# ------------------------------------------------------------
# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
  export PATH="$HOME/.local/bin:$PATH"
  echo "Added ~/.local/bin to PATH"
fi

# ------------------------------------------------------------
echo
echo "-------------------------------------------"
echo "$APP_NAME installed successfully."
echo
echo "Location: $INSTALL_DIR"
echo "Access:   http://127.0.0.1:8888"
echo
echo "Control:"
echo "  searxng start    # start"
echo "  searxng stop     # stop"
echo "  searxng restart  # restart"
echo "  searxng status   # status"
echo
echo "Uninstall:"
echo "  bash ~/Documents/searxng-local/sx-uninstall.sh"
echo "-------------------------------------------"
