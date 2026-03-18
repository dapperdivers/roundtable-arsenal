#!/bin/bash
set -euo pipefail

# IOC Distributor - Push IOCs to configured security endpoints
# Usage: ./distribute.sh --input /tmp/iocs.csv --endpoint siem-webhook

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config.env"

# Load configuration
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Defaults
INPUT=""
ENDPOINT=""
ALL_ENDPOINTS=0
DRY_RUN=0
VERBOSE=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_debug() { [[ $VERBOSE -eq 1 ]] && echo -e "${BLUE}[DEBUG]${NC} $*" || true; }

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Distribute IOCs to configured security endpoints.

OPTIONS:
    --input FILE           Input file with IOCs (required)
    --endpoint NAME        Endpoint name from config (siem-webhook, suricata-ids, etc.)
    --all                  Distribute to all configured endpoints
    --dry-run              Test without actually pushing
    --verbose              Enable debug logging
    -h, --help             Show this help message

CONFIGURED ENDPOINTS:
    siem-webhook           Push to SIEM via webhook (JSON/CSV)
    syslog                 Send to syslog server
    suricata-ids           Upload Suricata rules via SFTP
    misp-instance          Push to MISP threat sharing platform
    file-share             Copy to shared filesystem

EXAMPLES:
    # Push CSV to SIEM webhook
    $0 --input /tmp/iocs.csv --endpoint siem-webhook

    # Upload Suricata rules to IDS
    $0 --input /tmp/iocs.rules --endpoint suricata-ids

    # Test distribution to all endpoints
    $0 --input /tmp/iocs.json --all --dry-run

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --input) INPUT="$2"; shift 2 ;;
        --endpoint) ENDPOINT="$2"; shift 2 ;;
        --all) ALL_ENDPOINTS=1; shift ;;
        --dry-run) DRY_RUN=1; shift ;;
        --verbose) VERBOSE=1; shift ;;
        -h|--help) usage ;;
        *) log_error "Unknown option: $1"; usage ;;
    esac
done

# Validate input
if [[ -z "$INPUT" ]]; then
    log_error "Input file required (--input)"
    exit 1
fi

if [[ ! -f "$INPUT" ]]; then
    log_error "Input file not found: $INPUT"
    exit 1
fi

if [[ $ALL_ENDPOINTS -eq 0 ]] && [[ -z "$ENDPOINT" ]]; then
    log_error "Specify --endpoint or --all"
    exit 1
fi

# Check requirements
check_requirements() {
    local missing=()
    command -v curl >/dev/null 2>&1 || missing+=("curl")
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing[*]}"
        exit 1
    fi
}

# Push to SIEM webhook
push_to_siem_webhook() {
    local input_file="$1"
    
    if [[ -z "${SIEM_WEBHOOK:-}" ]]; then
        log_warn "SIEM_WEBHOOK not configured, skipping"
        return 1
    fi
    
    log_info "Pushing to SIEM webhook: $SIEM_WEBHOOK"
    
    local content_type="application/json"
    local file_ext="${input_file##*.}"
    
    if [[ "$file_ext" == "csv" ]]; then
        content_type="text/csv"
    fi
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would push to: $SIEM_WEBHOOK"
        log_debug "Content-Type: $content_type"
        log_debug "File size: $(wc -c < "$input_file") bytes"
        return 0
    fi
    
    local response
    local http_code
    
    response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Content-Type: $content_type" \
        ${SIEM_WEBHOOK_TOKEN:+-H "Authorization: $SIEM_WEBHOOK_TOKEN"} \
        --data-binary "@$input_file" \
        "$SIEM_WEBHOOK" 2>&1)
    
    http_code=$(echo "$response" | tail -n1)
    local body
    body=$(echo "$response" | head -n-1)
    
    if [[ "$http_code" =~ ^2[0-9]{2}$ ]]; then
        log_info "✓ Successfully pushed to SIEM (HTTP $http_code)"
        log_debug "Response: $body"
        return 0
    else
        log_error "✗ Failed to push to SIEM (HTTP $http_code)"
        log_error "Response: $body"
        return 1
    fi
}

# Send to syslog
push_to_syslog() {
    local input_file="$1"
    
    if [[ -z "${SYSLOG_SERVER:-}" ]]; then
        log_warn "SYSLOG_SERVER not configured, skipping"
        return 1
    fi
    
    log_info "Sending to syslog: $SYSLOG_SERVER"
    
    local server_host="${SYSLOG_SERVER%%:*}"
    local server_port="${SYSLOG_SERVER##*:}"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would send $(wc -l < "$input_file") lines to $SYSLOG_SERVER"
        return 0
    fi
    
    # Send each IOC as separate syslog message
    local count=0
    while IFS= read -r line; do
        # Skip header
        [[ "$line" == "type,value,"* ]] && continue
        
        # Send via netcat or logger
        if command -v nc >/dev/null 2>&1; then
            echo "<134>$(date '+%b %d %H:%M:%S') opencti-ioc: $line" | nc -w1 "$server_host" "$server_port" 2>/dev/null || true
        else
            logger -n "$server_host" -P "$server_port" -t "opencti-ioc" "$line" 2>/dev/null || true
        fi
        
        ((count++))
    done < "$input_file"
    
    log_info "✓ Sent $count IOCs to syslog"
    return 0
}

# Upload to Suricata IDS
push_to_suricata() {
    local input_file="$1"
    
    if [[ -z "${SURICATA_SFTP:-}" ]]; then
        log_warn "SURICATA_SFTP not configured, skipping"
        return 1
    fi
    
    log_info "Uploading Suricata rules: $SURICATA_SFTP"
    
    local remote_user="${SURICATA_SFTP%%@*}"
    local remote_path="${SURICATA_SFTP#*@}"
    local remote_host="${remote_path%%:*}"
    local remote_dir="${remote_path#*:}"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would upload to: $SURICATA_SFTP"
        log_debug "Rule count: $(grep -c '^alert' "$input_file" || echo 0)"
        return 0
    fi
    
    # Upload via SCP
    local ssh_opts=""
    if [[ -n "${SURICATA_SSH_KEY:-}" ]]; then
        ssh_opts="-i $SURICATA_SSH_KEY"
    fi
    
    if scp $ssh_opts "$input_file" "$remote_user@$remote_host:$remote_dir/opencti-iocs.rules" 2>&1; then
        log_info "✓ Uploaded Suricata rules"
        
        # Reload Suricata rules (optional)
        if [[ "${SURICATA_RELOAD:-0}" == "1" ]]; then
            log_info "Reloading Suricata rules..."
            ssh $ssh_opts "$remote_user@$remote_host" "sudo suricatasc -c 'reload-rules'" 2>/dev/null || \
                log_warn "Could not reload Suricata rules (manual reload may be required)"
        fi
        
        return 0
    else
        log_error "✗ Failed to upload Suricata rules"
        return 1
    fi
}

# Push to MISP
push_to_misp() {
    local input_file="$1"
    
    if [[ -z "${MISP_URL:-}" ]] || [[ -z "${MISP_KEY:-}" ]]; then
        log_warn "MISP_URL or MISP_KEY not configured, skipping"
        return 1
    fi
    
    log_info "Pushing to MISP: $MISP_URL"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would push to MISP"
        return 0
    fi
    
    # Convert to MISP format if not already JSON
    local upload_file="$input_file"
    if [[ "${input_file##*.}" != "json" ]]; then
        log_warn "MISP requires JSON format, skipping (convert with export-iocs.sh --format json)"
        return 1
    fi
    
    local response
    local http_code
    
    response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Authorization: $MISP_KEY" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        --data-binary "@$upload_file" \
        "$MISP_URL/attributes/add" 2>&1)
    
    http_code=$(echo "$response" | tail -n1)
    local body
    body=$(echo "$response" | head -n-1)
    
    if [[ "$http_code" =~ ^2[0-9]{2}$ ]]; then
        log_info "✓ Successfully pushed to MISP (HTTP $http_code)"
        return 0
    else
        log_error "✗ Failed to push to MISP (HTTP $http_code)"
        log_error "Response: $body"
        return 1
    fi
}

# Copy to file share
push_to_file_share() {
    local input_file="$1"
    
    if [[ -z "${FILE_SHARE_PATH:-}" ]]; then
        log_warn "FILE_SHARE_PATH not configured, skipping"
        return 1
    fi
    
    log_info "Copying to file share: $FILE_SHARE_PATH"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would copy to: $FILE_SHARE_PATH"
        return 0
    fi
    
    local dest_file="$FILE_SHARE_PATH/opencti-iocs-$(date +%Y%m%d-%H%M%S).${input_file##*.}"
    
    if cp "$input_file" "$dest_file" 2>&1; then
        log_info "✓ Copied to: $dest_file"
        
        # Create latest symlink
        ln -sf "$dest_file" "$FILE_SHARE_PATH/opencti-iocs-latest.${input_file##*.}" 2>/dev/null || true
        
        return 0
    else
        log_error "✗ Failed to copy to file share"
        return 1
    fi
}

# Distribute to specific endpoint
distribute_to_endpoint() {
    local endpoint="$1"
    local input_file="$2"
    
    log_info "=== Distributing to: $endpoint ==="
    
    case "$endpoint" in
        siem-webhook)
            push_to_siem_webhook "$input_file"
            ;;
        syslog)
            push_to_syslog "$input_file"
            ;;
        suricata-ids)
            push_to_suricata "$input_file"
            ;;
        misp-instance)
            push_to_misp "$input_file"
            ;;
        file-share)
            push_to_file_share "$input_file"
            ;;
        *)
            log_error "Unknown endpoint: $endpoint"
            return 1
            ;;
    esac
}

# Main execution
main() {
    check_requirements
    
    log_info "Input file: $INPUT ($(wc -c < "$INPUT") bytes)"
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_warn "=== DRY RUN MODE - No actual distribution ==="
    fi
    
    local success_count=0
    local fail_count=0
    
    if [[ $ALL_ENDPOINTS -eq 1 ]]; then
        # Distribute to all configured endpoints
        local endpoints=("siem-webhook" "syslog" "suricata-ids" "misp-instance" "file-share")
        
        for ep in "${endpoints[@]}"; do
            if distribute_to_endpoint "$ep" "$INPUT"; then
                ((success_count++))
            else
                ((fail_count++))
            fi
            echo ""
        done
    else
        # Distribute to specific endpoint
        if distribute_to_endpoint "$ENDPOINT" "$INPUT"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    fi
    
    log_info "=== Distribution Summary ==="
    log_info "Successful: $success_count"
    [[ $fail_count -gt 0 ]] && log_warn "Failed: $fail_count"
    
    [[ $fail_count -eq 0 ]] && exit 0 || exit 1
}

main "$@"
