---
name: application-tracker
description: Track job applications, interview stages, contacts, and follow-ups as a JSON database. Use for managing active job searches, generating status reports, and tracking interview pipelines.
allowed-tools: Bash(jq:*,date:*) Read Write
metadata:
  author: roundtable
  version: "1.0"
  tier: career
  compatibility: Requires jq. Data stored in /data/applications.json.
---

# Application Tracker

JSON-based job application tracking database for managing active job searches.

## Data Storage

Applications stored in `/data/applications.json` as a JSON array.

### Application Schema
```json
{
  "id": "bw-2026-01",
  "company": "Bridgewater Associates",
  "role": "Technical Risk Analysis",
  "status": "final-round",
  "applied_date": "2026-01-15",
  "last_updated": "2026-03-17",
  "stages": [
    {"stage": "applied", "date": "2026-01-15"},
    {"stage": "phone-screen", "date": "2026-01-28", "interviewer": "Anthony (CISO)"},
    {"stage": "round-2", "date": "2026-02-10", "interviewer": "Tommy + Samuel"},
    {"stage": "round-3", "date": "2026-02-26", "interviewer": "Patrick + Michael"},
    {"stage": "round-4", "date": "2026-03-04", "interviewer": "Gloria Harris"}
  ],
  "contacts": [
    {"name": "Spencer", "role": "recruiter", "email": ""},
    {"name": "Alana", "role": "scheduling", "email": ""}
  ],
  "notes": "Final 2 candidates. Purple team / AI offensive automation.",
  "salary_range": "$200K-300K base + bonus + co-invest",
  "source": "direct-application",
  "priority": "high"
}
```

## Scripts

### Add application
```bash
bash scripts/app-tracker.sh add \
  --company "Company Name" \
  --role "Role Title" \
  --source "linkedin|referral|direct" \
  --notes "Initial notes"
```

### Update stage
```bash
bash scripts/app-tracker.sh update --id "bw-2026-01" \
  --stage "offer-received" \
  --interviewer "HR Director" \
  --notes "Verbal offer received"
```

### List active
```bash
bash scripts/app-tracker.sh list [--status active|rejected|accepted|withdrawn]
```

### Status report
```bash
bash scripts/status-report.sh [--format markdown|json]
```

**Example markdown output:**
```markdown
# Job Search Status — 2026-03-17

## Active (2)
- **Bridgewater Associates** — Technical Risk Analysis
  Status: Final Round | Last: 2026-03-04 | Next: Awaiting decision
- **Acme Corp** — Sr Security Engineer
  Status: Phone Screen | Last: 2026-03-10 | Next: Technical round TBD

## Pipeline Summary
| Status | Count |
|--------|-------|
| Active | 2 |
| Rejected | 1 |
| Withdrawn | 0 |
| Offers | 0 |

## Follow-ups Needed
- Acme Corp: No update in 7 days — consider follow-up email
```

### Search
```bash
bash scripts/app-tracker.sh search "bridgewater"
```

## Interview Stage Definitions

| Stage | Description |
|-------|-------------|
| `applied` | Application submitted |
| `phone-screen` | Initial recruiter call |
| `technical` | Technical interview/assessment |
| `round-N` | Numbered interview rounds |
| `final-round` | Final interview stage |
| `offer-received` | Offer extended |
| `negotiating` | Counter-offer in progress |
| `accepted` | Offer accepted |
| `rejected` | Rejected by company |
| `withdrawn` | Withdrawn by candidate |
| `ghosted` | No response after 14+ days |

## Workflow

1. **Add** new application when you apply
2. **Update** after each interview with stage, interviewer, notes
3. **Report** weekly to review pipeline and identify follow-ups
4. **Search** when preparing for specific company interviews
