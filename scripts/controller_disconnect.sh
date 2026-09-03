#!/usr/bin/env bash
set -euo pipefail

address=${1:-}
if [[ ! "$address" =~ ^([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}$ ]]; then
    printf 'Invalid controller address\n' >&2
    exit 2
fi

device=${address//:/_}
exec busctl call org.bluez "/org/bluez/hci0/dev_${device^^}" \
    org.bluez.Device1 Disconnect
