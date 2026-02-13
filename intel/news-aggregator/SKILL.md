---
name: news-aggregator
description: Aggregate tech and security news from RSS/Atom feeds. Use for morning intelligence reports, nerd news digests, and staying informed on topics relevant to the user.
allowed-tools: Bash(curl:*) Bash(python3:*) Read
metadata:
  author: roundtable
  version: "2.0"
  tier: intel
---

# News Aggregator

Fetches and filters news from configured RSS/Atom sources with relevance scoring.

## Scripts

### Fetch news
```bash
python3 scripts/fetch-news.py [--hours 24] [--category tech|security|all]
```

## Output

Returns structured entries with: title, link, published date, source, and relevance score.
