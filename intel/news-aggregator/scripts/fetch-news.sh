#!/usr/bin/env bash
# fetch-news.sh — Fetch and summarize news from RSS feeds using curl
# No Python dependencies required. Uses curl + grep/sed for XML parsing.
# Usage: fetch-news.sh [--hours 24] [--category tech|security|gaming|science|all] [--limit 10]
set -euo pipefail

HOURS=24
CATEGORY="all"
LIMIT=15

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hours) HOURS="$2"; shift 2 ;;
    --category) CATEGORY="$2"; shift 2 ;;
    --limit) LIMIT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Feed lists by category
TECH_FEEDS=(
  "https://news.ycombinator.com/rss"
  "https://arstechnica.com/feed/"
  "https://www.theverge.com/rss/index.xml"
)
SECURITY_FEEDS=(
  "https://feeds.feedburner.com/TheHackersNews"
  "https://www.bleepingcomputer.com/feed/"
  "https://krebsonsecurity.com/feed/"
)
GAMING_FEEDS=(
  "https://www.eurogamer.net/feed"
  "https://www.polygon.com/rss/index.xml"
)
SCIENCE_FEEDS=(
  "https://rss.sciencedaily.com/all.xml"
)

# Build feed list
declare -a FEEDS
case "$CATEGORY" in
  tech)     FEEDS=("${TECH_FEEDS[@]}") ;;
  security) FEEDS=("${SECURITY_FEEDS[@]}") ;;
  gaming)   FEEDS=("${GAMING_FEEDS[@]}") ;;
  science)  FEEDS=("${SCIENCE_FEEDS[@]}") ;;
  all)      FEEDS=("${TECH_FEEDS[@]}" "${SECURITY_FEEDS[@]}" "${GAMING_FEEDS[@]}" "${SCIENCE_FEEDS[@]}") ;;
  *)        echo "Unknown category: $CATEGORY" >&2; exit 1 ;;
esac

COUNT=0

for FEED_URL in "${FEEDS[@]}"; do
  [[ $COUNT -ge $LIMIT ]] && break

  # Fetch with timeout
  XML=$(curl -sfL --connect-timeout 5 --max-time 10 "$FEED_URL" 2>/dev/null) || continue

  # Extract items (works for both RSS <item> and Atom <entry>)
  # Simple approach: extract title + link pairs
  echo "$XML" | grep -oP '<item>.*?</item>|<entry>.*?</entry>' 2>/dev/null | head -5 | while read -r item; do
    [[ $COUNT -ge $LIMIT ]] && break

    title=$(echo "$item" | grep -oP '<title[^>]*>\K[^<]+' | head -1 | sed 's/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g; s/&#39;/'"'"'/g; s/&quot;/"/g')
    link=$(echo "$item" | grep -oP '<link[^>]*href="?\K[^"< ]+|<link>\K[^<]+' | head -1)

    [[ -z "$title" ]] && continue

    echo "---"
    echo "Title: $title"
    echo "URL: ${link:-unknown}"
    echo "Source: $FEED_URL"
    COUNT=$((COUNT + 1))
  done
done

# If XML parsing got nothing, fall back to SearXNG
if [[ $COUNT -eq 0 ]]; then
  echo "# RSS parsing returned no results, falling back to SearXNG search"
  SEARXNG="http://searxng.selfhosted.svc.cluster.local:8080"
  for q in "technology news today" "cybersecurity news today" "gaming news today"; do
    ENCODED=$(printf '%s' "$q" | sed 's/ /+/g')
    curl -sf "${SEARXNG}/search?q=${ENCODED}&format=json" 2>/dev/null \
      | grep -oP '"title"\s*:\s*"[^"]*"|"url"\s*:\s*"[^"]*"' \
      | paste - - \
      | head -3 \
      | while IFS=$'\t' read -r t u; do
        title=$(echo "$t" | sed 's/.*"title"\s*:\s*"//;s/"$//')
        url=$(echo "$u" | sed 's/.*"url"\s*:\s*"//;s/"$//')
        echo "---"
        echo "Title: $title"
        echo "URL: $url"
        echo "Source: SearXNG ($q)"
      done
  done
fi
