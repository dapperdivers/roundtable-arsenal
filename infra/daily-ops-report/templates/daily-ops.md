---
title: "Infrastructure Daily Report — {{date}}"
knight: sir-tristan
date: "{{date}}"
tags: [daily-report, infrastructure, ops]
---

# 🏗️ Infrastructure Report — {{date}}

## Overall Status: {{overall_status_emoji}} {{overall_status}}

> {{summary}}

---

## 1. Alert Status {{alert_status_emoji}}

| Metric | Value | Δ Yesterday |
|--------|-------|-------------|
| Active Alerts | {{active_alerts}} | {{alert_delta}} |
| Fired (24h) | {{fired_24h}} | |
| Resolved (24h) | {{resolved_24h}} | |

{{#if alert_details}}
### Active Alerts
| Alert | Severity | Since | Namespace |
|-------|----------|-------|-----------|
{{#each alert_details}}
| {{name}} | {{severity}} | {{since}} | {{namespace}} |
{{/each}}
{{/if}}

---

## 2. Flux Reconciliation {{flux_status_emoji}}

| Resource Type | Total | Ready | Failed | Suspended |
|---------------|-------|-------|--------|-----------|
| Kustomizations | {{ks_total}} | {{ks_ready}} | {{ks_failed}} | {{ks_suspended}} |
| HelmReleases | {{hr_total}} | {{hr_ready}} | {{hr_failed}} | {{hr_suspended}} |
| Sources | {{src_total}} | {{src_ready}} | {{src_failed}} | — |

{{#if flux_failures}}
### ❌ Failed Reconciliations
| Resource | Namespace | Last Attempt | Error |
|----------|-----------|--------------|-------|
{{#each flux_failures}}
| {{name}} | {{namespace}} | {{last_attempt}} | {{error}} |
{{/each}}

**Investigate:**
```bash
{{#each flux_failures}}
flux get {{type}} {{name}} -n {{namespace}}
kubectl describe {{type}} {{name}} -n {{namespace}}
{{/each}}
```
{{/if}}

---

## 3. Cluster Resource Health {{cluster_status_emoji}}

### Nodes
| Node | Status | CPU% | Mem% | Pressure |
|------|--------|------|------|----------|
{{#each nodes}}
| {{name}} | {{status}} | {{cpu_pct}} | {{mem_pct}} | {{pressure}} |
{{/each}}

### Pod Summary
| Status | Count | Δ Yesterday |
|--------|-------|-------------|
| Running | {{pods_running}} | {{pods_running_delta}} |
| Pending | {{pods_pending}} | {{pods_pending_delta}} |
| Failed | {{pods_failed}} | {{pods_failed_delta}} |
| CrashLoopBackOff | {{pods_crashloop}} | {{pods_crashloop_delta}} |

{{#if problem_pods}}
### ⚠️ Problem Pods
| Pod | Namespace | Status | Restarts | Age |
|-----|-----------|--------|----------|-----|
{{#each problem_pods}}
| {{name}} | {{namespace}} | {{status}} | {{restarts}} | {{age}} |
{{/each}}

**Debug:**
```bash
{{#each problem_pods}}
kubectl logs {{name}} -n {{namespace}} --tail=50
kubectl describe pod {{name}} -n {{namespace}}
{{/each}}
```
{{/if}}

### PVC Usage
| PVC | Namespace | Used% | Size |
|-----|-----------|-------|------|
{{#each pvc_warnings}}
| {{name}} | {{namespace}} | {{used_pct}} | {{size}} |
{{/each}}

---

## 4. Recent Deployments {{deploy_status_emoji}}

| Release | Namespace | Version Change | Status | Time |
|---------|-----------|---------------|--------|------|
{{#each recent_deployments}}
| {{name}} | {{namespace}} | {{old_ver}} → {{new_ver}} | {{status}} | {{time}} |
{{/each}}

{{#if rollbacks}}
### 🔄 Rollbacks Detected
{{#each rollbacks}}
- **{{name}}** in `{{namespace}}` — rolled back at {{time}}
{{/each}}
{{/if}}

---

## 5. Renovate Pipeline {{renovate_status_emoji}}

| Type | Open PRs | Auto-merge | Needs Review |
|------|----------|------------|--------------|
| Patch | {{renovate_patch}} | {{renovate_patch_auto}} | {{renovate_patch_review}} |
| Minor | {{renovate_minor}} | {{renovate_minor_auto}} | {{renovate_minor_review}} |
| Major | {{renovate_major}} | — | {{renovate_major_review}} |

{{#if renovate_action_needed}}
### Action Needed
{{#each renovate_action_needed}}
- [PR #{{number}}]({{url}}) — {{title}}
{{/each}}
{{/if}}

---

## 6. Infrastructure PRs {{pr_status_emoji}}

| PR | Author | Age | Checks | Review |
|----|--------|-----|--------|--------|
{{#each open_prs}}
| [#{{number}}]({{url}}) {{title}} | {{author}} | {{age}} | {{checks}} | {{review}} |
{{/each}}

**Oldest open PR:** {{oldest_pr_age}}

---

## 7. Certificates & Secrets {{cert_status_emoji}}

| Certificate | Namespace | Expires | Days Left |
|-------------|-----------|---------|-----------|
{{#each cert_warnings}}
| {{name}} | {{namespace}} | {{expires}} | {{days_left}} |
{{/each}}

| ExternalSecret | Namespace | Status |
|----------------|-----------|--------|
{{#each external_secrets}}
| {{name}} | {{namespace}} | {{status}} |
{{/each}}

---

## 8. Backup Status {{backup_status_emoji}}

| PVC | Namespace | Last Backup | Age | Status |
|-----|-----------|-------------|-----|--------|
{{#each backups}}
| {{name}} | {{namespace}} | {{last_sync}} | {{age}} | {{status}} |
{{/each}}

---

## 9. Trends

| Metric | Today | Yesterday | 7d Avg | Trend |
|--------|-------|-----------|--------|-------|
| Total Pods | {{pods_total}} | {{pods_total_yesterday}} | {{pods_total_7d}} | {{pods_trend}} |
| Deployments | {{deploys_today}} | {{deploys_yesterday}} | {{deploys_7d}} | {{deploys_trend}} |
| Failed Reconciliations | {{flux_fail_today}} | {{flux_fail_yesterday}} | {{flux_fail_7d}} | {{flux_fail_trend}} |
| Avg CPU% | {{avg_cpu}} | {{avg_cpu_yesterday}} | {{avg_cpu_7d}} | {{cpu_trend}} |
| Avg Mem% | {{avg_mem}} | {{avg_mem_yesterday}} | {{avg_mem_7d}} | {{mem_trend}} |

---

## Action Items

{{#each action_items}}
- [ ] **{{priority}}** — {{description}}
{{/each}}

{{#if follow_up_questions}}
## Questions for Tim
{{#each follow_up_questions}}
- {{this}}
{{/each}}
{{/if}}
