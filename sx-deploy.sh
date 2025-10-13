#!/usr/bin/env bash
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
echo "========================================"
echo " SearxNG Local Installer"
echo "========================================"
echo
echo "1) Full automatic mode (auto-start at login)"
echo "2) Manual mode (start/stop on demand)"
printf "Choose [1/2]: "
read -r MODE

echo
echo "[*] Checking prerequisites..."
sudo apt update -y >/dev/null
sudo apt install -y python3 python3-venv python3-pip git libnotify-bin xdg-utils >/dev/null

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

# Python deps
echo "[*] Installing Python dependencies..."
pip install -U pip setuptools wheel pyyaml msgspec redis httpx uvloop >/dev/null
(cd "$REPO_DIR" && pip install --use-pep517 --no-build-isolation -e . >/dev/null)
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
cat >"$INSTALL_DIR/start-searx.sh"<<EOF
#!/usr/bin/env bash
source "$VENV_DIR/bin/activate"
export SEARXNG_SETTINGS_PATH="$CONFIG"
nohup python "$PY_APP" >/dev/null 2>&1 &
disown
echo "$APP_NAME started at http://127.0.0.1:8888"
EOF
chmod +x "$INSTALL_DIR/start-searx.sh"

cat >"$INSTALL_DIR/stop-searx.sh"<<'EOF'
#!/usr/bin/env bash
if pgrep -f "searx/webapp.py" >/dev/null; then
  pkill -f "searx/webapp.py"
  echo "SearxNG stopped."
else
  echo "SearxNG is not running."
fi
EOF
chmod +x "$INSTALL_DIR/stop-searx.sh"

cat >"$INSTALL_DIR/sx-uninstall.sh"<<'EOF'
#!/usr/bin/env bash
set -e
pkill -f "searx/webapp.py" >/dev/null 2>&1 || true
rm -rf "$HOME/Documents/searxng"
echo "✅ Uninstall complete."
EOF
chmod +x "$INSTALL_DIR/sx-uninstall.sh"

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

menu() {
  echo "SearxNG Local Control"
  echo "---------------------"
  echo "1) Start"
  echo "2) Stop"
  echo "3) Status"
  echo "4) Open in browser"
  echo "5) Exit"
  printf "Choose [1-5]: "
}
status() {
  if systemctl --user is-active --quiet "\$UNIT" 2>/dev/null; then
    echo "🟢 Running (systemd)"
  elif pgrep -f "searx/webapp.py" >/dev/null; then
    echo "🟢 Running (manual)"
  else
    echo "🔴 Not running"
  fi
}
case "\${1:-}" in
  start) systemctl --user start "\$UNIT" 2>/dev/null || bash "\$START"; exit;;
  stop)  systemctl --user stop "\$UNIT" 2>/dev/null || bash "\$STOP"; exit;;
  status) status; exit;;
  *) while true; do clear; menu; read -r c;
       case "\$c" in
         1) systemctl --user start "\$UNIT" 2>/dev/null || bash "\$START";;
         2) systemctl --user stop "\$UNIT" 2>/dev/null || bash "\$STOP";;
         3) status; read -rp 'Enter to continue...';;
         4) xdg-open "http://127.0.0.1:8888" >/dev/null 2>&1;;
         5) exit 0;;
       esac
     done;;
esac
EOF
chmod +x "$CLI_BIN"

# ------------------------------------------------------------
# Add ~/.local/bin to PATH if missing
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
  export PATH="$HOME/.local/bin:$PATH"
  echo "✅ Added ~/.local/bin to PATH"
fi

# ------------------------------------------------------------
# Auto-start for mode 1
if [ "$MODE" = "1" ]; then
  mkdir -p "$(dirname "$SYSTEMD_UNIT")"
  cat >"$SYSTEMD_UNIT"<<EOF
[Unit]
Description=SearxNG Local Search
After=network.target

[Service]
Environment=SEARXNG_SETTINGS_PATH=$CONFIG
ExecStart=$VENV_DIR/bin/python $PY_APP
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

  echo "[*] Enabling systemd-user service..."
  if systemctl --user daemon-reload >/dev/null 2>&1; then
    systemctl --user enable --now searxng.service >/dev/null 2>&1 && \
      echo "✅ Auto-start enabled (systemd-user)."
  else
    echo "[!] systemd-user not available; using nohup fallback."
    bash "$INSTALL_DIR/start-searx.sh"
  fi
else
  echo "✅ Manual mode selected. Use 'searxng' to control it."
fi

# ------------------------------------------------------------
# Post-install info
echo
echo "✅ Installation complete."
echo
echo "Access: http://127.0.0.1:8888"
echo
echo "Control:"
echo "  searxng start    # start"
echo "  searxng stop     # stop"
echo "  searxng status   # status"
echo
echo "Uninstall:"
echo "  bash ~/Documents/searxng/sx-uninstall.sh"
echo
echo "To set as Firefox default search:"
echo "  http://127.0.0.1:8888/search?q=%s"
echo
echo "----------------------------------------"
echo " SearxNG Local setup finished"
echo "----------------------------------------"
