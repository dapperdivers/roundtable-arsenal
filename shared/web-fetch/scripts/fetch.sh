#!/usr/bin/env bash
# Fetch and extract text from a URL
# Usage: fetch.sh "url" [max_chars]
set -euo pipefail

URL="${1:?Usage: fetch.sh \"url\" [max_chars]}"
MAX_CHARS="${2:-10000}"

CONTENT=$(curl -sL -A "Mozilla/5.0 (compatible; Knight-Agent/1.0)" \
  --max-time 15 \
  "$URL" 2>/dev/null)

if [ -z "$CONTENT" ]; then
  echo "ERROR: Failed to fetch ${URL}"
  exit 1
fi

# Strip scripts, styles, HTML tags, normalize whitespace
echo "$CONTENT" \
  | sed 's/<script[^>]*>.*<\/script>//gI' \
  | sed 's/<style[^>]*>.*<\/style>//gI' \
  | sed 's/<[^>]*>/ /g' \
  | sed 's/&nbsp;/ /g; s/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g; s/&quot;/"/g' \
  | tr -s ' \n\t' ' ' \
  | head -c "$MAX_CHARS"

echo  # trailing newline
