#!/usr/bin/env bash
# vault-health.sh — Full vault health scan
# Usage: bash vault-health.sh /vault
set -euo pipefail

VAULT="${1:-/vault}"

if [ ! -d "$VAULT" ]; then
  echo "ERROR: Vault directory not found: $VAULT"
  exit 1
fi

echo "# Vault Health Report"
echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# Count total notes
total=$(find "$VAULT" -name "*.md" \
  -not -path "*/.obsidian/*" \
  -not -path "*/.trash/*" \
  -not -path "*/.stversions/*" \
  -not -path "*/Resources/Templates/*" | wc -l)
echo "## Summary"
echo "- Total notes: $total"

# Count by folder
echo ""
echo "## Notes by Folder"
for dir in Briefings Excalidraw Inbox Journal Personal Projects Research Resources Roundtable Work; do
  if [ -d "$VAULT/$dir" ]; then
    count=$(find "$VAULT/$dir" -name "*.md" | wc -l)
    echo "- $dir: $count"
  fi
done

# Frontmatter check
echo ""
echo "## Frontmatter Status"
has_fm=0
no_fm=0
empty_tags=0
no_tags=0

while IFS= read -r -d '' f; do
  if head -1 "$f" 2>/dev/null | grep -q "^---"; then
    has_fm=$((has_fm + 1))
    # Check for empty tags
    if grep -q "^tags: \[\]" "$f" 2>/dev/null || grep -q "^tags:$" "$f" 2>/dev/null; then
      empty_tags=$((empty_tags + 1))
    elif ! grep -q "^tags:" "$f" 2>/dev/null; then
      no_tags=$((no_tags + 1))
    fi
  else
    no_fm=$((no_fm + 1))
  fi
done < <(find "$VAULT" -name "*.md" \
  -not -path "*/.obsidian/*" \
  -not -path "*/.trash/*" \
  -not -path "*/.stversions/*" \
  -not -path "*/Resources/Templates/*" \
  -print0)

echo "- With frontmatter: $has_fm"
echo "- Missing frontmatter: $no_fm"
echo "- Empty/missing tags: $((empty_tags + no_tags))"
echo "- Empty tag arrays: $empty_tags"

# Wikilinks
echo ""
echo "## Wikilink Status"
has_links=0
while IFS= read -r -d '' f; do
  if grep -q '\[\[' "$f" 2>/dev/null; then
    has_links=$((has_links + 1))
  fi
done < <(find "$VAULT" -name "*.md" \
  -not -path "*/.obsidian/*" \
  -not -path "*/.trash/*" \
  -not -path "*/.stversions/*" \
  -print0)
echo "- Notes with wikilinks: $has_links / $total"
echo "- Notes without wikilinks: $((total - has_links))"

# Inbox
echo ""
echo "## Inbox Status"
inbox_count=$(find "$VAULT/Inbox" -name "*.md" 2>/dev/null | wc -l)
echo "- Unprocessed inbox items: $inbox_count"
if [ "$inbox_count" -gt 0 ]; then
  echo "- Files:"
  find "$VAULT/Inbox" -name "*.md" 2>/dev/null | while read -r f; do
    echo "  - $(basename "$f")"
  done
fi

# Briefing age
echo ""
echo "## Briefing Lifecycle"
thirty_days_ago=$(date -d "30 days ago" +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d 2>/dev/null || echo "")
if [ -n "$thirty_days_ago" ]; then
  old_briefings=0
  while IFS= read -r -d '' f; do
    fname=$(basename "$f")
    # Extract date from filename (YYYY-MM-DD pattern)
    fdate=$(echo "$fname" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
    if [ -n "$fdate" ] && [ "$fdate" \< "$thirty_days_ago" ]; then
      old_briefings=$((old_briefings + 1))
    fi
  done < <(find "$VAULT/Briefings" -name "*.md" -print0 2>/dev/null)
  echo "- Briefings older than 30 days: $old_briefings"
else
  echo "- (Could not calculate date threshold)"
fi
total_briefings=$(find "$VAULT/Briefings" -name "*.md" 2>/dev/null | wc -l)
echo "- Total briefings: $total_briefings"

# Stubs (very short notes, likely incomplete)
echo ""
echo "## Potential Stubs"
stub_count=0
while IFS= read -r -d '' f; do
  lines=$(wc -l < "$f")
  if [ "$lines" -lt 5 ]; then
    stub_count=$((stub_count + 1))
    echo "  - $(echo "$f" | sed "s|$VAULT/||") ($lines lines)"
  fi
done < <(find "$VAULT" -name "*.md" \
  -not -path "*/.obsidian/*" \
  -not -path "*/.trash/*" \
  -not -path "*/.stversions/*" \
  -not -path "*/Resources/Templates/*" \
  -print0)
echo "- Total stubs (<5 lines): $stub_count"

# Legacy junk tags
echo ""
echo "## Legacy/Junk Tags"
junk_tags=0
for pattern in "type/note" "area/projects" "area/personal" "area/work"; do
  count=$(grep -rl "$pattern" "$VAULT" --include="*.md" 2>/dev/null | grep -v '.obsidian\|.trash\|.stversions' | wc -l)
  if [ "$count" -gt 0 ]; then
    echo "- '$pattern': $count files"
    junk_tags=$((junk_tags + count))
  fi
done
echo "- Total files with junk tags: $junk_tags"

echo ""
echo "---"
echo "End of report"
