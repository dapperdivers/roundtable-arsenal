---
name: threat-intel-api
description: Automated RSS feed monitoring and threat intelligence API integration. Polls security feeds, queries NVD/CISA KEV APIs, and enriches IOCs with multi-source context. Use for real-time threat detection and intelligence gathering.
allowed-tools: Bash(curl:*,wget:*) Read Write
metadata:
  author: roundtable
  version: "1.0"
  tier: security
  compatibility: Requires internet access, curl, jq. Optional feedparser for Python-based RSS parsing.
  knight: kay
---

# Threat Intelligence API Integration

Automates RSS feed monitoring and integrates with public threat intelligence APIs for real-time security intelligence gathering.

## When to Use

- **Automated monitoring**: Continuous polling of security RSS feeds for new threats
- **CVE research**: Query National Vulnerability Database for detailed CVE information
- **KEV tracking**: Check CISA Known Exploited Vulnerabilities catalog
- **IOC enrichment**: Gather context about IPs, domains, hashes from multiple sources
- **Real-time intelligence**: Leverage Kay's internet access for fresh threat data

## Workflow

### RSS Feed Monitoring
1. **Poll** — Check configured RSS feeds for new entries
2. **Parse** — Extract title, link, published date, description
3. **Filter** — Apply keyword filters and severity scoring
4. **Alert** — Notify on high-severity findings
5. **Store** — Cache processed entries to avoid duplicates

### API Integration
1. **Query** — Call NVD, CISA KEV, or other threat intel APIs
2. **Parse** — Extract relevant fields from JSON responses
3. **Enrich** — Combine data from multiple sources
4. **Format** — Output structured JSON or markdown reports

## Scripts

### Monitor RSS Feeds
```bash
bash scripts/monitor-feeds.sh [--interval 300] [--notify]
```

**Options:**
- `--interval <seconds>`: Polling interval (default: 300 = 5 minutes)
- `--notify`: Send notifications on new high-severity entries
- `--daemon`: Run as background daemon
- `--once`: Poll once and exit (for cron jobs)

**Exit codes:**
- 0: Success, no new entries
- 1: Error (network, parsing, etc.)
- 2: New high-severity entries found (with --notify)

**Example:**
```bash
# Poll every 5 minutes in daemon mode
bash scripts/monitor-feeds.sh --interval 300 --daemon --notify

# One-shot poll for cron
bash scripts/monitor-feeds.sh --once
```

### Query NVD API
```bash
bash scripts/query-nvd.sh <CVE-ID> [--output json]
```

**Arguments:**
- `<CVE-ID>`: CVE identifier (e.g., CVE-2024-1234)

**Options:**
- `--output <format>`: json|summary (default: summary)
- `--verbose`: Include full CPE and reference data

**Example:**
```bash
# Get summary of CVE-2024-21626
bash scripts/query-nvd.sh CVE-2024-21626

# Full JSON output
bash scripts/query-nvd.sh CVE-2024-21626 --output json --verbose
```

**Output (summary format):**
```
CVE-2024-21626: runc process.cwd and leaked fds container breakout
CVSS 3.1 Score: 8.6 (HIGH)
Vector: CVSS:3.1/AV:L/AC:L/PR:N/UI:R/S:C/C:H/I:H/A:H
Published: 2024-01-31
Description: runc through 1.1.11 allows container escape via file descriptor leak...
References:
  - https://github.com/opencontainers/runc/security/advisories/GHSA-xr7r-f8xq-vfvv
  - https://nvd.nist.gov/vuln/detail/CVE-2024-21626
```

### Query CISA KEV
```bash
bash scripts/query-kev.sh [<CVE-ID>] [--format json]
```

**Arguments:**
- `<CVE-ID>`: Optional - check if specific CVE is in KEV catalog

**Options:**
- `--format <type>`: json|table|summary (default: summary)
- `--recent <days>`: Show KEV entries added in last N days
- `--vendor <name>`: Filter by vendor

**Example:**
```bash
# Check if CVE is in KEV
bash scripts/query-kev.sh CVE-2024-21626

# Get all KEV entries from last 7 days
bash scripts/query-kev.sh --recent 7 --format table

# Get Microsoft CVEs in KEV
bash scripts/query-kev.sh --vendor Microsoft --format json
```

**Output:**
```
CVE-2024-21626: IN KEV CATALOG ⚠️
Vendor: Linux
Product: runc
Added to KEV: 2024-02-01
Due Date: 2024-02-22
Required Action: Apply mitigations per vendor instructions or discontinue use
Known Ransomware: No
Notes: runc container escape vulnerability actively exploited
```

### Enrich IOC
```bash
bash scripts/enrich-ioc.sh <IOC> [--type auto] [--sources all]
```

**Arguments:**
- `<IOC>`: IP address, domain, URL, or file hash

**Options:**
- `--type <t>`: auto|ip|domain|url|hash (default: auto-detect)
- `--sources <s>`: all|whois|dns|geolocation|reputation (default: all)
- `--output <format>`: json|summary (default: summary)

**Example:**
```bash
# Enrich IP address
bash scripts/enrich-ioc.sh 192.0.2.1

# Enrich domain with specific sources
bash scripts/enrich-ioc.sh example.com --type domain --sources whois,dns

# Enrich hash (SHA256)
bash scripts/enrich-ioc.sh a1b2c3d4... --type hash --output json
```

**Output (IP enrichment):**
```
IOC: 192.0.2.1
Type: IPv4 Address

WHOIS:
  Organization: Example ISP
  Country: US
  Network: 192.0.2.0/24
  Abuse Contact: abuse@example.com

Geolocation:
  City: San Francisco
  Region: California
  Country: United States
  Coordinates: 37.7749, -122.4194

DNS:
  Reverse DNS: example.com
  ASN: AS15169 (Google LLC)

Reputation:
  VirusTotal: 0/90 detections (clean)
  AbuseIPDB: Confidence 0% (clean)
  Shodan: 3 open ports (22, 80, 443)
```

## Configuration

### Feed Configuration
Edit `references/FEEDS.md` to add/modify RSS feeds. See [references/FEEDS.md](references/FEEDS.md) for the current list and format.

### API Rate Limits

| API | Rate Limit | Key Required | Notes |
|-----|-----------|--------------|-------|
| NVD | 5 req/30s (no key), 50 req/30s (with key) | Optional | Get key at https://nvd.nist.gov/developers/request-an-api-key |
| CISA KEV | No limit | No | Public JSON feed |
| VirusTotal | 4 req/min (free), 1000 req/day | Yes | Register at https://www.virustotal.com/gui/join-us |
| AbuseIPDB | 1000 req/day | Yes | Get key at https://www.abuseipdb.com/account/api |

**Setting API Keys:**
```bash
export NVD_API_KEY="your-nvd-api-key"
export VT_API_KEY="your-virustotal-api-key"
export ABUSEIPDB_KEY="your-abuseipdb-key"
```

Scripts will use API keys if set, otherwise fall back to public/unauthenticated access where possible.

## Error Handling

All scripts implement comprehensive error handling:

### Network Errors
- **Timeout**: 30-second timeout for all API calls
- **Retry**: Automatic retry (max 3 attempts) with exponential backoff
- **Offline**: Graceful degradation when APIs unavailable

### Rate Limiting
- **Detection**: Parse `429 Too Many Requests` and `Retry-After` headers
- **Backoff**: Wait specified time before retrying
- **Caching**: Cache API responses to minimize repeated queries

### Data Validation
- **Schema**: Validate JSON responses against expected structure
- **Sanitization**: Sanitize user input to prevent injection attacks
- **Fallback**: Provide partial results if some sources fail

**Example error output:**
```
ERROR: NVD API rate limit exceeded (429 Too Many Requests)
INFO: Waiting 30 seconds before retry (Retry-After header)
WARNING: VirusTotal lookup failed (API key required)
INFO: Continuing with available data from 2/3 sources
```

## Edge Cases

### CVE Format Validation
- Validates CVE-YYYY-NNNNN format (e.g., CVE-2024-1234)
- Handles both uppercase and lowercase input
- Rejects malformed CVE IDs with clear error message

### IOC Type Detection
- Auto-detects IPv4, IPv6, domain, URL, MD5, SHA1, SHA256
- Handles edge cases: localhost, private IPs, internationalized domains
- Falls back to manual `--type` specification if auto-detect fails

### Feed Parsing
- Handles both RSS 2.0 and Atom formats
- Gracefully handles malformed XML
- Supports feeds with non-standard date formats
- Detects and reports duplicate entries across feeds

### Stale Data
- Caches API responses with TTL (default: 24 hours for NVD, 1 hour for KEV)
- Warns when using cached data older than TTL
- Force refresh with `--no-cache` flag

## Monitoring & Alerting

### RSS Monitor Daemon
When running in daemon mode (`--daemon`), the monitor:

1. **Polls feeds** at specified interval
2. **Logs activity** to `/tmp/threat-intel-api-monitor.log`
3. **Tracks state** in `/tmp/threat-intel-api-state.json`
4. **Sends alerts** via configured notification method

**State tracking:**
```json
{
  "last_poll": "2026-03-14T18:30:00Z",
  "feeds_checked": 18,
  "new_entries": 5,
  "high_severity": 2,
  "last_error": null
}
```

### Notification Methods

The monitor supports multiple notification backends:

**1. File Output**
```bash
# Append new entries to file
export NOTIFY_METHOD="file"
export NOTIFY_FILE="/tmp/threat-alerts.txt"
```

**2. NATS Publish** (if available)
```bash
export NOTIFY_METHOD="nats"
export NATS_URL="nats://nats.database.svc:4222"
export NATS_SUBJECT="alerts.security.threats"
```

**3. Webhook**
```bash
export NOTIFY_METHOD="webhook"
export WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

**4. Standard Output** (default)
```bash
export NOTIFY_METHOD="stdout"
```

## Integration Examples

### Daily Threat Briefing
```bash
#!/bin/bash
# Collect threat intel for daily briefing

echo "## CVEs from KEV (Last 24h)"
bash scripts/query-kev.sh --recent 1 --format table

echo ""
echo "## High-Severity RSS Findings"
bash scripts/monitor-feeds.sh --once | grep -i "HIGH\|CRITICAL"

echo ""
echo "## Specific CVE Deep Dive"
bash scripts/query-nvd.sh CVE-2024-21626 --output summary
```

### Automated IOC Enrichment Pipeline
```bash
#!/bin/bash
# Enrich IOCs from input file

while read -r ioc; do
  echo "Enriching: $ioc"
  bash scripts/enrich-ioc.sh "$ioc" --output json >> enriched-iocs.json
  sleep 2  # Respect rate limits
done < ioc-list.txt
```

### Continuous Monitoring
```bash
# Start RSS monitor as systemd service
# See assets/threat-intel-monitor.service for service file

sudo systemctl start threat-intel-monitor
sudo systemctl enable threat-intel-monitor

# Check logs
journalctl -u threat-intel-monitor -f
```

## Output Formats

### JSON
Machine-readable structured output:
```json
{
  "cve_id": "CVE-2024-21626",
  "cvss_score": 8.6,
  "severity": "HIGH",
  "published": "2024-01-31T00:00:00Z",
  "description": "runc container escape...",
  "references": [...]
}
```

### Summary
Human-readable text format (shown in examples above)

### Table
Tabular format for multiple results:
```
CVE ID          | CVSS | Severity | Vendor    | Product | Added
----------------|------|----------|-----------|---------|------------
CVE-2024-21626  | 8.6  | HIGH     | Linux     | runc    | 2024-02-01
CVE-2024-3177   | 8.1  | HIGH     | Kubernetes| API     | 2024-03-10
```

## Performance Optimization

### Caching Strategy
- **NVD queries**: Cache for 24 hours (CVE data rarely changes)
- **KEV queries**: Cache for 1 hour (updated daily)
- **RSS feeds**: Cache for 5 minutes (balance freshness vs load)
- **IOC enrichment**: Cache for 6 hours (reputation can change)

**Cache location:** `/tmp/threat-intel-api-cache/`

**Clear cache:**
```bash
rm -rf /tmp/threat-intel-api-cache/
```

### Parallel Processing
For bulk operations, use GNU parallel:
```bash
# Enrich 100 IOCs in parallel (4 concurrent)
cat ioc-list.txt | parallel -j 4 bash scripts/enrich-ioc.sh {}
```

### Batch API Calls
When available, use batch APIs:
```bash
# Query multiple CVEs in one NVD API call
bash scripts/query-nvd.sh --batch CVE-2024-1,CVE-2024-2,CVE-2024-3
```

## Dependencies

### Required
- `curl` or `wget` - HTTP requests
- `jq` - JSON parsing
- `bash` 4.0+ - Script runtime

### Optional
- `python3` with `feedparser` - Better RSS parsing (falls back to curl + grep)
- `xmllint` - XML validation and parsing
- `parallel` - Parallel processing for bulk operations
- `systemd` - Daemon management

**Install dependencies:**
```bash
# Debian/Ubuntu
apt-get install curl jq xmlstarlet

# RHEL/CentOS
yum install curl jq libxml2

# Python dependencies (optional)
pip3 install feedparser requests
```

## Troubleshooting

### "API key required" errors
**Problem:** Some sources require API keys for full functionality

**Solution:** Register for free API keys and set environment variables:
```bash
export NVD_API_KEY="your-key"
export VT_API_KEY="your-key"
export ABUSEIPDB_KEY="your-key"
```

### RSS feed timeouts
**Problem:** Some feeds are slow or unreliable

**Solution:** Adjust timeout and retry settings:
```bash
# Increase timeout to 60 seconds
export HTTP_TIMEOUT=60

# Skip slow feeds
bash scripts/monitor-feeds.sh --skip-slow
```

### Cache issues
**Problem:** Stale cached data being returned

**Solution:** Clear cache or disable caching:
```bash
# Clear all cached data
rm -rf /tmp/threat-intel-api-cache/

# Disable caching for this run
bash scripts/query-nvd.sh CVE-2024-1234 --no-cache
```

### High memory usage in daemon mode
**Problem:** Long-running daemon accumulates memory

**Solution:** Restart daemon periodically via cron:
```cron
# Restart threat-intel monitor daily at 3am
0 3 * * * systemctl restart threat-intel-monitor
```

## Security Considerations

### API Key Protection
- Never commit API keys to git repositories
- Use environment variables or secret management systems
- Rotate keys periodically (every 90 days recommended)

### Input Validation
- All user input is sanitized before passing to APIs
- CVE IDs validated against regex: `^CVE-\d{4}-\d{4,}$`
- URLs validated and unsafe characters escaped

### Network Security
- All API calls use HTTPS
- SSL/TLS certificate validation enabled by default
- Option to use proxy: `export HTTPS_PROXY=http://proxy:8080`

### Data Privacy
- Cached data may contain sensitive threat information
- Secure cache directory permissions: `chmod 700 /tmp/threat-intel-api-cache/`
- Clear cache after sensitive operations

## Advanced Usage

See [references/ADVANCED.md](references/ADVANCED.md) for:
- Custom RSS feed parsers
- Multi-source correlation rules
- Advanced filtering and alerting logic
- Integration with SIEM platforms
- Custom API source integration
