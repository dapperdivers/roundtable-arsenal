---
name: opencti-intel
description: Query the OpenCTI threat intelligence platform for STIX 2.1 data including indicators, vulnerabilities, malware, reports, and attack patterns. Use for threat briefings, CVE lookups, IOC searches, and platform statistics.
allowed-tools: Bash(curl:*) Read
metadata:
  author: roundtable
  version: "2.0"
  tier: security
  compatibility: Requires OPENCTI_URL and OPENCTI_TOKEN environment variables
---

# OpenCTI Intelligence

Query the OpenCTI threat intelligence platform for structured STIX 2.1 data.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENCTI_URL` | `http://opencti-server.security.svc.cluster.local` | API base URL (port 80) |
| `OPENCTI_TOKEN` | — | Bearer token (required) |

## Scripts

### General query
```bash
bash scripts/opencti-query.sh '{ about { version } }'
```

### Daily briefing (pre-built)
```bash
bash scripts/daily-brief.sh
```

### Platform statistics
```bash
bash scripts/platform-stats.sh
```

### Search indicators
```bash
bash scripts/opencti-indicators.sh [count]
```

### Search vulnerabilities
```bash
bash scripts/opencti-vulns.sh [count]
```

### Search by keyword
```bash
bash scripts/opencti-search.sh "search term"
```

### Recent threats
```bash
bash scripts/opencti-threats.sh [count]
```

## Common GraphQL Queries

See [references/QUERIES.md](references/QUERIES.md) for the full query reference.

### Quick examples:

**Recent reports:**
```graphql
{reports(first:20 orderBy:created_at orderMode:desc){edges{node{name description created_at createdBy{name}}}}}
```

**Recent indicators (IOCs):**
```graphql
{indicators(first:20 orderBy:created_at orderMode:desc){edges{node{name pattern indicator_types valid_from created_at createdBy{name}}}}}
```

**Vulnerabilities by CVSS:**
```graphql
{vulnerabilities(first:10 orderBy:x_opencti_cvss_base_score orderMode:desc){edges{node{name description x_opencti_cvss_base_score created}}}}
```

## Data Sources

- **Connectors:** CISA KEV, MITRE ATT&CK, EPSS, CVE/NVD, ThreatFox, URLhaus, AlienVault OTX, Malware Bazaar
- **RSS feeds:** 18 security news feeds (Krebs, BleepingComputer, The Record, Unit 42, Securelist, etc.)
- All data normalized to STIX 2.1 with relationships and enrichment
