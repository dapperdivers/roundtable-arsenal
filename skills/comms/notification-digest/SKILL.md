---
name: notification-digest
description: Collect and aggregate notifications from various sources into a digest. Use for periodic notification summaries.
---

# Notification Digest

Collects notifications from configured sources and compiles them into a digest.

## Scripts

### `collect-notifications.sh`

```bash
./scripts/collect-notifications.sh --sources all
./scripts/collect-notifications.sh --sources "email,discord,github" --since 4h
```

**Arguments:**
| Flag | Description |
|------|-------------|
| `--sources` | Notification sources: `all`, or comma-separated list |
| `--since` | Time window (e.g., `4h`, `1d`) |
| `--format` | Output: `json` or `summary` |

**Output:** JSON array of notifications with source, type, title, timestamp, and priority.
