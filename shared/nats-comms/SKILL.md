---
name: nats-comms
description: Publish additional NATS messages beyond the automatic task result. Use when you need to send reports, alerts, or data to specific NATS subjects outside the normal task response flow.
allowed-tools: Bash(nats:*) Read
metadata:
  author: roundtable
  version: "3.0"
  tier: shared
---

# NATS Communications

Your task results are published automatically by the knight-agent runtime — you don't need this skill for normal task responses.

Use this skill when you need to publish **additional** messages to specific NATS subjects (alerts, reports, data feeds) outside the standard request/response flow.

## When to Use

- Publishing an alert to a monitoring subject
- Sending a report to a specific topic
- Broadcasting data that isn't a direct task response

## Scripts

### `nats-publish.sh` — Publish to any NATS subject

```bash
bash /workspace/skills/nats-comms/scripts/nats-publish.sh "<subject>" "<payload>"
```

**Example:**
```bash
bash /workspace/skills/nats-comms/scripts/nats-publish.sh \
  "fleet-a.alerts.security" \
  '{"type":"alert","severity":"high","message":"Critical CVE detected"}'
```

### `nats-respond.sh` — Publish a task result manually

Only needed if you want to publish a result to a subject different from the automatic one:

```bash
bash /workspace/skills/nats-comms/scripts/nats-respond.sh "<result_subject>" "<json_payload>"
```

## Architecture

Knights connect to NATS directly (native client in knight-agent runtime).
- **NATS URL:** `nats://nats.database.svc:4222`
- **nats CLI:** Available at `/usr/local/bin/nats` or via `$PATH`
- **Task results:** Published automatically — don't duplicate them

## Important

- Your normal task output is captured and published by the runtime. You do NOT need to call nats-respond.sh for standard tasks.
- Only use these scripts for out-of-band messaging.
