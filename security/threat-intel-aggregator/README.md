# 🛡️ Threat Intel Aggregator

**Knight:** Galahad (Security)
**Purpose:** Aggregate freely available threat intelligence feeds into a unified briefing.

## Data Sources

All sources are **free, public, and require no API keys**:

| Source | Description | URL |
|--------|-------------|-----|
| **CISA KEV** | Known Exploited Vulnerabilities catalog | https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json |
| **NVD CVEs** | Recently published CVEs (last 20) | https://services.nvd.nist.gov/rest/json/cves/2.0 |
| **URLhaus** | Recently reported malicious URLs | https://urlhaus-api.abuse.ch/v1/urls/recent/ |
| **ThreatFox** | Recent IOCs (indicators of compromise) | https://threatfox-api.abuse.ch/api/v1/ |

## Usage

```bash
# Fetch latest threat intel → /data/threat-intel-latest.json
./fetch-intel.sh

# Generate a human-readable markdown briefing
./summarize-intel.sh
```

## Output

- `fetch-intel.sh` saves structured JSON to `/data/threat-intel-latest.json`
- `summarize-intel.sh` outputs a markdown briefing to stdout

## Notes

- No API keys required
- No PII collected or stored
- All feeds are publicly available
- Designed for automated morning briefings
