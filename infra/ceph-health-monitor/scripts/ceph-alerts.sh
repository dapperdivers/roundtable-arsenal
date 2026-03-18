#!/bin/bash
# ceph-alerts.sh - Parse Ceph health warnings/errors into structured JSON alerts
# Part of ceph-health-monitor skill v1.0.0

set -euo pipefail

# Configuration
NAMESPACE="${CEPH_NAMESPACE:-rook-ceph}"
TOOLS_DEPLOY="${CEPH_TOOLS_DEPLOY:-deploy/rook-ceph-tools}"
TIMEOUT="${CEPH_TIMEOUT:-30}"

# Check dependencies
for cmd in kubectl jq; do
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

# Function to get health check documentation URL
get_health_check_url() {
    local check_code="$1"
    echo "https://docs.ceph.com/en/latest/rados/operations/health-checks/#${check_code,,}"
}

# Function to get recommended action for health check
get_recommended_action() {
    local check_code="$1"
    local detail="$2"
    
    case "$check_code" in
        POOL_NEARFULL|POOL_FULL)
            echo "Add OSDs to increase capacity or delete unused data/snapshots"
            ;;
        OSD_NEARFULL|OSD_FULL)
            echo "Rebalance data using 'ceph osd reweight-by-utilization' or add capacity"
            ;;
        PG_DEGRADED|PG_UNDERSIZED)
            echo "Wait for recovery to complete; check for failed OSDs or network issues"
            ;;
        PG_DAMAGED)
            echo "CRITICAL: Data corruption detected. Review ceph pg query for affected PG"
            ;;
        MON_DOWN)
            echo "Restart failed monitor daemon and verify time synchronization"
            ;;
        MON_CLOCK_SKEW)
            echo "Synchronize clocks across all nodes using NTP/chrony"
            ;;
        OSD_DOWN|OSD_OUT)
            echo "Check OSD host connectivity and disk health; restart OSD daemon if needed"
            ;;
        SLOW_OPS|REQUEST_SLOW)
            echo "Check OSD disk I/O performance and network latency between nodes"
            ;;
        CACHE_POOL_NEAR_FULL)
            echo "Increase cache pool size or adjust cache tier target_max_bytes setting"
            ;;
        TOO_FEW_PGS|TOO_MANY_PGS)
            echo "Adjust PG count for pools using 'ceph osd pool set <pool> pg_num <value>'"
            ;;
        POOL_APP_NOT_ENABLED)
            echo "Enable application on pool: 'ceph osd pool application enable <pool> <app>'"
            ;;
        *)
            echo "Review health detail and Ceph documentation for specific remediation"
            ;;
    esac
}

# Function to determine if health check auto-resolves
is_auto_resolve() {
    local check_code="$1"
    
    case "$check_code" in
        PG_DEGRADED|PG_UNDERSIZED|PG_ACTIVATING|PG_PEERING)
            echo "true"
            ;;
        SLOW_OPS|REQUEST_SLOW)
            echo "true"
            ;;
        OSD_BACKFILLTOFULL|OSD_NEARFULL)
            echo "true"  # May auto-resolve after rebalance
            ;;
        *)
            echo "false"
            ;;
    esac
}

# Function to get TTL for auto-resolving alerts (in minutes)
get_auto_resolve_ttl() {
    local check_code="$1"
    
    case "$check_code" in
        PG_DEGRADED|PG_UNDERSIZED)
            echo "30"  # PG recovery usually completes within 30 min
            ;;
        SLOW_OPS|REQUEST_SLOW)
            echo "15"  # Transient performance issues
            ;;
        OSD_BACKFILLTOFULL)
            echo "60"  # Rebalancing may take longer
            ;;
        *)
            echo "60"  # Default 1 hour
            ;;
    esac
}

# Function to parse severity level
get_severity_level() {
    local health_status="$1"
    
    case "$health_status" in
        HEALTH_ERR)
            echo "critical"
            ;;
        HEALTH_WARN)
            echo "warning"
            ;;
        HEALTH_OK)
            echo "info"
            ;;
        *)
            echo "unknown"
            ;;
    esac
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
    
    # Get health detail in JSON format
    local health_json
    if ! health_json=$(exec_ceph "ceph health detail --format=json" 2>&1); then
        echo "{\"error\": \"Failed to get health detail\", \"details\": $(echo "$health_json" | jq -Rs .)}" >&2
        exit 1
    fi
    
    # Extract overall health status
    local overall_health=$(echo "$health_json" | jq -r '.status // "UNKNOWN"')
    
    # Count alerts by severity
    local critical_count=0
    local warning_count=0
    local info_count=0
    
    # Parse health checks
    local alerts_array="["
    local first=true
    
    # Process each health check
    while IFS= read -r check; do
        local severity=$(echo "$check" | jq -r '.severity // "UNKNOWN"')
        local check_code=$(echo "$check" | jq -r '.type // "UNKNOWN"')
        local summary=$(echo "$check" | jq -r '.summary.message // "No message"')
        
        # Extract detail message (combine all detail entries)
        local detail_msg=""
        local detail_entries=$(echo "$check" | jq -r '.detail[]? // empty')
        if [ -n "$detail_entries" ]; then
            detail_msg=$(echo "$detail_entries" | jq -rs 'join("; ")')
        else
            detail_msg="$summary"
        fi
        
        # Get metadata for this check
        local recommended_action=$(get_recommended_action "$check_code" "$detail_msg")
        local doc_url=$(get_health_check_url "$check_code")
        local auto_resolve=$(is_auto_resolve "$check_code")
        local ttl_minutes=$(get_auto_resolve_ttl "$check_code")
        
        # Parse affected resource from detail
        local affected_resource="cluster"
        if [[ "$detail_msg" =~ pool[[:space:]]\'([^\']+)\' ]]; then
            affected_resource="pool:${BASH_REMATCH[1]}"
        elif [[ "$detail_msg" =~ osd\.([0-9]+) ]]; then
            affected_resource="osd:${BASH_REMATCH[1]}"
        elif [[ "$detail_msg" =~ pg[[:space:]]([0-9]+\.[0-9a-f]+) ]]; then
            affected_resource="pg:${BASH_REMATCH[1]}"
        elif [[ "$detail_msg" =~ mon\.([a-z0-9]+) ]]; then
            affected_resource="mon:${BASH_REMATCH[1]}"
        fi
        
        # Count by severity
        case "$severity" in
            HEALTH_ERR)
                critical_count=$((critical_count + 1))
                ;;
            HEALTH_WARN)
                warning_count=$((warning_count + 1))
                ;;
            HEALTH_OK)
                info_count=$((info_count + 1))
                ;;
        esac
        
        # Build alert JSON
        [ "$first" = false ] && alerts_array+=","
        
        if [ "$auto_resolve" = "true" ]; then
            alerts_array+=$(cat <<EOF_ALERT
{
  "severity": "$severity",
  "severity_level": "$(get_severity_level "$severity")",
  "code": "$check_code",
  "message": $(echo "$summary" | jq -Rs .),
  "detail": $(echo "$detail_msg" | jq -Rs .),
  "affected_resource": "$affected_resource",
  "recommended_action": "$recommended_action",
  "documentation": "$doc_url",
  "auto_resolve": true,
  "ttl_minutes": $ttl_minutes
}
EOF_ALERT
)
        else
            alerts_array+=$(cat <<EOF_ALERT
{
  "severity": "$severity",
  "severity_level": "$(get_severity_level "$severity")",
  "code": "$check_code",
  "message": $(echo "$summary" | jq -Rs .),
  "detail": $(echo "$detail_msg" | jq -Rs .),
  "affected_resource": "$affected_resource",
  "recommended_action": "$recommended_action",
  "documentation": "$doc_url",
  "auto_resolve": false
}
EOF_ALERT
)
        fi
        
        first=false
        
    done < <(echo "$health_json" | jq -c '.checks[]? // empty')
    
    alerts_array+="]"
    
    # Calculate next check time (5 minutes from now)
    local next_check=$(date -u -d '+5 minutes' +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v+5M +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "")
    
    # Output final JSON
    cat <<EOF
{
  "cluster_health": "$overall_health",
  "alert_count": {
    "critical": $critical_count,
    "warning": $warning_count,
    "info": $info_count
  },
  "alerts": $alerts_array,
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "next_check": "$next_check"
}
EOF
}

# Run main function
main "$@"
