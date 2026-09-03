#!/usr/bin/env bash
set -euo pipefail

new_workspace=$(hyprctl workspaces -j | jq -r '[.[].id] | (max // 0) + 1')
exec hyprctl dispatch workspace "$new_workspace"
