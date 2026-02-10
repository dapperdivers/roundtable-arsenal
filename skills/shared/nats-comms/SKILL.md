---
name: nats-comms
description: Communicate with the Round Table via NATS. Use when you need to send results, reports, or messages to Tim or other knights through the NATS messaging bus. Your nats-bridge sidecar exposes a local HTTP API for publishing.
---

# NATS Communications

Your pod runs a **nats-bridge sidecar** on `localhost:8080` that connects you to the Round Table's NATS messaging bus. Use it to publish results, reports, and messages.

## Quick Reference

### Publish a message to NATS

```bash
./scripts/nats-publish.sh <subject> '<json-data>'
```

### Get your bridge info (fleet ID, agent ID, etc.)

```bash
curl -s http://localhost:8080/info | jq .
```

### Check bridge health

```bash
curl -s http://localhost:8080/healthz
```

## Scripts

### `nats-publish.sh`

Publishes a JSON message to any NATS subject via the local bridge sidecar.

```bash
# Send a task result back to Tim
./scripts/nats-publish.sh "fleet-a.results.security.task-123" '{"id":"task-123","type":"task.result","from":"galahad","to":"tim","payload":{"summary":"No critical CVEs found","details":"..."}}'
```

**Arguments:**
| Position | Description |
|----------|-------------|
| `$1` | NATS subject to publish to |
| `$2` | JSON data (message body) |

**Exit codes:** 0 = success, 1 = error (prints error message to stderr)

### `nats-respond.sh`

Convenience wrapper for responding to a task. Automatically constructs the correct result envelope and subject.

```bash
# Respond to a task by ID
./scripts/nats-respond.sh <task-id> <domain> '{"summary":"Result here","details":"..."}'
```

**Arguments:**
| Position | Description |
|----------|-------------|
| `$1` | Task ID (from the incoming task envelope) |
| `$2` | Domain (e.g., `security`, `intel`, `comms`) |
| `$3` | JSON payload (your result data) |

**Example:**
```bash
./scripts/nats-respond.sh "task-abc123" "security" '{"summary":"Scan complete","findings":[],"severity":"low"}'
```

## Envelope Format

All NATS messages use a standard envelope:

```json
{
  "id": "unique-task-id",
  "fleetId": "fleet-a",
  "type": "task.result",
  "from": "your-agent-id",
  "to": "tim",
  "timestamp": "2026-02-09T00:00:00Z",
  "payload": {
    "your": "result data here"
  }
}
```

## How It Works

```
You (OpenClaw) → curl localhost:8080/publish → nats-bridge sidecar → NATS JetStream → Tim
```

The nats-bridge sidecar handles all NATS connection management, JetStream publishing, and reconnection. You just POST JSON to `localhost:8080/publish`.

## Important Notes

- The bridge runs on **localhost:8080** — same pod, no auth needed
- Subjects follow the pattern: `{fleet-id}.results.{domain}.{task-id}`
- Your fleet ID and agent ID are available via `GET /info`
- Messages are published to JetStream (durable, persisted)
- Keep payloads under 1MB
