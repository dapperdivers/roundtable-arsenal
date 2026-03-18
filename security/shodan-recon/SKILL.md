---
name: shodan-recon
description: Query Shodan for internet-facing asset intelligence, exposure analysis, and threat enrichment.
---

# Shodan Reconnaissance

Query the Shodan API for internet-facing asset intelligence. Use for exposure analysis, threat enrichment, vulnerability correlation, and attack surface mapping.

## Prerequisites

- `SHODAN_API_KEY` environment variable must be set
- Free tier: 100 queries/month | Membership: unlimited

## Commands

### Search hosts by query
```bash
bash scripts/shodan-search.sh "query" [limit]
```
Search Shodan's database. Uses Shodan search syntax (e.g., `org:"Target Corp"`, `port:22 country:US`, `vuln:CVE-2026-1731`).

### Get host details by IP
```bash
bash scripts/shodan-host.sh <ip>
```
Returns open ports, services, banners, vulnerabilities, and geolocation for a specific IP.

### Check exploit availability
```bash
bash scripts/shodan-exploits.sh "query" [limit]
```
Search Shodan's exploit database for known exploits matching a query (CVE ID, product name, etc.).

## Query Syntax Examples

| Query | Description |
|-------|-------------|
| `port:3389 country:US` | RDP exposed in the US |
| `vuln:CVE-2026-1731` | Hosts vulnerable to specific CVE |
| `org:"Company Name"` | Assets belonging to an organization |
| `product:nginx city:"Birmingham"` | Nginx servers in Birmingham |
| `ssl.cert.subject.CN:"example.com"` | Hosts with specific SSL cert |
| `has_vuln:true port:443` | HTTPS hosts with known vulns |

## Use Cases

1. **Threat enrichment** — Look up IPs from OpenCTI IOCs for context
2. **Exposure monitoring** — Check if specific services are internet-facing
3. **Vulnerability correlation** — Find hosts affected by a CVE being tracked
4. **Attack surface mapping** — Enumerate an organization's exposed assets
5. **Incident investigation** — Profile attacker infrastructure

## Output

All scripts output JSON. Parse with standard tools or pass to report-generator skill for formatted output.

## Rate Limits

- Free API: 1 query/second, 100 queries/month
- Membership: 1 query/second, unlimited queries
- Scripts include 1-second delays between paginated requests
