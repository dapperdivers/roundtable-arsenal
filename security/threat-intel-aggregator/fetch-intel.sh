#!/usr/bin/env bash
# Threat Intel Aggregator — Fetch Script
# Fetches from free public threat intel feeds (no API keys needed)
# Output: /data/threat-intel-latest.json

set -euo pipefail

OUTPUT_DIR="/data"
OUTPUT_FILE="${OUTPUT_DIR}/threat-intel-latest.json"
TIMEOUT=30
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$OUTPUT_DIR"

fetch() {
  local url="$1"
  local method="${2:-GET}"
  local data="${3:-}"
  local args=(-s -f --max-time "$TIMEOUT" -H "Accept: application/json")

  if [[ "$method" == "POST" ]]; then
    args+=(-X POST -H "Content-Type: application/json" -d "$data")
  fi

  curl "${args[@]}" "$url" 2>/dev/null || echo '{"error":"fetch_failed"}'
}

echo "[$TIMESTAMP] Fetching threat intel..." >&2

# 1. CISA KEV
echo "  → CISA KEV..." >&2
CISA_RAW=$(fetch "https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json")
CISA_KEV=$(echo "$CISA_RAW" | jq -c '[.vulnerabilities[-20:] // [] | .[] | {cveID, vendorProject, product, vulnerabilityName, dateAdded, dueDate, shortDescription}]' 2>/dev/null || echo '[]')

# 2. NVD Recent CVEs
echo "  → NVD recent CVEs..." >&2
NVD_RAW=$(fetch "https://services.nvd.nist.gov/rest/json/cves/2.0?resultsPerPage=20")
RECENT_CVES=$(echo "$NVD_RAW" | jq -c '[.vulnerabilities // [] | .[] | .cve | {id, description: (.descriptions[] | select(.lang=="en") | .value), cvss: ((.metrics.cvssMetricV31 // .metrics.cvssMetricV30 // [{}])[0].cvssData.baseScore // null), severity: ((.metrics.cvssMetricV31 // .metrics.cvssMetricV30 // [{}])[0].cvssData.baseSeverity // null), published}]' 2>/dev/null || echo '[]')

# 3. URLhaus Recent
echo "  → URLhaus recent URLs..." >&2
URLHAUS_RAW=$(fetch "https://urlhaus-api.abuse.ch/v1/urls/recent/" POST "")
MALICIOUS_URLS=$(echo "$URLHAUS_RAW" | jq -c '[.urls[:20] // [] | .[] | {url, url_status, threat, tags, date_added, reporter}]' 2>/dev/null || echo '[]')

# 4. ThreatFox IOCs
echo "  → ThreatFox IOCs..." >&2
THREATFOX_RAW=$(fetch "https://threatfox-api.abuse.ch/api/v1/" POST '{"query":"get_iocs","days":1}')
IOCS=$(echo "$THREATFOX_RAW" | jq -c '[if .data then .data[:20] | .[] | {ioc: .ioc, ioc_type: .ioc_type, threat_type: .threat_type, malware: .malware_printable, confidence_level: .confidence_level, first_seen: .first_seen_utc} else empty end] // []' 2>/dev/null || echo '[]')

# Assemble output
jq -n \
  --arg ts "$TIMESTAMP" \
  --argjson cisa_kev "$CISA_KEV" \
  --argjson recent_cves "$RECENT_CVES" \
  --argjson malicious_urls "$MALICIOUS_URLS" \
  --argjson iocs "$IOCS" \
  '{
    timestamp: $ts,
    sources: ["CISA KEV", "NVD", "URLhaus", "ThreatFox"],
    cisa_kev: $cisa_kev,
    recent_cves: $recent_cves,
    malicious_urls: $malicious_urls,
    iocs: $iocs
  }' > "$OUTPUT_FILE"

echo "[$TIMESTAMP] Saved to $OUTPUT_FILE" >&2
echo "  KEV: $(echo "$CISA_KEV" | jq 'length') | CVEs: $(echo "$RECENT_CVES" | jq 'length') | URLs: $(echo "$MALICIOUS_URLS" | jq 'length') | IOCs: $(echo "$IOCS" | jq 'length')" >&2
