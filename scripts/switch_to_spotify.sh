#!/usr/bin/env bash
set -euo pipefail

workspace_id=$(hyprctl clients -j | jq -r '
    .[] | select(.class? | test("Spotify"; "i")) | .workspace.id
' | head -n 1)

if [[ -n "$workspace_id" ]]; then
    exec hyprctl dispatch focusworkspaceoncurrentmonitor "$workspace_id"
fi

if (($# == 0)); then
    set -- spotify-launcher
fi

setsid "$@" >/dev/null 2>&1 &
