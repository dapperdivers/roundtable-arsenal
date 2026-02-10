#!/usr/bin/env bash
# nats-respond.sh — Respond to a NATS task with a properly formatted envelope.
# Usage: nats-respond.sh <task-id> <domain> '<payload-json>'
# No external dependencies (no jq required).
set -euo pipefail

BRIDGE_URL="${NATS_BRIDGE_URL:-http://localhost:8080}"
TASK_ID="${1:?Usage: nats-respond.sh <task-id> <domain> '<payload-json>'}"
DOMAIN="${2:?Usage: nats-respond.sh <task-id> <domain> '<payload-json>'}"
PAYLOAD="${3:?Usage: nats-respond.sh <task-id> <domain> '<payload-json>'}"

# Get bridge info for fleet/agent IDs
INFO=$(curl -sf "${BRIDGE_URL}/info" 2>/dev/null) || {
  echo "ERROR: Cannot reach bridge at ${BRIDGE_URL}/info" >&2
  exit 1
}

# Parse info without jq — extract using grep/sed
FLEET_ID=$(echo "$INFO" | grep -o '"fleetId":"[^"]*"' | head -1 | cut -d'"' -f4)
AGENT_ID=$(echo "$INFO" | grep -o '"agentId":"[^"]*"' | head -1 | cut -d'"' -f4)
RESULT_PREFIX=$(echo "$INFO" | grep -o '"resultPrefix":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$FLEET_ID" ] || [ -z "$AGENT_ID" ]; then
  echo "ERROR: Could not parse bridge info" >&2
  exit 1
fi

# Build subject
SUBJECT="${RESULT_PREFIX}.${DOMAIN}.${TASK_ID}"

# Build envelope
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
ENVELOPE="{\"id\":\"${TASK_ID}\",\"fleetId\":\"${FLEET_ID}\",\"type\":\"task.result\",\"from\":\"${AGENT_ID}\",\"to\":\"tim\",\"timestamp\":\"${TIMESTAMP}\",\"payload\":${PAYLOAD}}"

# Publish via bridge
PUBLISH_BODY="{\"subject\":\"${SUBJECT}\",\"data\":${ENVELOPE}}"

RESPONSE=$(curl -sf -X POST "${BRIDGE_URL}/publish" \
  -H "Content-Type: application/json" \
  -d "$PUBLISH_BODY" 2>&1) || {
  echo "ERROR: Failed to publish result to ${SUBJECT}: ${RESPONSE}" >&2
  exit 1
}

echo "Published result to ${SUBJECT}"
echo "$RESPONSE"
