# Quickshell Desktop Bar

A Hyprland/Quickshell top bar with Cyberpunk and Industrial themes, a control center, live theme editing, media controls, weather, workspaces, wallpaper cycling, and system tray integration.

## Requirements

Core:

- Quickshell
- Hyprland (`hyprctl`)
- Qt 6
- Python 3
- `jq`
- `curl`
- `playerctl`
- `hyprpaper`

Feature-specific:

- `makoctl` for notification and game modes
- `pwvucontrol` for the default volume application
- `spotify-launcher` for the default Spotify command
- BlueZ and `busctl` for the optional controller control
- `wf-recorder` for the recording indicator
- PyQt6 only for the legacy standalone `pick_chrome.py` dialog

No Piper installation or voice model is required.

## Installation

Place or symlink the project at `~/.config/quickshell`, then launch:

```bash
quickshell
```

Quickshell resolves bundled scripts from its active shell root, so the QML files do not contain a username or fixed home directory.

## Configuration

Edit [config.json](config.json). Commands are JSON argument arrays, which avoids shell quoting and allows applications to be replaced directly.

```json
{
  "version": 1,
  "apps": {
    "volume": ["pwvucontrol"],
    "spotify": ["spotify-launcher"]
  },
  "weather": {
    "location": "London"
  },
  "wallpaper": {
    "directory": "~/Pictures/walls"
  },
  "controller": {
    "enabled": false,
    "address": ""
  },
  "workspace2": {
    "enabled": false,
    "id": 2,
    "apps": [
      ["kitty", "-e", "btop"],
      ["firefox"]
    ]
  },
  "minimisedStateFile": ""
}
```

### Applications

- `apps.volume` is launched by the VOL control.
- `apps.spotify` is launched when no Spotify window exists.
- `workspace2.enabled` controls whether the WS2 button is shown and defaults to `false`.
- `workspace2.apps` contains commands launched after switching to `workspace2.id`.

Each command must be a non-empty array of strings. Executables must be available in `PATH` unless an absolute path is supplied.

### Weather

`weather.location` is passed to wttr.in. No API key is required.

### Wallpapers

`wallpaper.directory` accepts an absolute path or a path beginning with `~/`. Supported files are JPG, JPEG, and PNG.

To enable automatic cycling:

```bash
mkdir -p ~/.config/systemd/user
cp systemd/wallpaper-cycle.service systemd/wallpaper-cycle.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now wallpaper-cycle.timer
```

The control center's Auto-cycle switch pauses or resumes this timer-driven behavior through an XDG cache state file.

### Controller

Controller support is disabled by default. Set `controller.enabled` to `true` and provide a Bluetooth MAC address in `controller.address`. The address remains in the user's local config; remove or replace it before publishing a personalized fork.

### Minimised windows

The minimised-windows module reads a JSON array from `minimisedStateFile`. When empty, it defaults to `$XDG_CACHE_HOME/quickshell/minimised_windows.json`. Producing that file is compositor-binding specific and is not handled by this project.

## Theme state

Theme selection and live-editor overrides are local runtime state and are ignored by Git:

- `theme_selection`
- `theme_overrides.json`

[theme_overrides.example.json](theme_overrides.example.json) documents the empty override schema. Removing the local override file restores authored theme defaults.

## Publishing

Before publishing a fork, check `config.json` for personal locations, hardware addresses, and application commands. Runtime caches and Python bytecode are already excluded by [.gitignore](.gitignore).
