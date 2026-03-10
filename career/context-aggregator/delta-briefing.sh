#!/usr/bin/env bash
# Delta Briefing — compares current career context with previous snapshot
# and outputs only what changed. Outputs JSON delta to stdout.
set -euo pipefail

CURRENT="/data/career-context.json"
PREVIOUS="/data/career-context-prev.json"

if [[ ! -f "$CURRENT" ]]; then
  echo '{"error": "No current context found. Run aggregate-context.sh first."}' >&2
  exit 1
fi

if [[ ! -f "$PREVIOUS" ]]; then
  echo '{"info": "No previous snapshot. Treating everything as new."}' >&2
  python3 -c "
import json
with open('$CURRENT') as f:
    ctx = json.load(f)
delta = {
    'generated_at': ctx.get('generated_at', ''),
    'previous_snapshot': None,
    'added': {
        'opportunities': ctx.get('opportunities', []),
        'skills': ctx.get('skills_inventory', []),
        'prep_materials': ctx.get('prep_materials', []),
        'career_goals': ctx.get('career_goals', []),
    },
    'removed': {'opportunities': [], 'skills': [], 'prep_materials': [], 'career_goals': []},
    'changed': {'opportunities': []},
}
print(json.dumps(delta, indent=2))
"
  exit 0
fi

python3 << 'PYEOF'
import json

with open("/data/career-context.json") as f:
    curr = json.load(f)
with open("/data/career-context-prev.json") as f:
    prev = json.load(f)

def list_diff(curr_list, prev_list):
    """For simple lists (strings), return added/removed."""
    cs, ps = set(curr_list), set(prev_list)
    return list(cs - ps), list(ps - cs)

def opp_key(o):
    return (o.get("company", ""), o.get("role", ""))

# Opportunities diff
curr_opps = {opp_key(o): o for o in curr.get("opportunities", [])}
prev_opps = {opp_key(o): o for o in prev.get("opportunities", [])}

added_opps = [curr_opps[k] for k in curr_opps if k not in prev_opps]
removed_opps = [prev_opps[k] for k in prev_opps if k not in curr_opps]

changed_opps = []
for k in curr_opps:
    if k in prev_opps and curr_opps[k] != prev_opps[k]:
        changes = {}
        for field in ("status", "next_steps"):
            old_val = prev_opps[k].get(field, "")
            new_val = curr_opps[k].get(field, "")
            if old_val != new_val:
                changes[field] = {"from": old_val, "to": new_val}
        if changes:
            changed_opps.append({
                "company": curr_opps[k].get("company", ""),
                "role": curr_opps[k].get("role", ""),
                "changes": changes,
            })

# Simple list diffs
skills_added, skills_removed = list_diff(
    curr.get("skills_inventory", []), prev.get("skills_inventory", []))
prep_added, prep_removed = list_diff(
    curr.get("prep_materials", []), prev.get("prep_materials", []))
goals_added, goals_removed = list_diff(
    curr.get("career_goals", []), prev.get("career_goals", []))

delta = {
    "generated_at": curr.get("generated_at", ""),
    "previous_snapshot": prev.get("generated_at", ""),
    "added": {
        "opportunities": added_opps,
        "skills": skills_added,
        "prep_materials": prep_added,
        "career_goals": goals_added,
    },
    "removed": {
        "opportunities": removed_opps,
        "skills": skills_removed,
        "prep_materials": prep_removed,
        "career_goals": goals_removed,
    },
    "changed": {
        "opportunities": changed_opps,
    },
}

# Check if anything actually changed
has_changes = any([
    added_opps, removed_opps, changed_opps,
    skills_added, skills_removed,
    prep_added, prep_removed,
    goals_added, goals_removed,
])

if not has_changes:
    delta["summary"] = "No changes detected since last snapshot."
else:
    parts = []
    if added_opps: parts.append(f"{len(added_opps)} new opportunity(ies)")
    if removed_opps: parts.append(f"{len(removed_opps)} removed opportunity(ies)")
    if changed_opps: parts.append(f"{len(changed_opps)} opportunity status change(s)")
    if skills_added: parts.append(f"{len(skills_added)} new skill(s)")
    if skills_removed: parts.append(f"{len(skills_removed)} removed skill(s)")
    if prep_added: parts.append(f"{len(prep_added)} new prep material(s)")
    if goals_added: parts.append(f"{len(goals_added)} new goal(s)")
    delta["summary"] = "; ".join(parts)

print(json.dumps(delta, indent=2))
PYEOF
