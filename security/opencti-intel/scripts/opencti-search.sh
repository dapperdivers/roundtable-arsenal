#!/bin/sh
# opencti-search.sh — Search across all OpenCTI entities
# Usage: ./opencti-search.sh "search term" [limit]
set -e

OPENCTI_URL="${OPENCTI_URL:-http://opencti-server.security.svc:80}"
SEARCH="$1"
LIMIT="${2:-10}"

if [ -z "$OPENCTI_TOKEN" ]; then
  echo "ERROR: OPENCTI_TOKEN not set" >&2
  exit 1
fi

if [ -z "$SEARCH" ]; then
  echo "Usage: $0 \"search term\" [limit]" >&2
  exit 1
fi

ESCAPED_SEARCH=$(printf '%s' "$SEARCH" | sed 's/"/\\"/g')

curl -sS -X POST "${OPENCTI_URL}/graphql" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${OPENCTI_TOKEN}" \
  -d "{\"query\":\"{ stixCoreObjects(search: \\\"${ESCAPED_SEARCH}\\\", first: ${LIMIT}) { edges { node { ... on StixDomainObject { id entity_type standard_id created_at } ... on Vulnerability { name description } ... on Malware { name description } ... on IntrusionSet { name description } ... on ThreatActor { name description } ... on AttackPattern { name description x_mitre_id } ... on Indicator { name description pattern } ... on Campaign { name description } } } pageInfo { globalCount } } }\"}"
