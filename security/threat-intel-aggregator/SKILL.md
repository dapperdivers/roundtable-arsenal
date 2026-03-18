---
name: threat-intel-aggregator
description: Automated threat intelligence aggregation from RSS feeds, NVD API, CISA KEV, and OpenCTI. Correlate findings, deduplicate, and generate daily digests.
allowed-tools: Bash(curl:*,jq:*) Read Write
metadata:
  author: roundtable
  version: "1.0"
  tier: security
  compatibility: Requires network access to threat intel sources
---

# Threat Intelligence Aggregator

Automated collection, correlation, and synthesis of threat intelligence from multiple public and private sources.

## Purpose

Security teams need to monitor dozens of threat intelligence sources:
- **CVE databases:** NVD, CVE.org
- **Government feeds:** CISA KEV, US-CERT, NCSC
- **Vendor advisories:** Microsoft, Google, AWS, Kubernetes
- **Threat intel platforms:** OpenCTI, MISP
- **RSS feeds:** Security blogs, researcher Twitter/Mastodon

This skill automates aggregation, correlation, deduplication, and scoring to produce actionable daily digests.

## Features

- **Multi-source aggregation:** RSS, APIs, OpenCTI, CISA KEV
- **Smart correlation:** Link CVEs to threat actors, campaigns, IOCs
- **Relevance scoring:** Stack-specific prioritization
- **Deduplication:** Merge duplicate findings across sources
- **Daily digest:** Automated morning briefing generation
- **Alert triggering:** High-confidence threats trigger immediate alerts

## Usage

### Aggregate All Sources

```bash
# Pull from all configured sources
./scripts/aggregate.sh --all --output /tmp/intel.json

# Pull specific sources
./scripts/aggregate.sh --sources "cisa-kev,nvd,rss-feeds" --days 1
```

### Correlate Findings

```bash
# Cross-reference CVEs with threat actors and IOCs
./scripts/correlate.sh --input /tmp/intel.json --output /tmp/correlated.json

# Score relevance to tracked infrastructure
./scripts/correlate.sh --input /tmp/intel.json --stack-file config/stack.yaml --score
```

### Generate Daily Digest

```bash
# Full automation: aggregate → correlate → digest
./scripts/daily-digest.sh --email security@domain.com

# Generate digest only (no email)
./scripts/daily-digest.sh --output /tmp/digest.md
```

## Configuration

Create `config/sources.yaml`:

```yaml
sources:
  cisa_kev:
    enabled: true
    url: "https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json"
    priority: critical
  
  nvd_api:
    enabled: true
    url: "https://services.nvd.nist.gov/rest/json/cves/2.0"
    api_key: "${NVD_API_KEY}"  # Optional, increases rate limit
    priority: high
  
  opencti:
    enabled: true
    url: "${OPENCTI_URL}"
    token: "${OPENCTI_TOKEN}"
    priority: high
  
  rss_feeds:
    enabled: true
    feeds:
      - name: "Krebs on Security"
        url: "https://krebsonsecurity.com/feed/"
        priority: medium
      - name: "Schneier on Security"
        url: "https://www.schneier.com/blog/atom.xml"
        priority: medium
      - name: "Talos Intelligence"
        url: "https://blog.talosintelligence.com/rss/"
        priority: high

tracked_stack:
  - kubernetes
  - talos
  - cilium
  - flux
  - nats
  - rabbitmq
  - opensearch
  - minio
  - home-assistant
  - nginx
  - cert-manager
  - linux-kernel
  - golang
  - nodejs
  - python
```

## File Structure

```
threat-intel-aggregator/
├── SKILL.md                    # This file
├── config/
│   ├── sources.yaml            # Intel source configuration
│   └── stack.yaml              # Tracked infrastructure
├── scripts/
│   ├── aggregate.sh            # Pull from all sources
│   ├── correlate.sh            # Cross-reference findings
│   ├── daily-digest.sh         # Generate daily briefing
│   └── fetch-source.sh         # Individual source fetchers
├── data/
│   ├── intel/                  # Raw intel data (timestamped)
│   ├── correlated/             # Correlated findings
│   └── digests/                # Generated digests
├── references/
│   ├── SOURCES.md              # Source documentation
│   └── CORRELATION.md          # Correlation logic
└── examples/
    ├── cron-daily.sh           # Cron automation
    └── alert-webhook.sh        # Alert integration
```

## Aggregation Process

### 1. Fetch from Sources

```bash
# CISA KEV (Known Exploited Vulnerabilities)
curl -s "https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json" | \
  jq '.vulnerabilities[] | select(.dateAdded >= "2026-03-10")'

# NVD API (Recent CVEs)
curl -s "https://services.nvd.nist.gov/rest/json/cves/2.0?pubStartDate=2026-03-10T00:00:00.000" | \
  jq '.vulnerabilities[]'

# OpenCTI (Indicators + Reports)
curl -s -H "Authorization: Bearer $OPENCTI_TOKEN" \
  -d '{"query": "{ indicators { edges { node { pattern confidence } } } }"}' \
  "$OPENCTI_URL/graphql"

# RSS Feeds
curl -s "https://krebsonsecurity.com/feed/" | xmllint --xpath '//item' -
```

### 2. Normalize Data

All sources normalized to common schema:

```json
{
  "id": "unique-id",
  "type": "cve|ioc|report|advisory",
  "source": "cisa-kev|nvd|opencti|rss",
  "timestamp": "2026-03-17T12:00:00Z",
  "title": "CVE-2026-3910: Chrome V8 RCE",
  "description": "...",
  "severity": "critical|high|medium|low",
  "confidence": 85,
  "references": ["https://..."],
  "tags": ["browser", "rce", "zero-day"],
  "indicators": {
    "cves": ["CVE-2026-3910"],
    "threat_actors": ["APT41"],
    "iocs": ["192.0.2.1", "evil.com"]
  }
}
```

### 3. Correlate Findings

Cross-reference across sources:
- **CVE → Threat Actor:** Link CVEs to known APT campaigns
- **CVE → IOCs:** Associate exploited CVEs with observed indicators
- **Threat Actor → TTPs:** Map actors to MITRE ATT&CK techniques
- **IOC → Infrastructure:** Track attacker infrastructure changes

### 4. Score Relevance

Stack-specific scoring:
- **Critical (90-100):** Actively exploited, affects your stack
- **High (70-89):** PoC available, broad impact
- **Medium (40-69):** Theoretical risk, limited exposure
- **Low (0-39):** Informational, no direct impact

### 5. Generate Digest

Daily briefing structure:
1. **Executive Summary** (2-3 sentences)
2. **Critical Items** (action required today)
3. **High Priority** (monitor/investigate)
4. **Notable Mentions** (awareness)
5. **Detection Opportunities** (Sigma rules, hunt queries)
6. **MITRE ATT&CK Coverage**

## Integration

### OpenCTI

Requires API token with read access. Pulls:
- Indicators (last 24 hours)
- Reports (published recently)
- Threat actors (active campaigns)
- Malware (new families)

### SIEM

Push digest to SIEM for enrichment:
```bash
# Splunk HEC
curl -X POST "$SPLUNK_HEC_URL/services/collector/event" \
  -H "Authorization: Splunk $SPLUNK_TOKEN" \
  -d @/tmp/digest.json

# Elastic
curl -X POST "$ELASTIC_URL/threat-intel/_doc" \
  -H "Content-Type: application/json" \
  -d @/tmp/digest.json
```

### Email/Slack

Daily digest delivery:
```bash
# Email
./scripts/daily-digest.sh --email security@domain.com

# Slack
./scripts/daily-digest.sh --slack-webhook "$SLACK_WEBHOOK"

# Both
./scripts/daily-digest.sh --email security@domain.com --slack-webhook "$SLACK_WEBHOOK"
```

## Automation

### Cron Schedule

```bash
# Daily at 06:00 - Morning briefing
0 6 * * * /path/to/scripts/daily-digest.sh --email security@domain.com

# Every 4 hours - Critical alerts only
0 */4 * * * /path/to/scripts/aggregate.sh --critical-only --alert

# Weekly Sunday 08:00 - Weekly summary
0 8 * * 0 /path/to/scripts/weekly-summary.sh --email security-all@domain.com
```

### systemd Timer

```ini
# /etc/systemd/system/threat-intel-daily.timer
[Unit]
Description=Daily Threat Intelligence Aggregation

[Timer]
OnCalendar=daily
OnCalendar=06:00
Persistent=true

[Install]
WantedBy=timers.target
```

## Dependencies

- `curl` — HTTP requests
- `jq` — JSON processing
- `xmllint` (libxml2) — RSS/XML parsing
- `yq` (optional) — YAML parsing
- `mail` or `sendmail` (optional) — Email delivery

## Example Workflow

```bash
# Morning routine (automated)
cd /path/to/threat-intel-aggregator

# 1. Aggregate from all sources
./scripts/aggregate.sh --all --days 1 --output data/intel/$(date +%Y%m%d).json

# 2. Correlate findings
./scripts/correlate.sh \
  --input data/intel/$(date +%Y%m%d).json \
  --stack-file config/stack.yaml \
  --output data/correlated/$(date +%Y%m%d).json

# 3. Generate daily digest
./scripts/daily-digest.sh \
  --input data/correlated/$(date +%Y%m%d).json \
  --output data/digests/$(date +%Y%m%d).md \
  --email security@domain.com

# 4. Check for critical alerts
if grep -q "CRITICAL" data/digests/$(date +%Y%m%d).md; then
  ./examples/alert-webhook.sh data/digests/$(date +%Y%m%d).md
fi
```

## Correlation Examples

### CVE → Threat Actor

```json
{
  "cve": "CVE-2026-3910",
  "threat_actors": [
    {
      "name": "APT41",
      "confidence": 80,
      "source": "opencti",
      "campaign": "Chrome Zero-Day Campaign Q1 2026"
    }
  ]
}
```

### CVE → IOCs

```json
{
  "cve": "CVE-2025-68613",
  "iocs": [
    {
      "type": "ipv4-addr",
      "value": "192.0.2.1",
      "role": "c2-server",
      "confidence": 90,
      "first_seen": "2026-03-10"
    },
    {
      "type": "domain-name",
      "value": "malicious-n8n.com",
      "role": "exploit-hosting",
      "confidence": 85,
      "first_seen": "2026-03-12"
    }
  ]
}
```

## Security Considerations

- **API keys:** Store in environment variables, never commit
- **Rate limiting:** Respect API limits (NVD: 5 req/30s without key, 50 req/30s with key)
- **Data retention:** Purge raw intel older than 90 days
- **Access control:** Restrict digest distribution (may contain sensitive intel)
- **Logging:** Log all aggregation runs for audit

## Troubleshooting

**NVD API rate limited:**
```bash
# Get API key from https://nvd.nist.gov/developers/request-an-api-key
export NVD_API_KEY="your-key-here"

# Test rate limit
curl -H "apiKey: $NVD_API_KEY" \
  "https://services.nvd.nist.gov/rest/json/cves/2.0?resultsPerPage=1"
```

**OpenCTI connection fails:**
```bash
# Test GraphQL endpoint
curl -H "Authorization: Bearer $OPENCTI_TOKEN" \
  -d '{"query": "{ about { version } }"}' \
  "$OPENCTI_URL/graphql"
```

**RSS feed parse error:**
```bash
# Test XML parsing
curl -s "https://feed-url.com/rss" | xmllint --format - | head -20
```

## References

- **CISA KEV:** https://www.cisa.gov/known-exploited-vulnerabilities-catalog
- **NVD API:** https://nvd.nist.gov/developers
- **OpenCTI API:** https://docs.opencti.io/latest/deployment/integrations/
- **STIX 2.1:** https://docs.oasis-open.org/cti/stix/v2.1/
