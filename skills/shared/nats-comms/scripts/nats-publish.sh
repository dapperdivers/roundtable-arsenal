#!/usr/bin/env bash
# nats-publish.sh — Publish a message to NATS via the local bridge sidecar.
# Usage: nats-publish.sh <subject> '<json-data>'
set -euo pipefail

BRIDGE_URL="${NATS_BRIDGE_URL:-http://localhost:8080}"
SUBJECT="${1:?Usage: nats-publish.sh <subject> '<json-data>'}"
DATA="${2:?Usage: nats-publish.sh <subject> '<json-data>'}"

# Validate JSON
if ! echo "$DATA" | jq empty 2>/dev/null; then
  echo "ERROR: data is not valid JSON" >&2
  exit 1
fi

# Build publish request
PAYLOAD=$(jq -n --arg subject "$SUBJECT" --argjson data "$DATA" \
  '{subject: $subject, data: $data}')

# Publish via bridge
RESPONSE=$(curl -sf -X POST "${BRIDGE_URL}/publish" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" 2>&1) || {
  echo "ERROR: Failed to publish to ${SUBJECT}: ${RESPONSE}" >&2
  exit 1
}

echo "$RESPONSE" | jq .
