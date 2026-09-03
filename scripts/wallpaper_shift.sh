#!/usr/bin/env bash
# Usage: wallpaper_shift.sh next|prev|tick|restore [wallpaper-directory]

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CONFIG_FILE="$SCRIPT_DIR/../config.json"
WALL_DIR=${2:-}
if [[ -z "$WALL_DIR" && -f "$CONFIG_FILE" ]]; then
    WALL_DIR=$(jq -r '.wallpaper.directory // empty' "$CONFIG_FILE")
fi
WALL_DIR=${WALL_DIR:-"$HOME/Pictures/walls"}
[[ "$WALL_DIR" == ~/* ]] && WALL_DIR="$HOME/${WALL_DIR#~/}"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell"
STATEFILE="$CACHE_DIR/wallpaper_index"
FREEZEFILE="$CACHE_DIR/wallpaper_freeze"
mkdir -p "$CACHE_DIR"

[ -d "$WALL_DIR" ] || { echo "Wallpaper directory not found: $WALL_DIR" >&2; exit 1; }

mapfile -t FILES < <(find "$WALL_DIR" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | sort)
[ ${#FILES[@]} -gt 0 ] || { echo "No images found in $WALL_DIR" >&2; exit 1; }

# tick: called by systemd timer every 30s — silently exits if frozen
if [[ "${1:-}" == "tick" ]]; then
    freeze=$(cat "$FREEZEFILE" 2>/dev/null || echo "0")
    [[ "$freeze" == "1" ]] && exit 0
    exec "$0" next "$WALL_DIR"
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
    # wait for hyprpaper socket to be ready (up to 4 s)
    for _ in $(seq 1 20); do
        hyprctl hyprpaper listloaded &>/dev/null && break
        sleep 0.2
    done
    hyprctl hyprpaper preload "$target" >/dev/null 2>&1
    while IFS=': ' read -r mon _; do
        hyprctl hyprpaper wallpaper "${mon},${target}" >/dev/null 2>&1
    done < <(hyprctl hyprpaper listactive 2>/dev/null)
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

while IFS=': ' read -r mon _; do
    hyprctl hyprpaper wallpaper "${mon},${FILES[$idx]}" >/dev/null 2>&1
done < <(hyprctl hyprpaper listactive 2>/dev/null)

# Reset the systemd timer so the next auto-tick is a full 30 s away
systemctl --user restart wallpaper-cycle.timer 2>/dev/null || true
