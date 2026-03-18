---
name: ioc-distributor
description: Distribute IOCs to security tools in actionable formats (CSV, STIX, Suricata, YARA). Export from OpenCTI and push to configured endpoints.
allowed-tools: Bash(curl:*,jq:*) Read Write
metadata:
  author: roundtable
  version: "1.0"
  tier: security
  compatibility: Requires OPENCTI_TOKEN for IOC export
---

# IOC Distributor

Exports Indicators of Compromise (IOCs) from threat intelligence platforms and distributes them to security tools in multiple formats.

## Purpose

Security tools require IOCs in different formats:
- **SIEM/SOAR:** CSV, JSON, STIX 2.1
- **IDS/IPS:** Suricata rules, Snort rules
- **Endpoint:** YARA rules, Sigma rules
- **Firewalls:** IP lists, domain blocklists

This skill automates IOC export, format conversion, and distribution to configured endpoints.

## Features

- **Multi-format export:** CSV, JSON, STIX 2.1, Suricata, YARA
- **Source aggregation:** OpenCTI, MISP, local files
- **Automated distribution:** Syslog, webhook, SFTP, file
- **Deduplication:** Remove duplicate IOCs across sources
- **Scoring:** Confidence and relevance scoring
- **Expiration:** TTL management for time-sensitive IOCs

## Usage

### Export IOCs from OpenCTI

```bash
# Export all IOCs from last 7 days
./scripts/export-iocs.sh --source opencti --days 7 --format csv

# Export specific IOC types
./scripts/export-iocs.sh --source opencti --types "ipv4-addr,domain-name" --format stix

# Export as Suricata rules
./scripts/export-iocs.sh --source opencti --format suricata --output /tmp/opencti.rules
```

### Distribute to Endpoints

```bash
# Distribute to all configured endpoints
./scripts/distribute.sh --input /tmp/iocs.csv --all

# Push to specific endpoint
./scripts/distribute.sh --input /tmp/iocs.json --endpoint siem-webhook

# Test distribution (dry run)
./scripts/distribute.sh --input /tmp/iocs.csv --dry-run
```

### Full Pipeline

```bash
# Export from OpenCTI → Convert to Suricata → Push to IDS
./scripts/export-iocs.sh --source opencti --days 1 --format suricata --output /tmp/daily.rules
./scripts/distribute.sh --input /tmp/daily.rules --endpoint suricata-ids
```

## Configuration

Create `config.env`:

```bash
# OpenCTI Configuration
OPENCTI_URL="https://opencti.domain.com"
OPENCTI_TOKEN="your-token-here"

# Distribution Endpoints
SYSLOG_SERVER="192.168.1.100:514"
SIEM_WEBHOOK="https://siem.domain.com/api/iocs"
SIEM_WEBHOOK_TOKEN="Bearer xyz123"
SURICATA_SFTP="user@ids.domain.com:/etc/suricata/rules/"
SURICATA_SSH_KEY="/path/to/key"

# Export Settings
DEFAULT_DAYS=7
DEFAULT_CONFIDENCE=70
IOC_TTL_DAYS=30
```

## File Structure

```
ioc-distributor/
├── SKILL.md                    # This file
├── scripts/
│   ├── export-iocs.sh          # Export IOCs from sources
│   ├── distribute.sh           # Push IOCs to endpoints
│   ├── convert-format.sh       # Format conversion utilities
│   └── validate-iocs.sh        # IOC validation/scoring
├── references/
│   ├── FORMATS.md              # Output format documentation
│   └── ENDPOINTS.md            # Endpoint configuration guide
└── examples/
    ├── config.env.example      # Example configuration
    └── cron-daily.sh           # Daily automation example
```

## Integration

### OpenCTI

Requires API token with read access to indicators. Set `OPENCTI_TOKEN` environment variable.

### SIEM Integration

- **Splunk:** Push CSV via HEC webhook
- **Elastic:** Push JSON via bulk API
- **Sentinel:** Push STIX via Threat Intelligence connector

### IDS/IPS Integration

- **Suricata:** Generate rules, push via SFTP, reload rules
- **Snort:** Convert to Snort rule format
- **Zeek:** Generate Intel Framework format

## Dependencies

- `curl` — API requests
- `jq` — JSON processing
- `xmlstarlet` — STIX XML processing (optional)
- `ssh`/`scp` — SFTP distribution
- OpenCTI Python client (optional, for advanced queries)

## Example Workflow

```bash
# Morning: Export high-confidence IOCs from OpenCTI
./scripts/export-iocs.sh \
  --source opencti \
  --days 1 \
  --confidence 80 \
  --format csv \
  --output /tmp/daily-iocs.csv

# Convert to multiple formats
./scripts/convert-format.sh /tmp/daily-iocs.csv --to stix --output /tmp/iocs.stix
./scripts/convert-format.sh /tmp/daily-iocs.csv --to suricata --output /tmp/iocs.rules

# Distribute to all systems
./scripts/distribute.sh --input /tmp/daily-iocs.csv --endpoint siem-webhook
./scripts/distribute.sh --input /tmp/iocs.rules --endpoint suricata-ids
./scripts/distribute.sh --input /tmp/iocs.stix --endpoint misp-instance
```

## Security Considerations

- **API tokens:** Store in environment variables, never commit to git
- **Validation:** Validate IOCs before distribution to prevent false positives
- **Rate limiting:** Respect API rate limits for OpenCTI/external sources
- **Logging:** Log all distributions for audit trail
- **Encryption:** Use HTTPS/TLS for webhook endpoints, SSH for SFTP

## Troubleshooting

**OpenCTI connection fails:**
```bash
# Test connectivity
curl -H "Authorization: Bearer $OPENCTI_TOKEN" $OPENCTI_URL/graphql

# Check token permissions
./scripts/export-iocs.sh --source opencti --test
```

**Distribution fails:**
```bash
# Dry run to test endpoints
./scripts/distribute.sh --input /tmp/iocs.csv --dry-run --verbose

# Check endpoint configuration
grep SIEM_WEBHOOK config.env
```

**Invalid IOC format:**
```bash
# Validate before distribution
./scripts/validate-iocs.sh --input /tmp/iocs.csv --strict
```
