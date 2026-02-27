---
name: fleet-status
description: Check the health and status of all Round Table knights by pinging them via NATS. Use to verify fleet readiness before dispatching chains.
metadata:
  author: roundtable
  version: "1.0"
  tier: project
---

# Fleet Status Check

Ping all knights to verify they're online and responsive. Use before dispatching critical chains or when asked about fleet health.

## How to Check

Ping each knight with a lightweight task:

```
nats_request(
  knight: "galahad", domain: "security",
  task: "Reply with PONG and your current status (ready/busy). One word.",
  timeout_ms: 15000
)
```

## Quick Health Check

Ping all knights in sequence. A knight that times out (15s) is likely down or overloaded.

## Reporting Format

```markdown
## ⚔️ Fleet Status

| Knight | Domain | Status | Response Time |
|--------|--------|--------|---------------|
| Galahad | security | 🟢 Online | 2.1s |
| Kay | research | 🟢 Online | 1.8s |
| Tristan | infra | 🔴 Timeout | >15s |
| ... | ... | ... | ... |

**Fleet: 9/10 online** | Last check: [timestamp]
```

## When to Use

- Before dispatching a multi-knight chain
- When Tim or Derek asks "how are the knights?"
- As part of morning mission briefing prep
- After deployments or operator changes
