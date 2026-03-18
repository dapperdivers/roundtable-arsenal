---
name: opencti-intel
description: >
  Query the OpenCTI threat intelligence platform for STIX 2.1 data including indicators, vulnerabilities, malware, reports, and attack patterns. Use for threat briefings, CVE lookups, IOC searches, and platform statistics.
---

# OpenCTI Intelligence

Query the OpenCTI threat intelligence platform for structured STIX 2.1 data.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENCTI_URL` | `http://opencti-server.security.svc.cluster.local` | API base URL (port 80) |
| `OPENCTI_TOKEN` | — | Bearer token (required) |
| `OPENCTI_TIMEOUT` | `30` | Request timeout in seconds |

## Scripts

### General query
```bash
bash scripts/opencti-query.sh '{ about { version } }'
```

Executes arbitrary GraphQL query against OpenCTI API. Returns JSON response.

**Example output:**
```json
{
  "data": {
    "about": {
      "version": "5.12.0"
    }
  }
}
```

### Daily briefing (pre-built)
```bash
bash scripts/daily-brief.sh [--since 24h]
```

Returns recent indicators, vulnerabilities, and reports formatted for briefing consumption.

### Platform statistics
```bash
bash scripts/platform-stats.sh
```

**Example output:**
```json
{
  "connectors": {
    "total": 12,
    "active": 11,
    "failed": 1
  },
  "entities": {
    "indicators": 1423,
    "vulnerabilities": 892,
    "reports": 67
  }
}
```

### Search indicators
```bash
bash scripts/opencti-indicators.sh [count]
```

Returns most recent indicators (IOCs). Default count: 20.

**Example:**
```bash
# Get 50 most recent IOCs
bash scripts/opencti-indicators.sh 50
```

### Search vulnerabilities
```bash
bash scripts/opencti-vulns.sh [count] [--min-cvss 7.0]
```

Returns vulnerabilities, optionally filtered by minimum CVSS score.

### Search by keyword
```bash
bash scripts/opencti-search.sh "search term"
```

Full-text search across all STIX entities.

**Example:**
```bash
# Find all entities mentioning Log4j
bash scripts/opencti-search.sh "log4j"
```

### Recent threats
```bash
bash scripts/opencti-threats.sh [count]
```

Returns recent threat actor and campaign data.

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

## Error Handling

All scripts exit with:
- `0` — Success, data returned
- `1` — Authentication failure (invalid or missing OPENCTI_TOKEN)
- `2` — Connection error (OPENCTI_URL unreachable)
- `3` — Query error (invalid GraphQL syntax)
- `4` — Timeout (query took >${OPENCTI_TIMEOUT}s)

Check stderr for detailed error messages.

## Examples

### Use Case 1: Morning Briefing
```bash
# Get overnight threats
bash scripts/daily-brief.sh --since 12h
```

### Use Case 2: Investigating an IP
```bash
# Search for IOCs matching specific IP
bash scripts/opencti-search.sh "192.168.1.100"
```

### Use Case 3: CVE Monitoring
```bash
# Get all critical CVEs from this month
bash scripts/opencti-vulns.sh 100 --min-cvss 9.0 | jq '.[] | select(.created > "2026-03-01")'
```

## Data Sources

OpenCTI aggregates data from these connectors (as of v2.1):

- **Connectors:** CISA KEV, MITRE ATT&CK, EPSS, CVE/NVD, ThreatFox, URLhaus, AlienVault OTX, Malware Bazaar
- **RSS feeds:** 18 security news feeds (Krebs, BleepingComputer, The Record, Unit 42, Securelist, etc.)
- All data normalized to STIX 2.1 with relationships and enrichment

## References

- [Query Reference](references/QUERIES.md) — Complete GraphQL query examples
- [STIX Format](references/STIX-FORMAT.md) — STIX 2.1 object types and relationships
- [Connector Status](references/CONNECTORS.md) — Data source details and refresh schedules
