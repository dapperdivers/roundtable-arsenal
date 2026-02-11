# OpenCTI Intelligence Skill

Query the OpenCTI threat intelligence platform for structured STIX 2.1 data.

## Configuration

- **Endpoint:** `http://opencti-server.security.svc.cluster.local/graphql`
- **Auth:** Bearer token from `OPENCTI_TOKEN` environment variable
- **Version:** 6.9.16+

## Scripts

### `scripts/opencti-query.sh`
General-purpose GraphQL query runner.

```bash
# Usage
./scripts/opencti-query.sh "<graphql_query>"

# Examples
./scripts/opencti-query.sh '{about{version}}'
./scripts/opencti-query.sh '{reports(first:5 orderBy:created_at orderMode:desc){edges{node{name created_at createdBy{name}}}}}'
```

### `scripts/daily-brief.sh`
Pre-built daily intelligence summary query. Returns indicators, CVEs, malware, reports, and platform stats.

```bash
./scripts/daily-brief.sh
```

### `scripts/platform-stats.sh`
Quick platform health and object counts.

```bash
./scripts/platform-stats.sh
```

## Common Queries

### Recent Reports (RSS + connector ingested)
```graphql
{reports(first:20 orderBy:created_at orderMode:desc){edges{node{name description created_at createdBy{name}}}}}
```

### Recent Indicators (IOCs)
```graphql
{indicators(first:20 orderBy:created_at orderMode:desc){edges{node{name pattern indicator_types valid_from created_at createdBy{name}}}}}
```

### Vulnerabilities by CVSS
```graphql
{vulnerabilities(first:10 orderBy:x_opencti_cvss_base_score orderMode:desc){edges{node{name description x_opencti_cvss_base_score created}}}}
```

### Malware Families
```graphql
{malwares(first:10 orderBy:created_at orderMode:desc){edges{node{name description is_family created_at}}}}
```

### Attack Patterns (MITRE ATT&CK)
```graphql
{attackPatterns(first:10 orderBy:created_at orderMode:desc){edges{node{name x_mitre_id description}}}}
```

### Platform Stats
```graphql
{stixCoreObjectsNumber{total count}}
```

## Data Sources
- **Connector feeds:** CISA KEV, MITRE ATT&CK, EPSS, CVE/NVD, ThreatFox, URLhaus, AlienVault OTX, Malware Bazaar
- **Built-in RSS:** 18 security news feeds (Krebs, BleepingComputer, The Record, Unit 42, Securelist, etc.)
- All data normalized to STIX 2.1 with relationships and enrichment
