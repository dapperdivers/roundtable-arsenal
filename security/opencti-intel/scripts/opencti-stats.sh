#!/bin/sh
# opencti-stats.sh — Get OpenCTI platform statistics
# Usage: ./opencti-stats.sh
set -e

OPENCTI_URL="${OPENCTI_URL:-http://opencti-server.security.svc:80}"

if [ -z "$OPENCTI_TOKEN" ]; then
  echo "ERROR: OPENCTI_TOKEN not set" >&2
  exit 1
fi

curl -sS -X POST "${OPENCTI_URL}/graphql" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${OPENCTI_TOKEN}" \
  -d '{"query":"{ about { version } vulnerabilities(first: 0) { pageInfo { globalCount } } malwares(first: 0) { pageInfo { globalCount } } intrusionSets(first: 0) { pageInfo { globalCount } } attackPatterns(first: 0) { pageInfo { globalCount } } indicators(first: 0) { pageInfo { globalCount } } campaigns(first: 0) { pageInfo { globalCount } } stixCoreRelationships(first: 0) { pageInfo { globalCount } } connectors { id name connector_type active updated_at } }"}'
