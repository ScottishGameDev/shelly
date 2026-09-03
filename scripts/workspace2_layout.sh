#!/usr/bin/env bash
set -euo pipefail

# Position the default workspace-2 application profile. Adjust these values or
# replace workspace2.postLaunch in config.json with your own command.
WS_ID=${1:-2}
BTOP_X=2400
BTOP_Y=130
BTOP_WIDTH=1400
BTOP_HEIGHT=1600

LEFT_X=40
LEFT_Y=130
LEFT_WIDTH=700
LEFT_HEIGHT=450

GAP=15
CAVA_HEIGHT=400

find_title() {
    local title=$1
    hyprctl clients -j | jq -r --arg title "$title" --argjson ws "$WS_ID" '
        .[]
        | select(.workspace.id == $ws)
        | select((.title // "") | test($title; "i"))
        | .address
    ' | head -n 1
}

find_class() {
    local class=$1
    hyprctl clients -j | jq -r --arg class "$class" --argjson ws "$WS_ID" '
        .[]
        | select(.workspace.id == $ws)
        | select(.class == $class)
        | .address
    ' | head -n 1
}

find_generic_kitty() {
    hyprctl clients -j | jq -r --argjson ws "$WS_ID" '
        .[]
        | select(.workspace.id == $ws)
        | select((.class // "") | test("kitty"; "i"))
        | select(((.title // "") | test("btop|bluetuith|cava"; "i")) | not)
        | .address
    ' | head -n 1
}

ensure_floating() {
    local address=$1
    local floating
    floating=$(hyprctl clients -j | jq -r --arg address "$address" '
        .[] | select(.address == $address) | .floating
    ')
    if [[ "$floating" != true ]]; then
        hyprctl dispatch togglefloating "address:$address" >/dev/null
    fi
}

move_and_size() {
    local address=$1 x=$2 y=$3 width=$4 height=$5
    ensure_floating "$address"
    hyprctl dispatch resizewindowpixel "exact $width $height,address:$address" >/dev/null
    hyprctl dispatch movewindowpixel "exact $x $y,address:$address" >/dev/null
}

btop_address=$(find_title "btop")
if [[ -n "$btop_address" ]]; then
    move_and_size "$btop_address" "$BTOP_X" "$BTOP_Y" "$BTOP_WIDTH" "$BTOP_HEIGHT"
fi

bluetuith_address=$(find_title "bluetuith")
if [[ -n "$bluetuith_address" ]]; then
    move_and_size "$bluetuith_address" "$LEFT_X" "$LEFT_Y" "$LEFT_WIDTH" "$LEFT_HEIGHT"
fi

xpad_address=$(find_class "xpad")
if [[ -n "$xpad_address" ]]; then
    xpad_y=$((LEFT_Y + LEFT_HEIGHT + GAP))
    move_and_size "$xpad_address" "$LEFT_X" "$xpad_y" "$LEFT_WIDTH" "$LEFT_HEIGHT"
fi

cava_address=$(find_title "cava")
if [[ -n "$cava_address" ]]; then
    cava_y=$((BTOP_Y + BTOP_HEIGHT + GAP))
    move_and_size "$cava_address" "$BTOP_X" "$cava_y" "$BTOP_WIDTH" "$CAVA_HEIGHT"
fi

kitty_address=$(find_title "^~$")
[[ -n "$kitty_address" ]] || kitty_address=$(find_generic_kitty)
if [[ -n "$kitty_address" ]]; then
    kitty_y=$((LEFT_Y + (LEFT_HEIGHT + GAP) * 2))
    move_and_size "$kitty_address" "$LEFT_X" "$kitty_y" "$LEFT_WIDTH" "$LEFT_HEIGHT"
fi

windy_address=$(find_title "^Windy")
[[ -n "$windy_address" ]] || windy_address=$(find_class "firefox")
if [[ -n "$windy_address" ]]; then
    windy_y=$((LEFT_Y + (LEFT_HEIGHT + GAP) * 3))
    move_and_size "$windy_address" "$LEFT_X" "$windy_y" "$LEFT_WIDTH" "$LEFT_HEIGHT"
fi
