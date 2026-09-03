#!/usr/bin/env bash
set -o pipefail

location=${1:-London}
encoded_location=$(jq -rn --arg value "$location" '$value | @uri')
url="https://wttr.in/${encoded_location}?format=j1"
response=$(mktemp)
trap 'rm -f "$response"' EXIT

if ! curl --fail --silent --show-error --max-time 15 --connect-timeout 5 \
        --retry 2 --retry-delay 2 --output "$response" "$url"; then
    exit 1
fi

jq -e -c '
    if (has("current_condition") and (.current_condition | length > 0)
        and has("weather") and (.weather | length > 0)) then
        {
            tempC: .current_condition[0].temp_C,
            sunrise: .weather[0].astronomy[0].sunrise,
            sunset: .weather[0].astronomy[0].sunset,
            moonrise: .weather[0].astronomy[0].moonrise,
            moonset: .weather[0].astronomy[0].moonset,
            moonPhase: .weather[0].astronomy[0].moon_phase,
            moonIllum: .weather[0].astronomy[0].moon_illumination,
            weatherDesc: .current_condition[0].weatherDesc[0].value
        }
    else error("unexpected weather response") end
' "$response"
