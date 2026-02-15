# Data Sources Reference

All data sources used by Galahad's daily security report, with query methods and refresh rates.

## Primary Sources

### CISA Known Exploited Vulnerabilities (KEV)
- **Priority:** 1 (highest signal)
- **What:** Actively exploited vulnerabilities with federal remediation deadlines
- **Ingestion:** OpenCTI CISA KEV connector (auto)
- **Query:**
  ```bash
  # Via OpenCTI — KEV-tagged vulnerabilities
  bash scripts/opencti-vulns.sh 20
  # Filter for CISA KEV source in results
  ```
- **Direct feed:** `https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json`
- **Refresh:** Daily
- **Confidence:** HIGH

### NVD / CVE (via OpenCTI)
- **Priority:** 2
- **What:** All published CVEs with CVSS scoring, descriptions, references
- **Ingestion:** OpenCTI CVE connector
- **Query:**
  ```bash
  # Recent critical CVEs (CVSS ≥ 9.0)
  bash scripts/opencti-vulns.sh 50
  # GraphQL for custom filters:
  bash scripts/opencti-query.sh '{
    vulnerabilities(
      first: 20
      orderBy: x_opencti_cvss_base_score
      orderMode: desc
      filters: {
        mode: and
        filters: [{key: "x_opencti_cvss_base_score", values: ["9"], operator: gte}]
      }
    ) {
      edges { node { name description x_opencti_cvss_base_score created } }
    }
  }'
  ```
- **Refresh:** Continuous (OpenCTI connector)
- **Confidence:** HIGH

### ThreatFox (via OpenCTI)
- **Priority:** 3
- **What:** Malware IOCs — IPs, domains, URLs, hashes linked to malware families
- **Ingestion:** OpenCTI ThreatFox connector
- **Query:**
  ```bash
  # Recent indicators
  bash scripts/opencti-indicators.sh 50
  # Filter by indicator_types for malware-specific IOCs
  ```
- **Refresh:** Every 6 hours
- **Confidence:** HIGH

### URLhaus (via OpenCTI)
- **Priority:** 3
- **What:** Malware distribution URLs and C2 infrastructure
- **Ingestion:** OpenCTI URLhaus connector
- **Query:**
  ```bash
  # Query via indicators, filter for url pattern type
  bash scripts/opencti-indicators.sh 50
  ```
- **Refresh:** Every 6 hours
- **Confidence:** HIGH

## Secondary Sources

### Curated RSS Feeds
- **Priority:** 4
- **What:** Security news and analysis from trusted outlets
- **Query:**
  ```bash
  # Fetch and analyze last 24h
  python3 scripts/fetch-feeds.py
  python3 scripts/analyze-feed.py --since 24h --min-severity medium
  ```
- **Key feeds:**
  - BleepingComputer
  - KrebsOnSecurity
  - The Hacker News
  - The Record (Recorded Future)
  - Google TAG blog
  - Unit 42 (Palo Alto)
  - Securelist (Kaspersky)
  - CISA Alerts
- **Note:** 18 feeds also ingested into OpenCTI as STIX reports. Use `rss-analyzer` for narrative text; use `opencti-intel` for structured data.
- **Refresh:** Varies by feed (most hourly)
- **Confidence:** MEDIUM

### OpenCTI Reports
- **Priority:** 5
- **What:** Aggregated threat reports from all connectors, including attribution and campaigns
- **Query:**
  ```bash
  # Recent reports
  bash scripts/opencti-query.sh '{
    reports(first: 20 orderBy: created_at orderMode: desc) {
      edges { node { name description created_at createdBy { name } } }
    }
  }'
  ```
- **Refresh:** Continuous
- **Confidence:** MEDIUM (depends on source connector)

### MITRE ATT&CK (via OpenCTI)
- **Priority:** 6
- **What:** Technique and tactic mappings for threat actor TTPs
- **Query:**
  ```bash
  bash scripts/opencti-query.sh '{
    attackPatterns(first: 20 orderBy: created_at orderMode: desc) {
      edges { node { name x_mitre_id description } }
    }
  }'
  ```
- **Refresh:** Weekly (MITRE connector)
- **Confidence:** HIGH (reference data)

## Platform Health Queries

### Connector Status
```bash
bash scripts/platform-stats.sh
# Or direct GraphQL:
bash scripts/opencti-query.sh '{
  connectorsForImport { name active updated_at connector_state }
}'
```

### Entity Counts
```bash
bash scripts/opencti-query.sh '{
  stixCoreObjectsNumber(types: ["Indicator"]) { total }
}'
```

### EPSS Scores
- Ingested via OpenCTI EPSS connector
- Query alongside vulnerability data for exploitability probability
- **Refresh:** Daily

## Environment

| Variable | Value | Required |
|----------|-------|----------|
| `OPENCTI_URL` | `http://opencti-server.security.svc.cluster.local` | Yes |
| `OPENCTI_TOKEN` | Set in environment | Yes |

## Notes

- Always prefer OpenCTI structured data over raw RSS for IOCs and CVEs
- Use RSS only for narrative context or when OpenCTI connectors are stale
- Check connector freshness in Platform Health before trusting ingested data
- EPSS scores supplement CVSS — high EPSS + high CVSS = immediate action
