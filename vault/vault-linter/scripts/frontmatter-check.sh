#!/usr/bin/env bash
# frontmatter-check.sh — List files missing or with incomplete frontmatter
# Usage: bash frontmatter-check.sh /vault [folder]
set -euo pipefail

VAULT="${1:-/vault}"
FOLDER="${2:-}"
SEARCH_PATH="$VAULT"
[ -n "$FOLDER" ] && SEARCH_PATH="$VAULT/$FOLDER"

echo "# Frontmatter Check: $SEARCH_PATH"
echo ""

echo "## Missing Frontmatter"
count=0
while IFS= read -r -d '' f; do
  if ! head -1 "$f" 2>/dev/null | grep -q "^---"; then
    echo "- $(echo "$f" | sed "s|$VAULT/||")"
    count=$((count + 1))
  fi
done < <(find "$SEARCH_PATH" -name "*.md" \
  -not -path "*/.obsidian/*" \
  -not -path "*/.trash/*" \
  -not -path "*/.stversions/*" \
  -not -path "*/Resources/Templates/*" \
  -print0)
echo "Total: $count"

echo ""
echo "## Missing 'created' Field"
count=0
while IFS= read -r -d '' f; do
  if head -1 "$f" 2>/dev/null | grep -q "^---"; then
    # Extract frontmatter block
    if ! sed -n '2,/^---$/p' "$f" 2>/dev/null | grep -q "^created:"; then
      echo "- $(echo "$f" | sed "s|$VAULT/||")"
      count=$((count + 1))
    fi
  fi
done < <(find "$SEARCH_PATH" -name "*.md" \
  -not -path "*/.obsidian/*" \
  -not -path "*/.trash/*" \
  -not -path "*/.stversions/*" \
  -not -path "*/Resources/Templates/*" \
  -print0)
echo "Total: $count"

echo ""
echo "## Missing 'type' Field"
count=0
while IFS= read -r -d '' f; do
  if head -1 "$f" 2>/dev/null | grep -q "^---"; then
    if ! sed -n '2,/^---$/p' "$f" 2>/dev/null | grep -q "^type:"; then
      echo "- $(echo "$f" | sed "s|$VAULT/||")"
      count=$((count + 1))
    fi
  fi
done < <(find "$SEARCH_PATH" -name "*.md" \
  -not -path "*/.obsidian/*" \
  -not -path "*/.trash/*" \
  -not -path "*/.stversions/*" \
  -not -path "*/Resources/Templates/*" \
  -print0)
echo "Total: $count"

echo ""
echo "## Empty or Missing Tags"
count=0
while IFS= read -r -d '' f; do
  if head -1 "$f" 2>/dev/null | grep -q "^---"; then
    fm=$(sed -n '2,/^---$/p' "$f" 2>/dev/null)
    if echo "$fm" | grep -q "^tags: \[\]"; then
      echo "- $(echo "$f" | sed "s|$VAULT/||") (empty array)"
      count=$((count + 1))
    elif ! echo "$fm" | grep -q "^tags:"; then
      echo "- $(echo "$f" | sed "s|$VAULT/||") (missing)"
      count=$((count + 1))
    fi
  fi
done < <(find "$SEARCH_PATH" -name "*.md" \
  -not -path "*/.obsidian/*" \
  -not -path "*/.trash/*" \
  -not -path "*/.stversions/*" \
  -not -path "*/Resources/Templates/*" \
  -print0)
echo "Total: $count"
