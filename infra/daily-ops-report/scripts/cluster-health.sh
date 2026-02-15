#!/usr/bin/env bash
# cluster-health.sh — Automated cluster health checks for Tristan's daily report
# Outputs JSON to stdout. Pipe to jq or consume programmatically.
set -euo pipefail

# ---------- helpers ----------
now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
stderr() { echo "[cluster-health] $*" >&2; }

# ---------- pod status summary ----------
pod_summary() {
  stderr "Collecting pod status..."
  local pods_json
  pods_json=$(kubectl get pods -A -o json 2>/dev/null || echo '{"items":[]}')

  local running pending failed succeeded crashloop
  running=$(echo "$pods_json" | jq '[.items[] | select(.status.phase=="Running")] | length')
  pending=$(echo "$pods_json" | jq '[.items[] | select(.status.phase=="Pending")] | length')
  failed=$(echo "$pods_json" | jq '[.items[] | select(.status.phase=="Failed")] | length')
  succeeded=$(echo "$pods_json" | jq '[.items[] | select(.status.phase=="Succeeded")] | length')
  crashloop=$(echo "$pods_json" | jq '[.items[] | select(.status.containerStatuses[]? | .state.waiting.reason=="CrashLoopBackOff")] | length')

  # High-restart pods (>3 restarts)
  local high_restart
  high_restart=$(echo "$pods_json" | jq '[.items[] | select(.status.containerStatuses[]?.restartCount > 3) | {
    name: .metadata.name,
    namespace: .metadata.namespace,
    restarts: (.status.containerStatuses[0].restartCount),
    status: (.status.phase)
  }]')

  # Problem pods (not Running/Succeeded)
  local problem_pods
  problem_pods=$(echo "$pods_json" | jq '[.items[] | select(.status.phase != "Running" and .status.phase != "Succeeded") | {
    name: .metadata.name,
    namespace: .metadata.namespace,
    status: .status.phase,
    reason: (.status.containerStatuses[0]?.state.waiting.reason // .status.reason // "Unknown")
  }] | .[0:20]')

  jq -n \
    --argjson running "$running" \
    --argjson pending "$pending" \
    --argjson failed "$failed" \
    --argjson succeeded "$succeeded" \
    --argjson crashloop "$crashloop" \
    --argjson high_restart "$high_restart" \
    --argjson problem_pods "$problem_pods" \
    '{running: $running, pending: $pending, failed: $failed, succeeded: $succeeded, crashloop: $crashloop, high_restart: $high_restart, problem_pods: $problem_pods}'
}

# ---------- flux reconciliation ----------
flux_status() {
  stderr "Collecting Flux status..."

  if ! command -v flux &>/dev/null; then
    echo '{"available": false}'
    return
  fi

  local ks_json hr_json failed_json suspended_json
  ks_json=$(flux get ks -A -o json 2>/dev/null || echo '[]')
  hr_json=$(flux get hr -A -o json 2>/dev/null || echo '[]')
  failed_json=$(flux get all -A --status-selector ready=false -o json 2>/dev/null || echo '[]')
  suspended_json=$(flux get all -A --status-selector suspended=true -o json 2>/dev/null || echo '[]')

  local ks_total ks_ready ks_failed hr_total hr_ready hr_failed
  ks_total=$(echo "$ks_json" | jq 'length')
  ks_ready=$(echo "$ks_json" | jq '[.[] | select(.isReady==true)] | length')
  ks_failed=$((ks_total - ks_ready))

  hr_total=$(echo "$hr_json" | jq 'length')
  hr_ready=$(echo "$hr_json" | jq '[.[] | select(.isReady==true)] | length')
  hr_failed=$((hr_total - hr_ready))

  local failed_count suspended_count
  failed_count=$(echo "$failed_json" | jq 'length')
  suspended_count=$(echo "$suspended_json" | jq 'length')

  local failures
  failures=$(echo "$failed_json" | jq '[.[] | {name: .name, namespace: .namespace, kind: .kind, message: .message}] | .[0:10]')

  jq -n \
    --argjson ks_total "$ks_total" \
    --argjson ks_ready "$ks_ready" \
    --argjson ks_failed "$ks_failed" \
    --argjson hr_total "$hr_total" \
    --argjson hr_ready "$hr_ready" \
    --argjson hr_failed "$hr_failed" \
    --argjson failed_total "$failed_count" \
    --argjson suspended "$suspended_count" \
    --argjson failures "$failures" \
    '{available: true, kustomizations: {total: $ks_total, ready: $ks_ready, failed: $ks_failed}, helmreleases: {total: $hr_total, ready: $hr_ready, failed: $hr_failed}, failed_total: $failed_total, suspended: $suspended, failures: $failures}'
}

# ---------- node health ----------
node_health() {
  stderr "Collecting node health..."
  local nodes_json
  nodes_json=$(kubectl get nodes -o json 2>/dev/null || echo '{"items":[]}')

  local node_summary
  node_summary=$(echo "$nodes_json" | jq '[.items[] | {
    name: .metadata.name,
    status: (if (.status.conditions[] | select(.type=="Ready") | .status) == "True" then "Ready" else "NotReady" end),
    memory_pressure: (.status.conditions[] | select(.type=="MemoryPressure") | .status),
    disk_pressure: (.status.conditions[] | select(.type=="DiskPressure") | .status),
    pid_pressure: (.status.conditions[] | select(.type=="PIDPressure") | .status),
    kubelet_version: .status.nodeInfo.kubeletVersion
  }]')

  # Resource usage via top (may fail if metrics-server unavailable)
  local top_nodes
  top_nodes=$(kubectl top nodes --no-headers 2>/dev/null | awk '{print "{\"name\":\""$1"\",\"cpu_cores\":\""$2"\",\"cpu_pct\":\""$3"\",\"mem_bytes\":\""$4"\",\"mem_pct\":\""$5"\"}"}' | jq -s '.' 2>/dev/null || echo '[]')

  jq -n \
    --argjson nodes "$node_summary" \
    --argjson usage "$top_nodes" \
    '{nodes: $nodes, usage: $usage}'
}

# ---------- PVC usage ----------
pvc_status() {
  stderr "Collecting PVC status..."
  local pvcs
  pvcs=$(kubectl get pvc -A -o json 2>/dev/null || echo '{"items":[]}')

  echo "$pvcs" | jq '[.items[] | {
    name: .metadata.name,
    namespace: .metadata.namespace,
    status: .status.phase,
    capacity: (.status.capacity.storage // "unknown"),
    storage_class: (.spec.storageClassName // "default")
  }]'
}

# ---------- certificates ----------
cert_status() {
  stderr "Collecting certificate status..."
  local certs
  certs=$(kubectl get certificates -A -o json 2>/dev/null || echo '{"items":[]}')

  local thirty_days_from_now
  thirty_days_from_now=$(date -u -d '+30 days' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v+30d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")

  echo "$certs" | jq --arg cutoff "$thirty_days_from_now" '[.items[] | {
    name: .metadata.name,
    namespace: .metadata.namespace,
    not_after: (.status.notAfter // "unknown"),
    ready: (.status.conditions[]? | select(.type=="Ready") | .status),
    expiring_soon: (if $cutoff != "" and .status.notAfter != null then (.status.notAfter < $cutoff) else false end)
  }]'
}

# ---------- recent events (warnings) ----------
recent_warnings() {
  stderr "Collecting recent warning events..."
  kubectl get events -A --field-selector type=Warning --sort-by='.lastTimestamp' -o json 2>/dev/null \
    | jq '[.items[-20:] | .[] | {
        namespace: .metadata.namespace,
        reason: .reason,
        message: (.message | .[0:120]),
        count: .count,
        last_seen: .lastTimestamp,
        object: (.involvedObject.kind + "/" + .involvedObject.name)
      }]' 2>/dev/null || echo '[]'
}

# ---------- assemble ----------
main() {
  stderr "Starting cluster health check at $(now_iso)"

  local pods flux nodes pvcs certs warnings

  pods=$(pod_summary)
  flux=$(flux_status)
  nodes=$(node_health)
  pvcs=$(pvc_status)
  certs=$(cert_status)
  warnings=$(recent_warnings)

  jq -n \
    --arg timestamp "$(now_iso)" \
    --argjson pods "$pods" \
    --argjson flux "$flux" \
    --argjson nodes "$nodes" \
    --argjson pvcs "$pvcs" \
    --argjson certs "$certs" \
    --argjson warnings "$warnings" \
    '{
      timestamp: $timestamp,
      pods: $pods,
      flux: $flux,
      nodes: $nodes,
      pvcs: $pvcs,
      certificates: $certs,
      recent_warnings: $warnings
    }'

  stderr "Done."
}

main "$@"
