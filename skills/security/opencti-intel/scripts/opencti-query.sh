#!/bin/bash
# OpenCTI GraphQL query runner
# Usage: ./opencti-query.sh '<graphql_query>'

QUERY="$1"
if [ -z "$QUERY" ]; then
  echo "Usage: $0 '<graphql_query>'"
  exit 1
fi

TOKEN="${OPENCTI_TOKEN:-}"
if [ -z "$TOKEN" ]; then
  echo "Error: OPENCTI_TOKEN not set"
  exit 1
fi

API="http://opencti-server.security.svc.cluster.local/graphql"

curl -s --max-time 30 -X POST "$API" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"query\":\"$QUERY\"}"
