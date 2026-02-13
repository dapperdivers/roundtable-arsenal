# OpenCTI GraphQL Query Reference

## Reports
```graphql
# Recent reports (RSS + connector ingested)
{reports(first:20 orderBy:created_at orderMode:desc){edges{node{name description created_at createdBy{name}}}}}

# Reports by source
{reports(first:10 filters:{mode:and,filters:[{key:"createdBy",values:["<creator_id>"]}]} orderBy:created_at orderMode:desc){edges{node{name created_at}}}}
```

## Indicators (IOCs)
```graphql
# Recent indicators
{indicators(first:20 orderBy:created_at orderMode:desc){edges{node{name pattern indicator_types valid_from created_at createdBy{name}}}}}

# Indicators by type
{indicators(first:20 filters:{mode:and,filters:[{key:"indicator_types",values:["IPv4-Addr"]}]}){edges{node{name pattern valid_from}}}}
```

## Vulnerabilities
```graphql
# By CVSS score (highest first)
{vulnerabilities(first:10 orderBy:x_opencti_cvss_base_score orderMode:desc){edges{node{name description x_opencti_cvss_base_score created}}}}

# Specific CVE
{vulnerabilities(filters:{mode:and,filters:[{key:"name",values:["CVE-2026-1234"]}]}){edges{node{name description x_opencti_cvss_base_score x_opencti_cvss_base_severity}}}}
```

## Malware
```graphql
# Recent malware families
{malwares(first:10 orderBy:created_at orderMode:desc){edges{node{name description is_family created_at}}}}
```

## Attack Patterns (MITRE ATT&CK)
```graphql
# Recent attack patterns
{attackPatterns(first:10 orderBy:created_at orderMode:desc){edges{node{name x_mitre_id description}}}}
```

## Threat Actors
```graphql
{threatActors(first:10 orderBy:created_at orderMode:desc){edges{node{name description threat_actor_types aliases}}}}
```

## Platform Stats
```graphql
# Total STIX objects
{stixCoreObjectsNumber{total count}}

# Platform version
{about{version}}
```

## Ingestion (RSS feeds)
```graphql
# List configured RSS feeds (6.9.x Connection type)
{ingestionRsss(first:50){edges{node{id name uri ingestion_running}}}}
```
