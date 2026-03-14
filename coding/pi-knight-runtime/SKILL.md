---
name: pi-knight-runtime
description: Work within the pi-knight runtime repo (TypeScript/Node). Use when modifying knight runtime, NATS messaging, tools, or the coding agent SDK in dapperdivers/pi-knight.
---

# pi-knight Runtime Codebase Guide

## Quick Reference

| Aspect | Detail |
|--------|--------|
| Language | TypeScript (ES modules) |
| Runtime | Node.js 22 |
| Framework | pi-agent-core + pi-ai + pi-coding-agent (pi.dev SDKs) |
| NATS | `nats` npm v2.28+ (JetStream) |
| CI | `npm ci && npm run build`, Docker build+push to GHCR |
| Image | `ghcr.io/dapperdivers/pi-knight:<sha>` |

## Project Layout

```
src/
  index.ts          Entry point — boots knight, connects NATS, starts health server
  knight.ts         Core knight logic — task handling, tool registration
  config.ts         Environment-based configuration
  nats.ts           NATS JetStream consumer/publisher
  health.ts         HTTP health/readiness endpoints
  introspect.ts     Knight self-description for operator
  logger.ts         Structured logging
  metrics.ts        Prometheus metrics (prom-client)
  tools/
    nats.ts         NATS communication tools (knight-to-knight messaging)
    subagent.ts     Sub-agent spawning tools
defaults/           Default configuration files
docs/               Documentation
examples/           Example configurations
scripts/            Build/deploy scripts
```

## Build & Test

```bash
npm ci              # Install dependencies
npm run build       # TypeScript compile (tsc)
npm run dev         # Watch mode (tsx)
npm start           # Run compiled output
```

**No test suite currently** — `tsc` is the primary validation gate.

## Key Dependencies

- `@mariozechner/pi-agent-core` — Base agent framework (tools, context, orchestration)
- `@mariozechner/pi-ai` — LLM provider abstraction
- `@mariozechner/pi-coding-agent` — Coding tools (bash, read, write, edit) with inner iteration
- `@sinclair/typebox` — Runtime type validation
- `nats` — NATS client for JetStream
- `prom-client` — Prometheus metrics

## NATS Architecture

- Knights consume tasks from JetStream WorkQueue streams
- Configurable via env: `NATS_TASKS_STREAM`, `NATS_RESULTS_STREAM`, `NATS_RESULTS_PREFIX`
- Results published to `<prefix>.<knight-name>.<task-id>`
- Task payloads: `{taskId, input, context}` → Results: `{task_id, result, success}`
- **Field name mismatch with operator**: Controller expects `{taskId, output, error}`, pi-knight publishes `{task_id, result, success}`. Getter methods bridge both formats.

## Environment Variables

Key env vars set by the operator:
- `KNIGHT_NAME` — Identity
- `NATS_URL` — JetStream connection
- `NATS_TASKS_STREAM`, `NATS_RESULTS_STREAM`, `NATS_RESULTS_PREFIX` — Stream config
- `LLM_BASE_URL`, `LLM_API_KEY`, `LLM_MODEL` — AI provider
- `SKILLS_DIR` — Arsenal skills mount path
- `WORKSPACE_DIR` — Persistent workspace
- `SHARED_DIR` — Shared CephFS mount (`/shared`)

## Knight Communication

Knight-to-knight comms are baked into `src/tools/nats.ts` (not arsenal skills). Knights can:
- Send messages to other knights via NATS
- Query knight status
- NATS prefix derived from `NATS_RESULTS_PREFIX` env var (operator sets per-table)

## Coding Agent Capabilities

When `pi-coding-agent` is active, knights get:
- `bash` — Execute shell commands
- `read` — Read files
- `write` — Write files  
- `edit` — Precise file edits
- Inner iteration loops for complex tasks

## Known Gotchas

- Knights can self-install tools: `nix profile install nixpkgs#<package>` (persists on PVC)
- Nix entrypoint checks `/nix/store` but not `~/.nix-profile` symlink integrity — stale PVCs with broken symlinks cause silent tool failure (delete PVC to fix)
- Knights describe work instead of outputting artifacts — always verify output IS the deliverable
- Frontend tasks need explicit `npx tsc --noEmit` mandate — knights skip it otherwise
