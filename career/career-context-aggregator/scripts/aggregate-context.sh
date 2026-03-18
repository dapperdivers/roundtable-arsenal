#!/usr/bin/env bash
set -euo pipefail

# Career Context Aggregator
# Scans vault paths and builds consolidated career dashboard

VAULT_PATH="${VAULT_PATH:-/vault}"
CAREER_PATHS="${CAREER_PATHS:-Personal/Career,Work,Research,Projects}"
MAX_AGE_DAYS="${MAX_AGE_DAYS:-90}"
FORMAT="${FORMAT:-markdown}"
ACTIVE_ONLY=false

usage() {
  echo "Usage: aggregate-context.sh [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --format markdown|json    Output format (default: markdown)"
  echo "  --active-only             Only show active opportunities"
  echo "  --vault PATH              Vault root path (default: /vault)"
  echo "  --max-age DAYS            Max note age in days (default: 90)"
  echo "  -h, --help                Show this help"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --format) FORMAT="$2"; shift 2 ;;
    --active-only) ACTIVE_ONLY=true; shift ;;
    --vault) VAULT_PATH="$2"; shift 2 ;;
    --max-age) MAX_AGE_DAYS="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ ! -d "$VAULT_PATH" ]]; then
  echo "Error: Vault path not found: $VAULT_PATH" >&2
  exit 1
fi

# Find recent career-related notes
NOTES=()
IFS=',' read -ra PATHS <<< "$CAREER_PATHS"
for p in "${PATHS[@]}"; do
  full_path="$VAULT_PATH/$p"
  if [[ -d "$full_path" ]]; then
    while IFS= read -r -d '' file; do
      NOTES+=("$file")
    done < <(find "$full_path" -name "*.md" -mtime "-${MAX_AGE_DAYS}" -print0 2>/dev/null)
  fi
done

if [[ ${#NOTES[@]} -eq 0 ]]; then
  echo "No career notes found in configured paths" >&2
  exit 2
fi

echo "# Career Context Dashboard"
echo ""
echo "**Generated:** $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "**Notes scanned:** ${#NOTES[@]}"
echo ""

# Extract and display active opportunities
echo "## Active Opportunities"
echo ""
for note in "${NOTES[@]}"; do
  # Check if note contains status indicators
  if grep -qi "status.*active\|status.*interviewing\|status.*offer\|status.*final" "$note" 2>/dev/null; then
    basename_note=$(basename "$note" .md)
    echo "### $basename_note"
    # Extract frontmatter status fields
    sed -n '/^---$/,/^---$/p' "$note" 2>/dev/null | grep -i "status\|company\|role\|next\|timeline\|contact" || true
    echo ""
  fi
done

if [[ "$ACTIVE_ONLY" == "true" ]]; then
  exit 0
fi

# Recent career notes by modification date
echo "## Recent Career Notes"
echo ""
for note in "${NOTES[@]}"; do
  mod_date=$(date -r "$note" '+%Y-%m-%d' 2>/dev/null || stat -c '%y' "$note" 2>/dev/null | cut -d' ' -f1)
  rel_path="${note#$VAULT_PATH/}"
  echo "- **$mod_date** — $rel_path"
done | sort -r | head -20

echo ""
echo "---"
echo "*Aggregated from ${#NOTES[@]} notes across ${#PATHS[@]} vault paths*"
