#!/usr/bin/env bash
set -euo pipefail

# fetch-rss.sh — Fetch RSS feeds from OPML, extract last 24h entries, output JSON
# Usage: ./fetch-rss.sh [opml-file]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPML_FILE="${1:-$SCRIPT_DIR/rss-feeds.opml}"
OUTFILE="${OUTFILE:-/data/rss-latest.json}"
MAX_AGE_HOURS="${MAX_AGE_HOURS:-24}"

if [ ! -f "$OPML_FILE" ]; then
  echo "Error: OPML file not found: $OPML_FILE" >&2
  exit 1
fi

# Ensure output directory exists
mkdir -p "$(dirname "$OUTFILE")"

# Extract feed URLs and titles from OPML
extract_feeds() {
  python3 - "$OPML_FILE" << 'PYEOF'
import xml.etree.ElementTree as ET, sys
tree = ET.parse(sys.argv[1])
for outline in tree.iter("outline"):
    url = outline.get("xmlUrl")
    title = outline.get("text", outline.get("title", "Unknown"))
    if url:
        print(f"{title}\t{url}")
PYEOF
}

# Fetch a single feed and extract entries as JSON lines
fetch_feed() {
  local feed_name="$1"
  local feed_url="$2"

  local xml
  xml=$(curl -sL --max-time 30 --retry 1 "$feed_url" 2>/dev/null) || return 0

  echo "$xml" | python3 - "$feed_name" "$MAX_AGE_HOURS" << 'PYEOF'
import sys, json, re
from datetime import datetime, timedelta, timezone
from xml.etree.ElementTree import fromstring

feed_name = sys.argv[1]
max_age_hours = int(sys.argv[2])
cutoff = datetime.now(timezone.utc) - timedelta(hours=max_age_hours)
xml_data = sys.stdin.read()

if not xml_data.strip():
    sys.exit(0)

try:
    root = fromstring(xml_data)
except Exception:
    sys.exit(0)

ns = {"atom": "http://www.w3.org/2005/Atom", "dc": "http://purl.org/dc/elements/1.1/"}

def parse_date(s):
    if not s:
        return None
    s = s.strip()
    for fmt in [
        "%a, %d %b %Y %H:%M:%S %z",
        "%a, %d %b %Y %H:%M:%S %Z",
        "%Y-%m-%dT%H:%M:%S%z",
        "%Y-%m-%dT%H:%M:%SZ",
        "%Y-%m-%d %H:%M:%S",
    ]:
        try:
            dt = datetime.strptime(s, fmt)
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            return dt
        except ValueError:
            continue
    return None

def clean_html(s):
    if not s:
        return ""
    return re.sub(r"<[^>]+>", "", s).strip()[:500]

items = []

# RSS 2.0
for item in root.findall(".//item"):
    pub = item.findtext("pubDate") or item.findtext("dc:date", namespaces=ns)
    dt = parse_date(pub)
    if dt and dt < cutoff:
        continue
    items.append({
        "title": (item.findtext("title") or "").strip(),
        "link": (item.findtext("link") or "").strip(),
        "published": dt.isoformat() if dt else pub or "",
        "source": feed_name,
        "summary": clean_html(item.findtext("description") or ""),
    })

# Atom
for entry in root.findall("atom:entry", ns):
    pub = entry.findtext("atom:published", namespaces=ns) or entry.findtext("atom:updated", namespaces=ns)
    dt = parse_date(pub)
    if dt and dt < cutoff:
        continue
    link_el = entry.find("atom:link[@rel='alternate']", ns) or entry.find("atom:link", ns)
    link = link_el.get("href", "") if link_el is not None else ""
    items.append({
        "title": (entry.findtext("atom:title", namespaces=ns) or "").strip(),
        "link": link.strip(),
        "published": dt.isoformat() if dt else pub or "",
        "source": feed_name,
        "summary": clean_html(entry.findtext("atom:summary", namespaces=ns) or entry.findtext("atom:content", namespaces=ns) or ""),
    })

for item in items:
    print(json.dumps(item))
PYEOF
}

echo "Fetching RSS feeds from: $OPML_FILE" >&2

# Collect all entries
ALL_ITEMS=""
while IFS=$'\t' read -r name url; do
  echo "  Fetching: $name" >&2
  result=$(fetch_feed "$name" "$url")
  if [ -n "$result" ]; then
    ALL_ITEMS="${ALL_ITEMS}${result}"$'\n'
  fi
done < <(extract_feeds)

# Combine into JSON array, sort by date descending
echo "$ALL_ITEMS" | python3 -c "
import sys, json
items = []
for line in sys.stdin:
    line = line.strip()
    if line:
        try:
            items.append(json.loads(line))
        except json.JSONDecodeError:
            pass
items.sort(key=lambda x: x.get('published', ''), reverse=True)
print(json.dumps(items, indent=2))
" > "$OUTFILE"

COUNT=$(python3 -c "import json; print(len(json.load(open('$OUTFILE'))))")
echo "Done: $COUNT articles saved to $OUTFILE" >&2
