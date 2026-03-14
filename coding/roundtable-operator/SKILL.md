---
name: roundtable-operator
description: Work within the roundtable operator repo (Go, Kubebuilder). Use when modifying CRDs, controllers, Helm charts, or NATS integration in dapperdivers/roundtable.
---

# roundtable-operator Codebase Guide

## Quick Reference

| Aspect | Detail |
|--------|--------|
| Language | Go 1.25+ |
| Framework | Kubebuilder (controller-runtime) |
| Tests | Ginkgo + Gomega (BDD), envtest |
| CRD Group | `ai.roundtable.io/v1alpha1` |
| Kinds | Knight, Chain, Mission, RoundTable |
| NATS | `github.com/nats-io/nats.go` v1.49+ |
| CI | `go vet`, `go test`, Docker build+push to GHCR |
| Image | `ghcr.io/dapperdivers/roundtable:<sha>` |

## Project Layout

```
cmd/main.go                         Entry point (registers controllers)
api/v1alpha1/*_types.go             CRD schemas (kubebuilder markers)
api/v1alpha1/zz_generated.*         AUTO-GENERATED — never edit
internal/controller/
  knight_controller.go              Knight reconciliation → Deployments
  chain_controller.go               Chain reconciliation → NATS task dispatch
  mission_controller.go             Mission planning + execution
  roundtable_controller.go          RoundTable (dynamic tables)
  plan.go                           Mission planning logic
pkg/nats/
  client.go                         NATS JetStream client wrapper
  config.go                         NATS configuration
  helpers.go                        Subject/stream helpers
  payload.go                        Task/result payload types
charts/roundtable-operator/         Helm chart (CRDs in crds/, templates in templates/)
config/crd/bases/                   Generated CRDs — never edit directly
hack/                               Dev scripts
```

## Critical Rules

1. **Never edit auto-generated files**: `config/crd/bases/*.yaml`, `config/rbac/role.yaml`, `**/zz_generated.*.go`
2. **Never remove scaffold markers**: `// +kubebuilder:scaffold:*` comments
3. **After editing `*_types.go`**: Run `make manifests generate`
4. **After editing `*.go`**: Run `make test`
5. **Always `CGO_ENABLED=0`** for builds (no gcc in runtime image)
6. **Kubebuilder CRD defaults are applied at API server admission** — controller-side env vars can't override them

## Build & Test

```bash
make manifests generate   # Regen CRDs + DeepCopy after type changes
make test                 # Unit tests (envtest — real API server + etcd)
go vet ./...              # Lint
go build -o bin/manager cmd/main.go
```

## CRD Types — Source of Truth

**Always validate Knight CRs against `api/v1alpha1/knight_types.go`.**

Key fields:
- `spec.nats.subjects` (NOT `topics`)
- `spec.workspace.size` (NOT `storageSize`)
- `spec.arsenal` has `repo/ref/period/image` (NOT `skills`)
- `spec.skills` is top-level (not under arsenal)

## NATS Integration

- Streams are configurable via env: `NATS_TASKS_STREAM`, `NATS_RESULTS_STREAM`, `NATS_RESULTS_PREFIX`
- Chain task subjects: `chain-name-step.timestamp` (dots, not dashes, before timestamp)
- WorkQueue retention for dynamic/ephemeral tables
- `OrderedConsumer` incompatible with WorkQueue retention streams

## Helm Chart

Located at `charts/roundtable-operator/`. CRDs go in `crds/` (plain YAML, no templating).

**Trap**: `cp *.yaml` into `crds/` dir can grab kustomization.yaml → breaks chart upgrade. Be explicit with filenames.

## Controller Patterns

- Idempotent reconciliation (safe to run multiple times)
- Re-fetch before updates to avoid conflicts
- Owner references for garbage collection
- Structured logging (capital first letter, no trailing period, past tense)
- `metav1.Condition` for status (not custom strings)

## Known Gotchas

- `spec.timeout` on Chain CRD defaults to 600s — set explicitly for multi-step chains (3600+)
- Step names in chains: **underscores, not hyphens** (Go templates interpret `-` as subtraction)
- 3 hardcoded `fleet-a` bugs remain: mission_controller:1053, knight_controller:996/1002, chain_controller:55
- `Flux targetNamespace` rewrites ALL namespace fields including cross-namespace SA refs
