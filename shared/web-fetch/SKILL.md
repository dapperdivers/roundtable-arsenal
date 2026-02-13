---
name: web-fetch
description: Fetch and extract readable content from a URL. Use when you need to read a webpage, article, or documentation page. Strips HTML to plain text.
allowed-tools: Bash(curl:*)
metadata:
  author: roundtable
  version: "1.0"
  tier: shared
---

# Web Fetch

Retrieve and extract readable text content from any URL. Useful for reading articles, documentation, or any web page referenced in your research.

## Quick Reference

```bash
# Fetch a URL (default 10000 chars max)
bash scripts/fetch.sh "https://example.com/article"

# With character limit
bash scripts/fetch.sh "https://example.com/article" 5000
```

## Direct Usage

```bash
curl -sL -A "Knight-Agent/1.0" "https://example.com" \
  | sed 's/<script[^>]*>.*<\/script>//g; s/<style[^>]*>.*<\/style>//g; s/<[^>]*>/ /g' \
  | tr -s ' \n' | head -c 10000
```

## Tips

- Some sites block automated fetches — the script uses a browser-like User-Agent
- JavaScript-rendered pages won't work — use the browser skill for those
- Output is truncated to avoid flooding context

## Scripts

See [scripts/fetch.sh](scripts/fetch.sh) for implementation.
