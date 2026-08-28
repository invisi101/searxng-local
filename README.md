# SearxNG Local — Private Search Engine Installer

This project installs your own private instance of SearxNG entirely inside your user folder — no root system changes, no system-wide background services — auto-start (if chosen) runs only in your user session, and no logging.

Everything runs from:

`~/Documents/searxng`

It uses a Python virtual environment and can be completely removed with one command.

---

## Compatibility

Tested on:
- Arch Linux / Manjaro / EndeavourOS
- Fedora 42
- Ubuntu
- Debian
- Pop!_OS

(For the macOS version, please visit [searx-mac-local](https://github.com/invisi101/searx-mac-local))

Previous instances of SearxNG or aliases in .bashrc or .zshrc can clash with this install.
It is recommended you firstly backup then remove all such SearxNG instances, folders, and files before installing this.

---

## Installation

### Debian, Ubuntu, Pop!_OS

```bash
cd ~/Documents
git clone https://github.com/invisi101/searxng-local.git
cd searxng-local
bash sx-deploy.sh
```

### Fedora

```bash
cd ~/Documents
git clone https://github.com/invisi101/searxng-local.git
cd searxng-local
bash sx-deploy-fedora.sh
```

### Arch Linux / Manjaro / EndeavourOS

```bash
cd ~/Documents
git clone https://github.com/invisi101/searxng-local.git
cd searxng-local
bash sx-deploy-arch.sh
```

---

You'll be prompted:
```
1) Full automatic mode (auto-start at login)
2) Manual mode (start/stop on demand)
Choose [1/2]:
```

> The installer automatically adds `~/.local/bin` to your PATH if it's missing,
> so you can run `searxng` from any terminal right away.

---

## Usage

After installation, you can control your private SearxNG instance with these commands:
```bash
searxng start
searxng stop
searxng restart
searxng status
```

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
3. Name it "SearxNG Local"

---

## Switching Between Modes

If you installed with **Manual mode (2)** and later want SearxNG to auto-start when you log in:

```bash
bash ~/Documents/searxng-local/setup-autostart.sh
```

### To disable auto-start again:

```bash
systemctl --user disable --now searxng.service
```

---

## Uninstall

To remove everything and stop the service:
```bash
bash ~/Documents/searxng-local/sx-uninstall.sh
```

This completely deletes the `~/Documents/searxng` directory and all associated files.

---

## Updating

To update to the latest version of SearxNG:
```bash
cd ~/Documents/searxng/searxng
git pull
```

Re-running the installer is safe: it will not overwrite an existing
`settings.yml`. Delete that file first if you want a clean default config
regenerated.

Then restart:
```bash
searxng restart
```

---

## Troubleshooting

### "Sorry! No results were found" with errors next to engine names

Open the results page and look under **Messages from the search engines**. The
error text tells you which of these it is.

**`too many requests` / engine works then disappears.**
SearXNG suspends an engine that rate-limits it (Brave for 180s, Startpage for
3600s), and a retry inside that window re-suspends it — so a brief hiccup can
look like a permanently dead engine. Restart to clear the timers:

```bash
searxng restart
```

If an engine only drops out after several searches in a row, that is normal
rate-limiting, not a fault.

**`CAPTCHA` — usually a VPN.**
Startpage, Qwant and Brave block or challenge shared VPN exit IPs. Startpage's
block page names the provider directly. If you search through a VPN, expect
these engines to be unreliable and lean on ones that tolerate it — Bing,
Mojeek, Yahoo and Wikipedia are dependable. Enable them in `~/Documents/searxng/settings.yml`:

```yaml
engines:
  - name: bing
    engine: bing
    disabled: false
  - name: mojeek
    engine: mojeek
    disabled: false
  - name: yahoo
    engine: yahoo
    disabled: false
```

Then `searxng restart`.

**`HTTP error` from DuckDuckGo.**
DuckDuckGo currently returns `406 Not Acceptable` to SearXNG's HTTP client
while accepting an ordinary browser from the same machine — it is fingerprinting
the TLS handshake. Nothing to fix locally; it comes and goes as SearXNG works
around it upstream, so keep SearXNG updated (see **Updating**). The search-box
autocomplete uses a different DuckDuckGo endpoint and is unaffected.

**`HTTP connection error` from a single engine.**
Check that its hostname actually resolves. Ad-blocking DNS (Pi-hole,
pfBlockerNG, AdGuard Home) sometimes sinkholes engine domains:

```bash
getent hosts cse.google.com
```

A result of `0.0.0.0` means your DNS is blocking it. Allow the domain in your
blocker, or disable that engine.

### Disabling an engine

Add it to the `engines:` list in `~/Documents/searxng/settings.yml`:

```yaml
engines:
  - name: startpage
    engine: startpage
    disabled: true
```

Note that the autocomplete backend set under `search: autocomplete:` needs its
engine left enabled — disabling the DuckDuckGo engine while
`autocomplete: 'duckduckgo'` is set will break the search box's suggestions.
Point `autocomplete:` at an engine you have kept enabled, such as `'google'`.

### Checking the logs

The installer silences SearXNG's own logging, so read the service journal
instead (auto-start mode only — manual mode discards output):

```bash
journalctl --user -u searxng -f
```

Engine failures appear there as `WARNING:searx.engines.<name>: ErrorContext(...)`
with the underlying exception at the end of the line.

---

### Credits
This installer automates the deployment of [SearxNG](https://github.com/searxng/searxng), an open-source metasearch engine licensed under the GNU AGPLv3.
