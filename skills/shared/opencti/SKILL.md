# OpenCTI Threat Intelligence Skill

Query the OpenCTI platform for threat intelligence data via GraphQL API.

## Environment

- `OPENCTI_URL` — OpenCTI API base URL (default: `http://opencti-server.security.svc:80`)
- `OPENCTI_TOKEN` — API token for authentication (required)

## Scripts

### opencti-query.sh
General-purpose GraphQL query runner.

```bash
# Raw GraphQL query
./scripts/opencti-query.sh '{ about { version } }'

# Query with variables
./scripts/opencti-query.sh '{ vulnerabilities(first: 5) { edges { node { name description } } } }'
```

### opencti-search.sh
Search across all entity types.

```bash
# Search for a CVE
./scripts/opencti-search.sh "CVE-2025-29927"

# Search for a threat actor
./scripts/opencti-search.sh "APT29"

# Search for malware
./scripts/opencti-search.sh "Cobalt Strike"
```

### opencti-vulns.sh
Query vulnerabilities with optional filters.

```bash
# Recent vulnerabilities (default: 10)
./scripts/opencti-vulns.sh

# Get more results
./scripts/opencti-vulns.sh 50

# Search specific CVE
./scripts/opencti-vulns.sh 10 "CVE-2025"
```

### opencti-indicators.sh
Query indicators of compromise (IOCs).

```bash
# Recent indicators
./scripts/opencti-indicators.sh

# Get more
./scripts/opencti-indicators.sh 50

# Filter by pattern type
./scripts/opencti-indicators.sh 20 "domain-name"
```

### opencti-threats.sh
Query threat actors, intrusion sets, and campaigns.

```bash
# All threat actors
./scripts/opencti-threats.sh actors

# Intrusion sets
./scripts/opencti-threats.sh intrusions

# Malware
./scripts/opencti-threats.sh malware

# Campaigns
./scripts/opencti-threats.sh campaigns
```

### opencti-stats.sh
Get platform statistics — entity counts, connector status.

```bash
./scripts/opencti-stats.sh
```

## Use Cases for Galahad

1. **Contextual vulnerability analysis** — Query CVEs, cross-reference with EPSS scores and CISA KEV status
2. **Threat actor profiling** — Look up APT groups, their TTPs (MITRE ATT&CK), and associated malware
3. **IOC enrichment** — Search indicators, get related context and relationships
4. **Detection engineering** — Use threat intel to generate KQL/Sigma rules targeted at active threats
5. **Briefing generation** — Pull latest threats and vulnerabilities for security briefings
