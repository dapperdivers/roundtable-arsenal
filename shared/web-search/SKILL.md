---
name: web-search
description: Search the web using the cluster SearXNG metasearch engine. Use when you need to find current information, research topics, or verify facts. Aggregates Google, Brave, DuckDuckGo, and more.
allowed-tools: Bash(curl:*)
metadata:
  author: roundtable
  version: "1.0"
  tier: shared
  compatibility: Requires access to searxng.selfhosted.svc.cluster.local
---

# Web Search (SearXNG)

Search the web via the self-hosted SearXNG metasearch engine. No API keys needed — it aggregates multiple search engines with no rate limits.

## Quick Reference

```bash
# Basic search (returns top 5)
bash scripts/search.sh "your query here"

# With result count
bash scripts/search.sh "your query here" 10
```

## Direct API Usage

```bash
curl -s "http://searxng.selfhosted.svc.cluster.local:8080/search?q=QUERY&format=json" \
  | grep -o '"title":"[^"]*"\|"url":"[^"]*"\|"content":"[^"]*"'
```

## Tips

- Use specific, targeted queries — SearXNG ranks by relevance across engines
- Add `site:github.com` or `site:reddit.com` for source-specific results
- Results include title, URL, and content snippet
- No jq available — use grep/sed/cut for JSON parsing

## Scripts

See [scripts/search.sh](scripts/search.sh) for implementation.
