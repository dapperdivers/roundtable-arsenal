---
name: morning-security-brief
description: >
  Write a short, high-signal daily security brief for a senior security engineer: actively
  exploited vulnerabilities and CISA KEV additions, headline outages and breaches everyone
  will be discussing, critical CVEs in the reader's own stack with an "affects me?" verdict,
  and one item worth reading. Use when asked
  for a morning or daily security brief, security news, "what happened in security", or a
  KEV/CVE roundup, especially as one section of a larger morning brief.
compatibility: >
  Needs web search plus a page/URL fetch tool that returns raw JSON (for example the
  web-fetch MCP server). Reads the reader's stack from an Obsidian vault if one is available.
metadata:
  author: dapperdivers
  runtime: kagent (claude harness)
---

# Morning Security Brief

A brief the reader finishes in two minutes and trusts. Fewer, better items beat coverage.

## Workflow

1. **Know the stack.** If a vault is available, search it for the homelab/stack inventory
   (e.g. `search_notes` for "stack", "homelab", "cluster", "versions") and note product
   *and version* where written. Without versions, you can only say "check your version".
2. **Exploited first.** Look for what is being exploited now:
   - CISA KEV: fetch `https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json`
     raw (it is large; page through with `start_index` only as far as needed) and keep entries
     with `dateAdded` in the last 2 days. Cross-check with the CISA alert that announced them.
   - Search for active exploitation, zero-days and major incidents from the last 24 hours.
3. **Headline events, even outside the stack.** Major outages and incidents everyone will be
   talking about today: banks or payment networks offline, Microsoft/AWS/Google/Cloudflare
   problems, a bad vendor update taking systems down, large breaches or ransomware at
   well-known organisations. For each: what happened, who was hit, and whether it is an
   **attack or an operational failure** (leadership will ask "is this a breach?").
4. **Your stack.** For each product in the stack, search for new critical/high CVEs and
   vendor advisories from the last few days. For any CVE you include, check:
   - EPSS: `https://api.first.org/data/v1/epss?cve=<CVE>` (probability of exploitation)
   - NVD: `https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=<CVE>` (CVSS, affected
     versions; unauthenticated calls are rate-limited, so look up only what you include)
5. **Pick one "worth reading"**: a primary write-up (post-mortem, research, advisory), not
   a news rewrite. Link the original when you can find it.
6. **Write** using the format below. Drop anything that isn't actionable or important.

## Output format

Markdown bullets only, most important first, at most 6 top-level bullets, each one or two
short lines:

```
- **<Thing> (<exploited|critical|high>):** what happened, in one line. Affects you: <yes — why / no / check vX.Y>. [source](url)
- **<Outage/incident> (<attack|operational failure|cause unknown>):** who was hit, impact, status. [source](url)
- **Worth reading:** <title> — why it matters in one line. [source](url)
```

If nothing important happened, say so in one bullet. No heading, preamble or sign-off.

## Gotchas

- **"Affects you" needs evidence.** Say "yes" only when the product is in the stack *and*
  the version is affected or unknown-but-likely. Otherwise "no", or "check your version".
- **Absence of results is not "clean".** Write "nothing found for X", never "X is safe".
- **Prefer primary sources** (vendor advisory, CISA, NVD, the researcher's post). If you
  only saw an item in secondary coverage or an aggregator, say so.
- **Don't reject unfamiliar CVE IDs.** IDs from 2025 on often have 6+ digits.
- **Severity labels:** use the vendor's or NVD's, not your own guess. KEV listing means
  exploited regardless of CVSS.
- **Never invent** CVE IDs, versions, dates, EPSS scores or quotes. Unverified → say so.
- **Don't call an outage an attack** until a credible source (the company, CISA, a named
  researcher) says so. Early reports often guess; write "cause not yet confirmed".
- **Skip noise:** vendor marketing, "top 10" lists, funding news, generic advice.
