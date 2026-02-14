---
name: flux-ops
description: Flux/GitOps operations, troubleshooting, and cluster health monitoring
---

# Flux Operations

Commands and patterns for managing Flux-based GitOps deployments.

## Health Checks

### Quick Status
```bash
# All Flux components
flux check

# All Kustomizations
flux get kustomizations -A

# All HelmReleases
flux get helmreleases -A

# All sources
flux get sources all -A

# Failed resources only
flux get all -A --status-selector ready=false
```

### Pod Health
```bash
# Pods not running across all namespaces
kubectl get pods -A --field-selector 'status.phase!=Running,status.phase!=Succeeded'

# Pods with restarts
kubectl get pods -A -o json | jq -r '.items[] | select(.status.containerStatuses[]?.restartCount > 3) | "\(.metadata.namespace)/\(.metadata.name) restarts=\(.status.containerStatuses[0].restartCount)"'

# Resource usage
kubectl top pods -A --sort-by=memory | head -20
```

## HelmRelease Troubleshooting

### Diagnosis Flow
```bash
# 1. Check HR status
flux get hr <name> -n <namespace>

# 2. Get detailed conditions
kubectl describe helmrelease <name> -n <namespace>

# 3. Check the HelmChart source
kubectl get helmchart -n <namespace>

# 4. Check Helm history
helm history <name> -n <namespace>

# 5. Check events
kubectl events -n <namespace> --for helmrelease/<name>
```

### Common Issues

**"upgrade retries exhausted"**
```bash
# Suspend and resume to reset retry counter
flux suspend hr <name> -n <namespace>
flux resume hr <name> -n <namespace>
```

**"chart not found"**
```bash
# Check HelmRepository source
flux get sources helm -A
# Force reconcile the source
flux reconcile source helm <repo-name> -n <namespace>
```

**"values validation failed"**
```bash
# Get the rendered values
helm get values <name> -n <namespace> -a
# Compare with what's in Git
```

**Stuck in "progressing"**
```bash
# Check if pods are actually rolling out
kubectl rollout status deployment/<name> -n <namespace> --timeout=60s
# Force reconcile
flux reconcile hr <name> -n <namespace> --force
```

## Kustomization Operations

### Drift Detection
```bash
# Check for drift (diff what's applied vs what's in Git)
flux diff kustomization <name>

# Force reconciliation
flux reconcile ks <name> --with-source

# List all with last applied revision
flux get ks -A -o json | jq -r '.[] | "\(.namespace)/\(.name) rev=\(.lastAppliedRevision) ready=\(.isReady)"'
```

### Dependency Issues
```bash
# Show dependency tree
flux tree ks <name> -n <namespace>

# If a dependency is stuck, reconcile from the root
flux reconcile ks flux-system --with-source
```

## Source Management

```bash
# Force Git repo pull
flux reconcile source git flux-system

# Check Git source health
flux get sources git -A

# OCI sources
flux get sources oci -A

# Check Helm repo index freshness
flux get sources helm -A -o json | jq '.[] | {name: .name, url: .url, lastUpdated: .lastHandledReconcileAt}'
```

## PR Review Checklist for Manifest Changes

When reviewing PRs that modify Kubernetes manifests:

- [ ] **Namespace** — Correct namespace? Not accidentally `default`?
- [ ] **Image tag** — Pinned to digest or semver? No `latest`
- [ ] **Resource limits** — CPU/memory requests and limits set?
- [ ] **Secrets** — No plaintext secrets? Using SealedSecrets/SOPS?
- [ ] **RBAC** — Minimal permissions? No cluster-admin for apps?
- [ ] **Network policies** — Appropriate ingress/egress rules?
- [ ] **Health checks** — Liveness and readiness probes defined?
- [ ] **PDB** — PodDisruptionBudget for critical services?
- [ ] **Kustomization deps** — Dependencies correct if ordering matters?
- [ ] **HelmRelease values** — Diff against current values; any breaking changes?
- [ ] **Flux annotations** — `reconcile.fluxcd.io/requestedAt` not hardcoded?

## Useful Aliases

```bash
alias fga='flux get all -A'
alias fgk='flux get ks -A'
alias fgh='flux get hr -A'
alias fgs='flux get sources all -A'
alias frf='flux reconcile ks flux-system --with-source'
```

## Emergency: Force Sync Everything

```bash
# Nuclear option — reconcile all sources and kustomizations
flux reconcile source git flux-system
for ks in $(flux get ks -A -o json | jq -r '.[].name'); do
  flux reconcile ks "$ks" --with-source &
done
wait
```

## Notes
- Always check `flux logs` for controller-level errors
- Use `--force` sparingly — it reapplies everything
- HelmRelease remediation: set `remediateLastFailure: true` in spec
- Flux v2 stores state in-cluster, not in Git — Git is the desired state
