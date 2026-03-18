---
name: career-context-aggregator
description: >
  Aggregate career context from the Obsidian vault into a single quick-reference dashboard. Use before interviews, negotiations, or career planning sessions to load all relevant context in 30 seconds.
---

# Career Context Aggregator

Scans the Obsidian vault and builds a consolidated career context document for rapid consumption.

## When to Use

- Before an interview (load company research, prep notes, talking points)
- When an offer arrives (aggregate negotiation data, BATNA, comp research)
- Weekly career check-ins (status of all active opportunities)
- Updating resume or LinkedIn (pull experience highlights)

## Workflow

1. **Scan** vault paths for career-related notes
2. **Extract** key metadata (status, company, dates, contacts)
3. **Aggregate** into a single context document
4. **Prioritize** by relevance and recency

## Scripts

### Build career dashboard
```bash
bash scripts/aggregate-context.sh [--format markdown|json] [--active-only]
```

Scans configured vault paths and builds a consolidated career context document.

**Vault paths scanned:**
- `Personal/Career/` — applications, interviews, offers
- `Work/` — current employment context
- `Research/` — company research, industry analysis
- `Projects/` — portfolio projects with impact metrics

**Output sections:**
1. **Active Opportunities** — status, next steps, contacts, timeline
2. **Interview Prep** — company-specific research, questions, talking points
3. **Skills & Experience** — highlights, certifications, impact metrics
4. **Negotiation Data** — comp research, BATNA, market benchmarks
5. **Network** — key contacts, referrals, recruiter relationships

### Quick status check
```bash
bash scripts/aggregate-context.sh --active-only --format json
```

Returns just active opportunities as JSON for quick parsing.

**Example output:**
```json
{
  "active_opportunities": [
    {
      "company": "Bridgewater Associates",
      "role": "Technical Risk Analysis",
      "status": "Final 2 Candidates",
      "next_step": "Awaiting offer decision",
      "timeline": "March 19-23",
      "contacts": ["Spencer (recruiter)", "Alana (scheduling)"]
    }
  ],
  "last_updated": "2026-03-17T21:00:00Z"
}
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `VAULT_PATH` | `/vault` | Root path to Obsidian vault |
| `CAREER_PATHS` | `Personal/Career,Work,Research,Projects` | Comma-separated paths to scan |
| `MAX_AGE_DAYS` | `90` | Ignore notes older than this |

## Edge Cases

- **No career notes found**: Returns empty dashboard with path suggestions
- **Malformed frontmatter**: Skips file, logs warning to stderr
- **Large vault**: Scans by modification date first, limits to MAX_AGE_DAYS
- **Missing paths**: Silently skips non-existent directories

## Error Handling

Exit codes:
- `0` — Success, dashboard generated
- `1` — Vault path not found
- `2` — No career notes found in any configured path
- `3` — Output write failure
