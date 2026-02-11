#!/bin/sh
# opencti-threats.sh — Query threat actors, intrusion sets, malware, campaigns
# Usage: ./opencti-threats.sh [actors|intrusions|malware|campaigns] [limit]
set -e

OPENCTI_URL="${OPENCTI_URL:-http://opencti-server.security.svc:80}"
TYPE="${1:-actors}"
LIMIT="${2:-10}"

if [ -z "$OPENCTI_TOKEN" ]; then
  echo "ERROR: OPENCTI_TOKEN not set" >&2
  exit 1
fi

case "$TYPE" in
  actors)
    QUERY="{ threatActorsIndividual(first: ${LIMIT}, orderBy: created_at, orderMode: desc) { edges { node { name description threat_actor_types first_seen last_seen } } pageInfo { globalCount } } }"
    ;;
  intrusions)
    QUERY="{ intrusionSets(first: ${LIMIT}, orderBy: created_at, orderMode: desc) { edges { node { name description first_seen last_seen } } pageInfo { globalCount } } }"
    ;;
  malware)
    QUERY="{ malwares(first: ${LIMIT}, orderBy: created_at, orderMode: desc) { edges { node { name description malware_types is_family first_seen last_seen } } pageInfo { globalCount } } }"
    ;;
  campaigns)
    QUERY="{ campaigns(first: ${LIMIT}, orderBy: created_at, orderMode: desc) { edges { node { name description first_seen last_seen } } pageInfo { globalCount } } }"
    ;;
  *)
    echo "Usage: $0 [actors|intrusions|malware|campaigns] [limit]" >&2
    exit 1
    ;;
esac

ESCAPED=$(printf '%s' "$QUERY" | sed 's/"/\\"/g' | tr '\n' ' ')

curl -sS -X POST "${OPENCTI_URL}/graphql" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${OPENCTI_TOKEN}" \
  -d "{\"query\":\"${ESCAPED}\"}"
