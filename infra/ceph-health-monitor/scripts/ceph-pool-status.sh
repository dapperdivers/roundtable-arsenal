#!/bin/bash
# ceph-pool-status.sh - Monitor Ceph pool usage and quotas
# Part of ceph-health-monitor skill v1.0.0

set -euo pipefail

# Configuration
NAMESPACE="${CEPH_NAMESPACE:-rook-ceph}"
TOOLS_DEPLOY="${CEPH_TOOLS_DEPLOY:-deploy/rook-ceph-tools}"
TIMEOUT="${CEPH_TIMEOUT:-30}"
WARN_THRESHOLD="${POOL_WARN_THRESHOLD:-85}"
CRIT_THRESHOLD="${POOL_CRIT_THRESHOLD:-95}"

# Check dependencies
for cmd in kubectl jq awk; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "{\"error\": \"$cmd not found in PATH\"}" >&2
        exit 1
    fi
done

# Function to execute ceph command
exec_ceph() {
    local cmd="$1"
    kubectl -n "$NAMESPACE" exec "$TOOLS_DEPLOY" -i --request-timeout="${TIMEOUT}s" -- \
        bash -c "$cmd" 2>&1
}

# Function to get pool list
get_pool_list() {
    exec_ceph "ceph osd pool ls detail --format=json"
}

# Function to get pool usage stats
get_pool_stats() {
    exec_ceph "ceph df detail --format=json"
}

# Function to convert bytes to human readable
bytes_to_human() {
    local bytes=$1
    awk "BEGIN {
        units[0] = \"B\"
        units[1] = \"KiB\"
        units[2] = \"MiB\"
        units[3] = \"GiB\"
        units[4] = \"TiB\"
        units[5] = \"PiB\"
        
        bytes = $bytes
        unit = 0
        
        while (bytes >= 1024 && unit < 5) {
            bytes = bytes / 1024
            unit++
        }
        
        printf \"%.1f %s\", bytes, units[unit]
    }"
}

# Main execution
main() {
    # Check if tools pod is available
    if ! kubectl -n "$NAMESPACE" get "$TOOLS_DEPLOY" &>/dev/null; then
        cat <<EOF
{
  "error": "rook-ceph-tools deployment not found",
  "namespace": "$NAMESPACE",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
        exit 1
    fi
    
    # Get pool details
    local pool_list_json
    if ! pool_list_json=$(get_pool_list 2>&1); then
        echo "{\"error\": \"Failed to get pool list\", \"details\": $(echo "$pool_list_json" | jq -Rs .)}" >&2
        exit 1
    fi
    
    # Get pool statistics
    local pool_stats_json
    if ! pool_stats_json=$(get_pool_stats 2>&1); then
        echo "{\"error\": \"Failed to get pool stats\", \"details\": $(echo "$pool_stats_json" | jq -Rs .)}" >&2
        exit 1
    fi
    
    # Build pools array
    local pools_array="["
    local first=true
    local total_used=0
    local total_avail=0
    local highest_usage_pool=""
    local highest_usage_percent=0
    local pool_count=0
    
    # Extract stats section from df output
    local stats_pools=$(echo "$pool_stats_json" | jq -c '.pools[]? // empty')
    
    # Process each pool
    while IFS= read -r pool_entry; do
        pool_count=$((pool_count + 1))
        
        local pool_name=$(echo "$pool_entry" | jq -r '.pool_name // .name // "unknown"')
        local pool_id=$(echo "$pool_entry" | jq -r '.pool_id // .pool // 0')
        
        # Get pool details from pool list
        local pool_details=$(echo "$pool_list_json" | jq --arg id "$pool_id" \
            '.[] | select(.pool==($id|tonumber)) // {}')
        
        local pool_type=$(echo "$pool_details" | jq -r '.type // "replicated"')
        local size=$(echo "$pool_details" | jq -r '.size // 3')
        local min_size=$(echo "$pool_details" | jq -r '.min_size // 2')
        local pg_num=$(echo "$pool_details" | jq -r '.pg_num // 0')
        local pgp_num=$(echo "$pool_details" | jq -r '.pg_placement_num // .pgp_num // 0')
        
        # Get usage stats
        local stats=$(echo "$pool_entry" | jq -r '.stats // {}')
        local stored=$(echo "$stats" | jq -r '.stored // 0')
        local objects=$(echo "$stats" | jq -r '.objects // 0')
        local kb_used=$(echo "$stats" | jq -r '.kb_used // 0')
        local bytes_used=$(echo "$stats" | jq -r '.bytes_used // 0')
        local max_avail=$(echo "$stats" | jq -r '.max_avail // 0')
        local percent_used=$(echo "$stats" | jq -r '.percent_used // 0')
        
        # Convert to human readable
        local stored_hr=$(bytes_to_human "$stored")
        local used_hr=$(bytes_to_human "$bytes_used")
        local avail_hr=$(bytes_to_human "$max_avail")
        
        # Round percent_used to 2 decimals
        percent_used=$(awk "BEGIN {printf \"%.2f\", $percent_used}")
        
        # Track totals
        total_used=$((total_used + bytes_used))
        total_avail=$((total_avail + max_avail))
        
        # Track highest usage
        if (( $(awk "BEGIN {print ($percent_used > $highest_usage_percent)}") )); then
            highest_usage_percent=$percent_used
            highest_usage_pool=$pool_name
        fi
        
        # Get quota info
        local quota_max_objects=$(echo "$pool_details" | jq -r '.quota_max_objects // null')
        local quota_max_bytes=$(echo "$pool_details" | jq -r '.quota_max_bytes // null')
        
        # Check for alerts
        local alerts_array="[]"
        if (( $(awk "BEGIN {print ($percent_used >= $CRIT_THRESHOLD)}") )); then
            alerts_array=$(cat <<EOF_ALERT
[{
  "severity": "critical",
  "issue": "pool_full",
  "threshold": $CRIT_THRESHOLD,
  "message": "Pool critically full - writes may be blocked soon"
}]
EOF_ALERT
)
        elif (( $(awk "BEGIN {print ($percent_used >= $WARN_THRESHOLD)}") )); then
            alerts_array=$(cat <<EOF_ALERT
[{
  "severity": "warning",
  "issue": "nearfull",
  "threshold": $WARN_THRESHOLD,
  "message": "Pool approaching capacity limit"
}]
EOF_ALERT
)
        fi
        
        # Add pool to array
        [ "$first" = false ] && pools_array+=","
        pools_array+=$(cat <<EOF_POOL
{
  "name": "$pool_name",
  "id": $pool_id,
  "type": "$pool_type",
  "size": $size,
  "min_size": $min_size,
  "pg_num": $pg_num,
  "pgp_num": $pgp_num,
  "usage": {
    "stored": "$stored_hr",
    "objects": $objects,
    "used": "$used_hr",
    "max_avail": "$avail_hr",
    "percent_used": $percent_used
  },
  "quota": {
    "max_objects": $quota_max_objects,
    "max_bytes": $quota_max_bytes
  },
  "alerts": $alerts_array
}
EOF_POOL
)
        first=false
        
    done < <(echo "$stats_pools")
    
    pools_array+="]"
    
    # Calculate total usage
    local total_used_hr=$(bytes_to_human "$total_used")
    local total_avail_hr=$(bytes_to_human "$total_avail")
    local total_capacity=$((total_used + total_avail))
    local total_usage_percent=0
    if [ "$total_capacity" -gt 0 ]; then
        total_usage_percent=$(awk "BEGIN {printf \"%.2f\", ($total_used / $total_capacity) * 100}")
    fi
    
    # Output final JSON
    cat <<EOF
{
  "pools": $pools_array,
  "summary": {
    "total_pools": $pool_count,
    "total_used": "$total_used_hr",
    "total_available": "$total_avail_hr",
    "total_usage_percent": $total_usage_percent,
    "highest_usage_pool": "$highest_usage_pool",
    "highest_usage_percent": $highest_usage_percent
  },
  "thresholds": {
    "warning": $WARN_THRESHOLD,
    "critical": $CRIT_THRESHOLD
  },
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
}

# Run main function
main "$@"
