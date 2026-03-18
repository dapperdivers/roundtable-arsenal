#!/bin/bash
################################################################################
# NVD API Query Script
# Queries National Vulnerability Database for CVE details
#
# Usage: query-nvd.sh <CVE-ID> [--output json|summary] [--verbose]
# Exit codes: 0=success, 1=error, 2=CVE not found
################################################################################

set -euo pipefail

# Configuration
NVD_API_URL="${NVD_API_URL:-https://services.nvd.nist.gov/rest/json/cves/2.0}"
NVD_API_KEY="${NVD_API_KEY:-}"
HTTP_TIMEOUT="${HTTP_TIMEOUT:-30}"
CACHE_DIR="${CACHE_DIR:-/tmp/threat-intel-api-cache}"
CACHE_TTL="${CACHE_TTL:-86400}"  # 24 hours in seconds

# Default options
OUTPUT_FORMAT="summary"
VERBOSE=false
CVE_ID=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    CVE-*|cve-*)
      CVE_ID=$(echo "$1" | tr '[:lower:]' '[:upper:]')
      shift
      ;;
    --output)
      OUTPUT_FORMAT="$2"
      shift 2
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --no-cache)
      CACHE_TTL=0
      shift
      ;;
    --help)
      echo "Usage: $0 <CVE-ID> [--output json|summary] [--verbose] [--no-cache]"
      echo ""
      echo "Arguments:"
      echo "  CVE-ID          CVE identifier (e.g., CVE-2024-1234)"
      echo ""
      echo "Options:"
      echo "  --output FORMAT Output format: json or summary (default: summary)"
      echo "  --verbose       Include full CPE and reference data"
      echo "  --no-cache      Bypass cache and fetch fresh data"
      echo ""
      echo "Environment Variables:"
      echo "  NVD_API_KEY     Optional API key for higher rate limits"
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Validate CVE ID
if [[ -z "$CVE_ID" ]]; then
  echo "Error: CVE ID required"
  echo "Usage: $0 <CVE-ID> [options]"
  exit 1
fi

if ! echo "$CVE_ID" | grep -qE '^CVE-[0-9]{4}-[0-9]{4,}$'; then
  echo "Error: Invalid CVE ID format: $CVE_ID"
  echo "Expected format: CVE-YYYY-NNNNN (e.g., CVE-2024-1234)"
  exit 1
fi

# Initialize cache directory
mkdir -p "$CACHE_DIR"

# Generate cache filename
CACHE_FILE="$CACHE_DIR/nvd-${CVE_ID}.json"

# Check cache
use_cache=false
if [[ -f "$CACHE_FILE" && $CACHE_TTL -gt 0 ]]; then
  file_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)))
  if [[ $file_age -lt $CACHE_TTL ]]; then
    use_cache=true
    [[ "$VERBOSE" == true ]] && echo "# Using cached data (age: ${file_age}s)" >&2
  fi
fi

# Fetch from NVD API if not using cache
if [[ "$use_cache" == false ]]; then
  # Build API request
  API_URL="${NVD_API_URL}?cveId=${CVE_ID}"
  
  # Add API key header if available
  if [[ -n "$NVD_API_KEY" ]]; then
    curl_args=(-H "apiKey: $NVD_API_KEY")
  else
    curl_args=()
  fi
  
  # Fetch data
  http_code=$(curl -sSL --max-time "$HTTP_TIMEOUT" \
    -w "%{http_code}" \
    -o "$CACHE_FILE" \
    "${curl_args[@]}" \
    "$API_URL" 2>/dev/null)
  
  # Check HTTP response
  if [[ "$http_code" != "200" ]]; then
    case $http_code in
      404)
        echo "Error: CVE not found in NVD database: $CVE_ID"
        rm -f "$CACHE_FILE"
        exit 2
        ;;
      429)
        echo "Error: NVD API rate limit exceeded"
        echo "Wait 30 seconds or set NVD_API_KEY environment variable"
        rm -f "$CACHE_FILE"
        exit 1
        ;;
      *)
        echo "Error: NVD API request failed (HTTP $http_code)"
        rm -f "$CACHE_FILE"
        exit 1
        ;;
    esac
  fi
  
  # Validate JSON response
  if ! jq empty "$CACHE_FILE" 2>/dev/null; then
    echo "Error: Invalid JSON response from NVD API"
    rm -f "$CACHE_FILE"
    exit 1
  fi
fi

# Parse JSON response
if [[ "$OUTPUT_FORMAT" == "json" ]]; then
  # Raw JSON output
  cat "$CACHE_FILE"
else
  # Summary format
  
  # Check if CVE exists in response
  results_per_page=$(jq -r '.resultsPerPage // 0' "$CACHE_FILE")
  if [[ "$results_per_page" == "0" ]]; then
    echo "Error: CVE not found: $CVE_ID"
    exit 2
  fi
  
  # Extract fields using jq
  description=$(jq -r '.vulnerabilities[0].cve.descriptions[] | select(.lang == "en") | .value' "$CACHE_FILE" 2>/dev/null || echo "No description available")
  
  # CVSS scores (try v3.1 first, fall back to v3.0, then v2.0)
  cvss_score=$(jq -r '.vulnerabilities[0].cve.metrics.cvssMetricV31[0].cvssData.baseScore // .vulnerabilities[0].cve.metrics.cvssMetricV30[0].cvssData.baseScore // .vulnerabilities[0].cve.metrics.cvssMetricV2[0].cvssData.baseScore // "N/A"' "$CACHE_FILE")
  cvss_vector=$(jq -r '.vulnerabilities[0].cve.metrics.cvssMetricV31[0].cvssData.vectorString // .vulnerabilities[0].cve.metrics.cvssMetricV30[0].cvssData.vectorString // "N/A"' "$CACHE_FILE")
  cvss_severity=$(jq -r '.vulnerabilities[0].cve.metrics.cvssMetricV31[0].cvssData.baseSeverity // .vulnerabilities[0].cve.metrics.cvssMetricV30[0].cvssData.baseSeverity // "UNKNOWN"' "$CACHE_FILE")
  
  published=$(jq -r '.vulnerabilities[0].cve.published' "$CACHE_FILE")
  last_modified=$(jq -r '.vulnerabilities[0].cve.lastModified' "$CACHE_FILE")
  
  # Output summary
  echo "$CVE_ID: $(echo "$description" | head -c 80)..."
  echo "CVSS 3.1 Score: $cvss_score ($cvss_severity)"
  echo "Vector: $cvss_vector"
  echo "Published: $published"
  echo "Last Modified: $last_modified"
  echo ""
  echo "Description:"
  echo "$description"
  echo ""
  
  # References
  echo "References:"
  jq -r '.vulnerabilities[0].cve.references[] | "  - \(.url)"' "$CACHE_FILE" | head -10
  
  # Verbose output: CPE configurations
  if [[ "$VERBOSE" == true ]]; then
    echo ""
    echo "Affected Products (CPE):"
    jq -r '.vulnerabilities[0].cve.configurations[].nodes[].cpeMatch[]? | "  - \(.criteria)"' "$CACHE_FILE" 2>/dev/null | head -20 || echo "  No CPE data available"
    
    echo ""
    echo "Weaknesses (CWE):"
    jq -r '.vulnerabilities[0].cve.weaknesses[]? | .description[] | select(.lang == "en") | "  - \(.value)"' "$CACHE_FILE" 2>/dev/null || echo "  No CWE data available"
  fi
fi

exit 0
