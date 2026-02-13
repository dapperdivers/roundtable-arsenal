---
name: notification-digest
description: Collect and aggregate notifications from various sources into a digest. Use for periodic notification summaries.
allowed-tools: Bash(curl:*) Read
metadata:
  author: roundtable
  version: "2.0"
  tier: comms
---

# Notification Digest

Collects notifications from configured sources and compiles them into a digest.

## Scripts

```bash
bash scripts/collect-notifications.sh [--hours 24]
```
