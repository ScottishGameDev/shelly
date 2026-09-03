#!/usr/bin/env bash
# Usage: wallpaper_shift.sh next|prev|tick|restore [wallpaper-directory] [images|solid] [#RRGGBB]

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CONFIG_FILE="$SCRIPT_DIR/../config.json"
[[ -f "$CONFIG_FILE" ]] || CONFIG_FILE="$SCRIPT_DIR/../config.example.json"
WALL_DIR=${2:-}
WALL_MODE=${3:-}
SOLID_COLOR=${4:-}
if [[ -z "$WALL_DIR" && -f "$CONFIG_FILE" ]]; then
    WALL_DIR=$(jq -r '.wallpaper.directory // empty' "$CONFIG_FILE")
fi
if [[ -z "$WALL_MODE" && -f "$CONFIG_FILE" ]]; then
    WALL_MODE=$(jq -r '.wallpaper.mode // "images"' "$CONFIG_FILE")
fi
if [[ -z "$SOLID_COLOR" && -f "$CONFIG_FILE" ]]; then
    SOLID_COLOR=$(jq -r '.wallpaper.color // "#26312F"' "$CONFIG_FILE")
fi
WALL_DIR=${WALL_DIR:-"$HOME/Pictures/walls"}
WALL_MODE=${WALL_MODE:-images}
SOLID_COLOR=${SOLID_COLOR:-#26312F}
[[ "$WALL_DIR" == "~/"* ]] && WALL_DIR="$HOME/${WALL_DIR#\~/}"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell"
STATEFILE="$CACHE_DIR/wallpaper_index"
FREEZEFILE="$CACHE_DIR/wallpaper_freeze"
mkdir -p "$CACHE_DIR"
exec 9>"$CACHE_DIR/wallpaper.lock"
flock 9

apply_wallpaper() {
    local target=$1
    hyprctl hyprpaper preload "$target" >/dev/null 2>&1 || true
    while IFS=': ' read -r monitor _; do
        [[ -n "$monitor" ]] || continue
        hyprctl hyprpaper wallpaper "${monitor},${target}" >/dev/null 2>&1
    done < <(hyprctl hyprpaper listactive 2>/dev/null)
}

if [[ "$WALL_MODE" == "solid" ]]; then
    solid_path="$CACHE_DIR/solid-${SOLID_COLOR#\#}.png"
    python3 "$SCRIPT_DIR/solid_wallpaper.py" "$SOLID_COLOR" "$solid_path"
    apply_wallpaper "$solid_path"
    exit 0
fi

[[ "$WALL_MODE" == "images" ]] || {
    echo "Wallpaper mode must be images or solid: $WALL_MODE" >&2
    exit 2
}

[ -d "$WALL_DIR" ] || { echo "Wallpaper directory not found: $WALL_DIR" >&2; exit 1; }

mapfile -t FILES < <(find "$WALL_DIR" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | sort)
[ ${#FILES[@]} -gt 0 ] || { echo "No images found in $WALL_DIR" >&2; exit 1; }

# tick: called by systemd timer every 30s — silently exits if frozen
if [[ "${1:-}" == "tick" ]]; then
    freeze=$(cat "$FREEZEFILE" 2>/dev/null || echo "0")
    [[ "$freeze" == "1" ]] && exit 0
    WALLPAPER_FROM_TIMER=1 exec "$0" next "$WALL_DIR" "$WALL_MODE" "$SOLID_COLOR"
fi

case "${1:-next}" in
    prev|-1) delta=-1 ;;
    next|+1|1) delta=1 ;;
    restore) delta=0 ;;
    *) echo "Usage: $0 next|prev|tick|restore" >&2; exit 2 ;;
esac

# restore: read index from statefile, preload, and re-apply without changing index
if [[ "${1:-}" == "restore" ]]; then
    idx=0
    if [ -f "$STATEFILE" ]; then
        saved=$(cat "$STATEFILE" 2>/dev/null)
        [[ "$saved" =~ ^[0-9]+$ ]] && idx=$saved
    fi
    idx=$((idx % ${#FILES[@]}))
    target="${FILES[$idx]}"
    apply_wallpaper "$target"
    exit 0
fi

idx=0
current=$(hyprctl hyprpaper listactive 2>/dev/null | head -1 | sed 's/^[^:]*: *//')
if [ -n "$current" ]; then
    for i in "${!FILES[@]}"; do
        [ "${FILES[$i]}" = "$current" ] && idx=$i && break
    done
elif [ -f "$STATEFILE" ]; then
    saved=$(cat "$STATEFILE" 2>/dev/null)
    [[ "$saved" =~ ^[0-9]+$ ]] && idx=$saved
fi

n=${#FILES[@]}
idx=$(( (idx + delta + n) % n ))
printf "%d" "$idx" > "$STATEFILE"

apply_wallpaper "${FILES[$idx]}"

if [[ "${WALLPAPER_FROM_TIMER:-0}" != "1" ]]; then
    systemctl --user try-restart wallpaper-cycle.timer 2>/dev/null || true
fi
