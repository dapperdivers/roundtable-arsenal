#!/usr/bin/env bash
# shodan-search.sh — Search Shodan for hosts matching a query.
# Usage: shodan-search.sh "query" [limit]
# Requires: SHODAN_API_KEY env var
set -euo pipefail

QUERY="${1:?Usage: shodan-search.sh \"query\" [limit]}"
LIMIT="${2:-5}"
API_KEY="${SHODAN_API_KEY:?SHODAN_API_KEY not set}"

ENCODED_QUERY=$(printf '%s' "$QUERY" | sed 's/ /%20/g; s/"/%22/g; s/:/%3A/g')

RESPONSE=$(curl -s --max-time 30 \
  "https://api.shodan.io/shodan/host/search?key=${API_KEY}&query=${ENCODED_QUERY}&page=1")

# Check for errors
ERROR=$(echo "$RESPONSE" | grep -o '"error":[^,}]*' | head -1 || true)
if [ -n "$ERROR" ]; then
  echo "Shodan API error: $ERROR" >&2
  echo "$RESPONSE"
  exit 1
fi

# Extract total count
TOTAL=$(echo "$RESPONSE" | grep -o '"total":[0-9]*' | head -1 | cut -d: -f2)
echo "=== Shodan Search Results ==="
echo "Query: $QUERY"
echo "Total matches: ${TOTAL:-unknown}"
echo "Showing: up to $LIMIT results"
echo "==="
echo ""

# Output the raw JSON for the agent to parse
echo "$RESPONSE"
