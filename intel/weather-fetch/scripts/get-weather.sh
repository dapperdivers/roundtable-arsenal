#!/usr/bin/env bash
set -euo pipefail

# get-weather.sh — Fetch weather data from wttr.in
# Usage: get-weather.sh [--location LOC] [--format FORMAT] [--days N]

LOCATION=""
FORMAT="text"
DAYS=1

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Fetch weather data.

Options:
  --location LOC   Location (e.g., "Dallas,TX"). Default: auto-detect
  --format FORMAT  Output: json, text, oneline (default: text)
  --days N         Forecast days 1-3 (default: 1)
  -h, --help       Show this help
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --location) LOCATION="$2"; shift 2 ;;
        --format) FORMAT="$2"; shift 2 ;;
        --days) DAYS="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown: $1" >&2; exit 1 ;;
    esac
done

ENCODED_LOC=$(printf '%s' "$LOCATION" | sed 's/ /+/g')

case "$FORMAT" in
    json)
        curl -sf "https://wttr.in/${ENCODED_LOC}?format=j1&days=${DAYS}" || {
            echo "Error: Failed to fetch weather" >&2; exit 1
        }
        ;;
    oneline)
        curl -sf "https://wttr.in/${ENCODED_LOC}?format=%l:+%C+%t+%w+%h" || {
            echo "Error: Failed to fetch weather" >&2; exit 1
        }
        echo
        ;;
    *)
        curl -sf "https://wttr.in/${ENCODED_LOC}?${DAYS}" || {
            echo "Error: Failed to fetch weather" >&2; exit 1
        }
        ;;
esac
