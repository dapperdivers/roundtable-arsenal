---
name: flux-dependency-resolver
description: >
  Trace Flux Kustomization dependency chains to identify root blockers when deployments are stuck. Use when debugging Flux reconciliation failures or dependency issues.
---

# Flux Dependency Resolver

**Version:** 1.0.0  
**Author:** Tristan (Infrastructure Knight)  
**Category:** GitOps Troubleshooting  
**Tags:** flux, fluxcd, dependencies, gitops, troubleshooting, kustomization  
**Spec Version:** AgentSkills.io v1.0

## Overview

Automatically parse Flux Kustomization dependencies and identify root blockers preventing reconciliation. Provides dependency chain tracing, root cause analysis, and visualization of Kustomization dependency trees to debug complex GitOps deployment issues.

## Capabilities

- **Dependency Chain Tracing**: Follow `dependsOn` relationships between Kustomizations
- **Root Blocker Identification**: Find the source cause of cascading failures
- **Dependency Tree Visualization**: ASCII tree view of Kustomization relationships
- **Circular Dependency Detection**: Identify dependency loops
- **Health Status Propagation**: Understand how failures cascade through dependencies
- **Reconciliation Timeline**: Track when dependencies will be ready

## Prerequisites

### RBAC Requirements

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: flux-dependency-resolver
rules:
- apiGroups: ["kustomize.toolkit.fluxcd.io"]
  resources: ["kustomizations"]
  verbs: ["get", "list"]
- apiGroups: ["source.toolkit.fluxcd.io"]
  resources: ["gitrepositories", "ocirepositories", "buckets"]
  verbs: ["get", "list"]
- apiGroups: ["helm.toolkit.fluxcd.io"]
  resources: ["helmreleases"]
  verbs: ["get", "list"]
```

### Cluster Requirements

- Flux CD v2 installed
- Kustomize controller running
- kubectl access to cluster
- jq for JSON processing

## Usage

### Trace Dependencies and Find Root Blockers

```bash
./scripts/flux-deps.sh
```

**Example Output:**
```json
{
  "timestamp": "2026-03-17T20:30:00Z",
  "cluster": "dapper-cluster",
  "namespace": "flux-system",
  "total_kustomizations": 5,
  "healthy": 5,
  "unhealthy": 0,
  "pending": 0,
  "root_blockers": [],
  "dependency_chains": [
    {
      "name": "flux-system",
      "namespace": "flux-system",
      "status": "Ready",
      "dependencies": [],
      "dependents": ["flux-operator", "flux-instance"],
      "is_root": true,
      "depth": 0
    },
    {
      "name": "flux-operator",
      "namespace": "flux-system",
      "status": "Ready",
      "dependencies": ["flux-system"],
      "dependents": ["cluster-apps"],
      "is_root": false,
      "depth": 1,
      "blocks": 1
    }
  ],
  "issues": [],
  "recommendations": [
    "All Kustomizations healthy - no action required"
  ]
}
```

**With Failures Example:**
```json
{
  "timestamp": "2026-03-17T20:30:00Z",
  "total_kustomizations": 8,
  "healthy": 5,
  "unhealthy": 3,
  "root_blockers": [
    {
      "name": "infrastructure",
      "namespace": "flux-system",
      "status": "False",
      "reason": "HealthCheckFailed",
      "message": "Health check failed: deployment cert-manager/cert-manager not ready",
      "blocks_count": 2,
      "blocked_kustomizations": [
        "applications",
        "ingress"
      ]
    }
  ],
  "dependency_chains": [
    {
      "name": "infrastructure",
      "namespace": "flux-system",
      "status": "False",
      "reason": "HealthCheckFailed",
      "dependencies": [],
      "dependents": ["applications", "ingress"],
      "is_root": true,
      "depth": 0,
      "blocks": 2,
      "blocked_resources": [
        "applications",
        "ingress"
      ]
    }
  ],
  "issues": [
    {
      "severity": "critical",
      "kustomization": "infrastructure",
      "description": "Root blocker preventing 2 dependent Kustomizations from reconciling",
      "cause": "Health check failed: deployment cert-manager/cert-manager not ready",
      "impact": "Blocks: applications, ingress",
      "remediation": "Fix cert-manager deployment, then Flux will automatically reconcile dependents"
    }
  ]
}
```

### Visualize Dependency Tree

```bash
./scripts/flux-tree.sh
```

**Example Output:**
```
Flux Kustomization Dependency Tree
===================================

flux-system (Ready) ✓
├── flux-operator (Ready) ✓
│   └── cluster-apps (Ready) ✓
│       ├── cert-manager (Ready) ✓
│       ├── ingress-nginx (Ready) ✓
│       └── external-dns (Ready) ✓
└── flux-instance (Ready) ✓

cluster-meta (Ready) ✓
├── network-policies (Ready) ✓
└── resource-quotas (Ready) ✓

Legend:
  ✓ = Ready
  ✗ = Failed
  ⧗ = Pending/Progressing
  ○ = Unknown

Summary:
  Total: 10 Kustomizations
  Ready: 10
  Failed: 0
  Pending: 0
```

**With Failures:**
```
Flux Kustomization Dependency Tree
===================================

infrastructure (HealthCheckFailed) ✗
├── applications (DependencyNotReady) ⧗ [BLOCKED]
│   ├── frontend (DependencyNotReady) ⧗ [BLOCKED]
│   └── backend (DependencyNotReady) ⧗ [BLOCKED]
└── ingress (DependencyNotReady) ⧗ [BLOCKED]

ROOT BLOCKER: infrastructure
  Reason: Health check failed: deployment cert-manager/cert-manager not ready
  Blocking: 4 Kustomizations (applications, frontend, backend, ingress)

ACTION REQUIRED: Fix infrastructure Kustomization to unblock dependents
```

### Check Specific Kustomization

```bash
# Trace dependencies for a specific Kustomization
./scripts/flux-deps.sh --kustomization applications

# Show only blockers
./scripts/flux-deps.sh --blockers-only

# Check specific namespace
./scripts/flux-deps.sh --namespace production
```

## Troubleshooting Workflows

### Workflow 1: All Kustomizations Stuck

**Symptoms:**
- Multiple Kustomizations showing "DependencyNotReady"
- `flux get kustomizations` shows many pending

**Diagnostic Steps:**
```bash
./scripts/flux-deps.sh
```

**Analysis:**
1. Look for `root_blockers` in output
2. Check why root blocker is failing
3. All dependents will auto-reconcile once root is fixed

**Example Root Causes:**
- Source (GitRepository) not ready
- Health check failing on deployed resources
- Prune or validation errors

### Workflow 2: Specific Kustomization Won't Reconcile

**Symptoms:**
- One Kustomization stuck
- Others working fine

**Diagnostic Steps:**
```bash
# Check its dependencies
./scripts/flux-deps.sh --kustomization my-app

# Visualize tree
./scripts/flux-tree.sh
```

**Analysis:**
1. Check if any dependencies are not Ready
2. Verify dependency names are correct
3. Check if circular dependency exists

### Workflow 3: Circular Dependencies

**Symptoms:**
- Kustomizations referencing each other
- None ever become Ready

**Diagnostic Steps:**
```bash
./scripts/flux-deps.sh
```

**Analysis:**
Look for `circular_dependencies` in issues array:
```json
{
  "issues": [
    {
      "severity": "error",
      "type": "circular_dependency",
      "description": "Circular dependency detected",
      "cycle": ["app-a", "app-b", "app-a"]
    }
  ]
}
```

**Resolution:**
Remove one of the `dependsOn` references to break the cycle.

### Workflow 4: Health Check Failures

**Symptoms:**
- Kustomization shows "HealthCheckFailed"
- Resources deployed but Kustomization not Ready

**Diagnostic Steps:**
```bash
./scripts/flux-deps.sh
```

**Root Causes:**
- Deployment not reaching Ready state
- Service endpoints not available
- Custom health checks failing

**Resolution:**
1. Check the specific resource mentioned in error message
2. Fix the unhealthy resource
3. Flux will auto-reconcile once healthy

## Dependency Patterns

### Linear Chain

```
A → B → C → D
```

**Behavior:**
- D waits for C
- C waits for B  
- B waits for A
- If A fails, all downstream fail

**Use Case:** Sequential infrastructure deployment

### Fan-Out

```
     ┌→ B
A →  ├→ C
     └→ D
```

**Behavior:**
- B, C, D all wait for A
- B, C, D can reconcile in parallel once A is Ready

**Use Case:** Base infrastructure → multiple apps

### Fan-In

```
A ┐
B ├→ D
C ┘
```

**Behavior:**
- D waits for A, B, and C
- D reconciles only when all dependencies Ready

**Use Case:** App requiring multiple infrastructure components

### Diamond

```
    ┌→ B ┐
A →       → D
    └→ C ┘
```

**Behavior:**
- B and C wait for A
- D waits for both B and C

**Use Case:** Complex multi-tier deployments

## Understanding Dependency Status

### Status Types

| Status | Meaning | Next Action |
|--------|---------|-------------|
| **Ready** | Reconciliation successful | None - healthy |
| **Progressing** | Currently reconciling | Wait for completion |
| **DependencyNotReady** | Waiting for dependencies | Check dependencies |
| **HealthCheckFailed** | Resources not healthy | Fix unhealthy resources |
| **ArtifactFailed** | Source artifact issue | Check GitRepository/OCI |
| **BuildFailed** | Kustomize build error | Fix kustomization.yaml syntax |
| **PruneError** | Failed to prune resources | Check RBAC, finalize |

### Cascading Failures

```
Root (HealthCheckFailed)
  → Dep1 (DependencyNotReady)
    → Dep2 (DependencyNotReady)
      → Dep3 (DependencyNotReady)
```

**Key Insight:** Fix the root, and all dependents will auto-reconcile.

## Advanced Usage

### Check All Namespaces

```bash
./scripts/flux-deps.sh --all-namespaces
```

### Export Dependency Graph

```bash
# Generate DOT format for Graphviz
./scripts/flux-deps.sh --format dot > deps.dot
dot -Tpng deps.dot -o deps.png
```

### Monitor Continuously

```bash
# Watch for changes
watch -n 10 './scripts/flux-tree.sh'
```

### Integration with CI/CD

```bash
#!/bin/bash
# Pre-deployment check

BLOCKERS=$(./scripts/flux-deps.sh | jq -r '.root_blockers | length')

if [ "$BLOCKERS" -gt 0 ]; then
  echo "❌ Cannot deploy - Flux has $BLOCKERS root blockers"
  ./scripts/flux-deps.sh | jq '.root_blockers'
  exit 1
fi

echo "✅ Flux healthy - proceeding with deployment"
```

## Common Issues and Solutions

### Issue: "DependsOn references non-existent Kustomization"

**Cause:** Typo in dependency name or wrong namespace

**Detection:**
```bash
./scripts/flux-deps.sh
```

Look for:
```json
{
  "issues": [{
    "severity": "error",
    "type": "missing_dependency",
    "kustomization": "my-app",
    "missing": "base-infra",
    "referenced_in": "spec.dependsOn[0]"
  }]
}
```

**Resolution:**
- Verify Kustomization name: `flux get kustomizations`
- Fix typo in dependsOn
- Ensure dependency in same namespace or use `namespace/name` format

### Issue: Long Dependency Chain Slow to Reconcile

**Cause:** Sequential dependencies with interval waits

**Detection:**
```bash
./scripts/flux-deps.sh | jq '.dependency_chains[] | select(.depth > 5)'
```

**Solutions:**
1. Reduce dependency chain depth (parallel where possible)
2. Decrease `spec.interval` on leaf nodes
3. Use `spec.wait: false` if health checks not needed

### Issue: Suspended Kustomization Blocking Dependents

**Cause:** Kustomization manually suspended

**Detection:**
```bash
flux get kustomizations --status-selector '!suspend=true'
```

**Resolution:**
```bash
flux resume kustomization <name>
```

## Configuration Options

### Environment Variables

```bash
# Namespace to check (default: flux-system)
FLUX_NAMESPACE=flux-system

# Include all namespaces
FLUX_ALL_NAMESPACES=true

# Specific Kustomization to analyze
FLUX_KUSTOMIZATION=my-app

# Show only blockers
FLUX_BLOCKERS_ONLY=true

# Output format (json, text, dot)
FLUX_OUTPUT_FORMAT=json

# Maximum depth to traverse
FLUX_MAX_DEPTH=10
```

## Performance Considerations

- Execution time: 1-5 seconds for typical clusters
- API calls: 1-3 per Kustomization (cached)
- Safe to run frequently
- Read-only operations only

## Integration Examples

### Prometheus Alert

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: flux-dependency-alerts
spec:
  groups:
  - name: flux
    rules:
    - alert: FluxRootBlocker
      expr: |
        count(kustomize_kustomization_ready{status="False", has_dependents="true"}) > 0
      annotations:
        summary: Flux root blocker detected
        description: Run flux-deps.sh to identify blocked resources
```

### Slack Notification

```bash
#!/bin/bash
# Alert on root blockers

RESULT=$(./scripts/flux-deps.sh)
BLOCKERS=$(echo "$RESULT" | jq -r '.root_blockers | length')

if [ "$BLOCKERS" -gt 0 ]; then
  MESSAGE=$(echo "$RESULT" | jq -r '.root_blockers[] | 
    "🔴 *\(.name)* blocking \(.blocks_count) Kustomizations
  Reason: \(.message)"')
  
  curl -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"$MESSAGE\"}" \
    "$SLACK_WEBHOOK_URL"
fi
```

## Related Skills

- `flux-reconciler` - Force Flux reconciliation
- `kustomize-validator` - Validate Kustomization manifests
- `helm-dependency-resolver` - HelmRelease dependency analysis
- `gitops-health-check` - Overall GitOps health validation

## Changelog

### v1.0.0 (2026-03-17)
- Initial release
- Dependency chain tracing
- Root blocker identification
- ASCII tree visualization
- Circular dependency detection
- JSON and text output formats
- Multi-namespace support

## License

MIT License - Part of Roundtable Knight Skills Collection

## Support

For issues or enhancements, contact the Infrastructure Knight (Tristan) or submit to the skills repository.
