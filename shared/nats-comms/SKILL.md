---
name: nats-comms
description: Communicate with the Round Table via NATS JetStream. Use when returning task results, publishing reports, or sending messages to Tim or other knights. Every knight has a nats-bridge sidecar on localhost:8080.
allowed-tools: Bash(curl:*) Read
metadata:
  author: roundtable
  version: "2.0"
  tier: shared
---

# NATS Communications

Your pod runs a **nats-bridge sidecar** at `http://127.0.0.1:8080` that connects you to the Round Table's NATS JetStream messaging bus.

## When to Use

- **Returning task results** — after completing a dispatched task
- **Publishing reports** — sending structured output to the orchestrator
- **Status updates** — progress on long-running tasks

## Quick Reference

### Respond to a task
```bash
bash scripts/nats-respond.sh "<subject>" "<result_payload>"
```

### Publish to an arbitrary subject
```bash
bash scripts/nats-publish.sh "<subject>" "<payload>"
```

### Check sidecar status
```bash
curl -s http://127.0.0.1:8080/info
```

## Important

- The `subject` for responses comes from your task metadata (`reply_subject` or `task_id`)
- Results are published to `fleet-a.results.<task_id>` by default
- The sidecar handles JetStream persistence — your message is durable
- If the sidecar is unreachable, return your result as plain text output (the runtime will capture it)

## Scripts

See [scripts/nats-respond.sh](scripts/nats-respond.sh) and [scripts/nats-publish.sh](scripts/nats-publish.sh) for implementation.
