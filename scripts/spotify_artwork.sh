#!/usr/bin/env bash
set -euo pipefail

art_url=$(playerctl -p spotify metadata --format '{{mpris:artUrl}}' 2>/dev/null || true)
if [[ -z "$art_url" ]]; then
    printf '\n'
    exit 0
fi

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/spotify-artwork"
mkdir -p "$cache_dir"

clean_url=${art_url%%[?#]*}
filename=$(basename "$clean_url")
[[ "$filename" == *.* ]] || filename="$filename.jpg"
save_path="$cache_dir/$filename"

if [[ ! -f "$save_path" ]]; then
    if ! curl --fail --silent --show-error --location --output "$save_path" "$art_url"; then
        rm -f "$save_path"
        printf '\n'
        exit 0
    fi
fi

printf '%s\n' "$save_path"
