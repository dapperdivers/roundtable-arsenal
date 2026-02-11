#!/bin/sh
# opencti-vulns.sh — Query vulnerabilities from OpenCTI
# Usage: ./opencti-vulns.sh [limit] [search]
set -e

OPENCTI_URL="${OPENCTI_URL:-http://opencti-server.security.svc:80}"
LIMIT="${1:-10}"
SEARCH="$2"

if [ -z "$OPENCTI_TOKEN" ]; then
  echo "ERROR: OPENCTI_TOKEN not set" >&2
  exit 1
fi

if [ -n "$SEARCH" ]; then
  ESCAPED_SEARCH=$(printf '%s' "$SEARCH" | sed 's/"/\\"/g')
  SEARCH_ARG=", search: \\\"${ESCAPED_SEARCH}\\\""
else
  SEARCH_ARG=""
fi

curl -sS -X POST "${OPENCTI_URL}/graphql" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${OPENCTI_TOKEN}" \
  -d "{\"query\":\"{ vulnerabilities(first: ${LIMIT}, orderBy: created_at, orderMode: desc${SEARCH_ARG}) { edges { node { name description created_at x_opencti_cvss_base_score x_opencti_cvss_base_severity x_opencti_cisa_kev } } pageInfo { globalCount } } }\"}"
