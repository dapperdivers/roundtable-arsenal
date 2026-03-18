---
name: news-aggregator
description: >
  Aggregate tech and security news from RSS/Atom feeds. Use for morning intelligence reports, nerd news digests, and staying informed on topics relevant to the user.
---

# News Aggregator

Fetches and filters news from configured RSS/Atom sources with relevance scoring.

## Scripts

### Fetch news (bash — no dependencies)
```bash
bash scripts/fetch-news.sh --hours 24 --category all --limit 15
```
Categories: `tech`, `security`, `gaming`, `science`, `all`

Falls back to SearXNG if RSS feeds fail.

### Fetch news (python — requires feedparser)
```bash
python3 scripts/fetch-news.py [--hours 24] [--category tech|security|all]
```

## Output

Returns structured entries with: title, link, published date, source, and relevance score.
