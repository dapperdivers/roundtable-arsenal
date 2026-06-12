---
name: night-watch-triage
description: Turn collected telemetry into fingerprinted incidents, dedup against the ledger and prior Missions, and dispatch at most three fix Missions per night. Use during the Night Watch triage step.
---

# Night Watch Triage

You turn raw error signatures into **incidents**, keep the ledger truthful, and
dispatch fix Missions. You never fix anything yourself.

## Fingerprinting

A fingerprint identifies a *bug*, not an *occurrence*:

```
fp = first 12 hex of sha256("<workload>|<normalized-signature>")
```

- `workload`: the owning deployment/knight name (`coder-1`, `roundtable-operator`,
  `roundtable-operator-dashboard`), not the pod hash.
- `normalized-signature`: the error message with volatile parts stripped —
  task IDs, timestamps, pod suffixes, durations, request IDs all become `*`.
  `task abc-123 timeout after 1800s` → `task * timeout after *s`.

```bash
fp=$(printf '%s|%s' "$workload" "$signature" | sha256sum | cut -c1-12)
```

## The ledger — /vault/NightWatch/ledger.md

Single source of incident history. Create it if missing with this header:

```markdown
# Night Watch Ledger
| fingerprint | first-seen | last-seen | count | workload | repo | tier | status | mission/PR | summary |
|---|---|---|---|---|---|---|---|---|---|
```

Status values: `observed` → `dispatched` → `fix-pr-open` → `merged` →
`verified` (error gone next sweep) or `recurred` (came back — re-triage at
higher priority). Dead ends: `wont-fix`, `not-platform` (with a one-line reason).

Every incident you see tonight gets a row (new) or an updated `last-seen`/`count`
(known). The ledger is append-friendly markdown — keep rows sorted newest-first.

## Dedup

Before dispatching anything:

1. `grep <fp> /vault/NightWatch/ledger.md` — if status is `dispatched`,
   `fix-pr-open`, or `merged`, do NOT re-dispatch. Update `last-seen` and move on.
   If `verified` but now recurring, set `recurred` — it may be dispatched again.
2. `kubectl get missions -n roundtable -l night-watch/fingerprint=<fp>` —
   an existing non-failed Mission means it's already in flight.

## Ranking

Score each new/recurred incident; dispatch the top ≤ 3:

1. **Recurrence** — `recurred` after a "fix" outranks everything (our fix was wrong)
2. **Blast radius** — operator/chain failures > single-knight failures > cosmetic
3. **Frequency** — events/24h
4. **Fixability** — clear signature + obvious owning repo beats a mystery

Skip (ledger `not-platform`): bad task prompts, model-provider outages,
transient infra (node reboot) — anything a repo PR can't fix.

## Hard limits — check BEFORE dispatching

- **Max 3 Missions per night.** Quality over coverage; the rest wait in the ledger.
- **Cost cap $10:** query `sum(increase(pi_knight_llm_cost_dollars_total[24h]))`
  (see telemetry-queries). If ≥ 10, dispatch NOTHING tonight; record
  `cost-cap-hit` in the ledger and say so in your output.

## Repo routing and tiers

| Target | Repo | Fixer | Tier |
|---|---|---|---|
| pi-knight runtime (task.failed, timeouts, entrypoint) | dapperdivers/pi-knight | coder-1 | 2 |
| dashboard API/UI | dapperdivers/roundtable-ui | coder-1 | 2 |
| skills/prompts | dapperdivers/roundtable-arsenal | coder-1 | 1 |
| operator (reconcile errors, CRD logic) | dapperdivers/roundtable | coder-2 | 3 |
| nats-bridge | dapperdivers/nats-bridge | coder-2 | 2 |
| deployment config (env, resources, model names) | dapperdivers/dapper-cluster — `kubernetes/apps/roundtable/**` ONLY | coder-2 | 1 |

## Dispatch — Mission CR

Mode is set by your task text. In **DIAGNOSIS mode**: full triage + ledger, but
create NO Missions. In **DISPATCH mode**, apply:

```bash
kubectl apply -f - <<EOF
apiVersion: ai.roundtable.io/v1alpha1
kind: Mission
metadata:
  name: nw-<fp>
  namespace: roundtable
  labels:
    night-watch/fingerprint: "<fp>"
    night-watch/repo: "<short-repo-name>"
    night-watch/tier: "<1|2|3>"
spec:
  objective: "Night Watch fix: <one-line summary>"
  briefing: |
    Read the coding/night-watch-fix skill first and follow it exactly.

    Incident fingerprint: <fp> (tier <N>)
    Target repo: <org/repo>
    Workload: <workload>
    Occurrences: <count> in 24h

    Evidence:
    <the 3-5 most informative raw log lines / metric values — verbatim>

    Diagnosis hypothesis:
    <your best root-cause analysis: file/area if you can tell, what changed>

    Definition of done: PR opened against <org/repo> with the fix and a test,
    PR body includes "Night-Watch-Fingerprint: <fp>". If you conclude this is
    NOT a real bug, say so explicitly with reasoning instead of forcing a PR.
  knights:
    - name: <coder-1|coder-2>
  roundTableRef: personal
  costBudgetUSD: "3"
  timeout: 7200
  ttl: 172800
  retainResults: true
EOF
```

Then set the ledger row to `dispatched` with the mission name.

## Output

Your step output is consumed by the report step. Emit compact, factual markdown:
incidents seen (with fps), dispatched (with mission names), skipped (with reasons),
ledger deltas, verification results, total fleet cost. No filler.
