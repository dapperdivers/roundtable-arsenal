---
name: rss-analyzer
description: Fetch and analyze cybersecurity RSS feeds for threat intelligence. Use for daily/weekly security briefings or ad-hoc feed analysis. Categorizes entries by severity, relevance, and threat type.
allowed-tools: Bash(curl:*) Read Write
metadata:
  author: roundtable
  version: "2.0"
  tier: security
---

# RSS Analyzer

Fetches cybersecurity RSS feeds and analyzes entries for threats, categorization, and severity scoring.

## When to Use

- Building daily/weekly security briefings
- Monitoring specific feeds for breaking threats
- Supplementing OpenCTI data with narrative context from security blogs

## Configured Feeds

See [references/feeds.md](references/feeds.md) for the full feed list with categories.

## Workflow

1. Fetch configured RSS/Atom feeds
2. Parse entries (title, link, published date, description)
3. Categorize: vulnerability, malware, threat-actor, policy, tool, research
4. Score severity based on keywords and context
5. Deduplicate across feeds
6. Output structured JSON or markdown

## Scripts

### Fetch all feeds
```bash
python3 scripts/fetch-feeds.py
```

### Analyze fetched entries
```bash
python3 scripts/analyze-feed.py [--since 24h] [--min-severity medium]
```

## Note on OpenCTI RSS

18 security feeds are also ingested into OpenCTI as STIX reports. For structured data, prefer querying OpenCTI via `opencti-intel`. Use this skill for:
- Feeds NOT in OpenCTI
- When you need the raw narrative/article text
- When OpenCTI RSS ingestion is behind or inactive
