#!/usr/bin/env python3
"""fetch-news.py — Fetch and filter news from RSS/Atom feeds."""

import argparse
import json
import sys
from datetime import datetime, timedelta, timezone

try:
    import feedparser
except ImportError:
    print("Error: feedparser not installed. Run: pip install feedparser", file=sys.stderr)
    sys.exit(1)

DEFAULT_FEEDS = {
    "tech": [
        "https://news.ycombinator.com/rss",
        "https://www.theverge.com/rss/index.xml",
        "https://arstechnica.com/feed/",
    ],
    "general": [
        "https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml",
        "https://feeds.bbci.co.uk/news/rss.xml",
    ],
    "business": [
        "https://feeds.bloomberg.com/markets/news.rss",
    ],
    "science": [
        "https://rss.sciencedaily.com/all.xml",
    ],
}


def parse_since(s: str) -> datetime:
    now = datetime.now(timezone.utc)
    if s.endswith("h"):
        return now - timedelta(hours=int(s[:-1]))
    elif s.endswith("d"):
        return now - timedelta(days=int(s[:-1]))
    raise ValueError(f"Invalid time format: {s}")


def main():
    parser = argparse.ArgumentParser(description="Fetch news from RSS feeds.")
    parser.add_argument("--sources", help="Categories: tech,general,business,science")
    parser.add_argument("--config", help="JSON config with feed URLs")
    parser.add_argument("--since", help="Time window (e.g., 24h, 7d)")
    parser.add_argument("--limit", type=int, default=20)
    parser.add_argument("--format", choices=["json", "summary"], default="json")
    args = parser.parse_args()

    urls = []
    if args.config:
        urls = json.loads(open(args.config).read())
    elif args.sources:
        for cat in args.sources.split(","):
            urls.extend(DEFAULT_FEEDS.get(cat.strip(), []))
    else:
        for feeds in DEFAULT_FEEDS.values():
            urls.extend(feeds)

    since = parse_since(args.since) if args.since else None
    entries = []

    for url in urls:
        try:
            feed = feedparser.parse(url)
            for entry in feed.entries:
                pub = entry.get("published_parsed")
                if pub:
                    pub_dt = datetime(*pub[:6], tzinfo=timezone.utc)
                    if since and pub_dt < since:
                        continue
                    pub_str = pub_dt.isoformat()
                else:
                    pub_str = None

                entries.append({
                    "title": entry.get("title", ""),
                    "link": entry.get("link", ""),
                    "published": pub_str,
                    "summary": entry.get("summary", "")[:300],
                    "source": feed.feed.get("title", url),
                })
        except Exception as e:
            print(f"Warning: {url}: {e}", file=sys.stderr)

    entries.sort(key=lambda x: x.get("published") or "", reverse=True)
    entries = entries[:args.limit]

    if args.format == "summary":
        for e in entries:
            print(f"[{e['source']}] {e['title']}")
            print(f"  {e['link']}\n")
    else:
        json.dump(entries, sys.stdout, indent=2)


if __name__ == "__main__":
    main()
