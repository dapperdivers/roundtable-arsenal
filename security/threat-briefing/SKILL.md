---
name: threat-briefing
description: Generate daily and weekly security threat intelligence briefings. Combines OpenCTI data, RSS feeds, and CVE analysis into structured reports. Use for scheduled briefing tasks or on-demand threat summaries.
allowed-tools: Bash(curl:*) Read Write
metadata:
  author: roundtable
  version: "2.0"
  tier: security
  compatibility: Requires opencti-intel skill and OPENCTI_TOKEN
---

# Threat Briefing Generator

Produces structured security intelligence briefings by combining data from OpenCTI, RSS feeds, and CVE databases.

## Workflow

1. **Gather** — Query OpenCTI for recent indicators, vulnerabilities, reports, and malware
2. **Analyze** — Prioritize by severity, relevance to tracked infrastructure, and novelty
3. **Synthesize** — Combine structured data with RSS context into a narrative briefing
4. **Format** — Render using the appropriate template (daily or weekly)
5. **Deliver** — Return via NATS for the orchestrator to distribute

## Templates

### Daily Briefing
Use [assets/daily-briefing.md](assets/daily-briefing.md) — covers last 24 hours, focused on actionable items.

### Weekly Summary
Use [assets/weekly-briefing.md](assets/weekly-briefing.md) — covers 7-day trends, strategic analysis.

### CVE Report
Use [assets/cve-report.md](assets/cve-report.md) — deep dive on specific vulnerabilities.

## Severity Classification

| Level | Criteria |
|-------|----------|
| 🔴 CRITICAL | Active exploitation, CVSS 9.0+, affects tracked stack |
| 🟠 HIGH | CVSS 7.0-8.9, proof-of-concept available, broad impact |
| 🟡 MEDIUM | CVSS 4.0-6.9, theoretical risk, limited exposure |
| 🟢 LOW/INFO | Informational, trend tracking, no immediate action |

## Stack Relevance

Prioritize findings related to:
- Kubernetes, Talos, Cilium, Flux
- Linux kernel, container runtimes
- NATS, RabbitMQ, OpenSearch, MinIO
- Home Assistant, network infrastructure
- Go, Node.js, Python dependencies

## Output Structure

Briefings should include:
1. Executive summary (2-3 sentences)
2. Critical/high findings with context
3. Notable CVEs with CVSS and affected products
4. Trending themes and threat actor activity
5. Recommended actions

## Dependencies

This skill works best when combined with:
- `opencti-intel` — for structured threat data
- `web-search` — for additional context on emerging threats
- `report-generator` — for template rendering
- `nats-comms` — for result delivery
