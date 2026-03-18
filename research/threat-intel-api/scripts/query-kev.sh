#!/bin/bash
################################################################################
# CISA KEV Query Script
# Queries CISA Known Exploited Vulnerabilities catalog
#
# Usage: query-kev.sh [<CVE-ID>] [--format json|table|summary] [--recent N]
# Exit codes: 0=success, 1=error, 2=CVE not in KEV
################################################################################

set -euo pipefail

# Configuration
KEV_URL="${KEV_URL:-https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json}"
HTTP_TIMEOUT="${HTTP_TIMEOUT:-30}"
CACHE_DIR="${CACHE_DIR:-/tmp/threat-intel-api-cache}"
CACHE_TTL="${CACHE_TTL:-3600}"  # 1 hour in seconds

# Default options
CVE_ID=""
OUTPUT_FORMAT="summary"
RECENT_DAYS=""
VENDOR_FILTER=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    CVE-*|cve-*)
      CVE_ID=$(echo "$1" | tr '[:lower:]' '[:upper:]')
      shift
      ;;
    --format)
      OUTPUT_FORMAT="$2"
      shift 2
      ;;
    --recent)
      RECENT_DAYS="$2"
      shift 2
      ;;
    --vendor)
      VENDOR_FILTER="$2"
      shift 2
      ;;
    --no-cache)
      CACHE_TTL=0
      shift
      ;;
    --help)
      echo "Usage: $0 [<CVE-ID>] [--format json|table|summary] [--recent N] [--vendor NAME]"
      echo ""
      echo "Arguments:"
      echo "  CVE-ID          Optional - check if specific CVE is in KEV catalog"
      echo ""
      echo "Options:"
      echo "  --format FORMAT Output format: json, table, or summary (default: summary)"
      echo "  --recent N      Show KEV entries added in last N days"
      echo "  --vendor NAME   Filter by vendor name"
      echo "  --no-cache      Bypass cache and fetch fresh data"
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Initialize cache directory
mkdir -p "$CACHE_DIR"

# Cache file
CACHE_FILE="$CACHE_DIR/cisa-kev.json"

# Check cache
use_cache=false
if [[ -f "$CACHE_FILE" && $CACHE_TTL -gt 0 ]]; then
  file_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)))
  if [[ $file_age -lt $CACHE_TTL ]]; then
    use_cache=true
  fi
fi

# Fetch KEV catalog if not using cache
if [[ "$use_cache" == false ]]; then
  if ! curl -sSL --max-time "$HTTP_TIMEOUT" "$KEV_URL" -o "$CACHE_FILE" 2>/dev/null; then
    echo "Error: Failed to fetch CISA KEV catalog"
    exit 1
  fi
  
  # Validate JSON
  if ! jq empty "$CACHE_FILE" 2>/dev/null; then
    echo "Error: Invalid JSON in KEV catalog"
    rm -f "$CACHE_FILE"
    exit 1
  fi
fi

# If specific CVE requested, check if it's in KEV
if [[ -n "$CVE_ID" ]]; then
  kev_entry=$(jq --arg cve "$CVE_ID" '.vulnerabilities[] | select(.cveID == $cve)' "$CACHE_FILE" 2>/dev/null)
  
  if [[ -z "$kev_entry" ]]; then
    echo "$CVE_ID: NOT in KEV catalog"
    exit 2
  fi
  
  if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    echo "$kev_entry" | jq .
  else
    vendor=$(echo "$kev_entry" | jq -r '.vendorProject')
    product=$(echo "$kev_entry" | jq -r '.product')
    vuln_name=$(echo "$kev_entry" | jq -r '.vulnerabilityName')
    date_added=$(echo "$kev_entry" | jq -r '.dateAdded')
    due_date=$(echo "$kev_entry" | jq -r '.dueDate')
    required_action=$(echo "$kev_entry" | jq -r '.requiredAction')
    known_ransomware=$(echo "$kev_entry" | jq -r '.knownRansomwareCampaignUse')
    notes=$(echo "$kev_entry" | jq -r '.notes // "N/A"')
    
    echo "$CVE_ID: IN KEV CATALOG ⚠️"
    echo "Vulnerability: $vuln_name"
    echo "Vendor: $vendor"
    echo "Product: $product"
    echo "Added to KEV: $date_added"
    echo "Due Date: $due_date"
    echo "Required Action: $required_action"
    echo "Known Ransomware: $known_ransomware"
    if [[ "$notes" != "N/A" ]]; then
      echo "Notes: $notes"
    fi
  fi
  exit 0
fi

# Filter by recent additions if requested
filter_jq='.vulnerabilities[]'
if [[ -n "$RECENT_DAYS" ]]; then
  cutoff_date=$(date -u -d "$RECENT_DAYS days ago" +"%Y-%m-%d" 2>/dev/null || date -u -v-${RECENT_DAYS}d +"%Y-%m-%d" 2>/dev/null)
  filter_jq="$filter_jq | select(.dateAdded >= \"$cutoff_date\")"
fi

# Filter by vendor if requested
if [[ -n "$VENDOR_FILTER" ]]; then
  filter_jq="$filter_jq | select(.vendorProject | test(\"$VENDOR_FILTER\"; \"i\"))"
fi

# Output based on format
case "$OUTPUT_FORMAT" in
  json)
    jq "$filter_jq" "$CACHE_FILE" | jq -s .
    ;;
  table)
    echo "CVE ID          | CVSS | Vendor         | Product        | Added      | Due Date"
    echo "----------------|------|----------------|----------------|------------|------------"
    jq -r "$filter_jq | \"\(.cveID)|\(.vendorProject)|\(.product)|\(.dateAdded)|\(.dueDate)\"" "$CACHE_FILE" | \
    while IFS='|' read -r cve vendor product added due; do
      printf "%-15s | N/A  | %-14s | %-14s | %-10s | %s\n" "$cve" "${vendor:0:14}" "${product:0:14}" "$added" "$due"
    done
    ;;
  summary|*)
    catalog_version=$(jq -r '.catalogVersion' "$CACHE_FILE")
    catalog_date=$(jq -r '.dateReleased' "$CACHE_FILE")
    total_vulns=$(jq '[.vulnerabilities[]] | length' "$CACHE_FILE")
    
    echo "CISA Known Exploited Vulnerabilities Catalog"
    echo "============================================="
    echo "Catalog Version: $catalog_version"
    echo "Date Released: $catalog_date"
    echo "Total Vulnerabilities: $total_vulns"
    echo ""
    
    if [[ -n "$RECENT_DAYS" ]]; then
      echo "Vulnerabilities added in last $RECENT_DAYS days:"
      echo ""
    elif [[ -n "$VENDOR_FILTER" ]]; then
      echo "Vulnerabilities from vendor: $VENDOR_FILTER"
      echo ""
    else
      echo "Recent additions (last 10):"
      echo ""
      filter_jq="$filter_jq | select(.dateAdded >= \"$(date -u -d '30 days ago' +"%Y-%m-%d" 2>/dev/null || date -u -v-30d +"%Y-%m-%d")\")"
    fi
    
    jq -r "$filter_jq" "$CACHE_FILE" | jq -s 'sort_by(.dateAdded) | reverse | .[:10]' | \
    jq -r '.[] | "[\(.dateAdded)] \(.cveID): \(.vulnerabilityName)\n  Vendor: \(.vendorProject) | Product: \(.product)\n  Action: \(.requiredAction)\n"'
    ;;
esac

exit 0
