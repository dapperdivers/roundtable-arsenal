---
name: daily-ops-report
description: Daily infrastructure report for Tristan. Cluster health, Flux status, deployments, PRs, certs, backups — structured and actionable.
allowed-tools: Bash Read Write
metadata:
  author: tristan
  version: "1.0"
  tier: knight
  knight: sir-tristan
  domain: infrastructure
---

# Daily Infrastructure Report — Tristan

Generate a daily ops report covering cluster health, GitOps state, deployments, and maintenance pipeline. Output MUST conform to the shared `daily-reports` JSON contract.

## Report Sections (Priority Order)

Generate each section below. Lead every section with a traffic light status: 🔴 RED / 🟡 YELLOW / 🟢 GREEN.

### 1. Alert Status *(Critical)*

Check active and recently fired alerts.

```bash
# Active alerts (if Alertmanager is available)
kubectl get prometheusrules -A --no-headers | wc -l
# Recent events with warnings
kubectl get events -A --field-selector type=Warning --sort-by='.lastTimestamp' | tail -20
```

**Include:** Active alert count, new alerts (last 24h), resolved alerts, alert trend (improving/worsening).

- 🔴 Any critical/firing alerts
- 🟡 Warning-level alerts or recent firings now resolved
- 🟢 No active alerts, no recent firings

### 2. Flux Reconciliation Health *(Critical)*

Use the `infra/flux-ops` skill as reference. Run:

```bash
# Failed resources
flux get all -A --status-selector ready=false

# All Kustomizations with status
flux get ks -A

# All HelmReleases with status
flux get hr -A

# Suspended resources (should be near zero)
flux get all -A --status-selector suspended=true

# Last applied revisions
flux get ks -A -o json | jq -r '.[] | "\(.namespace)/\(.name) ready=\(.isReady) rev=\(.lastAppliedRevision)"'
```

**Include:** Failed count, suspended count, last successful sync per source, drift detected.

- 🔴 Any failed reconciliations
- 🟡 Suspended resources or stale syncs (>1h)
- 🟢 All reconciliations healthy

### 3. Cluster Resource Health *(High)*

Run `scripts/cluster-health.sh` or manually:

```bash
# Node conditions
kubectl get nodes -o wide
kubectl describe nodes | grep -A5 "Conditions:"

# Pod status summary
kubectl get pods -A --no-headers | awk '{print $4}' | sort | uniq -c | sort -rn

# Pods not running
kubectl get pods -A --field-selector 'status.phase!=Running,status.phase!=Succeeded'

# High-restart pods
kubectl get pods -A -o json | jq -r '.items[] | select(.status.containerStatuses[]?.restartCount > 3) | "\(.metadata.namespace)/\(.metadata.name) restarts=\(.status.containerStatuses[0].restartCount)"'

# PVC usage
kubectl get pvc -A --no-headers

# Top resource consumers
kubectl top pods -A --sort-by=memory | head -15
kubectl top nodes
```

**Include:** Node count and status, pod counts by phase, CrashLoopBackOff list, PVCs over 80%, node memory/CPU pressure.

- 🔴 Node NotReady, CrashLoopBackOff pods, PVC >95%
- 🟡 Pending pods, PVC >80%, high restart counts
- 🟢 All nodes Ready, no abnormal pods, PVCs healthy

### 4. Recent Deployments *(High)*

```bash
# HelmReleases updated in last 24h
flux get hr -A -o json | jq -r '.[] | select(.lastHandledReconcileAt > "'$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S)'") | "\(.namespace)/\(.name) rev=\(.lastAppliedRevision) ready=\(.isReady)"'

# Recent rollout events
kubectl get events -A --field-selector reason=ScalingReplicaSet --sort-by='.lastTimestamp' | tail -10
```

**Include:** Table of deployments with name, namespace, old→new version, status, timestamp. Flag any rollbacks.

- 🔴 Failed deployments or rollbacks
- 🟡 Deployments in progress
- 🟢 All recent deployments successful

### 5. Renovate Pipeline *(Medium)*

```bash
# Open Renovate PRs
gh pr list --repo <INFRA_REPO> --author 'renovate[bot]' --state open --json number,title,labels,createdAt

# Group by update type
gh pr list --repo <INFRA_REPO> --author 'renovate[bot]' --state open --json labels --jq '.[].labels[].name' | sort | uniq -c
```

**Include:** Count by type (patch/minor/major), auto-merge candidates, PRs needing manual review (majors, breaking), failed checks.

- 🔴 Major updates with failing checks
- 🟡 Major updates pending review
- 🟢 Only patch/minor, auto-merge handling it

### 6. Infrastructure PRs *(Medium)*

```bash
# All open PRs
gh pr list --repo <INFRA_REPO> --state open --json number,title,author,createdAt,reviewDecision,statusCheckRollup

# Stale PRs (>7 days)
gh pr list --repo <INFRA_REPO> --state open --json number,title,createdAt --jq '.[] | select(.createdAt < "'$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S)'")'
```

**Include:** Open PR count, failing checks, oldest PR age, PRs needing review.

- 🔴 PRs with failing checks blocking deployment
- 🟡 PRs open >7 days
- 🟢 Clean queue, all checks passing

### 7. Certificate & Secret Expiry *(Medium)*

```bash
# Certificates via cert-manager
kubectl get certificates -A -o json | jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name) notAfter=\(.status.notAfter) ready=\(.status.conditions[]? | select(.type=="Ready") | .status)"'

# Certs expiring within 30 days
kubectl get certificates -A -o json | jq -r '.items[] | select(.status.notAfter < "'$(date -u -d '+30 days' +%Y-%m-%dT%H:%M:%SZ)'") | "\(.metadata.namespace)/\(.metadata.name) expires=\(.status.notAfter)"'

# ExternalSecrets sync
kubectl get externalsecrets -A -o json | jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name) status=\(.status.conditions[]? | select(.type=="Ready") | .status)"'
```

**Include:** Certs expiring <30d, failed ExternalSecrets, SealedSecrets health.

- 🔴 Cert expiring <7 days or failed renewal
- 🟡 Cert expiring <30 days
- 🟢 All certs valid >30 days

### 8. Backup Status *(Low)*

```bash
# Volsync ReplicationSources
kubectl get replicationsources -A -o json | jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name) lastSync=\(.status.lastSyncTime) duration=\(.status.lastSyncDuration)"'

# Failed or stale backups
kubectl get replicationsources -A -o json | jq -r '.items[] | select(.status.conditions[]? | select(.type=="Synchronizing" and .status!="True")) | "\(.metadata.namespace)/\(.metadata.name)"'
```

**Include:** Last successful backup per PVC, failed backups, stale backups (>24h).

- 🔴 Failed backups
- 🟡 Backups >24h old
- 🟢 All backups current

### 9. Trends *(Informational)*

Compare today's data against yesterday's report (if available in vault).

**Include:** Week-over-week resource usage delta, deployment frequency, mean time to reconciliation, new vs resolved issues.

---

## Generating the Report

### Step 1: Gather Data

Run `scripts/cluster-health.sh` for automated collection, then supplement with the commands above for sections not covered by the script.

### Step 2: Build JSON Output

Output MUST conform to the `shared/daily-reports` contract:

```json
{
  "knight": "sir-tristan",
  "run_id": "daily-YYYY-MM-DD",
  "report_type": "daily-briefing",
  "timestamp": "ISO-8601",
  "summary": "2-3 sentences. Lead with overall status color.",
  "sections": [
    {
      "title": "Alert Status",
      "priority": "high|medium|low",
      "content": "Markdown with traffic light, tables, actionable items",
      "data_sources": ["kubectl", "flux CLI"],
      "confidence": "high|medium|low"
    }
  ],
  "highlights": [
    "3-5 bullets for Tim's morning scan"
  ],
  "follow_up_needed": false,
  "follow_up_questions": []
}
```

### Step 3: Render Markdown

Use `templates/daily-ops.md` as the template. Render to Tim's Obsidian vault via `shared/report-generator`.

### Step 4: Diff from Yesterday

Compare key metrics against the previous day's report:
- New alerts vs resolved
- Pod count changes
- Failed reconciliation changes
- New PRs vs merged
- Resource usage delta

Flag anything that changed materially with ↑/↓ indicators.

---

## Priority Rules

| Priority | Condition |
|----------|-----------|
| **high** | Any 🔴 section, failed deployments, node issues, cert <7d |
| **medium** | 🟡 sections, open PRs needing review, approaching thresholds |
| **low** | All 🟢, routine observations, trends |

Set `follow_up_needed: true` if ANY section is 🔴.

## Data Sources

All data comes from the cluster directly:
- `kubectl` — pod/node/PVC/cert/event data
- `flux` CLI — GitOps reconciliation state
- `gh` CLI — GitHub PRs and checks
- `scripts/cluster-health.sh` — aggregated JSON output

## Style

- Tables over paragraphs
- Counts over descriptions
- Copy-pasteable commands for investigation
- No fluff
