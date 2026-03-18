# Cleanup Findings — dapper-cluster

Audit date: 2026-03-18

## 🔴 Should Fix

### 1. `chelonianlabs/` — Duplicate namespace of `chelonian/`
Both contain `turtle-track`. `chelonianlabs/` appears to be the older version.
- **Path**: `kubernetes/apps/chelonianlabs/`
- **Action**: Determine which is canonical, archive or delete the other

### 2. `ai/archon-bak/` — Stale backup directory
Should be in `.archive/`, not suffixed with `-bak`.
- **Path**: `kubernetes/apps/ai/archon-bak/`
- **Action**: Move to `kubernetes/apps/ai/.archive/archon-bak/` or delete

### 3. `chelonian/turtle-track/` — Raw manifests instead of HelmRelease
Uses `deployment.yaml`, `service.yaml`, `ingress.yaml` instead of app-template HelmRelease.
- **Path**: `kubernetes/apps/chelonian/turtle-track/app/`
- **Action**: Convert to app-template HelmRelease pattern

## 🟡 Should Standardize

### 4. `helm-values.yaml` files (6 apps)
These apps split values into a separate file instead of inlining in `helmrelease.yaml`:
- `flux-system/flux-operator/app/helm-values.yaml`
- `flux-system/flux-operator/instance/helm-values.yaml`
- `external-secrets/external-secrets/app/helm-values.yaml`
- `cert-manager/cert-manager/app/helm-values.yaml`
- `kube-system/coredns/app/helm-values.yaml`
- `kube-system/cilium/app/helm-values.yaml`
- **Action**: These are all infrastructure charts with large value files — acceptable exception but should be documented

### 5. `network/internal/` and `network/external/` — Missing `app/` subdirectory
These use direct subdirectories (`ingress-nginx/`, `cloudflared/`, etc.) without the `app/` wrapper.
- **Action**: These are multi-component infra, pattern is acceptable but differs from standard apps

### 6. `chelonian/finance-app/` — Non-standard microservice layout
Individual service YAML files (`ai-service.yaml`, `auth-service.yaml`, etc.) in `app/` instead of using app-template controllers.
- **Path**: `kubernetes/apps/chelonian/finance-app/app/`
- **Action**: Consider migrating to app-template multi-controller pattern

## 🟢 Minor / Cosmetic

### 7. Inconsistent PVC naming
Some apps use `pvc.yaml`, others use descriptive names like `paperless-cephfs-pv.yaml`, `minio-cephfs-pv.yaml`, `media-cephfs-pv.yaml`.
- **Action**: Static CephFS PVs are a special case — descriptive names acceptable for clarity

### 8. `flux-system/` — Missing `namespace.yaml`
Flux-system namespace is bootstrapped, not managed by the repo. This is expected.

### 9. Roundtable `chains/` and `knights/` directories
These contain CRD instances (Knight, Chain resources), not standard apps. The `app/` subdirectory pattern still holds, which is good.
