# RSS Monitor

Automated RSS feed monitoring skill for security and tech intelligence gathering.

## Purpose

Fetches recent articles from curated security/tech RSS feeds and outputs structured JSON for downstream analysis and reporting.

## Files

- `rss-feeds.opml` — Starter OPML with security/tech feeds
- `fetch-rss.sh` — Fetches feeds, extracts last 24h entries, outputs JSON

## Usage

```bash
# Fetch latest articles (saves to /data/rss-latest.json)
./fetch-rss.sh

# Use custom OPML file
./fetch-rss.sh /path/to/custom-feeds.opml

# Use custom output path
OUTFILE=/tmp/rss.json ./fetch-rss.sh
```

## Output Format

```json
[
  {
    "title": "Article Title",
    "link": "https://example.com/article",
    "published": "2026-03-09T12:00:00Z",
    "source": "Feed Name",
    "summary": "Brief description..."
  }
]
```

## Dependencies

- `curl`
- `xmllint` (libxml2-utils)
- Python 3 (for JSON formatting and date parsing)
