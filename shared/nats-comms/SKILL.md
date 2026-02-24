---
name: nats-comms
description: Publish additional NATS messages beyond the automatic task result. Use for alerts, reports, or broadcasts outside the normal task response flow.
metadata:
  author: roundtable
  version: "4.0"
  tier: shared
---

# NATS Communications

Your task results are published automatically by the runtime — you don't need this for normal task responses.

Use the `nats_publish` tool when you need to send **additional** messages to specific NATS subjects outside the standard request/response flow.

## When to Use

- Publishing an alert to a monitoring subject
- Sending a report to a specific topic
- Broadcasting data that isn't a direct task response

## Usage

Use the `nats_publish` tool directly:

```
nats_publish(
  subject: "fleet-a.alerts.security",
  message: '{"type":"alert","severity":"high","message":"Critical CVE detected"}'
)
```

## Important

- Your normal task output is captured and published by the runtime automatically
- Do NOT use `nats_publish` for task results — that's handled for you
- Only use this for out-of-band messaging, alerts, and broadcasts
