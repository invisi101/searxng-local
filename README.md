# SearxNG Local — Private Search Engine Installer

SORRY.  THIS WAS WORKING PERFECTLY FOR A MONTH OR SO, ok no more caps, but some changes were made on the SearxNG side and the script no longer works.
Anyone is welcome to take what's here and try to get it working.  
It was really useful for setting SearxNG up on friends' computers and I do plan to try to make a new working version at some point, but not sure when I'll have time. 
Anyway, for what it's worth......

-------


This project installs your own private instance of SearxNG entirely inside your user folder — no root system changes, no system-wide background services — auto-start (if chosen) runs only in your user session, and no logging. 

Everything runs from:

`~/Documents/searxng`

It uses a Python virtual environment and can be completely removed with one command.

---

## Compatibility

Tested on:
- Fedora 42
- Ubuntu
- Debian
- Pop!_OS

(For the Mac OS version, please visit  [https://github.com/invisi101/searx-mac-local])

Previous instances of SearxNG or aliases in .bashrc or .zshrc can clash with this install.  
It is recommended you firstly backup then remove all such SearxNG instances, folders, and files before installing this.
  
---

## Installation
Run the following commands (do not include any ```bash lines):

### Debian, Ubuntu, Pop!_OS
#### 1. Install prerequisites
```bash
sudo apt install -y python3 python3-venv python3-pip git libnotify-bin xdg-utils
```

#### 2. Clone and run the installer
```bash
cd ~/Documents
git clone https://github.com/invisi101/searxng-local.git
cd searxng-local
bash sx-deploy.sh
```

### Fedora
#### 1. Install prerequisites
```bash
sudo dnf install -y git
```

#### 2. Clone and run the installer
```bash
cd ~/Documents
git clone https://github.com/invisi101/searxng-local.git
cd searxng-local
bash sx-deploy-fedora.sh
```

You’ll be prompted:
```
1) Full automatic mode (auto-start at login)
2) Manual mode (start/stop on demand)
Choose [1/2]:
```

> ✅ **Note:** The installer automatically adds `~/.local/bin` to your PATH if it’s missing,  
> so you can run `searxng` from any terminal right away.

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

---

## Switching Between Modes

If you installed with **Manual mode (2)** and later want SearxNG to auto-start when you log in:

```bash
# Debian / Ubuntu / Pop!_OS
bash ~/Documents/searxng-local/setup-autostart.sh

# Fedora
bash ~/Documents/searxng-local/setup-autostart-fedora.sh
```

### To disable auto-start again:

```bash
systemctl --user disable --now searxng.service
```

---

## Uninstall

To remove everything and stop the service:
```bash
# Debian / Ubuntu / Pop!_OS
bash ~/Documents/searxng-local/sx-uninstall.sh

# Fedora
bash ~/Documents/searxng-local/sx-uninstall-fedora.sh
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

### Credits
This installer automates the deployment of [SearxNG](https://github.com/searxng/searxng), an open-source metasearch engine licensed under the GNU AGPLv3.
