---
name: ceph-health-monitor
description: Monitor Rook-Ceph cluster health via kubectl exec into rook-ceph-tools pod. Use for storage health checks, OSD analysis, pool monitoring, and alert generation.
allowed-tools: Bash(kubectl:*,jq:*) Read
metadata:
  author: roundtable
  version: "1.0"
  tier: infra
  compatibility: Requires kubectl access to rook-ceph namespace and rook-ceph-tools deployment
---

# Ceph Health Monitor

**Version:** 1.0.0  
**Author:** Tristan (Infrastructure Knight)  
**Category:** Infrastructure Monitoring  
**Tags:** ceph, storage, rook, monitoring, health-check  
**Spec Version:** AgentSkills.io v1.0

## Overview

Monitors Rook-Ceph cluster health by executing diagnostic commands inside the rook-ceph-tools pod. Provides structured health status, OSD analysis, pool utilization, and actionable alerts for storage infrastructure.

## Capabilities

- **Health Status Monitoring**: Execute `ceph status` and parse cluster health state
- **OSD Analysis**: Monitor Object Storage Daemon health, utilization, and performance
- **Pool Monitoring**: Track pool usage, quotas, and PG distribution
- **Alert Generation**: Convert Ceph warnings/errors into structured JSON alerts
- **Trend Analysis**: Track storage growth and capacity planning metrics

## Prerequisites

### RBAC Requirements

This skill requires the ability to execute commands in pods:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ceph-diagnostics
  namespace: rook-ceph
rules:
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
```

### Cluster Requirements

- Rook-Ceph deployed in `rook-ceph` namespace
- `rook-ceph-tools` deployment running
- Ceph cluster operational (connected state)

## Usage

### Check Overall Cluster Health

```bash
./scripts/ceph-status.sh
```

**Example Output:**
```json
{
  "cluster_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "health_status": "HEALTH_WARN",
  "overall_status": "Connected",
  "mon_status": "3 mons up, quorum a,b,c",
  "mgr_status": "Active: a, Standbys: b",
  "osd_status": "12 osds: 12 up, 12 in",
  "pg_status": "1024 pgs: 1024 active+clean",
  "data": {
    "pools": 5,
    "objects": 1234567,
    "usage": "2.3 TiB used, 3.7 TiB available, 6.0 TiB total",
    "usage_percent": 38.3
  },
  "health_checks": [
    {
      "severity": "HEALTH_WARN",
      "message": "1 pool(s) nearfull",
      "detail": "pool 'rbd' has 85% usage"
    }
  ],
  "timestamp": "2026-03-17T18:30:00Z"
}
```

### Monitor OSD Health

```bash
./scripts/ceph-osd-status.sh
```

**Example Output:**
```json
{
  "osd_summary": {
    "total": 12,
    "up": 12,
    "in": 12,
    "down": 0,
    "out": 0
  },
  "osds": [
    {
      "id": 0,
      "host": "node-large-1",
      "status": "up",
      "weight": 1.0,
      "reweight": 1.0,
      "usage_percent": 42.5,
      "used": "850 GiB",
      "available": "1150 GiB",
      "total": "2000 GiB",
      "pgs": 89
    }
  ],
  "alerts": [
    {
      "severity": "warning",
      "osd_id": 5,
      "issue": "high_utilization",
      "usage_percent": 87.2,
      "threshold": 85.0
    }
  ],
  "timestamp": "2026-03-17T18:30:00Z"
}
```

### Check Pool Status

```bash
./scripts/ceph-pool-status.sh
```

**Example Output:**
```json
{
  "pools": [
    {
      "name": "ceph-rbd",
      "id": 1,
      "type": "replicated",
      "size": 3,
      "min_size": 2,
      "pg_num": 256,
      "pgp_num": 256,
      "usage": {
        "stored": "456 GiB",
        "objects": 123456,
        "used": "1.37 TiB",
        "max_avail": "1.8 TiB",
        "percent_used": 43.2
      },
      "quota": {
        "max_objects": null,
        "max_bytes": null
      },
      "status": "active"
    },
    {
      "name": "cephfs-data",
      "id": 2,
      "type": "replicated",
      "size": 3,
      "usage": {
        "percent_used": 87.5
      },
      "alerts": [
        {
          "severity": "warning",
          "issue": "nearfull",
          "threshold": 85.0
        }
      ]
    }
  ],
  "summary": {
    "total_pools": 5,
    "total_usage": "2.3 TiB",
    "total_available": "3.7 TiB",
    "highest_usage_pool": "cephfs-data",
    "highest_usage_percent": 87.5
  },
  "timestamp": "2026-03-17T18:30:00Z"
}
```

### Parse Health Alerts

```bash
./scripts/ceph-alerts.sh
```

**Example Output:**
```json
{
  "cluster_health": "HEALTH_WARN",
  "alert_count": {
    "critical": 0,
    "warning": 2,
    "info": 1
  },
  "alerts": [
    {
      "severity": "HEALTH_WARN",
      "code": "POOL_NEARFULL",
      "message": "1 pool(s) nearfull",
      "detail": "pool 'cephfs-data' has 87% usage (>= 85% nearfull threshold)",
      "affected_resource": "pool:cephfs-data",
      "recommended_action": "Add OSDs or reduce data in pool",
      "documentation": "https://docs.ceph.com/en/latest/rados/operations/health-checks/#pool-nearfull"
    },
    {
      "severity": "HEALTH_WARN",
      "code": "OSD_NEARFULL",
      "message": "1 OSD nearfull",
      "detail": "osd.5 is 87% full (>= 85% nearfull threshold)",
      "affected_resource": "osd:5",
      "recommended_action": "Rebalance data or add capacity",
      "documentation": "https://docs.ceph.com/en/latest/rados/operations/health-checks/#osd-nearfull"
    },
    {
      "severity": "HEALTH_OK",
      "code": "PG_AVAILABILITY",
      "message": "Reduced data availability: 12 pgs inactive",
      "detail": "12 pgs are not active+clean (peering or degraded)",
      "affected_resource": "pg:multiple",
      "recommended_action": "Monitor - PGs may be recovering after rebalance",
      "auto_resolve": true,
      "ttl_minutes": 30
    }
  ],
  "timestamp": "2026-03-17T18:30:00Z",
  "next_check": "2026-03-17T18:35:00Z"
}
```

## Health Status Interpretation

### Health States

| State | Severity | Description | Action Required |
|-------|----------|-------------|-----------------|
| **HEALTH_OK** | ✅ Normal | Cluster is healthy, all systems operational | None - routine monitoring |
| **HEALTH_WARN** | ⚠️ Warning | Non-critical issues detected, cluster functional | Investigate and plan remediation |
| **HEALTH_ERR** | 🔴 Critical | Critical issues affecting availability/durability | Immediate action required |

### Common Health Checks

#### POOL_NEARFULL / POOL_FULL
- **Severity:** Warning / Critical
- **Cause:** Pool usage exceeds thresholds (85% nearfull, 95% full)
- **Impact:** May block writes when full
- **Remediation:**
  1. Check pool usage: `ceph df detail`
  2. Identify large objects/files consuming space
  3. Add OSDs to increase capacity
  4. Delete unused data or snapshots
  5. Adjust pool quotas if applicable

#### OSD_NEARFULL / OSD_FULL
- **Severity:** Warning / Critical
- **Cause:** Individual OSD exceeds capacity thresholds
- **Impact:** Unbalanced cluster, potential performance degradation
- **Remediation:**
  1. Check OSD tree: `ceph osd tree`
  2. Verify OSD weights are balanced
  3. Trigger rebalancing: `ceph osd reweight-by-utilization`
  4. Add OSDs to overloaded nodes
  5. Check for failed OSDs preventing rebalancing

#### PG_DEGRADED / PG_UNDERSIZED
- **Severity:** Warning
- **Cause:** Placement groups don't have enough copies
- **Impact:** Reduced data redundancy
- **Remediation:**
  1. Check PG status: `ceph pg stat`
  2. Verify all OSDs are up: `ceph osd stat`
  3. Wait for recovery to complete (monitor `ceph -s`)
  4. If persistent, check for failed OSDs or network issues

#### MON_DOWN / MON_CLOCK_SKEW
- **Severity:** Warning / Critical
- **Cause:** Monitor daemon down or time synchronization issue
- **Impact:** Quorum at risk, potential split-brain
- **Remediation:**
  1. Check monitor status: `ceph mon stat`
  2. Verify time sync across all nodes (NTP/chrony)
  3. Restart failed monitor daemon
  4. Check network connectivity between monitors

#### SLOW_OPS / REQUEST_SLOW
- **Severity:** Warning
- **Cause:** Operations taking longer than expected
- **Impact:** Performance degradation, client timeouts
- **Remediation:**
  1. Check OSD performance: `ceph osd perf`
  2. Review disk I/O wait times on OSD hosts
  3. Check network latency between nodes
  4. Look for failing or slow disks
  5. Review OSD logs for errors

#### CACHE_POOL_NEAR_FULL
- **Severity:** Warning
- **Cause:** Cache tier approaching capacity
- **Impact:** Cache eviction, performance impact
- **Remediation:**
  1. Increase cache pool size
  2. Adjust cache tier settings (target_max_bytes)
  3. Review cache hit ratio effectiveness

## Alert Thresholds and Severity

### Storage Capacity Thresholds

| Metric | Warning | Critical | Notes |
|--------|---------|----------|-------|
| Pool Usage | 85% | 95% | Per-pool utilization |
| OSD Usage | 85% | 95% | Individual OSD capacity |
| Cluster Usage | 80% | 90% | Overall cluster capacity |

### Performance Thresholds

| Metric | Warning | Critical | Notes |
|--------|---------|----------|-------|
| Slow Ops | >10 | >50 | Operations taking >30s |
| Request Latency | >100ms | >500ms | Average operation time |
| Recovery Rate | <10 MB/s | <5 MB/s | Data recovery speed |

### Availability Thresholds

| Metric | Warning | Critical | Notes |
|--------|---------|----------|-------|
| OSDs Down | 1 | >2 | Per failure domain |
| Monitors Down | 1 | >1 (no quorum) | Monitor availability |
| PGs Degraded | >5% | >20% | Percentage of total PGs |
| PGs Inactive | >0 | >10% | PGs not serving I/O |

## Common Issues and Remediation

### Issue: Persistent HEALTH_WARN with no clear cause

**Diagnosis:**
```bash
./scripts/ceph-alerts.sh
ceph health detail
```

**Common Causes:**
1. Old health check not cleared
2. Silent background recovery
3. Timing-based warnings (clock skew)

**Resolution:**
```bash
# Force health check update
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph health mute <CHECK_NAME>
# Or wait for auto-clear (many warnings auto-resolve)
```

### Issue: High OSD utilization variance

**Diagnosis:**
```bash
./scripts/ceph-osd-status.sh
```

**Resolution:**
```bash
# Rebalance by utilization
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  ceph osd reweight-by-utilization 110
  
# Or rebalance by PG count
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  ceph osd reweight-by-pg 110
```

### Issue: Slow recovery/backfill

**Diagnosis:**
```bash
# Check recovery priority
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph progress
```

**Resolution:**
```bash
# Adjust recovery throttling (increase speed)
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  ceph tell 'osd.*' config set osd_max_backfills 2
  
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- \
  ceph tell 'osd.*' config set osd_recovery_max_active 4
```

### Issue: PGs stuck in peering

**Diagnosis:**
```bash
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph pg dump | grep peering
```

**Resolution:**
```bash
# Query stuck PG
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph pg <pgid> query

# If safe, force PG creation
kubectl -n rook-ceph exec deploy/rook-ceph-tools -- ceph pg force-create-pg <pgid>
```

## Integration Examples

### Continuous Monitoring Loop

```bash
#!/bin/bash
# Monitor Ceph health every 5 minutes

while true; do
  echo "=== Ceph Health Check $(date) ==="
  
  # Run health check
  ./scripts/ceph-status.sh > /tmp/ceph-status.json
  
  # Parse alerts
  ./scripts/ceph-alerts.sh > /tmp/ceph-alerts.json
  
  # Check for critical issues
  CRITICAL_COUNT=$(jq -r '.alert_count.critical' /tmp/ceph-alerts.json)
  
  if [ "$CRITICAL_COUNT" -gt 0 ]; then
    echo "🔴 CRITICAL: $CRITICAL_COUNT critical alerts detected"
    # Send notification (integrate with alerting system)
    cat /tmp/ceph-alerts.json | jq '.alerts[] | select(.severity=="HEALTH_ERR")'
  fi
  
  sleep 300  # 5 minutes
done
```

### Health Report Generation

```bash
#!/bin/bash
# Generate daily Ceph health report

REPORT_DATE=$(date +%Y-%m-%d)
REPORT_FILE="/reports/ceph-health-${REPORT_DATE}.md"

cat > "$REPORT_FILE" << EOF
# Ceph Health Report - ${REPORT_DATE}

## Cluster Status
\`\`\`json
$(./scripts/ceph-status.sh)
\`\`\`

## OSD Status
\`\`\`json
$(./scripts/ceph-osd-status.sh)
\`\`\`

## Pool Status
\`\`\`json
$(./scripts/ceph-pool-status.sh)
\`\`\`

## Active Alerts
\`\`\`json
$(./scripts/ceph-alerts.sh)
\`\`\`

---
Report generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

echo "Report saved to: $REPORT_FILE"
```

## Troubleshooting

### Script fails with "rook-ceph-tools not found"

**Cause:** Tools pod not deployed or in different namespace

**Solution:**
```bash
# Check if tools pod exists
kubectl get deployment -n rook-ceph rook-ceph-tools

# If not found, deploy it
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rook-ceph-tools
  namespace: rook-ceph
spec:
  replicas: 1
  selector:
    matchLabels:
      app: rook-ceph-tools
  template:
    metadata:
      labels:
        app: rook-ceph-tools
    spec:
      containers:
      - name: rook-ceph-tools
        image: rook/ceph:v1.15.0
        command: ["/bin/bash"]
        args: ["-c", "sleep infinity"]
        env:
        - name: ROOK_CEPH_USERNAME
          valueFrom:
            secretKeyRef:
              name: rook-ceph-mon
              key: ceph-username
        - name: ROOK_CEPH_SECRET
          valueFrom:
            secretKeyRef:
              name: rook-ceph-mon
              key: ceph-secret
EOF
```

### Script fails with "Permission denied"

**Cause:** Insufficient RBAC permissions

**Solution:** Apply the RBAC role from Prerequisites section, then bind it to your ServiceAccount.

### Ceph commands timeout

**Cause:** Ceph cluster unresponsive or severely degraded

**Solution:**
1. Check if OSDs are running: `kubectl get pods -n rook-ceph -l app=rook-ceph-osd`
2. Check monitor quorum: `kubectl get pods -n rook-ceph -l app=rook-ceph-mon`
3. Increase timeout in scripts (add `--connect-timeout=30` to ceph commands)

## Performance Considerations

- **Execution Time:** Each script takes 1-5 seconds depending on cluster size
- **API Load:** Minimal - single kubectl exec per invocation
- **Ceph Load:** Negligible - status commands are read-only and cached
- **Recommended Frequency:** 
  - Health status: Every 1-5 minutes
  - OSD/Pool status: Every 5-15 minutes
  - Detailed analysis: Every 30-60 minutes

## Security Considerations

- Scripts execute with permissions of calling user's ServiceAccount
- No credentials stored - uses Kubernetes RBAC delegation
- Ceph admin credentials accessed via rook-ceph-tools pod context
- Output may contain sensitive cluster topology information
- Restrict access to scripts via filesystem permissions

## Related Skills

- `k8s-resource-monitor` - Kubernetes cluster resource monitoring
- `storage-capacity-planner` - Storage capacity planning and forecasting
- `volume-snapshot-manager` - PVC and VolumeSnapshot management
- `disaster-recovery-validator` - Backup and DR validation

## Changelog

### v1.0.0 (2026-03-17)
- Initial release
- Basic health monitoring (status, OSD, pools, alerts)
- JSON output format
- Common issue remediation guide
- Alert threshold documentation

## License

MIT License - Part of Roundtable Knight Skills Collection

## Support

For issues or enhancements, contact the Infrastructure Knight (Tristan) or submit to the skills repository.
