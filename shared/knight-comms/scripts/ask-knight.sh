#!/usr/bin/env bash
# ask-knight.sh — Ask another Round Table knight for help via NATS.
# Usage: ask-knight.sh <domain> "<question>" [timeout_seconds]
#
# Publishes a task to the target domain, waits for the result, and
# prints the output to stdout.
#
# Example:
#   RESULT=$(bash ask-knight.sh research "What is the airspeed velocity of a swallow?" 60)
set -euo pipefail

NATS_URL="${NATS_URL:-nats://nats.database.svc:4222}"
FLEET_ID="${FLEET_ID:-fleet-a}"
AGENT_ID="${AGENT_ID:-unknown}"

DOMAIN="${1:?Usage: ask-knight.sh <domain> \"<question>\" [timeout_seconds]}"
QUESTION="${2:?Usage: ask-knight.sh <domain> \"<question>\" [timeout_seconds]}"
TIMEOUT="${3:-60}"

# Generate unique task ID
TASK_ID="xknight-${AGENT_ID}-${DOMAIN}-$(date +%s)-$$"
SUBJECT="${FLEET_ID}.tasks.${DOMAIN}.${TASK_ID}"
RESULT_SUBJECT="${FLEET_ID}.results.${TASK_ID}"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Escape question for JSON
ESCAPED=$(printf '%s' "$QUESTION" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' ')

# Build task envelope — include instruction not to chain
ENVELOPE="{
  \"task\": \"${ESCAPED} (Do not delegate to other knights. Answer directly with your own knowledge and tools.)\",
  \"metadata\": {
    \"taskId\": \"${TASK_ID}\",
    \"replyTo\": \"${RESULT_SUBJECT}\",
    \"from\": \"${AGENT_ID}\",
    \"type\": \"cross-knight\",
    \"timestamp\": \"${TIMESTAMP}\"
  }
}"

# Publish the task
nats -s "$NATS_URL" pub "$SUBJECT" "$ENVELOPE" >/dev/null 2>&1

# Poll for the result
ELAPSED=0
POLL_INTERVAL=3

while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  sleep "$POLL_INTERVAL"
  ELAPSED=$((ELAPSED + POLL_INTERVAL))

  # Try to get the result from the stream
  RAW=$(nats -s "$NATS_URL" stream get fleet_a_results --last-for="$RESULT_SUBJECT" 2>/dev/null || true)

  if echo "$RAW" | grep -q '"success"'; then
    # Extract the JSON payload (everything after the blank line)
    PAYLOAD=$(echo "$RAW" | sed -n '/^{/,$p' | head -1)

    if [ -n "$PAYLOAD" ]; then
      # Extract output field
      OUTPUT=$(echo "$PAYLOAD" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if d.get('success'):
        print(d.get('output', '(no output)'))
    else:
        print('ERROR: ' + d.get('output', 'unknown error'))
except:
    print('ERROR: Failed to parse result')
" 2>/dev/null)

      if [ -n "$OUTPUT" ]; then
        echo "$OUTPUT"
        exit 0
      fi
    fi
  fi
done

echo "ERROR: Timeout waiting for response from ${DOMAIN} knight after ${TIMEOUT}s"
exit 1
