---
name: open-items-ledger
description: >
  Protocol for the per-domain open-items ledger at
  /vault/Briefings/Ledger/<domain>.json. Replaces prose memory as the
  carry-forward mechanism for tracked items: Day-N counters are computed from
  first_seen, items are re-verified before being carried, and resolutions are
  recorded machine-readably so they can never be silently lost.
---

# Open-Items Ledger — Carry-Forward Protocol

Your domain has a ledger file: `/vault/Briefings/Ledger/<domain>.json`.
It is the **single source of truth for tracked items** — not yesterday's
report, not your memory, not your task prompt. Follow this protocol every
time you produce a daily report or briefing summary.

## The file

```json
{
  "domain": "infra",
  "knight": "tristan",
  "meta": { "last_report": "2026-07-05", "last_summary_received": "2026-07-05" },
  "items": [
    {
      "id": "short-stable-slug",
      "claim": "one-line statement of the issue",
      "severity": "low | medium | high",
      "first_seen": "YYYY-MM-DD or null",
      "last_verified": "YYYY-MM-DD",
      "verification": { "command": "read-only command", "expect": "what confirms it" },
      "status": "open | resolved",
      "resolved_on": "YYYY-MM-DD or null",
      "notes": "one line of context"
    }
  ]
}
```

- `first_seen: null` means unknown/pre-ledger — never invent a date.
- `verification: null` means not mechanically checkable (personal items) —
  such claims are always rendered `[unverified]`.

## Ownership

**You write only your own domain's file.** The verifier step updates
`last_verified` timestamps and `meta.last_summary_received`; the synthesizer
only reads. Keep the file valid JSON — if you can, sanity-check with
`jq . <file>` after writing.

## Protocol — at the start of every report

1. **Read your ledger file.** If it is missing, say so in your report,
   create a minimal one from what you observe today, and flag it.
2. **For every `open` item, re-verify it today:**
   - It has a `verification.command` → run it (read-only). Still reproduces →
     keep it open and set `last_verified` to today. No longer reproduces →
     set `status: resolved`, `resolved_on` today, and lead your summary with
     a `RESOLVED:` bullet for it.
   - `verification: null` (personal) → carry it, but it renders
     `[unverified]`; never claim it was confirmed.
   - The command errors → keep the item open, don't update `last_verified`,
     and note the verification failure in your report.
3. **Never carry an open item you did not re-verify today.** An item whose
   `last_verified` is more than 2 days old must be re-verified or explicitly
   flagged as unverifiable — never silently carried.

## Day-N counters

`Day N = today − first_seen`, **computed at write time, every time.**

- Never increment yesterday's counter, never copy a counter from a prior
  report or briefing, never estimate one.
- `first_seen: null` → no Day-N number at all; describe the item without one.
- If your computed Day-N contradicts what yesterday's briefing printed,
  yours is correct — the ledger beats prose history.

## New and recurring items

- **New item found today:** append it with `first_seen` = today, the exact
  command that found it as `verification.command`, and `status: open`.
- **Resolved items stay in the file.** They are the anti-resurrection
  record. Never delete them and never flip one back to `open`. If the same
  problem genuinely recurs, add a **new item** with a fresh `first_seen` and
  a note referencing the old id — its history restarts; it is not "Day 140".

## Finishing

- Update `meta.last_report` to today when you write your vault report.
- Your summary must agree with the ledger: every `RESOLVED:` bullet matches
  an item resolved today; every carried item is `open` with
  `last_verified` = today (or explicitly `[unverified]`).
