#!/usr/bin/env python3
"""fetch-feeds.py — Fetch RSS feeds and return structured JSON."""

import argparse
import json
import sys
from datetime import datetime, timedelta, timezone

try:
    import feedparser
except ImportError:
    print("Error: feedparser not installed. Run: pip install feedparser", file=sys.stderr)
    sys.exit(1)


DEFAULT_FEEDS = [
    "https://feeds.feedburner.com/TheHackersNews",
    "https://www.cisa.gov/cybersecurity-advisories/all.xml",
    "https://krebsonsecurity.com/feed/",
    "https://www.bleepingcomputer.com/feed/",
]


def parse_since(since_str: str) -> datetime:
    """Parse a relative time string like '24h' or '7d' into a datetime."""
    now = datetime.now(timezone.utc)
    if since_str.endswith("h"):
        return now - timedelta(hours=int(since_str[:-1]))
    elif since_str.endswith("d"):
        return now - timedelta(days=int(since_str[:-1]))
    raise ValueError(f"Invalid --since format: {since_str}")


def fetch_feed(url: str, since: datetime = None) -> list:
    """Fetch a single feed and return entries."""
    feed = feedparser.parse(url)
    entries = []
    for entry in feed.entries:
        published = entry.get("published_parsed")
        if published:
            pub_dt = datetime(*published[:6], tzinfo=timezone.utc)
            if since and pub_dt < since:
                continue
            pub_str = pub_dt.isoformat()
        else:
            pub_str = None

        entries.append({
            "title": entry.get("title", ""),
            "link": entry.get("link", ""),
            "published": pub_str,
            "summary": entry.get("summary", "")[:500],
            "source": feed.feed.get("title", url),
        })
    return entries


def main():
    parser = argparse.ArgumentParser(description="Fetch cybersecurity RSS feeds.")
    parser.add_argument("--url", action="append", help="Feed URL (repeatable)")
    parser.add_argument("--feeds", help="JSON file with list of feed URLs")
    parser.add_argument("--since", help="Only entries from last Nh or Nd (e.g., 24h, 7d)")
    parser.add_argument("--format", choices=["json", "summary"], default="json")
    args = parser.parse_args()

    urls = []
    if args.url:
        urls.extend(args.url)
    if args.feeds:
        urls.extend(json.loads(open(args.feeds).read()))
    if not urls:
        urls = DEFAULT_FEEDS

    since = parse_since(args.since) if args.since else None

    all_entries = []
    for url in urls:
        try:
            all_entries.extend(fetch_feed(url, since))
        except Exception as e:
            print(f"Warning: Failed to fetch {url}: {e}", file=sys.stderr)

    all_entries.sort(key=lambda x: x.get("published") or "", reverse=True)

    if args.format == "summary":
        for e in all_entries:
            print(f"[{e['published'] or '?'}] {e['title']}")
            print(f"  {e['link']}\n")
    else:
        json.dump(all_entries, sys.stdout, indent=2)


if __name__ == "__main__":
    main()
