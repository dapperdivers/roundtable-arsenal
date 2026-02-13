#!/usr/bin/env bash
set -euo pipefail

# fetch-emails.sh — Fetch emails from the Outlook bridge API
# Usage: fetch-emails.sh [--count N] [--since Nh] [--unread] [--folder NAME] [--format FORMAT]

BRIDGE_URL="${OUTLOOK_BRIDGE_URL:-http://outlook-bridge.ai.svc.cluster.local:8080}"
COUNT=10
SINCE=""
UNREAD=""
FOLDER="inbox"
FORMAT="json"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Fetch emails from the Outlook bridge API.

Options:
  --count N        Number of emails to fetch (default: 10)
  --since Nh|Nd    Only emails from last N hours/days
  --unread         Only unread emails
  --folder NAME    Mail folder (default: inbox)
  --format FORMAT  Output format: json or summary (default: json)
  -h, --help       Show this help
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --count) COUNT="$2"; shift 2 ;;
        --since) SINCE="$2"; shift 2 ;;
        --unread) UNREAD="true"; shift ;;
        --folder) FOLDER="$2"; shift 2 ;;
        --format) FORMAT="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Build query parameters
PARAMS="folder=${FOLDER}&count=${COUNT}"
[[ -n "$SINCE" ]] && PARAMS="${PARAMS}&since=${SINCE}"
[[ -n "$UNREAD" ]] && PARAMS="${PARAMS}&unread=true"

RESPONSE=$(curl -sf "${BRIDGE_URL}/api/messages?${PARAMS}" 2>/dev/null) || {
    echo "Error: Failed to fetch emails from ${BRIDGE_URL}" >&2
    exit 1
}

if [[ "$FORMAT" == "summary" ]]; then
    echo "$RESPONSE" | jq -r '.[] | "[\(.date)] \(.from) — \(.subject)"'
else
    echo "$RESPONSE" | jq '.'
fi
