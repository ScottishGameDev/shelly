# A backup of my Quickshell Desktop Bar

<img width="3840" height="2160" alt="image" src="https://github.com/user-attachments/assets/5c7f868d-60e1-4c69-ba18-0845d11910ce" />



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

Copy the tracked example to the ignored private config, then edit it:

```bash
cp config.example.json config.json
```

[config.example.json](config.example.json) is safe to share. `config.json` is the local runtime configuration and is ignored by Git, so it can contain personal locations, hardware addresses, and application choices. Commands are JSON argument arrays, which avoids shell quoting and allows applications to be replaced directly.

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
    "mode": "images",
    "directory": "~/Pictures/walls",
    "color": "#26312F",
    "colors": ["#26312F", "#EEF1ED", "#B8D5CC", "#DCC7A1", "#B98282"]
  },
  "controller": {
    "enabled": false,
    "address": ""
  },
  "workspace2": {
    "enabled": false,
    "id": 2,
    "monitor": "",
    "launchDelayMs": 1000,
    "apps": [
      ["kitty", "-e", "btop"],
      ["firefox"]
    ],
    "postLaunchDelayMs": 2000,
    "postLaunch": []
  },
  "minimisedStateFile": ""
}
```

### Applications

- `apps.volume` is launched by the VOL control.
- `apps.spotify` is launched when no Spotify window exists.
- `workspace2.enabled` controls whether the WS2 button is shown and defaults to `false`.
- `workspace2.apps` contains commands launched after switching to `workspace2.id`.
- `workspace2.monitor` optionally focuses a named monitor before switching workspace.
- `workspace2.launchDelayMs` waits after switching before launching applications.
- `workspace2.postLaunch` is an optional command run after all applications launch. Relative `scripts/...` paths resolve from the project root, `~` expands to the user's home, and `{workspaceId}` expands to the configured workspace ID.
- `workspace2.postLaunchDelayMs` controls how long to wait for application windows before running the post-launch command. A project-local `scripts/workspace2_layout.sh` is included as a starting point for window placement.

The WS2 Close action asks Hyprland to close each window on that workspace by its unique window address. It never kills application process IDs, because applications such as Firefox may share one process across windows on multiple workspaces.

Kitty may prompt when a compositor asks it to close. Disable that prompt only for dedicated WS2 terminals by adding `"-o", "confirm_os_window_close=0"` to their command arrays, as shown in `config.example.json`. Existing Kitty windows must be relaunched before the option takes effect.

Each command must be a non-empty array of strings. Executables must be available in `PATH` unless an absolute path is supplied.

### Weather

`weather.location` is passed to wttr.in. No API key is required.

### Wallpapers

- Set `wallpaper.mode` to `"images"` to use wallpaper rotation. `wallpaper.directory` accepts an absolute path or a path beginning with `~/`; JPG, JPEG, and PNG are supported.
- Set `wallpaper.mode` to `"solid"` to use `wallpaper.color`, which must be an opaque `#RRGGBB` value. Shelly generates a cached one-pixel PNG, so no image utility is required.
- `wallpaper.colors` supplies the solid-color swatches shown in the control center.

The control center offers Images, configured color swatches, and Theme BG, which snapshots the active theme background as a solid wallpaper. Previous, next, and Auto-cycle controls are disabled while solid mode is active. Changes are persisted to the private `config.json` and applied live.

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

Publish `config.example.json`, not your private `config.json`. Runtime configuration, theme state, caches, and Python bytecode are excluded by [.gitignore](.gitignore).
