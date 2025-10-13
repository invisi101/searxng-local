#!/usr/bin/env bash
set -euo pipefail

APP_NAME="SearxNG"
INSTALL_DIR="$HOME/Documents/searxng"
REPO_DIR="$INSTALL_DIR/searxng"
VENV_DIR="$INSTALL_DIR/venv"
PY_APP="$REPO_DIR/searx/webapp.py"
CONFIG_PATH="$INSTALL_DIR/settings.yml"

# --- prerequisites ---
echo "[*] Checking prerequisites..."
sudo apt update -y
sudo apt install -y python3 python3-venv python3-pip git libnotify-bin xdg-utils

# --- directory setup ---
mkdir -p "$INSTALL_DIR"

# --- clone repo ---
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "[*] Cloning SearxNG repository..."
  git clone https://github.com/searxng/searxng "$REPO_DIR"
else
  echo "[*] Updating existing repository..."
  (cd "$REPO_DIR" && git pull)
fi

# --- create venv ---
if [ ! -d "$VENV_DIR" ]; then
  echo "[*] Creating virtual environment..."
  python3 -m venv "$VENV_DIR"
fi
source "$VENV_DIR/bin/activate"

# --- python dependencies ---
echo "[*] Installing Python dependencies..."
pip install -U pip setuptools wheel pyyaml msgspec redis httpx uvloop
(cd "$REPO_DIR" && pip install --use-pep517 --no-build-isolation -e .)
deactivate

# --- config ---
echo "[*] Configuring $APP_NAME..."
cp "$REPO_DIR/searx/settings.yml" "$CONFIG_PATH"
sed -i "s|ultrasecretkey|$(openssl rand -hex 32)|" "$CONFIG_PATH"
cat >>"$CONFIG_PATH" <<'YAML'

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

# --- helper scripts ---
cat > "$INSTALL_DIR/start-searx.sh" <<EOF
#!/usr/bin/env bash
source "$VENV_DIR/bin/activate"
export SEARXNG_SETTINGS_PATH="$CONFIG_PATH"
nohup python "$PY_APP" >/dev/null 2>&1 &
disown
echo "$APP_NAME started at http://127.0.0.1:8888"
EOF
chmod +x "$INSTALL_DIR/start-searx.sh"

cat > "$INSTALL_DIR/stop-searx.sh" <<'EOF'
#!/usr/bin/env bash
if pgrep -f "searx/webapp.py" >/dev/null; then
  pkill -f "searx/webapp.py"
  echo "SearxNG stopped."
else
  echo "SearxNG is not running."
fi
EOF
chmod +x "$INSTALL_DIR/stop-searx.sh"

cat > "$INSTALL_DIR/sx-uninstall.sh" <<'EOF'
#!/usr/bin/env bash
set -e
echo "Stopping SearxNG..."
pkill -f "searx/webapp.py" >/dev/null 2>&1 || true
echo "Removing ~/Documents/searxng..."
rm -rf "$HOME/Documents/searxng"
echo "✅ Uninstall complete."
EOF
chmod +x "$INSTALL_DIR/sx-uninstall.sh"

echo
echo "✅ $APP_NAME installed successfully."
echo
echo "Run:"
echo "  $INSTALL_DIR/start-searx.sh    # start"
echo "  $INSTALL_DIR/stop-searx.sh     # stop"
echo "  $INSTALL_DIR/sx-uninstall.sh   # uninstall"
echo
echo "Access: http://127.0.0.1:8888"
echo
echo "To make it default in Firefox:"
echo "  Settings → Search → Add:"
echo "  http://127.0.0.1:8888/search?q=%s"

