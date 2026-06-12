---
name: telemetry-queries
description: Query Prometheus and Victoria Logs for Round Table platform errors. Use during the Night Watch sweep to collect the last 24h of failures from the roundtable namespace.
---

# Telemetry Queries — Night Watch Collection

In-cluster endpoints (no auth required):

| Source | URL |
|--------|-----|
| Prometheus | `http://kube-prometheus-stack-prometheus.observability.svc.cluster.local:9090` |
| Victoria Logs | `http://victoria-logs-server.observability.svc.cluster.local:9428` |

## Prometheus

Instant query helper:

```bash
PROM=http://kube-prometheus-stack-prometheus.observability.svc.cluster.local:9090
pq() { curl -sf "$PROM/api/v1/query" --data-urlencode "query=$1" | jq -r '.data.result[] | [(.metric | tostring), .value[1]] | @tsv'; }
```

The queries that matter, in order:

```bash
# 1. Firing alerts in the roundtable namespace (the curated signal — see the
#    PrometheusRule 'roundtable' for what these mean)
pq 'ALERTS{namespace="roundtable", alertstate="firing"}'

# 2. Knight task failures over the sweep window, by knight and status
pq 'sum by (knight, status) (increase(pi_knight_tasks_total{status=~"error|timeout"}[24h])) > 0'

# 3. Pod restarts and OOM kills in the namespace
pq 'sum by (pod) (increase(kube_pod_container_status_restarts_total{namespace="roundtable"}[24h])) > 0'
pq 'max_over_time(kube_pod_container_status_last_terminated_reason{namespace="roundtable", reason="OOMKilled"}[24h]) == 1'

# 4. Fleet LLM spend over the window (input to the cost-cap check)
pq 'sum(increase(pi_knight_llm_cost_dollars_total[24h]))'

# 5. NATS consumer health
pq 'pi_knight_nats_connected == 0'
```

## Victoria Logs (LogsQL)

Stream fields from fluent-bit: `k_namespace_name`, `k_pod_name`, `app`, `stream`.
pi-knight logs are pino JSON (`level` 50=error 40=warn, `event`, `knight`, `taskId`).
The dashboard API logs are slog JSON (`level`, `msg`, `error`).

```bash
VL=http://victoria-logs-server.observability.svc.cluster.local:9428
vq() { curl -sf "$VL/select/logsql/query" --data-urlencode "query=$1" --data-urlencode "limit=${2:-200}"; }

# Error volume per pod over 24h — start here, it tells you where to dig
vq 'k_namespace_name:roundtable _time:24h (level:50 OR level:error OR "level\":50") | stats by (k_pod_name) count() errors' 50

# Pull the actual error lines for a noisy pod (keep limit small; you have
# limited context — aggregate first, sample second)
vq 'k_namespace_name:roundtable k_pod_name:<pod> _time:24h (level:50 OR "task.failed" OR "task.timeout")' 30

# Operator reconcile errors (controller-runtime JSON, level:error)
vq 'k_namespace_name:roundtable k_pod_name:roundtable-operator* _time:24h "ERROR"' 30
```

If a field filter returns nothing, the JSON probably wasn't parsed into fields —
fall back to substring matching (`"task.failed"`, `"\"level\":50"`), which always works.

## Discipline

- **Aggregate before sampling.** `stats by (...) count()` first; only fetch raw
  lines for the top offenders. Never pull thousands of lines into context.
- Scope every query to `k_namespace_name:roundtable` / `namespace="roundtable"`.
- Distinguish *task content failures* (a knight's task text was bad — not a
  platform bug) from *platform failures* (crash, timeout, disconnect, 5xx —
  Night Watch's actual quarry). Read the error payloads before deciding.
