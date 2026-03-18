---
name: email-triage
description: >
  Fetch and triage emails from the Outlook bridge API. Use when checking for urgent messages, compiling email digests, or scanning for important communications.
---

# Email Triage

Fetches recent emails via the outlook-bridge API for triage and categorization.

## Scripts

```bash
bash scripts/fetch-emails.sh [--hours 24] [--folder inbox]
```

## Triage Categories
- 🔴 **Urgent** — time-sensitive, requires immediate action
- 🟡 **Action needed** — needs response but not time-critical
- 🟢 **Informational** — FYI, newsletters, notifications
- ⚪ **Skip** — spam, marketing, automated notifications
