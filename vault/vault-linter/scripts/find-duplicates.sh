#!/usr/bin/env bash
# find-duplicates.sh — Find notes with similar titles suggesting duplication
# Usage: bash find-duplicates.sh /vault
set -euo pipefail

VAULT="${1:-/vault}"

echo "# Duplicate Detection Report"
echo ""

echo "## Similar Titles"
echo "Notes with similar names that may cover the same topic:"
echo ""

# Collect all note paths and titles
tmpfile=$(mktemp)
find "$VAULT" -name "*.md" \
  -not -path "*/.obsidian/*" \
  -not -path "*/.trash/*" \
  -not -path "*/.stversions/*" \
  -not -path "*/Resources/Templates/*" | while read -r f; do
  basename "$f" .md | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/ /g' | tr -s ' '
  echo "|$f"
done | paste -d '' - - > "$tmpfile"

# Find titles sharing significant words (3+ char words)
echo "### Potential Duplicates by Keyword Overlap"
# Extract key terms from each file and group
declare -A term_files
while IFS='|' read -r normalized path; do
  for word in $normalized; do
    if [ ${#word} -ge 4 ]; then
      key="$word"
      if [ -n "${term_files[$key]:-}" ]; then
        term_files[$key]="${term_files[$key]}|$path"
      else
        term_files[$key]="$path"
      fi
    fi
  done
done < "$tmpfile"

# Report terms that appear in multiple files (potential duplicates)
reported=""
for key in "${!term_files[@]}"; do
  files="${term_files[$key]}"
  count=$(echo "$files" | tr '|' '\n' | wc -l)
  if [ "$count" -ge 2 ] && [ "$count" -le 5 ]; then
    # Only report interesting clusters, skip very common terms
    case "$key" in
      daily|note|report|2026|2025|security|briefing|home)
        continue
        ;;
    esac
    # Check if we already reported this cluster
    if echo "$reported" | grep -q "$key"; then
      continue
    fi
    reported="$reported $key"
    echo "**'$key'** ($count notes):"
    echo "$files" | tr '|' '\n' | while read -r p; do
      echo "  - $(echo "$p" | sed "s|$VAULT/||")"
    done
    echo ""
  fi
done

rm -f "$tmpfile"

echo ""
echo "## Cross-Folder Overlap"
echo "Notes in Roundtable/ that may duplicate content in other folders:"
echo ""
if [ -d "$VAULT/Roundtable" ]; then
  find "$VAULT/Roundtable" -name "*.md" -not -name "README.md" | while read -r rt_file; do
    rt_name=$(basename "$rt_file" .md)
    # Search for similar names outside Roundtable
    matches=$(find "$VAULT" -name "*.md" -not -path "*/Roundtable/*" \
      -not -path "*/.obsidian/*" -not -path "*/.trash/*" \
      -not -path "*/.stversions/*" | while read -r other; do
      other_name=$(basename "$other" .md)
      # Simple keyword overlap check
      for word in $(echo "$rt_name" | tr '-' ' ' | tr '[:upper:]' '[:lower:]'); do
        if [ ${#word} -ge 4 ] && echo "$other_name" | tr '-' ' ' | tr '[:upper:]' '[:lower:]' | grep -qw "$word"; then
          echo "$(echo "$other" | sed "s|$VAULT/||")"
          break
        fi
      done
    done)
    if [ -n "$matches" ]; then
      echo "**$(echo "$rt_file" | sed "s|$VAULT/||")** may overlap with:"
      echo "$matches" | while read -r m; do echo "  - $m"; done
      echo ""
    fi
  done
fi

echo "---"
echo "Review these manually — similar titles don't always mean duplicate content."
