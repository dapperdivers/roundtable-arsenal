#!/usr/bin/env bash
# Career Context Aggregator — scans vault directories and produces
# a consolidated JSON summary at /data/career-context.json
# No PII: all example values use placeholders.
set -euo pipefail

VAULT_CAREER="/vault/Roundtable/Career-Strategy"
VAULT_WORK="/vault/Work"
VAULT_PERSONAL="/vault/Personal"
OUTPUT="/data/career-context.json"
PREV_OUTPUT="/data/career-context-prev.json"

mkdir -p /data

# Archive previous snapshot for delta-briefing
if [[ -f "$OUTPUT" ]]; then
  cp "$OUTPUT" "$PREV_OUTPUT"
fi

# ── helpers ──────────────────────────────────────────────────────
json_escape() { python3 -c "import json,sys; print(json.dumps(sys.stdin.read().strip()))"; }

collect_files() {
  local dir="$1" pattern="${2:-*.md}"
  if [[ -d "$dir" ]]; then
    find "$dir" -maxdepth 3 -name "$pattern" -type f 2>/dev/null || true
  fi
}

# ── opportunities ────────────────────────────────────────────────
# Looks for markdown files with YAML-ish front-matter keys:
#   company, role, status, next_steps
parse_opportunities() {
  local opps="[]"
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    local company role status next_steps
    company=$(grep -m1 -iE '^company:' "$file" 2>/dev/null | sed 's/^[^:]*:\s*//' || echo "")
    role=$(grep -m1 -iE '^role:' "$file" 2>/dev/null | sed 's/^[^:]*:\s*//' || echo "")
    status=$(grep -m1 -iE '^status:' "$file" 2>/dev/null | sed 's/^[^:]*:\s*//' || echo "")
    next_steps=$(grep -m1 -iE '^next.steps:' "$file" 2>/dev/null | sed 's/^[^:]*:\s*//' || echo "")
    if [[ -n "$company" || -n "$role" ]]; then
      opps=$(echo "$opps" | python3 -c "
import json, sys
arr = json.load(sys.stdin)
arr.append({
    'company': '''$company'''.strip(),
    'role': '''$role'''.strip(),
    'status': '''$status'''.strip() or 'unknown',
    'next_steps': '''$next_steps'''.strip() or 'none',
    'source_file': '''$file'''
})
print(json.dumps(arr))
")
    fi
  done < <(collect_files "$VAULT_CAREER" "*.md"; collect_files "$VAULT_WORK" "*.md")
  echo "$opps"
}

# ── skills inventory ─────────────────────────────────────────────
# Looks for files named *skill* or *inventory* and extracts list items
parse_skills() {
  local skills="[]"
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    while IFS= read -r line; do
      skill=$(echo "$line" | sed 's/^[-*]\s*//' | xargs)
      [[ -z "$skill" ]] && continue
      skills=$(echo "$skills" | python3 -c "
import json, sys
arr = json.load(sys.stdin)
s = '''$skill'''.strip()
if s and s not in arr:
    arr.append(s)
print(json.dumps(arr))
")
    done < <(grep -E '^\s*[-*]' "$file" 2>/dev/null || true)
  done < <(collect_files "$VAULT_CAREER" "*skill*"; collect_files "$VAULT_CAREER" "*inventory*"; collect_files "$VAULT_WORK" "*skill*")
  echo "$skills"
}

# ── prep materials ───────────────────────────────────────────────
collect_prep_paths() {
  local paths="[]"
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    paths=$(echo "$paths" | python3 -c "
import json, sys
arr = json.load(sys.stdin)
arr.append('''$file''')
print(json.dumps(arr))
")
  done < <(collect_files "$VAULT_CAREER" "*prep*"; collect_files "$VAULT_CAREER" "*interview*"; collect_files "$VAULT_WORK" "*interview*")
  echo "$paths"
}

# ── career goals ─────────────────────────────────────────────────
parse_goals() {
  local goals="[]"
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    while IFS= read -r line; do
      goal=$(echo "$line" | sed 's/^[-*]\s*//' | xargs)
      [[ -z "$goal" ]] && continue
      goals=$(echo "$goals" | python3 -c "
import json, sys
arr = json.load(sys.stdin)
g = '''$goal'''.strip()
if g and g not in arr:
    arr.append(g)
print(json.dumps(arr))
")
    done < <(grep -E '^\s*[-*]' "$file" 2>/dev/null || true)
  done < <(collect_files "$VAULT_CAREER" "*goal*"; collect_files "$VAULT_PERSONAL" "*goal*"; collect_files "$VAULT_PERSONAL" "*career*")
  echo "$goals"
}

# ── assemble ─────────────────────────────────────────────────────
echo "🏰 Lancelot — aggregating career context..."

OPPORTUNITIES=$(parse_opportunities)
SKILLS=$(parse_skills)
PREP_PATHS=$(collect_prep_paths)
GOALS=$(parse_goals)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

python3 -c "
import json
ctx = {
    'generated_at': '$TIMESTAMP',
    'opportunities': json.loads('''$(echo "$OPPORTUNITIES")'''),
    'skills_inventory': json.loads('''$(echo "$SKILLS")'''),
    'prep_materials': json.loads('''$(echo "$PREP_PATHS")'''),
    'career_goals': json.loads('''$(echo "$GOALS")'''),
}
with open('$OUTPUT', 'w') as f:
    json.dump(ctx, f, indent=2)
print(json.dumps(ctx, indent=2))
"

echo ""
echo "✅ Career context written to $OUTPUT"
