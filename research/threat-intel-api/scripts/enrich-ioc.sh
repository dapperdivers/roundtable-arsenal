#!/bin/bash
################################################################################
# IOC Enrichment Script
# Enriches indicators of compromise with context from multiple sources
#
# Usage: enrich-ioc.sh <IOC> [--type auto|ip|domain|hash] [--sources all]
# Exit codes: 0=success, 1=error
################################################################################

set -euo pipefail

# Configuration
HTTP_TIMEOUT="${HTTP_TIMEOUT:-30}"
CACHE_DIR="${CACHE_DIR:-/tmp/threat-intel-api-cache}"
CACHE_TTL="${CACHE_TTL:-21600}"  # 6 hours in seconds

# API keys (optional - will use free tier if not set)
VT_API_KEY="${VT_API_KEY:-}"
ABUSEIPDB_KEY="${ABUSEIPDB_KEY:-}"

# Default options
IOC=""
IOC_TYPE="auto"
SOURCES="all"
OUTPUT_FORMAT="summary"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --type)
      IOC_TYPE="$2"
      shift 2
      ;;
    --sources)
      SOURCES="$2"
      shift 2
      ;;
    --output)
      OUTPUT_FORMAT="$2"
      shift 2
      ;;
    --no-cache)
      CACHE_TTL=0
      shift
      ;;
    --help)
      echo "Usage: $0 <IOC> [--type TYPE] [--sources SOURCES] [--output FORMAT]"
      echo ""
      echo "Arguments:"
      echo "  IOC             IP address, domain, URL, or file hash"
      echo ""
      echo "Options:"
      echo "  --type TYPE     IOC type: auto|ip|domain|url|hash (default: auto)"
      echo "  --sources SRC   Sources: all|whois|dns|geo|reputation (default: all)"
      echo "  --output FMT    Output format: json|summary (default: summary)"
      echo "  --no-cache      Bypass cache and fetch fresh data"
      echo ""
      echo "Environment Variables:"
      echo "  VT_API_KEY      VirusTotal API key (optional)"
      echo "  ABUSEIPDB_KEY   AbuseIPDB API key (optional)"
      exit 0
      ;;
    -*)
      echo "Error: Unknown option: $1"
      exit 1
      ;;
    *)
      IOC="$1"
      shift
      ;;
  esac
done

# Validate IOC
if [[ -z "$IOC" ]]; then
  echo "Error: IOC required"
  echo "Usage: $0 <IOC> [options]"
  exit 1
fi

# Initialize cache directory
mkdir -p "$CACHE_DIR"

# Auto-detect IOC type
detect_ioc_type() {
  local ioc=$1
  
  # IPv4
  if echo "$ioc" | grep -qE '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
    echo "ipv4"
  # IPv6
  elif echo "$ioc" | grep -qE '^([0-9a-fA-F]{0,4}:){7}[0-9a-fA-F]{0,4}$'; then
    echo "ipv6"
  # MD5
  elif echo "$ioc" | grep -qE '^[a-fA-F0-9]{32}$'; then
    echo "md5"
  # SHA1
  elif echo "$ioc" | grep -qE '^[a-fA-F0-9]{40}$'; then
    echo "sha1"
  # SHA256
  elif echo "$ioc" | grep -qE '^[a-fA-F0-9]{64}$'; then
    echo "sha256"
  # URL
  elif echo "$ioc" | grep -qE '^https?://'; then
    echo "url"
  # Domain
  elif echo "$ioc" | grep -qE '^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$'; then
    echo "domain"
  else
    echo "unknown"
  fi
}

# Detect type if auto
if [[ "$IOC_TYPE" == "auto" ]]; then
  IOC_TYPE=$(detect_ioc_type "$IOC")
  if [[ "$IOC_TYPE" == "unknown" ]]; then
    echo "Error: Could not auto-detect IOC type for: $IOC"
    echo "Use --type to specify manually"
    exit 1
  fi
fi

# WHOIS lookup
whois_lookup() {
  local target=$1
  
  if ! command -v whois >/dev/null; then
    echo "  whois not installed" >&2
    return 1
  fi
  
  whois "$target" 2>/dev/null | grep -E "^(OrgName|Organization|Country|NetRange|abuse)" | head -10 || echo "  No WHOIS data"
}

# DNS lookup
dns_lookup() {
  local target=$1
  
  # A record
  a_record=$(dig +short A "$target" 2>/dev/null | head -1)
  
  # Reverse DNS if IP
  if [[ "$IOC_TYPE" =~ ^ipv[46]$ ]]; then
    rdns=$(dig +short -x "$target" 2>/dev/null | head -1)
  else
    rdns="N/A"
  fi
  
  # MX records for domains
  if [[ "$IOC_TYPE" == "domain" ]]; then
    mx_records=$(dig +short MX "$target" 2>/dev/null | head -3)
  else
    mx_records="N/A"
  fi
  
  cat <<EOF
  A Record: ${a_record:-N/A}
  Reverse DNS: ${rdns}
  MX Records: ${mx_records}
EOF
}

# Geolocation (using ip-api.com free API)
geo_lookup() {
  local ip=$1
  
  if [[ ! "$IOC_TYPE" =~ ^ipv[46]$ ]]; then
    echo "  Geolocation only available for IPs"
    return 0
  fi
  
  geo_data=$(curl -sSL --max-time 10 "http://ip-api.com/json/${ip}?fields=status,country,regionName,city,lat,lon,org,as" 2>/dev/null)
  
  if [[ -z "$geo_data" ]] || ! echo "$geo_data" | jq -e '.status == "success"' >/dev/null 2>&1; then
    echo "  Geolocation lookup failed"
    return 1
  fi
  
  city=$(echo "$geo_data" | jq -r '.city // "Unknown"')
  region=$(echo "$geo_data" | jq -r '.regionName // "Unknown"')
  country=$(echo "$geo_data" | jq -r '.country // "Unknown"')
  lat=$(echo "$geo_data" | jq -r '.lat // "N/A"')
  lon=$(echo "$geo_data" | jq -r '.lon // "N/A"')
  org=$(echo "$geo_data" | jq -r '.org // "Unknown"')
  asn=$(echo "$geo_data" | jq -r '.as // "Unknown"')
  
  cat <<EOF
  City: $city
  Region: $region
  Country: $country
  Coordinates: $lat, $lon
  Organization: $org
  ASN: $asn
EOF
}

# VirusTotal lookup
vt_lookup() {
  local target=$1
  
  if [[ -z "$VT_API_KEY" ]]; then
    echo "  VirusTotal: API key required (set VT_API_KEY)"
    return 0
  fi
  
  # Determine VT API endpoint based on type
  case "$IOC_TYPE" in
    ipv4|ipv6)
      vt_url="https://www.virustotal.com/api/v3/ip_addresses/${target}"
      ;;
    domain)
      vt_url="https://www.virustotal.com/api/v3/domains/${target}"
      ;;
    url)
      url_id=$(echo -n "$target" | base64 | tr '+/' '-_' | tr -d '=')
      vt_url="https://www.virustotal.com/api/v3/urls/${url_id}"
      ;;
    md5|sha1|sha256)
      vt_url="https://www.virustotal.com/api/v3/files/${target}"
      ;;
    *)
      echo "  VirusTotal: Unsupported IOC type"
      return 1
      ;;
  esac
  
  vt_data=$(curl -sSL --max-time "$HTTP_TIMEOUT" \
    -H "x-apikey: $VT_API_KEY" \
    "$vt_url" 2>/dev/null)
  
  if [[ -z "$vt_data" ]]; then
    echo "  VirusTotal: Lookup failed"
    return 1
  fi
  
  malicious=$(echo "$vt_data" | jq -r '.data.attributes.last_analysis_stats.malicious // 0')
  total=$(echo "$vt_data" | jq -r '.data.attributes.last_analysis_stats | add // 0')
  
  echo "  VirusTotal: $malicious/$total detections"
}

# AbuseIPDB lookup (IP only)
abuseipdb_lookup() {
  local ip=$1
  
  if [[ ! "$IOC_TYPE" =~ ^ipv[46]$ ]]; then
    return 0
  fi
  
  if [[ -z "$ABUSEIPDB_KEY" ]]; then
    echo "  AbuseIPDB: API key required (set ABUSEIPDB_KEY)"
    return 0
  fi
  
  abuse_data=$(curl -sSL --max-time "$HTTP_TIMEOUT" \
    -H "Key: $ABUSEIPDB_KEY" \
    -H "Accept: application/json" \
    "https://api.abuseipdb.com/api/v2/check?ipAddress=${ip}" 2>/dev/null)
  
  if [[ -z "$abuse_data" ]]; then
    echo "  AbuseIPDB: Lookup failed"
    return 1
  fi
  
  confidence=$(echo "$abuse_data" | jq -r '.data.abuseConfidenceScore // 0')
  reports=$(echo "$abuse_data" | jq -r '.data.totalReports // 0')
  
  echo "  AbuseIPDB: Confidence ${confidence}% ($reports reports)"
}

# Shodan lookup (IP only)
shodan_lookup() {
  local ip=$1
  
  if [[ ! "$IOC_TYPE" =~ ^ipv[46]$ ]]; then
    return 0
  fi
  
  # Use Shodan's free InternetDB API (no key required, limited data)
  shodan_data=$(curl -sSL --max-time 10 "https://internetdb.shodan.io/${ip}" 2>/dev/null)
  
  if [[ -z "$shodan_data" ]] || echo "$shodan_data" | jq -e '.error' >/dev/null 2>&1; then
    echo "  Shodan: No data available"
    return 0
  fi
  
  ports=$(echo "$shodan_data" | jq -r '.ports[]?' 2>/dev/null | tr '\n' ',' | sed 's/,$//')
  vulns=$(echo "$shodan_data" | jq -r '.vulns[]?' 2>/dev/null | tr '\n' ',' | sed 's/,$//')
  
  if [[ -n "$ports" ]]; then
    echo "  Shodan: Open ports [$ports]"
  fi
  if [[ -n "$vulns" ]]; then
    echo "  Shodan: Vulnerabilities [$vulns]"
  fi
}

# Main enrichment
echo "IOC: $IOC"
echo "Type: $IOC_TYPE"
echo ""

# Determine which sources to query
if [[ "$SOURCES" == "all" ]]; then
  sources_array=(whois dns geolocation reputation)
else
  IFS=',' read -ra sources_array <<< "$SOURCES"
fi

# Execute lookups
for source in "${sources_array[@]}"; do
  case "$source" in
    whois)
      echo "WHOIS:"
      whois_lookup "$IOC" || true
      echo ""
      ;;
    dns)
      echo "DNS:"
      dns_lookup "$IOC" || true
      echo ""
      ;;
    geo|geolocation)
      echo "Geolocation:"
      geo_lookup "$IOC" || true
      echo ""
      ;;
    reputation)
      echo "Reputation:"
      vt_lookup "$IOC" || true
      abuseipdb_lookup "$IOC" || true
      shodan_lookup "$IOC" || true
      echo ""
      ;;
  esac
done

exit 0
