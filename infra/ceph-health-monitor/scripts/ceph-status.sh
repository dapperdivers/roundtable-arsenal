#!/bin/bash
# ceph-status.sh - Get overall Ceph cluster health status
# Part of ceph-health-monitor skill v1.0.0

set -euo pipefail

# Configuration
NAMESPACE="${CEPH_NAMESPACE:-rook-ceph}"
TOOLS_DEPLOY="${CEPH_TOOLS_DEPLOY:-deploy/rook-ceph-tools}"
TIMEOUT="${CEPH_TIMEOUT:-30}"

# Colors for terminal output (if not piping to JSON processor)
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo '{"error": "kubectl not found in PATH"}' >&2
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo '{"error": "jq not found in PATH - required for JSON parsing"}' >&2
    exit 1
fi

# Function to execute ceph command
exec_ceph() {
    local cmd="$1"
    kubectl -n "$NAMESPACE" exec "$TOOLS_DEPLOY" -i --request-timeout="${TIMEOUT}s" -- \
        bash -c "$cmd" 2>&1
}

# Function to parse health status from ceph status output
parse_ceph_status() {
    local status_output="$1"
    
    # Extract key information using awk/grep
    local health_status=$(echo "$status_output" | grep -oP '(?<=health: )\S+' || echo "UNKNOWN")
    local cluster_id=$(echo "$status_output" | grep -oP '(?<=id:\s{5})[a-f0-9-]+' || echo "unknown")
    
    # Extract mon status
    local mon_status=$(echo "$status_output" | grep -oP '\d+ mons? at .*?(?=\n|$)' | head -1 || echo "unknown")
    if [ -z "$mon_status" ]; then
        mon_status=$(echo "$status_output" | grep -i "mon:" -A 1 | tail -1 | xargs || echo "unknown")
    fi
    
    # Extract mgr status
    local mgr_status=$(echo "$status_output" | grep -i "mgr:" -A 1 | tail -1 | xargs || echo "unknown")
    
    # Extract osd status
    local osd_status=$(echo "$status_output" | grep -i "osd:" -A 1 | tail -1 | xargs || echo "unknown")
    
    # Extract PG status
    local pg_status=$(echo "$status_output" | grep -oP '\d+ pgs.*?(?=\n|data:)' || echo "unknown")
    
    # Extract data usage
    local pools=$(echo "$status_output" | grep -oP '(?<=pools:\s+)\d+' || echo "0")
    local objects=$(echo "$status_output" | grep -oP '(?<=objects:\s+)\d+(\.\d+)?\s*\w+' | sed 's/[^0-9.]//g' || echo "0")
    local usage_line=$(echo "$status_output" | grep -oP '\d+(\.\d+)?\s*\w+\s+used.*?total' || echo "")
    
    # Parse usage percentages
    local used_bytes=$(echo "$usage_line" | grep -oP '^\d+(\.\d+)?\s*\w+' | head -1 || echo "0 B")
    local avail_bytes=$(echo "$usage_line" | grep -oP '\d+(\.\d+)?\s*\w+(?=\s+avail)' || echo "0 B")
    local total_bytes=$(echo "$usage_line" | grep -oP '\d+(\.\d+)?\s*\w+(?=\s+total)' || echo "0 B")
    
    # Calculate usage percentage (rough estimate from strings)
    local usage_percent="0"
    if [[ "$status_output" =~ ([0-9.]+)% ]]; then
        usage_percent="${BASH_REMATCH[1]}"
    fi
    
    # Extract health details/warnings
    local health_detail=$(echo "$status_output" | sed -n '/health:/,/services:/p' | grep -v "health:" | grep -v "services:" | sed 's/^[[:space:]]*//' | grep -v "^$" || echo "")
    
    # Build JSON output
    cat <<EOF
{
  "cluster_id": "$cluster_id",
  "health_status": "$health_status",
  "mon_status": "$mon_status",
  "mgr_status": "$mgr_status",
  "osd_status": "$osd_status",
  "pg_status": "$pg_status",
  "data": {
    "pools": $pools,
    "objects": "$objects",
    "used": "$used_bytes",
    "available": "$avail_bytes",
    "total": "$total_bytes",
    "usage_percent": $usage_percent
  },
  "health_detail": $(echo "$health_detail" | jq -Rs . || echo '""'),
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "raw_output": $(echo "$status_output" | jq -Rs . || echo '""')
}
EOF
}

# Main execution
main() {
    # Check if tools pod is available
    if ! kubectl -n "$NAMESPACE" get "$TOOLS_DEPLOY" &>/dev/null; then
        cat <<EOF
{
  "error": "rook-ceph-tools deployment not found in namespace $NAMESPACE",
  "namespace": "$NAMESPACE",
  "deployment": "$TOOLS_DEPLOY",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
        exit 1
    fi
    
    # Execute ceph status
    local status_output
    if ! status_output=$(exec_ceph "ceph status"); then
        cat <<EOF
{
  "error": "Failed to execute ceph status command",
  "details": $(echo "$status_output" | jq -Rs . || echo '""'),
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
        exit 1
    fi
    
    # Parse and output JSON
    parse_ceph_status "$status_output"
}

# Run main function
main "$@"
