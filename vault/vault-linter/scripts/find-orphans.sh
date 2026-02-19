#!/usr/bin/env bash
# find-orphans.sh — Find notes with no incoming wikilinks from other notes
# Usage: bash find-orphans.sh /vault
set -euo pipefail

VAULT="${1:-/vault}"

echo "# Orphan Notes Report"
echo "Notes that are never linked to from any other note."
echo ""

# Build list of all note names (without .md)
declare -A linked_notes

# Find all wikilinks across the vault
while IFS= read -r -d '' f; do
  # Extract wikilink targets: [[Target]] or [[Target|Display]]
  grep -oP '\[\[([^\]|]+)' "$f" 2>/dev/null | sed 's/\[\[//' | while read -r link; do
    # Normalize: take just the filename part if it includes a path
    basename_link=$(basename "$link")
    linked_notes["$basename_link"]=1
  done
done < <(find "$VAULT" -name "*.md" \
  -not -path "*/.obsidian/*" \
  -not -path "*/.trash/*" \
  -not -path "*/.stversions/*" \
  -print0)

# Now check which notes are never linked to
orphan_count=0
echo "## Orphan Notes (no incoming links)"
while IFS= read -r -d '' f; do
  fname=$(basename "$f" .md)
  rel=$(echo "$f" | sed "s|$VAULT/||")

  # Skip templates, Home.md, and dotfiles
  case "$rel" in
    Resources/Templates/*|Home.md|.*)
      continue
      ;;
  esac

  # Check if this note name appears as a wikilink anywhere
  if ! grep -rq "\[\[$fname" "$VAULT" --include="*.md" 2>/dev/null | grep -v "$f" >/dev/null 2>&1; then
    # Double check with path-based links
    if ! grep -rq "\[\[.*$fname" "$VAULT" --include="*.md" 2>/dev/null; then
      echo "- $rel"
      orphan_count=$((orphan_count + 1))
    fi
  fi
done < <(find "$VAULT" -name "*.md" \
  -not -path "*/.obsidian/*" \
  -not -path "*/.trash/*" \
  -not -path "*/.stversions/*" \
  -not -path "*/Resources/Templates/*" \
  -print0)

echo ""
echo "Total orphans: $orphan_count"
