---
name: news-aggregator
description: Aggregate news from configured RSS/Atom sources. Use for morning intelligence reports and staying informed.
---

# News Aggregator

Fetches and filters news from configured sources.

## Scripts

### `fetch-news.py`

```bash
python3 scripts/fetch-news.py --sources tech,general --since 24h
python3 scripts/fetch-news.py --config feeds.json --limit 20
```

**Arguments:**
| Flag | Description |
|------|-------------|
| `--sources` | Source categories: `tech`, `general`, `business`, `science` |
| `--config` | JSON config file with feed URLs |
| `--since` | Time window (e.g., `24h`, `7d`) |
| `--limit` | Max results (default: 20) |
| `--format` | Output: `json` or `summary` |

**Output:** JSON array of news items with title, source, date, summary, and link.
