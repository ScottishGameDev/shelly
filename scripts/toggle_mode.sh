#!/usr/bin/env bash
set -euo pipefail

mode=${1:-toggle}
state_dir="${XDG_RUNTIME_DIR:-/tmp}/quickshell"
state_file="$state_dir/game_mode_state"
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
wallpaper_dir=${2:-}
wallpaper_mode=${3:-images}
wallpaper_color=${4:-#26312F}
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
    local runtime_dir="${XDG_RUNTIME_DIR:-/tmp}/quickshell"
    local hyprpaper_count
    mkdir -p "$runtime_dir"

    exec 8>"$runtime_dir/hyprpaper.lock"
    flock 8
    hyprpaper_count=$(pgrep -xc hyprpaper || true)
    if [[ "$hyprpaper_count" != "1" ]]; then
        pkill -x hyprpaper 2>/dev/null || true
        setsid hyprpaper >/dev/null 2>&1 &
    fi
    flock -u 8

    setsid bash "$script_dir/wallpaper_shift.sh" restore "$wallpaper_dir" \
        "$wallpaper_mode" "$wallpaper_color" \
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
