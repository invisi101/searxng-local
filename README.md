# SearxNG Local — Private Search Engine Installer

This project installs your own private instance of SearxNG entirely inside your user folder — no root system changes, no system-wide background services — auto-start (if chosen) runs only in your user session, and no logging.

Everything runs from:

`~/Documents/searxng`

It uses a Python virtual environment and can be completely removed with one command.

---

## Installation
Run the following commands (do not include the ```bash lines):


### 1. Install prerequisites
```bash
sudo apt install -y python3 python3-venv python3-pip git libnotify-bin xdg-utils
```

### 2. Clone and run the installer
```bash
cd ~/Documents
git clone https://github.com/YOURUSERNAME/searxng-local.git
cd searxng-local
bash sx-deploy.sh
```

You’ll be prompted:
```
1) Full automatic mode (auto-start at login)
2) Manual mode (start/stop on demand)
Choose [1/2]:
```

---

## Usage

After installation, you can control your private SearxNG instance with these commands:
```bash
searxng start
searxng stop
searxng status
```

or use the interactive menu:
```bash
searxng
```

That opens a simple menu where you can:
- Start  
- Stop  
- Check status  
- Open your browser  
- Exit  

Access your search engine at:
```
http://127.0.0.1:8888
```

To completely remove everything:
```bash
bash ~/Documents/searxng/sx-uninstall.sh
```

---

## Set as Default Search Engine

To make your local SearxNG instance your default search engine, use this URL:
```
http://127.0.0.1:8888/search?q=%s
```

### Firefox
1. Open **Settings → Search → Add search engine**
2. Use the above URL
3. Name it “SearxNG Local”

### Brave
1. Go to **Settings → Search Engines → Manage Search Engines**
2. Add a new engine with:  
   - **Name:** SearxNG Local  
   - **Keyword:** sx  
   - **URL:** `http://127.0.0.1:8888/search?q=%s`

---

## Uninstall

To remove everything and stop the service:
```bash
bash ~/Documents/searxng/sx-uninstall.sh
```

This completely deletes the `~/Documents/searxng` directory and all associated files.

---

## Updating

To update to the latest version of SearxNG:
```bash
cd ~/Documents/searxng/searxng
git pull
```

Then restart:
```bash
searxng stop
searxng start
```

---
