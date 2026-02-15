---
name: daily-security-report
description: Generate Galahad's daily security briefing. Aggregates data from OpenCTI, RSS feeds, CISA KEV, and CVE sources into a structured report following the shared daily-reports contract.
allowed-tools: Bash(curl:*) Read Write
metadata:
  author: roundtable
  version: "1.0"
  tier: security
  knight: sir-galahad
  schedule: "0600 UTC daily"
---

# Daily Security Report — Galahad

Produce a daily security briefing covering the threat landscape, active vulnerabilities, IOCs, and recommended actions. Output MUST conform to the shared `daily-reports` JSON contract.

## Dependencies

| Skill | Purpose |
|-------|---------|
| `security/opencti-intel` | CVEs, IOCs, threat actors, platform health, STIX data |
| `security/rss-analyzer` | Security news, narrative context, feed analysis |
| `security/cve-deep-dive` | Deep analysis of specific critical CVEs |
| `security/threat-briefing` | Threat actor profiles and campaign tracking |
| `shared/daily-reports` | **Output contract** — JSON schema and vault template |

## Data Source Priority

Query in this order. Higher priority sources override lower on conflicts.

| Priority | Source | Skill/Method | Signal Quality |
|----------|--------|--------------|----------------|
| 1 | CISA KEV feed | `opencti-intel` → KEV connector | Highest — actively exploited |
| 2 | OpenCTI vulnerabilities | `opencti-intel` → `opencti-vulns.sh` | High — NVD/CVE normalized |
| 3 | ThreatFox + URLhaus | `opencti-intel` → indicators | High — active malware IOCs |
| 4 | Curated RSS feeds | `rss-analyzer` → `analyze-feed.py` | Medium — narrative context |
| 5 | OpenCTI reports | `opencti-intel` → reports query | Medium — depends on connectors |
| 6 | MITRE ATT&CK | `opencti-intel` → attack patterns | Reference — technique mapping |

## Report Sections

Generate exactly 8 sections in this order. Each section maps to one entry in the `sections` array of the JSON contract.

### 1. Executive Threat Summary
- 2–3 sentence threat landscape overview
- State the threat level: `CRITICAL` | `HIGH` | `MEDIUM` | `LOW` | `QUIET`
- Confidence assessment for the day's intelligence
- Period covered (default: previous 24h, 0600 UTC to 0600 UTC)
- **This also populates the top-level `summary` field in the JSON contract**
- Priority: match to highest-priority finding in the report
- Confidence: aggregate of section confidences

### 2. Critical Alerts
- New CISA KEV additions (last 24h)
- Critical CVEs: CVSS ≥ 9.0 published in period
- Active exploit code released (check ThreatFox, ExploitDB references)
- Zero-days in the wild
- Format per item: `CVE ID | Product | CVSS | Exploit Status | Recommendation`
- Priority: `high` if any items exist, `low` if empty
- Confidence: `high` (direct platform data)
- Data sources: `["CISA KEV", "NVD/CVE", "ThreatFox"]`

### 3. Threat Actor Activity
- New campaigns from OpenCTI reports
- Attribution updates
- TTPs observed (map to MITRE ATT&CK)
- Geographic targeting patterns
- If no actor data available, state explicitly: "No tracked threat actor activity in period."
- Priority: `high` if nation-state or targeted campaigns, `medium` otherwise
- Confidence: `medium` (attribution is inherently uncertain)
- Data sources: `["OpenCTI Reports", "MITRE ATT&CK"]`

### 4. Indicators of Compromise
- New malware families (ThreatFox)
- C2 infrastructure (URLhaus)
- Top 10 most prevalent threats by IOC volume
- Infrastructure clustering patterns
- Priority: `high` if new C2 or malware families, `medium` for routine volume
- Confidence: `high` (direct IOC data)
- Data sources: `["ThreatFox", "URLhaus", "OpenCTI Indicators"]`

### 5. Vulnerability Intelligence
- High-severity CVEs: CVSS 7.0–8.9
- Trending vulnerabilities (multiple sources reporting)
- Patch availability status
- Exploitability assessment (EPSS scores if available)
- Priority: `medium`
- Confidence: `high` (NVD data)
- Data sources: `["NVD/CVE", "EPSS", "OpenCTI Vulnerabilities"]`

### 6. RSS Threat Feed Highlights
- Top 5 security news items by relevance
- Categorize each: `ransomware` | `supply-chain` | `cloud` | `insider-threat` | `nation-state` | `other`
- Ensure source diversity — no more than 2 items from the same feed
- Include source URL for each item
- Priority: `medium`
- Confidence: `medium` (news reporting, not primary data)
- Data sources: `["BleepingComputer", "KrebsOnSecurity", "The Hacker News", "The Record", ...]`

### 7. Platform Health
- OpenCTI connector status (any failed or stale?)
- Entity growth delta (new entities ingested in period)
- Data freshness check per connector
- Keep clinical — health indicators only, no commentary
- Priority: `low` unless connectors are failing
- Confidence: `high` (direct platform metrics)
- Data sources: `["OpenCTI Platform Stats"]`

### 8. Recommended Actions
- **Tactical** (immediate): Block IOCs, patch specific CVEs, investigate alerts
- **Strategic** (short-term): Monitor campaigns, review exposure, update detection rules
- **Intelligence gaps**: What data is missing or stale?
- Priority: match to highest-priority recommendation
- Confidence: derived from underlying section confidences
- Data sources: aggregate from all sections

## Confidence Scoring

Apply per section:

| Level | Criteria |
|-------|----------|
| `high` | Direct platform data (CVEs, IOCs, connector status). Verified from authoritative sources. |
| `medium` | RSS analysis, unverified attribution, single-source corroboration. Reasonable but uncertain. |
| `low` | Single-source claims, speculation, stale data (>48h old). Flag explicitly. |

## Execution Workflow

```
1. Query OpenCTI: platform stats, recent vulns, indicators, reports
   └─ bash scripts from opencti-intel skill

2. Query RSS: fetch and analyze last 24h
   └─ python3 scripts from rss-analyzer skill

3. Cross-reference: deduplicate, correlate CVEs across sources

4. Assess: assign threat level, confidence per section

5. Build JSON: populate the shared daily-reports contract
   └─ knight: "sir-galahad"
   └─ run_id: "daily-YYYY-MM-DD"
   └─ report_type: "daily-briefing"

6. Render markdown: use templates/daily-briefing.md for vault output

7. Output both: JSON to stdout/file, markdown to vault path
```

## Modes

| Mode | Trigger | Behavior |
|------|---------|----------|
| **Scheduled** | Cron at 0600 UTC | Full report, publish to `reports.security.daily` |
| **On-demand** | "Give me today's briefing" | Full report, return immediately |
| **Historical** | "Briefing for YYYY-MM-DD" | Query historical data for specified date |

## Output

- **JSON:** Conforms to `shared/daily-reports` contract schema
- **Markdown:** Rendered via `templates/daily-briefing.md` for Obsidian vault
- **Highlights:** 3–5 bullet points for Tim's morning briefing (populates `highlights` array)

## What This Report Is NOT

- Not a compliance checklist
- Not a marketing summary of blog posts
- Not a dump of every CVE published
- Not a repeat of yesterday's report with new dates

Every line answers "so what?" or it doesn't belong.
