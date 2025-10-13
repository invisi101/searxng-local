#!/usr/bin/env bash
# SearxNG Local Installer (macOS)
# Author: invis101
# Description: Installs a fully local SearxNG instance on macOS — either manual or auto-start mode.

set -euo pipefail

APP_NAME="SearxNG"
INSTALL_DIR="$HOME/Documents/searxng"
REPO_DIR="$INSTALL_DIR/searxng"
VENV_DIR="$INSTALL_DIR/venv"
PY_APP="$REPO_DIR/searx/webapp.py"
CONFIG="$INSTALL_DIR/settings.yml"
USER_BIN="$HOME/.local/bin"
CLI_BIN="$USER_BIN/searxng"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/local.searxng.plist"

echo "$APP_NAME Local Installer (macOS)"
echo "-------------------------------"
echo "1) Full automatic mode (auto-start at login)"
echo "2) Manual mode (start/stop on demand)"
printf "Choose [1/2]: "
read -r MODE

echo
echo "[*] Checking prerequisites..."
brew install -q python git || true
python3 -m ensurepip --upgrade || true

echo "[*] Ensuring build dependencies..."
brew install -q python-setuptools pybind11 || true
python3 -m pip install --upgrade pip setuptools wheel pybind11 || true

mkdir -p "$INSTALL_DIR"

echo "[*] Cloning SearxNG repository..."
if [ ! -d "$REPO_DIR/.git" ]; then
  git clone --depth 1 https://github.com/searxng/searxng.git "$REPO_DIR"
else
  echo "SearxNG repo already exists — pulling latest changes..."
  (cd "$REPO_DIR" && git pull)
fi

echo "[*] Creating Python virtual environment..."
python3 -m venv "$VENV_DIR"

echo "[*] Installing Python dependencies..."
"$VENV_DIR/bin/pip" install --upgrade pip setuptools wheel
"$VENV_DIR/bin/pip" install -e "$REPO_DIR"

# -------------------------
# Create start/stop scripts
# -------------------------
cat > "$INSTALL_DIR/start-searx.sh" <<'EOF'
#!/usr/bin/env bash
set -e
BASE="$HOME/Documents/searxng"
source "$BASE/venv/bin/activate"
python "$BASE/searxng/searx/webapp.py" > /dev/null 2>&1 &
disown
echo "✅ SearxNG started at http://127.0.0.1:8888"
EOF

cat > "$INSTALL_DIR/stop-searx.sh" <<'EOF'
#!/usr/bin/env bash
set -e
if pgrep -f "searx/webapp.py" >/dev/null; then
  pkill -f "searx/webapp.py"
  echo "🛑 SearxNG stopped"
else
  echo "⚪ SearxNG is not running"
fi
EOF

chmod +x "$INSTALL_DIR"/start-searx.sh "$INSTALL_DIR"/stop-searx.sh

# -------------------------
# Create control CLI tool
# -------------------------
mkdir -p "$USER_BIN"
cat > "$CLI_BIN" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
BASE="$HOME/Documents/searxng"
START="$BASE/start-searx.sh"
STOP="$BASE/stop-searx.sh"
UNIT="$HOME/Library/LaunchAgents/local.searxng.plist"

status() {
  if pgrep -f "searx/webapp.py" >/dev/null; then
    echo "🟢 Running"
  else
    echo "🔴 Not running"
  fi
}

case "${1:-}" in
  start) bash "$START" ;;
  stop)  bash "$STOP" ;;
  status) status ;;
  *) echo "Usage: searxng {start|stop|status}" ;;
esac
EOF

chmod +x "$CLI_BIN"

# -------------------------
# Launchd (auto mode)
# -------------------------
if [ "$MODE" == "1" ]; then
  echo "[*] Setting up auto-start (LaunchAgent)..."
  mkdir -p "$(dirname "$LAUNCH_AGENT")"

  cat > "$LAUNCH_AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>local.searxng</string>
  <key>ProgramArguments</key>
  <array>
    <string>$VENV_DIR/bin/python</string>
    <string>$PY_APP</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>WorkingDirectory</key><string>$REPO_DIR</string>
  <key>StandardOutPath</key><string>$INSTALL_DIR/searxng.log</string>
  <key>StandardErrorPath</key><string>$INSTALL_DIR/searxng.err</string>
</dict>
</plist>
EOF

  launchctl unload "$LAUNCH_AGENT" 2>/dev/null || true
  launchctl load "$LAUNCH_AGENT"
  echo "✅ Auto-start enabled (LaunchAgent)."
fi

# -------------------------
# Done
# -------------------------
echo
echo "✅ Installation complete."
echo
echo "Access: http://127.0.0.1:8888"
echo
echo "Control:"
echo "  searxng start    # start manually"
echo "  searxng stop     # stop manually"
echo "  searxng status   # check status"
echo
echo "Uninstall:"
echo "  bash ~/Documents/searxng-local/sx-uninstall-mac.sh"
echo
echo "To set as Firefox default search:"
echo "  http://127.0.0.1:8888/search?q=%s"
echo
echo "----------------------------------------"
echo " $APP_NAME Local setup finished"
echo "----------------------------------------"