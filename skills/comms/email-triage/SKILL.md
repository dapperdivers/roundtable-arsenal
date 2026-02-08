---
name: email-triage
description: Fetch and triage emails from the Outlook bridge API. Use when checking for urgent messages or compiling email digests.
---

# Email Triage

Fetches recent emails via the outlook-bridge API for triage and categorization.

## Scripts

### `fetch-emails.sh`

```bash
./scripts/fetch-emails.sh --count 20
./scripts/fetch-emails.sh --since "2h" --unread
./scripts/fetch-emails.sh --folder inbox --format json
```

**Arguments:**
| Flag | Description |
|------|-------------|
| `--count` | Number of emails to fetch (default: 10) |
| `--since` | Only emails from last Nh or Nd |
| `--unread` | Only unread emails |
| `--folder` | Mail folder (default: inbox) |
| `--format` | Output: `json` (default) or `summary` |

**Output:** JSON array of email objects with sender, subject, date, preview, and flags.
