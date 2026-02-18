#!/usr/bin/env bash
# shodan-host.sh — Get detailed information about a specific IP from Shodan.
# Usage: shodan-host.sh <ip>
# Requires: SHODAN_API_KEY env var
set -euo pipefail

IP="${1:?Usage: shodan-host.sh <ip>}"
API_KEY="${SHODAN_API_KEY:?SHODAN_API_KEY not set}"

# Validate IP format (basic check)
if ! echo "$IP" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "Error: '$IP' does not look like a valid IPv4 address" >&2
  exit 1
fi

RESPONSE=$(curl -s --max-time 30 \
  "https://api.shodan.io/shodan/host/${IP}?key=${API_KEY}")

# Check for errors
ERROR=$(echo "$RESPONSE" | grep -o '"error":[^,}]*' | head -1 || true)
if [ -n "$ERROR" ]; then
  echo "Shodan API error: $ERROR" >&2
  echo "$RESPONSE"
  exit 1
fi

echo "=== Shodan Host Report: $IP ==="
echo ""
echo "$RESPONSE"
