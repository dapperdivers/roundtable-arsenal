#!/bin/bash
# ceph-osd-status.sh - Monitor Ceph OSD health and utilization
# Part of ceph-health-monitor skill v1.0.0

set -euo pipefail

# Configuration
NAMESPACE="${CEPH_NAMESPACE:-rook-ceph}"
TOOLS_DEPLOY="${CEPH_TOOLS_DEPLOY:-deploy/rook-ceph-tools}"
TIMEOUT="${CEPH_TIMEOUT:-30}"
WARN_THRESHOLD="${OSD_WARN_THRESHOLD:-85}"
CRIT_THRESHOLD="${OSD_CRIT_THRESHOLD:-95}"

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

# Function to get OSD tree (topology)
get_osd_tree() {
    exec_ceph "ceph osd tree --format=json"
}

# Function to get OSD utilization
get_osd_df() {
    exec_ceph "ceph osd df --format=json"
}

# Function to get OSD status
get_osd_stat() {
    exec_ceph "ceph osd stat --format=json"
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
    
    # Get OSD statistics
    local osd_stat_json
    if ! osd_stat_json=$(get_osd_stat 2>&1); then
        echo "{\"error\": \"Failed to get OSD stat\", \"details\": $(echo "$osd_stat_json" | jq -Rs .)}" >&2
        exit 1
    fi
    
    # Get OSD dataframe (utilization)
    local osd_df_json
    if ! osd_df_json=$(get_osd_df 2>&1); then
        echo "{\"error\": \"Failed to get OSD df\", \"details\": $(echo "$osd_df_json" | jq -Rs .)}" >&2
        exit 1
    fi
    
    # Get OSD tree (topology)
    local osd_tree_json
    if ! osd_tree_json=$(get_osd_tree 2>&1); then
        echo "{\"error\": \"Failed to get OSD tree\", \"details\": $(echo "$osd_tree_json" | jq -Rs .)}" >&2
        exit 1
    fi
    
    # Parse OSD summary from stat
    local num_osds=$(echo "$osd_stat_json" | jq -r '.num_osds // 0')
    local num_up_osds=$(echo "$osd_stat_json" | jq -r '.num_up_osds // 0')
    local num_in_osds=$(echo "$osd_stat_json" | jq -r '.num_in_osds // 0')
    local num_down=$(( num_osds - num_up_osds ))
    local num_out=$(( num_osds - num_in_osds ))
    
    # Build OSD details array
    local osds_array="["
    local first=true
    local alerts_array="["
    local alert_first=true
    
    # Parse each OSD from df output
    while IFS= read -r osd_entry; do
        local osd_id=$(echo "$osd_entry" | jq -r '.id // -1')
        [ "$osd_id" = "-1" ] && continue
        
        # Get OSD info from tree
        local osd_name="osd.$osd_id"
        local osd_host=$(echo "$osd_tree_json" | jq -r --arg id "$osd_id" \
            '.nodes[] | select(.type=="osd" and .id==($id|tonumber)) | .host // "unknown"' 2>/dev/null || echo "unknown")
        
        # Get utilization info from df
        local status=$(echo "$osd_entry" | jq -r '.status // "unknown"')
        local weight=$(echo "$osd_entry" | jq -r '.crush_weight // 0')
        local reweight=$(echo "$osd_entry" | jq -r '.reweight // 1.0')
        local var_usage=$(echo "$osd_entry" | jq -r '.var // 1.0')
        local pgs=$(echo "$osd_entry" | jq -r '.pgs // 0')
        
        # Size information (in KB from ceph)
        local kb_used=$(echo "$osd_entry" | jq -r '.kb_used // 0')
        local kb_avail=$(echo "$osd_entry" | jq -r '.kb_avail // 0') 
        local kb=$(echo "$osd_entry" | jq -r '.kb // 0')
        
        # Calculate usage percentage
        local usage_percent=0
        if [ "$kb" -gt 0 ]; then
            usage_percent=$(awk "BEGIN {printf \"%.2f\", ($kb_used / $kb) * 100}")
        fi
        
        # Convert KB to human readable
        local used_hr=$(awk "BEGIN {printf \"%.1f GiB\", $kb_used / 1048576}")
        local avail_hr=$(awk "BEGIN {printf \"%.1f GiB\", $kb_avail / 1048576}")
        local total_hr=$(awk "BEGIN {printf \"%.1f GiB\", $kb / 1048576}")
        
        # Add OSD to array
        [ "$first" = false ] && osds_array+=","
        osds_array+=$(cat <<EOF_OSD
{
  "id": $osd_id,
  "name": "$osd_name",
  "host": "$osd_host",
  "status": "$status",
  "weight": $weight,
  "reweight": $reweight,
  "variance": $var_usage,
  "usage_percent": $usage_percent,
  "used": "$used_hr",
  "available": "$avail_hr",
  "total": "$total_hr",
  "pgs": $pgs
}
EOF_OSD
)
        first=false
        
        # Check for alerts
        if (( $(awk "BEGIN {print ($usage_percent >= $CRIT_THRESHOLD)}") )); then
            [ "$alert_first" = false ] && alerts_array+=","
            alerts_array+=$(cat <<EOF_ALERT
{
  "severity": "critical",
  "osd_id": $osd_id,
  "osd_name": "$osd_name",
  "host": "$osd_host",
  "issue": "critical_utilization",
  "usage_percent": $usage_percent,
  "threshold": $CRIT_THRESHOLD
}
EOF_ALERT
)
            alert_first=false
        elif (( $(awk "BEGIN {print ($usage_percent >= $WARN_THRESHOLD)}") )); then
            [ "$alert_first" = false ] && alerts_array+=","
            alerts_array+=$(cat <<EOF_ALERT
{
  "severity": "warning",
  "osd_id": $osd_id,
  "osd_name": "$osd_name",
  "host": "$osd_host",
  "issue": "high_utilization",
  "usage_percent": $usage_percent,
  "threshold": $WARN_THRESHOLD
}
EOF_ALERT
)
            alert_first=false
        fi
        
    done < <(echo "$osd_df_json" | jq -c '.nodes[]? // empty')
    
    osds_array+="]"
    alerts_array+="]"
    
    # Output final JSON
    cat <<EOF
{
  "osd_summary": {
    "total": $num_osds,
    "up": $num_up_osds,
    "in": $num_in_osds,
    "down": $num_down,
    "out": $num_out
  },
  "osds": $osds_array,
  "alerts": $alerts_array,
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
