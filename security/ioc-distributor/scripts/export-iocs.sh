#!/bin/bash
set -euo pipefail

# IOC Exporter - Export IOCs from OpenCTI/MISP in multiple formats
# Usage: ./export-iocs.sh --source opencti --days 7 --format csv

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config.env"

# Load configuration
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Defaults
SOURCE="${SOURCE:-opencti}"
DAYS="${DAYS:-7}"
FORMAT="${FORMAT:-csv}"
OUTPUT="${OUTPUT:-/tmp/iocs.${FORMAT}}"
CONFIDENCE="${CONFIDENCE:-70}"
IOC_TYPES="${IOC_TYPES:-ipv4-addr,domain-name,file-hash,url}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Export IOCs from threat intelligence sources in multiple formats.

OPTIONS:
    --source SOURCE         Source: opencti, misp, file (default: opencti)
    --days DAYS            Export IOCs from last N days (default: 7)
    --format FORMAT        Output format: csv, json, stix, suricata, yara (default: csv)
    --output FILE          Output file path (default: /tmp/iocs.FORMAT)
    --types TYPES          Comma-separated IOC types (default: ipv4-addr,domain-name,file-hash,url)
    --confidence MIN       Minimum confidence score 0-100 (default: 70)
    --test                 Test connection and exit
    -h, --help             Show this help message

EXAMPLES:
    # Export all IOCs from last 7 days as CSV
    $0 --source opencti --days 7 --format csv

    # Export IP addresses and domains as Suricata rules
    $0 --source opencti --types "ipv4-addr,domain-name" --format suricata

    # Export high-confidence file hashes as YARA rules
    $0 --source opencti --types file-hash --confidence 90 --format yara

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --source) SOURCE="$2"; shift 2 ;;
        --days) DAYS="$2"; shift 2 ;;
        --format) FORMAT="$2"; shift 2 ;;
        --output) OUTPUT="$2"; shift 2 ;;
        --types) IOC_TYPES="$2"; shift 2 ;;
        --confidence) CONFIDENCE="$2"; shift 2 ;;
        --test) TEST_MODE=1; shift ;;
        -h|--help) usage ;;
        *) log_error "Unknown option: $1"; usage ;;
    esac
done

# Validate requirements
check_requirements() {
    local missing=()
    command -v curl >/dev/null 2>&1 || missing+=("curl")
    command -v jq >/dev/null 2>&1 || missing+=("jq")
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing[*]}"
        exit 1
    fi
}

# Test OpenCTI connection
test_opencti_connection() {
    if [[ -z "${OPENCTI_URL:-}" ]] || [[ -z "${OPENCTI_TOKEN:-}" ]]; then
        log_error "OPENCTI_URL and OPENCTI_TOKEN must be set"
        exit 1
    fi
    
    log_info "Testing OpenCTI connection: $OPENCTI_URL"
    
    local response
    response=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: Bearer $OPENCTI_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"query": "{ about { version } }"}' \
        "$OPENCTI_URL/graphql" 2>&1)
    
    local http_code
    http_code=$(echo "$response" | tail -n1)
    local body
    body=$(echo "$response" | head -n-1)
    
    if [[ "$http_code" == "200" ]]; then
        local version
        version=$(echo "$body" | jq -r '.data.about.version // "unknown"')
        log_info "✓ Connected to OpenCTI version $version"
        return 0
    else
        log_error "✗ Connection failed (HTTP $http_code)"
        echo "$body" | jq '.' 2>/dev/null || echo "$body"
        return 1
    fi
}

# Export IOCs from OpenCTI
export_from_opencti() {
    log_info "Exporting IOCs from OpenCTI (last $DAYS days, confidence >= $CONFIDENCE)"
    
    local start_date
    start_date=$(date -u -d "$DAYS days ago" +%Y-%m-%dT%H:%M:%S.000Z)
    
    # GraphQL query for indicators
    local query
    query=$(cat <<EOF
{
  "query": "query GetIndicators(\$filters: FilterGroup, \$first: Int) {
    indicators(filters: \$filters, first: \$first, orderBy: created_at, orderMode: desc) {
      edges {
        node {
          id
          standard_id
          entity_type
          pattern
          pattern_type
          name
          description
          valid_from
          valid_until
          confidence
          created
          modified
          objectLabel {
            edges {
              node {
                value
              }
            }
          }
        }
      }
    }
  }",
  "variables": {
    "first": 1000,
    "filters": {
      "mode": "and",
      "filters": [
        {
          "key": "created_at",
          "values": ["$start_date"],
          "operator": "gt",
          "mode": "or"
        },
        {
          "key": "confidence",
          "values": ["$CONFIDENCE"],
          "operator": "gte",
          "mode": "or"
        }
      ],
      "filterGroups": []
    }
  }
}
EOF
)
    
    local response
    response=$(curl -s \
        -H "Authorization: Bearer $OPENCTI_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$query" \
        "$OPENCTI_URL/graphql")
    
    # Check for errors
    if echo "$response" | jq -e '.errors' >/dev/null 2>&1; then
        log_error "OpenCTI API error:"
        echo "$response" | jq '.errors'
        exit 1
    fi
    
    # Save raw JSON
    local raw_file="/tmp/opencti-indicators-raw.json"
    echo "$response" > "$raw_file"
    
    local count
    count=$(echo "$response" | jq '.data.indicators.edges | length')
    log_info "Retrieved $count indicators from OpenCTI"
    
    # Convert to format
    case "$FORMAT" in
        csv)
            export_to_csv "$raw_file" "$OUTPUT"
            ;;
        json)
            export_to_json "$raw_file" "$OUTPUT"
            ;;
        stix)
            export_to_stix "$raw_file" "$OUTPUT"
            ;;
        suricata)
            export_to_suricata "$raw_file" "$OUTPUT"
            ;;
        yara)
            export_to_yara "$raw_file" "$OUTPUT"
            ;;
        *)
            log_error "Unsupported format: $FORMAT"
            exit 1
            ;;
    esac
}

# Export to CSV format
export_to_csv() {
    local input="$1"
    local output="$2"
    
    log_info "Converting to CSV format..."
    
    # CSV header
    echo "type,value,confidence,valid_from,valid_until,description,labels" > "$output"
    
    # Extract IOCs and convert to CSV
    jq -r '.data.indicators.edges[].node | 
        [
            .pattern_type // .entity_type,
            (.pattern // .name),
            .confidence,
            .valid_from,
            (.valid_until // ""),
            (.description // "" | gsub("\n"; " ") | gsub("\""; "\"\"")),
            ([.objectLabel.edges[].node.value] | join(";"))
        ] | @csv' "$input" >> "$output"
    
    local line_count
    line_count=$(wc -l < "$output")
    log_info "✓ Exported $((line_count - 1)) IOCs to $output"
}

# Export to JSON format
export_to_json() {
    local input="$1"
    local output="$2"
    
    log_info "Converting to JSON format..."
    
    jq '{
        metadata: {
            exported_at: now | todate,
            source: "opencti",
            confidence_threshold: '$CONFIDENCE',
            days: '$DAYS'
        },
        indicators: [.data.indicators.edges[].node | {
            type: (.pattern_type // .entity_type),
            value: (.pattern // .name),
            confidence: .confidence,
            valid_from: .valid_from,
            valid_until: .valid_until,
            description: .description,
            labels: [.objectLabel.edges[].node.value],
            id: .standard_id
        }]
    }' "$input" > "$output"
    
    local count
    count=$(jq '.indicators | length' "$output")
    log_info "✓ Exported $count IOCs to $output"
}

# Export to STIX 2.1 format
export_to_stix() {
    local input="$1"
    local output="$2"
    
    log_info "Converting to STIX 2.1 format..."
    
    jq '{
        type: "bundle",
        id: "bundle--" + (now | tostring | gsub("[^0-9]"; "") | .[0:32]),
        spec_version: "2.1",
        objects: [.data.indicators.edges[].node | {
            type: "indicator",
            spec_version: "2.1",
            id: .standard_id,
            created: .created,
            modified: .modified,
            name: .name,
            description: .description,
            pattern: .pattern,
            pattern_type: .pattern_type,
            valid_from: .valid_from,
            valid_until: .valid_until,
            confidence: .confidence,
            labels: [.objectLabel.edges[].node.value]
        }]
    }' "$input" > "$output"
    
    local count
    count=$(jq '.objects | length' "$output")
    log_info "✓ Exported $count STIX indicators to $output"
}

# Export to Suricata rules
export_to_suricata() {
    local input="$1"
    local output="$2"
    
    log_info "Converting to Suricata rules..."
    
    echo "# Suricata rules generated from OpenCTI" > "$output"
    echo "# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$output"
    echo "# Confidence threshold: $CONFIDENCE" >> "$output"
    echo "" >> "$output"
    
    local sid=9000000
    
    # Extract IP addresses
    jq -r '.data.indicators.edges[].node | 
        select(.pattern_type == "stix" and (.pattern | contains("[ipv4-addr:value"))) |
        .pattern' "$input" | \
    while IFS= read -r pattern; do
        local ip
        ip=$(echo "$pattern" | grep -oP "(?<=value = ')[^']+")
        
        if [[ -n "$ip" ]]; then
            echo "alert ip any any -> $ip any (msg:\"OpenCTI IOC: Suspicious IP $ip\"; sid:$sid; rev:1;)" >> "$output"
            ((sid++))
        fi
    done
    
    # Extract domains
    jq -r '.data.indicators.edges[].node | 
        select(.pattern_type == "stix" and (.pattern | contains("[domain-name:value"))) |
        .pattern' "$input" | \
    while IFS= read -r pattern; do
        local domain
        domain=$(echo "$pattern" | grep -oP "(?<=value = ')[^']+")
        
        if [[ -n "$domain" ]]; then
            echo "alert dns any any -> any any (msg:\"OpenCTI IOC: Suspicious domain $domain\"; dns.query; content:\"$domain\"; nocase; sid:$sid; rev:1;)" >> "$output"
            ((sid++))
        fi
    done
    
    local rule_count
    rule_count=$(grep -c "^alert" "$output" || true)
    log_info "✓ Generated $rule_count Suricata rules in $output"
}

# Export to YARA rules
export_to_yara() {
    local input="$1"
    local output="$2"
    
    log_info "Converting to YARA rules..."
    
    cat > "$output" << 'EOF'
/*
 * YARA rules generated from OpenCTI
 * Generated: DATE_PLACEHOLDER
 * Confidence threshold: CONFIDENCE_PLACEHOLDER
 */

import "pe"
import "hash"

EOF
    
    sed -i "s/DATE_PLACEHOLDER/$(date -u +%Y-%m-%dT%H:%M:%SZ)/" "$output"
    sed -i "s/CONFIDENCE_PLACEHOLDER/$CONFIDENCE/" "$output"
    
    local rule_count=0
    
    # Extract file hashes
    jq -r '.data.indicators.edges[].node | 
        select(.pattern_type == "stix" and (.pattern | contains("file:hashes"))) |
        {pattern: .pattern, name: .name, desc: .description}' "$input" | \
    jq -c '.' | \
    while IFS= read -r indicator; do
        local hash
        hash=$(echo "$indicator" | jq -r '.pattern' | grep -oP "(?<='MD5' = ')[^']+|(?<='SHA-256' = ')[^']+|(?<='SHA-1' = ')[^']+")
        
        local name
        name=$(echo "$indicator" | jq -r '.name // "unknown"' | tr ' ' '_' | tr -cd '[:alnum:]_')
        
        local desc
        desc=$(echo "$indicator" | jq -r '.desc // "Suspicious file"' | sed 's/"/\\"/g')
        
        if [[ -n "$hash" ]]; then
            cat >> "$output" << EOF

rule OpenCTI_${name}_${rule_count}
{
    meta:
        description = "$desc"
        source = "OpenCTI"
        confidence = $CONFIDENCE
        hash = "$hash"
    
    condition:
        hash.md5(0, filesize) == "$hash" or
        hash.sha1(0, filesize) == "$hash" or
        hash.sha256(0, filesize) == "$hash"
}
EOF
            ((rule_count++))
        fi
    done
    
    log_info "✓ Generated $rule_count YARA rules in $output"
}

# Main execution
main() {
    check_requirements
    
    if [[ "${TEST_MODE:-0}" == "1" ]]; then
        test_opencti_connection
        exit $?
    fi
    
    case "$SOURCE" in
        opencti)
            test_opencti_connection
            export_from_opencti
            ;;
        misp)
            log_error "MISP export not yet implemented"
            exit 1
            ;;
        file)
            log_error "File import not yet implemented"
            exit 1
            ;;
        *)
            log_error "Unknown source: $SOURCE"
            exit 1
            ;;
    esac
    
    log_info "✓ Export complete: $OUTPUT"
}

main "$@"
