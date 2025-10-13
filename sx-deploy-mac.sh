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
LAUNCH_AGENT="$HOME/Library/LaunchAgents/local.searxng.plist"

# ------------------------------------------------------------
echo "SearxNG Local Installer (macOS)"
echo "-------------------------------"
echo "1) Full automatic mode (auto-start at login)"
echo "2) Manual mode (start/stop on demand)"
printf "Choose [1/2]: "
read -r MODE

echo
echo "[*] Checking prerequisites..."
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
brew install -q python git >/dev/null 2>&1 || true

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
# Create Python virtual environment
if [ ! -d "$VENV_DIR" ]; then
  echo "[*] Creating Python virtual environment..."
  python3 -m venv "$VENV_DIR"
fi
source "$VENV_DIR/bin/activate"

# Install dependencies
echo "[*] Installing Python dependencies..."
pip install -U pip setuptools wheel pyyaml msgspec redis httpx uvloop >/dev/null
(cd "$REPO_DIR" && pip install --use-pep517 --no-build-isolation -e . >/dev/null)
deactivate

# ------------------------------------------------------------
# Config
echo "[*] Configuring SearxNG..."
cp "$REPO_DIR/searx/settings.yml" "$CONFIG"
sed -i '' "s|ultrasecretkey|$(openssl rand -hex 32)|" "$CONFIG"
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
launchctl unload ~/Library/LaunchAgents/local.searxng.plist >/dev/null 2>&1 || true
rm -f ~/Library/LaunchAgents/local.searxng.plist
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
PLIST="$LAUNCH_AGENT"

status() {
  if pgrep -f "searx/webapp.py" >/dev/null; then
    echo "🟢 Running"
  else
    echo "🔴 Not running"
  fi
}
case "\${1:-}" in
  start) bash "\$START";;
  stop) bash "\$STOP";;
  status) status;;
  *) while true; do clear; echo "SearxNG Local Control"; echo "---------------------";
       echo "1) Start"; echo "2) Stop"; echo "3) Status"; echo "4) Open in browser"; echo "5) Exit";
       printf "Choose [1-5]: "; read -r c;
       case "\$c" in
         1) bash "\$START";;
         2) bash "\$STOP";;
         3) status; read -rp 'Enter to continue...';;
         4) open "http://127.0.0.1:8888";;
         5) exit 0;;
       esac;
     done;;
esac
EOF
chmod +x "$CLI_BIN"

# ------------------------------------------------------------
# Auto-start (if selected)
if [ "$MODE" = "1" ]; then
  mkdir -p "$(dirname "$LAUNCH_AGENT")"
  cat >"$LAUNCH_AGENT"<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>local.searxng</string>
  <key>ProgramArguments</key>
  <array>
    <string>$VENV_DIR/bin/python</string>
    <string>$PY_APP</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>SEARXNG_SETTINGS_PATH</key>
    <string>$CONFIG</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>WorkingDirectory</key>
  <string>$INSTALL_DIR</string>
</dict>
</plist>
EOF

  launchctl unload "$LAUNCH_AGENT" >/dev/null 2>&1 || true
  launchctl load "$LAUNCH_AGENT"
  echo "✅ Auto-start enabled (launchd)."
else
  echo "✅ Manual mode selected. Use 'searxng' to control it."
fi

# ------------------------------------------------------------
# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zprofile"
  export PATH="$HOME/.local/bin:$PATH"
  echo "✅ Added ~/.local/bin to PATH"
fi

# ------------------------------------------------------------
# Launch in browser
open "http://127.0.0.1:8888" >/dev/null 2>&1 || true

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
echo "To set as default search engine:"
echo "  http://127.0.0.1:8888/search?q=%s"