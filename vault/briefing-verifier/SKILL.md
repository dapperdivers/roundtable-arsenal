---
name: briefing-verifier
description: >
  Procedure for the morning-briefing verify_claims step: re-run the check
  behind every mechanically-verifiable claim in the domain summaries, build
  the authoritative knight-liveness map from vault file mtimes, update the
  open-items ledgers, and emit one JSON verification report that the
  synthesizer treats as the only source of numbers.
---

# Briefing Verifier — verify_claims Procedure

You receive the seven domain summaries (JSON objects, prose fallbacks, or
empty strings for timeouts). Your output is the **verification report** — the
synthesizer may not print any number that isn't in it. You verify; you never
narrate, editorialize, or rank. Completeness beats brevity.

**You are READ-ONLY on the cluster.** `kubectl get`, `kubectl describe`,
`kubectl logs` only — never apply, delete, edit, scale, or exec. The only
files you write are the ledger files under `/vault/Briefings/Ledger/`.

## Step 1 — Parse the summaries

For each domain, classify its summary: `json` (parses as an object),
`unstructured` (non-empty but not valid JSON), or `missing` (empty/absent).
Never guess content for a missing summary.

## Step 2 — Re-verify claims

For every item in each summary's `open` and `new` lists (for `unstructured`
summaries: any bullet that asserts a checkable fact):

1. Find its verification command — the item's `evidence` field, or the
   matching item's `verification.command` in
   `/vault/Briefings/Ledger/<domain>.json`.
2. Run it (read-only). Compare against the claim / the ledger's
   `verification.expect`.
3. Record `verified: true` (reproduces), `false` (does not reproduce — e.g.
   the resource is healthy, absent, or the numbers don't match), or
   `"error"` (command failed to run).
4. No command at all (personal items) → `"unverified"`.

Also re-verify any `resolved` entry cheaply when a command exists — a
resolution that doesn't hold is an anomaly worth flagging.

## Step 3 — Liveness truth (the #1 error class)

The pipeline has repeatedly misreported which knights ran. You settle it:

- `ls -l` each domain's vault report directory (Security, Intel, HomeLab,
  Home, Finance, Career, Wellness under `/vault/Briefings/`).
- Judge **by file mtime, not filename** — Kay is known to future-date
  filenames (tomorrow's date written today).
- For each domain record: did a report land today (mtime), did a summary
  arrive (step output present), and the most recent report date. With the
  ledger's `meta.last_report` history, compute the trailing-7-day gap per
  domain.
- A domain can be `reported` in the vault yet `missing` on NATS (summary
  lost in transport) — that distinction goes in the report; never collapse it.

## Step 4 — Ledger stamps and anomalies

In each `/vault/Briefings/Ledger/<domain>.json` (valid JSON in, valid JSON
out — check with `jq` after writing):

- Set `last_verified` = today on items you re-verified successfully.
- Set `meta.last_summary_received` = today where a summary arrived.
- Do NOT change item status — resolving/opening items is the domain
  knight's job, not yours.

Flag as anomalies: a previously-`resolved` item appearing as open in today's
summary, `first_seen` values that changed, Day-N claims that don't equal
`today - first_seen`, and counters that moved backwards.

## Step 5 — The verification report

Your NATS response is EXACTLY one JSON object — no prose around it:

```json
{
  "verifier": "patsy",
  "date": "YYYY-MM-DD",
  "verifier_status": "ok | degraded",
  "liveness": {
    "security": { "summary": "received | missing | unstructured",
                   "vault_report_today": true,
                   "last_report": "YYYY-MM-DD", "gap_days": 0 }
  },
  "claims": [
    { "domain": "infra", "id": "ledger-id-or-null", "claim": "one line",
      "verified": true, "command": "what you ran", "observed": "1-line result",
      "day_n": 3 }
  ],
  "resolved_confirmed": [ { "domain": "infra", "id": "...", "holds": true } ],
  "anomalies": [ "one line each" ],
  "notes": "only if something impaired verification (RBAC denial, timeout)"
}
```

- `liveness` has all seven domains, always.
- `claims` carries every item you checked, including failures — `verified:
  false` entries are the most valuable ones.
- `day_n` is present only where the ledger has a non-null `first_seen`;
  compute it, never copy it.
- If you ran out of time or tools, emit the report anyway with
  `verifier_status: "degraded"` and what you couldn't check in `notes` —
  a partial report beats none; everything unchecked stays unverified.
