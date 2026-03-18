---
name: rss-analyzer
description: Fetch and analyze cybersecurity RSS feeds for threat intelligence. Use for daily/weekly security briefings or ad-hoc feed analysis. Categorizes entries by severity, relevance, and threat type.
allowed-tools: Bash(curl:*,python3:*) Read Write
metadata:
  author: roundtable
  version: "2.1"
  tier: security
  compatibility: Requires Python 3.9+, feedparser and beautifulsoup4 libraries
---

# RSS Analyzer

Fetches cybersecurity RSS feeds and analyzes entries for threats, categorization, and severity scoring.

## When to Use

- Building daily/weekly security briefings
- Monitoring specific feeds for breaking threats
- Supplementing OpenCTI data with narrative context from security blogs
- Tracking disclosure timelines for vulnerabilities

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `RSS_CACHE_DIR` | `/tmp/rss-cache` | Directory for cached feed data |
| `RSS_MAX_AGE_HOURS` | `24` | Maximum age of entries to process |

## Configured Feeds

See [references/feeds.md](references/feeds.md) for the full feed list with categories.

## Workflow

1. **Fetch** — Download configured RSS/Atom feeds via HTTP/HTTPS
2. **Parse** — Extract entries (title, link, published date, description/summary)
3. **Categorize** — Assign category: `vulnerability`, `malware`, `threat-actor`, `policy`, `tool`, `research`
4. **Score** — Assign severity (`critical`, `high`, `medium`, `low`) based on keywords and context
5. **Deduplicate** — Remove duplicate entries across feeds (by URL or title similarity)
6. **Output** — Return structured JSON or render markdown

## Scripts

### Fetch all feeds
```bash
python3 scripts/fetch-feeds.py [--cache-dir /path] [--verbose]
```

Fetches all feeds configured in `references/feeds.md`. Outputs JSON array of entries.

**Example output:**
```json
[
  {
    "feed": "BleepingComputer",
    "title": "Critical RCE in Log4j allows remote code execution",
    "link": "https://example.com/article",
    "published": "2026-03-17T14:30:00Z",
    "category": "vulnerability",
    "severity": "critical"
  }
]
```

### Analyze fetched entries
```bash
python3 scripts/analyze-feed.py [--since 24h] [--min-severity medium] [--category vulnerability]
```

Analyzes cached feed data. Filters by time window, severity, and category.

**Example:**
```bash
# Get all critical/high vulns from last 48 hours
python3 scripts/analyze-feed.py --since 48h --min-severity high --category vulnerability

# Output format
{
  "entries": [...],
  "summary": {
    "total": 42,
    "by_severity": {"critical": 3, "high": 12, "medium": 27},
    "by_category": {"vulnerability": 28, "malware": 14}
  }
}
```

### Error Handling

Scripts exit with:
- `0` — Success
- `1` — Network error (feed unreachable)
- `2` — Parse error (invalid XML/JSON)
- `3` — Configuration error (missing feed list)

Check stderr for error details.

## Examples

### Use Case 1: Daily Briefing
```bash
# Fetch latest, analyze high-severity items
python3 scripts/fetch-feeds.py
python3 scripts/analyze-feed.py --since 24h --min-severity high
```

### Use Case 2: Malware Tracking
```bash
# Get malware-specific entries from last week
python3 scripts/analyze-feed.py --since 168h --category malware
```

### Use Case 3: Custom Time Window
```bash
# Historical analysis for specific date range
python3 scripts/fetch-feeds.py
python3 scripts/analyze-feed.py --since 2026-03-15T00:00:00Z --until 2026-03-16T23:59:59Z
```

## Note on OpenCTI RSS

18 security feeds are also ingested into OpenCTI as STIX reports. For structured data, prefer querying OpenCTI via `opencti-intel`. Use this skill for:
- Feeds NOT in OpenCTI
- When you need the raw narrative/article text
- When OpenCTI RSS ingestion is behind or inactive
- Custom feed analysis not available in OpenCTI

## Dependencies

- Python 3.9+
- `feedparser` — RSS/Atom parsing
- `beautifulsoup4` — HTML cleanup
- `requests` — HTTP client

Install via: `pip3 install feedparser beautifulsoup4 requests`
