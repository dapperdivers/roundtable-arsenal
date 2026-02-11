#!/bin/sh
# opencti-query.sh — Run a raw GraphQL query against OpenCTI
# Usage: ./opencti-query.sh '<graphql query>'
set -e

OPENCTI_URL="${OPENCTI_URL:-http://opencti-server.security.svc:80}"
QUERY="$1"

if [ -z "$OPENCTI_TOKEN" ]; then
  echo "ERROR: OPENCTI_TOKEN not set" >&2
  exit 1
fi

if [ -z "$QUERY" ]; then
  echo "Usage: $0 '<graphql query>'" >&2
  exit 1
fi

# Escape the query for JSON
ESCAPED=$(printf '%s' "$QUERY" | sed 's/"/\\"/g' | tr '\n' ' ')

curl -sS -X POST "${OPENCTI_URL}/graphql" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${OPENCTI_TOKEN}" \
  -d "{\"query\":\"${ESCAPED}\"}"
