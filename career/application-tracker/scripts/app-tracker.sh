#!/usr/bin/env bash
# app-tracker.sh — JSON-based job application tracker
# Usage: app-tracker.sh <command> [options]
set -euo pipefail

DATA_FILE="${APP_TRACKER_DB:-/data/applications.json}"

# Ensure data file exists
if [[ ! -f "$DATA_FILE" ]]; then
    echo '[]' > "$DATA_FILE"
fi

usage() {
    cat <<EOF
Usage: app-tracker.sh <command> [options]

Commands:
  add       Add a new application
  update    Update application status
  list      List all applications (optionally filtered)
  view      View details of one application
  stats     Pipeline statistics
  stale     Show applications needing follow-up

Options for 'add':
  --company NAME    Company name (required)
  --role TITLE      Role title (required)
  --source SRC      Source: linkedin|referral|direct|recruiter
  --notes TEXT      Initial notes
  --salary RANGE    Salary range string
  --priority PRI    Priority: high|medium|low (default: medium)

Options for 'update':
  --id ID           Application ID (required)
  --status STATUS   New status: applied|screen|interview|final|offer|rejected|withdrawn|accepted
  --stage TEXT      Stage description (e.g. "round-2")
  --interviewer WHO Interviewer names
  --notes TEXT      Additional notes

Options for 'list':
  --status STATUS   Filter by status
  --active          Show only active (not rejected/withdrawn/accepted)

Options for 'stale':
  --days N          Days without update to consider stale (default: 7)
EOF
    exit 1
}

gen_id() {
    local company="$1"
    local prefix=$(echo "$company" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | cut -c1-15)
    echo "${prefix}-$(date +%Y%m%d)"
}

cmd_add() {
    local company="" role="" source="direct" notes="" salary="" priority="medium"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --company) company="$2"; shift 2 ;;
            --role) role="$2"; shift 2 ;;
            --source) source="$2"; shift 2 ;;
            --notes) notes="$2"; shift 2 ;;
            --salary) salary="$2"; shift 2 ;;
            --priority) priority="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    [[ -z "$company" || -z "$role" ]] && { echo "Error: --company and --role required"; exit 1; }

    local id=$(gen_id "$company")
    local now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local today=$(date +%Y-%m-%d)

    python3 -c "
import json, sys
with open('$DATA_FILE') as f:
    apps = json.load(f)
app = {
    'id': '$id',
    'company': '$company',
    'role': '$role',
    'status': 'applied',
    'applied_date': '$today',
    'last_updated': '$today',
    'stages': [{'stage': 'applied', 'date': '$today'}],
    'contacts': [],
    'notes': '''$notes''',
    'salary_range': '$salary',
    'source': '$source',
    'priority': '$priority'
}
apps.append(app)
with open('$DATA_FILE', 'w') as f:
    json.dump(apps, f, indent=2)
print(f'✅ Added: {app[\"company\"]} — {app[\"role\"]} (id: {app[\"id\"]})')
"
}

cmd_update() {
    local id="" status="" stage="" interviewer="" notes=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --id) id="$2"; shift 2 ;;
            --status) status="$2"; shift 2 ;;
            --stage) stage="$2"; shift 2 ;;
            --interviewer) interviewer="$2"; shift 2 ;;
            --notes) notes="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    [[ -z "$id" ]] && { echo "Error: --id required"; exit 1; }

    python3 -c "
import json
with open('$DATA_FILE') as f:
    apps = json.load(f)
found = False
for app in apps:
    if app['id'] == '$id':
        found = True
        today = '$(date +%Y-%m-%d)'
        app['last_updated'] = today
        if '$status': app['status'] = '$status'
        if '$stage':
            entry = {'stage': '$stage', 'date': today}
            if '$interviewer': entry['interviewer'] = '$interviewer'
            app['stages'].append(entry)
        if '$notes': app['notes'] += '\n$notes'
        print(f'✅ Updated: {app[\"company\"]} → {app[\"status\"]}')
        break
if not found:
    print(f'❌ No application with id: $id')
with open('$DATA_FILE', 'w') as f:
    json.dump(apps, f, indent=2)
"
}

cmd_list() {
    local filter_status="" active_only=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --status) filter_status="$2"; shift 2 ;;
            --active) active_only=true; shift ;;
            *) shift ;;
        esac
    done

    python3 -c "
import json
with open('$DATA_FILE') as f:
    apps = json.load(f)
inactive = {'rejected', 'withdrawn', 'accepted'}
for app in apps:
    if '$filter_status' and app['status'] != '$filter_status': continue
    if '$active_only' == 'true' and app['status'] in inactive: continue
    stages = len(app.get('stages', []))
    days = '?'
    try:
        from datetime import datetime
        d = datetime.strptime(app['applied_date'], '%Y-%m-%d')
        days = (datetime.now() - d).days
    except: pass
    icon = {'applied':'📝','screen':'📞','interview':'🎤','final':'🏆','offer':'💰','rejected':'❌','withdrawn':'🚫','accepted':'✅'}.get(app['status'], '❓')
    print(f'{icon} {app[\"company\"]:<25} {app[\"role\"]:<30} {app[\"status\"]:<12} Day {days}  ({stages} stages)')
if not apps:
    print('No applications tracked yet.')
"
}

cmd_view() {
    local id="$1"
    python3 -c "
import json
with open('$DATA_FILE') as f:
    apps = json.load(f)
for app in apps:
    if app['id'] == '$id':
        print(json.dumps(app, indent=2))
        break
else:
    print(f'❌ No application with id: $id')
"
}

cmd_stats() {
    python3 -c "
import json
from collections import Counter
with open('$DATA_FILE') as f:
    apps = json.load(f)
c = Counter(a['status'] for a in apps)
total = len(apps)
active = sum(1 for a in apps if a['status'] not in ('rejected','withdrawn','accepted'))
print(f'📊 Pipeline: {total} total, {active} active')
for status, count in sorted(c.items()):
    bar = '█' * count
    print(f'  {status:<12} {count:>3} {bar}')
# Response rate
callbacks = sum(1 for a in apps if len(a.get('stages',[])) > 1)
if total > 0:
    print(f'\n📈 Response rate: {callbacks}/{total} ({callbacks*100//total}%)')
"
}

cmd_stale() {
    local days=7
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --days) days="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    python3 -c "
import json
from datetime import datetime, timedelta
threshold = datetime.now() - timedelta(days=$days)
with open('$DATA_FILE') as f:
    apps = json.load(f)
stale = []
for app in apps:
    if app['status'] in ('rejected','withdrawn','accepted'): continue
    try:
        updated = datetime.strptime(app['last_updated'], '%Y-%m-%d')
        if updated < threshold:
            days_stale = (datetime.now() - updated).days
            stale.append((days_stale, app))
    except: pass
if stale:
    print(f'⚠️ {len(stale)} stale applications (no update in {$days}+ days):')
    for d, app in sorted(stale, reverse=True):
        print(f'  {d}d — {app[\"company\"]} ({app[\"status\"]})')
else:
    print('✅ No stale applications.')
"
}

# Main dispatch
[[ $# -lt 1 ]] && usage
cmd="$1"; shift
case "$cmd" in
    add)    cmd_add "$@" ;;
    update) cmd_update "$@" ;;
    list)   cmd_list "$@" ;;
    view)   cmd_view "${1:-}" ;;
    stats)  cmd_stats ;;
    stale)  cmd_stale "$@" ;;
    *)      usage ;;
esac
