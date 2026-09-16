# Baofeng AR-5 Helper

Omarchy Quattro **bar-widget** plugin for Baofeng AR-5 / UV-5R-class workflow helpers: memory channel lists, NOAA weather references, amateur simplex/calling references, CHIRP launch, CSV import/export, cable detection stub, and a programming safety checklist.

**Plugin id:** `io.github.raythurman.baofeng-ar5`

## Safety (read this)

- **Download from radio first. Remove antenna while programming. Volume at maximum.**
- **Never auto-upload to the radio.** This plugin launches CHIRP / manages local files only; it does not write memory to the radio.
- **You are responsible for authorized frequencies and licenses.** Reference lists (NOAA, calling, FRS/GMRS notes) are approximate — verify locally before TX.
- **This plugin runs unsandboxed** inside the Omarchy / Quickshell process with your user permissions. Review every command and dependency before enabling.

## Install

```sh
omarchy plugin add https://github.com/raythurman2386/baofeng-ar5-helper.git --enable
```

Then confirm discovery:

```sh
omarchy-shell shell rescanPlugins
omarchy plugin list --json | jq '.[] | select(.id=="io.github.raythurman.baofeng-ar5")'
```

Open the panel from the bar **AR-5** button (default section: right), or:

```sh
omarchy-shell shell summon io.github.raythurman.baofeng-ar5 '{}'
```

## Features

- Bar pill **AR-5** with details panel (Escape closes)
- Tabs: **My Channels** | **NOAA** | **Simplex / Calling**
- Search filter across name / frequency / tone / power / duplex
- Channel list with selection and **Copy frequency** (wl-copy / xclip)
- Actions: **Launch CHIRP**, **Open backups**, **Import CSV**, **Export CSV**
- Safety checklist persisted under `~/.local/share/baofeng-ar5/`
- Last programmed / last backup timestamps
- Cable detection status (stub: lists `/dev/ttyUSB*` / `/dev/ttyACM*`)
- CHIRP-like CSV columns for interchange

## CHIRP model

Default CHIRP radio model setting is **`5RM`**. Adjust if your CHIRP build uses a different id for your AR-5 / UV-5R-family radio.

## Configure (shell.json / bar settings)

Manifest defaults (override via Omarchy bar widget settings):

| Key | Default | Meaning |
|-----|---------|---------|
| `chirpCommand` | `chirp` | Executable to launch CHIRP |
| `chirpModel` | `5RM` | Model hint shown / documented for CHIRP |
| `showNoaa` | `true` | Show NOAA tab |
| `backupDir` | `~/.local/share/baofeng-ar5/backups` | CSV / backup folder |
| `dataDir` | `~/.local/share/baofeng-ar5` | channels / checklist / meta JSON |

Example layout move:

```sh
omarchy bar move io.github.raythurman.baofeng-ar5 --section right
```

## Validate

On an Omarchy host:

```sh
omarchy plugin validate ~/.config/omarchy/plugins/io.github.raythurman.baofeng-ar5
qmllint -I "$OMARCHY_PATH/shell" BarWidget.qml Panel.qml
```

## Reference frequencies

NOAA WX1–WX7 and common amateur calling/simplex values (e.g. **146.520**, **446.000**) are included as **reference only**. Channel names remind you to **verify locally** and that a **license is required for TX** where applicable. FRS/GMRS-style rows are marked RX-only reminders.

## Unsandboxed warning

Plugins share the long-running Omarchy shell. They are **not sandboxed**. This helper may run `chirp`, open folders with `xdg-open`, read/write files under your data/backup dirs, probe serial device nodes by name, and use clipboard tools. Do not enable untrusted plugins.

## Legal

You alone are responsible for complying with radio regulations, licenses, and local band plans. The authors provide no warranty. See [LICENSE](LICENSE) (MIT).

## Remove

```sh
omarchy plugin remove io.github.raythurman.baofeng-ar5
```
