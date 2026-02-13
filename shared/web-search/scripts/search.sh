#!/usr/bin/env bash
# Web search via SearXNG — no API key needed
# Usage: search.sh "query" [count]
set -euo pipefail

QUERY="${1:?Usage: search.sh \"query\" [count]}"
COUNT="${2:-5}"
SEARXNG_URL="${SEARXNG_URL:-http://searxng.selfhosted.svc.cluster.local:8080}"

ENCODED_QUERY=$(printf '%s' "$QUERY" | sed 's/ /+/g; s/[^a-zA-Z0-9+._-]/%&/g')

RESPONSE=$(curl -sf "${SEARXNG_URL}/search?q=${ENCODED_QUERY}&format=json" 2>/dev/null)

if [ -z "$RESPONSE" ]; then
  echo "ERROR: SearXNG unreachable at ${SEARXNG_URL}"
  exit 1
fi

# Parse results without jq — extract title, url, content triplets
echo "$RESPONSE" | grep -oP '"title"\s*:\s*"[^"]*"|"url"\s*:\s*"[^"]*"|"content"\s*:\s*"[^"]*"' \
  | paste - - - \
  | head -n "$COUNT" \
  | while IFS=$'\t' read -r title url content; do
    t=$(echo "$title" | sed 's/.*"title"\s*:\s*"//;s/"$//')
    u=$(echo "$url" | sed 's/.*"url"\s*:\s*"//;s/"$//')
    c=$(echo "$content" | sed 's/.*"content"\s*:\s*"//;s/"$//')
    echo "---"
    echo "Title: $t"
    echo "URL: $u"
    echo "Snippet: $c"
  done
