---
name: dapper-cluster
description: >
  Write and modify Kubernetes manifests for the dapper-cluster GitOps repository.
  Enforces file naming, folder structure, Flux Kustomization patterns, HelmRelease
  conventions, component reuse, and namespace layout. Use when creating new apps,
  modifying existing deployments, adding HelmReleases, writing Flux Kustomizations,
  adding ExternalSecrets, configuring VolSync backups, setting up Authentik auth,
  configuring ingress (internal/external), or reviewing dapper-cluster PRs.
  Triggers: "add an app", "deploy to cluster", "new helmrelease", "dapper-cluster",
  "homelab", "flux kustomization", "create namespace", "cluster manifest",
  "volsync backup", "externalsecret", "security context", "ingress class",
  "authentik auth".
---

# dapper-cluster Conventions

Repository: `repos/dapper-cluster`

## Directory Layout

```
kubernetes/
├── apps/
│   └── <namespace>/                    # e.g. media, ai, selfhosted
│       ├── kustomization.yaml          # Lists all app ks.yaml + namespace.yaml
│       ├── namespace.yaml              # Namespace resource (name: _)
│       └── <app-name>/
│           ├── ks.yaml                 # Flux Kustomization (always at this level)
│           └── app/                    # Primary manifests directory
│               ├── kustomization.yaml  # Lists resources in this dir
│               ├── helmrelease.yaml    # HelmRelease (inline values, NOT separate file)
│               └── externalsecret.yaml # ExternalSecret (if needed)
├── bootstrap/                          # Talos + initial helmfile
├── components/                         # Shared Flux components (rarely touched)
└── flux/
    ├── cluster/ks.yaml                 # Top-level cluster Kustomization
    ├── components/
    │   ├── common/                     # Alerts, repos, SOPS, substitutions
    │   ├── gatus/                      # Health check components
    │   └── volsync/                    # Backup components (repository + operations)
    └── meta/
        └── repositories/helm/          # HelmRepository definitions
```

## File Naming Rules

| File | Name | Notes |
|------|------|-------|
| Flux Kustomization | `ks.yaml` | ALWAYS `ks.yaml`, never `kustomization.yaml` at app level |
| Kustomize manifest | `kustomization.yaml` | The Kustomize resource list inside `app/` dirs |
| HelmRelease | `helmrelease.yaml` | Values INLINE, not in separate `helm-values.yaml` |
| ExternalSecret | `externalsecret.yaml` | One per app, targets `<app>-secret` |
| PVC | `pvc.yaml` | Only when not managed by VolSync/HelmRelease |
| RBAC | `rbac.yaml` | ServiceAccount, Role, RoleBinding combined |
| Namespace | `namespace.yaml` | At namespace level, `name: _` (rewritten by Flux) |
| OCI Repository | `ocirepository.yaml` | Only if app needs its own (most use common component) |

### Naming Anti-Patterns — DO NOT

- `helm-values.yaml` — inline values in `helmrelease.yaml`
- `deployment.yaml` / `service.yaml` / `ingress.yaml` — use HelmRelease (app-template) instead of raw manifests
- `<app>-kustomization.yaml` — it's always `kustomization.yaml`
- Suffixed variants like `pvc-direct.yaml`, `pvc-cephfs.yaml` — use `pvc.yaml` (one per concern)

## Standard App Structure

### ks.yaml (Flux Kustomization)

```yaml
---
# yaml-language-server: $schema=https://kubernetes-schemas.pages.dev/kustomize.toolkit.fluxcd.io/kustomization_v1.json
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: &app <app-name>
  namespace: &namespace <namespace>
spec:
  targetNamespace: *namespace
  commonMetadata:
    labels:
      app.kubernetes.io/name: *app
  dependsOn:
    - name: external-secrets-stores
      namespace: external-secrets
  path: ./kubernetes/apps/<namespace>/<app-name>/app
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system
  wait: true
  interval: 30m
  retryInterval: 1m
  timeout: 10m
```

#### dependsOn Common Targets

Add these based on what the app needs:

| Dependency | Namespace | When to add |
|-----------|-----------|-------------|
| `external-secrets-stores` | `external-secrets` | App has ExternalSecret (almost always) |
| `cloudnative-pg-cluster` | `database` | App uses PostgreSQL |
| `volsync` | `volsync-system` | App uses VolSync backups |
| `dragonfly-cluster` | `database` | App uses Dragonfly/Redis |

#### VolSync Components

Add when app needs persistent backup:

```yaml
  components:
    - ../../../../flux/components/volsync/repository
    - ../../../../flux/components/volsync/operations
  postBuild:
    substitute:
      APP: *app
      VOLSYNC_CAPACITY: 5Gi    # 1Gi config-only, 5Gi default, 10-20Gi large DBs
```

#### Gatus Health Check Components

Add when app has an ingress you want monitored:

```yaml
  components:
    - ../../../../flux/components/gatus/guarded    # or gatus/external for public
  postBuild:
    substitute:
      APP: *app
      GATUS_SUBDOMAIN: <subdomain>                 # optional, overrides app name
      GATUS_DOMAIN: ${SECRET_DOMAIN}               # match the app's domain var
```

### app/helmrelease.yaml (app-template pattern)

```yaml
---
# yaml-language-server: $schema=https://raw.githubusercontent.com/bjw-s/helm-charts/main/charts/other/app-template/schemas/helmrelease-helm-v2.schema.json
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: <app-name>
spec:
  interval: 30m
  chartRef:
    kind: OCIRepository
    name: app-template
  install:
    remediation:
      retries: 3
  upgrade:
    cleanupOnFail: true
    remediation:
      strategy: rollback
      retries: 3
  values:
    controllers:
      <app-name>:
        annotations:
          reloader.stakater.com/auto: "true"
        containers:
          app:
            image:
              repository: <image>
              tag: <tag>
            env:
              TZ: "${TIME_ZONE}"
            securityContext:
              allowPrivilegeEscalation: false
              readOnlyRootFilesystem: true
              capabilities: { drop: ["ALL"] }
            resources:
              requests:
                memory: 256Mi
                cpu: 100m
              limits:
                memory: 1Gi
    defaultPodOptions:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
        fsGroupChangePolicy: OnRootMismatch
        seccompProfile: { type: RuntimeDefault }
    service:
      app:
        controller: <app-name>
        ports:
          http:
            port: 80
    ingress:
      app:
        annotations:
          external-dns.alpha.kubernetes.io/target: "internal.${SECRET_DOMAIN}"
        className: internal
        hosts:
          - host: &host "<app>.${SECRET_DOMAIN}"
            paths:
              - path: /
                service:
                  identifier: app
                  port: http
        tls:
          - hosts: [*host]
            secretName: ${SECRET_DOMAIN/./-}-tls
    persistence:
      config:
        existingClaim: <app-name>
      tmp:
        type: emptyDir
```

### Ingress: Internal vs External

| className | DNS Target | Use When |
|-----------|-----------|----------|
| `internal` | `internal.${DOMAIN}` | LAN-only access (most apps) |
| `external` | `external.${DOMAIN}` | Public-facing via Cloudflare tunnel |

The `external-dns.alpha.kubernetes.io/target` annotation **must match** the className:
- `className: internal` → `internal.${SECRET_DOMAIN}`
- `className: external` → `external.${SECRET_DOMAIN}`

### Domain Variables by Namespace

| Namespace | Domain Variable | TLS Secret |
|-----------|----------------|------------|
| Most namespaces | `${SECRET_DOMAIN}` | `${SECRET_DOMAIN/./-}-tls` |
| `media` | `${SECRET_DOMAIN_MEDIA}` | `${SECRET_DOMAIN_MEDIA/./-}-tls` |
| Personal apps (resume) | `${SECRET_DOMAIN_PERSONAL}` | `${SECRET_DOMAIN_PERSONAL/./-}-tls` |

Additional domains exist (`SECRET_DOMAIN_DIVING`, `SECRET_DOMAIN_WIFE`) but are rarely used for new apps.

### Authentik Auth Annotations

For apps that need SSO/auth protection, add to ingress annotations:

```yaml
ingress:
  app:
    annotations:
      authentik.home.arpa/internal: "true"
      nginx.ingress.kubernetes.io/auth-signin: "https://<app>.${DOMAIN}/outpost.goauthentik.io/start?rd=$scheme://$http_host$escaped_request_uri"
```

Use this for admin UIs and apps without built-in auth (prowlarr, radarr, tdarr, bazarr, etc.).

### app/externalsecret.yaml

```yaml
---
# yaml-language-server: $schema=https://kubernetes-schemas.pages.dev/external-secrets.io/externalsecret_v1beta1.json
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: <app-name>
spec:
  secretStoreRef:
    kind: ClusterSecretStore
    name: infisical
  target:
    name: <app-name>-secret
    template:
      engineVersion: v2
      mergePolicy: Replace
      data:
        KEY_NAME: "{{ .INFISICAL_KEY }}"
  dataFrom:
    - find:
        path: INFISICAL_KEY
```

#### ClusterSecretStore Variants

| Store Name | Use When |
|-----------|----------|
| `infisical` | Default — most app secrets |
| `infisical-postgres` | App needs PostgreSQL credentials + connection strings |
| `infisical-authentik` | App needs Authentik OAuth credentials |

#### dataFrom Patterns

```yaml
# Match by prefix (all keys starting with APP_)
dataFrom:
  - find:
      name:
        regexp: ^APP_.*

# Match by exact path
dataFrom:
  - find:
      path: SPECIFIC_KEY_NAME

# Multiple sources combined
dataFrom:
  - find:
      name:
        regexp: ^ATUIN.*
  - find:
      path: POSTGRES_SUPER_USER
  - find:
      path: POSTGRES_SUPER_PASS
```

### app/kustomization.yaml

```yaml
---
# yaml-language-server: $schema=https://json.schemastore.org/kustomization
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ./externalsecret.yaml
  - ./helmrelease.yaml
```

### Namespace-level kustomization.yaml

```yaml
---
# yaml-language-server: $schema=https://json.schemastore.org/kustomization
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: <namespace>
components:
  - ../../flux/components/common
resources:
  - ./namespace.yaml
  - ./<app-name>/ks.yaml
```

### namespace.yaml

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: _
  annotations:
    kustomize.toolkit.fluxcd.io/prune: disabled
  labels:
    goldilocks.fairwinds.com/enabled: "true"
```

Add `volsync.backube/privileged-movers: "true"` annotation if apps in namespace use VolSync.

## Common Components

| Component | Path | Purpose |
|-----------|------|---------|
| common | `../../flux/components/common` | Alerts, OCI repos (app-template), SOPS, cluster substitutions |
| volsync/repository | `../../../../flux/components/volsync/repository` | VolSync PVC + PV for backups |
| volsync/operations | `../../../../flux/components/volsync/operations` | ReplicationSource/Destination |
| gatus/external | `../../../../flux/components/gatus/external` | External health check config |
| gatus/guarded | `../../../../flux/components/gatus/guarded` | Auth-guarded health check config |

## Multi-Component Apps

When an app has sub-components beyond `app/`, use named subdirectories with their own `kustomization.yaml`:

```
<app-name>/
├── ks.yaml                    # May have multiple Kustomizations
├── app/                       # Primary component
│   ├── kustomization.yaml
│   └── helmrelease.yaml
├── cluster/                   # e.g. database cluster resource
│   ├── kustomization.yaml
│   └── cluster.yaml
└── config/                    # e.g. additional ConfigMaps
    ├── kustomization.yaml
    └── net-attach-main.yaml
```

Each subdirectory referenced by its own Flux Kustomization in `ks.yaml`.

## Archiving Apps

Move to `.archive/` within the namespace directory. Remove from namespace `kustomization.yaml`.

```
<namespace>/
├── .archive/
│   └── <deprecated-app>/
│       └── app/
```

Do NOT leave stale `-bak` suffixed directories (e.g. `archon-bak`).

## Key Rules

1. **One `ks.yaml` per app** at `<namespace>/<app>/ks.yaml` — never deeper, never at namespace level
2. **Inline HelmRelease values** — no `helm-values.yaml` files (exception: infrastructure charts like Cilium/CoreDNS where values are enormous)
3. **Use app-template** for all standard apps — avoid raw Deployment/Service/Ingress manifests
4. **YAML anchors** for DRY — `&app`, `&namespace`, `&host`, `&port` are idiomatic
5. **Security context on every container** — `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`, `capabilities: { drop: ["ALL"] }`
6. **Resource requests AND limits** on every container
7. **`reloader.stakater.com/auto: "true"`** annotation on controllers using secrets/configmaps
8. **Schema comments** at top of every YAML file (`# yaml-language-server: $schema=...`)
9. **Common component** must be included in every namespace kustomization
10. **ExternalSecret targets `<app>-secret`** — consistent naming, referenced via `envFrom` in HelmRelease
11. **Match ingress class to DNS target** — `internal` ↔ `internal.${DOMAIN}`, `external` ↔ `external.${DOMAIN}`
