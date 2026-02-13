#!/usr/bin/env bash
# nats-publish.sh — Publish a message to NATS via the local bridge sidecar.
# Usage: nats-publish.sh <subject> '<json-data>'
# No external dependencies (no jq required).
set -euo pipefail

BRIDGE_URL="${NATS_BRIDGE_URL:-http://localhost:8080}"
SUBJECT="${1:?Usage: nats-publish.sh <subject> '<json-data>'}"
DATA="${2:?Usage: nats-publish.sh <subject> '<json-data>'}"

# Build the publish request using printf (no jq dependency)
# We need to escape the DATA for embedding in JSON
ESCAPED_DATA=$(printf '%s' "$DATA" | sed 's/\\/\\\\/g; s/"/\\"/g')

RESPONSE=$(curl -sf -X POST "${BRIDGE_URL}/publish" \
  -H "Content-Type: application/json" \
  -d "{\"subject\":\"${SUBJECT}\",\"data\":${DATA}}" 2>&1) || {
  echo "ERROR: Failed to publish to ${SUBJECT}: ${RESPONSE}" >&2
  exit 1
}

echo "$RESPONSE"
