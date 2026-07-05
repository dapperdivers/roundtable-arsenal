---
name: evidence-verification
description: >
  Mandatory evidence rules for any report or briefing that makes factual claims.
  Prevents the known corruption modes: AGE-column misreads, stale Day-N counters,
  Flux-status-as-outage claims, dropped resolutions, and uncited numbers.
---

# Evidence Verification — Report Integrity Rules

These rules are **mandatory** whenever you produce a report, briefing, or
summary that makes factual claims. They exist because each one maps to a real
corruption incident in a published briefing. Violating them produces a
fabricated briefing.

## Rule 1 — AGE is not a duration

The kubectl/flux `AGE` column is the **resource's** age — how long the object
has existed — not how long a problem has existed. A 507-day-old kustomization
that started failing yesterday has been broken for one day, not 507.

- NEVER report AGE as a stall, failure, or outage duration.
- Get problem durations from `status.conditions[].lastTransitionTime`,
  events, or your own prior reports' first-seen dates.

## Rule 2 — Re-verify before you increment

Before carrying any tracked item forward ("⏳ Day N", "Still pending",
"Day 139+"), **re-run the check that originally found it**, today.

- Still reproduces → carry it forward and increment.
- No longer reproduces → report it as `RESOLVED:` — do not silently drop it,
  and never increment a counter from memory or from yesterday's report alone.

## Rule 3 — Control-plane status is not workload status

A Flux Kustomization/HelmRelease that is `False`/not-ready tells you GitOps
reconciliation has a problem. It says **nothing** about whether the workload
is up.

- Check the actual pods (`kubectl get pods ...`) before claiming a service is
  degraded, down, or "failing silently".
- If pods are Running and Ready, say so explicitly and scope the finding to
  reconciliation only.

## Rule 4 — Resolutions are first-class signal

When something you previously reported is fixed, closed, or no longer present,
that is one of the most valuable things you can report.

- Lead your summary with a `RESOLVED: <item>` bullet for each such item.
- `RESOLVED:` bullets never count against any bullet-count cap and must never
  be dropped for space — compression that loses a resolution creates a
  phantom issue that haunts every future report.

## Rule 5 — No number without a source

Every number you print — day counts, durations, versions, counts of anything —
must be traceable to a command you ran today, a file you read today, or an
explicitly cited prior report.

- If you cannot point at the source, do not print the number.
- Estimates must be labeled as estimates.

## Rule 6 — Chronic is still critical

"Focus on changes" never demotes an ongoing incident. A node that has been
down for four days belongs in the headline every day until it is fixed, above
new-but-cosmetic findings. If your report has a "stale items" section, an
active outage never goes there.

## Rule 7 — Your instructions can be stale

Task prompts and skills are written at a point in time. If evidence you gather
today (vault files, cluster state, calendars) contradicts a fact stated in
your instructions, **trust the evidence**, say you did, and flag the stale
instruction in your report so it gets fixed.
