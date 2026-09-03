#!/usr/bin/env bash
set -euo pipefail

address=${1:-}
if [[ ! "$address" =~ ^([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}$ ]]; then
    printf '0\n'
    exit 0
fi

device=${address//:/_}
if busctl get-property org.bluez "/org/bluez/hci0/dev_${device^^}" \
        org.bluez.Device1 Connected 2>/dev/null | grep -q 'true'; then
    printf '1\n'
else
    printf '0\n'
fi
