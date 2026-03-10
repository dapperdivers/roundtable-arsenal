# Ceph Health Monitoring Skill

**Knight:** Tristan (Infrastructure Monitoring)

## Overview

Monitors Ceph cluster health via the Rook-Ceph tools pod in Kubernetes. Outputs structured JSON for automated alerting and dashboards.

## Requirements

- `kubectl` with access to the `rook-ceph` namespace
- `jq` for JSON construction
- A running `rook-ceph-tools` pod (labeled `app=rook-ceph-tools`)

## Usage

```bash
./ceph-health.sh
```

### Output

Returns a JSON object with:

| Field | Description |
|-------|-------------|
| `overall_health` | Ceph health status (HEALTH_OK, HEALTH_WARN, HEALTH_ERR) |
| `mon_count` | Number of monitors |
| `osd_count` | Total OSDs |
| `osd_up` | OSDs currently up |
| `osd_down` | OSDs currently down |
| `pg_status` | Placement group summary |
| `pool_usage` | Per-pool usage stats |
| `warnings` | Active health warnings/details |
| `timestamp` | ISO 8601 timestamp of the check |

### Exit Codes

- `0` — Success
- `1` — rook-ceph-tools pod not found or kubectl error

## Integration

Tristan runs this on a schedule and alerts on:
- `overall_health` != `HEALTH_OK`
- Any `osd_down` > 0
- Non-empty `warnings`
