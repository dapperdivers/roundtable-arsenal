---
name: rss-analyzer
description: Fetch and analyze cybersecurity RSS feeds for threat intelligence. Use for daily/weekly security briefings.
---

# RSS Analyzer

Fetches cybersecurity RSS feeds and analyzes entries for threats, categorization, and severity scoring.

## Scripts

### `fetch-feeds.py`

Fetch one or more RSS feeds and return structured JSON.

```bash
python3 scripts/fetch-feeds.py --feeds feeds.json
python3 scripts/fetch-feeds.py --url "https://feeds.feedburner.com/TheHackersNews"
python3 scripts/fetch-feeds.py --url "https://www.cisa.gov/cybersecurity-advisories/all.xml" --since 24h
```

**Arguments:**
| Flag | Description |
|------|-------------|
| `--url` | Single feed URL to fetch |
| `--feeds` | JSON file with list of feed URLs |
| `--since` | Only include entries from last N hours (e.g., `24h`, `7d`) |
| `--format` | Output format: `json` (default) or `summary` |

**Output:** JSON array of feed entries with title, link, published date, summary.

### `analyze-feed.py`

Analyze feed entries for threats and assign severity scores.

```bash
python3 scripts/fetch-feeds.py --url "..." | python3 scripts/analyze-feed.py
python3 scripts/analyze-feed.py --input entries.json --min-severity medium
```

**Arguments:**
| Flag | Description |
|------|-------------|
| `--input` | JSON file of feed entries (or stdin) |
| `--min-severity` | Minimum severity to include: `low`, `medium`, `high`, `critical` |
| `--categories` | Filter by categories (comma-separated) |

**Output:** JSON with analyzed entries including severity score, threat category, and relevance ranking.
