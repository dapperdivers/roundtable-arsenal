#!/usr/bin/env bash
# nats-respond.sh — Respond to a NATS task with a properly formatted envelope.
# Usage: nats-respond.sh <task-id> <domain> '<payload-json>'
set -euo pipefail

BRIDGE_URL="${NATS_BRIDGE_URL:-http://localhost:8080}"
TASK_ID="${1:?Usage: nats-respond.sh <task-id> <domain> '<payload-json>'}"
DOMAIN="${2:?Usage: nats-respond.sh <task-id> <domain> '<payload-json>'}"
PAYLOAD="${3:?Usage: nats-respond.sh <task-id> <domain> '<payload-json>'}"

# Validate payload JSON
if ! echo "$PAYLOAD" | jq empty 2>/dev/null; then
  echo "ERROR: payload is not valid JSON" >&2
  exit 1
fi

# Get bridge info for fleet/agent IDs
INFO=$(curl -sf "${BRIDGE_URL}/info" 2>/dev/null) || {
  echo "ERROR: Cannot reach bridge at ${BRIDGE_URL}/info" >&2
  exit 1
}

FLEET_ID=$(echo "$INFO" | jq -r '.fleetId')
AGENT_ID=$(echo "$INFO" | jq -r '.agentId')
RESULT_PREFIX=$(echo "$INFO" | jq -r '.resultPrefix')

# Build subject
SUBJECT="${RESULT_PREFIX}.${DOMAIN}.${TASK_ID}"

# Build envelope
ENVELOPE=$(jq -n \
  --arg id "$TASK_ID" \
  --arg fleetId "$FLEET_ID" \
  --arg from "$AGENT_ID" \
  --arg to "tim" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson payload "$PAYLOAD" \
  '{
    id: $id,
    fleetId: $fleetId,
    type: "task.result",
    from: $from,
    to: $to,
    timestamp: $ts,
    payload: $payload
  }')

# Publish
PUBLISH_BODY=$(jq -n --arg subject "$SUBJECT" --argjson data "$ENVELOPE" \
  '{subject: $subject, data: $data}')

RESPONSE=$(curl -sf -X POST "${BRIDGE_URL}/publish" \
  -H "Content-Type: application/json" \
  -d "$PUBLISH_BODY" 2>&1) || {
  echo "ERROR: Failed to publish result to ${SUBJECT}: ${RESPONSE}" >&2
  exit 1
}

echo "Published result to ${SUBJECT}"
echo "$RESPONSE" | jq .
