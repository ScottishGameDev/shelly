#!/usr/bin/env bash
# Wrapper — delegates to the Python live-picker.
exec python3 "$(dirname "$0")/pick_chrome.py" "$@"
