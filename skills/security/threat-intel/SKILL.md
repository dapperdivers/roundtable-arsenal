---
name: threat-intel
description: Aggregate threat intelligence from RSS feeds, CVE databases, and other sources into unified reports. Use for comprehensive threat assessments.
---

# Threat Intel Aggregator

Combines output from rss-analyzer and cve-lookup into a unified threat intelligence report.

## Scripts

### `aggregate-intel.py`

```bash
python3 scripts/aggregate-intel.py --feeds feed-results.json --cves cve-results.json
python3 scripts/aggregate-intel.py --feeds-stdin < combined.json --days 1
```

**Arguments:**
| Flag | Description |
|------|-------------|
| `--feeds` | JSON file from rss-analyzer output |
| `--cves` | JSON file from cve-lookup output |
| `--feeds-stdin` | Read combined feed data from stdin |
| `--days` | Reporting period in days (default: 1) |
| `--format` | Output: `json`, `markdown`, `brief` |

**Output:** Unified threat intelligence report with:
- Threat summary with counts by severity
- Top threats ranked by severity and relevance
- CVE highlights
- Recommended actions
