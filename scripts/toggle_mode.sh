#!/usr/bin/env bash
set -euo pipefail

mode=${1:-toggle}
state_dir="${XDG_RUNTIME_DIR:-/tmp}/quickshell"
state_file="$state_dir/game_mode_state"
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
wallpaper_dir=${2:-}
mkdir -p "$state_dir"

case "$mode" in
    on) new_state=1 ;;
    off) new_state=0 ;;
    ntfc) new_state=2 ;;
    *)
        current=$(cat "$state_file" 2>/dev/null || printf '0')
        ((current == 1)) && new_state=0 || new_state=1
        ;;
esac

printf '%s' "$new_state" > "$state_file"

restore_wallpaper() {
    pgrep -x hyprpaper >/dev/null || setsid hyprpaper >/dev/null 2>&1 &
    setsid bash "$script_dir/wallpaper_shift.sh" restore "$wallpaper_dir" \
        >/dev/null 2>&1 &
}

case "$new_state" in
    1)
        pkill -x hyprpaper 2>/dev/null || true
        makoctl mode -s do-not-disturb >/dev/null 2>&1 || true
        ;;
    2)
        restore_wallpaper
        makoctl mode -s do-not-disturb >/dev/null 2>&1 || true
        ;;
    *)
        restore_wallpaper
        makoctl mode -s default >/dev/null 2>&1 || true
        ;;
esac
