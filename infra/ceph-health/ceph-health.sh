#!/usr/bin/env bash
# Ceph Health Monitoring Skill
# Knight: Tristan — Infrastructure Monitoring
# Queries Rook-Ceph tools pod for cluster health and outputs structured JSON.
set -euo pipefail

NAMESPACE="rook-ceph"
LABEL="app=rook-ceph-tools"

# Find the tools pod
TOOLS_POD=$(kubectl get pods -n "$NAMESPACE" -l "$LABEL" -o name 2>/dev/null | head -n1)

if [[ -z "$TOOLS_POD" ]]; then
  echo '{"error":"rook-ceph-tools pod not found","timestamp":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}' | jq .
  exit 1
fi

ceph_exec() {
  kubectl exec -n "$NAMESPACE" "$TOOLS_POD" -- "$@" 2>/dev/null
}

# Gather raw data
STATUS_JSON=$(ceph_exec ceph status -f json 2>/dev/null || echo '{}')
HEALTH_DETAIL=$(ceph_exec ceph health detail 2>/dev/null || echo '')
OSD_DF_JSON=$(ceph_exec ceph osd df -f json 2>/dev/null || echo '{}')
CEPH_DF_JSON=$(ceph_exec ceph df -f json 2>/dev/null || echo '{}')

# Parse fields
OVERALL_HEALTH=$(echo "$STATUS_JSON" | jq -r '.health.status // "UNKNOWN"')
MON_COUNT=$(echo "$STATUS_JSON" | jq '.monmap.num_mons // 0')
OSD_COUNT=$(echo "$STATUS_JSON" | jq '.osdmap.num_osds // 0')
OSD_UP=$(echo "$STATUS_JSON" | jq '.osdmap.num_up_osds // 0')
OSD_DOWN=$(( ${OSD_COUNT:-0} - ${OSD_UP:-0} ))

# PG summary
PG_STATUS=$(echo "$STATUS_JSON" | jq '[.pgmap.pgs_by_state[]? | "\(.count) \(.state_name)"] // []')

# Pool usage from ceph df
POOL_USAGE=$(echo "$CEPH_DF_JSON" | jq '[.pools[]? | {name: .name, used_bytes: .stats.bytes_used, percent_used: .stats.percent_used, max_avail: .stats.max_avail}] // []')

# Warnings from health detail
WARNINGS=$(echo "$STATUS_JSON" | jq '[.health.checks // {} | to_entries[] | {code: .key, severity: .value.severity.severity, message: .value.summary.message}] // []')

# Build output
jq -n \
  --arg health "$OVERALL_HEALTH" \
  --argjson mon_count "$MON_COUNT" \
  --argjson osd_count "$OSD_COUNT" \
  --argjson osd_up "$OSD_UP" \
  --argjson osd_down "$OSD_DOWN" \
  --argjson pg_status "$PG_STATUS" \
  --argjson pool_usage "$POOL_USAGE" \
  --argjson warnings "$WARNINGS" \
  --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{
    overall_health: $health,
    mon_count: $mon_count,
    osd_count: $osd_count,
    osd_up: $osd_up,
    osd_down: $osd_down,
    pg_status: $pg_status,
    pool_usage: $pool_usage,
    warnings: $warnings,
    timestamp: $timestamp
  }'
